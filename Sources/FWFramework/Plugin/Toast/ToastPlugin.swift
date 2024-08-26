//
//  ToastPlugin.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - Wrapper+UIView
@MainActor extension Wrapper where Base: UIView {
    /// 自定义吐司插件，未设置时自动从插件池加载
    public var toastPlugin: ToastPlugin! {
        get {
            if let toastPlugin = property(forName: "toastPlugin") as? ToastPlugin {
                return toastPlugin
            } else if let toastPlugin = PluginManager.loadPlugin(ToastPlugin.self) {
                return toastPlugin
            }
            return ToastPluginImpl.shared
        }
        set {
            setProperty(newValue, forName: "toastPlugin")
        }
    }

    /// 设置吐司外间距，默认zero
    public var toastInsets: UIEdgeInsets {
        get {
            if let value = property(forName: "toastInsets") as? NSValue {
                return value.uiEdgeInsetsValue
            }
            return .zero
        }
        set {
            setProperty(NSValue(uiEdgeInsets: newValue), forName: "toastInsets")
        }
    }

    /// 显示加载吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public func showLoading(text: AttributedStringParameter? = nil, detail: AttributedStringParameter? = nil, cancelBlock: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        let attributedText = text?.attributedStringValue
        let attributedDetail = detail?.attributedStringValue
        let plugin = toastPlugin ?? ToastPluginImpl.shared
        plugin.showLoading(attributedText: attributedText, attributedDetail: attributedDetail, cancelBlock: cancelBlock, customBlock: customBlock, in: base)
    }

    /// 隐藏加载吐司，可指定延迟隐藏从而实现连续的加载效果
    public func hideLoading(delayed: Bool = false) {
        let plugin = toastPlugin ?? ToastPluginImpl.shared
        plugin.hideLoading(delayed: delayed, in: base)
    }

    /// 获取正在显示的加载吐司视图
    public var showingLoadingView: UIView? {
        let plugin = toastPlugin ?? ToastPluginImpl.shared
        return plugin.showingLoadingView(in: base)
    }

    /// 是否正在显示加载吐司
    public var isShowingLoading: Bool {
        showingLoadingView != nil
    }

    /// 显示进度条吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public func showProgress(_ progress: CGFloat, text: AttributedStringParameter? = nil, detail: AttributedStringParameter? = nil, cancelBlock: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        let attributedText = text?.attributedStringValue
        let attributedDetail = detail?.attributedStringValue
        let plugin = toastPlugin ?? ToastPluginImpl.shared
        plugin.showProgress(attributedText: attributedText, attributedDetail: attributedDetail, progress: progress, cancelBlock: cancelBlock, customBlock: customBlock, in: base)
    }

    /// 隐藏进度条吐司
    public func hideProgress() {
        let plugin = toastPlugin ?? ToastPluginImpl.shared
        plugin.hideProgress(in: base)
    }

    /// 获取正在显示的进度条吐司视图
    public var showingProgressView: UIView? {
        let plugin = toastPlugin ?? ToastPluginImpl.shared
        return plugin.showingProgressView(in: base)
    }

    /// 是否正在显示进度条吐司
    public var isShowingProgress: Bool {
        showingProgressView != nil
    }

    /// 显示错误消息吐司，自动隐藏，自动隐藏完成后回调
    public func showMessage(error: Error?, completion: (() -> Void)? = nil) {
        showMessage(
            text: ToastPluginImpl.shared.errorTextFormatter?(error) ?? error?.localizedDescription,
            detail: ToastPluginImpl.shared.errorDetailFormatter?(error),
            style: ToastPluginImpl.shared.errorStyleFormatter?(error) ?? .default,
            completion: completion
        )
    }

    /// 显示指定样式消息吐司，默认自动隐藏，自动隐藏完成后回调，支持String和AttributedString
    public func showMessage(text: AttributedStringParameter?, detail: AttributedStringParameter? = nil, style: ToastStyle = .default, autoHide: Bool = true, interactive: Bool? = nil, completion: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        let attributedText = text?.attributedStringValue
        let attributedDetail = detail?.attributedStringValue
        let plugin = toastPlugin ?? ToastPluginImpl.shared
        plugin.showMessage(attributedText: attributedText, attributedDetail: attributedDetail, style: style, autoHide: autoHide, interactive: interactive ?? (completion != nil ? false : true), completion: completion, customBlock: customBlock, in: base)
    }

    /// 隐藏消息吐司
    public func hideMessage() {
        let plugin = toastPlugin ?? ToastPluginImpl.shared
        plugin.hideMessage(in: base)
    }

    /// 获取正在显示的消息吐司视图
    public var showingMessageView: UIView? {
        let plugin = toastPlugin ?? ToastPluginImpl.shared
        return plugin.showingMessageView(in: base)
    }

    /// 是否正在显示消息吐司
    public var isShowingMessage: Bool {
        showingMessageView != nil
    }
}

