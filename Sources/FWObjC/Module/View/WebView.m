//
//  WebView.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "WebView.h"
#import "Bridge.h"
#import <objc/runtime.h>

#if FWMacroSPM

@interface NSObject ()

+ (void)__fw_logDebug:(NSString *)message;
+ (NSArray<NSString *> *)__fw_classMethods:(Class)clazz superclass:(BOOL)superclass;
- (nullable id)__fw_invokeMethod:(SEL)aSelector objects:(NSArray *)objects;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

#define __FWLogDebug( aFormat, ... ) \
    [NSObject __fw_logDebug:[NSString stringWithFormat:(@"(%@ %@ #%d %s) " aFormat), NSThread.isMainThread ? @"[M]" : @"[T]", [@(__FILE__) lastPathComponent], __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__]];

#pragma mark - __FWWebViewCookieManager

@implementation __FWWebViewCookieManager

+ (void)syncRequestCookie:(NSMutableURLRequest *)request
{
    if (!request.URL) {
        return;
    }
    
    NSArray<NSHTTPCookie *> *availableCookie = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:request.URL];
    if (availableCookie.count > 0) {
        NSDictionary *reqHeader = [NSHTTPCookie requestHeaderFieldsWithCookies:availableCookie];
        NSString *cookieStr = [reqHeader objectForKey:@"Cookie"];
        [request setValue:cookieStr forHTTPHeaderField:@"Cookie"];
    }
}

+ (void)syncRequestHttpOnlyCookie:(NSMutableURLRequest *)request
{
    if (!request.URL) {
        return;
    }
    
    NSArray<NSHTTPCookie *> *availableCookie = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:request.URL];
    if (availableCookie.count > 0) {
        NSMutableString *cookieStr = [[request valueForHTTPHeaderField:@"Cookie"] mutableCopy];
        if (!cookieStr) {
            cookieStr = [[NSMutableString alloc] init];
        }
        for (NSHTTPCookie *cookie in availableCookie) {
            if (!cookie.isHTTPOnly) {
                continue;
            }
            [cookieStr appendFormat:@"%@=%@;", cookie.name, cookie.value];
        }
        [request setValue:cookieStr forHTTPHeaderField:@"Cookie"];
    }
}

+ (NSString *)ajaxCookieScripts
{
    NSMutableString *cookieScript = [[NSMutableString alloc] init];
    for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
        if ([cookie.value rangeOfString:@"'"].location != NSNotFound) {
            continue;
        }
        [cookieScript appendFormat:@"document.cookie='%@=%@;", cookie.name, cookie.value];
        if (cookie.domain || cookie.domain.length > 0) {
            [cookieScript appendFormat:@"domain=%@;", cookie.domain];
        }
        if (cookie.path || cookie.path.length > 0) {
            [cookieScript appendFormat:@"path=%@;", cookie.path];
        }
        if (cookie.expiresDate) {
            [cookieScript appendFormat:@"expires=%@;", [[self cookieDateFormatter] stringFromDate:cookie.expiresDate]];
        }
        if (cookie.secure) {
            [cookieScript appendString:@"Secure;"];
        }
        if (cookie.HTTPOnly) {
            [cookieScript appendString:@"HTTPOnly;"];
        }
        [cookieScript appendFormat:@"'\n"];
    }
    return cookieScript;
}

+ (NSMutableURLRequest *)fixRequest:(NSURLRequest *)request
{
    NSMutableURLRequest *fixedRequest;
    if ([request isKindOfClass:[NSMutableURLRequest class]]) {
        fixedRequest = (NSMutableURLRequest *)request;
    } else {
        fixedRequest = request.mutableCopy;
    }
    
    NSMutableArray *array = [NSMutableArray array];
    for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:request.URL]) {
        NSString *value = [NSString stringWithFormat:@"%@=%@", cookie.name, cookie.value];
        [array addObject:value];
    }

    NSString *cookie = [array componentsJoinedByString:@";"];
    [fixedRequest setValue:cookie forHTTPHeaderField:@"Cookie"];
    return fixedRequest;
}

+ (void)copySharedCookie:(WKWebView *)webView completion:(void (^)(void))completion
{
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    WKHTTPCookieStore *cookieStroe = webView.configuration.websiteDataStore.httpCookieStore;
    if (cookies.count == 0) {
        completion ? completion() : nil;
        return;
    }
    for (NSHTTPCookie *cookie in cookies) {
        [cookieStroe setCookie:cookie completionHandler:^{
            if ([[cookies lastObject] isEqual:cookie]) {
                completion ? completion() : nil;
                return;
            }
        }];
    }
}

