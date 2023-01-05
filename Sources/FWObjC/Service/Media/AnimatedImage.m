//
//  AnimatedImage.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "AnimatedImage.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <ImageIO/ImageIO.h>
#import <dlfcn.h>
#import <objc/runtime.h>

#if FWMacroSPM

@interface UIImage ()

@property (nonatomic, assign, readonly) BOOL __fw_hasAlpha;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - __FWImageFrame

@implementation __FWImageFrame

- (instancetype)initWithImage:(UIImage *)image duration:(NSTimeInterval)duration
{
    self = [super init];
    if (self) {
        _image = image;
        _duration = duration;
    }
    return self;
}

+ (NSUInteger)gcd:(NSUInteger)a with:(NSUInteger)b
{
    NSUInteger c;
    while (a != 0) {
        c = a;
        a = b % a;
        b = c;
    }
    return b;
}

+ (NSUInteger)gcdArray:(size_t const)count values:(NSUInteger const * const)values
{
    if (count == 0) {
        return 0;
    }
    NSUInteger result = values[0];
    for (size_t i = 1; i < count; ++i) {
        result = [self gcd:values[i] with:result];
    }
    return result;
}

+ (UIImage *)animatedImageWithFrames:(NSArray<__FWImageFrame *> *)frames
{
    NSUInteger frameCount = frames.count;
    if (frameCount == 0) {
        return nil;
    }
    
    NSUInteger durations[frameCount];
    for (size_t i = 0; i < frameCount; i++) {
        durations[i] = frames[i].duration * 1000;
    }
    NSUInteger const gcd = [self gcdArray:frameCount values:durations];
    __block NSUInteger totalDuration = 0;
    NSMutableArray<UIImage *> *animatedImages = [NSMutableArray arrayWithCapacity:frameCount];
    [frames enumerateObjectsUsingBlock:^(__FWImageFrame * _Nonnull frame, NSUInteger idx, BOOL * _Nonnull stop) {
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
    
    return [UIImage animatedImageWithImages:animatedImages duration:totalDuration / 1000.f];
}

+ (NSArray<__FWImageFrame *> *)framesFromAnimatedImage:(UIImage *)animatedImage
{
    if (!animatedImage) {
        return nil;
    }
    
    NSMutableArray<__FWImageFrame *> *frames = [NSMutableArray array];
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
            __FWImageFrame *frame = [[__FWImageFrame alloc] initWithImage:previousImage duration:avgDuration * repeatCount];
            [frames addObject:frame];
            repeatCount = 1;
            index++;
        }
        previousImage = image;
        // last one
        if (idx == frameCount - 1) {
            __FWImageFrame *frame = [[__FWImageFrame alloc] initWithImage:previousImage duration:avgDuration * repeatCount];
            [frames addObject:frame];
        }
    }];
    return frames;
}

@end

#pragma mark - __FWImageCoder

#define kSVGTagEnd @"</svg>"

typedef struct CF_BRIDGED_TYPE(id) CGSVGDocument *CGSVGDocumentRef;
static void (*__FWCGSVGDocumentRelease)(CGSVGDocumentRef);
static CGSVGDocumentRef (*__FWCGSVGDocumentCreateFromData)(CFDataRef data, CFDictionaryRef options);
static void (*__FWCGSVGDocumentWriteToData)(CGSVGDocumentRef document, CFDataRef data, CFDictionaryRef options);
static SEL __FWImageWithCGSVGDocumentSEL = NULL;
static SEL __FWCGSVGDocumentSEL = NULL;

@implementation __FWImageCoder

+ (__FWImageCoder *)sharedInstance
{
    static __FWImageCoder *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[__FWImageCoder alloc] init];
    });
    return instance;
}

