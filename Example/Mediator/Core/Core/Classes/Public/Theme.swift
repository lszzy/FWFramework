//
//  CoreModule.swift
//  Core
//
//  Created by wuyong on 2021/1/1.
//

import FWFramework

@objcMembers public class Theme: NSObject {
    public static var backgroundColor = UIColor.fwThemeLight(.white, dark: .black)
    public static var textColor = UIColor.fwThemeLight(.black, dark: .white)
    public static var detailColor = UIColor.fwThemeLight(UIColor.black.withAlphaComponent(0.5), dark: UIColor.white.withAlphaComponent(0.5))
    public static var barColor = UIColor.fwThemeLight(.fwColor(withHex: 0xFAFAFA), dark: .fwColor(withHex: 0x121212))
    public static var tableColor = UIColor.fwThemeLight(.fwColor(withHex: 0xF2F2F2), dark: .fwColor(withHex: 0x000000))
    public static var cellColor = UIColor.fwThemeLight(.fwColor(withHex: 0xFFFFFF), dark: .fwColor(withHex: 0x1C1C1C))
    public static var borderColor = UIColor.fwThemeLight(.fwColor(withHex: 0xDDDDDD), dark: .fwColor(withHex: 0x303030))
    
    public static func largeButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitleColor(.white, for: .normal)
        button.setBackgroundImage(UIImage.fwImage(with: UIColor.fwThemeLight(.fwColor(withHex: 0x017AFF), dark: .fwColor(withHex: 0x0A84FF))), for: .normal)
        button.titleLabel?.font = .fwBoldFont(ofSize: 17)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.fwSetDimension(.width, toSize: FWScreenWidth - 30)
        button.fwSetDimension(.height, toSize: 50)
        return button
    }
}

extension Theme {
    static func setupTheme() {
        setupAppearance()
        setupPlugin()
    }
    
    private static func setupAppearance() {
        // 控制器样式设置
        let intercepter = FWViewControllerIntercepter()
        intercepter.initIntercepter = #selector(FWViewControllerManager.viewControllerInit(_:))
        intercepter.loadViewIntercepter = #selector(FWViewControllerManager.viewControllerLoadView(_:))
        intercepter.viewDidLoadIntercepter = #selector(FWViewControllerManager.viewControllerViewDidLoad(_:))
        FWViewControllerManager.sharedInstance.register(FWViewController.self, with: intercepter)
        
        // 导航栏样式设置
        let defaultAppearance = FWNavigationBarAppearance()
        defaultAppearance.foregroundColor = Theme.textColor
        defaultAppearance.backgroundColor = Theme.barColor
        let whiteAppearance = FWNavigationBarAppearance()
        whiteAppearance.foregroundColor = Theme.textColor.fwColor(forStyle: .light)
        whiteAppearance.backgroundColor = .white
        let transparentAppearance = FWNavigationBarAppearance()
        transparentAppearance.foregroundColor = Theme.textColor
        transparentAppearance.isTransparent = true
        FWNavigationBarAppearance.setAppearance(defaultAppearance, forStyle: .default)
        FWNavigationBarAppearance.setAppearance(whiteAppearance, forStyle: .init(2))
        FWNavigationBarAppearance.setAppearance(transparentAppearance, forStyle: .transparent)
    }
    
    private static func setupPlugin() {
        // 吐司等插件设置
        FWToastPluginImpl.sharedInstance.defaultLoadingText = {
            return NSAttributedString(string: "加载中...")
        }
        FWToastPluginImpl.sharedInstance.defaultProgressText = {
            return NSAttributedString(string: "上传中...")
        }
        FWToastPluginImpl.sharedInstance.defaultMessageText = { (style) in
            switch style {
            case .success:
                return NSAttributedString(string: "操作成功")
            case .failure:
                return NSAttributedString(string: "操作失败")
            default:
                return nil
            }
        }
        FWEmptyPluginImpl.sharedInstance.customBlock = { (emptyView) in
            // 设置图片中心为总高度的1/3
            emptyView.verticalOffsetBlock = { (totalHeight, contentHeight, imageHeight) in
                let centerOriginY = (totalHeight - contentHeight) / 2
                let targetOriginY = totalHeight / 3 - imageHeight / 2
                return targetOriginY - centerOriginY
            }
        }
        FWEmptyPluginImpl.sharedInstance.defaultText = {
            return "暂无数据"
        }
        FWEmptyPluginImpl.sharedInstance.defaultImage = {
            return UIImage.fwImageWithAppIcon()
        }
        FWEmptyPluginImpl.sharedInstance.defaultAction = {
            return "重新加载"
        }
    }
}

@objc extension FWViewControllerManager {
    func viewControllerInit(_ viewController: UIViewController) {
        viewController.edgesForExtendedLayout = []
        viewController.extendedLayoutIncludesOpaqueBars = true
        viewController.automaticallyAdjustsScrollViewInsets = false
        viewController.hidesBottomBarWhenPushed = true
        viewController.fwNavigationBarStyle = .default
    }
    
    func viewControllerLoadView(_ viewController: UIViewController) {
        viewController.view.backgroundColor = Theme.tableColor
    }
    
    func viewControllerViewDidLoad(_ viewController: UIViewController) {
        viewController.fwBackBarItem = CoreBundle.imageNamed("back")
    }
}
