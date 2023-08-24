//
//  FWEmptyPlugin.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWEmptyPlugin

/// 空界面插件协议，应用可自定义空界面插件实现
NS_SWIFT_NAME(EmptyPlugin)
@protocol FWEmptyPlugin <NSObject>

@optional

/// 显示空界面，指定文本、详细文本、图片、加载视图和最多两个动作按钮
- (void)showEmptyViewWithText:(nullable id)text detail:(nullable id)detail image:(nullable UIImage *)image loading:(BOOL)loading actions:(nullable NSArray *)actions block:(nullable void (^)(NSInteger index, id sender))block inView:(UIView *)view;

/// 隐藏空界面
- (void)hideEmptyView:(UIView *)view;

/// 获取正在显示的空界面视图
- (nullable UIView *)showingEmptyView:(UIView *)view;

@end

#pragma mark - UIView+FWEmptyPlugin

/// UIView使用空界面插件，兼容UITableView|UICollectionView
@interface UIView (FWEmptyPlugin)

/// 自定义空界面插件，未设置时自动从插件池加载
@property (nonatomic, strong, nullable) id<FWEmptyPlugin> fw_emptyPlugin NS_REFINED_FOR_SWIFT;

/// 设置空界面外间距，默认zero
@property (nonatomic, assign) UIEdgeInsets fw_emptyInsets NS_REFINED_FOR_SWIFT;

/// 获取正在显示的空界面视图
@property (nonatomic, weak, readonly, nullable) UIView *fw_showingEmptyView NS_REFINED_FOR_SWIFT;

/// 是否显示空界面
@property (nonatomic, assign, readonly) BOOL fw_hasEmptyView NS_REFINED_FOR_SWIFT;

/// 显示空界面
- (void)fw_showEmptyView NS_REFINED_FOR_SWIFT;

/// 显示空界面加载视图
- (void)fw_showEmptyViewLoading NS_REFINED_FOR_SWIFT;

/// 显示空界面，指定文本
- (void)fw_showEmptyViewWithText:(nullable id)text NS_REFINED_FOR_SWIFT;

/// 显示空界面，指定文本和详细文本
- (void)fw_showEmptyViewWithText:(nullable id)text detail:(nullable id)detail NS_REFINED_FOR_SWIFT;

/// 显示空界面，指定文本、详细文本和图片
- (void)fw_showEmptyViewWithText:(nullable id)text detail:(nullable id)detail image:(nullable UIImage *)image NS_REFINED_FOR_SWIFT;

/// 显示空界面，指定文本、详细文本、图片和动作按钮
- (void)fw_showEmptyViewWithText:(nullable id)text detail:(nullable id)detail image:(nullable UIImage *)image action:(nullable id)action block:(nullable void (^)(id sender))block NS_REFINED_FOR_SWIFT;

/// 显示空界面，指定文本、详细文本、图片、是否显示加载视图和动作按钮
- (void)fw_showEmptyViewWithText:(nullable id)text detail:(nullable id)detail image:(nullable UIImage *)image loading:(BOOL)loading action:(nullable id)action block:(nullable void (^)(id sender))block NS_REFINED_FOR_SWIFT;

/// 显示空界面，指定文本、详细文本、图片、是否显示加载视图和最多两个动作按钮
- (void)fw_showEmptyViewWithText:(nullable id)text detail:(nullable id)detail image:(nullable UIImage *)image loading:(BOOL)loading actions:(nullable NSArray *)actions block:(nullable void (^)(NSInteger index, id sender))block NS_REFINED_FOR_SWIFT;

/// 隐藏空界面
- (void)fw_hideEmptyView NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIViewController+FWEmptyPlugin

/// UIViewController使用空界面插件，内部使用UIViewController.view
@interface UIViewController (FWEmptyPlugin)

/// 设置空界面外间距，默认zero
@property (nonatomic, assign) UIEdgeInsets fw_emptyInsets NS_REFINED_FOR_SWIFT;

