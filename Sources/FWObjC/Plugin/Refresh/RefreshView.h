//
//  RefreshView.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWPullRefreshView

typedef NS_ENUM(NSUInteger, __FWPullRefreshState) {
    __FWPullRefreshStateIdle = 0,
    __FWPullRefreshStateTriggered,
    __FWPullRefreshStateLoading,
    __FWPullRefreshStateAll = 10
} NS_SWIFT_NAME(PullRefreshState);

@protocol __FWIndicatorViewPlugin;
@protocol __FWProgressViewPlugin;

/**
 下拉刷新视图，默认高度60
 @note 如果indicatorView为自定义指示器时会自动隐藏标题和箭头，仅显示指示器视图
 
 @see https://github.com/samvermette/SVPullToRefresh
*/
NS_SWIFT_NAME(PullRefreshView)
@interface __FWPullRefreshView : UIView

@property (class, nonatomic, assign) CGFloat height;
@property (nonatomic, readwrite) UIEdgeInsets originalInset;
@property (nullable, nonatomic, strong) UIColor *arrowColor;
@property (nullable, nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *subtitleLabel;
@property (nonatomic, strong) UIView<__FWIndicatorViewPlugin> *indicatorView;
@property (nullable, nonatomic, strong) UIColor *indicatorColor;
@property (nonatomic, assign) CGFloat indicatorPadding;
@property (nonatomic, assign) BOOL showsTitleLabel;
@property (nonatomic, assign) BOOL showsArrowView;
@property (nonatomic, assign) BOOL shouldChangeAlpha;

@property (nonatomic, readwrite) __FWPullRefreshState state;
@property (nonatomic, assign) BOOL userTriggered;
@property (nullable, nonatomic, copy) void (^stateBlock)(__FWPullRefreshView *view, __FWPullRefreshState state);
@property (nullable, nonatomic, copy) void (^progressBlock)(__FWPullRefreshView *view, CGFloat progress);

@property (nonatomic, copy, nullable) void (^pullRefreshBlock)(void);
@property (nonatomic, weak, nullable) id target;
@property (nonatomic, nullable) SEL action;
@property (nonatomic, weak, nullable) UIScrollView *scrollView;
@property (nonatomic, assign) BOOL isObserving;
- (void)gestureRecognizer:(UIPanGestureRecognizer *)gestureRecognizer stateChanged:(NSDictionary *)change;
- (void)resetScrollViewContentInset;

- (void)setTitle:(nullable NSString *)title forState:(__FWPullRefreshState)state;
- (void)setSubtitle:(nullable NSString *)subtitle forState:(__FWPullRefreshState)state;
- (void)setCustomView:(nullable UIView *)view forState:(__FWPullRefreshState)state;
- (void)setAnimationView:(nullable UIView<__FWProgressViewPlugin, __FWIndicatorViewPlugin> *)animationView;

- (void)startAnimating;
- (void)stopAnimating;
- (BOOL)isAnimating;

@end

#pragma mark - __FWInfiniteScrollView

typedef NS_ENUM(NSUInteger, __FWInfiniteScrollState) {
    __FWInfiniteScrollStateIdle = 0,
    __FWInfiniteScrollStateTriggered,
    __FWInfiniteScrollStateLoading,
    __FWInfiniteScrollStateAll = 10
} NS_SWIFT_NAME(InfiniteScrollState);

/**
 上拉追加视图，默认高度60
 
 @see https://github.com/samvermette/SVPullToRefresh
 */
NS_SWIFT_NAME(InfiniteScrollView)
@interface __FWInfiniteScrollView : UIView

@property (class, nonatomic, assign) CGFloat height;
@property (nonatomic, readwrite) BOOL enabled;
@property (nonatomic, readwrite) UIEdgeInsets originalInset;
@property (nonatomic, readwrite, assign) CGFloat preloadHeight;
@property (nonatomic, strong) UIView<__FWIndicatorViewPlugin> *indicatorView;
@property (nullable, nonatomic, strong) UIColor *indicatorColor;
@property (nonatomic, assign) CGFloat indicatorPadding;
@property (nonatomic, assign) BOOL finished;
@property (nonatomic, strong, readonly) UILabel *finishedLabel;
@property (nonatomic, strong) UIView *finishedView;
@property (nonatomic, assign) CGFloat finishedPadding;

@property (nonatomic, readwrite) __FWInfiniteScrollState state;
@property (nonatomic, assign) BOOL userTriggered;
@property (nullable, nonatomic, copy) void (^stateBlock)(__FWInfiniteScrollView *view, __FWInfiniteScrollState state);
@property (nullable, nonatomic, copy) void (^progressBlock)(__FWInfiniteScrollView *view, CGFloat progress);

@property (nonatomic, copy, nullable) void (^infiniteScrollBlock)(void);
@property (nonatomic, weak, nullable) id target;
@property (nonatomic, nullable) SEL action;
@property (nonatomic, weak, nullable) UIScrollView *scrollView;
@property (nonatomic, assign) BOOL isObserving;
- (void)gestureRecognizer:(UIPanGestureRecognizer *)gestureRecognizer stateChanged:(NSDictionary *)change;
- (void)resetScrollViewContentInset;
- (void)setScrollViewContentInsetForInfiniteScrolling;

- (void)setCustomView:(nullable UIView *)view forState:(__FWInfiniteScrollState)state;
- (void)setAnimationView:(nullable UIView<__FWProgressViewPlugin, __FWIndicatorViewPlugin> *)animationView;

- (void)startAnimating;
- (void)stopAnimating;
- (BOOL)isAnimating;

@end

NS_ASSUME_NONNULL_END
