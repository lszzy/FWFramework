//
//  WebView+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
import JavaScriptCore
#if FWMacroSPM
import FWObjC
#endif

extension Wrapper where Base: WKWebView {
    
    /// 重用WebView全局配置句柄(第二个参数为重用标志)，为所有复用WebView提供预先的默认configuration
    public static var reuseConfigurationBlock: ((WKWebViewConfiguration, String) -> Void)? {
        get { return Base.fw_reuseConfigurationBlock }
        set { Base.fw_reuseConfigurationBlock = newValue }
    }
    
    /// 是否持久化processPool，默认false，开启后会自动加载持久化processPool
    public static var processPoolPersisted: Bool {
        get { return Base.fw_processPoolPersisted }
        set { Base.fw_processPoolPersisted = newValue }
    }
    
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
    
    /// 加载网页请求，支持String|URL|URLRequest等
    @discardableResult
    public func loadRequest(_ request: Any?) -> WKNavigation? {
        return base.fw_loadRequest(request)
    }
    
    /// 清空网页缓存，完成后回调。单个网页请求指定URLRequest.cachePolicy即可
    public static func clearCache(_ completion: (() -> Void)? = nil) {
        Base.fw_clearCache(completion)
    }
    
    /// 使用JavaScriptCore执行脚本并返回结果，支持模板替换。常用语服务端下发计算公式等场景
    public static func evaluateScript(_ script: String, variables: [String: String] = [:]) -> JSValue? {
        return Base.fw_evaluateScript(script, variables: variables)
    }
    
    /// 清空WebView后退和前进的网页栈
    public func clearBackForwardList() {
        base.fw_clearBackForwardList()
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
    
}

extension Wrapper where Base: UIProgressView {
    
    /// 设置Web加载进度，0和1自动切换隐藏。可设置trackTintColor为clear，隐藏背景色
    public var webProgress: Float {
        get { return base.fw_webProgress }
        set { base.fw_webProgress = newValue }
    }
    
}
