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
#import "FWProxy.h"
#import <objc/runtime.h>

@implementation WKWebView (FWFramework)

- (id<FWWebViewNavigationDelegate>)fwNavigationDelegate
{
    FWWeakObject *value = objc_getAssociatedObject(self, @selector(fwNavigationDelegate));
    return value.object;
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
    
    objc_setAssociatedObject(self, @selector(fwNavigationDelegate), [[FWWeakObject alloc] initWithObject:fwNavigationDelegate], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    self.navigationDelegate = fwNavigationDelegate;
}

@end
