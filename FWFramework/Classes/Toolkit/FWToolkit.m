/**
 @header     FWToolkit.m
 @indexgroup FWFramework
      FWToolkit
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/22
 */

#import "FWToolkit.h"
#import "FWNavigation.h"
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

+ (void)fwOpenAppStore:(NSString *)appId
{
    // SKStoreProductViewController可以内部打开
    [self fwOpenURL:[NSString stringWithFormat:@"https://apps.apple.com/app/id%@", appId]];
}

+ (void)fwOpenAppStoreReview:(NSString *)appId
{
    [self fwOpenURL:[NSString stringWithFormat:@"https://apps.apple.com/app/id%@?action=write-review", appId]];
}

+ (void)fwOpenAppReview
{
    [SKStoreReviewController requestReview];
}

+ (void)fwOpenAppSettings
{
    [self fwOpenURL:UIApplicationOpenSettingsURLString];
}

+ (void)fwOpenMailApp:(NSString *)email
{
    [self fwOpenURL:[NSString stringWithFormat:@"mailto://%@", email]];
}

+ (void)fwOpenMessageApp:(NSString *)phone
{
    [self fwOpenURL:[NSString stringWithFormat:@"sms://%@", phone]];
}

+ (void)fwOpenPhoneApp:(NSString *)phone
{
    // tel:为直接拨打电话
    [self fwOpenURL:[NSString stringWithFormat:@"telprompt://%@", phone]];
}

+ (void)fwOpenActivityItems:(NSArray *)activityItems excludedTypes:(NSArray<UIActivityType> *)excludedTypes
{
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityController.excludedActivityTypes = excludedTypes;
    [[UIWindow fwMainWindow] fwPresentViewController:activityController animated:YES completion:nil];
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

+ (void)fwOpenMessageController:(MFMessageComposeViewController *)controller completionHandler:(void (^)(BOOL))completion
{
    if (!controller || ![MFMessageComposeViewController canSendText]) {
        if (completion) completion(NO);
        return;
    }
    
    if (completion) {
        objc_setAssociatedObject(controller, @selector(messageComposeViewController:didFinishWithResult:), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    controller.messageComposeDelegate = [FWSafariViewControllerDelegate sharedInstance];
    [UIWindow.fwMainWindow fwPresentViewController:controller animated:YES completion:nil];
}

+ (void)fwOpenMailController:(MFMailComposeViewController *)controller completionHandler:(void (^)(BOOL))completion
{
    if (!controller || ![MFMailComposeViewController canSendMail]) {
        if (completion) completion(NO);
        return;
    }
    
    if (completion) {
        objc_setAssociatedObject(controller, @selector(mailComposeController:didFinishWithResult:error:), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    controller.mailComposeDelegate = [FWSafariViewControllerDelegate sharedInstance];
    [UIWindow.fwMainWindow fwPresentViewController:controller animated:YES completion:nil];
}

+ (void)fwOpenStoreController:(NSDictionary<NSString *,id> *)parameters completionHandler:(void (^)(BOOL))completion
{
    SKStoreProductViewController *viewController = [[SKStoreProductViewController alloc] init];
    viewController.delegate = [FWSafariViewControllerDelegate sharedInstance];
    [viewController loadProductWithParameters:parameters completionBlock:^(BOOL result, NSError * _Nullable error) {
        if (!result) {
            if (completion) completion(NO);
            return;
        }
        
        objc_setAssociatedObject(viewController, @selector(productViewControllerDidFinish:), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
        [UIWindow.fwMainWindow fwPresentViewController:viewController animated:YES completion:nil];
    }];
}

+ (AVPlayerViewController *)fwOpenVideoPlayer:(id)url
{
    AVPlayer *player = nil;
    if ([url isKindOfClass:[AVPlayerItem class]]) {
        player = [AVPlayer playerWithPlayerItem:(AVPlayerItem *)url];
    } else if ([url isKindOfClass:[NSURL class]]) {
        player = [AVPlayer playerWithURL:(NSURL *)url];
    } else if ([url isKindOfClass:[NSString class]]) {
        NSURL *videoURL = [self fwNSURLWithURL:url];
        if (videoURL) player = [AVPlayer playerWithURL:videoURL];
    }
    if (!player) return nil;
    
    AVPlayerViewController *viewController = [[AVPlayerViewController alloc] init];
    viewController.player = player;
    return viewController;
}

+ (AVAudioPlayer *)fwOpenAudioPlayer:(id)url
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

- (UIColor *)fwColorWithAlpha:(CGFloat)alpha
{
    return [self colorWithAlphaComponent:alpha];
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

#pragma mark - UIImage+FWToolkit

@implementation UIImage (FWToolkit)

+ (UIImage *)fwImageWithView:(UIView *)view
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

+ (UIImage *)fwImageWithColor:(UIColor *)color
{
    return [UIImage fwImageWithColor:color size:CGSizeMake(1.0f, 1.0f)];
}

+ (UIImage *)fwImageWithColor:(UIColor *)color size:(CGSize)size
{
    return [UIImage fwImageWithColor:color size:size cornerRadius:0];
}

+ (UIImage *)fwImageWithColor:(UIColor *)color size:(CGSize)size cornerRadius:(CGFloat)radius
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

- (UIImage *)fwImageWithAlpha:(CGFloat)alpha
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height) blendMode:kCGBlendModeNormal alpha:alpha];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)fwImageWithSize:(CGSize)size block:(void (NS_NOESCAPE ^)(CGContextRef))block
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

- (UIImage *)fwImageWithTintColor:(UIColor *)tintColor
{
    return [self fwImageWithTintColor:tintColor blendMode:kCGBlendModeDestinationIn];
}

- (UIImage *)fwImageWithTintColor:(UIColor *)tintColor blendMode:(CGBlendMode)blendMode
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

- (UIImage *)fwImageWithScaleSize:(CGSize)size
{
    if (size.width <= 0 || size.height <= 0) return nil;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)fwImageWithScaleSize:(CGSize)size contentMode:(UIViewContentMode)contentMode
{
    if (size.width <= 0 || size.height <= 0) return nil;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [self fwDrawInRect:CGRectMake(0, 0, size.width, size.height) withContentMode:contentMode clipsToBounds:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)fwDrawInRect:(CGRect)rect withContentMode:(UIViewContentMode)contentMode clipsToBounds:(BOOL)clipsToBounds
{
    CGRect drawRect = [self fwInnerRectWithContentMode:contentMode rect:rect size:self.size];
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

- (CGRect)fwInnerRectWithContentMode:(UIViewContentMode)mode rect:(CGRect)rect size:(CGSize)size
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

- (UIImage *)fwImageWithCropRect:(CGRect)rect
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

- (UIImage *)fwImageWithInsets:(UIEdgeInsets)insets color:(UIColor *)color
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

- (UIImage *)fwImageWithCapInsets:(UIEdgeInsets)insets
{
    return [self resizableImageWithCapInsets:insets];
}

- (UIImage *)fwImageWithCapInsets:(UIEdgeInsets)insets resizingMode:(UIImageResizingMode)resizingMode
{
    return [self resizableImageWithCapInsets:insets resizingMode:resizingMode];
}

- (UIImage *)fwImageWithCornerRadius:(CGFloat)radius
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius] addClip];
    
    [self drawInRect:rect];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)fwImageWithRotateDegree:(CGFloat)degree
{
    return [self fwImageWithRotateDegree:degree fitSize:YES];
}

- (UIImage *)fwImageWithRotateDegree:(CGFloat)degree fitSize:(BOOL)fitSize
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

- (UIImage *)fwImageWithMaskImage:(UIImage *)maskImage
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClipToMask(context, CGRectMake(0.0f, 0.0f, self.size.width, self.size.height), maskImage.CGImage);
    
    [self drawAtPoint:CGPointZero];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)fwImageWithMergeImage:(UIImage *)mergeImage atPoint:(CGPoint)point
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0);
    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height)];
    [mergeImage drawAtPoint:point];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)fwImageWithFilter:(CIFilter *)filter
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

