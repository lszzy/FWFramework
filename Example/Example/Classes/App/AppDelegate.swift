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
        FWRouter.registerClass(AppRouter.self)
        let viewController = FWRouter.object(forURL: AppRouter.homeUrl) as! UIViewController
        
        let navController = UINavigationController(rootViewController: viewController)
        navController.fw.enablePopProxy()
        navController.navigationBar.fw.isTranslucent = false
        navController.navigationBar.fw.shadowColor = nil
        navController.navigationBar.fw.foregroundColor = UIColor.fw.themeLight(.black, dark: .white)
        navController.navigationBar.fw.backgroundColor = UIColor.fw.themeLight(.fw.color(withHex: 0xFAFAFA), dark: .fw.color(withHex: 0x121212))
        navController.navigationBar.fw.backImage = UIImage(named: "navBack")
        return navController
    }
    
}
