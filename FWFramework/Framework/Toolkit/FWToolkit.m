/*!
 @header     FWToolkit.m
 @indexgroup FWFramework
 @brief      FWToolkit
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/22
 */

#import "FWToolkit.h"
#import "FWRouter.h"
#import <SafariServices/SafariServices.h>
#import <objc/runtime.h>
#import <sys/sysctl.h>
#if FWCOMPONENT_TRACKING_ENABLED
#import <AdSupport/ASIdentifierManager.h>
#endif

#pragma mark - NSAttributedString+FWToolkit

@implementation NSAttributedString (FWToolkit)

+ (instancetype)fwAttributedStringWithHtmlString:(NSString *)htmlString
{
    NSData *htmlData = [htmlString dataUsingEncoding:NSUTF8StringEncoding];
    if (!htmlData || htmlData.length < 1) return nil;
    
    return [[self alloc] initWithData:htmlData options:@{
        NSDocumentTypeDocumentOption: NSHTMLTextDocumentType,
        NSCharacterEncodingDocumentOption: @(NSUTF8StringEncoding),
    } documentAttributes:nil error:nil];
}

- (NSString *)fwHtmlString
{
    NSData *htmlData = [self dataFromRange:NSMakeRange(0, self.length) documentAttributes:@{
        NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
    } error:nil];
    if (!htmlData || htmlData.length < 1) return nil;
    
    return [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
}

@end

#pragma mark - NSDate+FWToolkit

// 当前基准时间值
static NSTimeInterval fwStaticCurrentBaseTime = 0;
// 本地基准时间值
static NSTimeInterval fwStaticLocalBaseTime = 0;

@implementation NSDate (FWToolkit)

+ (NSTimeInterval)fwCurrentTime
{
    // 没有同步过返回本地时间
    if (fwStaticCurrentBaseTime == 0) {
        // 是否本地有服务器时间
        NSNumber *preCurrentTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWCurrentTime"];
        NSNumber *preLocalTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWLocalTime"];
        if (preCurrentTime && preLocalTime) {
            // 计算当前服务器时间
            NSTimeInterval offsetTime = [[NSDate date] timeIntervalSince1970] - preLocalTime.doubleValue;
            return preCurrentTime.doubleValue + offsetTime;
        } else {
            return [[NSDate date] timeIntervalSince1970];
        }
    // 同步过计算当前服务器时间
    } else {
        NSTimeInterval offsetTime = [self fwCurrentSystemUptime] - fwStaticLocalBaseTime;
        return fwStaticCurrentBaseTime + offsetTime;
    }
}

+ (void)setFwCurrentTime:(NSTimeInterval)currentTime
{
    fwStaticCurrentBaseTime = currentTime;
    // 取运行时间，调整系统时间不会影响
    fwStaticLocalBaseTime = [self fwCurrentSystemUptime];
    
    // 保存当前服务器时间到本地
    [[NSUserDefaults standardUserDefaults] setObject:@(currentTime) forKey:@"FWCurrentTime"];
    [[NSUserDefaults standardUserDefaults] setObject:@([[NSDate date] timeIntervalSince1970]) forKey:@"FWLocalTime"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (long long)fwCurrentSystemUptime
{
    struct timeval boottime;
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};
    size_t size = sizeof(boottime);
    time_t now;
    time_t uptime = -1;
    (void)time(&now);
    if (sysctl(mib, 2, &boottime, &size, NULL, 0) != -1 && boottime.tv_sec != 0) {
        uptime = now - boottime.tv_sec;
    }
    return uptime;
}

@end

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
    if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:nsurl options:@{} completionHandler:completion];
    } else {
        BOOL success = [[UIApplication sharedApplication] openURL:nsurl];
        if (completion) {
            completion(success);
        }
    }
}

