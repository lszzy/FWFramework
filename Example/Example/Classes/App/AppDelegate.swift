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
        FWMediator.setupAllModules()
        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white
        window?.rootViewController = rootController()
        window?.makeKeyAndVisible()
        return true
    }
}

// MARK: - Private
private extension AppDelegate {
    
    func rootController() -> UIViewController {
        let viewController = FWRouter.object(forURL: AppRouter.homeUrl) as! UIViewController
        
        let navController = UINavigationController(rootViewController: viewController)
        navController.navigationBar.fwIsTranslucent = false
        navController.navigationBar.fwShadowColor = nil
        navController.navigationBar.fwForegroundColor = UIColor.fwThemeLight(.black, dark: .white)
        navController.navigationBar.fwBackgroundColor = UIColor.fwThemeLight(.fwColor(withHex: 0xFAFAFA), dark: .fwColor(withHex: 0x121212))
        navController.navigationBar.fwBackImage = UIImage(named: "navBack")
        return navController
    }
    
}
