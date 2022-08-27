//
//  FWAnimatedImage.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWImagePlugin.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIImage+FWAnimated

/// 图片格式可扩展枚举
typedef NSInteger FWImageFormat NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(ImageFormat);
static const FWImageFormat FWImageFormatUndefined = -1;
static const FWImageFormat FWImageFormatJPEG      = 0;
static const FWImageFormat FWImageFormatPNG       = 1;
static const FWImageFormat FWImageFormatGIF       = 2;
static const FWImageFormat FWImageFormatTIFF      = 3;
static const FWImageFormat FWImageFormatWebP      = 4; //iOS14+
static const FWImageFormat FWImageFormatHEIC      = 5; //iOS13+
static const FWImageFormat FWImageFormatHEIF      = 6; //iOS13+
static const FWImageFormat FWImageFormatPDF       = 7;
static const FWImageFormat FWImageFormatSVG       = 8; //iOS13+

/**
 UIImage+FWAnimated
 
 @see https://github.com/SDWebImage/SDWebImage
 */
@interface UIImage (FWAnimated)

/// 图片循环次数，静态图片始终是0，动态图片0代表无限循环
@property (nonatomic, assign) NSUInteger fw_imageLoopCount NS_REFINED_FOR_SWIFT;

/// 是否是动图，内部检查images数组
@property (nonatomic, assign, readonly) BOOL fw_isAnimated NS_REFINED_FOR_SWIFT;

/// 是否是向量图，内部检查isSymbolImage属性，iOS11+支持PDF，iOS13+支持SVG
@property (nonatomic, assign, readonly) BOOL fw_isVector NS_REFINED_FOR_SWIFT;

/// 获取图片原始数据格式，未指定时尝试从CGImage获取，获取失败返回FWImageFormatUndefined
@property (nonatomic, assign) FWImageFormat fw_imageFormat NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSData+FWAnimated

/// 扩展系统UTType
#define kFWUTTypeHEIC ((__bridge CFStringRef)@"public.heic")
#define kFWUTTypeHEIF ((__bridge CFStringRef)@"public.heif")
#define kFWUTTypeHEICS ((__bridge CFStringRef)@"public.heics")
#define kFWUTTypeWebP ((__bridge CFStringRef)@"org.webmproject.webp")

@interface NSData (FWAnimated)

/// 获取图片数据的格式，未知格式返回FWImageFormatUndefined
+ (FWImageFormat)fw_imageFormatForImageData:(nullable NSData *)data NS_REFINED_FOR_SWIFT;

/// 图片格式转化为UTType，未知格式返回kUTTypeImage
+ (nonnull CFStringRef)fw_UTTypeFromImageFormat:(FWImageFormat)format CF_RETURNS_NOT_RETAINED NS_REFINED_FOR_SWIFT;

/// UTType转化为图片格式，未知格式返回FWImageFormatUndefined
+ (FWImageFormat)fw_imageFormatFromUTType:(nonnull CFStringRef)uttype NS_REFINED_FOR_SWIFT;

/// 图片格式转化为mimeType，未知格式返回application/octet-stream
+ (NSString *)fw_mimeTypeFromImageFormat:(FWImageFormat)format NS_REFINED_FOR_SWIFT;

/// 文件后缀转化为mimeType，未知后缀返回application/octet-stream
+ (NSString *)fw_mimeTypeFromExtension:(NSString *)extension NS_REFINED_FOR_SWIFT;

/// 图片数据编码为base64字符串，可直接用于H5显示等，字符串格式：data:image/png;base64,数据
+ (nullable NSString *)fw_base64StringForImageData:(nullable NSData *)data NS_REFINED_FOR_SWIFT;

@end

#pragma mark - FWImageFrame

/**
 动图单帧对象
 */
NS_SWIFT_NAME(ImageFrame)
@interface FWImageFrame : NSObject

/// 单帧图片
@property (nonatomic, strong, readonly) UIImage *image;

/// 单帧时长
@property (nonatomic, assign, readonly) NSTimeInterval duration;

/// 创建单帧对象
- (instancetype)initWithImage:(UIImage *)image duration:(NSTimeInterval)duration;

/// 根据单帧对象创建动图Image
+ (nullable UIImage *)animatedImageWithFrames:(nullable NSArray<FWImageFrame *> *)frames;

/// 从动图Image创建单帧对象数组
+ (nullable NSArray<FWImageFrame *> *)framesFromAnimatedImage:(nullable UIImage *)animatedImage;

@end

#pragma mark - FWImageCoder

/// 图片解码器，支持动图
NS_SWIFT_NAME(ImageCoder)
@interface FWImageCoder : NSObject

/// 单例模式
@property (class, nonatomic, readonly) FWImageCoder *sharedInstance NS_SWIFT_NAME(shared);

/// 是否启用HEIC动图，因系统解码性能原因，默认为NO，禁用HEIC动图
@property (nonatomic, assign) BOOL heicsEnabled;

/// 解析图片数据到Image，可指定scale
- (nullable UIImage *)decodedImageWithData:(nullable NSData *)data scale:(CGFloat)scale options:(nullable NSDictionary<FWImageCoderOptions, id> *)options;

/// 编码UIImage到图片数据，可指定格式
- (nullable NSData *)encodedDataWithImage:(nullable UIImage *)image format:(FWImageFormat)format options:(nullable NSDictionary<FWImageCoderOptions, id> *)options;

@end

NS_ASSUME_NONNULL_END
