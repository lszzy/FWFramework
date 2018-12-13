/*!
 @header     UIScrollView+FWRefreshControl.m
 @indexgroup FWFramework
 @brief      UIScrollView+FWRefreshControl
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/13
 */

#import "UIScrollView+FWRefreshControl.h"
#import "FWMessage.h"
#import <objc/runtime.h>

@implementation UIScrollView (FWRefreshControl)

#pragma mark - UIRefreshControl

- (UIRefreshControl *)fwRefreshControl
{
    if (@available(iOS 10.0, *)) {
        return self.refreshControl;
    }
    
    return objc_getAssociatedObject(self, @selector(fwRefreshControl));
}

- (void)setFwRefreshControl:(UIRefreshControl *)fwRefreshControl
{
    if (@available(iOS 10.0, *)) {
        if (fwRefreshControl != self.refreshControl) {
            // 删除旧的控件
            if (self.refreshControl) {
                if (self.refreshControl.isRefreshing) {
                    [self.refreshControl endRefreshing];
                }
                // 正在使用时设置为nil时会出现警告和不可预见的错误
                [self.refreshControl removeFromSuperview];
            }
            
            // 添加新的控件
            if (fwRefreshControl) {
                self.refreshControl = fwRefreshControl;
            }
        }
        return;
    }
    
    if (fwRefreshControl != self.fwRefreshControl) {
        // 删除旧的控件
        if (self.fwRefreshControl) {
            if (self.fwRefreshControl.isRefreshing) {
                [self.fwRefreshControl endRefreshing];
            }
            [self.fwRefreshControl removeFromSuperview];
        }
        
        // 添加新的控件
        if (fwRefreshControl) {
            [self insertSubview:fwRefreshControl atIndex:0];
        }
        
        // KVO，兼容iOS10
        [self willChangeValueForKey:@"refreshControl"];
        // 由于subviews引用fwRefreshControl，此处可以用ASSIGN
        objc_setAssociatedObject(self, @selector(fwRefreshControl), fwRefreshControl, OBJC_ASSOCIATION_ASSIGN);
        // KVO，兼容iOS10
        [self didChangeValueForKey:@"refreshControl"];
    }
}

#pragma mark - PullRefresh

- (BOOL)fwCanPullRefresh
{
    return [objc_getAssociatedObject(self, @selector(fwCanPullRefresh)) boolValue];
}

- (void)setFwCanPullRefresh:(BOOL)fwCanPullRefresh
{
    if (fwCanPullRefresh != self.fwCanPullRefresh) {
        [self willChangeValueForKey:@"fwCanPullRefresh"];
        objc_setAssociatedObject(self, @selector(fwCanPullRefresh), @(fwCanPullRefresh), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self didChangeValueForKey:@"fwCanPullRefresh"];
        
        // 显示下拉刷新
        if (fwCanPullRefresh) {
            self.fwRefreshControl = [[UIRefreshControl alloc] init];
            [self.fwRefreshControl addTarget:self action:@selector(fwInnerPullRefreshBlock) forControlEvents:UIControlEventValueChanged];
        // 去掉下拉刷新
        } else {
            self.fwRefreshControl = nil;
        }
    }
}

- (void)fwSetPullRefreshBlock:(void (^)(void))block
{
    objc_setAssociatedObject(self, @selector(fwInnerPullRefreshBlock), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    // 始终允许纵向拖拽，内容不够时也可以下拉
    self.alwaysBounceVertical = YES;
    // 自动启用下拉刷新
    self.fwCanPullRefresh = YES;
}

- (void)fwInnerPullRefreshBlock
{
    void (^block)(void) = objc_getAssociatedObject(self, @selector(fwInnerPullRefreshBlock));
    if (block) {
        dispatch_async(dispatch_get_main_queue(), ^{
            block();
        });
    }
}

- (BOOL)fwIsPullRefresh
{
    return self.fwRefreshControl.isRefreshing;
}

- (void)fwBeginPullRefresh
{
    if (self.fwCanPullRefresh) {
        [self.fwRefreshControl beginRefreshing];
        [self fwInnerPullRefreshBlock];
    }
}

- (void)fwEndPullRefresh
{
    [self.fwRefreshControl endRefreshing];
}

#pragma mark - InfiniteScroll

- (BOOL)fwCanInfiniteScroll
{
    return [objc_getAssociatedObject(self, @selector(fwCanInfiniteScroll)) boolValue];
}

- (void)setFwCanInfiniteScroll:(BOOL)fwCanInfiniteScroll
{
    if (fwCanInfiniteScroll != self.fwCanInfiniteScroll) {
        [self willChangeValueForKey:@"fwCanInfiniteScroll"];
        objc_setAssociatedObject(self, @selector(fwCanInfiniteScroll), @(fwCanInfiniteScroll), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self didChangeValueForKey:@"fwCanInfiniteScroll"];
    }
}

- (void)fwSetInfiniteScrollBlock:(void (^)(void))block
{
    objc_setAssociatedObject(self, @selector(fwInnerInfiniteScrollBlock), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    [self fwObserveProperty:@"contentOffset" target:self action:@selector(fwInnerScrollViewDidScroll)];
    
    self.fwCanInfiniteScroll = YES;
}

- (void)fwInnerInfiniteScrollBlock
{
    void (^block)(void) = objc_getAssociatedObject(self, @selector(fwInnerInfiniteScrollBlock));
    if (block) {
        dispatch_async(dispatch_get_main_queue(), ^{
            block();
        });
    }
}

- (BOOL)fwIsInfiniteScroll
{
    return [objc_getAssociatedObject(self, @selector(fwIsInfiniteScroll)) boolValue];
}

- (void)setFwIsInfiniteScroll:(BOOL)fwIsInfiniteScroll
{
    if (fwIsInfiniteScroll != self.fwIsInfiniteScroll) {
        [self willChangeValueForKey:@"fwIsInfiniteScroll"];
        objc_setAssociatedObject(self, @selector(fwIsInfiniteScroll), @(fwIsInfiniteScroll), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self didChangeValueForKey:@"fwIsInfiniteScroll"];
    }
}

- (void)fwBeginInfiniteScroll
{
    if (self.fwCanInfiniteScroll) {
        self.fwIsInfiniteScroll = YES;
        [self fwInnerInfiniteScrollBlock];
    }
}

- (void)fwEndInfiniteScroll
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.fwIsInfiniteScroll = NO;
    });
}

- (void)fwInnerScrollViewDidScroll
{
    if (!self.fwCanInfiniteScroll ||
        self.fwIsInfiniteScroll ||
        CGRectGetHeight(self.frame) < 1.0 ||
        (self.contentSize.height + self.contentInset.bottom < CGRectGetHeight(self.frame))) {
        return;
    }
    
    if (self.contentOffset.y + CGRectGetHeight(self.frame) > self.contentSize.height - self.contentInset.bottom - 200.f) {
        [self fwBeginInfiniteScroll];
    }
}

@end