+ (void)copyWebViewCookie:(WKWebView *)webView completion:(void (^)(void))completion
{
    WKHTTPCookieStore *cookieStroe = webView.configuration.websiteDataStore.httpCookieStore;
    [cookieStroe getAllCookies:^(NSArray<NSHTTPCookie *> * _Nonnull cookies) {
        if (cookies.count == 0) {
            completion ? completion() : nil;
            return;
        }
        for (NSHTTPCookie *cookie in cookies) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
            if ([[cookies lastObject] isEqual:cookie]) {
                completion ? completion() : nil;
                return;
            }
        }
    }];
}

+ (NSDateFormatter *)cookieDateFormatter
{
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [NSDateFormatter new];
        formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        formatter.dateFormat = @"EEE, d MMM yyyy HH:mm:ss zzz";
    });
    return formatter;
}

@end

#pragma mark - __FWWebViewJsBridge

@implementation __FWWebViewJsBridgeBase {
    __weak id _webViewDelegate;
    long _uniqueId;
}

static bool logging = false;
static int logMaxLength = 500;

+ (void)enableLogging { logging = true; }
+ (void)setLogMaxLength:(int)length { logMaxLength = length;}

- (id)init {
    if (self = [super init]) {
        self.messageHandlers = [NSMutableDictionary dictionary];
        self.startupMessageQueue = [NSMutableArray array];
        self.responseCallbacks = [NSMutableDictionary dictionary];
        _uniqueId = 0;
    }
    return self;
}

- (void)dealloc {
    self.startupMessageQueue = nil;
    self.responseCallbacks = nil;
    self.messageHandlers = nil;
    self.errorHandler = nil;
    self.filterHandler = nil;
}

- (void)reset {
    self.startupMessageQueue = [NSMutableArray array];
    self.responseCallbacks = [NSMutableDictionary dictionary];
    _uniqueId = 0;
}

- (void)sendData:(id)data responseCallback:(__FWJsBridgeResponseCallback)responseCallback handlerName:(NSString*)handlerName {
    NSMutableDictionary* message = [NSMutableDictionary dictionary];
    
    if (data) {
        message[@"data"] = data;
    }
    
    if (responseCallback) {
        NSString* callbackId = [NSString stringWithFormat:@"objc_cb_%ld", ++_uniqueId];
        self.responseCallbacks[callbackId] = [responseCallback copy];
        message[@"callbackId"] = callbackId;
    }
    
    if (handlerName) {
        message[@"handlerName"] = handlerName;
    }
    [self _queueMessage:message];
}

- (void)flushMessageQueue:(NSString *)messageQueueString{
    if (messageQueueString == nil || messageQueueString.length == 0) {
        __FWLogDebug(@"WebViewJavascriptBridge: WARNING: ObjC got nil while fetching the message queue JSON from webview. This can happen if the WebViewJavascriptBridge JS is not currently present in the webview, e.g if the webview just loaded a new page.");
        return;
    }

    id messages = [self _deserializeMessageJSON:messageQueueString];
    for (__FWJsBridgeMessage* message in messages) {
        if (![message isKindOfClass:[__FWJsBridgeMessage class]]) {
            __FWLogDebug(@"WebViewJavascriptBridge: WARNING: Invalid %@ received: %@", [message class], message);
            continue;
        }
        [self _log:@"RCVD" json:message];
        
        NSString* responseId = message[@"responseId"];
        if (responseId) {
            __FWJsBridgeResponseCallback responseCallback = _responseCallbacks[responseId];
            responseCallback(message[@"responseData"]);
            [self.responseCallbacks removeObjectForKey:responseId];
        } else {
            __FWJsBridgeResponseCallback responseCallback = NULL;
            NSString* callbackId = message[@"callbackId"];
            if (callbackId) {
                responseCallback = ^(id responseData) {
                    if (responseData == nil) {
                        responseData = [NSNull null];
                    }
                    
                    __FWJsBridgeMessage* msg = @{ @"responseId":callbackId, @"responseData":responseData };
                    [self _queueMessage:msg];
                };
            } else {
                responseCallback = ^(id ignoreResponseData) {
                    // Do nothing
                };
            }
            
            if (self.filterHandler) {
                BOOL filterResult = self.filterHandler(message[@"handlerName"], message[@"data"] ?: @{}, responseCallback);
                if (!filterResult) continue;
            }
            
            __FWJsBridgeHandler handler = self.messageHandlers[message[@"handlerName"]];
            if (handler) {
                handler(message[@"data"] ?: @{}, responseCallback);
                continue;
            }
            
            __FWLogDebug(@"WVJBNoHandlerException, No handler for message from JS: %@", message);
            if (self.errorHandler) {
                self.errorHandler(message[@"handlerName"], message[@"data"] ?: @{}, responseCallback);
            }
        }
    }
}

