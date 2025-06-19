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
    open var customBlock: (@MainActor @Sendable (UIAlertController) -> Void)?

    /// 默认close按钮文本句柄，alert单按钮或sheet单取消生效。未设置时为关闭
    open var defaultCloseButton: (@MainActor @Sendable (UIAlertController.Style) -> AttributedStringParameter?)?
    /// 默认cancel按钮文本句柄，alert多按钮或sheet生效。未设置时为取消
    open var defaultCancelButton: (@MainActor @Sendable (UIAlertController.Style) -> AttributedStringParameter?)?
    /// 默认confirm按钮文本句柄，alert多按钮生效。未设置时为确定
    open var defaultConfirmButton: (@MainActor @Sendable () -> AttributedStringParameter?)?

    /// 错误标题格式化句柄，error生效，默认nil
    open var errorTitleFormatter: (@MainActor @Sendable (Error?) -> AttributedStringParameter?)?
    /// 错误消息格式化句柄，error生效，默认nil
    open var errorMessageFormatter: (@MainActor @Sendable (Error?) -> AttributedStringParameter?)?
    /// 错误样式格式化句柄，error生效，默认nil
    open var errorStyleFormatter: (@MainActor @Sendable (Error?) -> AlertStyle)?
    /// 错误按钮格式化句柄，error生效，默认nil
    open var errorButtonFormatter: (@MainActor @Sendable (Error?) -> AttributedStringParameter?)?

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
        let alertController = UIAlertController.fw.alertController(title: title, message: message, preferredStyle: .alert, appearance: customAppearance)
        alertController.fw.alertStyle = style

        // 添加输入框
        for promptIndex in 0..<promptCount {
            alertController.addTextField { textField in
                promptBlock?(textField, promptIndex)
            }
        }

        // 添加动作按钮
        for actionIndex in 0..<(actions?.count ?? 0) {
            let alertAction = UIAlertAction.fw.action(object: actions?[actionIndex], style: .default, appearance: customAppearance) { _ in
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
            let cancelAction = UIAlertAction.fw.action(object: cancel, style: .cancel, appearance: customAppearance) { _ in
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
        let alertController = UIAlertController.fw.alertController(title: title, message: message, preferredStyle: .actionSheet, appearance: customAppearance)

        // 添加动作按钮
        for actionIndex in 0..<(actions?.count ?? 0) {
            let alertAction = UIAlertAction.fw.action(object: actions?[actionIndex], style: .default, appearance: customAppearance) { _ in
                actionBlock?(actionIndex)
            }
            alertController.addAction(alertAction)
        }

        // 添加取消按钮
        if cancel != nil {
            let cancelAction = UIAlertAction.fw.action(object: cancel, style: .cancel, appearance: customAppearance) { _ in
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

    open func hideAlert(
        animated: Bool,
        completion: (@MainActor @Sendable () -> Void)? = nil,
        in viewController: UIViewController
    ) {
        let alertController = showingAlertController(viewController)
        if let alertController {
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
        var alertClasses: [AnyClass] = [UIAlertController.self]
        if let alertClass = NSClassFromString("ObjCAlertController") {
            alertClasses.append(alertClass)
        }
        if let customAlertClasses, customAlertClasses.count > 0 {
            alertClasses.append(contentsOf: customAlertClasses)
        }

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
