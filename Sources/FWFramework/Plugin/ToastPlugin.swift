//
//  ToastPlugin.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

@_spi(FW) @objc extension UIView {
    
    /// 自定义吐司插件，未设置时自动从插件池加载
    public var fw_toastPlugin: ToastPlugin! {
        get {
            if let toastPlugin = fw_property(forName: "fw_toastPlugin") as? ToastPlugin {
                return toastPlugin
            } else if let toastPlugin = PluginManager.loadPlugin(ToastPlugin.self) as? ToastPlugin {
                return toastPlugin
            }
            return ToastPluginImpl.shared
        }
        set {
            fw_setProperty(newValue, forName: "fw_toastPlugin")
        }
    }
    
    /// 设置吐司外间距，默认zero
    public var fw_toastInsets: UIEdgeInsets {
        get {
            if let value = fw_property(forName: "fw_toastInsets") as? NSValue {
                return value.uiEdgeInsetsValue
            }
            return .zero
        }
        set {
            fw_setProperty(NSValue(uiEdgeInsets: newValue), forName: "fw_toastInsets")
        }
    }
    
    /// 显示加载吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public func fw_showLoading(text: Any? = nil, cancel: (() -> Void)? = nil) {
        var attributedText = text as? NSAttributedString
        if let string = text as? String {
            attributedText = NSAttributedString(string: string)
        }
        var plugin: ToastPlugin
        if let toastPlugin = self.fw_toastPlugin, toastPlugin.responds(to: #selector(ToastPlugin.showLoading(withAttributedText:cancel:in:))) {
            plugin = toastPlugin
        } else {
            plugin = ToastPluginImpl.shared
        }
        plugin.showLoading?(withAttributedText: attributedText, cancel: cancel, in: self)
    }

    /// 隐藏加载吐司
    public func fw_hideLoading() {
        var plugin: ToastPlugin
        if let toastPlugin = self.fw_toastPlugin, toastPlugin.responds(to: #selector(ToastPlugin.hideLoading(_:))) {
            plugin = toastPlugin
        } else {
            plugin = ToastPluginImpl.shared
        }
        plugin.hideLoading?(self)
    }
    
    /// 是否正在显示加载吐司
    public var fw_isShowingLoading: Bool {
        var plugin: ToastPlugin
        if let toastPlugin = self.fw_toastPlugin, toastPlugin.responds(to: #selector(ToastPlugin.isShowingLoading(_:))) {
            plugin = toastPlugin
        } else {
            plugin = ToastPluginImpl.shared
        }
        return plugin.isShowingLoading!(self)
    }
    
    /// 显示进度条吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public func fw_showProgress(_ progress: CGFloat, text: Any? = nil, cancel: (() -> Void)? = nil) {
        var attributedText = text as? NSAttributedString
        if let string = text as? String {
            attributedText = NSAttributedString(string: string)
        }
        var plugin: ToastPlugin
        if let toastPlugin = self.fw_toastPlugin, toastPlugin.responds(to: #selector(ToastPlugin.showProgress(withAttributedText:progress:cancel:in:))) {
            plugin = toastPlugin
        } else {
            plugin = ToastPluginImpl.shared
        }
        plugin.showProgress?(withAttributedText: attributedText, progress: progress, cancel: cancel, in: self)
    }

    /// 隐藏进度条吐司
    public func fw_hideProgress() {
        var plugin: ToastPlugin
        if let toastPlugin = self.fw_toastPlugin, toastPlugin.responds(to: #selector(ToastPlugin.hideProgress(_:))) {
            plugin = toastPlugin
        } else {
            plugin = ToastPluginImpl.shared
        }
        plugin.hideProgress?(self)
    }
    
    /// 是否正在显示进度条吐司
    public var fw_isShowingProgress: Bool {
        var plugin: ToastPlugin
        if let toastPlugin = self.fw_toastPlugin, toastPlugin.responds(to: #selector(ToastPlugin.isShowingProgress(_:))) {
            plugin = toastPlugin
        } else {
            plugin = ToastPluginImpl.shared
        }
        return plugin.isShowingProgress!(self)
    }

    /// 显示指定样式消息吐司，自动隐藏，自动隐藏完成后回调，支持String和AttributedString
    public func fw_showMessage(text: Any?, style: ToastStyle = .default, completion: (() -> Void)? = nil) {
        fw_showMessage(text: text, style: style, autoHide: true, interactive: completion != nil ? false : true, completion: completion)
    }

    /// 显示指定样式消息吐司，可设置自动隐藏和允许交互，自动隐藏完成后回调，支持String和AttributedString
    public func fw_showMessage(text: Any?, style: ToastStyle, autoHide: Bool, interactive: Bool, completion: (() -> Void)? = nil) {
        var attributedText = text as? NSAttributedString
        if let string = text as? String {
            attributedText = NSAttributedString(string: string)
        }
        var plugin: ToastPlugin
        if let toastPlugin = self.fw_toastPlugin, toastPlugin.responds(to: #selector(ToastPlugin.showMessage(withAttributedText:style:autoHide:interactive:completion:in:))) {
            plugin = toastPlugin
        } else {
            plugin = ToastPluginImpl.shared
        }
        plugin.showMessage?(withAttributedText: attributedText, style: style, autoHide: autoHide, interactive: interactive, completion: completion, in: self)
    }

    /// 隐藏消息吐司
    public func fw_hideMessage() {
        var plugin: ToastPlugin
        if let toastPlugin = self.fw_toastPlugin, toastPlugin.responds(to: #selector(ToastPlugin.hideMessage(_:))) {
            plugin = toastPlugin
        } else {
            plugin = ToastPluginImpl.shared
        }
        plugin.hideMessage?(self)
    }
    
    /// 是否正在显示消息吐司
    public var fw_isShowingMessage: Bool {
        var plugin: ToastPlugin
        if let toastPlugin = self.fw_toastPlugin, toastPlugin.responds(to: #selector(ToastPlugin.isShowingMessage(_:))) {
            plugin = toastPlugin
        } else {
            plugin = ToastPluginImpl.shared
        }
        return plugin.isShowingMessage!(self)
    }
    
}

