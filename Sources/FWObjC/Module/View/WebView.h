//
//  WebView.h
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - __FWWebView

NS_SWIFT_NAME(WebViewDelegate)
@protocol __FWWebViewDelegate <WKNavigationDelegate, WKUIDelegate>

@optional

/// 是否开始加载，可用来拦截URL SCHEME、通用链接、系统链接等
- (BOOL)webViewShouldLoad:(WKNavigationAction *)navigationAction;

/// 已经加载完成，可用来获取title、设置按钮等
- (void)webViewFinishLoad;

/// 网页加载失败，可用来处理加载异常等
- (void)webViewFailLoad:(NSError *)error;

@end

/**
 WKWebView封装，默认实现进度条、JS弹窗、Cookie管理、自定义User-Agent等
 */
NS_SWIFT_NAME(WebView)
@interface __FWWebView : WKWebView

/// 默认跨WKWebView共享Cookie，切换用户时可重置processPool清空Cookie
@property (class, nonatomic, strong) WKProcessPool *processPool;

/// 事件代理，包含navigationDelegate和UIDelegate
@property (nonatomic, weak, nullable) id<__FWWebViewDelegate> delegate;

/// 是否启用Cookie管理，默认NO未启用
@property (nonatomic, assign) BOOL cookieEnabled;

/// 进度视图，默认trackTintColor为clear
@property (nonatomic, readonly) UIProgressView *progressView;

/// 是否允许打开通用链接，默认NO
@property (nonatomic, assign) BOOL allowsUniversalLinks;

/// 是否允许打开Scheme链接(非http|https|file链接)，默认NO
@property (nonatomic, assign) BOOL allowsSchemeURL;

/// 网页请求，设置后会自动加载，支持NSString|NSURL|NSURLRequest。默认nil
@property (nonatomic, strong, nullable) id webRequest;

@end

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

#pragma mark - __FWWebViewJsBridge

typedef void (^__FWJsBridgeResponseCallback)(id responseData) NS_SWIFT_NAME(JsBridgeResponseCallback);
typedef void (^__FWJsBridgeHandler)(id data, __FWJsBridgeResponseCallback responseCallback) NS_SWIFT_NAME(JsBridgeHandler);
typedef void (^__FWJsBridgeErrorHandler)(NSString *handlerName, id data, __FWJsBridgeResponseCallback responseCallback) NS_SWIFT_NAME(JsBridgeErrorHandler);
typedef BOOL (^__FWJsBridgeFilterHandler)(NSString *handlerName, id data, __FWJsBridgeResponseCallback responseCallback) NS_SWIFT_NAME(JsBridgeFilterHandler);
typedef NSDictionary __FWJsBridgeMessage NS_SWIFT_NAME(JsBridgeMessage);

NS_SWIFT_NAME(WebViewJsBridgeDelegate)
@protocol __FWWebViewJsBridgeDelegate <NSObject>
- (NSString *)_evaluateJavascript:(NSString *)javascriptCommand;
@end

NS_SWIFT_NAME(WebViewJsBridgeBase)
@interface __FWWebViewJsBridgeBase : NSObject

@property (weak, nonatomic, nullable) id<__FWWebViewJsBridgeDelegate> delegate;
@property (strong, nonatomic, nullable) NSMutableArray *startupMessageQueue;
@property (strong, nonatomic, nullable) NSMutableDictionary *responseCallbacks;
@property (strong, nonatomic, nullable) NSMutableDictionary *messageHandlers;
@property (copy, nonatomic, nullable) __FWJsBridgeErrorHandler errorHandler;
@property (copy, nonatomic, nullable) __FWJsBridgeFilterHandler filterHandler;

+ (void)enableLogging;
+ (void)setLogMaxLength:(int)length;
- (void)reset;
- (void)sendData:(nullable id)data responseCallback:(nullable __FWJsBridgeResponseCallback)responseCallback handlerName:(nullable NSString *)handlerName;
- (void)flushMessageQueue:(NSString *)messageQueueString;
- (void)injectJavascriptFile;
- (BOOL)isWebViewJavascriptBridgeURL:(NSURL *)url;
- (BOOL)isQueueMessageURL:(NSURL *)url;
- (BOOL)isBridgeLoadedURL:(NSURL *)url;
- (void)logUnkownMessage:(NSURL *)url;
- (NSString *)webViewJavascriptCheckCommand;
- (NSString *)webViewJavascriptFetchQueyCommand;
- (void)disableJavscriptAlertBoxSafetyTimeout;

@end

/**
WKWebView实现Javascript桥接器

@see https://github.com/marcuswestin/WebViewJavascriptBridge
*/
NS_SWIFT_NAME(WebViewJsBridge)
@interface __FWWebViewJsBridge : NSObject<WKNavigationDelegate, __FWWebViewJsBridgeDelegate>

+ (instancetype)bridgeForWebView:(WKWebView *)webView;
+ (void)enableLogging;

- (void)registerClass:(id)clazz package:(nullable NSString *)package context:(nullable __weak id)context withMapper:(nullable NSDictionary<NSString *, NSString *> * (^)(NSArray<NSString *> *methods))mapper;
- (void)unregisterClass:(id)clazz package:(nullable NSString *)package withMapper:(nullable NSDictionary<NSString *, NSString *> * (^)(NSArray<NSString *> *methods))mapper;
- (void)registerHandler:(NSString *)handlerName handler:(__FWJsBridgeHandler)handler;
- (void)removeHandler:(NSString *)handlerName;
- (NSArray<NSString *> *)getRegisteredHandlers;
- (void)setErrorHandler:(nullable __FWJsBridgeErrorHandler)handler;
- (void)setFilterHandler:(nullable __FWJsBridgeFilterHandler)handler;
- (void)callHandler:(NSString *)handlerName;
- (void)callHandler:(NSString *)handlerName data:(nullable id)data;
- (void)callHandler:(NSString *)handlerName data:(nullable id)data responseCallback:(nullable __FWJsBridgeResponseCallback)responseCallback;
- (void)reset;
- (void)setWebViewDelegate:(nullable id)webViewDelegate;
- (void)disableJavscriptAlertBoxSafetyTimeout;

@end

NSString * __FWWebViewJsBridge_js(void) NS_SWIFT_NAME(WebViewJsBridge_js());

NS_ASSUME_NONNULL_END
