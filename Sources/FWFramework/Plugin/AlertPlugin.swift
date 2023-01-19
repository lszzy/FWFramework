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

@_spi(FW) extension UIViewController {
    
    /// 自定义弹窗插件，未设置时自动从插件池加载
    public var fw_alertPlugin: AlertPlugin! {
        get {
            if let alertPlugin = fw_property(forName: "fw_alertPlugin") as? AlertPlugin {
                return alertPlugin
            } else if let alertPlugin = PluginManager.loadPlugin(AlertPlugin.self) {
                return alertPlugin
            }
            return AlertPluginImpl.shared
        }
        set {
            fw_setProperty(newValue, forName: "fw_alertPlugin")
        }
    }

    /// 显示警告框(简单版)
    /// - Parameters:
    ///   - title: 警告框标题
    ///   - message:  警告框消息
    ///   - cancel: 取消按钮标题，默认关闭
    ///   - cancelBlock: 取消按钮事件
    @objc(__fw_showAlertWithTitle:message:cancel:cancelBlock:)
    public func fw_showAlert(
        title: Any?,
        message: Any?,
        cancel: Any? = nil,
        cancelBlock: (() -> Void)? = nil
    ) {
        fw_showAlert(title: title, message: message, style: .default, cancel: cancel, actions: nil, actionBlock: nil, cancelBlock: cancelBlock)
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
        title: Any?,
        message: Any?,
        style: AlertStyle = .default,
        cancel: Any?,
        actions: [Any]?,
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
        title: Any?,
        message: Any?,
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
    @objc(__fw_showConfirmWithTitle:message:cancel:confirm:confirmBlock:cancelBlock:)
    public func fw_showConfirm(
        title: Any?,
        message: Any?,
        cancel: Any?,
        confirm: Any?,
        confirmBlock: (() -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        let targetConfirm = confirm ?? (AlertPluginImpl.shared.defaultConfirmButton?() ?? AppBundle.localizedString("fw.confirm"))
        
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
    @objc(__fw_showPromptWithTitle:message:cancel:confirm:promptBlock:confirmBlock:cancelBlock:)
    public func fw_showPrompt(
        title: Any?,
        message: Any?,
        cancel: Any?,
        confirm: Any?,
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
        title: Any?,
        message: Any?,
        cancel: Any?,
        confirm: Any?,
        promptCount: Int,
        promptBlock: ((UITextField, Int) -> Void)?,
        confirmBlock: (([String]) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        let targetConfirm = confirm ?? (AlertPluginImpl.shared.defaultConfirmButton?() ?? AppBundle.localizedString("fw.confirm"))
        
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
        // 处理取消按钮，Alert多按钮时默认取消，单按钮时默认关闭
        var targetCancel = cancel
        if cancel == nil {
            if (actions?.count ?? 0) > 0 {
                targetCancel = AlertPluginImpl.shared.defaultCancelButton?(.alert) ?? AppBundle.localizedString("fw.cancel")
            } else {
                targetCancel = AlertPluginImpl.shared.defaultCloseButton?(.alert) ?? AppBundle.localizedString("fw.close")
            }
        }
        
        var plugin: AlertPlugin
        if let alertPlugin = self.fw_alertPlugin, alertPlugin.responds(to: #selector(AlertPlugin.viewController(_:showAlertWithTitle:message:style:cancel:actions:promptCount:promptBlock:actionBlock:cancel:customBlock:))) {
            plugin = alertPlugin
        } else {
            plugin = AlertPluginImpl.shared
        }
        plugin.viewController?(self, showAlertWithTitle: title, message: message, style: style, cancel: targetCancel, actions: actions, promptCount: promptCount, promptBlock: promptBlock, actionBlock: actionBlock, cancel: cancelBlock, customBlock: customBlock)
    }
    
    /// 显示操作表(无动作)
    /// - Parameters:
    ///   - title: 操作表标题
    ///   - message: 操作表消息
    ///   - cancel: 取消按钮标题，默认取消
    ///   - cancelBlock: 取消按钮事件
    public func fw_showSheet(
        title: Any?,
        message: Any?,
        cancel: Any?,
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
        title: Any?,
        message: Any?,
        actions: [Any]?,
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
    @objc(__fw_showSheetWithTitle:message:cancel:actions:currentIndex:actionBlock:cancelBlock:)
    public func fw_showSheet(
        title: Any?,
        message: Any?,
        cancel: Any?,
        actions: [Any]?,
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
        title: Any?,
        message: Any?,
        cancel: Any?,
        actions: [Any]?,
        currentIndex: Int = -1,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)?,
        customBlock: ((Any) -> Void)?
    ) {
        // 处理取消按钮，Sheet多按钮时默认取消，单按钮时默认关闭
        var targetCancel = cancel
        if cancel == nil {
            if (actions?.count ?? 0) > 0 {
                targetCancel = AlertPluginImpl.shared.defaultCancelButton?(.actionSheet) ?? AppBundle.localizedString("fw.cancel")
            } else {
                targetCancel = AlertPluginImpl.shared.defaultCloseButton?(.actionSheet) ?? AppBundle.localizedString("fw.close")
            }
        }
        
        var plugin: AlertPlugin
        if let alertPlugin = self.fw_alertPlugin, alertPlugin.responds(to: #selector(AlertPlugin.viewController(_:showSheetWithTitle:message:cancel:actions:currentIndex:actionBlock:cancel:customBlock:))) {
            plugin = alertPlugin
        } else {
            plugin = AlertPluginImpl.shared
        }
        plugin.viewController?(self, showSheetWithTitle: title, message: message, cancel: targetCancel, actions: actions, currentIndex: currentIndex, actionBlock: actionBlock, cancel: cancelBlock, customBlock: customBlock)
    }
    
    /// 手工隐藏弹出框，完成后回调
    /// - Parameters:
    ///   - animated: 是否执行动画
    ///   - completion: 完成回调
    public func fw_hideAlert(
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        var plugin: AlertPlugin
        if let alertPlugin = self.fw_alertPlugin, alertPlugin.responds(to: #selector(AlertPlugin.viewController(_:hideAlert:completion:))) {
            plugin = alertPlugin
        } else {
            plugin = AlertPluginImpl.shared
        }
        plugin.viewController?(self, hideAlert: animated, completion: completion)
    }
    
    /// 判断是否正在显示弹出框
    public var fw_isShowingAlert: Bool {
        var plugin: AlertPlugin
        if let alertPlugin = self.fw_alertPlugin, alertPlugin.responds(to: #selector(AlertPlugin.isShowingAlert(_:))) {
            plugin = alertPlugin
        } else {
            plugin = AlertPluginImpl.shared
        }
        return plugin.isShowingAlert?(self) ?? false
    }
    
}

@_spi(FW) extension UIView {
    
    /// 显示警告框(简单版)
    /// - Parameters:
    ///   - title: 警告框标题
    ///   - message:  警告框消息
    ///   - cancel: 取消按钮标题，默认关闭
    ///   - cancelBlock: 取消按钮事件
    @objc(__fw_showAlertWithTitle:message:cancel:cancelBlock:)
    public func fw_showAlert(
        title: Any?,
        message: Any?,
        cancel: Any? = nil,
        cancelBlock: (() -> Void)? = nil
    ) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw_mainWindow?.fw_topPresentedController
        }
        ctrl?.fw_showAlert(title: title, message: message, cancel: cancel, cancelBlock: cancelBlock)
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
        title: Any?,
        message: Any?,
        style: AlertStyle = .default,
        cancel: Any?,
        actions: [Any]?,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw_mainWindow?.fw_topPresentedController
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
        title: Any?,
        message: Any?,
        confirmBlock: (() -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw_mainWindow?.fw_topPresentedController
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
    @objc(__fw_showConfirmWithTitle:message:cancel:confirm:confirmBlock:cancelBlock:)
    public func fw_showConfirm(
        title: Any?,
        message: Any?,
        cancel: Any?,
        confirm: Any?,
        confirmBlock: (() -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw_mainWindow?.fw_topPresentedController
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
    @objc(__fw_showPromptWithTitle:message:cancel:confirm:promptBlock:confirmBlock:cancelBlock:)
    public func fw_showPrompt(
        title: Any?,
        message: Any?,
        cancel: Any?,
        confirm: Any?,
        promptBlock: ((UITextField) -> Void)? = nil,
        confirmBlock: ((String) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw_mainWindow?.fw_topPresentedController
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
        title: Any?,
        message: Any?,
        cancel: Any?,
        confirm: Any?,
        promptCount: Int,
        promptBlock: ((UITextField, Int) -> Void)?,
        confirmBlock: (([String]) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw_mainWindow?.fw_topPresentedController
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
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw_mainWindow?.fw_topPresentedController
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
        title: Any?,
        message: Any?,
        cancel: Any?,
        cancelBlock: (() -> Void)? = nil
    ) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw_mainWindow?.fw_topPresentedController
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
        title: Any?,
        message: Any?,
        actions: [Any]?,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw_mainWindow?.fw_topPresentedController
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
        title: Any?,
        message: Any?,
        cancel: Any?,
        actions: [Any]?,
        currentIndex: Int = -1,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw_mainWindow?.fw_topPresentedController
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
        title: Any?,
        message: Any?,
        cancel: Any?,
        actions: [Any]?,
        currentIndex: Int = -1,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)?,
        customBlock: ((Any) -> Void)?
    ) {
        var ctrl = self.fw_viewController
        if ctrl == nil || ctrl?.presentedViewController != nil {
            ctrl = UIWindow.fw_mainWindow?.fw_topPresentedController
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
            ctrl = UIWindow.fw_mainWindow?.rootViewController
        }
        ctrl?.fw_hideAlert(animated: animated, completion: completion)
    }
    
    /// 判断是否正在显示弹出框
    public var fw_isShowingAlert: Bool {
        var ctrl = self.fw_viewController
        if ctrl == nil {
            ctrl = UIWindow.fw_mainWindow?.rootViewController
        }
        return ctrl?.fw_isShowingAlert ?? false
    }
    
}

/// 系统弹出动作title仅支持NSString，如果需要支持NSAttributedString等，请使用AlertController
@_spi(FW) extension UIAlertAction {
    
    /// 自定义样式，默认为样式单例
    public var fw_alertAppearance: AlertAppearance! {
        get {
            let appearance = fw_property(forName: "fw_alertAppearance") as? AlertAppearance
            return appearance ?? AlertAppearance.appearance
        }
        set {
            fw_setProperty(newValue, forName: "fw_alertAppearance")
        }
    }
    
    /// 是否是推荐动作
    public var fw_isPreferred: Bool {
        get {
            return fw_propertyBool(forName: "fw_isPreferred")
        }
        set {
            fw_setPropertyBool(newValue, forName: "fw_isPreferred")
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
                self.fw_invokeSetter("titleTextColor", object: titleColor)
            }
        }
    }

    /// 指定标题颜色
    public var fw_titleColor: UIColor? {
        get {
            return fw_property(forName: "fw_titleColor") as? UIColor
        }
        set {
            fw_setProperty(newValue, forName: "fw_titleColor")
            self.fw_invokeSetter("titleTextColor", object: newValue)
        }
    }
    
    /// 快速创建弹出动作，title仅支持NSString
    public static func fw_action(object: Any?, style: UIAlertAction.Style, handler: ((UIAlertAction) -> Void)?) -> UIAlertAction {
        return fw_action(object: object, style: style, appearance: nil, handler: handler)
    }

    /// 快速创建弹出动作，title仅支持NSString，支持appearance
    @objc(__fw_actionWithObject:style:appearance:handler:)
    public static func fw_action(object: Any?, style: UIAlertAction.Style, appearance: AlertAppearance?, handler: ((UIAlertAction) -> Void)?) -> UIAlertAction {
        let attributedTitle = object as? NSAttributedString
        let alertAction = UIAlertAction(title: attributedTitle != nil ? attributedTitle?.string : (object as? String), style: style, handler: handler)
        
        alertAction.fw_alertAppearance = appearance
        alertAction.fw_isPreferred = false
        return alertAction
    }
    
}

/// 系统弹出框title和message仅支持NSString，如果需要支持NSAttributedString等，请使用AlertController
@_spi(FW) extension UIAlertController {
    
    /// 自定义样式，默认为样式单例
    @objc(__fw_alertAppearance)
    public var fw_alertAppearance: AlertAppearance! {
        get {
            let appearance = fw_property(forName: "fw_alertAppearance") as? AlertAppearance
            return appearance ?? AlertAppearance.appearance
        }
        set {
            fw_setProperty(newValue, forName: "fw_alertAppearance")
        }
    }
    
    /// 弹出框样式，默认为Default
    @objc(__fw_alertStyle)
    public var fw_alertStyle: AlertStyle {
        get {
            return .init(rawValue: fw_propertyInt(forName: "fw_alertStyle"))
        }
        set {
            fw_setPropertyInt(newValue.rawValue, forName: "fw_alertStyle")
        }
    }

    /// 设置属性标题
    public var fw_attributedTitle: NSAttributedString? {
        get {
            return fw_property(forName: "fw_attributedTitle") as? NSAttributedString
        }
        set {
            fw_setPropertyCopy(newValue, forName: "fw_attributedTitle")
            self.fw_invokeSetter("attributedTitle", object: newValue)
        }
    }

    /// 设置属性消息
    public var fw_attributedMessage: NSAttributedString? {
        get {
            return fw_property(forName: "fw_attributedMessage") as? NSAttributedString
        }
        set {
            fw_setPropertyCopy(newValue, forName: "fw_attributedMessage")
            self.fw_invokeSetter("attributedMessage", object: newValue)
        }
    }
    
    /// 快速创建弹出控制器，title和message仅支持NSString
    public static func fw_alertController(title: Any?, message: Any?, preferredStyle: UIAlertController.Style) -> UIAlertController {
        return self.fw_alertController(title: title, message: message, preferredStyle: preferredStyle, appearance: nil)
    }

    /// 快速创建弹出控制器，title和message仅支持NSString，支持自定义样式
    @objc(__fw_alertControllerWithTitle:message:preferredStyle:appearance:)
    public static func fw_alertController(title: Any?, message: Any?, preferredStyle: UIAlertController.Style, appearance: AlertAppearance?) -> UIAlertController {
        let attributedTitle = title as? NSAttributedString
        let attributedMessage = message as? NSAttributedString
        let alertController = UIAlertController(title: attributedTitle != nil ? attributedTitle?.string : (title as? String), message: attributedMessage != nil ? attributedMessage?.string : (message as? String), preferredStyle: preferredStyle)
        
        alertController.fw_alertAppearance = appearance
        if attributedTitle != nil {
            alertController.fw_attributedTitle = attributedTitle
        } else if let alertTitle = alertController.title, alertTitle.count > 0 && alertController.fw_alertAppearance.controllerEnabled {
            var titleAttributes: [NSAttributedString.Key: Any] = [:]
            if let titleFont = alertController.fw_alertAppearance.titleFont {
                titleAttributes[.font] = titleFont
            }
            if let titleColor = alertController.fw_alertAppearance.titleColor {
                titleAttributes[.foregroundColor] = titleColor
            }
            alertController.fw_attributedTitle = NSAttributedString(string: alertTitle, attributes: titleAttributes)
        }
        
        if attributedMessage != nil {
            alertController.fw_attributedMessage = attributedMessage
        } else if let alertMessage = alertController.message, alertMessage.count > 0 && alertController.fw_alertAppearance.controllerEnabled {
            var messageAttributes: [NSAttributedString.Key: Any] = [:]
            if let messageFont = alertController.fw_alertAppearance.messageFont {
                messageAttributes[.font] = messageFont
            }
            if let messageColor = alertController.fw_alertAppearance.messageColor {
                messageAttributes[.foregroundColor] = messageColor
            }
            alertController.fw_attributedMessage = NSAttributedString(string: alertMessage, attributes: messageAttributes)
        }
        
        alertController.fw_observeProperty("preferredAction") { object, _ in
            guard let object = object as? UIAlertController else { return }
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
            if #available(iOS 13.0, *) {
                guard let targetClass = objc_getClass("_UIInterfaceActionGroupHeaderScrollView") as? AnyClass else { return }
                
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

// MARK: - AlertPluginAutoloader
internal class AlertPluginAutoloader: AutoloadProtocol {
    
    static func autoload() {
        UIAlertController.fw_swizzleAlertController()
    }
    
}
