/*!
 @header     FWWebViewController.m
 @indexgroup FWFramework
 @brief      FWWebViewController
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/8/28
 */

#import "FWWebViewController.h"
#import "UIView+FWFramework.h"
#import "UIViewController+FWFramework.h"
#import "UIWebView+FWFramework.h"
#import "FWMessage.h"
#import <objc/runtime.h>

#pragma mark - FWViewControllerManager+FWWebViewController

@implementation FWViewControllerManager (FWWebViewController)

+ (void)load
{
    FWViewControllerIntercepter *intercepter = [[FWViewControllerIntercepter alloc] init];
    intercepter.loadViewIntercepter = @selector(webViewControllerLoadView:);
    intercepter.viewDidLoadIntercepter = @selector(webViewControllerViewDidLoad:);
    intercepter.forwardSelectors = @{@"webView" : @"fwInnerWebView",
                                     @"progressView" : @"fwInnerProgressView",
                                     @"webBackItem" : @"fwInnerWebBackItem",
                                     @"webCloseItem" : @"fwInnerWebCloseItem",
                                     @"webRequest" : @"fwInnerWebRequest",
                                     @"setWebRequest:" : @"fwInnerSetWebRequest:",
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
    
    [webView fwObserveProperty:@"title" block:^(WKWebView *webView, NSDictionary *change) {
        viewController.title = webView.title;
    }];
    [webView fwObserveProperty:@"estimatedProgress" block:^(WKWebView *webView, NSDictionary *change) {
        [progressView fwSetProgress:webView.estimatedProgress];
    }];
    
    [viewController renderWebView];
    [webView setNeedsLayout];
    [webView layoutIfNeeded];
}

- (void)webViewControllerViewDidLoad:(UIViewController<FWWebViewController> *)viewController
{
    if (viewController.webBackItem) {
        viewController.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:viewController.webBackItem, nil];
        [viewController.webView fwObserveProperty:@"canGoBack" block:^(WKWebView *webView, NSDictionary *change) {
            if (webView.canGoBack) {
                viewController.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:viewController.webBackItem, viewController.webCloseItem, nil];
            } else {
                viewController.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:viewController.webBackItem, nil];
            }
        }];
    }
    
    [self webViewControllerLoadRequest:viewController];
}

- (void)webViewControllerLoadRequest:(UIViewController<FWWebViewController> *)viewController
{
    id webRequest = [viewController webRequest];
    if (!webRequest) return;
    
    WKWebView *webView = [viewController webView];
    if ([webRequest isKindOfClass:[NSURLRequest class]]) {
        [webView loadRequest:webRequest];
    } else {
        NSURL *requestUrl = [webRequest isKindOfClass:[NSURL class]] ? webRequest : nil;
        if (!requestUrl && [webRequest isKindOfClass:[NSString class]]) {
            requestUrl = [NSURL URLWithString:webRequest];
        }
        if (!requestUrl) return;
        
        if (requestUrl.isFileURL) {
            NSString *htmlString = [NSString stringWithContentsOfURL:requestUrl encoding:NSUTF8StringEncoding error:NULL];
            if (htmlString) {
                [webView loadHTMLString:htmlString baseURL:nil];
            }
        } else {
            [webView loadRequest:[NSURLRequest requestWithURL:requestUrl]];
        }
    }
}

@end

#pragma mark - UIViewController+FWWebViewController

@interface UIViewController (FWWebViewController)

@end

@implementation UIViewController (FWWebViewController)

- (WKWebView *)fwInnerWebView
{
    WKWebView *webView = objc_getAssociatedObject(self, @selector(webView));
    if (!webView) {
        webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:[WKWebViewConfiguration new]];
        webView.allowsBackForwardNavigationGestures = YES;
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

- (UIBarButtonItem *)fwInnerWebBackItem
{
    UIBarButtonItem *backItem = objc_getAssociatedObject(self, @selector(webBackItem));
    if (!backItem) {
        __weak __typeof__(self) self_weak_ = self;
        backItem = [UIBarButtonItem fwBarItemWithObject:@"返回" block:^(id sender) {
            __typeof__(self) self = self_weak_;
            WKWebView *webView = [(id<FWWebViewController>)self webView];
            if ([webView canGoBack]) {
                [webView goBack];
            } else {
                [self fwCloseViewControllerAnimated:YES];
            }
        }];
        objc_setAssociatedObject(self, @selector(webBackItem), backItem, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return backItem;
}

- (UIBarButtonItem *)fwInnerWebCloseItem
{
    UIBarButtonItem *closeItem = objc_getAssociatedObject(self, @selector(webCloseItem));
    if (!closeItem) {
        __weak __typeof__(self) self_weak_ = self;
        closeItem = [UIBarButtonItem fwBarItemWithObject:@"关闭" block:^(id sender) {
            __typeof__(self) self = self_weak_;
            [self fwCloseViewControllerAnimated:YES];
        }];
        objc_setAssociatedObject(self, @selector(webCloseItem), closeItem, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return closeItem;
}

- (id)fwInnerWebRequest
{
    return objc_getAssociatedObject(self, @selector(webRequest));
}

- (void)fwInnerSetWebRequest:(id)webRequest
{
    objc_setAssociatedObject(self, @selector(webRequest), webRequest, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (self.isViewLoaded) {
        [[FWViewControllerManager sharedInstance] webViewControllerLoadRequest:(UIViewController<FWWebViewController> *)self];
    }
}

- (void)fwInnerRenderWebView
{
    WKWebView *webView = [(id<FWWebViewController>)self webView];
    [webView fwPinEdgesToSuperview];
}

@end
