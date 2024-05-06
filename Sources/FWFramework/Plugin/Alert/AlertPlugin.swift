//
//  AlertPlugin.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - Wrapper+UIViewController
extension Wrapper where Base: UIViewController {
    /// 自定义弹窗插件，未设置时自动从插件池加载
    public var alertPlugin: AlertPlugin! {
        get { return base.fw_alertPlugin }
        set { base.fw_alertPlugin = newValue }
    }
    
    /// 显示错误警告框
    /// - Parameters:
    ///   - error: 错误对象
    ///   - cancel: 取消按钮标题，默认关闭
    ///   - cancelBlock: 取消按钮事件
    public func showAlert(
        error: Error?,
        cancel: AttributedStringParameter? = nil,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.fw_showAlert(error: error, cancel: cancel, cancelBlock: cancelBlock)
    }

    /// 显示警告框(简单版)
    /// - Parameters:
    ///   - title: 警告框标题
    ///   - message: 警告框消息
    ///   - style: 警告框样式
    ///   - cancel: 取消按钮标题，默认关闭
    ///   - cancelBlock: 取消按钮事件
    public func showAlert(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        style: AlertStyle = .default,
        cancel: AttributedStringParameter? = nil,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.fw_showAlert(title: title, message: message, style: style, cancel: cancel, cancelBlock: cancelBlock)
    }

    /// 显示警告框(详细版)
    /// - Parameters:
    ///   - title: 警告框标题
    ///   - message: 警告框消息
    ///   - style: 警告框样式
    ///   - cancel: 取消按钮标题，默认单按钮关闭，多按钮取消
    ///   - actions: 动作按钮标题列表
    ///   - actionBlock: 动作按钮点击事件，参数为索引index
    ///   - cancelBlock: 取消按钮事件
    public func showAlert(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        style: AlertStyle = .default,
        cancel: AttributedStringParameter?,
        actions: [AttributedStringParameter]?,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.fw_showAlert(title: title, message: message, style: style, cancel: cancel, actions: actions, actionBlock: actionBlock, cancelBlock: cancelBlock)
    }
    
