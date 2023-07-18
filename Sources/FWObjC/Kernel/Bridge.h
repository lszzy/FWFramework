//
//  Bridge.h
//  FWFramework
//
//  Created by wuyong on 2022/11/11.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "ImagePlugin.h"
#import "ViewPlugin.h"
#import "AlertController.h"
#import "RefreshView.h"
#import "ImagePickerController.h"
#import "AnimatedImage.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWAutoloader

@interface __FWAutoloader : NSObject

@end

#pragma mark - __FWWeakProxy

@interface __FWWeakProxy : NSProxy

@property (nonatomic, weak, readonly, nullable) id target;

- (instancetype)initWithTarget:(nullable id)target;

@end

#pragma mark - __FWDelegateProxy

@interface __FWDelegateProxy : NSObject

@property (nonatomic, weak, nullable) id proxyDelegate;

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

+ (nullable NSString *)ipAddress;

+ (nullable NSString *)ipAddress:(NSString *)host;

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

// MARK: - __FWSwift

#define __FWLogDebug( aFormat, ... ) \
    [NSObject __fw_logDebug:[NSString stringWithFormat:(@"(%@ %@ #%d %s) " aFormat), NSThread.isMainThread ? @"[M]" : @"[T]", [@(__FILE__) lastPathComponent], __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__]];

@interface NSObject ()

+ (BOOL)__fw_swizzleMethod:(nullable id)target selector:(SEL)originalSelector identifier:(nullable NSString *)identifier block:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;

+ (NSArray<NSString *> *)__fw_classMethods:(Class)clazz;
- (nullable id)__fw_invokeGetter:(NSString *)name;

- (NSString *)__fw_observeProperty:(NSString *)property block:(void (^)(id object, NSDictionary<NSKeyValueChangeKey, id> *change))block;
- (NSString *)__fw_observeProperty:(NSString *)property target:(nullable id)target action:(SEL)action;
- (void)__fw_unobserveProperty:(NSString *)property target:(nullable id)target action:(nullable SEL)action;

+ (void)__fw_logDebug:(NSString *)message;

+ (NSString *)__fw_bundleString:(NSString *)key;
+ (nullable UIImage *)__fw_bundleImage:(NSString *)name;

- (void)__fw_applyAppearance;

@end

@interface NSTimer ()

+ (NSTimer *)__fw_commonTimerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *timer))block repeats:(BOOL)repeats;

@end

@interface UIPageControl ()

@property (nonatomic, assign) CGSize __fw_preferredSize;

@end

@interface UIImageView ()

+ (UIImageView *)__fw_animatedImageView;
- (void)__fw_setImageWithUrl:(nullable id)url placeholderImage:(nullable UIImage *)placeholderImage completion:(nullable void (^)(UIImage * _Nullable, NSError * _Nullable))completion;
- (void)__fw_setImageWithUrl:(nullable id)url placeholderImage:(nullable UIImage *)placeholderImage options:(__FWWebImageOptions)options context:(nullable NSDictionary *)context completion:(nullable void (^)(UIImage * _Nullable, NSError * _Nullable))completion progress:(nullable void (^)(double))progress;
- (void)__fw_cancelImageRequest;

@end

@interface UIImage ()

@property (nonatomic, assign, readonly) BOOL __fw_hasAlpha;
@property (nonatomic, assign) __FWImageFormat __fw_imageFormat;
@property (nonatomic, assign) NSUInteger __fw_imageLoopCount;

+ (nullable UIImage *)__fw_imageNamed:(NSString *)name bundle:(nullable NSBundle *)bundle options:(nullable NSDictionary *)options;
- (nullable UIImage *)__fw_imageWithAlpha:(CGFloat)alpha;
- (nullable UIImage *)__fw_croppedImageWithFrame:(CGRect)frame angle:(NSInteger)angle circular:(BOOL)circular;
+ (nullable UIImage *)__fw_imageWithData:(nullable NSData *)data scale:(CGFloat)scale options:(nullable NSDictionary *)options;
- (nullable UIImage *)__fw_imageWithScaleSize:(CGSize)size;

@end

@interface CALayer ()

- (void)__fw_removeDefaultAnimations;

@end

@interface UIView ()

@property (nonatomic, assign) UIEdgeInsets __fw_touchInsets;

@property (nonatomic, weak, readonly, nullable) UIViewController *__fw_viewController;

@property (nonatomic, assign) CGRect __fw_frameApplyTransform;

- (nullable UIView *)__fw_subviewWithTag:(NSInteger)tag;

- (NSString *)__fw_addTapGestureWithBlock:(void (^)(id sender))block customize:(nullable void (^)(__kindof UITapGestureRecognizer *gesture))customize;

+ (UIView<__FWIndicatorViewPlugin> *)__fw_indicatorViewWithStyle:(__FWIndicatorViewStyle)style;
+ (UIView<__FWProgressViewPlugin> *)__fw_progressViewWithStyle:(__FWProgressViewStyle)style;

- (NSArray<NSLayoutConstraint *> *)__fw_pinEdgesToSuperview:(UIEdgeInsets)insets;
- (NSArray<NSLayoutConstraint *> *)__fw_alignCenterToSuperview:(CGPoint)offset;

- (void)__fw_statisticalCheckExposure;
- (BOOL)__fw_statisticalTrackClickWithIndexPath:(nullable NSIndexPath *)indexPath event:(nullable id)event;
- (BOOL)__fw_statisticalBindExposure:(nullable UIView *)containerView;

@end