// MARK: - Wrapper+UIViewController
@MainActor extension Wrapper where Base: UIViewController {
    /// 设置吐司是否显示在window上，默认NO，显示到view上
    public var toastInWindow: Bool {
        get { propertyBool(forName: "toastInWindow") }
        set { setPropertyBool(newValue, forName: "toastInWindow") }
    }

    /// 设置吐司是否显示在祖先视图上，默认NO，显示到view上
    public var toastInAncestor: Bool {
        get { propertyBool(forName: "toastInAncestor") }
        set { setPropertyBool(newValue, forName: "toastInAncestor") }
    }

    /// 自定义吐司插件，未设置时自动从插件池加载
    public var toastPlugin: ToastPlugin! {
        get { toastContainer.fw.toastPlugin }
        set { toastContainer.fw.toastPlugin = newValue }
    }

    /// 设置吐司外间距，默认zero
    public var toastInsets: UIEdgeInsets {
        get { toastContainer.fw.toastInsets }
        set { toastContainer.fw.toastInsets = newValue }
    }

    /// 获取或设置吐司容器视图，默认view
    public var toastContainer: UIView! {
        get {
            if let view = property(forName: "toastContainer") as? UIView {
                return view
            }
            if toastInWindow { return UIWindow.fw.main ?? base.view }
            if toastInAncestor { return ancestorView }
            return base.view
        }
        set {
            setPropertyWeak(newValue, forName: "toastContainer")
        }
    }

    /// 显示加载吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public func showLoading(text: AttributedStringParameter? = nil, detail: AttributedStringParameter? = nil, cancelBlock: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        toastContainer.fw.showLoading(text: text, detail: detail, cancelBlock: cancelBlock, customBlock: customBlock)
    }

    /// 隐藏加载吐司，可指定延迟隐藏从而实现连续的加载效果
    public func hideLoading(delayed: Bool = false) {
        toastContainer.fw.hideLoading(delayed: delayed)
    }

    /// 获取正在显示的加载吐司视图
    public var showingLoadingView: UIView? {
        toastContainer.fw.showingLoadingView
    }

    /// 是否正在显示加载吐司
    public var isShowingLoading: Bool {
        toastContainer.fw.isShowingLoading
    }

    /// 显示进度条吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public func showProgress(_ progress: CGFloat, text: AttributedStringParameter? = nil, detail: AttributedStringParameter? = nil, cancelBlock: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        toastContainer.fw.showProgress(progress, text: text, detail: detail, cancelBlock: cancelBlock, customBlock: customBlock)
    }

    /// 隐藏进度条吐司
    public func hideProgress() {
        toastContainer.fw.hideProgress()
    }

    /// 获取正在显示的进度条吐司视图
    public var showingProgressView: UIView? {
        toastContainer.fw.showingProgressView
    }

    /// 是否正在显示进度条吐司
    public var isShowingProgress: Bool {
        toastContainer.fw.isShowingProgress
    }

    /// 显示错误消息吐司，自动隐藏，自动隐藏完成后回调
    public func showMessage(error: Error?, completion: (() -> Void)? = nil) {
        toastContainer.fw.showMessage(error: error, completion: completion)
    }

    /// 显示指定样式消息吐司，默认自动隐藏，自动隐藏完成后回调，支持String和AttributedString
    public func showMessage(text: AttributedStringParameter?, detail: AttributedStringParameter? = nil, style: ToastStyle = .default, autoHide: Bool = true, interactive: Bool? = nil, completion: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        toastContainer.fw.showMessage(text: text, detail: detail, style: style, autoHide: autoHide, interactive: interactive, completion: completion, customBlock: customBlock)
    }

    /// 隐藏消息吐司
    public func hideMessage() {
        toastContainer.fw.hideMessage()
    }

    /// 获取正在显示的消息吐司视图
    public var showingMessageView: UIView? {
        toastContainer.fw.showingMessageView
    }

    /// 是否正在显示消息吐司
    public var isShowingMessage: Bool {
        toastContainer.fw.isShowingMessage
    }
}

// MARK: - Wrapper+UIWindow
@MainActor extension Wrapper where Base: UIWindow {
    /// 自定义吐司插件，未设置时自动从插件池加载
    public static var toastPlugin: ToastPlugin! {
        get { UIWindow.fw.main?.fw.toastPlugin }
        set { UIWindow.fw.main?.fw.toastPlugin = newValue }
    }

