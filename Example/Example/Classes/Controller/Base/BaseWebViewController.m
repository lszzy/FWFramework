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

- (WKWebView *)webView
{
    WKWebView *webView = objc_getAssociatedObject(self, _cmd);
    if (!webView) {
        webView = [[FWViewControllerManager sharedInstance] performIntercepter:_cmd withObject:self];
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

- (BOOL)shouldStartLoad:(WKNavigationAction *)navigationAction
{
    if ([navigationAction.request.URL.scheme isEqualToString:@"app"]) {
        [FWRouter openURL:navigationAction.request.URL.absoluteString];
        return NO;
    }
    return YES;
}

@end
