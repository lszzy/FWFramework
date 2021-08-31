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

/// 进度值，0.0到1.0，默认0
@property (nonatomic, assign) CGFloat progress;

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

/// 是否显示百分比文本，默认NO
@property (nonatomic, assign) BOOL showsPercentText;

/// 百分比文本颜色，默认白色
@property (nonatomic, strong) UIColor *percentTextColor;

/// 百分比文本字体，默认12号字体
@property (nonatomic, strong) UIFont *percentFont;

@end

#pragma mark - FWIndicatorView

/// UIActivityIndicatorView默认实现加载视图协议
@interface UIActivityIndicatorView (FWIndicatorView) <FWIndicatorViewPlugin>

@end

NS_ASSUME_NONNULL_END
