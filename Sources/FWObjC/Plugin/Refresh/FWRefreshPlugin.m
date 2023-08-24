//
//  FWRefreshPlugin.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWRefreshPlugin.h"
#import "FWRefreshPluginImpl.h"
#import "FWPlugin.h"
#import <objc/runtime.h>

#pragma mark - UIScrollView+FWRefreshPlugin

@implementation UIScrollView (FWRefreshPlugin)

- (id<FWRefreshPlugin>)fw_refreshPlugin
{
    id<FWRefreshPlugin> refreshPlugin = objc_getAssociatedObject(self, @selector(fw_refreshPlugin));
    if (!refreshPlugin) refreshPlugin = [FWPluginManager loadPlugin:@protocol(FWRefreshPlugin)];
    if (!refreshPlugin) refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    return refreshPlugin;
}

- (void)setFw_refreshPlugin:(id<FWRefreshPlugin>)refreshPlugin
{
    objc_setAssociatedObject(self, @selector(fw_refreshPlugin), refreshPlugin, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Refreshing

- (BOOL)fw_isRefreshing {
    id<FWRefreshPlugin> refreshPlugin = self.fw_refreshPlugin;
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(isRefreshing:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    return [refreshPlugin isRefreshing:self];
}

- (BOOL)fw_shouldRefreshing {
    id<FWRefreshPlugin> refreshPlugin = self.fw_refreshPlugin;
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(shouldRefreshing:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    return [refreshPlugin shouldRefreshing:self];
}

- (void)setFw_shouldRefreshing:(BOOL)shouldRefreshing {
    id<FWRefreshPlugin> refreshPlugin = self.fw_refreshPlugin;
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(setShouldRefreshing:scrollView:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    [refreshPlugin setShouldRefreshing:shouldRefreshing scrollView:self];
}

- (void)fw_setRefreshingBlock:(void (^)(void))block {
    id<FWRefreshPlugin> refreshPlugin = self.fw_refreshPlugin;
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(setRefreshingBlock:scrollView:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    [refreshPlugin setRefreshingBlock:block scrollView:self];
}

- (void)fw_setRefreshingTarget:(id)target action:(SEL)action {
    id<FWRefreshPlugin> refreshPlugin = self.fw_refreshPlugin;
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(setRefreshingTarget:action:scrollView:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    [refreshPlugin setRefreshingTarget:target action:action scrollView:self];
}

- (void)fw_beginRefreshing {
    id<FWRefreshPlugin> refreshPlugin = self.fw_refreshPlugin;
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(beginRefreshing:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    [refreshPlugin beginRefreshing:self];
}

- (void)fw_endRefreshing {
    id<FWRefreshPlugin> refreshPlugin = self.fw_refreshPlugin;
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(endRefreshing:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    [refreshPlugin endRefreshing:self];
}

- (void)fw_endRefreshingWithFinished:(BOOL)finished {
    [self fw_endRefreshing];
    self.fw_loadingFinished = finished;
}

#pragma mark - Loading

- (BOOL)fw_isLoading {
    id<FWRefreshPlugin> refreshPlugin = self.fw_refreshPlugin;
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(isLoading:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    return [refreshPlugin isLoading:self];
}

- (BOOL)fw_shouldLoading {
    id<FWRefreshPlugin> refreshPlugin = self.fw_refreshPlugin;
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(shouldLoading:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    return [refreshPlugin shouldLoading:self];
}

- (void)setFw_shouldLoading:(BOOL)shouldLoading {
    id<FWRefreshPlugin> refreshPlugin = self.fw_refreshPlugin;
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(setShouldLoading:scrollView:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    [refreshPlugin setShouldLoading:shouldLoading scrollView:self];
}

- (BOOL)fw_loadingFinished {
    id<FWRefreshPlugin> refreshPlugin = self.fw_refreshPlugin;
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(loadingFinished:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    return [refreshPlugin loadingFinished:self];
}

- (void)setFw_loadingFinished:(BOOL)loadingFinished {
    id<FWRefreshPlugin> refreshPlugin = self.fw_refreshPlugin;
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(setLoadingFinished:scrollView:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    [refreshPlugin setLoadingFinished:loadingFinished scrollView:self];
}

- (void)fw_setLoadingBlock:(void (^)(void))block {
    id<FWRefreshPlugin> refreshPlugin = self.fw_refreshPlugin;
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(setLoadingBlock:scrollView:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    [refreshPlugin setLoadingBlock:block scrollView:self];
}

- (void)fw_setLoadingTarget:(id)target action:(SEL)action {
    id<FWRefreshPlugin> refreshPlugin = self.fw_refreshPlugin;
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(setLoadingTarget:action:scrollView:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    [refreshPlugin setLoadingTarget:target action:action scrollView:self];
}

- (void)fw_beginLoading {
    id<FWRefreshPlugin> refreshPlugin = self.fw_refreshPlugin;
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(beginLoading:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    [refreshPlugin beginLoading:self];
}

- (void)fw_endLoading {
    id<FWRefreshPlugin> refreshPlugin = self.fw_refreshPlugin;
    if (!refreshPlugin || ![refreshPlugin respondsToSelector:@selector(endLoading:)]) {
        refreshPlugin = FWRefreshPluginImpl.sharedInstance;
    }
    [refreshPlugin endLoading:self];
}

- (void)fw_endLoadingWithFinished:(BOOL)finished {
    [self fw_endLoading];
    self.fw_loadingFinished = finished;
}

@end
