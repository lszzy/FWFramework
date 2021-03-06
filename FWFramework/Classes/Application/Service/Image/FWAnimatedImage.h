/*!
 @header     FWAnimatedImage.h
 @indexgroup FWFramework
 @brief      FWAnimatedImage
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/7
 */

#import <UIKit/UIKit.h>
#import "FWImage.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIImage+FWAnimated

/// 图片格式可扩展枚举
typedef NSInteger FWImageFormat NS_TYPED_EXTENSIBLE_ENUM;
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

/*!
 @brief UIImage+FWAnimated
 
 @see https://github.com/SDWebImage/SDWebImage
 */
@interface UIImage (FWAnimated)

/// 图片循环次数，静态图片始终是0，动态图片0代表无限循环
@property (nonatomic, assign) NSUInteger fwImageLoopCount;

/// 是否是动图，内部检查images数组
@property (nonatomic, assign, readonly) BOOL fwIsAnimated;

/// 是否是向量图，内部检查isSymbolImage属性，iOS11+支持PDF，iOS13+支持SVG
@property (nonatomic, assign, readonly) BOOL fwIsVector;

/// 获取图片原始数据格式，未指定时尝试从CGImage获取，获取失败返回FWImageFormatUndefined
@property (nonatomic, assign) FWImageFormat fwImageFormat;

@end

#pragma mark - NSData+FWAnimated

/// 扩展系统UTType
#define kFWUTTypeHEIC ((__bridge CFStringRef)@"public.heic")
#define kFWUTTypeHEIF ((__bridge CFStringRef)@"public.heif")
#define kFWUTTypeHEICS ((__bridge CFStringRef)@"public.heics")
#define kFWUTTypeWebP ((__bridge CFStringRef)@"org.webmproject.webp")

/*!
 @brief NSData+FWAnimated
 */
@interface NSData (FWAnimated)

/// 获取图片数据的格式，未知格式返回FWImageFormatUndefined
+ (FWImageFormat)fwImageFormatForImageData:(nullable NSData *)data;

/// 图片格式转化为UTType，未知格式返回kUTTypeImage
+ (nonnull CFStringRef)fwUTTypeFromImageFormat:(FWImageFormat)format CF_RETURNS_NOT_RETAINED;

/// UTType转化为图片格式，未知格式返回FWImageFormatUndefined
+ (FWImageFormat)fwImageFormatFromUTType:(nonnull CFStringRef)uttype;

@end

#pragma mark - FWImageFrame

/*!
 @brief 动图单帧对象
 */
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
@interface FWImageCoder : NSObject

/// 单例模式
@property (class, nonatomic, readonly) FWImageCoder *sharedInstance;

/// 是否启用HEIC动图，因系统解码性能原因，默认为NO，禁用HEIC动图
@property (nonatomic, assign) BOOL heicsEnabled;

/// 解析图片数据到Image，可指定scale
- (nullable UIImage *)decodedImageWithData:(nullable NSData *)data scale:(CGFloat)scale options:(nullable NSDictionary<FWImageCoderOptions, id> *)options;

@end

NS_ASSUME_NONNULL_END
