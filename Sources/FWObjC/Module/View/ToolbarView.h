//
//  ToolbarView.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWToolbarView

/// 自定义工具栏视图类型枚举
typedef NS_ENUM(NSInteger, __FWToolbarViewType) {
    /// 默认工具栏，含菜单和底部，无titleView，自动兼容横屏
    __FWToolbarViewTypeDefault = 0,
    /// 导航栏类型，含顶部和菜单，自带titleView，自动兼容横屏
    __FWToolbarViewTypeNavBar,
    /// 标签栏类型，含菜单和底部，水平等分，自动兼容横屏
    __FWToolbarViewTypeTabBar,
    /// 自定义类型，无顶部和底部，初始高度44，需手工兼容横屏
    __FWToolbarViewTypeCustom,
} NS_SWIFT_NAME(ToolbarViewType);

@class __FWToolbarMenuView;

/**
 * 自定义工具栏视图，高度自动布局(总高度toolbarHeight)，可设置toolbarHidden隐藏(总高度0)
 *
 * 根据toolbarPosition自动设置默认高度，可自定义，如下：
 * 顶部：topView，高度为topHeight，可设置topHidden隐藏
 * 中间：menuView，高度为menuHeight，可设置menuHidden隐藏
 * 底部：bottomView，高度为bottomHeight，可设置bottomHidden隐藏
 */
NS_SWIFT_NAME(ToolbarView)
@interface __FWToolbarView : UIView

/// 指定类型初始化，会设置默认高度和视图
- (instancetype)initWithType:(__FWToolbarViewType)type;

/// 当前工具栏类型，只读，默认default
@property (nonatomic, assign, readonly) __FWToolbarViewType type;
/// 背景图片视图，用于设置背景图片
@property (nonatomic, strong, readonly) UIImageView *backgroundView;
/// 顶部视图，延迟加载
@property (nonatomic, strong, readonly) UIView *topView;
/// 菜单视图，初始加载
@property (nonatomic, strong, readonly) __FWToolbarMenuView *menuView;
/// 底部视图，延迟加载
@property (nonatomic, strong, readonly) UIView *bottomView;

/// 顶部高度，根据类型初始化
@property (nonatomic, assign) CGFloat topHeight;
/// 菜单高度，根据类型初始化
@property (nonatomic, assign) CGFloat menuHeight;
/// 底部高度，根据类型初始化
@property (nonatomic, assign) CGFloat bottomHeight;
/// 工具栏总高度，topHeight+menuHeight+bottomHeight，隐藏时为0
@property (nonatomic, assign, readonly) CGFloat toolbarHeight;

/// 顶部栏是否隐藏，默认NO
@property (nonatomic, assign) BOOL topHidden;
/// 菜单是否隐藏，默认NO
@property (nonatomic, assign) BOOL menuHidden;
/// 底部栏是否隐藏，默认NO
@property (nonatomic, assign) BOOL bottomHidden;
/// 工具栏是否隐藏，默认NO，推荐使用(系统hidden切换时无动画)
@property (nonatomic, assign) BOOL toolbarHidden;

/// 动态隐藏顶部栏
- (void)setTopHidden:(BOOL)hidden animated:(BOOL)animated;
/// 动态隐藏菜单栏
- (void)setMenuHidden:(BOOL)hidden animated:(BOOL)animated;
/// 动态隐藏底部栏
- (void)setBottomHidden:(BOOL)hidden animated:(BOOL)animated;
/// 动态隐藏工具栏
- (void)setToolbarHidden:(BOOL)hidden animated:(BOOL)animated;

@end

#pragma mark - __FWToolbarMenuView

@class __FWToolbarTitleView;

/**
 * 自定义工具栏菜单视图，支持完全自定义，默认最多只支持左右各两个按钮，如需更多按钮，请自行添加。
 *
 * 水平分割时，按钮水平等分；非水平分割时，左右侧间距为8，同系统一致
 */
NS_SWIFT_NAME(ToolbarMenuView)
@interface __FWToolbarMenuView : UIView

/// 自定义左侧按钮，设置后才显示，非等分时左侧间距为8。建议使用__FWToolbarButton
@property (nonatomic, strong, nullable) __kindof UIView *leftButton;

/// 自定义左侧更多按钮，设置后才显示，非等分时左侧间距为8。建议使用__FWToolbarButton
@property (nonatomic, strong, nullable) __kindof UIView *leftMoreButton;

/// 自定义居中按钮，设置后才显示，非等分时左右最大间距为0。建议使用__FWToolbarTitleView或__FWToolbarButton
@property (nonatomic, strong, nullable) __kindof UIView *centerButton;

/// 自定义右侧更多按钮，设置后才显示，非等分时右侧间距为8。建议使用__FWToolbarButton
@property (nonatomic, strong, nullable) __kindof UIView *rightMoreButton;

/// 自定义右侧按钮，设置后才显示，非等分时右侧间距为8。建议使用__FWToolbarButton
@property (nonatomic, strong, nullable) __kindof UIView *rightButton;

/// 是否等宽布局(类似UITabBar)，不含安全区域；默认NO，左右布局(类似UIToolbar|UINavigationBar)
@property (nonatomic, assign) BOOL equalWidth;

/// 快捷访问__FWToolbarTitleView标题视图，同centerButton
@property (nonatomic, strong, nullable) __FWToolbarTitleView *titleView;

/// 快捷访问标题，titleView类型为__FWToolbarTitleViewProtocol时才生效
@property (nonatomic, copy, nullable) NSString *title;

@end

#pragma mark - __FWToolbarTitleView

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
 *  可作为导航栏标题控件，通过 navigationItem.titleView 来设置。也可当成单独的标题组件，脱离 UIViewController 使用
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

/// 指定样式初始化
- (instancetype)initWithStyle:(__FWToolbarTitleViewStyle)style;

@end

#pragma mark - __FWToolbarButton

/**
 * 自定义工具栏按钮，兼容系统customView方式和自定义方式
 *
 * UIBarButtonItem自定义导航栏时最左和最右间距为16，系统导航栏时为8；
 * __FWToolbarButton作为customView使用时，会自动调整按钮内间距，和系统表现一致；
 * __FWToolbarButton自动适配横竖屏切换，竖屏时默认内间距{8, 8, 8, 8}，横屏时默认内间距{0,8,0,8}
 */
NS_SWIFT_NAME(ToolbarButton)
@interface __FWToolbarButton : UIButton

/// UIBarButtonItem默认都是跟随tintColor的，所以这里声明是否让图片也是用AlwaysTemplate模式，默认YES
@property (nonatomic, assign) BOOL adjustsTintColor;

/// 指定标题初始化，自适应内边距，可自定义
- (instancetype)initWithTitle:(nullable NSString *)title;

/// 指定图片初始化，自适应内边距，可自定义
- (instancetype)initWithImage:(nullable UIImage *)image;

/// 指定图片和标题初始化，自适应内边距，可自定义
- (instancetype)initWithImage:(nullable UIImage *)image title:(nullable NSString *)title;

/// 使用指定对象创建按钮，支持UIImage|NSString(默认)，同时添加点击事件
+ (instancetype)buttonWithObject:(nullable id)object target:(nullable id)target action:(nullable SEL)action;

/// 使用指定对象创建按钮，支持UIImage|NSString(默认)，同时添加点击句柄
+ (instancetype)buttonWithObject:(nullable id)object block:(nullable void (^)(id sender))block;

@end

NS_ASSUME_NONNULL_END
