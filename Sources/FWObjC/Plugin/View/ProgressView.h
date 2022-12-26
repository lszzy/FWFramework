//
//  ProgressView.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "ViewPlugin.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWProgressView

/// 框架默认进度条视图
NS_SWIFT_NAME(ProgressView)
@interface FWProgressView : UIView <FWProgressViewPlugin>

/// 是否是环形，默认YES，NO为扇形
@property (nonatomic, assign) BOOL annular;

/// 进度颜色，默认白色
@property (nonatomic, strong) UIColor *color;

/// 设置或获取进度条大小，默认{37, 37}
@property (nonatomic, assign) CGSize size;

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

NS_ASSUME_NONNULL_END
