//
//  ViewPlugin.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWProgressViewPlugin

/// 进度条视图样式枚举，可扩展
typedef NSInteger __FWProgressViewStyle NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(ProgressViewStyle);
/// 默认进度条样式，用于框架Toast等
static const __FWProgressViewStyle __FWProgressViewStyleDefault = 0;

/// 自定义进度条视图插件
NS_SWIFT_NAME(ProgressViewPlugin)
@protocol __FWProgressViewPlugin <NSObject>
@required

/// 设置或获取进度条当前颜色
@property (nonatomic, strong) UIColor *color;
/// 设置或获取进度条大小
@property (nonatomic, assign) CGSize size;
/// 设置或获取进度条当前进度
@property (nonatomic, assign) CGFloat progress;
/// 设置进度条当前进度，支持动画
- (void)setProgress:(CGFloat)progress animated:(BOOL)animated;

@end

#pragma mark - __FWIndicatorViewPlugin

/// 指示器视图样式枚举，可扩展
typedef NSInteger __FWIndicatorViewStyle NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(IndicatorViewStyle);
/// 默认指示器样式，用于框架Empty|Toast等
static const __FWIndicatorViewStyle __FWIndicatorViewStyleDefault = 0;
/// 刷新指示器样式，用于框架Refresh等
static const __FWIndicatorViewStyle __FWIndicatorViewStyleRefresh = 1;

/// 自定义指示器视图协议
NS_SWIFT_NAME(IndicatorViewPlugin)
@protocol __FWIndicatorViewPlugin <NSObject>
@required

/// 设置或获取指示器当前颜色
@property (nonatomic, strong) UIColor *color;
/// 设置或获取指示器大小
@property (nonatomic, assign) CGSize size;
/// 当前是否正在执行动画
@property (nonatomic, assign, readonly) BOOL isAnimating;
/// 开始加载动画
- (void)startAnimating;
/// 停止加载动画
- (void)stopAnimating;

@end

#pragma mark - __FWViewPlugin

/// 视图插件协议
NS_SWIFT_NAME(ViewPlugin)
@protocol __FWViewPlugin <NSObject>
@optional

/// 进度视图工厂方法
- (UIView<__FWProgressViewPlugin> *)progressViewWithStyle:(__FWProgressViewStyle)style;

/// 指示器视图工厂方法
- (UIView<__FWIndicatorViewPlugin> *)indicatorViewWithStyle:(__FWIndicatorViewStyle)style;

@end

NS_ASSUME_NONNULL_END
