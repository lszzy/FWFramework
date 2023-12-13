//
//  WebView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
import WebKit
import JavaScriptCore

// MARK: - WebView
/// WebView事件代理协议
public protocol WebViewDelegate: WKNavigationDelegate, WKUIDelegate {
    
    /// 是否开始加载，可用来拦截URL SCHEME、通用链接、系统链接等，默认true
    func webViewShouldLoad(_ navigationAction: WKNavigationAction) -> Bool

    /// 已经加载完成，可用来获取title、设置按钮等，默认空实现
    func webViewFinishLoad()

    /// 网页加载失败，可用来处理加载异常等，默认空实现
    func webViewFailLoad(_ error: Error)
    
}

extension WebViewDelegate {
    
    /// 是否开始加载，可用来拦截URL SCHEME、通用链接、系统链接等，默认true
    public func webViewShouldLoad(_ navigationAction: WKNavigationAction) -> Bool {
        return true
    }

    /// 已经加载完成，可用来获取title、设置按钮等，默认空实现
    public func webViewFinishLoad() {}

    /// 网页加载失败，可用来处理加载异常等，默认空实现
    public func webViewFailLoad(_ error: Error) {}
    
}

/// WKWebView封装，默认实现进度条、JS弹窗、Cookie管理、自定义User-Agent等
///
/// 备注：
/// 1. 如需实现加载离线资源等场景，请使用configuration.setURLSchemeHandler
/// 2. 第一次加载可携带自定义Header，如果存在重定向，Header里面的Authorization因安全策略会丢失。解决方法示例：可新增Header比如X-Authorization，重定向时不会丢失
/// 3. 后续非首次加载自定义Header会丢失，解决方法示例：通过JSBridge桥接获取授权信息或采用GET参数|cookie储存等
/// 4. 如果遇到Cookie丢失问题，可尝试开启cookieEnabled或自行设置Cookie等
open class WebView: WKWebView {
    
    private class WebViewDelegateProxy: DelegateProxy<WebViewDelegate>, WebViewDelegate {
        
        // MARK: - WKNavigationDelegate
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let webView = webView as? WebView,
               webView.cookieEnabled,
               let request = navigationAction.request as? NSMutableURLRequest {
                WebViewCookieManager.syncRequestCookie(request)
            }
            
            if self.delegate?.webView?(webView, decidePolicyFor: navigationAction, decisionHandler: decisionHandler) != nil {
                return
            }
            
            if let delegate = self.delegate,
               !delegate.webViewShouldLoad(navigationAction) {
                decisionHandler(.cancel)
                return
            }
            
            if UIApplication.fw_isSystemURL(navigationAction.request.url) {
                UIApplication.fw_openURL(navigationAction.request.url)
                decisionHandler(.cancel)
                return
            }
            
            if let webView = webView as? WebView,
               webView.allowsSchemeURL,
               UIApplication.fw_isSchemeURL(navigationAction.request.url) {
                UIApplication.fw_openURL(navigationAction.request.url)
                decisionHandler(.cancel)
                return
            }
            
            if let webView = webView as? WebView,
               webView.allowsUniversalLinks,
               navigationAction.request.url?.scheme == "https" {
                UIApplication.fw_openUniversalLinks(navigationAction.request.url) { success in
                    decisionHandler(success ? .cancel : .allow)
                }
                return
            }
            
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            if let webView = webView as? WebView,
               webView.cookieEnabled {
                WebViewCookieManager.copyWebViewCookie(webView)
            }
            
            if self.delegate?.webView?(webView, decidePolicyFor: navigationResponse, decisionHandler: decisionHandler) != nil {
                return
            }
            
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if self.delegate?.webView?(webView, didFinish: navigation) != nil {
            } else {
                self.delegate?.webViewFinishLoad()
            }
            
            if let webView = webView as? WebView, webView.isFirstLoad,
               !webView.fw_reusePreparing {
                webView.isFirstLoad = false
                webView.fw_preloadReusableView()
            }
            
            if let webView = webView as? WebView, webView.fw_reusePreparing {
                webView.reusableViewWillRecycle()
                webView.fw_reusePreparing = false
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            if self.delegate?.webView?(webView, didFailProvisionalNavigation: navigation, withError: error) != nil {
                return
            }
            
            if let webView = webView as? WebView, webView.fw_reusePreparing {
                webView.reusableViewWillRecycle()
                webView.fw_reusePreparing = false
            }
            
            if (error as NSError).code == NSURLErrorCancelled { return }
            self.delegate?.webViewFailLoad(error)
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            if self.delegate?.webView?(webView, didFail: navigation, withError: error) != nil {
                return
            }
            
            if let webView = webView as? WebView, webView.fw_reusePreparing {
                webView.reusableViewWillRecycle()
                webView.fw_reusePreparing = false
            }
            
            if (error as NSError).code == NSURLErrorCancelled { return }
            self.delegate?.webViewFailLoad(error)
        }
        
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            if let webView = webView as? WebView {
                webView.fw_reuseInvalid = true
            }
            
            if self.delegate?.webViewWebContentProcessDidTerminate?(webView) != nil {
                return
            }
            
            // 默认调用reload解决内存过大引起的白屏问题，可重写
            webView.reload()
        }
        
        // MARK: - WKUIDelegate
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            if self.delegate?.webView?(webView, runJavaScriptAlertPanelWithMessage: message, initiatedByFrame: frame, completionHandler: completionHandler) != nil {
                return
            }
            
