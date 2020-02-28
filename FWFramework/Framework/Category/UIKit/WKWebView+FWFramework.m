/*!
 @header     WKWebView+FWFramework.m
 @indexgroup FWFramework
 @brief      WKWebView+FWFramework
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/2/28
 */

#import "WKWebView+FWFramework.h"
#import "FWMessage.h"
#import <objc/runtime.h>

@implementation WKWebView (FWFramework)

- (id<FWWebViewNavigationDelegate>)fwNavigationDelegate
{
    return objc_getAssociatedObject(self, @selector(fwNavigationDelegate));
}

- (void)setFwNavigationDelegate:(id<FWWebViewNavigationDelegate>)fwNavigationDelegate
{
    if (!fwNavigationDelegate || (self.fwNavigationDelegate && ![self.fwNavigationDelegate isEqual:fwNavigationDelegate])) {
        [self fwUnobserveProperty:@"estimatedProgress"];
    }
    
    if (fwNavigationDelegate) {
        [self fwObserveProperty:@"estimatedProgress" block:^(WKWebView *webView, NSDictionary *change) {
            if (webView.fwNavigationDelegate && [webView.fwNavigationDelegate respondsToSelector:@selector(webView:updateProgress:)]) {
                [webView.fwNavigationDelegate webView:webView updateProgress:webView.estimatedProgress];
            }
        }];
    }
    
    objc_setAssociatedObject(self, @selector(fwNavigationDelegate), fwNavigationDelegate, OBJC_ASSOCIATION_ASSIGN);
    
    self.navigationDelegate = fwNavigationDelegate;
}

@end

@implementation UIProgressView (FWFramework)

- (void)fwSetProgress:(float)progress
{
    if (progress == 0) {
        self.alpha = 0;
    } else if (self.alpha == 0 && progress > 0) {
        self.progress = 0;
        [UIView animateWithDuration:0.2 animations:^{
            self.alpha = 1.0;
        }];
    } else if (self.alpha == 1.0 && progress == 1.0) {
        [UIView animateWithDuration:0.2 animations:^{
            self.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.progress = 0;
        }];
    }
    [self setProgress:progress animated:YES];
}

@end
