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

@_spi(FW) extension UIView {
    
    /// 自定义吐司插件，未设置时自动从插件池加载
    public var fw_toastPlugin: ToastPlugin! {
        get {
            if let toastPlugin = fw_property(forName: "fw_toastPlugin") as? ToastPlugin {
                return toastPlugin
            } else if let toastPlugin = PluginManager.loadPlugin(ToastPlugin.self) {
                return toastPlugin
            }
            return ToastPluginImpl.shared
        }
        set {
            fw_setProperty(newValue, forName: "fw_toastPlugin")
        }
    }
    
    /// 设置吐司外间距，默认zero
    @objc(__fw_toastInsets)
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
    public func fw_showLoading(text: Any? = nil, cancelBlock: (() -> Void)? = nil) {
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
        plugin.showLoading?(withAttributedText: attributedText, cancel: cancelBlock, in: self)
    }

    /// 隐藏加载吐司，可指定延迟隐藏从而实现连续的加载效果
    public func fw_hideLoading(delayed: Bool = false) {
        var plugin: ToastPlugin
        if let toastPlugin = self.fw_toastPlugin, toastPlugin.responds(to: #selector(ToastPlugin.hideLoading(_:in:))) {
            plugin = toastPlugin
        } else {
            plugin = ToastPluginImpl.shared
        }
        plugin.hideLoading?(delayed, in: self)
    }
    
    /// 获取正在显示的加载吐司视图
    public var fw_showingLoadingView: UIView? {
        var plugin: ToastPlugin
        if let toastPlugin = self.fw_toastPlugin, toastPlugin.responds(to: #selector(ToastPlugin.showingLoading(_:))) {
            plugin = toastPlugin
        } else {
            plugin = ToastPluginImpl.shared
        }
        return plugin.showingLoading!(self)
    }
    
    /// 是否正在显示加载吐司
    public var fw_isShowingLoading: Bool {
        return fw_showingLoadingView != nil
    }
    
    /// 显示进度条吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public func fw_showProgress(_ progress: CGFloat, text: Any? = nil, cancelBlock: (() -> Void)? = nil) {
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
        plugin.showProgress?(withAttributedText: attributedText, progress: progress, cancel: cancelBlock, in: self)
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
    
    /// 获取正在显示的进度条吐司视图
    public var fw_showingProgressView: UIView? {
        var plugin: ToastPlugin
        if let toastPlugin = self.fw_toastPlugin, toastPlugin.responds(to: #selector(ToastPlugin.showingProgressView(_:))) {
            plugin = toastPlugin
        } else {
            plugin = ToastPluginImpl.shared
        }
        return plugin.showingProgressView!(self)
    }
    
    /// 是否正在显示进度条吐司
    public var fw_isShowingProgress: Bool {
        return fw_showingProgressView != nil
    }
    
    /// 显示错误消息吐司，自动隐藏，自动隐藏完成后回调
    public func fw_showMessage(error: Error?, completion: (() -> Void)? = nil) {
        fw_showMessage(
            text: ToastPluginImpl.shared.errorTextFormatter?(error) ?? error?.localizedDescription,
            style: ToastPluginImpl.shared.errorStyleFormatter?(error) ?? .default,
            completion: completion
        )
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
    
    /// 获取正在显示的消息吐司视图
    public var fw_showingMessageView: UIView? {
        var plugin: ToastPlugin
        if let toastPlugin = self.fw_toastPlugin, toastPlugin.responds(to: #selector(ToastPlugin.showingMessageView(_:))) {
            plugin = toastPlugin
        } else {
            plugin = ToastPluginImpl.shared
        }
        return plugin.showingMessageView!(self)
    }
    
    /// 是否正在显示消息吐司
    public var fw_isShowingMessage: Bool {
        return fw_showingMessageView != nil
    }
    
}

@_spi(FW) extension UIViewController {
    
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
    @objc(__fw_showLoadingWithText:cancel:)
    public func fw_showLoading(text: Any? = nil, cancelBlock: (() -> Void)? = nil) {
        fw_toastContainerView?.fw_showLoading(text: text, cancelBlock: cancelBlock)
    }

    /// 隐藏加载吐司，可指定延迟隐藏从而实现连续的加载效果
    @objc(__fw_hideLoading:)
    public func fw_hideLoading(delayed: Bool = false) {
        fw_toastContainerView?.fw_hideLoading(delayed: delayed)
    }
    
