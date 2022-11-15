//
//  FWScrollViewController.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWScrollViewController.h"
#import <objc/runtime.h>
#if FWMacroSPM
@import FWFramework;
#else
#import <FWFramework/FWFramework-Swift.h>
#endif

#pragma mark - FWViewControllerManager+FWScrollViewController

@implementation FWViewControllerManager (FWScrollViewController)

+ (void)load
{
    FWViewControllerIntercepter *intercepter = [[FWViewControllerIntercepter alloc] init];
    intercepter.viewDidLoadIntercepter = @selector(scrollViewControllerViewDidLoad:);
    intercepter.forwardSelectors = @{
        @"scrollView" : @"fw_innerScrollView",
        @"contentView" : @"fw_innerContentView",
        @"setupScrollLayout" : @"fw_innerSetupScrollLayout",
    };
    [[FWViewControllerManager sharedInstance] registerProtocol:@protocol(FWScrollViewController) withIntercepter:intercepter];
}

- (void)scrollViewControllerViewDidLoad:(UIViewController<FWScrollViewController> *)viewController
{
    UIScrollView *scrollView = [viewController scrollView];
    [viewController.view addSubview:scrollView];
    
    UIView *contentView = [viewController contentView];
    [scrollView addSubview:contentView];
    [contentView fw_pinEdgesToSuperview:UIEdgeInsetsZero];
    
    if (self.hookScrollViewController) {
        self.hookScrollViewController(viewController);
    }
    
    if ([viewController respondsToSelector:@selector(setupScrollView)]) {
        [viewController setupScrollView];
    }
    
    [viewController setupScrollLayout];
    [scrollView setNeedsLayout];
    [scrollView layoutIfNeeded];
}

@end

#pragma mark - UIViewController+FWScrollViewController

@interface UIViewController (FWScrollViewController)

@end

@implementation UIViewController (FWScrollViewController)

- (UIScrollView *)fw_innerScrollView
{
    UIScrollView *scrollView = objc_getAssociatedObject(self, _cmd);
    if (!scrollView) {
        scrollView = [[UIScrollView alloc] init];
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.showsHorizontalScrollIndicator = NO;
        objc_setAssociatedObject(self, _cmd, scrollView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return scrollView;
}

- (UIView *)fw_innerContentView
{
    UIView *contentView = objc_getAssociatedObject(self, _cmd);
    if (!contentView) {
        contentView = [[UIView alloc] init];
        objc_setAssociatedObject(self, _cmd, contentView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return contentView;
}

- (void)fw_innerSetupScrollLayout
{
    UIScrollView *scrollView = [(id<FWScrollViewController>)self scrollView];
    [scrollView fw_pinEdgesToSuperview:UIEdgeInsetsZero];
}

@end
