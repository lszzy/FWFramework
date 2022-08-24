//
//  AppTheme.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/5/10.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

public typealias APP = FW

extension WrapperCompatible {
    
    public static var app: Wrapper<Self>.Type { get { fw } set {} }
    public var app: Wrapper<Self> { get { fw } set {} }
    
}

extension NavigationBarStyle {
    
    public static let white: NavigationBarStyle = .init(1)
    public static let transparent: NavigationBarStyle = .init(2)
    
}

@objcMembers class AppTheme: NSObject {
    
    public static var backgroundColor: UIColor {
        UIColor.fw.themeLight(.white, dark: .black)
    }
    public static var textColor: UIColor {
        UIColor.fw.themeLight(.black, dark: .white)
    }
    public static var detailColor: UIColor {
        UIColor.fw.themeLight(UIColor.black.withAlphaComponent(0.5), dark: UIColor.white.withAlphaComponent(0.5))
    }
    public static var barColor: UIColor {
        UIColor.fw.themeLight(.fw.color(hex: 0xFAFAFA), dark: .fw.color(hex: 0x121212))
    }
    public static var tableColor: UIColor {
        UIColor.fw.themeLight(.fw.color(hex: 0xF2F2F2), dark: .fw.color(hex: 0x000000))
    }
    public static var cellColor: UIColor {
        UIColor.fw.themeLight(.fw.color(hex: 0xFFFFFF), dark: .fw.color(hex: 0x1C1C1C))
    }
    public static var borderColor: UIColor {
        UIColor.fw.themeLight(.fw.color(hex: 0xDDDDDD), dark: .fw.color(hex: 0x303030))
    }
    public static var buttonColor: UIColor {
        UIColor.fw.themeLight(.fw.color(hex: 0x017AFF), dark: .fw.color(hex: 0x0A84FF))
    }
    
    public static func largeButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitleColor(.white, for: .normal)
        button.setBackgroundImage(UIImage.fw.image(color: AppTheme.buttonColor), for: .normal)
        button.titleLabel?.font = .fw.boldFont(ofSize: 17)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.fw.setDimension(.width, size: FW.screenWidth - 30)
        button.fw.setDimension(.height, size: 50)
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
        defaultAppearance.backgroundColor = AppTheme.barColor.fw.color(alpha: 0.5)
        defaultAppearance.isTranslucent = true
        defaultAppearance.leftBackImage = Icon.backImage
        let whiteAppearance = NavigationBarAppearance()
        whiteAppearance.foregroundColor = .black
        whiteAppearance.backgroundColor = .white.fw.color(alpha: 0.5)
        whiteAppearance.isTranslucent = true
        whiteAppearance.leftBackImage = Icon.backImage
        let transparentAppearance = NavigationBarAppearance()
        transparentAppearance.foregroundColor = AppTheme.textColor
        transparentAppearance.backgroundTransparent = true
        transparentAppearance.leftBackImage = Icon.backImage
        NavigationBarAppearance.setAppearance(defaultAppearance, forStyle: .default)
        NavigationBarAppearance.setAppearance(whiteAppearance, forStyle: .white)
        NavigationBarAppearance.setAppearance(transparentAppearance, forStyle: .transparent)
        
        UITableView.fw.resetTableStyle()
        UINavigationController.fw.enablePopProxy()
        ViewControllerManager.sharedInstance.hookInit = { viewController in
            viewController.extendedLayoutIncludesOpaqueBars = true
            viewController.hidesBottomBarWhenPushed = true
            viewController.fw.navigationBarHidden = false
            viewController.fw.navigationBarStyle = .default
        }
        ViewControllerManager.sharedInstance.hookViewDidLoad = { viewController in
            viewController.view.backgroundColor = AppTheme.tableColor
            // viewController.fw.backBarItem = Icon.backImage
            // if (viewController.navigationController?.children.count ?? 0) > 1 {
            //     viewController.fw.leftBarItem = Icon.backImage
            // }
        }
        ViewControllerManager.sharedInstance.hookTableViewController = { viewController in
            viewController.tableView.backgroundColor = AppTheme.tableColor
        }
    }
    
    private static func setupPlugin() {
        ToastPluginImpl.sharedInstance.defaultLoadingText = {
            return NSAttributedString(string: "加载中...")
        }
        ToastPluginImpl.sharedInstance.defaultProgressText = {
            return NSAttributedString(string: "上传中...")
        }
        ToastPluginImpl.sharedInstance.defaultMessageText = { (style) in
            switch style {
            case .success:
                return NSAttributedString(string: "操作成功")
            case .failure:
                return NSAttributedString(string: "操作失败")
            default:
                return nil
            }
        }
        ToastPluginImpl.sharedInstance.customBlock = { toastView in
            if toastView.type == .indicator {
                if (toastView.attributedTitle?.length ?? 0) < 1 {
                    toastView.contentBackgroundColor = .clear
                    toastView.indicatorColor = AppTheme.textColor
                }
            }
        }
        EmptyPluginImpl.sharedInstance.customBlock = { (emptyView) in
            emptyView.loadingViewColor = AppTheme.textColor
        }
        EmptyPluginImpl.sharedInstance.defaultText = {
            return "暂无数据"
        }
        EmptyPluginImpl.sharedInstance.defaultImage = {
            return UIImage.fw.appIconImage()
        }
        EmptyPluginImpl.sharedInstance.defaultAction = {
            return "重新加载"
        }
    }
    
}
