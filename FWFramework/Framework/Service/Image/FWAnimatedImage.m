/*!
 @header     FWAnimatedImage.m
 @indexgroup FWFramework
 @brief      FWAnimatedImage
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/2/26
 */

#import "FWAnimatedImage.h"
#import <objc/runtime.h>

#ifndef SD_LOCK
#define SD_LOCK(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#endif

#ifndef SD_UNLOCK
#define SD_UNLOCK(lock) dispatch_semaphore_signal(lock);
#endif

@interface SDImageAssetManager : NSObject

@property (nonatomic, strong, nonnull) NSMapTable<NSString *, UIImage *> *imageTable;

+ (nonnull instancetype)sharedAssetManager;
- (nullable NSString *)getPathForName:(nonnull NSString *)name bundle:(nonnull NSBundle *)bundle preferredScale:(nonnull CGFloat *)scale;
- (nullable UIImage *)imageForName:(nonnull NSString *)name;
- (void)storeImage:(nonnull UIImage *)image forName:(nonnull NSString *)name;

@end

static NSArray *SDBundlePreferredScales() {
    static NSArray *scales;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGFloat screenScale = [UIScreen mainScreen].scale;
        if (screenScale <= 1) {
            scales = @[@1,@2,@3];
        } else if (screenScale <= 2) {
            scales = @[@2,@3,@1];
        } else {
            scales = @[@3,@2,@1];
        }
    });
    return scales;
}

@implementation SDImageAssetManager {
    dispatch_semaphore_t _lock;
}

+ (instancetype)sharedAssetManager {
    static dispatch_once_t onceToken;
    static SDImageAssetManager *assetManager;
    dispatch_once(&onceToken, ^{
        assetManager = [[SDImageAssetManager alloc] init];
    });
    return assetManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSPointerFunctionsOptions valueOptions;
        // Apple says that UIImage use a strong reference to value
        valueOptions = NSPointerFunctionsStrongMemory;
        _imageTable = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsCopyIn valueOptions:valueOptions];
        _lock = dispatch_semaphore_create(1);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification {
    SD_LOCK(_lock);
    [self.imageTable removeAllObjects];
    SD_UNLOCK(_lock);
}

- (NSString *)getPathForName:(NSString *)name bundle:(NSBundle *)bundle preferredScale:(CGFloat *)scale {
    NSParameterAssert(name);
    NSParameterAssert(bundle);
    NSString *path;
    if (name.length == 0) {
        return path;
    }
    if ([name hasSuffix:@"/"]) {
        return path;
    }
    NSString *extension = name.pathExtension;
    if (extension.length == 0) {
        // If no extension, follow Apple's doc, check PNG format
        extension = @"png";
    }
    name = [name stringByDeletingPathExtension];
    
    CGFloat providedScale = *scale;
    NSArray *scales = SDBundlePreferredScales();
    
    // Check if file name contains scale
    for (size_t i = 0; i < scales.count; i++) {
        NSNumber *scaleValue = scales[i];
        if ([name hasSuffix:[NSString stringWithFormat:@"@%@x", scaleValue]]) {
            path = [bundle pathForResource:name ofType:extension];
            if (path) {
                *scale = scaleValue.doubleValue; // override
                return path;
            }
        }
    }
    
    // Search with provided scale first
    if (providedScale != 0) {
        NSString *scaledName = [name stringByAppendingFormat:@"@%@x", @(providedScale)];
        path = [bundle pathForResource:scaledName ofType:extension];
        if (path) {
            return path;
        }
    }
    
    // Search with preferred scale
    for (size_t i = 0; i < scales.count; i++) {
        NSNumber *scaleValue = scales[i];
        if (scaleValue.doubleValue == providedScale) {
            // Ignore provided scale
            continue;
        }
        NSString *scaledName = [name stringByAppendingFormat:@"@%@x", scaleValue];
        path = [bundle pathForResource:scaledName ofType:extension];
        if (path) {
            *scale = scaleValue.doubleValue; // override
            return path;
        }
    }
    
    // Search without scale
    path = [bundle pathForResource:name ofType:extension];
    
    return path;
}

- (UIImage *)imageForName:(NSString *)name {
    NSParameterAssert(name);
    UIImage *image;
    SD_LOCK(_lock);
    image = [self.imageTable objectForKey:name];
    SD_UNLOCK(_lock);
    return image;
}

- (void)storeImage:(UIImage *)image forName:(NSString *)name {
    NSParameterAssert(image);
    NSParameterAssert(name);
    SD_LOCK(_lock);
    [self.imageTable setObject:image forKey:name];
    SD_UNLOCK(_lock);
}

@end

