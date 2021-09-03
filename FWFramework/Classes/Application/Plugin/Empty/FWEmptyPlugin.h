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
- (void)fwShowEmptyViewWithText:(nullable NSString *)text detail:(nullable NSString *)detail image:(nullable UIImage *)image loading:(BOOL)loading action:(nullable NSString *)action block:(nullable void (^)(id sender))block inView:(UIView *)view;

/// 隐藏空界面
- (void)fwHideEmptyView:(UIView *)view;

/// 是否显示空界面
- (BOOL)fwHasEmptyView:(UIView *)view;

@end

#pragma mark - FWEmptyPluginView

/// 空界面插件视图协议，使用空界面插件
@protocol FWEmptyPluginView <NSObject>
@required

/// 设置空界面外间距，默认zero
@property (nonatomic, assign) UIEdgeInsets fwEmptyInsets;

/// 是否显示空界面
@property (nonatomic, assign, readonly) BOOL fwHasEmptyView;

/// 显示空界面
- (void)fwShowEmptyView;

/// 显示空界面加载视图
- (void)fwShowEmptyViewLoading;

/// 显示空界面，指定文本
- (void)fwShowEmptyViewWithText:(nullable NSString *)text;

/// 显示空界面，指定文本和详细文本
- (void)fwShowEmptyViewWithText:(nullable NSString *)text detail:(nullable NSString *)detail;

/// 显示空界面，指定文本、详细文本和图片
- (void)fwShowEmptyViewWithText:(nullable NSString *)text detail:(nullable NSString *)detail image:(nullable UIImage *)image;

/// 显示空界面，指定文本、详细文本、图片和动作按钮
- (void)fwShowEmptyViewWithText:(nullable NSString *)text detail:(nullable NSString *)detail image:(nullable UIImage *)image action:(nullable NSString *)action block:(nullable void (^)(id sender))block;

/// 显示空界面，指定文本、详细文本、图片、是否显示加载视图和动作按钮
- (void)fwShowEmptyViewWithText:(nullable NSString *)text detail:(nullable NSString *)detail image:(nullable UIImage *)image loading:(BOOL)loading action:(nullable NSString *)action block:(nullable void (^)(id sender))block;

/// 隐藏空界面
- (void)fwHideEmptyView;

@end

/// UIView使用空界面插件，兼容UITableView|UICollectionView
@interface UIView (FWEmptyPluginView) <FWEmptyPluginView>

@end

/// UIViewController使用空界面插件，内部使用UIViewController.view
@interface UIViewController (FWEmptyPluginView) <FWEmptyPluginView>

@end

#pragma mark - UIScrollView+FWEmptyPlugin

/// 空界面代理协议
@protocol FWEmptyViewDelegate <NSObject>
@optional

/// 显示空界面，默认调用UIScrollView.fwShowEmptyView
- (void)fwShowEmptyView:(UIScrollView *)scrollView;

/// 隐藏空界面，默认调用UIScrollView.fwHideEmptyView
- (void)fwHideEmptyView:(UIScrollView *)scrollView;

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
@interface UIScrollView (FWEmptyPlugin)

/// 空界面代理，默认nil
@property (nonatomic, weak, nullable) IBOutlet id<FWEmptyViewDelegate> fwEmptyViewDelegate;

/// 刷新空界面
- (void)fwReloadEmptyView;

@end

NS_ASSUME_NONNULL_END
