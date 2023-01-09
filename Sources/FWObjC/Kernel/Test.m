//
//  Test.m
//  FWFramework
//
//  Created by wuyong on 2022/8/20.
//

#import "Test.h"
#import <objc/runtime.h>

#if FWMacroSPM

@interface NSObject ()

+ (NSArray<NSString *> *)__fw_classMethods:(Class)clazz superclass:(BOOL)superclass;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#define __FWLogGroup( aGroup, aType, aFormat, ... ) \
    if ([__FWLogger check:aType]) [__FWLogger log:aType message:[NSString stringWithFormat:(@"(%@ %@ #%d %s) " aFormat), NSThread.isMainThread ? @"[M]" : @"[T]", [@(__FILE__) lastPathComponent], __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__] group:aGroup userInfo:nil];

#ifdef DEBUG

#pragma mark - __FWTestCase

@interface __FWTestCase ()

@property (nonatomic, strong) NSError *assertError;
@property (nonatomic, assign) BOOL isAssertAsync;
@property (nonatomic, strong) dispatch_semaphore_t assertSemaphore;

@end

@implementation __FWTestCase

- (void)setUp
{
    // 执行初始化
}

- (void)tearDown
{
    // 执行清理
}

#pragma mark - Sync

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
    self.assertError = [NSError errorWithDomain:@"FWTest" code:0 userInfo:userInfo];
    self.isAssertAsync = NO;
}

#pragma mark - Async

- (void)assertBegin
{
    self.assertSemaphore = dispatch_semaphore_create(0);
}

- (void)assertEnd
{
    if (self.assertSemaphore) dispatch_semaphore_wait(self.assertSemaphore, DISPATCH_TIME_FOREVER);
}

- (void)assertAsync:(BOOL)value expression:(NSString *)expression file:(NSString *)file line:(NSInteger)line
{
    [self assertTrue:value expression:expression file:file line:line];
    self.isAssertAsync = YES;
    if (self.assertSemaphore) dispatch_semaphore_signal(self.assertSemaphore);
}

@end

#pragma mark - __FWUnitTest

@interface __FWUnitTest : NSObject

@property (nonatomic, strong) NSMutableArray<Class> *testCases;
@property (nonatomic, strong) NSString *testLogs;

@end

@implementation __FWUnitTest

#pragma mark - Static

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[__FWUnitTest sharedInstance].testCases addObjectsFromArray:[self testSuite]];
            if ([__FWUnitTest sharedInstance].testCases.count > 0) {
                dispatch_queue_t queue = dispatch_queue_create("site.wuyong.queue.test.async", NULL);
                dispatch_async(queue, ^{
                    [[__FWUnitTest sharedInstance] runTests];
                    __FWLogGroup(@"FWFramework", __FWLogTypeDebug, @"%@", __FWUnitTest.debugDescription);
                });
            }
        });
    });
}

+ (NSString *)debugDescription
{
    if ([__FWUnitTest sharedInstance].testLogs) {
        return [__FWUnitTest sharedInstance].testLogs;
    }
    return [super debugDescription];
}

+ (NSArray<Class> *)testSuite
{
    NSMutableArray *testCases = [[NSMutableArray alloc] init];
    unsigned int classesCount = 0;
    Class *classes = objc_copyClassList(&classesCount);
    Class testClass = [__FWTestCase class], objectClass = [NSObject class];
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
    NSArray *selectorNames = [NSObject __fw_classMethods:clazz superclass:YES];
    for (NSString *selectorName in selectorNames) {
        if ([selectorName hasPrefix:@"test"] && ![selectorName containsString:@":"]) {
            [methodNames addObject:selectorName];
        }
    }
    return methodNames;
}

#pragma mark - Lifecycle

