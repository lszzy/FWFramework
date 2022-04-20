/**
 @header     FWWrapper.h
 @indexgroup FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-11
 */

#import <UIKit/UIKit.h>
#import "FWMacro.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Macro

/// 快速声明包装器宏
#define FWWrapperCompatible(baseClass, fw, objectWrapper, objectParent, classWrapper, classParent) \
    FWWrapperClass(baseClass, fw, objectWrapper, objectParent, classWrapper, classParent); \
    FWWrapperExtension(baseClass, fw, objectWrapper, objectParent, classWrapper, classParent);

/// 快速声明可用版本包装器宏
#define FWWrapperCompatibleAvailable(version, baseClass, fw, objectWrapper, objectParent, classWrapper, classParent) \
    FWWrapperClassAvailable(version, baseClass, fw, objectWrapper, objectParent, classWrapper, classParent); \
    FWWrapperExtensionAvailable(version, baseClass, fw, objectWrapper, objectParent, classWrapper, classParent);

/// 快速声明单泛型包装器宏
#define FWWrapperCompatibleGeneric(baseClass, fw, objectWrapper, objectParent, classWrapper, classParent) \
    FWWrapperClassGeneric(baseClass, fw, objectWrapper, objectParent, classWrapper, classParent); \
    FWWrapperExtensionGeneric(baseClass, fw, objectWrapper, objectParent, classWrapper, classParent);

/// 快速声明双泛型包装器宏
#define FWWrapperCompatibleGeneric2(baseClass, fw, objectWrapper, objectParent, classWrapper, classParent) \
    FWWrapperClassGeneric2(baseClass, fw, objectWrapper, objectParent, classWrapper, classParent); \
    FWWrapperExtensionGeneric2(baseClass, fw, objectWrapper, objectParent, classWrapper, classParent);

/// 快速实现包装器宏
#define FWDefWrapper(baseClass, fw, objectWrapper, classWrapper) \
    FWDefWrapperClass(baseClass, fw, objectWrapper, classWrapper); \
    FWDefWrapperExtension(baseClass, fw, objectWrapper, classWrapper);

/// 快速声明包装器类宏
#define FWWrapperClass(baseClass, fw, objectWrapper, objectParent, classWrapper, classParent) \
    @interface objectWrapper : objectParent \
    @property (nonatomic, weak, nullable, readonly) baseClass *base; \
    @end \
    @interface classWrapper : classParent \
    @end

/// 快速声明可用版本包装器类宏
#define FWWrapperClassAvailable(version, baseClass, fw, objectWrapper, objectParent, classWrapper, classParent) \
    API_AVAILABLE(ios(version)) \
    @interface objectWrapper : objectParent \
    @property (nonatomic, weak, nullable, readonly) baseClass *base; \
    @end \
    API_AVAILABLE(ios(version)) \
    @interface classWrapper : classParent \
    @end

/// 快速声明单泛型包装器类宏
#define FWWrapperClassGeneric(baseClass, fw, objectWrapper, objectParent, classWrapper, classParent) \
    @interface objectWrapper<__covariant ObjectType> : objectParent \
    @property (nonatomic, weak, nullable, readonly) baseClass<ObjectType> *base; \
    @end \
    @interface classWrapper : classParent \
    @end

/// 快速声明双泛型包装器类宏
#define FWWrapperClassGeneric2(baseClass, fw, objectWrapper, objectParent, classWrapper, classParent) \
    @interface objectWrapper<__covariant KeyType, __covariant ValueType> : objectParent \
    @property (nonatomic, weak, nullable, readonly) baseClass<KeyType, ValueType> *base; \
    @end \
    @interface classWrapper : classParent \
    @end

/// 快速实现包装器类宏
#define FWDefWrapperClass(baseClass, fw, objectWrapper, classWrapper) \
    @implementation objectWrapper \
    @dynamic base; \
    - (Class)wrapperClass { \
        return [classWrapper class]; \
    } \
    @end \
    @implementation classWrapper \
    - (Class)wrapperClass { \
        return [objectWrapper class]; \
    } \
    @end

