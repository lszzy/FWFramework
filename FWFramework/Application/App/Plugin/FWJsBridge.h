/*!
 @header     FWJsBridge.h
 @indexgroup FWFramework
 @brief      FWJsBridge
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/3/17
 */

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^FWJsBridgeResponseCallback)(id responseData);
typedef void (^FWJsBridgeHandler)(id data, FWJsBridgeResponseCallback responseCallback);
typedef NSDictionary FWJsBridgeMessage;

@protocol FWWebViewJsBridgeDelegate <NSObject>
- (NSString *)_evaluateJavascript:(NSString*)javascriptCommand;
@end

@interface FWWebViewJsBridgeBase : NSObject

@property (weak, nonatomic, nullable) id<FWWebViewJsBridgeDelegate> delegate;
@property (strong, nonatomic) NSMutableArray* startupMessageQueue;
@property (strong, nonatomic) NSMutableDictionary* responseCallbacks;
@property (strong, nonatomic) NSMutableDictionary* messageHandlers;
@property (strong, nonatomic) FWJsBridgeHandler messageHandler;

+ (void)enableLogging;
+ (void)setLogMaxLength:(int)length;
- (void)reset;
- (void)sendData:(id)data responseCallback:(FWJsBridgeResponseCallback)responseCallback handlerName:(NSString*)handlerName;
- (void)flushMessageQueue:(NSString *)messageQueueString;
- (void)injectJavascriptFile;
- (BOOL)isWebViewJavascriptBridgeURL:(NSURL*)url;
- (BOOL)isQueueMessageURL:(NSURL*)url;
- (BOOL)isBridgeLoadedURL:(NSURL*)url;
- (void)logUnkownMessage:(NSURL*)url;
- (NSString *)webViewJavascriptCheckCommand;
- (NSString *)webViewJavascriptFetchQueyCommand;
- (void)disableJavscriptAlertBoxSafetyTimeout;

@end

/*!
@brief WKWebView实现Javascript桥接器

@see https://github.com/marcuswestin/WebViewJavascriptBridge
*/
@interface FWWebViewJsBridge : NSObject<WKNavigationDelegate, FWWebViewJsBridgeDelegate>

+ (instancetype)bridgeForWebView:(WKWebView*)webView;
+ (void)enableLogging;

- (void)registerHandler:(NSString*)handlerName handler:(FWJsBridgeHandler)handler;
- (void)removeHandler:(NSString*)handlerName;
- (void)callHandler:(NSString*)handlerName;
- (void)callHandler:(NSString*)handlerName data:(id)data;
- (void)callHandler:(NSString*)handlerName data:(id)data responseCallback:(FWJsBridgeResponseCallback)responseCallback;
- (void)reset;
- (void)setWebViewDelegate:(nullable id)webViewDelegate;
- (void)disableJavscriptAlertBoxSafetyTimeout;

@end

NSString * FWWebViewJsBridge_js(void);

@interface WKWebView (FWJsBridge)

@property (strong, nonatomic, nullable) FWWebViewJsBridge *fwJsBridge;

/// 异步获取并缓存WebView原始默认UserAgent，需主线程调用，示例：Mozilla/5.0 (iPhone; CPU OS 14_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148
+ (void)fwWebViewUserAgent:(nullable void (^)(NSString * _Nullable userAgent))completion;

/// 获取默认浏览器UserAgent，包含应用信息，示例：Mozilla/5.0 (iPhone; CPU OS 14_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Example/1.0.0 Mobile/15E148 Safari/605.1.15
+ (NSString *)fwBrowserUserAgent;

/// 获取默认浏览器平台UserAgent，不含扩展信息，示例：Mozilla/5.0 (iPhone; CPU OS 14_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko)
+ (NSString *)fwBrowserPlatformUserAgent;

/// 获取默认浏览器扩展UserAgent，不含平台信息，可用于applicationNameForUserAgent，示例：Example/1.0.0 Mobile/15E148 Safari/605.1.15
+ (NSString *)fwBrowserExtensionUserAgent;

/// 获取默认请求UserAgent，可用于网络请求，示例：Example/1.0.0 (iPhone; iOS 14.2; Scale/3.00)
+ (NSString *)fwRequestUserAgent;

@end

@interface UIProgressView (FWJsBridge)

/// 更新进度，0和1自动切换隐藏状态。可设置trackTintColor为clear，隐藏背景色
- (void)fwSetProgress:(float)progress;

@end

NS_ASSUME_NONNULL_END
