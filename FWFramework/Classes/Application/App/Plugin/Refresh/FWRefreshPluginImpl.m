/*!
 @header     FWRefreshPluginImpl.m
 @indexgroup FWFramework
 @brief      FWRefreshPlugin
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/16
 */

#import "FWRefreshPluginImpl.h"

#pragma mark - FWRefreshPluginImpl

@implementation FWRefreshPluginImpl

+ (FWRefreshPluginImpl *)sharedInstance {
    static FWRefreshPluginImpl *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWRefreshPluginImpl alloc] init];
    });
    return instance;
}

#pragma mark - Refreshing

- (BOOL)fwIsRefreshing:(UIScrollView *)scrollView {
    return scrollView.fwPullRefreshView.state == FWPullRefreshStateLoading;
}

- (BOOL)fwShowRefreshing:(UIScrollView *)scrollView {
    return scrollView.fwShowPullRefresh;
}

- (void)fwSetShowRefreshing:(BOOL)showRefreshing scrollView:(UIScrollView *)scrollView {
    scrollView.fwShowPullRefresh = showRefreshing;
}

- (void)fwSetRefreshingBlock:(void (^)(void))block scrollView:(UIScrollView *)scrollView {
    [scrollView fwAddPullRefreshWithBlock:block];
    if (self.pullRefreshBlock) self.pullRefreshBlock(scrollView.fwPullRefreshView);
}

- (void)fwSetRefreshingTarget:(id)target action:(SEL)action scrollView:(UIScrollView *)scrollView {
    [scrollView fwAddPullRefreshWithTarget:target action:action];
    if (self.pullRefreshBlock) self.pullRefreshBlock(scrollView.fwPullRefreshView);
}

- (void)fwBeginRefreshing:(UIScrollView *)scrollView {
    [scrollView fwTriggerPullRefresh];
}

- (void)fwEndRefreshing:(UIScrollView *)scrollView {
    [scrollView.fwPullRefreshView stopAnimating];
}

#pragma mark - Loading

- (BOOL)fwIsLoading:(UIScrollView *)scrollView {
    return scrollView.fwInfiniteScrollView.state == FWInfiniteScrollStateLoading;
}

- (BOOL)fwShowLoading:(UIScrollView *)scrollView {
    return scrollView.fwShowInfiniteScroll;
}

- (void)fwSetShowLoading:(BOOL)showLoading scrollView:(UIScrollView *)scrollView {
    scrollView.fwShowInfiniteScroll = showLoading;
}

- (void)fwSetLoadingBlock:(void (^)(void))block scrollView:(UIScrollView *)scrollView {
    [scrollView fwAddInfiniteScrollWithBlock:block];
    if (self.infiniteScrollBlock) self.infiniteScrollBlock(scrollView.fwInfiniteScrollView);
}

- (void)fwSetLoadingTarget:(id)target action:(SEL)action scrollView:(UIScrollView *)scrollView {
    [scrollView fwAddInfiniteScrollWithTarget:target action:action];
    if (self.infiniteScrollBlock) self.infiniteScrollBlock(scrollView.fwInfiniteScrollView);
}

- (void)fwBeginLoading:(UIScrollView *)scrollView {
    [scrollView fwTriggerInfiniteScroll];
}

- (void)fwEndLoading:(UIScrollView *)scrollView {
    [scrollView.fwInfiniteScrollView stopAnimating];
}

@end
