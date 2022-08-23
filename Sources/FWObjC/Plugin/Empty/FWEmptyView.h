//
//  FWEmptyView.h
//  
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWEmptyView

@protocol FWIndicatorViewPlugin;

/**
 * 通用的空界面控件，布局顺序从上到下依次为：imageView, loadingView, textLabel, detailTextLabel, actionButton
 *
 * @see https://github.com/Tencent/QMUI_iOS
 */
NS_SWIFT_NAME(PlaceholderView)
@interface FWEmptyView : UIView

/// 此控件通过设置 loadingView.hidden 来控制 loadinView 的显示和隐藏，因此请确保你的loadingView 没有类似于 hidesWhenStopped = YES 之类会使 view.hidden 失效的属性
@property(nonatomic, strong) UIView<FWIndicatorViewPlugin> *loadingView;
/// 图片控件
@property(nonatomic, strong, readonly) UIImageView *imageView;
/// 文本控件
@property(nonatomic, strong, readonly) UILabel *textLabel;
/// 详细文本控件
@property(nonatomic, strong, readonly) UILabel *detailTextLabel;
/// 动作按钮控件
@property(nonatomic, strong, readonly) UIButton *actionButton;
/// 更多动作按钮控件，默认隐藏
@property(nonatomic, strong, readonly) UIButton *moreActionButton;

/// 内容视图间距，默认为(0, 16, 0, 16)
@property(nonatomic, assign) UIEdgeInsets contentViewInsets UI_APPEARANCE_SELECTOR;
/// 图片视图间距，默认为(0, 0, 36, 0)
@property(nonatomic, assign) UIEdgeInsets imageViewInsets UI_APPEARANCE_SELECTOR;
/// 加载视图间距，默认为(0, 0, 36, 0)
@property(nonatomic, assign) UIEdgeInsets loadingViewInsets UI_APPEARANCE_SELECTOR;
/// 文本视图间距，默认为(0, 0, 10, 0)
@property(nonatomic, assign) UIEdgeInsets textLabelInsets UI_APPEARANCE_SELECTOR;
/// 详细文本视图间距，默认为(0, 0, 10, 0)
@property(nonatomic, assign) UIEdgeInsets detailTextLabelInsets UI_APPEARANCE_SELECTOR;
/// 动作按钮间距，默认为(0, 0, 0, 0)
@property(nonatomic, assign) UIEdgeInsets actionButtonInsets UI_APPEARANCE_SELECTOR;
/// 更多动作按钮间距，默认为(0, 24, 0, 0)
@property(nonatomic, assign) UIEdgeInsets moreActionButtonInsets;
/// 如果不想要内容整体垂直居中，则可通过调整此属性来进行垂直偏移。默认为-30，即内容比中间略微偏上
@property(nonatomic, assign) CGFloat verticalOffset UI_APPEARANCE_SELECTOR;
/// 自定义垂直偏移句柄，参数依次为总高度，内容高度，图片高度
@property(nonatomic, copy, nullable) CGFloat (^verticalOffsetBlock)(CGFloat totalHeight, CGFloat contentHeight, CGFloat imageHeight);

/// textLabel字体，默认为15pt系统字体
@property(nonatomic, strong) UIFont *textLabelFont UI_APPEARANCE_SELECTOR;
/// detailTextLabel字体，默认为14pt系统字体
@property(nonatomic, strong) UIFont *detailTextLabelFont UI_APPEARANCE_SELECTOR;
/// actionButton标题字体，默认为15pt系统字体
@property(nonatomic, strong) UIFont *actionButtonFont UI_APPEARANCE_SELECTOR;
/// moreActionButton标题字体，默认为15pt系统字体
@property(nonatomic, strong) UIFont *moreActionButtonFont UI_APPEARANCE_SELECTOR;

/// loadingView颜色，默认灰色
@property(nonatomic, strong) UIColor *loadingViewColor UI_APPEARANCE_SELECTOR;
/// textLabel文本颜色，默认为(93, 100, 110)
@property(nonatomic, strong) UIColor *textLabelTextColor UI_APPEARANCE_SELECTOR;
/// detailTextLabel文本颜色，默认为(133, 140, 150)
@property(nonatomic, strong) UIColor *detailTextLabelTextColor UI_APPEARANCE_SELECTOR;
/// actionButton标题颜色，默认为 ButtonTintColor
@property(nonatomic, strong) UIColor *actionButtonTitleColor UI_APPEARANCE_SELECTOR;
/// moreActionButton标题颜色，默认为 ButtonTintColor
@property(nonatomic, strong) UIColor *moreActionButtonTitleColor UI_APPEARANCE_SELECTOR;

/// 显示或隐藏loading图标
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
 * 设置更多操作按钮的文本
 * @param title 操作按钮的文本，若为nil则隐藏moreActionButton
 */
- (void)setMoreActionButtonTitle:(nullable NSString *)title;

/**
 *  如果要继承QMUIEmptyView并添加新的子 view，则必须：
 *  1. 像其它自带 view 一样添加到 contentView 上
 *  2. 重写sizeThatContentViewFits
 */
@property(nonatomic, strong, readonly) UIView *contentView;

/// 返回一个恰好容纳所有子 view 的大小
- (CGSize)sizeThatContentViewFits;

@end

#pragma mark - UIScrollView+FWScrollOverlayView

NS_SWIFT_NAME(ScrollOverlayView)
@interface FWScrollOverlayView : UIView

@end

@interface UIScrollView (FWScrollOverlayView)

/// 滚动视图自定义浮层，用于显示空界面等，兼容UITableView|UICollectionView
@property (nonatomic, strong, readonly) UIView *fw_overlayView NS_REFINED_FOR_SWIFT;

/// 是否显示自定义浮层
@property (nonatomic, assign, readonly) BOOL fw_hasOverlayView NS_REFINED_FOR_SWIFT;

/// 显示自定义浮层，自动添加到滚动视图顶部、表格视图底部
- (void)fw_showOverlayView NS_REFINED_FOR_SWIFT;

/// 显示自定义浮层，执行渐变动画，自动添加到滚动视图顶部、表格视图底部
- (void)fw_showOverlayViewAnimated:(BOOL)animated NS_REFINED_FOR_SWIFT;

/// 隐藏自定义浮层，自动从滚动视图移除
- (void)fw_hideOverlayView NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
