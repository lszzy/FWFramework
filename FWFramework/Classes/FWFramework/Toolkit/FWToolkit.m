/**
 @header     FWToolkit.m
 @indexgroup FWFramework
      FWToolkit
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/22
 */

#import "FWToolkit.h"
#import "FWAdaptive.h"
#import "FWNavigation.h"
#import "FWProxy.h"
#import "FWSwizzle.h"
#import <SafariServices/SafariServices.h>
#import <StoreKit/StoreKit.h>
#import <objc/runtime.h>

#pragma mark - UIApplication+FWToolkit

@interface FWSafariViewControllerDelegate : NSObject <SFSafariViewControllerDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, SKStoreProductViewControllerDelegate>

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

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    void (^completion)(BOOL) = objc_getAssociatedObject(controller, @selector(messageComposeViewController:didFinishWithResult:));
    [controller dismissViewControllerAnimated:YES completion:^{
        if (completion) completion(result == MessageComposeResultSent);
    }];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    void (^completion)(BOOL) = objc_getAssociatedObject(controller, @selector(mailComposeController:didFinishWithResult:error:));
    [controller dismissViewControllerAnimated:YES completion:^{
        if (completion) completion(result == MFMailComposeResultSent);
    }];
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)controller
{
    void (^completion)(BOOL) = objc_getAssociatedObject(controller, @selector(productViewControllerDidFinish:));
    [controller dismissViewControllerAnimated:YES completion:^{
        if (completion) completion(YES);
    }];
}

@end

@implementation UIApplication (FWToolkit)

+ (NSString *)fw_appName
{
    NSString *appName = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleName"];
    return [appName isKindOfClass:[NSString class]] ? appName : @"";
}

+ (NSString *)fw_appDisplayName
{
    NSString *displayName = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (![displayName isKindOfClass:[NSString class]]) {
        displayName = [self fw_appName];
    }
    return displayName;
}

+ (NSString *)fw_appVersion
{
    NSString *appVersion = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    return [appVersion isKindOfClass:[NSString class]] ? appVersion : @"";
}

+ (NSString *)fw_appBuildVersion
{
    NSString *buildVersion = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
    return [buildVersion isKindOfClass:[NSString class]] ? buildVersion : @"";
}

+ (NSString *)fw_appIdentifier
{
    NSString *appIdentifier = [NSBundle.mainBundle objectForInfoDictionaryKey:(__bridge NSString *)kCFBundleIdentifierKey];
    return [appIdentifier isKindOfClass:[NSString class]] ? appIdentifier : @"";
}

+ (NSString *)fw_appExecutable
{
    NSString *appExecutable = [NSBundle.mainBundle objectForInfoDictionaryKey:(__bridge NSString *)kCFBundleExecutableKey];
    if (![appExecutable isKindOfClass:[NSString class]]) {
        appExecutable = [self fw_appIdentifier];
    }
    return appExecutable;
}

+ (BOOL)fw_canOpenURL:(id)url
{
    NSURL *nsurl = [self fw_urlWithString:url];
    return [[UIApplication sharedApplication] canOpenURL:nsurl];
}

+ (void)fw_openURL:(id)url
{
    [self fw_openURL:url completionHandler:nil];
}

+ (void)fw_openURL:(id)url completionHandler:(void (^)(BOOL success))completion
{
    NSURL *nsurl = [self fw_urlWithString:url];
    [[UIApplication sharedApplication] openURL:nsurl options:@{} completionHandler:completion];
}

+ (void)fw_openUniversalLinks:(id)url completionHandler:(void (^)(BOOL))completion
{
    NSURL *nsurl = [self fw_urlWithString:url];
    [[UIApplication sharedApplication] openURL:nsurl options:@{UIApplicationOpenURLOptionUniversalLinksOnly: @YES} completionHandler:completion];
}

+ (BOOL)fw_isSystemURL:(id)url
{
    NSURL *nsurl = [self fw_urlWithString:url];
    if (nsurl.scheme.lowercaseString && [@[@"tel", @"telprompt", @"sms", @"mailto"] containsObject:nsurl.scheme.lowercaseString]) {
        return YES;
    }
    if ([self fw_isAppStoreURL:nsurl]) {
        return YES;
    }
    if (nsurl.absoluteString && [nsurl.absoluteString isEqualToString:UIApplicationOpenSettingsURLString]) {
        return YES;
    }
    return NO;
}

+ (BOOL)fw_isHttpURL:(id)url
{
    NSString *urlString = [url isKindOfClass:[NSURL class]] ? [(NSURL *)url absoluteString] : url;
    return [urlString.lowercaseString hasPrefix:@"http://"] || [urlString.lowercaseString hasPrefix:@"https://"];
}

+ (BOOL)fw_isAppStoreURL:(id)url
{
    // itms-apps等
    NSURL *nsurl = [self fw_urlWithString:url];
    if ([nsurl.scheme.lowercaseString hasPrefix:@"itms"]) {
        return YES;
    // https://apps.apple.com/等
    } else if ([nsurl.host.lowercaseString isEqualToString:@"itunes.apple.com"] ||
               [nsurl.host.lowercaseString isEqualToString:@"apps.apple.com"]) {
        return YES;
    }
    return NO;
}

