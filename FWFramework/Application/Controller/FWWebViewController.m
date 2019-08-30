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
#import <objc/runtime.h>

#pragma mark - UIViewController+FWWebViewController

@interface UIViewController (FWWebViewController)

@end

@implementation UIViewController (FWWebViewController)

- (WKWebView *)fwInnerWebView
{
    WKWebView *webView = objc_getAssociatedObject(self, @selector(webView));
    if (!webView) {
        WKWebViewConfiguration *webConfiguration = [(id<FWWebViewController>)self renderWebConfiguration];
        if (webConfiguration) {
            webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:webConfiguration];
        } else {
            webView = [[WKWebView alloc] initWithFrame:CGRectZero];
        }
        webView.scrollView.showsVerticalScrollIndicator = NO;
        webView.scrollView.showsHorizontalScrollIndicator = NO;
        if (@available(iOS 11.0, *)) {
            webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        objc_setAssociatedObject(self, @selector(webView), webView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return webView;
}

- (WKWebViewConfiguration *)fwInnerRenderWebConfiguration
{
    WKWebViewConfiguration *webConfiguration = [[WKWebViewConfiguration alloc] init];
    return webConfiguration;
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
                                     @"renderWebConfiguration" : @"fwInnerRenderWebConfiguration",
                                     @"renderWebView" : @"fwInnerRenderWebView"};
    [[FWViewControllerManager sharedInstance] registerProtocol:@protocol(FWWebViewController) withIntercepter:intercepter];
}

- (void)webViewControllerLoadView:(UIViewController<FWWebViewController> *)viewController
{
    WKWebView *webView = [viewController webView];
    webView.navigationDelegate = viewController;
    [viewController.view addSubview:webView];
    
    [viewController renderWebView];
    [webView setNeedsLayout];
    [webView layoutIfNeeded];
}

@end
