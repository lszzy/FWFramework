//
//  TestWebViewController.m
//  Example
//
//  Created by wuyong on 2019/9/2.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import "TestWebViewController.h"

@interface TestWebViewController ()

@property (nonatomic, assign) BOOL gobackDisabled;

@end

@implementation TestWebViewController

- (instancetype)initWithRequestUrl:(NSString *)requestUrl
{
    self = [super init];
    if (self) {
        _requestUrl = requestUrl;
    }
    return self;
}

- (NSArray *)webItems
{
    if (self.navigationItem.leftBarButtonItem) {
        return nil;
    } else {
        return @[
            [UIBarButtonItem fwBarItemWithObject:[CoreBundle imageNamed:@"back"] target:self action:@selector(onWebBack)],
            [CoreBundle imageNamed:@"close"],
        ];
    }
}

- (void)onWebBack
{
    if (self.webView.canGoBack && !self.gobackDisabled) {
        [self.webView goBack];
    } else {
        [self onWebClose];
    }
}

- (BOOL)fwForcePopGesture
{
    return !self.webView.canGoBack || self.gobackDisabled;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadRequestUrl];
}

- (void)renderWebView
{
    self.view.backgroundColor = [Theme tableColor];
    self.webView.scrollView.backgroundColor = [UIColor clearColor];
    self.webView.scrollView.showsVerticalScrollIndicator = NO;
    self.webView.scrollView.showsHorizontalScrollIndicator = NO;
    
    // 显示网页host来源
    UILabel *tipLabel = [UILabel new];
    tipLabel.font = [UIFont systemFontOfSize:12];
    tipLabel.textColor = [Theme detailColor];
    [self.view insertSubview:tipLabel belowSubview:self.webView];
    tipLabel.fwLayoutChain.centerX().topWithInset(10);
    [self.webView fwObserveProperty:@"URL" block:^(WKWebView *webView, NSDictionary * _Nonnull change) {
        if (webView.URL.host.length > 0) {
            tipLabel.text = [NSString stringWithFormat:@"此网页由 %@ 提供", webView.URL.host];
        }
    }];
}

- (void)shareRequestUrl
{
    NSURL *url = [NSURL URLWithString:self.requestUrl];
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:[NSArray arrayWithObjects:url, nil] applicationActivities:nil];
    [self presentViewController:activityController animated:YES completion:nil];
}

- (void)loadRequestUrl
{
    [self.view fwHideEmptyView];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.requestUrl]];
    urlRequest.timeoutInterval = 30;
    [urlRequest setValue:@"test" forHTTPHeaderField:@"Test-Token"];
    self.webRequest = urlRequest;
}

- (void)didFinishLoad
{
    if (self.fwIsDataLoaded) return;
    self.fwIsDataLoaded = YES;
    
    [self fwSetRightBarItem:@(UIBarButtonSystemItemAction) target:self action:@selector(shareRequestUrl)];
}

- (void)didFailLoad:(NSError *)error
{
    if (self.fwIsDataLoaded) return;
    
    [self fwSetRightBarItem:@(UIBarButtonSystemItemRefresh) target:self action:@selector(loadRequestUrl)];
    
    FWWeakifySelf();
    [self.view fwShowEmptyViewWithText:error.localizedDescription detail:nil image:nil action:@"点击重试" block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        [self loadRequestUrl];
    }];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if ([self respondsToSelector:@selector(shouldStartLoad:)] &&
        ![self shouldStartLoad:navigationAction]) {
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    if ([UIApplication fwIsSystemURL:navigationAction.request.URL]) {
        [UIApplication fwOpenURL:navigationAction.request.URL];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    if ([navigationAction.request.URL.scheme isEqualToString:@"app"]) {
        [FWRouter openURL:navigationAction.request.URL.absoluteString];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
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
