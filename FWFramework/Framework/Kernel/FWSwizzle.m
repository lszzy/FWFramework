/*!
 @header     FWSwizzle.m
 @indexgroup FWFramework
 @brief      FWSwizzle
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/6/4
 */

#import "FWSwizzle.h"
#import <objc/runtime.h>

@implementation FWSwizzle

+ (BOOL)swizzleMethod:(id)target selector:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
{
    if (!target) return NO;
    
    if (object_isClass(target)) {
        if (identifier && identifier.length > 0) {
            return [self swizzleClass:target selector:originalSelector identifier:identifier withBlock:block];
        } else {
            return [self swizzleClass:target selector:originalSelector withBlock:block];
        }
    } else {
        return [self swizzleObject:target selector:originalSelector identifier:identifier withBlock:block];
    }
}

+ (BOOL)swizzleClass:(Class)originalClass selector:(SEL)originalSelector withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
{
    if (!originalClass) return NO;
    
    Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    IMP imp = method_getImplementation(originalMethod);
    BOOL isOverride = NO;
    if (originalMethod) {
        Method superclassMethod = class_getInstanceMethod(class_getSuperclass(originalClass), originalSelector);
        if (!superclassMethod) {
            isOverride = YES;
        } else {
            isOverride = (originalMethod != superclassMethod);
        }
    }
    
    IMP (^originalIMP)(void) = ^IMP(void) {
        IMP result = NULL;
        if (isOverride) {
            result = imp;
        } else {
            Class superclass = class_getSuperclass(originalClass);
            result = class_getMethodImplementation(superclass, originalSelector);
        }
        if (!result) {
            result = imp_implementationWithBlock(^(id selfObject){});
        }
        return result;
    };
    
    if (isOverride) {
        method_setImplementation(originalMethod, imp_implementationWithBlock(block(originalClass, originalSelector, originalIMP)));
    } else {
        const char *typeEncoding = method_getTypeEncoding(originalMethod);
        if (!typeEncoding) {
            NSMethodSignature *methodSignature = [originalClass instanceMethodSignatureForSelector:originalSelector];
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            SEL typeSelector = NSSelectorFromString([NSString stringWithFormat:@"_%@String", @"type"]);
            NSString *typeString = [methodSignature respondsToSelector:typeSelector] ? [methodSignature performSelector:typeSelector] : nil;
            #pragma clang diagnostic pop
            typeEncoding = typeString.UTF8String;
        }
        
        class_addMethod(originalClass, originalSelector, imp_implementationWithBlock(block(originalClass, originalSelector, originalIMP)), typeEncoding);
    }
    return YES;
}

+ (BOOL)swizzleClass:(Class)originalClass selector:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
{
    if (!originalClass) return NO;
    
    static NSMutableSet *swizzleIdentifiers;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        swizzleIdentifiers = [NSMutableSet new];
    });
    
    @synchronized (swizzleIdentifiers) {
        NSString *swizzleIdentifier = [NSString stringWithFormat:@"%@-%@-%@", NSStringFromClass(originalClass), NSStringFromSelector(originalSelector), identifier];
        if (![swizzleIdentifiers containsObject:swizzleIdentifier]) {
            [swizzleIdentifiers addObject:swizzleIdentifier];
            return [self swizzleClass:originalClass selector:originalSelector withBlock:block];
        }
        return NO;
    }
}

