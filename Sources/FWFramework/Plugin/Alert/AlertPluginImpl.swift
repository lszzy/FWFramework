//
//  AlertPluginImpl.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - AlertPluginImpl
/// 默认弹窗插件
open class AlertPluginImpl: NSObject, AlertPlugin, @unchecked Sendable {
    
    // MARK: - Accessor
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = AlertPluginImpl()

    /// 自定义Alert弹窗样式，nil时使用单例
    open var customAlertAppearance: AlertAppearance?

    /// 自定义ActionSheet弹窗样式，nil时使用单例
    open var customSheetAppearance: AlertAppearance?

    /// 自定义弹窗类数组，默认nil时查找UIAlertController|AlertController
    open var customAlertClasses: [AnyClass]?

    /// 弹窗自定义句柄，show方法自动调用
    open var customBlock: ((UIAlertController) -> Void)?

    /// 默认close按钮文本句柄，alert单按钮或sheet单取消生效。未设置时为关闭
    open var defaultCloseButton: ((UIAlertController.Style) -> AttributedStringParameter?)?
    /// 默认cancel按钮文本句柄，alert多按钮或sheet生效。未设置时为取消
    open var defaultCancelButton: ((UIAlertController.Style) -> AttributedStringParameter?)?
    /// 默认confirm按钮文本句柄，alert多按钮生效。未设置时为确定
    open var defaultConfirmButton: (() -> AttributedStringParameter?)?

    /// 错误标题格式化句柄，error生效，默认nil
    open var errorTitleFormatter: ((Error?) -> AttributedStringParameter?)?
    /// 错误消息格式化句柄，error生效，默认nil
    open var errorMessageFormatter: ((Error?) -> AttributedStringParameter?)?
    /// 错误样式格式化句柄，error生效，默认nil
    open var errorStyleFormatter: ((Error?) -> AlertStyle)?
    /// 错误按钮格式化句柄，error生效，默认nil
    open var errorButtonFormatter: ((Error?) -> AttributedStringParameter?)?
    
    // MARK: - AlertPlugin
    open func showAlert(title: AttributedStringParameter?, message: AttributedStringParameter?, style: AlertStyle, cancel: AttributedStringParameter?, actions: [AttributedStringParameter]?, promptCount: Int, promptBlock: ((UITextField, Int) -> Void)?, actionBlock: (([String], Int) -> Void)?, cancelBlock: (() -> Void)?, customBlock: ((Any) -> Void)? = nil, in viewController: UIViewController) {
        // 初始化Alert
        let customAppearance = self.customAlertAppearance
        let alertController = UIAlertController.fw.alertController(title: title, message: message, preferredStyle: .alert, appearance: customAppearance)
        alertController.fw.alertStyle = style
        
        // 添加输入框
        for promptIndex in 0 ..< promptCount {
            alertController.addTextField { textField in
                promptBlock?(textField, promptIndex)
            }
        }
        
        // 添加动作按钮
        for actionIndex in 0 ..< (actions?.count ?? 0) {
            let alertAction = UIAlertAction.fw.action(object: actions?[actionIndex], style: .default, appearance: customAppearance) { action in
                if actionBlock != nil {
                    var values: [String] = []
                    for fieldIndex in 0 ..< promptCount {
                        let textField = alertController.textFields?[fieldIndex]
                        values.append(textField?.text ?? "")
                    }
                    actionBlock?(values, actionIndex)
                }
            }
            alertController.addAction(alertAction)
        }
        
        // 添加取消按钮
        if cancel != nil {
            let cancelAction = UIAlertAction.fw.action(object: cancel, style: .cancel, appearance: customAppearance) { action in
                cancelBlock?()
            }
            alertController.addAction(cancelAction)
        }
        
        // 添加首选按钮
        if let preferredActionBlock = alertController.fw.alertAppearance.preferredActionBlock, alertController.actions.count > 0 {
            let preferredAction = preferredActionBlock(alertController)
            if preferredAction != nil {
                alertController.preferredAction = preferredAction
            }
        }
        
        // 自定义并显示Alert
        self.customBlock?(alertController)
        customBlock?(alertController)
        viewController.present(alertController, animated: true)
    }
    
