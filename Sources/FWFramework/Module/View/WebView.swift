//
//  WebView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
import WebKit
import JavaScriptCore

// MARK: - Wrapper+WKWebView
@MainActor extension Wrapper where Base: WKWebView {
    /// 重用WebView全局配置句柄(第二个参数为重用标志)，为所有复用WebView提供预先的默认configuration
    public static var reuseConfigurationBlock: ((WKWebViewConfiguration, String) -> Void)? {
        get { return NSObject.fw.getAssociatedObject(Base.self, key: #function) as? (WKWebViewConfiguration, String) -> Void }
        set { NSObject.fw.setAssociatedObject(Base.self, key: #function, value: newValue, policy: .OBJC_ASSOCIATION_COPY_NONATOMIC) }
    }
    
    /// 默认跨WKWebView共享Cookie，切换用户时可重置processPool清空Cookie
    public static var processPool: WKProcessPool {
        get { return WKWebView.innerProcessPool }
        set { WKWebView.innerProcessPool = newValue }
    }
    
    /// 快捷创建WKWebView默认配置，自动初始化User-Agent和共享processPool
    public static func defaultConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.applicationNameForUserAgent = extensionUserAgent
        configuration.processPool = processPool
        return configuration
    }
    
    /// 获取默认浏览器UserAgent，包含应用信息，示例：Mozilla/5.0 (iPhone; CPU OS 14_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Safari/605.1.15 Example/1.0.0
    public static var browserUserAgent: String {
        let platformUserAgent = String(format: "Mozilla/5.0 (%@; CPU OS %@ like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko)", UIDevice.current.model, UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_"))
        let userAgent = String(format: "%@ %@", platformUserAgent, extensionUserAgent)
        return userAgent
    }

    /// 获取默认浏览器扩展UserAgent，不含平台信息，可用于applicationNameForUserAgent，示例：Mobile/15E148 Safari/605.1.15 Example/1.0.0
    public static var extensionUserAgent: String {
        let userAgent = String(format: "Mobile/15E148 Safari/605.1.15 %@/%@", UIApplication.fw.appExecutable, UIApplication.fw.appVersion)
        return userAgent
    }

    /// 获取默认请求UserAgent，可用于网络请求，示例：Example/1.0.0 (iPhone; iOS 14.2; Scale/3.00)
    public static var requestUserAgent: String {
        let userAgent = String(format: "%@/%@ (%@; iOS %@; Scale/%0.2f)", UIApplication.fw.appExecutable, UIApplication.fw.appVersion, UIDevice.current.model, UIDevice.current.systemVersion, UIScreen.main.scale)
        return userAgent
    }
    
    /// 获取当前UserAgent，未自定义时为默认，示例：Mozilla/5.0 (iPhone; CPU OS 14_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148
    public var userAgent: String {
        if let userAgent = base.customUserAgent, !userAgent.isEmpty {
            return userAgent
        }
        if let userAgent = invokeGetter("userAgent") as? String, !userAgent.isEmpty {
            return userAgent
        }
        return WKWebView.fw.browserUserAgent
    }
    
    /// 加载网页请求，支持String|URL|URLRequest等
    @discardableResult
    public func loadRequest(_ request: Any?) -> WKNavigation? {
        guard let request = request else { return nil }
        if let urlRequest = request as? URLRequest {
            return base.load(urlRequest)
        }
        
        var requestUrl = request as? URL
        if requestUrl == nil, let urlString = request as? String {
            requestUrl = URL.fw.url(string: urlString)
        }
        guard let requestUrl = requestUrl else { return nil }
        
        if requestUrl.isFileURL {
            if let htmlString = try? String(contentsOf: requestUrl, encoding: .utf8) {
                return base.loadHTMLString(htmlString, baseURL: requestUrl)
            }
        } else {
            return base.load(URLRequest(url: requestUrl))
        }
        return nil
    }
    
    /// 清空网页缓存，完成后回调。单个网页请求指定URLRequest.cachePolicy即可
    public static func clearCache(_ completion: (() -> Void)? = nil) {
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        let sinceDate = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: sinceDate) {
            completion?()
        }
    }
    
    /// 清空WebView后退和前进的网页栈
    public func clearBackForwardList() {
        let selector = NSSelectorFromString(String(format: "%@%@%@", "_r", "emoveA", "llItems"))
        if base.backForwardList.responds(to: selector) {
            base.backForwardList.perform(selector)
        }
    }
    
    /// 使用JavaScriptCore执行脚本并返回结果，支持模板替换。常用语服务端下发计算公式等场景
    nonisolated public static func evaluateScript(_ script: String, variables: [String: String] = [:]) -> JSValue? {
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
    public var jsBridge: WebViewJSBridge? {
        get { property(forName: "jsBridge") as? WebViewJSBridge }
        set { setProperty(newValue, forName: "jsBridge") }
    }
    
    /// 是否启用Javascript桥接器，需结合setupJsBridge使用
    public var jsBridgeEnabled: Bool {
        get { propertyBool(forName: "jsBridgeEnabled") }
        set { setPropertyBool(newValue, forName: "jsBridgeEnabled") }
    }
    
    /// 自动初始化Javascript桥接器，jsBridgeEnabled开启时生效
    @discardableResult
    public func setupJsBridge() -> WebViewJSBridge? {
        guard jsBridgeEnabled else { return nil }
        let bridge = WebViewJSBridge(webView: base)
        jsBridge = bridge
        return bridge
    }
    
    /// 绑定控制器导航栏左侧按钮组，需结合setupNavigationItems使用
    public var navigationItems: [Any]? {
        get { property(forName: "navigationItems") as? [Any] }
        set { setProperty(newValue, forName: "navigationItems") }
    }
    
    /// 自动初始化控制器导航栏左侧按钮组，navigationItems设置后生效
    public func setupNavigationItems(_ viewController: UIViewController) {
        guard let navigationItems = navigationItems,
              !navigationItems.isEmpty,
              let navigationController = viewController.navigationController else { return }
        
        var leftItems: [UIBarButtonItem] = []
        for (i, navigationItem) in navigationItems.enumerated() {
            if let leftItem = navigationItem as? UIBarButtonItem {
                leftItems.append(leftItem)
            } else {
                if i == 0 {
                    let leftItem = UIBarButtonItem.fw.item(object: navigationItem) { [weak base, weak viewController] _ in
                        if base?.canGoBack ?? false {
                            base?.goBack()
                        } else {
                            if let navigationController = viewController?.navigationController,
                               navigationController.popViewController(animated: true) != nil    {
                                return
                            }
                            if viewController?.presentingViewController != nil {
                                viewController?.dismiss(animated: true, completion: nil)
                                return
                            }
                            
                            if let firstItem = base?.backForwardList.backList.first {
                                base?.go(to: firstItem)
                            }
                        }
                    }
                    leftItems.append(leftItem)
                } else {
                    let leftItem = UIBarButtonItem.fw.item(object: navigationItem) { [weak base, weak viewController] _ in
                        if let navigationController = viewController?.navigationController,
                           navigationController.popViewController(animated: true) != nil    {
                            return
                        }
                        if viewController?.presentingViewController != nil {
                            viewController?.dismiss(animated: true, completion: nil)
                            return
                        }
                        
                        if let firstItem = base?.backForwardList.backList.first {
                            base?.go(to: firstItem)
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
        observeProperty(\.canGoBack) { [weak viewController] webView, _ in
            DispatchQueue.fw.mainAsync { [weak viewController] in
                if webView.canGoBack {
                    viewController?.navigationItem.leftBarButtonItems = leftItems
                } else {
                    viewController?.navigationItem.leftBarButtonItems = showClose && leftItems.count > 0 ? [leftItems[0]]  : []
                }
            }
        }
    }
}

// MARK: - Wrapper+UIProgressView
@MainActor extension Wrapper where Base: UIProgressView {
    /// 设置Web加载进度，0和1自动切换隐藏。可设置trackTintColor为clear，隐藏背景色
    public var webProgress: Float {
        get {
            return base.progress
        }
        set {
            if newValue <= 0 {
                base.alpha = 0
            } else if newValue > 0 && newValue < 1.0 {
                if base.alpha == 0 {
                    base.progress = 0
                    let strongBase = base
                    UIView.animate(withDuration: 0.2) {
                        strongBase.alpha = 1.0
                    }
                }
            } else {
                base.alpha = 1.0
                let strongBase = base
                UIView.animate(withDuration: 0.2) {
                    strongBase.alpha = 0
                } completion: { _ in
                    strongBase.progress = 0
                }
            }
            base.setProgress(newValue, animated: true)
        }
    }
}

// MARK: - WebView
/// WebView事件代理协议
@MainActor public protocol WebViewDelegate: WKNavigationDelegate, WKUIDelegate {
    
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
    
    /// 事件代理，包含navigationDelegate和UIDelegate
    open weak var delegate: WebViewDelegate? {
        get { return delegateProxy.delegate }
        set {
            delegateProxy.delegate = newValue
            navigationDelegate = delegateProxy
            uiDelegate = delegateProxy
        }
    }

    /// 是否启用Cookie管理，默认false未启用
    open var cookieEnabled = false

    /// 进度视图，默认trackTintColor为clear
    open private(set) lazy var progressView: UIProgressView = {
        let result = UIProgressView(frame: .zero)
        result.trackTintColor = .clear
        result.fw.webProgress = 0
        return result
    }()
    
    /// 配置允许外部打开的Scheme数组，默认空
    open var allowsUrlSchemes: [String] = []
    
    /// 配置允许路由打开的Scheme数组，默认空
    open var allowsRouterSchemes: [String] = []
    
    /// 配置允许下载的url句柄(iOS14.5+生效)，默认nil
    open var allowsDownloadUrl: ((URL) -> Bool)?

    /// 是否允许打开通用链接，默认false
    open var allowsUniversalLinks = false
    
    /// 是否允许不受信任的服务器，默认false
    ///
    /// 需配置Info.plist开启NSAppTransportSecurity.NSAllowsArbitraryLoadsInWebContent或NSAllowsArbitraryLoads选项后生效
    open var allowsArbitraryLoads = false
    
    /// 是否允许window.close关闭当前控制器，默认true
    ///
    /// 如果WebView新开了界面，触发了createWebView回调后，则不会触发。
    /// 解决方案示例：使用JSBridge桥接或URL拦截等方式关闭界面
    open var allowsWindowClose = true

    /// 网页请求，设置后会自动加载，支持NSString|NSURL|NSURLRequest。默认nil
    open var webRequest: Any? {
        didSet {
            fw.loadRequest(webRequest)
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
        let configuration = WKWebView.fw.defaultConfiguration()
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
        progressView.fw.pinEdges(excludingEdge: .bottom, autoScale: false)
        progressView.fw.setDimension(.height, size: 2.0, autoScale: false)
        fw.observeProperty(\.estimatedProgress) { webView, _ in
            DispatchQueue.fw.mainAsync {
                webView.progressView.fw.webProgress = Float(webView.estimatedProgress)
            }
        }
        fw.observeProperty(\.isLoading) { webView, _ in
            DispatchQueue.fw.mainAsync {
                if !webView.isLoading && webView.progressView.fw.webProgress < 1.0 {
                    webView.progressView.fw.webProgress = 1.0
                }
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
        allowsUrlSchemes = []
        allowsRouterSchemes = []
        allowsDownloadUrl = nil
        allowsArbitraryLoads = false
        allowsWindowClose = true
        webRequest = nil
        isFirstLoad = false
        
        super.reusableViewWillRecycle()
        
        if fw.reusedTimes < 1,
           !fw.reusePreparing,
           let reuseIdentifier = fw.reuseIdentifier,
           !WebView.preloadedReuseIdentifiers.contains(reuseIdentifier),
           let preloadUrl = WebView.reusePreloadUrlBlock?(reuseIdentifier) {
            WebView.preloadedReuseIdentifiers.append(reuseIdentifier)
            
            fw.reusePreparing = true
            reusableViewWillReuse()
            fw.loadRequest(preloadUrl)
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
        Logger.debug(group: Logger.fw.moduleName, "%@ deinit", NSStringFromClass(type(of: self)))
        #endif
    }
    
    // MARK: - Public
    /// 注册JS桥接处理类或对象
    ///
    /// - Parameters:
    ///   - clazz: JS桥接处理类或对象
    ///   - package: 桥接包名，默认nil。示例：app.
    ///   - object: 自定义上下文，可通过context.object访问，示例：WebView控制器
    ///   - mapper: 自定义映射，默认nil时查找规则：xxxBridge: > xxxDefaultBridge:
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
    ///   - mapper: 自定义映射，默认nil时查找规则：xxxBridge: > xxxDefaultBridge:
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
        guard let metaClass = NSObject.fw.metaClass(clazz) else {
            return [:]
        }
        
        let methods = NSObject.fw.classMethods(metaClass)
        if let mapper = mapper {
            return mapper(methods)
        }
        
        var bridges: [String: String] = [:]
        let bridgeSuffix = "Bridge:"
        for method in methods {
            guard method.hasSuffix(bridgeSuffix),
                  method.components(separatedBy: ":").count == 2 else {
                continue
            }
            
            if method.hasSuffix("Default" + bridgeSuffix) {
                let name = method.replacingOccurrences(of: "Default" + bridgeSuffix, with: "")
                if !methods.contains(name + bridgeSuffix) {
                    bridges[name] = method
                }
            } else {
                let name = method.replacingOccurrences(of: bridgeSuffix, with: "")
                bridges[name] = method
            }
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
        Logger.debug(group: Logger.fw.moduleName, "WKWebViewJavascriptBridge: %@", message, function: function, file: file, line: line)
        #endif
    }
    
    private func evaluateJavascript(javascript: String, completion: (@MainActor @Sendable (Any?, Error?) -> Void)? = nil) {
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
extension WKWebView {
    
    fileprivate static var innerProcessPool = WKProcessPool()
    
    // MARK: - ReusableViewProtocol
    /// 初始化WKWebView可重用视图
    open override class func reusableViewInitialize(reuseIdentifier: String) -> Self {
        let configuration = WKWebView.fw.defaultConfiguration()
        let reuseBlock = NSObject.fw.getAssociatedObject(self, key: #function) as? (WKWebViewConfiguration, String) -> Void
        reuseBlock?(configuration, reuseIdentifier)
        return self.init(frame: .zero, configuration: configuration)
    }
    
    /// 即将回收视图，必须调用super
    open override func reusableViewWillRecycle() {
        super.reusableViewWillRecycle()
        
        fw.jsBridge = nil
        fw.jsBridgeEnabled = false
        fw.navigationItems = nil
        guard fw.reusedTimes > 0 else { return }
        
        scrollView.delegate = nil
        scrollView.isScrollEnabled = true
        stopLoading()
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        evaluateJavaScript("window.sessionStorage.clear();", completionHandler: nil)
        configuration.userContentController.removeAllUserScripts()
        load(URLRequest(url: URL()))
    }
    
    /// 即将重用视图，默认重用次数+1，必须调用super
    open override func reusableViewWillReuse() {
        super.reusableViewWillReuse()
        
        fw.clearBackForwardList()
    }
    
}

// MARK: - WebViewDelegateProxy
fileprivate class WebViewDelegateProxy: DelegateProxy<WebViewDelegate>, WebViewDelegate, WKDownloadDelegate {
    
    #if compiler(>=6.0)
    typealias DownloadCompletionHandler = @MainActor @Sendable (URL?) -> Void
    #else
    typealias DownloadCompletionHandler = (URL?) -> Void
    #endif
    
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
        
        if UIApplication.fw.isSystemURL(navigationAction.request.url) {
            UIApplication.fw.openURL(navigationAction.request.url)
            decisionHandler(.cancel)
            return
        }
        
        if #available(iOS 14.5, *) {
            if let webView = webView as? WebView,
               let url = navigationAction.request.url,
               webView.allowsDownloadUrl?(url) == true {
                decisionHandler(.download)
                return
            }
        }
        
        if let webView = webView as? WebView,
           !webView.allowsUrlSchemes.isEmpty,
           UIApplication.fw.isSchemeURL(navigationAction.request.url, schemes: webView.allowsUrlSchemes) {
            UIApplication.fw.openURL(navigationAction.request.url)
            decisionHandler(.cancel)
            return
        }
        
        if let webView = webView as? WebView,
           !webView.allowsRouterSchemes.isEmpty,
           let url = navigationAction.request.url,
           UIApplication.fw.isSchemeURL(url, schemes: webView.allowsRouterSchemes) {
            Router.openURL(url)
            decisionHandler(.cancel)
            return
        }
        
        if let webView = webView as? WebView,
           webView.allowsUniversalLinks,
           navigationAction.request.url?.scheme == "https" {
            UIApplication.fw.openUniversalLinks(navigationAction.request.url) { success in
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
        
        if #available(iOS 14.5, *) {
            if let webView = webView as? WebView,
               let url = navigationResponse.response.url,
               webView.allowsDownloadUrl?(url) == true {
                decisionHandler(.download)
                return
            }
        }
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if self.delegate?.webView?(webView, didFinish: navigation) != nil {
        } else {
            self.delegate?.webViewFinishLoad()
        }
        
        if let webView = webView as? WebView, webView.isFirstLoad,
           !webView.fw.reusePreparing {
            webView.isFirstLoad = false
            webView.fw.preloadReusableView()
        }
        
        if let webView = webView as? WebView, webView.fw.reusePreparing {
            webView.reusableViewWillRecycle()
            webView.fw.reusePreparing = false
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if self.delegate?.webView?(webView, didFailProvisionalNavigation: navigation, withError: error) != nil {
            return
        }
        
        if let webView = webView as? WebView, webView.fw.reusePreparing {
            webView.reusableViewWillRecycle()
            webView.fw.reusePreparing = false
        }
        
        if (error as NSError).code == NSURLErrorCancelled { return }
        self.delegate?.webViewFailLoad(error)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if self.delegate?.webView?(webView, didFail: navigation, withError: error) != nil {
            return
        }
        
        if let webView = webView as? WebView, webView.fw.reusePreparing {
            webView.reusableViewWillRecycle()
            webView.fw.reusePreparing = false
        }
        
        if (error as NSError).code == NSURLErrorCancelled { return }
        self.delegate?.webViewFailLoad(error)
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        if let webView = webView as? WebView {
            webView.fw.reuseInvalid = true
        }
        
        if self.delegate?.webViewWebContentProcessDidTerminate?(webView) != nil {
            return
        }
        
        // 默认调用reload解决内存过大引起的白屏问题，可重写
        webView.reload()
    }
    
    @available(iOS 14.5, *)
    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        if self.delegate?.webView?(webView, navigationAction: navigationAction, didBecome: download) != nil {
            return
        }
        
        download.delegate = self
    }
    
    @available(iOS 14.5, *)
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        if self.delegate?.webView?(webView, navigationResponse: navigationResponse, didBecome: download) != nil {
            return
        }
        
        download.delegate = self
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if self.delegate?.webView?(webView, didReceive: challenge, completionHandler: completionHandler) != nil {
            return
        }
        
        if let webView = webView as? WebView, webView.allowsArbitraryLoads,
           challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
            } else {
                completionHandler(.useCredential, nil)
            }
            return
        }
        
        completionHandler(.performDefaultHandling, nil)
    }
    
    // MARK: - WKUIDelegate
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        if self.delegate?.webView?(webView, runJavaScriptAlertPanelWithMessage: message, initiatedByFrame: frame, completionHandler: completionHandler) != nil {
            return
        }
        
        webView.fw.showAlert(title: nil, message: message, cancel: nil) {
            completionHandler()
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        if self.delegate?.webView?(webView, runJavaScriptConfirmPanelWithMessage: message, initiatedByFrame: frame, completionHandler: completionHandler) != nil {
            return
        }
        
        webView.fw.showConfirm(title: nil, message: message, cancel: nil, confirm: nil) {
            completionHandler(true)
        } cancelBlock: {
            completionHandler(false)
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        if self.delegate?.webView?(webView, runJavaScriptTextInputPanelWithPrompt: prompt, defaultText: defaultText, initiatedByFrame: frame, completionHandler: completionHandler) != nil {
            return
        }
        
        webView.fw.showPrompt(title: nil, message: prompt, cancel: nil, confirm: nil) { textField in
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
            webView.fw.viewController?.fw.close()
        }
    }
    
    // MARK: - WKDownloadDelegate
    @available(iOS 14.5, *)
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping DownloadCompletionHandler) {
        let downloadDelegate = self.delegate as? WKDownloadDelegate
        if downloadDelegate?.download(download, decideDestinationUsing: response, suggestedFilename: suggestedFilename, completionHandler: completionHandler) != nil {
            return
        }
        
        let fileExt = (suggestedFilename as NSString).pathExtension
        var fileName = (suggestedFilename as NSString).deletingPathExtension
        fileName = (UUID().uuidString + fileName).fw.md5Encode
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName).appendingPathExtension(fileExt)
        download.fw.setProperty(url, forName: "downloadUrl")
        completionHandler(url)
    }
    
    @available(iOS 14.5, *)
    func downloadDidFinish(_ download: WKDownload) {
        let downloadDelegate = self.delegate as? WKDownloadDelegate
        if downloadDelegate?.downloadDidFinish?(download) != nil {
            return
        }
        
        guard let url = download.fw.property(forName: "downloadUrl") as? URL else {
            return
        }
        
        DispatchQueue.fw.mainAsync {
            if let presentedController = download.webView?.fw.viewController?.presentedViewController {
                presentedController.dismiss(animated: true) {
                    UIApplication.fw.openActivityItems([url])
                }
            } else {
                UIApplication.fw.openActivityItems([url])
            }
        }
    }
    
}
