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
    UIScrollView *scrollView = objc_getAssociatedObject(self, @selector(fwScrollView));
    if (!scrollView) {
        scrollView = [[UIScrollView alloc] init];
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.showsHorizontalScrollIndicator = NO;
        if (@available(iOS 11.0, *)) {
            scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        objc_setAssociatedObject(self, @selector(fwScrollView), scrollView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return scrollView;
}

- (UIView *)fwInnerContentView
{
    UIView *contentView = objc_getAssociatedObject(self, @selector(fwContentView));
    if (!contentView) {
        contentView = [[UIView alloc] init];
        objc_setAssociatedObject(self, @selector(fwContentView), contentView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return contentView;
}

@end

#pragma mark - FWViewControllerIntercepter+FWScrollViewController

@implementation FWViewControllerIntercepter (FWScrollViewController)

+ (void)load
{
    [[FWViewControllerIntercepter sharedInstance] registerProtocol:@protocol(FWScrollViewController)
                                                   withIntercepter:@selector(setupScrollViewController:)
                                                  forwardSelectors:@{
                                                                     @"fwScrollView" : @"fwInnerScrollView",
                                                                     @"fwContentView" : @"fwInnerContentView",
                                                                     }];
}

- (void)setupScrollViewController:(UIViewController *)viewController
{
    UIScrollView *scrollView = [viewController performSelector:@selector(fwScrollView)];
    [viewController.view addSubview:scrollView];
    
    UIView *contentView = [viewController performSelector:@selector(fwContentView)];
    [scrollView addSubview:contentView];
    [contentView fwPinEdgesToSuperview];
    
    if ([viewController respondsToSelector:@selector(fwRenderScrollView)]) {
        [viewController performSelector:@selector(fwRenderScrollView)];
    } else {
        [scrollView fwPinEdgesToSuperview];
    }
    
    [scrollView setNeedsLayout];
    [scrollView layoutIfNeeded];
}

@end
