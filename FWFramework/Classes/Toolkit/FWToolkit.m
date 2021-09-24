/*!
 @header     FWToolkit.m
 @indexgroup FWFramework
 @brief      FWToolkit
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/22
 */

#import "FWToolkit.h"
#import "FWNavigation.h"
#import "FWSwizzle.h"
#import <SafariServices/SafariServices.h>
#import <objc/runtime.h>

#pragma mark - UIApplication+FWToolkit

@interface FWSafariViewControllerDelegate : NSObject <SFSafariViewControllerDelegate>

@end

@implementation FWSafariViewControllerDelegate

+ (FWSafariViewControllerDelegate *)sharedInstance
{
    static FWSafariViewControllerDelegate *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWSafariViewControllerDelegate alloc] init];
    });
    return instance;
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller
{
    void (^completion)(void) = objc_getAssociatedObject(controller, @selector(safariViewControllerDidFinish:));
    if (completion) {
        completion();
    }
}

@end

@implementation UIApplication (FWToolkit)

+ (BOOL)fwCanOpenURL:(id)url
{
    NSURL *nsurl = [self fwNSURLWithURL:url];
    return [[UIApplication sharedApplication] canOpenURL:nsurl];
}

+ (void)fwOpenURL:(id)url
{
    [self fwOpenURL:url completionHandler:nil];
}

+ (void)fwOpenURL:(id)url completionHandler:(void (^)(BOOL success))completion
{
    NSURL *nsurl = [self fwNSURLWithURL:url];
    [[UIApplication sharedApplication] openURL:nsurl options:@{} completionHandler:completion];
}

+ (void)fwOpenUniversalLinks:(id)url completionHandler:(void (^)(BOOL))completion
{
    NSURL *nsurl = [self fwNSURLWithURL:url];
    [[UIApplication sharedApplication] openURL:nsurl options:@{UIApplicationOpenURLOptionUniversalLinksOnly: @YES} completionHandler:completion];
}

+ (void)fwOpenAppStore:(NSString *)appId
{
    // SKStoreProductViewController可以内部打开，但需要加载
    [self fwOpenURL:[NSString stringWithFormat:@"https://apps.apple.com/app/id%@", appId]];
}

+ (BOOL)fwIsAppStoreURL:(id)url
{
    // itms-apps等
    NSURL *nsurl = [self fwNSURLWithURL:url];
    if ([nsurl.scheme.lowercaseString hasPrefix:@"itms"]) {
        return YES;
    // https://apps.apple.com/等
    } else if ([nsurl.host.lowercaseString isEqualToString:@"itunes.apple.com"] ||
               [nsurl.host.lowercaseString isEqualToString:@"apps.apple.com"]) {
        return YES;
    }
    return NO;
}

+ (BOOL)fwIsSystemURL:(id)url
{
    NSURL *nsurl = [self fwNSURLWithURL:url];
    if (nsurl.scheme.lowercaseString && [@[@"tel", @"telprompt", @"sms", @"mailto"] containsObject:nsurl.scheme.lowercaseString]) {
        return YES;
    }
    if ([self fwIsAppStoreURL:nsurl]) {
        return YES;
    }
    if (nsurl.absoluteString && [nsurl.absoluteString isEqualToString:UIApplicationOpenSettingsURLString]) {
        return YES;
    }
    return NO;
}

+ (BOOL)fwIsHttpURL:(id)url
{
    NSString *urlString = [url isKindOfClass:[NSURL class]] ? [(NSURL *)url absoluteString] : url;
    return [urlString.lowercaseString hasPrefix:@"http://"] || [urlString.lowercaseString hasPrefix:@"https://"];
}

+ (void)fwOpenSafariController:(id)url
{
    [self fwOpenSafariController:url completionHandler:nil];
}

