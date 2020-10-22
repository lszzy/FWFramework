/*!
 @header     FWImagePlugin.m
 @indexgroup FWFramework
 @brief      FWImagePlugin
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/7
 */

#import "FWImagePlugin.h"
#import "FWHTTPSessionManager.h"
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

#pragma mark - FWAutoPurgingImageCache

@interface FWCachedImage : NSObject

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, assign) UInt64 totalBytes;
@property (nonatomic, strong) NSDate *lastAccessDate;
@property (nonatomic, assign) UInt64 currentMemoryUsage;

@end

@implementation FWCachedImage

- (instancetype)initWithImage:(UIImage *)image identifier:(NSString *)identifier {
    if (self = [self init]) {
        self.image = image;
        self.identifier = identifier;

        CGSize imageSize = CGSizeMake(image.size.width * image.scale, image.size.height * image.scale);
        CGFloat bytesPerPixel = 4.0;
        CGFloat bytesPerSize = imageSize.width * imageSize.height;
        self.totalBytes = (UInt64)bytesPerPixel * (UInt64)bytesPerSize;
        self.lastAccessDate = [NSDate date];
    }
    return self;
}

- (UIImage *)accessImage {
    self.lastAccessDate = [NSDate date];
    return self.image;
}

- (NSString *)description {
    NSString *descriptionString = [NSString stringWithFormat:@"Idenfitier: %@  lastAccessDate: %@ ", self.identifier, self.lastAccessDate];
    return descriptionString;

}

@end

@interface FWAutoPurgingImageCache ()
@property (nonatomic, strong) NSMutableDictionary <NSString* , FWCachedImage*> *cachedImages;
@property (nonatomic, assign) UInt64 currentMemoryUsage;
@property (nonatomic, strong) dispatch_queue_t synchronizationQueue;
@end

@implementation FWAutoPurgingImageCache

- (instancetype)init {
    return [self initWithMemoryCapacity:100 * 1024 * 1024 preferredMemoryCapacity:60 * 1024 * 1024];
}

- (instancetype)initWithMemoryCapacity:(UInt64)memoryCapacity preferredMemoryCapacity:(UInt64)preferredMemoryCapacity {
    if (self = [super init]) {
        self.memoryCapacity = memoryCapacity;
        self.preferredMemoryUsageAfterPurge = preferredMemoryCapacity;
        self.cachedImages = [[NSMutableDictionary alloc] init];

        NSString *queueName = [NSString stringWithFormat:@"site.wuyong.autopurgingimagecache-%@", [[NSUUID UUID] UUIDString]];
        self.synchronizationQueue = dispatch_queue_create([queueName cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);

        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(removeAllImages)
         name:UIApplicationDidReceiveMemoryWarningNotification
         object:nil];

    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UInt64)memoryUsage {
    __block UInt64 result = 0;
    dispatch_sync(self.synchronizationQueue, ^{
        result = self.currentMemoryUsage;
    });
    return result;
}

- (void)addImage:(UIImage *)image withIdentifier:(NSString *)identifier {
    dispatch_barrier_async(self.synchronizationQueue, ^{
        FWCachedImage *cacheImage = [[FWCachedImage alloc] initWithImage:image identifier:identifier];

        FWCachedImage *previousCachedImage = self.cachedImages[identifier];
        if (previousCachedImage != nil) {
            self.currentMemoryUsage -= previousCachedImage.totalBytes;
        }

        self.cachedImages[identifier] = cacheImage;
        self.currentMemoryUsage += cacheImage.totalBytes;
    });

    dispatch_barrier_async(self.synchronizationQueue, ^{
        if (self.currentMemoryUsage > self.memoryCapacity) {
            UInt64 bytesToPurge = self.currentMemoryUsage - self.preferredMemoryUsageAfterPurge;
            NSMutableArray <FWCachedImage*> *sortedImages = [NSMutableArray arrayWithArray:self.cachedImages.allValues];
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastAccessDate"
                                                                           ascending:YES];
            [sortedImages sortUsingDescriptors:@[sortDescriptor]];

            UInt64 bytesPurged = 0;

            for (FWCachedImage *cachedImage in sortedImages) {
                [self.cachedImages removeObjectForKey:cachedImage.identifier];
                bytesPurged += cachedImage.totalBytes;
                if (bytesPurged >= bytesToPurge) {
                    break;
                }
            }
            self.currentMemoryUsage -= bytesPurged;
        }
    });
}

