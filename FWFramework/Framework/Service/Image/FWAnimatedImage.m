/*!
 @header     FWAnimatedImage.m
 @indexgroup FWFramework
 @brief      FWAnimatedImage
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/2/24
 */

#import "FWAnimatedImage.h"

/**
 An array of NSNumber objects, shows the best order for path scale search.
 e.g. iPhone3GS:@[@1,@2,@3] iPhone5:@[@2,@3,@1]  iPhone6 Plus:@[@3,@2,@1]
 */
static NSArray *_NSBundlePreferredScales() {
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

/**
 Add scale modifier to the file name (without path extension),
 From @"name" to @"name@2x".
 
 e.g.
 <table>
 <tr><th>Before     </th><th>After(scale:2)</th></tr>
 <tr><td>"icon"     </td><td>"icon@2x"     </td></tr>
 <tr><td>"icon "    </td><td>"icon @2x"    </td></tr>
 <tr><td>"icon.top" </td><td>"icon.top@2x" </td></tr>
 <tr><td>"/p/name"  </td><td>"/p/name@2x"  </td></tr>
 <tr><td>"/path/"   </td><td>"/path/"      </td></tr>
 </table>
 
 @param scale Resource scale.
 @return String by add scale modifier, or just return if it's not end with file name.
 */
static NSString *_NSStringByAppendingNameScale(NSString *string, CGFloat scale) {
    if (!string) return nil;
    if (fabs(scale - 1) <= __FLT_EPSILON__ || string.length == 0 || [string hasSuffix:@"/"]) return string.copy;
    return [string stringByAppendingFormat:@"@%@x", @(scale)];
}

/**
 Return the path scale.
 
 e.g.
 <table>
 <tr><th>Path            </th><th>Scale </th></tr>
 <tr><td>"icon.png"      </td><td>1     </td></tr>
 <tr><td>"icon@2x.png"   </td><td>2     </td></tr>
 <tr><td>"icon@2.5x.png" </td><td>2.5   </td></tr>
 <tr><td>"icon@2x"       </td><td>1     </td></tr>
 <tr><td>"icon@2x..png"  </td><td>1     </td></tr>
 <tr><td>"icon@2x.png/"  </td><td>1     </td></tr>
 </table>
 */
static CGFloat _NSStringPathScale(NSString *string) {
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


@implementation FWImage {
    FWImageDecoder *_decoder;
    NSArray *_preloadedFrames;
    dispatch_semaphore_t _preloadedLock;
    NSUInteger _bytesPerFrame;
}

+ (FWImage *)imageNamed:(NSString *)name {
    return [self imageNamed:name inBundle:nil];
}

+ (FWImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle {
    if (name.length == 0) return nil;
    if ([name hasSuffix:@"/"]) return nil;
    
    NSString *res = name.stringByDeletingPathExtension;
    NSString *ext = name.pathExtension;
    NSString *path = nil;
    CGFloat scale = 1;
    
    // If no extension, guess by system supported (same as UIImage).
    NSArray *exts = ext.length > 0 ? @[ext] : @[@"", @"png", @"jpeg", @"jpg", @"gif", @"webp", @"apng"];
    NSArray *scales = _NSBundlePreferredScales();
    for (int s = 0; s < scales.count; s++) {
        scale = ((NSNumber *)scales[s]).floatValue;
        NSString *scaledName = _NSStringByAppendingNameScale(res, scale);
        for (NSString *e in exts) {
            path = [(bundle ? bundle : [NSBundle mainBundle]) pathForResource:scaledName ofType:e];
            if (path) break;
        }
        if (path) break;
    }
    if (path.length == 0) return nil;
    
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (data.length == 0) return nil;
    
    return [[self alloc] initWithData:data scale:scale];
}

+ (FWImage *)imageWithContentsOfFile:(NSString *)path {
    return [[self alloc] initWithContentsOfFile:path];
}

+ (FWImage *)imageWithData:(NSData *)data {
    return [[self alloc] initWithData:data];
}

+ (FWImage *)imageWithData:(NSData *)data scale:(CGFloat)scale {
    return [[self alloc] initWithData:data scale:scale];
}

- (instancetype)initWithContentsOfFile:(NSString *)path {
    NSData *data = [NSData dataWithContentsOfFile:path];
    return [self initWithData:data scale:_NSStringPathScale(path)];
}

- (instancetype)initWithData:(NSData *)data {
    return [self initWithData:data scale:1];
}

- (instancetype)initWithData:(NSData *)data scale:(CGFloat)scale {
    if (data.length == 0) return nil;
    if (scale <= 0) scale = [UIScreen mainScreen].scale;
    _preloadedLock = dispatch_semaphore_create(1);
    @autoreleasepool {
        FWImageDecoder *decoder = [FWImageDecoder decoderWithData:data scale:scale];
        FWImageFrame *frame = [decoder frameAtIndex:0 decodeForDisplay:YES];
        UIImage *image = frame.image;
        if (!image) return nil;
        self = [self initWithCGImage:image.CGImage scale:decoder.scale orientation:image.imageOrientation];
        if (!self) return nil;
        _animatedImageType = decoder.type;
        if (decoder.frameCount > 1) {
            _decoder = decoder;
            _bytesPerFrame = CGImageGetBytesPerRow(image.CGImage) * CGImageGetHeight(image.CGImage);
            _animatedImageMemorySize = _bytesPerFrame * decoder.frameCount;
        }
        self.fwIsDecodedForDisplay = YES;
    }
    return self;
}

- (NSData *)animatedImageData {
    return _decoder.data;
}

- (void)setPreloadAllAnimatedImageFrames:(BOOL)preloadAllAnimatedImageFrames {
    if (_preloadAllAnimatedImageFrames != preloadAllAnimatedImageFrames) {
        if (preloadAllAnimatedImageFrames && _decoder.frameCount > 0) {
            NSMutableArray *frames = [NSMutableArray new];
            for (NSUInteger i = 0, max = _decoder.frameCount; i < max; i++) {
                UIImage *img = [self animatedImageFrameAtIndex:i];
                if (img) {
                    [frames addObject:img];
                } else {
                    [frames addObject:[NSNull null]];
                }
            }
            dispatch_semaphore_wait(_preloadedLock, DISPATCH_TIME_FOREVER);
            _preloadedFrames = frames;
            dispatch_semaphore_signal(_preloadedLock);
        } else {
            dispatch_semaphore_wait(_preloadedLock, DISPATCH_TIME_FOREVER);
            _preloadedFrames = nil;
            dispatch_semaphore_signal(_preloadedLock);
        }
    }
}

#pragma mark - protocol NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    NSNumber *scale = [aDecoder decodeObjectForKey:@"FWImageScale"];
    NSData *data = [aDecoder decodeObjectForKey:@"FWImageData"];
    if (data.length) {
        self = [self initWithData:data scale:scale.doubleValue];
    } else {
        self = [super initWithCoder:aDecoder];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    if (_decoder.data.length) {
        [aCoder encodeObject:@(self.scale) forKey:@"FWImageScale"];
        [aCoder encodeObject:_decoder.data forKey:@"FWImageData"];
    } else {
        [super encodeWithCoder:aCoder]; // Apple use UIImagePNGRepresentation() to encode UIImage.
    }
}

+ (BOOL)supportsSecureCoding {
    return  YES;
}

#pragma mark - protocol FWAnimatedImage

- (NSUInteger)animatedImageFrameCount {
    return _decoder.frameCount;
}

- (NSUInteger)animatedImageLoopCount {
    return _decoder.loopCount;
}

- (NSUInteger)animatedImageBytesPerFrame {
    return _bytesPerFrame;
}

- (UIImage *)animatedImageFrameAtIndex:(NSUInteger)index {
    if (index >= _decoder.frameCount) return nil;
    dispatch_semaphore_wait(_preloadedLock, DISPATCH_TIME_FOREVER);
    UIImage *image = _preloadedFrames[index];
    dispatch_semaphore_signal(_preloadedLock);
    if (image) return image == (id)[NSNull null] ? nil : image;
    return [_decoder frameAtIndex:index decodeForDisplay:YES].image;
}

- (NSTimeInterval)animatedImageDurationAtIndex:(NSUInteger)index {
    NSTimeInterval duration = [_decoder frameDurationAtIndex:index];
    
    /*
     http://opensource.apple.com/source/WebCore/WebCore-7600.1.25/platform/graphics/cg/ImageSourceCG.cpp
     Many annoying ads specify a 0 duration to make an image flash as quickly as
     possible. We follow Safari and Firefox's behavior and use a duration of 100 ms
     for any frames that specify a duration of <= 10 ms.
     See <rdar://problem/7689300> and <http://webkit.org/b/36082> for more information.
     
     See also: http://nullsleep.tumblr.com/post/16524517190/animated-gif-minimum-frame-delay-browser.
     */
    if (duration < 0.011f) return 0.100f;
    return duration;
}

@end

@implementation FWFrameImage {
    NSUInteger _loopCount;
    NSUInteger _oneFrameBytes;
    NSArray *_imagePaths;
    NSArray *_imageDatas;
    NSArray *_frameDurations;
}

- (instancetype)initWithImagePaths:(NSArray *)paths oneFrameDuration:(NSTimeInterval)oneFrameDuration loopCount:(NSUInteger)loopCount {
    NSMutableArray *durations = [NSMutableArray new];
    for (int i = 0, max = (int)paths.count; i < max; i++) {
        [durations addObject:@(oneFrameDuration)];
    }
    return [self initWithImagePaths:paths frameDurations:durations loopCount:loopCount];
}

- (instancetype)initWithImagePaths:(NSArray *)paths frameDurations:(NSArray *)frameDurations loopCount:(NSUInteger)loopCount {
    if (paths.count == 0) return nil;
    if (paths.count != frameDurations.count) return nil;
    
    NSString *firstPath = paths[0];
    NSData *firstData = [NSData dataWithContentsOfFile:firstPath];
    CGFloat scale = _NSStringPathScale(firstPath);
    UIImage *firstCG = [[[UIImage alloc] initWithData:firstData] fwImageByDecoded];
    self = [self initWithCGImage:firstCG.CGImage scale:scale orientation:firstCG.imageOrientation];
    if (!self) return nil;
    long frameByte = CGImageGetBytesPerRow(firstCG.CGImage) * CGImageGetHeight(firstCG.CGImage);
    _oneFrameBytes = (NSUInteger)frameByte;
    _imagePaths = paths.copy;
    _frameDurations = frameDurations.copy;
    _loopCount = loopCount;
    
    return self;
}

- (instancetype)initWithImageDataArray:(NSArray *)dataArray oneFrameDuration:(NSTimeInterval)oneFrameDuration loopCount:(NSUInteger)loopCount {
    NSMutableArray *durations = [NSMutableArray new];
    for (int i = 0, max = (int)dataArray.count; i < max; i++) {
        [durations addObject:@(oneFrameDuration)];
    }
    return [self initWithImageDataArray:dataArray frameDurations:durations loopCount:loopCount];
}

- (instancetype)initWithImageDataArray:(NSArray *)dataArray frameDurations:(NSArray *)frameDurations loopCount:(NSUInteger)loopCount {
    if (dataArray.count == 0) return nil;
    if (dataArray.count != frameDurations.count) return nil;
    
    NSData *firstData = dataArray[0];
    CGFloat scale = [UIScreen mainScreen].scale;
    UIImage *firstCG = [[[UIImage alloc] initWithData:firstData] fwImageByDecoded];
    self = [self initWithCGImage:firstCG.CGImage scale:scale orientation:firstCG.imageOrientation];
    if (!self) return nil;
    long frameByte = CGImageGetBytesPerRow(firstCG.CGImage) * CGImageGetHeight(firstCG.CGImage);
    _oneFrameBytes = (NSUInteger)frameByte;
    _imageDatas = dataArray.copy;
    _frameDurations = frameDurations.copy;
    _loopCount = loopCount;
    
    return self;
}

#pragma mark - FWAnimtedImage

- (NSUInteger)animatedImageFrameCount {
    if (_imagePaths) {
        return _imagePaths.count;
    } else if (_imageDatas) {
        return _imageDatas.count;
    } else {
        return 1;
    }
}

- (NSUInteger)animatedImageLoopCount {
    return _loopCount;
}

- (NSUInteger)animatedImageBytesPerFrame {
    return _oneFrameBytes;
}

- (UIImage *)animatedImageFrameAtIndex:(NSUInteger)index {
    if (_imagePaths) {
        if (index >= _imagePaths.count) return nil;
        NSString *path = _imagePaths[index];
        CGFloat scale = _NSStringPathScale(path);
        NSData *data = [NSData dataWithContentsOfFile:path];
        return [[UIImage imageWithData:data scale:scale] fwImageByDecoded];
    } else if (_imageDatas) {
        if (index >= _imageDatas.count) return nil;
        NSData *data = _imageDatas[index];
        return [[UIImage imageWithData:data scale:[UIScreen mainScreen].scale] fwImageByDecoded];
    } else {
        return index == 0 ? self : nil;
    }
}

- (NSTimeInterval)animatedImageDurationAtIndex:(NSUInteger)index {
    if (index >= _frameDurations.count) return 0;
    NSNumber *num = _frameDurations[index];
    return [num doubleValue];
}

@end

@implementation FWSpriteSheetImage

- (instancetype)initWithSpriteSheetImage:(UIImage *)image
                            contentRects:(NSArray *)contentRects
                          frameDurations:(NSArray *)frameDurations
                               loopCount:(NSUInteger)loopCount {
    if (!image.CGImage) return nil;
    if (contentRects.count < 1 || frameDurations.count < 1) return nil;
    if (contentRects.count != frameDurations.count) return nil;
    
    self = [super initWithCGImage:image.CGImage scale:image.scale orientation:image.imageOrientation];
    if (!self) return nil;
    
    _contentRects = contentRects.copy;
    _frameDurations = frameDurations.copy;
    _loopCount = loopCount;
    return self;
}

- (CGRect)contentsRectForCALayerAtIndex:(NSUInteger)index {
    CGRect layerRect = CGRectMake(0, 0, 1, 1);
    if (index >= _contentRects.count) return layerRect;
    
    CGSize imageSize = self.size;
    CGRect rect = [self animatedImageContentsRectAtIndex:index];
    if (imageSize.width > 0.01 && imageSize.height > 0.01) {
        layerRect.origin.x = rect.origin.x / imageSize.width;
        layerRect.origin.y = rect.origin.y / imageSize.height;
        layerRect.size.width = rect.size.width / imageSize.width;
        layerRect.size.height = rect.size.height / imageSize.height;
        layerRect = CGRectIntersection(layerRect, CGRectMake(0, 0, 1, 1));
        if (CGRectIsNull(layerRect) || CGRectIsEmpty(layerRect)) {
            layerRect = CGRectMake(0, 0, 1, 1);
        }
    }
    return layerRect;
}

#pragma mark @protocol FWAnimatedImage

- (NSUInteger)animatedImageFrameCount {
    return _contentRects.count;
}

- (NSUInteger)animatedImageLoopCount {
    return _loopCount;
}

- (NSUInteger)animatedImageBytesPerFrame {
    return 0;
}

- (UIImage *)animatedImageFrameAtIndex:(NSUInteger)index {
    return self;
}

- (NSTimeInterval)animatedImageDurationAtIndex:(NSUInteger)index {
    if (index >= _frameDurations.count) return 0;
    return ((NSNumber *)_frameDurations[index]).doubleValue;
}

- (CGRect)animatedImageContentsRectAtIndex:(NSUInteger)index {
    if (index >= _contentRects.count) return CGRectZero;
    return ((NSValue *)_contentRects[index]).CGRectValue;
}

@end
