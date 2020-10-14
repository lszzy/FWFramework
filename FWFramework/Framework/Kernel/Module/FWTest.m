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
        dispatch_async(dispatch_get_main_queue(), ^{
            [[FWUnitTest sharedInstance].testCases addObjectsFromArray:[self testSuite]];
            if ([FWUnitTest sharedInstance].testCases.count > 0) {
                dispatch_queue_t queue = dispatch_queue_create("site.wuyong.FWFramework.FWTestQueue", NULL);
                dispatch_async(queue, ^{
                    [[FWUnitTest sharedInstance] runTests];
                    FWLogDebug(@"%@", [FWUnitTest sharedInstance].debugDescription);
                    FWLogDebug(@"%@", [FWPluginManager sharedInstance].debugDescription);
                });
            }
        });
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

#import "FWPromise.h"
#import "FWCoroutine.h"
#import "FWSwizzle.h"
#import <objc/message.h>

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

#pragma mark - FWPromise

@interface FWTestCase_FWPromise : FWTestCase

@end

@implementation FWTestCase_FWPromise

- (void)testPromise
{
    __block NSNumber *result = nil;
    FWPromise *promise = [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
        dispatch_queue_t queue = dispatch_queue_create("FWTestCase_FWPromise", NULL);
        dispatch_async(queue, ^{
            [NSThread sleepForTimeInterval:0.1];
            resolve(@1);
        });
    }];
    promise.then(^id(NSNumber *value) {
        return [FWPromise resolve:@(value.integerValue + 1)];
    }).done(^(id  _Nullable value) {
        result = value;
    }).finally(^{
        FWAssertTrue(result.integerValue == 2);
    });
    
    result = nil;
    promise = [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
        resolve(@1);
    }];
    promise.then(^id(NSNumber *value) {
        return [FWPromise reject:nil];
    }).then(^id(id value) {
        result = value;
        return nil;
    }).catch(^(id error) {
        result = nil;
    }).finally(^{
        FWAssertTrue(result == nil);
    });
}

- (FWCoroutineClosure)login:(NSString *)account pwd:(NSString *)pwd
{
    return ^(FWCoroutineCallback callback){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if ([account isEqualToString:@"test"] && [pwd isEqualToString:@"123"]) {
                callback(@{@"uid": @"1", @"token": @"token"}, nil);
            } else {
                callback(nil, [NSError errorWithDomain:@"FWTest" code:1 userInfo:nil]);
            }
        });
    };
}

- (FWPromise *)query:(NSString *)uid token:(NSString *)token
{
    return [FWPromise promise:^(FWResolveBlock resolve, FWRejectBlock reject) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if ([uid isEqualToString:@"1"] && [token isEqualToString:@"token"]) {
                resolve(@{@"name": @"test"});
            } else {
                reject([NSError errorWithDomain:@"FWTest" code:2 userInfo:nil]);
            }
        });
    }];
}

