//
//  FWToolkit.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 从16进制创建UIColor，格式0xFFFFFF，透明度可选，默认1.0
#define FWColorHex( hex, ... ) \
    [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16))/255.0 green:((float)((hex & 0xFF00) >> 8))/255.0 blue:((float)(hex & 0xFF))/255.0 alpha:fw_macro_default(1.0, ##__VA_ARGS__)]

/// 从RGB创建UIColor，透明度可选，默认1.0
#define FWColorRgb( r, g, b, ... ) \
    [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:fw_macro_default(1.0f, ##__VA_ARGS__)]

/// 快速创建系统字体，字重可选，默认Regular
#define FWFontSize( size, ... ) \
    [UIFont fw_fontOfSize:size weight:fw_macro_default(UIFontWeightRegular, ##__VA_ARGS__)]

/// 快速创建Thin字体
FOUNDATION_EXPORT UIFont * FWFontThin(CGFloat size) NS_SWIFT_UNAVAILABLE("");
/// 快速创建Light字体
FOUNDATION_EXPORT UIFont * FWFontLight(CGFloat size) NS_SWIFT_UNAVAILABLE("");
/// 快速创建Regular字体
FOUNDATION_EXPORT UIFont * FWFontRegular(CGFloat size) NS_SWIFT_UNAVAILABLE("");
/// 快速创建Medium字体
FOUNDATION_EXPORT UIFont * FWFontMedium(CGFloat size) NS_SWIFT_UNAVAILABLE("");
/// 快速创建Semibold字体
FOUNDATION_EXPORT UIFont * FWFontSemibold(CGFloat size) NS_SWIFT_UNAVAILABLE("");
/// 快速创建Bold字体
FOUNDATION_EXPORT UIFont * FWFontBold(CGFloat size) NS_SWIFT_UNAVAILABLE("");

#pragma mark - UIImage+FWToolkit

@interface UIImage (FWToolkit)

/// 获取装饰图片
@property (nonatomic, readonly) UIImage *fw_maskImage NS_REFINED_FOR_SWIFT;

/// 高斯模糊图片，默认模糊半径为10，饱和度为1。注意CGContextDrawImage如果图片尺寸太大会导致内存不足闪退，建议先压缩再调用
- (nullable UIImage *)fw_imageWithBlurRadius:(CGFloat)blurRadius saturationDelta:(CGFloat)saturationDelta tintColor:(nullable UIColor *)tintColor maskImage:(nullable UIImage *)maskImage NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
