//
//  ScrollViewController.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "ScrollViewController.h"
#import <objc/runtime.h>

#if FWMacroSPM

@interface UIView ()

- (NSArray<NSLayoutConstraint *> *)fw_pinEdgesToSuperview:(UIEdgeInsets)insets;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - __FWViewControllerManager+__FWScrollViewController

@implementation __FWViewControllerManager (__FWScrollViewController)

+ (void)load
{
    __FWViewControllerIntercepter *intercepter = [[__FWViewControllerIntercepter alloc] init];
    intercepter.viewDidLoadIntercepter = @selector(scrollViewControllerViewDidLoad:);
    intercepter.forwardSelectors = @{
        @"scrollView" : @"fw_innerScrollView",
        @"contentView" : @"fw_innerContentView",
        @"setupScrollLayout" : @"fw_innerSetupScrollLayout",
    };
    [[__FWViewControllerManager sharedInstance] registerProtocol:@protocol(__FWScrollViewController) withIntercepter:intercepter];
}

- (void)scrollViewControllerViewDidLoad:(UIViewController<__FWScrollViewController> *)viewController
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

#pragma mark - UIViewController+__FWScrollViewController

@interface UIViewController (__FWScrollViewController)

@end

@implementation UIViewController (__FWScrollViewController)

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
    UIScrollView *scrollView = [(id<__FWScrollViewController>)self scrollView];
    [scrollView fw_pinEdgesToSuperview:UIEdgeInsetsZero];
}

@end
