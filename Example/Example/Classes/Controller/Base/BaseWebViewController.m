//
//  BaseWebViewController.m
//  Example
//
//  Created by wuyong on 2019/9/2.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "BaseWebViewController.h"

@interface BaseWebViewController ()

@end

@implementation BaseWebViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 分享按钮
    FWWeakifySelf();
    [self fwSetRightBarItem:@(UIBarButtonSystemItemAction) block:^(id sender) {
        FWStrongifySelf();
        [self fwShowAlertWithTitle:self.title message:self.requestUrl cancel:@"关闭" cancelBlock:nil];
    }];
    
    // 设置统一请求头
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.requestUrl]];
    [urlRequest setValue:@"test" forHTTPHeaderField:@"Test-Token"];
    self.webRequest = urlRequest;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if ([navigationAction.request.URL.scheme isEqualToString:@"app"]) {
        decisionHandler(WKNavigationActionPolicyCancel);
        [FWRouter openURL:navigationAction.request.URL.absoluteString];
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

@end
