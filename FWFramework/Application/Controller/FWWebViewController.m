/*!
 @header     FWWebViewController.m
 @indexgroup FWFramework
 @brief      FWWebViewController
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/8/28
 */

#import "FWWebViewController.h"
#import "FWViewControllerStyle.h"
#import "FWMessage.h"
#import "FWAutoLayout.h"
#import "FWBlock.h"
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
        @"webItems" : @"fwInnerWebItems",
        @"webRequest" : @"fwInnerWebRequest",
        @"setWebRequest:" : @"fwInnerSetWebRequest:",
        @"renderWebLayout" : @"fwInnerRenderWebLayout",
        @"onWebClose": @"fwInnerOnWebClose",
    };
    [[FWViewControllerManager sharedInstance] registerProtocol:@protocol(FWWebViewController) withIntercepter:intercepter];
}

- (void)webViewControllerLoadView:(UIViewController<FWWebViewController> *)viewController
{
    FWWebView *webView = [viewController webView];
    webView.delegate = viewController;
    [viewController.view addSubview:webView];
    
    __weak __typeof(viewController) weakController = viewController;
    [webView fwObserveProperty:@"title" block:^(WKWebView *webView, NSDictionary *change) {
        weakController.navigationItem.title = webView.title;
    }];
    
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
    if (webItems.count < 1 || !viewController.navigationController) {
        viewController.webView.webRequest = viewController.webRequest;
        return;
    }
    
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
                        [weakController onWebClose];
                    }
                }];
                [leftItems addObject:leftItem];
            } else {
                UIBarButtonItem *leftItem = [UIBarButtonItem fwBarItemWithObject:webItem block:^(id sender) {
                    [weakController onWebClose];
                }];
                [leftItems addObject:leftItem];
            }
        }
    }
    
    BOOL showClose = YES;
    if (viewController.navigationController.viewControllers.firstObject == viewController &&
        viewController.navigationController.presentingViewController.presentedViewController != viewController.navigationController) {
        showClose = NO;
    }
    viewController.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:showClose ? leftItems.firstObject : nil, nil];
    // 如需自定义fwForcePopGesture，重写该属性getter即可
    viewController.fwForcePopGesture = YES;
    [viewController.webView fwObserveProperty:@"canGoBack" block:^(WKWebView *webView, NSDictionary *change) {
        weakController.fwForcePopGesture = !webView.canGoBack;
        if (webView.canGoBack) {
            weakController.navigationItem.leftBarButtonItems = [leftItems copy];
        } else {
            weakController.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:showClose ? leftItems.firstObject : nil, nil];
        }
    }];
    
    viewController.webView.webRequest = viewController.webRequest;
}

@end

#pragma mark - UIViewController+FWWebViewController

@interface UIViewController (FWWebViewController)

@end

@implementation UIViewController (FWWebViewController)

- (FWWebView *)fwInnerWebView
{
    FWWebView *webView = objc_getAssociatedObject(self, _cmd);
    if (!webView) {
        webView = [[FWWebView alloc] initWithFrame:CGRectZero configuration:[WKWebViewConfiguration new]];
        objc_setAssociatedObject(self, _cmd, webView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return webView;
}

- (NSArray *)fwInnerWebItems
{
    return nil;
}

- (void)fwInnerOnWebClose
{
    if (self.navigationController) {
        if ([self.navigationController popViewControllerAnimated:YES]) return;
    }
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    FWWebView *webView = [(id<FWWebViewController>)self webView];
    WKBackForwardListItem *firstItem = webView.backForwardList.backList.firstObject;
    if (firstItem != nil) {
        [webView goToBackForwardListItem:firstItem];
    }
}

- (id)fwInnerWebRequest
{
    return objc_getAssociatedObject(self, @selector(fwInnerWebRequest));
}

- (void)fwInnerSetWebRequest:(id)webRequest
{
    objc_setAssociatedObject(self, @selector(fwInnerWebRequest), webRequest, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (self.isViewLoaded) {
        FWWebView *webView = [(id<FWWebViewController>)self webView];
        webView.webRequest = webRequest;
    }
}

- (void)fwInnerRenderWebLayout
{
    FWWebView *webView = [(id<FWWebViewController>)self webView];
    [webView fwPinEdgesToSuperview];
}

@end