            webView.fw_showAlert(title: nil, message: message, cancel: nil) {
                completionHandler()
            }
        }
        
        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            if self.delegate?.webView?(webView, runJavaScriptConfirmPanelWithMessage: message, initiatedByFrame: frame, completionHandler: completionHandler) != nil {
                return
            }
            
            webView.fw_showConfirm(title: nil, message: message, cancel: nil, confirm: nil) {
                completionHandler(true)
            } cancelBlock: {
                completionHandler(false)
            }
        }
        
        func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
            if self.delegate?.webView?(webView, runJavaScriptTextInputPanelWithPrompt: prompt, defaultText: defaultText, initiatedByFrame: frame, completionHandler: completionHandler) != nil {
                return
            }
            
            webView.fw_showPrompt(title: nil, message: prompt, cancel: nil, confirm: nil) { textField in
                textField.text = defaultText
            } confirmBlock: { text in
                completionHandler(text)
            } cancelBlock: {
                completionHandler(nil)
            }
        }
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if self.delegate?.responds(to: #selector(WebViewDelegate.webView(_:createWebViewWith:for:windowFeatures:))) ?? false {
                return self.delegate?.webView?(webView, createWebViewWith: configuration, for: navigationAction, windowFeatures: windowFeatures)
            }
            
            if !(navigationAction.targetFrame?.isMainFrame ?? false) {
                if let webView = webView as? WebView, webView.cookieEnabled {
                    webView.load(WebViewCookieManager.fixRequest(navigationAction.request))
                } else {
                    webView.load(navigationAction.request)
                }
            }
            return nil
        }
        
        func webViewDidClose(_ webView: WKWebView) {
            if self.delegate?.webViewDidClose?(webView) != nil {
                return
            }
            
            if let webView = webView as? WebView, webView.allowsWindowClose {
                webView.fw_viewController?.fw_close()
            }
        }
        
    }
    
    /// 事件代理，包含navigationDelegate和UIDelegate
    open weak var delegate: WebViewDelegate? {
        get { return delegateProxy.delegate }
        set { delegateProxy.delegate = newValue }
    }

    /// 是否启用Cookie管理，默认NO未启用
    open var cookieEnabled = false

    /// 进度视图，默认trackTintColor为clear
    open private(set) lazy var progressView: UIProgressView = {
        let result = UIProgressView(frame: .zero)
        result.trackTintColor = .clear
        result.fw_webProgress = 0
        return result
    }()

    /// 是否允许打开通用链接，默认NO
    open var allowsUniversalLinks = false

    /// 是否允许打开Scheme链接(非http|https|file链接)，默认NO
    open var allowsSchemeURL = false
    
    /// 是否允许window.close关闭当前控制器，默认YES
    ///
    /// 如果WebView新开了界面，触发了createWebView回调后，则不会触发。
    /// 解决方案示例：使用JSBridge桥接或URL拦截等方式关闭界面
    open var allowsWindowClose = true

    /// 网页请求，设置后会自动加载，支持NSString|NSURL|NSURLRequest。默认nil
    open var webRequest: Any? {
        didSet {
            fw_loadRequest(webRequest)
        }
    }
    
    /// 是否是第一次加载，第一次加载成功及以前都为true
    open var isFirstLoad = true
    
    /// 设置重用时预缓存资源的url句柄，同一个reuseIdentifier仅生效一次，自动处理堆栈
    public static var reusePreloadUrlBlock: ((String) -> Any?)?
    
    private static var preloadedReuseIdentifiers: [String] = []
    
    private var delegateProxy = WebViewDelegateProxy()
    
    // MARK: - Lifecycle
    public override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        didInitialize()
    }
    
    public convenience init(frame: CGRect) {
        let configuration = WKWebView.fw_defaultConfiguration()
        self.init(frame: frame, configuration: configuration)
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        didInitialize()
    }
    
    private func didInitialize() {
        navigationDelegate = delegateProxy
        uiDelegate = delegateProxy
        allowsBackForwardNavigationGestures = true
        #if DEBUG
        if #available(iOS 16.4, *) {
            isInspectable = true
        }
        #endif
        
        addSubview(progressView)
        progressView.fw_pinEdges(excludingEdge: .bottom)
        progressView.fw_setDimension(.height, size: 2.0)
        fw_observeProperty("estimatedProgress") { webView, _ in
            guard let webView = webView as? WebView else { return }
            webView.progressView.fw_webProgress = Float(webView.estimatedProgress)
        }
        fw_observeProperty("loading") { webView, _ in
            guard let webView = webView as? WebView else { return }
            if !webView.isLoading && webView.progressView.fw_webProgress < 1.0 {
                webView.progressView.fw_webProgress = 1.0
            }
        }
    }
    
    @discardableResult
    open override func load(_ request: URLRequest) -> WKNavigation? {
        if cookieEnabled && (request.url?.scheme?.count ?? 0) > 0 {
            let cookieScript = WKUserScript(source: WebViewCookieManager.ajaxCookieScripts(), injectionTime: .atDocumentStart, forMainFrameOnly: false)
            configuration.userContentController.addUserScript(cookieScript)
            
            if let cookieRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest {
                WebViewCookieManager.syncRequestCookie(cookieRequest)
                return super.load(cookieRequest as URLRequest)
            }
        }
        
        return super.load(request)
    }
    
    // MARK: - ReusableViewProtocol
    /// 即将回收视图，必须调用super
    open override func reusableViewWillRecycle() {
        delegate = nil
        cookieEnabled = false
        allowsUniversalLinks = false
        allowsSchemeURL = false
        webRequest = nil
        isFirstLoad = false
        
        super.reusableViewWillRecycle()
        
        if fw_reusedTimes < 1,
           !fw_reusePreparing,
           let reuseIdentifier = fw_reuseIdentifier,
           !WebView.preloadedReuseIdentifiers.contains(reuseIdentifier),
           let preloadUrl = WebView.reusePreloadUrlBlock?(reuseIdentifier) {
            WebView.preloadedReuseIdentifiers.append(reuseIdentifier)
            
            fw_reusePreparing = true
            reusableViewWillReuse()
            fw_loadRequest(preloadUrl)
        }
    }
    
    /// 即将重用视图，默认重用次数+1，必须调用super
    open override func reusableViewWillReuse() {
        super.reusableViewWillReuse()
        
        isFirstLoad = true
    }
    
}

