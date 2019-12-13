/*!
 @header     UIScrollView+FWInfiniteScroll.h
 @indexgroup FWFramework
 @brief      UIScrollView+FWInfiniteScroll
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/24
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

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
@property (nonatomic, assign) BOOL fwShowInfiniteScroll;

@end

NS_ASSUME_NONNULL_END
