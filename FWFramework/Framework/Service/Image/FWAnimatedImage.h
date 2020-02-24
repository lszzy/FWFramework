/*!
 @header     FWAnimatedImage.h
 @indexgroup FWFramework
 @brief      FWAnimatedImage
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/2/24
 */

#import <UIKit/UIKit.h>
#import "FWImageCoder.h"
#import "FWAnimatedImageView.h"

NS_ASSUME_NONNULL_BEGIN


/**
 A FWImage object is a high-level way to display animated image data.
 
 @discussion It is a fully compatible `UIImage` subclass. It extends the UIImage
 to support animated WebP, APNG and GIF format image data decoding. It also
 support NSCoding protocol to archive and unarchive multi-frame image data.
 
 If the image is created from multi-frame image data, and you want to play the
 animation, try replace UIImageView with `FWAnimatedImageView`.
 
 Sample Code:
 
     // animation@3x.webp
     FWImage *image = [FWImage imageNamed:@"animation.webp"];
     FWAnimatedImageView *imageView = [FWAnimatedImageView alloc] initWithImage:image];
     [view addSubView:imageView];
    
 */
@interface FWImage : UIImage <FWAnimatedImage>

+ (nullable FWImage *)imageNamed:(NSString *)name; // no cache!
+ (nullable FWImage *)imageNamed:(NSString *)name inBundle:(nullable NSBundle *)bundle; // no cache!
+ (nullable FWImage *)imageWithContentsOfFile:(NSString *)path;
+ (nullable FWImage *)imageWithData:(NSData *)data;
+ (nullable FWImage *)imageWithData:(NSData *)data scale:(CGFloat)scale;

/**
 If the image is created from data or file, then the value indicates the data type.
 */
@property (nonatomic, readonly) FWImageType animatedImageType;

/**
 If the image is created from animated image data (multi-frame GIF/APNG/WebP),
 this property stores the original image data.
 */
@property (nullable, nonatomic, readonly) NSData *animatedImageData;

/**
 The total memory usage (in bytes) if all frame images was loaded into memory.
 The value is 0 if the image is not created from a multi-frame image data.
 */
@property (nonatomic, readonly) NSUInteger animatedImageMemorySize;

/**
 Preload all frame image to memory.
 
 @discussion Set this property to `YES` will block the calling thread to decode
 all animation frame image to memory, set to `NO` will release the preloaded frames.
 If the image is shared by lots of image views (such as emoticon), preload all
 frames will reduce the CPU cost.
 
 See `animatedImageMemorySize` for memory cost.
 */
@property (nonatomic) BOOL preloadAllAnimatedImageFrames;

@end

/**
 An image to display frame-based animation.
 
 @discussion It is a fully compatible `UIImage` subclass.
 It only support system image format such as png and jpeg.
 The animation can be played by FWAnimatedImageView.
 
 Sample Code:
     
     NSArray *paths = @[@"/ani/frame1.png", @"/ani/frame2.png", @"/ani/frame3.png"];
     NSArray *times = @[@0.1, @0.2, @0.1];
     FWFrameImage *image = [FWFrameImage alloc] initWithImagePaths:paths frameDurations:times repeats:YES];
     FWAnimatedImageView *imageView = [FWAnimatedImageView alloc] initWithImage:image];
     [view addSubView:imageView];
 */
@interface FWFrameImage : UIImage <FWAnimatedImage>

/**
 Create a frame animated image from files.
 
 @param paths            An array of NSString objects, contains the full or
                         partial path to each image file.
                         e.g. @[@"/ani/1.png",@"/ani/2.png",@"/ani/3.png"]
 
 @param oneFrameDuration The duration (in seconds) per frame.
 
 @param loopCount        The animation loop count, 0 means infinite.
 
 @return An initialized FWFrameImage object, or nil when an error occurs.
 */
- (nullable instancetype)initWithImagePaths:(NSArray<NSString *> *)paths
                           oneFrameDuration:(NSTimeInterval)oneFrameDuration
                                  loopCount:(NSUInteger)loopCount;

/**
 Create a frame animated image from files.
 
 @param paths          An array of NSString objects, contains the full or
                       partial path to each image file.
                       e.g. @[@"/ani/frame1.png",@"/ani/frame2.png",@"/ani/frame3.png"]
 
 @param frameDurations An array of NSNumber objects, contains the duration (in seconds) per frame.
                       e.g. @[@0.1, @0.2, @0.3];
 
 @param loopCount      The animation loop count, 0 means infinite.
 
 @return An initialized FWFrameImage object, or nil when an error occurs.
 */