@_spi(FW) @objc extension UIViewController {
    
    /// 设置吐司是否显示在window上，默认NO，显示到view上
    public var fw_toastInWindow: Bool {
        get { fw_propertyBool(forName: "fw_toastInWindow") }
        set { fw_setPropertyBool(newValue, forName: "fw_toastInWindow") }
    }
    
    /// 设置吐司是否显示在祖先视图上，默认NO，显示到view上
    public var fw_toastInAncestor: Bool {
        get { fw_propertyBool(forName: "fw_toastInAncestor") }
        set { fw_setPropertyBool(newValue, forName: "fw_toastInAncestor") }
    }
    
    private var fw_toastContainerView: UIView? {
        if self.fw_toastInWindow { return UIWindow.fw_mainWindow }
        if self.fw_toastInAncestor { return self.fw_ancestorView }
        return self.view
    }
    
    /// 设置吐司外间距，默认zero
    public var fw_toastInsets: UIEdgeInsets {
        get { return fw_toastContainerView?.fw_toastInsets ?? .zero }
        set { fw_toastContainerView?.fw_toastInsets = newValue }
    }
    
    /// 显示加载吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public func fw_showLoading(text: Any? = nil, cancel: (() -> Void)? = nil) {
        fw_toastContainerView?.fw_showLoading(text: text, cancel: cancel)
    }

    /// 隐藏加载吐司
    public func fw_hideLoading() {
        fw_toastContainerView?.fw_hideLoading()
    }
    
    /// 是否正在显示加载吐司
    public var fw_isShowingLoading: Bool {
        return fw_toastContainerView?.fw_isShowingLoading ?? false
    }
    
    /// 显示进度条吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public func fw_showProgress(_ progress: CGFloat, text: Any? = nil, cancel: (() -> Void)? = nil) {
        fw_toastContainerView?.fw_showProgress(progress, text: text, cancel: cancel)
    }

    /// 隐藏进度条吐司
    public func fw_hideProgress() {
        fw_toastContainerView?.fw_hideProgress()
    }
    
    /// 是否正在显示进度条吐司
    public var fw_isShowingProgress: Bool {
        return fw_toastContainerView?.fw_isShowingProgress ?? false
    }

    /// 显示指定样式消息吐司，自动隐藏，自动隐藏完成后回调，支持String和AttributedString
    public func fw_showMessage(text: Any?, style: ToastStyle = .default, completion: (() -> Void)? = nil) {
        fw_toastContainerView?.fw_showMessage(text: text, style: style, completion: completion)
    }

    /// 显示指定样式消息吐司，可设置自动隐藏和允许交互，自动隐藏完成后回调，支持String和AttributedString
    public func fw_showMessage(text: Any?, style: ToastStyle, autoHide: Bool, interactive: Bool, completion: (() -> Void)? = nil) {
        fw_toastContainerView?.fw_showMessage(text: text, style: style, autoHide: autoHide, interactive: interactive, completion: completion)
    }

    /// 隐藏消息吐司
    public func fw_hideMessage() {
        fw_toastContainerView?.fw_hideMessage()
    }
    
    /// 是否正在显示消息吐司
    public var fw_isShowingMessage: Bool {
        return fw_toastContainerView?.fw_isShowingMessage ?? false
    }
    
}

