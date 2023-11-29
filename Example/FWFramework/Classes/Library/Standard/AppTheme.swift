//
//  AppTheme.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/5/10.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import FWFramework

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
    
    public static func largeButton() -> UIButton {
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
        
        button.app.setDimension(.width, size: APP.screenWidth - 30)
        button.app.setDimension(.height, size: 50)
        return button
    }
    
}

extension AppTheme {
    
    static func setupTheme() {
        setupAppearance()
        setupPlugin()
    }
    
    private static func setupAppearance() {
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
    
    private static func setupPlugin() {
        ToastPluginImpl.shared.defaultLoadingText = {
            return NSAttributedString(string: "加载中...")
        }
        ToastPluginImpl.shared.defaultProgressText = {
            return NSAttributedString(string: "上传中...")
        }
        ToastPluginImpl.shared.defaultMessageText = { (style) in
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
            return "暂无数据"
        }
        EmptyPluginImpl.shared.defaultImage = {
            return UIImage.app.appIconImage()
        }
        EmptyPluginImpl.shared.defaultAction = {
            return "重新加载"
        }
    }
    
}
