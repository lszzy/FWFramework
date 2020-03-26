/*!
 @header     FWImageCoder.m
 @indexgroup FWFramework
 @brief      FWImageCoder
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/2/26
 */

#import "FWImageCoder.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <objc/runtime.h>
#import <Accelerate/Accelerate.h>

#ifndef SD_LOCK
#define SD_LOCK(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#endif

#ifndef SD_UNLOCK
#define SD_UNLOCK(lock) dispatch_semaphore_signal(lock);
#endif

FWImageCoderOption const FWImageCoderDecodeFirstFrameOnly = @"decodeFirstFrameOnly";
FWImageCoderOption const FWImageCoderDecodeScaleFactor = @"decodeScaleFactor";

FWImageCoderOption const FWImageCoderEncodeFirstFrameOnly = @"encodeFirstFrameOnly";
FWImageCoderOption const FWImageCoderEncodeCompressionQuality = @"encodeCompressionQuality";

@interface FWImageCodersManager ()

@property (nonatomic, strong, nonnull) dispatch_semaphore_t codersLock;

@end

@implementation FWImageCodersManager
{
    NSMutableArray<id<FWImageCoder>> *_imageCoders;
}

+ (nonnull instancetype)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        // initialize with default coders
        _imageCoders = [NSMutableArray arrayWithArray:@[[FWImageIOCoder sharedCoder], [FWImageGIFCoder sharedCoder], [FWImageAPNGCoder sharedCoder]]];
        _codersLock = dispatch_semaphore_create(1);
    }
    return self;
}

- (NSArray<id<FWImageCoder>> *)coders
{
    SD_LOCK(self.codersLock);
    NSArray<id<FWImageCoder>> *coders = [_imageCoders copy];
    SD_UNLOCK(self.codersLock);
    return coders;
}

- (void)setCoders:(NSArray<id<FWImageCoder>> *)coders
{
    SD_LOCK(self.codersLock);
    [_imageCoders removeAllObjects];
    if (coders.count) {
        [_imageCoders addObjectsFromArray:coders];
    }
    SD_UNLOCK(self.codersLock);
}

#pragma mark - Coder IO operations

- (void)addCoder:(nonnull id<FWImageCoder>)coder {
    if (![coder conformsToProtocol:@protocol(FWImageCoder)]) {
        return;
    }
    SD_LOCK(self.codersLock);
    [_imageCoders addObject:coder];
    SD_UNLOCK(self.codersLock);
}

- (void)removeCoder:(nonnull id<FWImageCoder>)coder {
    if (![coder conformsToProtocol:@protocol(FWImageCoder)]) {
        return;
    }
    SD_LOCK(self.codersLock);
    [_imageCoders removeObject:coder];
    SD_UNLOCK(self.codersLock);
}

