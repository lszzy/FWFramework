//
//  ToolbarView.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWToolbarTitleView

@class __FWToolbarTitleView;

/// 自定义titleView协议
NS_SWIFT_NAME(TitleViewProtocol)
@protocol __FWTitleViewProtocol <NSObject>

@required
/// 当前标题文字，自动兼容VC.title和navigationItem.title调用
@property(nonatomic, copy, nullable) NSString *title;

@end

/// 自定义titleView事件代理
NS_SWIFT_NAME(ToolbarTitleViewDelegate)
@protocol __FWToolbarTitleViewDelegate <NSObject>

@optional

/**
 点击 titleView 后的回调，只需设置 titleView.userInteractionEnabled = YES 后即可使用

 @param titleView 被点击的 titleView
 @param isActive titleView 是否处于活跃状态
 */
- (void)didTouchTitleView:(__FWToolbarTitleView *)titleView isActive:(BOOL)isActive;

/**
 titleView 的活跃状态发生变化时会被调用，也即 [titleView setActive:] 被调用时。

 @param active 是否处于活跃状态
 @param titleView 变换状态的 titleView
 */
- (void)didChangedActive:(BOOL)active forTitleView:(__FWToolbarTitleView *)titleView;

@end

/// 自定义titleView布局方式，默认水平布局
typedef NS_ENUM(NSInteger, __FWToolbarTitleViewStyle) {
    __FWToolbarTitleViewStyleHorizontal = 0,
    __FWToolbarTitleViewStyleVertical,
} NS_SWIFT_NAME(ToolbarTitleViewStyle);

@protocol __FWIndicatorViewPlugin;

/**
 *  可作为导航栏标题控件，使用非等比例缩放布局，通过 navigationItem.titleView 来设置。也可当成单独的标题组件，脱离 UIViewController 使用
 *
 *  默认情况下 titleView 是不支持点击的，如需点击，请把 `userInteractionEnabled` 设为 `YES`
 *
 *  @see https://github.com/Tencent/QMUI_iOS
 */
NS_SWIFT_NAME(ToolbarTitleView)
@interface __FWToolbarTitleView : UIControl

/// 事件代理
@property(nonatomic, weak, nullable) id<__FWToolbarTitleViewDelegate> delegate;

/// 标题栏样式
@property(nonatomic, assign) __FWToolbarTitleViewStyle style;

/// 标题栏是否是激活状态，主要针对accessoryImage生效
@property(nonatomic, assign, getter=isActive) BOOL active;

/// 动画方式设置标题栏是否激活，主要针对accessoryImage生效
- (void)setActive:(BOOL)active animated:(BOOL)animated;

/// 标题栏最大显示宽度
@property(nonatomic, assign) CGFloat maximumWidth UI_APPEARANCE_SELECTOR;

/// 标题标签
@property(nonatomic, strong, readonly) UILabel *titleLabel;

/// 标题文字
@property(nonatomic, copy, nullable) NSString *title;

/// 副标题标签
@property(nonatomic, strong, readonly) UILabel *subtitleLabel;

/// 副标题
@property(nonatomic, copy, nullable) NSString *subtitle;

/// 是否适应tintColor变化，影响titleLabel、subtitleLabel、loadingView，默认YES
@property(nonatomic, assign) BOOL adjustsTintColor UI_APPEARANCE_SELECTOR;

/// 水平布局下的标题字体，默认为 加粗17
@property(nonatomic, strong) UIFont *horizontalTitleFont UI_APPEARANCE_SELECTOR;

/// 水平布局下的副标题的字体，默认为 加粗17
@property(nonatomic, strong) UIFont *horizontalSubtitleFont UI_APPEARANCE_SELECTOR;

/// 垂直布局下的标题字体，默认为 15
@property(nonatomic, strong) UIFont *verticalTitleFont UI_APPEARANCE_SELECTOR;

/// 垂直布局下的副标题字体，默认为 12
@property(nonatomic, strong) UIFont *verticalSubtitleFont UI_APPEARANCE_SELECTOR;

/// 标题的上下左右间距，标题不显示时不参与计算大小，默认为 UIEdgeInsetsZero
@property(nonatomic, assign) UIEdgeInsets titleEdgeInsets UI_APPEARANCE_SELECTOR;

/// 副标题的上下左右间距，副标题不显示时不参与计算大小，默认为 UIEdgeInsetsZero
@property(nonatomic, assign) UIEdgeInsets subtitleEdgeInsets UI_APPEARANCE_SELECTOR;

/// 标题栏左侧loading视图，可自定义，开启loading后才存在
@property(nonatomic, strong, nullable) UIView<__FWIndicatorViewPlugin> *loadingView;

/// 是否显示loading视图，开启后才会显示，默认NO
@property(nonatomic, assign) BOOL showsLoadingView;

/// 是否隐藏loading，开启之后生效，默认YES
@property(nonatomic, assign) BOOL loadingViewHidden;

/// 标题右侧是否显示和左侧loading一样的占位空间，默认YES
@property(nonatomic, assign) BOOL showsLoadingPlaceholder;

/// loading视图指定大小，默认(18, 18)
@property(nonatomic, assign) CGSize loadingViewSize UI_APPEARANCE_SELECTOR;

/// 指定loading右侧间距，默认3
@property(nonatomic, assign) CGFloat loadingViewSpacing UI_APPEARANCE_SELECTOR;

/// 自定义accessoryView，设置后accessoryImage无效，默认nil
@property(nonatomic, strong, nullable) UIView *accessoryView;

/// 自定义accessoryImage，accessoryView为空时才生效，默认nil
@property (nonatomic, strong, nullable) UIImage *accessoryImage;

/// 指定accessoryView偏移位置，默认(3, 0)
@property(nonatomic, assign) CGPoint accessoryViewOffset UI_APPEARANCE_SELECTOR;

/// 值为YES则title居中，`accessoryView`放在title的左边或右边；如果为NO，`accessoryView`和title整体居中；默认NO
@property(nonatomic, assign) BOOL showsAccessoryPlaceholder;

/// 同 accessoryView，用于 subtitle 的 AccessoryView，仅Vertical样式生效
@property(nonatomic, strong, nullable) UIView *subAccessoryView;

/// 指定subAccessoryView偏移位置，默认(3, 0)
@property(nonatomic, assign) CGPoint subAccessoryViewOffset UI_APPEARANCE_SELECTOR;

/// 同 showsAccessoryPlaceholder，用于 subtitle
@property(nonatomic, assign) BOOL showsSubAccessoryPlaceholder;

/// 整个titleView是否左对齐，需结合isExpandedSize使用，默认NO居中对齐
@property (nonatomic, assign) BOOL alignmentLeft;

/// 是否使用扩张尺寸，开启后会自动撑开到最大尺寸，默认NO
@property (nonatomic, assign) BOOL isExpandedSize;

/// 当titleView用于navigationBar且左对齐时，指定titleView离左侧的最小距离，默认为16同系统
@property (nonatomic, assign) CGFloat minimumLeftMargin;

/// 指定样式初始化
- (instancetype)initWithStyle:(__FWToolbarTitleViewStyle)style;

@end

NS_ASSUME_NONNULL_END
