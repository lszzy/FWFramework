/*!
 @header     FWImageCoder.h
 @indexgroup FWFramework
 @brief      FWImageCoder
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/2/26
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// 图片类型枚举，可动态扩展
typedef NSInteger FWImageFormat NS_TYPED_EXTENSIBLE_ENUM;
static const FWImageFormat FWImageFormatUndefined = -1;
static const FWImageFormat FWImageFormatJPEG      = 0;
static const FWImageFormat FWImageFormatPNG       = 1;
static const FWImageFormat FWImageFormatGIF       = 2;
static const FWImageFormat FWImageFormatTIFF      = 3;
static const FWImageFormat FWImageFormatWebP      = 4;
static const FWImageFormat FWImageFormatHEIC      = 5;
static const FWImageFormat FWImageFormatHEIF      = 6;

// 图片解码器选项，可动态扩展
typedef NSString * FWImageCoderOption NS_STRING_ENUM;
typedef NSDictionary<FWImageCoderOption, id> FWImageCoderOptions;
FOUNDATION_EXPORT FWImageCoderOption _Nonnull const FWImageCoderDecodeFirstFrameOnly;
FOUNDATION_EXPORT FWImageCoderOption _Nonnull const FWImageCoderDecodeScaleFactor;
FOUNDATION_EXPORT FWImageCoderOption _Nonnull const FWImageCoderEncodeFirstFrameOnly;
FOUNDATION_EXPORT FWImageCoderOption _Nonnull const FWImageCoderEncodeCompressionQuality;

// 图片编码器协议
@protocol FWImageCoder <NSObject>

@required

- (BOOL)canDecodeFromData:(nullable NSData *)data;
- (nullable UIImage *)decodedImageWithData:(nullable NSData *)data options:(nullable FWImageCoderOptions *)options;

- (BOOL)canEncodeToFormat:(FWImageFormat)format;
- (nullable NSData *)encodedDataWithImage:(nullable UIImage *)image format:(FWImageFormat)format options:(nullable FWImageCoderOptions *)options;

@end

@protocol FWAnimatedImageProvider <NSObject>

@required

@property (nonatomic, copy, readonly, nullable) NSData *animatedImageData;

@property (nonatomic, assign, readonly) NSUInteger animatedImageFrameCount;

@property (nonatomic, assign, readonly) NSUInteger animatedImageLoopCount;

- (nullable UIImage *)animatedImageFrameAtIndex:(NSUInteger)index;

- (NSTimeInterval)animatedImageDurationAtIndex:(NSUInteger)index;

@end

@protocol FWAnimatedImageCoder <FWImageCoder, FWAnimatedImageProvider>

@required

- (nullable instancetype)initWithAnimatedImageData:(nullable NSData *)data options:(nullable FWImageCoderOptions *)options;

@end

@protocol FWProgressiveImageCoder <FWImageCoder>

@required

- (BOOL)canIncrementalDecodeFromData:(nullable NSData *)data;

- (nonnull instancetype)initIncrementalWithOptions:(nullable FWImageCoderOptions *)options;

- (void)updateIncrementalData:(nullable NSData *)data finished:(BOOL)finished;

- (nullable UIImage *)incrementalDecodedImageWithOptions:(nullable FWImageCoderOptions *)options;

@end

@interface FWImageCodersManager : NSObject <FWImageCoder>

@property (nonatomic, class, readonly, nonnull) FWImageCodersManager *sharedManager;

@property (nonatomic, copy, nullable) NSArray<id<FWImageCoder>> *coders;

- (void)addCoder:(nonnull id<FWImageCoder>)coder;

- (void)removeCoder:(nonnull id<FWImageCoder>)coder;

@end

#pragma mark - Coder

@interface FWImageIOCoder : NSObject <FWProgressiveImageCoder>

@property (nonatomic, class, readonly, nonnull) FWImageIOCoder *sharedCoder;

@end

@interface FWImageIOAnimatedCoder : NSObject <FWProgressiveImageCoder, FWAnimatedImageCoder>

#pragma mark - Subclass Override
/**
 The supported animated image format. Such as `FWImageFormatGIF`.
 @note Subclass override.
 */
