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
extension NavigationBarStyle {
    public static let white: NavigationBarStyle = .init(1)
    public static let transparent: NavigationBarStyle = .init(2)
}

extension ViewStyle where Base: UIView {
    public static var `default`: Self { .init("default") }
}

class AppTheme: NSObject {
    public static var backgroundColor: UIColor {
        UIColor.app.themeLight(.white, dark: .black)
    }

    public static var textColor: UIColor {
        UIColor.app.themeLight(.black, dark: .white)
    }

    public static var detailColor: UIColor {
        UIColor.app.themeLight(UIColor.black.withAlphaComponent(0.5), dark: UIColor.white.withAlphaComponent(0.5))
    }

    public static var barColor: UIColor {
        UIColor.app.themeLight(.app.color(hex: 0xFAFAFA), dark: .app.color(hex: 0x121212))
    }

    public static var tableColor: UIColor {
        UIColor.app.themeLight(.app.color(hex: 0xF2F2F2), dark: .app.color(hex: 0x000000))
    }

    public static var cellColor: UIColor {
        UIColor.app.themeLight(.app.color(hex: 0xFFFFFF), dark: .app.color(hex: 0x1C1C1C))
    }

    public static var borderColor: UIColor {
        UIColor.app.themeLight(.app.color(hex: 0xDDDDDD), dark: .app.color(hex: 0x303030))
    }

    public static var buttonColor: UIColor {
        UIColor.app.themeLight(.app.color(hex: 0x017AFF), dark: .app.color(hex: 0x0A84FF))
    }

    @MainActor public static func largeButton() -> UIButton {
        let button = UIButton()
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .app.boldFont(ofSize: 17)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true

        // 高亮时内容不透明
        // button.app.setBackgroundColor(AppTheme.buttonColor, for: .normal)
        // button.app.setBackgroundColor(AppTheme.buttonColor, for: .disabled)
        // button.app.setBackgroundColor(AppTheme.buttonColor.app.addColor(UIColor.black.withAlphaComponent(0.1)), for: .highlighted)
        // button.app.disabledAlpha = UIButton.app.disabledAlpha

        // 高亮时内容也透明
        button.backgroundColor = AppTheme.buttonColor
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
        let defaultAppearance = NavigationBarAppearance()
        defaultAppearance.foregroundColor = AppTheme.textColor
        defaultAppearance.backgroundColor = AppTheme.barColor.app.color(alpha: 0.5)
        defaultAppearance.isTranslucent = true
        defaultAppearance.leftBackImage = Icon.backImage
        let whiteAppearance = NavigationBarAppearance()
        whiteAppearance.foregroundColor = .black
        whiteAppearance.backgroundColor = .white.app.color(alpha: 0.5)
        whiteAppearance.isTranslucent = true
        whiteAppearance.leftBackImage = Icon.backImage
        let transparentAppearance = NavigationBarAppearance()
        transparentAppearance.foregroundColor = AppTheme.textColor
        transparentAppearance.backgroundTransparent = true
        transparentAppearance.leftBackImage = Icon.backImage
        NavigationBarAppearance.setAppearance(defaultAppearance, for: .default)
        NavigationBarAppearance.setAppearance(whiteAppearance, for: .white)
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
            viewController.view.backgroundColor = AppTheme.tableColor
            // viewController.app.backBarItem = Icon.backImage
            // if (viewController.navigationController?.children.count ?? 0) > 1 &&
            //     viewController.navigationItem.leftBarButtonItem == nil {
            //     viewController.app.leftBarItem = Icon.backImage
            // }
        }
        ViewControllerManager.shared.hookTableViewController = { viewController in
            viewController.tableView.backgroundColor = AppTheme.tableColor
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
            textField.textColor = AppTheme.textColor
            textField.tintColor = AppTheme.textColor
            textField.backgroundColor = AppTheme.backgroundColor
            textField.clearButtonMode = .whileEditing
            textField.returnKeyType = .done
            textField.app.setBorderColor(AppTheme.borderColor, width: 0.5, cornerRadius: 5)
            textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
            textField.leftViewMode = .always
            textField.app.keyboardManager = true
            textField.app.touchResign = true
            textField.app.keyboardResign = true
            textField.app.returnResign = true
        }
    }
}
