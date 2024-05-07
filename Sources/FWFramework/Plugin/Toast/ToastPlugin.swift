//
//  ToastPlugin.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - Wrapper+UIView
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
    public func showLoading(text: AttributedStringParameter? = nil, cancelBlock: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
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
    public func showProgress(_ progress: CGFloat, text: AttributedStringParameter? = nil, cancelBlock: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
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
    public func showMessage(text: AttributedStringParameter?, style: ToastStyle = .default, completion: (() -> Void)? = nil) {
        base.fw_showMessage(text: text, style: style, completion: completion)
    }

    /// 显示指定样式消息吐司，可设置自动隐藏和允许交互，自动隐藏完成后回调，支持String和AttributedString
    public func showMessage(text: AttributedStringParameter?, style: ToastStyle, autoHide: Bool, interactive: Bool, completion: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
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

// MARK: - Wrapper+UIViewController
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
    
    /// 获取或设置吐司容器视图，默认view
    public var toastContainer: UIView! {
        get { return base.fw_toastContainer }
        set { base.fw_toastContainer = newValue }
    }
    
    /// 显示加载吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public func showLoading(text: AttributedStringParameter? = nil, cancelBlock: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
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
    public func showProgress(_ progress: CGFloat, text: AttributedStringParameter? = nil, cancelBlock: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
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
    public func showMessage(text: AttributedStringParameter?, style: ToastStyle = .default, completion: (() -> Void)? = nil) {
        base.fw_showMessage(text: text, style: style, completion: completion)
    }

    /// 显示指定样式消息吐司，可设置自动隐藏和允许交互，自动隐藏完成后回调，支持String和AttributedString
    public func showMessage(text: AttributedStringParameter?, style: ToastStyle, autoHide: Bool, interactive: Bool, completion: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
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

// MARK: - Wrapper+UIWindow
extension Wrapper where Base: UIWindow {
    /// 自定义吐司插件，未设置时自动从插件池加载
    public static var toastPlugin: ToastPlugin! {
        get { return Base.fw_toastPlugin }
        set { Base.fw_toastPlugin = newValue }
    }
    
    /// 设置吐司外间距，默认zero
    public static var toastInsets: UIEdgeInsets {
        get { return Base.fw_toastInsets }
        set { Base.fw_toastInsets = newValue }
    }
    
    /// 显示加载吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public static func showLoading(text: AttributedStringParameter? = nil, cancelBlock: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
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
    public static func showProgress(_ progress: CGFloat, text: AttributedStringParameter? = nil, cancelBlock: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
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
    public static func showMessage(text: AttributedStringParameter?, style: ToastStyle = .default, completion: (() -> Void)? = nil) {
        Base.fw_showMessage(text: text, style: style, completion: completion)
    }

    /// 显示指定样式消息吐司，可设置自动隐藏和允许交互，自动隐藏完成后回调，支持String和AttributedString
    public static func showMessage(text: AttributedStringParameter?, style: ToastStyle, autoHide: Bool, interactive: Bool, completion: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
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

// MARK: - ToastPlugin
/// 消息吐司可扩展样式枚举
public struct ToastStyle: RawRepresentable, Equatable, Hashable {
    
    public typealias RawValue = Int
    
    /// 默认消息样式
    public static let `default`: ToastStyle = .init(0)
    /// 成功消息样式
    public static let success: ToastStyle = .init(1)
    /// 失败消息样式
    public static let failure: ToastStyle = .init(2)
    /// 警告消息样式
    public static let warning: ToastStyle = .init(3)
    
    public var rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public init(_ rawValue: Int) {
        self.rawValue = rawValue
    }
    
}

/// 吐司插件协议，应用可自定义吐司插件实现
public protocol ToastPlugin: AnyObject {
    
    /// 显示加载吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之
    func showLoading(attributedText: NSAttributedString?, cancelBlock: (() -> Void)?, customBlock: ((Any) -> Void)?, in view: UIView)

    /// 隐藏加载吐司，可指定延迟隐藏从而实现连续的加载效果
    func hideLoading(delayed: Bool, in view: UIView)

    /// 获取正在显示的加载吐司视图
    func showingLoadingView(in view: UIView) -> UIView?

    /// 显示进度条吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之
    func showProgress(attributedText: NSAttributedString?, progress: CGFloat, cancelBlock: (() -> Void)?, customBlock: ((Any) -> Void)?, in view: UIView)

    /// 隐藏进度条吐司
    func hideProgress(in view: UIView)

    /// 获取正在显示的进度条吐司视图
    func showingProgressView(in view: UIView) -> UIView?

    /// 显示指定样式消息吐司，可设置自动隐藏和允许交互，自动隐藏完成后回调
    func showMessage(attributedText: NSAttributedString?, style: ToastStyle, autoHide: Bool, interactive: Bool, completion: (() -> Void)?, customBlock: ((Any) -> Void)?, in view: UIView)

    /// 隐藏消息吐司
    func hideMessage(in view: UIView)

    /// 获取正在显示的消息吐司视图
    func showingMessageView(in view: UIView) -> UIView?
    
}

extension ToastPlugin {
    
    /// 默认实现，显示加载吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之
    public func showLoading(attributedText: NSAttributedString?, cancelBlock: (() -> Void)?, customBlock: ((Any) -> Void)?, in view: UIView) {
        ToastPluginImpl.shared.showLoading(attributedText: attributedText, cancelBlock: cancelBlock, customBlock: customBlock, in: view)
    }

    /// 默认实现，隐藏加载吐司，可指定延迟隐藏从而实现连续的加载效果
    public func hideLoading(delayed: Bool, in view: UIView) {
        ToastPluginImpl.shared.hideLoading(delayed: delayed, in: view)
    }

    /// 默认实现，获取正在显示的加载吐司视图
    public func showingLoadingView(in view: UIView) -> UIView? {
        return ToastPluginImpl.shared.showingLoadingView(in: view)
    }

    /// 默认实现，显示进度条吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之
    public func showProgress(attributedText: NSAttributedString?, progress: CGFloat, cancelBlock: (() -> Void)?, customBlock: ((Any) -> Void)?, in view: UIView) {
        ToastPluginImpl.shared.showProgress(attributedText: attributedText, progress: progress, cancelBlock: cancelBlock, customBlock: customBlock, in: view)
    }

    /// 默认实现，隐藏进度条吐司
    public func hideProgress(in view: UIView) {
        ToastPluginImpl.shared.hideProgress(in: view)
    }

    /// 默认实现，获取正在显示的进度条吐司视图
    public func showingProgressView(in view: UIView) -> UIView? {
        return ToastPluginImpl.shared.showingProgressView(in: view)
    }

    /// 默认实现，显示指定样式消息吐司，可设置自动隐藏和允许交互，自动隐藏完成后回调
    public func showMessage(attributedText: NSAttributedString?, style: ToastStyle, autoHide: Bool, interactive: Bool, completion: (() -> Void)?, customBlock: ((Any) -> Void)?, in view: UIView) {
        ToastPluginImpl.shared.showMessage(attributedText: attributedText, style: style, autoHide: autoHide, interactive: interactive, completion: completion, customBlock: customBlock, in: view)
    }

    /// 默认实现，隐藏消息吐司
    public func hideMessage(in view: UIView) {
        ToastPluginImpl.shared.hideMessage(in: view)
    }

    /// 默认实现，获取正在显示的消息吐司视图
    public func showingMessageView(in view: UIView) -> UIView? {
        return ToastPluginImpl.shared.showingMessageView(in: view)
    }
    
}

// MARK: - UIView+ToastPlugin
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
    public func fw_showLoading(text: AttributedStringParameter? = nil, cancelBlock: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        let attributedText = text?.attributedStringValue
        let plugin = self.fw_toastPlugin ?? ToastPluginImpl.shared
        plugin.showLoading(attributedText: attributedText, cancelBlock: cancelBlock, customBlock: customBlock, in: self)
    }

    /// 隐藏加载吐司，可指定延迟隐藏从而实现连续的加载效果
    public func fw_hideLoading(delayed: Bool = false) {
        let plugin = self.fw_toastPlugin ?? ToastPluginImpl.shared
        plugin.hideLoading(delayed: delayed, in: self)
    }
    
    /// 获取正在显示的加载吐司视图
    public var fw_showingLoadingView: UIView? {
        let plugin = self.fw_toastPlugin ?? ToastPluginImpl.shared
        return plugin.showingLoadingView(in: self)
    }
    
    /// 是否正在显示加载吐司
    public var fw_isShowingLoading: Bool {
        return fw_showingLoadingView != nil
    }
    
    /// 显示进度条吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public func fw_showProgress(_ progress: CGFloat, text: AttributedStringParameter? = nil, cancelBlock: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        let attributedText = text?.attributedStringValue
        let plugin = self.fw_toastPlugin ?? ToastPluginImpl.shared
        plugin.showProgress(attributedText: attributedText, progress: progress, cancelBlock: cancelBlock, customBlock: customBlock, in: self)
    }

    /// 隐藏进度条吐司
    public func fw_hideProgress() {
        let plugin = self.fw_toastPlugin ?? ToastPluginImpl.shared
        plugin.hideProgress(in: self)
    }
    
    /// 获取正在显示的进度条吐司视图
    public var fw_showingProgressView: UIView? {
        let plugin = self.fw_toastPlugin ?? ToastPluginImpl.shared
        return plugin.showingProgressView(in: self)
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
    public func fw_showMessage(text: AttributedStringParameter?, style: ToastStyle = .default, completion: (() -> Void)? = nil) {
        fw_showMessage(text: text, style: style, autoHide: true, interactive: completion != nil ? false : true, completion: completion)
    }

    /// 显示指定样式消息吐司，可设置自动隐藏和允许交互，自动隐藏完成后回调，支持String和AttributedString
    public func fw_showMessage(text: AttributedStringParameter?, style: ToastStyle, autoHide: Bool, interactive: Bool, completion: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        let attributedText = text?.attributedStringValue
        let plugin = self.fw_toastPlugin ?? ToastPluginImpl.shared
        plugin.showMessage(attributedText: attributedText, style: style, autoHide: autoHide, interactive: interactive, completion: completion, customBlock: customBlock, in: self)
    }

    /// 隐藏消息吐司
    public func fw_hideMessage() {
        let plugin = self.fw_toastPlugin ?? ToastPluginImpl.shared
        plugin.hideMessage(in: self)
    }
    
    /// 获取正在显示的消息吐司视图
    public var fw_showingMessageView: UIView? {
        let plugin = self.fw_toastPlugin ?? ToastPluginImpl.shared
        return plugin.showingMessageView(in: self)
    }
    
    /// 是否正在显示消息吐司
    public var fw_isShowingMessage: Bool {
        return fw_showingMessageView != nil
    }
    
}

// MARK: - UIViewController+ToastPlugin
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
    
    /// 自定义吐司插件，未设置时自动从插件池加载
    public var fw_toastPlugin: ToastPlugin! {
        get { return fw_toastContainer.fw_toastPlugin }
        set { fw_toastContainer.fw_toastPlugin = newValue }
    }
    
    /// 设置吐司外间距，默认zero
    public var fw_toastInsets: UIEdgeInsets {
        get { return fw_toastContainer.fw_toastInsets }
        set { fw_toastContainer.fw_toastInsets = newValue }
    }
    
    /// 获取或设置吐司容器视图，默认view
    public var fw_toastContainer: UIView! {
        get {
            if let view = fw_property(forName: "fw_toastContainer") as? UIView {
                return view
            }
            if self.fw_toastInWindow { return UIWindow.fw_mainWindow ?? self.view }
            if self.fw_toastInAncestor { return self.fw_ancestorView }
            return self.view
        }
        set {
            fw_setPropertyWeak(newValue, forName: "fw_toastContainer")
        }
    }
    
    /// 显示加载吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public func fw_showLoading(text: AttributedStringParameter? = nil, cancelBlock: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        fw_toastContainer.fw_showLoading(text: text, cancelBlock: cancelBlock, customBlock: customBlock)
    }

    /// 隐藏加载吐司，可指定延迟隐藏从而实现连续的加载效果
    public func fw_hideLoading(delayed: Bool = false) {
        fw_toastContainer.fw_hideLoading(delayed: delayed)
    }
    
    /// 获取正在显示的加载吐司视图
    public var fw_showingLoadingView: UIView? {
        return fw_toastContainer.fw_showingLoadingView
    }
    
    /// 是否正在显示加载吐司
    public var fw_isShowingLoading: Bool {
        return fw_toastContainer.fw_isShowingLoading
    }
    
    /// 显示进度条吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public func fw_showProgress(_ progress: CGFloat, text: AttributedStringParameter? = nil, cancelBlock: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        fw_toastContainer.fw_showProgress(progress, text: text, cancelBlock: cancelBlock, customBlock: customBlock)
    }

    /// 隐藏进度条吐司
    public func fw_hideProgress() {
        fw_toastContainer.fw_hideProgress()
    }
    
    /// 获取正在显示的进度条吐司视图
    public var fw_showingProgressView: UIView? {
        return fw_toastContainer.fw_showingProgressView
    }
    
    /// 是否正在显示进度条吐司
    public var fw_isShowingProgress: Bool {
        return fw_toastContainer.fw_isShowingProgress
    }
    
    /// 显示错误消息吐司，自动隐藏，自动隐藏完成后回调
    public func fw_showMessage(error: Error?, completion: (() -> Void)? = nil) {
        fw_toastContainer.fw_showMessage(error: error, completion: completion)
    }

    /// 显示指定样式消息吐司，自动隐藏，自动隐藏完成后回调，支持String和AttributedString
    public func fw_showMessage(text: AttributedStringParameter?, style: ToastStyle = .default, completion: (() -> Void)? = nil) {
        fw_toastContainer.fw_showMessage(text: text, style: style, completion: completion)
    }

    /// 显示指定样式消息吐司，可设置自动隐藏和允许交互，自动隐藏完成后回调，支持String和AttributedString
    public func fw_showMessage(text: AttributedStringParameter?, style: ToastStyle, autoHide: Bool, interactive: Bool, completion: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        fw_toastContainer.fw_showMessage(text: text, style: style, autoHide: autoHide, interactive: interactive, completion: completion, customBlock: customBlock)
    }

    /// 隐藏消息吐司
    public func fw_hideMessage() {
        fw_toastContainer.fw_hideMessage()
    }
    
    /// 获取正在显示的消息吐司视图
    public var fw_showingMessageView: UIView? {
        return fw_toastContainer.fw_showingMessageView
    }
    
    /// 是否正在显示消息吐司
    public var fw_isShowingMessage: Bool {
        return fw_toastContainer.fw_isShowingMessage
    }
    
}

// MARK: - UIWindow+ToastPlugin
@_spi(FW) extension UIWindow {
    
    /// 自定义吐司插件，未设置时自动从插件池加载
    public static var fw_toastPlugin: ToastPlugin! {
        get { return UIWindow.fw_mainWindow?.fw_toastPlugin }
        set { UIWindow.fw_mainWindow?.fw_toastPlugin = newValue }
    }
    
    /// 设置吐司外间距，默认zero
    public static var fw_toastInsets: UIEdgeInsets {
        get { return UIWindow.fw_mainWindow?.fw_toastInsets ?? .zero }
        set { UIWindow.fw_mainWindow?.fw_toastInsets = newValue }
    }
    
    /// 显示加载吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public static func fw_showLoading(text: AttributedStringParameter? = nil, cancelBlock: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        UIWindow.fw_mainWindow?.fw_showLoading(text: text, cancelBlock: cancelBlock, customBlock: customBlock)
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
    public static func fw_showProgress(_ progress: CGFloat, text: AttributedStringParameter? = nil, cancelBlock: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        UIWindow.fw_mainWindow?.fw_showProgress(progress, text: text, cancelBlock: cancelBlock, customBlock: customBlock)
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
    public static func fw_showMessage(text: AttributedStringParameter?, style: ToastStyle = .default, completion: (() -> Void)? = nil) {
        UIWindow.fw_mainWindow?.fw_showMessage(text: text, style: style, completion: completion)
    }

    /// 显示指定样式消息吐司，可设置自动隐藏和允许交互，自动隐藏完成后回调，支持String和AttributedString
    public static func fw_showMessage(text: AttributedStringParameter?, style: ToastStyle, autoHide: Bool, interactive: Bool, completion: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        UIWindow.fw_mainWindow?.fw_showMessage(text: text, style: style, autoHide: autoHide, interactive: interactive, completion: completion, customBlock: customBlock)
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

// MARK: - FrameworkAutoloader+ToastPlugin
@objc extension FrameworkAutoloader {
    
    static func loadPlugin_ToastPlugin() {
        RequestContextAccessory.showErrorBlock = { context, error in
            if let viewController = context as? UIViewController {
                viewController.fw_showMessage(error: error)
            } else if let view = context as? UIView {
                view.fw_showMessage(error: error)
            } else {
                UIWindow.fw_showMessage(error: error)
            }
        }
        
        RequestContextAccessory.showLoadingBlock = { context in
            if let viewController = context as? UIViewController {
                viewController.fw_showLoading()
            } else if let view = context as? UIView {
                view.fw_showLoading()
            }
        }
        
        RequestContextAccessory.hideLoadingBlock = { context in
            if let viewController = context as? UIViewController {
                viewController.fw_hideLoading()
            } else if let view = context as? UIView {
                view.fw_hideLoading()
            }
        }
    }
    
}
