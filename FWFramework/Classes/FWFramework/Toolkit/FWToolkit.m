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

#pragma mark - FWApplicationClassWrapper+FWToolkit

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

@implementation FWApplicationClassWrapper (FWToolkit)

- (BOOL)canOpenURL:(id)url
{
    NSURL *nsurl = [self urlWithString:url];
    return [[UIApplication sharedApplication] canOpenURL:nsurl];
}

- (void)openURL:(id)url
{
    [self openURL:url completionHandler:nil];
}

- (void)openURL:(id)url completionHandler:(void (^)(BOOL success))completion
{
    NSURL *nsurl = [self urlWithString:url];
    [[UIApplication sharedApplication] openURL:nsurl options:@{} completionHandler:completion];
}

- (void)openUniversalLinks:(id)url completionHandler:(void (^)(BOOL))completion
{
    NSURL *nsurl = [self urlWithString:url];
    [[UIApplication sharedApplication] openURL:nsurl options:@{UIApplicationOpenURLOptionUniversalLinksOnly: @YES} completionHandler:completion];
}

- (BOOL)isSystemURL:(id)url
{
    NSURL *nsurl = [self urlWithString:url];
    if (nsurl.scheme.lowercaseString && [@[@"tel", @"telprompt", @"sms", @"mailto"] containsObject:nsurl.scheme.lowercaseString]) {
        return YES;
    }
    if ([self isAppStoreURL:nsurl]) {
        return YES;
    }
    if (nsurl.absoluteString && [nsurl.absoluteString isEqualToString:UIApplicationOpenSettingsURLString]) {
        return YES;
    }
    return NO;
}

- (BOOL)isHttpURL:(id)url
{
    NSString *urlString = [url isKindOfClass:[NSURL class]] ? [(NSURL *)url absoluteString] : url;
    return [urlString.lowercaseString hasPrefix:@"http://"] || [urlString.lowercaseString hasPrefix:@"https://"];
}

- (BOOL)isAppStoreURL:(id)url
{
    // itms-apps等
    NSURL *nsurl = [self urlWithString:url];
    if ([nsurl.scheme.lowercaseString hasPrefix:@"itms"]) {
        return YES;
    // https://apps.apple.com/等
    } else if ([nsurl.host.lowercaseString isEqualToString:@"itunes.apple.com"] ||
               [nsurl.host.lowercaseString isEqualToString:@"apps.apple.com"]) {
        return YES;
    }
    return NO;
}

- (void)openAppStore:(NSString *)appId
{
    // SKStoreProductViewController可以内部打开
    [self openURL:[NSString stringWithFormat:@"https://apps.apple.com/app/id%@", appId]];
}

- (void)openAppStoreReview:(NSString *)appId
{
    [self openURL:[NSString stringWithFormat:@"https://apps.apple.com/app/id%@?action=write-review", appId]];
}

- (void)openAppReview
{
    [SKStoreReviewController requestReview];
}

- (void)openAppSettings
{
    [self openURL:UIApplicationOpenSettingsURLString];
}

- (void)openMailApp:(NSString *)email
{
    [self openURL:[NSString stringWithFormat:@"mailto://%@", email]];
}

- (void)openMessageApp:(NSString *)phone
{
    [self openURL:[NSString stringWithFormat:@"sms://%@", phone]];
}

- (void)openPhoneApp:(NSString *)phone
{
    // tel:为直接拨打电话
    [self openURL:[NSString stringWithFormat:@"telprompt://%@", phone]];
}

- (void)openActivityItems:(NSArray *)activityItems excludedTypes:(NSArray<UIActivityType> *)excludedTypes
{
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityController.excludedActivityTypes = excludedTypes;
    [UIWindow.fw presentViewController:activityController animated:YES completion:nil];
}

- (void)openSafariController:(id)url
{
    [self openSafariController:url completionHandler:nil];
}

