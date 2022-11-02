//
//  FWAdaptive.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "FWAdaptive.h"
#import "FWNavigator.h"
#import "FWUIKit.h"
#import <objc/runtime.h>

#pragma mark - UIApplication+FWAdaptive

@implementation UIApplication (FWAdaptive)

+ (BOOL)fw_isDebug
{
#ifdef DEBUG
    return YES;
#else
    return NO;
#endif
}

@end

#pragma mark - UIDevice+FWAdaptive

@implementation UIDevice (FWAdaptive)

+ (BOOL)fw_isSimulator
{
#if TARGET_OS_SIMULATOR
    return YES;
#else
    return NO;
#endif
}

+ (BOOL)fw_isIphone
{
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
}

+ (BOOL)fw_isIpad
{
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}

+ (BOOL)fw_isMac
{
    if (@available(iOS 14.0, *)) {
        return NSProcessInfo.processInfo.isiOSAppOnMac ||
            NSProcessInfo.processInfo.isMacCatalystApp;
    }
    return NO;
}

+ (BOOL)fw_isLandscape
{
    return UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
}

+ (BOOL)fw_isDeviceLandscape
{
    return UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]);
}

+ (BOOL)fw_setDeviceOrientation:(UIDeviceOrientation)orientation
{
    if ([UIDevice currentDevice].orientation == orientation) {
        [UIViewController attemptRotationToDeviceOrientation];
        return NO;
    }
    
    #ifdef __IPHONE_16_0
    if (@available(iOS 16.0, *)) {
        UIInterfaceOrientationMask orientationMask = 0;
        switch (orientation) {
            case UIDeviceOrientationPortrait:
                orientationMask = UIInterfaceOrientationMaskPortrait;
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                orientationMask = UIInterfaceOrientationMaskPortraitUpsideDown;
                break;
            case UIDeviceOrientationLandscapeLeft:
                orientationMask = UIInterfaceOrientationMaskLandscapeLeft;
                break;
            case UIDeviceOrientationLandscapeRight:
                orientationMask = UIInterfaceOrientationMaskLandscapeRight;
                break;
            default:
                break;
        }
        
        UIWindowSceneGeometryPreferencesIOS *geometryPreferences = [[UIWindowSceneGeometryPreferencesIOS alloc] initWithInterfaceOrientations:orientationMask];
        [UIWindow.fw_mainScene requestGeometryUpdateWithPreferences:geometryPreferences errorHandler:nil];
        return YES;
    }
    #endif
    
    [[UIDevice currentDevice] setValue:@(orientation) forKey:@"orientation"];
    return YES;
}

+ (double)fw_iosVersion
{
    return [UIDevice currentDevice].systemVersion.doubleValue;
}

+ (BOOL)fw_isIos:(NSInteger)version
{
    return [self fw_iosVersion] >= version && [self fw_iosVersion] < (version + 1);
}

+ (BOOL)fw_isIosLater:(NSInteger)version
{
    return [self fw_iosVersion] >= version;
}

+ (CGSize)fw_deviceSize
{
    return CGSizeMake([self fw_deviceWidth], [self fw_deviceHeight]);
}

+ (CGFloat)fw_deviceWidth
{
    return MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
}

+ (CGFloat)fw_deviceHeight
{
    return MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
}

+ (CGSize)fw_deviceResolution
{
    return CGSizeMake([self fw_deviceWidth] * [UIScreen mainScreen].scale, [self fw_deviceHeight] * [UIScreen mainScreen].scale);
}

@end

#pragma mark - UIScreen+FWAdaptive

CGFloat FWRelativeValue(CGFloat value) {
    return [UIScreen fw_relativeValue:value];
}

CGFloat FWRelativeHeight(CGFloat value) {
    return [UIScreen fw_relativeHeight:value];
}

CGFloat FWFixedValue(CGFloat value) {
    return [UIScreen fw_fixedValue:value];
}

CGFloat FWFixedHeight(CGFloat value) {
    return [UIScreen fw_fixedHeight:value];
}

CGSize FWRelativeSize(CGSize size) {
    return CGSizeMake(FWRelativeValue(size.width), FWRelativeValue(size.height));
}

CGPoint FWRelativePoint(CGPoint point) {
    return CGPointMake(FWRelativeValue(point.x), FWRelativeValue(point.y));
}

