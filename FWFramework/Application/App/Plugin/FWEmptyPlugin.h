/*!
 @header     FWEmptyPlugin.h
 @indexgroup FWFramework
 @brief      FWEmptyPlugin
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/3
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWEmptyPlugin

/// 空界面插件协议，应用可自定义空界面插件实现
@protocol FWEmptyPlugin <NSObject>

@optional

/// 显示空界面，指定文本、图片和动作按钮
- (void)fwShowEmptyViewWithText:(nullable NSString *)text detail:(nullable NSString *)detail image:(nullable UIImage *)image action:(nullable NSString *)action block:(nullable void (^)(id sender))block inView:(UIView *)view;

/// 隐藏空界面
- (void)fwHideEmptyView:(UIView *)view;

/// 是否存在显示中的空界面
- (BOOL)fwExistsEmptyView:(UIView *)view;

@end

/// 空界面插件配置类
@interface FWEmptyPluginConfig : NSObject

/// 配置单例
@property (class, nonatomic, readonly) FWEmptyPluginConfig *sharedInstance;

/// 默认空界面文本句柄
@property (nonatomic, copy, nullable) NSString * _Nullable (^defaultText)(void);
/// 默认空界面详细文本句柄
@property (nonatomic, copy, nullable) NSString * _Nullable (^defaultDetail)(void);
/// 默认空界面图片句柄
@property (nonatomic, copy, nullable) UIImage * _Nullable (^defaultImage)(void);
/// 默认空界面动作按钮句柄
@property (nonatomic, copy, nullable) NSString * _Nullable (^defaultAction)(void);

@end

#pragma mark - UIView+FWEmptyPlugin

/*!
 @brief UIView+FWEmptyPlugin
 */
@interface UIView (FWEmptyPlugin)

/// 显示空界面
- (void)fwShowEmptyView;

/// 显示空界面，指定文本
- (void)fwShowEmptyViewWithText:(nullable NSString *)text;

/// 显示空界面，指定文本和详细文本
- (void)fwShowEmptyViewWithText:(nullable NSString *)text detail:(nullable NSString *)detail;

/// 显示空界面，指定文本、详细文本和图片
- (void)fwShowEmptyViewWithText:(nullable NSString *)text detail:(nullable NSString *)detail image:(nullable UIImage *)image;

/// 显示空界面，指定文本、详细文本、图片和动作按钮
- (void)fwShowEmptyViewWithText:(nullable NSString *)text detail:(nullable NSString *)detail image:(nullable UIImage *)image action:(nullable NSString *)action block:(nullable void (^)(id sender))block;

/// 隐藏空界面
- (void)fwHideEmptyView;

/// 是否存在显示中的空界面
- (BOOL)fwExistsEmptyView;

@end

#pragma mark - FWEmptyView

@protocol FWEmptyLoadingViewProtocol <NSObject>

@optional

// 当调用 setLoadingViewHidden:NO 时，系统将自动调用此处的 startAnimating
- (void)startAnimating;

@end

/*!
 @brief 通用的空界面控件，支持显示 loading、标题和副标题提示语、占位图片
 
 @see https://github.com/Tencent/QMUI_iOS
 */
@interface FWEmptyView : UIView

// 布局顺序从上到下依次为：imageView, loadingView, textLabel, detailTextLabel, actionButton
@property(nonatomic, strong) UIView<FWEmptyLoadingViewProtocol> *loadingView;   // 此控件通过设置 loadingView.hidden 来控制 loadinView 的显示和隐藏，因此请确保你的loadingView 没有类似于 hidesWhenStopped = YES 之类会使 view.hidden 失效的属性
@property(nonatomic, strong, readonly) UIImageView *imageView;
@property(nonatomic, strong, readonly) UILabel *textLabel;
@property(nonatomic, strong, readonly) UILabel *detailTextLabel;
@property(nonatomic, strong, readonly) UIButton *actionButton;

