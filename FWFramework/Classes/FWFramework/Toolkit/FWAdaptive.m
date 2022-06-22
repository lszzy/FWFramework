/**
 @header     FWAdaptive.m
 @indexgroup FWFramework
      FWAdaptive
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/8
 */

#import "FWAdaptive.h"
#import "FWNavigation.h"
#import "FWToolkit.h"
#import "FWUIKit.h"

#pragma mark - FWApplicationClassWrapper+FWAdaptive

@implementation FWApplicationClassWrapper (FWAdaptive)

- (BOOL)isDebug
{
#ifdef DEBUG
    return YES;
#else
    return NO;
#endif
}

@end

#pragma mark - FWDeviceClassWrapper+FWAdaptive

@implementation FWDeviceClassWrapper (FWAdaptive)

- (BOOL)isSimulator
{
#if TARGET_OS_SIMULATOR
    return YES;
#else
    return NO;
#endif
}

- (BOOL)isIphone
{
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
}

- (BOOL)isIpad
{
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}

- (BOOL)isMac
{
#if __IPHONE_14_0
    if (@available(iOS 14.0, *)) {
        return NSProcessInfo.processInfo.isiOSAppOnMac ||
            NSProcessInfo.processInfo.isMacCatalystApp;
    }
#endif
    return NO;
}

- (BOOL)isLandscape
{
    return UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
}

- (BOOL)isDeviceLandscape
{
    return UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]);
}

- (BOOL)setDeviceOrientation:(UIDeviceOrientation)orientation
{
    if ([UIDevice currentDevice].orientation == orientation) {
        [UIViewController attemptRotationToDeviceOrientation];
        return NO;
    }
    
    [[UIDevice currentDevice] setValue:@(orientation) forKey:@"orientation"];
    return YES;
}

- (double)iosVersion
{
    return [UIDevice currentDevice].systemVersion.doubleValue;
}

- (BOOL)isIos:(NSInteger)version
{
    return [self iosVersion] >= version && [self iosVersion] < (version + 1);
}

- (BOOL)isIosLater:(NSInteger)version
{
    return [self iosVersion] >= version;
}

- (CGSize)deviceSize
{
    return CGSizeMake([self deviceWidth], [self deviceHeight]);
}

- (CGFloat)deviceWidth
{
    return MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
}

- (CGFloat)deviceHeight
{
    return MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
}

- (CGSize)deviceResolution
{
    return CGSizeMake([self deviceWidth] * [UIScreen mainScreen].scale, [self deviceHeight] * [UIScreen mainScreen].scale);
}

@end

#pragma mark - FWScreenClassWrapper+FWAdaptive

CGFloat FWRelativeValue(CGFloat value) {
    return [UIScreen.fw relativeValue:value];
}

CGFloat FWRelativeHeight(CGFloat value) {
    return [UIScreen.fw relativeHeight:value];
}

CGFloat FWFixedValue(CGFloat value) {
    return [UIScreen.fw fixedValue:value];
}

CGFloat FWFixedHeight(CGFloat value) {
    return [UIScreen.fw fixedHeight:value];
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
    return [UIScreen.fw flatValue:value];
}

CGFloat FWFlatScale(CGFloat value, CGFloat scale) {
    return [UIScreen.fw flatValue:value scale:scale];
}

static CGFloat fwStaticReferenceWidth = 375;
static CGFloat fwStaticReferenceHeight = 812;

@implementation FWScreenClassWrapper (FWAdaptive)

- (CGSize)screenSize
{
    return [UIScreen mainScreen].bounds.size;
}

- (CGFloat)screenWidth
{
    return [UIScreen mainScreen].bounds.size.width;
}

- (CGFloat)screenHeight
{
    return [UIScreen mainScreen].bounds.size.height;
}

- (CGFloat)screenScale
{
    return [UIScreen mainScreen].scale;
}

- (BOOL)isScreenInch:(FWScreenInch)inch
{
    switch (inch) {
        case FWScreenInch35:
            return CGSizeEqualToSize(CGSizeMake(320, 480), [UIDevice.fw deviceSize]);
        case FWScreenInch40:
            return CGSizeEqualToSize(CGSizeMake(320, 568), [UIDevice.fw deviceSize]);
        case FWScreenInch47:
            return CGSizeEqualToSize(CGSizeMake(375, 667), [UIDevice.fw deviceSize]);
        case FWScreenInch54:
            return CGSizeEqualToSize(CGSizeMake(360, 780), [UIDevice.fw deviceSize]);
        case FWScreenInch55:
            return CGSizeEqualToSize(CGSizeMake(414, 736), [UIDevice.fw deviceSize]);
        case FWScreenInch58:
            return CGSizeEqualToSize(CGSizeMake(375, 812), [UIDevice.fw deviceSize]);
        case FWScreenInch61:
            return CGSizeEqualToSize(CGSizeMake(828, 1792), [UIDevice.fw deviceResolution])
                || CGSizeEqualToSize(CGSizeMake(390, 844), [UIDevice.fw deviceSize]);
        case FWScreenInch65:
            return CGSizeEqualToSize(CGSizeMake(1242, 2688), [UIDevice.fw deviceResolution]);
        case FWScreenInch67:
            return CGSizeEqualToSize(CGSizeMake(428, 926), [UIDevice.fw deviceSize]);
        default:
            return NO;
    }
}

