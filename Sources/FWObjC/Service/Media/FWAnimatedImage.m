//
//  FWAnimatedImage.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWAnimatedImage.h"
#import "FWToolkit.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <ImageIO/ImageIO.h>
#import <dlfcn.h>
#import <objc/runtime.h>

#pragma mark - UIImage+FWAnimated

@implementation UIImage (FWAnimated)

- (NSUInteger)fw_imageLoopCount
{
    return [objc_getAssociatedObject(self, @selector(fw_imageLoopCount)) unsignedIntegerValue];
}

- (void)setFw_imageLoopCount:(NSUInteger)imageLoopCount
{
    objc_setAssociatedObject(self, @selector(fw_imageLoopCount), @(imageLoopCount), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)fw_isAnimated
{
    return self.images != nil;
}

- (BOOL)fw_isVector
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
    // PDF
    SEL PDFSelector = NSSelectorFromString([NSString stringWithFormat:@"_%@", @"CGPDFPage"]);
    if ([self respondsToSelector:PDFSelector] && [self performSelector:PDFSelector]) {
        return YES;
    }
    return NO;
#pragma clang diagnostic pop
}

- (FWImageFormat)fw_imageFormat
{
    NSNumber *value = objc_getAssociatedObject(self, @selector(fw_imageFormat));
    if (value) {
        return [value integerValue];
    }
    CFStringRef uttype = CGImageGetUTType(self.CGImage);
    return [NSData fw_imageFormatFromUTType:uttype];
}

