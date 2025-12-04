//
//  AppTheme.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/5/10.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework
import UIKit

// MARK: - Wrapper
public typealias APP = WrapperGlobal

extension WrapperCompatible {
    public static var app: Wrapper<Self>.Type { get { wrapperExtension } set {} }
    public var app: Wrapper<Self> { get { wrapperExtension } set {} }
}

// MARK: - AppTheme
extension PaletteStyle {
    public static let custom: PaletteStyle = .init(5)
}

extension NavigationBarStyle {
    public static let transparent: NavigationBarStyle = .init(1)
}

extension ViewStyle where Base: UIView {
    public static var `default`: Self { .init("default") }
}

class AppTheme: NSObject {
    @MainActor public static func largeButton() -> UIButton {
        let button = UIButton()
        button.setTitleColor(UIColor.app.whiteColor, for: .normal)
        button.titleLabel?.font = .app.boldFont(ofSize: 17)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true

        // 高亮时内容不透明
        // button.app.setBackgroundColor(UIColor.app.primary, for: .normal)
        // button.app.setBackgroundColor(UIColor.app.primary, for: .disabled)
        // button.app.setBackgroundColor(UIColor.app.primary.app.addColor(UIColor.black.withAlphaComponent(0.1)), for: .highlighted)
        // button.app.disabledAlpha = UIButton.app.disabledAlpha

        // 高亮时内容也透明
        button.backgroundColor = UIColor.app.primary
        button.app.disabledAlpha = UIButton.app.disabledAlpha
        button.app.highlightedAlpha = UIButton.app.highlightedAlpha

        button.layoutChain.width(APP.screenWidth - 30).height(50)
        return button
    }
}

extension AppTheme {
    @MainActor static func setupTheme() {
        setupAppearance()
        setupPlugin()
        setupStyle()
    }

    @MainActor private static func setupAppearance() {
        PaletteTheme.customLightTheme = { style in
            if style == .custom {
                return PaletteTheme.lightTheme.merging([
                    "primary": UIColor.app.color(hex: 0xfa3534),
                    "primaryDark": UIColor.app.color(hex: 0xdd6161),
                    "primaryDisabled": UIColor.app.color(hex: 0xfab6b6),
                    "primaryLight": UIColor.app.color(hex: 0xfef0f0),
                ], uniquingKeysWith: { $1 })
            }
            return nil
        }
        
        let defaultAppearance = NavigationBarAppearance()
        defaultAppearance.foregroundColor = UIColor.app.mainColor
        defaultAppearance.backgroundColor = UIColor.app.bgWhite.app.color(alpha: 0.5)
        defaultAppearance.isTranslucent = true
        defaultAppearance.leftBackImage = Icon.backImage
        let transparentAppearance = NavigationBarAppearance()
        transparentAppearance.foregroundColor = UIColor.app.mainColor
        transparentAppearance.backgroundTransparent = true
        transparentAppearance.leftBackImage = Icon.backImage
        NavigationBarAppearance.setAppearance(defaultAppearance, for: .default)
        NavigationBarAppearance.setAppearance(transparentAppearance, for: .transparent)

        UITableView.app.resetTableStyle()
        UINavigationController.app.enablePopProxy()
        ViewControllerManager.shared.hookInit = { viewController in
            viewController.extendedLayoutIncludesOpaqueBars = true
            viewController.hidesBottomBarWhenPushed = true
            viewController.app.navigationBarHidden = false
            viewController.app.navigationBarStyle = .default
        }
        ViewControllerManager.shared.hookViewDidLoad = { viewController in
            viewController.view.backgroundColor = UIColor.app.bgColor
            // viewController.app.backBarItem = Icon.backImage
            // if (viewController.navigationController?.children.count ?? 0) > 1 &&
            //     viewController.navigationItem.leftBarButtonItem == nil {
            //     viewController.app.leftBarItem = Icon.backImage
            // }
        }
        ViewControllerManager.shared.hookTableViewController = { viewController in
            viewController.tableView.backgroundColor = UIColor.app.bgColor
        }
    }

    @MainActor private static func setupPlugin() {
        ToastPluginImpl.shared.defaultLoadingText = {
            NSAttributedString(string: "加载中...")
        }
        ToastPluginImpl.shared.defaultProgressText = {
            NSAttributedString(string: "上传中...")
        }
        ToastPluginImpl.shared.defaultMessageText = { style in
            switch style {
            case .success:
                return NSAttributedString(string: "操作成功")
            case .failure:
                return NSAttributedString(string: "操作失败")
            default:
                return nil
            }
        }
        EmptyPluginImpl.shared.defaultText = {
            "暂无数据"
        }
        EmptyPluginImpl.shared.defaultImage = {
            UIImage.app.appIconImage()
        }
        EmptyPluginImpl.shared.defaultAction = {
            "重新加载"
        }
    }

    @MainActor private static func setupStyle() {
        UITextField.app.defineStyle(.default) { textField in
            textField.font = UIFont.app.font(ofSize: 15)
            textField.textColor = UIColor.app.mainColor
            textField.tintColor = UIColor.app.mainColor
            textField.backgroundColor = UIColor.app.bgWhite
            textField.clearButtonMode = .whileEditing
            textField.returnKeyType = .done
            textField.app.setBorderColor(UIColor.app.borderColor, width: 0.5, cornerRadius: 5)
            textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
            textField.leftViewMode = .always
            textField.app.keyboardManager = true
            textField.app.touchResign = true
            textField.app.keyboardResign = true
            textField.app.returnResign = true
        }
    }
}
