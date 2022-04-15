/**
 @header     FWWrapper.h
 @indexgroup FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-11
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Macro

/// 快速声明包装器宏
#define FWWrapperCompatible(baseClass, objectWrapper, objectParent, classWrapper, classParent) \
    @interface objectWrapper : objectParent \
    @property (nonatomic, weak, nullable, readonly) baseClass *base; \
    @end \
    @interface baseClass (objectWrapper) \
    @property (nonatomic, strong, readonly) objectWrapper *fw; \
    @end \
    @interface classWrapper : classParent \
    @end \
    @interface baseClass (classWrapper) \
    @property (class, nonatomic, strong, readonly) classWrapper *fw; \
    @end

/// 快速声明可用版本包装器宏
#define FWWrapperCompatibleAvailable(version, baseClass, objectWrapper, objectParent, classWrapper, classParent) \
    API_AVAILABLE(ios(version)) \
    @interface objectWrapper : objectParent \
    @property (nonatomic, weak, nullable, readonly) baseClass *base; \
    @end \
    API_AVAILABLE(ios(version)) \
    @interface baseClass (objectWrapper) \
    @property (nonatomic, strong, readonly) objectWrapper *fw; \
    @end \
    API_AVAILABLE(ios(version)) \
    @interface classWrapper : classParent \
    @end \
    API_AVAILABLE(ios(version)) \
    @interface baseClass (classWrapper) \
    @property (class, nonatomic, strong, readonly) classWrapper *fw; \
    @end

/// 快速声明单泛型包装器宏
#define FWWrapperCompatibleGeneric(baseClass, objectWrapper, objectParent, classWrapper, classParent) \
    @interface objectWrapper<__covariant ObjectType> : objectParent \
    @property (nonatomic, weak, nullable, readonly) baseClass<ObjectType> *base; \
    @end \
    @interface baseClass<ObjectType> (objectWrapper) \
    @property (nonatomic, strong, readonly) objectWrapper<ObjectType> *fw; \
    @end \
    @interface classWrapper : classParent \
    @end \
    @interface baseClass (classWrapper) \
    @property (class, nonatomic, strong, readonly) classWrapper *fw; \
    @end

/// 快速声明双泛型包装器宏
#define FWWrapperCompatibleGeneric2(baseClass, objectWrapper, objectParent, classWrapper, classParent) \
    @interface objectWrapper<__covariant KeyType, __covariant ValueType> : objectParent \
    @property (nonatomic, weak, nullable, readonly) baseClass<KeyType, ValueType> *base; \
    @end \
    @interface baseClass<KeyType, ValueType> (objectWrapper) \
    @property (nonatomic, strong, readonly) objectWrapper<KeyType, ValueType> *fw; \
    @end \
    @interface classWrapper : classParent \
    @end \
    @interface baseClass (classWrapper) \
    @property (class, nonatomic, strong, readonly) classWrapper *fw; \
    @end

/// 快速实现包装器宏
#define FWDefWrapper(baseClass, objectWrapper, classWrapper) \
    @implementation objectWrapper \
    @dynamic base; \
    @end \
    @implementation baseClass (objectWrapper) \
    - (objectWrapper *)fw { \
        return [objectWrapper wrapper:self]; \
    } \
    @end \
    @implementation classWrapper \
    @end \
    @implementation baseClass (classWrapper) \
    + (classWrapper *)fw { \
        return [classWrapper wrapper:self]; \
    } \
    @end

#pragma mark - FWObjectWrapper

/// 框架包装器
///
/// 备注：因Swift无法扩展OC泛型，未使用OC泛型实现，子类需覆盖base属性声明
@interface FWObjectWrapper : NSObject

/// 原始对象
@property (nonatomic, weak, nullable, readonly) id base;

/// 禁用属性
@property (nonatomic, strong, readonly) FWObjectWrapper *fw NS_UNAVAILABLE;

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

FWWrapperCompatible(CALayer, FWLayerWrapper, FWObjectWrapper, FWLayerClassWrapper, FWClassWrapper);
FWWrapperCompatible(CAGradientLayer, FWGradientLayerWrapper, FWLayerWrapper, FWGradientLayerClassWrapper, FWLayerClassWrapper);
FWWrapperCompatible(CAAnimation, FWAnimationWrapper, FWObjectWrapper, FWAnimationClassWrapper, FWClassWrapper);
FWWrapperCompatible(CADisplayLink, FWDisplayLinkWrapper, FWObjectWrapper, FWDisplayLinkClassWrapper, FWClassWrapper);

FWWrapperCompatible(NSString, FWStringWrapper, FWObjectWrapper, FWStringClassWrapper, FWClassWrapper);
FWWrapperCompatible(NSAttributedString, FWAttributedStringWrapper, FWObjectWrapper, FWAttributedStringClassWrapper, FWClassWrapper);
FWWrapperCompatible(NSNumber, FWNumberWrapper, FWObjectWrapper, FWNumberClassWrapper, FWClassWrapper);
FWWrapperCompatible(NSData, FWDataWrapper, FWObjectWrapper, FWDataClassWrapper, FWClassWrapper);
FWWrapperCompatible(NSDate, FWDateWrapper, FWObjectWrapper, FWDateClassWrapper, FWClassWrapper);
FWWrapperCompatible(NSURL, FWURLWrapper, FWObjectWrapper, FWURLClassWrapper, FWClassWrapper);
FWWrapperCompatible(NSURLRequest, FWURLRequestWrapper, FWObjectWrapper, FWURLRequestClassWrapper, FWClassWrapper);
FWWrapperCompatible(NSBundle, FWBundleWrapper, FWObjectWrapper, FWBundleClassWrapper, FWClassWrapper);
FWWrapperCompatible(NSTimer, FWTimerWrapper, FWObjectWrapper, FWTimerClassWrapper, FWClassWrapper);
FWWrapperCompatible(NSUserDefaults, FWUserDefaultsWrapper, FWObjectWrapper, FWUserDefaultsClassWrapper, FWClassWrapper);
FWWrapperCompatible(NSFileManager, FWFileManagerWrapper, FWObjectWrapper, FWFileManagerClassWrapper, FWClassWrapper);
FWWrapperCompatibleGeneric(NSArray, FWArrayWrapper, FWObjectWrapper, FWArrayClassWrapper, FWClassWrapper);
FWWrapperCompatibleGeneric(NSMutableArray, FWMutableArrayWrapper, FWArrayWrapper, FWMutableArrayClassWrapper, FWArrayClassWrapper);
FWWrapperCompatibleGeneric(NSSet, FWSetWrapper, FWObjectWrapper, FWSetClassWrapper, FWClassWrapper);
FWWrapperCompatibleGeneric(NSMutableSet, FWMutableSetWrapper, FWSetWrapper, FWMutableSetClassWrapper, FWSetClassWrapper);
FWWrapperCompatibleGeneric2(NSDictionary, FWDictionaryWrapper, FWObjectWrapper, FWDictionaryClassWrapper, FWClassWrapper);
FWWrapperCompatibleGeneric2(NSMutableDictionary, FWMutableDictionaryWrapper, FWDictionaryWrapper, FWMutableDictionaryClassWrapper, FWClassWrapper);

FWWrapperCompatible(UIApplication, FWApplicationWrapper, FWObjectWrapper, FWApplicationClassWrapper, FWClassWrapper);
FWWrapperCompatible(UIBezierPath, FWBezierPathWrapper, FWObjectWrapper, FWBezierPathClassWrapper, FWClassWrapper);
FWWrapperCompatible(UIDevice, FWDeviceWrapper, FWObjectWrapper, FWDeviceClassWrapper, FWClassWrapper);
FWWrapperCompatible(UIScreen, FWScreenWrapper, FWObjectWrapper, FWScreenClassWrapper, FWClassWrapper);
FWWrapperCompatible(UIImage, FWImageWrapper, FWObjectWrapper, FWImageClassWrapper, FWClassWrapper);
FWWrapperCompatible(UIImageAsset, FWImageAssetWrapper, FWObjectWrapper, FWImageAssetClassWrapper, FWClassWrapper);
FWWrapperCompatible(UIFont, FWFontWrapper, FWObjectWrapper, FWFontClassWrapper, FWClassWrapper);
FWWrapperCompatible(UIColor, FWColorWrapper, FWObjectWrapper, FWColorClassWrapper, FWClassWrapper);
FWWrapperCompatible(UIView, FWViewWrapper, FWObjectWrapper, FWViewClassWrapper, FWClassWrapper);
FWWrapperCompatible(UILabel, FWLabelWrapper, FWViewWrapper, FWLabelClassWrapper, FWViewClassWrapper);
FWWrapperCompatible(UIImageView, FWImageViewWrapper, FWViewWrapper, FWImageViewClassWrapper, FWViewClassWrapper);
FWWrapperCompatible(UIScrollView, FWScrollViewWrapper, FWViewWrapper, FWScrollViewClassWrapper, FWViewClassWrapper);
FWWrapperCompatible(UITableView, FWTableViewWrapper, FWScrollViewWrapper, FWTableViewClassWrapper, FWScrollViewClassWrapper);
FWWrapperCompatible(UITableViewHeaderFooterView, FWTableViewHeaderFooterViewWrapper, FWViewWrapper, FWTableViewHeaderFooterViewClassWrapper, FWViewClassWrapper);
FWWrapperCompatible(UITableViewCell, FWTableViewCellWrapper, FWViewWrapper, FWTableViewCellClassWrapper, FWViewClassWrapper);
FWWrapperCompatible(UICollectionView, FWCollectionViewWrapper, FWScrollViewWrapper, FWCollectionViewClassWrapper, FWScrollViewClassWrapper);
FWWrapperCompatible(UICollectionReusableView, FWCollectionReusableViewWrapper, FWViewWrapper, FWCollectionReusableViewClassWrapper, FWViewClassWrapper);
FWWrapperCompatible(UICollectionViewCell, FWCollectionViewCellWrapper, FWCollectionReusableViewWrapper, FWCollectionViewCellClassWrapper, FWCollectionReusableViewClassWrapper);
FWWrapperCompatible(UIControl, FWControlWrapper, FWViewWrapper, FWControlClassWrapper, FWViewClassWrapper);
FWWrapperCompatible(UIButton, FWButtonWrapper, FWControlWrapper, FWButtonClassWrapper, FWControlClassWrapper);
FWWrapperCompatible(UISwitch, FWSwitchWrapper, FWControlWrapper, FWSwitchClassWrapper, FWControlClassWrapper);
FWWrapperCompatible(UIPageControl, FWPageControlWrapper, FWControlWrapper, FWPageControlClassWrapper, FWControlClassWrapper);
FWWrapperCompatible(UISlider, FWSliderWrapper, FWControlWrapper, FWSliderClassWrapper, FWControlClassWrapper);
FWWrapperCompatible(UITextField, FWTextFieldWrapper, FWControlWrapper, FWTextFieldClassWrapper, FWControlClassWrapper);
FWWrapperCompatible(UITextView, FWTextViewWrapper, FWScrollViewWrapper, FWTextViewClassWrapper, FWScrollViewClassWrapper);
FWWrapperCompatible(UIGestureRecognizer, FWGestureRecognizerWrapper, FWObjectWrapper, FWGestureRecognizerClassWrapper, FWClassWrapper);
FWWrapperCompatible(UIBarItem, FWBarItemWrapper, FWObjectWrapper, FWBarItemClassWrapper, FWClassWrapper);
FWWrapperCompatible(UIBarButtonItem, FWBarButtonItemWrapper, FWBarItemWrapper, FWBarButtonItemClassWrapper, FWBarItemClassWrapper);
FWWrapperCompatible(UINavigationBar, FWNavigationBarWrapper, FWViewWrapper, FWNavigationBarClassWrapper, FWViewClassWrapper);
FWWrapperCompatible(UITabBar, FWTabBarWrapper, FWViewWrapper, FWTabBarClassWrapper, FWViewClassWrapper);
FWWrapperCompatible(UIToolbar, FWToolbarWrapper, FWViewWrapper, FWToolbarClassWrapper, FWViewClassWrapper);
FWWrapperCompatible(UISearchBar, FWSearchBarWrapper, FWViewWrapper, FWSearchBarClassWrapper, FWViewClassWrapper);
FWWrapperCompatible(UIWindow, FWWindowWrapper, FWViewWrapper, FWWindowClassWrapper, FWViewClassWrapper);
FWWrapperCompatible(UIViewController, FWViewControllerWrapper, FWObjectWrapper, FWViewControllerClassWrapper, FWClassWrapper);
FWWrapperCompatible(UINavigationController, FWNavigationControllerWrapper, FWViewControllerWrapper, FWNavigationControllerClassWrapper, FWViewControllerClassWrapper);
FWWrapperCompatible(UITabBarController, FWTabBarControllerWrapper, FWViewControllerWrapper, FWTabBarControllerClassWrapper, FWViewControllerClassWrapper);

NS_ASSUME_NONNULL_END