    /// 显示确认框(简单版)
    /// - Parameters:
    ///   - title: 确认框标题
    ///   - message: 确认框消息
    ///   - confirmBlock: 确认按钮事件
    ///   - cancelBlock: 取消按钮事件
    public func showConfirm(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        confirmBlock: (() -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.fw_showConfirm(title: title, message: message, cancel: nil, confirm: nil, confirmBlock: confirmBlock, cancelBlock: cancelBlock)
    }

    /// 显示确认框(详细版)
    /// - Parameters:
    ///   - title: 确认框标题
    ///   - message: 确认框消息
    ///   - cancel: 取消按钮文字，默认取消
    ///   - confirm: 确认按钮文字，默认确定
    ///   - confirmBlock: 确认按钮事件
    ///   - cancelBlock: 取消按钮事件
    public func showConfirm(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        cancel: AttributedStringParameter?,
        confirm: AttributedStringParameter?,
        confirmBlock: (() -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.fw_showConfirm(title: title, message: message, cancel: cancel, confirm: confirm, confirmBlock: confirmBlock, cancelBlock: cancelBlock)
    }

    /// 显示输入框(简单版)
    /// - Parameters:
    ///   - title: 输入框标题
    ///   - message: 输入框消息
    ///   - cancel: 取消按钮文字，默认取消
    ///   - confirm: 确认按钮文字，默认确定
    ///   - promptBlock: 输入框初始化事件，参数为输入框
    ///   - confirmBlock: 确认按钮事件，参数为输入值
    ///   - cancelBlock: 取消按钮事件
    public func showPrompt(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        cancel: AttributedStringParameter? = nil,
        confirm: AttributedStringParameter? = nil,
        promptBlock: ((UITextField) -> Void)? = nil,
        confirmBlock: ((String) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.fw_showPrompt(title: title, message: message, cancel: cancel, confirm: confirm, promptBlock: promptBlock, confirmBlock: confirmBlock, cancelBlock: cancelBlock)
    }

    /// 显示输入框(详细版)
    /// - Parameters:
    ///   - title: 输入框标题
    ///   - message: 输入框消息
    ///   - cancel: 取消按钮文字，默认取消
    ///   - confirm: 确认按钮文字，默认确定
    ///   - promptCount: 输入框数量
    ///   - promptBlock: 输入框初始化事件，参数为输入框和索引index
    ///   - confirmBlock: 确认按钮事件，参数为输入值数组
    ///   - cancelBlock: 取消按钮事件
    public func showPrompt(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        cancel: AttributedStringParameter? = nil,
        confirm: AttributedStringParameter? = nil,
        promptCount: Int,
        promptBlock: ((UITextField, Int) -> Void)?,
        confirmBlock: (([String]) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.fw_showPrompt(title: title, message: message, cancel: cancel, confirm: confirm, promptCount: promptCount, promptBlock: promptBlock, confirmBlock: confirmBlock, cancelBlock: cancelBlock)
    }
    
    /// 显示弹出框(完整版)
    /// - Parameters:
    ///   - title: 弹出框标题
    ///   - message: 弹出框消息
    ///   - style: 警告框样式
    ///   - cancel: 取消按钮标题，默认Alert单按钮关闭，Alert多按钮或Sheet取消
    ///   - actions: 动作按钮标题列表
    ///   - promptCount: 输入框数量，默认0
    ///   - promptBlock: 输入框初始化事件，参数为输入框和索引index，默认nil
    ///   - actionBlock: 动作按钮点击事件，参数为输入值数组和索引index
    ///   - cancelBlock: 取消按钮事件
    ///   - customBlock: 自定义弹出框事件
    public func showAlert(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        style: AlertStyle = .default,
        cancel: AttributedStringParameter?,
        actions: [AttributedStringParameter]?,
        promptCount: Int = 0,
        promptBlock: ((UITextField, Int) -> Void)? = nil,
        actionBlock: (([String], Int) -> Void)?,
        cancelBlock: (() -> Void)?,
        customBlock: ((Any) -> Void)?
    ) {
        base.fw_showAlert(title: title, message: message, style: style, cancel: cancel, actions: actions, promptCount: promptCount, promptBlock: promptBlock, actionBlock: actionBlock, cancelBlock: cancelBlock, customBlock: customBlock)
    }
    
    /// 显示操作表(无动作)
    /// - Parameters:
    ///   - title: 操作表标题
    ///   - message: 操作表消息
    ///   - cancel: 取消按钮标题，默认取消
    ///   - cancelBlock: 取消按钮事件
    public func showSheet(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        cancel: AttributedStringParameter?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.fw_showSheet(title: title, message: message, cancel: cancel, cancelBlock: cancelBlock)
    }

    /// 显示操作表(简单版)
    /// - Parameters:
    ///   - title: 操作表标题
    ///   - message: 操作表消息
    ///   - actions: 动作按钮标题列表
    ///   - actionBlock: 动作按钮点击事件，参数为索引index
    ///   - cancelBlock: 取消按钮事件
    public func showSheet(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        actions: [AttributedStringParameter]?,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.fw_showSheet(title: title, message: message, cancel: nil, actions: actions, currentIndex: -1, actionBlock: actionBlock, cancelBlock: cancelBlock)
    }

    /// 显示操作表(详细版)
    /// - Parameters:
    ///   - title: 操作表标题
    ///   - message: 操作表消息
    ///   - cancel: 取消按钮标题，默认取消
    ///   - actions: 动作按钮标题列表
    ///   - currentIndex: 当前选中动作索引，默认-1
    ///   - actionBlock: 动作按钮点击事件，参数为索引index
    ///   - cancelBlock: 取消按钮事件
    public func showSheet(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        cancel: AttributedStringParameter?,
        actions: [AttributedStringParameter]?,
        currentIndex: Int = -1,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.fw_showSheet(title: title, message: message, cancel: cancel, actions: actions, currentIndex: currentIndex, actionBlock: actionBlock, cancelBlock: cancelBlock)
    }

    /// 显示操作表(完整版)
    /// - Parameters:
    ///   - title: 操作表标题
    ///   - message: 操作表消息
    ///   - cancel: 取消按钮标题，默认Alert单按钮关闭，Alert多按钮或Sheet取消
    ///   - actions: 动作按钮标题列表
    ///   - currentIndex: 当前选中动作索引，默认-1
    ///   - actionBlock: 动作按钮点击事件，参数为输入值数组和索引index
    ///   - cancelBlock: 取消按钮事件
    ///   - customBlock: 自定义弹出框事件
    public func showSheet(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        cancel: AttributedStringParameter?,
        actions: [AttributedStringParameter]?,
        currentIndex: Int = -1,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)?,
        customBlock: ((Any) -> Void)?
    ) {
        base.fw_showSheet(title: title, message: message, cancel: cancel, actions: actions, currentIndex: currentIndex, actionBlock: actionBlock, cancelBlock: cancelBlock, customBlock: customBlock)
    }
    
    /// 手工隐藏弹出框，完成后回调。当animated为false时如需获取最新控制器等，也需在异步completion中处理
    /// - Parameters:
    ///   - animated: 是否执行动画
    ///   - completion: 完成异步回调
    public func hideAlert(
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        base.fw_hideAlert(animated: animated, completion: completion)
    }
    
    /// 判断是否正在显示弹出框
    public var isShowingAlert: Bool {
        return base.fw_isShowingAlert
    }
}

// MARK: - Wrapper+UIView
extension Wrapper where Base: UIView {
    /// 显示错误警告框
    /// - Parameters:
    ///   - error: 错误对象
    ///   - cancel: 取消按钮标题，默认关闭
    ///   - cancelBlock: 取消按钮事件
    public func showAlert(
        error: Error?,
        cancel: AttributedStringParameter? = nil,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.fw_showAlert(error: error, cancel: cancel, cancelBlock: cancelBlock)
    }
    
    /// 显示警告框(简单版)
    /// - Parameters:
    ///   - title: 警告框标题
    ///   - message: 警告框消息
    ///   - style: 警告框样式
    ///   - cancel: 取消按钮标题，默认关闭
    ///   - cancelBlock: 取消按钮事件
    public func showAlert(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        style: AlertStyle = .default,
        cancel: AttributedStringParameter? = nil,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.fw_showAlert(title: title, message: message, style: style, cancel: cancel, cancelBlock: cancelBlock)
    }

    /// 显示警告框(详细版)
    /// - Parameters:
    ///   - title: 警告框标题
    ///   - message: 警告框消息
    ///   - style: 警告框样式
    ///   - cancel: 取消按钮标题，默认单按钮关闭，多按钮取消
    ///   - actions: 动作按钮标题列表
    ///   - actionBlock: 动作按钮点击事件，参数为索引index
    ///   - cancelBlock: 取消按钮事件
    public func showAlert(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        style: AlertStyle = .default,
        cancel: AttributedStringParameter?,
        actions: [AttributedStringParameter]?,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.fw_showAlert(title: title, message: message, style: style, cancel: cancel, actions: actions, actionBlock: actionBlock, cancelBlock: cancelBlock)
    }
    
    /// 显示确认框(简单版)
    /// - Parameters:
    ///   - title: 确认框标题
    ///   - message: 确认框消息
    ///   - confirmBlock: 确认按钮事件
    ///   - cancelBlock: 取消按钮事件
    public func showConfirm(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        confirmBlock: (() -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.fw_showConfirm(title: title, message: message, cancel: nil, confirm: nil, confirmBlock: confirmBlock, cancelBlock: cancelBlock)
    }

    /// 显示确认框(详细版)
    /// - Parameters:
    ///   - title: 确认框标题
    ///   - message: 确认框消息
    ///   - cancel: 取消按钮文字，默认取消
    ///   - confirm: 确认按钮文字，默认确定
    ///   - confirmBlock: 确认按钮事件
    ///   - cancelBlock: 取消按钮事件
    public func showConfirm(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        cancel: AttributedStringParameter?,
        confirm: AttributedStringParameter?,
        confirmBlock: (() -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.fw_showConfirm(title: title, message: message, cancel: cancel, confirm: confirm, confirmBlock: confirmBlock, cancelBlock: cancelBlock)
    }

    /// 显示输入框(简单版)
    /// - Parameters:
    ///   - title: 输入框标题
    ///   - message: 输入框消息
    ///   - cancel: 取消按钮文字，默认取消
    ///   - confirm: 确认按钮文字，默认确定
    ///   - promptBlock: 输入框初始化事件，参数为输入框
    ///   - confirmBlock: 确认按钮事件，参数为输入值
    ///   - cancelBlock: 取消按钮事件
    public func showPrompt(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        cancel: AttributedStringParameter?,
        confirm: AttributedStringParameter?,
        promptBlock: ((UITextField) -> Void)? = nil,
        confirmBlock: ((String) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.fw_showPrompt(title: title, message: message, cancel: cancel, confirm: confirm, promptBlock: promptBlock, confirmBlock: confirmBlock, cancelBlock: cancelBlock)
    }

    /// 显示输入框(详细版)
    /// - Parameters:
    ///   - title: 输入框标题
    ///   - message: 输入框消息
    ///   - cancel: 取消按钮文字，默认取消
    ///   - confirm: 确认按钮文字，默认确定
    ///   - promptCount: 输入框数量
    ///   - promptBlock: 输入框初始化事件，参数为输入框和索引index
    ///   - confirmBlock: 确认按钮事件，参数为输入值数组
    ///   - cancelBlock: 取消按钮事件
    public func showPrompt(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        cancel: AttributedStringParameter?,
        confirm: AttributedStringParameter?,
        promptCount: Int,
        promptBlock: ((UITextField, Int) -> Void)?,
        confirmBlock: (([String]) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.fw_showPrompt(title: title, message: message, cancel: cancel, confirm: confirm, promptCount: promptCount, promptBlock: promptBlock, confirmBlock: confirmBlock, cancelBlock: cancelBlock)
    }
    
    /// 显示弹出框(完整版)
    /// - Parameters:
    ///   - title: 弹出框标题
    ///   - message: 弹出框消息
    ///   - style: 弹出框样式
    ///   - cancel: 取消按钮标题，默认Alert单按钮关闭，Alert多按钮或Sheet取消
    ///   - actions: 动作按钮标题列表
    ///   - promptCount: 输入框数量，默认0
    ///   - promptBlock: 输入框初始化事件，参数为输入框和索引index，默认nil
    ///   - actionBlock: 动作按钮点击事件，参数为输入值数组和索引index
    ///   - cancelBlock: 取消按钮事件
    ///   - customBlock: 自定义弹出框事件
    public func showAlert(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        style: AlertStyle = .default,
        cancel: AttributedStringParameter?,
        actions: [AttributedStringParameter]?,
        promptCount: Int = 0,
        promptBlock: ((UITextField, Int) -> Void)? = nil,
        actionBlock: (([String], Int) -> Void)?,
        cancelBlock: (() -> Void)?,
        customBlock: ((Any) -> Void)?
    ) {
        base.fw_showAlert(title: title, message: message, style: style, cancel: cancel, actions: actions, promptCount: promptCount, promptBlock: promptBlock, actionBlock: actionBlock, cancelBlock: cancelBlock, customBlock: customBlock)
    }
    
    /// 显示操作表(无动作)
    /// - Parameters:
    ///   - title: 操作表标题
    ///   - message: 操作表消息
    ///   - cancel: 取消按钮标题，默认取消
    ///   - cancelBlock: 取消按钮事件
    public func showSheet(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        cancel: AttributedStringParameter?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.fw_showSheet(title: title, message: message, cancel: cancel, cancelBlock: cancelBlock)
    }

    /// 显示操作表(简单版)
    /// - Parameters:
    ///   - title: 操作表标题
    ///   - message: 操作表消息
    ///   - actions: 动作按钮标题列表
    ///   - actionBlock: 动作按钮点击事件，参数为索引index
    ///   - cancelBlock: 取消按钮事件
    public func showSheet(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        actions: [AttributedStringParameter]?,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.fw_showSheet(title: title, message: message, cancel: nil, actions: actions, currentIndex: -1, actionBlock: actionBlock, cancelBlock: cancelBlock)
    }

    /// 显示操作表(详细版)
    /// - Parameters:
    ///   - title: 操作表标题
    ///   - message: 操作表消息
    ///   - cancel: 取消按钮标题，默认取消
    ///   - actions: 动作按钮标题列表
    ///   - currentIndex: 当前选中动作索引，默认-1
    ///   - actionBlock: 动作按钮点击事件，参数为索引index
    ///   - cancelBlock: 取消按钮事件
    public func showSheet(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        cancel: AttributedStringParameter?,
        actions: [AttributedStringParameter]?,
        currentIndex: Int = -1,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.fw_showSheet(title: title, message: message, cancel: cancel, actions: actions, currentIndex: currentIndex, actionBlock: actionBlock, cancelBlock: cancelBlock)
    }

    /// 显示弹出框(完整版)
    /// - Parameters:
    ///   - title: 操作表标题
    ///   - message: 操作表消息
    ///   - cancel: 取消按钮标题，默认Alert单按钮关闭，Alert多按钮或Sheet取消
    ///   - actions: 动作按钮标题列表
    ///   - currentIndex: 当前选中动作索引，默认-1
    ///   - actionBlock: 动作按钮点击事件，参数为输入值数组和索引index
    ///   - cancelBlock: 取消按钮事件
    ///   - customBlock: 自定义弹出框事件
    public func showSheet(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        cancel: AttributedStringParameter?,
        actions: [AttributedStringParameter]?,
        currentIndex: Int = -1,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)?,
        customBlock: ((Any) -> Void)?
    ) {
        base.fw_showSheet(title: title, message: message, cancel: cancel, actions: actions, currentIndex: currentIndex, actionBlock: actionBlock, cancelBlock: cancelBlock, customBlock: customBlock)
    }
    
    /// 手工隐藏弹出框，完成后回调
    /// - Parameters:
    ///   - animated: 是否执行动画
    ///   - completion: 完成回调
    public func hideAlert(
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        base.fw_hideAlert(animated: animated, completion: completion)
    }
    
    /// 判断是否正在显示弹出框
    public var isShowingAlert: Bool {
        return base.fw_isShowingAlert
    }
}

// MARK: - Wrapper+UIAlertAction
extension Wrapper where Base: UIAlertAction {
    /// 自定义样式，默认为样式单例
    public var alertAppearance: AlertAppearance! {
        get { return base.fw_alertAppearance }
        set { base.fw_alertAppearance = newValue }
    }

    /// 指定标题颜色
    public var titleColor: UIColor? {
        get { return base.fw_titleColor }
        set { base.fw_titleColor = newValue }
    }
    
    /// 快速创建弹出动作，title仅支持NSString
    public static func action(object: AttributedStringParameter?, style: UIAlertAction.Style, handler: ((UIAlertAction) -> Void)?) -> UIAlertAction {
        return Base.fw_action(object: object, style: style, handler: handler)
    }

    /// 快速创建弹出动作，title仅支持NSString，支持appearance
    public static func action(object: AttributedStringParameter?, style: UIAlertAction.Style, appearance: AlertAppearance?, handler: ((UIAlertAction) -> Void)?) -> UIAlertAction {
        return Base.fw_action(object: object, style: style, appearance: appearance, handler: handler)
    }
}

// MARK: - Wrapper+UIAlertController
extension Wrapper where Base: UIAlertController {
    /// 自定义样式，默认为样式单例
    public var alertAppearance: AlertAppearance! {
        get { return base.fw_alertAppearance }
        set { base.fw_alertAppearance = newValue }
    }
    
    /// 弹出框样式，默认为Default
    public var alertStyle: AlertStyle {
        get { return base.fw_alertStyle }
        set { base.fw_alertStyle = newValue }
    }

    /// 设置属性标题
    public var attributedTitle: NSAttributedString? {
        get { return base.fw_attributedTitle }
        set { base.fw_attributedTitle = newValue }
    }

    /// 设置属性消息
    public var attributedMessage: NSAttributedString? {
        get { return base.fw_attributedMessage }
        set { base.fw_attributedMessage = newValue }
    }
    
    /// 快速创建弹出控制器，title和message仅支持NSString
    public static func alertController(title: AttributedStringParameter?, message: AttributedStringParameter?, preferredStyle: UIAlertController.Style) -> UIAlertController {
        return Base.fw_alertController(title: title, message: message, preferredStyle: preferredStyle)
    }

    /// 快速创建弹出控制器，title和message仅支持NSString，支持自定义样式
    public static func alertController(title: AttributedStringParameter?, message: AttributedStringParameter?, preferredStyle: UIAlertController.Style, appearance: AlertAppearance?) -> UIAlertController {
        return Base.fw_alertController(title: title, message: message, preferredStyle: preferredStyle, appearance: appearance)
    }
}

// MARK: - AlertPlugin
/// 弹框样式可扩展枚举
public struct AlertStyle: RawRepresentable, Equatable, Hashable {
    
    public typealias RawValue = Int
    
    /// 默认弹框样式
    public static let `default`: AlertStyle = .init(0)
    /// 成功弹框样式
    public static let success: AlertStyle = .init(1)
    /// 失败弹框样式
    public static let failure: AlertStyle = .init(2)
    /// 警告弹框样式
    public static let warning: AlertStyle = .init(3)
    
    public var rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public init(_ rawValue: Int) {
        self.rawValue = rawValue
    }
    
}

/// 弹窗插件协议，应用可自定义弹窗实现
public protocol AlertPlugin: AnyObject {
    
    /// 显示弹出框插件方法，默认使用系统UIAlertController
    func showAlert(title: AttributedStringParameter?, message: AttributedStringParameter?, style: AlertStyle, cancel: AttributedStringParameter?, actions: [AttributedStringParameter]?, promptCount: Int, promptBlock: ((_ textField: UITextField, _ index: Int) -> Void)?, actionBlock: ((_ values: [String], _ index: Int) -> Void)?, cancelBlock: (() -> Void)?, customBlock: ((_ alertController: Any) -> Void)?, in viewController: UIViewController)
    
    /// 显示操作表插件方法，默认使用系统UIAlertController
    func showSheet(title: AttributedStringParameter?, message: AttributedStringParameter?, cancel: AttributedStringParameter?, actions: [AttributedStringParameter]?, currentIndex: Int, actionBlock: ((_ index: Int) -> Void)?, cancelBlock: (() -> Void)?, customBlock: ((_ alertController: Any) -> Void)?, in viewController: UIViewController)
    
    /// 手工隐藏弹出框插件方法，默认查找UIAlertController|AlertController
    func hideAlert(animated: Bool, completion: (() -> Void)?, in viewController: UIViewController)
    
    /// 判断是否正在显示弹出框插件方法，默认查找UIAlertController|AlertController
    func isShowingAlert(in viewController: UIViewController) -> Bool
    
}

extension AlertPlugin {
    
    /// 显示弹出框插件方法，默认使用系统UIAlertController
    public func showAlert(title: AttributedStringParameter?, message: AttributedStringParameter?, style: AlertStyle, cancel: AttributedStringParameter?, actions: [AttributedStringParameter]?, promptCount: Int, promptBlock: ((_ textField: UITextField, _ index: Int) -> Void)?, actionBlock: ((_ values: [String], _ index: Int) -> Void)?, cancelBlock: (() -> Void)?, customBlock: ((_ alertController: Any) -> Void)?, in viewController: UIViewController) {
        AlertPluginImpl.shared.showAlert(title: title, message: message, style: style, cancel: cancel, actions: actions, promptCount: promptCount, promptBlock: promptBlock, actionBlock: actionBlock, cancelBlock: cancelBlock, customBlock: customBlock, in: viewController)
    }
    
    /// 显示操作表插件方法，默认使用系统UIAlertController
    public func showSheet(title: AttributedStringParameter?, message: AttributedStringParameter?, cancel: AttributedStringParameter?, actions: [AttributedStringParameter]?, currentIndex: Int, actionBlock: ((_ index: Int) -> Void)?, cancelBlock: (() -> Void)?, customBlock: ((_ alertController: Any) -> Void)?, in viewController: UIViewController) {
        AlertPluginImpl.shared.showSheet(title: title, message: message, cancel: cancel, actions: actions, currentIndex: currentIndex, actionBlock: actionBlock, cancelBlock: cancelBlock, customBlock: customBlock, in: viewController)
    }
    
    /// 手工隐藏弹出框插件方法，默认查找UIAlertController|AlertController
    public func hideAlert(animated: Bool, completion: (() -> Void)?, in viewController: UIViewController) {
        AlertPluginImpl.shared.hideAlert(animated: animated, completion: completion, in: viewController)
    }
    
    /// 判断是否正在显示弹出框插件方法，默认查找UIAlertController|AlertController
    public func isShowingAlert(in viewController: UIViewController) -> Bool {
        return AlertPluginImpl.shared.isShowingAlert(in: viewController)
    }
    
}

// MARK: - AlertAppearance
/// 系统弹出框样式配置类，由于系统兼容性，建议优先使用AlertController
///
/// 备注：如果未自定义样式，显示效果和系统一致，不会产生任何影响；框架会先渲染actions动作再渲染cancel动作
public class AlertAppearance: NSObject {
    
    /// 单例模式，统一设置样式
    public static let appearance = AlertAppearance()
    
    /// 自定义首选动作句柄，默认nil，跟随系统
    public var preferredActionBlock: ((_ alertController: UIAlertController) -> UIAlertAction?)?
    
    /// 标题颜色，仅全局生效，默认nil
    public var titleColor: UIColor?
    /// 标题字体，仅全局生效，默认nil
    public var titleFont: UIFont?
    /// 消息颜色，仅全局生效，默认nil
    public var messageColor: UIColor?
    /// 消息字体，仅全局生效，默认nil
    public var messageFont: UIFont?
    
    /// 默认动作颜色，仅全局生效，默认nil
    public var actionColor: UIColor?
    /// 首选动作颜色，仅全局生效，默认nil
    public var preferredActionColor: UIColor?
    /// 取消动作颜色，仅全局生效，默认nil
    public var cancelActionColor: UIColor?
    /// 警告动作颜色，仅全局生效，默认nil
    public var destructiveActionColor: UIColor?
    /// 禁用动作颜色，仅全局生效，默认nil
    public var disabledActionColor: UIColor?
    
    /// 是否启用Controller样式，设置后自动启用
    public var controllerEnabled: Bool {
        return titleColor != nil || titleFont != nil || messageColor != nil || messageFont != nil
    }
    
    /// 是否启用Action样式，设置后自动启用
    public var actionEnabled: Bool {
        return actionColor != nil || preferredActionColor != nil || cancelActionColor != nil || destructiveActionColor != nil || disabledActionColor != nil
    }
    
}

// MARK: - UIView+AlertPlugin
@_spi(FW) extension UIViewController {
    
    /// 自定义弹窗插件，未设置时自动从插件池加载
    public var fw_alertPlugin: AlertPlugin! {
        get {
            if let alertPlugin = fw.property(forName: "fw_alertPlugin") as? AlertPlugin {
                return alertPlugin
            } else if let alertPlugin = PluginManager.loadPlugin(AlertPlugin.self) {
                return alertPlugin
            }
            return AlertPluginImpl.shared
        }
        set {
            fw.setProperty(newValue, forName: "fw_alertPlugin")
        }
    }
    
    /// 显示错误警告框
    /// - Parameters:
    ///   - error: 错误对象
    ///   - cancel: 取消按钮标题，默认关闭
    ///   - cancelBlock: 取消按钮事件
    public func fw_showAlert(
        error: Error?,
        cancel: AttributedStringParameter? = nil,
        cancelBlock: (() -> Void)? = nil
    ) {
        fw_showAlert(
            title: AlertPluginImpl.shared.errorTitleFormatter?(error),
            message: AlertPluginImpl.shared.errorMessageFormatter?(error) ?? error?.localizedDescription,
            style: AlertPluginImpl.shared.errorStyleFormatter?(error) ?? .default,
            cancel: cancel ?? AlertPluginImpl.shared.errorButtonFormatter?(error),
            cancelBlock: cancelBlock
        )
    }

    /// 显示警告框(简单版)
    /// - Parameters:
    ///   - title: 警告框标题
    ///   - message:  警告框消息
    ///   - style: 警告框样式
    ///   - cancel: 取消按钮标题，默认关闭
    ///   - cancelBlock: 取消按钮事件
    public func fw_showAlert(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        style: AlertStyle = .default,
        cancel: AttributedStringParameter? = nil,
        cancelBlock: (() -> Void)? = nil
    ) {
        fw_showAlert(title: title, message: message, style: style, cancel: cancel, actions: nil, actionBlock: nil, cancelBlock: cancelBlock)
    }

    /// 显示警告框(详细版)
    /// - Parameters:
    ///   - title: 警告框标题
    ///   - message: 警告框消息
    ///   - style: 警告框样式
    ///   - cancel: 取消按钮标题，默认单按钮关闭，多按钮取消
    ///   - actions: 动作按钮标题列表
    ///   - actionBlock: 动作按钮点击事件，参数为索引index
    ///   - cancelBlock: 取消按钮事件
    public func fw_showAlert(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        style: AlertStyle = .default,
        cancel: AttributedStringParameter?,
        actions: [AttributedStringParameter]?,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        fw_showAlert(title: title, message: message, style: style, cancel: cancel, actions: actions, promptCount: 0, promptBlock: nil, actionBlock: { _, index in actionBlock?(index) }, cancelBlock: cancelBlock, customBlock: nil)
    }
    
    /// 显示确认框(简单版)
    /// - Parameters:
    ///   - title: 确认框标题
    ///   - message: 确认框消息
    ///   - confirmBlock: 确认按钮事件
    ///   - cancelBlock: 取消按钮事件
    public func fw_showConfirm(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        confirmBlock: (() -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        fw_showConfirm(title: title, message: message, cancel: nil, confirm: nil, confirmBlock: confirmBlock, cancelBlock: cancelBlock)
    }

    /// 显示确认框(详细版)
    /// - Parameters:
    ///   - title: 确认框标题
    ///   - message: 确认框消息
    ///   - cancel: 取消按钮文字，默认取消
    ///   - confirm: 确认按钮文字，默认确定
    ///   - confirmBlock: 确认按钮事件
    ///   - cancelBlock: 取消按钮事件
    public func fw_showConfirm(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        cancel: AttributedStringParameter?,
        confirm: AttributedStringParameter?,
        confirmBlock: (() -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        let targetConfirm = confirm ?? (AlertPluginImpl.shared.defaultConfirmButton?() ?? FrameworkBundle.confirmButton)
        
        fw_showAlert(title: title, message: message, style: .default, cancel: cancel, actions: [targetConfirm], promptCount: 0, promptBlock: nil, actionBlock: { _, index in confirmBlock?() }, cancelBlock: cancelBlock, customBlock: nil)
    }

    /// 显示输入框(简单版)
    /// - Parameters:
    ///   - title: 输入框标题
    ///   - message: 输入框消息
    ///   - cancel: 取消按钮文字，默认取消
    ///   - confirm: 确认按钮文字，默认确定
    ///   - promptBlock: 输入框初始化事件，参数为输入框
    ///   - confirmBlock: 确认按钮事件，参数为输入值
    ///   - cancelBlock: 取消按钮事件
    public func fw_showPrompt(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        cancel: AttributedStringParameter? = nil,
        confirm: AttributedStringParameter? = nil,
        promptBlock: ((UITextField) -> Void)? = nil,
        confirmBlock: ((String) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        fw_showPrompt(title: title, message: message, cancel: cancel, confirm: confirm, promptCount: 1, promptBlock: { textField, _ in promptBlock?(textField) }, confirmBlock: { values in confirmBlock?(values.first ?? "") }, cancelBlock: cancelBlock)
    }

    /// 显示输入框(详细版)
    /// - Parameters:
    ///   - title: 输入框标题
    ///   - message: 输入框消息
    ///   - cancel: 取消按钮文字，默认取消
    ///   - confirm: 确认按钮文字，默认确定
    ///   - promptCount: 输入框数量
    ///   - promptBlock: 输入框初始化事件，参数为输入框和索引index
    ///   - confirmBlock: 确认按钮事件，参数为输入值数组
    ///   - cancelBlock: 取消按钮事件
    public func fw_showPrompt(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        cancel: AttributedStringParameter? = nil,
        confirm: AttributedStringParameter? = nil,
        promptCount: Int,
        promptBlock: ((UITextField, Int) -> Void)?,
        confirmBlock: (([String]) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        let targetConfirm = confirm ?? (AlertPluginImpl.shared.defaultConfirmButton?() ?? FrameworkBundle.confirmButton)
        
        fw_showAlert(title: title, message: message, style: .default, cancel: cancel, actions: [targetConfirm], promptCount: promptCount, promptBlock: promptBlock, actionBlock: { values, _ in confirmBlock?(values) }, cancelBlock: cancelBlock, customBlock: nil)
    }
    
    /// 显示弹出框(完整版)
    /// - Parameters:
    ///   - title: 弹出框标题
    ///   - message: 弹出框消息
    ///   - style: 警告框样式
    ///   - cancel: 取消按钮标题，默认Alert单按钮关闭，Alert多按钮或Sheet取消
    ///   - actions: 动作按钮标题列表
    ///   - promptCount: 输入框数量，默认0
    ///   - promptBlock: 输入框初始化事件，参数为输入框和索引index，默认nil
    ///   - actionBlock: 动作按钮点击事件，参数为输入值数组和索引index
    ///   - cancelBlock: 取消按钮事件
    ///   - customBlock: 自定义弹出框事件
    public func fw_showAlert(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        style: AlertStyle = .default,
        cancel: AttributedStringParameter?,
        actions: [AttributedStringParameter]?,
        promptCount: Int = 0,
        promptBlock: ((UITextField, Int) -> Void)? = nil,
        actionBlock: (([String], Int) -> Void)?,
        cancelBlock: (() -> Void)?,
        customBlock: ((Any) -> Void)?
    ) {
        // 处理取消按钮，Alert多按钮时默认取消，单按钮时默认关闭
        var targetCancel = cancel
        if cancel == nil {
            if (actions?.count ?? 0) > 0 {
                targetCancel = AlertPluginImpl.shared.defaultCancelButton?(.alert) ?? FrameworkBundle.cancelButton
            } else {
                targetCancel = AlertPluginImpl.shared.defaultCloseButton?(.alert) ?? FrameworkBundle.closeButton
            }
        }
        
        let plugin = self.fw_alertPlugin ?? AlertPluginImpl.shared
        plugin.showAlert(title: title, message: message, style: style, cancel: targetCancel, actions: actions, promptCount: promptCount, promptBlock: promptBlock, actionBlock: actionBlock, cancelBlock: cancelBlock, customBlock: customBlock, in: self)
    }
    
    /// 显示操作表(无动作)
    /// - Parameters:
    ///   - title: 操作表标题
    ///   - message: 操作表消息
    ///   - cancel: 取消按钮标题，默认取消
    ///   - cancelBlock: 取消按钮事件
    public func fw_showSheet(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        cancel: AttributedStringParameter?,
        cancelBlock: (() -> Void)? = nil
    ) {
        fw_showSheet(title: title, message: message, cancel: cancel, actions: nil, currentIndex: -1, actionBlock: nil, cancelBlock: cancelBlock)
    }

    /// 显示操作表(简单版)
    /// - Parameters:
    ///   - title: 操作表标题
    ///   - message: 操作表消息
    ///   - actions: 动作按钮标题列表
    ///   - actionBlock: 动作按钮点击事件，参数为索引index
    ///   - cancelBlock: 取消按钮事件
    public func fw_showSheet(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        actions: [AttributedStringParameter]?,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        fw_showSheet(title: title, message: message, cancel: nil, actions: actions, currentIndex: -1, actionBlock: actionBlock, cancelBlock: cancelBlock)
    }

    /// 显示操作表(详细版)
    /// - Parameters:
    ///   - title: 操作表标题
    ///   - message: 操作表消息
    ///   - cancel: 取消按钮标题，默认取消
    ///   - actions: 动作按钮标题列表
    ///   - currentIndex: 当前选中动作索引，默认-1
    ///   - actionBlock: 动作按钮点击事件，参数为索引index
    ///   - cancelBlock: 取消按钮事件
    public func fw_showSheet(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        cancel: AttributedStringParameter?,
        actions: [AttributedStringParameter]?,
        currentIndex: Int = -1,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        fw_showSheet(title: title, message: message, cancel: cancel, actions: actions, currentIndex: currentIndex, actionBlock: actionBlock, cancelBlock: cancelBlock, customBlock: nil)
    }

    /// 显示操作表(完整版)
    /// - Parameters:
    ///   - title: 操作表标题
    ///   - message: 操作表消息
    ///   - cancel: 取消按钮标题，默认Alert单按钮关闭，Alert多按钮或Sheet取消
    ///   - actions: 动作按钮标题列表
    ///   - currentIndex: 当前选中动作索引，默认-1
    ///   - actionBlock: 动作按钮点击事件，参数为输入值数组和索引index
    ///   - cancelBlock: 取消按钮事件
    ///   - customBlock: 自定义弹出框事件
    public func fw_showSheet(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        cancel: AttributedStringParameter?,
        actions: [AttributedStringParameter]?,
        currentIndex: Int = -1,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)?,
        customBlock: ((Any) -> Void)?
    ) {
        // 处理取消按钮，Sheet多按钮时默认取消，单按钮时默认关闭
        var targetCancel = cancel
        if cancel == nil {
            if (actions?.count ?? 0) > 0 {
                targetCancel = AlertPluginImpl.shared.defaultCancelButton?(.actionSheet) ?? FrameworkBundle.cancelButton
            } else {
                targetCancel = AlertPluginImpl.shared.defaultCloseButton?(.actionSheet) ?? FrameworkBundle.closeButton
            }
        }
        
        let plugin = self.fw_alertPlugin ?? AlertPluginImpl.shared
        plugin.showSheet(title: title, message: message, cancel: targetCancel, actions: actions, currentIndex: currentIndex, actionBlock: actionBlock, cancelBlock: cancelBlock, customBlock: customBlock, in: self)
    }
    
    /// 手工隐藏弹出框，完成后回调。当animated为false时如需获取最新控制器等，也需在异步completion中处理
    /// - Parameters:
    ///   - animated: 是否执行动画
    ///   - completion: 完成异步回调
    public func fw_hideAlert(
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        let plugin = self.fw_alertPlugin ?? AlertPluginImpl.shared
        plugin.hideAlert(animated: animated, completion: completion, in: self)
    }
    
    /// 判断是否正在显示弹出框
    public var fw_isShowingAlert: Bool {
        let plugin = self.fw_alertPlugin ?? AlertPluginImpl.shared
        return plugin.isShowingAlert(in: self)
    }
    
}

@_spi(FW) extension UIView {
    
    /// 显示错误警告框
    /// - Parameters:
    ///   - error: 错误对象
    ///   - cancel: 取消按钮标题，默认关闭
    ///   - cancelBlock: 取消按钮事件
    public func fw_showAlert(
        error: Error?,
        cancel: AttributedStringParameter? = nil,
        cancelBlock: (() -> Void)? = nil
    ) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw.main?.fw.topPresentedController
        }
        ctrl?.fw_showAlert(error: error, cancel: cancel, cancelBlock: cancelBlock)
    }
    
    /// 显示警告框(简单版)
    /// - Parameters:
    ///   - title: 警告框标题
    ///   - message: 警告框消息
    ///   - style: 警告框样式
    ///   - cancel: 取消按钮标题，默认关闭
    ///   - cancelBlock: 取消按钮事件
    public func fw_showAlert(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        style: AlertStyle = .default,
        cancel: AttributedStringParameter? = nil,
        cancelBlock: (() -> Void)? = nil
    ) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw.main?.fw.topPresentedController
        }
        ctrl?.fw_showAlert(title: title, message: message, style: style, cancel: cancel, cancelBlock: cancelBlock)
    }

    /// 显示警告框(详细版)
    /// - Parameters:
    ///   - title: 警告框标题
    ///   - message: 警告框消息
    ///   - style: 警告框样式
    ///   - cancel: 取消按钮标题，默认单按钮关闭，多按钮取消
    ///   - actions: 动作按钮标题列表
    ///   - actionBlock: 动作按钮点击事件，参数为索引index
    ///   - cancelBlock: 取消按钮事件
    public func fw_showAlert(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        style: AlertStyle = .default,
        cancel: AttributedStringParameter?,
        actions: [AttributedStringParameter]?,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw.main?.fw.topPresentedController
        }
        ctrl?.fw_showAlert(title: title, message: message, style: style, cancel: cancel, actions: actions, actionBlock: actionBlock, cancelBlock: cancelBlock)
    }
    
    /// 显示确认框(简单版)
    /// - Parameters:
    ///   - title: 确认框标题
    ///   - message: 确认框消息
    ///   - confirmBlock: 确认按钮事件
    ///   - cancelBlock: 取消按钮事件
    public func fw_showConfirm(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        confirmBlock: (() -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw.main?.fw.topPresentedController
        }
        ctrl?.fw_showConfirm(title: title, message: message, confirmBlock: confirmBlock, cancelBlock: cancelBlock)
    }

    /// 显示确认框(详细版)
    /// - Parameters:
    ///   - title: 确认框标题
    ///   - message: 确认框消息
    ///   - cancel: 取消按钮文字，默认取消
    ///   - confirm: 确认按钮文字，默认确定
    ///   - confirmBlock: 确认按钮事件
    ///   - cancelBlock: 取消按钮事件
    public func fw_showConfirm(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        cancel: AttributedStringParameter?,
        confirm: AttributedStringParameter?,
        confirmBlock: (() -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw.main?.fw.topPresentedController
        }
        ctrl?.fw_showConfirm(title: title, message: message, cancel: cancel, confirm: confirm, confirmBlock: confirmBlock, cancelBlock: cancelBlock)
    }

    /// 显示输入框(简单版)
    /// - Parameters:
    ///   - title: 输入框标题
    ///   - message: 输入框消息
    ///   - cancel: 取消按钮文字，默认取消
    ///   - confirm: 确认按钮文字，默认确定
    ///   - promptBlock: 输入框初始化事件，参数为输入框
    ///   - confirmBlock: 确认按钮事件，参数为输入值
    ///   - cancelBlock: 取消按钮事件
    public func fw_showPrompt(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        cancel: AttributedStringParameter?,
        confirm: AttributedStringParameter?,
        promptBlock: ((UITextField) -> Void)? = nil,
        confirmBlock: ((String) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw.main?.fw.topPresentedController
        }
        ctrl?.fw_showPrompt(title: title, message: message, cancel: cancel, confirm: confirm, promptBlock: promptBlock, confirmBlock: confirmBlock, cancelBlock: cancelBlock)
    }

    /// 显示输入框(详细版)
    /// - Parameters:
    ///   - title: 输入框标题
    ///   - message: 输入框消息
    ///   - cancel: 取消按钮文字，默认取消
    ///   - confirm: 确认按钮文字，默认确定
    ///   - promptCount: 输入框数量
    ///   - promptBlock: 输入框初始化事件，参数为输入框和索引index
    ///   - confirmBlock: 确认按钮事件，参数为输入值数组
    ///   - cancelBlock: 取消按钮事件
    public func fw_showPrompt(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        cancel: AttributedStringParameter?,
        confirm: AttributedStringParameter?,
        promptCount: Int,
        promptBlock: ((UITextField, Int) -> Void)?,
        confirmBlock: (([String]) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw.main?.fw.topPresentedController
        }
        ctrl?.fw_showPrompt(title: title, message: message, cancel: cancel, confirm: confirm, promptCount: promptCount, promptBlock: promptBlock, confirmBlock: confirmBlock, cancelBlock: cancelBlock)
    }
    
    /// 显示弹出框(完整版)
    /// - Parameters:
    ///   - title: 弹出框标题
    ///   - message: 弹出框消息
    ///   - style: 弹出框样式
    ///   - cancel: 取消按钮标题，默认Alert单按钮关闭，Alert多按钮或Sheet取消
    ///   - actions: 动作按钮标题列表
    ///   - promptCount: 输入框数量，默认0
    ///   - promptBlock: 输入框初始化事件，参数为输入框和索引index，默认nil
    ///   - actionBlock: 动作按钮点击事件，参数为输入值数组和索引index
    ///   - cancelBlock: 取消按钮事件
    ///   - customBlock: 自定义弹出框事件
    public func fw_showAlert(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        style: AlertStyle = .default,
        cancel: AttributedStringParameter?,
        actions: [AttributedStringParameter]?,
        promptCount: Int = 0,
        promptBlock: ((UITextField, Int) -> Void)? = nil,
        actionBlock: (([String], Int) -> Void)?,
        cancelBlock: (() -> Void)?,
        customBlock: ((Any) -> Void)?
    ) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw.main?.fw.topPresentedController
        }
        ctrl?.fw_showAlert(title: title, message: message, style: style, cancel: cancel, actions: actions, promptCount: promptCount, promptBlock: promptBlock, actionBlock: actionBlock, cancelBlock: cancelBlock, customBlock: customBlock)
    }
    
    /// 显示操作表(无动作)
    /// - Parameters:
    ///   - title: 操作表标题
    ///   - message: 操作表消息
    ///   - cancel: 取消按钮标题，默认取消
    ///   - cancelBlock: 取消按钮事件
    public func fw_showSheet(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        cancel: AttributedStringParameter?,
        cancelBlock: (() -> Void)? = nil
    ) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw.main?.fw.topPresentedController
        }
        ctrl?.fw_showSheet(title: title, message: message, cancel: cancel, cancelBlock: cancelBlock)
    }

