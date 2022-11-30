//
//  FWWebViewController.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWWebViewController.h"
#import "FWNavigationController.h"
#import "FWToolkit.h"
#import <objc/runtime.h>

#if FWMacroSPM



#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - FWViewControllerManager+FWWebViewController

@implementation FWViewControllerManager (FWWebViewController)

+ (void)load
{
    FWViewControllerIntercepter *intercepter = [[FWViewControllerIntercepter alloc] init];
    intercepter.viewDidLoadIntercepter = @selector(webViewControllerViewDidLoad:);
    intercepter.forwardSelectors = @{
        @"webView" : @"fw_innerWebView",
        @"webItems" : @"fw_innerWebItems",
        @"setWebItems:" : @"fw_innerSetWebItems:",
        @"webRequest" : @"fw_innerWebRequest",
        @"setWebRequest:" : @"fw_innerSetWebRequest:",
        @"setupWebLayout" : @"fw_innerSetupWebLayout",
    };
    [[FWViewControllerManager sharedInstance] registerProtocol:@protocol(FWWebViewController) withIntercepter:intercepter];
}

- (void)webViewControllerViewDidLoad:(UIViewController<FWWebViewController> *)viewController
{
    FWWebView *webView = [viewController webView];
    webView.delegate = viewController;
    [viewController.view addSubview:webView];
    
    __weak __typeof(viewController) weakController = viewController;
    [webView fw_observeProperty:@"title" block:^(WKWebView *webView, NSDictionary *change) {
        weakController.navigationItem.title = webView.title;
    }];
    viewController.fw_allowsPopGesture = ^BOOL{
        return !weakController.webView.canGoBack;
    };
    
    if (self.hookWebViewController) {
        self.hookWebViewController(viewController);
    }
    
    if ([viewController respondsToSelector:@selector(setupWebView)]) {
        [viewController setupWebView];
    }
    
    [viewController setupWebLayout];
    [webView setNeedsLayout];
    [webView layoutIfNeeded];
    
    if ([viewController respondsToSelector:@selector(setupWebBridge:)]) {
        id<WKNavigationDelegate> delegate = webView.navigationDelegate;
        FWWebViewJsBridge *bridge = [FWWebViewJsBridge bridgeForWebView:webView];
        [bridge setWebViewDelegate:delegate];
        webView.fw_jsBridge = bridge;
        
        [viewController setupWebBridge:bridge];
    }
    
    NSArray *webItems = viewController.webItems;
    if (webItems.count < 1 || !viewController.navigationController) {
        viewController.webView.webRequest = viewController.webRequest;
        return;
    }
    
    NSMutableArray<UIBarButtonItem *> *leftItems = [NSMutableArray array];
    for (int i = 0; i < webItems.count; i++) {
        id webItem = webItems[i];
        if ([webItem isKindOfClass:[UIBarButtonItem class]]) {
            [leftItems addObject:webItem];
        } else {
            if (i == 0) {
                UIBarButtonItem *leftItem = [UIBarButtonItem fw_itemWithObject:webItem block:^(id sender) {
                    if (weakController.webView.canGoBack) {
                        [weakController.webView goBack];
                    } else {
                        if (weakController.navigationController) {
                            if ([weakController.navigationController popViewControllerAnimated:YES]) return;
                        }
                        if (weakController.presentingViewController) {
                            [weakController dismissViewControllerAnimated:YES completion:nil];
                            return;
                        }
                        
                        WKBackForwardListItem *firstItem = weakController.webView.backForwardList.backList.firstObject;
                        if (firstItem != nil) {
                            [weakController.webView goToBackForwardListItem:firstItem];
                        }
                    }
                }];
                [leftItems addObject:leftItem];
            } else {
                UIBarButtonItem *leftItem = [UIBarButtonItem fw_itemWithObject:webItem block:^(id sender) {
                    if (weakController.navigationController) {
                        if ([weakController.navigationController popViewControllerAnimated:YES]) return;
                    }
                    if (weakController.presentingViewController) {
                        [weakController dismissViewControllerAnimated:YES completion:nil];
                        return;
                    }
                    
                    WKBackForwardListItem *firstItem = weakController.webView.backForwardList.backList.firstObject;
                    if (firstItem != nil) {
                        [weakController.webView goToBackForwardListItem:firstItem];
                    }
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
    [viewController.webView fw_observeProperty:@"canGoBack" block:^(WKWebView *webView, NSDictionary *change) {
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

- (FWWebView *)fw_innerWebView
{
    FWWebView *webView = objc_getAssociatedObject(self, _cmd);
    if (!webView) {
        if ([self respondsToSelector:@selector(setupWebConfiguration)]) {
            webView = [[FWWebView alloc] initWithFrame:CGRectZero configuration:[(id<FWWebViewController>)self setupWebConfiguration]];
        } else {
            webView = [[FWWebView alloc] initWithFrame:CGRectZero];
        }
        objc_setAssociatedObject(self, _cmd, webView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return webView;
}

- (NSArray *)fw_innerWebItems
{
    return objc_getAssociatedObject(self, @selector(fw_innerWebItems));
}

- (void)fw_innerSetWebItems:(NSArray *)webItems
{
    objc_setAssociatedObject(self, @selector(fw_innerWebItems), webItems, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (id)fw_innerWebRequest
{
    return objc_getAssociatedObject(self, @selector(fw_innerWebRequest));
}

- (void)fw_innerSetWebRequest:(id)webRequest
{
    objc_setAssociatedObject(self, @selector(fw_innerWebRequest), webRequest, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (self.isViewLoaded) {
        FWWebView *webView = [(id<FWWebViewController>)self webView];
        webView.webRequest = webRequest;
    }
}

- (void)fw_innerSetupWebLayout
{
    FWWebView *webView = [(id<FWWebViewController>)self webView];
    [webView fw_pinEdgesToSuperview:UIEdgeInsetsZero];
}

@end