static CGFloat SDImageScaleFromPath(NSString *string) {
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

@interface FWAnimatedImage ()

@property (nonatomic, strong) id<FWAnimatedImageCoder> animatedCoder;
@property (nonatomic, assign, readwrite) FWImageFormat animatedImageFormat;
@property (atomic, copy) NSArray<FWImageFrame *> *loadedAnimatedImageFrames; // Mark as atomic to keep thread-safe
@property (nonatomic, assign, getter=isAllFramesLoaded) BOOL allFramesLoaded;

@end

@implementation FWAnimatedImage
@dynamic scale; // call super

+ (instancetype)imageNamed:(NSString *)name {
    return [self imageNamed:name inBundle:nil];
}

+ (instancetype)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle {
    return [self imageNamed:name inBundle:bundle scale:0];
}

// 0 scale means automatically check
+ (instancetype)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle scale:(CGFloat)scale {
    if (!name) {
        return nil;
    }
    if (!bundle) {
        bundle = [NSBundle mainBundle];
    }
    SDImageAssetManager *assetManager = [SDImageAssetManager sharedAssetManager];
    FWAnimatedImage *image = (FWAnimatedImage *)[assetManager imageForName:name];
    if ([image isKindOfClass:[FWAnimatedImage class]]) {
        return image;
    }
    NSString *path = [assetManager getPathForName:name bundle:bundle preferredScale:&scale];
    if (!path) {
        return image;
    }
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data) {
        return image;
    }
    image = [[self alloc] initWithData:data scale:scale];
    if (image) {
        [assetManager storeImage:image forName:name];
    }
    
    return image;
}

+ (instancetype)imageWithContentsOfFile:(NSString *)path {
    return [[self alloc] initWithContentsOfFile:path];
}

+ (instancetype)imageWithData:(NSData *)data {
    return [[self alloc] initWithData:data];
}

+ (instancetype)imageWithData:(NSData *)data scale:(CGFloat)scale {
    return [[self alloc] initWithData:data scale:scale];
}

- (instancetype)initWithContentsOfFile:(NSString *)path {
    NSData *data = [NSData dataWithContentsOfFile:path];
    return [self initWithData:data scale:SDImageScaleFromPath(path)];
}

- (instancetype)initWithData:(NSData *)data {
    return [self initWithData:data scale:1];
}

- (instancetype)initWithData:(NSData *)data scale:(CGFloat)scale {
    return [self initWithData:data scale:scale options:nil];
}

- (instancetype)initWithData:(NSData *)data scale:(CGFloat)scale options:(FWImageCoderOptions *)options {
    if (!data || data.length == 0) {
        return nil;
    }
    data = [data copy]; // avoid mutable data
    id<FWAnimatedImageCoder> animatedCoder = nil;
    for (id<FWImageCoder>coder in [FWImageCodersManager sharedManager].coders) {
        if ([coder conformsToProtocol:@protocol(FWAnimatedImageCoder)]) {
            if ([coder canDecodeFromData:data]) {
                if (!options) {
                    options = @{FWImageCoderDecodeScaleFactor : @(scale)};
                }
                animatedCoder = [[[coder class] alloc] initWithAnimatedImageData:data options:options];
                break;
            }
        }
    }
    if (!animatedCoder) {
        return nil;
    }
    return [self initWithAnimatedCoder:animatedCoder scale:scale];
}

- (instancetype)initWithAnimatedCoder:(id<FWAnimatedImageCoder>)animatedCoder scale:(CGFloat)scale {
    if (!animatedCoder) {
        return nil;
    }
    UIImage *image = [animatedCoder animatedImageFrameAtIndex:0];
    if (!image) {
        return nil;
    }
#if SD_MAC
    self = [super initWithCGImage:image.CGImage scale:MAX(scale, 1) orientation:kCGImagePropertyOrientationUp];
#else
    self = [super initWithCGImage:image.CGImage scale:MAX(scale, 1) orientation:image.imageOrientation];
#endif
    if (self) {
        // Only keep the animated coder if frame count > 1, save RAM usage for non-animated image format (APNG/WebP)
        if (animatedCoder.animatedImageFrameCount > 1) {
            _animatedCoder = animatedCoder;
        }
        NSData *data = [animatedCoder animatedImageData];
        FWImageFormat format = [NSData fw_imageFormatForImageData:data];
        _animatedImageFormat = format;
    }
    return self;
}

#pragma mark - Preload
- (void)preloadAllFrames {
    if (!_animatedCoder) {
        return;
    }
    if (!self.isAllFramesLoaded) {
        NSMutableArray<FWImageFrame *> *frames = [NSMutableArray arrayWithCapacity:self.animatedImageFrameCount];
        for (size_t i = 0; i < self.animatedImageFrameCount; i++) {
            UIImage *image = [self animatedImageFrameAtIndex:i];
            NSTimeInterval duration = [self animatedImageDurationAtIndex:i];
            FWImageFrame *frame = [FWImageFrame frameWithImage:image duration:duration]; // through the image should be nonnull, used as nullable for `animatedImageFrameAtIndex:`
            [frames addObject:frame];
        }
        self.loadedAnimatedImageFrames = frames;
        self.allFramesLoaded = YES;
    }
}

