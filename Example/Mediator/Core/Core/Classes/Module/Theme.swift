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
        viewController.fwSetBackBarImage(CoreBundle.imageNamed("back"))
    }
}

@objc extension FWAutoloader {
    func loadTheme() {
        // 控制器默认设置
        let intercepter = FWViewControllerIntercepter()
        intercepter.initIntercepter = #selector(FWViewControllerManager.viewControllerInit(_:))
        intercepter.loadViewIntercepter = #selector(FWViewControllerManager.viewControllerLoadView(_:))
        intercepter.viewDidLoadIntercepter = #selector(FWViewControllerManager.viewControllerViewDidLoad(_:))
        FWViewControllerManager.sharedInstance.register(FWViewController.self, with: intercepter)
        
        // 导航栏样式设置
        let defaultAppearance = FWNavigationBarAppearance()
        defaultAppearance.foregroundColor = Theme.textColor
        defaultAppearance.appearanceBlock = { (navigationBar) in
            navigationBar.fwThemeBackgroundColor = Theme.barColor
        }
        let whiteAppearance = FWNavigationBarAppearance()
        whiteAppearance.foregroundColor = .white
        whiteAppearance.appearanceBlock = { (navigationBar) in
            navigationBar.fwThemeBackgroundColor = .white
        }
        let clearAppearance = FWNavigationBarAppearance()
        clearAppearance.foregroundColor = Theme.textColor
        clearAppearance.appearanceBlock = { (navigationBar) in
            navigationBar.fwThemeBackgroundColor = .clear
        }
        FWNavigationBarAppearance.setAppearance(defaultAppearance, forStyle: .default)
        FWNavigationBarAppearance.setAppearance(whiteAppearance, forStyle: .init(2))
        FWNavigationBarAppearance.setAppearance(clearAppearance, forStyle: .clear)
    }
}