+ (void)fw_openAppStore:(NSString *)appId completionHandler:(void (^)(BOOL))completion
{
    // SKStoreProductViewController可以内部打开
    [self fw_openURL:[NSString stringWithFormat:@"https://apps.apple.com/app/id%@", appId] completionHandler:completion];
}

+ (void)fw_openAppStoreReview:(NSString *)appId completionHandler:(void (^)(BOOL))completion
{
    [self fw_openURL:[NSString stringWithFormat:@"https://apps.apple.com/app/id%@?action=write-review", appId] completionHandler:completion];
}

+ (void)fw_openAppReview
{
    [SKStoreReviewController requestReview];
}

+ (void)fw_openAppSettings:(void (^)(BOOL))completion
{
    [self fw_openURL:UIApplicationOpenSettingsURLString completionHandler:completion];
}

+ (void)fw_openMailApp:(NSString *)email completionHandler:(void (^)(BOOL))completion
{
    [self fw_openURL:[NSString stringWithFormat:@"mailto://%@", email] completionHandler:completion];
}

+ (void)fw_openMessageApp:(NSString *)phone completionHandler:(void (^)(BOOL))completion
{
    [self fw_openURL:[NSString stringWithFormat:@"sms://%@", phone] completionHandler:completion];
}

+ (void)fw_openPhoneApp:(NSString *)phone completionHandler:(void (^)(BOOL))completion
{
    // tel:为直接拨打电话
    [self fw_openURL:[NSString stringWithFormat:@"telprompt://%@", phone] completionHandler:completion];
}

+ (void)fw_openActivityItems:(NSArray *)activityItems excludedTypes:(NSArray<UIActivityType> *)excludedTypes
{
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityController.excludedActivityTypes = excludedTypes;
    [UIWindow fw_presentViewController:activityController animated:YES completion:nil];
}

+ (void)fw_openSafariController:(id)url
{
    [self fw_openSafariController:url completionHandler:nil];
}

