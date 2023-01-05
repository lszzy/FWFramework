//
//  RefreshPluginImpl.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "RefreshPluginImpl.h"

#if FWMacroSPM

@interface UIScrollView ()

@property (nonatomic, strong, nullable) __FWPullRefreshView *__fw_pullRefreshView;
@property (nonatomic, assign) BOOL __fw_showPullRefresh;
@property (nonatomic, strong, nullable) __FWInfiniteScrollView *__fw_infiniteScrollView;
@property (nonatomic, assign) BOOL __fw_showInfiniteScroll;
@property (nonatomic, assign) BOOL __fw_infiniteScrollFinished;
- (void)__fw_addPullRefreshWithBlock:(void (^)(void))block;
- (void)__fw_addPullRefreshWithTarget:(id)target action:(SEL)action;
- (void)__fw_triggerPullRefresh;
- (void)__fw_addInfiniteScrollWithBlock:(void (^)(void))block;
- (void)__fw_addInfiniteScrollWithTarget:(id)target action:(SEL)action;
- (void)__fw_triggerInfiniteScroll;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - __FWRefreshPluginImpl

@implementation __FWRefreshPluginImpl

+ (__FWRefreshPluginImpl *)sharedInstance {
    static __FWRefreshPluginImpl *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[__FWRefreshPluginImpl alloc] init];
    });
    return instance;
}

#pragma mark - Refreshing

- (BOOL)isRefreshing:(UIScrollView *)scrollView {
    return scrollView.__fw_pullRefreshView.state == __FWPullRefreshStateLoading;
}

- (BOOL)shouldRefreshing:(UIScrollView *)scrollView {
    return scrollView.__fw_showPullRefresh;
}

- (void)setShouldRefreshing:(BOOL)shouldRefreshing scrollView:(UIScrollView *)scrollView {
    scrollView.__fw_showPullRefresh = shouldRefreshing;
}

- (void)setRefreshingBlock:(void (^)(void))block scrollView:(UIScrollView *)scrollView {
    [scrollView __fw_addPullRefreshWithBlock:block];
    if (self.pullRefreshBlock) self.pullRefreshBlock(scrollView.__fw_pullRefreshView);
}

- (void)setRefreshingTarget:(id)target action:(SEL)action scrollView:(UIScrollView *)scrollView {
    [scrollView __fw_addPullRefreshWithTarget:target action:action];
    if (self.pullRefreshBlock) self.pullRefreshBlock(scrollView.__fw_pullRefreshView);
}

- (void)beginRefreshing:(UIScrollView *)scrollView {
    [scrollView __fw_triggerPullRefresh];
}

- (void)endRefreshing:(UIScrollView *)scrollView {
    [scrollView.__fw_pullRefreshView stopAnimating];
}

#pragma mark - Loading

- (BOOL)isLoading:(UIScrollView *)scrollView {
    return scrollView.__fw_infiniteScrollView.state == __FWInfiniteScrollStateLoading;
}

- (BOOL)shouldLoading:(UIScrollView *)scrollView {
    return scrollView.__fw_showInfiniteScroll;
}

- (void)setShouldLoading:(BOOL)shouldLoading scrollView:(UIScrollView *)scrollView {
    scrollView.__fw_showInfiniteScroll = shouldLoading;
}

- (BOOL)loadingFinished:(UIScrollView *)scrollView {
    return scrollView.__fw_infiniteScrollFinished;
}

- (void)setLoadingFinished:(BOOL)loadingFinished scrollView:(UIScrollView *)scrollView {
    scrollView.__fw_infiniteScrollFinished = loadingFinished;
}

- (void)setLoadingBlock:(void (^)(void))block scrollView:(UIScrollView *)scrollView {
    [scrollView __fw_addInfiniteScrollWithBlock:block];
    if (self.infiniteScrollBlock) self.infiniteScrollBlock(scrollView.__fw_infiniteScrollView);
}

- (void)setLoadingTarget:(id)target action:(SEL)action scrollView:(UIScrollView *)scrollView {
    [scrollView __fw_addInfiniteScrollWithTarget:target action:action];
    if (self.infiniteScrollBlock) self.infiniteScrollBlock(scrollView.__fw_infiniteScrollView);
}

- (void)beginLoading:(UIScrollView *)scrollView {
    [scrollView __fw_triggerInfiniteScroll];
}

- (void)endLoading:(UIScrollView *)scrollView {
    [scrollView.__fw_infiniteScrollView stopAnimating];
}

@end
