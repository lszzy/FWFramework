//
//  WebView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

// MARK: - WebViewPool
/// WKWebView缓存池
///
/// [KKJSBridge](https://github.com/karosLi/KKJSBridge)
public class WebViewPool: NSObject {
    
    /// 单例模式
    public static let shared = WebViewPool()
    
    /// webView最大缓存数量，默认5个
    public var webViewMaxReuseCount: Int = 5
    
    /// webview进入回收复用池前加载的url，用于刷新webview和容错，默认空
    public var webViewReuseLoadUrl = ""
    
    /// webview最大重用次数，默认为最大无限制
    public var webViewMaxReuseTimes: Int = .max
    
    /// 构建 webView configuration，作为所有复用 webView 提供预先的默认 configuration
    public var webViewConfigurationBlock: ((WKWebViewConfiguration) -> Void)?
    
    private var lock: DispatchSemaphore = .init(value: 1)
    private var dequeueWebViews: [String: [WKWebView]] = [:]
    private var enqueueWebViews: [String: [WKWebView]] = [:]
    
    // MARK: - Lifecycle
    /// 初始化方法，内存警告时自动清理全部
    public override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(clearAllReusableWebViews), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    /// 析构方法
    deinit {
        NotificationCenter.default.removeObserver(self)
        dequeueWebViews.removeAll()
        enqueueWebViews.removeAll()
    }
    
    // MARK: - Public
    /// 获得一个可复用的webview
    /// - Parameters:
    ///   - webViewType: webview的自定义class
    ///   - webViewHolder: webview的持有者，用于自动回收webview
    /// - Returns: 可复用的webview
    public func dequeueWebView<T: WKWebView>(with webViewType: T.Type = WKWebView.self, webViewHolder: NSObject?) -> T {
        tryCompactWeakHolderOfWebView()
        let webView = getWebView(with: webViewType)
        webView.fw_holderObject = webViewHolder
        return webView
    }
    
    /// 创建一个 webview，并且将它放入到回收池中
    public func enqueueWebView<T: WKWebView>(with webViewType: T.Type = WKWebView.self) {
        lock.wait()
        let webViewTypeString = NSStringFromClass(webViewType)
        var webViewArray = enqueueWebViews[webViewTypeString] ?? []
        if webViewArray.count < webViewMaxReuseCount {
            let webView = generateInstance(with: webViewType)
            webViewArray.append(webView)
            enqueueWebViews[webViewTypeString] = webViewArray
        }
        lock.signal()
    }
    
    /// 回收可复用的WKWebView
    public func enqueueWebView(_ webView: WKWebView?) {
        guard let webView = webView else { return }
        
        webView.removeFromSuperview()
        if webView.fw_reusedTimes >= webViewMaxReuseTimes || webView.fw_isInvalid {
            removeReusableWebView(webView)
        } else {
            recycleWebView(webView)
        }
    }
    
    /// 回收并销毁WKWebView，并且将之从回收池里删除
    public func removeReusableWebView(_ webView: WKWebView?) {
        guard let webView = webView else { return }
        
        webView.webViewWillEnterPool()
        lock.wait()
        let webViewTypeString = NSStringFromClass(webView.classForCoder)
        if var webViewArray = dequeueWebViews[webViewTypeString],
           webViewArray.contains(webView) {
            webViewArray.removeAll { $0 == webView }
            dequeueWebViews[webViewTypeString] = webViewArray
        }
        
        if var webViewArray = enqueueWebViews[webViewTypeString],
           webViewArray.contains(webView) {
            webViewArray.removeAll { $0 == webView }
            enqueueWebViews[webViewTypeString] = webViewArray
        }
        lock.signal()
    }
    
    /// 销毁在回收池中特定Class的WebView
    public func clearReusableWebViews<T: WKWebView>(with webViewType: T.Type = WKWebView.self) {
        let webViewTypeString = NSStringFromClass(webViewType)
        lock.wait()
        if enqueueWebViews.keys.contains(webViewTypeString) {
            enqueueWebViews.removeValue(forKey: webViewTypeString)
        }
        lock.signal()
    }
    
    /// 销毁全部在回收池中的WebView
    @objc public func clearAllReusableWebViews() {
        tryCompactWeakHolderOfWebView()
        lock.wait()
        enqueueWebViews.removeAll()
        lock.signal()
    }
    
    /// 重新刷新在回收池中的WebView
    public func reloadAllReusableWebViews() {
        lock.wait()
        for webViewArray in enqueueWebViews.values {
            for webView in webViewArray {
                webView.webViewWillEnterPool()
            }
        }
        lock.signal()
    }
    
    /// 判断回收池中是否包含特定Class的WebView
    public func containsReusableWebView<T: WKWebView>(with webViewType: T.Type = WKWebView.self) -> Bool {
        lock.wait()
        let webViewTypeString = NSStringFromClass(webViewType)
        var contains = false
        if dequeueWebViews.keys.contains(webViewTypeString) ||
            enqueueWebViews.keys.contains(webViewTypeString) {
            contains = true
        }
        lock.signal()
        return contains
    }
    
    // MARK: - Private
    private func tryCompactWeakHolderOfWebView() {
        let webViewDictionary = dequeueWebViews
        if webViewDictionary.count > 0 {
            for webViewArray in webViewDictionary.values {
                for webView in webViewArray {
                    if webView.fw_holderObject == nil {
                        enqueueWebView(webView)
                    }
                }
            }
        }
    }
    