+ (void)initialize
{
    if (@available(iOS 13.0, *)) {
        __FWCGSVGDocumentRelease = dlsym(RTLD_DEFAULT, [self base64DecodedString:@"Q0dTVkdEb2N1bWVudFJlbGVhc2U="].UTF8String);
        __FWCGSVGDocumentCreateFromData = dlsym(RTLD_DEFAULT, [self base64DecodedString:@"Q0dTVkdEb2N1bWVudENyZWF0ZUZyb21EYXRh"].UTF8String);
        __FWCGSVGDocumentWriteToData = dlsym(RTLD_DEFAULT, [self base64DecodedString:@"Q0dTVkdEb2N1bWVudFdyaXRlVG9EYXRh"].UTF8String);
        __FWImageWithCGSVGDocumentSEL = NSSelectorFromString([self base64DecodedString:@"X2ltYWdlV2l0aENHU1ZHRG9jdW1lbnQ6"]);
        __FWCGSVGDocumentSEL = NSSelectorFromString([self base64DecodedString:@"X0NHU1ZHRG9jdW1lbnQ="]);
    }
}

+ (NSString *)base64DecodedString:(NSString *)base64String
{
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64String options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (!data) return nil;
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (UIImage *)decodedImageWithData:(NSData *)data scale:(CGFloat)scale options:(NSDictionary<__FWImageCoderOptions,id> *)options
{
    if (data.length < 1) return nil;
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (!source) return nil;
    NSNumber *scaleFactor = options[__FWImageCoderOptionScaleFactor];
    if (scaleFactor != nil) scale = MAX([scaleFactor doubleValue], 1);
    
    UIImage *animatedImage;
    size_t count = CGImageSourceGetCount(source);
    __FWImageFormat format = [__FWImageCoder imageFormatForImageData:data];
    if (format == __FWImageFormatSVG) {
        if (@available(iOS 13.0, *)) {
            if ([UIImage respondsToSelector:__FWImageWithCGSVGDocumentSEL]) {
                CGSVGDocumentRef document = __FWCGSVGDocumentCreateFromData((__bridge CFDataRef)data, NULL);
                if (document) {
                    animatedImage = ((UIImage *(*)(id,SEL,CGSVGDocumentRef))[UIImage.class methodForSelector:__FWImageWithCGSVGDocumentSEL])(UIImage.class, __FWImageWithCGSVGDocumentSEL, document);
                    __FWCGSVGDocumentRelease(document);
                }
            }
        }
    } else if (![self isAnimated:format forDecode:YES] || count <= 1) {
        animatedImage = [self createFrameAtIndex:0 source:source scale:scale];
    } else {
        NSMutableArray *frames = [NSMutableArray array];
        for (size_t i = 0; i < count; i++) {
            UIImage *image = [self createFrameAtIndex:i source:source scale:scale];
            if (!image) continue;
            
            NSTimeInterval duration = [self frameDurationAtIndex:i source:source format:format];
            __FWImageFrame *frame = [[__FWImageFrame alloc] initWithImage:image duration:duration];
            [frames addObject:frame];
        }
        
        NSUInteger loopCount = [self imageLoopCountWithSource:source format:format];
        animatedImage = [__FWImageFrame animatedImageWithFrames:frames];
        animatedImage.__fw_imageLoopCount = loopCount;
    }
    
    animatedImage.__fw_imageFormat = format;
    CFRelease(source);
    return animatedImage;
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(__FWImageFormat)format options:(NSDictionary<__FWImageCoderOptions,id> *)options
{
    if (!image) return nil;
    if (format == __FWImageFormatUndefined) {
        format = image.__fw_hasAlpha ? __FWImageFormatPNG : __FWImageFormatJPEG;
    }
    if (format == __FWImageFormatSVG) {
        if (@available(iOS 13.0, *)) {
            if ([UIImage respondsToSelector:__FWImageWithCGSVGDocumentSEL]) {
                NSMutableData *data = [NSMutableData data];
                CGSVGDocumentRef document = ((CGSVGDocumentRef (*)(id,SEL))[image methodForSelector:__FWCGSVGDocumentSEL])(image, __FWCGSVGDocumentSEL);
                if (document) {
                    __FWCGSVGDocumentWriteToData(document, (__bridge CFDataRef)data, NULL);
                    return [data copy];
                }
            }
        }
        return nil;
    }
    
    CGImageRef imageRef = image.CGImage;
    if (!imageRef) return nil;
    
    NSMutableData *imageData = [NSMutableData data];
    CFStringRef imageUTType = [__FWImageCoder utTypeFromImageFormat:format];
    BOOL isAnimated = [self isAnimated:format forDecode:NO];
    NSArray<__FWImageFrame *> *frames = isAnimated ? [__FWImageFrame framesFromAnimatedImage:image] : nil;
    size_t count = frames.count > 0 ? frames.count : 1;
    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, imageUTType, count, NULL);
    if (!imageDestination) return nil;
    
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    properties[(__bridge NSString *)kCGImageDestinationLossyCompressionQuality] = @(1);
    properties[(__bridge NSString *)kCGImageDestinationEmbedThumbnail] = @(NO);

    if (!isAnimated || count <= 1) {
        properties[(__bridge NSString *)kCGImagePropertyOrientation] = @([self exifOrientation:image.imageOrientation]);
        
        CGImageDestinationAddImage(imageDestination, imageRef, (__bridge CFDictionaryRef)properties);
    } else {
        NSDictionary *containerProperties = @{
            [self dictionaryProperty:format]: @{[self loopCountProperty:format] : @(image.__fw_imageLoopCount)}
        };
        CGImageDestinationSetProperties(imageDestination, (__bridge CFDictionaryRef)containerProperties);
        
        for (size_t i = 0; i < count; i++) {
            __FWImageFrame *frame = frames[i];
            CGImageRef frameImageRef = frame.image.CGImage;
            properties[[self dictionaryProperty:format]] = @{[self delayTimeProperty:format] : @(frame.duration)};
            CGImageDestinationAddImage(imageDestination, frameImageRef, (__bridge CFDictionaryRef)properties);
        }
    }
    
    if (CGImageDestinationFinalize(imageDestination) == NO) imageData = nil;
    CFRelease(imageDestination);
    return [imageData copy];
}

- (BOOL)isAnimated:(__FWImageFormat)format forDecode:(BOOL)forDecode
{
    BOOL isAnimated = NO;
    switch (format) {
        case __FWImageFormatPNG:
        case __FWImageFormatGIF:
            isAnimated = YES;
            break;
        case __FWImageFormatHEIC:
        case __FWImageFormatHEIF:
            if (@available(iOS 13.0, *)) {
                isAnimated = self.heicsEnabled;
            }
            break;
        case __FWImageFormatWebP:
            if (@available(iOS 14.0, *)) {
                isAnimated = YES;
            }
            break;
        default:
            break;
    }
    if (!isAnimated) {
        return NO;
    }
    
    static dispatch_once_t onceToken;
    static NSSet *decodeUTTypeSet;
    static NSSet *encodeUTTypeSet;
    dispatch_once(&onceToken, ^{
        NSArray *decodeUTTypes = (__bridge_transfer NSArray *)CGImageSourceCopyTypeIdentifiers();
        decodeUTTypeSet = [NSSet setWithArray:decodeUTTypes];
        NSArray *encodeUTTypes = (__bridge_transfer NSArray *)CGImageDestinationCopyTypeIdentifiers();
        encodeUTTypeSet = [NSSet setWithArray:encodeUTTypes];
    });
    CFStringRef imageUTType = [__FWImageCoder utTypeFromImageFormat:format];
    NSSet *imageUTTypeSet = forDecode ? decodeUTTypeSet : encodeUTTypeSet;
    if ([imageUTTypeSet containsObject:(__bridge NSString *)(imageUTType)]) {
        return YES;
    }
    return NO;
}

- (CGImagePropertyOrientation)exifOrientation:(UIImageOrientation)imageOrientation
{
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

- (NSString *)dictionaryProperty:(__FWImageFormat)format
{
    switch (format) {
        case __FWImageFormatGIF:
            return (__bridge NSString *)kCGImagePropertyGIFDictionary;
        case __FWImageFormatPNG:
            return (__bridge NSString *)kCGImagePropertyPNGDictionary;
        case __FWImageFormatHEIC:
        case __FWImageFormatHEIF:
            if (@available(iOS 13.0, *)) {
                return (__bridge NSString *)kCGImagePropertyHEICSDictionary;
            } else {
                return @"{HEICS}";
            }
        case __FWImageFormatWebP:
            if (@available(iOS 14.0, *)) {
                return (__bridge NSString *)kCGImagePropertyWebPDictionary;
            }
            return @"{WebP}";
        default:
            return nil;
    }
}

- (NSString *)unclampedDelayTimeProperty:(__FWImageFormat)format
{
    switch (format) {
        case __FWImageFormatGIF:
            return (__bridge NSString *)kCGImagePropertyGIFUnclampedDelayTime;
        case __FWImageFormatPNG:
            return (__bridge NSString *)kCGImagePropertyAPNGUnclampedDelayTime;
        case __FWImageFormatHEIC:
        case __FWImageFormatHEIF:
            if (@available(iOS 13.0, *)) {
                return (__bridge NSString *)kCGImagePropertyHEICSUnclampedDelayTime;
            } else {
                return @"UnclampedDelayTime";
            }
        case __FWImageFormatWebP:
            if (@available(iOS 14.0, *)) {
                return (__bridge NSString *)kCGImagePropertyWebPUnclampedDelayTime;
            }
            return @"UnclampedDelayTime";
        default:
            return nil;
    }
}

- (NSString *)delayTimeProperty:(__FWImageFormat)format
{
    switch (format) {
        case __FWImageFormatGIF:
            return (__bridge NSString *)kCGImagePropertyGIFDelayTime;
        case __FWImageFormatPNG:
            return (__bridge NSString *)kCGImagePropertyAPNGDelayTime;
        case __FWImageFormatHEIC:
        case __FWImageFormatHEIF:
            if (@available(iOS 13.0, *)) {
                return (__bridge NSString *)kCGImagePropertyHEICSDelayTime;
            } else {
                return @"DelayTime";
            }
        case __FWImageFormatWebP:
            if (@available(iOS 14.0, *)) {
                return (__bridge NSString *)kCGImagePropertyWebPDelayTime;
            }
            return @"DelayTime";
        default:
            return nil;
    }
}

- (NSString *)loopCountProperty:(__FWImageFormat)format
{
    switch (format) {
        case __FWImageFormatGIF:
            return (__bridge NSString *)kCGImagePropertyGIFLoopCount;
        case __FWImageFormatPNG:
            return (__bridge NSString *)kCGImagePropertyAPNGLoopCount;
        case __FWImageFormatHEIC:
        case __FWImageFormatHEIF:
            if (@available(iOS 13.0, *)) {
                return (__bridge NSString *)kCGImagePropertyHEICSLoopCount;
            } else {
                return @"LoopCount";
            }
        case __FWImageFormatWebP:
            if (@available(iOS 14.0, *)) {
                return (__bridge NSString *)kCGImagePropertyWebPLoopCount;
            }
            return @"LoopCount";
        default:
            return nil;
    }
}

- (NSUInteger)defaultLoopCount:(__FWImageFormat)format
{
    switch (format) {
        case __FWImageFormatGIF:
            return 1;
        default:
            return 0;
    }
}

- (NSUInteger)imageLoopCountWithSource:(CGImageSourceRef)source format:(__FWImageFormat)format
{
    NSUInteger loopCount = [self defaultLoopCount:format];
    NSDictionary *imageProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyProperties(source, NULL);
    NSDictionary *containerProperties = imageProperties[[self dictionaryProperty:format]];
    if (containerProperties) {
        NSNumber *containerLoopCount = containerProperties[[self loopCountProperty:format]];
        if (containerLoopCount != nil) {
            loopCount = containerLoopCount.unsignedIntegerValue;
        }
    }
    return loopCount;
}

- (NSTimeInterval)frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source format:(__FWImageFormat)format
{
    NSDictionary *options = @{
        (__bridge NSString *)kCGImageSourceShouldCacheImmediately : @(YES),
        (__bridge NSString *)kCGImageSourceShouldCache : @(YES)
    };
    NSTimeInterval frameDuration = 0.1;
    CFDictionaryRef cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, (__bridge CFDictionaryRef)options);
    if (!cfFrameProperties) {
        return frameDuration;
    }
    NSDictionary *frameProperties = (__bridge NSDictionary *)cfFrameProperties;
    NSDictionary *containerProperties = frameProperties[[self dictionaryProperty:format]];
    
    NSNumber *delayTimeUnclampedProp = containerProperties[[self unclampedDelayTimeProperty:format]];
    if (delayTimeUnclampedProp != nil) {
        frameDuration = [delayTimeUnclampedProp doubleValue];
    } else {
        NSNumber *delayTimeProp = containerProperties[[self delayTimeProperty:format]];
        if (delayTimeProp != nil) {
            frameDuration = [delayTimeProp doubleValue];
        }
    }
    if (frameDuration < 0.011) {
        frameDuration = 0.1;
    }
    
    CFRelease(cfFrameProperties);
    return frameDuration;
}

- (UIImage *)createFrameAtIndex:(NSUInteger)index source:(CGImageSourceRef)source scale:(CGFloat)scale
{
    CFStringRef uttype = CGImageSourceGetType(source);
    BOOL isVector = ([__FWImageCoder imageFormatFromUTType:uttype] == __FWImageFormatPDF);

    NSMutableDictionary *decodingOptions = [NSMutableDictionary dictionary];
    if (isVector) {
        CGSize thumbnailSize = UIScreen.mainScreen.bounds.size;
        NSUInteger rasterizationDPI = MAX(thumbnailSize.width, thumbnailSize.height) * 2;
        decodingOptions[@"kCGImageSourceRasterizationDPI"] = @(rasterizationDPI);
    }
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, index, (__bridge CFDictionaryRef)[decodingOptions copy]);
    if (!imageRef) return nil;
    
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
    CGImageRelease(imageRef);
    return image;
}

