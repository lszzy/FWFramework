/*!
 @header     FWToolkitManager.m
 @indexgroup FWFramework
 @brief      FWToolkitManager
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/8
 */

#import "FWToolkitManager.h"

#pragma mark - UIApplication+FWToolkit

@implementation UIApplication (FWToolkit)

+ (BOOL)fwIsDebug
{
#ifdef DEBUG
    return YES;
#else
    return NO;
#endif
}

@end

#pragma mark - UIDevice+FWToolkit

@implementation UIDevice (FWToolkit)

+ (BOOL)fwIsSimulator
{
#if TARGET_OS_SIMULATOR
    return YES;
#else
    return NO;
#endif
}

+ (BOOL)fwIsIphone
{
    static BOOL isIphone;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isIphone = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
    });
    return isIphone;
}

+ (BOOL)fwIsIpad
{
    static BOOL isIpad;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isIpad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
    });
    return isIpad;
}

+ (float)fwIosVersion
{
    static float version;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        version = [UIDevice currentDevice].systemVersion.floatValue;
    });
    return version;
}

+ (BOOL)fwIsIos:(NSInteger)version
{
    return [self fwIosVersion] >= version && [self fwIosVersion] < (version + 1);
}

+ (BOOL)fwIsIosLater:(NSInteger)version
{
    return [self fwIosVersion] >= version;
}

@end

#pragma mark - UIScreen+FWToolkit

@implementation UIScreen (FWToolkit)

+ (CGSize)fwScreenSize
{
    return [UIScreen mainScreen].bounds.size;
}

+ (CGFloat)fwScreenWidth
{
    return [UIScreen mainScreen].bounds.size.width;
}

+ (CGFloat)fwScreenHeight
{
    return [UIScreen mainScreen].bounds.size.height;
}

+ (CGFloat)fwScreenScale
{
    return [UIScreen mainScreen].scale;
}

+ (CGSize)fwScreenResolution
{
    return CGSizeMake(
                      [UIScreen mainScreen].bounds.size.width * [UIScreen mainScreen].scale,
                      [UIScreen mainScreen].bounds.size.height * [UIScreen mainScreen].scale
                      );
}

+ (CGFloat)fwPixelOne
{
    static CGFloat pixelOne = -1.0;
    if (pixelOne < 0) {
        pixelOne = 1 / [[UIScreen mainScreen] scale];
    }
    return pixelOne;
}

+ (BOOL)fwIsScreenSize:(CGSize)size
{
    return CGSizeEqualToSize(size, [UIScreen mainScreen].bounds.size);
}

+ (BOOL)fwIsScreenResolution:(CGSize)resolution
{
    return CGSizeEqualToSize(resolution, [self fwScreenResolution]);
}

+ (BOOL)fwIsScreenInch:(FWScreenInch)inch
{
    switch (inch) {
        case FWScreenInch35:
            return [self fwIsScreenSize:CGSizeMake(320, 480)];
        case FWScreenInch40:
            return [self fwIsScreenSize:CGSizeMake(320, 568)];
        case FWScreenInch47:
            return [self fwIsScreenSize:CGSizeMake(375, 667)];
        case FWScreenInch55:
            return [self fwIsScreenSize:CGSizeMake(414, 736)];
        case FWScreenInch58:
            return [self fwIsScreenSize:CGSizeMake(375, 812)];
        case FWScreenInch61:
            return [self fwIsScreenResolution:CGSizeMake(828, 1792)];
        case FWScreenInch65:
            return [self fwIsScreenResolution:CGSizeMake(1242, 2688)];
        default:
            return NO;
    }
}

+ (BOOL)fwIsScreenX
{
    return [self fwIsScreenSize:CGSizeMake(375, 812)] || [self fwIsScreenSize:CGSizeMake(414, 896)];
}

+ (BOOL)fwHasSafeAreaInsets
{
    return [self fwSafeAreaInsets].bottom > 0;
}

+ (UIEdgeInsets)fwSafeAreaInsets
{
    static UIEdgeInsets safeAreaInsets;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 11.0, *)) {
            UIApplication *application = [UIApplication sharedApplication];
            if ([application.delegate respondsToSelector:@selector(window)]) {
                safeAreaInsets = [application.delegate window].safeAreaInsets;
            } else {
                safeAreaInsets = [application keyWindow].safeAreaInsets;
            }
        } else {
            safeAreaInsets = UIEdgeInsetsZero;
        }
    });
    return safeAreaInsets;
}

