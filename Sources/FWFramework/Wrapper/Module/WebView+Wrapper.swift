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

extension Wrapper where Base: UIProgressView {
    
    /// 设置Web加载进度，0和1自动切换隐藏。可设置trackTintColor为clear，隐藏背景色
    public var webProgress: Float {
        get { return base.fw_webProgress }
        set { base.fw_webProgress = newValue }
    }
    
}

extension Wrapper where Base: WKWebView {
    
    /// 默认跨WKWebView共享Cookie，切换用户时可重置processPool清空Cookie
    public static var processPool: WKProcessPool {
        get { return Base.fw_processPool }
        set { Base.fw_processPool = newValue }
    }
    
    /// 快捷创建WKWebView默认配置，自动初始化User-Agent和共享processPool
    public static func defaultConfiguration() -> WKWebViewConfiguration {
        return Base.fw_defaultConfiguration()
    }
    
    /// 获取默认浏览器UserAgent，包含应用信息，示例：Mozilla/5.0 (iPhone; CPU OS 14_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Safari/605.1.15 Example/1.0.0
    public static var browserUserAgent: String {
        return Base.fw_browserUserAgent
    }

    /// 获取默认浏览器扩展UserAgent，不含平台信息，可用于applicationNameForUserAgent，示例：Mobile/15E148 Safari/605.1.15 Example/1.0.0
    public static var extensionUserAgent: String {
        return Base.fw_extensionUserAgent
    }

    /// 获取默认请求UserAgent，可用于网络请求，示例：Example/1.0.0 (iPhone; iOS 14.2; Scale/3.00)
    public static var requestUserAgent: String {
        return Base.fw_requestUserAgent
    }
    
    /// 获取当前UserAgent，未自定义时为默认，示例：Mozilla/5.0 (iPhone; CPU OS 14_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148
    public var userAgent: String {
        return base.fw_userAgent
    }
    
    /// 清空网页缓存，完成后回调。单个网页请求指定URLRequest.cachePolicy即可
    public static func clearCache(_ completion: (() -> Void)? = nil) {
        Base.fw_clearCache(completion)
    }
    
    /// 设置Javascript桥接器强引用属性，防止使用过程中被释放
    public var jsBridge: WebViewJsBridge? {
        get { return base.fw_jsBridge }
        set { base.fw_jsBridge = newValue }
    }
    
    /// 是否启用Javascript桥接器，需结合setupJsBridge使用
    public var jsBridgeEnabled: Bool {
        get { return base.fw_jsBridgeEnabled }
        set { base.fw_jsBridgeEnabled = newValue }
    }
    
    /// 自动初始化Javascript桥接器，jsBridgeEnabled开启时生效
    @discardableResult
    public func setupJsBridge() -> WebViewJsBridge? {
        return base.fw_setupJsBridge()
    }
    
    /// 绑定控制器导航栏左侧按钮组，需结合setupNavigationItems使用
    public var navigationItems: [Any]? {
        get { return base.fw_navigationItems }
        set { base.fw_navigationItems = newValue }
    }
    
    /// 自动初始化控制器导航栏左侧按钮组，navigationItems设置后生效
    public func setupNavigationItems(_ viewController: UIViewController) {
        base.fw_setupNavigationItems(viewController)
    }
    
    /// 持有者对象，弱引用
    public weak var holderObject: NSObject? {
        get { return base.fw_holderObject }
        set { base.fw_holderObject = newValue }
    }
    
    /// 重用次数
    public var reusedTimes: Int {
        get { return base.fw_reusedTimes }
        set { base.fw_reusedTimes = newValue }
    }
    
    /// 是否已失效，将自动从缓存池移除
    public var isInvalid: Bool {
        get { return base.fw_isInvalid }
        set { base.fw_isInvalid = newValue }
    }
    
    /// 按需预加载下一个WebView实例，一般在didFinishNavigation中调用
    public func prepareNextWebView() {
        base.fw_prepareNextWebView()
    }
    
}
