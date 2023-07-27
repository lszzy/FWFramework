//
//  IndicatorView.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWIndicatorView

/// 自定义指示器视图动画协议
NS_SWIFT_NAME(IndicatorViewAnimationProtocol)
@protocol __FWIndicatorViewAnimationProtocol <NSObject>
@required

/// 初始化layer动画效果
- (void)setupAnimation:(CALayer *)layer size:(CGSize)size color:(UIColor *)color;

@end

/// 自定义指示器视图动画类型枚举，可扩展
typedef NSInteger __FWIndicatorViewAnimationType NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(IndicatorViewAnimationType);
/// 八线条渐变旋转，类似系统，默认
static const __FWIndicatorViewAnimationType __FWIndicatorViewAnimationTypeLineSpin = 0;
/// 五线条跳动，类似音符
static const __FWIndicatorViewAnimationType __FWIndicatorViewAnimationTypeLinePulse = 1;
/// 八圆球渐变旋转
static const __FWIndicatorViewAnimationType __FWIndicatorViewAnimationTypeBallSpin = 2;
/// 三圆球水平跳动
static const __FWIndicatorViewAnimationType __FWIndicatorViewAnimationTypeBallPulse = 3;
/// 三圆圈三角形旋转
static const __FWIndicatorViewAnimationType __FWIndicatorViewAnimationTypeBallTriangle = 4;
/// 单圆圈渐变旋转
static const __FWIndicatorViewAnimationType __FWIndicatorViewAnimationTypeCircleSpin = 5;
/// 圆形向外扩散，类似水波纹
static const __FWIndicatorViewAnimationType __FWIndicatorViewAnimationTypeTriplePulse = 6;

/**
 * 自定义指示器视图
 *
 * @see https://github.com/gontovnik/DGActivityIndicatorView
 */
NS_SWIFT_NAME(IndicatorView)
@interface __FWIndicatorView : UIView

/// 指定动画类型初始化
- (instancetype)initWithType:(__FWIndicatorViewAnimationType)type;

/// 当前动画类型
@property (nonatomic, assign) __FWIndicatorViewAnimationType type;

/// 指示器颜色，默认白色
@property (nonatomic, strong, nullable) UIColor *indicatorColor;

/// 设置或获取指示器大小，默认{37,37}
@property (nonatomic, assign) CGSize indicatorSize;

/// 停止动画时是否自动隐藏，默认YES
@property (nonatomic, assign) BOOL hidesWhenStopped;

/// 是否正在动画
@property (nonatomic, assign, readonly) BOOL isAnimating;

/// 开始动画
- (void)startAnimating;

/// 停止动画
- (void)stopAnimating;

/// 创建动画对象，子类可重写
- (id<__FWIndicatorViewAnimationProtocol>)animation;

/// 指示器进度，大于0小于1时开始动画，其它值停止动画。同setProgress:animated:
@property (nonatomic, assign) CGFloat progress;

/// 设置指示器进度，大于0小于1时开始动画，其它值停止动画。同setProgress:
- (void)setProgress:(CGFloat)progress animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