// MARK: - WebViewCookieManager
/// WKWebView管理Cookie
///
/// [KKJSBridge](https://github.com/karosLi/KKJSBridge)
public class WebViewCookieManager: NSObject {
    
    /// 同步首个请求的Cookie
    public static func syncRequestCookie(_ request: NSMutableURLRequest) {
        guard let url = request.url else { return }
        let availableCookie = HTTPCookieStorage.shared.cookies(for: url)
        guard let availableCookie = availableCookie, !availableCookie.isEmpty else { return }
        
        let reqHeader = HTTPCookie.requestHeaderFields(with: availableCookie)
        if let cookieStr = reqHeader["Cookie"] {
            request.setValue(cookieStr, forHTTPHeaderField: "Cookie")
        }
    }
    
    /// 同步请求的httpOnly Cookie
    public static func syncRequestHttpOnlyCookie(_ request: NSMutableURLRequest) {
        guard let url = request.url else { return }
        let availableCookie = HTTPCookieStorage.shared.cookies(for: url)
        guard let availableCookie = availableCookie, !availableCookie.isEmpty else { return }
        
        var cookieStr = request.value(forHTTPHeaderField: "Cookie") ?? ""
        for cookie in availableCookie {
            if !cookie.isHTTPOnly {
                continue
            }
            cookieStr.append("\(cookie.name)=\(cookie.value);")
        }
        request.setValue(cookieStr, forHTTPHeaderField: "Cookie")
    }
    
    /// 同步ajax请求的Cookie
    public static func ajaxCookieScripts() -> String {
        var cookieScript = ""
        let cookies = HTTPCookieStorage.shared.cookies ?? []
        for cookie in cookies {
            if cookie.value.range(of: "'") != nil {
                continue
            }
            cookieScript.append("document.cookie='\(cookie.name)=\(cookie.value);")
            if !cookie.domain.isEmpty {
                cookieScript.append("domain=\(cookie.domain);")
            }
            if !cookie.path.isEmpty {
                cookieScript.append("path=\(cookie.path);")
            }
            if let expiresDate = cookie.expiresDate {
                cookieScript.append("expires=\(cookieDateFormatter.string(from: expiresDate));")
            }
            if cookie.isSecure {
                cookieScript.append("Secure;")
            }
            if cookie.isHTTPOnly {
                cookieScript.append("HTTPOnly;")
            }
            cookieScript.append("'\n")
        }
        return cookieScript
    }
    
    /// 同步重定向请求的Cookie
    public static func fixRequest(_ request: URLRequest) -> URLRequest {
        var array = [String]()
        if let url = request.url, let cookies = HTTPCookieStorage.shared.cookies(for: url) {
            for cookie in cookies {
                let value = "\(cookie.name)=\(cookie.value)"
                array.append(value)
            }
        }
        
        var fixedRequest = request
        let cookie = array.joined(separator: ";")
        fixedRequest.setValue(cookie, forHTTPHeaderField: "Cookie")
        return fixedRequest
    }
    
    /// 拷贝共享Cookie到webView，iOS11+有效
    public static func copySharedCookie(_ webView: WKWebView, completion: (() -> Void)? = nil) {
        let cookies = HTTPCookieStorage.shared.cookies ?? []
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        if cookies.isEmpty {
            completion?()
            return
        }
        for (index, cookie) in cookies.enumerated() {
            cookieStore.setCookie(cookie) {
                if index == cookies.count - 1 {
                    completion?()
                }
            }
        }
    }
    
    /// 拷贝webView到共享Cookie，iOS11+有效
    public static func copyWebViewCookie(_ webView: WKWebView, completion: (() -> Void)? = nil) {
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        cookieStore.getAllCookies { cookies in
            if cookies.isEmpty {
                completion?()
                return
            }
            for (index, cookie) in cookies.enumerated() {
                HTTPCookieStorage.shared.setCookie(cookie)
                if index == cookies.count - 1 {
                    completion?()
                }
            }
        }
    }
    
    /// Cookie日期格式化对象
    public static var cookieDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss zzz"
        return formatter
    }()
    
}

