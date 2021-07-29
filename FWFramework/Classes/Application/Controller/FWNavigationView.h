/*!
 @header     FWNavigationView.h
 @indexgroup FWFramework
 @brief      FWNavigationView
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/2/14
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWNavigationView

/**
 * 自定义导航栏视图，高度自动布局，隐藏时自动收起
 */
@interface FWNavigationView : UIView

#pragma mark - Height

/// 自定义状态栏高度，隐藏时自动收起，默认FWStatusBarHeight
@property (nonatomic, assign) CGFloat statusBarHeight;

/// 自定义导航栏高度，隐藏时自动收起，默认0自适应
@property (nonatomic, assign) CGFloat navigationBarHeight;

/// 自定义附加高度，隐藏时自动收起，默认0
@property (nonatomic, assign) CGFloat addtionalHeight;

#pragma mark - Bar

/// 自定义导航栏，默认高度自适应，可隐藏
@property (nonatomic, strong, readonly) UINavigationBar *navigationBar;

/// 自定义导航项，可设置标题、按钮等
@property (nonatomic, strong, readonly) UINavigationItem *navigationItem;

/// 绑定scrollView，自动处理iOS11以上largeTitles动画，默认nil
@property (nonatomic, weak, nullable) UIScrollView *scrollView;

@property (nonatomic, assign) BOOL statusBarHidden;
@property (nonatomic, assign) BOOL navigationBarHidden;

#pragma mark - View

@property (nonatomic, strong, readonly) UIView *contentView;

@end

#pragma mark - UIViewController+FWNavigationView

/**
 * 控制器自定义导航栏
 *
 * 原则：优先用系统导航栏，不满足时才使用自定义导航栏
 * 注意：启用自定义导航栏后，虽然兼容FWNavigationStyle方法，但有几点不同，列举如下：
 * 1. VC容器视图为fwView，所有子视图应该添加到fwView；fwView兼容系统导航栏view和edgesForExtendedLayout
 * 2. fwNavigationView位于VC.view顶部；fwView位于VC.view底部，顶部对齐fwNavigationView.底部
 * 3. VC返回按钮会使用自身的backBarButtonItem，兼容系统导航栏动态切换；而系统VC会使用前一个控制器的backBarButtonItem
 * 4. 支持切换largeTitles样式，但默认不支持动画效果；可手工处理或绑定scrollView自动处理
 * 如果从系统导航栏动态迁移到自定义导航栏，注意检查导航相关功能是否异常
 */
@interface UIViewController (FWNavigationView)

/// 是否启用自定义导航栏，需在init中设置或子类重写，默认NO
@property (nonatomic, assign) BOOL fwNavigationViewEnabled;

/// 自定义导航栏视图，fwNavigationViewEnabled为YES时生效
@property (nonatomic, strong, readonly) FWNavigationView *fwNavigationView;

/// 当前导航栏，默认navigationController.navigationBar，用于兼容自定义导航栏
@property (nullable, nonatomic, readonly) UINavigationBar *fwNavigationBar;

/// 当前导航项，默认navigationItem，用于兼容自定义导航栏
@property (nonatomic, strong, readonly) UINavigationItem *fwNavigationItem;

/// 当前视图，默认view，用于兼容自定义导航栏
@property (nonatomic, strong, readonly) UIView *fwView;

@end

#pragma mark - FWNavigationTitleView

@class FWNavigationTitleView;

/// 自定义titleView协议
@protocol FWNavigationTitleViewProtocol <NSObject>

@required

/// 当前标题文字，自动兼容VC.title和navigationItem.title调用
@property(nonatomic, copy, nullable) NSString *title;

@end

/// 自定义titleView事件代理
@protocol FWNavigationTitleViewDelegate <NSObject>

@optional

/**
 点击 titleView 后的回调，只需设置 titleView.userInteractionEnabled = YES 后即可使用

 @param titleView 被点击的 titleView
 @param isActive titleView 是否处于活跃状态
 */
- (void)didTouchTitleView:(FWNavigationTitleView *)titleView isActive:(BOOL)isActive;

/**
 titleView 的活跃状态发生变化时会被调用，也即 [titleView setActive:] 被调用时。

 @param active 是否处于活跃状态
 @param titleView 变换状态的 titleView
 */
- (void)didChangedActive:(BOOL)active forTitleView:(FWNavigationTitleView *)titleView;

@end

/// 自定义titleView布局方式，默认水平布局
typedef NS_ENUM(NSInteger, FWNavigationTitleViewStyle) {
    FWNavigationTitleViewStyleHorizontal = 0,
    FWNavigationTitleViewStyleVertical,
};

/**
 *  可作为导航栏标题控件，通过 navigationItem.titleView 来设置。也可当成单独的组件，脱离 UIViewController 使用
 *
 *  默认情况下 titleView 是不支持点击的，如需点击，请把 `userInteractionEnabled` 设为 `YES`
 *
 *  @see https://github.com/Tencent/QMUI_iOS
 */
@interface FWNavigationTitleView : UIControl <FWNavigationTitleViewProtocol>

/// 事件代理
@property(nonatomic, weak, nullable) id<FWNavigationTitleViewDelegate> delegate;

/// 标题栏样式
@property(nonatomic, assign) FWNavigationTitleViewStyle style;

/// 标题栏是否是激活状态，主要针对accessoryImage生效
@property(nonatomic, assign, getter=isActive) BOOL active;

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

/// 标题栏左侧loading视图，开启loading后才存在
@property(nonatomic, strong, readonly, nullable) UIActivityIndicatorView *loadingView;

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

/// 指定样式初始化
- (instancetype)initWithStyle:(FWNavigationTitleViewStyle)style;

@end

#pragma mark - FWNavigationButton

/**
 * 自定义导航栏按钮，兼容系统customView方式和自定义方式
 *
 * UIBarButtonItem自定义导航栏时最左和最右间距为16，系统导航栏时为8；FWNavigationButton作为customView使用时，会自动调整按钮内间距，和系统表现一致
 */
@interface FWNavigationButton : UIButton

/// UIBarButtonItem默认都是跟随tintColor的，所以这里声明是否让图片也是用AlwaysTemplate模式，默认YES
@property (nonatomic, assign) BOOL adjustsTintColor;

/// 初始化标题类型按钮，默认内间距：{8, 8, 8, 8}，可自定义
- (instancetype)initWithTitle:(nullable NSString *)title;

/// 初始化图片类型按钮，默认内间距：{8, 8, 8, 8}，可自定义
- (instancetype)initWithImage:(nullable UIImage *)image;

@end

NS_ASSUME_NONNULL_END