- (void)injectJavascriptFile {
    NSString *js = __FWWebViewJsBridge_js();
    [self _evaluateJavascript:js];
    if (self.startupMessageQueue) {
        NSArray* queue = self.startupMessageQueue;
        self.startupMessageQueue = nil;
        for (id queuedMessage in queue) {
            [self _dispatchMessage:queuedMessage];
        }
    }
}

- (BOOL)isWebViewJavascriptBridgeURL:(NSURL*)url {
    if (![self isSchemeMatch:url]) {
        return NO;
    }
    return [self isBridgeLoadedURL:url] || [self isQueueMessageURL:url];
}

- (BOOL)isSchemeMatch:(NSURL*)url {
    NSString* scheme = url.scheme.lowercaseString;
    return [scheme isEqualToString:@"https"] || [scheme isEqualToString:@"wvjbscheme"];
}

- (BOOL)isQueueMessageURL:(NSURL*)url {
    NSString* host = url.host.lowercaseString;
    return [self isSchemeMatch:url] && [host isEqualToString:@"__wvjb_queue_message__"];
}

- (BOOL)isBridgeLoadedURL:(NSURL*)url {
    NSString* host = url.host.lowercaseString;
    return [self isSchemeMatch:url] && [host isEqualToString:@"__bridge_loaded__"];
}

- (void)logUnkownMessage:(NSURL*)url {
    __FWLogDebug(@"WebViewJavascriptBridge: WARNING: Received unknown WebViewJavascriptBridge command %@", [url absoluteString]);
}

- (NSString *)webViewJavascriptCheckCommand {
    return @"typeof WebViewJavascriptBridge == \'object\';";
}

- (NSString *)webViewJavascriptFetchQueyCommand {
    return @"WebViewJavascriptBridge._fetchQueue();";
}

- (void)disableJavscriptAlertBoxSafetyTimeout {
    [self sendData:nil responseCallback:nil handlerName:@"_disableJavascriptAlertBoxSafetyTimeout"];
}

// Private
// -------------------------------------------

- (void) _evaluateJavascript:(NSString *)javascriptCommand {
    [self.delegate _evaluateJavascript:javascriptCommand];
}

- (void)_queueMessage:(__FWJsBridgeMessage*)message {
    if (self.startupMessageQueue) {
        [self.startupMessageQueue addObject:message];
    } else {
        [self _dispatchMessage:message];
    }
}

- (void)_dispatchMessage:(__FWJsBridgeMessage*)message {
    NSString *messageJSON = [self _serializeMessage:message pretty:NO];
    [self _log:@"SEND" json:messageJSON];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
    
    NSString* javascriptCommand = [NSString stringWithFormat:@"WebViewJavascriptBridge._handleMessageFromObjC('%@');", messageJSON];
    if ([[NSThread currentThread] isMainThread]) {
        [self _evaluateJavascript:javascriptCommand];

    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self _evaluateJavascript:javascriptCommand];
        });
    }
}

- (NSString *)_serializeMessage:(id)message pretty:(BOOL)pretty{
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:message options:(NSJSONWritingOptions)(pretty ? NSJSONWritingPrettyPrinted : 0) error:nil] encoding:NSUTF8StringEncoding];
}