// MARK: - WebViewJSBridge
/**
 WKWebView实现Javascript桥接器
 
 参考链接：
 [WKWebViewJavascriptBridge](https://github.com/Lision/WKWebViewJavascriptBridge)
 
 Javascript示例：
 (兼容FWFramework/[WK]WebViewJavascriptBridge)
 ```javascript
 function setupWebViewJavascriptBridge(callback) {
     if (window.webkit &&
         window.webkit.messageHandlers &&
         window.webkit.messageHandlers.iOS_Native_InjectJavascript) {
         if (window.WKWebViewJavascriptBridge) { return callback(WKWebViewJavascriptBridge); }
         if (window.WKWVJBCallbacks) { return window.WKWVJBCallbacks.push(callback); }
         window.WKWVJBCallbacks = [callback];
         window.webkit.messageHandlers.iOS_Native_InjectJavascript.postMessage(null);
         return;
     }
 
     if (window.WebViewJavascriptBridge) { return callback(WebViewJavascriptBridge); }
     if (window.WVJBCallbacks) { return window.WVJBCallbacks.push(callback); }
     window.WVJBCallbacks = [callback];
     var WVJBIframe = document.createElement('iframe');
     WVJBIframe.style.display = 'none';
     WVJBIframe.src = 'https://__bridge_loaded__';
     document.documentElement.appendChild(WVJBIframe);
     setTimeout(function() { document.documentElement.removeChild(WVJBIframe) }, 0)
 }
 
 setupWebViewJavascriptBridge(function(bridge) {
     bridge.registerHandler('jsHandler', function(data, responseCallback) {
         var responseData = {'key': 'value'}
         responseCallback(responseData)
     })
 
     bridge.callHandler('iosHandler', {'key': 'value'}, function(response) {
         console.log(response)
     })
 })
 ```
 */
public class WebViewJSBridge: NSObject, WKScriptMessageHandler {
    
    // MARK: - Typealias
    /// JS桥接上下文
    public class Context: NSObject {
        /// 自定义对象
        public fileprivate(set) weak var object: AnyObject?
        /// 绑定WKWebView
        public fileprivate(set) weak var webView: WKWebView?
        
        /// 调用方法名称
        public private(set) var handlerName: String
        /// 调用参数
        public private(set) var parameters: [String: Any]
        /// 完成回调
        public private(set) var completion: ((Any?) -> Void)?
        
        /// 初始化方法
        public init(handlerName: String, parameters: [String: Any]? = nil, completion: ((Any?) -> Void)? = nil) {
            self.handlerName = handlerName
            self.parameters = parameters ?? [:]
            self.completion = completion
        }
    }
    
    /// JS桥接处理句柄
    public typealias Handler = (Context) -> Void
    /// JS桥接完成回调
    public typealias Completion = (Any?) -> Void
    /// JS桥接消息对象
    public typealias Message = [String: Any]
    
    private class Proxy: NSObject, WKScriptMessageHandler {
        weak var delegate: WKScriptMessageHandler?
        
        init(delegate: WKScriptMessageHandler) {
            super.init()
            self.delegate = delegate
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            delegate?.userContentController(userContentController, didReceive: message)
        }
    }
    
    /// 是否启用日志，默认false
    public var isLogEnabled = false
    
    private let iOS_Native_InjectJavascript = "iOS_Native_InjectJavascript"
    private let iOS_Native_FlushMessageQueue = "iOS_Native_FlushMessageQueue"
    
    private weak var webView: WKWebView?
    
    private var startupMessageQueue: [Message]? = []
    private var responseCallbacks = [String: Completion]()
    private var messageHandlers = [String: Handler]()
    private var errorHandler: Handler?
    private var filterHandler: ((Context) -> Bool)?
    private var uniqueId = 0
    
    public init(webView: WKWebView) {
        super.init()
        self.webView = webView
        addScriptMessageHandlers()
    }
    
    deinit {
        removeScriptMessageHandlers()
        
        #if DEBUG
        Logger.debug(group: Logger.fw_moduleName, "%@ did dealloc", NSStringFromClass(self.classForCoder))
        #endif
    }
    
    // MARK: - Public
    /// 注册JS桥接处理类或对象
    ///
    /// - Parameters:
    ///   - clazz: JS桥接处理类或对象
    ///   - package: 桥接包名，默认nil。示例：app.
    ///   - object: 自定义上下文，可通过context.object访问，示例：WebView控制器
    ///   - mapper: 自定义映射，默认nil时查找规则：xxxBridge:
    public func registerClass(_ clazz: Any, package: String? = nil, context object: AnyObject? = nil, mapper: (([String]) -> [String: String])? = nil) {
        let bridges = getClassBridges(clazz, mapper: mapper)
        if let targetClass = clazz as? NSObject.Type {
            for (key, obj) in bridges {
                let name = (package ?? "") + key
                registerHandler(name) { [weak object] context in
                    context.object = object
                    _ = targetClass.perform(NSSelectorFromString(obj), with: context)
                }
            }
        } else if let targetObject = clazz as? NSObject {
            for (key, obj) in bridges {
                let name = (package ?? "") + key
                registerHandler(name) { [weak object] context in
                    context.object = object
                    _ = targetObject.perform(NSSelectorFromString(obj), with: context)
                }
            }
        }
    }
    
    /// 取消注册指定JS桥接处理类或对象
    ///
    /// - Parameters:
    ///   - clazz: JS桥接处理类或对象
    ///   - package: 桥接包名，默认nil。示例：app.
    ///   - mapper: 自定义映射，默认nil时查找规则：xxxBridge:
    public func unregisterClass(_ clazz: Any, package: String? = nil, mapper: (([String]) -> [String: String])? = nil) {
        let bridges = getClassBridges(clazz, mapper: mapper)
        for (key, _) in bridges {
            let name = (package ?? "") + key
            removeHandler(name)
        }
    }
    
