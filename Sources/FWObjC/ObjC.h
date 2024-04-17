//
//  ObjC.h
//  FWFramework
//
//  Created by wuyong on 2023/8/11.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// ObjC桥接类，用于桥接Swift不支持的ObjC特性
NS_SWIFT_NAME(ObjCBridge)
@interface FWObjCBridge : NSObject

+ (BOOL)swizzleInstanceMethod:(Class)originalClass selector:(SEL)originalSelector withBlock:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;

+ (BOOL)swizzleInstanceMethod:(Class)originalClass selector:(SEL)originalSelector identifier:(nullable NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;

+ (nullable id)invokeMethod:(id)target selector:(SEL)aSelector objects:(NSArray *)objects;

+ (BOOL)invokeMethod:(id)target selector:(SEL)selector arguments:(nullable NSArray *)arguments returnValue:(void *)result;

+ (id)appearanceForClass:(Class)aClass;

+ (Class)classForAppearance:(id)appearance;

+ (void)applyAppearance:(NSObject *)object;

+ (void)captureExceptions:(NSArray<Class> *)captureClasses exceptionHandler:(nullable void (^)(NSException *exception, Class clazz, SEL selector, NSString *file, NSInteger line))exceptionHandler;

@end

NS_ASSUME_NONNULL_END
