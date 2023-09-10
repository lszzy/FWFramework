//
//  FWImagePlugin.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWImagePlugin.h"
#import "FWPlugin.h"
#import "FWToolkit.h"
#import <objc/runtime.h>

FWImageCoderOptions const FWImageCoderOptionScaleFactor = @"imageScaleFactor";

#pragma mark - UIImage+FWImagePlugin

UIImage * FWImageNamed(NSString *name) {
    return [UIImage fw_imageNamed:name];
}

static NSArray *FWInnerBundlePreferredScales(void) {
    static NSArray *scales;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGFloat screenScale = [UIScreen mainScreen].scale;
        if (screenScale <= 1) {
            scales = @[@1, @2, @3];
        } else if (screenScale <= 2) {
            scales = @[@2, @3, @1];
        } else {
            scales = @[@3, @2, @1];
        }
    });
    return scales;
}

static NSString *FWInnerAppendingNameScale(NSString *string, CGFloat scale) {
    if (!string) return nil;
    if (fabs(scale - 1) <= __FLT_EPSILON__ || string.length == 0 || [string hasSuffix:@"/"]) return string.copy;
    return [string stringByAppendingFormat:@"@%@x", @(scale)];
}

static CGFloat FWInnerStringPathScale(NSString *string) {
    if (string.length == 0 || [string hasSuffix:@"/"]) return 1;
    NSString *name = string.stringByDeletingPathExtension;
    __block CGFloat scale = 1;
    
    NSRegularExpression *pattern = [NSRegularExpression regularExpressionWithPattern:@"@[0-9]+\\.?[0-9]*x$" options:NSRegularExpressionAnchorsMatchLines error:nil];
    [pattern enumerateMatchesInString:name options:kNilOptions range:NSMakeRange(0, name.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        if (result.range.location >= 3) {
            scale = [string substringWithRange:NSMakeRange(result.range.location + 1, result.range.length - 2)].doubleValue;
        }
    }];
    return scale;
}

@implementation UIImage (FWImagePlugin)

+ (UIImage *)fw_imageNamed:(NSString *)name
{
    return [self fw_imageNamed:name bundle:nil];
}

+ (UIImage *)fw_imageNamed:(NSString *)name bundle:(NSBundle *)bundle
{
    return [self fw_imageNamed:name bundle:bundle options:nil];
}

