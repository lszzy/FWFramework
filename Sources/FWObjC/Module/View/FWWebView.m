//
//  FWWebView.m
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#import "FWWebView.h"
#import "FWProxy.h"
#import "FWNavigator.h"
#import "FWToolkit.h"
#import "FWUIKit.h"
#import "FWAlertPlugin.h"
#import "FWAutoLayout.h"
#import "FWRuntime.h"
#import "FWMessage.h"
#import "FWEncode.h"
#import <objc/runtime.h>

#pragma mark - FWWebView

@interface FWWebViewDelegateProxy : FWDelegateProxy <FWWebViewDelegate>

@end

@implementation FWWebViewDelegateProxy

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if ([webView isKindOfClass:[FWWebView class]] &&
        ((FWWebView *)webView).cookieEnabled &&
        [navigationAction.request isKindOfClass:NSMutableURLRequest.class]) {
        [FWWebViewCookieManager syncRequestCookie:(NSMutableURLRequest *)navigationAction.request];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(webView:decidePolicyForNavigationAction:decisionHandler:)]) {
        [self.delegate webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(webViewShouldLoad:)] &&
        ![self.delegate webViewShouldLoad:navigationAction]) {
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    if ([UIApplication fw_isSystemURL:navigationAction.request.URL]) {
        [UIApplication fw_openURL:navigationAction.request.URL];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    if (((FWWebView *)webView).allowsSchemeURL &&
        [UIApplication fw_isSchemeURL:navigationAction.request.URL]) {
        [UIApplication fw_openURL:navigationAction.request.URL];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    if ([webView isKindOfClass:[FWWebView class]] &&
        ((FWWebView *)webView).allowsUniversalLinks &&
        [navigationAction.request.URL.scheme isEqualToString:@"https"]) {
        [UIApplication fw_openUniversalLinks:navigationAction.request.URL completionHandler:^(BOOL success) {
            decisionHandler(success ? WKNavigationActionPolicyCancel : WKNavigationActionPolicyAllow);
        }];
        return;
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    if ([webView isKindOfClass:[FWWebView class]] &&
        ((FWWebView *)webView).cookieEnabled) {
        [FWWebViewCookieManager copyWebViewCookie:webView completion:nil];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(webView:decidePolicyForNavigationResponse:decisionHandler:)]) {
        [self.delegate webView:webView decidePolicyForNavigationResponse:navigationResponse decisionHandler:decisionHandler];
        return;
    }
    
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(webView:didFinishNavigation:)]) {
        [self.delegate webView:webView didFinishNavigation:navigation];
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(webViewFinishLoad)]) {
        [self.delegate webViewFinishLoad];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(webView:didFailProvisionalNavigation:withError:)]) {
        [self.delegate webView:webView didFailProvisionalNavigation:navigation withError:error];
        return;
    }
    
    if (error.code == NSURLErrorCancelled) return;
    if (self.delegate && [self.delegate respondsToSelector:@selector(webViewFailLoad:)]) {
        [self.delegate webViewFailLoad:error];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(webView:didFailNavigation:withError:)]) {
        [self.delegate webView:webView didFailNavigation:navigation withError:error];
        return;
    }
    
    if (error.code == NSURLErrorCancelled) return;
    if (self.delegate && [self.delegate respondsToSelector:@selector(webViewFailLoad:)]) {
        [self.delegate webViewFailLoad:error];
    }
}

#pragma mark - WKUIDelegate

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(webView:runJavaScriptAlertPanelWithMessage:initiatedByFrame:completionHandler:)]) {
        [self.delegate webView:webView runJavaScriptAlertPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
        return;
    }
    
    [webView fw_showAlertWithTitle:nil message:message cancel:nil cancelBlock:^{
        completionHandler();
    }];
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(webView:runJavaScriptConfirmPanelWithMessage:initiatedByFrame:completionHandler:)]) {
        [self.delegate webView:webView runJavaScriptConfirmPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
        return;
    }
    
    [webView fw_showConfirmWithTitle:nil message:message cancel:nil confirm:nil confirmBlock:^{
        completionHandler(YES);
    } cancelBlock:^{
        completionHandler(NO);
    }];
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString *))completionHandler
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(webView:runJavaScriptTextInputPanelWithPrompt:defaultText:initiatedByFrame:completionHandler:)]) {
        [self.delegate webView:webView runJavaScriptTextInputPanelWithPrompt:prompt defaultText:defaultText initiatedByFrame:frame completionHandler:completionHandler];
        return;
    }
    
    [webView fw_showPromptWithTitle:nil message:prompt cancel:nil confirm:nil promptBlock:^(UITextField *textField) {
        textField.text = defaultText;
    } confirmBlock:^(NSString *text) {
        completionHandler(text);
    } cancelBlock:^{
        completionHandler(nil);
    }];
}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(webView:createWebViewWithConfiguration:forNavigationAction:windowFeatures:)]) {
        return [self.delegate webView:webView createWebViewWithConfiguration:configuration forNavigationAction:navigationAction windowFeatures:windowFeatures];
    }
    
    if (!navigationAction.targetFrame.isMainFrame) {
        if ([webView isKindOfClass:[FWWebView class]] && ((FWWebView *)webView).cookieEnabled) {
            [webView loadRequest:[FWWebViewCookieManager fixRequest:navigationAction.request]];
        } else {
            [webView loadRequest:navigationAction.request];
        }
    }
    return nil;
}

