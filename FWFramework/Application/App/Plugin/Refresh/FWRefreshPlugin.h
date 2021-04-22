/*!
 @header     FWRefreshPlugin.h
 @indexgroup FWFramework
 @brief      FWRefreshPlugin
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/16
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWRefreshPlugin

/// 刷新插件协议，应用可自定义刷新插件实现
@protocol FWRefreshPlugin <NSObject>

@optional

#pragma mark - Refreshing

/// 是否正在刷新中
- (BOOL)fwIsRefreshing:(UIScrollView *)scrollView;

/// 是否显示刷新组件
- (BOOL)fwShowRefreshing:(UIScrollView *)scrollView;

/// 设置是否显示刷新组件
- (void)fwSetShowRefreshing:(BOOL)showRefreshing scrollView:(UIScrollView *)scrollView;

/// 配置下拉刷新句柄
- (void)fwSetRefreshingBlock:(void (^)(void))block scrollView:(UIScrollView *)scrollView;

/// 配置下拉刷新事件
- (void)fwSetRefreshingTarget:(id)target action:(SEL)action scrollView:(UIScrollView *)scrollView;

/// 开始下拉刷新
- (void)fwBeginRefreshing:(UIScrollView *)scrollView;

/// 结束下拉刷新
- (void)fwEndRefreshing:(UIScrollView *)scrollView;

#pragma mark - Loading

/// 是否正在追加中
- (BOOL)fwIsLoading:(UIScrollView *)scrollView;

/// 是否显示追加组件
- (BOOL)fwShowLoading:(UIScrollView *)scrollView;

/// 设置是否显示追加组件
- (void)fwSetShowLoading:(BOOL)showLoading scrollView:(UIScrollView *)scrollView;

/// 配置上拉追加句柄
- (void)fwSetLoadingBlock:(void (^)(void))block scrollView:(UIScrollView *)scrollView;

/// 配置上拉追加事件
- (void)fwSetLoadingTarget:(id)target action:(SEL)action scrollView:(UIScrollView *)scrollView;

/// 开始上拉追加
- (void)fwBeginLoading:(UIScrollView *)scrollView;

/// 结束上拉追加
- (void)fwEndLoading:(UIScrollView *)scrollView;

@end

#pragma mark - UIScrollView+FWRefreshPlugin

/// UIScrollView刷新插件分类
@interface UIScrollView (FWRefreshPlugin)

#pragma mark - Refreshing

/// 是否正在刷新中
@property (nonatomic, readonly) BOOL fwIsRefreshing;

/// 是否显示刷新组件
@property (nonatomic, assign) BOOL fwShowRefreshing;

/// 配置下拉刷新句柄
- (void)fwSetRefreshingBlock:(void (^)(void))block;

/// 配置下拉刷新事件
- (void)fwSetRefreshingTarget:(id)target action:(SEL)action;

/// 开始下拉刷新
- (void)fwBeginRefreshing;

/// 结束下拉刷新
- (void)fwEndRefreshing;

#pragma mark - Loading

/// 是否正在追加中
@property (nonatomic, readonly) BOOL fwIsLoading;

/// 是否显示追加组件
@property (nonatomic, assign) BOOL fwShowLoading;

/// 配置上拉追加句柄
- (void)fwSetLoadingBlock:(void (^)(void))block;

/// 配置上拉追加事件
- (void)fwSetLoadingTarget:(id)target action:(SEL)action;

/// 开始上拉追加
- (void)fwBeginLoading;

/// 结束上拉追加
- (void)fwEndLoading;

@end

NS_ASSUME_NONNULL_END
