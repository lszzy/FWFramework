/*!
 @header     TestJavascriptBridgeViewController.m
 @indexgroup Example
 @brief      TestJavascriptBridgeViewController
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/3/17
 */

#import "TestJavascriptBridgeViewController.h"

@implementation TestJavascriptBridgeViewController

- (void)renderWebBridge:(FWWebViewJsBridge *)bridge {
    [FWWebViewJsBridge enableLogging];
    [bridge registerHandler:@"testObjcCallback" handler:^(id data, FWJsBridgeResponseCallback responseCallback) {
        NSLog(@"testObjcCallback called: %@", data);
        responseCallback(@"Response from testObjcCallback");
    }];
    [bridge callHandler:@"testJavascriptHandler" data:@{ @"foo":@"before ready" }];
}

- (void)callHandler:(id)sender {
    id data = @{ @"greetingFromObjC": @"Hi there, JS!" };
    [self.webView.fwJsBridge callHandler:@"testJavascriptHandler" data:data responseCallback:^(id response) {
        NSLog(@"testJavascriptHandler responded: %@", response);
    }];
}

- (void)renderView
{
    [self renderButtons:self.webView];
    
    NSURL *htmlUrl = [TestBundle.bundle URLForResource:@"JavascriptBridge" withExtension:@"html"];
    self.webRequest = htmlUrl;
}

- (void)renderButtons:(WKWebView*)webView {
    UIFont* font = [UIFont fontWithName:@"HelveticaNeue" size:12.0];
    CGFloat y = FWScreenHeight - FWTopBarHeight - UIScreen.fwSafeAreaInsets.bottom - 45;
    
    UIButton *callbackButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [callbackButton setTitle:@"Call handler" forState:UIControlStateNormal];
    [callbackButton addTarget:self action:@selector(callHandler:) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:callbackButton aboveSubview:webView];
    callbackButton.frame = CGRectMake(10, y, 100, 35);
    callbackButton.titleLabel.font = font;
    
    UIButton* reloadButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [reloadButton setTitle:@"Reload webview" forState:UIControlStateNormal];
    [reloadButton addTarget:webView action:@selector(reload) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:reloadButton aboveSubview:webView];
    reloadButton.frame = CGRectMake(110, y, 100, 35);
    reloadButton.titleLabel.font = font;
    
    UIButton* jumpButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [jumpButton setTitle:@"Jump url" forState:UIControlStateNormal];
    FWWeakifySelf();
    [jumpButton fwAddTouchBlock:^(id  _Nonnull sender) {
        FWStrongifySelf();
        self.webRequest = @"http://kvm.wuyong.site/test.php";
    }];
    [self.view insertSubview:jumpButton aboveSubview:webView];
    jumpButton.frame = CGRectMake(210, y, 100, 35);
    jumpButton.titleLabel.font = font;
}

@end