#pragma mark - FWImageCoder
- (BOOL)canDecodeFromData:(NSData *)data {
    NSArray<id<FWImageCoder>> *coders = self.coders;
    for (id<FWImageCoder> coder in coders.reverseObjectEnumerator) {
        if ([coder canDecodeFromData:data]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)canEncodeToFormat:(FWImageFormat)format {
    NSArray<id<FWImageCoder>> *coders = self.coders;
    for (id<FWImageCoder> coder in coders.reverseObjectEnumerator) {
        if ([coder canEncodeToFormat:format]) {
            return YES;
        }
    }
    return NO;
}

- (UIImage *)decodedImageWithData:(NSData *)data options:(nullable FWImageCoderOptions *)options {
    if (!data) {
        return nil;
    }
    UIImage *image;
    NSArray<id<FWImageCoder>> *coders = self.coders;
    for (id<FWImageCoder> coder in coders.reverseObjectEnumerator) {
        if ([coder canDecodeFromData:data]) {
            image = [coder decodedImageWithData:data options:options];
            break;
        }
    }
    
    return image;
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(FWImageFormat)format options:(nullable FWImageCoderOptions *)options {
    if (!image) {
        return nil;
    }
    NSArray<id<FWImageCoder>> *coders = self.coders;
    for (id<FWImageCoder> coder in coders.reverseObjectEnumerator) {
        if ([coder canEncodeToFormat:format]) {
            return [coder encodedDataWithImage:image format:format options:options];
        }
    }
    return nil;
}

@end

#pragma mark - Coder

// Currently Image/IO does not support WebP
#define kSDUTTypeWebP ((__bridge CFStringRef)@"public.webp")
// AVFileTypeHEIC/AVFileTypeHEIF is defined in AVFoundation via iOS 11, we use this without import AVFoundation
#define kSDUTTypeHEIC ((__bridge CFStringRef)@"public.heic")
#define kSDUTTypeHEIF ((__bridge CFStringRef)@"public.heif")
// HEIC Sequence (Animated Image)
#define kSDUTTypeHEICS ((__bridge CFStringRef)@"public.heics")

@interface FWImageIOAnimatedCoder ()

+ (NSTimeInterval)frameDurationAtIndex:(NSUInteger)index source:(nonnull CGImageSourceRef)source;
+ (NSUInteger)imageLoopCountWithSource:(nonnull CGImageSourceRef)source;
+ (nullable UIImage *)createFrameAtIndex:(NSUInteger)index source:(nonnull CGImageSourceRef)source scale:(CGFloat)scale;

@end

@interface FWImageHEICCoder ()

+ (BOOL)canDecodeFromHEICFormat;
+ (BOOL)canDecodeFromHEIFFormat;
+ (BOOL)canEncodeToHEICFormat;
+ (BOOL)canEncodeToHEIFFormat;

@end

@implementation FWImageIOCoder {
    size_t _width, _height;
    CGImagePropertyOrientation _orientation;
    CGImageSourceRef _imageSource;
    CGFloat _scale;
    BOOL _finished;
}

- (void)dealloc {
    if (_imageSource) {
        CFRelease(_imageSource);
        _imageSource = NULL;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification
{
    if (_imageSource) {
        CGImageSourceRemoveCacheAtIndex(_imageSource, 0);
    }
}

+ (instancetype)sharedCoder {
    static FWImageIOCoder *coder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coder = [[FWImageIOCoder alloc] init];
    });
    return coder;
}

#pragma mark - Decode
- (BOOL)canDecodeFromData:(nullable NSData *)data {
    switch ([NSData fw_imageFormatForImageData:data]) {
        case FWImageFormatWebP:
            // Do not support WebP decoding
            return NO;
        case FWImageFormatHEIC:
            // Check HEIC decoding compatibility
            return [FWImageHEICCoder canDecodeFromHEICFormat];
        case FWImageFormatHEIF:
            // Check HEIF decoding compatibility
            return [FWImageHEICCoder canDecodeFromHEIFFormat];
        default:
            return YES;
    }
}

- (UIImage *)decodedImageWithData:(NSData *)data options:(nullable FWImageCoderOptions *)options {
    if (!data) {
        return nil;
    }
    CGFloat scale = 1;
    NSNumber *scaleFactor = options[FWImageCoderDecodeScaleFactor];
    if (scaleFactor != nil) {
        scale = MAX([scaleFactor doubleValue], 1) ;
    }
    
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (!source) {
        return nil;
    }
    
    UIImage *image = [FWImageIOAnimatedCoder createFrameAtIndex:0 source:source scale:scale];
    CFRelease(source);
    if (!image) {
        return nil;
    }
    
    image.fw_imageFormat = [NSData fw_imageFormatForImageData:data];
    return image;
}

#pragma mark - Progressive Decode

- (BOOL)canIncrementalDecodeFromData:(NSData *)data {
    return [self canDecodeFromData:data];
}

- (instancetype)initIncrementalWithOptions:(nullable FWImageCoderOptions *)options {
    self = [super init];
    if (self) {
        _imageSource = CGImageSourceCreateIncremental(NULL);
        CGFloat scale = 1;
        NSNumber *scaleFactor = options[FWImageCoderDecodeScaleFactor];
        if (scaleFactor != nil) {
            scale = MAX([scaleFactor doubleValue], 1);
        }
        _scale = scale;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (void)updateIncrementalData:(NSData *)data finished:(BOOL)finished {
    if (_finished) {
        return;
    }
    _finished = finished;
    
    // The following code is from http://www.cocoaintheshell.com/2011/05/progressive-images-download-imageio/
    // Thanks to the author @Nyx0uf
    
    // Update the data source, we must pass ALL the data, not just the new bytes
    CGImageSourceUpdateData(_imageSource, (__bridge CFDataRef)data, finished);
    
    if (_width + _height == 0) {
        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(_imageSource, 0, NULL);
        if (properties) {
            NSInteger orientationValue = 1;
            CFTypeRef val = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
            if (val) CFNumberGetValue(val, kCFNumberLongType, &_height);
            val = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
            if (val) CFNumberGetValue(val, kCFNumberLongType, &_width);
            val = CFDictionaryGetValue(properties, kCGImagePropertyOrientation);
            if (val) CFNumberGetValue(val, kCFNumberNSIntegerType, &orientationValue);
            CFRelease(properties);
            
            // When we draw to Core Graphics, we lose orientation information,
            // which means the image below born of initWithCGIImage will be
            // oriented incorrectly sometimes. (Unlike the image born of initWithData
            // in didCompleteWithError.) So save it here and pass it on later.
            _orientation = (CGImagePropertyOrientation)orientationValue;
        }
    }
}

- (UIImage *)incrementalDecodedImageWithOptions:(FWImageCoderOptions *)options {
    UIImage *image;
    
    if (_width + _height > 0) {
        // Create the image
        CGFloat scale = _scale;
        NSNumber *scaleFactor = options[FWImageCoderDecodeScaleFactor];
        if (scaleFactor != nil) {
            scale = MAX([scaleFactor doubleValue], 1);
        }
        image = [FWImageIOAnimatedCoder createFrameAtIndex:0 source:_imageSource scale:scale];
        if (image) {
            CFStringRef uttype = CGImageSourceGetType(_imageSource);
            image.fw_imageFormat = [NSData fw_imageFormatFromUTType:uttype];
        }
    }
    
    return image;
}

#pragma mark - Encode
- (BOOL)canEncodeToFormat:(FWImageFormat)format {
    switch (format) {
        case FWImageFormatWebP:
            // Do not support WebP encoding
            return NO;
        case FWImageFormatHEIC:
            // Check HEIC encoding compatibility
            return [FWImageHEICCoder canEncodeToHEICFormat];
        case FWImageFormatHEIF:
            // Check HEIF encoding compatibility
            return [FWImageHEICCoder canEncodeToHEIFFormat];
        default:
            return YES;
    }
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(FWImageFormat)format options:(nullable FWImageCoderOptions *)options {
    if (!image) {
        return nil;
    }
    
    if (format == FWImageFormatUndefined) {
        BOOL hasAlpha = [FWImageCoderHelper CGImageContainsAlpha:image.CGImage];
        if (hasAlpha) {
            format = FWImageFormatPNG;
        } else {
            format = FWImageFormatJPEG;
        }
    }
    
    NSMutableData *imageData = [NSMutableData data];
    CFStringRef imageUTType = [NSData fw_UTTypeFromImageFormat:format];
    
    // Create an image destination.
    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, imageUTType, 1, NULL);
    if (!imageDestination) {
        // Handle failure.
        return nil;
    }
    
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    CGImagePropertyOrientation exifOrientation = [FWImageCoderHelper exifOrientationFromImageOrientation:image.imageOrientation];
    properties[(__bridge NSString *)kCGImagePropertyOrientation] = @(exifOrientation);
    double compressionQuality = 1;
    if (options[FWImageCoderEncodeCompressionQuality]) {
        compressionQuality = [options[FWImageCoderEncodeCompressionQuality] doubleValue];
    }
    properties[(__bridge NSString *)kCGImageDestinationLossyCompressionQuality] = @(compressionQuality);
    
    // Add your image to the destination.
    CGImageDestinationAddImage(imageDestination, image.CGImage, (__bridge CFDictionaryRef)properties);
    
    // Finalize the destination.
    if (CGImageDestinationFinalize(imageDestination) == NO) {
        // Handle failure.
        imageData = nil;
    }
    
    CFRelease(imageDestination);
    
    return [imageData copy];
}

@end

@interface FWImageIOCoderFrame : NSObject

@property (nonatomic, assign) NSUInteger index; // Frame index (zero based)
@property (nonatomic, assign) NSTimeInterval duration; // Frame duration in seconds

@end

@implementation FWImageIOCoderFrame
@end

@implementation FWImageIOAnimatedCoder {
    size_t _width, _height;
    CGImageSourceRef _imageSource;
    NSData *_imageData;
    CGFloat _scale;
    NSUInteger _loopCount;
    NSUInteger _frameCount;
    NSArray<FWImageIOCoderFrame *> *_frames;
    BOOL _finished;
}

- (void)dealloc
{
    if (_imageSource) {
        CFRelease(_imageSource);
        _imageSource = NULL;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification
{
    if (_imageSource) {
        for (size_t i = 0; i < _frameCount; i++) {
            CGImageSourceRemoveCacheAtIndex(_imageSource, i);
        }
    }
}

#pragma mark - Subclass Override

+ (FWImageFormat)imageFormat {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"For `FWImageIOAnimatedCoder` subclass, you must override %@ method", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

+ (NSString *)imageUTType {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"For `FWImageIOAnimatedCoder` subclass, you must override %@ method", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

+ (NSString *)dictionaryProperty {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"For `FWImageIOAnimatedCoder` subclass, you must override %@ method", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

+ (NSString *)unclampedDelayTimeProperty {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"For `FWImageIOAnimatedCoder` subclass, you must override %@ method", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

+ (NSString *)delayTimeProperty {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"For `FWImageIOAnimatedCoder` subclass, you must override %@ method", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

+ (NSString *)loopCountProperty {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"For `FWImageIOAnimatedCoder` subclass, you must override %@ method", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

+ (NSUInteger)defaultLoopCount {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"For `FWImageIOAnimatedCoder` subclass, you must override %@ method", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

#pragma mark - Utils

+ (NSUInteger)imageLoopCountWithSource:(CGImageSourceRef)source {
    NSUInteger loopCount = self.defaultLoopCount;
    NSDictionary *imageProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyProperties(source, nil);
    NSDictionary *containerProperties = imageProperties[self.dictionaryProperty];
    if (containerProperties) {
        NSNumber *containerLoopCount = containerProperties[self.loopCountProperty];
        if (containerLoopCount != nil) {
            loopCount = containerLoopCount.unsignedIntegerValue;
        }
    }
    return loopCount;
}

+ (NSTimeInterval)frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source {
    NSTimeInterval frameDuration = 0.1;
    CFDictionaryRef cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil);
    if (!cfFrameProperties) {
        return frameDuration;
    }
    NSDictionary *frameProperties = (__bridge NSDictionary *)cfFrameProperties;
    NSDictionary *containerProperties = frameProperties[self.dictionaryProperty];
    
    NSNumber *delayTimeUnclampedProp = containerProperties[self.unclampedDelayTimeProperty];
    if (delayTimeUnclampedProp != nil) {
        frameDuration = [delayTimeUnclampedProp doubleValue];
    } else {
        NSNumber *delayTimeProp = containerProperties[self.delayTimeProperty];
        if (delayTimeProp != nil) {
            frameDuration = [delayTimeProp doubleValue];
        }
    }
    
    // Many annoying ads specify a 0 duration to make an image flash as quickly as possible.
    // We follow Firefox's behavior and use a duration of 100 ms for any frames that specify
    // a duration of <= 10 ms. See <rdar://problem/7689300> and <http://webkit.org/b/36082>
    // for more information.
    
    if (frameDuration < 0.011) {
        frameDuration = 0.1;
    }
    
    CFRelease(cfFrameProperties);
    return frameDuration;
}

+ (UIImage *)createFrameAtIndex:(NSUInteger)index source:(CGImageSourceRef)source scale:(CGFloat)scale {
    // Parse the image properties
    NSDictionary *properties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, index, NULL);
    CGImagePropertyOrientation exifOrientation = (CGImagePropertyOrientation)[properties[(__bridge NSString *)kCGImagePropertyOrientation] unsignedIntegerValue];
    if (!exifOrientation) {
        exifOrientation = kCGImagePropertyOrientationUp;
    }
    
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, index, NULL);
    if (!imageRef) {
        return nil;
    }
    
    UIImageOrientation imageOrientation = [FWImageCoderHelper imageOrientationFromEXIFOrientation:exifOrientation];
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:imageOrientation];
    CGImageRelease(imageRef);
    return image;
}

#pragma mark - Decode
- (BOOL)canDecodeFromData:(nullable NSData *)data {
    return ([NSData fw_imageFormatForImageData:data] == self.class.imageFormat);
}

- (UIImage *)decodedImageWithData:(NSData *)data options:(nullable FWImageCoderOptions *)options {
    if (!data) {
        return nil;
    }
    CGFloat scale = 1;
    NSNumber *scaleFactor = options[FWImageCoderDecodeScaleFactor];
    if (scaleFactor != nil) {
        scale = MAX([scaleFactor doubleValue], 1);
    }
    
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (!source) {
        return nil;
    }
    size_t count = CGImageSourceGetCount(source);
    UIImage *animatedImage;
    
    BOOL decodeFirstFrame = [options[FWImageCoderDecodeFirstFrameOnly] boolValue];
    if (decodeFirstFrame || count <= 1) {
        animatedImage = [self.class createFrameAtIndex:0 source:source scale:scale];
    } else {
        NSMutableArray<FWImageFrame *> *frames = [NSMutableArray array];
        
        for (size_t i = 0; i < count; i++) {
            UIImage *image = [self.class createFrameAtIndex:i source:source scale:scale];
            if (!image) {
                continue;
            }
            
            NSTimeInterval duration = [self.class frameDurationAtIndex:i source:source];
            
            FWImageFrame *frame = [FWImageFrame frameWithImage:image duration:duration];
            [frames addObject:frame];
        }
        
        NSUInteger loopCount = [self.class imageLoopCountWithSource:source];
        
        animatedImage = [FWImageCoderHelper animatedImageWithFrames:frames];
        animatedImage.fw_imageLoopCount = loopCount;
    }
    animatedImage.fw_imageFormat = self.class.imageFormat;
    CFRelease(source);
    
    return animatedImage;
}

#pragma mark - Progressive Decode

- (BOOL)canIncrementalDecodeFromData:(NSData *)data {
    return ([NSData fw_imageFormatForImageData:data] == self.class.imageFormat);
}

- (instancetype)initIncrementalWithOptions:(nullable FWImageCoderOptions *)options {
    self = [super init];
    if (self) {
        NSString *imageUTType = self.class.imageUTType;
        _imageSource = CGImageSourceCreateIncremental((__bridge CFDictionaryRef)@{(__bridge NSString *)kCGImageSourceTypeIdentifierHint : imageUTType});
        CGFloat scale = 1;
        NSNumber *scaleFactor = options[FWImageCoderDecodeScaleFactor];
        if (scaleFactor != nil) {
            scale = MAX([scaleFactor doubleValue], 1);
        }
        _scale = scale;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (void)updateIncrementalData:(NSData *)data finished:(BOOL)finished {
    if (_finished) {
        return;
    }
    _imageData = data;
    _finished = finished;
    
    // The following code is from http://www.cocoaintheshell.com/2011/05/progressive-images-download-imageio/
    // Thanks to the author @Nyx0uf
    
    // Update the data source, we must pass ALL the data, not just the new bytes
    CGImageSourceUpdateData(_imageSource, (__bridge CFDataRef)data, finished);
    
    if (_width + _height == 0) {
        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(_imageSource, 0, NULL);
        if (properties) {
            CFTypeRef val = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
            if (val) CFNumberGetValue(val, kCFNumberLongType, &_height);
            val = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
            if (val) CFNumberGetValue(val, kCFNumberLongType, &_width);
            CFRelease(properties);
        }
    }
    
    // For animated image progressive decoding because the frame count and duration may be changed.
    [self scanAndCheckFramesValidWithImageSource:_imageSource];
}

- (UIImage *)incrementalDecodedImageWithOptions:(FWImageCoderOptions *)options {
    UIImage *image;
    
    if (_width + _height > 0) {
        // Create the image
        CGFloat scale = _scale;
        NSNumber *scaleFactor = options[FWImageCoderDecodeScaleFactor];
        if (scaleFactor != nil) {
            scale = MAX([scaleFactor doubleValue], 1);
        }
        image = [FWImageIOAnimatedCoder createFrameAtIndex:0 source:_imageSource scale:scale];
        if (image) {
            image.fw_imageFormat = self.class.imageFormat;
        }
    }
    
    return image;
}

#pragma mark - Encode
- (BOOL)canEncodeToFormat:(FWImageFormat)format {
    return (format == self.class.imageFormat);
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(FWImageFormat)format options:(nullable FWImageCoderOptions *)options {
    if (!image) {
        return nil;
    }
    
    if (format != self.class.imageFormat) {
        return nil;
    }
    
    NSMutableData *imageData = [NSMutableData data];
    CFStringRef imageUTType = [NSData fw_UTTypeFromImageFormat:format];
    NSArray<FWImageFrame *> *frames = [FWImageCoderHelper framesFromAnimatedImage:image];
    
    // Create an image destination. Animated Image does not support EXIF image orientation TODO
    // The `CGImageDestinationCreateWithData` will log a warning when count is 0, use 1 instead.
    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, imageUTType, frames.count ?: 1, NULL);
    if (!imageDestination) {
        // Handle failure.
        return nil;
    }
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    double compressionQuality = 1;
    if (options[FWImageCoderEncodeCompressionQuality]) {
        compressionQuality = [options[FWImageCoderEncodeCompressionQuality] doubleValue];
    }
    properties[(__bridge NSString *)kCGImageDestinationLossyCompressionQuality] = @(compressionQuality);
    
    BOOL encodeFirstFrame = [options[FWImageCoderEncodeFirstFrameOnly] boolValue];
    if (encodeFirstFrame || frames.count == 0) {
        // for static single images
        CGImageDestinationAddImage(imageDestination, image.CGImage, (__bridge CFDictionaryRef)properties);
    } else {
        // for animated images
        NSUInteger loopCount = image.fw_imageLoopCount;
        NSDictionary *containerProperties = @{self.class.loopCountProperty : @(loopCount)};
        properties[self.class.dictionaryProperty] = containerProperties;
        CGImageDestinationSetProperties(imageDestination, (__bridge CFDictionaryRef)properties);
        
        for (size_t i = 0; i < frames.count; i++) {
            FWImageFrame *frame = frames[i];
            NSTimeInterval frameDuration = frame.duration;
            CGImageRef frameImageRef = frame.image.CGImage;
            NSDictionary *frameProperties = @{self.class.dictionaryProperty : @{self.class.delayTimeProperty : @(frameDuration)}};
            CGImageDestinationAddImage(imageDestination, frameImageRef, (__bridge CFDictionaryRef)frameProperties);
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

#pragma mark - FWAnimatedImageCoder
- (nullable instancetype)initWithAnimatedImageData:(nullable NSData *)data options:(nullable FWImageCoderOptions *)options {
    if (!data) {
        return nil;
    }
    self = [super init];
    if (self) {
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
        if (!imageSource) {
            return nil;
        }
        BOOL framesValid = [self scanAndCheckFramesValidWithImageSource:imageSource];
        if (!framesValid) {
            CFRelease(imageSource);
            return nil;
        }
        CGFloat scale = 1;
        NSNumber *scaleFactor = options[FWImageCoderDecodeScaleFactor];
        if (scaleFactor != nil) {
            scale = MAX([scaleFactor doubleValue], 1);
        }
        _scale = scale;
        _imageSource = imageSource;
        _imageData = data;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (BOOL)scanAndCheckFramesValidWithImageSource:(CGImageSourceRef)imageSource {
    if (!imageSource) {
        return NO;
    }
    NSUInteger frameCount = CGImageSourceGetCount(imageSource);
    NSUInteger loopCount = [self.class imageLoopCountWithSource:imageSource];
    NSMutableArray<FWImageIOCoderFrame *> *frames = [NSMutableArray array];
    
    for (size_t i = 0; i < frameCount; i++) {
        FWImageIOCoderFrame *frame = [[FWImageIOCoderFrame alloc] init];
        frame.index = i;
        frame.duration = [self.class frameDurationAtIndex:i source:imageSource];
        [frames addObject:frame];
    }
    
    _frameCount = frameCount;
    _loopCount = loopCount;
    _frames = [frames copy];
    
    return YES;
}

- (NSData *)animatedImageData {
    return _imageData;
}

- (NSUInteger)animatedImageLoopCount {
    return _loopCount;
}

- (NSUInteger)animatedImageFrameCount {
    return _frameCount;
}

- (NSTimeInterval)animatedImageDurationAtIndex:(NSUInteger)index {
    if (index >= _frameCount) {
        return 0;
    }
    return _frames[index].duration;
}

- (UIImage *)animatedImageFrameAtIndex:(NSUInteger)index {
    UIImage *image = [self.class createFrameAtIndex:index source:_imageSource scale:_scale];
    if (!image) {
        return nil;
    }
    image.fw_imageFormat = self.class.imageFormat;
    // Image/IO create CGImage does not decode, so we do this because this is called background queue, this can avoid main queue block when rendering(especially when one more imageViews use the same image instance)
    CGImageRef imageRef = [FWImageCoderHelper CGImageCreateDecoded:image.CGImage];
    if (!imageRef) {
        return image;
    }
    image = [[UIImage alloc] initWithCGImage:imageRef scale:_scale orientation:image.imageOrientation];
    CGImageRelease(imageRef);
    image.fw_isDecoded = YES;
    image.fw_imageFormat = self.class.imageFormat;
    return image;
}

@end

@implementation FWImageGIFCoder

+ (instancetype)sharedCoder {
    static FWImageGIFCoder *coder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coder = [[FWImageGIFCoder alloc] init];
    });
    return coder;
}

#pragma mark - Subclass Override

+ (FWImageFormat)imageFormat {
    return FWImageFormatGIF;
}

+ (NSString *)imageUTType {
    return (__bridge NSString *)kUTTypeGIF;
}

+ (NSString *)dictionaryProperty {
    return (__bridge NSString *)kCGImagePropertyGIFDictionary;
}

+ (NSString *)unclampedDelayTimeProperty {
    return (__bridge NSString *)kCGImagePropertyGIFUnclampedDelayTime;
}

+ (NSString *)delayTimeProperty {
    return (__bridge NSString *)kCGImagePropertyGIFDelayTime;
}

+ (NSString *)loopCountProperty {
    return (__bridge NSString *)kCGImagePropertyGIFLoopCount;
}

+ (NSUInteger)defaultLoopCount {
    return 1;
}

@end

#if (__IPHONE_OS_VERSION_MIN_REQUIRED && __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0)
const CFStringRef kCGImagePropertyAPNGLoopCount = (__bridge CFStringRef)@"LoopCount";
const CFStringRef kCGImagePropertyAPNGDelayTime = (__bridge CFStringRef)@"DelayTime";
const CFStringRef kCGImagePropertyAPNGUnclampedDelayTime = (__bridge CFStringRef)@"UnclampedDelayTime";
#endif

@implementation FWImageAPNGCoder

+ (instancetype)sharedCoder {
    static FWImageAPNGCoder *coder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coder = [[FWImageAPNGCoder alloc] init];
    });
    return coder;
}

#pragma mark - Subclass Override

+ (FWImageFormat)imageFormat {
    return FWImageFormatPNG;
}

+ (NSString *)imageUTType {
    return (__bridge NSString *)kUTTypePNG;
}

+ (NSString *)dictionaryProperty {
    return (__bridge NSString *)kCGImagePropertyPNGDictionary;
}

+ (NSString *)unclampedDelayTimeProperty {
    return (__bridge NSString *)kCGImagePropertyAPNGUnclampedDelayTime;
}

+ (NSString *)delayTimeProperty {
    return (__bridge NSString *)kCGImagePropertyAPNGDelayTime;
}

+ (NSString *)loopCountProperty {
    return (__bridge NSString *)kCGImagePropertyAPNGLoopCount;
}

+ (NSUInteger)defaultLoopCount {
    return 0;
}

@end

// These constantce are available from iOS 13+ and Xcode 11. This raw value is used for toolchain and firmware compatiblitiy
static NSString * kSDCGImagePropertyHEICSDictionary = @"{HEICS}";
static NSString * kSDCGImagePropertyHEICSLoopCount = @"LoopCount";
static NSString * kSDCGImagePropertyHEICSDelayTime = @"DelayTime";
static NSString * kSDCGImagePropertyHEICSUnclampedDelayTime = @"UnclampedDelayTime";

@implementation FWImageHEICCoder

+ (void)initialize {
#if __IPHONE_13_0 || __TVOS_13_0 || __MAC_10_15 || __WATCHOS_6_0
    // Xcode 11
    if (@available(iOS 13, tvOS 13, macOS 10.15, watchOS 6, *)) {
        // Use SDK instead of raw value
        kSDCGImagePropertyHEICSDictionary = (__bridge NSString *)kCGImagePropertyHEICSDictionary;
        kSDCGImagePropertyHEICSLoopCount = (__bridge NSString *)kCGImagePropertyHEICSLoopCount;
        kSDCGImagePropertyHEICSDelayTime = (__bridge NSString *)kCGImagePropertyHEICSDelayTime;
        kSDCGImagePropertyHEICSUnclampedDelayTime = (__bridge NSString *)kCGImagePropertyHEICSUnclampedDelayTime;
    }
#endif
}

+ (instancetype)sharedCoder {
    static FWImageHEICCoder *coder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coder = [[FWImageHEICCoder alloc] init];
    });
    return coder;
}

#pragma mark - FWImageCoder

- (BOOL)canDecodeFromData:(nullable NSData *)data {
    switch ([NSData fw_imageFormatForImageData:data]) {
        case FWImageFormatHEIC:
            // Check HEIC decoding compatibility
            return [self.class canDecodeFromHEICFormat];
        case FWImageFormatHEIF:
            // Check HEIF decoding compatibility
            return [self.class canDecodeFromHEIFFormat];
        default:
            return NO;
    }
}

- (BOOL)canIncrementalDecodeFromData:(NSData *)data {
    return [self canDecodeFromData:data];
}

- (BOOL)canEncodeToFormat:(FWImageFormat)format {
    switch (format) {
        case FWImageFormatHEIC:
            // Check HEIC encoding compatibility
            return [self.class canEncodeToHEICFormat];
        case FWImageFormatHEIF:
            // Check HEIF encoding compatibility
            return [self.class canEncodeToHEIFFormat];
        default:
            return NO;
    }
}

#pragma mark - HEIF Format

+ (BOOL)canDecodeFromFormat:(FWImageFormat)format {
    CFStringRef imageUTType = [NSData fw_UTTypeFromImageFormat:format];
    NSArray *imageUTTypes = (__bridge_transfer NSArray *)CGImageSourceCopyTypeIdentifiers();
    if ([imageUTTypes containsObject:(__bridge NSString *)(imageUTType)]) {
        return YES;
    }
    return NO;
}

+ (BOOL)canDecodeFromHEICFormat {
    static BOOL canDecode = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        canDecode = [self canDecodeFromFormat:FWImageFormatHEIC];
    });
    return canDecode;
}

+ (BOOL)canDecodeFromHEIFFormat {
    static BOOL canDecode = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        canDecode = [self canDecodeFromFormat:FWImageFormatHEIF];
    });
    return canDecode;
}

+ (BOOL)canEncodeToFormat:(FWImageFormat)format {
    NSMutableData *imageData = [NSMutableData data];
    CFStringRef imageUTType = [NSData fw_UTTypeFromImageFormat:format];
    
    // Create an image destination.
    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, imageUTType, 1, NULL);
    if (!imageDestination) {
        // Can't encode to HEIC
        return NO;
    } else {
        // Can encode to HEIC
        CFRelease(imageDestination);
        return YES;
    }
}

+ (BOOL)canEncodeToHEICFormat {
    static BOOL canEncode = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        canEncode = [self canEncodeToFormat:FWImageFormatHEIC];
    });
    return canEncode;
}

+ (BOOL)canEncodeToHEIFFormat {
    static BOOL canEncode = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        canEncode = [self canEncodeToFormat:FWImageFormatHEIF];
    });
    return canEncode;
}

#pragma mark - Subclass Override

+ (FWImageFormat)imageFormat {
    return FWImageFormatHEIC;
}

+ (NSString *)imageUTType {
    return (__bridge NSString *)kSDUTTypeHEIC;
}

+ (NSString *)dictionaryProperty {
    return kSDCGImagePropertyHEICSDictionary;
}

+ (NSString *)unclampedDelayTimeProperty {
    return kSDCGImagePropertyHEICSUnclampedDelayTime;
}

+ (NSString *)delayTimeProperty {
    return kSDCGImagePropertyHEICSDelayTime;
}

+ (NSString *)loopCountProperty {
    return kSDCGImagePropertyHEICSLoopCount;
}

+ (NSUInteger)defaultLoopCount {
    return 0;
}

@end

static const size_t kBytesPerPixel = 4;
static const size_t kBitsPerComponent = 8;

static const CGFloat kBytesPerMB = 1024.0f * 1024.0f;
static const CGFloat kPixelsPerMB = kBytesPerMB / kBytesPerPixel;
/*
 * Defines the maximum size in MB of the decoded image when the flag `SDWebImageScaleDownLargeImages` is set
 * Suggested value for iPad1 and iPhone 3GS: 60.
 * Suggested value for iPad2 and iPhone 4: 120.
 * Suggested value for iPhone 3G and iPod 2 and earlier devices: 30.
 */
static CGFloat kDestImageLimitBytes = 60.f * kBytesPerMB;

static const CGFloat kDestSeemOverlap = 2.0f;   // the numbers of pixels to overlap the seems where tiles meet.

@implementation FWImageCoderHelper

+ (UIImage *)animatedImageWithFrames:(NSArray<FWImageFrame *> *)frames {
    NSUInteger frameCount = frames.count;
    if (frameCount == 0) {
        return nil;
    }
    
    UIImage *animatedImage;
    
    NSUInteger durations[frameCount];
    for (size_t i = 0; i < frameCount; i++) {
        durations[i] = frames[i].duration * 1000;
    }
    NSUInteger const gcd = gcdArray(frameCount, durations);
    __block NSUInteger totalDuration = 0;
    NSMutableArray<UIImage *> *animatedImages = [NSMutableArray arrayWithCapacity:frameCount];
    [frames enumerateObjectsUsingBlock:^(FWImageFrame * _Nonnull frame, NSUInteger idx, BOOL * _Nonnull stop) {
        UIImage *image = frame.image;
        NSUInteger duration = frame.duration * 1000;
        totalDuration += duration;
        NSUInteger repeatCount;
        if (gcd) {
            repeatCount = duration / gcd;
        } else {
            repeatCount = 1;
        }
        for (size_t i = 0; i < repeatCount; ++i) {
            [animatedImages addObject:image];
        }
    }];
    
    animatedImage = [UIImage animatedImageWithImages:animatedImages duration:totalDuration / 1000.f];
    
    return animatedImage;
}

+ (NSArray<FWImageFrame *> *)framesFromAnimatedImage:(UIImage *)animatedImage {
    if (!animatedImage) {
        return nil;
    }
    
    NSMutableArray<FWImageFrame *> *frames = [NSMutableArray array];
    NSUInteger frameCount = 0;
    
    NSArray<UIImage *> *animatedImages = animatedImage.images;
    frameCount = animatedImages.count;
    if (frameCount == 0) {
        return nil;
    }
    
    NSTimeInterval avgDuration = animatedImage.duration / frameCount;
    if (avgDuration == 0) {
        avgDuration = 0.1; // if it's a animated image but no duration, set it to default 100ms (this do not have that 10ms limit like GIF or WebP to allow custom coder provide the limit)
    }
    
    __block NSUInteger index = 0;
    __block NSUInteger repeatCount = 1;
    __block UIImage *previousImage = animatedImages.firstObject;
    [animatedImages enumerateObjectsUsingBlock:^(UIImage * _Nonnull image, NSUInteger idx, BOOL * _Nonnull stop) {
        // ignore first
        if (idx == 0) {
            return;
        }
        if ([image isEqual:previousImage]) {
            repeatCount++;
        } else {
            FWImageFrame *frame = [FWImageFrame frameWithImage:previousImage duration:avgDuration * repeatCount];
            [frames addObject:frame];
            repeatCount = 1;
            index++;
        }
        previousImage = image;
        // last one
        if (idx == frameCount - 1) {
            FWImageFrame *frame = [FWImageFrame frameWithImage:previousImage duration:avgDuration * repeatCount];
            [frames addObject:frame];
        }
    }];
    
    return frames;
}

+ (CGColorSpaceRef)colorSpaceGetDeviceRGB {
    static CGColorSpaceRef colorSpace;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 9.0, tvOS 9.0, *)) {
            colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        } else {
            colorSpace = CGColorSpaceCreateDeviceRGB();
        }
    });
    return colorSpace;
}

