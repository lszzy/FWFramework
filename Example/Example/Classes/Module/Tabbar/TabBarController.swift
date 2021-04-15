//
//  TabBarController.swift
//  Example
//
//  Created by wuyong on 2021/3/19.
//  Copyright © 2021 site.wuyong. All rights reserved.
//

import Foundation

extension UITabBarController: UITabBarControllerDelegate {
    // MARK: - Static
    static func setupController() -> UIViewController {
        let tabBarController = AppConfig.isRootCustom ? FWTabBarController() : UITabBarController()
        tabBarController.setupController()
        if !AppConfig.isRootNavigation { return tabBarController }
        
        let navigationController = UINavigationController(rootViewController: tabBarController)
        navigationController.isNavigationBarHidden = true
        return navigationController
    }
    
    static func refreshController() {
        if #available(iOS 13.0, *) {
            if let sceneDelegate = UIWindow.fwMainScene?.delegate as? FWSceneDelegate {
                sceneDelegate.setupController()
            }
        } else {
            if let appDelegate = UIApplication.shared.delegate as? FWAppDelegate {
                appDelegate.setupController()
            }
        }
    }
    
    // MARK: - Private
    private func setupController() {
        delegate = self
        tabBar.fwTextColor = Theme.textColor
        tabBar.fwThemeBackgroundColor = Theme.barColor
        
        let homeController = HomeViewController()
        homeController.hidesBottomBarWhenPushed = false
        let homeNav = UINavigationController(rootViewController: homeController)
        homeNav.tabBarItem.image = UIImage(named: "tabbarHome")
        homeNav.tabBarItem.title = FWLocalizedString("homeTitle")
        homeNav.tabBarItem.fwShow(FWBadgeView(badgeStyle: .small), badgeValue: "1")
        
        let testController = Mediator.testModule.testViewController()
        testController.hidesBottomBarWhenPushed = false
        let testNav = UINavigationController(rootViewController: testController)
        testNav.tabBarItem.image = UIImage(named: "tabbarTest")
        testNav.tabBarItem.title = FWLocalizedString("testTitle")
        
        let settingsControlelr = SettingsViewController()
        settingsControlelr.hidesBottomBarWhenPushed = false
        let settingsNav = UINavigationController(rootViewController: settingsControlelr)
        if AppConfig.isRootCustom {
            let tabBarItem = FWTabBarItem()
            tabBarItem.contentView.highlightTextColor = Theme.textColor
            tabBarItem.contentView.highlightIconColor = Theme.textColor
            settingsNav.tabBarItem = tabBarItem
            settingsNav.tabBarItem.badgeValue = ""
        } else {
            let badgeView = FWBadgeView(badgeStyle: .dot)
            settingsNav.tabBarItem.fwShow(badgeView, badgeValue: nil)
        }
        settingsNav.tabBarItem.image = UIImage(named: "tabbarSettings")
        settingsNav.tabBarItem.title = FWLocalizedString("settingTitle")
        viewControllers = [homeNav, testNav, settingsNav]
        
        fwObserveNotification(NSNotification.Name.FWLanguageChanged.rawValue) { (notification) in
            homeNav.tabBarItem.title = FWLocalizedString("homeTitle")
            testNav.tabBarItem.title = FWLocalizedString("testTitle")
            settingsNav.tabBarItem.title = FWLocalizedString("settingTitle")
        }
    }
    
    // MARK: - UITabBarControllerDelegate
    public func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if let index = tabBarController.viewControllers?.firstIndex(of: viewController), index == 1 {
            if AppConfig.isRootLogin && !Mediator.userModule.isLogin() {
                Mediator.userModule.login { [weak self] in
                    if self?.viewControllers?.contains(viewController) ?? false {
                        self?.selectedViewController = viewController
                    }
                }
                return false
            }
        }
        
        return true
    }
    
    public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.values = [1.0, 1.4, 0.9, 1.15, 0.95, 1.02, 1.0]
        animation.duration = 0.3 * 2
        animation.calculationMode = .cubic
        
        var animationView = viewController.tabBarItem.fwImageView
        if let tabBarItem = viewController.tabBarItem as? FWTabBarItem {
            animationView = tabBarItem.contentView.imageView
        }
        animationView?.layer.add(animation, forKey: nil)
    }
}