    /// 注册指定名称处理句柄
    public func registerHandler(_ handlerName: String, handler: @escaping Handler) {
        messageHandlers[handlerName] = handler
    }
    
    /// 移除指定名称处理句柄
    public func removeHandler(_ handlerName: String) {
        messageHandlers.removeValue(forKey: handlerName)
    }
    
    /// 获取所有已注册处理句柄的名称
    public func getRegisteredHandlers() -> [String] {
        return Array(messageHandlers.keys)
    }
    
    /// 设置错误处理句柄，句柄未找到时触发
    public func setErrorHandler(_ handler: Handler?) {
        errorHandler = handler
    }
    
    /// 注册过滤器句柄，句柄访问时优先触发。如果返回true，继续处理handler，否则停止处理
    public func setFilterHandler(_ handler: ((Context) -> Bool)?) {
        filterHandler = handler
    }
    
    /// 调用JS端已注册的句柄，完成后回调
    public func callHandler(_ handlerName: String, data: Any? = nil, callback: Completion? = nil) {
        send(handlerName: handlerName, data: data, callback: callback)
    }
    
    /// 重置JS桥接队列
    public func reset() {
        startupMessageQueue = nil
        responseCallbacks = [String: Completion]()
        uniqueId = 0
    }
    
    // MARK: - WKScriptMessageHandler
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == iOS_Native_InjectJavascript {
            injectJavascriptFile()
        }
        
