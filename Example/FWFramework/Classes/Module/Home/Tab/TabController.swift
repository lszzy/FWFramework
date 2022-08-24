//
//  TabController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/24.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TabController: TabBarController {
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSubviews()
        setupController()
    }
    
}

// MARK: - Setup
extension TabController {
    
    func setupSubviews() {
        delegate = self
        tabBar.fw.isTranslucent = true
        tabBar.fw.shadowColor = nil
        tabBar.fw.foregroundColor = AppTheme.textColor
        tabBar.fw.backgroundColor = AppTheme.barColor.fw.color(alpha: 0.5)
    }
    
    func setupController() {
        let homeController = Router.object(forURL: AppRouter.homeUrl) as! UIViewController
        homeController.hidesBottomBarWhenPushed = false
        let homeNav = UINavigationController(rootViewController: homeController)
        homeNav.tabBarItem.image = FW.iconImage("zmdi-var-home", 26)
        homeNav.tabBarItem.title = FW.localized("homeTitle")
        homeNav.tabBarItem.fw.showBadgeView(BadgeView(badgeStyle: .small), badgeValue: "1")
        
        let testController = Router.object(forURL: AppRouter.testUrl) as! UIViewController
        testController.hidesBottomBarWhenPushed = false
        let testNav = UINavigationController(rootViewController: testController)
        testNav.tabBarItem.image = Icon.iconImage("zmdi-var-bug", size: 26)
        testNav.tabBarItem.title = FW.localized("testTitle")
        
        let settingsControlelr = Router.object(forURL: AppRouter.settingsUrl) as! UIViewController
        settingsControlelr.hidesBottomBarWhenPushed = false
        let settingsNav = UINavigationController(rootViewController: settingsControlelr)
        let tabBarItem = TabBarItem()
        tabBarItem.contentView.highlightTextColor = AppTheme.textColor
        tabBarItem.contentView.highlightIconColor = AppTheme.textColor
        settingsNav.tabBarItem = tabBarItem
        settingsNav.tabBarItem.badgeValue = ""
        settingsNav.tabBarItem.image = FW.icon("zmdi-var-settings", 26)?.image
        settingsNav.tabBarItem.title = FW.localized("settingTitle")
        viewControllers = [homeNav, testNav, settingsNav]
        
        fw.observeNotification(NSNotification.Name.LanguageChanged) { (notification) in
            homeNav.tabBarItem.title = FW.localized("homeTitle")
            testNav.tabBarItem.title = FW.localized("testTitle")
            settingsNav.tabBarItem.title = FW.localized("settingTitle")
        }
    }
    
}

// MARK: - Public
extension TabController {
    
    static func refreshController() {
        if let appDelegate = UIApplication.shared.delegate as? AppResponder {
            appDelegate.setupController()
        }
    }
    
}

// MARK: - UITabBarControllerDelegate
extension TabController: UITabBarControllerDelegate {
    
    public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.values = [1.0, 1.4, 0.9, 1.15, 0.95, 1.02, 1.0]
        animation.duration = 0.3 * 2
        animation.calculationMode = .cubic
        
        var animationView = viewController.tabBarItem.fw.imageView
        if let tabBarItem = viewController.tabBarItem as? TabBarItem {
            animationView = tabBarItem.contentView.imageView
        }
        animationView?.layer.add(animation, forKey: nil)
    }
    
}