- (NSArray*)_deserializeMessageJSON:(NSString *)messageJSON {
    return [NSJSONSerialization JSONObjectWithData:[messageJSON dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
}

- (void)_log:(NSString *)action json:(id)json {
    if (!logging) { return; }
    if (![json isKindOfClass:[NSString class]]) {
        json = [self _serializeMessage:json pretty:YES];
    }
    if ([json length] > logMaxLength) {
        __FWLogDebug(@"WVJB %@: %@ [...]", action, [json substringToIndex:logMaxLength]);
    } else {
        __FWLogDebug(@"WVJB %@: %@", action, json);
    }
}

@end

@implementation __FWWebViewJsBridge {
    __weak WKWebView* _webView;
    __weak id<WKNavigationDelegate> _webViewDelegate;
    long _uniqueId;
    __FWWebViewJsBridgeBase *_base;
}

/* API
 *****/

+ (void)enableLogging { [__FWWebViewJsBridgeBase enableLogging]; }

+ (instancetype)bridgeForWebView:(WKWebView*)webView {
    __FWWebViewJsBridge* bridge = [[self alloc] init];
    [bridge _setupInstance:webView];
    [bridge reset];
    return bridge;
}

- (void)send:(id)data {
    [self send:data responseCallback:nil];
}

- (void)send:(id)data responseCallback:(__FWJsBridgeResponseCallback)responseCallback {
    [_base sendData:data responseCallback:responseCallback handlerName:nil];
}

- (void)callHandler:(NSString *)handlerName {
    [self callHandler:handlerName data:nil responseCallback:nil];
}

- (void)callHandler:(NSString *)handlerName data:(id)data {
    [self callHandler:handlerName data:data responseCallback:nil];
}

- (void)callHandler:(NSString *)handlerName data:(id)data responseCallback:(__FWJsBridgeResponseCallback)responseCallback {
    [_base sendData:data responseCallback:responseCallback handlerName:handlerName];
}

- (void)registerClass:(id)clazz package:(NSString *)package context:(nullable __weak id)context withMapper:(NSDictionary<NSString *,NSString *> * (^)(NSArray<NSString *> *))mapper
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if (!context) context = _webView;
    NSDictionary<NSString *,NSString *> *bridges = [self bridgeClass:clazz withMapper:mapper];
    [bridges enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        NSString *name = package.length > 0 ? [package stringByAppendingString:key] : key;
        [self registerHandler:name handler:^(id  _Nonnull data, __FWJsBridgeResponseCallback  _Nonnull responseCallback) {
            if (context) [clazz __fw_invokeMethod:NSSelectorFromString(obj) objects:[NSArray arrayWithObjects:context, data, responseCallback, nil]];
        }];
    }];
#pragma clang diagnostic pop
}

- (void)unregisterClass:(id)clazz package:(NSString *)package withMapper:(NSDictionary<NSString *,NSString *> * (^)(NSArray<NSString *> *))mapper
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSDictionary<NSString *,NSString *> *bridges = [self bridgeClass:clazz withMapper:mapper];
    [bridges enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        NSString *name = package.length > 0 ? [package stringByAppendingString:key] : key;
        [self removeHandler:name];
    }];
#pragma clang diagnostic pop
}

- (NSDictionary<NSString *,NSString *> *)bridgeClass:(id)clazz withMapper:(NSDictionary<NSString *,NSString *> * (^)(NSArray<NSString *> *))mapper
{
    Class metaClass;
    if (object_isClass(clazz)) {
        metaClass = objc_getMetaClass(NSStringFromClass(clazz).UTF8String);
    } else {
        metaClass = object_getClass(clazz);
    }
    if (!metaClass) return @{};
    
    NSArray<NSString *> *methods = [NSObject __fw_classMethods:metaClass superclass:NO];
    if (mapper) {
        return mapper(methods);
    }
    
    NSMutableDictionary *bridges = [NSMutableDictionary dictionary];
    for (NSString *method in methods) {
        if (![method hasSuffix:@":data:callback:"]) continue;
        if ([method componentsSeparatedByString:@":"].count != 4) continue;
        
        NSString *name = [method stringByReplacingOccurrencesOfString:@":data:callback:" withString:@""];
        bridges[name] = method;
    }
    return bridges;
}

- (void)registerHandler:(NSString *)handlerName handler:(__FWJsBridgeHandler)handler {
    _base.messageHandlers[handlerName] = [handler copy];
}

- (void)removeHandler:(NSString *)handlerName {
    [_base.messageHandlers removeObjectForKey:handlerName];
}

- (NSArray<NSString *> *)getRegisteredHandlers {
    return _base.messageHandlers.allKeys ?: @[];
}

- (void)setErrorHandler:(__FWJsBridgeErrorHandler)handler {
    _base.errorHandler = handler;
}

