//
//  FWViewPluginImpl.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "FWViewPlugin.h"
#import "FWIndicatorView.h"
#import "FWProgressView.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIActivityIndicatorView+FWViewPlugin

/// 系统指示器默认实现指示器视图协议
@interface UIActivityIndicatorView (FWViewPlugin) <FWIndicatorViewPlugin, FWProgressViewPlugin>

/// 设置或获取指示器大小，默认中{20,20}，大{37,37}
@property (nonatomic, assign) CGSize size;

/// 指示器进度，大于0小于1时开始动画，其它值停止动画。同setProgress:animated:
@property (nonatomic, assign) CGFloat progress;

/// 设置指示器进度，大于0小于1时开始动画，其它值停止动画。同setProgress:
- (void)setProgress:(CGFloat)progress animated:(BOOL)animated;

/// 快速创建指示器，可指定颜色，默认白色
+ (UIActivityIndicatorView *)fw_indicatorViewWithColor:(nullable UIColor *)color NS_REFINED_FOR_SWIFT;

@end

#pragma mark - FWViewPluginImpl

/// 默认视图插件
NS_SWIFT_NAME(ViewPluginImpl)
@interface FWViewPluginImpl : NSObject <FWViewPlugin>

/// 单例模式
@property (class, nonatomic, readonly) FWViewPluginImpl *sharedInstance NS_SWIFT_NAME(shared);

/// 自定义进度视图生产句柄，默认FWProgressView
@property (nullable, nonatomic, copy) UIView<FWProgressViewPlugin> * (^customProgressView)(FWProgressViewStyle style);

/// 自定义指示器视图生产句柄，默认UIActivityIndicatorView
@property (nullable, nonatomic, copy) UIView<FWIndicatorViewPlugin> * (^customIndicatorView)(FWIndicatorViewStyle style);

@end

NS_ASSUME_NONNULL_END
