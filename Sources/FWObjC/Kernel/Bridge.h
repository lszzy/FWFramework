//
//  Bridge.h
//  FWFramework
//
//  Created by wuyong on 2022/11/11.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWAutoloader

@interface __FWAutoloader : NSObject

@end

#pragma mark - __FWWeakProxy

@interface __FWWeakProxy : NSProxy

@property (nonatomic, weak, readonly, nullable) id target;

- (instancetype)initWithTarget:(nullable id)target;

@end

#pragma mark - __FWBlockProxy

@interface __FWBlockProxy : NSObject

@property (nonatomic, copy, readonly) id block;

@property (nonatomic, strong, readonly) NSMethodSignature *methodSignature;

+ (nullable NSMethodSignature *)methodSignatureForBlock:(id)block;

- (instancetype)initWithBlock:(id)block;

+ (instancetype)proxyWithBlock:(id)block;

- (BOOL)invokeWithInvocation:(NSInvocation *)invocation returnValue:(out NSValue * __nullable * __nonnull)returnValue;

- (void)invokeWithInvocation:(NSInvocation *)invocation;

@end

#pragma mark - __FWDelegateProxy

@interface __FWDelegateProxy : NSObject

@property (nonatomic, weak, nullable) id proxyDelegate;

- (void)setSelector:(SEL)selector withBlock:(nullable id)block;

- (nullable id)blockForSelector:(SEL)selector;

@end

#pragma mark - __FWWeakObject

@interface __FWWeakObject : NSObject

@property (nonatomic, weak, readonly, nullable) id object;

- (instancetype)initWithObject:(nullable id)object;

@end

#pragma mark - __FWRuntime

@interface __FWRuntime : NSObject

+ (nullable id)getProperty:(id)target forName:(NSString *)name;

+ (void)setPropertyPolicy:(id)target withObject:(nullable id)object policy:(objc_AssociationPolicy)policy forName:(NSString *)name;

+ (void)setPropertyWeak:(id)target withObject:(nullable id)object forName:(NSString *)name;

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

+ (void)tryCatch:(void (NS_NOESCAPE ^)(void))block exceptionHandler:(nullable void (^)(NSException *exception))exceptionHandler;

+ (BOOL)isEqual:(nullable id)obj1 with:(nullable id)obj2;

@end

#pragma mark - __FWSwizzle

@interface __FWSwizzle : NSObject

+ (BOOL)swizzleInstanceMethod:(Class)originalClass selector:(SEL)originalSelector withBlock:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;

+ (BOOL)swizzleInstanceMethod:(Class)originalClass selector:(SEL)originalSelector identifier:(nullable NSString *)identifier withBlock:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;

+ (BOOL)swizzleDeallocMethod:(Class)originalClass identifier:(nullable NSString *)identifier withBlock:(void (^)(__kindof NSObject *__unsafe_unretained object))block;

+ (BOOL)exchangeInstanceMethod:(Class)originalClass originalSelector:(SEL)originalSelector swizzleSelector:(SEL)swizzleSelector;

+ (BOOL)exchangeInstanceMethod:(Class)originalClass originalSelector:(SEL)originalSelector swizzleSelector:(SEL)swizzleSelector withBlock:(id)swizzleBlock;

@end

#pragma mark - __FWBridge

@interface __FWBridge : NSObject

+ (void)logMessage:(NSString *)message;

+ (NSTimeInterval)systemUptime;

+ (NSString *)escapeHtml:(NSString *)string;

+ (BOOL)isIdcard:(NSString *)string;

+ (BOOL)isBankcard:(NSString *)string;

+ (NSString *)ipAddress;

+ (NSString *)hostName;

@end

#pragma mark - __FWEncrypt

@interface NSData (__FWEncrypt)

- (nullable id)__fw_unarchiveObject:(Class)clazz;

- (nullable NSData *)__fw_AESEncryptWithKey:(NSString *)key andIV:(NSData *)iv;

- (nullable NSData *)__fw_AESDecryptWithKey:(NSString *)key andIV:(NSData *)iv;

- (nullable NSData *)__fw_DES3EncryptWithKey:(NSString *)key andIV:(NSData *)iv;

- (nullable NSData *)__fw_DES3DecryptWithKey:(NSString *)key andIV:(NSData *)iv;

- (nullable NSData *)__fw_RSAEncryptWithPublicKey:(NSString *)publicKey;

- (nullable NSData *)__fw_RSAEncryptWithPublicKey:(NSString *)publicKey andTag:(NSString *)tagName base64Encode:(BOOL)base64Encode;

