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
    
    /// webview进入回收复用池前加载的url，用于刷新webview和容错，默认nil
    public var webViewReuseLoadUrlStr: String?
    
}

/// WKWebView重用协议
public protocol WebViewReusableProtocol {
    
    /// 即将进入回收池
    func webViewWillEnterPool()
    
    /// 即将离开回收池
    func webViewWillLeavePool()
    
}

@_spi(FW) extension WKWebView {
    
    public weak var fw_holderObject: NSObject? {
        get { return fw_property(forName: "fw_holderObject") as? NSObject }
        set { fw_setPropertyWeak(newValue, forName: "fw_holderObject") }
    }
    
    public var fw_reusedTimes: Int {
        get { return fw_propertyInt(forName: "fw_reusedTimes") }
        set { fw_setPropertyInt(newValue, forName: "fw_reusedTimes") }
    }
    
    public var fw_invalid: Bool {
        get { return fw_propertyBool(forName: "fw_invalid") }
        set { fw_setPropertyBool(newValue, forName: "fw_invalid") }
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
        if let reuseLoadUrl = WebViewPool.shared.webViewReuseLoadUrlStr, !reuseLoadUrl.isEmpty {
            load(URLRequest(url: URL.fw_safeURL(reuseLoadUrl)))
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
    
    /// 获取默认浏览器UserAgent，包含应用信息，示例：Mozilla/5.0 (iPhone; CPU OS 14_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Safari/605.1.15 Example/1.0.0
    public static var fw_browserUserAgent: String {
        let platformUserAgent = String(format: "Mozilla/5.0 (%@; CPU OS %@ like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko)", UIDevice.current.model, UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_"))
        let userAgent = String(format: "%@ %@", platformUserAgent, fw_extensionUserAgent)
        return userAgent
    }

    /// 获取默认浏览器扩展UserAgent，不含平台信息，可用于applicationNameForUserAgent，示例：Mobile/15E148 Safari/605.1.15 Example/1.0.0
    @objc(__fw_extensionUserAgent)
    public static var fw_extensionUserAgent: String {
        let userAgent = String(format: "Mobile/15E148 Safari/605.1.15 %@/%@", UIApplication.fw_appExecutable, UIApplication.fw_appVersion)
        return userAgent
    }

    /// 获取默认请求UserAgent，可用于网络请求，示例：Example/1.0.0 (iPhone; iOS 14.2; Scale/3.00)
    public static var fw_requestUserAgent: String {
        let userAgent = String(format: "%@/%@ (%@; iOS %@; Scale/%0.2f)", UIApplication.fw_appExecutable, UIApplication.fw_appVersion, UIDevice.current.model, UIDevice.current.systemVersion, UIScreen.main.scale)
        return userAgent
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