        if message.name == iOS_Native_FlushMessageQueue {
            flushMessageQueue()
        }
    }
    
    // MARK: - Private
    private func getClassBridges(_ clazz: Any, mapper: (([String]) -> [String: String])?) -> [String: String] {
        guard let metaClass = NSObject.fw_metaClass(clazz) else {
            return [:]
        }
        
        let methods = NSObject.fw_classMethods(metaClass)
        if let mapper = mapper {
            return mapper(methods)
        }
        
        var bridges: [String: String] = [:]
        for method in methods {
            guard method.hasSuffix("Bridge:"),
                  method.components(separatedBy: ":").count == 2 else {
                continue
            }
            
            let name = method.replacingOccurrences(of: "Bridge:", with: "")
            bridges[name] = method
        }
        return bridges
    }
    
    private func flushMessageQueue() {
        webView?.evaluateJavaScript("WKWebViewJavascriptBridge._fetchQueue();") { (result, error) in
            if error != nil {
                if self.isLogEnabled {
                    self.log("WARNING: Error when trying to fetch data from WKWebView: \(String(describing: error))")
                }
            }
            
            guard let resultStr = result as? String else { return }
            self.flush(messageQueueString: resultStr)
        }
    }
    
    private func addScriptMessageHandlers() {
        webView?.configuration.userContentController.add(Proxy(delegate: self), name: iOS_Native_InjectJavascript)
        webView?.configuration.userContentController.add(Proxy(delegate: self), name: iOS_Native_FlushMessageQueue)
    }
    
    private func removeScriptMessageHandlers() {
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: iOS_Native_InjectJavascript)
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: iOS_Native_FlushMessageQueue)
    }
    
    private func send(handlerName: String, data: Any?, callback: Completion?) {
        var message = [String: Any]()
        message["handlerName"] = handlerName
        
        if data != nil {
            message["data"] = data
        }
        
        if callback != nil {
            uniqueId += 1
            let callbackID = "native_iOS_cb_\(uniqueId)"
            responseCallbacks[callbackID] = callback
            message["callbackID"] = callbackID
        }
        
        queue(message: message)
    }
    
    private func flush(messageQueueString: String) {
        guard let messages = deserialize(messageJSON: messageQueueString) else {
            if isLogEnabled {
                log("WARNING: " + messageQueueString)
            }
            return
        }
        
        for message in messages {
            if isLogEnabled {
                log("RCVD: \(message)")
            }
            
            if let responseID = message["responseID"] as? String {
                guard let callback = responseCallbacks[responseID] else { continue }
                callback(message["responseData"])
                responseCallbacks.removeValue(forKey: responseID)
            } else {
                guard let handlerName = message["handlerName"] as? String else { continue }
                
                var callback: Completion?
                if let callbackID = message["callbackID"] {
                    callback = { responseData in
                        let msg = ["responseID": callbackID, "responseData": responseData ?? NSNull()] as Message
                        self.queue(message: msg)
                    }
                } else {
                    callback = { ignoreResponseData in
                        // Do nothing
                    }
                }
                
                let context = Context(handlerName: handlerName, parameters: message["data"] as? [String : Any], completion: callback)
                context.webView = webView
                
                if let filterHandler = filterHandler {
                    if !filterHandler(context) { continue }
                }
                
                if let handler = messageHandlers[handlerName] {
                    handler(context)
                } else {
                    if isLogEnabled {
                        log("WARNING: NoHandlerException, No handler for message from JS: \(message)")
                    }
                    
                    errorHandler?(context)
                }
            }
        }
    }
    
    private func queue(message: Message) {
        if startupMessageQueue == nil {
            dispatch(message: message)
        } else {
            startupMessageQueue?.append(message)
        }
    }
    
    private func dispatch(message: Message) {
        guard var messageJSON = serialize(message: message, pretty: false) else { return }
        if isLogEnabled {
            log("SEND: \(messageJSON)")
        }
        
        messageJSON = messageJSON.replacingOccurrences(of: "\\", with: "\\\\")
        messageJSON = messageJSON.replacingOccurrences(of: "\"", with: "\\\"")
        messageJSON = messageJSON.replacingOccurrences(of: "\'", with: "\\\'")
        messageJSON = messageJSON.replacingOccurrences(of: "\n", with: "\\n")
        messageJSON = messageJSON.replacingOccurrences(of: "\r", with: "\\r")
        messageJSON = messageJSON.replacingOccurrences(of: "\u{000C}", with: "\\f")
        messageJSON = messageJSON.replacingOccurrences(of: "\u{2028}", with: "\\u2028")
        messageJSON = messageJSON.replacingOccurrences(of: "\u{2029}", with: "\\u2029")
        
        let javascriptCommand = "WKWebViewJavascriptBridge._handleMessageFromiOS('\(messageJSON)');"
        if Thread.current.isMainThread {
            evaluateJavascript(javascript: javascriptCommand)
        } else {
            DispatchQueue.main.async {
                self.evaluateJavascript(javascript: javascriptCommand)
            }
        }
    }
    
    private func serialize(message: Message, pretty: Bool) -> String? {
        var result: String?
        do {
            let data = try JSONSerialization.data(withJSONObject: message, options: pretty ? .prettyPrinted : JSONSerialization.WritingOptions(rawValue: 0))
            result = String(data: data, encoding: .utf8)
        } catch let error {
            if isLogEnabled {
                log("ERROR: \(error)")
            }
        }
        return result
    }
    
    private func deserialize(messageJSON: String) -> [Message]? {
        var result: [Message]?
        guard let data = messageJSON.data(using: .utf8) else { return nil }
        do {
            result = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [Message]
        } catch let error {
            if isLogEnabled {
                log("ERROR: \(error)")
            }
        }
        return result
    }
    
    private func log(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        Logger.debug(group: Logger.fw_moduleName, "WKWebViewJavascriptBridge: %@", message, function: function, file: file, line: line)
        #endif
    }
    
    private func evaluateJavascript(javascript: String, completion: ((Any?, Error?) -> Void)? = nil) {
        webView?.evaluateJavaScript(javascript, completionHandler: completion)
    }
    
    private func injectJavascriptFile() {
        let js = javascriptBridgeJS
        evaluateJavascript(javascript: js, completion: { [weak self] (_, error) in
            guard let self = self else { return }
            if let error = error {
                self.log("ERROR: \(error)")
                return
            }
            self.startupMessageQueue?.forEach({ (message) in
                self.dispatch(message: message)
            })
            self.startupMessageQueue = nil
        })
    }
    
    private let javascriptBridgeJS = """
;(function() {
    if (window.WKWebViewJavascriptBridge) {
        return;
    }

    if (!window.onerror) {
        window.onerror = function(msg, url, line) {
            console.log("WKWebViewJavascriptBridge: ERROR:" + msg + "@" + url + ":" + line);
        }
    }
    window.WKWebViewJavascriptBridge = {
        registerHandler: registerHandler,
        removeHandler: removeHandler,
        getRegisteredHandlers: getRegisteredHandlers,
        setErrorHandler: setErrorHandler,
        setFilterHandler: setFilterHandler,
        callHandler: callHandler,
        _fetchQueue: _fetchQueue,
        _handleMessageFromiOS: _handleMessageFromiOS
    };

    var sendMessageQueue = [];
    var messageHandlers = {};
    var errorHandler = null;
    var filterHandler = null;

    var responseCallbacks = {};
    var uniqueId = 1;

    function registerHandler(handlerName, handler) {
        messageHandlers[handlerName] = handler;
    }

    function removeHandler(handlerName) {
        delete messageHandlers[handlerName];
    }
    
    function getRegisteredHandlers() {
        var registeredHandlers = [];
        for (handlerName in messageHandlers) {
            registeredHandlers.push(handlerName);
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

    function _doSend(message, responseCallback) {
        if (responseCallback) {
            var callbackID = 'cb_'+(uniqueId++)+'_'+new Date().getTime();
            responseCallbacks[callbackID] = responseCallback;
            message['callbackID'] = callbackID;
        }
        sendMessageQueue.push(message);
        window.webkit.messageHandlers.iOS_Native_FlushMessageQueue.postMessage(null)
    }

    function _fetchQueue() {
        var messageQueueString = JSON.stringify(sendMessageQueue);
        sendMessageQueue = [];
        return messageQueueString;
    }

    function _dispatchMessageFromiOS(messageJSON) {
        var message = JSON.parse(messageJSON);
        var responseCallback;

        if (message.responseID) {
            responseCallback = responseCallbacks[message.responseID];
            if (!responseCallback) {
                return;
            }
            responseCallback(message.responseData);
            delete responseCallbacks[message.responseID];
        } else {
            if (message.callbackID) {
                var callbackResponseId = message.callbackID;
                responseCallback = function(responseData) {
                    _doSend({ handlerName:message.handlerName, responseID:callbackResponseId, responseData:responseData });
                };
            } else {
                responseCallback = function(ignoreResponseData) {};
            }

            if (filterHandler) {
                var filterResult = filterHandler(message.handlerName, message.data, responseCallback);
                if (!filterResult) { return; }
            }

            var handler = messageHandlers[message.handlerName];
            if (!handler) {
                console.log("WKWebViewJavascriptBridge: WARNING: no handler for message from iOS:", message);
                if (errorHandler) {
                    errorHandler(message.handlerName, message.data, responseCallback);
                }
            } else {
                handler(message.data, responseCallback);
            }
        }
    }

    function _handleMessageFromiOS(messageJSON) {
        _dispatchMessageFromiOS(messageJSON);
    }

    setTimeout(_callWVJBCallbacks, 0);
    function _callWVJBCallbacks() {
        var callbacks = window.WKWVJBCallbacks;
        delete window.WKWVJBCallbacks;
        for (var i = 0; i < callbacks.length; i++) {
            callbacks[i](WKWebViewJavascriptBridge);
        }
    }
})();
"""
    
}

