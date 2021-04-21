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

@objc extension FWLoader {
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
        defaultAppearance.backgroundColor = Theme.barColor
        let whiteAppearance = FWNavigationBarAppearance()
        whiteAppearance.foregroundColor = Theme.textColor.fwThemeColor(.light)
        whiteAppearance.backgroundColor = .white
        let transparentAppearance = FWNavigationBarAppearance()
        transparentAppearance.foregroundColor = Theme.textColor
        transparentAppearance.isTransparent = true
        FWNavigationBarAppearance.setAppearance(defaultAppearance, forStyle: .default)
        FWNavigationBarAppearance.setAppearance(whiteAppearance, forStyle: .init(2))
        FWNavigationBarAppearance.setAppearance(transparentAppearance, forStyle: .transparent)
        
        // 吐司等插件设置
        UIView.appearance().fwDefaultLoadingText = "加载中..."
        UIView.appearance().fwDefaultEmptyText = "暂无数据"
        UIView.appearance().fwDefaultEmptyImage = UIImage.fwImageWithAppIcon()
        UIView.appearance().fwDefaultEmptyAction = "重新加载"
    }
}
