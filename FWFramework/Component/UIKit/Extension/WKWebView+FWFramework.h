/*!
 @header     WKWebView+FWFramework.h
 @indexgroup FWFramework
 @brief      WKWebView+FWFramework
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/2/28
 */

#import <WebKit/WebKit.h>
#import "WKWebView+FWJsBridge.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FWWebViewNavigationDelegate <WKNavigationDelegate>

- (void)webView:(WKWebView *)webView updateProgress:(CGFloat)progress;

@end

@interface WKWebView (FWFramework)

@property (nullable, nonatomic, weak) id<FWWebViewNavigationDelegate> fwNavigationDelegate;

@end

NS_ASSUME_NONNULL_END
