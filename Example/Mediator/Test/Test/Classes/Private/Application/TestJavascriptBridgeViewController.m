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
    [bridge setErrorHandler:^(NSString *handlerName, id data, FWJsBridgeResponseCallback responseCallback) {
        [UIWindow.fwMainWindow fwShowMessageWithText:[NSString stringWithFormat:@"handler %@ undefined: %@", handlerName, data] style:FWToastStyleDefault completion:^{
            responseCallback(@"Response from errorHandler");
        }];
    }];
    [bridge setFilterHandler:^BOOL(NSString * _Nonnull handlerName, id  _Nonnull data, FWJsBridgeResponseCallback  _Nonnull responseCallback) {
        if ([handlerName isEqualToString:@"testFilterCallback"]) {
            NSLog(@"testFilterCallback called: %@", data);
            responseCallback(@"Response from testFilterCallback");
            return false;
        }
        
        return true;
    }];
    [bridge registerHandler:@"testObjcCallback" handler:^(id data, FWJsBridgeResponseCallback responseCallback) {
        NSLog(@"testObjcCallback called: %@", data);
        responseCallback(@"Response from testObjcCallback");
    }];
    
    NSLog(@"registeredHandlers: %@", [bridge getRegisteredHandlers]);
    [bridge callHandler:@"testJavascriptHandler" data:@{ @"foo":@"before ready" }];
}

- (void)callHandler:(id)sender {
    id data = @{ @"greetingFromObjC": @"Hi there, JS!" };
    [self.webView.fwJsBridge callHandler:@"testJavascriptHandler" data:data responseCallback:^(id response) {
        NSLog(@"testJavascriptHandler responded: %@", response);
    }];
}

- (void)errorHandler:(id)sender {
    id data = @{ @"greetingFromObjC": @"Hi there, Error!" };
    [self.webView.fwJsBridge callHandler:@"notFoundHandler" data:data responseCallback:^(id  _Nonnull responseData) {
        NSLog(@"notFoundHandler responded: %@", responseData);
    }];
}

- (void)filterHandler:(id)sender {
    id data = @{ @"greetingFromObjC": @"Hi there, Error!" };
    [self.webView.fwJsBridge callHandler:@"testFilterHandler" data:data responseCallback:^(id  _Nonnull responseData) {
        NSLog(@"testFilterHandler responded: %@", responseData);
    }];
}

- (void)renderView
{
    [self renderButtons:self.webView];
    
    NSURL *htmlUrl = [TestBundle.bundle URLForResource:@"JavascriptBridge" withExtension:@"html"];
    self.requestUrl = htmlUrl.absoluteString;
}

- (void)renderButtons:(WKWebView*)webView {
    UIFont* font = [UIFont fontWithName:@"HelveticaNeue" size:12.0];
    CGFloat y = FWScreenHeight - FWTopBarHeight - UIScreen.fwSafeAreaInsets.bottom - 45;
    
    UIButton *callbackButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [callbackButton setTitle:@"Call" forState:UIControlStateNormal];
    [callbackButton addTarget:self action:@selector(callHandler:) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:callbackButton aboveSubview:webView];
    callbackButton.frame = CGRectMake(10, y, 60, 35);
    callbackButton.titleLabel.font = font;
    
    UIButton *errorButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [errorButton setTitle:@"Error" forState:UIControlStateNormal];
    [errorButton addTarget:self action:@selector(errorHandler:) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:errorButton aboveSubview:webView];
    errorButton.frame = CGRectMake(70, y, 60, 35);
    errorButton.titleLabel.font = font;
    
    UIButton *filterButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [filterButton setTitle:@"Filter" forState:UIControlStateNormal];
    [filterButton addTarget:self action:@selector(filterHandler:) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:filterButton aboveSubview:webView];
    filterButton.frame = CGRectMake(130, y, 60, 35);
    filterButton.titleLabel.font = font;
    
    UIButton* reloadButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [reloadButton setTitle:@"Reload" forState:UIControlStateNormal];
    [reloadButton addTarget:webView action:@selector(reload) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:reloadButton aboveSubview:webView];
    reloadButton.frame = CGRectMake(190, y, 60, 35);
    reloadButton.titleLabel.font = font;
    
    UIButton* jumpButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [jumpButton setTitle:@"Jump" forState:UIControlStateNormal];
    FWWeakifySelf();
    [jumpButton fwAddTouchBlock:^(id  _Nonnull sender) {
        FWStrongifySelf();
        self.webRequest = @"http://kvm.wuyong.site/jssdk.html";
    }];
    [self.view insertSubview:jumpButton aboveSubview:webView];
    jumpButton.frame = CGRectMake(250, y, 60, 35);
    jumpButton.titleLabel.font = font;
}

@end
