/*!
 @header     FWViewControllerStyle.h
 @indexgroup FWFramework
 @brief      FWViewControllerStyle
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/12/5
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 导航栏样式可扩展枚举
typedef NSInteger FWNavigationBarStyle NS_TYPED_EXTENSIBLE_ENUM;
static const FWNavigationBarStyle FWNavigationBarStyleDefault = 0;
static const FWNavigationBarStyle FWNavigationBarStyleClear   = 1;

/*!
 @brief 视图控制器样式分类
 @discussion 需要设置UIViewControllerBasedStatusBarAppearance为YES，视图控制器修改状态栏样式才会生效
 */
@interface UIViewController (FWStyle)

#pragma mark - Bar

/// 状态栏是否隐藏，默认NO，设置后才会生效
@property (nonatomic, assign) BOOL fwStatusBarHidden;

/// 状态栏样式，默认UIStatusBarStyleDefault，设置后才会生效
@property (nonatomic, assign) UIStatusBarStyle fwStatusBarStyle;

/// 导航栏是否隐藏，默认为NO，设置后才会在viewWillAppear:自动应用生效
@property (nonatomic, assign) BOOL fwNavigationBarHidden;

/// 动态设置导航栏是否隐藏，切换动画不突兀，立即生效
- (void)fwSetNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated;

/// 当前导航栏样式，默认Default，设置后才会在viewWillAppear:自动应用生效
@property (nonatomic, assign) FWNavigationBarStyle fwNavigationBarStyle;

/// 标签栏是否隐藏，默认为NO，立即生效。如果tabBar一直存在，则用tabBar包裹navBar；如果tabBar只存在主界面，则用navBar包裹tabBar
@property (nonatomic, assign) BOOL fwTabBarHidden;

/// 工具栏是否隐藏，默认为YES。需设置toolbarItems，立即生效
@property (nonatomic, assign) BOOL fwToolBarHidden;

/// 动态设置工具栏是否隐藏，切换动画不突兀，立即生效
- (void)fwSetToolBarHidden:(BOOL)hidden animated:(BOOL)animated;

/// 设置视图布局Bar延伸类型，None为不延伸(Bar不覆盖视图)，All为全部延伸(全部Bar覆盖视图)
- (void)fwSetBarExtendEdge:(UIRectEdge)edge;

#pragma mark - Item

/// 快捷设置导航栏标题文字或视图
- (void)fwSetBarTitle:(nullable id)title;

/// 快捷设置导航栏左侧按钮。注意自定义left按钮之后，系统返回手势失效
- (void)fwSetLeftBarItem:(nullable id)object target:(id)target action:(SEL)action;

/// 快捷设置导航栏左侧按钮，block事件。注意自定义left按钮之后，系统返回手势失效
- (void)fwSetLeftBarItem:(nullable id)object block:(void (^)(id sender))block;

/// 快捷设置导航栏右侧按钮
- (void)fwSetRightBarItem:(nullable id)object target:(id)target action:(SEL)action;

/// 快捷设置导航栏右侧按钮，block事件
- (void)fwSetRightBarItem:(nullable id)object block:(void (^)(id sender))block;

#pragma mark - Back

/// 设置导航栏返回按钮仅显示箭头模式，下个页面生效
- (void)fwSetBackBarArrow;

/// 设置导航栏返回按钮文字加箭头模式，下个页面生效
- (void)fwSetBackBarTitle:(nullable NSString *)title;

/// 设置导航栏返回按钮仅显示图片模式，下个页面生效
- (void)fwSetBackBarImage:(nullable UIImage *)image;

@end

/// 导航栏样式配置
@interface FWNavigationBarAppearance : NSObject

@property (nullable, nonatomic, strong, readonly) UIColor *backgroundColor;
@property (nullable, nonatomic, strong, readonly) UIColor *foregroundColor;
@property (nullable, nonatomic, copy, readonly) void (^appearanceBlock)(UINavigationBar *navigationBar);

- (instancetype)initWithBackgroundColor:(nullable UIColor *)backgroundColor
                        foregroundColor:(nullable UIColor *)foregroundColor
                        appearanceBlock:(nullable void (^)(UINavigationBar *navigationBar))appearanceBlock;

+ (nullable FWNavigationBarAppearance *)appearanceForStyle:(FWNavigationBarStyle)style;
+ (void)setAppearance:(nullable FWNavigationBarAppearance *)appearance forStyle:(FWNavigationBarStyle)style;

@end

NS_ASSUME_NONNULL_END
