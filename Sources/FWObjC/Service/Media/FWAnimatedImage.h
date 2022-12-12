//
//  FWAnimatedImage.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWImagePlugin.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWImageFormat

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

/// 扩展系统UTType
#define kFWUTTypeHEIC ((__bridge CFStringRef)@"public.heic")
#define kFWUTTypeHEIF ((__bridge CFStringRef)@"public.heif")
#define kFWUTTypeHEICS ((__bridge CFStringRef)@"public.heics")
#define kFWUTTypeWebP ((__bridge CFStringRef)@"org.webmproject.webp")

/**
 图片解码器，支持动图
 
 @see https://github.com/SDWebImage/SDWebImage
 */
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

/// 获取图片数据的格式，未知格式返回FWImageFormatUndefined
+ (FWImageFormat)imageFormatForImageData:(nullable NSData *)data;

/// 图片格式转化为UTType，未知格式返回kUTTypeImage
+ (nonnull CFStringRef)utTypeFromImageFormat:(FWImageFormat)format CF_RETURNS_NOT_RETAINED;

/// UTType转化为图片格式，未知格式返回FWImageFormatUndefined
+ (FWImageFormat)imageFormatFromUTType:(nullable CFStringRef)uttype;

/// 图片格式转化为mimeType，未知格式返回application/octet-stream
+ (NSString *)mimeTypeFromImageFormat:(FWImageFormat)format;

/// 文件后缀转化为mimeType，未知后缀返回application/octet-stream
+ (NSString *)mimeTypeFromExtension:(NSString *)extension;

/// 图片数据编码为base64字符串，可直接用于H5显示等，字符串格式：data:image/png;base64,数据
+ (nullable NSString *)base64StringForImageData:(nullable NSData *)data;

/// 是否是向量图，内部检查isSymbolImage属性，iOS11+支持PDF，iOS13+支持SVG
+ (BOOL)isVectorImage:(nullable UIImage *)image;

@end

NS_ASSUME_NONNULL_END