+ (CGFloat)fwStatusBarHeight
{
    return [self fwIsScreenX] ? 44.0 : 20.0;
}

+ (CGFloat)fwNavigationBarHeight
{
    return 44.0;
}

+ (CGFloat)fwTabBarHeight
{
    return [self fwIsScreenX] ? 83.0 : 49.0;
}

+ (CGFloat)fwToolBarHeight
{
    return [self fwIsScreenX] ? 78.0 : 44.0;
}

+ (CGFloat)fwTopBarHeight
{
    return [self fwStatusBarHeight] + [self fwNavigationBarHeight];
}

+ (CGFloat)fwBottomBarHeight
{
    return [self fwTabBarHeight];
}

@end

@implementation UIViewController (FWToolkit)

- (CGFloat)fwStatusBarHeight
{
    if ([self prefersStatusBarHidden]) {
        return 0.0;
    } else {
        return [UIApplication sharedApplication].statusBarFrame.size.height;
    }
}

- (CGFloat)fwNavigationBarHeight
{
    if (self.navigationController.navigationBarHidden) {
        return 0.0;
    } else {
        return self.navigationController.navigationBar.frame.size.height;
    }
}

- (CGFloat)fwTabBarHeight
{
    if (self.tabBarController.tabBar.hidden) {
        return 0.0;
    } else {
        return self.tabBarController.tabBar.frame.size.height;
    }
}

- (CGFloat)fwToolBarHeight
{
    if (self.navigationController.toolbarHidden) {
        return 0.0;
    } else {
        return self.navigationController.toolbar.frame.size.height;
    }
}

- (CGFloat)fwTopBarHeight
{
    return [self fwStatusBarHeight] + [self fwNavigationBarHeight];
}

- (CGFloat)fwBottomBarHeight
{
    return [self fwTabBarHeight];
}

@end

#pragma mark - UIColor+FWToolkit

static BOOL fwStaticColorARGB = NO;

@implementation UIColor (FWToolkit)

+ (UIColor *)fwColorWithHex:(long)hex
{
    return [UIColor fwColorWithHex:hex alpha:1.0f];
}