/// 快速声明包装器扩展宏
#define FWWrapperExtension(baseClass, fw, objectWrapper, objectParent, classWrapper, classParent) \
    @interface baseClass (objectWrapper) \
    @property (nonatomic, strong, readonly) objectWrapper *fw; \
    @end \
    @interface baseClass (classWrapper) \
    @property (class, nonatomic, strong, readonly) classWrapper *fw; \
    @end

/// 快速声明可用版本包装器扩展宏
#define FWWrapperExtensionAvailable(version, baseClass, fw, objectWrapper, objectParent, classWrapper, classParent) \
    API_AVAILABLE(ios(version)) \
    @interface baseClass (objectWrapper) \
    @property (nonatomic, strong, readonly) objectWrapper *fw; \
    @end \
    API_AVAILABLE(ios(version)) \
    @interface baseClass (classWrapper) \
    @property (class, nonatomic, strong, readonly) classWrapper *fw; \
    @end

/// 快速声明单泛型包装器扩展宏
#define FWWrapperExtensionGeneric(baseClass, fw, objectWrapper, objectParent, classWrapper, classParent) \
    @interface baseClass<ObjectType> (objectWrapper) \
    @property (nonatomic, strong, readonly) objectWrapper<ObjectType> *fw; \
    @end \
    @interface baseClass (classWrapper) \
    @property (class, nonatomic, strong, readonly) classWrapper *fw; \
    @end

/// 快速声明双泛型包装器扩展宏
#define FWWrapperExtensionGeneric2(baseClass, fw, objectWrapper, objectParent, classWrapper, classParent) \
    @interface baseClass<KeyType, ValueType> (objectWrapper) \
    @property (nonatomic, strong, readonly) objectWrapper<KeyType, ValueType> *fw; \
    @end \
    @interface baseClass (classWrapper) \
    @property (class, nonatomic, strong, readonly) classWrapper *fw; \
    @end

/// 快速实现包装器扩展宏
#define FWDefWrapperExtension(baseClass, fw, objectWrapper, classWrapper) \
    @implementation baseClass (objectWrapper) \
    - (objectWrapper *)fw { \
        return [objectWrapper wrapper:self]; \
    } \
    @end \
    @implementation baseClass (classWrapper) \
    + (classWrapper *)fw { \
        return [classWrapper wrapper:self]; \
    } \
    @end

/// 快速声明自定义包装器宏
///
/// 自定义fw为任意名称(如app)示例：
/// h文件声明：
/// FWWrapperCustomizable(app)
/// m文件实现：
/// FWDefWrapperCustomizable(app)
/// 使用示例：
/// NSString.app.jsonEncode(object)
#define FWWrapperCustomizable(fw) \
    FWWrapperFramework_(FWWrapperExtension, fw);

/// 快速实现自定义包装器宏
#define FWDefWrapperCustomizable(fw) \
    FWDefWrapperFramework_(FWDefWrapperExtension, fw);