+ (__FWUnitTest *)sharedInstance
{
    static __FWUnitTest *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[__FWUnitTest alloc] init];
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
        
        NSString *formatClass = [NSStringFromClass(classType) stringByReplacingOccurrencesOfString:@"__FWTestCase_" withString:@""];
        formatClass = [formatClass stringByReplacingOccurrencesOfString:@"TestCase_" withString:@""];
        formatClass = [formatClass stringByReplacingOccurrencesOfString:@"TestCase" withString:@""];
        formatClass = [formatClass stringByReplacingOccurrencesOfString:@"_" withString:@"."];
        NSString *formatMethod = nil;
        NSString *formatError = nil;
        
        NSArray *selectorNames = [self.class testMethods:classType];
        BOOL testCasePassed = YES;
        NSUInteger totalTestCount = selectorNames.count;
        NSUInteger currentTestCount = 0;
        
        NSError *assertError = nil;
        BOOL assertAsync = NO;
        if (selectorNames && selectorNames.count > 0) {
            // 执行初始化，同一个对象
            __FWTestCase *testCase = [[classType alloc] init];
            for (NSString *selectorName in selectorNames) {
                currentTestCount++;
                formatMethod = selectorName;
                SEL selector = NSSelectorFromString(selectorName);
                if (selector && [testCase respondsToSelector:selector]) {
                    // 依次执行setUp|test|tearDown
                    [testCase setUp];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    [testCase performSelector:selector];
#pragma clang diagnostic pop
                    [testCase tearDown];
                    
                    // 如果失败，当前类测试结束
                    assertError = testCase.assertError;
                    assertAsync = testCase.isAssertAsync;
                    if (assertError) {
                        break;
                    }
                }
            }
        }
        
        if (assertError) {
            NSDictionary *userInfo = assertError.userInfo;
            formatError = [NSString stringWithFormat:@"- assert%@(%@); (%@ - %@ #%@)", assertAsync ? @"Async" : @"True", [userInfo[@"expression"] length] > 0 ? userInfo[@"expression"] : @"false", formatMethod, userInfo[@"file"], userInfo[@"line"]];
            testCasePassed = NO;
        }
        
        NSTimeInterval time2 = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval time = time2 - time1;
        NSUInteger succeedTestCount = testCasePassed ? currentTestCount : (currentTestCount - 1);
        float classPassRate = totalTestCount > 0 ? (succeedTestCount * 1.0f) / (totalTestCount * 1.0f) * 100.0f : 100.0f;
        
        if ( testCasePassed ) {
            succeedCount += 1;
            [testLog appendFormat:@"%@. %@: %@ (%lu/%lu) (%.0f%%) (%.003fs)\n", @(succeedCount + failedCount), @"✔️", formatClass, (unsigned long)succeedTestCount, (unsigned long)totalTestCount, classPassRate, time];
        } else {
            failedCount += 1;
            [testLog appendFormat:@"%@. %@: %@ (%lu/%lu) (%.0f%%) (%.003fs)\n", @(succeedCount + failedCount), @"❌", formatClass, (unsigned long)succeedTestCount, (unsigned long)totalTestCount, classPassRate, time];
            [testLog appendFormat:@"     %@\n", formatError];
        }
    }
    
    // 计算统计数据
    NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval totalTime = endTime - beginTime;
    NSUInteger totalCount = succeedCount + failedCount;
    float passRate = totalCount > 0 ? (succeedCount * 1.0f) / (totalCount * 1.0f) * 100.0f : 100.0f;
    
    // 生成测试日志
    NSString *totalLog = [NSString stringWithFormat:@"   %@: (%lu/%lu) (%.0f%%) (%.003fs)\n", failedCount < 1 ? @"✔️" : @"❌", (unsigned long)succeedCount, (unsigned long)totalCount, passRate, totalTime];
    self.testLogs = [NSString stringWithFormat:@"\n========== TEST  ==========\n%@%@========== TEST  ==========", testLog, totalCount > 0 ? totalLog : @""];
}

@end

#endif
