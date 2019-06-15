/*!
 @header     UIScrollView+FWPullRefresh.h
 @indexgroup FWFramework
 @brief      UIScrollView+FWPullRefresh
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/24
 */

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, FWPullRefreshState) {
    FWPullRefreshStateStopped = 0,
    FWPullRefreshStateTriggered,
    FWPullRefreshStateLoading,
    FWPullRefreshStateAll = 10
};

@interface FWPullRefreshView : UIView

@property (nonatomic, strong) UIColor *arrowColor;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *subtitleLabel;
@property (nonatomic, strong, readwrite) UIColor *activityIndicatorViewColor;
@property (nonatomic, readwrite) UIActivityIndicatorViewStyle activityIndicatorViewStyle;

@property (nonatomic, readonly) FWPullRefreshState state;

- (void)setTitle:(NSString *)title forState:(FWPullRefreshState)state;
- (void)setSubtitle:(NSString *)subtitle forState:(FWPullRefreshState)state;
- (void)setCustomView:(UIView *)view forState:(FWPullRefreshState)state;

- (void)startAnimating;
- (void)stopAnimating;

@end

/*!
 @brief UIScrollView+FWPullRefresh
 
 @see https://github.com/samvermette/SVPullToRefresh
 */
@interface UIScrollView (FWPullRefresh)

- (void)fwAddPullRefreshWithBlock:(void (^)(void))block;
- (void)fwAddPullRefreshWithTarget:(id)target action:(SEL)action;
- (void)fwTriggerPullRefresh;

@property (nonatomic, strong, readonly) FWPullRefreshView *fwPullRefreshView;
@property (nonatomic, assign) BOOL fwShowPullRefresh;

@end
