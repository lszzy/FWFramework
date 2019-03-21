/*!
 @header     UIColor+FWFramework.h
 @indexgroup FWFramework
 @brief      UIColor+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/18
 */

#import <UIKit/UIKit.h>

#pragma mark - Macro

// 从16进制创建UIColor，格式0xFFFFFF，透明度可选，默认1.0
#define FWColorHex( hex, ... ) \
    [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16))/255.0 green:((float)((hex & 0xFF00) >> 8))/255.0 blue:((float)(hex & 0xFF))/255.0 alpha:fw_macro_default(1.0, ##__VA_ARGS__)]

// 从RGB创建UIColor，透明度可选，默认1.0
#define FWColorRgb( r, g, b, ... ) \
    [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:fw_macro_default(1.0f, ##__VA_ARGS__)]

/*!
 @brief UIColor+FWFramework
 */
@interface UIColor (FWFramework)

#pragma mark - Hex

// 从十六进制值初始化，格式：0x20B2AA，透明度为1.0
+ (UIColor *)fwColorWithHex:(long)hex;

// 从十六进制值初始化，格式：0x20B2AA，自定义透明度
+ (UIColor *)fwColorWithHex:(long)hex alpha:(CGFloat)alpha;

#pragma mark - String

// 从十六进制字符串初始化，支持RGB、RGBA、RRGGBB、RRGGBBAA，格式：@"20B2AA", @"#FFFFFF"，透明度为1.0
+ (UIColor *)fwColorWithHexString:(NSString *)hexString;

// 从十六进制字符串初始化，支持RGB、RGBA、RRGGBB、RRGGBBAA，格式：@"20B2AA", @"#FFFFFF"，自定义透明度
+ (UIColor *)fwColorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha;

// 从颜色字符串初始化，支持十六进制和颜色值，透明度为1.0
+ (UIColor *)fwColorWithString:(NSString *)string;

// 从颜色字符串初始化，支持十六进制和颜色值，自定义透明度
+ (UIColor *)fwColorWithString:(NSString *)string alpha:(CGFloat)alpha;

#pragma mark - Image

// 从整个图像初始化UIColor
+ (UIColor *)fwColorWithImage:(UIImage *)image;

// 从图像的某个点初始化UIColor
+ (UIColor *)fwColorWithImage:(UIImage *)image point:(CGPoint)point;

#pragma mark - Color

// 以指定模式添加混合颜色
- (UIColor *)fwAddColor:(UIColor *)color blendMode:(CGBlendMode)blendMode;

// 当前颜色的反色。http://stackoverflow.com/questions/5893261/how-to-get-inverse-color-from-uicolor
- (UIColor *)fwInverseColor;

// 判断当前颜色是否为深色。http://stackoverflow.com/questions/19456288/text-color-based-on-background-image
- (BOOL)fwIsDarkColor;

#pragma mark - Value

// 读取颜色的十六进制值，不含透明度
- (long)fwHexValue;

// 读取颜色的十六进制字符串，不含透明度
- (NSString *)fwHexString;

// 读取颜色的十六进制字符串，包含透明度
- (NSString *)fwHexStringWithAlpha;

// 读取颜色的透明度值，范围0~1
- (CGFloat)fwAlpha;

// 返回颜色对应透明度的新颜色
- (UIColor *)fwColorWithAlpha:(CGFloat)alpha;

#pragma mark - Gradient

/*!
 @brief 创建渐变颜色，支持四个方向，默认向下Down
 
 @param size 渐变尺寸，非渐变边可以设置为1。如CGSizeMake(1, 50)
 @param colors 渐变颜色，CGColor数组，如：@[(__bridge id)[UIColor redColor].CGColor, (__bridge id)[UIColor blueColor].CGColor]
 @param locations 渐变位置，传NULL时均分，如：CGFloat locations[] = {0.0, 1.0};
 @param direction 渐变方向，自动计算startPoint和endPoint，支持四个方向，默认向下Down
 */
+ (UIColor *)fwGradientColorWithSize:(CGSize)size
                              colors:(NSArray *)colors
                           locations:(const CGFloat *)locations
                           direction:(UISwipeGestureRecognizerDirection)direction;

/*!
 @brief 创建渐变颜色
 
 @param size 渐变尺寸，非渐变边可以设置为1。如CGSizeMake(1, 50)
 @param colors 渐变颜色，CGColor数组，如：@[(__bridge id)[UIColor redColor].CGColor, (__bridge id)[UIColor blueColor].CGColor]
 @param locations 渐变位置，传NULL时均分，如：CGFloat locations[] = {0.0, 1.0};
 @param startPoint 渐变开始点，需要根据rect计算
 @param endPoint 渐变结束点，需要根据rect计算
 */
+ (UIColor *)fwGradientColorWithSize:(CGSize)size
                              colors:(NSArray *)colors
                           locations:(const CGFloat *)locations
                          startPoint:(CGPoint)startPoint
                            endPoint:(CGPoint)endPoint;

#pragma mark - Random

// 随机颜色
+ (UIColor *)fwRandomColor;

@end
