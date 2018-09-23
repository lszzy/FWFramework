/*!
 @header     FWTest.m
 @indexgroup FWFramework
 @brief      单元测试
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-11
 */

#import "FWTest.h"
#import "FWPlugin.h"
#import "FWLog.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

#if FW_TEST

#pragma mark - FWTestCase

@implementation FWTestCase

- (void)setUp
{
}

- (void)tearDown
{
}

- (void)assert:(BOOL)value
{
    [self assert:value userInfo:nil];
}

- (void)assert:(BOOL)value expr:(const char *)expr file:(const char *)file line:(int)line
{
    [self assert:value userInfo:@{@"expr":@(expr), @"file":[@(file) lastPathComponent], @"line":@(line)}];
}

- (void)assert:(BOOL)value userInfo:(NSDictionary *)userInfo
{
    if (!value) {
        @throw [NSException exceptionWithName:@"FWFramework" reason:@"Assertion failed" userInfo:userInfo];
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
            
            // 执行框架单元测试
            if ([FWUnitTest sharedInstance].testCases.count > 0) {
                [[FWUnitTest sharedInstance] run];
                
                // 打印测试结果及插件
                FWLogDebug(@"%@", [FWUnitTest sharedInstance].debugDescription);
                FWLogDebug(@"%@", [FWPluginManager sharedInstance].debugDescription);
            }
        });
    }];
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
        NSString *formatClass = [className stringByReplacingOccurrencesOfString:@"FWTestCase____" withString:@""];
        formatClass = [formatClass stringByReplacingOccurrencesOfString:@"____" withString:@"."];
        NSString *formatMethod = nil;
        NSString *formatError = nil;
        
        NSArray *selectorNames = [self testMethods:classType];
        BOOL testCasePassed = YES;
        NSUInteger totalTestCount = selectorNames.count;
        NSUInteger currentTestCount = 0;
        
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
                    }
                }
            }
        } @catch (NSException *e) {
            NSDictionary *userInfo = e.userInfo && [e.userInfo objectForKey:@"expr"] ? e.userInfo : nil;
            if (userInfo) {
                formatError = [NSString stringWithFormat:@"- ASSERT ( %@ ); ( %@ - %@ #%@ )", [userInfo objectForKey:@"expr"], formatMethod, [userInfo objectForKey:@"file"], [userInfo objectForKey:@"line"]];
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

#endif
