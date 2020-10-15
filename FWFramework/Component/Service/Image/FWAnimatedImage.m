/*!
 @header     FWAnimatedImage.m
 @indexgroup FWFramework
 @brief      FWAnimatedImage
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/7
 */

#import "FWAnimatedImage.h"
#import "FWPlugin.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <ImageIO/ImageIO.h>
#import <objc/runtime.h>

#pragma mark - FWAnimatedImage

UIImage * FWImageName(NSString *name) {
    return [UIImage fwImageWithName:name];
}

UIImage * FWImageFile(NSString *path) {
    return [UIImage fwImageWithFile:path];
}

#pragma mark - UIImage+FWAnimated

@implementation UIImage (FWAnimated)

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
    
    return [[FWImageCoder sharedInstance] decodedImageWithData:data scale:scale];
}

#pragma mark - Property

- (NSUInteger)fwImageLoopCount
{
    return [objc_getAssociatedObject(self, @selector(fwImageLoopCount)) unsignedIntegerValue];
}

- (void)setFwImageLoopCount:(NSUInteger)fwImageLoopCount
{
    objc_setAssociatedObject(self, @selector(fwImageLoopCount), @(fwImageLoopCount), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fwIsAnimated
{
    return self.images != nil;
}

- (BOOL)fwIsVector
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if (@available(iOS 13.0, *)) {
        // Xcode 11 supports symbol image, keep Xcode 10 compatible currently
        SEL SymbolSelector = NSSelectorFromString(@"isSymbolImage");
        if ([self respondsToSelector:SymbolSelector] && [self performSelector:SymbolSelector]) {
            return YES;
        }
        // SVG
        SEL SVGSelector = NSSelectorFromString([NSString stringWithFormat:@"_%@", @"CGSVGDocument"]);
        if ([self respondsToSelector:SVGSelector] && [self performSelector:SVGSelector]) {
            return YES;
        }
    }
    if (@available(iOS 11.0, *)) {
        // PDF
        SEL PDFSelector = NSSelectorFromString([NSString stringWithFormat:@"_%@", @"CGPDFPage"]);
        if ([self respondsToSelector:PDFSelector] && [self performSelector:PDFSelector]) {
            return YES;
        }
    }
    return NO;
#pragma clang diagnostic pop
}

- (FWImageFormat)fwImageFormat
{
    NSNumber *value = objc_getAssociatedObject(self, @selector(fwImageFormat));
    if (value) {
        return [value integerValue];
    }
    if (@available(iOS 9.0, *)) {
        CFStringRef uttype = CGImageGetUTType(self.CGImage);
        return [NSData fwImageFormatFromUTType:uttype];
    }
    return FWImageFormatUndefined;
}

- (void)setFwImageFormat:(FWImageFormat)fwImageFormat
{
    objc_setAssociatedObject(self, @selector(fwImageFormat), @(fwImageFormat), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark - NSData+FWAnimated

#define kSVGTagEnd @"</svg>"

@implementation NSData (FWAnimated)

+ (FWImageFormat)fwImageFormatForImageData:(NSData *)data
{
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
        case 0x25: {
            if (data.length >= 4) {
                //%PDF
                NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(1, 3)] encoding:NSASCIIStringEncoding];
                if ([testString isEqualToString:@"PDF"]) {
                    return FWImageFormatPDF;
                }
            }
        }
        case 0x3C: {
            // Check end with SVG tag
            if ([data rangeOfData:[kSVGTagEnd dataUsingEncoding:NSUTF8StringEncoding] options:NSDataSearchBackwards range: NSMakeRange(data.length - MIN(100, data.length), MIN(100, data.length))].location != NSNotFound) {
                return FWImageFormatSVG;
            }
        }
    }
    return FWImageFormatUndefined;
}

+ (nonnull CFStringRef)fwUTTypeFromImageFormat:(FWImageFormat)format
{
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
            UTType = kFWUTTypeWebP;
            break;
        case FWImageFormatHEIC:
            UTType = kFWUTTypeHEIC;
            break;
        case FWImageFormatHEIF:
            UTType = kFWUTTypeHEIF;
            break;
        case FWImageFormatPDF:
            UTType = kUTTypePDF;
            break;
        case FWImageFormatSVG:
            UTType = kUTTypeScalableVectorGraphics;
            break;
        default:
            // default is kUTTypeImage abstract type
            UTType = kUTTypeImage;
            break;
    }
    return UTType;
}

