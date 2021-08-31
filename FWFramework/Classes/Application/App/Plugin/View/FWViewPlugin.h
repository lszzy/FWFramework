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

/// 设置或获取进度条当前进度
@property (nonatomic, assign) CGFloat progress;

@end

#pragma mark - FWIndicatorViewPlugin

/// 指示器视图样式枚举，可扩展
typedef NSInteger FWIndicatorViewStyle NS_TYPED_EXTENSIBLE_ENUM;
/// 白色指示器样式，默认
static const FWIndicatorViewStyle FWIndicatorViewStyleWhite = 0;
/// 灰色指示器样式
static const FWIndicatorViewStyle FWIndicatorViewStyleGray = 1;

/// 自定义指示器视图协议
@protocol FWIndicatorViewPlugin <NSObject>
@required

/// 开始加载动画
- (void)startAnimating;
/// 停止加载动画
- (void)stopAnimating;

@end

#pragma mark - FWViewPluginManager

/// 视图插件管理器
@interface FWViewPluginManager : NSObject

/// 单例模式
@property (class, nonatomic, readonly) FWViewPluginManager *sharedInstance;

/// 自定义进度视图生产句柄
@property (nullable, nonatomic, copy) UIView<FWProgressViewPlugin> * (^progressViewCreator)(FWProgressViewStyle style);

/// 自定义指示器视图生产句柄
@property (nullable, nonatomic, copy) UIView<FWIndicatorViewPlugin> * (^indicatorViewCreator)(FWIndicatorViewStyle style);

/// 进度视图工厂方法，默认FWProgressView
- (UIView<FWProgressViewPlugin> *)createProgressView:(FWProgressViewStyle)style;

/// 指示器视图工厂方法，默认UIActivityIndicatorView
- (UIView<FWIndicatorViewPlugin> *)createIndicatorView:(FWIndicatorViewStyle)style;

@end

NS_ASSUME_NONNULL_END