    /// 显示操作表(简单版)
    /// - Parameters:
    ///   - title: 操作表标题
    ///   - message: 操作表消息
    ///   - actions: 动作按钮标题列表
    ///   - actionBlock: 动作按钮点击事件，参数为索引index
    ///   - cancelBlock: 取消按钮事件
    public func fw_showSheet(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        actions: [AttributedStringParameter]?,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw.main?.fw.topPresentedController
        }
        ctrl?.fw_showSheet(title: title, message: message, actions: actions, actionBlock: actionBlock, cancelBlock: cancelBlock)
    }

    /// 显示操作表(详细版)
    /// - Parameters:
    ///   - title: 操作表标题
    ///   - message: 操作表消息
    ///   - cancel: 取消按钮标题，默认取消
    ///   - actions: 动作按钮标题列表
    ///   - currentIndex: 当前选中动作索引，默认-1
    ///   - actionBlock: 动作按钮点击事件，参数为索引index
    ///   - cancelBlock: 取消按钮事件
    public func fw_showSheet(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        cancel: AttributedStringParameter?,
        actions: [AttributedStringParameter]?,
        currentIndex: Int = -1,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw.main?.fw.topPresentedController
        }
        ctrl?.fw_showSheet(title: title, message: message, cancel: cancel, actions: actions, currentIndex: currentIndex, actionBlock: actionBlock, cancelBlock: cancelBlock)
    }

    /// 显示弹出框(完整版)
    /// - Parameters:
    ///   - title: 操作表标题
    ///   - message: 操作表消息
    ///   - cancel: 取消按钮标题，默认Alert单按钮关闭，Alert多按钮或Sheet取消
    ///   - actions: 动作按钮标题列表
    ///   - currentIndex: 当前选中动作索引，默认-1
    ///   - actionBlock: 动作按钮点击事件，参数为输入值数组和索引index
    ///   - cancelBlock: 取消按钮事件
    ///   - customBlock: 自定义弹出框事件
    public func fw_showSheet(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        cancel: AttributedStringParameter?,
        actions: [AttributedStringParameter]?,
        currentIndex: Int = -1,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)?,
        customBlock: ((Any) -> Void)?
    ) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw.main?.fw.topPresentedController
        }
        ctrl?.fw_showSheet(title: title, message: message, cancel: cancel, actions: actions, currentIndex: currentIndex, actionBlock: actionBlock, cancelBlock: cancelBlock, customBlock: customBlock)
    }
    
    /// 手工隐藏弹出框，完成后回调
    /// - Parameters:
    ///   - animated: 是否执行动画
    ///   - completion: 完成回调
    public func fw_hideAlert(
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        var ctrl = self.fw_viewController
        if ctrl == nil {
            ctrl = UIWindow.fw.main?.rootViewController
        }
        ctrl?.fw_hideAlert(animated: animated, completion: completion)
    }
    
    /// 判断是否正在显示弹出框
    public var fw_isShowingAlert: Bool {
        var ctrl = self.fw_viewController
        if ctrl == nil {
            ctrl = UIWindow.fw.main?.rootViewController
        }
        return ctrl?.fw_isShowingAlert ?? false
    }
    
}