+ (void)fw_openSafariController:(id)url completionHandler:(nullable void (^)(void))completion
{
    if (![self fw_isHttpURL:url]) return;
    
    NSURL *nsurl = [self fw_urlWithString:url];
    SFSafariViewController *safariController = [[SFSafariViewController alloc] initWithURL:nsurl];
    if (completion) {
        objc_setAssociatedObject(safariController, @selector(safariViewControllerDidFinish:), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
        safariController.delegate = [FWSafariViewControllerDelegate sharedInstance];
    }
    [UIWindow fw_presentViewController:safariController animated:YES completion:nil];
}

+ (void)fw_openMessageController:(MFMessageComposeViewController *)controller completionHandler:(void (^)(BOOL))completion
{
    if (!controller || ![MFMessageComposeViewController canSendText]) {
        if (completion) completion(NO);
        return;
    }
    
    if (completion) {
        objc_setAssociatedObject(controller, @selector(messageComposeViewController:didFinishWithResult:), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    controller.messageComposeDelegate = [FWSafariViewControllerDelegate sharedInstance];
    [UIWindow fw_presentViewController:controller animated:YES completion:nil];
}

+ (void)fw_openMailController:(MFMailComposeViewController *)controller completionHandler:(void (^)(BOOL))completion
{
    if (!controller || ![MFMailComposeViewController canSendMail]) {
        if (completion) completion(NO);
        return;
    }
    
    if (completion) {
        objc_setAssociatedObject(controller, @selector(mailComposeController:didFinishWithResult:error:), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    controller.mailComposeDelegate = [FWSafariViewControllerDelegate sharedInstance];
    [UIWindow fw_presentViewController:controller animated:YES completion:nil];
}

+ (void)fw_openStoreController:(NSDictionary<NSString *,id> *)parameters completionHandler:(void (^)(BOOL))completion
{
    SKStoreProductViewController *viewController = [[SKStoreProductViewController alloc] init];
    viewController.delegate = [FWSafariViewControllerDelegate sharedInstance];
    [viewController loadProductWithParameters:parameters completionBlock:^(BOOL result, NSError * _Nullable error) {
        if (!result) {
            if (completion) completion(NO);
            return;
        }
        
        objc_setAssociatedObject(viewController, @selector(productViewControllerDidFinish:), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
        [UIWindow fw_presentViewController:viewController animated:YES completion:nil];
    }];
}

+ (AVPlayerViewController *)fw_openVideoPlayer:(id)url
{
    AVPlayer *player = nil;
    if ([url isKindOfClass:[AVPlayerItem class]]) {
        player = [AVPlayer playerWithPlayerItem:(AVPlayerItem *)url];
    } else if ([url isKindOfClass:[NSURL class]]) {
        player = [AVPlayer playerWithURL:(NSURL *)url];
    } else if ([url isKindOfClass:[NSString class]]) {
        NSURL *videoURL = [self fw_urlWithString:url];
        if (videoURL) player = [AVPlayer playerWithURL:videoURL];
    }
    if (!player) return nil;
    
    AVPlayerViewController *viewController = [[AVPlayerViewController alloc] init];
    viewController.player = player;
    return viewController;
}

+ (AVAudioPlayer *)fw_openAudioPlayer:(id)url
{
    // 设置播放模式示例
    // [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
    
    NSURL *audioURL = nil;
    if ([url isKindOfClass:[NSURL class]]) {
        audioURL = (NSURL *)url;
    } else if ([url isKindOfClass:[NSString class]]) {
        if ([url isAbsolutePath]) {
            audioURL = [NSURL fileURLWithPath:url];
        } else {
            audioURL = [[NSBundle mainBundle] URLForResource:url withExtension:nil];
        }
    }
    if (!audioURL) return nil;
    
    AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioURL error:NULL];
    if (![audioPlayer prepareToPlay]) return nil;
    
    [audioPlayer play];
    return audioPlayer;
}

+ (NSURL *)fw_urlWithString:(id)url
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

- (UIColor *)fw_colorWithAlpha:(CGFloat)alpha
{
    return [self colorWithAlphaComponent:alpha];
}

- (long)fw_hexValue
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

- (CGFloat)fw_alphaValue
{
    return CGColorGetAlpha(self.CGColor);
}

- (NSString *)fw_hexString
{
    CGFloat r = 0, g = 0, b = 0, a = 0;
    if (![self getRed:&r green:&g blue:&b alpha:&a]) {
        if ([self getWhite:&r alpha:&a]) { g = r; b = r; }
    }
    
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255)];
}

- (NSString *)fw_hexAlphaString
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

+ (BOOL)fw_colorStandardARGB
{
    return fwStaticColorARGB;
}

+ (void)setFw_colorStandardARGB:(BOOL)enabled
{
    fwStaticColorARGB = enabled;
}

+ (UIColor *)fw_randomColor
{
    NSInteger red = arc4random() % 255;
    NSInteger green = arc4random() % 255;
    NSInteger blue = arc4random() % 255;
    return [UIColor colorWithRed:red / 255.0 green:green / 255.0 blue:blue / 255.0 alpha:1.0f];
}

+ (UIColor *)fw_colorWithHex:(long)hex
{
    return [self fw_colorWithHex:hex alpha:1.0f];
}

+ (UIColor *)fw_colorWithHex:(long)hex alpha:(CGFloat)alpha
{
    float red = ((float)((hex & 0xFF0000) >> 16)) / 255.0;
    float green = ((float)((hex & 0xFF00) >> 8)) / 255.0;
    float blue = ((float)(hex & 0xFF)) / 255.0;
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+ (UIColor *)fw_colorWithHexString:(NSString *)hexString
{
    return [self fw_colorWithHexString:hexString alpha:1.0f];
}

+ (UIColor *)fw_colorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha
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

+ (UIColor *)fw_colorWithString:(NSString *)string
{
    return [self fw_colorWithString:string alpha:1.0f];
}

+ (UIColor *)fw_colorWithString:(NSString *)string alpha:(CGFloat)alpha
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
    return [self fw_colorWithHexString:string alpha:alpha];
}

@end

#pragma mark - UIFont+FWToolkit

UIFont * FWFontThin(CGFloat size) { return [UIFont fw_thinFontOfSize:size]; }
UIFont * FWFontLight(CGFloat size) { return [UIFont fw_lightFontOfSize:size]; }
UIFont * FWFontRegular(CGFloat size) { return [UIFont fw_fontOfSize:size]; }
UIFont * FWFontMedium(CGFloat size) { return [UIFont fw_mediumFontOfSize:size]; }
UIFont * FWFontSemibold(CGFloat size) { return [UIFont fw_semiboldFontOfSize:size]; }
UIFont * FWFontBold(CGFloat size) { return [UIFont fw_boldFontOfSize:size]; }

static BOOL fwStaticAutoScaleFont = NO;

@implementation UIFont (FWToolkit)

+ (BOOL)fw_autoScale
{
    return fwStaticAutoScaleFont;
}

+ (void)setFw_autoScale:(BOOL)autoScale
{
    fwStaticAutoScaleFont = autoScale;
}

+ (UIFont *)fw_thinFontOfSize:(CGFloat)size
{
    return [self fw_fontOfSize:size weight:UIFontWeightThin];
}

+ (UIFont *)fw_lightFontOfSize:(CGFloat)size
{
    return [self fw_fontOfSize:size weight:UIFontWeightLight];
}

+ (UIFont *)fw_fontOfSize:(CGFloat)size
{
    return [self fw_fontOfSize:size weight:UIFontWeightRegular];
}

+ (UIFont *)fw_mediumFontOfSize:(CGFloat)size
{
    return [self fw_fontOfSize:size weight:UIFontWeightMedium];
}

+ (UIFont *)fw_semiboldFontOfSize:(CGFloat)size
{
    return [self fw_fontOfSize:size weight:UIFontWeightSemibold];
}

+ (UIFont *)fw_boldFontOfSize:(CGFloat)size
{
    return [self fw_fontOfSize:size weight:UIFontWeightBold];
}

+ (UIFont * (^)(CGFloat, UIFontWeight))fw_fontBlock
{
    return objc_getAssociatedObject([UIFont class], @selector(fw_fontBlock));
}

+ (void)setFw_fontBlock:(UIFont * (^)(CGFloat, UIFontWeight))fontBlock
{
    objc_setAssociatedObject([UIFont class], @selector(fw_fontBlock), fontBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (UIFont *)fw_fontOfSize:(CGFloat)size weight:(UIFontWeight)weight
{
    UIFont * (^fontBlock)(CGFloat, UIFontWeight) = self.fw_fontBlock;
    if (fontBlock) return fontBlock(size, weight);
    
    if (fwStaticAutoScaleFont) {
        size = [UIScreen fw_relativeValue:size];
    }
    return [UIFont systemFontOfSize:size weight:weight];
}

@end

#pragma mark - UIImage+FWToolkit

@implementation UIImage (FWToolkit)

- (UIImage *)fw_imageWithAlpha:(CGFloat)alpha
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height) blendMode:kCGBlendModeNormal alpha:alpha];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)fw_imageWithTintColor:(UIColor *)tintColor
{
    return [self fw_imageWithTintColor:tintColor blendMode:kCGBlendModeDestinationIn];
}

- (UIImage *)fw_imageWithTintColor:(UIColor *)tintColor blendMode:(CGBlendMode)blendMode
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    [tintColor setFill];
    CGRect bounds = CGRectMake(0, 0, self.size.width, self.size.height);
    UIRectFill(bounds);
    [self drawInRect:bounds blendMode:blendMode alpha:1.0f];
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return tintedImage;
}

- (UIImage *)fw_imageWithScaleSize:(CGSize)size
{
    if (size.width <= 0 || size.height <= 0) return nil;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)fw_imageWithScaleSize:(CGSize)size contentMode:(UIViewContentMode)contentMode
{
    if (size.width <= 0 || size.height <= 0) return nil;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [self fw_drawInRect:CGRectMake(0, 0, size.width, size.height) withContentMode:contentMode clipsToBounds:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)fw_drawInRect:(CGRect)rect withContentMode:(UIViewContentMode)contentMode clipsToBounds:(BOOL)clipsToBounds
{
    CGRect drawRect = [self fw_innerRectWithContentMode:contentMode rect:rect size:self.size];
    if (drawRect.size.width == 0 || drawRect.size.height == 0) return;
    if (clipsToBounds) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        if (context) {
            CGContextSaveGState(context);
            CGContextAddRect(context, rect);
            CGContextClip(context);
            [self drawInRect:drawRect];
            CGContextRestoreGState(context);
        }
    } else {
        [self drawInRect:drawRect];
    }
}

- (CGRect)fw_innerRectWithContentMode:(UIViewContentMode)mode rect:(CGRect)rect size:(CGSize)size
{
    rect = CGRectStandardize(rect);
    size.width = size.width < 0 ? -size.width : size.width;
    size.height = size.height < 0 ? -size.height : size.height;
    CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    switch (mode) {
        case UIViewContentModeScaleAspectFit:
        case UIViewContentModeScaleAspectFill: {
            if (rect.size.width < 0.01 || rect.size.height < 0.01 ||
                size.width < 0.01 || size.height < 0.01) {
                rect.origin = center;
                rect.size = CGSizeZero;
            } else {
                CGFloat scale;
                if (mode == UIViewContentModeScaleAspectFit) {
                    if (size.width / size.height < rect.size.width / rect.size.height) {
                        scale = rect.size.height / size.height;
                    } else {
                        scale = rect.size.width / size.width;
                    }
                } else {
                    if (size.width / size.height < rect.size.width / rect.size.height) {
                        scale = rect.size.width / size.width;
                    } else {
                        scale = rect.size.height / size.height;
                    }
                }
                size.width *= scale;
                size.height *= scale;
                rect.size = size;
                rect.origin = CGPointMake(center.x - size.width * 0.5, center.y - size.height * 0.5);
            }
        } break;
        case UIViewContentModeCenter: {
            rect.size = size;
            rect.origin = CGPointMake(center.x - size.width * 0.5, center.y - size.height * 0.5);
        } break;
        case UIViewContentModeTop: {
            rect.origin.x = center.x - size.width * 0.5;
            rect.size = size;
        } break;
        case UIViewContentModeBottom: {
            rect.origin.x = center.x - size.width * 0.5;
            rect.origin.y += rect.size.height - size.height;
            rect.size = size;
        } break;
        case UIViewContentModeLeft: {
            rect.origin.y = center.y - size.height * 0.5;
            rect.size = size;
        } break;
        case UIViewContentModeRight: {
            rect.origin.y = center.y - size.height * 0.5;
            rect.origin.x += rect.size.width - size.width;
            rect.size = size;
        } break;
        case UIViewContentModeTopLeft: {
            rect.size = size;
        } break;
        case UIViewContentModeTopRight: {
            rect.origin.x += rect.size.width - size.width;
            rect.size = size;
        } break;
        case UIViewContentModeBottomLeft: {
            rect.origin.y += rect.size.height - size.height;
            rect.size = size;
        } break;
        case UIViewContentModeBottomRight: {
            rect.origin.x += rect.size.width - size.width;
            rect.origin.y += rect.size.height - size.height;
            rect.size = size;
        } break;
        case UIViewContentModeScaleToFill:
        case UIViewContentModeRedraw:
        default: {
            rect = rect;
        }
    }
    return rect;
}

- (UIImage *)fw_imageWithCropRect:(CGRect)rect
{
    rect.origin.x *= self.scale;
    rect.origin.y *= self.scale;
    rect.size.width *= self.scale;
    rect.size.height *= self.scale;
    if (rect.size.width <= 0 || rect.size.height <= 0) return nil;
    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    return image;
}

- (UIImage *)fw_imageWithInsets:(UIEdgeInsets)insets color:(UIColor *)color
{
    CGSize size = self.size;
    size.width -= insets.left + insets.right;
    size.height -= insets.top + insets.bottom;
    if (size.width <= 0 || size.height <= 0) return nil;
    CGRect rect = CGRectMake(-insets.left, -insets.top, self.size.width, self.size.height);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (color) {
        CGContextSetFillColorWithColor(context, color.CGColor);
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, CGRectMake(0, 0, size.width, size.height));
        CGPathAddRect(path, NULL, rect);
        CGContextAddPath(context, path);
        CGContextEOFillPath(context);
        CGPathRelease(path);
    }
    [self drawInRect:rect];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)fw_imageWithCapInsets:(UIEdgeInsets)insets
{
    return [self resizableImageWithCapInsets:insets];
}

