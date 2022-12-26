//
//  RefreshPlugin.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWRefreshPlugin

/// 刷新插件协议，应用可自定义刷新插件实现
NS_SWIFT_NAME(RefreshPlugin)
@protocol __FWRefreshPlugin <NSObject>

@optional

#pragma mark - Refreshing

/// 是否正在刷新中
- (BOOL)isRefreshing:(UIScrollView *)scrollView;

/// 是否显示刷新组件
- (BOOL)shouldRefreshing:(UIScrollView *)scrollView;

/// 设置是否显示刷新组件
- (void)setShouldRefreshing:(BOOL)shouldRefreshing scrollView:(UIScrollView *)scrollView;

/// 配置下拉刷新句柄
- (void)setRefreshingBlock:(void (^)(void))block scrollView:(UIScrollView *)scrollView;

/// 配置下拉刷新事件
- (void)setRefreshingTarget:(id)target action:(SEL)action scrollView:(UIScrollView *)scrollView;

/// 开始下拉刷新
- (void)beginRefreshing:(UIScrollView *)scrollView;

/// 结束下拉刷新
- (void)endRefreshing:(UIScrollView *)scrollView;

#pragma mark - Loading

/// 是否正在追加中
- (BOOL)isLoading:(UIScrollView *)scrollView;

/// 是否显示追加组件
- (BOOL)shouldLoading:(UIScrollView *)scrollView;

/// 设置是否显示追加组件
- (void)setShouldLoading:(BOOL)shouldLoading scrollView:(UIScrollView *)scrollView;

/// 是否已追加完成，不能继续追加
- (BOOL)loadingFinished:(UIScrollView *)scrollView;

/// 设置是否已追加完成，不能继续追加
- (void)setLoadingFinished:(BOOL)loadingFinished scrollView:(UIScrollView *)scrollView;

/// 配置上拉追加句柄
- (void)setLoadingBlock:(void (^)(void))block scrollView:(UIScrollView *)scrollView;

/// 配置上拉追加事件
- (void)setLoadingTarget:(id)target action:(SEL)action scrollView:(UIScrollView *)scrollView;

/// 开始上拉追加
- (void)beginLoading:(UIScrollView *)scrollView;

/// 结束上拉追加
- (void)endLoading:(UIScrollView *)scrollView;

@end

NS_ASSUME_NONNULL_END
