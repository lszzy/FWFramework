/*!
 @header     FWToastPluginImpl.h
 @indexgroup FWFramework
 @brief      FWToastPlugin
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/22
 */

#import "FWToastPlugin.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWAppToastPlugin

/// 应用默认吐司插件
@interface FWAppToastPlugin : NSObject <FWToastPlugin>

/// 单例模式
@property (class, nonatomic, readonly) FWAppToastPlugin *sharedInstance;

/// 文本字体，默认16号
@property (nonatomic, strong) UIFont *textFont;
/// 文本颜色，默认白色
@property (nonatomic, strong) UIColor *textColor;
/// 指示器样式，默认medium
@property (nonatomic, assign) UIActivityIndicatorViewStyle indicatorStyle;
/// 指示器颜色，默认白色
@property (nonatomic, strong) UIColor *indicatorColor;
/// 吐司背景色，默认#404040
@property (nonatomic, strong) UIColor *backgroundColor;
/// 全局背景色，默认透明
@property (nonatomic, strong) UIColor *dimBackgroundColor;
/// 是否水平对齐，默认NO垂直对齐
@property (nonatomic, assign) BOOL horizontalAlignment;
/// 文本内间距，默认{10, 10, 10, 10}
@property (nonatomic, assign) UIEdgeInsets contentInsets;
/// 吐司左右最小内间距，默认10
@property (nonatomic, assign) CGFloat paddingWidth;
/// 指示器圆角半径，默认5.0
@property (nonatomic, assign) CGFloat cornerRadius;
/// 消息吐司自动隐藏延迟时间，默认2.0秒
@property (nonatomic, assign) NSTimeInterval delayTime;

#pragma mark - Public

/// 显示指示器，不可点击，返回指示器视图
- (UIView *)showIndicator:(nullable NSAttributedString *)attributedTitle inView:(UIView *)view;

/// 隐藏指示器，与show必须成对出现。指示器不存在时返回NO
- (BOOL)hideIndicator:(UIView *)view;

/// 延迟n秒后自动隐藏指示器，如果期间调用了show则取消隐藏，可避免连续show|hide时闪烁问题。指示器不存在时返回NO
- (BOOL)hideIndicatorAfterDelay:(NSTimeInterval)delay inView:(UIView *)view;

/// 显示吐司，默认不可点击，返回吐司视图。如需点击可设置userInteractionEnabled为NO
- (UIView *)showToast:(nullable NSAttributedString *)attributedText inView:(UIView *)view;

/// 手工隐藏吐司。吐司不存在时返回NO
- (BOOL)hideToast:(UIView *)view;

/// 延迟n秒后自动隐藏吐司。吐司不存在时返回NO
- (BOOL)hideToastAfterDelay:(NSTimeInterval)delay completion:(nullable void (^)(void))completion inView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