    open func showSheet(title: AttributedStringParameter?, message: AttributedStringParameter?, cancel: AttributedStringParameter?, actions: [AttributedStringParameter]?, currentIndex: Int, actionBlock: ((Int) -> Void)?, cancelBlock: (() -> Void)?, customBlock: ((Any) -> Void)? = nil, in viewController: UIViewController) {
        // 初始化Alert
        let customAppearance = customSheetAppearance
        let alertController = UIAlertController.fw.alertController(title: title, message: message, preferredStyle: .actionSheet, appearance: customAppearance)
        
        // 添加动作按钮
        for actionIndex in 0 ..< (actions?.count ?? 0) {
            let alertAction = UIAlertAction.fw.action(object: actions?[actionIndex], style: .default, appearance: customAppearance) { action in
                actionBlock?(actionIndex)
            }
            alertController.addAction(alertAction)
        }
        
        // 添加取消按钮
        if cancel != nil {
            let cancelAction = UIAlertAction.fw.action(object: cancel, style: .cancel, appearance: customAppearance) { action in
                cancelBlock?()
            }
            alertController.addAction(cancelAction)
        }
        
        // 添加首选按钮
        if currentIndex >= 0, alertController.actions.count > currentIndex {
            alertController.preferredAction = alertController.actions[currentIndex]
        } else if let preferredActionBlock = alertController.fw.alertAppearance.preferredActionBlock, alertController.actions.count > 0 {
            let preferredAction = preferredActionBlock(alertController)
            if preferredAction != nil {
                alertController.preferredAction = preferredAction
            }
        }
        
        // 兼容iPad，默认居中显示ActionSheet。注意点击视图(如UIBarButtonItem)必须是sourceView及其子视图
        if UIDevice.current.userInterfaceIdiom == .pad,
           let popoverController = alertController.popoverPresentationController {
            let ancestorView = viewController.fw.ancestorView
            popoverController.sourceView = ancestorView
            popoverController.sourceRect = CGRect(x: ancestorView.center.x, y: ancestorView.center.y, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        // 自定义并显示Alert
        self.customBlock?(alertController)
        customBlock?(alertController)
        viewController.present(alertController, animated: true)
    }
    
    open func hideAlert(animated: Bool, completion: (() -> Void)? = nil, in viewController: UIViewController) {
        let alertController = showingAlertController(viewController)
        if let alertController = alertController {
            alertController.presentingViewController?.dismiss(animated: animated, completion: completion)
        } else {
            completion?()
        }
    }
    
    open func isShowingAlert(in viewController: UIViewController) -> Bool {
        let alertController = showingAlertController(viewController)
        return alertController != nil
    }
    
    // MARK: - Private
    private func showingAlertController(_ viewController: UIViewController) -> UIViewController? {
        var alertController: UIViewController?
        let alertClasses = (customAlertClasses?.count ?? 0) > 0 ? customAlertClasses! : [UIAlertController.self, AlertController.self]
        
        var presentedController = viewController.presentedViewController
        while presentedController != nil {
            for alertClass in alertClasses {
                if presentedController?.isKind(of: alertClass) ?? false {
                    alertController = presentedController
                    break
                }
            }
            if alertController != nil {
                break
            }
            presentedController = presentedController?.presentedViewController
        }
        
        return alertController
    }
    
}

// MARK: - AlertControllerImpl
/// 自定义弹窗插件
open class AlertControllerImpl: NSObject, AlertPlugin, @unchecked Sendable {
    
    // MARK: - Accessor
    /// 单例模式
    @objc(sharedInstance)
    public static let shared = AlertControllerImpl()

    /// 自定义Alert弹窗样式，nil时使用单例
    open var customAlertAppearance: AlertControllerAppearance?

    /// 自定义ActionSheet弹窗样式，nil时使用单例
    open var customSheetAppearance: AlertControllerAppearance?

    /// 点击暗色背景关闭时是否触发cancelBlock，默认NO
    open var dimmingTriggerCancel: Bool = false
    
    /// 是否隐藏ActionSheet取消按钮，取消后可点击背景关闭并触发cancelBlock
    open var hidesSheetCancel: Bool = false

    /// 弹窗自定义句柄，show方法自动调用
    open var customBlock: ((AlertController) -> Void)?
    
    // MARK: - AlertPlugin
    open func showAlert(title: AttributedStringParameter?, message: AttributedStringParameter?, style: AlertStyle, cancel: AttributedStringParameter?, actions: [AttributedStringParameter]?, promptCount: Int, promptBlock: ((UITextField, Int) -> Void)?, actionBlock: (([String], Int) -> Void)?, cancelBlock: (() -> Void)?, customBlock: ((Any) -> Void)? = nil, in viewController: UIViewController) {
        // 初始化Alert
        let customAppearance = self.customAlertAppearance
        let alertController = alertController(title: title, message: message, preferredStyle: .alert, appearance: customAppearance)
        alertController.alertStyle = style
        
        // 添加输入框
        for promptIndex in 0 ..< promptCount {
            alertController.addTextField { textField in
                promptBlock?(textField, promptIndex)
            }
        }
        
        // 添加动作按钮
        for actionIndex in 0 ..< (actions?.count ?? 0) {
            let alertAction = action(object: actions?[actionIndex], style: .default, appearance: customAppearance) { action in
                if actionBlock != nil {
                    var values: [String] = []
                    for fieldIndex in 0 ..< promptCount {
                        let textField = alertController.textFields?[fieldIndex]
                        values.append(textField?.text ?? "")
                    }
                    actionBlock?(values, actionIndex)
                }
            }
            alertController.addAction(alertAction)
        }
        
        // 添加取消按钮
        if cancel != nil {
            let cancelAction = action(object: cancel, style: .cancel, appearance: customAppearance) { action in
                cancelBlock?()
            }
            alertController.addAction(cancelAction)
        }
        
        // 点击背景
        if dimmingTriggerCancel {
            alertController.dismissCompletion = cancelBlock
        }
        
        // 添加首选按钮
        if let preferredActionBlock = alertController.alertAppearance.preferredActionBlock, alertController.actions.count > 0 {
            let preferredAction = preferredActionBlock(alertController)
            if preferredAction != nil {
                alertController.preferredAction = preferredAction
            }
        }
        
        // 自定义并显示Alert
        self.customBlock?(alertController)
        customBlock?(alertController)
        viewController.present(alertController, animated: true)
    }
    
    open func showSheet(title: AttributedStringParameter?, message: AttributedStringParameter?, cancel: AttributedStringParameter?, actions: [AttributedStringParameter]?, currentIndex: Int, actionBlock: ((Int) -> Void)?, cancelBlock: (() -> Void)?, customBlock: ((Any) -> Void)? = nil, in viewController: UIViewController) {
        // 初始化Alert
        let customAppearance = customSheetAppearance
        let alertController = alertController(title: title, message: message, preferredStyle: .actionSheet, appearance: customAppearance)
        
        // 添加动作按钮
        for actionIndex in 0 ..< (actions?.count ?? 0) {
            let alertAction = action(object: actions?[actionIndex], style: .default, appearance: customAppearance) { action in
                actionBlock?(actionIndex)
            }
            alertController.addAction(alertAction)
        }
        
        // 添加取消按钮
        if cancel != nil && !hidesSheetCancel {
            let cancelAction = action(object: cancel, style: .cancel, appearance: customAppearance) { action in
                cancelBlock?()
            }
            alertController.addAction(cancelAction)
        }
        
        // 点击背景
        if dimmingTriggerCancel || hidesSheetCancel {
            alertController.dismissCompletion = cancelBlock
        }
        
        // 添加首选按钮
        if currentIndex >= 0, alertController.actions.count > currentIndex {
            alertController.preferredAction = alertController.actions[currentIndex]
        } else if let preferredActionBlock = alertController.alertAppearance.preferredActionBlock, alertController.actions.count > 0 {
            let preferredAction = preferredActionBlock(alertController)
            if preferredAction != nil {
                alertController.preferredAction = preferredAction
            }
        }
        
        // 自定义并显示Alert
        self.customBlock?(alertController)
        customBlock?(alertController)
        viewController.present(alertController, animated: true)
    }
    
    // MARK: - Public
    /// 显示自定义视图弹窗，无默认按钮
    open func showAlert(style: UIAlertController.Style, headerView: UIView, cancel: AttributedStringParameter?, actions: [AttributedStringParameter]?, actionBlock: ((Int) -> Void)?, cancelBlock: (() -> Void)?, customBlock: ((Any) -> Void)? = nil, in viewController: UIViewController) {
        // 初始化Alert
        let customAppearance = style == .actionSheet ? customSheetAppearance : customAlertAppearance
        let alertController = alertController(headerView: headerView, preferredStyle: style == .actionSheet ? .actionSheet : .alert, appearance: customAppearance)
        
        // 添加动作按钮
        for actionIndex in 0 ..< (actions?.count ?? 0) {
            let alertAction = action(object: actions?[actionIndex], style: .default, appearance: customAppearance) { action in
                actionBlock?(actionIndex)
            }
            alertController.addAction(alertAction)
        }
        
        // 添加取消按钮
        if cancel != nil {
            let cancelAction = action(object: cancel, style: .cancel, appearance: customAppearance) { action in
                cancelBlock?()
            }
            alertController.addAction(cancelAction)
        }
        
        // 点击背景
        if dimmingTriggerCancel {
            alertController.dismissCompletion = cancelBlock
        }
        
        // 添加首选按钮
        if let preferredActionBlock = alertController.alertAppearance.preferredActionBlock, alertController.actions.count > 0 {
            let preferredAction = preferredActionBlock(alertController)
            if preferredAction != nil {
                alertController.preferredAction = preferredAction
            }
        }
        
        // 自定义并显示Alert
        self.customBlock?(alertController)
        customBlock?(alertController)
        viewController.present(alertController, animated: true)
    }
    
    // MARK: - Private
    private func alertController(title titleObject: AttributedStringParameter?, message messageObject: AttributedStringParameter?, preferredStyle: AlertControllerStyle, appearance: AlertControllerAppearance?) -> AlertController {
        let title = titleObject as? String
        let attributedTitle = title != nil ? nil : titleObject?.attributedStringValue
        let message = messageObject as? String
        let attributedMessage = message != nil ? nil : messageObject?.attributedStringValue
        
        let alertController = AlertController(title: attributedTitle != nil ? nil : title, message: attributedMessage != nil ? nil : message, preferredStyle: preferredStyle, animationType: .default, appearance: appearance)
        alertController.tapBackgroundViewDismiss = (preferredStyle == .actionSheet)
        
        if let attributedTitle = attributedTitle {
            alertController.attributedTitle = attributedTitle
        } else if let title = title, title.count > 0, alertController.alertAppearance.controllerEnabled {
            var titleAttributes: [NSAttributedString.Key: Any] = [:]
            if let titleFont = alertController.alertAppearance.titleFont {
                titleAttributes[.font] = titleFont
            }
            if let titleColor = alertController.alertAppearance.titleColor {
                titleAttributes[.foregroundColor] = titleColor
            }
            alertController.attributedTitle = NSAttributedString(string: title, attributes: titleAttributes)
        }
        
        if let attributedMessage = attributedMessage {
            alertController.attributedMessage = attributedMessage
        } else if let message = message, message.count > 0, alertController.alertAppearance.controllerEnabled {
            var messageAttributes: [NSAttributedString.Key: Any] = [:]
            if let messageFont = alertController.alertAppearance.messageFont {
                messageAttributes[.font] = messageFont
            }
            if let messageColor = alertController.alertAppearance.messageColor {
                messageAttributes[.foregroundColor] = messageColor
            }
            alertController.attributedMessage = NSAttributedString(string: message, attributes: messageAttributes)
        }
        
        return alertController
    }
    
    private func alertController(headerView: UIView, preferredStyle: AlertControllerStyle, appearance: AlertControllerAppearance?) -> AlertController {
        let alertController = AlertController(customHeaderView: headerView, preferredStyle: preferredStyle, animationType: .default, appearance: appearance)
        alertController.tapBackgroundViewDismiss = (preferredStyle == .actionSheet)
        
        return alertController
    }
    
    private func action(object: AttributedStringParameter?, style: AlertActionStyle, appearance: AlertControllerAppearance?, handler: ((AlertAction) -> Void)?) -> AlertAction {
        let title = object as? String
        let attributedTitle = title != nil ? nil : object?.attributedStringValue
        
        let alertAction = AlertAction(title: attributedTitle != nil ? nil : title, style: style, appearance: appearance, handler: handler)
        if let attributedTitle = attributedTitle {
            alertAction.attributedTitle = attributedTitle
        } else {
            alertAction.isPreferred = false
        }
        
        return alertAction
    }
    
}
