/*!
 @header     UIImage+FWFramework.h
 @indexgroup FWFramework
 @brief      UIImage+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/19
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief UIImage+FWFramework
 @discussion 注意CGContextDrawImage如果图片尺寸太大会导致内存不足闪退(如高斯模糊效果)，建议先压缩再调用
 */
@interface UIImage (FWFramework)

#pragma mark - View

// 截取View所有视图，包括旋转缩放效果
+ (nullable UIImage *)fwImageWithView:(UIView *)view limitWidth:(CGFloat)limitWidth;

#pragma mark - Color

// 获取灰度图
@property (nonatomic, readonly, nullable) UIImage *fwGrayImage;

// 取图片某一点的颜色
- (nullable UIColor *)fwColorAtPoint:(CGPoint)point;

// 取图片某一像素的颜色
- (nullable UIColor *)fwColorAtPixel:(CGPoint)point;

// 获取图片的平均颜色
@property (nonatomic, readonly) UIColor *fwAverageColor;

// 获取当前图片的像素大小，多倍图会放大到一倍
@property (nonatomic, assign, readonly) CGSize fwPixelSize;

#pragma mark - Icon

// 获取AppIcon图片
+ (nullable UIImage *)fwImageWithAppIcon;

// 获取AppIcon指定尺寸图片，名称格式：AppIcon60x60
+ (nullable UIImage *)fwImageWithAppIcon:(CGSize)size;

#pragma mark - Pdf

// 从Pdf数据或者路径创建UIImage
+ (nullable UIImage *)fwImageWithPdf:(id)path;

// 从Pdf数据或者路径创建指定大小UIImage
+ (nullable UIImage *)fwImageWithPdf:(id)path size:(CGSize)size;

#pragma mark - Emoji

// 从Emoji字符串创建指定大小UIImage
+ (nullable UIImage *)fwImageWithEmoji:(NSString *)emoji size:(CGFloat)size;

#pragma mark - Block

// 执行block创建指定大小UIImage
+ (nullable UIImage *)fwImageWithBlock:(void (^)(CGContextRef context))block size:(CGSize)size;

#pragma mark - Gradient

/*!
 @brief 创建渐变颜色UIImage，支持四个方向，默认向下Down
 
 @param size 图片大小
 @param colors 渐变颜色，CGColor数组，如：@[(__bridge id)[UIColor redColor].CGColor, (__bridge id)[UIColor blueColor].CGColor]
 @param locations 渐变位置，传NULL时均分，如：CGFloat locations[] = {0.0, 1.0};
 @param direction 渐变方向，自动计算startPoint和endPoint，支持四个方向，默认向下Down
 @return 渐变颜色UIImage
 */
+ (nullable UIImage *)fwGradientImageWithSize:(CGSize)size
                                       colors:(NSArray *)colors
                                    locations:(nullable const CGFloat *)locations
                                    direction:(UISwipeGestureRecognizerDirection)direction;

/*!
 @brief 创建渐变颜色UIImage
 
 @param size 图片大小
 @param colors 渐变颜色，CGColor数组，如：@[(__bridge id)[UIColor redColor].CGColor, (__bridge id)[UIColor blueColor].CGColor]
 @param locations 渐变位置，传NULL时均分，如：CGFloat locations[] = {0.0, 1.0};
 @param startPoint 渐变开始点，需要根据rect计算
 @param endPoint 渐变结束点，需要根据rect计算
 @return 渐变颜色UIImage
 */
+ (nullable UIImage *)fwGradientImageWithSize:(CGSize)size
                                       colors:(NSArray *)colors
                                    locations:(nullable const CGFloat *)locations
                                   startPoint:(CGPoint)startPoint
                                     endPoint:(CGPoint)endPoint;

#pragma mark - Blend

// 设置图片渲染模式为原始，始终显示原色，不显示tintColor。默认自动根据上下文
@property (nonatomic, readonly) UIImage *fwImageWithRenderOriginal;

// 设置图片渲染模式为模板，始终显示tintColor，不显示原色。默认自动根据上下文
@property (nonatomic, readonly) UIImage *fwImageWithRenderTemplate;

#pragma mark - Resize

// 缩放图片到指定大小
- (nullable UIImage *)fwImageWithScaleSize:(CGSize)size;

// 缩放图片到指定大小，指定模式
- (nullable UIImage *)fwImageWithScaleSize:(CGSize)size contentMode:(UIViewContentMode)contentMode;

// 按指定模式绘制图片
- (void)fwDrawInRect:(CGRect)rect withContentMode:(UIViewContentMode)contentMode clipsToBounds:(BOOL)clipsToBounds;

// 裁剪指定区域图片
- (nullable UIImage *)fwImageWithCropRect:(CGRect)rect;

// 指定颜色填充图片边缘
- (nullable UIImage *)fwImageWithInsets:(UIEdgeInsets)insets color:(nullable UIColor *)color;

// 拉伸图片(平铺模式)，指定端盖区域（不拉伸区域）
- (UIImage *)fwImageWithCapInsets:(UIEdgeInsets)insets;

// 拉伸图片(指定模式)，指定端盖区域（不拉伸区域）。Tile为平铺模式，Stretch为拉伸模式
- (UIImage *)fwImageWithCapInsets:(UIEdgeInsets)insets resizingMode:(UIImageResizingMode)resizingMode;

#pragma mark - Effect

// 倒影图片
- (nullable UIImage *)fwImageWithReflectScale:(CGFloat)scale;

// 倒影图片
- (nullable UIImage *)fwImageWithReflectScale:(CGFloat)scale gap:(CGFloat)gap alpha:(CGFloat)alpha;

// 阴影图片
- (nullable UIImage *)fwImageWithShadowColor:(UIColor *)color offset:(CGSize)offset blur:(CGFloat)blur;

// 圆角图片
- (nullable UIImage *)fwImageWithCornerRadius:(CGFloat)radius;

// 透明图片
- (nullable UIImage *)fwImageWithAlpha:(CGFloat)alpha;

// 装饰图片
- (nullable UIImage *)fwImageWithMaskImage:(UIImage *)maskImage;

// 获取装饰图片
@property (nonatomic, readonly) UIImage *fwMaskImage;

// 合并图片
- (nullable UIImage *)fwImageWithMergeImage:(UIImage *)mergeImage;

// 高斯模糊图片，默认模糊半径为10，饱和度为1
- (nullable UIImage *)fwImageWithBlurRadius:(CGFloat)blurRadius saturationDelta:(CGFloat)saturationDelta tintColor:(nullable UIColor *)tintColor maskImage:(nullable UIImage *)maskImage;

#pragma mark - Rotate

// 按角度常数(0~360)转动图片，默认图片尺寸适应内容
- (nullable UIImage *)fwImageWithRotateDegree:(CGFloat)degree;

// 按角度常数(0~360)转动图片，指定图片尺寸是否延伸来适应内容，否则图片尺寸不变，内容被裁剪
- (nullable UIImage *)fwImageWithRotateDegree:(CGFloat)degree fitSize:(BOOL)fitSize;

#pragma mark - Alpha

// 如果没有透明通道，增加透明通道
@property (nonatomic, readonly) UIImage *fwAlphaImage;

#pragma mark - Save

// 保存图片到相册，保存成功时error为nil
- (void)fwSaveImageWithBlock:(nullable void (^)(NSError * _Nullable error))block;

@end

NS_ASSUME_NONNULL_END