- (void)unloadAllFrames {
    if (!_animatedCoder) {
        return;
    }
    if (self.isAllFramesLoaded) {
        self.loadedAnimatedImageFrames = nil;
        self.allFramesLoaded = NO;
    }
}

#pragma mark - NSSecureCoding
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _animatedImageFormat = [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(animatedImageFormat))];
        NSData *animatedImageData = [aDecoder decodeObjectOfClass:[NSData class] forKey:NSStringFromSelector(@selector(animatedImageData))];
        if (!animatedImageData) {
            return self;
        }
        CGFloat scale = self.scale;
        id<FWAnimatedImageCoder> animatedCoder = nil;
        for (id<FWImageCoder>coder in [FWImageCodersManager sharedManager].coders) {
            if ([coder conformsToProtocol:@protocol(FWAnimatedImageCoder)]) {
                if ([coder canDecodeFromData:animatedImageData]) {
                    animatedCoder = [[[coder class] alloc] initWithAnimatedImageData:animatedImageData options:@{FWImageCoderDecodeScaleFactor : @(scale)}];
                    break;
                }
            }
        }
        if (!animatedCoder) {
            return self;
        }
        if (animatedCoder.animatedImageFrameCount > 1) {
            _animatedCoder = animatedCoder;
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeInteger:self.animatedImageFormat forKey:NSStringFromSelector(@selector(animatedImageFormat))];
    NSData *animatedImageData = self.animatedImageData;
    if (animatedImageData) {
        [aCoder encodeObject:animatedImageData forKey:NSStringFromSelector(@selector(animatedImageData))];
    }
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

#pragma mark - FWAnimatedImageProvider

- (NSData *)animatedImageData {
    return [self.animatedCoder animatedImageData];
}

- (NSUInteger)animatedImageLoopCount {
    return [self.animatedCoder animatedImageLoopCount];
}

- (NSUInteger)animatedImageFrameCount {
    return [self.animatedCoder animatedImageFrameCount];
}

- (UIImage *)animatedImageFrameAtIndex:(NSUInteger)index {
    if (index >= self.animatedImageFrameCount) {
        return nil;
    }
    if (self.isAllFramesLoaded) {
        FWImageFrame *frame = [self.loadedAnimatedImageFrames objectAtIndex:index];
        return frame.image;
    }
    return [self.animatedCoder animatedImageFrameAtIndex:index];
}

- (NSTimeInterval)animatedImageDurationAtIndex:(NSUInteger)index {
    if (index >= self.animatedImageFrameCount) {
        return 0;
    }
    if (self.isAllFramesLoaded) {
        FWImageFrame *frame = [self.loadedAnimatedImageFrames objectAtIndex:index];
        return frame.duration;
    }
    return [self.animatedCoder animatedImageDurationAtIndex:index];
}

@end

FOUNDATION_STATIC_INLINE NSUInteger SDMemoryCacheCostForImage(UIImage *image) {
    CGImageRef imageRef = image.CGImage;
    if (!imageRef) {
        return 0;
    }
    NSUInteger bytesPerFrame = CGImageGetBytesPerRow(imageRef) * CGImageGetHeight(imageRef);
    NSUInteger frameCount;
    frameCount = image.images.count > 0 ? image.images.count : 1;
    NSUInteger cost = bytesPerFrame * frameCount;
    return cost;
}

@implementation UIImage (MemoryCacheCost)

- (NSUInteger)fw_memoryCost {
    NSNumber *value = objc_getAssociatedObject(self, @selector(fw_memoryCost));
    NSUInteger memoryCost;
    if (value != nil) {
        memoryCost = [value unsignedIntegerValue];
    } else {
        memoryCost = SDMemoryCacheCostForImage(self);
    }
    return memoryCost;
}

- (void)setSd_memoryCost:(NSUInteger)fw_memoryCost {
    objc_setAssociatedObject(self, @selector(fw_memoryCost), @(fw_memoryCost), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation FWAnimatedImage (MemoryCacheCost)

- (NSUInteger)fw_memoryCost {
    NSNumber *value = objc_getAssociatedObject(self, @selector(fw_memoryCost));
    if (value != nil) {
        return value.unsignedIntegerValue;
    }
    
    CGImageRef imageRef = self.CGImage;
    if (!imageRef) {
        return 0;
    }
    NSUInteger bytesPerFrame = CGImageGetBytesPerRow(imageRef) * CGImageGetHeight(imageRef);
    NSUInteger frameCount = 1;
    if (self.isAllFramesLoaded) {
        frameCount = self.animatedImageFrameCount;
    }
    frameCount = frameCount > 0 ? frameCount : 1;
    NSUInteger cost = bytesPerFrame * frameCount;
    return cost;
}

@end