- (void)webViewDidClose:(WKWebView *)webView
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(webViewDidClose:)]) {
        [self.delegate webViewDidClose:webView];
        return;
    }
    
    if ([webView isKindOfClass:[FWWebView class]] && ((FWWebView *)webView).allowsWindowClose) {
        [webView.fw_viewController fw_closeViewControllerAnimated:YES];
    }
}

@end

static WKProcessPool *fwStaticProcessPool = nil;

@interface FWWebView ()

@property (nonatomic, strong) FWWebViewDelegateProxy *delegateProxy;

@property (nonatomic, strong) UIProgressView *progressView;

@end

@implementation FWWebView

+ (WKProcessPool *)processPool
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!fwStaticProcessPool) fwStaticProcessPool = [[WKProcessPool alloc] init];
    });
    return fwStaticProcessPool;
}

+ (void)setProcessPool:(WKProcessPool *)processPool
{
    if (processPool) fwStaticProcessPool = processPool;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
    configuration.applicationNameForUserAgent = [WKWebView fw_extensionUserAgent];
    configuration.processPool = [FWWebView processPool];
    return [self initWithFrame:frame configuration:configuration];
}

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration
{
    self = [super initWithFrame:frame configuration:configuration];
    if (self) {
        [self didInitialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self didInitialize];
    }
    return self;
}

- (void)didInitialize
{
    self.delegateProxy = [[FWWebViewDelegateProxy alloc] init];
    self.navigationDelegate = self.delegateProxy;
    self.UIDelegate = self.delegateProxy;
    self.allowsBackForwardNavigationGestures = YES;
    self.allowsWindowClose = YES;
    #ifdef DEBUG
    if (@available(iOS 16.4, *)) {
        self.inspectable = YES;
    }
    #endif
    
    self.progressView = [[UIProgressView alloc] initWithFrame:CGRectZero];
    self.progressView.trackTintColor = [UIColor clearColor];
    self.progressView.fw_webProgress = 0;
    [self addSubview:self.progressView];
    [self.progressView fw_pinEdgesToSuperviewWithInsets:UIEdgeInsetsZero excludingEdge:NSLayoutAttributeBottom];
    [self.progressView fw_setDimension:NSLayoutAttributeHeight toSize:2.f];
    [self fw_observeProperty:@"estimatedProgress" block:^(FWWebView *webView, NSDictionary *change) {
        if (webView.estimatedProgress < 1.0) {
            webView.progressView.fw_webProgress = webView.estimatedProgress;
        }
    }];
    [self fw_observeProperty:@"loading" block:^(FWWebView *webView, NSDictionary *change) {
        if (!webView.isLoading) {
            webView.progressView.fw_webProgress = 1.0;
        }
    }];
}

- (id<FWWebViewDelegate>)delegate
{
    return self.delegateProxy.delegate;
}

- (void)setDelegate:(id<FWWebViewDelegate>)delegate
{
    self.delegateProxy.delegate = delegate;
}

- (void)setWebRequest:(id)webRequest
{
    _webRequest = webRequest;
    
    if (!webRequest) return;
    if ([webRequest isKindOfClass:[NSURLRequest class]]) {
        [self loadRequest:webRequest];
        return;
    }
    
    NSURL *requestUrl = [webRequest isKindOfClass:[NSURL class]] ? webRequest : nil;
    if (!requestUrl && [webRequest isKindOfClass:[NSString class]]) {
        requestUrl = [NSURL fw_urlWithString:webRequest];
    }
    if (requestUrl.absoluteString.length < 1) return;
    
    if (requestUrl.isFileURL) {
        NSString *htmlString = [NSString stringWithContentsOfURL:requestUrl encoding:NSUTF8StringEncoding error:NULL];
        if (htmlString) {
            [self loadHTMLString:htmlString baseURL:requestUrl];
        }
    } else {
        [self loadRequest:[NSURLRequest requestWithURL:requestUrl]];
    }
}

