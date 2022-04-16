/**
 @header     FWWrapper.m
 @indexgroup FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-11
 */

#import "FWWrapper.h"
#import "FWAppearance.h"
#import <objc/runtime.h>

#pragma mark - FWObjectWrapper

@implementation FWObjectWrapper

+ (instancetype)wrapper:(id)base {
    id wrapper = objc_getAssociatedObject(base, @selector(fw));
    if (wrapper) return wrapper;
    
    Class wrapperClass = [self class];
    // 兼容_UIAppearance对象，自动查找对应包装器类
    if ([base isKindOfClass:NSClassFromString(@"_UIAppearance")]) {
        Class appearanceClass = [FWAppearance classForAppearance:base];
        wrapperClass = [[appearanceClass fw] wrapperClass];
    }
    
    wrapper = [[wrapperClass alloc] init:base];
    objc_setAssociatedObject(base, @selector(fw), wrapper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return wrapper;
}

- (instancetype)init:(id)base {
    self = [super init];
    if (self) {
        _base = base;
    }
    return self;
}

- (Class)wrapperClass {
    return [FWClassWrapper class];
}

@end

@implementation NSObject (FWObjectWrapper)

- (FWObjectWrapper *)fw {
    return [FWObjectWrapper wrapper:self];
}

@end

#pragma mark - FWClassWrapper

@implementation FWClassWrapper

+ (instancetype)wrapper:(Class)base {
    return [[self alloc] init:base];
}

- (instancetype)init:(Class)base {
    self = [super init];
    if (self) {
        _base = base;
    }
    return self;
}

- (Class)wrapperClass {
    return [FWObjectWrapper class];
}

@end

@implementation NSObject (FWClassWrapper)

+ (FWClassWrapper *)fw {
    return [FWClassWrapper wrapper:self];
}

@end

#pragma mark - FWWrapperCompatible

FWDefWrapper(CALayer, FWLayerWrapper, FWLayerClassWrapper);
FWDefWrapper(CAGradientLayer, FWGradientLayerWrapper, FWGradientLayerClassWrapper);
FWDefWrapper(CAAnimation, FWAnimationWrapper, FWAnimationClassWrapper);
FWDefWrapper(CADisplayLink, FWDisplayLinkWrapper, FWDisplayLinkClassWrapper);

FWDefWrapper(NSString, FWStringWrapper, FWStringClassWrapper);
FWDefWrapper(NSAttributedString, FWAttributedStringWrapper, FWAttributedStringClassWrapper);
FWDefWrapper(NSNumber, FWNumberWrapper, FWNumberClassWrapper);
FWDefWrapper(NSData, FWDataWrapper, FWDataClassWrapper);
FWDefWrapper(NSDate, FWDateWrapper, FWDateClassWrapper);
FWDefWrapper(NSURL, FWURLWrapper, FWURLClassWrapper);
FWDefWrapper(NSURLRequest, FWURLRequestWrapper, FWURLRequestClassWrapper);
FWDefWrapper(NSBundle, FWBundleWrapper, FWBundleClassWrapper);
FWDefWrapper(NSTimer, FWTimerWrapper, FWTimerClassWrapper);
FWDefWrapper(NSUserDefaults, FWUserDefaultsWrapper, FWUserDefaultsClassWrapper);
FWDefWrapper(NSFileManager, FWFileManagerWrapper, FWFileManagerClassWrapper);
FWDefWrapper(NSArray, FWArrayWrapper, FWArrayClassWrapper);
FWDefWrapper(NSMutableArray, FWMutableArrayWrapper, FWMutableArrayClassWrapper);
FWDefWrapper(NSSet, FWSetWrapper, FWSetClassWrapper);
FWDefWrapper(NSMutableSet, FWMutableSetWrapper, FWMutableSetClassWrapper);
FWDefWrapper(NSDictionary, FWDictionaryWrapper, FWDictionaryClassWrapper);
FWDefWrapper(NSMutableDictionary, FWMutableDictionaryWrapper, FWMutableDictionaryClassWrapper);

FWDefWrapper(UIApplication, FWApplicationWrapper, FWApplicationClassWrapper);
FWDefWrapper(UIBezierPath, FWBezierPathWrapper, FWBezierPathClassWrapper);
FWDefWrapper(UIDevice, FWDeviceWrapper, FWDeviceClassWrapper);
FWDefWrapper(UIScreen, FWScreenWrapper, FWScreenClassWrapper);
FWDefWrapper(UIImage, FWImageWrapper, FWImageClassWrapper);
FWDefWrapper(UIImageAsset, FWImageAssetWrapper, FWImageAssetClassWrapper);
FWDefWrapper(UIFont, FWFontWrapper, FWFontClassWrapper);
FWDefWrapper(UIColor, FWColorWrapper, FWColorClassWrapper);
FWDefWrapper(UIView, FWViewWrapper, FWViewClassWrapper);
FWDefWrapper(UILabel, FWLabelWrapper, FWLabelClassWrapper);
FWDefWrapper(UIImageView, FWImageViewWrapper, FWImageViewClassWrapper);
FWDefWrapper(UIScrollView, FWScrollViewWrapper, FWScrollViewClassWrapper);
FWDefWrapper(UITableView, FWTableViewWrapper, FWTableViewClassWrapper);
FWDefWrapper(UITableViewHeaderFooterView, FWTableViewHeaderFooterViewWrapper, FWTableViewHeaderFooterViewClassWrapper);
FWDefWrapper(UITableViewCell, FWTableViewCellWrapper, FWTableViewCellClassWrapper);
FWDefWrapper(UICollectionView, FWCollectionViewWrapper, FWCollectionViewClassWrapper);
FWDefWrapper(UICollectionReusableView, FWCollectionReusableViewWrapper, FWCollectionReusableViewClassWrapper);
FWDefWrapper(UICollectionViewCell, FWCollectionViewCellWrapper, FWCollectionViewCellClassWrapper);
FWDefWrapper(UIControl, FWControlWrapper, FWControlClassWrapper);
FWDefWrapper(UIButton, FWButtonWrapper, FWButtonClassWrapper);
FWDefWrapper(UISwitch, FWSwitchWrapper, FWSwitchClassWrapper);
FWDefWrapper(UIPageControl, FWPageControlWrapper, FWPageControlClassWrapper);
FWDefWrapper(UISlider, FWSliderWrapper, FWSliderClassWrapper);
FWDefWrapper(UITextField, FWTextFieldWrapper, FWTextFieldClassWrapper);
FWDefWrapper(UITextView, FWTextViewWrapper, FWTextViewClassWrapper);
FWDefWrapper(UIGestureRecognizer, FWGestureRecognizerWrapper, FWGestureRecognizerClassWrapper);
FWDefWrapper(UIBarItem, FWBarItemWrapper, FWBarItemClassWrapper);
FWDefWrapper(UIBarButtonItem, FWBarButtonItemWrapper, FWBarButtonItemClassWrapper);
FWDefWrapper(UINavigationBar, FWNavigationBarWrapper, FWNavigationBarClassWrapper);
FWDefWrapper(UITabBar, FWTabBarWrapper, FWTabBarClassWrapper);
FWDefWrapper(UIToolbar, FWToolbarWrapper, FWToolbarClassWrapper);
FWDefWrapper(UISearchBar, FWSearchBarWrapper, FWSearchBarClassWrapper);
FWDefWrapper(UIWindow, FWWindowWrapper, FWWindowClassWrapper);
FWDefWrapper(UIViewController, FWViewControllerWrapper, FWViewControllerClassWrapper);
FWDefWrapper(UINavigationController, FWNavigationControllerWrapper, FWNavigationControllerClassWrapper);
FWDefWrapper(UITabBarController, FWTabBarControllerWrapper, FWTabBarControllerClassWrapper);
