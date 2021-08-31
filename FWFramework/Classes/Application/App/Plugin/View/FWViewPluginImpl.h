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

/// 是否显示环形样式，默认YES，NO为扇形样式
@property (nonatomic, assign) BOOL annular;

/// 进度值，0.0到1.0
@property (nonatomic, assign) CGFloat progress;

/// 进度颜色，默认白色
@property (nonatomic, strong) UIColor *color;

/// 填充颜色，默认nil不填充
@property (nonatomic, strong, nullable) UIColor *fillColor;

/// 线条宽度，仅环形生效，默认3.0f
@property (nonatomic, assign) CGFloat lineWidth;

/// 线条颜色，仅环形生效，默认白色透明度0.1
@property (nonatomic, strong) UIColor *lineColor;

/// 线条样式，仅环形生效，默认kCGLineCapRound
@property (nonatomic, assign) CGLineCap lineCapStyle;

/// 外边框大小，仅扇形生效，默认1
@property (nonatomic, assign) CGFloat borderWidth;

/// 外边框颜色，仅扇形生效，默认白色
@property (nonatomic, strong) UIColor *borderColor;

/// 外边框内边距大小，仅扇形生效，默认0
@property (nonatomic, assign) CGFloat borderInset;

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
