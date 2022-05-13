//
//  AppDelegate.swift
//  Example
//
//  Created by wuyong on 2021/3/19.
//  Copyright © 2021 site.wuyong. All rights reserved.
//

import UIKit
import FWFramework

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        Mediator.setupAllModules()
        Router.registerClass(AppRouter.self)
        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white
        window?.rootViewController = setupController()
        window?.makeKeyAndVisible()
        return true
    }
    
}

// MARK: - Private
private extension AppDelegate {
    
    func setupController() -> UIViewController {
        let homeController = Router.object(forURL: AppRouter.homeUrl) as! UIViewController
        homeController.hidesBottomBarWhenPushed = false
        let homeNav = navigationController(homeController)
        homeNav.tabBarItem.title = APP.localized("home.title")
        
        let testController = Router.object(forURL: AppRouter.testUrl) as! UIViewController
        testController.hidesBottomBarWhenPushed = false
        let testNav = navigationController(testController)
        testNav.tabBarItem.title = APP.localized("test.title")
        
        let settingsController = Router.object(forURL: AppRouter.settingsUrl) as! UIViewController
        settingsController.hidesBottomBarWhenPushed = false
        let settingsNav = navigationController(settingsController)
        settingsNav.tabBarItem.title = APP.localized("settings.title")
        
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [homeNav, testNav, settingsNav]
        return tabBarController
    }
    
    func navigationController(_ viewController: UIViewController) -> UINavigationController {
        let navController = UINavigationController(rootViewController: viewController)
        navController.fw.enablePopProxy()
        navController.navigationBar.fw.isTranslucent = false
        navController.navigationBar.fw.shadowColor = nil
        navController.navigationBar.fw.foregroundColor = UIColor.fw.themeLight(.black, dark: .white)
        navController.navigationBar.fw.backgroundColor = UIColor.fw.themeLight(.fw.color(hex: 0xFAFAFA), dark: .fw.color(hex: 0x121212))
        navController.navigationBar.fw.backImage = UIImage(named: "navBack")
        return navController
    }
    
}