- (BOOL)removeImageWithIdentifier:(NSString *)identifier {
    __block BOOL removed = NO;
    dispatch_barrier_sync(self.synchronizationQueue, ^{
        FWCachedImage *cachedImage = self.cachedImages[identifier];
        if (cachedImage != nil) {
            [self.cachedImages removeObjectForKey:identifier];
            self.currentMemoryUsage -= cachedImage.totalBytes;
            removed = YES;
        }
    });
    return removed;
}

- (BOOL)removeAllImages {
    __block BOOL removed = NO;
    dispatch_barrier_sync(self.synchronizationQueue, ^{
        if (self.cachedImages.count > 0) {
            [self.cachedImages removeAllObjects];
            self.currentMemoryUsage = 0;
            removed = YES;
        }
    });
    return removed;
}

- (nullable UIImage *)imageWithIdentifier:(NSString *)identifier {
    __block UIImage *image = nil;
    dispatch_sync(self.synchronizationQueue, ^{
        FWCachedImage *cachedImage = self.cachedImages[identifier];
        image = [cachedImage accessImage];
    });
    return image;
}

- (void)addImage:(UIImage *)image forRequest:(NSURLRequest *)request withAdditionalIdentifier:(NSString *)identifier {
    [self addImage:image withIdentifier:[self imageCacheKeyFromURLRequest:request withAdditionalIdentifier:identifier]];
}

- (BOOL)removeImageforRequest:(NSURLRequest *)request withAdditionalIdentifier:(NSString *)identifier {
    return [self removeImageWithIdentifier:[self imageCacheKeyFromURLRequest:request withAdditionalIdentifier:identifier]];
}

- (nullable UIImage *)imageforRequest:(NSURLRequest *)request withAdditionalIdentifier:(NSString *)identifier {
    return [self imageWithIdentifier:[self imageCacheKeyFromURLRequest:request withAdditionalIdentifier:identifier]];
}

- (NSString *)imageCacheKeyFromURLRequest:(NSURLRequest *)request withAdditionalIdentifier:(NSString *)additionalIdentifier {
    NSString *key = request.URL.absoluteString;
    if (additionalIdentifier != nil) {
        key = [key stringByAppendingString:additionalIdentifier];
    }
    return key;
}

- (BOOL)shouldCacheImage:(UIImage *)image forRequest:(NSURLRequest *)request withAdditionalIdentifier:(nullable NSString *)identifier {
    return YES;
}

@end

#pragma mark - FWImageDownloader

@interface FWImageDownloaderResponseHandler : NSObject
@property (nonatomic, strong) NSUUID *uuid;
@property (nonatomic, copy) void (^successBlock)(NSURLRequest *, NSHTTPURLResponse *, UIImage *);
@property (nonatomic, copy) void (^failureBlock)(NSURLRequest *, NSHTTPURLResponse *, NSError *);
@property (nonatomic, copy) void (^progressBlock)(NSProgress *);
@end

@implementation FWImageDownloaderResponseHandler

- (instancetype)initWithUUID:(NSUUID *)uuid
                     success:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, UIImage *responseObject))success
                     failure:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, NSError *error))failure
                    progress:(nullable void (^)(NSProgress *downloadProgress))progress {
    if (self = [self init]) {
        self.uuid = uuid;
        self.successBlock = success;
        self.failureBlock = failure;
        self.progressBlock = progress;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"<FWImageDownloaderResponseHandler>UUID: %@", [self.uuid UUIDString]];
}

@end

@interface FWImageDownloaderMergedTask : NSObject
@property (nonatomic, strong) NSString *URLIdentifier;
@property (nonatomic, strong) NSUUID *identifier;
@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (nonatomic, strong) NSMutableArray <FWImageDownloaderResponseHandler*> *responseHandlers;

