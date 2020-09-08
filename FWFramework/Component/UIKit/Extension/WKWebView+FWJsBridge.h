/*!
 @header     WKWebView+FWJsBridge.h
 @indexgroup FWFramework
 @brief      WKWebView+FWJsBridge
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/3/17
 */

#import <WebKit/WebKit.h>

typedef void (^FWJsBridgeResponseCallback)(id responseData);
typedef void (^FWJsBridgeHandler)(id data, FWJsBridgeResponseCallback responseCallback);
typedef NSDictionary FWJsBridgeMessage;

@protocol FWWebViewJsBridgeDelegate <NSObject>
- (NSString *)_evaluateJavascript:(NSString*)javascriptCommand;
@end

@interface FWWebViewJsBridgeBase : NSObject

@property (weak, nonatomic) id<FWWebViewJsBridgeDelegate> delegate;
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
- (BOOL)isQueueMessageURL:(NSURL*)urll;
- (BOOL)isBridgeLoadedURL:(NSURL*)urll;
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
- (void)setWebViewDelegate:(id)webViewDelegate;
- (void)disableJavscriptAlertBoxSafetyTimeout;

@end

NSString * FWWebViewJsBridge_js(void);

@interface WKWebView (FWJsBridge)

@property (strong, nonatomic) FWWebViewJsBridge *fwJsBridge;

@end