CGRect FWRelativeRect(CGRect rect) {
    return CGRectMake(FWRelativeValue(rect.origin.x), FWRelativeValue(rect.origin.y), FWRelativeValue(rect.size.width), FWRelativeValue(rect.size.height));
}

UIEdgeInsets FWRelativeInsets(UIEdgeInsets insets) {
    return UIEdgeInsetsMake(FWRelativeValue(insets.top), FWRelativeValue(insets.left), FWRelativeValue(insets.bottom), FWRelativeValue(insets.right));
}

CGFloat FWFlatValue(CGFloat value) {
    return [UIScreen fw_flatValue:value];
}

CGFloat FWFlatScale(CGFloat value, CGFloat scale) {
    return [UIScreen fw_flatValue:value scale:scale];
}

static CGFloat fwStaticReferenceWidth = 375;
static CGFloat fwStaticReferenceHeight = 812;

@implementation UIScreen (FWAdaptive)

+ (CGSize)fw_screenSize
{
    return [UIScreen mainScreen].bounds.size;
}

+ (CGFloat)fw_screenWidth
{
    return [UIScreen mainScreen].bounds.size.width;
}

+ (CGFloat)fw_screenHeight
{
    return [UIScreen mainScreen].bounds.size.height;
}

+ (CGFloat)fw_screenScale
{
    return [UIScreen mainScreen].scale;
}

+ (BOOL)fw_isScreenInch:(FWScreenInch)inch
{
    switch (inch) {
        case FWScreenInch35:
            return CGSizeEqualToSize(CGSizeMake(320, 480), [UIDevice fw_deviceSize]);
        case FWScreenInch40:
            return CGSizeEqualToSize(CGSizeMake(320, 568), [UIDevice fw_deviceSize]);
        case FWScreenInch47:
            return CGSizeEqualToSize(CGSizeMake(375, 667), [UIDevice fw_deviceSize]);
        case FWScreenInch54:
            return CGSizeEqualToSize(CGSizeMake(360, 780), [UIDevice fw_deviceSize]);
        case FWScreenInch55:
            return CGSizeEqualToSize(CGSizeMake(414, 736), [UIDevice fw_deviceSize]);
        case FWScreenInch58:
            return CGSizeEqualToSize(CGSizeMake(375, 812), [UIDevice fw_deviceSize]);
        case FWScreenInch61:
            return CGSizeEqualToSize(CGSizeMake(828, 1792), [UIDevice fw_deviceResolution])
                || CGSizeEqualToSize(CGSizeMake(390, 844), [UIDevice fw_deviceSize]);
        case FWScreenInch65:
            return CGSizeEqualToSize(CGSizeMake(1242, 2688), [UIDevice fw_deviceResolution]);
        case FWScreenInch67:
            return CGSizeEqualToSize(CGSizeMake(428, 926), [UIDevice fw_deviceSize]);
        default:
            return NO;
    }
}

+ (BOOL)fw_isNotchedScreen
{
    return [self fw_safeAreaInsets].bottom > 0;
}

+ (CGFloat)fw_pixelOne
{
    return 1 / UIScreen.mainScreen.scale;
}

+ (BOOL)fw_hasSafeAreaInsets
{
    return [self fw_safeAreaInsets].bottom > 0;
}

+ (UIEdgeInsets)fw_safeAreaInsets
{
    static UIWindow *window = nil;
    UIWindow *mainWindow = UIWindow.fw_mainWindow;
    if (mainWindow) {
        if (window) window = nil;
    } else {
        if (!window) window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
        mainWindow = window;
    }
    return mainWindow.safeAreaInsets;
}

+ (CGFloat)fw_statusBarHeight
{
    if (!UIApplication.sharedApplication.statusBarHidden) {
        return UIApplication.sharedApplication.statusBarFrame.size.height;
    }
    
    if ([UIDevice fw_isIpad]) {
        return [self fw_isNotchedScreen] ? 24 : 20;
    }
    
    if ([UIDevice fw_isLandscape]) { return 0; }
    if (![self fw_isNotchedScreen]) { return 20; }
    if ([[UIDevice fw_deviceModel] isEqualToString:@"iPhone12,1"]) { return 48; }
    if (CGSizeEqualToSize(CGSizeMake(390, 844), [UIDevice fw_deviceSize])) { return 47; }
    if ([self fw_isScreenInch:FWScreenInch67]) { return 47; }
    if ([self fw_isScreenInch:FWScreenInch54] && [UIDevice fw_iosVersion] >= 15.0) { return 50; }
    return 44;
}