@property (class, readonly) FWImageFormat imageFormat;
/**
 The supported image format UTI Type. Such as `kUTTypeGIF`.
 This can be used for cases when we can not detect `FWImageFormat. Such as progressive decoding's hint format `kCGImageSourceTypeIdentifierHint`.
 @note Subclass override.
 */
@property (class, readonly, nonnull) NSString *imageUTType;
/**
 The image container property key used in Image/IO API. Such as `kCGImagePropertyGIFDictionary`.
 @note Subclass override.
 */
@property (class, readonly, nonnull) NSString *dictionaryProperty;
/**
 The image unclamped deply time property key used in Image/IO  API. Such as `kCGImagePropertyGIFUnclampedDelayTime`
 @note Subclass override.
 */
@property (class, readonly, nonnull) NSString *unclampedDelayTimeProperty;
/**
 The image delay time property key used in Image/IO API. Such as `kCGImagePropertyGIFDelayTime`.
 @note Subclass override.
 */
@property (class, readonly, nonnull) NSString *delayTimeProperty;
/**
 The image loop count property key used in Image/IO API. Such as `kCGImagePropertyGIFLoopCount`.
 @note Subclass override.
 */
@property (class, readonly, nonnull) NSString *loopCountProperty;
/**
 The default loop count when there are no any loop count information inside image container metadata.
 For example, for GIF format, the standard use 1 (play once). For APNG format, the standard use 0 (infinity loop).
 @note Subclass override.
 */
@property (class, readonly) NSUInteger defaultLoopCount;

@end

@interface FWImageGIFCoder : FWImageIOAnimatedCoder <FWProgressiveImageCoder, FWAnimatedImageCoder>

@property (nonatomic, class, readonly, nonnull) FWImageGIFCoder *sharedCoder;

@end

@interface FWImageAPNGCoder : FWImageIOAnimatedCoder <FWProgressiveImageCoder, FWAnimatedImageCoder>

@property (nonatomic, class, readonly, nonnull) FWImageAPNGCoder *sharedCoder;

@end

@interface FWImageHEICCoder : FWImageIOAnimatedCoder <FWProgressiveImageCoder, FWAnimatedImageCoder>

@property (nonatomic, class, readonly, nonnull) FWImageHEICCoder *sharedCoder;

@end

#pragma mark - FWImageFrame

@interface FWImageFrame : NSObject

@property (nonatomic, strong, readonly, nonnull) UIImage *image;

@property (nonatomic, readonly, assign) NSTimeInterval duration;

+ (instancetype _Nonnull)frameWithImage:(UIImage * _Nonnull)image duration:(NSTimeInterval)duration;

@end

@interface FWImageCoderHelper : NSObject

/**
 Return an animated image with frames array.
 For UIKit, this will apply the patch and then create animated UIImage. The patch is because that `+[UIImage animatedImageWithImages:duration:]` just use the average of duration for each image. So it will not work if different frame has different duration. Therefore we repeat the specify frame for specify times to let it work.
 For AppKit, NSImage does not support animates other than GIF. This will try to encode the frames to GIF format and then create an animated NSImage for rendering. Attention the animated image may loss some detail if the input frames contain full alpha channel because GIF only supports 1 bit alpha channel. (For 1 pixel, either transparent or not)

 @param frames The frames array. If no frames or frames is empty, return nil
 @return A animated image for rendering on UIImageView(UIKit) or NSImageView(AppKit)
 */
+ (UIImage * _Nullable)animatedImageWithFrames:(NSArray<FWImageFrame *> * _Nullable)frames;

/**
 Return frames array from an animated image.
 For UIKit, this will unapply the patch for the description above and then create frames array. This will also work for normal animated UIImage.
 For AppKit, NSImage does not support animates other than GIF. This will try to decode the GIF imageRep and then create frames array.

 @param animatedImage A animated image. If it's not animated, return nil
 @return The frames array
 */
+ (NSArray<FWImageFrame *> * _Nullable)framesFromAnimatedImage:(UIImage * _Nullable)animatedImage;