+ (FWImageFormat)fwImageFormatFromUTType:(CFStringRef)uttype
{
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
    } else if (CFStringCompare(uttype, kFWUTTypeWebP, 0) == kCFCompareEqualTo) {
        imageFormat = FWImageFormatWebP;
    } else if (CFStringCompare(uttype, kFWUTTypeHEIC, 0) == kCFCompareEqualTo) {
        imageFormat = FWImageFormatHEIC;
    } else if (CFStringCompare(uttype, kFWUTTypeHEIF, 0) == kCFCompareEqualTo) {
        imageFormat = FWImageFormatHEIF;
    } else if (CFStringCompare(uttype, kUTTypePDF, 0) == kCFCompareEqualTo) {
        imageFormat = FWImageFormatPDF;
    } else if (CFStringCompare(uttype, kUTTypeScalableVectorGraphics, 0) == kCFCompareEqualTo) {
        imageFormat = FWImageFormatSVG;
    } else {
        imageFormat = FWImageFormatUndefined;
    }
    return imageFormat;
}

@end

#pragma mark - FWImageFrame

@implementation FWImageFrame

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

+ (UIImage *)animatedImageWithFrames:(NSArray<FWImageFrame *> *)frames
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
    
    return [UIImage animatedImageWithImages:animatedImages duration:totalDuration / 1000.f];
}

+ (NSArray<FWImageFrame *> *)framesFromAnimatedImage:(UIImage *)animatedImage
{
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
            FWImageFrame *frame = [[FWImageFrame alloc] initWithImage:previousImage duration:avgDuration * repeatCount];
            [frames addObject:frame];
            repeatCount = 1;
            index++;
        }
        previousImage = image;
        // last one
        if (idx == frameCount - 1) {
            FWImageFrame *frame = [[FWImageFrame alloc] initWithImage:previousImage duration:avgDuration * repeatCount];
            [frames addObject:frame];
        }
    }];
    return frames;
}

@end

#pragma mark - FWImageCoder

@implementation FWImageCoder

+ (FWImageCoder *)sharedInstance
{
    static FWImageCoder *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWImageCoder alloc] init];
    });
    return instance;
}

- (UIImage *)decodedImageWithData:(NSData *)data scale:(CGFloat)scale
{
    if (!data) return nil;
    
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (!source) return nil;
    
    UIImage *animatedImage;
    size_t count = CGImageSourceGetCount(source);
    FWImageFormat format = [NSData fwImageFormatForImageData:data];
    if (![self isAnimated:format] || count <= 1) {
        animatedImage = [self createFrameAtIndex:0 source:source scale:scale];
    } else {
        NSMutableArray *frames = [NSMutableArray array];
        for (size_t i = 0; i < count; i++) {
            UIImage *image = [self createFrameAtIndex:i source:source scale:scale];
            if (!image) continue;
            
            NSTimeInterval duration = [self frameDurationAtIndex:i source:source format:format];
            FWImageFrame *frame = [[FWImageFrame alloc] initWithImage:image duration:duration];
            [frames addObject:frame];
        }
        
        NSUInteger loopCount = [self imageLoopCountWithSource:source format:format];
        animatedImage = [FWImageFrame animatedImageWithFrames:frames];
        animatedImage.fwImageLoopCount = loopCount;
    }
    animatedImage.fwImageFormat = format;
    CFRelease(source);
    
    return animatedImage;
}

