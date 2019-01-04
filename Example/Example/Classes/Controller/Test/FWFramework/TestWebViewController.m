//
//  TestWebViewController.m
//  Example
//
//  Created by wuyong on 2019/1/4.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestWebViewController.h"

@interface TestWebViewController () <UIWebViewDelegate, FWWebViewProgressDelegate>

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) FWWebViewProgress *progressProxy;
@property (nonatomic, strong) FWWebViewProgressView *progressView;

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
    
    [self loadBaidu];
}

-(void)loadBaidu
{
    NSURLRequest *req = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://baidu.com/"]];
    [_webView loadRequest:req];
}

#pragma mark - NJKWebViewProgressDelegate

- (void)webViewProgress:(FWWebViewProgress *)webViewProgress updateProgress:(float)progress
{
    [_progressView setProgress:progress animated:YES];
    self.title = [_webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}

@end
