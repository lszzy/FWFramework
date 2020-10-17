/*!
 @header     FWWebViewController.m
 @indexgroup FWFramework
 @brief      FWWebViewController
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/8/28
 */

#import "FWWebViewController.h"
#import "FWEncode.h"
#import "FWMessage.h"
#import "FWAdaptive.h"
#import "FWAutoLayout.h"
#import "WKWebView+FWJsBridge.h"
#import "UIView+FWFramework.h"
#import "UIViewController+FWFramework.h"
#import "UIViewController+FWAlert.h"
#import <objc/runtime.h>

#pragma mark - FWViewControllerManager+FWWebViewController

@implementation FWViewControllerManager (FWWebViewController)

+ (void)load
{
    FWViewControllerIntercepter *intercepter = [[FWViewControllerIntercepter alloc] init];
    intercepter.loadViewIntercepter = @selector(webViewControllerLoadView:);
    intercepter.viewDidLoadIntercepter = @selector(webViewControllerViewDidLoad:);
    intercepter.forwardSelectors = @{
        @"webView" : @"fwInnerWebView",
        @"progressView" : @"fwInnerProgressView",
        @"webItems" : @"fwInnerWebItems",
        @"webRequest" : @"fwInnerWebRequest",
        @"setWebRequest:" : @"fwInnerSetWebRequest:",
        @"renderWebLayout" : @"fwInnerRenderWebLayout",
        @"webView:didFinishNavigation:" : @"fwInnerWebView:didFinishNavigation:",
        @"webView:decidePolicyForNavigationAction:decisionHandler:" : @"fwInnerWebView:decidePolicyForNavigationAction:decisionHandler:",
        @"webView:runJavaScriptAlertPanelWithMessage:initiatedByFrame:completionHandler:" : @"fwInnerWebView:runJavaScriptAlertPanelWithMessage:initiatedByFrame:completionHandler:",
        @"webView:runJavaScriptConfirmPanelWithMessage:initiatedByFrame:completionHandler:" : @"fwInnerWebView:runJavaScriptConfirmPanelWithMessage:initiatedByFrame:completionHandler:",
        @"webView:runJavaScriptTextInputPanelWithPrompt:defaultText:initiatedByFrame:completionHandler:" : @"fwInnerWebView:runJavaScriptTextInputPanelWithPrompt:defaultText:initiatedByFrame:completionHandler:",
        @"webView:createWebViewWithConfiguration:forNavigationAction:windowFeatures:" : @"fwInnerWebView:createWebViewWithConfiguration:forNavigationAction:windowFeatures:",
    };
    [[FWViewControllerManager sharedInstance] registerProtocol:@protocol(FWWebViewController) withIntercepter:intercepter];
}

- (void)webViewControllerLoadView:(UIViewController<FWWebViewController> *)viewController
{
    WKWebView *webView = [viewController webView];
    webView.navigationDelegate = viewController;
    webView.UIDelegate = viewController;
    [viewController.view addSubview:webView];
    
    UIProgressView *progressView = [viewController progressView];
    [webView addSubview:progressView];
    [progressView fwPinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeBottom];
    [progressView fwSetDimension:NSLayoutAttributeHeight toSize:2.f];
    
    __weak __typeof(viewController) weakController = viewController;
    [webView fwObserveProperty:@"title" block:^(WKWebView *webView, NSDictionary *change) {
        weakController.title = webView.title;
    }];
    __weak __typeof(progressView) weakProgressView = progressView;
    [webView fwObserveProperty:@"estimatedProgress" block:^(WKWebView *webView, NSDictionary *change) {
        [weakProgressView fwSetProgress:webView.estimatedProgress];
    }];
    if (@available(iOS 9.0, *)) {
        webView.customUserAgent = [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)", [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleExecutableKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey], [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], [[UIScreen mainScreen] scale]];
    }
    
    if ([viewController respondsToSelector:@selector(renderWebView)]) {
        [viewController renderWebView];
    }
    
    [viewController renderWebLayout];
    [webView setNeedsLayout];
    [webView layoutIfNeeded];
    
    if ([viewController respondsToSelector:@selector(renderWebBridge:)]) {
        id<WKNavigationDelegate> delegate = webView.navigationDelegate;
        FWWebViewJsBridge *bridge = [FWWebViewJsBridge bridgeForWebView:webView];
        [bridge setWebViewDelegate:delegate];
        webView.fwJsBridge = bridge;
        
        [viewController renderWebBridge:bridge];
    }
}