+ (UIColor *)fwColorWithHex:(long)hex alpha:(CGFloat)alpha
{
    float red = ((float)((hex & 0xFF0000) >> 16)) / 255.0;
    float green = ((float)((hex & 0xFF00) >> 8)) / 255.0;
    float blue = ((float)(hex & 0xFF)) / 255.0;
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+ (void)fwColorStandardARGB:(BOOL)enabled
{
    fwStaticColorARGB = enabled;
}

+ (UIColor *)fwColorWithHexString:(NSString *)hexString
{
    return [UIColor fwColorWithHexString:hexString alpha:1.0f];
}

+ (UIColor *)fwColorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha
{
    // 处理参数
    NSString *string = hexString ? hexString.uppercaseString : @"";
    if ([string hasPrefix:@"0X"]) {
        string = [string substringFromIndex:2];
    }
    if ([string hasPrefix:@"#"]) {
        string = [string substringFromIndex:1];
    }
    
    // 检查长度
    NSUInteger length = string.length;
    if (length != 3 && length != 4 && length != 6 && length != 8) {
        return [UIColor clearColor];
    }
    
    // 解析颜色
    NSString *strR = nil, *strG = nil, *strB = nil, *strA = nil;
    if (length < 5) {
        // ARGB
        if (fwStaticColorARGB && length == 4) {
            string = [NSString stringWithFormat:@"%@%@", [string substringWithRange:NSMakeRange(1, 3)], [string substringWithRange:NSMakeRange(0, 1)]];
        }
        // RGB|RGBA
        NSString *tmpR = [string substringWithRange:NSMakeRange(0, 1)];
        NSString *tmpG = [string substringWithRange:NSMakeRange(1, 1)];
        NSString *tmpB = [string substringWithRange:NSMakeRange(2, 1)];
        strR = [NSString stringWithFormat:@"%@%@", tmpR, tmpR];
        strG = [NSString stringWithFormat:@"%@%@", tmpG, tmpG];
        strB = [NSString stringWithFormat:@"%@%@", tmpB, tmpB];
        if (length == 4) {
            NSString *tmpA = [string substringWithRange:NSMakeRange(3, 1)];
            strA = [NSString stringWithFormat:@"%@%@", tmpA, tmpA];
        }
    } else {
        // AARRGGBB
        if (fwStaticColorARGB && length == 8) {
            string = [NSString stringWithFormat:@"%@%@", [string substringWithRange:NSMakeRange(2, 6)], [string substringWithRange:NSMakeRange(0, 2)]];
        }
        // RRGGBB|RRGGBBAA
        strR = [string substringWithRange:NSMakeRange(0, 2)];
        strG = [string substringWithRange:NSMakeRange(2, 2)];
        strB = [string substringWithRange:NSMakeRange(4, 2)];
        if (length == 8) {
            strA = [string substringWithRange:NSMakeRange(6, 2)];
        }
    }
    
    // 解析颜色
    unsigned int r, g, b;
    [[NSScanner scannerWithString:strR] scanHexInt:&r];
    [[NSScanner scannerWithString:strG] scanHexInt:&g];
    [[NSScanner scannerWithString:strB] scanHexInt:&b];
    float fr = (r * 1.0f) / 255.0f;
    float fg = (g * 1.0f) / 255.0f;
    float fb = (b * 1.0f) / 255.0f;
    
    // 解析透明度，字符串的透明度优先级高于alpha参数
    if (strA) {
        unsigned int a;
        [[NSScanner scannerWithString:strA] scanHexInt:&a];
        // 计算十六进制对应透明度
        alpha = (a * 1.0f) / 255.0f;
    }
    
    return [UIColor colorWithRed:fr green:fg blue:fb alpha:alpha];
}

+ (UIColor *)fwColorWithString:(NSString *)string
{
    return [UIColor fwColorWithString:string alpha:1.0f];
}

+ (UIColor *)fwColorWithString:(NSString *)string alpha:(CGFloat)alpha
{
    // 颜色值
    SEL colorSelector = NSSelectorFromString([NSString stringWithFormat:@"%@Color", string]);
    if ([[UIColor class] respondsToSelector:colorSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        UIColor *color = [[UIColor class] performSelector:colorSelector];
#pragma clang diagnostic pop
        return alpha < 1.0f ? [color colorWithAlphaComponent:alpha] : color;
    }
    
    // 十六进制
    return [UIColor fwColorWithHexString:string alpha:alpha];
}

- (long)fwHexValue
{
    CGFloat r = 0, g = 0, b = 0, a = 0;
    [self getRed:&r green:&g blue:&b alpha:&a];
    int8_t red = r * 255;
    uint8_t green = g * 255;
    uint8_t blue = b * 255;
    return (red << 16) + (green << 8) + blue;
}

- (NSString *)fwHexString
{
    const CGFloat *components = CGColorGetComponents(self.CGColor);
    CGFloat r = components[0], g = components[1], b = components[2];
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255)];
}

- (NSString *)fwHexStringWithAlpha
{
    const CGFloat *components = CGColorGetComponents(self.CGColor);
    CGFloat r = components[0], g = components[1], b = components[2];
    CGFloat a = CGColorGetAlpha(self.CGColor);
    if (fwStaticColorARGB) {
        return [NSString stringWithFormat:@"#%02lX%02lX%02lX%02lX", lround(a * 255), lroundf(r * 255), lroundf(g * 255), lroundf(b * 255)];
    } else {
        return [NSString stringWithFormat:@"#%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lround(a * 255)];
    }
}

@end

#pragma mark - UIFont+FWToolkit

UIFont * FWFontLight(CGFloat size) { return [UIFont systemFontOfSize:size weight:UIFontWeightLight]; }
UIFont * FWFontRegular(CGFloat size) { return [UIFont systemFontOfSize:size]; }
UIFont * FWFontBold(CGFloat size) { return [UIFont boldSystemFontOfSize:size]; }
UIFont * FWFontItalic(CGFloat size) { return [UIFont italicSystemFontOfSize:size]; }

@implementation UIFont (FWToolkit)

+ (UIFont *)fwLightFontOfSize:(CGFloat)size
{
    return [UIFont systemFontOfSize:size weight:UIFontWeightLight];
}

+ (UIFont *)fwFontOfSize:(CGFloat)size
{
    return [UIFont systemFontOfSize:size];
}

+ (UIFont *)fwBoldFontOfSize:(CGFloat)size
{
    return [UIFont boldSystemFontOfSize:size];
}

+ (UIFont *)fwItalicFontOfSize:(CGFloat)size
{
    return [UIFont italicSystemFontOfSize:size];
}

+ (UIFont *)fwFontOfSize:(CGFloat)size weight:(UIFontWeight)weight
{
    return [UIFont systemFontOfSize:size weight:weight];
}

@end
