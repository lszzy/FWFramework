//
//  ToastPlugin+Wrapper.swift
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
    public var toastPlugin: ToastPlugin! {
        get { return base.fw_toastPlugin }
        set { base.fw_toastPlugin = newValue }
    }
    
    /// 设置吐司外间距，默认zero
    public var toastInsets: UIEdgeInsets {
        get { return base.fw_toastInsets }
        set { base.fw_toastInsets = newValue }
    }
    
    /// 显示加载吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public func showLoading(text: Any? = nil, cancelBlock: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        base.fw_showLoading(text: text, cancelBlock: cancelBlock, customBlock: customBlock)
    }

    /// 隐藏加载吐司，可指定延迟隐藏从而实现连续的加载效果
    public func hideLoading(delayed: Bool = false) {
        base.fw_hideLoading(delayed: delayed)
    }
    
    /// 获取正在显示的加载吐司视图
    public var showingLoadingView: UIView? {
        return base.fw_showingLoadingView
    }
    
    /// 是否正在显示加载吐司
    public var isShowingLoading: Bool {
        return base.fw_isShowingLoading
    }
    
    /// 显示进度条吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public func showProgress(_ progress: CGFloat, text: Any? = nil, cancelBlock: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        base.fw_showProgress(progress, text: text, cancelBlock: cancelBlock, customBlock: customBlock)
    }

    /// 隐藏进度条吐司
    public func hideProgress() {
        base.fw_hideProgress()
    }
    
    /// 获取正在显示的进度条吐司视图
    public var showingProgressView: UIView? {
        return base.fw_showingProgressView
    }
    
    /// 是否正在显示进度条吐司
    public var isShowingProgress: Bool {
        return base.fw_isShowingProgress
    }
    
    /// 显示错误消息吐司，自动隐藏，自动隐藏完成后回调
    public func showMessage(error: Error?, completion: (() -> Void)? = nil) {
        base.fw_showMessage(error: error, completion: completion)
    }

    /// 显示指定样式消息吐司，自动隐藏，自动隐藏完成后回调，支持String和AttributedString
    public func showMessage(text: Any?, style: ToastStyle = .default, completion: (() -> Void)? = nil) {
        base.fw_showMessage(text: text, style: style, completion: completion)
    }

    /// 显示指定样式消息吐司，可设置自动隐藏和允许交互，自动隐藏完成后回调，支持String和AttributedString
    public func showMessage(text: Any?, style: ToastStyle, autoHide: Bool, interactive: Bool, completion: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        base.fw_showMessage(text: text, style: style, autoHide: autoHide, interactive: interactive, completion: completion, customBlock: customBlock)
    }

    /// 隐藏消息吐司
    public func hideMessage() {
        base.fw_hideMessage()
    }
    
    /// 获取正在显示的消息吐司视图
    public var showingMessageView: UIView? {
        return base.fw_showingMessageView
    }
    
    /// 是否正在显示消息吐司
    public var isShowingMessage: Bool {
        return base.fw_isShowingMessage
    }
    
}

extension Wrapper where Base: UIViewController {
    
    /// 设置吐司是否显示在window上，默认NO，显示到view上
    public var toastInWindow: Bool {
        get { return base.fw_toastInWindow }
        set { base.fw_toastInWindow = newValue }
    }
    
    /// 设置吐司是否显示在祖先视图上，默认NO，显示到view上
    public var toastInAncestor: Bool {
        get { return base.fw_toastInAncestor }
        set { base.fw_toastInAncestor = newValue }
    }
    
    /// 设置吐司外间距，默认zero
    public var toastInsets: UIEdgeInsets {
        get { return base.fw_toastInsets }
        set { base.fw_toastInsets = newValue }
    }
    