+ (BOOL)CGImageContainsAlpha:(CGImageRef)cgImage {
    if (!cgImage) {
        return NO;
    }
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(cgImage);
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    return hasAlpha;
}

+ (CGImageRef)CGImageCreateDecoded:(CGImageRef)cgImage {
    return [self CGImageCreateDecoded:cgImage orientation:kCGImagePropertyOrientationUp];
}

+ (CGImageRef)CGImageCreateDecoded:(CGImageRef)cgImage orientation:(CGImagePropertyOrientation)orientation {
    if (!cgImage) {
        return NULL;
    }
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    if (width == 0 || height == 0) return NULL;
    size_t newWidth;
    size_t newHeight;
    switch (orientation) {
        case kCGImagePropertyOrientationLeft:
        case kCGImagePropertyOrientationLeftMirrored:
        case kCGImagePropertyOrientationRight:
        case kCGImagePropertyOrientationRightMirrored: {
            // These orientation should swap width & height
            newWidth = height;
            newHeight = width;
        }
            break;
        default: {
            newWidth = width;
            newHeight = height;
        }
            break;
    }
    
    BOOL hasAlpha = [self CGImageContainsAlpha:cgImage];
    // iOS prefer BGRA8888 (premultiplied) or BGRX8888 bitmapInfo for screen rendering, which is same as `UIGraphicsBeginImageContext()` or `- [CALayer drawInContext:]`
    // Though you can use any supported bitmapInfo (see: https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_context/dq_context.html#//apple_ref/doc/uid/TP30001066-CH203-BCIBHHBB ) and let Core Graphics reorder it when you call `CGContextDrawImage`
    // But since our build-in coders use this bitmapInfo, this can have a little performance benefit
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
    bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
    CGContextRef context = CGBitmapContextCreate(NULL, newWidth, newHeight, 8, 0, [self colorSpaceGetDeviceRGB], bitmapInfo);
    if (!context) {
        return NULL;
    }
    
    // Apply transform
    CGAffineTransform transform = SDCGContextTransformFromOrientation(orientation, CGSizeMake(newWidth, newHeight));
    CGContextConcatCTM(context, transform);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage); // The rect is bounding box of CGImage, don't swap width & height
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    return newImageRef;
}