- (void)testCoroutine
{
    __block NSInteger value = 0;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    fw_async(^{
        FWResult *result = nil;
        
        result = fw_await([self login:@"test" pwd:@"123"]);
        FWAssertTrue(!result.error);
        
        NSDictionary *user = result.value;
        value = [user[@"uid"] integerValue];
        FWAssertTrue([user[@"uid"] isEqualToString:@"1"]);
        
        result = fw_await([self query:user[@"uid"] token:user[@"token"]]);
        FWAssertTrue(!result.error);
        
        NSDictionary *info = result.value;
        FWAssertTrue([info[@"name"] isEqualToString:@"test"]);
        
        result = fw_await([self login:@"test" pwd:@""]);
        FWAssertTrue(result.error);
    }).finally(^{
        value++;
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    FWAssertTrue(value == 2);
}

@end

#pragma mark - FWSwizzle

@interface FWTestCase_FWRuntime : FWTestCase

@end

@interface FWTestCase_FWRuntime_Person : NSObject

@property (nonatomic, assign) NSInteger count;

@end

@implementation FWTestCase_FWRuntime_Person

- (void)sayHello:(BOOL)value
{
    self.count += 1;
}

- (void)sayHello2:(BOOL)value
{
    self.count += 1;
}

- (void)sayHello3:(BOOL)value
{
    self.count += 1;
}

- (void)sayHello4:(BOOL)value
{
    self.count += 1;
}

@end

@interface FWTestCase_FWRuntime_Student : FWTestCase_FWRuntime_Person

@end

@implementation FWTestCase_FWRuntime_Student

@end

@implementation FWTestCase_FWRuntime_Student (swizzle)

- (void)s_sayHello:(BOOL)value
{
    [self s_sayHello:value];
    self.count += 2;
}

@end

@implementation FWTestCase_FWRuntime_Person (swizzle)

- (void)p_sayHello:(BOOL)value
{
    [self p_sayHello:value];
    self.count += 3;
}

@end

@implementation FWTestCase_FWRuntime

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [FWTestCase_FWRuntime_Student fwSwizzleInstanceMethod:@selector(sayHello:) with:@selector(s_sayHello:)];
        [FWTestCase_FWRuntime_Person fwSwizzleInstanceMethod:@selector(sayHello:) with:@selector(p_sayHello:)];
        
        SEL swizzleSelector1 = [NSObject fwSwizzleSelectorForSelector:@selector(sayHello4:)];
        [FWTestCase_FWRuntime_Student fwSwizzleInstanceMethod:@selector(sayHello4:) with:swizzleSelector1 block:^(__unsafe_unretained FWTestCase_FWRuntime_Student *selfObject, BOOL value){
            ((void(*)(id, SEL, BOOL))objc_msgSend)(selfObject, swizzleSelector1, value);
            selfObject.count += 2;
        }];
        SEL swizzleSelector2 = [NSObject fwSwizzleSelectorForSelector:@selector(sayHello4:)];
        [FWTestCase_FWRuntime_Person fwSwizzleInstanceMethod:@selector(sayHello4:) with:swizzleSelector2 block:^(__unsafe_unretained FWTestCase_FWRuntime_Person *selfObject, BOOL value){
            ((void(*)(id, SEL, BOOL))objc_msgSend)(selfObject, swizzleSelector2, value);
            selfObject.count += 3;
        }];
        
        Class studentClass = [FWTestCase_FWRuntime_Student class];
        FWSwizzleClass(FWTestCase_FWRuntime_Student, @selector(sayHello3:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL value), FWSwizzleCode({
            FWSwizzleOriginal(value);
            
            // 防止父类子类重复调用
            BOOL isSelf = (studentClass == [selfObject class]);
            if (isSelf) {
                selfObject.count += 2;
            }
        }));
        
        [NSObject fwSwizzleClass:[FWTestCase_FWRuntime_Person class] selector:@selector(sayHello3:) identifier:@"Test" withBlock:^id _Nonnull(__unsafe_unretained Class  _Nonnull targetClass, SEL  _Nonnull originalCMD, IMP  _Nonnull (^ _Nonnull originalIMP)(void)) {
            return ^(__unsafe_unretained FWTestCase_FWRuntime_Person *selfObject, BOOL value) {
                void (*originalMSG)(id, SEL, BOOL) = (void (*)(id, SEL, BOOL))originalIMP();
                originalMSG(selfObject, originalCMD, value);
                selfObject.count += 3;
            };
        }];
    });
}

- (void)testMethod
{
    FWTestCase_FWRuntime_Student *student = [FWTestCase_FWRuntime_Student new];
    [student sayHello:YES];
    FWAssertTrue(student.count == 3);
    
    student = [FWTestCase_FWRuntime_Student new];
    [student sayHello4:YES];
    FWAssertTrue(student.count == 3);
}

- (void)testBlock
{
    FWTestCase_FWRuntime_Student *student = [FWTestCase_FWRuntime_Student new];
    [student sayHello3:YES];
    FWAssertTrue(student.count == 6);
}

- (void)testObject
{
    FWTestCase_FWRuntime_Student *student = [FWTestCase_FWRuntime_Student new];
    [student sayHello2:YES];
    FWAssertTrue(student.count == 1);
    
    student = [FWTestCase_FWRuntime_Student new];
    FWSwizzleMethod(student, @selector(sayHello2:), @"s_sayHello2:", FWSwizzleType(FWTestCase_FWRuntime_Student *), FWSwizzleReturn(void), FWSwizzleArgs(BOOL value), FWSwizzleCode({
        ((void (*)(id, SEL, BOOL))originalIMP())(selfObject, originalCMD, value);
        
        // 防止影响其它对象
        if (![selfObject fwIsSwizzleMethod:@selector(sayHello2:) identifier:@"s_sayHello2:"]) return;
        selfObject.count += 2;
    }));
    [student fwSwizzleMethod:@selector(sayHello2:) identifier:@"p_sayHello2:" withBlock:^id _Nonnull(__unsafe_unretained Class  _Nonnull targetClass, SEL  _Nonnull originalCMD, IMP  _Nonnull (^ _Nonnull originalIMP)(void)) {
        return FWSwizzleBlock(FWSwizzleType(FWTestCase_FWRuntime_Person *), FWSwizzleReturn(void), FWSwizzleArgs(BOOL value), FWSwizzleCode({
            originalMSG(selfObject, originalCMD, value);
            
            if (![selfObject fwIsSwizzleMethod:@selector(sayHello2:) identifier:@"p_sayHello2:"]) return;
            selfObject.count += 3;
        }));
    }];
    [student sayHello2:YES];
    FWAssertTrue(student.count == 6);
    
    student = [FWTestCase_FWRuntime_Student new];
    [student sayHello2:YES];
    FWAssertTrue(student.count == 1);
}

@end

#endif