@interface UICollectionViewFlowLayout ()

- (void)__fw_sectionConfigPrepareLayout;
- (NSArray *)__fw_sectionConfigLayoutAttributesForElementsIn:(CGRect)rect;

@end

@interface UITextField ()

@property (nonatomic, assign) BOOL __fw_menuDisabled;

@end

@interface UIWindow ()

@property (class, nonatomic, readwrite, nullable) UIWindow *__fw_mainWindow;

@end

@interface UIControl ()

- (NSString *)__fw_addTouchWithBlock:(void (^)(id sender))block;

@end

@interface UIButton ()

@property (class, nonatomic, assign) CGFloat __fw_disabledAlpha;
@property (class, nonatomic, assign) CGFloat __fw_highlightedAlpha;
@property (nonatomic, assign) CGFloat __fw_disabledAlpha;
@property (nonatomic, assign) CGFloat __fw_highlightedAlpha;

@end

@interface UIScreen ()

@property (class, nonatomic, assign, readonly) CGFloat __fw_statusBarHeight;
@property (class, nonatomic, assign, readonly) CGFloat __fw_navigationBarHeight;
@property (class, nonatomic, assign, readonly) CGFloat __fw_tabBarHeight;
@property (class, nonatomic, assign, readonly) UIEdgeInsets __fw_safeAreaInsets;
@property (class, nonatomic, assign, readonly) CGFloat __fw_toolBarHeight;
@property (class, nonatomic, assign, readonly) CGFloat __fw_topBarHeight;

+ (CGFloat)__fw_flatValue:(CGFloat)value scale:(CGFloat)scale;

@end

@interface UISlider ()

@property (nonatomic, assign) CGSize __fw_thumbSize;
@property (nonatomic, strong, nullable) UIColor *__fw_thumbColor;

@end

@interface UIActivityIndicatorView ()

+ (UIActivityIndicatorView *)__fw_indicatorViewWithColor:(nullable UIColor *)color;

@end

@interface UIViewController ()

@property (nonatomic, strong, readonly) UIView *__fw_ancestorView;
@property (nonatomic, assign, readonly) BOOL __fw_isPresented;

- (BOOL)__fw_isInvisibleState;

- (void)__fw_showLoadingWithText:(nullable id)text cancel:(nullable void (^)(void))cancel;
- (void)__fw_hideLoading:(BOOL)delayed;
- (void)__fw_showEmptyViewWithText:(nullable NSString *)text detail:(nullable NSString *)detail image:(nullable UIImage *)image action:(nullable NSString *)action block:(nullable void (^)(id))block;
- (void)__fw_showAlertWithTitle:(nullable id)title message:(nullable id)message style:(__FWAlertStyle)style cancel:(nullable id)cancel cancelBlock:(nullable void (^)(void))cancelBlock;
- (void)__fw_showSheetWithTitle:(nullable id)title message:(nullable id)message cancel:(nullable id)cancel actions:(nullable NSArray *)actions currentIndex:(NSInteger)currentIndex actionBlock:(nullable void (^)(NSInteger))actionBlock cancelBlock:(nullable void (^)(void))cancelBlock;

@end

@interface UINavigationBar ()

@property (nonatomic, strong, nullable) UIColor *__fw_backgroundColor;
@property (nonatomic, strong, nullable) UIColor *__fw_foregroundColor;
@property (nonatomic, strong, nullable) UIImage *__fw_backImage;
@property (nonatomic, assign) BOOL __fw_isTranslucent;
@property (nonatomic, strong, nullable) UIColor *__fw_shadowColor;

@end

@interface UIScrollView ()

@property (nonatomic, strong, nullable) __FWPullRefreshView *__fw_pullRefreshView;
@property (nonatomic, assign) BOOL __fw_showPullRefresh;
@property (nonatomic, assign) CGFloat __fw_pullRefreshHeight;
@property (nonatomic, strong, nullable) __FWInfiniteScrollView *__fw_infiniteScrollView;
@property (nonatomic, assign) BOOL __fw_showInfiniteScroll;
@property (nonatomic, assign) CGFloat __fw_infiniteScrollHeight;

@end

@interface PHPhotoLibrary ()

@property (class, nonatomic, copy, readonly) NSString *__fw_pickerControllerVideoCachePath;

+ (NSArray *)__fw_fetchAllAlbumsWithAlbumContentType:(__FWAlbumContentType)albumContentType showEmptyAlbum:(BOOL)showEmptyAlbum showSmartAlbum:(BOOL)showSmartAlbum;
+ (PHFetchOptions *)__fw_createFetchOptionsWithAlbumContentType:(__FWAlbumContentType)albumContentType;
- (void)__fw_addImageToAlbum:(CGImageRef)imageRef assetCollection:(PHAssetCollection *)assetCollection orientation:(UIImageOrientation)orientation completionHandler:(nullable void (^)(BOOL, NSDate * _Nullable, NSError * _Nullable))completionHandler;
- (void)__fw_addImageToAlbum:(NSURL *)imagePathURL assetCollection:(PHAssetCollection *)assetCollection completionHandler:(nullable void (^)(BOOL, NSDate * _Nullable, NSError * _Nullable))completionHandler;
- (void)__fw_addVideoToAlbum:(NSURL *)videoPathURL assetCollection:(PHAssetCollection *)assetCollection completionHandler:(nullable void (^)(BOOL, NSDate * _Nullable, NSError * _Nullable))completionHandler;

@end

NS_ASSUME_NONNULL_END