+ (void)fwOpenSafariController:(id)url completionHandler:(nullable void (^)(void))completion
{
    if (![self fwIsHttpURL:url]) return;
    
    NSURL *nsurl = [self fwNSURLWithURL:url];
    SFSafariViewController *safariController = [[SFSafariViewController alloc] initWithURL:nsurl];
    if (completion) {
        objc_setAssociatedObject(safariController, @selector(safariViewControllerDidFinish:), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
        safariController.delegate = [FWSafariViewControllerDelegate sharedInstance];
    }
    [UIWindow.fwMainWindow fwPresentViewController:safariController animated:YES completion:nil];
}

+ (NSURL *)fwNSURLWithURL:(id)url
{
    if (![url isKindOfClass:[NSString class]]) return url;
    
    NSURL *nsurl = [NSURL URLWithString:url];
    if (!nsurl && [url length] > 0) {
        nsurl = [NSURL URLWithString:[url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    }
    return nsurl;
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
    if (![self getRed:&r green:&g blue:&b alpha:&a]) {
        if ([self getWhite:&r alpha:&a]) { g = r; b = r; }
    }
    
    int8_t red = r * 255;
    uint8_t green = g * 255;
    uint8_t blue = b * 255;
    return (red << 16) + (green << 8) + blue;
}

- (CGFloat)fwAlphaValue
{
    return CGColorGetAlpha(self.CGColor);
}

- (NSString *)fwHexString
{
    CGFloat r = 0, g = 0, b = 0, a = 0;
    if (![self getRed:&r green:&g blue:&b alpha:&a]) {
        if ([self getWhite:&r alpha:&a]) { g = r; b = r; }
    }
    
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255)];
}

- (NSString *)fwHexStringWithAlpha
{
    CGFloat r = 0, g = 0, b = 0, a = 0;
    if (![self getRed:&r green:&g blue:&b alpha:&a]) {
        if ([self getWhite:&r alpha:&a]) { g = r; b = r; }
    }
    
    if (a >= 1.0) {
        return [NSString stringWithFormat:@"#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255)];
    } else if (fwStaticColorARGB) {
        return [NSString stringWithFormat:@"#%02lX%02lX%02lX%02lX", lround(a * 255), lroundf(r * 255), lroundf(g * 255), lroundf(b * 255)];
    } else {
        return [NSString stringWithFormat:@"#%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lround(a * 255)];
    }
}

@end

#pragma mark - UIFont+FWToolkit

UIFont * FWFontLight(CGFloat size) { return [UIFont fwLightFontOfSize:size]; }
UIFont * FWFontRegular(CGFloat size) { return [UIFont fwFontOfSize:size]; }
UIFont * FWFontBold(CGFloat size) { return [UIFont fwBoldFontOfSize:size]; }
UIFont * FWFontItalic(CGFloat size) { return [UIFont fwItalicFontOfSize:size]; }

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

#pragma mark - UIView+FWToolkit

@implementation UIView (FWToolkit)

- (CGFloat)fwTop
{
    return self.frame.origin.y;
}

- (void)setFwTop:(CGFloat)fwTop
{
    CGRect frame = self.frame;
    frame.origin.y = fwTop;
    self.frame = frame;
}

- (CGFloat)fwBottom
{
    return self.fwTop + self.fwHeight;
}

- (void)setFwBottom:(CGFloat)fwBottom
{
    self.fwTop = fwBottom - self.fwHeight;
}

- (CGFloat)fwLeft
{
    return self.frame.origin.x;
}

- (void)setFwLeft:(CGFloat)fwLeft
{
    CGRect frame = self.frame;
    frame.origin.x = fwLeft;
    self.frame = frame;
}

- (CGFloat)fwRight
{
    return self.fwLeft + self.fwWidth;
}

- (void)setFwRight:(CGFloat)fwRight
{
    self.fwLeft = fwRight - self.fwWidth;
}

- (CGFloat)fwWidth
{
    return self.frame.size.width;
}

- (void)setFwWidth:(CGFloat)fwWidth
{
    CGRect frame = self.frame;
    frame.size.width = fwWidth;
    self.frame = frame;
}

- (CGFloat)fwHeight
{
    return self.frame.size.height;
}

- (void)setFwHeight:(CGFloat)fwHeight
{
    CGRect frame = self.frame;
    frame.size.height = fwHeight;
    self.frame = frame;
}

- (CGFloat)fwCenterX
{
    return self.center.x;
}

- (void)setFwCenterX:(CGFloat)fwCenterX
{
    self.center = CGPointMake(fwCenterX, self.fwCenterY);
}

- (CGFloat)fwCenterY
{
    return self.center.y;
}

- (void)setFwCenterY:(CGFloat)fwCenterY
{
    self.center = CGPointMake(self.fwCenterX, fwCenterY);
}

- (CGFloat)fwX
{
    return self.frame.origin.x;
}

- (void)setFwX:(CGFloat)fwX
{
    CGRect frame = self.frame;
    frame.origin.x = fwX;
    self.frame = frame;
}

- (CGFloat)fwY
{
    return self.frame.origin.y;
}

- (void)setFwY:(CGFloat)fwY
{
    CGRect frame = self.frame;
    frame.origin.y = fwY;
    self.frame = frame;
}

- (CGPoint)fwOrigin
{
    return self.frame.origin;
}

- (void)setFwOrigin:(CGPoint)fwOrigin
{
    CGRect frame = self.frame;
    frame.origin = fwOrigin;
    self.frame = frame;
}

- (CGSize)fwSize
{
    return self.frame.size;
}

- (void)setFwSize:(CGSize)fwSize
{
    CGRect frame = self.frame;
    frame.size = fwSize;
    self.frame = frame;
}

@end

#pragma mark - UIViewController+FWToolkit

@implementation UIViewController (FWToolkit)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UIViewController, @selector(viewDidLoad), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            selfObject.fwVisibleState = FWViewControllerVisibleStateDidLoad;
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewWillAppear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            selfObject.fwVisibleState = FWViewControllerVisibleStateWillAppear;
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewDidAppear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            selfObject.fwVisibleState = FWViewControllerVisibleStateDidAppear;
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewWillDisappear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            selfObject.fwVisibleState = FWViewControllerVisibleStateWillDisappear;
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewDidDisappear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            selfObject.fwVisibleState = FWViewControllerVisibleStateDidDisappear;
        }));
        
        FWSwizzleClass(UIViewController, NSSelectorFromString(@"dealloc"), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            if (selfObject.fwWillDeallocBlock) selfObject.fwWillDeallocBlock(selfObject);
            FWSwizzleOriginal();
        }));
    });
}