// MARK: - WKWebView+WebView
@_spi(FW) extension WKWebView {
    
    // MARK: - ReusableViewProtocol
    /// 重用WebView全局配置句柄(第二个参数为重用标志)，为所有复用WebView提供预先的默认configuration
    public class var fw_reuseConfigurationBlock: ((WKWebViewConfiguration, String) -> Void)? {
        get { return self.fw_property(forName: "fw_reuseConfigurationBlock") as? (WKWebViewConfiguration, String) -> Void }
        set { self.fw_setPropertyCopy(newValue, forName: "fw_reuseConfigurationBlock") }
    }
    
    /// 初始化WKWebView可重用视图
    open override class func reusableViewInitialize(reuseIdentifier: String) -> Self {
        let configuration = WKWebView.fw_defaultConfiguration()
        self.fw_reuseConfigurationBlock?(configuration, reuseIdentifier)
        return self.init(frame: .zero, configuration: configuration)
    }
    
    /// 即将回收视图，必须调用super
    open override func reusableViewWillRecycle() {
        super.reusableViewWillRecycle()
        
        fw_jsBridge = nil
        fw_jsBridgeEnabled = false
        fw_navigationItems = nil
        guard fw_reusedTimes > 0 else { return }
        
        scrollView.delegate = nil
        scrollView.isScrollEnabled = true
        stopLoading()
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        evaluateJavaScript("window.sessionStorage.clear();", completionHandler: nil)
        configuration.userContentController.removeAllUserScripts()
        load(URLRequest(url: NSURL() as URL))
    }
    
    /// 即将重用视图，默认重用次数+1，必须调用super
    open override func reusableViewWillReuse() {
        super.reusableViewWillReuse()
        
        fw_clearBackForwardList()
    }
    
    // MARK: - WebView
    /// 默认跨WKWebView共享Cookie，切换用户时可重置processPool清空Cookie
    public static var fw_processPool = WKProcessPool()
    