+ (UIImage *)decodedImageWithImage:(UIImage *)image {
    if (![self shouldDecodeImage:image]) {
        return image;
    }
    
    CGImageRef imageRef = [self CGImageCreateDecoded:image.CGImage];
    if (!imageRef) {
        return image;
    }
    UIImage *decodedImage = [[UIImage alloc] initWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(imageRef);
    //SDImageCopyAssociatedObject(image, decodedImage);
    decodedImage.fw_isDecoded = YES;
    return decodedImage;
}

+ (UIImage *)decodedAndScaledDownImageWithImage:(UIImage *)image limitBytes:(NSUInteger)bytes {
    if (![self shouldDecodeImage:image]) {
        return image;
    }
    
    if (![self shouldScaleDownImage:image limitBytes:bytes]) {
        return [self decodedImageWithImage:image];
    }
    
    CGFloat destTotalPixels;
    CGFloat tileTotalPixels;
    if (bytes == 0) {
        bytes = kDestImageLimitBytes;
    }
    destTotalPixels = bytes / kBytesPerPixel;
    tileTotalPixels = destTotalPixels / 3;
    CGContextRef destContext;
    
    // autorelease the bitmap context and all vars to help system to free memory when there are memory warning.
    // on iOS7, do not forget to call [[SDImageCache sharedImageCache] clearMemory];
    @autoreleasepool {
        CGImageRef sourceImageRef = image.CGImage;
        
        CGSize sourceResolution = CGSizeZero;
        sourceResolution.width = CGImageGetWidth(sourceImageRef);
        sourceResolution.height = CGImageGetHeight(sourceImageRef);
        CGFloat sourceTotalPixels = sourceResolution.width * sourceResolution.height;
        // Determine the scale ratio to apply to the input image
        // that results in an output image of the defined size.
        // see kDestImageSizeMB, and how it relates to destTotalPixels.
        CGFloat imageScale = sqrt(destTotalPixels / sourceTotalPixels);
        CGSize destResolution = CGSizeZero;
        destResolution.width = (int)(sourceResolution.width * imageScale);
        destResolution.height = (int)(sourceResolution.height * imageScale);
        
        // device color space
        CGColorSpaceRef colorspaceRef = [self colorSpaceGetDeviceRGB];
        BOOL hasAlpha = [self CGImageContainsAlpha:sourceImageRef];
        // iOS display alpha info (BGRA8888/BGRX8888)
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
        bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
        
        // kCGImageAlphaNone is not supported in CGBitmapContextCreate.
        // Since the original image here has no alpha info, use kCGImageAlphaNoneSkipFirst
        // to create bitmap graphics contexts without alpha info.
        destContext = CGBitmapContextCreate(NULL,
                                            destResolution.width,
                                            destResolution.height,
                                            kBitsPerComponent,
                                            0,
                                            colorspaceRef,
                                            bitmapInfo);
        
        if (destContext == NULL) {
            return image;
        }
        CGContextSetInterpolationQuality(destContext, kCGInterpolationHigh);
        
        // Now define the size of the rectangle to be used for the
        // incremental blits from the input image to the output image.
        // we use a source tile width equal to the width of the source
        // image due to the way that iOS retrieves image data from disk.
        // iOS must decode an image from disk in full width 'bands', even
        // if current graphics context is clipped to a subrect within that
        // band. Therefore we fully utilize all of the pixel data that results
        // from a decoding opertion by achnoring our tile size to the full
        // width of the input image.
        CGRect sourceTile = CGRectZero;
        sourceTile.size.width = sourceResolution.width;
        // The source tile height is dynamic. Since we specified the size
        // of the source tile in MB, see how many rows of pixels high it
        // can be given the input image width.
        sourceTile.size.height = (int)(tileTotalPixels / sourceTile.size.width );
        sourceTile.origin.x = 0.0f;
        // The output tile is the same proportions as the input tile, but
        // scaled to image scale.
        CGRect destTile;
        destTile.size.width = destResolution.width;
        destTile.size.height = sourceTile.size.height * imageScale;
        destTile.origin.x = 0.0f;
        // The source seem overlap is proportionate to the destination seem overlap.
        // this is the amount of pixels to overlap each tile as we assemble the ouput image.
        float sourceSeemOverlap = (int)((kDestSeemOverlap/destResolution.height)*sourceResolution.height);
        CGImageRef sourceTileImageRef;
        // calculate the number of read/write operations required to assemble the
        // output image.
        int iterations = (int)( sourceResolution.height / sourceTile.size.height );
        // If tile height doesn't divide the image height evenly, add another iteration
        // to account for the remaining pixels.
        int remainder = (int)sourceResolution.height % (int)sourceTile.size.height;
        if(remainder) {
            iterations++;
        }
        // Add seem overlaps to the tiles, but save the original tile height for y coordinate calculations.
        float sourceTileHeightMinusOverlap = sourceTile.size.height;
        sourceTile.size.height += sourceSeemOverlap;
        destTile.size.height += kDestSeemOverlap;
        for( int y = 0; y < iterations; ++y ) {
            @autoreleasepool {
                sourceTile.origin.y = y * sourceTileHeightMinusOverlap + sourceSeemOverlap;
                destTile.origin.y = destResolution.height - (( y + 1 ) * sourceTileHeightMinusOverlap * imageScale + kDestSeemOverlap);
                sourceTileImageRef = CGImageCreateWithImageInRect( sourceImageRef, sourceTile );
                if( y == iterations - 1 && remainder ) {
                    float dify = destTile.size.height;
                    destTile.size.height = CGImageGetHeight( sourceTileImageRef ) * imageScale;
                    dify -= destTile.size.height;
                    destTile.origin.y += dify;
                }
                CGContextDrawImage( destContext, destTile, sourceTileImageRef );
                CGImageRelease( sourceTileImageRef );
            }
        }
        
        CGImageRef destImageRef = CGBitmapContextCreateImage(destContext);
        CGContextRelease(destContext);
        if (destImageRef == NULL) {
            return image;
        }
        UIImage *destImage = [[UIImage alloc] initWithCGImage:destImageRef scale:image.scale orientation:image.imageOrientation];
        CGImageRelease(destImageRef);
        if (destImage == nil) {
            return image;
        }
        //SDImageCopyAssociatedObject(image, destImage);
        destImage.fw_isDecoded = YES;
        return destImage;
    }
}

+ (NSUInteger)defaultScaleDownLimitBytes {
    return kDestImageLimitBytes;
}

+ (void)setDefaultScaleDownLimitBytes:(NSUInteger)defaultScaleDownLimitBytes {
    if (defaultScaleDownLimitBytes < kBytesPerMB) {
        return;
    }
    kDestImageLimitBytes = defaultScaleDownLimitBytes;
}

// Convert an EXIF image orientation to an iOS one.
+ (UIImageOrientation)imageOrientationFromEXIFOrientation:(CGImagePropertyOrientation)exifOrientation {
    UIImageOrientation imageOrientation = UIImageOrientationUp;
    switch (exifOrientation) {
        case kCGImagePropertyOrientationUp:
            imageOrientation = UIImageOrientationUp;
            break;
        case kCGImagePropertyOrientationDown:
            imageOrientation = UIImageOrientationDown;
            break;
        case kCGImagePropertyOrientationLeft:
            imageOrientation = UIImageOrientationLeft;
            break;
        case kCGImagePropertyOrientationRight:
            imageOrientation = UIImageOrientationRight;
            break;
        case kCGImagePropertyOrientationUpMirrored:
            imageOrientation = UIImageOrientationUpMirrored;
            break;
        case kCGImagePropertyOrientationDownMirrored:
            imageOrientation = UIImageOrientationDownMirrored;
            break;
        case kCGImagePropertyOrientationLeftMirrored:
            imageOrientation = UIImageOrientationLeftMirrored;
            break;
        case kCGImagePropertyOrientationRightMirrored:
            imageOrientation = UIImageOrientationRightMirrored;
            break;
        default:
            break;
    }
    return imageOrientation;
}

// Convert an iOS orientation to an EXIF image orientation.
+ (CGImagePropertyOrientation)exifOrientationFromImageOrientation:(UIImageOrientation)imageOrientation {
    CGImagePropertyOrientation exifOrientation = kCGImagePropertyOrientationUp;
    switch (imageOrientation) {
        case UIImageOrientationUp:
            exifOrientation = kCGImagePropertyOrientationUp;
            break;
        case UIImageOrientationDown:
            exifOrientation = kCGImagePropertyOrientationDown;
            break;
        case UIImageOrientationLeft:
            exifOrientation = kCGImagePropertyOrientationLeft;
            break;
        case UIImageOrientationRight:
            exifOrientation = kCGImagePropertyOrientationRight;
            break;
        case UIImageOrientationUpMirrored:
            exifOrientation = kCGImagePropertyOrientationUpMirrored;
            break;
        case UIImageOrientationDownMirrored:
            exifOrientation = kCGImagePropertyOrientationDownMirrored;
            break;
        case UIImageOrientationLeftMirrored:
            exifOrientation = kCGImagePropertyOrientationLeftMirrored;
            break;
        case UIImageOrientationRightMirrored:
            exifOrientation = kCGImagePropertyOrientationRightMirrored;
            break;
        default:
            break;
    }
    return exifOrientation;
}

#pragma mark - Helper Fuction
+ (BOOL)shouldDecodeImage:(nullable UIImage *)image {
    // Avoid extra decode
    if (image.fw_isDecoded) {
        return NO;
    }
    // Prevent "CGBitmapContextCreateImage: invalid context 0x0" error
    if (image == nil) {
        return NO;
    }
    // do not decode animated images
    if (image.fw_isAnimated) {
        return NO;
    }
    
    return YES;
}

+ (BOOL)shouldScaleDownImage:(nonnull UIImage *)image limitBytes:(NSUInteger)bytes {
    BOOL shouldScaleDown = YES;
    
    CGImageRef sourceImageRef = image.CGImage;
    CGSize sourceResolution = CGSizeZero;
    sourceResolution.width = CGImageGetWidth(sourceImageRef);
    sourceResolution.height = CGImageGetHeight(sourceImageRef);
    float sourceTotalPixels = sourceResolution.width * sourceResolution.height;
    if (sourceTotalPixels <= 0) {
        return NO;
    }
    CGFloat destTotalPixels;
    if (bytes == 0) {
        bytes = kDestImageLimitBytes;
    }
    destTotalPixels = bytes / kBytesPerPixel;
    if (destTotalPixels <= kPixelsPerMB) {
        // Too small to scale down
        return NO;
    }
    float imageScale = destTotalPixels / sourceTotalPixels;
    if (imageScale < 1) {
        shouldScaleDown = YES;
    } else {
        shouldScaleDown = NO;
    }
    
    return shouldScaleDown;
}

static inline CGAffineTransform SDCGContextTransformFromOrientation(CGImagePropertyOrientation orientation, CGSize size) {
    // Inspiration from @libfeihu
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (orientation) {
        case kCGImagePropertyOrientationDown:
        case kCGImagePropertyOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case kCGImagePropertyOrientationLeft:
        case kCGImagePropertyOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case kCGImagePropertyOrientationRight:
        case kCGImagePropertyOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case kCGImagePropertyOrientationUp:
        case kCGImagePropertyOrientationUpMirrored:
            break;
    }
    
    switch (orientation) {
        case kCGImagePropertyOrientationUpMirrored:
        case kCGImagePropertyOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case kCGImagePropertyOrientationLeftMirrored:
        case kCGImagePropertyOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case kCGImagePropertyOrientationUp:
        case kCGImagePropertyOrientationDown:
        case kCGImagePropertyOrientationLeft:
        case kCGImagePropertyOrientationRight:
            break;
    }
    
    return transform;
}

static NSUInteger gcd(NSUInteger a, NSUInteger b) {
    NSUInteger c;
    while (a != 0) {
        c = a;
        a = b % a;
        b = c;
    }
    return b;
}

static NSUInteger gcdArray(size_t const count, NSUInteger const * const values) {
    if (count == 0) {
        return 0;
    }
    NSUInteger result = values[0];
    for (size_t i = 1; i < count; ++i) {
        result = gcd(values[i], result);
    }
    return result;
}

@end

#pragma mark - FWImageFrame

@interface FWImageFrame ()

@property (nonatomic, strong, readwrite, nonnull) UIImage *image;
@property (nonatomic, readwrite, assign) NSTimeInterval duration;

@end

@implementation FWImageFrame

+ (instancetype)frameWithImage:(UIImage *)image duration:(NSTimeInterval)duration {
    FWImageFrame *frame = [[FWImageFrame alloc] init];
    frame.image = image;
    frame.duration = duration;
    
    return frame;
}

@end

@implementation NSData (ImageContentType)

+ (FWImageFormat)fw_imageFormatForImageData:(nullable NSData *)data {
    if (!data) {
        return FWImageFormatUndefined;
    }
    
    // File signatures table: http://www.garykessler.net/library/file_sigs.html
    uint8_t c;
    [data getBytes:&c length:1];
    switch (c) {
        case 0xFF:
            return FWImageFormatJPEG;
        case 0x89:
            return FWImageFormatPNG;
        case 0x47:
            return FWImageFormatGIF;
        case 0x49:
        case 0x4D:
            return FWImageFormatTIFF;
        case 0x52: {
            if (data.length >= 12) {
                //RIFF....WEBP
                NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
                if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"]) {
                    return FWImageFormatWebP;
                }
            }
            break;
        }
        case 0x00: {
            if (data.length >= 12) {
                //....ftypheic ....ftypheix ....ftyphevc ....ftyphevx
                NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(4, 8)] encoding:NSASCIIStringEncoding];
                if ([testString isEqualToString:@"ftypheic"]
                    || [testString isEqualToString:@"ftypheix"]
                    || [testString isEqualToString:@"ftyphevc"]
                    || [testString isEqualToString:@"ftyphevx"]) {
                    return FWImageFormatHEIC;
                }
                //....ftypmif1 ....ftypmsf1
                if ([testString isEqualToString:@"ftypmif1"] || [testString isEqualToString:@"ftypmsf1"]) {
                    return FWImageFormatHEIF;
                }
            }
            break;
        }
    }
    return FWImageFormatUndefined;
}

