/*!
 @header     FWWebViewBridge.h
 @indexgroup FWFramework
 @brief      FWWebViewBridge
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/3/17
 */

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWWebViewBridge

typedef void (^FWJsBridgeResponseCallback)(id responseData);
typedef void (^FWJsBridgeHandler)(id data, FWJsBridgeResponseCallback responseCallback);
typedef NSDictionary FWJsBridgeMessage;

@protocol FWWebViewJsBridgeDelegate <NSObject>
- (NSString *)_evaluateJavascript:(NSString *)javascriptCommand;
@end

@interface FWWebViewJsBridgeBase : NSObject

@property (weak, nonatomic, nullable) id<FWWebViewJsBridgeDelegate> delegate;
@property (strong, nonatomic, nullable) NSMutableArray *startupMessageQueue;
@property (strong, nonatomic, nullable) NSMutableDictionary *responseCallbacks;
@property (strong, nonatomic, nullable) NSMutableDictionary *messageHandlers;
@property (strong, nonatomic) FWJsBridgeHandler messageHandler;

+ (void)enableLogging;
+ (void)setLogMaxLength:(int)length;
- (void)reset;
- (void)sendData:(nullable id)data responseCallback:(nullable FWJsBridgeResponseCallback)responseCallback handlerName:(nullable NSString *)handlerName;
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

/*!
@brief WKWebView实现Javascript桥接器

@see https://github.com/marcuswestin/WebViewJavascriptBridge
*/
@interface FWWebViewJsBridge : NSObject<WKNavigationDelegate, FWWebViewJsBridgeDelegate>

+ (instancetype)bridgeForWebView:(WKWebView *)webView;
+ (void)enableLogging;

- (void)registerHandler:(NSString *)handlerName handler:(FWJsBridgeHandler)handler;
- (void)removeHandler:(NSString *)handlerName;
- (void)callHandler:(NSString *)handlerName;
- (void)callHandler:(NSString *)handlerName data:(nullable id)data;
- (void)callHandler:(NSString *)handlerName data:(nullable id)data responseCallback:(nullable FWJsBridgeResponseCallback)responseCallback;
- (void)reset;
- (void)setWebViewDelegate:(nullable id)webViewDelegate;
- (void)disableJavscriptAlertBoxSafetyTimeout;

@end

NSString * FWWebViewJsBridge_js(void);

@interface WKWebView (FWWebViewBridge)

/// 设置Javascript桥接器强引用属性，防止使用过程中被释放
@property (nonatomic, strong, nullable) FWWebViewJsBridge *fwJsBridge;

/// 获取当前UserAgent，未自定义时为默认，示例：Mozilla/5.0 (iPhone; CPU OS 14_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148
@property (nonatomic, copy, readonly) NSString *fwUserAgent;

/// 获取默认浏览器UserAgent，包含应用信息，示例：Mozilla/5.0 (iPhone; CPU OS 14_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Safari/605.1.15 Example/1.0.0
@property (class, nonatomic, copy, readonly) NSString *fwBrowserUserAgent;

/// 获取默认浏览器扩展UserAgent，不含平台信息，可用于applicationNameForUserAgent，示例：Mobile/15E148 Safari/605.1.15 Example/1.0.0
@property (class, nonatomic, copy, readonly) NSString *fwExtensionUserAgent;

/// 获取默认请求UserAgent，可用于网络请求，示例：Example/1.0.0 (iPhone; iOS 14.2; Scale/3.00)
@property (class, nonatomic, copy, readonly) NSString *fwRequestUserAgent;

@end

#pragma mark - FWWebViewCookieManager

/*!
@brief WKWebView管理Cookie

@see https://github.com/karosLi/KKJSBridge
*/
@interface FWWebViewCookieManager : NSObject

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

#pragma mark - FWWebView

@protocol FWWebViewDelegate <WKNavigationDelegate, WKUIDelegate>

@optional

/// 是否开始加载，可用来拦截URL SCHEME、通用链接、系统链接等
- (BOOL)shouldStartLoad:(WKNavigationAction *)navigationAction;

/// 已经加载完成，可用来获取title、设置按钮等
- (void)didFinishLoad;

/// 网页加载失败，可用来处理加载异常等
- (void)didFailLoad:(NSError *)error;

@end

/*!
 @brief WKWebView封装，默认实现进度条、JS弹窗、Cookie管理、自定义User-Agent等
 */
@interface FWWebView : WKWebView

/// 默认跨WKWebView共享Cookie，切换用户时可重置processPool清空Cookie
@property (class, nonatomic, strong) WKProcessPool *processPool;

/// 事件代理，包含navigationDelegate和UIDelegate
@property (nonatomic, weak, nullable) id<FWWebViewDelegate> delegate;

/// 是否启用Cookie管理，默认NO未启用
@property (nonatomic, assign) BOOL cookieEnabled;

/// 进度视图，默认trackTintColor为clear
@property (nonatomic, readonly) UIProgressView *progressView;

/// 网页请求，设置后会自动加载，支持NSString|NSURL|NSURLRequest。默认nil
@property (nonatomic, strong, nullable) id webRequest;

@end

@interface UIProgressView (FWWebView)

/// 更新进度，0和1自动切换隐藏状态。可设置trackTintColor为clear，隐藏背景色
- (void)fwSetProgress:(float)progress;

@end

NS_ASSUME_NONNULL_END