@_spi(FW) @objc extension UIWindow {
    
    /// 设置吐司外间距，默认zero
    public static var fw_toastInsets: UIEdgeInsets {
        get { return UIWindow.fw_mainWindow?.fw_toastInsets ?? .zero }
        set { UIWindow.fw_mainWindow?.fw_toastInsets = newValue }
    }
    
    /// 显示加载吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public static func fw_showLoading(text: Any? = nil, cancel: (() -> Void)? = nil) {
        UIWindow.fw_mainWindow?.fw_showLoading(text: text, cancel: cancel)
    }

    /// 隐藏加载吐司
    public static func fw_hideLoading() {
        UIWindow.fw_mainWindow?.fw_hideLoading()
    }
    
    /// 是否正在显示加载吐司
    public static var fw_isShowingLoading: Bool {
        return UIWindow.fw_mainWindow?.fw_isShowingLoading ?? false
    }
    
    /// 显示进度条吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public static func fw_showProgress(_ progress: CGFloat, text: Any? = nil, cancel: (() -> Void)? = nil) {
        UIWindow.fw_mainWindow?.fw_showProgress(progress, text: text, cancel: cancel)
    }

    /// 隐藏进度条吐司
    public static func fw_hideProgress() {
        UIWindow.fw_mainWindow?.fw_hideProgress()
    }
    
    /// 是否正在显示进度条吐司
    public static var fw_isShowingProgress: Bool {
        return UIWindow.fw_mainWindow?.fw_isShowingProgress ?? false
    }

    /// 显示指定样式消息吐司，自动隐藏，自动隐藏完成后回调，支持String和AttributedString
    public static func fw_showMessage(text: Any?, style: ToastStyle = .default, completion: (() -> Void)? = nil) {
        UIWindow.fw_mainWindow?.fw_showMessage(text: text, style: style, completion: completion)
    }

    /// 显示指定样式消息吐司，可设置自动隐藏和允许交互，自动隐藏完成后回调，支持String和AttributedString
    public static func fw_showMessage(text: Any?, style: ToastStyle, autoHide: Bool, interactive: Bool, completion: (() -> Void)? = nil) {
        UIWindow.fw_mainWindow?.fw_showMessage(text: text, style: style, autoHide: autoHide, interactive: interactive, completion: completion)
    }

    /// 隐藏消息吐司
    public static func fw_hideMessage() {
        UIWindow.fw_mainWindow?.fw_hideMessage()
    }
    
    /// 是否正在显示消息吐司
    public static var fw_isShowingMessage: Bool {
        return UIWindow.fw_mainWindow?.fw_isShowingMessage ?? false
    }
    
}
