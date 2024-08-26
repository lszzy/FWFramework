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
        tabBar.app.foregroundColor = AppTheme.textColor
        if #available(iOS 15, *) {
            tabBar.app.isTranslucent = true
            tabBar.app.backgroundColor = AppTheme.barColor.app.color(alpha: 0.5)
        } else {
            tabBar.app.backgroundColor = AppTheme.barColor
        }
        tabBar.app.shadowColor = nil
        tabBar.app.setShadowColor(.app.color(hex: 0x040000, alpha: 0.15), offset: CGSize(width: 0, height: 1), radius: 3)
    }

    func setupController() {
        let homeController = Router.object(forURL: AppRouter.homeUrl) as! UIViewController
        homeController.hidesBottomBarWhenPushed = false
        let homeNav = UINavigationController(rootViewController: homeController)
        homeNav.tabBarItem.accessibilityIdentifier = "id.home"
        homeNav.tabBarItem.image = APP.iconImage("zmdi-var-home", 26)
        homeNav.tabBarItem.title = APP.localized("homeTitle")
        homeNav.tabBarItem.app.showBadgeView(BadgeView(badgeStyle: .small), badgeValue: "1")

        let testController = Router.object(forURL: AppRouter.testUrl) as! UIViewController
        testController.hidesBottomBarWhenPushed = false
        let testNav = UINavigationController(rootViewController: testController)
        testNav.tabBarItem.accessibilityIdentifier = "id.test"
        testNav.tabBarItem.image = Icon.iconImage("zmdi-var-toys", size: 26)
        testNav.tabBarItem.title = APP.localized("testTitle")

        let settingsControlelr = Router.object(forURL: AppRouter.settingsUrl) as! UIViewController
        settingsControlelr.hidesBottomBarWhenPushed = false
        let settingsNav = UINavigationController(rootViewController: settingsControlelr)
        let tabBarItem = TabBarItem()
        tabBarItem.contentView.highlightTextColor = AppTheme.textColor
        tabBarItem.contentView.highlightIconColor = AppTheme.textColor
        settingsNav.tabBarItem = tabBarItem
        settingsNav.tabBarItem.accessibilityIdentifier = "id.settings"
        settingsNav.tabBarItem.badgeValue = ""
        settingsNav.tabBarItem.image = APP.icon("zmdi-var-settings", 26)?.image
        settingsNav.tabBarItem.title = APP.localized("settingTitle")
        viewControllers = [homeNav, testNav, settingsNav]

        app.safeObserveNotification(.LanguageChanged) { _ in
            homeNav.tabBarItem.title = APP.localized("homeTitle")
            testNav.tabBarItem.title = APP.localized("testTitle")
            settingsNav.tabBarItem.title = APP.localized("settingTitle")
        }
    }
}

// MARK: - UITabBarControllerDelegate
extension TabController: UITabBarControllerDelegate {
    public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let animation: CAAnimation
        let identifier = viewController.tabBarItem.accessibilityIdentifier
        if identifier == "id.test" {
            let basicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
            basicAnimation.fromValue = NSNumber(value: 0)
            basicAnimation.toValue = NSNumber(value: CGFloat.pi)
            basicAnimation.duration = 0.3
            animation = basicAnimation
        } else {
            let keyframeAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
            keyframeAnimation.values = [1.0, 1.4, 0.9, 1.15, 0.95, 1.02, 1.0]
            keyframeAnimation.duration = 0.3 * 2
            keyframeAnimation.calculationMode = .cubic
            animation = keyframeAnimation
        }

        var animationView = viewController.tabBarItem.app.imageView
        if let tabBarItem = viewController.tabBarItem as? TabBarItem {
            animationView = tabBarItem.contentView.imageView
        }
        animationView?.layer.add(animation, forKey: nil)
    }
}