    /// 快捷创建WKWebView默认配置，自动初始化User-Agent和共享processPool
    public static func fw_defaultConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.applicationNameForUserAgent = fw_extensionUserAgent
        configuration.processPool = fw_processPool
        return configuration
    }
    
    /// 获取默认浏览器UserAgent，包含应用信息，示例：Mozilla/5.0 (iPhone; CPU OS 14_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Safari/605.1.15 Example/1.0.0
    public static var fw_browserUserAgent: String {
        let platformUserAgent = String(format: "Mozilla/5.0 (%@; CPU OS %@ like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko)", UIDevice.current.model, UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_"))
        let userAgent = String(format: "%@ %@", platformUserAgent, fw_extensionUserAgent)
        return userAgent
    }

    /// 获取默认浏览器扩展UserAgent，不含平台信息，可用于applicationNameForUserAgent，示例：Mobile/15E148 Safari/605.1.15 Example/1.0.0
    public static var fw_extensionUserAgent: String {
        let userAgent = String(format: "Mobile/15E148 Safari/605.1.15 %@/%@", UIApplication.fw_appExecutable, UIApplication.fw_appVersion)
        return userAgent
    }

    /// 获取默认请求UserAgent，可用于网络请求，示例：Example/1.0.0 (iPhone; iOS 14.2; Scale/3.00)
    public static var fw_requestUserAgent: String {
        let userAgent = String(format: "%@/%@ (%@; iOS %@; Scale/%0.2f)", UIApplication.fw_appExecutable, UIApplication.fw_appVersion, UIDevice.current.model, UIDevice.current.systemVersion, UIScreen.main.scale)
        return userAgent
    }
    
    /// 获取当前UserAgent，未自定义时为默认，示例：Mozilla/5.0 (iPhone; CPU OS 14_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148
    public var fw_userAgent: String {
        if let userAgent = customUserAgent, !userAgent.isEmpty {
            return userAgent
        }
        if let userAgent = fw_invokeGetter("userAgent") as? String, !userAgent.isEmpty {
            return userAgent
        }
        return WKWebView.fw_browserUserAgent
    }
    
    /// 加载网页请求，支持String|URL|URLRequest等
    @discardableResult
    public func fw_loadRequest(_ request: Any?) -> WKNavigation? {
        guard let request = request else { return nil }
        if let urlRequest = request as? URLRequest {
            return load(urlRequest)
        }
        
        var requestUrl = request as? URL
        if requestUrl == nil, let urlString = request as? String {
            requestUrl = URL.fw_url(string: urlString)
        }
        guard let requestUrl = requestUrl else { return nil }
        
        if requestUrl.isFileURL {
            if let htmlString = try? String(contentsOf: requestUrl, encoding: .utf8) {
                return loadHTMLString(htmlString, baseURL: requestUrl)
            }
        } else {
            return load(URLRequest(url: requestUrl))
        }
        return nil
    }
    
    /// 清空网页缓存，完成后回调。单个网页请求指定URLRequest.cachePolicy即可
    public static func fw_clearCache(_ completion: (() -> Void)? = nil) {
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        let sinceDate = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: sinceDate) {
            completion?()
        }
    }
    
    /// 清空WebView后退和前进的网页栈
    public func fw_clearBackForwardList() {
        let selector = NSSelectorFromString(String(format: "%@%@%@", "_r", "emoveA", "llItems"))
        if backForwardList.responds(to: selector) {
            backForwardList.perform(selector)
        }
    }
    
    /// 使用JavaScriptCore执行脚本并返回结果，支持模板替换。常用语服务端下发计算公式等场景
    public static func fw_evaluateScript(_ script: String, variables: [String: String] = [:]) -> JSValue? {
        var javascript = script
        if !variables.isEmpty {
            for (key, value) in variables {
                javascript = javascript.replacingOccurrences(of: key, with: value)
            }
        }
        
        let context = JSContext()
        let value = context?.evaluateScript(javascript)
        return value
    }
    
    /// 设置Javascript桥接器强引用属性，防止使用过程中被释放
    public var fw_jsBridge: WebViewJSBridge? {
        get { fw_property(forName: "fw_jsBridge") as? WebViewJSBridge }
        set { fw_setProperty(newValue, forName: "fw_jsBridge") }
    }
    
    /// 是否启用Javascript桥接器，需结合setupJsBridge使用
    public var fw_jsBridgeEnabled: Bool {
        get { fw_propertyBool(forName: "fw_jsBridgeEnabled") }
        set { fw_setPropertyBool(newValue, forName: "fw_jsBridgeEnabled") }
    }
    
    /// 自动初始化Javascript桥接器，jsBridgeEnabled开启时生效
    @discardableResult
    public func fw_setupJsBridge() -> WebViewJSBridge? {
        guard fw_jsBridgeEnabled else { return nil }
        let jsBridge = WebViewJSBridge(webView: self)
        self.fw_jsBridge = jsBridge
        return jsBridge
    }
    
    /// 绑定控制器导航栏左侧按钮组，需结合setupNavigationItems使用
    public var fw_navigationItems: [Any]? {
        get { fw_property(forName: "fw_navigationItems") as? [Any] }
        set { fw_setProperty(newValue, forName: "fw_navigationItems") }
    }
    
    /// 自动初始化控制器导航栏左侧按钮组，navigationItems设置后生效
    public func fw_setupNavigationItems(_ viewController: UIViewController) {
        guard let navigationItems = fw_navigationItems,
              !navigationItems.isEmpty,
              let navigationController = viewController.navigationController else { return }
        
        var leftItems: [UIBarButtonItem] = []
        for (i, navigationItem) in navigationItems.enumerated() {
            if let leftItem = navigationItem as? UIBarButtonItem {
                leftItems.append(leftItem)
            } else {
                if i == 0 {
                    let leftItem = UIBarButtonItem.fw_item(object: navigationItem) { [weak self, weak viewController] _ in
                        if self?.canGoBack ?? false {
                            self?.goBack()
                        } else {
                            if let navigationController = viewController?.navigationController,
                               navigationController.popViewController(animated: true) != nil    {
                                return
                            }
                            if viewController?.presentingViewController != nil {
                                viewController?.dismiss(animated: true, completion: nil)
                                return
                            }
                            
                            if let firstItem = self?.backForwardList.backList.first {
                                self?.go(to: firstItem)
                            }
                        }
                    }
                    leftItems.append(leftItem)
                } else {
                    let leftItem = UIBarButtonItem.fw_item(object: navigationItem) { [weak self, weak viewController] _ in
                        if let navigationController = viewController?.navigationController,
                           navigationController.popViewController(animated: true) != nil    {
                            return
                        }
                        if viewController?.presentingViewController != nil {
                            viewController?.dismiss(animated: true, completion: nil)
                            return
                        }
                        
                        if let firstItem = self?.backForwardList.backList.first {
                            self?.go(to: firstItem)
                        }
                    }
                    leftItems.append(leftItem)
                }
            }
        }
        
        var showClose = true
        if navigationController.viewControllers.first == viewController,
           navigationController.presentingViewController?.presentedViewController != navigationController {
            showClose = false
        }
        viewController.navigationItem.leftBarButtonItems = showClose && leftItems.count > 0 ? [leftItems[0]]  : []
        fw_observeProperty("canGoBack") { [weak viewController] webView, _ in
            guard let webView = webView as? WKWebView else { return }
            if webView.canGoBack {
                viewController?.navigationItem.leftBarButtonItems = leftItems
            } else {
                viewController?.navigationItem.leftBarButtonItems = showClose && leftItems.count > 0 ? [leftItems[0]]  : []
            }
        }
    }
    
}

// MARK: - UIProgressView+WebView
@_spi(FW) extension UIProgressView {
    
    /// 设置Web加载进度，0和1自动切换隐藏。可设置trackTintColor为clear，隐藏背景色
    public var fw_webProgress: Float {
        get {
            return self.progress
        }
        set {
            if newValue <= 0 {
                self.alpha = 0
            } else if newValue > 0 && newValue < 1.0 {
                if self.alpha == 0 {
                    self.progress = 0
                    UIView.animate(withDuration: 0.2) {
                        self.alpha = 1.0
                    }
                }
            } else {
                self.alpha = 1.0
                UIView.animate(withDuration: 0.2) {
                    self.alpha = 0
                } completion: { _ in
                    self.progress = 0
                }
            }
            self.setProgress(newValue, animated: true)
        }
    }
    
}
