/*!
 @header     FWRefreshPlugin.m
 @indexgroup FWFramework
 @brief      FWRefreshPlugin
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/16
 */

#import "FWRefreshPlugin.h"
#import "FWRefreshPluginImpl.h"
#import "FWPlugin.h"

#pragma mark - UIScrollView+FWRefreshPlugin

@implementation UIScrollView (FWRefreshPlugin)

#pragma mark - Refreshing

- (BOOL)fwIsRefreshing {
    id<FWRefreshPlugin> refreshPlugin = [FWPluginManager loadPlugin:@protocol(FWRefreshPlugin)];
    if (refreshPlugin && [refreshPlugin respondsToSelector:@selector(fwIsRefreshing:)]) {
        return [refreshPlugin fwIsRefreshing:self];
    }
    
    return self.fwPullRefreshView.state == FWPullRefreshStateLoading;
}

- (BOOL)fwShowRefreshing {
    id<FWRefreshPlugin> refreshPlugin = [FWPluginManager loadPlugin:@protocol(FWRefreshPlugin)];
    if (refreshPlugin && [refreshPlugin respondsToSelector:@selector(fwShowRefreshing:)]) {
        return [refreshPlugin fwShowRefreshing:self];
    }
    
    return self.fwShowPullRefresh;
}

- (void)setFwShowRefreshing:(BOOL)fwShowRefreshing {
    id<FWRefreshPlugin> refreshPlugin = [FWPluginManager loadPlugin:@protocol(FWRefreshPlugin)];
    if (refreshPlugin && [refreshPlugin respondsToSelector:@selector(fwSetShowRefreshing:scrollView:)]) {
        [refreshPlugin fwSetShowRefreshing:fwShowRefreshing scrollView:self];
        return;
    }
    
    self.fwShowPullRefresh = fwShowRefreshing;
}

- (void)fwSetRefreshingBlock:(void (^)(void))block {
    id<FWRefreshPlugin> refreshPlugin = [FWPluginManager loadPlugin:@protocol(FWRefreshPlugin)];
    if (refreshPlugin && [refreshPlugin respondsToSelector:@selector(fwSetRefreshingBlock:scrollView:)]) {
        [refreshPlugin fwSetRefreshingBlock:block scrollView:self];
        return;
    }
    
    [self fwAddPullRefreshWithBlock:block];
}

- (void)fwSetRefreshingTarget:(id)target action:(SEL)action {
    id<FWRefreshPlugin> refreshPlugin = [FWPluginManager loadPlugin:@protocol(FWRefreshPlugin)];
    if (refreshPlugin && [refreshPlugin respondsToSelector:@selector(fwSetRefreshingTarget:action:scrollView:)]) {
        [refreshPlugin fwSetRefreshingTarget:target action:action scrollView:self];
        return;
    }
    
    [self fwAddPullRefreshWithTarget:target action:action];
}

- (void)fwBeginRefreshing {
    id<FWRefreshPlugin> refreshPlugin = [FWPluginManager loadPlugin:@protocol(FWRefreshPlugin)];
    if (refreshPlugin && [refreshPlugin respondsToSelector:@selector(fwBeginRefreshing:)]) {
        [refreshPlugin fwBeginRefreshing:self];
        return;
    }
    
    [self fwTriggerPullRefresh];
}

- (void)fwEndRefreshing {
    id<FWRefreshPlugin> refreshPlugin = [FWPluginManager loadPlugin:@protocol(FWRefreshPlugin)];
    if (refreshPlugin && [refreshPlugin respondsToSelector:@selector(fwEndRefreshing:)]) {
        [refreshPlugin fwEndRefreshing:self];
        return;
    }
    
    [self.fwPullRefreshView stopAnimating];
}

#pragma mark - Loading

- (BOOL)fwIsLoading {
    id<FWRefreshPlugin> refreshPlugin = [FWPluginManager loadPlugin:@protocol(FWRefreshPlugin)];
    if (refreshPlugin && [refreshPlugin respondsToSelector:@selector(fwIsLoading:)]) {
        return [refreshPlugin fwIsLoading:self];
    }
    
    return self.fwInfiniteScrollView.state == FWInfiniteScrollStateLoading;
}

- (BOOL)fwShowLoading {
    id<FWRefreshPlugin> refreshPlugin = [FWPluginManager loadPlugin:@protocol(FWRefreshPlugin)];
    if (refreshPlugin && [refreshPlugin respondsToSelector:@selector(fwShowLoading:)]) {
        return [refreshPlugin fwShowLoading:self];
    }
    
    return self.fwShowInfiniteScroll;
}

- (void)setFwShowLoading:(BOOL)fwShowLoading {
    id<FWRefreshPlugin> refreshPlugin = [FWPluginManager loadPlugin:@protocol(FWRefreshPlugin)];
    if (refreshPlugin && [refreshPlugin respondsToSelector:@selector(fwSetShowLoading:scrollView:)]) {
        [refreshPlugin fwSetShowLoading:fwShowLoading scrollView:self];
        return;
    }
    
    self.fwShowInfiniteScroll = fwShowLoading;
}

- (void)fwSetLoadingBlock:(void (^)(void))block {
    id<FWRefreshPlugin> refreshPlugin = [FWPluginManager loadPlugin:@protocol(FWRefreshPlugin)];
    if (refreshPlugin && [refreshPlugin respondsToSelector:@selector(fwSetLoadingBlock:scrollView:)]) {
        [refreshPlugin fwSetLoadingBlock:block scrollView:self];
        return;
    }
    
    [self fwAddInfiniteScrollWithBlock:block];
}

- (void)fwSetLoadingTarget:(id)target action:(SEL)action {
    id<FWRefreshPlugin> refreshPlugin = [FWPluginManager loadPlugin:@protocol(FWRefreshPlugin)];
    if (refreshPlugin && [refreshPlugin respondsToSelector:@selector(fwSetLoadingTarget:action:scrollView:)]) {
        [refreshPlugin fwSetLoadingTarget:target action:action scrollView:self];
        return;
    }
    
    [self fwAddInfiniteScrollWithTarget:target action:action];
}

- (void)fwBeginLoading {
    id<FWRefreshPlugin> refreshPlugin = [FWPluginManager loadPlugin:@protocol(FWRefreshPlugin)];
    if (refreshPlugin && [refreshPlugin respondsToSelector:@selector(fwBeginLoading:)]) {
        [refreshPlugin fwBeginLoading:self];
        return;
    }
    
    [self fwTriggerInfiniteScroll];
}

- (void)fwEndLoading {
    id<FWRefreshPlugin> refreshPlugin = [FWPluginManager loadPlugin:@protocol(FWRefreshPlugin)];
    if (refreshPlugin && [refreshPlugin respondsToSelector:@selector(fwEndLoading:)]) {
        [refreshPlugin fwEndLoading:self];
        return;
    }
    
    [self.fwInfiniteScrollView stopAnimating];
}

@end
