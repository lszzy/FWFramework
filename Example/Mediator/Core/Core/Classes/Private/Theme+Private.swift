//
//  CoreModule.swift
//  Core
//
//  Created by wuyong on 2021/1/1.
//

import FWFramework

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