@end

@implementation FWImageDownloaderMergedTask

- (instancetype)initWithURLIdentifier:(NSString *)URLIdentifier identifier:(NSUUID *)identifier task:(NSURLSessionDataTask *)task {
    if (self = [self init]) {
        self.URLIdentifier = URLIdentifier;
        self.task = task;
        self.identifier = identifier;
        self.responseHandlers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addResponseHandler:(FWImageDownloaderResponseHandler *)handler {
    [self.responseHandlers addObject:handler];
}

- (void)removeResponseHandler:(FWImageDownloaderResponseHandler *)handler {
    [self.responseHandlers removeObject:handler];
}

@end

@implementation FWImageDownloadReceipt

- (instancetype)initWithReceiptID:(NSUUID *)receiptID task:(NSURLSessionDataTask *)task {
    if (self = [self init]) {
        self.receiptID = receiptID;
        self.task = task;
    }
    return self;
}

@end

@interface FWImageDownloader ()

@property (nonatomic, strong) dispatch_queue_t synchronizationQueue;
@property (nonatomic, strong) dispatch_queue_t responseQueue;

@property (nonatomic, assign) NSInteger maximumActiveDownloads;
@property (nonatomic, assign) NSInteger activeRequestCount;

@property (nonatomic, strong) NSMutableArray *queuedMergedTasks;
@property (nonatomic, strong) NSMutableDictionary *mergedTasks;

@end

@implementation FWImageDownloader

+ (NSURLCache *)defaultURLCache {
    NSUInteger memoryCapacity = 20 * 1024 * 1024; // 20MB
    NSUInteger diskCapacity = 150 * 1024 * 1024; // 150MB
    NSURL *cacheURL = [[[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory
                                                              inDomain:NSUserDomainMask
                                                     appropriateForURL:nil
                                                                create:YES
                                                                 error:nil]
                       URLByAppendingPathComponent:@"site.wuyong.imagedownloader"];

    return [[NSURLCache alloc] initWithMemoryCapacity:memoryCapacity
                                         diskCapacity:diskCapacity
                                             diskPath:[cacheURL path]];
}

+ (NSURLSessionConfiguration *)defaultURLSessionConfiguration {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];

    //TODO set the default HTTP headers

    configuration.HTTPShouldSetCookies = YES;
    configuration.HTTPShouldUsePipelining = NO;

    configuration.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
    configuration.allowsCellularAccess = YES;
    configuration.timeoutIntervalForRequest = 60.0;
    configuration.URLCache = [FWImageDownloader defaultURLCache];

    return configuration;
}

- (instancetype)init {
    NSURLSessionConfiguration *defaultConfiguration = [self.class defaultURLSessionConfiguration];
    return [self initWithSessionConfiguration:defaultConfiguration];
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration {
    FWHTTPSessionManager *sessionManager = [[FWHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
    sessionManager.responseSerializer = [FWImageResponseSerializer serializer];

    return [self initWithSessionManager:sessionManager
                 downloadPrioritization:FWImageDownloadPrioritizationFIFO
                 maximumActiveDownloads:4
                             imageCache:[[FWAutoPurgingImageCache alloc] init]];
}

- (instancetype)initWithSessionManager:(FWHTTPSessionManager *)sessionManager
                downloadPrioritization:(FWImageDownloadPrioritization)downloadPrioritization
                maximumActiveDownloads:(NSInteger)maximumActiveDownloads
                            imageCache:(id <FWImageRequestCache>)imageCache {
    if (self = [super init]) {
        self.sessionManager = sessionManager;

        self.downloadPrioritization = downloadPrioritization;
        self.maximumActiveDownloads = maximumActiveDownloads;
        self.imageCache = imageCache;

        self.queuedMergedTasks = [[NSMutableArray alloc] init];
        self.mergedTasks = [[NSMutableDictionary alloc] init];
        self.activeRequestCount = 0;

        NSString *name = [NSString stringWithFormat:@"site.wuyong.imagedownloader.synchronizationqueue-%@", [[NSUUID UUID] UUIDString]];
        self.synchronizationQueue = dispatch_queue_create([name cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);

        name = [NSString stringWithFormat:@"site.wuyong.imagedownloader.responsequeue-%@", [[NSUUID UUID] UUIDString]];
        self.responseQueue = dispatch_queue_create([name cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);
    }

    return self;
}

+ (instancetype)defaultInstance {
    static FWImageDownloader *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (nullable FWImageDownloadReceipt *)downloadImageForURLRequest:(NSURLRequest *)request
                                                        success:(void (^)(NSURLRequest * _Nonnull, NSHTTPURLResponse * _Nullable, UIImage * _Nonnull))success
                                                        failure:(void (^)(NSURLRequest * _Nonnull, NSHTTPURLResponse * _Nullable, NSError * _Nonnull))failure
                                                       progress:(nullable void (^)(NSProgress * _Nonnull))progress {
    return [self downloadImageForURLRequest:request withReceiptID:[NSUUID UUID] success:success failure:failure progress:progress];
}

- (nullable FWImageDownloadReceipt *)downloadImageForURLRequest:(NSURLRequest *)request
                                                  withReceiptID:(nonnull NSUUID *)receiptID
                                                        success:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse  * _Nullable response, UIImage *responseObject))success
                                                        failure:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, NSError *error))failure
                                                       progress:(nullable void (^)(NSProgress * _Nonnull))progress {
    __block NSURLSessionDataTask *task = nil;
    dispatch_sync(self.synchronizationQueue, ^{
        NSString *URLIdentifier = request.URL.absoluteString;
        if (URLIdentifier == nil) {
            if (failure) {
                NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(request, nil, error);
                });
            }
            return;
        }

        // 1) Append the success and failure blocks to a pre-existing request if it already exists
        FWImageDownloaderMergedTask *existingMergedTask = self.mergedTasks[URLIdentifier];
        if (existingMergedTask != nil) {
            FWImageDownloaderResponseHandler *handler = [[FWImageDownloaderResponseHandler alloc] initWithUUID:receiptID success:success failure:failure progress:progress];
            [existingMergedTask addResponseHandler:handler];
            task = existingMergedTask.task;
            return;
        }

        // 2) Attempt to load the image from the image cache if the cache policy allows it
        switch (request.cachePolicy) {
            case NSURLRequestUseProtocolCachePolicy:
            case NSURLRequestReturnCacheDataElseLoad:
            case NSURLRequestReturnCacheDataDontLoad: {
                UIImage *cachedImage = [self.imageCache imageforRequest:request withAdditionalIdentifier:nil];
                if (cachedImage != nil) {
                    if (success) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            success(request, nil, cachedImage);
                        });
                    }
                    return;
                }
                break;
            }
            default:
                break;
        }

        // 3) Create the request and set up authentication, validation and response serialization
        NSUUID *mergedTaskIdentifier = [NSUUID UUID];
        NSURLSessionDataTask *createdTask;
        __weak __typeof__(self) weakSelf = self;

        createdTask = [self.sessionManager
                       dataTaskWithRequest:request
                       uploadProgress:nil
                       downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
                           dispatch_async(self.responseQueue, ^{
                               __strong __typeof__(weakSelf) strongSelf = weakSelf;
                               FWImageDownloaderMergedTask *mergedTask = [strongSelf safelyGetMergedTask:URLIdentifier];
                               if ([mergedTask.identifier isEqual:mergedTaskIdentifier]) {
                                   mergedTask = [strongSelf safelyGetMergedTask:URLIdentifier];
                                   NSArray *responseHandlers = [mergedTask.responseHandlers copy];
                                   for (FWImageDownloaderResponseHandler *handler in responseHandlers) {
                                       if (handler.progressBlock) {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               handler.progressBlock(downloadProgress);
                                           });
                                       }
                                   }
                               }
                           });
                       }
                       completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                           dispatch_async(self.responseQueue, ^{
                               __strong __typeof__(weakSelf) strongSelf = weakSelf;
                               FWImageDownloaderMergedTask *mergedTask = [strongSelf safelyGetMergedTask:URLIdentifier];
                               if ([mergedTask.identifier isEqual:mergedTaskIdentifier]) {
                                   mergedTask = [strongSelf safelyRemoveMergedTaskWithURLIdentifier:URLIdentifier];
                                   if (error) {
                                       for (FWImageDownloaderResponseHandler *handler in mergedTask.responseHandlers) {
                                           if (handler.failureBlock) {
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   handler.failureBlock(request, (NSHTTPURLResponse *)response, error);
                                               });
                                           }
                                       }
                                   } else {
                                       if ([strongSelf.imageCache shouldCacheImage:responseObject forRequest:request withAdditionalIdentifier:nil]) {
                                           [strongSelf.imageCache addImage:responseObject forRequest:request withAdditionalIdentifier:nil];
                                       }

                                       for (FWImageDownloaderResponseHandler *handler in mergedTask.responseHandlers) {
                                           if (handler.successBlock) {
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   handler.successBlock(request, (NSHTTPURLResponse *)response, responseObject);
                                               });
                                           }
                                       }
                                       
                                   }
                               }
                               [strongSelf safelyDecrementActiveTaskCount];
                               [strongSelf safelyStartNextTaskIfNecessary];
                           });
                       }];

        // 4) Store the response handler for use when the request completes
        FWImageDownloaderResponseHandler *handler = [[FWImageDownloaderResponseHandler alloc] initWithUUID:receiptID
                                                                                                   success:success
                                                                                                   failure:failure
                                                                                                  progress:progress];
        FWImageDownloaderMergedTask *mergedTask = [[FWImageDownloaderMergedTask alloc]
                                                   initWithURLIdentifier:URLIdentifier
                                                   identifier:mergedTaskIdentifier
                                                   task:createdTask];
        [mergedTask addResponseHandler:handler];
        self.mergedTasks[URLIdentifier] = mergedTask;

        // 5) Either start the request or enqueue it depending on the current active request count
        if ([self isActiveRequestCountBelowMaximumLimit]) {
            [self startMergedTask:mergedTask];
        } else {
            [self enqueueMergedTask:mergedTask];
        }

        task = mergedTask.task;
    });
    if (task) {
        return [[FWImageDownloadReceipt alloc] initWithReceiptID:receiptID task:task];
    } else {
        return nil;
    }
}