+ (__FWImageFormat)imageFormatForImageData:(NSData *)data
{
    if (data.length < 1) {
        return __FWImageFormatUndefined;
    }
    
    // File signatures table: http://www.garykessler.net/library/file_sigs.html
    uint8_t c;
    [data getBytes:&c length:1];
    switch (c) {
        case 0xFF:
            return __FWImageFormatJPEG;
        case 0x89:
            return __FWImageFormatPNG;
        case 0x47:
            return __FWImageFormatGIF;
        case 0x49:
        case 0x4D:
            return __FWImageFormatTIFF;
        case 0x52: {
            if (data.length >= 12) {
                //RIFF....WEBP
                NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
                if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"]) {
                    return __FWImageFormatWebP;
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
                    return __FWImageFormatHEIC;
                }
                //....ftypmif1 ....ftypmsf1
                if ([testString isEqualToString:@"ftypmif1"] || [testString isEqualToString:@"ftypmsf1"]) {
                    return __FWImageFormatHEIF;
                }
            }
            break;
        }
        case 0x25: {
            if (data.length >= 4) {
                //%PDF
                NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(1, 3)] encoding:NSASCIIStringEncoding];
                if ([testString isEqualToString:@"PDF"]) {
                    return __FWImageFormatPDF;
                }
            }
        }
        case 0x3C: {
            // Check end with SVG tag
            if ([data rangeOfData:[kSVGTagEnd dataUsingEncoding:NSUTF8StringEncoding] options:NSDataSearchBackwards range: NSMakeRange(data.length - MIN(100, data.length), MIN(100, data.length))].location != NSNotFound) {
                return __FWImageFormatSVG;
            }
        }
    }
    return __FWImageFormatUndefined;
}

