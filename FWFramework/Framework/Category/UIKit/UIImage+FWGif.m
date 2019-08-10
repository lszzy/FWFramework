//
//  UIImage+FWGif.m
//  FWFramework
//
//  Created by wuyong on 17/3/13.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "UIImage+FWGif.h"
#import <objc/runtime.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>

@implementation UIImage (FWGif)

#pragma mark - Judge

+ (BOOL)fwIsGifData:(NSData *)data
{
    if (data.length > 4) {
        const unsigned char * bytes = [data bytes];
        return bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46;
    }
    return NO;
}

- (BOOL)fwIsGifImage
{
    return (self.images != nil);
}

#pragma mark - Coder

- (NSUInteger)fwImageLoopCount
{
    return [objc_getAssociatedObject(self, @selector(fwImageLoopCount)) unsignedIntegerValue];
}

- (void)setFwImageLoopCount:(NSUInteger)fwImageLoopCount
{
    objc_setAssociatedObject(self, @selector(fwImageLoopCount), @(fwImageLoopCount), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (UIImage *)fwGifImageWithData:(NSData *)data
{
    if (!data) {
        return nil;
    }
    
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    size_t count = CGImageSourceGetCount(source);
    UIImage *animatedImage;
    if (count <= 1) {
        animatedImage = [[UIImage alloc] initWithData:data];
    } else {
        NSMutableArray *images = [NSMutableArray array];
        NSTimeInterval duration = 0.0f;
        for (size_t i = 0; i < count; i++) {
            CGImageRef image = CGImageSourceCreateImageAtIndex(source, i, NULL);
            if (!image) {
                continue;
            }
            
            duration += [self fwFrameDurationAtIndex:i source:source];
            CGFloat scale = 1;
            scale = [UIScreen mainScreen].scale;
            [images addObject:[UIImage imageWithCGImage:image scale:scale orientation:UIImageOrientationUp]];
            CGImageRelease(image);
        }
        
        if (!duration) {
            duration = (1.0f / 10.0f) * count;
        }
        
        animatedImage = [UIImage animatedImageWithImages:images duration:duration];
        
        NSUInteger loopCount = 0;
        NSDictionary *imageProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyProperties(source, nil);
        NSDictionary *gifProperties = [imageProperties objectForKey:(__bridge_transfer NSString *)kCGImagePropertyGIFDictionary];
        if (gifProperties) {
            NSNumber *gifLoopCount = [gifProperties objectForKey:(__bridge_transfer NSString *)kCGImagePropertyGIFLoopCount];
            if (gifLoopCount) {
                loopCount = gifLoopCount.unsignedIntegerValue;
            }
        }
        animatedImage.fwImageLoopCount = loopCount;
    }
    CFRelease(source);
    
    return animatedImage;
}

+ (float)fwFrameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source
{
    float frameDuration = 0.1f;
    CFDictionaryRef cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil);
    if (!cfFrameProperties) {
        return frameDuration;
    }
    NSDictionary *frameProperties = (__bridge NSDictionary *)cfFrameProperties;
    NSDictionary *gifProperties = frameProperties[(NSString *)kCGImagePropertyGIFDictionary];
    
    NSNumber *delayTimeUnclampedProp = gifProperties[(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (delayTimeUnclampedProp) {
        frameDuration = [delayTimeUnclampedProp floatValue];
    } else {
        NSNumber *delayTimeProp = gifProperties[(NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTimeProp) {
            frameDuration = [delayTimeProp floatValue];
        }
    }
    
    if (frameDuration < 0.011f) {
        frameDuration = 0.100f;
    }
    
    CFRelease(cfFrameProperties);
    return frameDuration;
}

+ (NSData *)fwGifDataWithImage:(UIImage *)image
{
    if (!image) {
        return nil;
    }
    
    NSMutableData *imageData = [NSMutableData data];
    NSUInteger frameCount = 0; // assume static images by default
    CFStringRef imageUTType = kUTTypeGIF;
    frameCount = image.images.count;
    
    // Create an image destination. GIF does not support EXIF image orientation
    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, imageUTType, frameCount, NULL);
    if (!imageDestination) {
        // Handle failure.
        return nil;
    }
    
    if (frameCount == 0) {
        // for static single GIF images
        CGImageDestinationAddImage(imageDestination, image.CGImage, nil);
    } else {
        // for animated GIF images
        NSUInteger loopCount = image.fwImageLoopCount;
        NSDictionary *gifProperties = @{(__bridge_transfer NSString *)kCGImagePropertyGIFDictionary: @{(__bridge_transfer NSString *)kCGImagePropertyGIFLoopCount : @(loopCount)}};
        CGImageDestinationSetProperties(imageDestination, (__bridge CFDictionaryRef)gifProperties);
        for (size_t i = 0; i < frameCount; i++) {
            @autoreleasepool {
                float frameDuration = image.duration / frameCount;
                CGImageRef frameImageRef = image.images[i].CGImage;
                NSDictionary *frameProperties = @{(__bridge_transfer NSString *)kCGImagePropertyGIFDictionary : @{(__bridge_transfer NSString *)kCGImagePropertyGIFUnclampedDelayTime : @(frameDuration)}};
                CGImageDestinationAddImage(imageDestination, frameImageRef, (__bridge CFDictionaryRef)frameProperties);
            }
        }
    }
    // Finalize the destination.
    if (CGImageDestinationFinalize(imageDestination) == NO) {
        // Handle failure.
        imageData = nil;
    }
    CFRelease(imageDestination);
    
    return [imageData copy];
}

#pragma mark - File

+ (UIImage *)fwGifImageWithFile:(NSString *)path
{
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (data) {
        return [UIImage fwGifImageWithData:data];
    }
    return nil;
}

+ (UIImage *)fwGifImageWithName:(NSString *)name
{
    UIImage *gifImage = nil;
    NSString *path = nil;
    CGFloat scale = [UIScreen mainScreen].scale;
    if (scale > 2.0f) {
        path = [[NSBundle mainBundle] pathForResource:[name stringByAppendingString:@"@3x"] ofType:@"gif"];
        gifImage = [UIImage fwGifImageWithFile:path];
        if (gifImage) {
            return gifImage;
        }
    }
    if (scale > 1.0f) {
        path = [[NSBundle mainBundle] pathForResource:[name stringByAppendingString:@"@2x"] ofType:@"gif"];
        gifImage = [UIImage fwGifImageWithFile:path];
        if (gifImage) {
            return gifImage;
        }
    }
    
    path = [[NSBundle mainBundle] pathForResource:name ofType:@"gif"];
    gifImage = [UIImage fwGifImageWithFile:path];
    if (gifImage) {
        return gifImage;
    }
    
    return [UIImage imageNamed:name];
}

#pragma mark - Scale

- (UIImage *)fwGifImageWithScaleSize:(CGSize)size
{
    if (CGSizeEqualToSize(self.size, size) || CGSizeEqualToSize(size, CGSizeZero)) {
        return self;
    }
    
    CGSize scaledSize = size;
    CGPoint thumbnailPoint = CGPointZero;
    
    CGFloat widthFactor = size.width / self.size.width;
    CGFloat heightFactor = size.height / self.size.height;
    CGFloat scaleFactor = (widthFactor > heightFactor) ? widthFactor : heightFactor;
    scaledSize.width = self.size.width * scaleFactor;
    scaledSize.height = self.size.height * scaleFactor;
    
    if (widthFactor > heightFactor) {
        thumbnailPoint.y = (size.height - scaledSize.height) * 0.5;
    }
    else if (widthFactor < heightFactor) {
        thumbnailPoint.x = (size.width - scaledSize.width) * 0.5;
    }
    
    NSMutableArray *scaledImages = [NSMutableArray array];
    
    for (UIImage *image in self.images) {
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
        
        [image drawInRect:CGRectMake(thumbnailPoint.x, thumbnailPoint.y, scaledSize.width, scaledSize.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        
        [scaledImages addObject:newImage];
        
        UIGraphicsEndImageContext();
    }
    
    return [UIImage animatedImageWithImages:scaledImages duration:self.duration];
}

#pragma mark - Save

+ (void)fwSaveGifData:(NSData *)data completion:(void (^)(NSError *))completion
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    NSDictionary *metadata = @{@"UTI":(__bridge NSString *)kUTTypeImage};
    [library writeImageDataToSavedPhotosAlbum:data metadata:metadata completionBlock:^(NSURL *assetURL, NSError *error) {
        if (completion) {
            completion(error);
        }
    }];
}

@end
