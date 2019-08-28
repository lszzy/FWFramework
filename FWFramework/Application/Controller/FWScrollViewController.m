/*!
 @header     FWScrollViewController.m
 @indexgroup FWFramework
 @brief      FWScrollViewController
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/27
 */

#import "FWScrollViewController.h"
#import "UIView+FWAutoLayout.h"
#import <objc/runtime.h>

#pragma mark - UIViewController+FWScrollViewController

@interface UIViewController (FWScrollViewController)

@end

@implementation UIViewController (FWScrollViewController)

- (UIScrollView *)fwInnerScrollView
{
    UIScrollView *scrollView = objc_getAssociatedObject(self, @selector(fwInnerScrollView));
    if (!scrollView) {
        scrollView = [[UIScrollView alloc] init];
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.showsHorizontalScrollIndicator = NO;
        if (@available(iOS 11.0, *)) {
            scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        objc_setAssociatedObject(self, @selector(fwInnerScrollView), scrollView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return scrollView;
}

- (UIView *)fwInnerContentView
{
    UIView *contentView = objc_getAssociatedObject(self, @selector(fwInnerContentView));
    if (!contentView) {
        contentView = [[UIView alloc] init];
        objc_setAssociatedObject(self, @selector(fwInnerContentView), contentView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return contentView;
}

@end

#pragma mark - FWViewControllerManager+FWScrollViewController

@implementation FWViewControllerManager (FWScrollViewController)

+ (void)load
{
    FWViewControllerIntercepter *intercepter = [[FWViewControllerIntercepter alloc] init];
    intercepter.loadViewIntercepter = @selector(scrollViewControllerLoadView:);
    intercepter.forwardSelectors = @{@"scrollView" : @"fwInnerScrollView", @"contentView" : @"fwInnerContentView"};
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
    } else {
        [scrollView fwPinEdgesToSuperview];
    }
    
    [scrollView setNeedsLayout];
    [scrollView layoutIfNeeded];
}

@end