+ (nonnull CFStringRef)fw_UTTypeFromImageFormat:(FWImageFormat)format {
    CFStringRef UTType;
    switch (format) {
        case FWImageFormatJPEG:
            UTType = kUTTypeJPEG;
            break;
        case FWImageFormatPNG:
            UTType = kUTTypePNG;
            break;
        case FWImageFormatGIF:
            UTType = kUTTypeGIF;
            break;
        case FWImageFormatTIFF:
            UTType = kUTTypeTIFF;
            break;
        case FWImageFormatWebP:
            UTType = kSDUTTypeWebP;
            break;
        case FWImageFormatHEIC:
            UTType = kSDUTTypeHEIC;
            break;
        case FWImageFormatHEIF:
            UTType = kSDUTTypeHEIF;
            break;
        default:
            // default is kUTTypePNG
            UTType = kUTTypePNG;
            break;
    }
    return UTType;
}

+ (FWImageFormat)fw_imageFormatFromUTType:(CFStringRef)uttype {
    if (!uttype) {
        return FWImageFormatUndefined;
    }
    FWImageFormat imageFormat;
    if (CFStringCompare(uttype, kUTTypeJPEG, 0) == kCFCompareEqualTo) {
        imageFormat = FWImageFormatJPEG;
    } else if (CFStringCompare(uttype, kUTTypePNG, 0) == kCFCompareEqualTo) {
        imageFormat = FWImageFormatPNG;
    } else if (CFStringCompare(uttype, kUTTypeGIF, 0) == kCFCompareEqualTo) {
        imageFormat = FWImageFormatGIF;
    } else if (CFStringCompare(uttype, kUTTypeTIFF, 0) == kCFCompareEqualTo) {
        imageFormat = FWImageFormatTIFF;
    } else if (CFStringCompare(uttype, kSDUTTypeWebP, 0) == kCFCompareEqualTo) {
        imageFormat = FWImageFormatWebP;
    } else if (CFStringCompare(uttype, kSDUTTypeHEIC, 0) == kCFCompareEqualTo) {
        imageFormat = FWImageFormatHEIC;
    } else if (CFStringCompare(uttype, kSDUTTypeHEIF, 0) == kCFCompareEqualTo) {
        imageFormat = FWImageFormatHEIF;
    } else {
        imageFormat = FWImageFormatUndefined;
    }
    return imageFormat;
}

