//
//  WebViewController.m
//  Example
//
//  Created by wuyong on 2019/9/2.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "WebViewController.h"

@interface WebViewController ()

@end

@implementation WebViewController

- (WKWebView *)webView
{
    WKWebView *webView = objc_getAssociatedObject(self, _cmd);
    if (!webView) {
        webView = [[FWViewControllerManager sharedInstance] performIntercepter:_cmd withObject:self];
        FWWeakifySelf();
        [webView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            FWStrongifySelf();
            self.webView.customUserAgent = [NSString stringWithFormat:@"%@ %@", [WKWebView fwRequestUserAgent], result ?: [WKWebView fwBrowserUserAgent]];
        }];
        objc_setAssociatedObject(self, _cmd, webView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return webView;
}

- (NSArray *)webItems
{
    return @[[UIImage imageNamed:@"public_back"], [UIImage imageNamed:@"public_close"]];
}

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (!self.requestUrl) return;
    
    // 侧滑返回和webView手势兼容
    self.fwForcePopGesture = YES;
    FWWeakifySelf();
    [self.webView fwObserveProperty:@"canGoBack" block:^(WKWebView *webView, NSDictionary *change) {
        FWStrongifySelf();
        self.fwForcePopGesture = !webView.canGoBack;
    }];
    
    // 分享按钮
    [self fwSetRightBarItem:@(UIBarButtonSystemItemAction) block:^(id sender) {
        FWStrongifySelf();
        [self fwShowAlertWithTitle:self.title message:self.requestUrl cancel:@"关闭" cancelBlock:nil];
    }];
    
    // 设置统一请求头
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.requestUrl]];
    [urlRequest setValue:@"test" forHTTPHeaderField:@"Test-Token"];
    self.webRequest = urlRequest;
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    // 调用钩子
    if ([self respondsToSelector:@selector(shouldStartLoad:)] &&
        ![self shouldStartLoad:navigationAction]) {
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    // 系统Scheme
    if ([UIApplication fwIsSystemURL:navigationAction.request.URL]) {
        [UIApplication fwOpenURL:navigationAction.request.URL];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    // AppScheme
    if ([navigationAction.request.URL.scheme isEqualToString:@"app"]) {
        [FWRouter openURL:navigationAction.request.URL.absoluteString];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    // 通用链接
    if ([navigationAction.request.URL.scheme isEqualToString:@"https"]) {
        [UIApplication fwOpenUniversalLinks:navigationAction.request.URL completionHandler:^(BOOL success) {
            if (success) {
                decisionHandler(WKNavigationActionPolicyCancel);
            } else {
                decisionHandler(WKNavigationActionPolicyAllow);
            }
        }];
        return;
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