/// 系统弹出动作title仅支持NSString，如果需要支持NSAttributedString等，请使用AlertController
@_spi(FW) extension UIAlertAction {
    
    /// 自定义样式，默认为样式单例
    public var fw_alertAppearance: AlertAppearance! {
        get {
            let appearance = fw.property(forName: "fw_alertAppearance") as? AlertAppearance
            return appearance ?? AlertAppearance.appearance
        }
        set {
            fw.setProperty(newValue, forName: "fw_alertAppearance")
        }
    }
    
    /// 是否是推荐动作
    public var fw_isPreferred: Bool {
        get {
            return fw.propertyBool(forName: "fw_isPreferred")
        }
        set {
            fw.setPropertyBool(newValue, forName: "fw_isPreferred")
            if self.fw_titleColor != nil || (self.title?.count ?? 0) < 1 || !self.fw_alertAppearance.actionEnabled { return }
            
            var titleColor: UIColor?
            if !self.isEnabled {
                titleColor = self.fw_alertAppearance.disabledActionColor
            } else if newValue {
                titleColor = self.fw_alertAppearance.preferredActionColor
            } else if self.style == .destructive {
                titleColor = self.fw_alertAppearance.destructiveActionColor
            } else if self.style == .cancel {
                titleColor = self.fw_alertAppearance.cancelActionColor
            } else {
                titleColor = self.fw_alertAppearance.actionColor
            }
            if let titleColor = titleColor {
                self.fw.invokeSetter("titleTextColor", object: titleColor)
            }
        }
    }