+ (UIImage *)fw_imageNamed:(NSString *)name bundle:(NSBundle *)aBundle options:(NSDictionary<FWImageCoderOptions,id> *)options
{
    if (name.length < 1) return nil;
    if ([name hasSuffix:@"/"]) return nil;
    
    if ([name isAbsolutePath]) {
        NSData *data = [NSData dataWithContentsOfFile:name];
        CGFloat scale = FWInnerStringPathScale(name);
        return [self fw_imageWithData:data scale:scale options:options];
    }
    
    NSString *path = nil;
    CGFloat scale = 1;
    NSBundle *bundle = aBundle ?: [NSBundle mainBundle];
    NSString *res = name.stringByDeletingPathExtension;
    NSString *ext = name.pathExtension;
    NSArray *exts = ext.length > 0 ? @[ext] : @[@"", @"png", @"jpeg", @"jpg", @"gif", @"webp", @"apng", @"svg"];
    NSArray *scales = FWInnerBundlePreferredScales();
    for (int s = 0; s < scales.count; s++) {
        scale = ((NSNumber *)scales[s]).floatValue;
        NSString *scaledName = FWInnerAppendingNameScale(res, scale);
        for (NSString *e in exts) {
            path = [bundle pathForResource:scaledName ofType:e];
            if (path) break;
        }
        if (path) break;
    }
    
    NSData *data = path.length > 0 ? [NSData dataWithContentsOfFile:path] : nil;
    if (data.length < 1) {
        return [UIImage imageNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
    }
    return [self fw_imageWithData:data scale:scale options:options];
}

+ (UIImage *)fw_imageWithContentsOfFile:(NSString *)path
{
    NSData *data = [NSData dataWithContentsOfFile:path];
    CGFloat scale = FWInnerStringPathScale(path);
    return [self fw_imageWithData:data scale:scale];
}

+ (UIImage *)fw_imageWithData:(NSData *)data
{
    return [self fw_imageWithData:data scale:1];
}

+ (UIImage *)fw_imageWithData:(NSData *)data scale:(CGFloat)scale
{
    return [self fw_imageWithData:data scale:scale options:nil];
}

+ (UIImage *)fw_imageWithData:(NSData *)data scale:(CGFloat)scale options:(NSDictionary<FWImageCoderOptions,id> *)options
{
    if (data.length < 1) return nil;
    
    id<FWImagePlugin> imagePlugin = [FWPluginManager loadPlugin:@protocol(FWImagePlugin)];
    if (imagePlugin && [imagePlugin respondsToSelector:@selector(imageDecode:scale:options:)]) {
        return [imagePlugin imageDecode:data scale:scale options:options];
    }
    
    NSNumber *scaleFactor = options[FWImageCoderOptionScaleFactor];
    if (scaleFactor != nil) scale = [scaleFactor doubleValue];
    return [UIImage imageWithData:data scale:MAX(scale, 1)];
}

+ (NSData *)fw_dataWithImage:(UIImage *)image
{
    return [self fw_dataWithImage:image options:nil];
}

+ (NSData *)fw_dataWithImage:(UIImage *)image options:(NSDictionary<FWImageCoderOptions,id> *)options
{
    if (!image) return nil;
    
    id<FWImagePlugin> imagePlugin = [FWPluginManager loadPlugin:@protocol(FWImagePlugin)];
    if (imagePlugin && [imagePlugin respondsToSelector:@selector(imageEncode:options:)]) {
        return [imagePlugin imageEncode:image options:options];
    }
    
    if (image.fw_hasAlpha) {
        return UIImagePNGRepresentation(image);
    } else {
        return UIImageJPEGRepresentation(image, 1);
    }
}

+ (id)fw_downloadImage:(id)url
           completion:(void (^)(UIImage * _Nullable, NSData * _Nullable, NSError * _Nullable))completion
             progress:(void (^)(double))progress
{
    return [self fw_downloadImage:url options:0 context:nil completion:completion progress:progress];
}

+ (id)fw_downloadImage:(id)url
              options:(FWWebImageOptions)options
              context:(NSDictionary<FWImageCoderOptions,id> *)context
           completion:(void (^)(UIImage * _Nullable, NSData * _Nullable, NSError * _Nullable))completion
             progress:(void (^)(double))progress
{
    id<FWImagePlugin> imagePlugin = [FWPluginManager loadPlugin:@protocol(FWImagePlugin)];
    if (imagePlugin && [imagePlugin respondsToSelector:@selector(downloadImage:options:context:completion:progress:)]) {
        NSURL *imageURL = [UIImage fw_imageURLwithURL:url];
        return [imagePlugin downloadImage:imageURL options:options context:context completion:completion progress:progress];
    }
    return nil;
}

+ (void)fw_cancelImageDownload:(id)receipt
{
    id<FWImagePlugin> imagePlugin = [FWPluginManager loadPlugin:@protocol(FWImagePlugin)];
    if (imagePlugin && [imagePlugin respondsToSelector:@selector(cancelImageDownload:)]) {
        [imagePlugin cancelImageDownload:receipt];
    }
}

+ (nullable NSURL *)fw_imageURLwithURL:(id)url
{
    NSURL *imageURL = nil;
    if ([url isKindOfClass:[NSString class]] && [url length] > 0) {
        imageURL = [NSURL URLWithString:url];
        if (!imageURL) {
            imageURL = [NSURL URLWithString:[url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
        }
    } else if ([url isKindOfClass:[NSURL class]]) {
        imageURL = url;
    } else if ([url isKindOfClass:[NSURLRequest class]]) {
        imageURL = [url URL];
    }
    return imageURL;
}

@end

#pragma mark - UIImageView+FWImagePlugin

@implementation UIImageView (FWImagePlugin)

- (id<FWImagePlugin>)fw_imagePlugin
{
    id<FWImagePlugin> imagePlugin = objc_getAssociatedObject(self, @selector(fw_imagePlugin));
    if (!imagePlugin) imagePlugin = [FWPluginManager loadPlugin:@protocol(FWImagePlugin)];
    return imagePlugin;
}

- (void)setFw_imagePlugin:(id<FWImagePlugin>)imagePlugin
{
    objc_setAssociatedObject(self, @selector(fw_imagePlugin), imagePlugin, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSURL *)fw_imageURL
{
    id<FWImagePlugin> imagePlugin = self.fw_imagePlugin;
    if (imagePlugin && [imagePlugin respondsToSelector:@selector(imageURL:)]) {
        return [imagePlugin imageURL:self];
    }
    return nil;
}

- (void)fw_setImageWithURL:(id)url
{
    [self fw_setImageWithURL:url placeholderImage:nil];
}

- (void)fw_setImageWithURL:(id)url
         placeholderImage:(UIImage *)placeholderImage
{
    [self fw_setImageWithURL:url placeholderImage:placeholderImage completion:nil];
}

- (void)fw_setImageWithURL:(id)url
         placeholderImage:(UIImage *)placeholderImage
               completion:(void (^)(UIImage * _Nullable, NSError * _Nullable))completion
{
    [self fw_setImageWithURL:url placeholderImage:placeholderImage options:0 context:nil completion:completion progress:nil];
}

- (void)fw_setImageWithURL:(id)url
         placeholderImage:(UIImage *)placeholderImage
                  options:(FWWebImageOptions)options
                  context:(NSDictionary<FWImageCoderOptions,id> *)context
               completion:(void (^)(UIImage * _Nullable, NSError * _Nullable))completion
                 progress:(void (^)(double))progress
{
    id<FWImagePlugin> imagePlugin = self.fw_imagePlugin;
    if (imagePlugin && [imagePlugin respondsToSelector:@selector(imageView:setImageURL:placeholder:options:context:completion:progress:)]) {
        NSURL *imageURL = [UIImage fw_imageURLwithURL:url];
        [imagePlugin imageView:self setImageURL:imageURL placeholder:placeholderImage options:options context:context completion:completion progress:progress];
    }
}

- (void)fw_cancelImageRequest
{
    id<FWImagePlugin> imagePlugin = self.fw_imagePlugin;
    if (imagePlugin && [imagePlugin respondsToSelector:@selector(cancelImageRequest:)]) {
        [imagePlugin cancelImageRequest:self];
    }
}

- (UIImage *)fw_loadImageCacheWithURL:(id)url
{
    id<FWImagePlugin> imagePlugin = self.fw_imagePlugin;
    if (imagePlugin && [imagePlugin respondsToSelector:@selector(loadImageCache:)]) {
        NSURL *imageURL = [UIImage fw_imageURLwithURL:url];
        return [imagePlugin loadImageCache:imageURL];
    }
    
    return nil;
}

+ (void)fw_clearImageCaches:(void (^)(void))completion
{
    id<FWImagePlugin> imagePlugin = [FWPluginManager loadPlugin:@protocol(FWImagePlugin)];
    if (imagePlugin && [imagePlugin respondsToSelector:@selector(clearImageCaches:)]) {
        [imagePlugin clearImageCaches:completion];
    }
}

+ (UIImageView *)fw_animatedImageView
{
    id<FWImagePlugin> imagePlugin = [FWPluginManager loadPlugin:@protocol(FWImagePlugin)];
    if (imagePlugin && [imagePlugin respondsToSelector:@selector(animatedImageView)]) {
        return [imagePlugin animatedImageView];
    }
    
    return [[UIImageView alloc] init];
}

@end
