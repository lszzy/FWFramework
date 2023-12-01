//
//  AlertPlugin+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

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
