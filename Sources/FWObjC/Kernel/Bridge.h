//
//  Bridge.h
//  FWFramework
//
//  Created by wuyong on 2022/11/11.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import "ObjC.h"
#import "Exception.h"
#import "HTTPSessionManager.h"
#import "RequestManager.h"
#import "Database.h"
#import "WebImage.h"
#import "AttributedLabel.h"
#import "BarrageView.h"
#import "CollectionViewFlowLayout.h"
#import "PopupMenu.h"
#import "SegmentedControl.h"
#import "TagCollectionView.h"
#import "ToolbarView.h"
#import "WebView.h"
#import "ImagePlugin.h"
#import "AlertController.h"
#import "ImagePickerController.h"
#import "ImagePreviewController.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWRuntime

@interface __FWRuntime : NSObject

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

+ (nullable NSString *)ipAddress;

+ (nullable NSString *)ipAddress:(NSString *)host;

+ (nullable UIImage *)svgDecode:(NSData *)data thumbnailSize:(CGSize)thumbnailSize;

+ (nullable NSData *)svgEncode:(UIImage *)image;

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

#pragma mark - __FWKvoTarget

@interface __FWKvoTarget : NSObject

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

NS_ASSUME_NONNULL_END
