/*!
 @header     FWViewPlugin.h
 @indexgroup FWFramework
 @brief      FWViewPlugin
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/22
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWProgressViewPlugin

/// 进度条视图样式枚举，可扩展
typedef NSInteger FWProgressViewStyle NS_TYPED_EXTENSIBLE_ENUM;
/// 默认进度条样式
static const FWProgressViewStyle FWProgressViewStyleDefault = 0;

/// 自定义进度条视图插件
@protocol FWProgressViewPlugin <NSObject>
@required

/// 设置或获取进度条当前颜色
@property (nonatomic, strong) UIColor *color;
/// 设置或获取进度条当前进度
@property (nonatomic, assign) CGFloat progress;

@end

#pragma mark - FWIndicatorViewPlugin

/// 指示器视图样式枚举，可扩展
typedef NSInteger FWIndicatorViewStyle NS_TYPED_EXTENSIBLE_ENUM;
/// 默认指示器样式
static const FWIndicatorViewStyle FWIndicatorViewStyleDefault = 0;

/// 自定义指示器视图协议
@protocol FWIndicatorViewPlugin <NSObject>
@required

/// 设置或获取指示器当前颜色
@property (nonatomic, strong) UIColor *color;
/// 开始加载动画
- (void)startAnimating;
/// 停止加载动画
- (void)stopAnimating;

@end

#pragma mark - FWViewPlugin

/// 视图插件协议
@protocol FWViewPlugin <NSObject>
@optional

/// 进度视图工厂方法
- (UIView<FWProgressViewPlugin> *)createProgressView:(FWProgressViewStyle)style;

/// 指示器视图工厂方法
- (UIView<FWIndicatorViewPlugin> *)createIndicatorView:(FWIndicatorViewStyle)style;

@end

/// 视图插件管理器
@interface FWViewPluginManager : NSObject

/// 统一进度视图工厂方法
+ (UIView<FWProgressViewPlugin> *)createProgressView:(FWProgressViewStyle)style;

/// 统一指示器视图工厂方法
+ (UIView<FWIndicatorViewPlugin> *)createIndicatorView:(FWIndicatorViewStyle)style;

@end

NS_ASSUME_NONNULL_END
