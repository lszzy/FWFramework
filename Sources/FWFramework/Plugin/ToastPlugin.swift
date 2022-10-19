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

extension Wrapper where Base: UIView {
    
    /// 自定义吐司插件，未设置时自动从插件池加载
    public var toastPlugin: ToastPlugin? {
        get { return base.__fw_toastPlugin }
        set { base.__fw_toastPlugin = newValue }
    }
    
    /// 设置吐司外间距，默认zero
    public var toastInsets: UIEdgeInsets {
        get { return base.__fw_toastInsets }
        set { base.__fw_toastInsets = newValue }
    }
    
    /// 显示加载吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public func showLoading(text: Any? = nil, cancel: (() -> Void)? = nil) {
        base.__fw_showLoading(withText: text, cancel: cancel)
    }

    /// 隐藏加载吐司
    public func hideLoading() {
        base.__fw_hideLoading()
    }
    
    /// 是否正在显示加载吐司
    public var isShowingLoading: Bool {
        return base.__fw_isShowingLoading
    }
    
    /// 显示进度条吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public func showProgress(_ progress: CGFloat, text: Any? = nil, cancel: (() -> Void)? = nil) {
        base.__fw_showProgress(withText: text, progress: progress, cancel: cancel)
    }

    /// 隐藏进度条吐司
    public func hideProgress() {
        base.__fw_hideProgress()
    }
    
    /// 是否正在显示进度条吐司
    public var isShowingProgress: Bool {
        return base.__fw_isShowingProgress
    }

    /// 显示指定样式消息吐司，自动隐藏，自动隐藏完成后回调，支持String和AttributedString
    public func showMessage(text: Any?, style: ToastStyle = .default, completion: (() -> Void)? = nil) {
        base.__fw_showMessage(withText: text, style: style, completion: completion)
    }

    /// 显示指定样式消息吐司，可设置自动隐藏和允许交互，自动隐藏完成后回调，支持String和AttributedString
    public func showMessage(text: Any?, style: ToastStyle, autoHide: Bool, interactive: Bool, completion: (() -> Void)? = nil) {
        base.__fw_showMessage(withText: text, style: style, autoHide: autoHide, interactive: interactive, completion: completion)
    }

    /// 隐藏消息吐司
    public func hideMessage() {
        base.__fw_hideMessage()
    }
    
    /// 是否正在显示消息吐司
    public var isShowingMessage: Bool {
        return base.__fw_isShowingMessage
    }
    
}

extension Wrapper where Base: UIViewController {
    
    /// 设置吐司是否显示在window上，默认NO，显示到view上
    public var toastInWindow: Bool {
        get { return base.__fw_toastInWindow }
        set { base.__fw_toastInWindow = newValue }
    }
    
    /// 设置吐司是否显示在祖先视图上，默认NO，显示到view上
    public var toastInAncestor: Bool {
        get { return base.__fw_toastInAncestor }
        set { base.__fw_toastInAncestor = newValue }
    }
    
    /// 设置吐司外间距，默认zero
    public var toastInsets: UIEdgeInsets {
        get { return base.__fw_toastInsets }
        set { base.__fw_toastInsets = newValue }
    }
    
    /// 显示加载吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public func showLoading(text: Any? = nil, cancel: (() -> Void)? = nil) {
        base.__fw_showLoading(withText: text, cancel: cancel)
    }

    /// 隐藏加载吐司
    public func hideLoading() {
        base.__fw_hideLoading()
    }
    
    public var isShowingLoading: Bool {
        return base.__fw_isShowingLoading
    }
    
    /// 显示进度条吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public func showProgress(_ progress: CGFloat, text: Any? = nil, cancel: (() -> Void)? = nil) {
        base.__fw_showProgress(withText: text, progress: progress, cancel: cancel)
    }

    /// 隐藏进度条吐司
    public func hideProgress() {
        base.__fw_hideProgress()
    }
    
    /// 是否正在显示进度条吐司
    public var isShowingProgress: Bool {
        return base.__fw_isShowingProgress
    }

    /// 显示指定样式消息吐司，自动隐藏，自动隐藏完成后回调，支持String和AttributedString
    public func showMessage(text: Any?, style: ToastStyle = .default, completion: (() -> Void)? = nil) {
        base.__fw_showMessage(withText: text, style: style, completion: completion)
    }

    /// 显示指定样式消息吐司，可设置自动隐藏和允许交互，自动隐藏完成后回调，支持String和AttributedString
    public func showMessage(text: Any?, style: ToastStyle, autoHide: Bool, interactive: Bool, completion: (() -> Void)? = nil) {
        base.__fw_showMessage(withText: text, style: style, autoHide: autoHide, interactive: interactive, completion: completion)
    }

    /// 隐藏消息吐司
    public func hideMessage() {
        base.__fw_hideMessage()
    }
    
    /// 是否正在显示消息吐司
    public var isShowingMessage: Bool {
        return base.__fw_isShowingMessage
    }
    
}

extension Wrapper where Base: UIWindow {
    
    /// 设置吐司外间距，默认zero
    public static var toastInsets: UIEdgeInsets {
        get { return Base.__fw_toastInsets }
        set { Base.__fw_toastInsets = newValue }
    }
    
    /// 显示加载吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public static func showLoading(text: Any? = nil, cancel: (() -> Void)? = nil) {
        Base.__fw_showLoading(withText: text, cancel: cancel)
    }

    /// 隐藏加载吐司
    public static func hideLoading() {
        Base.__fw_hideLoading()
    }
    
    public static var isShowingLoading: Bool {
        return Base.__fw_isShowingLoading
    }
    
    /// 显示进度条吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public static func showProgress(_ progress: CGFloat, text: Any? = nil, cancel: (() -> Void)? = nil) {
        Base.__fw_showProgress(withText: text, progress: progress, cancel: cancel)
    }

    /// 隐藏进度条吐司
    public static func hideProgress() {
        Base.__fw_hideProgress()
    }
    
    /// 是否正在显示进度条吐司
    public static var isShowingProgress: Bool {
        return Base.__fw_isShowingProgress
    }

    /// 显示指定样式消息吐司，自动隐藏，自动隐藏完成后回调，支持String和AttributedString
    public static func showMessage(text: Any?, style: ToastStyle = .default, completion: (() -> Void)? = nil) {
        Base.__fw_showMessage(withText: text, style: style, completion: completion)
    }

    /// 显示指定样式消息吐司，可设置自动隐藏和允许交互，自动隐藏完成后回调，支持String和AttributedString
    public static func showMessage(text: Any?, style: ToastStyle, autoHide: Bool, interactive: Bool, completion: (() -> Void)? = nil) {
        Base.__fw_showMessage(withText: text, style: style, autoHide: autoHide, interactive: interactive, completion: completion)
    }

    /// 隐藏消息吐司
    public static func hideMessage() {
        Base.__fw_hideMessage()
    }
    
    /// 是否正在显示消息吐司
    public static var isShowingMessage: Bool {
        return Base.__fw_isShowingMessage
    }
    
}