+ (nonnull CFStringRef)utTypeFromImageFormat:(__FWImageFormat)format
{
    CFStringRef UTType;
    switch (format) {
        case __FWImageFormatJPEG:
            UTType = kUTTypeJPEG;
            break;
        case __FWImageFormatPNG:
            UTType = kUTTypePNG;
            break;
        case __FWImageFormatGIF:
            UTType = kUTTypeGIF;
            break;
        case __FWImageFormatTIFF:
            UTType = kUTTypeTIFF;
            break;
        case __FWImageFormatWebP:
            UTType = kFWUTTypeWebP;
            break;
        case __FWImageFormatHEIC:
            UTType = kFWUTTypeHEIC;
            break;
        case __FWImageFormatHEIF:
            UTType = kFWUTTypeHEIF;
            break;
        case __FWImageFormatPDF:
            UTType = kUTTypePDF;
            break;
        case __FWImageFormatSVG:
            UTType = kUTTypeScalableVectorGraphics;
            break;
        default:
            // default is kUTTypeImage abstract type
            UTType = kUTTypeImage;
            break;
    }
    return UTType;
}

+ (__FWImageFormat)imageFormatFromUTType:(CFStringRef)uttype
{
    if (!uttype) {
        return __FWImageFormatUndefined;
    }
    __FWImageFormat imageFormat;
    if (CFStringCompare(uttype, kUTTypeJPEG, 0) == kCFCompareEqualTo) {
        imageFormat = __FWImageFormatJPEG;
    } else if (CFStringCompare(uttype, kUTTypePNG, 0) == kCFCompareEqualTo) {
        imageFormat = __FWImageFormatPNG;
    } else if (CFStringCompare(uttype, kUTTypeGIF, 0) == kCFCompareEqualTo) {
        imageFormat = __FWImageFormatGIF;
    } else if (CFStringCompare(uttype, kUTTypeTIFF, 0) == kCFCompareEqualTo) {
        imageFormat = __FWImageFormatTIFF;
    } else if (CFStringCompare(uttype, kFWUTTypeWebP, 0) == kCFCompareEqualTo) {
        imageFormat = __FWImageFormatWebP;
    } else if (CFStringCompare(uttype, kFWUTTypeHEIC, 0) == kCFCompareEqualTo) {
        imageFormat = __FWImageFormatHEIC;
    } else if (CFStringCompare(uttype, kFWUTTypeHEIF, 0) == kCFCompareEqualTo) {
        imageFormat = __FWImageFormatHEIF;
    } else if (CFStringCompare(uttype, kUTTypePDF, 0) == kCFCompareEqualTo) {
        imageFormat = __FWImageFormatPDF;
    } else if (CFStringCompare(uttype, kUTTypeScalableVectorGraphics, 0) == kCFCompareEqualTo) {
        imageFormat = __FWImageFormatSVG;
    } else {
        imageFormat = __FWImageFormatUndefined;
    }
    return imageFormat;
}

