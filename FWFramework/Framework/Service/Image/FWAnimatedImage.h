/*!
 @header     FWAnimatedImage.h
 @indexgroup FWFramework
 @brief      FWAnimatedImage
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/2/26
 */

#import "FWImageCoder.h"

@protocol SDAnimatedImage <SDAnimatedImageProvider>

@required

- (nullable instancetype)initWithData:(nonnull NSData *)data scale:(CGFloat)scale options:(nullable SDImageCoderOptions *)options;

- (nullable instancetype)initWithAnimatedCoder:(nonnull id<SDAnimatedImageCoder>)animatedCoder scale:(CGFloat)scale;

@optional

- (void)preloadAllFrames;

- (void)unloadAllFrames;

@property (nonatomic, assign, readonly, getter=isAllFramesLoaded) BOOL allFramesLoaded;

@property (nonatomic, strong, readonly, nullable) id<SDAnimatedImageCoder> animatedCoder;

@end

@interface SDAnimatedImage : UIImage <SDAnimatedImage>

// This class override these methods from UIImage(NSImage), and it supports NSSecureCoding.
// You should use these methods to create a new animated image. Use other methods just call super instead.
// Pay attention, when the animated image frame count <= 1, all the `SDAnimatedImageProvider` protocol methods will return nil or 0 value, you'd better check the frame count before usage and keep fallback.
+ (nullable instancetype)imageNamed:(nonnull NSString *)name; // Cache in memory, no Asset Catalog support
+ (nullable instancetype)imageNamed:(nonnull NSString *)name inBundle:(nullable NSBundle *)bundle; // Cache in memory, no Asset
+ (nullable instancetype)imageWithContentsOfFile:(nonnull NSString *)path;
+ (nullable instancetype)imageWithData:(nonnull NSData *)data;
+ (nullable instancetype)imageWithData:(nonnull NSData *)data scale:(CGFloat)scale;
- (nullable instancetype)initWithContentsOfFile:(nonnull NSString *)path;
- (nullable instancetype)initWithData:(nonnull NSData *)data;
- (nullable instancetype)initWithData:(nonnull NSData *)data scale:(CGFloat)scale;

/**
 Current animated image format.
 */
@property (nonatomic, assign, readonly) SDImageFormat animatedImageFormat;

/**
 Current animated image data, you can use this to grab the compressed format data and create another animated image instance.
 If this image instance is an animated image created by using animated image coder (which means using the API listed above or using `initWithAnimatedCoder:scale:`), this property is non-nil.
 */
@property (nonatomic, copy, readonly, nullable) NSData *animatedImageData;

/**
 The scale factor of the image.
 
 @note For UIKit, this just call super instead.
 @note For AppKit, `NSImage` can contains multiple image representations with different scales. However, this class does not do that from the design. We processs the scale like UIKit. This wil actually be calculated from image size and pixel size.
 */
@property (nonatomic, readonly) CGFloat scale;

// By default, animated image frames are returned by decoding just in time without keeping into memory. But you can choose to preload them into memory as well, See the decsription in `SDAnimatedImage` protocol.
// After preloaded, there is no huge difference on performance between this and UIImage's `animatedImageWithImages:duration:`. But UIImage's animation have some issues such like blanking and pausing during segue when using in `UIImageView`. It's recommend to use only if need.
- (void)preloadAllFrames;
- (void)unloadAllFrames;
@property (nonatomic, assign, readonly, getter=isAllFramesLoaded) BOOL allFramesLoaded;

@end

/**
 UIImage category for memory cache cost.
 */
@interface UIImage (MemoryCacheCost)

/**
 The memory cache cost for specify image used by image cache. The cost function is the bytes size held in memory.
 If you set some associated object to `UIImage`, you can set the custom value to indicate the memory cost.
 
 For `UIImage`, this method return the single frame bytes size when `image.images` is nil for static image. Retuen full frame bytes size when `image.images` is not nil for animated image.
 For `NSImage`, this method return the single frame bytes size because `NSImage` does not store all frames in memory.
 @note Note that because of the limitations of category this property can get out of sync if you create another instance with CGImage or other methods.
 @note For custom animated class conforms to `SDAnimatedImage`, you can override this getter method in your subclass to return a more proper value instead, which representing the current frame's total bytes.
 */
@property (assign, nonatomic) NSUInteger sd_memoryCost;

@end