    /// 显示加载吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public func showLoading(text: Any? = nil, cancelBlock: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        base.fw_showLoading(text: text, cancelBlock: cancelBlock, customBlock: customBlock)
    }

    /// 隐藏加载吐司，可指定延迟隐藏从而实现连续的加载效果
    public func hideLoading(delayed: Bool = false) {
        base.fw_hideLoading(delayed: delayed)
    }
    
    /// 获取正在显示的加载吐司视图
    public var showingLoadingView: UIView? {
        return base.fw_showingLoadingView
    }
    
    /// 是否正在显示加载吐司
    public var isShowingLoading: Bool {
        return base.fw_isShowingLoading
    }
    
    /// 显示进度条吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public func showProgress(_ progress: CGFloat, text: Any? = nil, cancelBlock: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        base.fw_showProgress(progress, text: text, cancelBlock: cancelBlock, customBlock: customBlock)
    }

    /// 隐藏进度条吐司
    public func hideProgress() {
        base.fw_hideProgress()
    }
    
    /// 获取正在显示的进度条吐司视图
    public var showingProgressView: UIView? {
        return base.fw_showingProgressView
    }
    
    /// 是否正在显示进度条吐司
    public var isShowingProgress: Bool {
        return base.fw_isShowingProgress
    }
    
    /// 显示错误消息吐司，自动隐藏，自动隐藏完成后回调
    public func showMessage(error: Error?, completion: (() -> Void)? = nil) {
        base.fw_showMessage(error: error, completion: completion)
    }

    /// 显示指定样式消息吐司，自动隐藏，自动隐藏完成后回调，支持String和AttributedString
    public func showMessage(text: Any?, style: ToastStyle = .default, completion: (() -> Void)? = nil) {
        base.fw_showMessage(text: text, style: style, completion: completion)
    }

    /// 显示指定样式消息吐司，可设置自动隐藏和允许交互，自动隐藏完成后回调，支持String和AttributedString
    public func showMessage(text: Any?, style: ToastStyle, autoHide: Bool, interactive: Bool, completion: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        base.fw_showMessage(text: text, style: style, autoHide: autoHide, interactive: interactive, completion: completion, customBlock: customBlock)
    }

    /// 隐藏消息吐司
    public func hideMessage() {
        base.fw_hideMessage()
    }
    
    /// 获取正在显示的消息吐司视图
    public var showingMessageView: UIView? {
        return base.fw_showingMessageView
    }
    
    /// 是否正在显示消息吐司
    public var isShowingMessage: Bool {
        return base.fw_isShowingMessage
    }
    
}

extension Wrapper where Base: UIWindow {
    
    /// 设置吐司外间距，默认zero
    public static var toastInsets: UIEdgeInsets {
        get { return Base.fw_toastInsets }
        set { Base.fw_toastInsets = newValue }
    }
    
    /// 显示加载吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public static func showLoading(text: Any? = nil, cancelBlock: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        Base.fw_showLoading(text: text, cancelBlock: cancelBlock, customBlock: customBlock)
    }

    /// 隐藏加载吐司，可指定延迟隐藏从而实现连续的加载效果
    public static func hideLoading(delayed: Bool = false) {
        Base.fw_hideLoading(delayed: delayed)
    }
    
    /// 获取正在显示的加载吐司视图
    public static var showingLoadingView: UIView? {
        return Base.fw_showingLoadingView
    }
    
    /// 是否正在显示加载吐司
    public static var isShowingLoading: Bool {
        return Base.fw_isShowingLoading
    }
    
    /// 显示进度条吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public static func showProgress(_ progress: CGFloat, text: Any? = nil, cancelBlock: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        Base.fw_showProgress(progress, text: text, cancelBlock: cancelBlock, customBlock: customBlock)
    }

    /// 隐藏进度条吐司
    public static func hideProgress() {
        Base.fw_hideProgress()
    }
    
    /// 获取正在显示的进度条吐司视图
    public static var showingProgressView: UIView? {
        return Base.fw_showingProgressView
    }
    
    /// 是否正在显示进度条吐司
    public static var isShowingProgress: Bool {
        return Base.fw_isShowingProgress
    }
    
    /// 显示错误消息吐司，自动隐藏，自动隐藏完成后回调
    public static func showMessage(error: Error?, completion: (() -> Void)? = nil) {
        Base.fw_showMessage(error: error, completion: completion)
    }

    /// 显示指定样式消息吐司，自动隐藏，自动隐藏完成后回调，支持String和AttributedString
    public static func showMessage(text: Any?, style: ToastStyle = .default, completion: (() -> Void)? = nil) {
        Base.fw_showMessage(text: text, style: style, completion: completion)
    }

    /// 显示指定样式消息吐司，可设置自动隐藏和允许交互，自动隐藏完成后回调，支持String和AttributedString
    public static func showMessage(text: Any?, style: ToastStyle, autoHide: Bool, interactive: Bool, completion: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        Base.fw_showMessage(text: text, style: style, autoHide: autoHide, interactive: interactive, completion: completion, customBlock: customBlock)
    }

    /// 隐藏消息吐司
    public static func hideMessage() {
        Base.fw_hideMessage()
    }
    
    /// 获取正在显示的消息吐司视图
    public static var showingMessageView: UIView? {
        return Base.fw_showingMessageView
    }
    
    /// 是否正在显示消息吐司
    public static var isShowingMessage: Bool {
        return Base.fw_isShowingMessage
    }
    
}
