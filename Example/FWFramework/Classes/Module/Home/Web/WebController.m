//
//  WebController.m
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/24.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "WebController.h"
#import "AppSwift.h"

@interface WebController ()

@property (nonatomic, assign) BOOL toolbarHidden;

@end

@implementation WebController

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
            FWIcon.backImage,
            FWIcon.closeImage,
        ];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.toolbarHidden = YES;
    [self setupToolbar];
    [self loadRequestUrl];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.toolbarHidden = self.toolbarHidden;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.toolbarHidden = self.navigationController.toolbarHidden;
    self.navigationController.toolbarHidden = YES;
}

- (void)setupWebView
{
    self.view.backgroundColor = [AppTheme tableColor];
    self.webView.allowsUniversalLinks = YES;
}

- (void)setupWebLayout
{
    CGFloat bottomHeight = self.hidesBottomBarWhenPushed ? 0 : self.fw_tabBarHeight;
    bottomHeight += self.fw_toolBarHidden ? 0 : self.fw_toolBarHeight;
    self.webView.fw_layoutChain.horizontal().topToSafeArea().bottomWithInset(bottomHeight);
}

- (void)setupToolbar
{
    FWWeakifySelf();
    UIBarButtonItem *backItem = [UIBarButtonItem fw_itemWithObject:FWIcon.backImage block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        if ([self.webView canGoBack]) [self.webView goBack];
    }];
    backItem.enabled = NO;
    [self.webView fw_observeProperty:@"canGoBack" block:^(WKWebView *webView, NSDictionary * _Nonnull change) {
        FWStrongifySelf();
        backItem.enabled = webView.canGoBack;
        [self reloadToolbar:NO];
    }];
    
    UIBarButtonItem *forwardItem = [UIBarButtonItem fw_itemWithObject:[FWIcon.backImage fw_imageWithRotateDegree:180] block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        if ([self.webView canGoForward]) [self.webView goForward];
    }];
    forwardItem.enabled = NO;
    [self.webView fw_observeProperty:@"canGoForward" block:^(WKWebView *webView, NSDictionary * _Nonnull change) {
        FWStrongifySelf();
        forwardItem.enabled = webView.canGoForward;
        [self reloadToolbar:NO];
    }];
    
    [self.webView fw_observeProperty:@"isLoading" block:^(id  _Nonnull object, NSDictionary * _Nonnull change) {
        FWStrongifySelf();
        [self reloadToolbar:NO];
    }];
    
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spaceItem.width = 79;
    self.toolbarItems = @[flexibleItem, backItem, spaceItem, forwardItem, flexibleItem];
    
    self.navigationController.toolbar.fw_shadowImage = [UIImage fw_imageWithColor:AppTheme.borderColor size:CGSizeMake(self.view.bounds.size.width, 0.5)];
    self.navigationController.toolbar.fw_backgroundColor = AppTheme.barColor;
    self.navigationController.toolbar.fw_foregroundColor = AppTheme.textColor;
}

- (void)reloadToolbar:(BOOL)animated
{
    BOOL hidden = !(self.webView.canGoBack || self.webView.canGoForward);
    if (self.fw_toolBarHidden == hidden) return;
    
    if (animated) {
        [CATransaction begin];
        FWWeakifySelf();
        [CATransaction setCompletionBlock:^{
            FWStrongifySelf();
            if (self.webView.superview) [self setupWebLayout];
        }];
        [self.navigationController setToolbarHidden:hidden animated:animated];
        [CATransaction commit];
    } else {
        [self.navigationController setToolbarHidden:hidden animated:animated];
        if (self.webView.superview) [self setupWebLayout];
    }
}

- (void)shareRequestUrl
{
    [UIApplication fw_openActivityItems:@[FWSafeURL(self.requestUrl)] excludedTypes:nil];
}

- (void)loadRequestUrl
{
    [self fw_hideEmptyView];
    if (!self.fw_isLoaded) {
        [self fw_showLoading];
    }
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.requestUrl]];
    urlRequest.timeoutInterval = 30;
    [urlRequest setValue:@"test" forHTTPHeaderField:@"Test-Token"];
    self.webRequest = urlRequest;
}

- (void)webViewFinishLoad
{
    if (self.fw_isLoaded) return;
    [self fw_hideLoading];
    self.fw_isLoaded = YES;
    
    [self fw_setRightBarItem:@(UIBarButtonSystemItemAction) target:self action:@selector(shareRequestUrl)];
}

- (void)webViewFailLoad:(NSError *)error
{
    if (self.fw_isLoaded) return;
    [self fw_hideLoading];
    
    [self fw_setRightBarItem:@(UIBarButtonSystemItemRefresh) target:self action:@selector(loadRequestUrl)];
    
    FWWeakifySelf();
    [self fw_showEmptyViewWithText:error.localizedDescription detail:nil image:nil action:@"点击重试" block:^(id  _Nonnull sender) {
        FWStrongifySelf();
        [self loadRequestUrl];
    }];
}

- (BOOL)webViewShouldLoad:(WKNavigationAction *)navigationAction
{
    if ([navigationAction.request.URL.scheme isEqualToString:@"app"]) {
        [FWRouter openURL:navigationAction.request.URL.absoluteString];
        return NO;
    }
    
    return YES;
}

@end