- (void)webViewControllerViewDidLoad:(UIViewController<FWWebViewController> *)viewController
{
    NSArray *webItems = viewController.webItems;
    if (webItems.count > 0) {
        __weak __typeof(viewController) weakController = viewController;
        NSMutableArray<UIBarButtonItem *> *leftItems = [NSMutableArray array];
        for (int i = 0; i < webItems.count; i++) {
            id webItem = webItems[i];
            if ([webItem isKindOfClass:[UIBarButtonItem class]]) {
                [leftItems addObject:webItem];
            } else {
                if (i == 0) {
                    UIBarButtonItem *leftItem = [UIBarButtonItem fwBarItemWithObject:webItem block:^(id sender) {
                        if (weakController.webView.canGoBack) {
                            [weakController.webView goBack];
                        } else {
                            [weakController fwCloseViewControllerAnimated:YES];
                        }
                    }];
                    [leftItems addObject:leftItem];
                } else {
                    UIBarButtonItem *leftItem = [UIBarButtonItem fwBarItemWithObject:webItem block:^(id sender) {
                        [weakController fwCloseViewControllerAnimated:YES];
                    }];
                    [leftItems addObject:leftItem];
                }
            }
        }
        
        viewController.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:leftItems.firstObject, nil];
        [viewController.webView fwObserveProperty:@"canGoBack" block:^(WKWebView *webView, NSDictionary *change) {
            if (webView.canGoBack) {
                weakController.navigationItem.leftBarButtonItems = [leftItems copy];
            } else {
                weakController.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:leftItems.firstObject, nil];
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
            requestUrl = [NSURL fwURLWithString:webRequest];
        }
        if (!requestUrl) return;
        
        if (requestUrl.isFileURL) {
            NSString *htmlString = [NSString stringWithContentsOfURL:requestUrl encoding:NSUTF8StringEncoding error:NULL];
            if (htmlString) {
                [webView loadHTMLString:htmlString baseURL:requestUrl];
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
    WKWebView *webView = objc_getAssociatedObject(self, _cmd);
    if (!webView) {
        webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:[WKWebViewConfiguration new]];
        webView.allowsBackForwardNavigationGestures = YES;
        if (@available(iOS 11.0, *)) {
            webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        objc_setAssociatedObject(self, _cmd, webView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return webView;
}

- (UIProgressView *)fwInnerProgressView
{
    UIProgressView *progressView = objc_getAssociatedObject(self, _cmd);
    if (!progressView) {
        progressView = [[UIProgressView alloc] initWithFrame:CGRectZero];
        progressView.trackTintColor = [UIColor clearColor];
        [progressView fwSetProgress:0];
        objc_setAssociatedObject(self, _cmd, progressView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return progressView;
}

- (NSArray *)fwInnerWebItems
{
    return nil;
}

- (id)fwInnerWebRequest
{
    return objc_getAssociatedObject(self, @selector(fwInnerWebRequest));
}

- (void)fwInnerSetWebRequest:(id)webRequest
{
    objc_setAssociatedObject(self, @selector(fwInnerWebRequest), webRequest, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (self.isViewLoaded) {
        [[FWViewControllerManager sharedInstance] webViewControllerLoadRequest:(UIViewController<FWWebViewController> *)self];
    }
}

- (void)fwInnerRenderWebLayout
{
    WKWebView *webView = [(id<FWWebViewController>)self webView];
    [webView fwPinEdgesToSuperview];
}

#pragma mark - WKNavigationDelegate

- (void)fwInnerWebView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if ([self respondsToSelector:@selector(shouldStartLoad:)] &&
        ![(id<FWWebViewController>)self shouldStartLoad:navigationAction]) {
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    if ([UIApplication fwIsSystemURL:navigationAction.request.URL]) {
        [UIApplication fwOpenURL:navigationAction.request.URL];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)fwInnerWebView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    if ([self respondsToSelector:@selector(didFinishLoad:)]) {
        [(id<FWWebViewController>)self didFinishLoad:navigation];
    }
}

#pragma mark - WKUIDelegate

- (void)fwInnerWebView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    [self fwShowAlertWithTitle:nil message:message cancel:NSLocalizedString(@"关闭", nil) cancelBlock:^{
        completionHandler();
    }];
}

- (void)fwInnerWebView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler
{
    [self fwShowConfirmWithTitle:nil message:message cancel:NSLocalizedString(@"取消", nil) confirm:NSLocalizedString(@"确定", nil) confirmBlock:^{
        completionHandler(YES);
    } cancelBlock:^{
        completionHandler(NO);
    } priority:FWAlertPriorityNormal];
}

- (void)fwInnerWebView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString *))completionHandler
{
    [self fwShowPromptWithTitle:nil message:prompt cancel:NSLocalizedString(@"取消", nil) confirm:NSLocalizedString(@"确定", nil) promptBlock:^(UITextField *textField) {
        textField.text = defaultText;
    } confirmBlock:^(NSString *text) {
        completionHandler(text);
    } cancelBlock:^{
        completionHandler(nil);
    } priority:FWAlertPriorityNormal];
}

- (WKWebView *)fwInnerWebView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures
{
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}

@end
