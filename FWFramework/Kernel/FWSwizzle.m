/*!
 @header     FWSwizzle.m
 @indexgroup FWFramework
 @brief      FWSwizzle
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/6/5
 */

#import "FWSwizzle.h"
#import <objc/runtime.h>

@implementation NSObject (FWSwizzle)

#pragma mark - Simple

+ (BOOL)fwSwizzleInstanceMethod:(SEL)originalSelector with:(SEL)swizzleSelector
{
    Method originalMethod = class_getInstanceMethod(self, originalSelector);
    Method swizzleMethod = class_getInstanceMethod(self, swizzleSelector);
    if (!swizzleMethod) {
        return NO;
    }
    
    if (originalMethod) {
        class_addMethod(self, originalSelector, class_getMethodImplementation(self, originalSelector), method_getTypeEncoding(originalMethod));
    } else {
        class_addMethod(self, originalSelector, imp_implementationWithBlock(^(id selfObject){}), "v@:");
    }
    class_addMethod(self, swizzleSelector, class_getMethodImplementation(self, swizzleSelector), method_getTypeEncoding(swizzleMethod));
    
    method_exchangeImplementations(class_getInstanceMethod(self, originalSelector), class_getInstanceMethod(self, swizzleSelector));
    return YES;
}

+ (BOOL)fwSwizzleClassMethod:(SEL)originalSelector with:(SEL)swizzleSelector
{
    return [object_getClass((id)self) fwSwizzleInstanceMethod:originalSelector with:swizzleSelector];
}

+ (BOOL)fwSwizzleInstanceMethod:(SEL)originalSelector with:(SEL)swizzleSelector block:(id)swizzleBlock
{
    Method originalMethod = class_getInstanceMethod(self, originalSelector);
    Method swizzleMethod = class_getInstanceMethod(self, swizzleSelector);
    if (!originalMethod || swizzleMethod) return NO;
    
    class_addMethod(self, originalSelector, class_getMethodImplementation(self, originalSelector), method_getTypeEncoding(originalMethod));
    class_addMethod(self, swizzleSelector, imp_implementationWithBlock(swizzleBlock), method_getTypeEncoding(originalMethod));
    method_exchangeImplementations(class_getInstanceMethod(self, originalSelector), class_getInstanceMethod(self, swizzleSelector));
    return YES;
}

+ (BOOL)fwSwizzleClassMethod:(SEL)originalSelector with:(SEL)swizzleSelector block:(id)swizzleBlock
{
    return [object_getClass((id)self) fwSwizzleInstanceMethod:originalSelector with:swizzleSelector block:swizzleBlock];
}

+ (SEL)fwSwizzleSelectorForSelector:(SEL)selector
{
    return NSSelectorFromString([NSString stringWithFormat:@"fw_swizzle_%x_%@", arc4random(), NSStringFromSelector(selector)]);
}

#pragma mark - Complex

+ (BOOL)fwSwizzleMethod:(id)target selector:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
{
    if (!target) return NO;
    
    if (object_isClass(target)) {
        if (identifier && identifier.length > 0) {
            return [self fwSwizzleClass:target selector:originalSelector identifier:identifier withBlock:block];
        } else {
            return [self fwSwizzleClass:target selector:originalSelector withBlock:block];
        }
    } else {
        return [target fwSwizzleMethod:originalSelector identifier:identifier withBlock:block];
    }
}

+ (BOOL)fwSwizzleClass:(Class)originalClass selector:(SEL)originalSelector withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
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

+ (BOOL)fwSwizzleClass:(Class)originalClass selector:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
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
            return [self fwSwizzleClass:originalClass selector:originalSelector withBlock:block];
        }
        return NO;
    }
}

- (BOOL)fwSwizzleMethod:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class, SEL, IMP (^)(void)))block
{
    NSString *swizzleIdentifier = [NSString stringWithFormat:@"%@-%@-%@", NSStringFromClass(object_getClass(self)), NSStringFromSelector(originalSelector), identifier];
    objc_setAssociatedObject(self, NSSelectorFromString(swizzleIdentifier), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return [NSObject fwSwizzleClass:object_getClass(self) selector:originalSelector identifier:identifier withBlock:block];
}

- (BOOL)fwIsSwizzleMethod:(SEL)originalSelector identifier:(NSString *)identifier
{
    NSString *swizzleIdentifier = [NSString stringWithFormat:@"%@-%@-%@", NSStringFromClass(object_getClass(self)), NSStringFromSelector(originalSelector), identifier];
    return [objc_getAssociatedObject(self, NSSelectorFromString(swizzleIdentifier)) boolValue];
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
