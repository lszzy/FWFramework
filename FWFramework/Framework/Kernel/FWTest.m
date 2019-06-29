/*!
 @header     FWTest.m
 @indexgroup FWFramework
 @brief      单元测试
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-11
 */

#import "FWTest.h"
#import "FWLog.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

#ifdef DEBUG

#pragma mark - FWTestCase

@interface FWTestCase ()

@property (nonatomic, strong) NSException *exception;

@end

@implementation FWTestCase

+ (void)load
{
    if ([[self class] autoLoad]) {
        [[FWUnitTest sharedInstance] addTestCase:[self class]];
    }
}

+ (BOOL)autoLoad
{
    return NO;
}

- (void)setUp
{
}

- (void)tearDown
{
}

- (void)assertTrue:(BOOL)value expr:(NSString *)expr file:(NSString *)file line:(NSInteger)line
{
    [self assert:value userInfo:@{@"expr":(expr ?: @""), @"expect": @"true", @"value": @"false", @"assert": @"assertTrue", @"file":(file ? [file lastPathComponent] : @""), @"line":@(line)}];
}

- (void)assert:(BOOL)value userInfo:(NSDictionary *)userInfo
{
    if (!value) {
        self.exception = [NSException exceptionWithName:@"FWFramework" reason:@"Assertion failed" userInfo:userInfo];
    }
}

@end

#pragma mark - FWUnitTest

@interface FWUnitTest ()

@property (nonatomic, strong) NSMutableArray<Class> *testCases;
@property (nonatomic, strong) NSString *testLogs;

@property (nonatomic, strong) id testRunner;

@end

@implementation FWUnitTest

#pragma mark - Lifecycle

+ (void)load
{
    // 监听应用启动通知，自动执行框架单元测试
    [FWUnitTest sharedInstance].testRunner = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
        // 并行队列执行框架单元测试
        dispatch_queue_t queue = dispatch_queue_create("site.wuyong.FWFramework.FWTestQueue", NULL);
        dispatch_async(queue, ^{
            // 移除应用启动通知
            [[NSNotificationCenter defaultCenter] removeObserver:[FWUnitTest sharedInstance].testRunner];
            [FWUnitTest sharedInstance].testRunner = nil;
            
            NSArray *classes = [self subclassesOfClass:[FWTestCase class]];
            for (NSString *className in classes) {
                Class classType = NSClassFromString(className);
                [[FWUnitTest sharedInstance] addTestCase:classType];
            }
            
            // 执行框架单元测试
            if ([FWUnitTest sharedInstance].testCases.count > 0) {
                [[FWUnitTest sharedInstance] run];
                
                // 打印测试结果
                FWLogDebug(@"%@", [FWUnitTest sharedInstance].debugDescription);
            }
        });
    }];
}

+ (NSArray *)allClasses
{
    static NSMutableArray *classNames;
    
    if (!classNames) {
        classNames = [[NSMutableArray alloc] init];
        
        unsigned int classesCount = 0;
        Class *classes = objc_copyClassList(&classesCount);
        
        for (unsigned int i = 0; i < classesCount; ++i) {
            Class classType = classes[i];
            if (class_isMetaClass(classType)) continue;
            
            Class superClass = class_getSuperclass(classType);
            if (nil == superClass) continue;
            
            [classNames addObject:[NSString stringWithUTF8String:class_getName(classType)]];
        }
        
        [classNames sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [obj1 compare:obj2];
        }];
        
        free(classes);
    }
    
    return classNames;
}

+ (NSArray *)subclassesOfClass:(Class)clazz
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSArray *allClasses = [self allClasses];
    for (NSString *className in allClasses) {
        Class classType = NSClassFromString(className);
        if (classType == clazz) continue;
        if (![classType isSubclassOfClass:clazz]) continue;
        
        [result addObject:className];
    }
    return result;
}

+ (NSArray *)subclassesOfClass:(Class)clazz withPrefix:(NSString *)prefix
{
    NSArray *classNames = [self subclassesOfClass:clazz];
    if (nil == classNames || 0 == classNames.count) {
        return classNames;
    }
    
    if (nil == prefix) {
        return classNames;
    }
    
    NSMutableArray *result = [NSMutableArray array];
    for (NSString *className in classNames) {
        if (![className hasPrefix:prefix]) continue;
        
        [result addObject:className];
    }
    
    return result;
}

+ (instancetype)sharedInstance
{
    static FWUnitTest *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWUnitTest alloc] init];
    });
    return instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.testCases = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Public

- (void)addTestCase:(Class)testCase
{
    if (![testCase isSubclassOfClass:[FWTestCase class]]) {
        return;
    }
    
    if (![self.testCases containsObject:testCase]) {
        [self.testCases addObject:testCase];
    }
}