+ (BOOL)swizzleObject:(id)object selector:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
{
    if (!object) return NO;
    
    NSString *swizzleIdentifier = [NSString stringWithFormat:@"%@-%@-%@", NSStringFromClass(object_getClass(object)), NSStringFromSelector(originalSelector), identifier];
    objc_setAssociatedObject(object, NSSelectorFromString(swizzleIdentifier), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return [self swizzleClass:object_getClass(object) selector:originalSelector identifier:identifier withBlock:block];
}

+ (BOOL)isSwizzleObject:(id)object selector:(SEL)originalSelector identifier:(NSString *)identifier
{
    if (!object) return NO;
    
    NSString *swizzleIdentifier = [NSString stringWithFormat:@"%@-%@-%@", NSStringFromClass(object_getClass(object)), NSStringFromSelector(originalSelector), identifier];
    return [objc_getAssociatedObject(object, NSSelectorFromString(swizzleIdentifier)) boolValue];
}

@end

#ifdef DEBUG

#pragma mark - Test

#import "FWTest.h"
#import "NSObject+FWRuntime.h"
#import <objc/message.h>

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
        [FWTestCase_FWRuntime_Student fwSwizzleInstanceMethod:@selector(sayHello4:) with:swizzleSelector1 block:^(FWTestCase_FWRuntime_Student *selfObject, BOOL value){
            ((void(*)(id, SEL, BOOL))objc_msgSend)(selfObject, swizzleSelector1, value);
            selfObject.count += 2;
        }];
        SEL swizzleSelector2 = [NSObject fwSwizzleSelectorForSelector:@selector(sayHello4:)];
        [FWTestCase_FWRuntime_Person fwSwizzleInstanceMethod:@selector(sayHello4:) with:swizzleSelector2 block:^(FWTestCase_FWRuntime_Person *selfObject, BOOL value){
            ((void(*)(id, SEL, BOOL))objc_msgSend)(selfObject, swizzleSelector2, value);
            selfObject.count += 3;
        }];
        
        Class studentClass = [FWTestCase_FWRuntime_Student class];
        [FWSwizzle swizzleClass:studentClass selector:@selector(sayHello3:) withBlock:^id _Nonnull(__unsafe_unretained Class  _Nonnull targetClass, SEL  _Nonnull originalCMD, IMP  _Nonnull (^ _Nonnull originalIMP)(void)) {
            return ^(FWTestCase_FWRuntime_Student *selfObject, BOOL value) {
                void (*originalMSG)(id, SEL, BOOL);
                originalMSG = (void (*)(id, SEL, BOOL value))originalIMP();
                originalMSG(selfObject, originalCMD, value);
                
                // 防止父类子类重复调用
                BOOL isSelf = (studentClass == [selfObject class]);
                if (isSelf) {
                    selfObject.count += 2;
                }
            };
        }];
        
        [FWSwizzle swizzleClass:[FWTestCase_FWRuntime_Person class] selector:@selector(sayHello3:) identifier:@"Test" withBlock:^id _Nonnull(__unsafe_unretained Class  _Nonnull targetClass, SEL  _Nonnull originalCMD, IMP  _Nonnull (^ _Nonnull originalIMP)(void)) {
            return ^(FWTestCase_FWRuntime_Person *selfObject, BOOL value) {
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
    [FWSwizzle swizzleObject:student selector:@selector(sayHello2:) identifier:@"s_sayHello2:" withBlock:^id _Nonnull(__unsafe_unretained Class  _Nonnull targetClass, SEL  _Nonnull originalCMD, IMP  _Nonnull (^ _Nonnull originalIMP)(void)) {
        return ^(FWTestCase_FWRuntime_Student *selfObject, BOOL value) {
            ((void (*)(id, SEL, BOOL))originalIMP())(selfObject, originalCMD, value);
            
            // 防止影响其它对象
            if (![FWSwizzle isSwizzleObject:selfObject selector:@selector(sayHello2:) identifier:@"s_sayHello2:"]) return;
            selfObject.count += 2;
        };
    }];
    [FWSwizzle swizzleObject:student selector:@selector(sayHello2:) identifier:@"p_sayHello2:" withBlock:^id _Nonnull(__unsafe_unretained Class  _Nonnull targetClass, SEL  _Nonnull originalCMD, IMP  _Nonnull (^ _Nonnull originalIMP)(void)) {
        return ^(FWTestCase_FWRuntime_Person *selfObject, BOOL value) {
            ((void (*)(id, SEL, BOOL))originalIMP())(selfObject, originalCMD, value);
            
            if (![FWSwizzle isSwizzleObject:selfObject selector:@selector(sayHello2:) identifier:@"p_sayHello2:"]) return;
            selfObject.count += 3;
        };
    }];
    [student sayHello2:YES];
    FWAssertTrue(student.count == 6);
    
    student = [FWTestCase_FWRuntime_Student new];
    [student sayHello2:YES];
    FWAssertTrue(student.count == 1);
}

@end

#endif
