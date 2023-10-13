//
//  ObjC.h
//  FWFramework
//
//  Created by wuyong on 2023/8/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define FWLogDebug( aFormat, ... ) \
    [FWObjCBridge logDebug:[NSString stringWithFormat:(@"(%@ %@ #%d %s) " aFormat), NSThread.isMainThread ? @"[M]" : @"[T]", [@(__FILE__) lastPathComponent], __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__]];

#pragma mark - WeakProxyBridge

/// 弱引用代理类，用于解决NSTimer等循环引用target问题(默认NSTimer会强引用target,直到invalidate)
NS_SWIFT_NAME(WeakProxyBridge)
@interface FWWeakProxyBridge : NSProxy

@property (nonatomic, weak, readonly, nullable) id target;

- (instancetype)initWithTarget:(nullable id)target;

@end

#pragma mark - DelegateProxyBridge

/// 事件协议代理基类，可继承重写事件代理方法
NS_SWIFT_NAME(DelegateProxyBridge)
@interface FWDelegateProxyBridge : NSObject

@property (nonatomic, weak, nullable) id target;

@end

#pragma mark - UnsafeObjectBridge

/// 非安全对象类，不同于weak和deinit，自动释放时仍可访问object，可用于自动解绑、释放监听等场景
NS_SWIFT_NAME(UnsafeObjectBridge)
@interface FWUnsafeObjectBridge : NSObject

@property (nonatomic, unsafe_unretained, nullable) id object;

- (void)deallocObject;

@end

#pragma mark - ObjCBridge

/// ObjC桥接协议，Swift扩展实现桥接协议即可
NS_SWIFT_NAME(ObjCBridgeProtocol)
@protocol FWObjCBridgeProtocol <NSObject>
@optional

+ (void)autoload;
+ (void)log:(NSString *)message;

@end

/// ObjC桥接类，用于桥接Swift不支持的ObjC特性
NS_SWIFT_NAME(ObjCBridge)
@interface FWObjCBridge : NSObject

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

+ (void)logDebug:(NSString *)message;

+ (BOOL)tryCatch:(void (NS_NOESCAPE ^)(void))block exceptionHandler:(nullable void (^)(NSException *exception))exceptionHandler;

+ (void)captureExceptions:(NSArray<Class> *)captureClasses exceptionHandler:(nullable void (^)(NSException *exception, Class clazz, SEL selector, NSString *file, NSInteger line))exceptionHandler;

+ (nullable UIImage *)svgDecode:(NSData *)data thumbnailSize:(CGSize)thumbnailSize;

+ (nullable NSData *)svgEncode:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