+ (CGFloat)fw_navigationBarHeight
{
    if ([UIDevice fw_isIpad]) {
        return [UIDevice fw_iosVersion] >= 12.0 ? 50 : 44;
    }
    
    CGFloat height = 44;
    if ([UIDevice fw_isLandscape]) {
        height = [self fw_isRegularScreen] ? 44 : 32;
    }
    return height;
}

+ (CGFloat)fw_topBarHeight
{
    return [self fw_statusBarHeight] + [self fw_navigationBarHeight];
}

+ (CGFloat)fw_tabBarHeight
{
    if ([UIDevice fw_isIpad]) {
        if ([self fw_isNotchedScreen]) { return 65; }
        return [UIDevice fw_iosVersion] >= 12.0 ? 50 : 49;
    }
    
    CGFloat height = 49;
    if ([UIDevice fw_isLandscape]) {
        height = [self fw_isRegularScreen] ? 49 : 32;
    }
    return height + [self fw_safeAreaInsets].bottom;
}

+ (CGFloat)fw_toolBarHeight
{
    if ([UIDevice fw_isIpad]) {
        if ([UIScreen fw_isNotchedScreen]) { return 70; }
        return [UIDevice fw_iosVersion] >= 12.0 ? 50 : 44;
    }
    
    CGFloat height = 44;
    if ([UIDevice fw_isLandscape]) {
        height = [self fw_isRegularScreen] ? 44 : 32;
    }
    return height + [self fw_safeAreaInsets].bottom;
}

+ (BOOL)fw_isRegularScreen
{
    // https://github.com/Tencent/QMUI_iOS
    if ([UIDevice fw_isIpad]) { return YES; }
    
    BOOL isZoomedMode = NO;
    if ([UIDevice fw_isIphone]) {
        CGFloat nativeScale = UIScreen.mainScreen.nativeScale;
        CGFloat scale = UIScreen.mainScreen.scale;
        if (CGSizeEqualToSize(UIScreen.mainScreen.nativeBounds.size, CGSizeMake(1080, 1920))) {
            scale /= 1.15;
        }
        isZoomedMode = nativeScale > scale;
    }
    if (isZoomedMode) return NO;
    
    if ([self fw_isScreenInch:FWScreenInch67] ||
        [self fw_isScreenInch:FWScreenInch65] ||
        [self fw_isScreenInch:FWScreenInch61] ||
        [self fw_isScreenInch:FWScreenInch55]) {
        return YES;
    }
    return NO;
}

+ (CGSize)fw_referenceSize
{
    return CGSizeMake(fwStaticReferenceWidth, fwStaticReferenceHeight);
}

+ (void)setFw_referenceSize:(CGSize)size
{
    fwStaticReferenceWidth = size.width;
    fwStaticReferenceHeight = size.height;
}

+ (CGFloat)fw_relativeScale
{
    if ([UIScreen mainScreen].bounds.size.height > [UIScreen mainScreen].bounds.size.width) {
        return [UIScreen mainScreen].bounds.size.width / fwStaticReferenceWidth;
    } else {
        return [UIScreen mainScreen].bounds.size.width / fwStaticReferenceHeight;
    }
}

+ (CGFloat)fw_relativeHeightScale
{
    if ([UIScreen mainScreen].bounds.size.height > [UIScreen mainScreen].bounds.size.width) {
        return [UIScreen mainScreen].bounds.size.height / fwStaticReferenceHeight;
    } else {
        return [UIScreen mainScreen].bounds.size.height / fwStaticReferenceWidth;
    }
}

+ (CGFloat)fw_relativeValue:(CGFloat)value
{
    return value * [self fw_relativeScale];
}

+ (CGFloat)fw_relativeHeight:(CGFloat)value
{
    return value * [self fw_relativeHeightScale];
}

+ (CGFloat)fw_fixedValue:(CGFloat)value
{
    return value / [self fw_relativeScale];
}

+ (CGFloat)fw_fixedHeight:(CGFloat)value
{
    return value / [self fw_relativeHeightScale];
}

+ (CGFloat)fw_flatValue:(CGFloat)value
{
    return [self fw_flatValue:value scale:0];
}

+ (CGFloat)fw_flatValue:(CGFloat)value scale:(CGFloat)scale
{
    value = (value == CGFLOAT_MIN) ? 0 : value;
    scale = scale ?: [UIScreen mainScreen].scale;
    CGFloat flattedValue = ceil(value * scale) / scale;
    return flattedValue;
}