- (void)run
{
    // 取出测试用例
    NSArray *testCases = [self.testCases copy];
    [self.testCases removeAllObjects];
    
    // 定义统计数据
    NSUInteger failedCount = 0;
    NSUInteger succeedCount = 0;
    NSMutableString *testLog = [[NSMutableString alloc] init];
    NSTimeInterval beginTime = [[NSDate date] timeIntervalSince1970];
    
    // 依次执行测试
    for (Class classType in testCases) {
        NSTimeInterval time1 = [[NSDate date] timeIntervalSince1970];
        
        NSString *className = NSStringFromClass(classType);
        NSString *formatClass = [className stringByReplacingOccurrencesOfString:@"FWTestCase_" withString:@""];
        formatClass = [formatClass stringByReplacingOccurrencesOfString:@"_" withString:@"."];
        NSString *formatMethod = nil;
        NSString *formatError = nil;
        
        NSArray *selectorNames = [self testMethods:classType];
        BOOL testCasePassed = YES;
        NSUInteger totalTestCount = selectorNames.count;
        NSUInteger currentTestCount = 0;
        
        NSException *e = nil;
        
        @try {
            if (selectorNames && selectorNames.count > 0) {
                // 执行初始化，同一个对象
                FWTestCase *testCase = [[classType alloc] init];
                for (NSString *selectorName in selectorNames) {
                    currentTestCount++;
                    formatMethod = [selectorName stringByReplacingOccurrencesOfString:@"test" withString:@""];
                    SEL selector = NSSelectorFromString(selectorName);
                    if (selector && [testCase respondsToSelector:selector]) {
                        // 执行setUp
                        [testCase setUp];
                        
                        // 执行test
                        NSMethodSignature *signature = [testCase methodSignatureForSelector:selector];
                        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
                        [invocation setTarget:testCase];
                        [invocation setSelector:selector];
                        [invocation invoke];
                        
                        // 执行tearDown
                        [testCase tearDown];
                        
                        e = testCase.exception;
                        if (testCase.exception) {
                            break;
                        }
                    }
                }
            }
        } @catch (NSException *exp) {
            e = exp;
        }
        
        if (e) {
            NSDictionary *userInfo = e.userInfo && [e.userInfo objectForKey:@"expr"] ? e.userInfo : nil;
            if (userInfo) {
                formatError = [NSString stringWithFormat:@"- %@ ( %@, %@ : %@ ); ( %@ - %@ #%@ )", (userInfo[@"assert"] ?: @"ASSERT"), userInfo[@"value"], userInfo[@"expect"], [userInfo objectForKey:@"expr"], formatMethod, [userInfo objectForKey:@"file"], [userInfo objectForKey:@"line"]];
            } else {
                formatError = [NSString stringWithFormat:@"- %@ ( %@ )", e.reason, formatMethod];
            }
            testCasePassed = NO;
        }
        
        NSTimeInterval time2 = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval time = time2 - time1;
        NSUInteger succeedTestCount = testCasePassed ? currentTestCount : (currentTestCount - 1);
        float classPassRate = totalTestCount > 0 ? (succeedTestCount * 1.0f) / (totalTestCount * 1.0f) * 100.0f : 100.0f;
        
        if ( testCasePassed ) {
            succeedCount += 1;
            [testLog appendFormat:@"[  OK  ] : %@ ( %lu/%lu ) ( %.0f%% ) ( %.003fs )\n", formatClass, (unsigned long)succeedTestCount, (unsigned long)totalTestCount, classPassRate, time];
        } else {
            failedCount += 1;
            [testLog appendFormat:@"[ FAIL ] : %@ ( %lu/%lu ) ( %.0f%% ) ( %.003fs )\n", formatClass, (unsigned long)succeedTestCount, (unsigned long)totalTestCount, classPassRate, time];
            [testLog appendFormat:@"    %@\n", formatError];
        }
    }
    
    // 计算统计数据
    NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval totalTime = endTime - beginTime;
    NSUInteger totalCount = succeedCount + failedCount;
    float passRate = totalCount > 0 ? (succeedCount * 1.0f) / (totalCount * 1.0f) * 100.0f : 100.0f;
    
    // 生成测试日志
    NSString *totalLog = [NSString stringWithFormat:@"  TOTAL  : [ %@ ] ( %lu/%lu ) ( %.0f%% ) ( %.003fs )\n", failedCount < 1 ? @"OK" : @"FAIL", (unsigned long)succeedCount, (unsigned long)totalCount, passRate, totalTime];
    self.testLogs = [NSString stringWithFormat:@"\n========== TEST  ==========\n%@%@========== TEST  ==========", testLog, totalCount > 0 ? totalLog : @""];
}

- (NSArray *)testMethods:(Class)clazz
{
    NSMutableArray *methodNames = [NSMutableArray array];
    
    while (clazz != NULL) {
        unsigned int methodCount = 0;
        Method *methods = class_copyMethodList(clazz, &methodCount);
        
        for (unsigned int i = 0; i < methodCount; ++i) {
            SEL selector = method_getName(methods[i]);
            if (selector) {
                const char *cstrName = sel_getName(selector);
                if (NULL == cstrName) continue;
                
                NSString *selectorName = [NSString stringWithUTF8String:cstrName];
                if (NULL == selectorName) continue;
                if ([methodNames containsObject:selectorName]) continue;
                
                // 是否是测试方法(前缀test)
                if ([selectorName hasPrefix:@"test"]) {
                    [methodNames addObject:selectorName];
                }
            }
        }
        
        free(methods);
        
        clazz = class_getSuperclass(clazz);
        if (nil == clazz || clazz == [NSObject class]) break;
    }
    
    return methodNames;
}

#pragma mark - NSObject

- (NSString *)debugDescription
{
    return self.testLogs;
}

@end

#pragma mark - Test

@interface FWTestCase_FWTest_Objc : FWTestCase

@property (nonatomic, assign) NSInteger value;

@end

@implementation FWTestCase_FWTest_Objc

- (void)setUp
{
    // 重置资源
    self.value = 0;
}

- (void)tearDown
{
    // 释放资源
}

- (void)testPlus
{
    FWAssertTrue(self.value++ == 0);
    FWAssertTrue(++self.value == 2);
}

- (void)testMinus
{
    FWAssertTrue(self.value-- == 0);
    FWAssertTrue(--self.value == -1);
}

- (void)testThree
{
    FWAssertTrue(self.value-- == 0);
}

@end

#endif
