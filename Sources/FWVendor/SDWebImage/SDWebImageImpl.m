//
//  SDWebImageImpl.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "SDWebImageImpl.h"
@import SDWebImage;
#if FWMacroSPM
@import FWObjC;
#else
#import "FWImagePlugin.h"
#import "FWPlugin.h"
#endif

@interface FWSDWebImageImpl () <FWImagePlugin>

@end

@implementation FWSDWebImageImpl

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [FWPluginManager registerPlugin:@protocol(FWImagePlugin) withObject:[FWSDWebImageImpl class]];
    });
}

+ (FWSDWebImageImpl *)sharedInstance
{
    static FWSDWebImageImpl *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWSDWebImageImpl alloc] init];
    });
    return instance;
}

- (UIImageView *)animatedImageView
{
    return [[SDAnimatedImageView alloc] init];
}

- (UIImage *)imageDecode:(NSData *)data scale:(CGFloat)scale options:(NSDictionary<FWImageCoderOptions,id> *)options
{
    NSNumber *scaleFactor = options[FWImageCoderOptionScaleFactor];
    if (scaleFactor != nil) scale = [scaleFactor doubleValue];
    SDImageCoderMutableOptions *coderOptions = [[NSMutableDictionary alloc] init];
    coderOptions[SDImageCoderDecodeScaleFactor] = @(MAX(scale, 1));
    coderOptions[SDImageCoderDecodeFirstFrameOnly] = @(NO);
    if (options) [coderOptions addEntriesFromDictionary:options];
    return [[SDImageCodersManager sharedManager] decodedImageWithData:data options:[coderOptions copy]];
}

- (NSData *)imageEncode:(UIImage *)image options:(NSDictionary<FWImageCoderOptions,id> *)options
{
    SDImageCoderMutableOptions *coderOptions = [[NSMutableDictionary alloc] init];
    coderOptions[SDImageCoderEncodeCompressionQuality] = @(1);
    coderOptions[SDImageCoderEncodeFirstFrameOnly] = @(NO);
    if (options) [coderOptions addEntriesFromDictionary:options];
    
    SDImageFormat imageFormat = image.sd_imageFormat;
    NSData *imageData = [[SDImageCodersManager sharedManager] encodedDataWithImage:image format:imageFormat options:[coderOptions copy]];
    if (imageData || imageFormat == SDImageFormatUndefined) return imageData;
    return [[SDImageCodersManager sharedManager] encodedDataWithImage:image format:SDImageFormatUndefined options:[coderOptions copy]];
}

- (NSURL *)imageURL:(UIImageView *)imageView
{
    return imageView.sd_imageURL;
}

- (void)imageView:(UIImageView *)imageView
        setImageURL:(NSURL *)imageURL
        placeholder:(UIImage *)placeholder
            options:(FWWebImageOptions)options
            context:(NSDictionary<FWImageCoderOptions,id> *)context
         completion:(void (^)(UIImage * _Nullable, NSError * _Nullable))completion
           progress:(void (^)(double))progress
{
    if (self.fadeAnimated && !imageView.sd_imageTransition) {
        imageView.sd_imageTransition = SDWebImageTransition.fadeTransition;
    }
    if (self.customBlock) {
        self.customBlock(imageView);
    }
    
    [imageView sd_setImageWithURL:imageURL
                 placeholderImage:placeholder
                          options:options | SDWebImageRetryFailed
                          context:context
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

- (void)cancelImageRequest:(UIImageView *)imageView
{
    [imageView sd_cancelCurrentImageLoad];
}

- (UIImage *)loadImageCache:(NSURL *)imageURL
{
    NSString *cacheKey = [SDWebImageManager.sharedManager cacheKeyForURL:imageURL];
    if (cacheKey.length < 1) return nil;
    UIImage *cachedImage = [SDImageCache.sharedImageCache imageFromCacheForKey:cacheKey];
    return cachedImage;
}

- (void)clearImageCaches:(void (^)(void))completion
{
    [SDImageCache.sharedImageCache clearMemory];
    [SDImageCache.sharedImageCache clearDiskOnCompletion:completion];
}

- (id)downloadImage:(NSURL *)imageURL
              options:(FWWebImageOptions)options
              context:(NSDictionary<FWImageCoderOptions,id> *)context
           completion:(void (^)(UIImage * _Nullable, NSData * _Nullable, NSError * _Nullable))completion
             progress:(void (^)(double))progress
{
    return [[SDWebImageManager sharedManager]
            loadImageWithURL:imageURL
            options:options | SDWebImageRetryFailed
            context:context
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
                    completion(image, data, error);
                }
            }];
}

- (void)cancelImageDownload:(id)receipt
{
    if (receipt && [receipt isKindOfClass:[SDWebImageCombinedOperation class]]) {
        [(SDWebImageCombinedOperation *)receipt cancel];
    }
}

@end