- (BOOL)isNotchedScreen
{
    return [self safeAreaInsets].bottom > 0;
}

- (CGFloat)pixelOne
{
    return 1 / UIScreen.mainScreen.scale;
}

- (BOOL)hasSafeAreaInsets
{
    return [self safeAreaInsets].bottom > 0;
}

- (UIEdgeInsets)safeAreaInsets
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

- (CGFloat)statusBarHeight
{
    if (!UIApplication.sharedApplication.statusBarHidden) {
        return UIApplication.sharedApplication.statusBarFrame.size.height;
    }
    
    if ([UIDevice.fw isIpad]) {
        return [self isNotchedScreen] ? 24 : 20;
    }
    
    if ([UIDevice.fw isLandscape]) { return 0; }
    if (![self isNotchedScreen]) { return 20; }
    if ([[UIDevice.fw deviceModel] isEqualToString:@"iPhone12,1"]) { return 48; }
    if (CGSizeEqualToSize(CGSizeMake(390, 844), [UIDevice.fw deviceSize])) { return 47; }
    if ([self isScreenInch:FWScreenInch67]) { return 47; }
    return 44;
}

- (CGFloat)navigationBarHeight
{
    if ([UIDevice.fw isIpad]) {
        return [UIDevice.fw iosVersion] >= 12.0 ? 50 : 44;
    }
    
    CGFloat height = 44;
    if ([UIDevice.fw isLandscape]) {
        height = [self isRegularScreen] ? 44 : 32;
    }
    return height;
}

- (CGFloat)topBarHeight
{
    return [self statusBarHeight] + [self navigationBarHeight];
}

- (CGFloat)tabBarHeight
{
    if ([UIDevice.fw isIpad]) {
        if ([self isNotchedScreen]) { return 65; }
        return [UIDevice.fw iosVersion] >= 12.0 ? 50 : 49;
    }
    
    CGFloat height = 49;
    if ([UIDevice.fw isLandscape]) {
        height = [self isRegularScreen] ? 49 : 32;
    }
    return height + [self safeAreaInsets].bottom;
}

- (CGFloat)toolBarHeight
{
    if ([UIDevice.fw isIpad]) {
        if ([UIScreen.fw isNotchedScreen]) { return 70; }
        return [UIDevice.fw iosVersion] >= 12.0 ? 50 : 44;
    }
    
    CGFloat height = 44;
    if ([UIDevice.fw isLandscape]) {
        height = [self isRegularScreen] ? 44 : 32;
    }
    return height + [self safeAreaInsets].bottom;
}

- (BOOL)isRegularScreen
{
    // https://github.com/Tencent/QMUI_iOS
    if ([UIDevice.fw isIpad]) { return YES; }
    
    BOOL isZoomedMode = NO;
    if ([UIDevice.fw isIphone]) {
        CGFloat nativeScale = UIScreen.mainScreen.nativeScale;
        CGFloat scale = UIScreen.mainScreen.scale;
        if (CGSizeEqualToSize(UIScreen.mainScreen.nativeBounds.size, CGSizeMake(1080, 1920))) {
            scale /= 1.15;
        }
        isZoomedMode = nativeScale > scale;
    }
    if (isZoomedMode) return NO;
    
    if ([self isScreenInch:FWScreenInch67] ||
        [self isScreenInch:FWScreenInch65] ||
        [self isScreenInch:FWScreenInch61] ||
        [self isScreenInch:FWScreenInch55]) {
        return YES;
    }
    return NO;
}

- (CGSize)referenceSize
{
    return CGSizeMake(fwStaticReferenceWidth, fwStaticReferenceHeight);
}

- (void)setReferenceSize:(CGSize)size
{
    fwStaticReferenceWidth = size.width;
    fwStaticReferenceHeight = size.height;
}

- (CGFloat)relativeScale
{
    if ([UIScreen mainScreen].bounds.size.height > [UIScreen mainScreen].bounds.size.width) {
        return [UIScreen mainScreen].bounds.size.width / fwStaticReferenceWidth;
    } else {
        return [UIScreen mainScreen].bounds.size.width / fwStaticReferenceHeight;
    }
}

