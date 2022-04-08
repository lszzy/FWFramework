/**
 @header     FWWrapper.m
 @indexgroup FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-11
 */

#import "FWWrapper.h"

#pragma mark - FWObjectWrapper

@implementation FWObjectWrapper

- (instancetype)init:(id)base {
    self = [super init];
    if (self) {
        _base = base;
    }
    return self;
}

@end

@implementation NSObject (FWObjectWrapper)

- (FWObjectWrapper *)fw {
    return [[FWObjectWrapper alloc] init:self];
}

@end

#pragma mark - FWClassWrapper

@implementation FWClassWrapper

- (instancetype)init:(Class)base {
    self = [super init];
    if (self) {
        _base = base;
    }
    return self;
}

@end

@implementation NSObject (FWClassWrapper)

+ (FWClassWrapper *)fw {
    return [[FWClassWrapper alloc] init:self];
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
FWDefWrapper(NSArray, FWArrayWrapper, FWArrayClassWrapper);
FWDefWrapper(NSMutableArray, FWMutableArrayWrapper, FWMutableArrayClassWrapper);
FWDefWrapper(NSDictionary, FWDictionaryWrapper, FWDictionaryClassWrapper);
FWDefWrapper(NSMutableDictionary, FWMutableDictionaryWrapper, FWMutableDictionaryClassWrapper);
FWDefWrapper(NSURL, FWURLWrapper, FWURLClassWrapper);
FWDefWrapper(NSURLRequest, FWURLRequestWrapper, FWURLRequestClassWrapper);
FWDefWrapper(NSBundle, FWBundleWrapper, FWBundleClassWrapper);
FWDefWrapper(NSTimer, FWTimerWrapper, FWTimerClassWrapper);
FWDefWrapper(NSUserDefaults, FWUserDefaultsWrapper, FWUserDefaultsClassWrapper);
FWDefWrapper(NSFileManager, FWFileManagerWrapper, FWFileManagerClassWrapper);

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
FWDefWrapper(UIBarButtonItem, FWBarButtonItemWrapper, FWBarButtonItemClassWrapper);
FWDefWrapper(UINavigationBar, FWNavigationBarWrapper, FWNavigationBarClassWrapper);
FWDefWrapper(UITabBar, FWTabBarWrapper, FWTabBarClassWrapper);
FWDefWrapper(UIToolbar, FWToolbarWrapper, FWToolbarClassWrapper);
FWDefWrapper(UISearchBar, FWSearchBarWrapper, FWSearchBarClassWrapper);
FWDefWrapper(UIWindow, FWWindowWrapper, FWWindowClassWrapper);
FWDefWrapper(UIViewController, FWViewControllerWrapper, FWViewControllerClassWrapper);
FWDefWrapper(UINavigationController, FWNavigationControllerWrapper, FWNavigationControllerClassWrapper);
FWDefWrapper(UITabBarController, FWTabBarControllerWrapper, FWTabBarControllerClassWrapper);
