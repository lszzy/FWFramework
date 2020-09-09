/*!
 @header     FWScrollViewController.m
 @indexgroup FWFramework
 @brief      FWScrollViewController
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/27
 */

#import "FWScrollViewController.h"
#import "FWLayoutManager.h"
#import <objc/runtime.h>

#pragma mark - FWViewControllerManager+FWScrollViewController

@implementation FWViewControllerManager (FWScrollViewController)

+ (void)load
{
    FWViewControllerIntercepter *intercepter = [[FWViewControllerIntercepter alloc] init];
    intercepter.loadViewIntercepter = @selector(scrollViewControllerLoadView:);
    intercepter.forwardSelectors = @{
        @"scrollView" : @"fwInnerScrollView",
        @"contentView" : @"fwInnerContentView",
        @"renderScrollLayout" : @"fwInnerRenderScrollLayout",
    };
    [[FWViewControllerManager sharedInstance] registerProtocol:@protocol(FWScrollViewController) withIntercepter:intercepter];
}

- (void)scrollViewControllerLoadView:(UIViewController<FWScrollViewController> *)viewController
{
    UIScrollView *scrollView = [viewController scrollView];
    [viewController.view addSubview:scrollView];
    
    UIView *contentView = [viewController contentView];
    [scrollView addSubview:contentView];
    [contentView fwPinEdgesToSuperview];
    
    if ([viewController respondsToSelector:@selector(renderScrollView)]) {
        [viewController renderScrollView];
    }
    
    [viewController renderScrollLayout];
    [scrollView setNeedsLayout];
    [scrollView layoutIfNeeded];
}

@end

#pragma mark - UIViewController+FWScrollViewController

@interface UIViewController (FWScrollViewController)

@end

@implementation UIViewController (FWScrollViewController)

- (UIScrollView *)fwInnerScrollView
{
    UIScrollView *scrollView = objc_getAssociatedObject(self, _cmd);
    if (!scrollView) {
        scrollView = [[UIScrollView alloc] init];
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.showsHorizontalScrollIndicator = NO;
        if (@available(iOS 11.0, *)) {
            scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        objc_setAssociatedObject(self, _cmd, scrollView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return scrollView;
}

- (UIView *)fwInnerContentView
{
    UIView *contentView = objc_getAssociatedObject(self, _cmd);
    if (!contentView) {
        contentView = [[UIView alloc] init];
        objc_setAssociatedObject(self, _cmd, contentView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return contentView;
}

- (void)fwInnerRenderScrollLayout
{
    UIScrollView *scrollView = [(id<FWScrollViewController>)self scrollView];
    [scrollView fwPinEdgesToSuperview];
}

@end