- (WKNavigation *)loadRequest:(NSURLRequest *)request
{
    if (self.cookieEnabled && request.URL.scheme.length > 0) {
        WKUserScript *cookieScript = [[WKUserScript alloc] initWithSource:[FWWebViewCookieManager ajaxCookieScripts] injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
        [self.configuration.userContentController addUserScript:cookieScript];
        
        NSMutableURLRequest *cookieRequest = request.mutableCopy;
        [FWWebViewCookieManager syncRequestCookie:cookieRequest];
        return [super loadRequest:cookieRequest];
    }
    
    return [super loadRequest:request];
}

@end

@implementation UIProgressView (FWWebView)

- (float)fw_webProgress
{
    return self.progress;
}

- (void)setFw_webProgress:(float)progress
{
    if (progress <= 0) {
        self.alpha = 0;
    } else if (progress > 0 && progress < 1.0) {
        if (self.alpha == 0) {
            self.progress = 0;
            [UIView animateWithDuration:0.2 animations:^{
                self.alpha = 1.0;
            }];
        }
    } else {
        self.alpha = 1.0;
        [UIView animateWithDuration:0.2 animations:^{
            self.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.progress = 0;
        }];
    }
    [self setProgress:progress animated:YES];
}

@end

#pragma mark - FWWebViewCookieManager

@implementation FWWebViewCookieManager

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
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        formatter.dateFormat = @"EEE, d MMM yyyy HH:mm:ss zzz";
    });
    return formatter;
}

@end

#pragma mark - FWWebViewBridge