/// 获取正在显示的空界面视图
@property (nonatomic, weak, readonly, nullable) UIView *fw_showingEmptyView NS_REFINED_FOR_SWIFT;

/// 是否显示空界面
@property (nonatomic, assign, readonly) BOOL fw_hasEmptyView NS_REFINED_FOR_SWIFT;

/// 显示空界面
- (void)fw_showEmptyView NS_REFINED_FOR_SWIFT;

/// 显示空界面加载视图
- (void)fw_showEmptyViewLoading NS_REFINED_FOR_SWIFT;

/// 显示空界面，指定文本
- (void)fw_showEmptyViewWithText:(nullable id)text NS_REFINED_FOR_SWIFT;

/// 显示空界面，指定文本和详细文本
- (void)fw_showEmptyViewWithText:(nullable id)text detail:(nullable id)detail NS_REFINED_FOR_SWIFT;

/// 显示空界面，指定文本、详细文本和图片
- (void)fw_showEmptyViewWithText:(nullable id)text detail:(nullable id)detail image:(nullable UIImage *)image NS_REFINED_FOR_SWIFT;

/// 显示空界面，指定文本、详细文本、图片和动作按钮
- (void)fw_showEmptyViewWithText:(nullable id)text detail:(nullable id)detail image:(nullable UIImage *)image action:(nullable id)action block:(nullable void (^)(id sender))block NS_REFINED_FOR_SWIFT;

/// 显示空界面，指定文本、详细文本、图片、是否显示加载视图和动作按钮
- (void)fw_showEmptyViewWithText:(nullable id)text detail:(nullable id)detail image:(nullable UIImage *)image loading:(BOOL)loading action:(nullable id)action block:(nullable void (^)(id sender))block NS_REFINED_FOR_SWIFT;

/// 显示空界面，指定文本、详细文本、图片、是否显示加载视图和最多两个动作按钮
- (void)fw_showEmptyViewWithText:(nullable id)text detail:(nullable id)detail image:(nullable UIImage *)image loading:(BOOL)loading actions:(nullable NSArray *)actions block:(nullable void (^)(NSInteger index, id sender))block NS_REFINED_FOR_SWIFT;

/// 隐藏空界面
- (void)fw_hideEmptyView NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIScrollView+FWEmptyPlugin

/// 空界面代理协议
NS_SWIFT_NAME(EmptyViewDelegate)
@protocol FWEmptyViewDelegate <NSObject>
@optional

/// 显示空界面，默认调用UIScrollView.fwShowEmptyView
- (void)showEmptyView:(UIScrollView *)scrollView;

/// 隐藏空界面，默认调用UIScrollView.fwHideEmptyView
- (void)hideEmptyView:(UIScrollView *)scrollView;

/// 显示空界面时是否允许滚动，默认NO
- (BOOL)emptyViewShouldScroll:(UIScrollView *)scrollView;

/// 无数据时是否显示空界面，默认YES
- (BOOL)emptyViewShouldDisplay:(UIScrollView *)scrollView;

/// 有数据时是否强制显示空界面，默认NO
- (BOOL)emptyViewForceDisplay:(UIScrollView *)scrollView;

@end

/**
 滚动视图空界面分类
 
 @see https://github.com/dzenbot/DZNEmptyDataSet
 */
@interface UIScrollView (FWEmptyPlugin)

/// 空界面代理，默认nil
@property (nonatomic, weak, nullable) id<FWEmptyViewDelegate> fw_emptyViewDelegate NS_REFINED_FOR_SWIFT;

/// 刷新空界面
- (void)fw_reloadEmptyView NS_REFINED_FOR_SWIFT;

/// 当前数据总条数，默认自动获取tableView和collectionView，支持自定义覆盖(优先级高，小于0还原)
@property (nonatomic, assign) NSInteger fw_totalDataCount NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
