//
//  AlertPluginImpl.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

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
    open var customBlock: (@MainActor @Sendable (AlertController) -> Void)?

    // MARK: - AlertPlugin
    open func showAlert(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        style: AlertStyle,
        cancel: AttributedStringParameter?,
        actions: [AttributedStringParameter]?,
        promptCount: Int,
        promptBlock: (@MainActor @Sendable (UITextField, Int) -> Void)?,
        actionBlock: (@MainActor @Sendable ([String], Int) -> Void)?,
        cancelBlock: (@MainActor @Sendable () -> Void)?,
        customBlock: (@MainActor @Sendable (Any) -> Void)? = nil,
        in viewController: UIViewController
    ) {
        // 初始化Alert
        let customAppearance = customAlertAppearance
        let alertController = alertController(title: title, message: message, preferredStyle: .alert, appearance: customAppearance)
        alertController.alertStyle = style

        // 添加输入框
        for promptIndex in 0..<promptCount {
            alertController.addTextField { textField in
                promptBlock?(textField, promptIndex)
            }
        }

        // 添加动作按钮
        for actionIndex in 0..<(actions?.count ?? 0) {
            let alertAction = action(object: actions?[actionIndex], style: .default, appearance: customAppearance) { _ in
                if actionBlock != nil {
                    var values: [String] = []
                    for fieldIndex in 0..<promptCount {
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
            let cancelAction = action(object: cancel, style: .cancel, appearance: customAppearance) { _ in
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

    open func showSheet(
        title: AttributedStringParameter?,
        message: AttributedStringParameter?,
        cancel: AttributedStringParameter?,
        actions: [AttributedStringParameter]?,
        currentIndex: Int,
        actionBlock: (@MainActor @Sendable (Int) -> Void)?,
        cancelBlock: (@MainActor @Sendable () -> Void)?,
        customBlock: (@MainActor @Sendable (Any) -> Void)? = nil,
        in viewController: UIViewController
    ) {
        // 初始化Alert
        let customAppearance = customSheetAppearance
        let alertController = alertController(title: title, message: message, preferredStyle: .actionSheet, appearance: customAppearance)

        // 添加动作按钮
        for actionIndex in 0..<(actions?.count ?? 0) {
            let alertAction = action(object: actions?[actionIndex], style: .default, appearance: customAppearance) { _ in
                actionBlock?(actionIndex)
            }
            alertController.addAction(alertAction)
        }

        // 添加取消按钮
        if cancel != nil && !hidesSheetCancel {
            let cancelAction = action(object: cancel, style: .cancel, appearance: customAppearance) { _ in
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
    open func showAlert(
        style: UIAlertController.Style,
        headerView: UIView,
        cancel: AttributedStringParameter?,
        actions: [AttributedStringParameter]?,
        actionBlock: (@MainActor @Sendable (Int) -> Void)?,
        cancelBlock: (@MainActor @Sendable () -> Void)?,
        customBlock: (@MainActor @Sendable (Any) -> Void)? = nil,
        in viewController: UIViewController
    ) {
        // 初始化Alert
        let customAppearance = style == .actionSheet ? customSheetAppearance : customAlertAppearance
        let alertController = alertController(headerView: headerView, preferredStyle: style == .actionSheet ? .actionSheet : .alert, appearance: customAppearance)

        // 添加动作按钮
        for actionIndex in 0..<(actions?.count ?? 0) {
            let alertAction = action(object: actions?[actionIndex], style: .default, appearance: customAppearance) { _ in
                actionBlock?(actionIndex)
            }
            alertController.addAction(alertAction)
        }

        // 添加取消按钮
        if cancel != nil {
            let cancelAction = action(object: cancel, style: .cancel, appearance: customAppearance) { _ in
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
    private func alertController(
        title titleObject: AttributedStringParameter?,
        message messageObject: AttributedStringParameter?,
        preferredStyle: AlertControllerStyle,
        appearance: AlertControllerAppearance?
    ) -> AlertController {
        let title = titleObject as? String
        let attributedTitle = title != nil ? nil : titleObject?.attributedStringValue
        let message = messageObject as? String
        let attributedMessage = message != nil ? nil : messageObject?.attributedStringValue

        let alertController = AlertController(title: attributedTitle != nil ? nil : title, message: attributedMessage != nil ? nil : message, preferredStyle: preferredStyle, animationType: .default, appearance: appearance)
        alertController.tapBackgroundViewDismiss = (preferredStyle == .actionSheet)

        if let attributedTitle {
            alertController.attributedTitle = attributedTitle
        } else if let title, title.count > 0, alertController.alertAppearance.controllerEnabled {
            var titleAttributes: [NSAttributedString.Key: Any] = [:]
            if let titleFont = alertController.alertAppearance.titleFont {
                titleAttributes[.font] = titleFont
            }
            if let titleColor = alertController.alertAppearance.titleColor {
                titleAttributes[.foregroundColor] = titleColor
            }
            alertController.attributedTitle = NSAttributedString(string: title, attributes: titleAttributes)
        }

        if let attributedMessage {
            alertController.attributedMessage = attributedMessage
        } else if let message, message.count > 0, alertController.alertAppearance.controllerEnabled {
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

    private func alertController(
        headerView: UIView,
        preferredStyle: AlertControllerStyle,
        appearance: AlertControllerAppearance?
    ) -> AlertController {
        let alertController = AlertController(customHeaderView: headerView, preferredStyle: preferredStyle, animationType: .default, appearance: appearance)
        alertController.tapBackgroundViewDismiss = (preferredStyle == .actionSheet)

        return alertController
    }

    private func action(
        object: AttributedStringParameter?,
        style: AlertActionStyle,
        appearance: AlertControllerAppearance?,
        handler: (@MainActor @Sendable (AlertAction) -> Void)?
    ) -> AlertAction {
        let title = object as? String
        let attributedTitle = title != nil ? nil : object?.attributedStringValue

        let alertAction = AlertAction(title: attributedTitle != nil ? nil : title, style: style, appearance: appearance, handler: handler)
        if let attributedTitle {
            alertAction.attributedTitle = attributedTitle
        } else {
            alertAction.isPreferred = false
        }

        return alertAction
    }
}
