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
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(fwIsRefreshing:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    return [refreshPlugin fwIsRefreshing:self];
}

- (BOOL)fwShowRefreshing {
    id<FWRefreshPlugin> refreshPlugin = [FWPluginManager loadPlugin:@protocol(FWRefreshPlugin)];
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(fwShowRefreshing:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    return [refreshPlugin fwShowRefreshing:self];
}

- (void)setFwShowRefreshing:(BOOL)fwShowRefreshing {
    id<FWRefreshPlugin> refreshPlugin = [FWPluginManager loadPlugin:@protocol(FWRefreshPlugin)];
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(fwSetShowRefreshing:scrollView:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    [refreshPlugin fwSetShowRefreshing:fwShowRefreshing scrollView:self];
}

- (void)fwSetRefreshingBlock:(void (^)(void))block {
    id<FWRefreshPlugin> refreshPlugin = [FWPluginManager loadPlugin:@protocol(FWRefreshPlugin)];
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(fwSetRefreshingBlock:scrollView:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    [refreshPlugin fwSetRefreshingBlock:block scrollView:self];
}

- (void)fwSetRefreshingTarget:(id)target action:(SEL)action {
    id<FWRefreshPlugin> refreshPlugin = [FWPluginManager loadPlugin:@protocol(FWRefreshPlugin)];
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(fwSetRefreshingTarget:action:scrollView:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    [refreshPlugin fwSetRefreshingTarget:target action:action scrollView:self];
}

- (void)fwBeginRefreshing {
    id<FWRefreshPlugin> refreshPlugin = [FWPluginManager loadPlugin:@protocol(FWRefreshPlugin)];
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(fwBeginRefreshing:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    [refreshPlugin fwBeginRefreshing:self];
}

- (void)fwEndRefreshing {
    id<FWRefreshPlugin> refreshPlugin = [FWPluginManager loadPlugin:@protocol(FWRefreshPlugin)];
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(fwEndRefreshing:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    [refreshPlugin fwEndRefreshing:self];
}

#pragma mark - Loading

- (BOOL)fwIsLoading {
    id<FWRefreshPlugin> refreshPlugin = [FWPluginManager loadPlugin:@protocol(FWRefreshPlugin)];
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(fwIsLoading:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    return [refreshPlugin fwIsLoading:self];
}

- (BOOL)fwShowLoading {
    id<FWRefreshPlugin> refreshPlugin = [FWPluginManager loadPlugin:@protocol(FWRefreshPlugin)];
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(fwShowLoading:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    return [refreshPlugin fwShowLoading:self];
}

- (void)setFwShowLoading:(BOOL)fwShowLoading {
    id<FWRefreshPlugin> refreshPlugin = [FWPluginManager loadPlugin:@protocol(FWRefreshPlugin)];
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(fwSetShowLoading:scrollView:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    [refreshPlugin fwSetShowLoading:fwShowLoading scrollView:self];
}

- (void)fwSetLoadingBlock:(void (^)(void))block {
    id<FWRefreshPlugin> refreshPlugin = [FWPluginManager loadPlugin:@protocol(FWRefreshPlugin)];
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(fwSetLoadingBlock:scrollView:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    [refreshPlugin fwSetLoadingBlock:block scrollView:self];
}

- (void)fwSetLoadingTarget:(id)target action:(SEL)action {
    id<FWRefreshPlugin> refreshPlugin = [FWPluginManager loadPlugin:@protocol(FWRefreshPlugin)];
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(fwSetLoadingTarget:action:scrollView:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    [refreshPlugin fwSetLoadingTarget:target action:action scrollView:self];
}

- (void)fwBeginLoading {
    id<FWRefreshPlugin> refreshPlugin = [FWPluginManager loadPlugin:@protocol(FWRefreshPlugin)];
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(fwBeginLoading:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    [refreshPlugin fwBeginLoading:self];
}

- (void)fwEndLoading {
    id<FWRefreshPlugin> refreshPlugin = [FWPluginManager loadPlugin:@protocol(FWRefreshPlugin)];
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(fwEndLoading:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    [refreshPlugin fwEndLoading:self];
}

@end