- (BOOL)isAnimated:(FWImageFormat)format
{
    BOOL isAnimated = NO;
    switch (format) {
        case FWImageFormatPNG:
        case FWImageFormatGIF:
            isAnimated = YES;
            break;
        case FWImageFormatHEIC:
        case FWImageFormatHEIF:
            if (@available(iOS 13.0, *)) {
                isAnimated = self.heicsEnabled;
            }
            break;
        case FWImageFormatWebP:
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
    static NSSet *imageUTTypeSet;
    dispatch_once(&onceToken, ^{
        NSArray *imageUTTypes = (__bridge_transfer NSArray *)CGImageSourceCopyTypeIdentifiers();
        imageUTTypeSet = [NSSet setWithArray:imageUTTypes];
    });
    CFStringRef imageUTType = [NSData fwUTTypeFromImageFormat:format];
    if ([imageUTTypeSet containsObject:(__bridge NSString *)(imageUTType)]) {
        return YES;
    }
    return NO;
}

- (NSString *)dictionaryProperty:(FWImageFormat)format
{
    switch (format) {
        case FWImageFormatGIF:
            return (__bridge NSString *)kCGImagePropertyGIFDictionary;
        case FWImageFormatPNG:
            return (__bridge NSString *)kCGImagePropertyPNGDictionary;
        case FWImageFormatHEIC:
        case FWImageFormatHEIF:
            if (@available(iOS 13.0, *)) {
                return (__bridge NSString *)kCGImagePropertyHEICSDictionary;
            } else {
                return @"{HEICS}";
            }
        case FWImageFormatWebP:
#if __IPHONE_14_0
            if (@available(iOS 14.0, *)) {
                return (__bridge NSString *)kCGImagePropertyWebPDictionary;
            }
#endif
            return @"{WebP}";
        default:
            return nil;
    }
}

- (NSString *)unclampedDelayTimeProperty:(FWImageFormat)format
{
    switch (format) {
        case FWImageFormatGIF:
            return (__bridge NSString *)kCGImagePropertyGIFUnclampedDelayTime;
        case FWImageFormatPNG:
            return (__bridge NSString *)kCGImagePropertyAPNGUnclampedDelayTime;
        case FWImageFormatHEIC:
        case FWImageFormatHEIF:
            if (@available(iOS 13.0, *)) {
                return (__bridge NSString *)kCGImagePropertyHEICSUnclampedDelayTime;
            } else {
                return @"UnclampedDelayTime";
            }
        case FWImageFormatWebP:
#if __IPHONE_14_0
            if (@available(iOS 14.0, *)) {
                return (__bridge NSString *)kCGImagePropertyWebPUnclampedDelayTime;
            }
#endif
            return @"UnclampedDelayTime";
        default:
            return nil;
    }
}

- (NSString *)delayTimeProperty:(FWImageFormat)format
{
    switch (format) {
        case FWImageFormatGIF:
            return (__bridge NSString *)kCGImagePropertyGIFDelayTime;
        case FWImageFormatPNG:
            return (__bridge NSString *)kCGImagePropertyAPNGDelayTime;
        case FWImageFormatHEIC:
        case FWImageFormatHEIF:
            if (@available(iOS 13.0, *)) {
                return (__bridge NSString *)kCGImagePropertyHEICSDelayTime;
            } else {
                return @"DelayTime";
            }
        case FWImageFormatWebP:
#if __IPHONE_14_0
            if (@available(iOS 14.0, *)) {
                return (__bridge NSString *)kCGImagePropertyWebPDelayTime;
            }
#endif
            return @"DelayTime";
        default:
            return nil;
    }
}

- (NSString *)loopCountProperty:(FWImageFormat)format
{
    switch (format) {
        case FWImageFormatGIF:
            return (__bridge NSString *)kCGImagePropertyGIFLoopCount;
        case FWImageFormatPNG:
            return (__bridge NSString *)kCGImagePropertyAPNGLoopCount;
        case FWImageFormatHEIC:
        case FWImageFormatHEIF:
            if (@available(iOS 13.0, *)) {
                return (__bridge NSString *)kCGImagePropertyHEICSLoopCount;
            } else {
                return @"LoopCount";
            }
        case FWImageFormatWebP:
#if __IPHONE_14_0
            if (@available(iOS 14.0, *)) {
                return (__bridge NSString *)kCGImagePropertyWebPLoopCount;
            }
#endif
            return @"LoopCount";
        default:
            return nil;
    }
}

- (NSUInteger)defaultLoopCount:(FWImageFormat)format
{
    switch (format) {
        case FWImageFormatGIF:
            return 1;
        default:
            return 0;
    }
}

- (NSUInteger)imageLoopCountWithSource:(CGImageSourceRef)source format:(FWImageFormat)format
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

- (NSTimeInterval)frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source format:(FWImageFormat)format
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
    BOOL isVector = ([NSData fwImageFormatFromUTType:uttype] == FWImageFormatPDF);

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

@end