+ (void)fwOpenUniversalLinks:(id)url completionHandler:(void (^)(BOOL))completion
{
    NSURL *nsurl = [self fwNSURLWithURL:url];
    if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:nsurl options:@{UIApplicationOpenURLOptionUniversalLinksOnly: @YES} completionHandler:completion];
    } else {
        if (completion) {
            completion(NO);
        }
    }
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

#pragma mark - UIDevice+FWToolkit

@implementation UIDevice (FWToolkit)

+ (void)fwSetDeviceTokenData:(NSData *)tokenData
{
    if (tokenData) {
        NSMutableString *deviceToken = [NSMutableString string];
        const char *bytes = tokenData.bytes;
        NSInteger count = tokenData.length;
        for (int i = 0; i < count; i++) {
            [deviceToken appendFormat:@"%02x", bytes[i] & 0x000000FF];
        }
        [[NSUserDefaults standardUserDefaults] setObject:[deviceToken copy] forKey:@"FWDeviceToken"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDeviceToken"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

+ (NSString *)fwDeviceToken
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDeviceToken"];
}

+ (NSString *)fwDeviceModel
{
    static NSString *model;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        model = [NSString stringWithUTF8String:machine];
        free(machine);
    });
    return model;
}

+ (NSString *)fwDeviceIDFV
{
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

+ (NSString *)fwDeviceIDFA
{
#if FWCOMPONENT_TRACKING_ENABLED
    return [[ASIdentifierManager sharedManager].advertisingIdentifier UUIDString];
#else
    return nil;
#endif
}

@end

#pragma mark - UIView+FWToolkit

@implementation UIView (FWToolkit)

- (UIViewController *)fwViewController
{
    UIResponder *responder = [self nextResponder];
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
        responder = [responder nextResponder];
    }
    return nil;
}

@end

#pragma mark - UIScrollView+FWToolkit

@interface FWScrollOverlayView : UIView

@property (nonatomic, assign) BOOL fadeAnimated;

@end

@implementation FWScrollOverlayView

- (void)didMoveToSuperview
{
    self.frame = self.superview.bounds;
    
    if (self.fadeAnimated) {
        self.fadeAnimated = NO;
        self.alpha = 0;
        [UIView animateWithDuration:0.25 animations:^{
            self.alpha = 1.0;
        } completion:NULL];
    } else {
        self.alpha = 1.0;
    }
}

@end

@implementation UIScrollView (FWEmptyPlugin)

- (UIView *)fwOverlayView
{
    UIView *overlayView = objc_getAssociatedObject(self, @selector(fwOverlayView));
    if (!overlayView) {
        overlayView = [[FWScrollOverlayView alloc] init];
        overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        overlayView.userInteractionEnabled = YES;
        overlayView.backgroundColor = UIColor.clearColor;
        overlayView.clipsToBounds = YES;
        overlayView.alpha = 0;
        
        objc_setAssociatedObject(self, @selector(fwOverlayView), overlayView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return overlayView;
}

- (BOOL)fwIsOverlayViewVisible
{
    UIView *overlayView = objc_getAssociatedObject(self, @selector(fwOverlayView));
    return overlayView && overlayView.superview && !overlayView.isHidden;
}

- (void)fwShowOverlayView
{
    [self fwShowOverlayViewAnimated:NO];
}

- (void)fwShowOverlayViewAnimated:(BOOL)animated
{
    [self fwHideOverlayView];
    
    FWScrollOverlayView *overlayView = (FWScrollOverlayView *)self.fwOverlayView;
    overlayView.fadeAnimated = animated;
    if (([self isKindOfClass:[UITableView class]] || [self isKindOfClass:[UICollectionView class]]) && self.subviews.count > 1) {
        [self insertSubview:overlayView atIndex:0];
    } else {
        [self addSubview:overlayView];
    }
}

- (void)fwHideOverlayView
{
    UIView *overlayView = objc_getAssociatedObject(self, @selector(fwOverlayView));
    if (overlayView && overlayView.superview) {
        [overlayView removeFromSuperview];
    }
}

@end