- (void)setFilterHandler:(__FWJsBridgeFilterHandler)handler {
    _base.filterHandler = handler;
}

- (void)reset {
    [_base reset];
}

- (void)setWebViewDelegate:(id<WKNavigationDelegate>)webViewDelegate {
    _webViewDelegate = webViewDelegate;
}

- (void)disableJavscriptAlertBoxSafetyTimeout {
    [_base disableJavscriptAlertBoxSafetyTimeout];
}

/* Internals
 ***********/

- (void)dealloc {
    _base = nil;
    _webView = nil;
    _webViewDelegate = nil;
    _webView.navigationDelegate = nil;
}


/* WKWebView Specific Internals
 ******************************/

- (void) _setupInstance:(WKWebView*)webView {
    _webView = webView;
    _webView.navigationDelegate = self;
    _base = [[__FWWebViewJsBridgeBase alloc] init];
    _base.delegate = self;
}


- (void)WKFlushMessageQueue {
    [_webView evaluateJavaScript:[_base webViewJavascriptFetchQueyCommand] completionHandler:^(NSString* result, NSError* error) {
        if (error != nil) {
            __FWLogDebug(@"WebViewJavascriptBridge: WARNING: Error when trying to fetch data from WKWebView: %@", error);
        }
        [self->_base flushMessageQueue:result];
    }];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (webView != _webView) { return; }
    
    __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webView:didFinishNavigation:)]) {
        [strongDelegate webView:webView didFinishNavigation:navigation];
    }
}


- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    if (webView != _webView) { return; }

    __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationResponse:decisionHandler:)]) {
        [strongDelegate webView:webView decidePolicyForNavigationResponse:navigationResponse decisionHandler:decisionHandler];
    }
    else {
        decisionHandler(WKNavigationResponsePolicyAllow);
    }
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    if (webView != _webView) { return; }

    __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webView:didReceiveAuthenticationChallenge:completionHandler:)]) {
        [strongDelegate webView:webView didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (webView != _webView) { return; }
    NSURL *url = navigationAction.request.URL;
    __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;

    if ([_base isWebViewJavascriptBridgeURL:url]) {
        if ([_base isBridgeLoadedURL:url]) {
            [_base injectJavascriptFile];
        } else if ([_base isQueueMessageURL:url]) {
            [self WKFlushMessageQueue];
        } else {
            [_base logUnkownMessage:url];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationAction:decisionHandler:)]) {
        [_webViewDelegate webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    if (webView != _webView) { return; }
    
    __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webView:didStartProvisionalNavigation:)]) {
        [strongDelegate webView:webView didStartProvisionalNavigation:navigation];
    }
}


- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (webView != _webView) { return; }
    
    __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webView:didFailNavigation:withError:)]) {
        [strongDelegate webView:webView didFailNavigation:navigation withError:error];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (webView != _webView) { return; }
    
    __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webView:didFailProvisionalNavigation:withError:)]) {
        [strongDelegate webView:webView didFailProvisionalNavigation:navigation withError:error];
    }
}

- (NSString*) _evaluateJavascript:(NSString*)javascriptCommand {
    [_webView evaluateJavaScript:javascriptCommand completionHandler:nil];
    return NULL;
}

@end

