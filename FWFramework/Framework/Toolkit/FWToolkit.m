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
#import "FWPlugin.h"
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

#pragma mark - UIImage+FWToolkit

UIImage * FWImageName(NSString *name) {
    return [UIImage fwImageWithName:name];
}

UIImage * FWImageFile(NSString *path) {
    return [UIImage fwImageWithFile:path];
}

@implementation UIImage (FWToolkit)

+ (UIImage *)fwImageWithName:(NSString *)name
{
    return [UIImage imageNamed:name];
}

+ (UIImage *)fwImageWithFile:(NSString *)path
{
    if (path.length < 1) return nil;
    
    NSString *file = path.isAbsolutePath ? path : [[NSBundle mainBundle] pathForResource:path ofType:nil];
    NSData *data = [NSData dataWithContentsOfFile:file];
    if (!data) {
        return [UIImage imageNamed:path];
    }
    
    return [self fwImageWithData:data scale:[UIScreen mainScreen].scale];
}

+ (UIImage *)fwImageWithData:(NSData *)data
{
    return [self fwImageWithData:data scale:1];
}

+ (UIImage *)fwImageWithData:(NSData *)data scale:(CGFloat)scale
{
    if (!data) return nil;
    
    id<FWImagePlugin> imagePlugin = [[FWPluginManager sharedInstance] loadPlugin:@protocol(FWImagePlugin)];
    if (imagePlugin && [imagePlugin respondsToSelector:@selector(fwImageDecode:scale:)]) {
        return [imagePlugin fwImageDecode:data scale:scale];
    }
    
    return [UIImage imageWithData:data scale:scale];
}

+ (id)fwDownloadImage:(id)url
           completion:(void (^)(UIImage * _Nullable, NSError * _Nullable))completion
             progress:(void (^)(double))progress
{
    id<FWImagePlugin> imagePlugin = [[FWPluginManager sharedInstance] loadPlugin:@protocol(FWImagePlugin)];
    if (imagePlugin && [imagePlugin respondsToSelector:@selector(fwDownloadImage:completion:progress:)]) {
        NSURL *imageURL = nil;
        if ([url isKindOfClass:[NSString class]]) {
            imageURL = [NSURL URLWithString:url];
            if (!imageURL && [url length] > 0) {
                imageURL = [NSURL URLWithString:[url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
            }
        } else if ([url isKindOfClass:[NSURL class]]) {
            imageURL = url;
        } else if ([url isKindOfClass:[NSURLRequest class]]) {
            imageURL = [url URL];
        }
        
        return [imagePlugin fwDownloadImage:imageURL completion:completion progress:progress];
    }
    return nil;
}

+ (void)fwCancelImageDownload:(id)receipt
{
    id<FWImagePlugin> imagePlugin = [[FWPluginManager sharedInstance] loadPlugin:@protocol(FWImagePlugin)];
    if (imagePlugin && [imagePlugin respondsToSelector:@selector(fwCancelImageDownload:)]) {
        [imagePlugin fwCancelImageDownload:receipt];
    }
}

@end

#pragma mark - UIImageView+FWToolkit

@implementation UIImageView (FWToolkit)

+ (Class)fwImageViewAnimatedClass
{
    id<FWImagePlugin> imagePlugin = [[FWPluginManager sharedInstance] loadPlugin:@protocol(FWImagePlugin)];
    if (imagePlugin && [imagePlugin respondsToSelector:@selector(fwImageViewAnimatedClass)]) {
        return [imagePlugin fwImageViewAnimatedClass];
    }
    
    return objc_getAssociatedObject([UIImageView class], @selector(fwImageViewAnimatedClass)) ?: [UIImageView class];
}

+ (void)setFwImageViewAnimatedClass:(Class)animatedClass
{
    objc_setAssociatedObject([UIImageView class], @selector(fwImageViewAnimatedClass), animatedClass, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)fwSetImageWithURL:(id)url
{
    [self fwSetImageWithURL:url placeholderImage:nil];
}

- (void)fwSetImageWithURL:(id)url
         placeholderImage:(UIImage *)placeholderImage
{
    [self fwSetImageWithURL:url placeholderImage:placeholderImage completion:nil];
}

- (void)fwSetImageWithURL:(id)url
         placeholderImage:(UIImage *)placeholderImage
               completion:(void (^)(UIImage * _Nullable, NSError * _Nullable))completion
{
    [self fwSetImageWithURL:url placeholderImage:placeholderImage completion:completion progress:nil];
}

- (void)fwSetImageWithURL:(id)url
         placeholderImage:(UIImage *)placeholderImage
               completion:(void (^)(UIImage * _Nullable, NSError * _Nullable))completion
                 progress:(void (^)(double))progress
{
    id<FWImagePlugin> imagePlugin = [[FWPluginManager sharedInstance] loadPlugin:@protocol(FWImagePlugin)];
    if (imagePlugin && [imagePlugin respondsToSelector:@selector(fwImageView:setImageURL:placeholder:completion:progress:)]) {
        NSURL *imageURL = nil;
        if ([url isKindOfClass:[NSString class]]) {
            imageURL = [NSURL URLWithString:url];
            if (!imageURL && [url length] > 0) {
                imageURL = [NSURL URLWithString:[url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
            }
        } else if ([url isKindOfClass:[NSURL class]]) {
            imageURL = url;
        } else if ([url isKindOfClass:[NSURLRequest class]]) {
            imageURL = [url URL];
        }
        
        [imagePlugin fwImageView:self setImageURL:imageURL placeholder:placeholderImage completion:completion progress:progress];
    }
}

- (void)fwCancelImageRequest
{
    id<FWImagePlugin> imagePlugin = [[FWPluginManager sharedInstance] loadPlugin:@protocol(FWImagePlugin)];
    if (imagePlugin && [imagePlugin respondsToSelector:@selector(fwCancelImageRequest:)]) {
        [imagePlugin fwCancelImageRequest:self];
    }
}

@end

#pragma mark - FWSDWebImagePlugin

#if FWCOMPONENT_SDWEBIMAGE_ENABLED
@import SDWebImage;
#endif

@implementation FWSDWebImagePlugin

+ (FWSDWebImagePlugin *)sharedInstance
{
    static FWSDWebImagePlugin *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWSDWebImagePlugin alloc] init];
    });
    return instance;
}

#if FWCOMPONENT_SDWEBIMAGE_ENABLED

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[FWPluginManager sharedInstance] registerPlugin:@protocol(FWImagePlugin) withObject:[FWSDWebImagePlugin class]];
    });
}