- (void)openSafariController:(id)url completionHandler:(nullable void (^)(void))completion
{
    if (![self isHttpURL:url]) return;
    
    NSURL *nsurl = [self urlWithString:url];
    SFSafariViewController *safariController = [[SFSafariViewController alloc] initWithURL:nsurl];
    if (completion) {
        objc_setAssociatedObject(safariController, @selector(safariViewControllerDidFinish:), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
        safariController.delegate = [FWSafariViewControllerDelegate sharedInstance];
    }
    [UIWindow.fw presentViewController:safariController animated:YES completion:nil];
}

- (void)openMessageController:(MFMessageComposeViewController *)controller completionHandler:(void (^)(BOOL))completion
{
    if (!controller || ![MFMessageComposeViewController canSendText]) {
        if (completion) completion(NO);
        return;
    }
    
    if (completion) {
        objc_setAssociatedObject(controller, @selector(messageComposeViewController:didFinishWithResult:), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    controller.messageComposeDelegate = [FWSafariViewControllerDelegate sharedInstance];
    [UIWindow.fw presentViewController:controller animated:YES completion:nil];
}

- (void)openMailController:(MFMailComposeViewController *)controller completionHandler:(void (^)(BOOL))completion
{
    if (!controller || ![MFMailComposeViewController canSendMail]) {
        if (completion) completion(NO);
        return;
    }
    
    if (completion) {
        objc_setAssociatedObject(controller, @selector(mailComposeController:didFinishWithResult:error:), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    controller.mailComposeDelegate = [FWSafariViewControllerDelegate sharedInstance];
    [UIWindow.fw presentViewController:controller animated:YES completion:nil];
}

- (void)openStoreController:(NSDictionary<NSString *,id> *)parameters completionHandler:(void (^)(BOOL))completion
{
    SKStoreProductViewController *viewController = [[SKStoreProductViewController alloc] init];
    viewController.delegate = [FWSafariViewControllerDelegate sharedInstance];
    [viewController loadProductWithParameters:parameters completionBlock:^(BOOL result, NSError * _Nullable error) {
        if (!result) {
            if (completion) completion(NO);
            return;
        }
        
        objc_setAssociatedObject(viewController, @selector(productViewControllerDidFinish:), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
        [UIWindow.fw presentViewController:viewController animated:YES completion:nil];
    }];
}

- (AVPlayerViewController *)openVideoPlayer:(id)url
{
    AVPlayer *player = nil;
    if ([url isKindOfClass:[AVPlayerItem class]]) {
        player = [AVPlayer playerWithPlayerItem:(AVPlayerItem *)url];
    } else if ([url isKindOfClass:[NSURL class]]) {
        player = [AVPlayer playerWithURL:(NSURL *)url];
    } else if ([url isKindOfClass:[NSString class]]) {
        NSURL *videoURL = [self urlWithString:url];
        if (videoURL) player = [AVPlayer playerWithURL:videoURL];
    }
    if (!player) return nil;
    
    AVPlayerViewController *viewController = [[AVPlayerViewController alloc] init];
    viewController.player = player;
    return viewController;
}

- (AVAudioPlayer *)openAudioPlayer:(id)url
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

- (NSURL *)urlWithString:(id)url
{
    if (![url isKindOfClass:[NSString class]]) return url;
    
    NSURL *nsurl = [NSURL URLWithString:url];
    if (!nsurl && [url length] > 0) {
        nsurl = [NSURL URLWithString:[url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    }
    return nsurl;
}

@end

#pragma mark - FWColorWrapper+FWToolkit

static BOOL fwStaticColorARGB = NO;

@implementation FWColorWrapper (FWToolkit)

- (UIColor *)colorWithAlpha:(CGFloat)alpha
{
    return [self.base colorWithAlphaComponent:alpha];
}

- (long)hexValue
{
    CGFloat r = 0, g = 0, b = 0, a = 0;
    if (![self.base getRed:&r green:&g blue:&b alpha:&a]) {
        if ([self.base getWhite:&r alpha:&a]) { g = r; b = r; }
    }
    
    int8_t red = r * 255;
    uint8_t green = g * 255;
    uint8_t blue = b * 255;
    return (red << 16) + (green << 8) + blue;
}

- (CGFloat)alphaValue
{
    return CGColorGetAlpha(self.base.CGColor);
}

- (NSString *)hexString
{
    CGFloat r = 0, g = 0, b = 0, a = 0;
    if (![self.base getRed:&r green:&g blue:&b alpha:&a]) {
        if ([self.base getWhite:&r alpha:&a]) { g = r; b = r; }
    }
    
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255)];
}

- (NSString *)hexStringWithAlpha
{
    CGFloat r = 0, g = 0, b = 0, a = 0;
    if (![self.base getRed:&r green:&g blue:&b alpha:&a]) {
        if ([self.base getWhite:&r alpha:&a]) { g = r; b = r; }
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

@implementation FWColorClassWrapper (FWToolkit)

- (BOOL)colorStandardARGB
{
    return fwStaticColorARGB;
}

- (void)setColorStandardARGB:(BOOL)enabled
{
    fwStaticColorARGB = enabled;
}

- (UIColor *)randomColor
{
    NSInteger red = arc4random() % 255;
    NSInteger green = arc4random() % 255;
    NSInteger blue = arc4random() % 255;
    return [UIColor colorWithRed:red / 255.0 green:green / 255.0 blue:blue / 255.0 alpha:1.0f];
}

- (UIColor *)colorWithHex:(long)hex
{
    return [self colorWithHex:hex alpha:1.0f];
}

- (UIColor *)colorWithHex:(long)hex alpha:(CGFloat)alpha
{
    float red = ((float)((hex & 0xFF0000) >> 16)) / 255.0;
    float green = ((float)((hex & 0xFF00) >> 8)) / 255.0;
    float blue = ((float)(hex & 0xFF)) / 255.0;
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

- (UIColor *)colorWithHexString:(NSString *)hexString
{
    return [self colorWithHexString:hexString alpha:1.0f];
}

- (UIColor *)colorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha
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

- (UIColor *)colorWithString:(NSString *)string
{
    return [self colorWithString:string alpha:1.0f];
}

- (UIColor *)colorWithString:(NSString *)string alpha:(CGFloat)alpha
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
    return [self colorWithHexString:string alpha:alpha];
}

@end

#pragma mark - FWFontClassWrapper+FWToolkit

UIFont * FWFontThin(CGFloat size) { return [UIFont.fw thinFontOfSize:size]; }
UIFont * FWFontLight(CGFloat size) { return [UIFont.fw lightFontOfSize:size]; }
UIFont * FWFontRegular(CGFloat size) { return [UIFont.fw fontOfSize:size]; }
UIFont * FWFontMedium(CGFloat size) { return [UIFont.fw mediumFontOfSize:size]; }
UIFont * FWFontSemibold(CGFloat size) { return [UIFont.fw semiboldFontOfSize:size]; }
UIFont * FWFontBold(CGFloat size) { return [UIFont.fw boldFontOfSize:size]; }

@implementation FWFontClassWrapper (FWToolkit)

- (UIFont *)thinFontOfSize:(CGFloat)size
{
    return [self fontOfSize:size weight:UIFontWeightThin];
}

- (UIFont *)lightFontOfSize:(CGFloat)size
{
    return [self fontOfSize:size weight:UIFontWeightLight];
}

- (UIFont *)fontOfSize:(CGFloat)size
{
    return [self fontOfSize:size weight:UIFontWeightRegular];
}

- (UIFont *)mediumFontOfSize:(CGFloat)size
{
    return [self fontOfSize:size weight:UIFontWeightMedium];
}

- (UIFont *)semiboldFontOfSize:(CGFloat)size
{
    return [self fontOfSize:size weight:UIFontWeightSemibold];
}

- (UIFont *)boldFontOfSize:(CGFloat)size
{
    return [self fontOfSize:size weight:UIFontWeightBold];
}

- (UIFont * (^)(CGFloat, UIFontWeight))fontBlock
{
    return objc_getAssociatedObject([UIFont class], @selector(fontBlock));
}

- (void)setFontBlock:(UIFont * (^)(CGFloat, UIFontWeight))fontBlock
{
    objc_setAssociatedObject([UIFont class], @selector(fontBlock), fontBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (UIFont *)fontOfSize:(CGFloat)size weight:(UIFontWeight)weight
{
    UIFont * (^fontBlock)(CGFloat, UIFontWeight) = self.fontBlock;
    if (fontBlock) return fontBlock(size, weight);
    
    return [UIFont systemFontOfSize:size weight:weight];
}

@end

#pragma mark - FWImageWrapper+FWToolkit

@implementation FWImageWrapper (FWToolkit)

- (UIImage *)imageWithAlpha:(CGFloat)alpha
{
    UIGraphicsBeginImageContextWithOptions(self.base.size, NO, self.base.scale);
    [self.base drawInRect:CGRectMake(0, 0, self.base.size.width, self.base.size.height) blendMode:kCGBlendModeNormal alpha:alpha];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)imageWithTintColor:(UIColor *)tintColor
{
    return [self imageWithTintColor:tintColor blendMode:kCGBlendModeDestinationIn];
}

- (UIImage *)imageWithTintColor:(UIColor *)tintColor blendMode:(CGBlendMode)blendMode
{
    UIGraphicsBeginImageContextWithOptions(self.base.size, NO, 0.0f);
    [tintColor setFill];
    CGRect bounds = CGRectMake(0, 0, self.base.size.width, self.base.size.height);
    UIRectFill(bounds);
    [self.base drawInRect:bounds blendMode:blendMode alpha:1.0f];
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return tintedImage;
}

- (UIImage *)imageWithScaleSize:(CGSize)size
{
    if (size.width <= 0 || size.height <= 0) return nil;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [self.base drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)imageWithScaleSize:(CGSize)size contentMode:(UIViewContentMode)contentMode
{
    if (size.width <= 0 || size.height <= 0) return nil;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height) withContentMode:contentMode clipsToBounds:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)drawInRect:(CGRect)rect withContentMode:(UIViewContentMode)contentMode clipsToBounds:(BOOL)clipsToBounds
{
    CGRect drawRect = [self innerRectWithContentMode:contentMode rect:rect size:self.base.size];
    if (drawRect.size.width == 0 || drawRect.size.height == 0) return;
    if (clipsToBounds) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        if (context) {
            CGContextSaveGState(context);
            CGContextAddRect(context, rect);
            CGContextClip(context);
            [self.base drawInRect:drawRect];
            CGContextRestoreGState(context);
        }
    } else {
        [self.base drawInRect:drawRect];
    }
}

- (CGRect)innerRectWithContentMode:(UIViewContentMode)mode rect:(CGRect)rect size:(CGSize)size
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

- (UIImage *)imageWithCropRect:(CGRect)rect
{
    rect.origin.x *= self.base.scale;
    rect.origin.y *= self.base.scale;
    rect.size.width *= self.base.scale;
    rect.size.height *= self.base.scale;
    if (rect.size.width <= 0 || rect.size.height <= 0) return nil;
    CGImageRef imageRef = CGImageCreateWithImageInRect(self.base.CGImage, rect);
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:self.base.scale orientation:self.base.imageOrientation];
    CGImageRelease(imageRef);
    return image;
}

- (UIImage *)imageWithInsets:(UIEdgeInsets)insets color:(UIColor *)color
{
    CGSize size = self.base.size;
    size.width -= insets.left + insets.right;
    size.height -= insets.top + insets.bottom;
    if (size.width <= 0 || size.height <= 0) return nil;
    CGRect rect = CGRectMake(-insets.left, -insets.top, self.base.size.width, self.base.size.height);
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
    [self.base drawInRect:rect];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)imageWithCapInsets:(UIEdgeInsets)insets
{
    return [self.base resizableImageWithCapInsets:insets];
}

- (UIImage *)imageWithCapInsets:(UIEdgeInsets)insets resizingMode:(UIImageResizingMode)resizingMode
{
    return [self.base resizableImageWithCapInsets:insets resizingMode:resizingMode];
}

- (UIImage *)imageWithCornerRadius:(CGFloat)radius
{
    UIGraphicsBeginImageContextWithOptions(self.base.size, NO, 0.0f);
    CGRect rect = CGRectMake(0, 0, self.base.size.width, self.base.size.height);
    [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius] addClip];
    
    [self.base drawInRect:rect];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)imageWithRotateDegree:(CGFloat)degree
{
    return [self imageWithRotateDegree:degree fitSize:YES];
}

- (UIImage *)imageWithRotateDegree:(CGFloat)degree fitSize:(BOOL)fitSize
{
    CGFloat radians = degree * M_PI / 180.0;
    size_t width = (size_t)CGImageGetWidth(self.base.CGImage);
    size_t height = (size_t)CGImageGetHeight(self.base.CGImage);
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
    
    CGContextDrawImage(context, CGRectMake(-(width * 0.5), -(height * 0.5), width, height), self.base.CGImage);
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    UIImage *img = [UIImage imageWithCGImage:imgRef scale:self.base.scale orientation:self.base.imageOrientation];
    CGImageRelease(imgRef);
    CGContextRelease(context);
    return img;
}

- (UIImage *)imageWithMaskImage:(UIImage *)maskImage
{
    UIGraphicsBeginImageContextWithOptions(self.base.size, NO, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClipToMask(context, CGRectMake(0.0f, 0.0f, self.base.size.width, self.base.size.height), maskImage.CGImage);
    
    [self.base drawAtPoint:CGPointZero];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)imageWithMergeImage:(UIImage *)mergeImage atPoint:(CGPoint)point
{
    UIGraphicsBeginImageContextWithOptions(self.base.size, NO, 0);
    [self.base drawInRect:CGRectMake(0, 0, self.base.size.width, self.base.size.height)];
    [mergeImage drawAtPoint:point];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)imageWithFilter:(CIFilter *)filter
{
    CIImage *inputImage;
    if (self.base.CIImage) {
        inputImage = self.base.CIImage;
    } else {
        CGImageRef imageRef = self.base.CGImage;
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
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:self.base.scale orientation:self.base.imageOrientation];
    CGImageRelease(imageRef);
    return image;
}

- (UIImage *)compressImageWithMaxLength:(NSInteger)maxLength
{
    NSData *data = [self compressDataWithMaxLength:maxLength compressRatio:0];
    return [[UIImage alloc] initWithData:data];
}

- (NSData *)compressDataWithMaxLength:(NSInteger)maxLength compressRatio:(CGFloat)compressRatio
{
    CGFloat compress = 1.f;
    CGFloat stepCompress = compressRatio > 0 ? compressRatio : 0.1f;
    NSData *data = self.hasAlpha
        ? UIImagePNGRepresentation(self.base)
        : UIImageJPEGRepresentation(self.base, compress);
    while (data.length > maxLength && compress > stepCompress) {
        compress -= stepCompress;
        data = UIImageJPEGRepresentation(self.base, compress);
    }
    return data;
}

- (UIImage *)compressImageWithMaxWidth:(NSInteger)maxWidth
{
    CGSize newSize = [self scaleSizeWithMaxWidth:maxWidth];
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    [self.base drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (CGSize)scaleSizeWithMaxWidth:(CGFloat)maxWidth
{
    if (maxWidth <= 0) {
        return self.base.size;
    }
    
    CGFloat width = self.base.size.width;
    CGFloat height = self.base.size.height;
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

- (UIImage *)originalImage
{
    return [self.base imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (UIImage *)templateImage
{
    return [self.base imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (BOOL)hasAlpha
{
    if (self.base.CGImage == NULL) return NO;
    CGImageAlphaInfo alpha = CGImageGetAlphaInfo(self.base.CGImage) & kCGBitmapAlphaInfoMask;
    return (alpha == kCGImageAlphaFirst ||
            alpha == kCGImageAlphaLast ||
            alpha == kCGImageAlphaPremultipliedFirst ||
            alpha == kCGImageAlphaPremultipliedLast);
}

- (CGSize)pixelSize
{
    return CGSizeMake(self.base.size.width * self.base.scale, self.base.size.height * self.base.scale);
}

@end

@implementation FWImageClassWrapper (FWToolkit)

- (UIImage *)imageWithView:(UIView *)view
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

- (UIImage *)imageWithColor:(UIColor *)color
{
    return [self imageWithColor:color size:CGSizeMake(1.0f, 1.0f)];
}

- (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size
{
    return [self imageWithColor:color size:size cornerRadius:0];
}

- (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size cornerRadius:(CGFloat)radius
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

- (UIImage *)imageWithSize:(CGSize)size block:(void (NS_NOESCAPE ^)(CGContextRef))block
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

@end

#pragma mark - FWViewWrapper+FWToolkit

@implementation FWViewWrapper (FWToolkit)

- (CGFloat)top
{
    return self.base.frame.origin.y;
}

- (void)setTop:(CGFloat)top
{
    CGRect frame = self.base.frame;
    frame.origin.y = top;
    self.base.frame = frame;
}

- (CGFloat)bottom
{
    return self.top + self.height;
}

- (void)setBottom:(CGFloat)bottom
{
    self.top = bottom - self.height;
}

- (CGFloat)left
{
    return self.base.frame.origin.x;
}

- (void)setLeft:(CGFloat)left
{
    CGRect frame = self.base.frame;
    frame.origin.x = left;
    self.base.frame = frame;
}

- (CGFloat)right
{
    return self.left + self.width;
}

- (void)setRight:(CGFloat)right
{
    self.left = right - self.width;
}

- (CGFloat)width
{
    return self.base.frame.size.width;
}

- (void)setWidth:(CGFloat)width
{
    CGRect frame = self.base.frame;
    frame.size.width = width;
    self.base.frame = frame;
}

- (CGFloat)height
{
    return self.base.frame.size.height;
}

- (void)setHeight:(CGFloat)height
{
    CGRect frame = self.base.frame;
    frame.size.height = height;
    self.base.frame = frame;
}

- (CGFloat)centerX
{
    return self.base.center.x;
}

- (void)setCenterX:(CGFloat)centerX
{
    self.base.center = CGPointMake(centerX, self.centerY);
}

- (CGFloat)centerY
{
    return self.base.center.y;
}

- (void)setCenterY:(CGFloat)centerY
{
    self.base.center = CGPointMake(self.centerX, centerY);
}

- (CGFloat)x
{
    return self.base.frame.origin.x;
}

- (void)setX:(CGFloat)x
{
    CGRect frame = self.base.frame;
    frame.origin.x = x;
    self.base.frame = frame;
}

- (CGFloat)y
{
    return self.base.frame.origin.y;
}

- (void)setY:(CGFloat)y
{
    CGRect frame = self.base.frame;
    frame.origin.y = y;
    self.base.frame = frame;
}

- (CGPoint)origin
{
    return self.base.frame.origin;
}

- (void)setOrigin:(CGPoint)origin
{
    CGRect frame = self.base.frame;
    frame.origin = origin;
    self.base.frame = frame;
}

- (CGSize)size
{
    return self.base.frame.size;
}

- (void)setSize:(CGSize)size
{
    CGRect frame = self.base.frame;
    frame.size = size;
    self.base.frame = frame;
}

@end

#pragma mark - FWViewControllerWrapper+FWToolkit

@implementation FWViewControllerWrapper (FWToolkit)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        FWSwizzleClass(UIViewController, @selector(viewDidLoad), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            FWSwizzleOriginal();
            selfObject.fw.visibleState = FWViewControllerVisibleStateDidLoad;
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewWillAppear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            selfObject.fw.visibleState = FWViewControllerVisibleStateWillAppear;
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewDidAppear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            selfObject.fw.visibleState = FWViewControllerVisibleStateDidAppear;
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewWillDisappear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            selfObject.fw.visibleState = FWViewControllerVisibleStateWillDisappear;
        }));
        
        FWSwizzleClass(UIViewController, @selector(viewDidDisappear:), FWSwizzleReturn(void), FWSwizzleArgs(BOOL animated), FWSwizzleCode({
            FWSwizzleOriginal(animated);
            selfObject.fw.visibleState = FWViewControllerVisibleStateDidDisappear;
        }));
        
        FWSwizzleClass(UIViewController, NSSelectorFromString(@"dealloc"), FWSwizzleReturn(void), FWSwizzleArgs(), FWSwizzleCode({
            // dealloc时不调用fw，防止释放时动态创建包装器对象
            void (^completionHandler)(id) = objc_getAssociatedObject(selfObject, @selector(completionHandler));
            if (completionHandler != nil) {
                id completionResult = objc_getAssociatedObject(selfObject, @selector(completionResult));
                completionHandler(completionResult);
            }
            
            FWSwizzleOriginal();
        }));
    });
}

- (FWViewControllerVisibleState)visibleState
{
    return [objc_getAssociatedObject(self.base, @selector(visibleState)) unsignedIntegerValue];
}

- (void)setVisibleState:(FWViewControllerVisibleState)visibleState
{
    BOOL valueChanged = self.visibleState != visibleState;
    objc_setAssociatedObject(self.base, @selector(visibleState), @(visibleState), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (valueChanged && self.visibleStateChanged) {
        self.visibleStateChanged(self.base, visibleState);
    }
}

- (void (^)(__kindof UIViewController *, FWViewControllerVisibleState))visibleStateChanged
{
    return objc_getAssociatedObject(self.base, @selector(visibleStateChanged));
}

- (void)setVisibleStateChanged:(void (^)(__kindof UIViewController *, FWViewControllerVisibleState))visibleStateChanged
{
    objc_setAssociatedObject(self.base, @selector(visibleStateChanged), visibleStateChanged, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (id)completionResult
{
    return objc_getAssociatedObject(self.base, @selector(completionResult));
}

- (void)setCompletionResult:(id)completionResult
{
    objc_setAssociatedObject(self.base, @selector(completionResult), completionResult, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void (^)(id _Nullable))completionHandler
{
    return objc_getAssociatedObject(self.base, @selector(completionHandler));
}

- (void)setCompletionHandler:(void (^)(id _Nullable))completionHandler
{
    objc_setAssociatedObject(self.base, @selector(completionHandler), completionHandler, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)popGestureEnabled
{
    BOOL (^block)(void) = self.popGestureBlock;
    if (block != nil) return block();
    NSNumber *value = objc_getAssociatedObject(self.base, @selector(popGestureEnabled));
    return value ? [value boolValue] : YES;
}

- (void)setPopGestureEnabled:(BOOL)popGestureEnabled
{
    objc_setAssociatedObject(self.base, @selector(popGestureEnabled), @(popGestureEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL (^)(void))popGestureBlock
{
    return objc_getAssociatedObject(self.base, @selector(popGestureBlock));
}

- (void)setPopGestureBlock:(BOOL (^)(void))popGestureBlock
{
    objc_setAssociatedObject(self.base, @selector(popGestureBlock), popGestureBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

#pragma mark - FWNavigationControllerWrapper+FWToolkit

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

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return self.navigationController.topViewController.fw.popGestureEnabled;
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

@implementation FWNavigationControllerWrapper (FWToolkit)

- (void)enablePopProxy
{
    self.base.interactivePopGestureRecognizer.delegate = self.innerPopProxyTarget;
}

- (FWInnerPopProxyTarget *)innerPopProxyTarget
{
    FWInnerPopProxyTarget *target = objc_getAssociatedObject(self.base, _cmd);
    if (!target) {
        target = [[FWInnerPopProxyTarget alloc] initWithNavigationController:self.base];
        objc_setAssociatedObject(self.base, _cmd, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return target;
}

@end