- (nullable instancetype)initWithImagePaths:(NSArray<NSString *> *)paths
                             frameDurations:(NSArray<NSNumber *> *)frameDurations
                                  loopCount:(NSUInteger)loopCount;

/**
 Create a frame animated image from an array of data.
 
 @param dataArray        An array of NSData objects.
 
 @param oneFrameDuration The duration (in seconds) per frame.
 
 @param loopCount        The animation loop count, 0 means infinite.
 
 @return An initialized FWFrameImage object, or nil when an error occurs.
 */
- (nullable instancetype)initWithImageDataArray:(NSArray<NSData *> *)dataArray
                               oneFrameDuration:(NSTimeInterval)oneFrameDuration
                                      loopCount:(NSUInteger)loopCount;

/**
 Create a frame animated image from an array of data.
 
 @param dataArray      An array of NSData objects.
 
 @param frameDurations An array of NSNumber objects, contains the duration (in seconds) per frame.
                       e.g. @[@0.1, @0.2, @0.3];
 
 @param loopCount      The animation loop count, 0 means infinite.
 
 @return An initialized FWFrameImage object, or nil when an error occurs.
 */
- (nullable instancetype)initWithImageDataArray:(NSArray<NSData *> *)dataArray
                                 frameDurations:(NSArray *)frameDurations
                                      loopCount:(NSUInteger)loopCount;

@end

/**
 An image to display sprite sheet animation.
 
 @discussion It is a fully compatible `UIImage` subclass.
 The animation can be played by FWAnimatedImageView.
 
 Sample Code:
  
    // 8 * 12 sprites in a single sheet image
    UIImage *spriteSheet = [UIImage imageNamed:@"sprite-sheet"];
    NSMutableArray *contentRects = [NSMutableArray new];
    NSMutableArray *durations = [NSMutableArray new];
    for (int j = 0; j < 12; j++) {
        for (int i = 0; i < 8; i++) {
            CGRect rect;
            rect.size = CGSizeMake(img.size.width / 8, img.size.height / 12);
            rect.origin.x = img.size.width / 8 * i;
            rect.origin.y = img.size.height / 12 * j;
            [contentRects addObject:[NSValue valueWithCGRect:rect]];
            [durations addObject:@(1 / 60.0)];
        }
    }
    FWSpriteSheetImage *sprite;
    sprite = [[FWSpriteSheetImage alloc] initWithSpriteSheetImage:img
                                                     contentRects:contentRects
                                                   frameDurations:durations
                                                        loopCount:0];
    FWAnimatedImageView *imgView = [FWAnimatedImageView new];
    imgView.size = CGSizeMake(img.size.width / 8, img.size.height / 12);
    imgView.image = sprite;
 
 
 
 @discussion It can also be used to display single frame in sprite sheet image.
 Sample Code:
 
    FWSpriteSheetImage *sheet = ...;
    UIImageView *imageView = ...;
    imageView.image = sheet;
    imageView.layer.contentsRect = [sheet contentsRectForCALayerAtIndex:6];
 
 */
@interface FWSpriteSheetImage : UIImage <FWAnimatedImage>

/**
 Creates and returns an image object.
 
 @param image          The sprite sheet image (contains all frames).
 
 @param contentRects   The sprite sheet image frame rects in the image coordinates.
     The rectangle should not outside the image's bounds. The objects in this array
     should be created with [NSValue valueWithCGRect:].
 
 @param frameDurations The sprite sheet image frame's durations in seconds.
     The objects in this array should be NSNumber.
 
 @param loopCount      Animation loop count, 0 means infinite looping.
 
 @return An image object, or nil if an error occurs.
 */
- (nullable instancetype)initWithSpriteSheetImage:(UIImage *)image
                                     contentRects:(NSArray<NSValue *> *)contentRects
                                   frameDurations:(NSArray<NSNumber *> *)frameDurations
                                        loopCount:(NSUInteger)loopCount;

@property (nonatomic, readonly) NSArray<NSValue *> *contentRects;
@property (nonatomic, readonly) NSArray<NSValue *> *frameDurations;
@property (nonatomic, readonly) NSUInteger loopCount;

/**
 Get the contents rect for CALayer.
 See "contentsRect" property in CALayer for more information.
 
 @param index Index of frame.
 @return Contents Rect.
 */
- (CGRect)contentsRectForCALayerAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