    /// 设置吐司外间距，默认zero
    public static var toastInsets: UIEdgeInsets {
        get { UIWindow.fw.main?.fw.toastInsets ?? .zero }
        set { UIWindow.fw.main?.fw.toastInsets = newValue }
    }

    /// 显示加载吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public static func showLoading(text: AttributedStringParameter? = nil, detail: AttributedStringParameter? = nil, cancelBlock: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        UIWindow.fw.main?.fw.showLoading(text: text, detail: detail, cancelBlock: cancelBlock, customBlock: customBlock)
    }

    /// 隐藏加载吐司，可指定延迟隐藏从而实现连续的加载效果
    public static func hideLoading(delayed: Bool = false) {
        UIWindow.fw.main?.fw.hideLoading(delayed: delayed)
    }

    /// 获取正在显示的加载吐司视图
    public static var showingLoadingView: UIView? {
        UIWindow.fw.main?.fw.showingLoadingView
    }

    /// 是否正在显示加载吐司
    public static var isShowingLoading: Bool {
        UIWindow.fw.main?.fw.isShowingLoading ?? false
    }

    /// 显示进度条吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之，支持String和AttributedString
    public static func showProgress(_ progress: CGFloat, text: AttributedStringParameter? = nil, detail: AttributedStringParameter? = nil, cancelBlock: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        UIWindow.fw.main?.fw.showProgress(progress, text: text, detail: detail, cancelBlock: cancelBlock, customBlock: customBlock)
    }

    /// 隐藏进度条吐司
    public static func hideProgress() {
        UIWindow.fw.main?.fw.hideProgress()
    }

    /// 获取正在显示的进度条吐司视图
    public static var showingProgressView: UIView? {
        UIWindow.fw.main?.fw.showingProgressView
    }

    /// 是否正在显示进度条吐司
    public static var isShowingProgress: Bool {
        UIWindow.fw.main?.fw.isShowingProgress ?? false
    }

    /// 显示错误消息吐司，自动隐藏，自动隐藏完成后回调
    public static func showMessage(error: Error?, completion: (() -> Void)? = nil) {
        UIWindow.fw.main?.fw.showMessage(error: error, completion: completion)
    }

    /// 显示指定样式消息吐司，默认自动隐藏，自动隐藏完成后回调，支持String和AttributedString
    public static func showMessage(text: AttributedStringParameter?, detail: AttributedStringParameter? = nil, style: ToastStyle = .default, autoHide: Bool = true, interactive: Bool? = nil, completion: (() -> Void)? = nil, customBlock: ((Any) -> Void)? = nil) {
        UIWindow.fw.main?.fw.showMessage(text: text, detail: detail, style: style, autoHide: autoHide, interactive: interactive, completion: completion, customBlock: customBlock)
    }

    /// 隐藏消息吐司
    public static func hideMessage() {
        UIWindow.fw.main?.fw.hideMessage()
    }

    /// 获取正在显示的消息吐司视图
    public static var showingMessageView: UIView? {
        UIWindow.fw.main?.fw.showingMessageView
    }

    /// 是否正在显示消息吐司
    public static var isShowingMessage: Bool {
        UIWindow.fw.main?.fw.isShowingMessage ?? false
    }
}

// MARK: - ToastPlugin
/// 消息吐司可扩展样式枚举
public struct ToastStyle: RawRepresentable, Equatable, Hashable, Sendable {
    public typealias RawValue = Int

    /// 默认消息样式
    public static let `default`: ToastStyle = .init(0)
    /// 加载吐司样式
    public static let loading: ToastStyle = .init(1)
    /// 进度吐司样式
    public static let progress: ToastStyle = .init(2)
    /// 成功消息样式
    public static let success: ToastStyle = .init(3)
    /// 失败消息样式
    public static let failure: ToastStyle = .init(4)
    /// 警告消息样式
    public static let warning: ToastStyle = .init(5)

    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int) {
        self.rawValue = rawValue
    }
}

/// 吐司插件协议，应用可自定义吐司插件实现
@MainActor public protocol ToastPlugin: AnyObject {
    /// 显示加载吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之
    func showLoading(attributedText: NSAttributedString?, attributedDetail: NSAttributedString?, cancelBlock: (() -> Void)?, customBlock: ((Any) -> Void)?, in view: UIView)

    /// 隐藏加载吐司，可指定延迟隐藏从而实现连续的加载效果
    func hideLoading(delayed: Bool, in view: UIView)

    /// 获取正在显示的加载吐司视图
    func showingLoadingView(in view: UIView) -> UIView?

