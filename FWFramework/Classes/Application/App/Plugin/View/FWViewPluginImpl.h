/*!
 @header     FWViewPluginImpl.h
 @indexgroup FWFramework
 @brief      FWViewPluginImpl
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/22
 */

#import "FWViewPlugin.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWProgressView

/// 框架默认进度条视图，默认大小{37, 37}
@interface FWProgressView : UIView <FWProgressViewPlugin>

/// 是否是环形，默认YES，NO为扇形
@property (nonatomic, assign) BOOL annular;

/// 进度颜色，默认白色
@property (nonatomic, strong) UIColor *color;

/// 自定义线条颜色，默认nil自动处理。环形时为color透明度0.1，扇形时为color
@property (nonatomic, strong, nullable) UIColor *lineColor;

/// 自定义线条宽度，默认0自动处理。环形时为3，扇形时为1
@property (nonatomic, assign) CGFloat lineWidth;

/// 自定义线条样式，仅环形生效，默认kCGLineCapRound
@property (nonatomic, assign) CGLineCap lineCap;

/// 自定义填充颜色，默认nil
@property (nonatomic, strong, nullable) UIColor *fillColor;

/// 自定义填充内边距，默认0
@property (nonatomic, assign) CGFloat fillInset;

/// 进度动画时长，默认0.5
@property (nonatomic, assign) CFTimeInterval animationDuration;

/// 当前进度，0.0到1.0，默认0
@property (nonatomic, assign) CGFloat progress;

/// 设置当前进度，支持动画
- (void)setProgress:(CGFloat)progress animated:(BOOL)animated;

@end

#pragma mark - UIActivityIndicatorView+FWIndicatorView

/// 系统指示器默认实现指示器视图协议
@interface UIActivityIndicatorView (FWIndicatorView) <FWIndicatorViewPlugin, FWProgressViewPlugin>

/// 指示器进度，大于0小于1时开始动画，其它值停止动画。同setProgress:animated:
@property (nonatomic, assign) CGFloat progress;

/// 设置指示器进度，大于0小于1时开始动画，其它值停止动画。同setProgress:
- (void)setProgress:(CGFloat)progress animated:(BOOL)animated;

@end

#pragma mark - FWIndicatorView

/// 自定义指示器视图动画协议
@protocol FWIndicatorViewAnimationProtocol <NSObject>
@required

/// 初始化layer动画效果
- (void)setupAnimation:(CALayer *)layer size:(CGSize)size color:(UIColor *)color;

@end

/// 自定义指示器视图动画类型枚举，可扩展
typedef NSInteger FWIndicatorViewAnimationType NS_TYPED_EXTENSIBLE_ENUM;
/// 八线条渐变旋转，类似系统，默认
static const FWIndicatorViewAnimationType FWIndicatorViewAnimationTypeLineSpin = 0;
/// 五线条跳动，类似音符
static const FWIndicatorViewAnimationType FWIndicatorViewAnimationTypeLinePulse = 1;
/// 八圆球渐变旋转
static const FWIndicatorViewAnimationType FWIndicatorViewAnimationTypeBallSpin = 2;
/// 单线条圆形旋转
static const FWIndicatorViewAnimationType FWIndicatorViewAnimationTypeBallRotate = 3;
/// 三圆球水平跳动
static const FWIndicatorViewAnimationType FWIndicatorViewAnimationTypeBallPulse = 4;
/// 三圆圈三角形旋转
static const FWIndicatorViewAnimationType FWIndicatorViewAnimationTypeBallTriangle = 5;
/// 圆形向外扩散，类似水波纹
static const FWIndicatorViewAnimationType FWIndicatorViewAnimationTypeTriplePulse = 6;

/**
 * 自定义指示器视图，默认大小{37, 37}
 *
 * @see https://github.com/gontovnik/DGActivityIndicatorView
 */
@interface FWIndicatorView : UIView <FWIndicatorViewPlugin, FWProgressViewPlugin>

/// 指定动画类型初始化
- (instancetype)initWithType:(FWIndicatorViewAnimationType)type;

/// 当前动画类型
@property (nonatomic, assign) FWIndicatorViewAnimationType type;

/// 指示器颜色，默认白色
@property (nonatomic, strong) UIColor *color;

/// 停止动画时是否自动隐藏，默认YES
@property (nonatomic, assign) BOOL hidesWhenStopped;

/// 是否正在动画
@property (nonatomic, assign, readonly) BOOL isAnimating;

/// 开始动画
- (void)startAnimating;

/// 停止动画
- (void)stopAnimating;

/// 创建动画对象，子类可重写
- (id<FWIndicatorViewAnimationProtocol>)animation;

/// 指示器进度，大于0小于1时开始动画，其它值停止动画。同setProgress:animated:
@property (nonatomic, assign) CGFloat progress;

/// 设置指示器进度，大于0小于1时开始动画，其它值停止动画。同setProgress:
- (void)setProgress:(CGFloat)progress animated:(BOOL)animated;

@end

#pragma mark - FWViewPluginImpl

/// 默认视图插件
@interface FWViewPluginImpl : NSObject <FWViewPlugin>

/// 单例模式
@property (class, nonatomic, readonly) FWViewPluginImpl *sharedInstance;

/// 自定义进度视图生产句柄，默认FWProgressView
@property (nullable, nonatomic, copy) UIView<FWProgressViewPlugin> * (^customProgressView)(FWProgressViewStyle style);

/// 自定义指示器视图生产句柄，默认UIActivityIndicatorView
@property (nullable, nonatomic, copy) UIView<FWIndicatorViewPlugin> * (^customIndicatorView)(FWIndicatorViewStyle style);

@end

NS_ASSUME_NONNULL_END
