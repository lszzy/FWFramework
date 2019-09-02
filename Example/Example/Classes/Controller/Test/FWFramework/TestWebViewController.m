//
//  TestWebViewController.m
//  Example
//
//  Created by wuyong on 2019/1/4.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestWebViewController.h"

@interface TestWebViewController () <UIWebViewDelegate, FWWebViewProgressDelegate, FWWebViewNavigationDelegate>

@property (nonatomic, assign) BOOL isWKWebView;

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) FWWebViewProgress *progressProxy;
@property (nonatomic, strong) FWWebViewProgressView *progressView;

@property (nonatomic, strong) WKWebView *webView2;
@property (nonatomic, strong) UIProgressView *progressView2;

@end

@implementation TestWebViewController

- (void)renderView
{
    if (!self.isWKWebView) {
        self.webView = [[UIWebView alloc] init];
        [self.view addSubview:self.webView];
        [self.webView fwPinEdgesToSuperview];
        
        self.progressProxy = [[FWWebViewProgress alloc] init];
        self.webView.delegate = self.progressProxy;
        self.progressProxy.webViewProxyDelegate = self;
        self.progressProxy.progressDelegate = self;
        
        _progressView = [[FWWebViewProgressView alloc] initWithFrame:CGRectMake(0, 0, FWScreenWidth, 2.f)];
        [self.webView addSubview:_progressView];
        
        NSURLRequest *req = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.wuyong.site"]];
        [_webView loadRequest:req];
    } else {
        self.webView2 = [[WKWebView alloc] initWithFrame:self.view.bounds];
        self.webView2.fwNavigationDelegate = self;
        [self.view addSubview:self.webView2];
        [self.webView2 fwPinEdgesToSuperview];
        
        _progressView2 = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, FWScreenWidth, 2.f)];
        _progressView2.trackTintColor = [UIColor clearColor];
        [_progressView2 fwSetProgress:0];
        [self.webView2 addSubview:_progressView2];
        
        NSURLRequest *req2 = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.wuyong.site"]];
        [_webView2 loadRequest:req2];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!self.isWKWebView) {
        self.title = @"UIWebView";
        
        FWWeakifySelf();
        [self fwSetRightBarItem:@"WKWebView" block:^(id sender) {
            FWStrongifySelf();
            
            TestWebViewController *viewController = [TestWebViewController new];
            viewController.isWKWebView = YES;
            [self fwOpenViewController:viewController animated:YES];
        }];
    } else {
        self.title = @"WKWebView";
    }
}

#pragma mark - FWWebViewProgressDelegate

- (void)webViewProgress:(FWWebViewProgress *)webViewProgress updateProgress:(float)progress
{
    [_progressView setProgress:progress animated:YES];
    self.title = [_webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}

#pragma mark - FWWebViewNavigationDelegate

- (void)webView:(WKWebView *)webView updateProgress:(CGFloat)progress
{
    [self.progressView2 fwSetProgress:progress];
    FWWeakifySelf();
    [_webView2 evaluateJavaScript:@"document.title" completionHandler:^(id title, NSError * _Nullable error) {
        FWStrongifySelf();
        self.title = [title fwAsNSString];
    }];
}

@end