    /// 指定标题颜色
    public var fw_titleColor: UIColor? {
        get {
            return fw.property(forName: "fw_titleColor") as? UIColor
        }
        set {
            fw.setProperty(newValue, forName: "fw_titleColor")
            self.fw.invokeSetter("titleTextColor", object: newValue)
        }
    }
    
    /// 快速创建弹出动作，title仅支持NSString
    public static func fw_action(object: AttributedStringParameter?, style: UIAlertAction.Style, handler: ((UIAlertAction) -> Void)?) -> UIAlertAction {
        return fw_action(object: object, style: style, appearance: nil, handler: handler)
    }

    /// 快速创建弹出动作，title仅支持NSString，支持appearance
    public static func fw_action(object: AttributedStringParameter?, style: UIAlertAction.Style, appearance: AlertAppearance?, handler: ((UIAlertAction) -> Void)?) -> UIAlertAction {
        let title = object as? String
        let attributedTitle = title != nil ? nil : object?.attributedStringValue
        
        let alertAction = UIAlertAction(title: attributedTitle != nil ? attributedTitle?.string : title, style: style, handler: handler)
        
        if let attributedTitle = attributedTitle, attributedTitle.length > 0,
           let titleColor = attributedTitle.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor {
            alertAction.fw_titleColor = titleColor
        }
        
        alertAction.fw_alertAppearance = appearance
        alertAction.fw_isPreferred = false
        return alertAction
    }
    
}

