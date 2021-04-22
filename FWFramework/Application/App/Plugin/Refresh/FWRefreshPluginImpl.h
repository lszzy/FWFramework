/*!
 @header     FWRefreshPluginImpl.h
 @indexgroup FWFramework
 @brief      FWRefreshPlugin
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/16
 */

#import "FWRefreshPlugin.h"

NS_ASSUME_NONNULL_BEGIN

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