/// 内部快速声明所有框架包装器宏
#define FWWrapperFramework_(macro, fw) \
    macro(CALayer, fw, FWLayerWrapper, FWObjectWrapper, FWLayerClassWrapper, FWClassWrapper); \
    macro(CAGradientLayer, fw, FWGradientLayerWrapper, FWLayerWrapper, FWGradientLayerClassWrapper, FWLayerClassWrapper); \
    macro(CAAnimation, fw, FWAnimationWrapper, FWObjectWrapper, FWAnimationClassWrapper, FWClassWrapper); \
    macro(CADisplayLink, fw, FWDisplayLinkWrapper, FWObjectWrapper, FWDisplayLinkClassWrapper, FWClassWrapper); \
     \
    macro(NSString, fw, FWStringWrapper, FWObjectWrapper, FWStringClassWrapper, FWClassWrapper); \
    macro(NSAttributedString, fw, FWAttributedStringWrapper, FWObjectWrapper, FWAttributedStringClassWrapper, FWClassWrapper); \
    macro(NSNumber, fw, FWNumberWrapper, FWObjectWrapper, FWNumberClassWrapper, FWClassWrapper); \
    macro(NSData, fw, FWDataWrapper, FWObjectWrapper, FWDataClassWrapper, FWClassWrapper); \
    macro(NSDate, fw, FWDateWrapper, FWObjectWrapper, FWDateClassWrapper, FWClassWrapper); \
    macro(NSURL, fw, FWURLWrapper, FWObjectWrapper, FWURLClassWrapper, FWClassWrapper); \
    macro(NSURLRequest, fw, FWURLRequestWrapper, FWObjectWrapper, FWURLRequestClassWrapper, FWClassWrapper); \
    macro(NSBundle, fw, FWBundleWrapper, FWObjectWrapper, FWBundleClassWrapper, FWClassWrapper); \
    macro(NSTimer, fw, FWTimerWrapper, FWObjectWrapper, FWTimerClassWrapper, FWClassWrapper); \
    macro(NSUserDefaults, fw, FWUserDefaultsWrapper, FWObjectWrapper, FWUserDefaultsClassWrapper, FWClassWrapper); \
    macro(NSFileManager, fw, FWFileManagerWrapper, FWObjectWrapper, FWFileManagerClassWrapper, FWClassWrapper); \
    fw_macro_concat(macro, Generic)(NSArray, fw, FWArrayWrapper, FWObjectWrapper, FWArrayClassWrapper, FWClassWrapper); \
    fw_macro_concat(macro, Generic)(NSMutableArray, fw, FWMutableArrayWrapper, FWArrayWrapper, FWMutableArrayClassWrapper, FWArrayClassWrapper); \
    fw_macro_concat(macro, Generic)(NSSet, fw, FWSetWrapper, FWObjectWrapper, FWSetClassWrapper, FWClassWrapper); \
    fw_macro_concat(macro, Generic)(NSMutableSet, fw, FWMutableSetWrapper, FWSetWrapper, FWMutableSetClassWrapper, FWSetClassWrapper); \
    fw_macro_concat(macro, Generic2)(NSDictionary, fw, FWDictionaryWrapper, FWObjectWrapper, FWDictionaryClassWrapper, FWClassWrapper); \
    fw_macro_concat(macro, Generic2)(NSMutableDictionary, fw, FWMutableDictionaryWrapper, FWDictionaryWrapper, FWMutableDictionaryClassWrapper, FWClassWrapper); \
     \
    macro(UIApplication, fw, FWApplicationWrapper, FWObjectWrapper, FWApplicationClassWrapper, FWClassWrapper); \
    macro(UIBezierPath, fw, FWBezierPathWrapper, FWObjectWrapper, FWBezierPathClassWrapper, FWClassWrapper); \
    macro(UIDevice, fw, FWDeviceWrapper, FWObjectWrapper, FWDeviceClassWrapper, FWClassWrapper); \
    macro(UIScreen, fw, FWScreenWrapper, FWObjectWrapper, FWScreenClassWrapper, FWClassWrapper); \
    macro(UIImage, fw, FWImageWrapper, FWObjectWrapper, FWImageClassWrapper, FWClassWrapper); \
    macro(UIImageAsset, fw, FWImageAssetWrapper, FWObjectWrapper, FWImageAssetClassWrapper, FWClassWrapper); \
    macro(UIFont, fw, FWFontWrapper, FWObjectWrapper, FWFontClassWrapper, FWClassWrapper); \
    macro(UIColor, fw, FWColorWrapper, FWObjectWrapper, FWColorClassWrapper, FWClassWrapper); \
    macro(UIView, fw, FWViewWrapper, FWObjectWrapper, FWViewClassWrapper, FWClassWrapper); \
    macro(UILabel, fw, FWLabelWrapper, FWViewWrapper, FWLabelClassWrapper, FWViewClassWrapper); \
    macro(UIImageView, fw, FWImageViewWrapper, FWViewWrapper, FWImageViewClassWrapper, FWViewClassWrapper); \
    macro(UIScrollView, fw, FWScrollViewWrapper, FWViewWrapper, FWScrollViewClassWrapper, FWViewClassWrapper); \
    macro(UITableView, fw, FWTableViewWrapper, FWScrollViewWrapper, FWTableViewClassWrapper, FWScrollViewClassWrapper); \
    macro(UITableViewHeaderFooterView, fw, FWTableViewHeaderFooterViewWrapper, FWViewWrapper, FWTableViewHeaderFooterViewClassWrapper, FWViewClassWrapper); \
    macro(UITableViewCell, fw, FWTableViewCellWrapper, FWViewWrapper, FWTableViewCellClassWrapper, FWViewClassWrapper); \
    macro(UICollectionView, fw, FWCollectionViewWrapper, FWScrollViewWrapper, FWCollectionViewClassWrapper, FWScrollViewClassWrapper); \
    macro(UICollectionReusableView, fw, FWCollectionReusableViewWrapper, FWViewWrapper, FWCollectionReusableViewClassWrapper, FWViewClassWrapper); \
    macro(UICollectionViewCell, fw, FWCollectionViewCellWrapper, FWCollectionReusableViewWrapper, FWCollectionViewCellClassWrapper, FWCollectionReusableViewClassWrapper); \
    macro(UIControl, fw, FWControlWrapper, FWViewWrapper, FWControlClassWrapper, FWViewClassWrapper); \
    macro(UIButton, fw, FWButtonWrapper, FWControlWrapper, FWButtonClassWrapper, FWControlClassWrapper); \
    macro(UISwitch, fw, FWSwitchWrapper, FWControlWrapper, FWSwitchClassWrapper, FWControlClassWrapper); \
    macro(UIPageControl, fw, FWPageControlWrapper, FWControlWrapper, FWPageControlClassWrapper, FWControlClassWrapper); \
    macro(UISlider, fw, FWSliderWrapper, FWControlWrapper, FWSliderClassWrapper, FWControlClassWrapper); \
    macro(UITextField, fw, FWTextFieldWrapper, FWControlWrapper, FWTextFieldClassWrapper, FWControlClassWrapper); \
    macro(UITextView, fw, FWTextViewWrapper, FWScrollViewWrapper, FWTextViewClassWrapper, FWScrollViewClassWrapper); \
    macro(UIGestureRecognizer, fw, FWGestureRecognizerWrapper, FWObjectWrapper, FWGestureRecognizerClassWrapper, FWClassWrapper); \
    macro(UIBarItem, fw, FWBarItemWrapper, FWObjectWrapper, FWBarItemClassWrapper, FWClassWrapper); \
    macro(UIBarButtonItem, fw, FWBarButtonItemWrapper, FWBarItemWrapper, FWBarButtonItemClassWrapper, FWBarItemClassWrapper); \
    macro(UINavigationBar, fw, FWNavigationBarWrapper, FWViewWrapper, FWNavigationBarClassWrapper, FWViewClassWrapper); \
    macro(UITabBar, fw, FWTabBarWrapper, FWViewWrapper, FWTabBarClassWrapper, FWViewClassWrapper); \
    macro(UIToolbar, fw, FWToolbarWrapper, FWViewWrapper, FWToolbarClassWrapper, FWViewClassWrapper); \
    macro(UISearchBar, fw, FWSearchBarWrapper, FWViewWrapper, FWSearchBarClassWrapper, FWViewClassWrapper); \
    macro(UIWindow, fw, FWWindowWrapper, FWViewWrapper, FWWindowClassWrapper, FWViewClassWrapper); \
    macro(UIViewController, fw, FWViewControllerWrapper, FWObjectWrapper, FWViewControllerClassWrapper, FWClassWrapper); \
    macro(UINavigationController, fw, FWNavigationControllerWrapper, FWViewControllerWrapper, FWNavigationControllerClassWrapper, FWViewControllerClassWrapper); \
    macro(UITabBarController, fw, FWTabBarControllerWrapper, FWViewControllerWrapper, FWTabBarControllerClassWrapper, FWViewControllerClassWrapper);