@implementation FWWebViewJsBridgeBase {
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

- (void)sendData:(id)data responseCallback:(FWJsBridgeResponseCallback)responseCallback handlerName:(NSString*)handlerName {
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
        NSLog(@"WebViewJavascriptBridge: WARNING: ObjC got nil while fetching the message queue JSON from webview. This can happen if the WebViewJavascriptBridge JS is not currently present in the webview, e.g if the webview just loaded a new page.");
        return;
    }

    id messages = [self _deserializeMessageJSON:messageQueueString];
    for (FWJsBridgeMessage* message in messages) {
        if (![message isKindOfClass:[FWJsBridgeMessage class]]) {
            NSLog(@"WebViewJavascriptBridge: WARNING: Invalid %@ received: %@", [message class], message);
            continue;
        }
        [self _log:@"RCVD" json:message];
        
        NSString* responseId = message[@"responseId"];
        if (responseId) {
            FWJsBridgeResponseCallback responseCallback = _responseCallbacks[responseId];
            responseCallback(message[@"responseData"]);
            [self.responseCallbacks removeObjectForKey:responseId];
        } else {
            FWJsBridgeResponseCallback responseCallback = NULL;
            NSString* callbackId = message[@"callbackId"];
            if (callbackId) {
                responseCallback = ^(id responseData) {
                    if (responseData == nil) {
                        responseData = [NSNull null];
                    }
                    
                    FWJsBridgeMessage* msg = @{ @"responseId":callbackId, @"responseData":responseData };
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
            
            FWJsBridgeHandler handler = self.messageHandlers[message[@"handlerName"]];
            if (handler) {
                handler(message[@"data"] ?: @{}, responseCallback);
                continue;
            }
            
            NSLog(@"WVJBNoHandlerException, No handler for message from JS: %@", message);
            if (self.errorHandler) {
                self.errorHandler(message[@"handlerName"], message[@"data"] ?: @{}, responseCallback);
            }
        }
    }
}

- (void)injectJavascriptFile {
    NSString *js = FWWebViewJsBridge_js();
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
    NSLog(@"WebViewJavascriptBridge: WARNING: Received unknown WebViewJavascriptBridge command %@", [url absoluteString]);
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

- (void)_queueMessage:(FWJsBridgeMessage*)message {
    if (self.startupMessageQueue) {
        [self.startupMessageQueue addObject:message];
    } else {
        [self _dispatchMessage:message];
    }
}

- (void)_dispatchMessage:(FWJsBridgeMessage*)message {
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
        NSLog(@"WVJB %@: %@ [...]", action, [json substringToIndex:logMaxLength]);
    } else {
        NSLog(@"WVJB %@: %@", action, json);
    }
}

@end

@implementation FWWebViewJsBridge {
    __weak WKWebView* _webView;
    __weak id<WKNavigationDelegate> _webViewDelegate;
    long _uniqueId;
    FWWebViewJsBridgeBase *_base;
}

/* API
 *****/

+ (void)enableLogging { [FWWebViewJsBridgeBase enableLogging]; }

+ (instancetype)bridgeForWebView:(WKWebView*)webView {
    FWWebViewJsBridge* bridge = [[self alloc] init];
    [bridge _setupInstance:webView];
    [bridge reset];
    return bridge;
}

- (void)send:(id)data {
    [self send:data responseCallback:nil];
}

- (void)send:(id)data responseCallback:(FWJsBridgeResponseCallback)responseCallback {
    [_base sendData:data responseCallback:responseCallback handlerName:nil];
}

- (void)callHandler:(NSString *)handlerName {
    [self callHandler:handlerName data:nil responseCallback:nil];
}

- (void)callHandler:(NSString *)handlerName data:(id)data {
    [self callHandler:handlerName data:data responseCallback:nil];
}

- (void)callHandler:(NSString *)handlerName data:(id)data responseCallback:(FWJsBridgeResponseCallback)responseCallback {
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
        [self registerHandler:name handler:^(id  _Nonnull data, FWJsBridgeResponseCallback  _Nonnull responseCallback) {
            if (context) [clazz fw_invokeMethod:NSSelectorFromString(obj) withObjects:[NSArray arrayWithObjects:context, data, responseCallback, nil]];
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
    
    NSArray<NSString *> *methods = [NSObject fw_classMethods:metaClass superclass:NO];
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

- (void)registerHandler:(NSString *)handlerName handler:(FWJsBridgeHandler)handler {
    _base.messageHandlers[handlerName] = [handler copy];
}

- (void)removeHandler:(NSString *)handlerName {
    [_base.messageHandlers removeObjectForKey:handlerName];
}

- (NSArray<NSString *> *)getRegisteredHandlers {
    return _base.messageHandlers.allKeys ?: @[];
}

- (void)setErrorHandler:(FWJsBridgeErrorHandler)handler {
    _base.errorHandler = handler;
}

- (void)setFilterHandler:(FWJsBridgeFilterHandler)handler {
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
    _base = [[FWWebViewJsBridgeBase alloc] init];
    _base.delegate = self;
}


- (void)WKFlushMessageQueue {
    [_webView evaluateJavaScript:[_base webViewJavascriptFetchQueyCommand] completionHandler:^(NSString* result, NSError* error) {
        if (error != nil) {
            NSLog(@"WebViewJavascriptBridge: WARNING: Error when trying to fetch data from WKWebView: %@", error);
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
        [strongDelegate webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
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

NSString * FWWebViewJsBridge_js(void) {
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

@implementation WKWebView (FWWebViewBridge)

- (FWWebViewJsBridge *)fw_jsBridge
{
    return objc_getAssociatedObject(self, @selector(fw_jsBridge));
}

- (void)setFw_jsBridge:(FWWebViewJsBridge *)jsBridge
{
    objc_setAssociatedObject(self, @selector(fw_jsBridge), jsBridge, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)fw_userAgent
{
    if (self.customUserAgent.length > 0) return self.customUserAgent;
    NSString *userAgent = [self fw_invokeGetter:@"userAgent"];
    if ([userAgent isKindOfClass:[NSString class]] && userAgent.length > 0) return userAgent;
    return [WKWebView fw_browserUserAgent];
}

+ (NSString *)fw_browserUserAgent
{
    NSString *platformUserAgent = [NSString stringWithFormat:@"Mozilla/5.0 (%@; CPU OS %@ like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko)", [[UIDevice currentDevice] model], [[UIDevice currentDevice].systemVersion stringByReplacingOccurrencesOfString:@"." withString:@"_"]];
    NSString *userAgent = [NSString stringWithFormat:@"%@ %@", platformUserAgent, [self fw_extensionUserAgent]];
    return userAgent;
}

+ (NSString *)fw_extensionUserAgent
{
    NSString *userAgent = [NSString stringWithFormat:@"Mobile/15E148 Safari/605.1.15 %@/%@", [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleExecutableKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey], [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey]];
    return userAgent;
}

+ (NSString *)fw_requestUserAgent
{
    NSString *userAgent = [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)", [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleExecutableKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey], [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], [[UIScreen mainScreen] scale]];
    return userAgent;
}

+ (void)fw_clearCache:(void (^)(void))completion
{
    NSSet<NSString *> *dataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
    NSDate *sinceDate = [NSDate dateWithTimeIntervalSince1970:0];
    [WKWebsiteDataStore.defaultDataStore removeDataOfTypes:dataTypes modifiedSince:sinceDate completionHandler:^{
        if (completion) completion();
    }];
}

@end