    /// 获取正在显示的加载吐司视图
    public var fw_showingLoadingView: UIView? {
        return fw_toastContainerView?.fw_showingLoadingView
    }
    
    /// 是否正在显示加载吐司
    public var fw_isShowingLoading: Bool {
        return fw_toastContainerView?.fw_isShowingLoading ?? false
    }
    
    /// 显示进度条吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public func fw_showProgress(_ progress: CGFloat, text: Any? = nil, cancelBlock: (() -> Void)? = nil) {
        fw_toastContainerView?.fw_showProgress(progress, text: text, cancelBlock: cancelBlock)
    }

    /// 隐藏进度条吐司
    public func fw_hideProgress() {
        fw_toastContainerView?.fw_hideProgress()
    }
    
    /// 获取正在显示的进度条吐司视图
    public var fw_showingProgressView: UIView? {
        return fw_toastContainerView?.fw_showingProgressView
    }
    
    /// 是否正在显示进度条吐司
    public var fw_isShowingProgress: Bool {
        return fw_toastContainerView?.fw_isShowingProgress ?? false
    }
    
    /// 显示错误消息吐司，自动隐藏，自动隐藏完成后回调
    public func fw_showMessage(error: Error?, completion: (() -> Void)? = nil) {
        fw_toastContainerView?.fw_showMessage(error: error, completion: completion)
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
    
    /// 获取正在显示的消息吐司视图
    public var fw_showingMessageView: UIView? {
        return fw_toastContainerView?.fw_showingMessageView
    }
    
    /// 是否正在显示消息吐司
    public var fw_isShowingMessage: Bool {
        return fw_toastContainerView?.fw_isShowingMessage ?? false
    }
    
}

@_spi(FW) extension UIWindow {
    
    /// 设置吐司外间距，默认zero
    public static var fw_toastInsets: UIEdgeInsets {
        get { return UIWindow.fw_mainWindow?.fw_toastInsets ?? .zero }
        set { UIWindow.fw_mainWindow?.fw_toastInsets = newValue }
    }
    
    /// 显示加载吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public static func fw_showLoading(text: Any? = nil, cancelBlock: (() -> Void)? = nil) {
        UIWindow.fw_mainWindow?.fw_showLoading(text: text, cancelBlock: cancelBlock)
    }

    /// 隐藏加载吐司，可指定延迟隐藏从而实现连续的加载效果
    public static func fw_hideLoading(delayed: Bool = false) {
        UIWindow.fw_mainWindow?.fw_hideLoading(delayed: delayed)
    }
    
    /// 获取正在显示的加载吐司视图
    public static var fw_showingLoadingView: UIView? {
        return UIWindow.fw_mainWindow?.fw_showingLoadingView
    }
    
    /// 是否正在显示加载吐司
    public static var fw_isShowingLoading: Bool {
        return UIWindow.fw_mainWindow?.fw_isShowingLoading ?? false
    }
    
    /// 显示进度条吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public static func fw_showProgress(_ progress: CGFloat, text: Any? = nil, cancelBlock: (() -> Void)? = nil) {
        UIWindow.fw_mainWindow?.fw_showProgress(progress, text: text, cancelBlock: cancelBlock)
    }

    /// 隐藏进度条吐司
    public static func fw_hideProgress() {
        UIWindow.fw_mainWindow?.fw_hideProgress()
    }
    
    /// 获取正在显示的进度条吐司视图
    public static var fw_showingProgressView: UIView? {
        return UIWindow.fw_mainWindow?.fw_showingProgressView
    }
    
    /// 是否正在显示进度条吐司
    public static var fw_isShowingProgress: Bool {
        return UIWindow.fw_mainWindow?.fw_isShowingProgress ?? false
    }
    
    /// 显示错误消息吐司，自动隐藏，自动隐藏完成后回调
    public static func fw_showMessage(error: Error?, completion: (() -> Void)? = nil) {
        UIWindow.fw_mainWindow?.fw_showMessage(error: error, completion: completion)
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
    
    /// 获取正在显示的消息吐司视图
    public static var fw_showingMessageView: UIView? {
        return UIWindow.fw_mainWindow?.fw_showingMessageView
    }
    
    /// 是否正在显示消息吐司
    public static var fw_isShowingMessage: Bool {
        return UIWindow.fw_mainWindow?.fw_isShowingMessage ?? false
    }
    
}