/// 系统弹出框title和message仅支持NSString，如果需要支持NSAttributedString等，请使用AlertController
@_spi(FW) extension UIAlertController {
    
    /// 自定义样式，默认为样式单例
    public var fw_alertAppearance: AlertAppearance! {
        get {
            let appearance = fw.property(forName: "fw_alertAppearance") as? AlertAppearance
            return appearance ?? AlertAppearance.appearance
        }
        set {
            fw.setProperty(newValue, forName: "fw_alertAppearance")
        }
    }
    
    /// 弹出框样式，默认为Default
    public var fw_alertStyle: AlertStyle {
        get {
            return .init(rawValue: fw.propertyInt(forName: "fw_alertStyle"))
        }
        set {
            fw.setPropertyInt(newValue.rawValue, forName: "fw_alertStyle")
        }
    }

    /// 设置属性标题
    public var fw_attributedTitle: NSAttributedString? {
        get {
            return fw.property(forName: "fw_attributedTitle") as? NSAttributedString
        }
        set {
            fw.setPropertyCopy(newValue, forName: "fw_attributedTitle")
            self.fw.invokeSetter("attributedTitle", object: newValue)
        }
    }

    /// 设置属性消息
    public var fw_attributedMessage: NSAttributedString? {
        get {
            return fw.property(forName: "fw_attributedMessage") as? NSAttributedString
        }
        set {
            fw.setPropertyCopy(newValue, forName: "fw_attributedMessage")
            self.fw.invokeSetter("attributedMessage", object: newValue)
        }
    }
    