- (Class)fwImageViewAnimatedClass
{
    return [SDAnimatedImageView class];
}

- (UIImage *)fwImageDecode:(NSData *)data scale:(CGFloat)scale
{
    return [UIImage sd_imageWithData:data scale:scale];
}

- (void)fwImageView:(UIImageView *)imageView
        setImageURL:(NSURL *)imageURL
        placeholder:(UIImage *)placeholder
         completion:(void (^)(UIImage * _Nullable, NSError * _Nullable))completion
           progress:(void (^)(double))progress
{
    [imageView sd_setImageWithURL:imageURL
                 placeholderImage:placeholder
                          options:SDWebImageRetryFailed
                          context:nil
                         progress:progress ? ^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                            if (expectedSize > 0) {
                                if ([NSThread isMainThread]) {
                                    progress(receivedSize / (double)expectedSize);
                                } else {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        progress(receivedSize / (double)expectedSize);
                                    });
                                }
                            }
                        } : nil
                        completed:completion ? ^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                            completion(image, error);
                        } : nil];
}

- (void)fwCancelImageRequest:(UIImageView *)imageView
{
    [imageView sd_cancelCurrentImageLoad];
}

- (id)fwDownloadImage:(NSURL *)imageURL
           completion:(void (^)(UIImage * _Nullable, NSError * _Nullable))completion
             progress:(void (^)(double))progress
{
    return [[SDWebImageManager sharedManager]
            loadImageWithURL:imageURL
            options:SDWebImageRetryFailed
            progress:(progress ? ^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                if (expectedSize > 0) {
                    if ([NSThread isMainThread]) {
                        progress(receivedSize / (double)expectedSize);
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            progress(receivedSize / (double)expectedSize);
                        });
                    }
                }
            } : nil)
            completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                if (completion) {
                    completion(image, error);
                }
            }];
}

- (void)fwCancelImageDownload:(id)receipt
{
    if (receipt && [receipt isKindOfClass:[SDWebImageCombinedOperation class]]) {
        [(SDWebImageCombinedOperation *)receipt cancel];
    }
}

#endif

@end