- (void)setFw_imageFormat:(FWImageFormat)imageFormat
{
    objc_setAssociatedObject(self, @selector(fw_imageFormat), @(imageFormat), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark - NSData+FWAnimated

#define kSVGTagEnd @"</svg>"

@implementation NSData (FWAnimated)

+ (FWImageFormat)fw_imageFormatForImageData:(NSData *)data
{
    if (data.length < 1) {
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

+ (nonnull CFStringRef)fw_UTTypeFromImageFormat:(FWImageFormat)format
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

+ (FWImageFormat)fw_imageFormatFromUTType:(CFStringRef)uttype
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

+ (NSString *)fw_mimeTypeFromImageFormat:(FWImageFormat)format
{
    NSString *mimeType;
    switch (format) {
        case FWImageFormatJPEG:
            mimeType = @"image/jpeg";
            break;
        case FWImageFormatPNG:
            mimeType = @"image/png";
            break;
        case FWImageFormatGIF:
            mimeType = @"image/gif";
            break;
        case FWImageFormatTIFF:
            mimeType = @"image/tiff";
            break;
        case FWImageFormatWebP:
            mimeType = @"image/webp";
            break;
        case FWImageFormatHEIC:
            mimeType = @"image/heic";
            break;
        case FWImageFormatHEIF:
            mimeType = @"image/heif";
            break;
        case FWImageFormatPDF:
            mimeType = @"application/pdf";
            break;
        case FWImageFormatSVG:
            mimeType = @"image/svg+xml";
            break;
        default:
            mimeType = @"application/octet-stream";
            break;
    }
    return mimeType;
}

+ (NSString *)fw_mimeTypeFromExtension:(NSString *)extension
{
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    NSString *mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
    if (!mimeType) mimeType = @"application/octet-stream";
    return mimeType;
}

+ (NSString *)fw_base64StringForImageData:(NSData *)data
{
    if (data.length < 1) return nil;
    NSString *base64String = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    NSString *mimeType = [NSData fw_mimeTypeFromImageFormat:[NSData fw_imageFormatForImageData:data]];
    NSString *base64Prefix = [NSString stringWithFormat:@"data:%@;base64,", mimeType];
    return [base64Prefix stringByAppendingString:base64String];
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

typedef struct CF_BRIDGED_TYPE(id) CGSVGDocument *CGSVGDocumentRef;
static void (*FWCGSVGDocumentRelease)(CGSVGDocumentRef);
static CGSVGDocumentRef (*FWCGSVGDocumentCreateFromData)(CFDataRef data, CFDictionaryRef options);
static void (*FWCGSVGDocumentWriteToData)(CGSVGDocumentRef document, CFDataRef data, CFDictionaryRef options);
static SEL FWImageWithCGSVGDocumentSEL = NULL;
static SEL FWCGSVGDocumentSEL = NULL;

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

+ (void)initialize
{
    if (@available(iOS 13.0, *)) {
        FWCGSVGDocumentRelease = dlsym(RTLD_DEFAULT, [self base64DecodedString:@"Q0dTVkdEb2N1bWVudFJlbGVhc2U="].UTF8String);
        FWCGSVGDocumentCreateFromData = dlsym(RTLD_DEFAULT, [self base64DecodedString:@"Q0dTVkdEb2N1bWVudENyZWF0ZUZyb21EYXRh"].UTF8String);
        FWCGSVGDocumentWriteToData = dlsym(RTLD_DEFAULT, [self base64DecodedString:@"Q0dTVkdEb2N1bWVudFdyaXRlVG9EYXRh"].UTF8String);
        FWImageWithCGSVGDocumentSEL = NSSelectorFromString([self base64DecodedString:@"X2ltYWdlV2l0aENHU1ZHRG9jdW1lbnQ6"]);
        FWCGSVGDocumentSEL = NSSelectorFromString([self base64DecodedString:@"X0NHU1ZHRG9jdW1lbnQ="]);
    }
}

+ (NSString *)base64DecodedString:(NSString *)base64String
{
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64String options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (!data) return nil;
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (UIImage *)decodedImageWithData:(NSData *)data scale:(CGFloat)scale options:(NSDictionary<FWImageCoderOptions,id> *)options
{
    if (data.length < 1) return nil;
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (!source) return nil;
    NSNumber *scaleFactor = options[FWImageCoderOptionScaleFactor];
    if (scaleFactor != nil) scale = MAX([scaleFactor doubleValue], 1);
    
    UIImage *animatedImage;
    size_t count = CGImageSourceGetCount(source);
    FWImageFormat format = [NSData fw_imageFormatForImageData:data];
    if (format == FWImageFormatSVG) {
        if (@available(iOS 13.0, *)) {
            if ([UIImage respondsToSelector:FWImageWithCGSVGDocumentSEL]) {
                CGSVGDocumentRef document = FWCGSVGDocumentCreateFromData((__bridge CFDataRef)data, NULL);
                if (document) {
                    animatedImage = ((UIImage *(*)(id,SEL,CGSVGDocumentRef))[UIImage.class methodForSelector:FWImageWithCGSVGDocumentSEL])(UIImage.class, FWImageWithCGSVGDocumentSEL, document);
                    FWCGSVGDocumentRelease(document);
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
            FWImageFrame *frame = [[FWImageFrame alloc] initWithImage:image duration:duration];
            [frames addObject:frame];
        }
        
        NSUInteger loopCount = [self imageLoopCountWithSource:source format:format];
        animatedImage = [FWImageFrame animatedImageWithFrames:frames];
        animatedImage.fw_imageLoopCount = loopCount;
    }
    
    animatedImage.fw_imageFormat = format;
    CFRelease(source);
    return animatedImage;
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(FWImageFormat)format options:(NSDictionary<FWImageCoderOptions,id> *)options
{
    if (!image) return nil;
    if (format == FWImageFormatUndefined) {
        format = image.fw_hasAlpha ? FWImageFormatPNG : FWImageFormatJPEG;
    }
    if (format == FWImageFormatSVG) {
        if (@available(iOS 13.0, *)) {
            if ([UIImage respondsToSelector:FWImageWithCGSVGDocumentSEL]) {
                NSMutableData *data = [NSMutableData data];
                CGSVGDocumentRef document = ((CGSVGDocumentRef (*)(id,SEL))[image methodForSelector:FWCGSVGDocumentSEL])(image, FWCGSVGDocumentSEL);
                if (document) {
                    FWCGSVGDocumentWriteToData(document, (__bridge CFDataRef)data, NULL);
                    return [data copy];
                }
            }
        }
        return nil;
    }
    
    CGImageRef imageRef = image.CGImage;
    if (!imageRef) return nil;
    
    NSMutableData *imageData = [NSMutableData data];
    CFStringRef imageUTType = [NSData fw_UTTypeFromImageFormat:format];
    BOOL isAnimated = [self isAnimated:format forDecode:NO];
    NSArray<FWImageFrame *> *frames = isAnimated ? [FWImageFrame framesFromAnimatedImage:image] : nil;
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
            [self dictionaryProperty:format]: @{[self loopCountProperty:format] : @(image.fw_imageLoopCount)}
        };
        CGImageDestinationSetProperties(imageDestination, (__bridge CFDictionaryRef)containerProperties);
        
        for (size_t i = 0; i < count; i++) {
            FWImageFrame *frame = frames[i];
            CGImageRef frameImageRef = frame.image.CGImage;
            properties[[self dictionaryProperty:format]] = @{[self delayTimeProperty:format] : @(frame.duration)};
            CGImageDestinationAddImage(imageDestination, frameImageRef, (__bridge CFDictionaryRef)properties);
        }
    }
    
    if (CGImageDestinationFinalize(imageDestination) == NO) imageData = nil;
    CFRelease(imageDestination);
    return [imageData copy];
}

- (BOOL)isAnimated:(FWImageFormat)format forDecode:(BOOL)forDecode
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
    static NSSet *decodeUTTypeSet;
    static NSSet *encodeUTTypeSet;
    dispatch_once(&onceToken, ^{
        NSArray *decodeUTTypes = (__bridge_transfer NSArray *)CGImageSourceCopyTypeIdentifiers();
        decodeUTTypeSet = [NSSet setWithArray:decodeUTTypes];
        NSArray *encodeUTTypes = (__bridge_transfer NSArray *)CGImageDestinationCopyTypeIdentifiers();
        encodeUTTypeSet = [NSSet setWithArray:encodeUTTypes];
    });
    CFStringRef imageUTType = [NSData fw_UTTypeFromImageFormat:format];
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
    BOOL isVector = ([NSData fw_imageFormatFromUTType:uttype] == FWImageFormatPDF);

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