+ (NSString *)mimeTypeFromImageFormat:(__FWImageFormat)format
{
    NSString *mimeType;
    switch (format) {
        case __FWImageFormatJPEG:
            mimeType = @"image/jpeg";
            break;
        case __FWImageFormatPNG:
            mimeType = @"image/png";
            break;
        case __FWImageFormatGIF:
            mimeType = @"image/gif";
            break;
        case __FWImageFormatTIFF:
            mimeType = @"image/tiff";
            break;
        case __FWImageFormatWebP:
            mimeType = @"image/webp";
            break;
        case __FWImageFormatHEIC:
            mimeType = @"image/heic";
            break;
        case __FWImageFormatHEIF:
            mimeType = @"image/heif";
            break;
        case __FWImageFormatPDF:
            mimeType = @"application/pdf";
            break;
        case __FWImageFormatSVG:
            mimeType = @"image/svg+xml";
            break;
        default:
            mimeType = @"application/octet-stream";
            break;
    }
    return mimeType;
}

+ (NSString *)mimeTypeFromExtension:(NSString *)extension
{
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    NSString *mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
    if (!mimeType) mimeType = @"application/octet-stream";
    return mimeType;
}

+ (NSString *)base64StringForImageData:(NSData *)data
{
    if (data.length < 1) return nil;
    NSString *base64String = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    NSString *mimeType = [__FWImageCoder mimeTypeFromImageFormat:[__FWImageCoder imageFormatForImageData:data]];
    NSString *base64Prefix = [NSString stringWithFormat:@"data:%@;base64,", mimeType];
    return [base64Prefix stringByAppendingString:base64String];
}

+ (BOOL)isVectorImage:(UIImage *)image
{
    if (!image) return NO;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if (@available(iOS 13.0, *)) {
        // Xcode 11 supports symbol image, keep Xcode 10 compatible currently
        SEL SymbolSelector = NSSelectorFromString(@"isSymbolImage");
        if ([image respondsToSelector:SymbolSelector] && [image performSelector:SymbolSelector]) {
            return YES;
        }
        // SVG
        SEL SVGSelector = NSSelectorFromString([NSString stringWithFormat:@"_%@", @"CGSVGDocument"]);
        if ([image respondsToSelector:SVGSelector] && [image performSelector:SVGSelector]) {
            return YES;
        }
    }
    // PDF
    SEL PDFSelector = NSSelectorFromString([NSString stringWithFormat:@"_%@", @"CGPDFPage"]);
    if ([image respondsToSelector:PDFSelector] && [image performSelector:PDFSelector]) {
        return YES;
    }
    return NO;
#pragma clang diagnostic pop
}

@end
