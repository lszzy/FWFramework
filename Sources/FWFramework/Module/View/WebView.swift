//
//  WebView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
import JavaScriptCore
#if FWMacroSPM
import FWObjC
#endif

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
/// 备注：如需实现加载离线资源等场景，请使用configuration.setURLSchemeHandler
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
                    webView.load(WebViewCookieManager.fix(navigationAction.request) as URLRequest)
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
    /// 是否持久化processPool，默认false，开启后会自动加载持久化processPool
    public static var fw_processPoolPersisted = false
    
    /// 默认跨WKWebView共享Cookie，切换用户时可重置processPool清空Cookie
    public static var fw_processPool: WKProcessPool = {
        guard fw_processPoolPersisted else {
            return WKProcessPool()
        }
        
        let cacheFile = fw_processCacheFile()
        if let processPool = Data.fw_unarchivedObject(WKProcessPool.self, withFile: cacheFile) {
            return processPool
        } else {
            let processPool = WKProcessPool()
            Data.fw_archiveObject(processPool, toFile: cacheFile)
            return processPool
        }
    }() {
        didSet {
            guard fw_processPoolPersisted else { return }
            
            let cacheFile = fw_processCacheFile()
            Data.fw_archiveObject(fw_processPool, toFile: cacheFile)
        }
    }
    
    private static func fw_processCacheFile() -> String {
        var cacheFile = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first ?? ""
        cacheFile = (cacheFile as NSString).appendingPathComponent("FWCache/WKProcessPool.plist")
        let cacheDir = (cacheFile as NSString).deletingLastPathComponent
        if !FileManager.default.fileExists(atPath: cacheDir) {
            try? FileManager.default.createDirectory(atPath: cacheDir, withIntermediateDirectories: true, attributes: nil)
        }
        return cacheFile
    }
    
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
    public var fw_jsBridge: WebViewJsBridge? {
        get { fw_property(forName: "fw_jsBridge") as? WebViewJsBridge }
        set { fw_setProperty(newValue, forName: "fw_jsBridge") }
    }
    
    /// 是否启用Javascript桥接器，需结合setupJsBridge使用
    public var fw_jsBridgeEnabled: Bool {
        get { fw_propertyBool(forName: "fw_jsBridgeEnabled") }
        set { fw_setPropertyBool(newValue, forName: "fw_jsBridgeEnabled") }
    }
    
    /// 自动初始化Javascript桥接器，jsBridgeEnabled开启时生效
    @discardableResult
    public func fw_setupJsBridge() -> WebViewJsBridge? {
        guard fw_jsBridgeEnabled else { return nil }
        let delegate = self.navigationDelegate
        let jsBridge = WebViewJsBridge(for: self)
        jsBridge.setWebViewDelegate(delegate)
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
