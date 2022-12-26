//
//  RefreshView.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIScrollView+__FWPullRefresh

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

@property (nonatomic, readonly) __FWPullRefreshState state;
@property (nonatomic, assign, readonly) BOOL userTriggered;
@property (nullable, nonatomic, copy) void (^stateBlock)(__FWPullRefreshView *view, __FWPullRefreshState state);
@property (nullable, nonatomic, copy) void (^progressBlock)(__FWPullRefreshView *view, CGFloat progress);

- (void)setTitle:(nullable NSString *)title forState:(__FWPullRefreshState)state;
- (void)setSubtitle:(nullable NSString *)subtitle forState:(__FWPullRefreshState)state;
- (void)setCustomView:(nullable UIView *)view forState:(__FWPullRefreshState)state;
- (void)setAnimationView:(nullable UIView<__FWProgressViewPlugin, __FWIndicatorViewPlugin> *)animationView;

- (void)startAnimating;
- (void)stopAnimating;
- (BOOL)isAnimating;

@end

/**
 UIScrollView+__FWPullRefresh
 
 @see https://github.com/samvermette/SVPullToRefresh
 */
@interface UIScrollView (__FWPullRefresh)

- (void)fw_addPullRefreshWithBlock:(void (^)(void))block NS_REFINED_FOR_SWIFT;
- (void)fw_addPullRefreshWithTarget:(id)target action:(SEL)action NS_REFINED_FOR_SWIFT;
- (void)fw_triggerPullRefresh NS_REFINED_FOR_SWIFT;

@property (nullable, nonatomic, strong, readonly) __FWPullRefreshView *fw_pullRefreshView NS_REFINED_FOR_SWIFT;
@property (nonatomic, assign) CGFloat fw_pullRefreshHeight NS_REFINED_FOR_SWIFT;
@property (nonatomic, assign) BOOL fw_showPullRefresh NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIScrollView+__FWInfiniteScroll

typedef NS_ENUM(NSUInteger, __FWInfiniteScrollState) {
    __FWInfiniteScrollStateIdle = 0,
    __FWInfiniteScrollStateTriggered,
    __FWInfiniteScrollStateLoading,
    __FWInfiniteScrollStateAll = 10
} NS_SWIFT_NAME(InfiniteScrollState);

/**
 上拉追加视图，默认高度60
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

@property (nonatomic, readonly) __FWInfiniteScrollState state;
@property (nonatomic, assign, readonly) BOOL userTriggered;
@property (nullable, nonatomic, copy) void (^stateBlock)(__FWInfiniteScrollView *view, __FWInfiniteScrollState state);
@property (nullable, nonatomic, copy) void (^progressBlock)(__FWInfiniteScrollView *view, CGFloat progress);

- (void)setCustomView:(nullable UIView *)view forState:(__FWInfiniteScrollState)state;
- (void)setAnimationView:(nullable UIView<__FWProgressViewPlugin, __FWIndicatorViewPlugin> *)animationView;

- (void)startAnimating;
- (void)stopAnimating;
- (BOOL)isAnimating;

@end

/**
 UIScrollView+__FWInfiniteScroll
 
 @see https://github.com/samvermette/SVPullToRefresh
 */
@interface UIScrollView (__FWInfiniteScroll)

- (void)fw_addInfiniteScrollWithBlock:(void (^)(void))block NS_REFINED_FOR_SWIFT;
- (void)fw_addInfiniteScrollWithTarget:(id)target action:(SEL)action NS_REFINED_FOR_SWIFT;
- (void)fw_triggerInfiniteScroll NS_REFINED_FOR_SWIFT;

@property (nullable, nonatomic, strong, readonly) __FWInfiniteScrollView *fw_infiniteScrollView NS_REFINED_FOR_SWIFT;
@property (nonatomic, assign) CGFloat fw_infiniteScrollHeight NS_REFINED_FOR_SWIFT;
@property (nonatomic, assign) BOOL fw_showInfiniteScroll NS_REFINED_FOR_SWIFT;
@property (nonatomic, assign) BOOL fw_infiniteScrollFinished NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