    /// 显示进度条吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之
    func showProgress(attributedText: NSAttributedString?, attributedDetail: NSAttributedString?, progress: CGFloat, cancelBlock: (() -> Void)?, customBlock: ((Any) -> Void)?, in view: UIView)

    /// 隐藏进度条吐司
    func hideProgress(in view: UIView)

    /// 获取正在显示的进度条吐司视图
    func showingProgressView(in view: UIView) -> UIView?

    /// 显示指定样式消息吐司，可设置自动隐藏和允许交互，自动隐藏完成后回调
    func showMessage(attributedText: NSAttributedString?, attributedDetail: NSAttributedString?, style: ToastStyle, autoHide: Bool, interactive: Bool, completion: (() -> Void)?, customBlock: ((Any) -> Void)?, in view: UIView)

    /// 隐藏消息吐司
    func hideMessage(in view: UIView)

    /// 获取正在显示的消息吐司视图
    func showingMessageView(in view: UIView) -> UIView?
}

extension ToastPlugin {
    /// 默认实现，显示加载吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之
    public func showLoading(attributedText: NSAttributedString?, attributedDetail: NSAttributedString?, cancelBlock: (() -> Void)?, customBlock: ((Any) -> Void)?, in view: UIView) {
        ToastPluginImpl.shared.showLoading(attributedText: attributedText, attributedDetail: attributedDetail, cancelBlock: cancelBlock, customBlock: customBlock, in: view)
    }

    /// 默认实现，隐藏加载吐司，可指定延迟隐藏从而实现连续的加载效果
    public func hideLoading(delayed: Bool, in view: UIView) {
        ToastPluginImpl.shared.hideLoading(delayed: delayed, in: view)
    }

    /// 默认实现，获取正在显示的加载吐司视图
    public func showingLoadingView(in view: UIView) -> UIView? {
        ToastPluginImpl.shared.showingLoadingView(in: view)
    }

    /// 默认实现，显示进度条吐司，默认需手工隐藏，指定cancelBlock时点击会自动隐藏并调用之
    public func showProgress(attributedText: NSAttributedString?, attributedDetail: NSAttributedString?, progress: CGFloat, cancelBlock: (() -> Void)?, customBlock: ((Any) -> Void)?, in view: UIView) {
        ToastPluginImpl.shared.showProgress(attributedText: attributedText, attributedDetail: attributedDetail, progress: progress, cancelBlock: cancelBlock, customBlock: customBlock, in: view)
    }

    /// 默认实现，隐藏进度条吐司
    public func hideProgress(in view: UIView) {
        ToastPluginImpl.shared.hideProgress(in: view)
    }

    /// 默认实现，获取正在显示的进度条吐司视图
    public func showingProgressView(in view: UIView) -> UIView? {
        ToastPluginImpl.shared.showingProgressView(in: view)
    }

    /// 默认实现，显示指定样式消息吐司，可设置自动隐藏和允许交互，自动隐藏完成后回调
    public func showMessage(attributedText: NSAttributedString?, attributedDetail: NSAttributedString?, style: ToastStyle, autoHide: Bool, interactive: Bool, completion: (() -> Void)?, customBlock: ((Any) -> Void)?, in view: UIView) {
        ToastPluginImpl.shared.showMessage(attributedText: attributedText, attributedDetail: attributedDetail, style: style, autoHide: autoHide, interactive: interactive, completion: completion, customBlock: customBlock, in: view)
    }

    /// 默认实现，隐藏消息吐司
    public func hideMessage(in view: UIView) {
        ToastPluginImpl.shared.hideMessage(in: view)
    }

    /// 默认实现，获取正在显示的消息吐司视图
    public func showingMessageView(in view: UIView) -> UIView? {
        ToastPluginImpl.shared.showingMessageView(in: view)
    }
}

// MARK: - FrameworkAutoloader+ToastPlugin
extension FrameworkAutoloader {
    @objc static func loadPlugin_ToastPlugin() {
        RequestContextAccessory.showErrorBlock = { @MainActor @Sendable context, error in
            if let viewController = context as? UIViewController {
                viewController.fw.showMessage(error: error)
            } else if let view = context as? UIView {
                view.fw.showMessage(error: error)
            } else {
                UIWindow.fw.showMessage(error: error)
            }
        }

        RequestContextAccessory.showLoadingBlock = { @MainActor @Sendable context in
            if let viewController = context as? UIViewController {
                viewController.fw.showLoading()
            } else if let view = context as? UIView {
                view.fw.showLoading()
            }
        }

        RequestContextAccessory.hideLoadingBlock = { @MainActor @Sendable context in
            if let viewController = context as? UIViewController {
                viewController.fw.hideLoading()
            } else if let view = context as? UIView {
                view.fw.hideLoading()
            }
        }
    }
}
