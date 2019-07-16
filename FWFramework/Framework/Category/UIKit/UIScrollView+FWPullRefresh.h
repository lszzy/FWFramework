/*!
 @header     UIScrollView+FWPullRefresh.h
 @indexgroup FWFramework
 @brief      UIScrollView+FWPullRefresh
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/24
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, FWPullRefreshState) {
    FWPullRefreshStateStopped = 0,
    FWPullRefreshStateTriggered,
    FWPullRefreshStateLoading,
    FWPullRefreshStateAll = 10
};

@interface FWPullRefreshView : UIView

@property (nullable, nonatomic, strong) UIColor *arrowColor;
@property (nullable, nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *subtitleLabel;
@property (nullable, nonatomic, strong) UIColor *activityIndicatorViewColor;
@property (nonatomic, assign) UIActivityIndicatorViewStyle activityIndicatorViewStyle;

@property (nonatomic, readonly) FWPullRefreshState state;

- (void)setTitle:(nullable NSString *)title forState:(FWPullRefreshState)state;
- (void)setSubtitle:(nullable NSString *)subtitle forState:(FWPullRefreshState)state;
- (void)setCustomView:(nullable UIView *)view forState:(FWPullRefreshState)state;

- (void)startAnimating;
- (void)stopAnimating;
- (BOOL)isAnimating;

@end

/*!
 @brief UIScrollView+FWPullRefresh
 
 @see https://github.com/samvermette/SVPullToRefresh
 */
@interface UIScrollView (FWPullRefresh)

- (void)fwAddPullRefreshWithBlock:(void (^)(void))block;
- (void)fwAddPullRefreshWithTarget:(id)target action:(SEL)action;
- (void)fwTriggerPullRefresh;

@property (nullable, nonatomic, strong, readonly) FWPullRefreshView *fwPullRefreshView;
@property (nonatomic, assign) BOOL fwShowPullRefresh;

@end

NS_ASSUME_NONNULL_END