- (nullable NSData *)__fw_RSADecryptWithPrivateKey:(NSString *)privateKey;

- (nullable NSData *)__fw_RSADecryptWithPrivateKey:(NSString *)privateKey andTag:(NSString *)tagName base64Decode:(BOOL)base64Decode;

- (nullable NSData *)__fw_RSASignWithPrivateKey:(NSString *)privateKey;

- (nullable NSData *)__fw_RSASignWithPrivateKey:(NSString *)privateKey andTag:(NSString *)tagName base64Encode:(BOOL)base64Encode;

- (nullable NSData *)__fw_RSAVerifyWithPublicKey:(NSString *)publicKey;

- (nullable NSData *)__fw_RSAVerifyWithPublicKey:(NSString *)publicKey andTag:(NSString *)tagName base64Decode:(BOOL)base64Decode;

@end

#pragma mark - UIImage+__FWBridge

@interface UIImage (__FWBridge)

@property (nonatomic, readonly) UIImage *__fw_maskImage;

- (nullable UIImage *)__fw_imageWithBlurRadius:(CGFloat)blurRadius saturationDelta:(CGFloat)saturationDelta tintColor:(nullable UIColor *)tintColor maskImage:(nullable UIImage *)maskImage;

@end

#pragma mark - UIImageView+__FWBridge

@interface UIImageView (__FWBridge)

- (void)__fw_faceAware;

@end

#pragma mark - __FWNotificationTarget

@interface __FWNotificationTarget : NSObject

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

#pragma mark - __FWKvoTarget

@interface __FWKvoTarget : NSObject

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

#pragma mark - __FWBlockTarget

@interface __FWBlockTarget : NSObject

@property (nonatomic, copy) NSString *identifier;

@property (nonatomic, copy, nullable) void (^block)(id sender);

@property (nonatomic, assign) UIControlEvents events;

- (void)invoke:(id)sender;

@end

#pragma mark - __FWInputTarget

@interface __FWInputTarget : NSObject

@property (nonatomic, weak, nullable, readonly) UIView<UITextInput> *textInput;

@property (nonatomic, assign) NSInteger maxLength;

@property (nonatomic, assign) NSInteger maxUnicodeLength;

@property (nonatomic, copy, nullable) void (^textChangedBlock)(NSString *text);

@property (nonatomic, assign) NSTimeInterval autoCompleteInterval;

@property (nonatomic, assign) NSTimeInterval autoCompleteTimestamp;

@property (nonatomic, copy, nullable) void (^autoCompleteBlock)(NSString *text);

- (instancetype)initWithTextInput:(nullable UIView<UITextInput> *)textInput;

- (void)textLengthChanged;

- (void)textChangedAction;

- (NSString *)filterText:(NSString *)text;

@end

#pragma mark - __FWStatisticalDelegate

/// 统计点击回调block，参数cell为表格子cell，indexPath为表格子cell所在位置
typedef void (^__FWStatisticalClickCallback)(__kindof UIView * _Nullable cell, NSIndexPath * _Nullable indexPath) NS_SWIFT_NAME(StatisticalClickCallback);

/// 统计曝光回调block，参数cell为表格子cell，indexPath为表格子cell所在位置，duration为曝光时长(0表示开始)
typedef void (^__FWStatisticalExposureCallback)(__kindof UIView * _Nullable cell, NSIndexPath * _Nullable indexPath, NSTimeInterval duration) NS_SWIFT_NAME(StatisticalExposureCallback);

/// 自定义统计实现代理
NS_SWIFT_NAME(StatisticalDelegate)
@protocol __FWStatisticalDelegate <NSObject>
@optional

/// 自定义点击事件统计方式(单次)，仅注册时调用一次，点击触发时必须调用callback。参数cell为表格子cell，indexPath为表格子cell所在位置
- (void)statisticalClickWithCallback:(__FWStatisticalClickCallback)callback;

/// 自定义曝光事件统计方式(多次)，当视图绑定曝光、完全曝光时会调用，曝光触发时必须调用callback。参数cell为表格子cell，indexPath为表格子cell所在位置，duration为曝光时长(0表示开始)
- (void)statisticalExposureWithCallback:(__FWStatisticalExposureCallback)callback;

/// 自定义cell事件代理视图，仅cell生效。默认为所在tableView|collectionView，如果不同，实现此方法即可
- (nullable UIView *)statisticalCellProxyView;

@end

NS_ASSUME_NONNULL_END