- (UIImage *)fw_imageWithCapInsets:(UIEdgeInsets)insets resizingMode:(UIImageResizingMode)resizingMode
{
    return [self resizableImageWithCapInsets:insets resizingMode:resizingMode];
}

- (UIImage *)fw_imageWithCornerRadius:(CGFloat)radius
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius] addClip];
    
    [self drawInRect:rect];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)fw_imageWithRotateDegree:(CGFloat)degree
{
    return [self fw_imageWithRotateDegree:degree fitSize:YES];
}

- (UIImage *)fw_imageWithRotateDegree:(CGFloat)degree fitSize:(BOOL)fitSize
{
    CGFloat radians = degree * M_PI / 180.0;
    size_t width = (size_t)CGImageGetWidth(self.CGImage);
    size_t height = (size_t)CGImageGetHeight(self.CGImage);
    CGRect newRect = CGRectApplyAffineTransform(CGRectMake(0., 0., width, height),
                                                fitSize ? CGAffineTransformMakeRotation(radians) : CGAffineTransformIdentity);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 (size_t)newRect.size.width,
                                                 (size_t)newRect.size.height,
                                                 8,
                                                 (size_t)newRect.size.width * 4,
                                                 colorSpace,
                                                 kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    if (!context) return nil;
    
    CGContextSetShouldAntialias(context, true);
    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextTranslateCTM(context, +(newRect.size.width * 0.5), +(newRect.size.height * 0.5));
    CGContextRotateCTM(context, radians);
    
    CGContextDrawImage(context, CGRectMake(-(width * 0.5), -(height * 0.5), width, height), self.CGImage);
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    UIImage *img = [UIImage imageWithCGImage:imgRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imgRef);
    CGContextRelease(context);
    return img;
}

