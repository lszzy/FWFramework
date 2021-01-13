//
//  TestWebViewController.m
//  Example
//
//  Created by wuyong on 2019/1/4.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestWebViewController.h"

@interface TestWebViewController () <FWWebViewNavigationDelegate>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIProgressView *progressView;

@end

@implementation TestWebViewController

- (void)renderView
{
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    self.webView.fwNavigationDelegate = self;
    [self.view addSubview:self.webView];
    [self.webView fwPinEdgesToSuperview];
    
    _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, FWScreenWidth, 2.f)];
    _progressView.trackTintColor = [UIColor clearColor];
    [_progressView fwSetProgress:0];
    [self.webView addSubview:_progressView];
    
    NSURLRequest *req = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.wuyong.site"]];
    [_webView loadRequest:req];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"WKWebView";
}

#pragma mark - FWWebViewNavigationDelegate

- (void)webView:(WKWebView *)webView updateProgress:(CGFloat)progress
{
    [self.progressView fwSetProgress:progress];
    FWWeakifySelf();
    [_webView evaluateJavaScript:@"document.title" completionHandler:^(id title, NSError * _Nullable error) {
        FWStrongifySelf();
        self.navigationItem.title = [title fwAsNSString];
    }];
}

@end