/**
 Return the shared device-dependent RGB color space. This follows The Get Rule.
 On iOS, it's created with deviceRGB (if available, use sRGB).
 On macOS, it's from the screen colorspace (if failed, use deviceRGB)
 Because it's shared, you should not retain or release this object.
 
 @return The device-dependent RGB color space
 */
+ (CGColorSpaceRef _Nonnull)colorSpaceGetDeviceRGB CF_RETURNS_NOT_RETAINED;

/**
 Check whether CGImage contains alpha channel.
 
 @param cgImage The CGImage
 @return Return YES if CGImage contains alpha channel, otherwise return NO
 */
+ (BOOL)CGImageContainsAlpha:(_Nonnull CGImageRef)cgImage;

/**
 Create a decoded CGImage by the provided CGImage. This follows The Create Rule and you are response to call release after usage.
 It will detect whether image contains alpha channel, then create a new bitmap context with the same size of image, and draw it. This can ensure that the image do not need extra decoding after been set to the imageView.
 @note This actually call `CGImageCreateDecoded:orientation:` with the Up orientation.

 @param cgImage The CGImage
 @return A new created decoded image
 */
+ (CGImageRef _Nullable)CGImageCreateDecoded:(_Nonnull CGImageRef)cgImage CF_RETURNS_RETAINED;

/**
 Create a decoded CGImage by the provided CGImage and orientation. This follows The Create Rule and you are response to call release after usage.
 It will detect whether image contains alpha channel, then create a new bitmap context with the same size of image, and draw it. This can ensure that the image do not need extra decoding after been set to the imageView.
 
 @param cgImage The CGImage
 @param orientation The EXIF image orientation.
 @return A new created decoded image
 */
+ (CGImageRef _Nullable)CGImageCreateDecoded:(_Nonnull CGImageRef)cgImage orientation:(CGImagePropertyOrientation)orientation CF_RETURNS_RETAINED;

/**
 Return the decoded image by the provided image. This one unlike `CGImageCreateDecoded:`, will not decode the image which contains alpha channel or animated image
 @param image The image to be decoded
 @return The decoded image
 */
+ (UIImage * _Nullable)decodedImageWithImage:(UIImage * _Nullable)image;

/**
 Return the decoded and probably scaled down image by the provided image. If the image is large than the limit size, will try to scale down. Or just works as `decodedImageWithImage:`

 @param image The image to be decoded and scaled down
 @param bytes The limit bytes size. Provide 0 to use the build-in limit.
 @return The decoded and probably scaled down image
 */
+ (UIImage * _Nullable)decodedAndScaledDownImageWithImage:(UIImage * _Nullable)image limitBytes:(NSUInteger)bytes;

/**
 Control the default limit bytes to scale down larget images.
 This value must be larger than or equal to 1MB. Defaults to 60MB on iOS/tvOS, 90MB on macOS, 30MB on watchOS.
 */
@property (class, readwrite) NSUInteger defaultScaleDownLimitBytes;
/**
 Convert an EXIF image orientation to an iOS one.

 @param exifOrientation EXIF orientation
 @return iOS orientation
 */
+ (UIImageOrientation)imageOrientationFromEXIFOrientation:(CGImagePropertyOrientation)exifOrientation;

/**
 Convert an iOS orientation to an EXIF image orientation.

 @param imageOrientation iOS orientation
 @return EXIF orientation
 */
+ (CGImagePropertyOrientation)exifOrientationFromImageOrientation:(UIImageOrientation)imageOrientation;

@end

@interface NSData (ImageContentType)

/**
 *  Return image format
 *
 *  @param data the input image data
 *
 *  @return the image format as `FWImageFormat` (enum)
 */
+ (FWImageFormat)fw_imageFormatForImageData:(nullable NSData *)data;

/**
 *  Convert FWImageFormat to UTType
 *
 *  @param format Format as FWImageFormat
 *  @return The UTType as CFStringRef
 */
+ (nonnull CFStringRef)fw_UTTypeFromImageFormat:(FWImageFormat)format CF_RETURNS_NOT_RETAINED;

/**
 *  Convert UTTyppe to FWImageFormat
 *
 *  @param uttype The UTType as CFStringRef
 *  @return The Format as FWImageFormat
 */
