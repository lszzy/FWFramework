//
//  ObjC.h
//  FWFramework
//
//  Created by wuyong on 2023/8/11.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWAutoloader

/// Swift自动加载器，扩展实现objc静态autoload方法即可自动调用
@interface __FWAutoloader : NSObject

@end

#pragma mark - __FWWeakProxy

/// 弱引用代理类，用于解决NSTimer等循环引用target问题(默认NSTimer会强引用target,直到invalidate)
@interface __FWWeakProxy : NSProxy

@property (nonatomic, weak, readonly, nullable) id target;

- (instancetype)initWithTarget:(nullable id)target;

@end

#pragma mark - __FWDelegateProxy

/// 事件协议代理基类，可继承重写事件代理方法
@interface __FWDelegateProxy : NSObject

@property (nonatomic, weak, nullable) id target;

@end

#pragma mark - __FWUnsafeObject

/// 非安全对象类，不同于weak和deinit，自动释放时仍可访问object，可用于自动解绑、释放监听等场景
@interface __FWUnsafeObject : NSObject

@property (nonatomic, unsafe_unretained, nullable) id object;

- (void)deallocObject;

@end

#pragma mark - __FWObjC

/// ObjC桥接类，用于桥接Swift不支持的ObjC特性方法
@interface __FWObjC : NSObject

+ (nullable id)getAssociatedObject:(id)object forName:(NSString *)name;

+ (void)setAssociatedObject:(id)object value:(nullable id)value policy:(objc_AssociationPolicy)policy forName:(NSString *)name;

+ (BOOL)swizzleInstanceMethod:(Class)originalClass selector:(SEL)originalSelector withBlock:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;

+ (BOOL)swizzleInstanceMethod:(Class)originalClass selector:(SEL)originalSelector identifier:(nullable NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;

+ (BOOL)swizzleDeallocMethod:(Class)originalClass identifier:(nullable NSString *)identifier withBlock:(void (^)(__kindof NSObject *__unsafe_unretained object))block;

+ (BOOL)exchangeInstanceMethod:(Class)originalClass originalSelector:(SEL)originalSelector swizzleSelector:(SEL)swizzleSelector;

+ (BOOL)exchangeInstanceMethod:(Class)originalClass originalSelector:(SEL)originalSelector swizzleSelector:(SEL)swizzleSelector withBlock:(id)swizzleBlock;

+ (nullable id)invokeMethod:(id)target selector:(SEL)aSelector;

+ (nullable id)invokeMethod:(id)target selector:(SEL)aSelector object:(nullable id)object;

+ (nullable id)invokeMethod:(id)target selector:(SEL)aSelector object:(nullable id)object1 object:(nullable id)object2;

+ (nullable id)invokeMethod:(id)target selector:(SEL)aSelector objects:(NSArray *)objects;

+ (BOOL)invokeMethod:(id)target selector:(SEL)selector arguments:(nullable NSArray *)arguments returnValue:(void *)result;

+ (nullable id)invokeGetter:(id)target name:(NSString *)name;

+ (nullable id)invokeSetter:(id)target name:(NSString *)name object:(nullable id)object;

+ (id)appearanceForClass:(Class)aClass;

+ (Class)classForAppearance:(id)appearance;

+ (void)applyAppearance:(NSObject *)object;

+ (NSArray<Class> *)getClasses:(Class)superClass;

+ (void)logMessage:(NSString *)message;

+ (BOOL)isEqual:(nullable id)obj1 withObject:(nullable id)obj2;

@end

NS_ASSUME_NONNULL_END