    /// 快速创建弹出控制器，title和message仅支持NSString
    public static func fw_alertController(title: AttributedStringParameter?, message: AttributedStringParameter?, preferredStyle: UIAlertController.Style) -> UIAlertController {
        return self.fw_alertController(title: title, message: message, preferredStyle: preferredStyle, appearance: nil)
    }

    /// 快速创建弹出控制器，title和message仅支持NSString，支持自定义样式
    public static func fw_alertController(title titleObject: AttributedStringParameter?, message messageObject: AttributedStringParameter?, preferredStyle: UIAlertController.Style, appearance: AlertAppearance?) -> UIAlertController {
        let title = titleObject as? String
        let attributedTitle = title != nil ? nil : titleObject?.attributedStringValue
        let message = messageObject as? String
        let attributedMessage = message != nil ? nil : messageObject?.attributedStringValue
        
        let alertController = UIAlertController(title: attributedTitle != nil ? attributedTitle?.string : title, message: attributedMessage != nil ? attributedMessage?.string : message, preferredStyle: preferredStyle)
        
        alertController.fw_alertAppearance = appearance
        if attributedTitle != nil {
            alertController.fw_attributedTitle = attributedTitle
        } else if let title = title, title.count > 0 && alertController.fw_alertAppearance.controllerEnabled {
            var titleAttributes: [NSAttributedString.Key: Any] = [:]
            if let titleFont = alertController.fw_alertAppearance.titleFont {
                titleAttributes[.font] = titleFont
            }
            if let titleColor = alertController.fw_alertAppearance.titleColor {
                titleAttributes[.foregroundColor] = titleColor
            }
            alertController.fw_attributedTitle = NSAttributedString(string: title, attributes: titleAttributes)
        }
        
        if attributedMessage != nil {
            alertController.fw_attributedMessage = attributedMessage
        } else if let message = message, message.count > 0 && alertController.fw_alertAppearance.controllerEnabled {
            var messageAttributes: [NSAttributedString.Key: Any] = [:]
            if let messageFont = alertController.fw_alertAppearance.messageFont {
                messageAttributes[.font] = messageFont
            }
            if let messageColor = alertController.fw_alertAppearance.messageColor {
                messageAttributes[.foregroundColor] = messageColor
            }
            alertController.fw_attributedMessage = NSAttributedString(string: message, attributes: messageAttributes)
        }
        
        alertController.fw.observeProperty(\.preferredAction) { object, _ in
            for action in object.actions {
                if action.fw_isPreferred { action.fw_isPreferred = false }
            }
            object.preferredAction?.fw_isPreferred = true
        }
        
        return alertController
    }
    