- (void)cancelTaskForImageDownloadReceipt:(FWImageDownloadReceipt *)imageDownloadReceipt {
    dispatch_sync(self.synchronizationQueue, ^{
        NSString *URLIdentifier = imageDownloadReceipt.task.originalRequest.URL.absoluteString;
        FWImageDownloaderMergedTask *mergedTask = self.mergedTasks[URLIdentifier];
        NSUInteger index = [mergedTask.responseHandlers indexOfObjectPassingTest:^BOOL(FWImageDownloaderResponseHandler * _Nonnull handler, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
            return handler.uuid == imageDownloadReceipt.receiptID;
        }];

        if (index != NSNotFound) {
            FWImageDownloaderResponseHandler *handler = mergedTask.responseHandlers[index];
            [mergedTask removeResponseHandler:handler];
            NSString *failureReason = [NSString stringWithFormat:@"ImageDownloader cancelled URL request: %@",imageDownloadReceipt.task.originalRequest.URL.absoluteString];
            NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey:failureReason};
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:userInfo];
            if (handler.failureBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler.failureBlock(imageDownloadReceipt.task.originalRequest, nil, error);
                });
            }
        }

        if (mergedTask.responseHandlers.count == 0) {
            [mergedTask.task cancel];
            [self removeMergedTaskWithURLIdentifier:URLIdentifier];
        }
    });
}

