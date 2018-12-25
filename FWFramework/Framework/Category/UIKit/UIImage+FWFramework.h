/*!
 @header     UIImage+FWFramework.h
 @indexgroup FWFramework
 @brief      UIImage+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/19
 */

#import <UIKit/UIKit.h>
#import "UIImage+FWGif.h"

// 使用文件名方式加载UIImage。会被系统缓存，适用于大量复用的小资源图
#define FWImageName( name ) \
    [UIImage imageNamed:name]

// 从图片文件加载UIImage。不会被系统缓存，适用于不被复用的图片，特别是大图
#define FWImageFile( file ) \
    [UIImage imageWithContentsOfFile:file]

// 从应用资源路径加载UIImage，后缀可选，默认nil。不会被系统缓存，适用于不被复用的图片，特别是大图
#define FWImageResource( path, ... ) \
    FWImageFile( [[NSBundle mainBundle] pathForResource:path ofType:fw_macro_default(nil, ##__VA_ARGS__)] )

/*!
 @brief UIImage+FWFramework
 */
@interface UIImage (FWFramework)

#pragma mark - Make

// 使用文件名方式加载UIImage。会被系统缓存，适用于大量复用的小资源图
+ (UIImage *)fwImageWithName:(NSString *)name;

// 使用文件名方式从bundle加载UIImage。会被系统缓存，适用于大量复用的小资源图
+ (UIImage *)fwImageWithName:(NSString *)name inBundle:(NSBundle *)bundle;

// 从图片文件加载UIImage。不会被系统缓存，适用于不被复用的图片，特别是大图
+ (UIImage *)fwImageWithFile:(NSString *)path;

// 从应用资源路径加载UIImage。不会被系统缓存，适用于不被复用的图片，特别是大图
+ (UIImage *)fwImageWithResource:(NSString *)path;

// 从应用资源路径加载UIImage，后缀可选，默认nil。不会被系统缓存，适用于不被复用的图片，特别是大图
+ (UIImage *)fwImageWithResource:(NSString *)path ofType:(NSString *)type;

// 从应用资源路径从bundle加载UIImage，后缀可选，默认nil。不会被系统缓存，适用于不被复用的图片，特别是大图
+ (UIImage *)fwImageWithResource:(NSString *)path ofType:(NSString *)type inBundle:(NSBundle *)bundle;

#pragma mark - View

// 从View创建UIImage
+ (UIImage *)fwImageWithView:(UIView *)view;

// 截取View所有视图，包括旋转缩放效果
+ (UIImage *)fwImageWithView:(UIView *)view limitWidth:(CGFloat)limitWidth;

#pragma mark - Color

// 从颜色创建UIImage，默认尺寸1x1
+ (UIImage *)fwImageWithColor:(UIColor *)color;

// 从颜色创建UIImage
+ (UIImage *)fwImageWithColor:(UIColor *)color size:(CGSize)size;

// 获取灰度图
- (UIImage *)fwGrayImage;

// 取图片某一点的颜色
- (UIColor *)fwColorAtPoint:(CGPoint)point;

// 取图片某一像素的颜色
- (UIColor *)fwColorAtPixel:(CGPoint)point;

// 获取图片的平均颜色
- (UIColor *)fwAverageColor;

#pragma mark - Icon

// 获取AppIcon图片
+ (UIImage *)fwImageWithAppIcon;

// 获取AppIcon指定尺寸图片，名称格式：AppIcon60x60
+ (UIImage *)fwImageWithAppIcon:(CGSize)size;

#pragma mark - Pdf

// 从Pdf数据或者路径创建UIImage
+ (UIImage *)fwImageWithPdf:(id)path;

// 从Pdf数据或者路径创建指定大小UIImage
+ (UIImage *)fwImageWithPdf:(id)path size:(CGSize)size;

#pragma mark - Emoji

// 从Emoji字符串创建指定大小UIImage
+ (UIImage *)fwImageWithEmoji:(NSString *)emoji size:(CGFloat)size;

#pragma mark - Block

// 执行block创建指定大小UIImage
+ (UIImage *)fwImageWithBlock:(void (^)(CGContextRef context))block size:(CGSize)size;

#pragma mark - Blend

// 从当前图片混合颜色创建UIImage，默认kCGBlendModeDestinationIn模式，适合透明图标
- (UIImage *)fwImageWithTintColor:(UIColor *)tintColor;

// 从当前UIImage混合颜色创建UIImage，自定义模式
- (UIImage *)fwImageWithTintColor:(UIColor *)tintColor blendMode:(CGBlendMode)blendMode;

// 设置图片渲染模式为原始，始终显示原色，不显示tintColor。默认自动根据上下文
- (UIImage *)fwImageWithRenderOriginal;

// 设置图片渲染模式为模板，始终显示tintColor，不显示原色。默认自动根据上下文
- (UIImage *)fwImageWithRenderTemplate;

#pragma mark - Resize

// 缩放图片到指定大小
- (UIImage *)fwImageWithScaleSize:(CGSize)size;

// 缩放图片到指定大小，指定模式
- (UIImage *)fwImageWithScaleSize:(CGSize)size contentMode:(UIViewContentMode)contentMode;

// 按指定模式绘制图片
- (void)fwDrawInRect:(CGRect)rect withContentMode:(UIViewContentMode)contentMode clipsToBounds:(BOOL)clipsToBounds;

// 裁剪指定区域图片
- (UIImage *)fwImageWithCropRect:(CGRect)rect;

// 指定颜色填充图片边缘
- (UIImage *)fwImageWithInsets:(UIEdgeInsets)insets color:(UIColor *)color;

// 拉伸图片(平铺模式)，指定端盖区域（不拉伸区域）
- (UIImage *)fwImageWithCapInsets:(UIEdgeInsets)insets;

// 拉伸图片(指定模式)，指定端盖区域（不拉伸区域）。Tile为平铺模式，Stretch为拉伸模式
- (UIImage *)fwImageWithCapInsets:(UIEdgeInsets)insets resizingMode:(UIImageResizingMode)resizingMode;

#pragma mark - Compress

// 压缩图片到指定字节
- (NSData *)fwCompressDataWithMaxLength:(NSInteger)maxLength maxWidth:(NSInteger)maxWidth;

// 通过指定图片最长边，获取等比例的图片size
- (CGSize)fwScaleSizeWithMaxLength:(CGFloat)maxLength;

#pragma mark - Effect

// 倒影图片
- (UIImage *)fwImageWithReflectScale:(CGFloat)scale;

// 倒影图片
- (UIImage *)fwImageWithReflectScale:(CGFloat)scale gap:(CGFloat)gap alpha:(CGFloat)alpha;

// 阴影图片
- (UIImage *)fwImageWithShadowColor:(UIColor *)color offset:(CGSize)offset blur:(CGFloat)blur;

// 圆角图片
- (UIImage *)fwImageWithCornerRadius:(CGFloat)radius;

// 透明图片
- (UIImage *)fwImageWithAlpha:(CGFloat)alpha;

// 装饰图片
- (UIImage *)fwImageWithMaskImage:(UIImage *)maskImage;

// 获取装饰图片
- (UIImage *)fwMaskImage;

// 合并图片
- (UIImage *)fwImageWithMergeImage:(UIImage *)mergeImage;

#pragma mark - Rotate

// 按角度常数(0~360)转动图片，默认图片尺寸适应内容
- (UIImage *)fwImageWithRotateDegree:(CGFloat)degree;

// 按角度常数(0~360)转动图片，指定图片尺寸是否延伸来适应内容，否则图片尺寸不变，内容被裁剪
- (UIImage *)fwImageWithRotateDegree:(CGFloat)degree fitSize:(BOOL)fitSize;

#pragma mark - Alpha

// 判断图片是否有透明通道
- (BOOL)fwHasAlpha;

// 如果没有透明通道，增加透明通道
- (UIImage *)fwAlphaImage;

#pragma mark - Save

// 保存图片到相册，保存成功时error为nil
- (void)fwSaveImageWithBlock:(void (^)(NSError *error))block;

@end
