//
//  FWRefreshView.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIScrollView+FWPullRefresh

typedef NS_ENUM(NSUInteger, FWPullRefreshState) {
    FWPullRefreshStateIdle = 0,
    FWPullRefreshStateTriggered,
    FWPullRefreshStateLoading,
    FWPullRefreshStateAll = 10
} NS_SWIFT_NAME(PullRefreshState);

@protocol FWIndicatorViewPlugin;
@protocol FWProgressViewPlugin;

/**
 下拉刷新视图，默认高度60
 @note 如果indicatorView为自定义指示器时会自动隐藏标题和箭头，仅显示指示器视图
*/
NS_SWIFT_NAME(PullRefreshView)
@interface FWPullRefreshView : UIView

@property (class, nonatomic, assign) CGFloat height;
@property (nonatomic, readwrite) UIEdgeInsets originalInset;
@property (nullable, nonatomic, strong) UIColor *arrowColor;
@property (nullable, nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *subtitleLabel;
@property (nonatomic, strong) UIView<FWIndicatorViewPlugin> *indicatorView;
@property (nullable, nonatomic, strong) UIColor *indicatorColor;
@property (nonatomic, assign) CGFloat indicatorPadding;
@property (nonatomic, assign) BOOL showsTitleLabel;
@property (nonatomic, assign) BOOL showsArrowView;
@property (nonatomic, assign) BOOL shouldChangeAlpha;

@property (nonatomic, readonly) FWPullRefreshState state;
@property (nonatomic, assign, readonly) BOOL userTriggered;
@property (nullable, nonatomic, copy) void (^stateBlock)(FWPullRefreshView *view, FWPullRefreshState state);
@property (nullable, nonatomic, copy) void (^progressBlock)(FWPullRefreshView *view, CGFloat progress);

- (void)setTitle:(nullable NSString *)title forState:(FWPullRefreshState)state;
- (void)setSubtitle:(nullable NSString *)subtitle forState:(FWPullRefreshState)state;
- (void)setCustomView:(nullable UIView *)view forState:(FWPullRefreshState)state;
- (void)setAnimationView:(nullable UIView<FWProgressViewPlugin, FWIndicatorViewPlugin> *)animationView;

- (void)startAnimating;
- (void)stopAnimating;
- (BOOL)isAnimating;

@end

/**
 UIScrollView+FWPullRefresh
 
 @see https://github.com/samvermette/SVPullToRefresh
 */
@interface UIScrollView (FWPullRefresh)

- (void)fw_addPullRefreshWithBlock:(void (^)(void))block NS_REFINED_FOR_SWIFT;
- (void)fw_addPullRefreshWithTarget:(id)target action:(SEL)action NS_REFINED_FOR_SWIFT;
- (void)fw_triggerPullRefresh NS_REFINED_FOR_SWIFT;

@property (nullable, nonatomic, strong, readonly) FWPullRefreshView *fw_pullRefreshView NS_REFINED_FOR_SWIFT;
@property (nonatomic, assign) CGFloat fw_pullRefreshHeight NS_REFINED_FOR_SWIFT;
@property (nonatomic, assign) BOOL fw_showPullRefresh NS_REFINED_FOR_SWIFT;

@end

#pragma mark - UIScrollView+FWInfiniteScroll

typedef NS_ENUM(NSUInteger, FWInfiniteScrollState) {
    FWInfiniteScrollStateIdle = 0,
    FWInfiniteScrollStateTriggered,
    FWInfiniteScrollStateLoading,
    FWInfiniteScrollStateAll = 10
} NS_SWIFT_NAME(InfiniteScrollState);

/**
 上拉追加视图，默认高度60
 */
NS_SWIFT_NAME(InfiniteScrollView)
@interface FWInfiniteScrollView : UIView

@property (class, nonatomic, assign) CGFloat height;
@property (nonatomic, readwrite) BOOL enabled;
@property (nonatomic, readwrite) UIEdgeInsets originalInset;
@property (nonatomic, readwrite, assign) CGFloat preloadHeight;
@property (nonatomic, strong) UIView<FWIndicatorViewPlugin> *indicatorView;
@property (nullable, nonatomic, strong) UIColor *indicatorColor;
@property (nonatomic, assign) CGFloat indicatorPadding;
@property (nonatomic, assign) BOOL finished;
@property (nonatomic, assign, readonly) BOOL isDataEmpty;
@property (nonatomic, assign) BOOL showsFinishedView;
@property (nonatomic, strong, readonly) UILabel *finishedLabel;
@property (nonatomic, strong) UIView *finishedView;
@property (nonatomic, assign) CGFloat finishedPadding;

@property (nonatomic, readonly) FWInfiniteScrollState state;
@property (nonatomic, assign, readonly) BOOL userTriggered;
@property (nullable, nonatomic, copy) void (^stateBlock)(FWInfiniteScrollView *view, FWInfiniteScrollState state);
@property (nullable, nonatomic, copy) void (^progressBlock)(FWInfiniteScrollView *view, CGFloat progress);
@property (nullable, nonatomic, copy) void (^finishedBlock)(FWInfiniteScrollView *view, BOOL finished);
@property (nullable, nonatomic, copy) BOOL (^emptyDataBlock)(UIScrollView *scrollView);

- (void)setCustomView:(nullable UIView *)view forState:(FWInfiniteScrollState)state;
- (void)setAnimationView:(nullable UIView<FWProgressViewPlugin, FWIndicatorViewPlugin> *)animationView;

- (void)startAnimating;
- (void)stopAnimating;
- (BOOL)isAnimating;

@end

/**
 UIScrollView+FWInfiniteScroll
 
 @see https://github.com/samvermette/SVPullToRefresh
 */
@interface UIScrollView (FWInfiniteScroll)

- (void)fw_addInfiniteScrollWithBlock:(void (^)(void))block NS_REFINED_FOR_SWIFT;
- (void)fw_addInfiniteScrollWithTarget:(id)target action:(SEL)action NS_REFINED_FOR_SWIFT;
- (void)fw_triggerInfiniteScroll NS_REFINED_FOR_SWIFT;
- (void)fw_reloadInfiniteScroll NS_REFINED_FOR_SWIFT;

@property (nullable, nonatomic, strong, readonly) FWInfiniteScrollView *fw_infiniteScrollView NS_REFINED_FOR_SWIFT;
@property (nonatomic, assign) CGFloat fw_infiniteScrollHeight NS_REFINED_FOR_SWIFT;
@property (nonatomic, assign) BOOL fw_showInfiniteScroll NS_REFINED_FOR_SWIFT;
@property (nonatomic, assign) BOOL fw_infiniteScrollFinished NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