- (FWImageDownloaderMergedTask *)safelyRemoveMergedTaskWithURLIdentifier:(NSString *)URLIdentifier {
    __block FWImageDownloaderMergedTask *mergedTask = nil;
    dispatch_sync(self.synchronizationQueue, ^{
        mergedTask = [self removeMergedTaskWithURLIdentifier:URLIdentifier];
    });
    return mergedTask;
}

//This method should only be called from safely within the synchronizationQueue
- (FWImageDownloaderMergedTask *)removeMergedTaskWithURLIdentifier:(NSString *)URLIdentifier {
    FWImageDownloaderMergedTask *mergedTask = self.mergedTasks[URLIdentifier];
    [self.mergedTasks removeObjectForKey:URLIdentifier];
    return mergedTask;
}

- (void)safelyDecrementActiveTaskCount {
    dispatch_sync(self.synchronizationQueue, ^{
        if (self.activeRequestCount > 0) {
            self.activeRequestCount -= 1;
        }
    });
}

- (void)safelyStartNextTaskIfNecessary {
    dispatch_sync(self.synchronizationQueue, ^{
        if ([self isActiveRequestCountBelowMaximumLimit]) {
            while (self.queuedMergedTasks.count > 0) {
                FWImageDownloaderMergedTask *mergedTask = [self dequeueMergedTask];
                if (mergedTask.task.state == NSURLSessionTaskStateSuspended) {
                    [self startMergedTask:mergedTask];
                    break;
                }
            }
        }
    });
}