- (UIImage *)fw_imageWithMaskImage:(UIImage *)maskImage
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClipToMask(context, CGRectMake(0.0f, 0.0f, self.size.width, self.size.height), maskImage.CGImage);
    
    [self drawAtPoint:CGPointZero];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)fw_imageWithMergeImage:(UIImage *)mergeImage atPoint:(CGPoint)point
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0);
    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height)];
    [mergeImage drawAtPoint:point];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)fw_imageWithFilter:(CIFilter *)filter
{
    CIImage *inputImage;
    if (self.CIImage) {
        inputImage = self.CIImage;
    } else {
        CGImageRef imageRef = self.CGImage;
        if (!imageRef) return nil;
        inputImage = [CIImage imageWithCGImage:imageRef];
    }
    if (!inputImage) return nil;
    
    CIContext *context = [CIContext context];
    [filter setValue:inputImage forKey:kCIInputImageKey];
    CIImage *outputImage = filter.outputImage;
    if (!outputImage) return nil;
    
    CGImageRef imageRef = [context createCGImage:outputImage fromRect:outputImage.extent];
    if (!imageRef) return nil;
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    return image;
}

- (UIImage *)fw_compressImageWithMaxLength:(NSInteger)maxLength
{
    NSData *data = [self fw_compressDataWithMaxLength:maxLength compressRatio:0];
    return [[UIImage alloc] initWithData:data];
}

- (NSData *)fw_compressDataWithMaxLength:(NSInteger)maxLength compressRatio:(CGFloat)compressRatio
{
    CGFloat compress = 1.f;
    CGFloat stepCompress = compressRatio > 0 ? compressRatio : 0.1f;
    NSData *data = self.fw_hasAlpha
        ? UIImagePNGRepresentation(self)
        : UIImageJPEGRepresentation(self, compress);
    while (data.length > maxLength && compress > stepCompress) {
        compress -= stepCompress;
        data = UIImageJPEGRepresentation(self, compress);
    }
    return data;
}

