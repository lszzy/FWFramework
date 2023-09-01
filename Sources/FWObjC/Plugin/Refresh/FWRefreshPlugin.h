//
//  FWRefreshPlugin.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWRefreshPlugin

/// 刷新插件协议，应用可自定义刷新插件实现
NS_SWIFT_NAME(RefreshPlugin)
@protocol FWRefreshPlugin <NSObject>

@optional

#pragma mark - Refreshing

/// 是否正在刷新中
- (BOOL)isRefreshing:(UIScrollView *)scrollView;

/// 是否显示刷新组件
- (BOOL)shouldRefreshing:(UIScrollView *)scrollView;

/// 设置是否显示刷新组件
- (void)setShouldRefreshing:(BOOL)shouldRefreshing scrollView:(UIScrollView *)scrollView;

/// 配置下拉刷新句柄
- (void)setRefreshingBlock:(void (^)(void))block customBlock:(nullable void (^)(id))customBlock scrollView:(UIScrollView *)scrollView;

/// 配置下拉刷新事件
- (void)setRefreshingTarget:(id)target action:(SEL)action customBlock:(nullable void (^)(id))customBlock scrollView:(UIScrollView *)scrollView;

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
- (void)setLoadingBlock:(void (^)(void))block customBlock:(nullable void (^)(id))customBlock scrollView:(UIScrollView *)scrollView;

/// 配置上拉追加事件
- (void)setLoadingTarget:(id)target action:(SEL)action customBlock:(nullable void (^)(id))customBlock scrollView:(UIScrollView *)scrollView;

/// 开始上拉追加
- (void)beginLoading:(UIScrollView *)scrollView;

/// 结束上拉追加
- (void)endLoading:(UIScrollView *)scrollView;

@end

#pragma mark - UIScrollView+FWRefreshPlugin

/// UIScrollView刷新插件分类
@interface UIScrollView (FWRefreshPlugin)

/// 自定义刷新插件，未设置时自动从插件池加载
@property (nonatomic, strong, nullable) id<FWRefreshPlugin> fw_refreshPlugin NS_REFINED_FOR_SWIFT;

#pragma mark - Refreshing

/// 是否正在刷新中
@property (nonatomic, readonly) BOOL fw_isRefreshing NS_REFINED_FOR_SWIFT;

/// 是否显示刷新组件
@property (nonatomic, assign) BOOL fw_shouldRefreshing NS_REFINED_FOR_SWIFT;

/// 配置下拉刷新句柄
- (void)fw_setRefreshingBlock:(void (^)(void))block customBlock:(nullable void (^)(id))customBlock NS_REFINED_FOR_SWIFT;

/// 配置下拉刷新事件
- (void)fw_setRefreshingTarget:(id)target action:(SEL)action customBlock:(nullable void (^)(id))customBlock NS_REFINED_FOR_SWIFT;

/// 开始下拉刷新
- (void)fw_beginRefreshing NS_REFINED_FOR_SWIFT;

/// 结束下拉刷新
- (void)fw_endRefreshing NS_REFINED_FOR_SWIFT;

/// 结束下拉刷新并标记是否加载完成，最好在reloadData之后调用
- (void)fw_endRefreshingWithFinished:(BOOL)finished NS_REFINED_FOR_SWIFT;

#pragma mark - Loading

/// 是否正在追加中
@property (nonatomic, readonly) BOOL fw_isLoading NS_REFINED_FOR_SWIFT;

/// 是否显示追加组件
@property (nonatomic, assign) BOOL fw_shouldLoading NS_REFINED_FOR_SWIFT;

/// 是否已加载完成，不能继续追加，最好在reloadData之后调用
@property (nonatomic, assign) BOOL fw_loadingFinished NS_REFINED_FOR_SWIFT;

/// 配置上拉追加句柄
- (void)fw_setLoadingBlock:(void (^)(void))block customBlock:(nullable void (^)(id))customBlock NS_REFINED_FOR_SWIFT;

/// 配置上拉追加事件
- (void)fw_setLoadingTarget:(id)target action:(SEL)action customBlock:(nullable void (^)(id))customBlock NS_REFINED_FOR_SWIFT;

/// 开始上拉追加
- (void)fw_beginLoading NS_REFINED_FOR_SWIFT;

/// 结束上拉追加
- (void)fw_endLoading NS_REFINED_FOR_SWIFT;

/// 结束上拉追加并标记是否加载完成，最好在reloadData之后调用
- (void)fw_endLoadingWithFinished:(BOOL)finished NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
