//
//  TestWebViewController.m
//  Example
//
//  Created by wuyong on 2019/1/4.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestWebViewController.h"

@interface TestWebViewController () <UIWebViewDelegate, FWWebViewProgressDelegate, FWWebViewNavigationDelegate>

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) FWWebViewProgress *progressProxy;
@property (nonatomic, strong) FWWebViewProgressView *progressView;

@property (nonatomic, strong) WKWebView *webView2;
@property (nonatomic, strong) UIProgressView *progressView2;

@end

@implementation TestWebViewController

- (void)renderView
{
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, FWScreenWidth, FWScreenHeight / 2.0)];
    [self.view addSubview:self.webView];
    
    self.progressProxy = [[FWWebViewProgress alloc] init];
    self.webView.delegate = self.progressProxy;
    self.progressProxy.webViewProxyDelegate = self;
    self.progressProxy.progressDelegate = self;
    
    _progressView = [[FWWebViewProgressView alloc] initWithFrame:CGRectMake(0, 0, FWScreenWidth, 2.f)];
    [self.webView addSubview:_progressView];
    
    self.webView2 = [[WKWebView alloc] initWithFrame:CGRectMake(0, FWScreenHeight / 2.0, FWScreenWidth, FWScreenHeight / 2.0)];
    self.webView2.fwNavigationDelegate = self;
    [self.view addSubview:self.webView2];
    
    _progressView2 = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, FWScreenWidth, 2.f)];
    _progressView2.trackTintColor = [UIColor clearColor];
    _progressView2.alpha = 0.0f;
    [self.webView2 addSubview:_progressView2];
    
    [self loadBaidu];
}

-(void)loadBaidu
{
    NSURLRequest *req = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://baidu.com/"]];
    [_webView loadRequest:req];
    
    NSURLRequest *req2 = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://baidu.com/"]];
    [_webView2 loadRequest:req2];
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
    if (self.progressView2.alpha == 0 && progress > 0) {
        self.progressView2.progress = 0;
        [UIView animateWithDuration:0.2 animations:^{
            self.progressView2.alpha = 1.0;
        }];
    } else if (self.progressView2.alpha == 1.0 && progress == 1.0) {
        [UIView animateWithDuration:0.2 animations:^{
            self.progressView2.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.progressView2.progress = 0;
        }];
    }
    [self.progressView2 setProgress:progress animated:YES];
}

@end