/// 内部快速实现所有框架包装器宏
#define FWDefWrapperFramework_(macro, fw) \
    macro(CALayer, fw, FWLayerWrapper, FWLayerClassWrapper); \
    macro(CAGradientLayer, fw, FWGradientLayerWrapper, FWGradientLayerClassWrapper); \
    macro(CAAnimation, fw, FWAnimationWrapper, FWAnimationClassWrapper); \
    macro(CADisplayLink, fw, FWDisplayLinkWrapper, FWDisplayLinkClassWrapper); \
     \
    macro(NSString, fw, FWStringWrapper, FWStringClassWrapper); \
    macro(NSAttributedString, fw, FWAttributedStringWrapper, FWAttributedStringClassWrapper); \
    macro(NSNumber, fw, FWNumberWrapper, FWNumberClassWrapper); \
    macro(NSData, fw, FWDataWrapper, FWDataClassWrapper); \
    macro(NSDate, fw, FWDateWrapper, FWDateClassWrapper); \
    macro(NSURL, fw, FWURLWrapper, FWURLClassWrapper); \
    macro(NSURLRequest, fw, FWURLRequestWrapper, FWURLRequestClassWrapper); \
    macro(NSBundle, fw, FWBundleWrapper, FWBundleClassWrapper); \
    macro(NSTimer, fw, FWTimerWrapper, FWTimerClassWrapper); \
    macro(NSUserDefaults, fw, FWUserDefaultsWrapper, FWUserDefaultsClassWrapper); \
    macro(NSFileManager, fw, FWFileManagerWrapper, FWFileManagerClassWrapper); \
    macro(NSArray, fw, FWArrayWrapper, FWArrayClassWrapper); \
    macro(NSMutableArray, fw, FWMutableArrayWrapper, FWMutableArrayClassWrapper); \
    macro(NSSet, fw, FWSetWrapper, FWSetClassWrapper); \
    macro(NSMutableSet, fw, FWMutableSetWrapper, FWMutableSetClassWrapper); \
    macro(NSDictionary, fw, FWDictionaryWrapper, FWDictionaryClassWrapper); \
    macro(NSMutableDictionary, fw, FWMutableDictionaryWrapper, FWMutableDictionaryClassWrapper); \
     \
    macro(UIApplication, fw, FWApplicationWrapper, FWApplicationClassWrapper); \
    macro(UIBezierPath, fw, FWBezierPathWrapper, FWBezierPathClassWrapper); \
    macro(UIDevice, fw, FWDeviceWrapper, FWDeviceClassWrapper); \
    macro(UIScreen, fw, FWScreenWrapper, FWScreenClassWrapper); \
    macro(UIImage, fw, FWImageWrapper, FWImageClassWrapper); \
    macro(UIImageAsset, fw, FWImageAssetWrapper, FWImageAssetClassWrapper); \
    macro(UIFont, fw, FWFontWrapper, FWFontClassWrapper); \
    macro(UIColor, fw, FWColorWrapper, FWColorClassWrapper); \
    macro(UIView, fw, FWViewWrapper, FWViewClassWrapper); \
    macro(UILabel, fw, FWLabelWrapper, FWLabelClassWrapper); \
    macro(UIImageView, fw, FWImageViewWrapper, FWImageViewClassWrapper); \
    macro(UIScrollView, fw, FWScrollViewWrapper, FWScrollViewClassWrapper); \
    macro(UITableView, fw, FWTableViewWrapper, FWTableViewClassWrapper); \
    macro(UITableViewHeaderFooterView, fw, FWTableViewHeaderFooterViewWrapper, FWTableViewHeaderFooterViewClassWrapper); \
    macro(UITableViewCell, fw, FWTableViewCellWrapper, FWTableViewCellClassWrapper); \
    macro(UICollectionView, fw, FWCollectionViewWrapper, FWCollectionViewClassWrapper); \
    macro(UICollectionReusableView, fw, FWCollectionReusableViewWrapper, FWCollectionReusableViewClassWrapper); \
    macro(UICollectionViewCell, fw, FWCollectionViewCellWrapper, FWCollectionViewCellClassWrapper); \
    macro(UIControl, fw, FWControlWrapper, FWControlClassWrapper); \
    macro(UIButton, fw, FWButtonWrapper, FWButtonClassWrapper); \
    macro(UISwitch, fw, FWSwitchWrapper, FWSwitchClassWrapper); \
    macro(UIPageControl, fw, FWPageControlWrapper, FWPageControlClassWrapper); \
    macro(UISlider, fw, FWSliderWrapper, FWSliderClassWrapper); \
    macro(UITextField, fw, FWTextFieldWrapper, FWTextFieldClassWrapper); \
    macro(UITextView, fw, FWTextViewWrapper, FWTextViewClassWrapper); \
    macro(UIGestureRecognizer, fw, FWGestureRecognizerWrapper, FWGestureRecognizerClassWrapper); \
    macro(UIBarItem, fw, FWBarItemWrapper, FWBarItemClassWrapper); \
    macro(UIBarButtonItem, fw, FWBarButtonItemWrapper, FWBarButtonItemClassWrapper); \
    macro(UINavigationBar, fw, FWNavigationBarWrapper, FWNavigationBarClassWrapper); \
    macro(UITabBar, fw, FWTabBarWrapper, FWTabBarClassWrapper); \
    macro(UIToolbar, fw, FWToolbarWrapper, FWToolbarClassWrapper); \
    macro(UISearchBar, fw, FWSearchBarWrapper, FWSearchBarClassWrapper); \
    macro(UIWindow, fw, FWWindowWrapper, FWWindowClassWrapper); \
    macro(UIViewController, fw, FWViewControllerWrapper, FWViewControllerClassWrapper); \
    macro(UINavigationController, fw, FWNavigationControllerWrapper, FWNavigationControllerClassWrapper); \
    macro(UITabBarController, fw, FWTabBarControllerWrapper, FWTabBarControllerClassWrapper);

