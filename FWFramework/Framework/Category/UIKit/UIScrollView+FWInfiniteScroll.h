/*!
 @header     UIScrollView+FWInfiniteScroll.h
 @indexgroup FWFramework
 @brief      UIScrollView+FWInfiniteScroll
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/24
 */

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, FWInfiniteScrollState) {
    FWInfiniteScrollStateStopped = 0,
    FWInfiniteScrollStateTriggered,
    FWInfiniteScrollStateLoading,
    FWInfiniteScrollStateAll = 10
};

@interface FWInfiniteScrollView : UIView

@property (nonatomic, readwrite) UIActivityIndicatorViewStyle activityIndicatorViewStyle;
@property (nonatomic, readonly) FWInfiniteScrollState state;
@property (nonatomic, readwrite) BOOL enabled;

- (void)setCustomView:(UIView *)view forState:(FWInfiniteScrollState)state;

- (void)startAnimating;
- (void)stopAnimating;

@end

/*!
 @brief UIScrollView+FWInfiniteScroll
 
 @see https://github.com/samvermette/SVPullToRefresh
 */
@interface UIScrollView (FWInfiniteScroll)

- (void)fwAddInfiniteScrollWithBlock:(void (^)(void))block;
- (void)fwAddInfiniteScrollWithTarget:(id)target action:(SEL)action;
- (void)fwTriggerInfiniteScroll;

@property (nonatomic, strong, readonly) FWInfiniteScrollView *fwInfiniteScrollView;
@property (nonatomic, assign) BOOL fwShowInfiniteScroll;

@end
