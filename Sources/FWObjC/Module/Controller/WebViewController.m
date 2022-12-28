//
//  WebViewController.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "WebViewController.h"
#import "NavigationController.h"
#import <objc/runtime.h>

#if FWMacroSPM

@interface UIView ()

- (NSArray<NSLayoutConstraint *> *)fw_pinEdgesToSuperview:(UIEdgeInsets)insets;

@end

@interface NSObject ()

- (NSString *)fw_observeProperty:(NSString *)property block:(void (^)(id object, NSDictionary<NSKeyValueChangeKey, id> *change))block;

@end

@interface UIViewController ()

@property (nonatomic, copy, nullable) BOOL (^fw_allowsPopGesture)(void);

@end

@interface UIBarButtonItem ()

+ (instancetype)fw_itemWithObject:(nullable id)object block:(nullable void (^)(id sender))block;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#pragma mark - __FWViewControllerManager+__FWWebViewController

@implementation __FWViewControllerManager (__FWWebViewController)

+ (void)load
{
    __FWViewControllerIntercepter *intercepter = [[__FWViewControllerIntercepter alloc] init];
    intercepter.viewDidLoadIntercepter = @selector(webViewControllerViewDidLoad:);
    intercepter.forwardSelectors = @{
        @"webView" : @"fw_innerWebView",
        @"webItems" : @"fw_innerWebItems",
        @"setWebItems:" : @"fw_innerSetWebItems:",
        @"webRequest" : @"fw_innerWebRequest",
        @"setWebRequest:" : @"fw_innerSetWebRequest:",
        @"setupWebLayout" : @"fw_innerSetupWebLayout",
    };
    [[__FWViewControllerManager sharedInstance] registerProtocol:@protocol(__FWWebViewController) withIntercepter:intercepter];
}

- (void)webViewControllerViewDidLoad:(UIViewController<__FWWebViewController> *)viewController
{
    __FWWebView *webView = [viewController webView];
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
        __FWWebViewJsBridge *bridge = [__FWWebViewJsBridge bridgeForWebView:webView];
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

#pragma mark - UIViewController+__FWWebViewController

@interface UIViewController (__FWWebViewController)

@end

@implementation UIViewController (__FWWebViewController)

- (__FWWebView *)fw_innerWebView
{
    __FWWebView *webView = objc_getAssociatedObject(self, _cmd);
    if (!webView) {
        if ([self respondsToSelector:@selector(setupWebConfiguration)]) {
            webView = [[__FWWebView alloc] initWithFrame:CGRectZero configuration:[(id<__FWWebViewController>)self setupWebConfiguration]];
        } else {
            webView = [[__FWWebView alloc] initWithFrame:CGRectZero];
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
        __FWWebView *webView = [(id<__FWWebViewController>)self webView];
        webView.webRequest = webRequest;
    }
}

- (void)fw_innerSetupWebLayout
{
    __FWWebView *webView = [(id<__FWWebViewController>)self webView];
    [webView fw_pinEdgesToSuperview:UIEdgeInsetsZero];
}

@end