    fileprivate static func fw_swizzleAlertController() {
        NSObject.fw_swizzleInstanceMethod(
            UIAlertController.self,
            selector: #selector(UIAlertController.viewDidLoad),
            methodSignature: (@convention(c) (UIAlertController, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UIAlertController) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            
            if selfObject.preferredStyle != .actionSheet { return }
            if selfObject.fw_attributedTitle == nil && selfObject.fw_attributedMessage == nil { return }
            
            // 兼容iOS13操作表设置title和message样式不生效问题
            guard let targetClass = objc_getClass(String(format: "%@%@%@", "_U", "IInterfaceActionGrou", "pHeaderScrollView")) as? AnyClass else { return }
            
            UIAlertController.fw_alertSubview(selfObject.view) { view in
                if !view.isKind(of: targetClass) { return false }
                
                UIAlertController.fw_alertSubview(view) { view in
                    if let effectView = view as? UIVisualEffectView {
                        // 取消effect效果，否则样式不生效，全是灰色
                        effectView.effect = nil
                        return true
                    }
                    return false
                }
                return true
            }
        }}
    }
    
    @discardableResult
    private static func fw_alertSubview(_ view: UIView, block: @escaping (UIView) -> Bool) -> UIView? {
        if block(view) {
            return view
        }
        
        for subview in view.subviews {
            let resultView = fw_alertSubview(subview, block: block)
            if resultView != nil {
                return resultView
            }
        }
        
        return nil
    }
    
}

// MARK: - FrameworkAutoloader+AlertPlugin
@objc extension FrameworkAutoloader {
    
    static func loadPlugin_AlertPlugin() {
        UIAlertController.fw_swizzleAlertController()
    }
    
}
