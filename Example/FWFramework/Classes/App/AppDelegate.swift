//
//  AppDelegate.swift
//  FWFramework
//
//  Created by wuyong on 05/07/2022.
//  Copyright (c) 2022 wuyong. All rights reserved.
//

import FWFramework

@UIApplicationMain
class AppDelegate: AppResponder {
    
    override func setupApplication(_ application: UIApplication, options: [UIApplication.LaunchOptionsKey : Any]? = nil) {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white
        window?.makeKeyAndVisible()
    }
    
    override func setupController() {
        let homeController = HomeController()
        homeController.hidesBottomBarWhenPushed = false
        let homeNav = UINavigationController(rootViewController: homeController)
        homeNav.tabBarItem.title = NSLocalizedString("home.title", comment: "首页")
        
        let testController = TestController()
        testController.hidesBottomBarWhenPushed = false
        let testNav = UINavigationController(rootViewController: testController)
        testNav.tabBarItem.title = NSLocalizedString("test.title", comment: "测试")
        
        let settingsController = SettingsController()
        settingsController.hidesBottomBarWhenPushed = false
        let settingsNav = UINavigationController(rootViewController: settingsController)
        settingsNav.tabBarItem.title = NSLocalizedString("settings.title", comment: "设置")
        
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [homeNav, testNav, settingsNav]
        window?.rootViewController = tabBarController
    }

}