NSString * __FWWebViewJsBridge_js() {
    #define __wvjb_js_func__(x) #x
    
    // BEGIN preprocessorJSCode
    static NSString * preprocessorJSCode = @__wvjb_js_func__(
;(function() {
    if (window.WebViewJavascriptBridge) {
        return;
    }

    if (!window.onerror) {
        window.onerror = function(msg, url, line) {
            console.log("WebViewJavascriptBridge: ERROR:" + msg + "@" + url + ":" + line);
        }
    }
    window.WebViewJavascriptBridge = {
        registerHandler: registerHandler,
        removeHandler: removeHandler,
        getRegisteredHandlers: getRegisteredHandlers,
        setErrorHandler: setErrorHandler,
        setFilterHandler: setFilterHandler,
        callHandler: callHandler,
        disableJavscriptAlertBoxSafetyTimeout: disableJavscriptAlertBoxSafetyTimeout,
        _fetchQueue: _fetchQueue,
        _handleMessageFromObjC: _handleMessageFromObjC
    };

    var messagingIframe;
    var sendMessageQueue = [];
    var messageHandlers = {};
    var errorHandler = null;
    var filterHandler = null;
    
    var CUSTOM_PROTOCOL_SCHEME = 'https';
    var QUEUE_HAS_MESSAGE = '__wvjb_queue_message__';
    
    var responseCallbacks = {};
    var uniqueId = 1;
    var dispatchMessagesWithTimeoutSafety = true;

    function registerHandler(handlerName, handler) {
        messageHandlers[handlerName] = handler;
    }
    
    function removeHandler(handlerName) {
        delete messageHandlers[handlerName];
    }
    
    function getRegisteredHandlers() {
        var registeredHandlers = [];
        for (handlerName in messageHandlers) {
            if (handlerName != '_disableJavascriptAlertBoxSafetyTimeout') {
                registeredHandlers.push(handlerName);
            }
        }
        return registeredHandlers;
    }
    
    function setErrorHandler(handler) {
        errorHandler = handler;
    }
    
    function setFilterHandler(handler) {
        filterHandler = handler;
    }
    
    function callHandler(handlerName, data, responseCallback) {
        if (arguments.length == 2 && typeof data == 'function') {
            responseCallback = data;
            data = null;
        }
        _doSend({ handlerName:handlerName, data:data }, responseCallback);
    }
    
    function disableJavscriptAlertBoxSafetyTimeout() {
        dispatchMessagesWithTimeoutSafety = false;
    }
    
    function _doSend(message, responseCallback) {
        if (responseCallback) {
            var callbackId = 'cb_'+(uniqueId++)+'_'+new Date().getTime();
            responseCallbacks[callbackId] = responseCallback;
            message['callbackId'] = callbackId;
        }
        sendMessageQueue.push(message);
        messagingIframe.src = CUSTOM_PROTOCOL_SCHEME + '://' + QUEUE_HAS_MESSAGE;
    }

    function _fetchQueue() {
        var messageQueueString = JSON.stringify(sendMessageQueue);
        sendMessageQueue = [];
        return messageQueueString;
    }

    function _dispatchMessageFromObjC(messageJSON) {
        if (dispatchMessagesWithTimeoutSafety) {
            setTimeout(_doDispatchMessageFromObjC);
        } else {
             _doDispatchMessageFromObjC();
        }
        
        function _doDispatchMessageFromObjC() {
            var message = JSON.parse(messageJSON);
            var responseCallback;

            if (message.responseId) {
                responseCallback = responseCallbacks[message.responseId];
                if (!responseCallback) { return; }
                responseCallback(message.responseData);
                delete responseCallbacks[message.responseId];
            } else {
                if (message.callbackId) {
                    var callbackResponseId = message.callbackId;
                    responseCallback = function(responseData) {
                        _doSend({ handlerName:message.handlerName, responseId:callbackResponseId, responseData:responseData });
                    };
                } else {
                    responseCallback = function(ignoreResponseData) {};
                }
                
                if (filterHandler) {
                    var filterResult = filterHandler(message.handlerName, message.data, responseCallback);
                    if (!filterResult) { return; }
                }
                
                var handler = messageHandlers[message.handlerName];
                if (handler) {
                    handler(message.data, responseCallback);
                } else {
                    console.log("WebViewJavascriptBridge: WARNING: no handler for message from ObjC:", message);
                    if (errorHandler) {
                        errorHandler(message.handlerName, message.data, responseCallback);
                    }
                }
            }
        }
    }
    
    function _handleMessageFromObjC(messageJSON) {
        _dispatchMessageFromObjC(messageJSON);
    }

    messagingIframe = document.createElement('iframe');
    messagingIframe.style.display = 'none';
    messagingIframe.src = CUSTOM_PROTOCOL_SCHEME + '://' + QUEUE_HAS_MESSAGE;
    document.documentElement.appendChild(messagingIframe);

    registerHandler("_disableJavascriptAlertBoxSafetyTimeout", disableJavscriptAlertBoxSafetyTimeout);
    
    setTimeout(_callWVJBCallbacks, 0);
    function _callWVJBCallbacks() {
        var callbacks = window.WVJBCallbacks;
        delete window.WVJBCallbacks;
        for (var i=0; i<callbacks.length; i++) {
            callbacks[i](WebViewJavascriptBridge);
        }
    }
})();
    ); // END preprocessorJSCode

    #undef __wvjb_js_func__
    return preprocessorJSCode;
};