- (CGFloat)relativeHeightScale
{
    if ([UIScreen mainScreen].bounds.size.height > [UIScreen mainScreen].bounds.size.width) {
        return [UIScreen mainScreen].bounds.size.height / fwStaticReferenceHeight;
    } else {
        return [UIScreen mainScreen].bounds.size.height / fwStaticReferenceWidth;
    }
}

- (CGFloat)relativeValue:(CGFloat)value
{
    return value * [self relativeScale];
}

- (CGFloat)relativeHeight:(CGFloat)value
{
    return value * [self relativeHeightScale];
}

- (CGFloat)fixedValue:(CGFloat)value
{
    return value / [self relativeScale];
}

- (CGFloat)fixedHeight:(CGFloat)value
{
    return value / [self relativeHeightScale];
}

- (CGFloat)flatValue:(CGFloat)value
{
    return [self flatValue:value scale:0];
}

- (CGFloat)flatValue:(CGFloat)value scale:(CGFloat)scale
{
    value = (value == CGFLOAT_MIN) ? 0 : value;
    scale = scale ?: [UIScreen mainScreen].scale;
    CGFloat flattedValue = ceil(value * scale) / scale;
    return flattedValue;
}

@end

#pragma mark - FWViewControllerWrapper+FWAdaptive

@implementation FWViewControllerWrapper (FWAdaptive)

- (CGFloat)statusBarHeight
{
    // 1. 导航栏隐藏时不占用布局高度始终为0
    if (!self.base.navigationController || self.base.navigationController.navigationBarHidden) return 0.0;
    
    // 2. 竖屏且为iOS13+弹出pageSheet样式时布局高度为0
    BOOL isPortrait = !UIDevice.fw.isLandscape;
    if (isPortrait && self.base.fw.isPageSheet) return 0.0;
    
    // 3. 竖屏且异形屏，导航栏显示时布局高度固定
    if (isPortrait && UIScreen.fw.isNotchedScreen) {
        // 也可以这样计算：CGRectGetMinY(self.base.navigationController.navigationBar.frame)
        return UIScreen.fw.statusBarHeight;
    }
    
    // 4. 其他情况状态栏显示时布局高度固定，隐藏时布局高度为0
    if (UIApplication.sharedApplication.statusBarHidden) return 0.0;
    return [UIApplication sharedApplication].statusBarFrame.size.height;
    
    /*
     // 系统状态栏可见高度算法：
     // 1. 竖屏且为iOS13+弹出pageSheet样式时安全高度为0
     if (![UIDevice.fw isLandscape] && self.base.fw.isPageSheet) return 0.0;
     
     // 2. 其他情况状态栏显示时安全高度固定，隐藏时安全高度为0
     if (UIApplication.sharedApplication.statusBarHidden) return 0.0;
     return [UIApplication sharedApplication].statusBarFrame.size.height;
     */
}

- (CGFloat)navigationBarHeight
{
    // 系统导航栏
    if (!self.base.navigationController || self.base.navigationController.navigationBarHidden) return 0.0;
    return self.base.navigationController.navigationBar.frame.size.height;
}

- (CGFloat)topBarHeight
{
    // 通常情况下导航栏显示时可以这样计算：CGRectGetMaxY(self.base.navigationController.navigationBar.frame)
    return [self statusBarHeight] + [self navigationBarHeight];
    
    /*
     // 系统顶部栏可见高度算法：
     // 1. 导航栏隐藏时和状态栏安全高度相同
     if (!self.base.navigationController || self.base.navigationController.navigationBarHidden) {
         return [self statusBarHeight];
     }
     
     // 2. 导航栏显示时和顶部栏布局高度相同
     return [self topBarHeight];
     */
}

- (CGFloat)tabBarHeight
{
    if (!self.base.tabBarController || self.base.tabBarController.tabBar.hidden) return 0.0;
    return self.base.tabBarController.tabBar.frame.size.height;
}

- (CGFloat)toolBarHeight
{
    if (!self.base.navigationController || self.base.navigationController.toolbarHidden) return 0.0;
    // 如果未同时显示标签栏，高度需要加上安全区域高度
    CGFloat height = self.base.navigationController.toolbar.frame.size.height;
    if (!self.base.tabBarController || self.base.tabBarController.tabBar.hidden) {
        height += UIScreen.fw.safeAreaInsets.bottom;
    }
    return height;
}

- (CGFloat)bottomBarHeight
{
    return [self tabBarHeight] + [self toolBarHeight];
}

@end