+ (FWImageFormat)fw_imageFormatFromUTType:(nonnull CFStringRef)uttype;

@end

@interface UIImage (Metadata)

/**
 * UIKit:
 * For static image format, this value is always 0.
 * For animated image format, 0 means infinite looping.
 * Note that because of the limitations of categories this property can get out of sync if you create another instance with CGImage or other methods.
 * AppKit:
 * NSImage currently only support animated via GIF imageRep unlike UIImage.
 * The getter of this property will get the loop count from GIF imageRep
 * The setter of this property will set the loop count from GIF imageRep
 */
@property (nonatomic, assign) NSUInteger fw_imageLoopCount;

/**
 * UIKit:
 * Check the `images` array property
 * AppKit:
 * NSImage currently only support animated via GIF imageRep unlike UIImage. It will check the imageRep's frame count.
 */
@property (nonatomic, assign, readonly) BOOL fw_isAnimated;

/**
 * The image format represent the original compressed image data format.
 * If you don't manually specify a format, this information is retrieve from CGImage using `CGImageGetUTType`, which may return nil for non-CG based image. At this time it will return `FWImageFormatUndefined` as default value.
 * @note Note that because of the limitations of categories this property can get out of sync if you create another instance with CGImage or other methods.
 */
@property (nonatomic, assign) FWImageFormat fw_imageFormat;

/**
 A bool value indicating whether the image is during incremental decoding and may not contains full pixels.
 */
@property (nonatomic, assign) BOOL fw_isIncremental;

/**
 A bool value indicating whether the image has already been decoded. This can help to avoid extra force decode.
 */
@property (nonatomic, assign) BOOL fw_isDecoded;

@end

/**
 UIImage category for convenient image format decoding/encoding.
 */
@interface UIImage (MultiFormat)
#pragma mark - Decode
/**
 Create and decode a image with the specify image data

 @param data The image data
 @return The created image
 */
+ (nullable UIImage *)fw_imageWithData:(nullable NSData *)data;

/**
 Create and decode a image with the specify image data and scale
 
 @param data The image data
 @param scale The image scale factor. Should be greater than or equal to 1.0.
 @return The created image
 */
+ (nullable UIImage *)fw_imageWithData:(nullable NSData *)data scale:(CGFloat)scale;

/**
 Create and decode a image with the specify image data and scale, allow specify animate/static control
 
 @param data The image data
 @param scale The image scale factor. Should be greater than or equal to 1.0.
 @param firstFrameOnly Even if the image data is animated image format, decode the first frame only as static image.
 @return The created image
 */
+ (nullable UIImage *)fw_imageWithData:(nullable NSData *)data scale:(CGFloat)scale firstFrameOnly:(BOOL)firstFrameOnly;

#pragma mark - Encode
/**
 Encode the current image to the data, the image format is unspecified

 @return The encoded data. If can't encode, return nil
 */
- (nullable NSData *)fw_imageData;

/**
 Encode the current image to data with the specify image format

 @param imageFormat The specify image format
 @return The encoded data. If can't encode, return nil
 */
- (nullable NSData *)fw_imageDataAsFormat:(FWImageFormat)imageFormat;

/**
 Encode the current image to data with the specify image format and compression quality

 @param imageFormat The specify image format
 @param compressionQuality The quality of the resulting image data. Value between 0.0-1.0. Some coders may not support compression quality.
 @return The encoded data. If can't encode, return nil
 */
- (nullable NSData *)fw_imageDataAsFormat:(FWImageFormat)imageFormat compressionQuality:(double)compressionQuality;

/**
 Encode the current image to data with the specify image format and compression quality, allow specify animate/static control
 
 @param imageFormat The specify image format
 @param compressionQuality The quality of the resulting image data. Value between 0.0-1.0. Some coders may not support compression quality.
 @param firstFrameOnly Even if the image is animated image, encode the first frame only as static image.
 @return The encoded data. If can't encode, return nil
 */
- (nullable NSData *)fw_imageDataAsFormat:(FWImageFormat)imageFormat compressionQuality:(double)compressionQuality firstFrameOnly:(BOOL)firstFrameOnly;

@end

NS_ASSUME_NONNULL_END
