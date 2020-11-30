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

#pragma mark - UIScrollView+FWInfiniteScroll

typedef NS_ENUM(NSUInteger, FWInfiniteScrollState) {
    FWInfiniteScrollStateStopped = 0,
    FWInfiniteScrollStateTriggered,
    FWInfiniteScrollStateLoading,
    FWInfiniteScrollStateAll = 10
};

/*!
 @brief 上拉追加视图，默认高度60
 */
@interface FWInfiniteScrollView : UIView

@property (class, nonatomic, assign) CGFloat height;
@property (nonatomic, readwrite) UIActivityIndicatorViewStyle activityIndicatorViewStyle;
@property (nonatomic, readwrite) BOOL enabled;
@property (nonatomic, readwrite, assign) CGFloat preloadHeight;

@property (nonatomic, readonly) FWInfiniteScrollState state;
@property (nonatomic, assign, readonly) BOOL userTriggered;
@property (nullable, nonatomic, copy) void (^stateBlock)(FWInfiniteScrollView *view, FWInfiniteScrollState state);
@property (nullable, nonatomic, copy) void (^progressBlock)(FWInfiniteScrollView *view, CGFloat progress);

- (void)setCustomView:(nullable UIView *)view forState:(FWInfiniteScrollState)state;

- (void)startAnimating;
- (void)stopAnimating;
- (BOOL)isAnimating;

@end

/*!
 @brief UIScrollView+FWInfiniteScroll
 
 @see https://github.com/samvermette/SVPullToRefresh
 */
@interface UIScrollView (FWInfiniteScroll)

- (void)fwAddInfiniteScrollWithBlock:(void (^)(void))block;
- (void)fwAddInfiniteScrollWithTarget:(id)target action:(SEL)action;
- (void)fwTriggerInfiniteScroll;

@property (nullable, nonatomic, strong, readonly) FWInfiniteScrollView *fwInfiniteScrollView;
@property (nonatomic, assign) CGFloat fwInfiniteScrollHeight;
@property (nonatomic, assign) BOOL fwShowInfiniteScroll;

@end

#pragma mark - UIScrollView+FWPullRefresh

typedef NS_ENUM(NSUInteger, FWPullRefreshState) {
    FWPullRefreshStateStopped = 0,
    FWPullRefreshStateTriggered,
    FWPullRefreshStateLoading,
    FWPullRefreshStateAll = 10
};

/*!
@brief 下拉刷新视图，默认高度60
*/
@interface FWPullRefreshView : UIView

@property (class, nonatomic, assign) CGFloat height;
@property (nullable, nonatomic, strong) UIColor *arrowColor;
@property (nullable, nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *subtitleLabel;
@property (nullable, nonatomic, strong) UIColor *activityIndicatorViewColor;
@property (nonatomic, assign) UIActivityIndicatorViewStyle activityIndicatorViewStyle;

@property (nonatomic, readonly) FWPullRefreshState state;
@property (nonatomic, assign, readonly) BOOL userTriggered;
@property (nullable, nonatomic, copy) void (^stateBlock)(FWPullRefreshView *view, FWPullRefreshState state);
@property (nullable, nonatomic, copy) void (^progressBlock)(FWPullRefreshView *view, CGFloat progress);

- (void)setTitle:(nullable NSString *)title forState:(FWPullRefreshState)state;
- (void)setSubtitle:(nullable NSString *)subtitle forState:(FWPullRefreshState)state;
- (void)setCustomView:(nullable UIView *)view forState:(FWPullRefreshState)state;

- (void)startAnimating;
- (void)stopAnimating;
- (BOOL)isAnimating;

@end

/*!
 @brief UIScrollView+FWPullRefresh
 @discussion FWRefreshPlugin
 
 @see https://github.com/samvermette/SVPullToRefresh
 */
@interface UIScrollView (FWPullRefresh)

- (void)fwAddPullRefreshWithBlock:(void (^)(void))block;
- (void)fwAddPullRefreshWithTarget:(id)target action:(SEL)action;
- (void)fwTriggerPullRefresh;

@property (nullable, nonatomic, strong, readonly) FWPullRefreshView *fwPullRefreshView;
@property (nonatomic, assign) CGFloat fwPullRefreshHeight;
@property (nonatomic, assign) BOOL fwShowPullRefresh;

@end

NS_ASSUME_NONNULL_END