- (UIImage *)fwCompressImageWithMaxLength:(NSInteger)maxLength
{
    NSData *data = [self fwCompressDataWithMaxLength:maxLength compressRatio:0];
    return [[UIImage alloc] initWithData:data];
}

- (NSData *)fwCompressDataWithMaxLength:(NSInteger)maxLength compressRatio:(CGFloat)compressRatio
{
    CGFloat compress = 1.f;
    CGFloat stepCompress = compressRatio > 0 ? compressRatio : 0.1f;
    NSData *data = self.fwHasAlpha
        ? UIImagePNGRepresentation(self)
        : UIImageJPEGRepresentation(self, compress);
    while (data.length > maxLength && compress > stepCompress) {
        compress -= stepCompress;
        data = UIImageJPEGRepresentation(self, compress);
    }
    return data;
}

- (UIImage *)fwCompressImageWithMaxWidth:(NSInteger)maxWidth
{
    CGSize newSize = [self fwScaleSizeWithMaxWidth:maxWidth];
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    [self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (CGSize)fwScaleSizeWithMaxWidth:(CGFloat)maxWidth
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

- (UIImage *)fwOriginalImage
{
    return [self imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (UIImage *)fwTemplateImage
{
    return [self imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (BOOL)fwHasAlpha
{
    if (self.CGImage == NULL) return NO;
    CGImageAlphaInfo alpha = CGImageGetAlphaInfo(self.CGImage) & kCGBitmapAlphaInfoMask;
    return (alpha == kCGImageAlphaFirst ||
            alpha == kCGImageAlphaLast ||
            alpha == kCGImageAlphaPremultipliedFirst ||
            alpha == kCGImageAlphaPremultipliedLast);
}

- (CGSize)fwPixelSize
{
    return CGSizeMake(self.size.width * self.scale, self.size.height * self.scale);
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
            if (selfObject.fwCompletionHandler) selfObject.fwCompletionHandler(selfObject.fwCompletionResult);
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

- (id)fwCompletionResult
{
    return objc_getAssociatedObject(self, @selector(fwCompletionResult));
}

- (void)setFwCompletionResult:(id)fwCompletionResult
{
    objc_setAssociatedObject(self, @selector(fwCompletionResult), fwCompletionResult, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void (^)(id _Nullable))fwCompletionHandler
{
    return objc_getAssociatedObject(self, @selector(fwCompletionHandler));
}

- (void)setFwCompletionHandler:(void (^)(id _Nullable))fwCompletionHandler
{
    objc_setAssociatedObject(self, @selector(fwCompletionHandler), fwCompletionHandler, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
