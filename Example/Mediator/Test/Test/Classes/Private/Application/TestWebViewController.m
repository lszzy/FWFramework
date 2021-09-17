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
    if (self.fwNavigationItem.leftBarButtonItem) {
        return nil;
    } else {
        return @[
            [UIBarButtonItem fwBarItemWithObject:FWIcon.backImage target:self action:@selector(onWebBack)],
            FWIcon.closeImage,
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
    [self renderToolbar];
    [self loadRequestUrl];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.toolbarHidden = YES;
}

- (void)renderWebView
{
    self.fwView.backgroundColor = [Theme tableColor];
    self.webView.scrollView.showsVerticalScrollIndicator = NO;
    self.webView.scrollView.showsHorizontalScrollIndicator = NO;
}

- (void)renderToolbar
{
    FWWeakifySelf();
    UIBarButtonItem *backItem = [UIBarButtonItem fwBarItemWithObject:FWIconImage(@"ion-ios-arrow-back", 24) block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        if ([self.webView canGoBack]) [self.webView goBack];
    }];
    backItem.enabled = NO;
    [self.webView fwObserveProperty:@"canGoBack" block:^(WKWebView *webView, NSDictionary * _Nonnull change) {
        FWStrongifySelf();
        backItem.enabled = webView.canGoBack;
        [self reloadToolbar];
    }];
    
    UIBarButtonItem *forwardItem = [UIBarButtonItem fwBarItemWithObject:FWIconImage(@"ion-ios-arrow-forward", 24) block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        if ([self.webView canGoForward]) [self.webView goForward];
    }];
    forwardItem.enabled = NO;
    [self.webView fwObserveProperty:@"canGoForward" block:^(WKWebView *webView, NSDictionary * _Nonnull change) {
        FWStrongifySelf();
        forwardItem.enabled = webView.canGoForward;
        [self reloadToolbar];
    }];
    
    [self.webView fwObserveProperty:@"isLoading" block:^(id  _Nonnull object, NSDictionary * _Nonnull change) {
        FWStrongifySelf();
        [self reloadToolbar];
    }];
    [self.webView fwObserveProperty:@"scrollView.contentOffset" block:^(WKWebView *webView, NSDictionary * _Nonnull change) {
        FWStrongifySelf();
        if (webView.scrollView.isDragging) [self reloadToolbar];
    }];
    
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spaceItem.width = 79;
    self.toolbarItems = @[flexibleItem, backItem, spaceItem, forwardItem, flexibleItem];
    
    self.navigationController.toolbar.fwBackgroundColor = Theme.barColor;
    self.navigationController.toolbar.fwForegroundColor = Theme.textColor;
}

- (void)reloadToolbar
{
    if (self.webView.canGoBack || [self.webView canGoForward]) {
        if (self.webView.scrollView.isDragging && self.webView.scrollView.fwCanScroll) {
            UISwipeGestureRecognizerDirection scrollDirection = self.webView.scrollView.fwScrollDirection;
            if (scrollDirection == UISwipeGestureRecognizerDirectionUp) {
                if (!self.navigationController.toolbarHidden) {
                    [self.navigationController setToolbarHidden:YES animated:YES];
                }
            } else if (scrollDirection == UISwipeGestureRecognizerDirectionDown) {
                if (self.navigationController.toolbarHidden) {
                    [self.navigationController setToolbarHidden:NO animated:YES];
                }
            }
        } else {
            self.navigationController.toolbarHidden = NO;
        }
    } else {
        self.navigationController.toolbarHidden = YES;
    }
}

- (void)shareRequestUrl
{
    [UIApplication fwOpenActivityItems:@[FWSafeURL(self.requestUrl)] excludedTypes:nil];
}

- (void)loadRequestUrl
{
    [self fwHideEmptyView];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.requestUrl]];
    urlRequest.timeoutInterval = 30;
    [urlRequest setValue:@"test" forHTTPHeaderField:@"Test-Token"];
    self.webRequest = urlRequest;
}

- (void)webViewFinishLoad
{
    if (self.fwIsDataLoaded) return;
    self.fwIsDataLoaded = YES;
    
    [self fwSetRightBarItem:FWIcon.actionImage target:self action:@selector(shareRequestUrl)];
}

- (void)webViewFailLoad:(NSError *)error
{
    if (self.fwIsDataLoaded) return;
    
    [self fwSetRightBarItem:FWIcon.refreshImage target:self action:@selector(loadRequestUrl)];
    
    FWWeakifySelf();
    [self fwShowEmptyViewWithText:error.localizedDescription detail:nil image:nil action:@"点击重试" block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        [self loadRequestUrl];
    }];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if ([self respondsToSelector:@selector(webViewShouldLoad:)] &&
        ![self webViewShouldLoad:navigationAction]) {
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
