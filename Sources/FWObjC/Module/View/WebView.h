//
//  WebView.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWWebViewCookieManager

/**
WKWebView管理Cookie

@see https://github.com/karosLi/KKJSBridge
*/
NS_SWIFT_NAME(WebViewCookieManager)
@interface __FWWebViewCookieManager : NSObject

/// 同步首个请求的Cookie
+ (void)syncRequestCookie:(NSMutableURLRequest *)request;

/// 同步请求的httpOnly Cookie
+ (void)syncRequestHttpOnlyCookie:(NSMutableURLRequest *)request;

/// 同步ajax请求的Cookie
+ (NSString *)ajaxCookieScripts;

/// 同步重定向请求的Cookie
+ (NSMutableURLRequest *)fixRequest:(NSURLRequest *)request;

/// 拷贝共享Cookie到webView，iOS11+有效
+ (void)copySharedCookie:(WKWebView *)toWebView completion:(nullable void (^)(void))completion;

/// 拷贝webView到共享Cookie，iOS11+有效
+ (void)copyWebViewCookie:(WKWebView *)fromWebView completion:(nullable void (^)(void))completion;

/// Cookie日期格式化对象
+ (NSDateFormatter *)cookieDateFormatter;

@end

NS_ASSUME_NONNULL_END
