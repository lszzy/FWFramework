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

#pragma mark - FWToastProgressView

/// 自定义吐司加载视图协议
@protocol FWToastLoadingViewProtocol <NSObject>
@optional

/// 当显示指示器时，将自动调用此处的startAnimating
- (void)startAnimating;

@end

/// 自定义吐司进度条视图协议
@protocol FWToastProgressViewProtocol <NSObject>
@optional

/// 当进度发生变化时，将自动调用此处的setProgress:
- (void)setProgress:(CGFloat)progress;

@end

/// 默认吐司进度条视图
@interface FWToastProgressView : UIView

/// 进度条颜色，默认白色
@property (nonatomic, strong) UIColor *progressColor;
/// 进度条宽度，默认2
@property (nonatomic, assign) CGFloat lineWidth;
/// 当前进度
@property (nonatomic, assign) CGFloat progress;

@end

#pragma mark - FWToastView

/// 吐司视图类型
typedef NS_ENUM(NSInteger, FWToastViewType) {
    /// 自定义吐司
    FWToastViewTypeCustom = 0,
    /// 文本吐司
    FWToastViewTypeText,
    /// 图片吐司
    FWToastViewTypeImage,
    /// 指示器吐司
    FWToastViewTypeIndicator,
    /// 进度条吐司
    FWToastViewTypeProgress,
};

/// 吐司视图，默认背景色透明
@interface FWToastView : UIControl

/// 当前吐司类型，只读
@property (nonatomic, readonly) FWToastViewType type;

/// 内容视图，可设置背景色(默认#404040)、圆角(默认5)，只读
@property (nonatomic, readonly) UIView *contentView;
/// 自定义视图，仅Custom生效
@property (nonatomic, strong, nullable) UIView *customView;
/// 图片视图，仅Image存在
@property (nonatomic, readonly, nullable) UIImageView *imageView;
/// 指示器视图，仅Loading存在
@property (nonatomic, readonly, nullable) UIActivityIndicatorView *indicatorView;
/// 进度条视图，仅Progress存在
@property (nonatomic, readonly, nullable) FWToastProgressView *progressView;
/// 标题标签，都存在，有内容时才显示
@property (nonatomic, readonly) UILabel *titleLabel;

/// 内容背景色，默认#404040
@property (nonatomic, strong) UIColor *contentBackgroundColor UI_APPEARANCE_SELECTOR;
/// 内容视图最小外间距，默认{10, 10, 10, 10}
@property (nonatomic, assign) UIEdgeInsets contentMarginInsets UI_APPEARANCE_SELECTOR;
/// 内容视图内间距，默认{10, 10, 10, 10}
@property (nonatomic, assign) UIEdgeInsets contentInsets UI_APPEARANCE_SELECTOR;
/// 视图和文本之间的间距，默认5.0
@property (nonatomic, assign) CGFloat contentSpacing UI_APPEARANCE_SELECTOR;
/// 内容圆角半径，默认5.0
@property (nonatomic, assign) CGFloat contentCornerRadius UI_APPEARANCE_SELECTOR;
/// 是否水平对齐，默认NO垂直对齐
@property (nonatomic, assign) BOOL horizontalAlignment UI_APPEARANCE_SELECTOR;
/// 指示器图片，支持动画图片，自适应大小，仅Image生效
@property (nonatomic, strong, nullable) UIImage *indicatorImage;
/// 指示器样式，默认medium，仅Loading生效
@property (nonatomic, assign) UIActivityIndicatorViewStyle indicatorStyle UI_APPEARANCE_SELECTOR;
/// 指示器颜色，默认白色，仅Loading生效
@property (nonatomic, strong) UIColor *indicatorColor UI_APPEARANCE_SELECTOR;
/// 指示器大小，默认根据类型处理
@property (nonatomic, assign) CGSize indicatorSize UI_APPEARANCE_SELECTOR;
/// 标题字体，默认16号
@property (nonatomic, strong) UIFont *titleFont UI_APPEARANCE_SELECTOR;
/// 标题颜色，默认白色
@property (nonatomic, strong) UIColor *titleColor UI_APPEARANCE_SELECTOR;

/// 带属性标题文本，为空时不显示
@property (nonatomic, copy, nullable) NSAttributedString *attributedTitle;
/// 当前指示器进度值，范围0~1，仅Progress生效
@property (nonatomic, assign) CGFloat progress;

/// 初始化指定类型指示器
- (instancetype)initWithType:(FWToastViewType)type;

/// 显示吐司，不执行动画
- (void)show;

/// 显示吐司，执行淡入渐变动画
- (void)showAnimated:(BOOL)animated;

/// 隐藏吐司。吐司不存在时返回NO
- (BOOL)hide;

/// 隐藏吐司，延迟指定时间后执行。吐司不存在时返回NO
- (BOOL)hideAfterDelay:(NSTimeInterval)delay completion:(nullable void (^)(void))completion;

/// 清理延迟隐藏吐司定时器
- (void)invalidateTimer;

@end

#pragma mark - FWToastPluginImpl

/// 默认吐司插件
@interface FWToastPluginImpl : NSObject <FWToastPlugin>

/// 单例模式
@property (class, nonatomic, readonly) FWToastPluginImpl *sharedInstance;

/// 显示吐司时是否执行淡入动画，默认YES
@property (nonatomic, assign) BOOL fadeAnimated;
/// 吐司自动隐藏时间，默认2.0
@property (nonatomic, assign) NSTimeInterval delayTime;
/// 吐司自定义句柄，show方法自动调用
@property (nonatomic, copy, nullable) void (^customBlock)(FWToastView *toastView);

/// 默认加载吐司文本句柄
@property (nonatomic, copy, nullable) NSAttributedString * _Nullable (^defaultLoadingText)(void);
/// 默认进度条吐司文本句柄
@property (nonatomic, copy, nullable) NSAttributedString * _Nullable (^defaultProgressText)(void);
/// 默认消息吐司文本句柄
@property (nonatomic, copy, nullable) NSAttributedString * _Nullable (^defaultMessageText)(FWToastStyle style);

@end

NS_ASSUME_NONNULL_END
