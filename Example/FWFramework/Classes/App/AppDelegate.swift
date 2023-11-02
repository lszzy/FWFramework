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
    
    var backgroundTask: ((@escaping () -> Void) -> Void)?
    var expirationHandler: (() -> Void)?
    
    // MARK: - Override
    override func setupApplication(_ application: UIApplication, options: [UIApplication.LaunchOptionsKey : Any]? = nil) {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = AppTheme.backgroundColor
        window?.makeKeyAndVisible()
        
        Router.registerClass(AppRouter.self)
        MaterialIcons.setupIcon()
        AppTheme.setupTheme()
        Mediator.loadModule(AppModuleProtocol.self)?.moduleMethod()
        APP.debug("appId: %@", AppConfig.shared.appId)
        APP.debug("apiUrl: %@", AppConfig.shared.network.apiUrl)
        
        if let url = UIApplication.app.appLaunchURL(options) {
            APP.debug("launchURL: %@", url.absoluteString)
        }
    }
    
    override func setupController() {
        window?.rootViewController = TabController()
    }
    
    override func reloadController() {
        window?.app.addTransition(type: .init(rawValue: "oglFlip"), subtype: .fromLeft, timingFunction: .init(name: .easeInEaseOut), duration: 1.0)
        super.reloadController()
    }
    
    // MARK: - UIApplicationDelegate
    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        Router.openURL(url.absoluteString)
        return true
    }
    
    override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let webpageURL = userActivity.webpageURL {
            Router.openURL(webpageURL.absoluteString)
            return true
        }
        return false
    }
    
    override func applicationDidEnterBackground(_ application: UIApplication) {
        if let backgroundTask = backgroundTask {
            UIApplication.app.beginBackgroundTask(backgroundTask, expirationHandler: expirationHandler)
        }
    }

}