    private func recycleWebView(_ webView: WKWebView?) {
        guard let webView = webView else { return }
        
        webView.webViewWillEnterPool()
        lock.wait()
        let webViewTypeString = NSStringFromClass(webView.classForCoder)
        if var webViewArray = dequeueWebViews[webViewTypeString],
           webViewArray.contains(webView) {
            webViewArray.removeAll { $0 == webView }
            dequeueWebViews[webViewTypeString] = webViewArray
        }
        
        var webViewArray = enqueueWebViews[webViewTypeString] ?? []
        if webViewArray.count < webViewMaxReuseCount {
            webViewArray.append(webView)
            enqueueWebViews[webViewTypeString] = webViewArray
        }
        lock.signal()
    }
    
    private func getWebView<T: WKWebView>(with webViewType: T.Type) -> T {
        let webViewTypeString = NSStringFromClass(webViewType)
        var enqueueWebView: T?
        lock.wait()
        if var webViewArray = enqueueWebViews[webViewTypeString],
           webViewArray.count > 0 {
            enqueueWebView = webViewArray.removeFirst() as? T
            enqueueWebViews[webViewTypeString] = webViewArray
        }
        
        let webView = enqueueWebView ?? generateInstance(with: webViewType)
        var webViewArray = dequeueWebViews[webViewTypeString] ?? []
        webViewArray.append(webView)
        dequeueWebViews[webViewTypeString] = webViewArray
        lock.signal()
        
        webView.webViewWillLeavePool()
        return webView
    }
    
    private func generateInstance<T: WKWebView>(with webViewType: T.Type) -> T {
        let configuration = WKWebView.fw_defaultConfiguration()
        webViewConfigurationBlock?(configuration)
        return webViewType.init(frame: .zero, configuration: configuration)
    }
    
}

/// WKWebView重用协议
public protocol WebViewReusableProtocol {
    
    /// 即将进入回收池
    func webViewWillEnterPool()
    
    /// 即将离开回收池
    func webViewWillLeavePool()
    
}

@_spi(FW) extension WKWebView {
    
    /// 持有者对象，弱引用
    public weak var fw_holderObject: NSObject? {
        get { return fw_property(forName: "fw_holderObject") as? NSObject }
        set { fw_setPropertyWeak(newValue, forName: "fw_holderObject") }
    }
    
    /// 重用次数
    public var fw_reusedTimes: Int {
        get { return fw_propertyInt(forName: "fw_reusedTimes") }
        set { fw_setPropertyInt(newValue, forName: "fw_reusedTimes") }
    }
    
    /// 是否已失效，将自动从缓存池移除
    public var fw_isInvalid: Bool {
        get { return fw_propertyBool(forName: "fw_isInvalid") }
        set { fw_setPropertyBool(newValue, forName: "fw_isInvalid") }
    }
    
    /// 按需预加载下一个WebView实例，一般在didFinishNavigation中调用
    public func fw_prepareNextWebView() {
        if WebViewPool.shared.containsReusableWebView(with: type(of: self)) {
            WebViewPool.shared.enqueueWebView(with: type(of: self))
        }
    }
    
    private func fw_clearBackForwardList() {
        let selector = NSSelectorFromString(String(format: "%@%@%@%@", "_re", "moveA", "llIte", "ms"))
        if backForwardList.responds(to: selector) {
            backForwardList.perform(selector)
        }
    }
    
}

@objc extension WKWebView: WebViewReusableProtocol {
    
    /// 即将进入回收池，必须调用super
    open func webViewWillEnterPool() {
        fw_holderObject = nil
        fw_jsBridge = nil
        fw_jsBridgeEnabled = false
        fw_navigationItems = nil
        scrollView.delegate = nil
        scrollView.isScrollEnabled = true
        stopLoading()
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        evaluateJavaScript("window.sessionStorage.clear();", completionHandler: nil)
        configuration.userContentController.removeAllUserScripts()
        if !WebViewPool.shared.webViewReuseLoadUrl.isEmpty {
            load(URLRequest(url: URL.fw_safeURL(WebViewPool.shared.webViewReuseLoadUrl)))
        } else {
            load(URLRequest(url: URL.fw_safeURL(nil)))
        }
    }
    
    /// 即将离开回收池，必须调用super
    open func webViewWillLeavePool() {
        fw_reusedTimes += 1
        fw_clearBackForwardList()
    }
    
}

extension WebView {
    
    /// 即将进入回收池，必须调用super
    open override func webViewWillEnterPool() {
        delegate = nil
        cookieEnabled = false
        allowsUniversalLinks = false
        allowsSchemeURL = false
        webRequest = nil
        super.webViewWillEnterPool()
    }
    
}

// MARK: - UIProgressView+WebView
@_spi(FW) extension UIProgressView {
    
    /// 设置Web加载进度，0和1自动切换隐藏。可设置trackTintColor为clear，隐藏背景色
    @objc(__fw_webProgress)
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

// MARK: - WKWebView+WebView
@_spi(FW) extension WKWebView {
    
    /// 默认跨WKWebView共享Cookie，切换用户时可重置processPool清空Cookie
    public static var fw_processPool = WKProcessPool()
    
    /// 快捷创建WKWebView默认配置，自动初始化User-Agent和共享processPool
    @objc(__fw_defaultConfiguration)
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
    
    /// 清空网页缓存，完成后回调。单个网页请求指定URLRequest.cachePolicy即可
    public static func fw_clearCache(_ completion: (() -> Void)? = nil) {
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        let sinceDate = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: sinceDate) {
            completion?()
        }
    }
    
    /// 设置Javascript桥接器强引用属性，防止使用过程中被释放
    @objc(__fw_jsBridge)
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