- (void)startMergedTask:(FWImageDownloaderMergedTask *)mergedTask {
    [mergedTask.task resume];
    ++self.activeRequestCount;
}

- (void)enqueueMergedTask:(FWImageDownloaderMergedTask *)mergedTask {
    switch (self.downloadPrioritization) {
        case FWImageDownloadPrioritizationFIFO:
            [self.queuedMergedTasks addObject:mergedTask];
            break;
        case FWImageDownloadPrioritizationLIFO:
            [self.queuedMergedTasks insertObject:mergedTask atIndex:0];
            break;
    }
}

- (FWImageDownloaderMergedTask *)dequeueMergedTask {
    FWImageDownloaderMergedTask *mergedTask = nil;
    mergedTask = [self.queuedMergedTasks firstObject];
    [self.queuedMergedTasks removeObject:mergedTask];
    return mergedTask;
}

- (BOOL)isActiveRequestCountBelowMaximumLimit {
    return self.activeRequestCount < self.maximumActiveDownloads;
}

- (FWImageDownloaderMergedTask *)safelyGetMergedTask:(NSString *)URLIdentifier {
    __block FWImageDownloaderMergedTask *mergedTask;
    dispatch_sync(self.synchronizationQueue, ^(){
        mergedTask = self.mergedTasks[URLIdentifier];
    });
    return mergedTask;
}

@end

#pragma mark - UIImageView+FWNetwork

@implementation UIImageView (FWNetwork)

+ (FWImageDownloader *)fwSharedImageDownloader
{
    return objc_getAssociatedObject([UIImageView class], @selector(fwSharedImageDownloader)) ?: [FWImageDownloader defaultInstance];
}