- (UIImage *)fw_compressImageWithMaxWidth:(NSInteger)maxWidth
{
    CGSize newSize = [self fw_scaleSizeWithMaxWidth:maxWidth];
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    [self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (CGSize)fw_scaleSizeWithMaxWidth:(CGFloat)maxWidth
{
    if (maxWidth <= 0) {
        return self.size;
    }
    
    CGFloat width = self.size.width;
    CGFloat height = self.size.height;
    if (width > maxWidth || height > maxWidth) {
        CGFloat newWidth = 0.0f;
        CGFloat newHeight = 0.0f;
        if (width > height) {
            newWidth = maxWidth;
            newHeight = newWidth * height / width;
        } else if (height > width) {
            newHeight = maxWidth;
            newWidth = newHeight * width / height;
        } else {
            newWidth = maxWidth;
            newHeight = maxWidth;
        }
        return CGSizeMake(newWidth, newHeight);
    } else {
        return CGSizeMake(width, height);
    }
}

- (UIImage *)fw_originalImage
{
    return [self imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (UIImage *)fw_templateImage
{
    return [self imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (BOOL)fw_hasAlpha
{
    if (self.CGImage == NULL) return NO;
    CGImageAlphaInfo alpha = CGImageGetAlphaInfo(self.CGImage) & kCGBitmapAlphaInfoMask;
    return (alpha == kCGImageAlphaFirst ||
            alpha == kCGImageAlphaLast ||
            alpha == kCGImageAlphaPremultipliedFirst ||
            alpha == kCGImageAlphaPremultipliedLast);
}

- (CGSize)fw_pixelSize
{
    return CGSizeMake(self.size.width * self.scale, self.size.height * self.scale);
}

+ (UIImage *)fw_imageWithView:(UIView *)view
{
    if (!view) return nil;
    
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0);
    if (view.window) {
        [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    } else {
        [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)fw_imageWithColor:(UIColor *)color
{
    return [self fw_imageWithColor:color size:CGSizeMake(1.0f, 1.0f)];
}

+ (UIImage *)fw_imageWithColor:(UIColor *)color size:(CGSize)size
{
    return [self fw_imageWithColor:color size:size cornerRadius:0];
}

+ (UIImage *)fw_imageWithColor:(UIColor *)color size:(CGSize)size cornerRadius:(CGFloat)radius
{
    if (!color || size.width <= 0 || size.height <= 0) return nil;
    
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    if (radius > 0) {
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius];
        [path addClip];
        [path fill];
    } else {
        CGContextFillRect(context, rect);
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)fw_imageWithSize:(CGSize)size block:(void (NS_NOESCAPE ^)(CGContextRef))block
{
    if (!block) return nil;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) return nil;
    block(context);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)fw_saveImageWithCompletion:(void (^)(NSError * _Nullable))completion
{
    objc_setAssociatedObject(self, @selector(fw_saveImageWithCompletion:), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
    UIImageWriteToSavedPhotosAlbum(self, self, @selector(fw_innerImage:didFinishSavingWithError:contextInfo:), NULL);
}

+ (void)fw_saveVideo:(NSString *)videoPath withCompletion:(nullable void (^)(NSError * _Nullable))completion
{
    objc_setAssociatedObject(self, @selector(fw_saveVideo:withCompletion:), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoPath)) {
        UISaveVideoAtPathToSavedPhotosAlbum(videoPath, self, @selector(fw_innerVideo:didFinishSavingWithError:contextInfo:), NULL);
    }
}

- (void)fw_innerImage:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    void (^block)(NSError *error) = objc_getAssociatedObject(self, @selector(fw_saveImageWithCompletion:));
    objc_setAssociatedObject(self, @selector(fw_saveImageWithCompletion:), nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
    if (block) {
        block(error);
    }
}

+ (void)fw_innerVideo:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    void (^block)(NSError *error) = objc_getAssociatedObject(self, @selector(fw_saveVideo:withCompletion:));
    objc_setAssociatedObject(self, @selector(fw_saveVideo:withCompletion:), nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
    if (block) {
        block(error);
    }
}

@end

#pragma mark - UIView+FWToolkit

@implementation UIView (FWToolkit)

- (CGFloat)fw_top
{
    return self.frame.origin.y;
}

- (void)setFw_top:(CGFloat)top
{
    CGRect frame = self.frame;
    frame.origin.y = top;
    self.frame = frame;
}

- (CGFloat)fw_bottom
{
    return self.fw_top + self.fw_height;
}

- (void)setFw_bottom:(CGFloat)bottom
{
    self.fw_top = bottom - self.fw_height;
}

- (CGFloat)fw_left
{
    return self.frame.origin.x;
}

- (void)setFw_left:(CGFloat)left
{
    CGRect frame = self.frame;
    frame.origin.x = left;
    self.frame = frame;
}

- (CGFloat)fw_right
{
    return self.fw_left + self.fw_width;
}

- (void)setFw_right:(CGFloat)right
{
    self.fw_left = right - self.fw_width;
}

- (CGFloat)fw_width
{
    return self.frame.size.width;
}

- (void)setFw_width:(CGFloat)width
{
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (CGFloat)fw_height
{
    return self.frame.size.height;
}

- (void)setFw_height:(CGFloat)height
{
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (CGFloat)fw_centerX
{
    return self.center.x;
}

- (void)setFw_centerX:(CGFloat)centerX
{
    self.center = CGPointMake(centerX, self.fw_centerY);
}

- (CGFloat)fw_centerY
{
    return self.center.y;
}

- (void)setFw_centerY:(CGFloat)centerY
{
    self.center = CGPointMake(self.fw_centerX, centerY);
}

- (CGFloat)fw_x
{
    return self.frame.origin.x;
}

- (void)setFw_x:(CGFloat)x
{
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (CGFloat)fw_y
{
    return self.frame.origin.y;
}

- (void)setFw_y:(CGFloat)y
{
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (CGPoint)fw_origin
{
    return self.frame.origin;
}

- (void)setFw_origin:(CGPoint)origin
{
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}

- (CGSize)fw_size
{
    return self.frame.size;
}

- (void)setFw_size:(CGSize)size
{
    CGRect frame = self.frame;
    frame.size = size;
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
            selfObject.fw_visibleState = FWViewControllerVisibleStateDidLoad;
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewWillAppear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            selfObject.fw_visibleState = FWViewControllerVisibleStateWillAppear;
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewDidAppear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            selfObject.fw_visibleState = FWViewControllerVisibleStateDidAppear;
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewWillDisappear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            selfObject.fw_visibleState = FWViewControllerVisibleStateWillDisappear;
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewDidDisappear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            selfObject.fw_visibleState = FWViewControllerVisibleStateDidDisappear;
        }));
        
        FWSwizzleClass(UIViewController, NSSelectorFromString(@"dealloc"), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            // dealloc时不调用fw，防止释放时动态创建包装器对象
            void (^completionHandler)(id) = objc_getAssociatedObject(selfObject, @selector(fw_completionHandler));
            if (completionHandler != nil) {
                id completionResult = objc_getAssociatedObject(selfObject, @selector(fw_completionResult));
                completionHandler(completionResult);
            }
            
            FWSwizzleOriginal();
        }));
    });
}

- (FWViewControllerVisibleState)fw_visibleState
{
    return [objc_getAssociatedObject(self, @selector(fw_visibleState)) unsignedIntegerValue];
}

- (void)setFw_visibleState:(FWViewControllerVisibleState)visibleState
{
    BOOL valueChanged = self.fw_visibleState != visibleState;
    objc_setAssociatedObject(self, @selector(fw_visibleState), @(visibleState), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (valueChanged && self.fw_visibleStateChanged) {
        self.fw_visibleStateChanged(self, visibleState);
    }
}

- (void (^)(__kindof UIViewController *, FWViewControllerVisibleState))fw_visibleStateChanged
{
    return objc_getAssociatedObject(self, @selector(fw_visibleStateChanged));
}

- (void)setFw_visibleStateChanged:(void (^)(__kindof UIViewController *, FWViewControllerVisibleState))visibleStateChanged
{
    objc_setAssociatedObject(self, @selector(fw_visibleStateChanged), visibleStateChanged, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (id)fw_completionResult
{
    return objc_getAssociatedObject(self, @selector(fw_completionResult));
}

- (void)setFw_completionResult:(id)completionResult
{
    objc_setAssociatedObject(self, @selector(fw_completionResult), completionResult, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void (^)(id _Nullable))fw_completionHandler
{
    return objc_getAssociatedObject(self, @selector(fw_completionHandler));
}

- (void)setFw_completionHandler:(void (^)(id _Nullable))completionHandler
{
    objc_setAssociatedObject(self, @selector(fw_completionHandler), completionHandler, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL (^)(void))fw_allowsPopGesture
{
    return objc_getAssociatedObject(self, @selector(fw_allowsPopGesture));
}

- (void)setFw_allowsPopGesture:(BOOL (^)(void))allowsPopGesture
{
    objc_setAssociatedObject(self, @selector(fw_allowsPopGesture), allowsPopGesture, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL (^)(void))fw_shouldPopController
{
    return objc_getAssociatedObject(self, @selector(fw_shouldPopController));
}

- (void)setFw_shouldPopController:(BOOL (^)(void))shouldPopController
{
    objc_setAssociatedObject(self, @selector(fw_shouldPopController), shouldPopController, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)allowsPopGesture
{
    BOOL (^block)(void) = objc_getAssociatedObject(self, @selector(fw_allowsPopGesture));
    if (block) return block();
    return YES;
}

- (BOOL)shouldPopController
{
    BOOL (^block)(void) = objc_getAssociatedObject(self, @selector(fw_shouldPopController));
    if (block) return block();
    return YES;
}

@end

#pragma mark - UINavigationController+FWToolkit

@interface FWInnerPopProxyTarget : NSObject <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UINavigationController *navigationController;

@end

@implementation FWInnerPopProxyTarget

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController
{
    self = [super init];
    if (self) {
        _navigationController = navigationController;
    }
    return self;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    UIViewController *topController = self.navigationController.topViewController;
    return topController.shouldPopController && topController.allowsPopGesture;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return [gestureRecognizer isKindOfClass:[UIScreenEdgePanGestureRecognizer class]];
}

@end

@interface FWGestureRecognizerDelegateProxy : FWDelegateProxy <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UINavigationController *navigationController;

@end

@implementation FWGestureRecognizerDelegateProxy

- (BOOL)shouldForceReceive
{
    if (self.navigationController.viewControllers.count <= 1) return NO;
    if (!self.navigationController.interactivePopGestureRecognizer.enabled) return NO;
    return self.navigationController.topViewController.allowsPopGesture;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.navigationController.interactivePopGestureRecognizer) {
        // 调用钩子。如果返回NO，则不开始手势；如果返回YES，则使用系统方式
        BOOL shouldPop = self.navigationController.topViewController.shouldPopController;
        if (shouldPop) {
            if ([self.delegate respondsToSelector:@selector(gestureRecognizerShouldBegin:)]) {
                return [self.delegate gestureRecognizerShouldBegin:gestureRecognizer];
            }
        }
        return NO;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (gestureRecognizer == self.navigationController.interactivePopGestureRecognizer) {
        if ([self.delegate respondsToSelector:@selector(gestureRecognizer:shouldReceiveTouch:)]) {
            BOOL shouldReceive = [self.delegate gestureRecognizer:gestureRecognizer shouldReceiveTouch:touch];
            if (!shouldReceive && [self shouldForceReceive]) {
                return YES;
            }
            return shouldReceive;
        }
    }
    return YES;
}

- (BOOL)_gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveEvent:(UIEvent *)event
{
    // 修复iOS13.4拦截返回失效问题，返回YES才会走后续流程
    if (gestureRecognizer == self.navigationController.interactivePopGestureRecognizer) {
        if ([self.delegate respondsToSelector:@selector(_gestureRecognizer:shouldReceiveEvent:)]) {
            BOOL shouldReceive = [self.delegate _gestureRecognizer:gestureRecognizer shouldReceiveEvent:event];
            if (!shouldReceive && [self shouldForceReceive]) {
                return YES;
            }
            return shouldReceive;
        }
    }
    return YES;
}

@end

static BOOL fwStaticPopProxyEnabled = NO;

@implementation UINavigationController (FWToolkit)

+ (void)fw_swizzlePopProxy
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UINavigationController, @selector(navigationBar:shouldPopItem:), FWSwizzleReturn(BOOL), FWSwizzleArgs(UINavigationBar *navigationBar, UINavigationItem *item), FWSwizzleCode({
            if (fwStaticPopProxyEnabled || [selfObject fw_popProxyEnabled]) {
                // 检查并调用返回按钮钩子。如果返回NO，则不pop当前页面；如果返回YES，则使用默认方式
                if (selfObject.viewControllers.count >= navigationBar.items.count &&
                    !selfObject.topViewController.shouldPopController) {
                    return NO;
                }
            }
            
            return FWSwizzleOriginal(navigationBar, item);
        }));
        
        FWSwizzleClass(UINavigationController, @selector(viewDidLoad), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            if (!fwStaticPopProxyEnabled || [selfObject fw_popProxyEnabled]) return;
            
            // 拦截系统返回手势事件代理，加载自定义代理方法
            if (selfObject.interactivePopGestureRecognizer.delegate != selfObject.fw_delegateProxy) {
                selfObject.fw_delegateProxy.delegate = selfObject.interactivePopGestureRecognizer.delegate;
                selfObject.fw_delegateProxy.navigationController = selfObject;
                selfObject.interactivePopGestureRecognizer.delegate = selfObject.fw_delegateProxy;
            }
        }));
        
        FWSwizzleClass(UINavigationController, @selector(childViewControllerForStatusBarHidden), FWSwizzleReturn(UIViewController *), FWSwizzleArgs(), FWSwizzleCode({
            if (fwStaticPopProxyEnabled && selfObject.topViewController) {
                return selfObject.topViewController;
            } else {
                return FWSwizzleOriginal();
            }
        }));
        FWSwizzleClass(UINavigationController, @selector(childViewControllerForStatusBarStyle), FWSwizzleReturn(UIViewController *), FWSwizzleArgs(), FWSwizzleCode({
            if (fwStaticPopProxyEnabled && selfObject.topViewController) {
                return selfObject.topViewController;
            } else {
                return FWSwizzleOriginal();
            }
        }));
    });
}

- (BOOL)fw_popProxyEnabled
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)fw_enablePopProxy
{
    self.interactivePopGestureRecognizer.delegate = self.fw_innerPopProxyTarget;
    objc_setAssociatedObject(self, @selector(fw_popProxyEnabled), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [UINavigationController fw_swizzlePopProxy];
}

- (FWInnerPopProxyTarget *)fw_innerPopProxyTarget
{
    FWInnerPopProxyTarget *target = objc_getAssociatedObject(self, _cmd);
    if (!target) {
        target = [[FWInnerPopProxyTarget alloc] initWithNavigationController:self];
        objc_setAssociatedObject(self, _cmd, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return target;
}

- (FWGestureRecognizerDelegateProxy *)fw_delegateProxy
{
    FWGestureRecognizerDelegateProxy *proxy = objc_getAssociatedObject(self, _cmd);
    if (!proxy) {
        proxy = [[FWGestureRecognizerDelegateProxy alloc] init];
        objc_setAssociatedObject(self, _cmd, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return proxy;
}

+ (void)fw_enablePopProxy
{
    fwStaticPopProxyEnabled = YES;
    [UINavigationController fw_swizzlePopProxy];
}

@end