// 可通过调整这些insets来控制间距
@property(nonatomic, assign) UIEdgeInsets imageViewInsets UI_APPEARANCE_SELECTOR;   // 默认为(0, 0, 36, 0)
@property(nonatomic, assign) UIEdgeInsets loadingViewInsets UI_APPEARANCE_SELECTOR;     // 默认为(0, 0, 36, 0)
@property(nonatomic, assign) UIEdgeInsets textLabelInsets UI_APPEARANCE_SELECTOR;   // 默认为(0, 0, 10, 0)
@property(nonatomic, assign) UIEdgeInsets detailTextLabelInsets UI_APPEARANCE_SELECTOR; // 默认为(0, 0, 10, 0)
@property(nonatomic, assign) UIEdgeInsets actionButtonInsets UI_APPEARANCE_SELECTOR;    // 默认为(0, 0, 0, 0)
@property(nonatomic, assign) CGFloat verticalOffset UI_APPEARANCE_SELECTOR; // 如果不想要内容整体垂直居中，则可通过调整此属性来进行垂直偏移。默认为-30，即内容比中间略微偏上

// 字体
@property(nonatomic, strong) UIFont *textLabelFont UI_APPEARANCE_SELECTOR;  // 默认为15pt系统字体
@property(nonatomic, strong) UIFont *detailTextLabelFont UI_APPEARANCE_SELECTOR;    // 默认为14pt系统字体
@property(nonatomic, strong) UIFont *actionButtonFont UI_APPEARANCE_SELECTOR;   // 默认为15pt系统字体

// 颜色
@property(nonatomic, strong) UIColor *textLabelTextColor UI_APPEARANCE_SELECTOR;    // 默认为(93, 100, 110)
@property(nonatomic, strong) UIColor *detailTextLabelTextColor UI_APPEARANCE_SELECTOR;  // 默认为(133, 140, 150)
@property(nonatomic, strong) UIColor *actionButtonTitleColor UI_APPEARANCE_SELECTOR;    // 默认为 ButtonTintColor

// 显示或隐藏loading图标
- (void)setLoadingViewHidden:(BOOL)hidden;

/**
 * 设置要显示的图片
 * @param image 要显示的图片，为nil则不显示
 */
- (void)setImage:(nullable UIImage *)image;

/**
 * 设置提示语
 * @param text 提示语文本，若为nil则隐藏textLabel
 */
- (void)setTextLabelText:(nullable NSString *)text;

/**
 * 设置详细提示语的文本
 * @param text 详细提示语文本，若为nil则隐藏detailTextLabel
 */
- (void)setDetailTextLabelText:(nullable NSString *)text;

/**
 * 设置操作按钮的文本
 * @param title 操作按钮的文本，若为nil则隐藏actionButton
 */
- (void)setActionButtonTitle:(nullable NSString *)title;

/**
 *  如果要继承QMUIEmptyView并添加新的子 view，则必须：
 *  1. 像其它自带 view 一样添加到 contentView 上
 *  2. 重写sizeThatContentViewFits
 */
@property(nonatomic, strong, readonly) UIView *contentView;

/// 返回一个恰好容纳所有子 view 的大小
- (CGSize)sizeThatContentViewFits;

@end

#pragma mark - UIScrollView+FWEmptyView

/// 空界面代理协议
@protocol FWEmptyViewDelegate <NSObject>
@optional

/// 显示空界面，contentView为空界面容器
- (void)fwShowEmptyView:(UIView *)contentView scrollView:(UIScrollView *)scrollView;

/// 隐藏空界面，contentView为空界面容器
- (void)fwHideEmptyView:(UIView *)contentView scrollView:(UIScrollView *)scrollView;

/// 显示空界面时是否允许滚动，默认NO
- (BOOL)fwEmptyViewShouldScroll:(UIScrollView *)scrollView;

/// 无数据时是否显示空界面，默认YES
- (BOOL)fwEmptyViewShouldDisplay:(UIScrollView *)scrollView;

/// 有数据时是否强制显示空界面，默认NO
- (BOOL)fwEmptyViewForceDisplay:(UIScrollView *)scrollView;

@end

/**
 @brief 滚动视图空界面分类
 
 @see https://github.com/dzenbot/DZNEmptyDataSet
 */
@interface UIScrollView (FWEmptyView)

/// 空界面代理，默认nil
@property (nonatomic, weak, nullable) IBOutlet id<FWEmptyViewDelegate> fwEmptyViewDelegate;

/// 是否正在显示空界面
@property (nonatomic, assign, readonly) BOOL fwIsEmptyViewVisible;

/// 刷新空界面
- (void)fwReloadEmptyView;

@end

NS_ASSUME_NONNULL_END
