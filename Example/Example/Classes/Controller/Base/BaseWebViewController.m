//
//  BaseWebViewController.m
//  Example
//
//  Created by wuyong on 2019/9/2.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "BaseWebViewController.h"

@interface BaseWebViewController ()

@property (nonatomic, strong) UIBarButtonItem *backItem;
@property (nonatomic, strong) UIBarButtonItem *closeItem;
@property (nonatomic, strong) UIBarButtonItem *shareItem;

@end

@implementation BaseWebViewController

#pragma mark - Accessor

- (UIBarButtonItem *)backItem
{
    if (!_backItem) {
        _backItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"public_back"] style:UIBarButtonItemStylePlain target:self action:@selector(onBack)];
    }
    return _backItem;
}

- (UIBarButtonItem *)closeItem
{
    if (!_closeItem) {
        _closeItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"public_close"] style:UIBarButtonItemStylePlain target:self action:@selector(onClose)];
    }
    return _closeItem;
}

- (UIBarButtonItem *)shareItem
{
    if (!_shareItem) {
        _shareItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(onShare)];
    }
    return _shareItem;
}

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.fwForcePopGesture = YES;
    
    self.navigationItem.leftBarButtonItems = @[self.backItem];
    self.navigationItem.rightBarButtonItem = self.shareItem;
    FWWeakifySelf();
    [self.webView fwObserveProperty:@"canGoBack" block:^(WKWebView *webView, NSDictionary *change) {
        FWStrongifySelf();
        BOOL canGoBack = [change[NSKeyValueChangeNewKey] boolValue];
        if (canGoBack) {
            self.navigationItem.leftBarButtonItems = @[self.backItem, self.closeItem];
        } else {
            self.navigationItem.leftBarButtonItems = @[self.backItem];
        }
    }];
    
    // 设置统一请求头
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.requestUrl]];
    [urlRequest setValue:@"test" forHTTPHeaderField:@"Test-Token"];
    self.webRequest = urlRequest;
}

#pragma mark - Action

- (void)onBack
{
    if ([self.webView canGoBack]) {
        [self.webView goBack];
    } else {
        [self onClose];
    }
}

- (void)onClose
{
    [self fwCloseViewControllerAnimated:YES];
}

- (void)onShare
{
    [self fwShowAlertWithTitle:@"分享功能" message:nil cancel:@"关闭" cancelBlock:nil];
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
