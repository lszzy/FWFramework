/*!
 @header     FWWebViewController.m
 @indexgroup FWFramework
 @brief      FWWebViewController
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/8/28
 */

#import "FWWebViewController.h"
#import "UIView+FWAutoLayout.h"
#import "UIWebView+FWFramework.h"
#import "FWMessage.h"
#import <objc/runtime.h>

#pragma mark - UIViewController+FWWebViewController

@interface UIViewController (FWWebViewController)

@end

@implementation UIViewController (FWWebViewController)

- (WKWebView *)fwInnerWebView
{
    WKWebView *webView = objc_getAssociatedObject(self, @selector(webView));
    if (!webView) {
        webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:[WKWebViewConfiguration new]];
        webView.scrollView.showsVerticalScrollIndicator = NO;
        webView.scrollView.showsHorizontalScrollIndicator = NO;
        if (@available(iOS 11.0, *)) {
            webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        objc_setAssociatedObject(self, @selector(webView), webView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return webView;
}

- (UIProgressView *)fwInnerProgressView
{
    UIProgressView *progressView = objc_getAssociatedObject(self, @selector(progressView));
    if (!progressView) {
        progressView = [[UIProgressView alloc] initWithFrame:CGRectZero];
        progressView.trackTintColor = [UIColor clearColor];
        [progressView fwSetProgress:0];
        objc_setAssociatedObject(self, @selector(progressView), progressView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return progressView;
}

- (id)fwInnerUrlRequest
{
    return objc_getAssociatedObject(self, @selector(urlRequest));
}

- (void)fwInnerSetUrlRequest:(id)urlRequest
{
    objc_setAssociatedObject(self, @selector(urlRequest), urlRequest, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    WKWebView *webView = [(id<FWWebViewController>)self webView];
    if (webView.superview != nil && urlRequest != nil) {
        if ([urlRequest isKindOfClass:[NSURLRequest class]]) {
            [webView loadRequest:urlRequest];
        } else if ([urlRequest isKindOfClass:[NSURL class]]) {
            [webView loadRequest:[NSURLRequest requestWithURL:urlRequest]];
        } else if ([urlRequest isKindOfClass:[NSString class]]) {
            [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlRequest]]];
        }
    }
}

- (void)fwInnerRenderWebView
{
    WKWebView *webView = [(id<FWWebViewController>)self webView];
    [webView fwPinEdgesToSuperview];
}

@end

#pragma mark - FWViewControllerManager+FWWebViewController

@implementation FWViewControllerManager (FWWebViewController)

+ (void)load
{
    FWViewControllerIntercepter *intercepter = [[FWViewControllerIntercepter alloc] init];
    intercepter.loadViewIntercepter = @selector(webViewControllerLoadView:);
    intercepter.forwardSelectors = @{@"webView" : @"fwInnerWebView",
                                     @"progressView" : @"fwInnerProgressView",
                                     @"urlRequest" : @"fwInnerUrlRequest",
                                     @"setUrlRequest:" : @"fwInnerSetUrlRequest:",
                                     @"renderWebView" : @"fwInnerRenderWebView"};
    [[FWViewControllerManager sharedInstance] registerProtocol:@protocol(FWWebViewController) withIntercepter:intercepter];
}

- (void)webViewControllerLoadView:(UIViewController<FWWebViewController> *)viewController
{
    WKWebView *webView = [viewController webView];
    webView.navigationDelegate = viewController;
    [viewController.view addSubview:webView];
    
    UIProgressView *progressView = [viewController progressView];
    [webView addSubview:progressView];
    [progressView fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeBottom];
    [progressView fwSetDimension:NSLayoutAttributeHeight toSize:2.f];
    
    [webView fwObserveProperty:@"estimatedProgress" block:^(WKWebView *webView, NSDictionary *change) {
        [progressView fwSetProgress:webView.estimatedProgress];
    }];
    
    [viewController renderWebView];
    [webView setNeedsLayout];
    [webView layoutIfNeeded];
    
    id urlRequest = [viewController urlRequest];
    if (urlRequest != nil) {
        if ([urlRequest isKindOfClass:[NSURLRequest class]]) {
            [webView loadRequest:urlRequest];
        } else if ([urlRequest isKindOfClass:[NSURL class]]) {
            [webView loadRequest:[NSURLRequest requestWithURL:urlRequest]];
        } else if ([urlRequest isKindOfClass:[NSString class]]) {
            [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlRequest]]];
        }
    }
}

@end
