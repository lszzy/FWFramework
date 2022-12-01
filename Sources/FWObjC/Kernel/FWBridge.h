//
//  FWBridge.h
//  FWFramework
//
//  Created by wuyong on 2022/11/11.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __Autoloader

@interface __Autoloader : NSObject

@end

#pragma mark - __WeakProxy

@interface __WeakProxy : NSProxy

@property (nonatomic, weak, readonly, nullable) id target;

- (instancetype)initWithTarget:(nullable id)target;

@end

#pragma mark - __DelegateProxy

@interface __DelegateProxy : NSObject

@property (nonatomic, readonly) Protocol *protocol;

@property (nonatomic, weak, nullable) id delegate;

- (instancetype)initWithProtocol:(Protocol *)protocol;

@end

#pragma mark - __WeakObject

@interface __WeakObject : NSObject

@property (nonatomic, weak, readonly, nullable) id object;

- (instancetype)initWithObject:(nullable id)object;

@end

#pragma mark - __Runtime

@interface __Runtime : NSObject

+ (nullable id)getProperty:(id)target forName:(NSString *)name;

+ (void)setPropertyPolicy:(id)target withObject:(nullable id)object policy:(objc_AssociationPolicy)policy forName:(NSString *)name;

+ (void)setPropertyWeak:(id)target withObject:(nullable id)object forName:(NSString *)name;

+ (nullable id)invokeMethod:(id)target selector:(SEL)aSelector;

+ (nullable id)invokeMethod:(id)target selector:(SEL)aSelector object:(nullable id)object;

+ (nullable id)invokeMethod:(id)target selector:(SEL)aSelector objects:(NSArray *)objects;

+ (nullable id)invokeGetter:(id)target name:(NSString *)name;

+ (nullable id)invokeSetter:(id)target name:(NSString *)name object:(nullable id)object;

+ (void)tryCatch:(void (NS_NOESCAPE ^)(void))block exceptionHandler:(nullable void (^)(NSException *exception))exceptionHandler;

+ (void)synchronized:(id)object closure:(__attribute__((noescape)) void (^)(void))closure;

+ (BOOL)isEqual:(nullable id)obj1 with:(nullable id)obj2;

@end

#pragma mark - __Swizzle

@interface __Swizzle : NSObject

+ (BOOL)swizzleInstanceMethod:(Class)originalClass selector:(SEL)originalSelector withBlock:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;

+ (BOOL)swizzleInstanceMethod:(Class)originalClass selector:(SEL)originalSelector identifier:(NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;

+ (BOOL)exchangeInstanceMethod:(Class)originalClass originalSelector:(SEL)originalSelector swizzleSelector:(SEL)swizzleSelector;

+ (BOOL)exchangeInstanceMethod:(Class)originalClass originalSelector:(SEL)originalSelector swizzleSelector:(SEL)swizzleSelector withBlock:(id)swizzleBlock;

@end

#pragma mark - __Bridge

@interface __Bridge : NSObject

+ (NSTimeInterval)systemUptime;

+ (NSString *)escapeHtml:(NSString *)string;

+ (BOOL)isIdcard:(NSString *)string;

+ (BOOL)isBankcard:(NSString *)string;

+ (NSString *)ipAddress;

+ (NSString *)hostName;

@end

#pragma mark - __Encrypt

@interface NSData (__Encrypt)

- (nullable id)__unarchiveObject:(Class)clazz;

- (nullable NSData *)__AESEncryptWithKey:(NSString *)key andIV:(NSData *)iv;

- (nullable NSData *)__AESDecryptWithKey:(NSString *)key andIV:(NSData *)iv;

- (nullable NSData *)__DES3EncryptWithKey:(NSString *)key andIV:(NSData *)iv;

- (nullable NSData *)__DES3DecryptWithKey:(NSString *)key andIV:(NSData *)iv;

- (nullable NSData *)__RSAEncryptWithPublicKey:(NSString *)publicKey;

- (nullable NSData *)__RSAEncryptWithPublicKey:(NSString *)publicKey andTag:(NSString *)tagName base64Encode:(BOOL)base64Encode;

- (nullable NSData *)__RSADecryptWithPrivateKey:(NSString *)privateKey;

- (nullable NSData *)__RSADecryptWithPrivateKey:(NSString *)privateKey andTag:(NSString *)tagName base64Decode:(BOOL)base64Decode;

- (nullable NSData *)__RSASignWithPrivateKey:(NSString *)privateKey;

- (nullable NSData *)__RSASignWithPrivateKey:(NSString *)privateKey andTag:(NSString *)tagName base64Encode:(BOOL)base64Encode;

- (nullable NSData *)__RSAVerifyWithPublicKey:(NSString *)publicKey;

- (nullable NSData *)__RSAVerifyWithPublicKey:(NSString *)publicKey andTag:(NSString *)tagName base64Decode:(BOOL)base64Decode;

@end

#pragma mark - __Image

@interface UIImage (__Image)

@property (nonatomic, readonly) UIImage *__maskImage;

- (nullable UIImage *)__imageWithBlurRadius:(CGFloat)blurRadius saturationDelta:(CGFloat)saturationDelta tintColor:(nullable UIColor *)tintColor maskImage:(nullable UIImage *)maskImage;

@end

#pragma mark - __NotificationTarget

@interface __NotificationTarget : NSObject

@property (nonatomic, copy, readonly) NSString *identifier;

@property (nonatomic, assign) BOOL broadcast;

@property (nonatomic, weak, nullable) id object;

@property (nonatomic, weak, nullable) id target;

@property (nonatomic) SEL action;

@property (nonatomic, copy, nullable) void (^block)(NSNotification *notification);

- (void)handleNotification:(NSNotification *)notification;

- (BOOL)equalsObject:(nullable id)object;

- (BOOL)equalsObject:(nullable id)object target:(nullable id)target action:(nullable SEL)action;

@end

#pragma mark - __KvoTarget

@interface __KvoTarget : NSObject

@property (nonatomic, copy, readonly) NSString *identifier;

@property (nonatomic, unsafe_unretained, nullable) id object;

@property (nonatomic, copy, nullable) NSString *keyPath;

@property (nonatomic, weak, nullable) id target;

@property (nonatomic) SEL action;

@property (nonatomic, copy, nullable) void (^block)(__weak id object, NSDictionary<NSKeyValueChangeKey, id> *change);

@property (nonatomic, assign, readonly) BOOL isObserving;

- (void)addObserver;

- (void)removeObserver;

- (BOOL)equalsTarget:(nullable id)target action:(nullable SEL)action;

@end

#pragma mark - __BlockTarget

@interface __BlockTarget : NSObject

@property (nonatomic, copy) NSString *identifier;

@property (nonatomic, copy, nullable) void (^block)(id sender);

@property (nonatomic, assign) UIControlEvents events;

- (void)invoke:(id)sender;

@end

NS_ASSUME_NONNULL_END