@end

@implementation UIImage (Metadata)

- (NSUInteger)fw_imageLoopCount {
    NSUInteger imageLoopCount = 0;
    NSNumber *value = objc_getAssociatedObject(self, @selector(fw_imageLoopCount));
    if ([value isKindOfClass:[NSNumber class]]) {
        imageLoopCount = value.unsignedIntegerValue;
    }
    return imageLoopCount;
}

- (void)setFw_imageLoopCount:(NSUInteger)fw_imageLoopCount {
    NSNumber *value = @(fw_imageLoopCount);
    objc_setAssociatedObject(self, @selector(fw_imageLoopCount), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fw_isAnimated {
    return (self.images != nil);
}

- (FWImageFormat)fw_imageFormat {
    FWImageFormat imageFormat = FWImageFormatUndefined;
    NSNumber *value = objc_getAssociatedObject(self, @selector(fw_imageFormat));
    if ([value isKindOfClass:[NSNumber class]]) {
        imageFormat = value.integerValue;
        return imageFormat;
    }
    // Check CGImage's UTType, may return nil for non-Image/IO based image
    if (@available(iOS 9.0, tvOS 9.0, macOS 10.11, watchOS 2.0, *)) {
        CFStringRef uttype = CGImageGetUTType(self.CGImage);
        imageFormat = [NSData fw_imageFormatFromUTType:uttype];
    }
    return imageFormat;
}

- (void)setFw_imageFormat:(FWImageFormat)fw_imageFormat {
    objc_setAssociatedObject(self, @selector(fw_imageFormat), @(fw_imageFormat), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setFw_isIncremental:(BOOL)fw_isIncremental {
    objc_setAssociatedObject(self, @selector(fw_isIncremental), @(fw_isIncremental), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fw_isIncremental {
    NSNumber *value = objc_getAssociatedObject(self, @selector(fw_isIncremental));
    return value.boolValue;
}

- (BOOL)fw_isDecoded {
    NSNumber *value = objc_getAssociatedObject(self, @selector(fw_isDecoded));
    return value.boolValue;
}

- (void)setFw_isDecoded:(BOOL)fw_isDecoded {
    objc_setAssociatedObject(self, @selector(fw_isDecoded), @(fw_isDecoded), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UIImage (MultiFormat)

+ (nullable UIImage *)fw_imageWithData:(nullable NSData *)data {
    return [self fw_imageWithData:data scale:1];
}

+ (nullable UIImage *)fw_imageWithData:(nullable NSData *)data scale:(CGFloat)scale {
    return [self fw_imageWithData:data scale:scale firstFrameOnly:NO];
}

+ (nullable UIImage *)fw_imageWithData:(nullable NSData *)data scale:(CGFloat)scale firstFrameOnly:(BOOL)firstFrameOnly {
    if (!data) {
        return nil;
    }
    FWImageCoderOptions *options = @{FWImageCoderDecodeScaleFactor : @(MAX(scale, 1)), FWImageCoderDecodeFirstFrameOnly : @(firstFrameOnly)};
    return [[FWImageCodersManager sharedManager] decodedImageWithData:data options:options];
}

- (nullable NSData *)fw_imageData {
    return [self fw_imageDataAsFormat:FWImageFormatUndefined];
}

- (nullable NSData *)fw_imageDataAsFormat:(FWImageFormat)imageFormat {
    return [self fw_imageDataAsFormat:imageFormat compressionQuality:1];
}

- (nullable NSData *)fw_imageDataAsFormat:(FWImageFormat)imageFormat compressionQuality:(double)compressionQuality {
    return [self fw_imageDataAsFormat:imageFormat compressionQuality:compressionQuality firstFrameOnly:NO];
}

- (nullable NSData *)fw_imageDataAsFormat:(FWImageFormat)imageFormat compressionQuality:(double)compressionQuality firstFrameOnly:(BOOL)firstFrameOnly {
    FWImageCoderOptions *options = @{FWImageCoderEncodeCompressionQuality : @(compressionQuality), FWImageCoderEncodeFirstFrameOnly : @(firstFrameOnly)};
    return [[FWImageCodersManager sharedManager] encodedDataWithImage:self format:imageFormat options:options];
}

@end