- (FWViewControllerVisibleState)fwVisibleState
{
    return [objc_getAssociatedObject(self, @selector(fwVisibleState)) unsignedIntegerValue];
}

- (void)setFwVisibleState:(FWViewControllerVisibleState)fwVisibleState
{
    BOOL valueChanged = self.fwVisibleState != fwVisibleState;
    objc_setAssociatedObject(self, @selector(fwVisibleState), @(fwVisibleState), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (valueChanged && self.fwVisibleStateChanged) {
        self.fwVisibleStateChanged(self, fwVisibleState);
    }
}

- (void (^)(__kindof UIViewController *, FWViewControllerVisibleState))fwVisibleStateChanged
{
    return objc_getAssociatedObject(self, @selector(fwVisibleStateChanged));
}

- (void)setFwVisibleStateChanged:(void (^)(__kindof UIViewController *, FWViewControllerVisibleState))fwVisibleStateChanged
{
    objc_setAssociatedObject(self, @selector(fwVisibleStateChanged), fwVisibleStateChanged, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(__kindof UIViewController * _Nonnull))fwWillDeallocBlock
{
    return objc_getAssociatedObject(self, @selector(fwWillDeallocBlock));
}

- (void)setFwWillDeallocBlock:(void (^)(__kindof UIViewController * _Nonnull))fwWillDeallocBlock
{
    objc_setAssociatedObject(self, @selector(fwWillDeallocBlock), fwWillDeallocBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
