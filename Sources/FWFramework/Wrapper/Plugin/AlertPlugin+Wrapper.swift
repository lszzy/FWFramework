//
//  AlertPlugin.swift
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
        get { return base.__fw_alertPlugin }
        set { base.__fw_alertPlugin = newValue }
    }

    /// 显示警告框(简单版)
    /// - Parameters:
    ///   - title: 警告框标题
    ///   - message:  警告框消息
    ///   - cancel: 取消按钮标题，默认关闭
    ///   - cancelBlock: 取消按钮事件
    public func showAlert(
        title: Any?,
        message: Any?,
        cancel: Any? = nil,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.__fw_showAlert(withTitle: title, message: message, cancel: cancel, cancel: cancelBlock)
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
        title: Any?,
        message: Any?,
        style: AlertStyle = .default,
        cancel: Any?,
        actions: [Any]?,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.__fw_showAlert(withTitle: title, message: message, style: style, cancel: cancel, actions: actions, actionBlock: actionBlock, cancel: cancelBlock)
    }
    
    /// 显示确认框(简单版)
    /// - Parameters:
    ///   - title: 确认框标题
    ///   - message: 确认框消息
    ///   - confirmBlock: 确认按钮事件
    ///   - cancelBlock: 取消按钮事件
    public func showConfirm(
        title: Any?,
        message: Any?,
        confirmBlock: (() -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.__fw_showConfirm(withTitle: title, message: message, cancel: nil, confirm: nil, confirmBlock: confirmBlock, cancel: cancelBlock)
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
        title: Any?,
        message: Any?,
        cancel: Any?,
        confirm: Any?,
        confirmBlock: (() -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.__fw_showConfirm(withTitle: title, message: message, cancel: cancel, confirm: confirm, confirmBlock: confirmBlock, cancel: cancelBlock)
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
        title: Any?,
        message: Any?,
        cancel: Any?,
        confirm: Any?,
        promptBlock: ((UITextField) -> Void)? = nil,
        confirmBlock: ((String) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.__fw_showPrompt(withTitle: title, message: message, cancel: cancel, confirm: confirm, promptBlock: promptBlock, confirmBlock: confirmBlock, cancel: cancelBlock)
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
        title: Any?,
        message: Any?,
        cancel: Any?,
        confirm: Any?,
        promptCount: Int,
        promptBlock: ((UITextField, Int) -> Void)?,
        confirmBlock: (([String]) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.__fw_showPrompt(withTitle: title, message: message, cancel: cancel, confirm: confirm, promptCount: promptCount, promptBlock: promptBlock, confirmBlock: confirmBlock, cancel: cancelBlock)
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
        title: Any?,
        message: Any?,
        style: AlertStyle = .default,
        cancel: Any?,
        actions: [Any]?,
        promptCount: Int = 0,
        promptBlock: ((UITextField, Int) -> Void)? = nil,
        actionBlock: (([String], Int) -> Void)?,
        cancelBlock: (() -> Void)?,
        customBlock: ((Any) -> Void)?
    ) {
        base.__fw_showAlert(withTitle: title, message: message, style: style, cancel: cancel, actions: actions, promptCount: promptCount, promptBlock: promptBlock, actionBlock: actionBlock, cancel: cancelBlock, customBlock: customBlock)
    }
    
    /// 显示操作表(无动作)
    /// - Parameters:
    ///   - title: 操作表标题
    ///   - message: 操作表消息
    ///   - cancel: 取消按钮标题，默认取消
    ///   - cancelBlock: 取消按钮事件
    public func showSheet(
        title: Any?,
        message: Any?,
        cancel: Any?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.__fw_showSheet(withTitle: title, message: message, cancel: cancel, cancel: cancelBlock)
    }

    /// 显示操作表(简单版)
    /// - Parameters:
    ///   - title: 操作表标题
    ///   - message: 操作表消息
    ///   - actions: 动作按钮标题列表
    ///   - actionBlock: 动作按钮点击事件，参数为索引index
    ///   - cancelBlock: 取消按钮事件
    public func showSheet(
        title: Any?,
        message: Any?,
        actions: [Any]?,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.__fw_showSheet(withTitle: title, message: message, cancel: nil, actions: actions, currentIndex: -1, actionBlock: actionBlock, cancel: cancelBlock)
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
        title: Any?,
        message: Any?,
        cancel: Any?,
        actions: [Any]?,
        currentIndex: Int = -1,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.__fw_showSheet(withTitle: title, message: message, cancel: cancel, actions: actions, currentIndex: currentIndex, actionBlock: actionBlock, cancel: cancelBlock)
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
        title: Any?,
        message: Any?,
        cancel: Any?,
        actions: [Any]?,
        currentIndex: Int = -1,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)?,
        customBlock: ((Any) -> Void)?
    ) {
        base.__fw_showSheet(withTitle: title, message: message, cancel: cancel, actions: actions, currentIndex: currentIndex, actionBlock: actionBlock, cancel: cancelBlock, customBlock: customBlock)
    }
    
    /// 手工隐藏弹出框，完成后回调
    /// - Parameters:
    ///   - animated: 是否执行动画
    ///   - completion: 完成回调
    public func hideAlert(
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        base.__fw_hideAlert(animated, completion: completion)
    }
    
    /// 判断是否正在显示弹出框
    public var isShowingAlert: Bool {
        return base.__fw_isShowingAlert
    }
    
}

extension Wrapper where Base: UIView {
    
    /// 显示警告框(简单版)
    /// - Parameters:
    ///   - title: 警告框标题
    ///   - message:  警告框消息
    ///   - cancel: 取消按钮标题，默认关闭
    ///   - cancelBlock: 取消按钮事件
    public func showAlert(
        title: Any?,
        message: Any?,
        cancel: Any? = nil,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.__fw_showAlert(withTitle: title, message: message, cancel: cancel, cancel: cancelBlock)
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
        title: Any?,
        message: Any?,
        style: AlertStyle = .default,
        cancel: Any?,
        actions: [Any]?,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.__fw_showAlert(withTitle: title, message: message, style: style, cancel: cancel, actions: actions, actionBlock: actionBlock, cancel: cancelBlock)
    }
    
    /// 显示确认框(简单版)
    /// - Parameters:
    ///   - title: 确认框标题
    ///   - message: 确认框消息
    ///   - confirmBlock: 确认按钮事件
    ///   - cancelBlock: 取消按钮事件
    public func showConfirm(
        title: Any?,
        message: Any?,
        confirmBlock: (() -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.__fw_showConfirm(withTitle: title, message: message, cancel: nil, confirm: nil, confirmBlock: confirmBlock, cancel: cancelBlock)
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
        title: Any?,
        message: Any?,
        cancel: Any?,
        confirm: Any?,
        confirmBlock: (() -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.__fw_showConfirm(withTitle: title, message: message, cancel: cancel, confirm: confirm, confirmBlock: confirmBlock, cancel: cancelBlock)
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
        title: Any?,
        message: Any?,
        cancel: Any?,
        confirm: Any?,
        promptBlock: ((UITextField) -> Void)? = nil,
        confirmBlock: ((String) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.__fw_showPrompt(withTitle: title, message: message, cancel: cancel, confirm: confirm, promptBlock: promptBlock, confirmBlock: confirmBlock, cancel: cancelBlock)
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
        title: Any?,
        message: Any?,
        cancel: Any?,
        confirm: Any?,
        promptCount: Int,
        promptBlock: ((UITextField, Int) -> Void)?,
        confirmBlock: (([String]) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.__fw_showPrompt(withTitle: title, message: message, cancel: cancel, confirm: confirm, promptCount: promptCount, promptBlock: promptBlock, confirmBlock: confirmBlock, cancel: cancelBlock)
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
        title: Any?,
        message: Any?,
        style: AlertStyle = .default,
        cancel: Any?,
        actions: [Any]?,
        promptCount: Int = 0,
        promptBlock: ((UITextField, Int) -> Void)? = nil,
        actionBlock: (([String], Int) -> Void)?,
        cancelBlock: (() -> Void)?,
        customBlock: ((Any) -> Void)?
    ) {
        base.__fw_showAlert(withTitle: title, message: message, style: style, cancel: cancel, actions: actions, promptCount: promptCount, promptBlock: promptBlock, actionBlock: actionBlock, cancel: cancelBlock, customBlock: customBlock)
    }
    
    /// 显示操作表(无动作)
    /// - Parameters:
    ///   - title: 操作表标题
    ///   - message: 操作表消息
    ///   - cancel: 取消按钮标题，默认取消
    ///   - cancelBlock: 取消按钮事件
    public func showSheet(
        title: Any?,
        message: Any?,
        cancel: Any?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.__fw_showSheet(withTitle: title, message: message, cancel: cancel, cancel: cancelBlock)
    }

    /// 显示操作表(简单版)
    /// - Parameters:
    ///   - title: 操作表标题
    ///   - message: 操作表消息
    ///   - actions: 动作按钮标题列表
    ///   - actionBlock: 动作按钮点击事件，参数为索引index
    ///   - cancelBlock: 取消按钮事件
    public func showSheet(
        title: Any?,
        message: Any?,
        actions: [Any]?,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.__fw_showSheet(withTitle: title, message: message, cancel: nil, actions: actions, currentIndex: -1, actionBlock: actionBlock, cancel: cancelBlock)
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
        title: Any?,
        message: Any?,
        cancel: Any?,
        actions: [Any]?,
        currentIndex: Int = -1,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        base.__fw_showSheet(withTitle: title, message: message, cancel: cancel, actions: actions, currentIndex: currentIndex, actionBlock: actionBlock, cancel: cancelBlock)
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
        title: Any?,
        message: Any?,
        cancel: Any?,
        actions: [Any]?,
        currentIndex: Int = -1,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)?,
        customBlock: ((Any) -> Void)?
    ) {
        base.__fw_showSheet(withTitle: title, message: message, cancel: cancel, actions: actions, currentIndex: currentIndex, actionBlock: actionBlock, cancel: cancelBlock, customBlock: customBlock)
    }
    
    /// 手工隐藏弹出框，完成后回调
    /// - Parameters:
    ///   - animated: 是否执行动画
    ///   - completion: 完成回调
    public func hideAlert(
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        base.__fw_hideAlert(animated, completion: completion)
    }
    
    /// 判断是否正在显示弹出框
    public var isShowingAlert: Bool {
        return base.__fw_isShowingAlert
    }
    
}

extension Wrapper where Base: UIAlertAction {
    
    /// 自定义样式，默认为样式单例
    public var alertAppearance: AlertAppearance {
        get { return base.__fw_alertAppearance }
        set { base.__fw_alertAppearance = newValue }
    }

    /// 指定标题颜色
    public var titleColor: UIColor? {
        get { return base.__fw_titleColor }
        set { base.__fw_titleColor = newValue }
    }
    
    /// 快速创建弹出动作，title仅支持NSString
    public static func action(object: Any?, style: UIAlertAction.Style, handler: ((UIAlertAction) -> Void)?) -> UIAlertAction {
        return Base.__fw_action(with: object, style: style, handler: handler)
    }

    /// 快速创建弹出动作，title仅支持NSString，支持appearance
    public static func action(object: Any?, style: UIAlertAction.Style, appearance: AlertAppearance?, handler: ((UIAlertAction) -> Void)?) -> UIAlertAction {
        return Base.__fw_action(with: object, style: style, appearance: appearance, handler: handler)
    }
    
}

extension Wrapper where Base: UIAlertController {
    
    /// 自定义样式，默认为样式单例
    public var alertAppearance: AlertAppearance {
        get { return base.__fw_alertAppearance }
        set { base.__fw_alertAppearance = newValue }
    }
    
    /// 弹出框样式，默认为Default
    public var alertStyle: AlertStyle {
        get { return base.__fw_alertStyle }
        set { base.__fw_alertStyle = newValue }
    }

    /// 设置属性标题
    public var attributedTitle: NSAttributedString? {
        get { return base.__fw_attributedTitle }
        set { base.__fw_attributedTitle = newValue }
    }

    /// 设置属性消息
    public var attributedMessage: NSAttributedString? {
        get { return base.__fw_attributedMessage }
        set { base.__fw_attributedMessage = newValue }
    }
    
    /// 快速创建弹出控制器，title和message仅支持NSString
    public static func alertController(title: Any?, message: Any?, preferredStyle: UIAlertController.Style) -> UIAlertController {
        return Base.__fw_alertController(withTitle: title, message: message, preferredStyle: preferredStyle)
    }

    /// 快速创建弹出控制器，title和message仅支持NSString，支持自定义样式
    public static func alertController(title: Any?, message: Any?, preferredStyle: UIAlertController.Style, appearance: AlertAppearance?) -> UIAlertController {
        return Base.__fw_alertController(withTitle: title, message: message, preferredStyle: preferredStyle, appearance: appearance)
    }
    
}
