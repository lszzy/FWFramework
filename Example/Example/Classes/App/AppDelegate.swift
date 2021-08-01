//
//  AppDelegate.swift
//  Example
//
//  Created by wuyong on 2021/3/19.
//  Copyright © 2021 site.wuyong. All rights reserved.
//

import Foundation

@UIApplicationMain
class AppDelegate: FWAppDelegate {
    // MARK: - UISceneSession
    @available(iOS 13.0, *)
    override func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13.0, *)
    override func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
    
    // MARK: - OpenURL
    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        FWRouter.openURL(url.absoluteString)
        return true
    }
    
    override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let webpageURL = userActivity.webpageURL {
            FWRouter.openURL(webpageURL.absoluteString)
            return true
        }
        return false
    }
    
    // MARK: - Protected
    override func setupController() {
        // iOS13以前使用旧的方式
        if #available(iOS 13.0, *) { return }
        
        if window == nil {
            window = UIWindow(frame: UIScreen.main.bounds)
            window?.backgroundColor = Theme.backgroundColor
            window?.makeKeyAndVisible()
        }
        window?.rootViewController = UITabBarController.setupController()
    }
}
