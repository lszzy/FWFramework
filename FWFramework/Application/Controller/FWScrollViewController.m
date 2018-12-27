/*!
 @header     FWScrollViewController.m
 @indexgroup FWFramework
 @brief      FWScrollViewController
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/27
 */

#import "FWScrollViewController.h"
#import "FWAspect.h"
#import "UIView+FWAutoLayout.h"
#import <objc/runtime.h>

@interface UIViewController (FWScrollViewController) <FWScrollViewController>

@end

@implementation UIViewController (FWScrollViewController)

- (UIScrollView *)fwScrollView
{
    return objc_getAssociatedObject(self, @selector(fwScrollView));
}

- (UIView *)fwContentView
{
    return objc_getAssociatedObject(self, @selector(fwContentView));
}

@end

@implementation FWViewControllerIntercepter (FWScrollViewController)

- (void)setupScrollViewController:(UIViewController *)viewController
{
    UIScrollView *scrollView = nil;
    if ([viewController respondsToSelector:@selector(fwRenderScrollView)]) {
        scrollView = [viewController performSelector:@selector(fwRenderScrollView)];
    } else {
        scrollView = [[UIScrollView alloc] init];
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.showsHorizontalScrollIndicator = NO;
        if (@available(iOS 11.0, *)) {
            scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    objc_setAssociatedObject(viewController, @selector(fwScrollView), scrollView, OBJC_ASSOCIATION_ASSIGN);
    [viewController.view addSubview:scrollView];
    
    UIView *contentView = [[UIView alloc] init];
    objc_setAssociatedObject(viewController, @selector(fwContentView), contentView, OBJC_ASSOCIATION_ASSIGN);
    [scrollView addSubview:contentView];
    [contentView fwPinEdgesToSuperview];
    
    if ([viewController respondsToSelector:@selector(fwRenderScrollLayout)]) {
        [viewController performSelector:@selector(fwRenderScrollLayout)];
    } else {
        [scrollView fwPinEdgesToSuperview];
    }
    
    [scrollView setNeedsLayout];
    [scrollView layoutIfNeeded];
}

@end