+ (void)setFwSharedImageDownloader:(FWImageDownloader *)imageDownloader
{
    objc_setAssociatedObject([UIImageView class], @selector(fwSharedImageDownloader), imageDownloader, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

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

- (FWImageDownloadReceipt *)fwActiveImageDownloadReceipt
{
    return (FWImageDownloadReceipt *)objc_getAssociatedObject(self, @selector(fwActiveImageDownloadReceipt));
}

- (void)setFwActiveImageDownloadReceipt:(FWImageDownloadReceipt *)imageDownloadReceipt
{
    objc_setAssociatedObject(self, @selector(fwActiveImageDownloadReceipt), imageDownloadReceipt, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
         placeholderImage:(nullable UIImage *)placeholderImage
               completion:(nullable void (^)(UIImage * _Nullable, NSError * _Nullable))completion
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
        return;
    }
    
    NSURLRequest *urlRequest = nil;
    if ([url isKindOfClass:[NSURLRequest class]]) {
        urlRequest = url;
    } else {
        NSURL *nsurl = nil;
        if ([url isKindOfClass:[NSURL class]]) {
            nsurl = url;
        } else if ([url isKindOfClass:[NSString class]]) {
            nsurl = [NSURL URLWithString:url];
            if (!nsurl && [url length] > 0) {
                nsurl = [NSURL URLWithString:[url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
            }
        }
        
        urlRequest = [NSMutableURLRequest requestWithURL:nsurl];
        [(NSMutableURLRequest *)urlRequest addValue:@"image/*,*/*;q=0.8" forHTTPHeaderField:@"Accept"];
    }
    
    if ([urlRequest URL] == nil) {
        self.image = placeholderImage;
        if (completion) {
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil];
            completion(nil, error);
        }
        return;
    }
    
    if ([self isActiveTaskURLEqualToURLRequest:urlRequest]) {
        return;
    }
    
    [self fwCancelImageDownloadTask];

    FWImageDownloader *downloader = [[self class] fwSharedImageDownloader];
    id <FWImageRequestCache> imageCache = downloader.imageCache;

    //Use the image from the image cache if it exists
    UIImage *cachedImage = [imageCache imageforRequest:urlRequest withAdditionalIdentifier:nil];
    if (cachedImage) {
        if (completion) {
            completion(cachedImage, nil);
        } else {
            self.image = cachedImage;
        }
        [self clearActiveDownloadInformation];
    } else {
        if (placeholderImage) {
            self.image = placeholderImage;
        }

        __weak __typeof(self)weakSelf = self;
        NSUUID *downloadID = [NSUUID UUID];
        FWImageDownloadReceipt *receipt;
        receipt = [downloader
                   downloadImageForURLRequest:urlRequest
                   withReceiptID:downloadID
                   success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
                       __strong __typeof(weakSelf)strongSelf = weakSelf;
                       if ([strongSelf.fwActiveImageDownloadReceipt.receiptID isEqual:downloadID]) {
                           if (completion) {
                               completion(responseObject, nil);
                           } else if (responseObject) {
                               strongSelf.image = responseObject;
                           }
                           [strongSelf clearActiveDownloadInformation];
                       }
                   }
                   failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
                       __strong __typeof(weakSelf)strongSelf = weakSelf;
                        if ([strongSelf.fwActiveImageDownloadReceipt.receiptID isEqual:downloadID]) {
                            if (completion) {
                                completion(nil, error);
                            }
                            [strongSelf clearActiveDownloadInformation];
                        }
                   }
                   progress:(progress ? ^(NSProgress * _Nonnull downloadProgress) {
                       __strong __typeof(weakSelf)strongSelf = weakSelf;
                       if ([strongSelf.fwActiveImageDownloadReceipt.receiptID isEqual:downloadID]) {
                           progress(downloadProgress.fractionCompleted);
                       }
                   } : nil)];

        self.fwActiveImageDownloadReceipt = receipt;
    }
}

- (void)fwCancelImageDownloadTask
{
    if (self.fwActiveImageDownloadReceipt != nil) {
        [[self.class fwSharedImageDownloader] cancelTaskForImageDownloadReceipt:self.fwActiveImageDownloadReceipt];
        [self clearActiveDownloadInformation];
     }
}

- (void)clearActiveDownloadInformation
{
    self.fwActiveImageDownloadReceipt = nil;
}

- (BOOL)isActiveTaskURLEqualToURLRequest:(NSURLRequest *)urlRequest
{
    return [self.fwActiveImageDownloadReceipt.task.originalRequest.URL.absoluteString isEqualToString:urlRequest.URL.absoluteString];
}

@end

#pragma mark - FWSDWebImagePlugin

#if FWCOMPONENT_SDWEBIMAGE_ENABLED

@import SDWebImage;

@implementation FWSDWebImagePlugin

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[FWPluginManager sharedInstance] registerDefault:@protocol(FWImagePlugin) withObject:[FWSDWebImagePlugin class]];
    });
}

+ (FWSDWebImagePlugin *)sharedInstance
{
    static FWSDWebImagePlugin *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWSDWebImagePlugin alloc] init];
    });
    return instance;
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
                          options:0
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

@end

#endif