@end

#pragma mark - UIView+FWAdaptive

@implementation UIView (FWAdaptive)

- (BOOL)fw_autoScaleTransform
{
    return [objc_getAssociatedObject(self, @selector(fw_autoScaleTransform)) boolValue];
}

- (void)setFw_autoScaleTransform:(BOOL)autoScale
{
    objc_setAssociatedObject(self, @selector(fw_autoScaleTransform), @(autoScale), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (autoScale) {
        CGFloat scaleX = UIScreen.fw_relativeScale;
        CGFloat scaleY = UIScreen.fw_relativeHeightScale;
        if (scaleX > scaleY) {
            self.transform = CGAffineTransformMakeScale(scaleY, scaleY);
        } else {
            self.transform = CGAffineTransformMakeScale(scaleX, scaleX);
        }
    } else {
        self.transform = CGAffineTransformIdentity;
    }
}

@end

#pragma mark - UIViewController+FWAdaptive

@implementation UIViewController (FWAdaptive)

- (CGFloat)fw_statusBarHeight
{
    // 1. 导航栏隐藏时不占用布局高度始终为0
    if (!self.navigationController || self.navigationController.navigationBarHidden) return 0.0;
    
    // 2. 竖屏且为iOS13+弹出pageSheet样式时布局高度为0
    BOOL isPortrait = !UIDevice.fw_isLandscape;
    if (isPortrait && self.fw_isPageSheet) return 0.0;
    
    // 3. 竖屏且异形屏，导航栏显示时布局高度固定
    if (isPortrait && UIScreen.fw_isNotchedScreen) {
        // 也可以这样计算：CGRectGetMinY(self.navigationController.navigationBar.frame)
        return UIScreen.fw_statusBarHeight;
    }
    
    // 4. 其他情况状态栏显示时布局高度固定，隐藏时布局高度为0
    if (UIApplication.sharedApplication.statusBarHidden) return 0.0;
    return [UIApplication sharedApplication].statusBarFrame.size.height;
    
    /*
     // 系统状态栏可见高度算法：
     // 1. 竖屏且为iOS13+弹出pageSheet样式时安全高度为0
     if (![UIDevice fw_isLandscape] && self.fw_isPageSheet) return 0.0;
     
     // 2. 其他情况状态栏显示时安全高度固定，隐藏时安全高度为0
     if (UIApplication.sharedApplication.statusBarHidden) return 0.0;
     return [UIApplication sharedApplication].statusBarFrame.size.height;
     */
}

- (CGFloat)fw_navigationBarHeight
{
    // 系统导航栏
    if (!self.navigationController || self.navigationController.navigationBarHidden) return 0.0;
    return self.navigationController.navigationBar.frame.size.height;
}

- (CGFloat)fw_topBarHeight
{
    // 通常情况下导航栏显示时可以这样计算：CGRectGetMaxY(self.navigationController.navigationBar.frame)
    return [self fw_statusBarHeight] + [self fw_navigationBarHeight];
    
    /*
     // 系统顶部栏可见高度算法：
     // 1. 导航栏隐藏时和状态栏安全高度相同
     if (!self.navigationController || self.navigationController.navigationBarHidden) {
         return [self fw_statusBarHeight];
     }
     
     // 2. 导航栏显示时和顶部栏布局高度相同
     return [self fw_topBarHeight];
     */
}

- (CGFloat)fw_tabBarHeight
{
    if (!self.tabBarController || self.tabBarController.tabBar.hidden) return 0.0;
    if (self.hidesBottomBarWhenPushed && !self.fw_isRoot) return 0.0;
    return self.tabBarController.tabBar.frame.size.height;
}

- (CGFloat)fw_toolBarHeight
{
    if (!self.navigationController || self.navigationController.toolbarHidden) return 0.0;
    // 如果未同时显示标签栏，高度需要加上安全区域高度
    CGFloat height = self.navigationController.toolbar.frame.size.height;
    if (!self.tabBarController || self.tabBarController.tabBar.hidden ||
        (self.hidesBottomBarWhenPushed && !self.fw_isRoot)) {
        height += UIScreen.fw_safeAreaInsets.bottom;
    }
    return height;
}

- (CGFloat)fw_bottomBarHeight
{
    return [self fw_tabBarHeight] + [self fw_toolBarHeight];
}

@end
