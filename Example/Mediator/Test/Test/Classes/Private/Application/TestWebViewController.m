//
//  TestWebViewController.m
//  Example
//
//  Created by wuyong on 2019/9/2.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestWebViewController.h"

@interface TestWebViewController ()

@end

@implementation TestWebViewController

- (NSArray *)webItems
{
    return [NSArray arrayWithObjects:[CoreBundle imageNamed:@"back"], [CoreBundle imageNamed:@"close"], nil];
}

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
    
    // 加载网页
    [self loadRequestUrl];
}

- (void)loadRequestUrl
{
    // 设置统一请求头
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.requestUrl]];
    urlRequest.timeoutInterval = 30;
    [urlRequest setValue:@"test" forHTTPHeaderField:@"Test-Token"];
    self.webRequest = urlRequest;
}

- (void)didFailLoad:(NSError *)error
{
    FWWeakifySelf();
    [self.view fwShowEmptyViewWithText:error.localizedDescription detail:nil image:nil action:@"点击重试" block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        [self.view fwHideEmptyView];
        [self loadRequestUrl];
    }];
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
