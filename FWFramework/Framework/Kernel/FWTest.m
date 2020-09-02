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
#import "FWPlugin.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#ifdef DEBUG

#pragma mark - FWTestCase

@interface FWTestCase ()

@property (nonatomic, strong) NSError *assertError;

@end

@implementation FWTestCase

- (void)setUp
{
    // 执行初始化
}

- (void)tearDown
{
    // 执行清理
}

- (void)assertTrue:(BOOL)value expression:(NSString *)expression file:(NSString *)file line:(NSInteger)line
{
    // 断言成功
    if (value) return;
    
    // 断言失败
    NSDictionary *userInfo = @{
                               @"expression": (expression ?: @""),
                               @"file": (file ? file.lastPathComponent : @""),
                               @"line": @(line),
                               };
    self.assertError = [NSError errorWithDomain:@"FWFramework" code:0 userInfo:userInfo];
}

@end

#pragma mark - FWUnitTest

@interface FWUnitTest : NSObject

@property (nonatomic, strong) NSMutableArray<Class> *testCases;
@property (nonatomic, strong) NSString *testLogs;

@end

@implementation FWUnitTest

#pragma mark - Static

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 监听应用启动完成通知，自动异步执行框架单元测试并打印结果
        static id testRunner = nil;
        testRunner = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
            [[NSNotificationCenter defaultCenter] removeObserver:testRunner];
            testRunner = nil;
            
            [[FWUnitTest sharedInstance].testCases addObjectsFromArray:[self testSuite]];
            if ([FWUnitTest sharedInstance].testCases.count > 0) {
                dispatch_queue_t queue = dispatch_queue_create("site.wuyong.FWFramework.FWTestQueue", NULL);
                dispatch_async(queue, ^{
                    [[FWUnitTest sharedInstance] runTests];
                    FWLogDebug(@"%@", [FWUnitTest sharedInstance].debugDescription);
                    FWLogDebug(@"%@", [FWPluginManager sharedInstance].debugDescription);
                });
            }
        }];
    });
}

+ (NSArray<Class> *)testSuite
{
    NSMutableArray *testCases = [[NSMutableArray alloc] init];
    
    unsigned int classesCount = 0;
    Class *classes = objc_copyClassList(&classesCount);
    Class testClass = [FWTestCase class], objectClass = [NSObject class];
    Class classType = Nil, superClass = Nil;
    for (unsigned int i = 0; i < classesCount; ++i) {
        classType = classes[i];
        superClass = class_getSuperclass(classType);
        while (superClass && superClass != objectClass) {
            if (superClass == testClass) {
                [testCases addObject:classType];
                break;
            }
            superClass = class_getSuperclass(superClass);
        }
    }
    free(classes);
    
    [testCases sortUsingComparator:^NSComparisonResult(Class obj1, Class obj2) {
        return [NSStringFromClass(obj1) compare:NSStringFromClass(obj2)];
    }];
    return testCases;
}

+ (NSArray *)testMethods:(Class)clazz
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

#pragma mark - Lifecycle

+ (FWUnitTest *)sharedInstance
{
    static FWUnitTest *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWUnitTest alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.testCases = [NSMutableArray array];
    }
    return self;
}

- (NSString *)debugDescription
{
    return self.testLogs;
}

- (void)runTests
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
        
        NSString *formatClass = [NSStringFromClass(classType) stringByReplacingOccurrencesOfString:@"FWTestCase_" withString:@""];
        formatClass = [formatClass stringByReplacingOccurrencesOfString:@"_" withString:@"."];
        NSString *formatMethod = nil;
        NSString *formatError = nil;
        
        NSArray *selectorNames = [self.class testMethods:classType];
        BOOL testCasePassed = YES;
        NSUInteger totalTestCount = selectorNames.count;
        NSUInteger currentTestCount = 0;
        
        NSError *assertError = nil;
        if (selectorNames && selectorNames.count > 0) {
            // 执行初始化，同一个对象
            FWTestCase *testCase = [[classType alloc] init];
            for (NSString *selectorName in selectorNames) {
                currentTestCount++;
                formatMethod = selectorName;
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
                    
                    // 如果失败，当前类测试结束
                    assertError = testCase.assertError;
                    if (assertError) {
                        break;
                    }
                }
            }
        }
        
        if (assertError) {
            NSDictionary *userInfo = assertError.userInfo;
            formatError = [NSString stringWithFormat:@"- assertTrue ( %@ ); ( %@ - %@ #%@ )", [userInfo[@"expression"] length] > 0 ? userInfo[@"expression"] : @"false", formatMethod, userInfo[@"file"], userInfo[@"line"]];
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

- (void)testSync
{
    FWAssertTrue(self.value++ == 0);
    FWAssertTrue(++self.value == 2);
}

- (void)testAsync
{
    __block NSInteger result = 0;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_queue_t queue = dispatch_queue_create("FWTestCase_FWTest_Objc", NULL);
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:0.1];
        result = 1;
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    FWAssertTrue(self.value + result == 1);
}

@end

#endif