#pragma mark - FWObjectWrapper

/// 框架包装器
///
/// 备注：因Swift无法扩展OC泛型，未使用OC泛型实现，子类需覆盖base属性声明
@interface FWObjectWrapper : NSObject

/// 原始对象
@property (nonatomic, weak, nullable, readonly) id base;

/// 禁用属性
@property (nonatomic, strong, readonly) FWObjectWrapper *fw NS_UNAVAILABLE;

/// 获取关联的类包装器类
@property (nonatomic, unsafe_unretained, readonly) Class wrapperClass;

/// 快速创建包装器，自动缓存
+ (instancetype)wrapper:(id)base;

@end

/// 框架包装器协议
@protocol FWObjectWrapper <NSObject>

/// 对象包装器
@property (nonatomic, strong, readonly) FWObjectWrapper *fw;

@end

/// NSObject实现包装器协议
@interface NSObject (FWObjectWrapper) <FWObjectWrapper>

/// 对象包装器
@property (nonatomic, strong, readonly) FWObjectWrapper *fw;

@end

#pragma mark - FWClassWrapper

/// 框架类包装器
@interface FWClassWrapper : NSObject

/// 原始类
@property (nonatomic, unsafe_unretained, readonly) Class base;

/// 禁用属性
@property (nonatomic, strong, readonly) FWClassWrapper *fw NS_UNAVAILABLE;

/// 获取关联的对象包装器类
@property (nonatomic, unsafe_unretained, readonly) Class wrapperClass;

/// 快速创建包装器，无缓存
+ (instancetype)wrapper:(Class)base;

@end

/// 框架类包装器协议
@protocol FWClassWrapper <NSObject>

/// 类包装器
@property (class, nonatomic, strong, readonly) FWClassWrapper *fw;

@end

/// NSObject实现类包装器协议
@interface NSObject (FWClassWrapper) <FWClassWrapper>

/// 类包装器
@property (class, nonatomic, strong, readonly) FWClassWrapper *fw;

@end

#pragma mark - FWWrapperCompatible

FWWrapperFramework_(FWWrapperCompatible, fw);

NS_ASSUME_NONNULL_END
