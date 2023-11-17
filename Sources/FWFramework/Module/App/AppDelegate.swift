//
//  AppDelegate.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

/// AppDelegate基类
open class AppResponder: UIResponder, UIApplicationDelegate {
    
    /// 应用主delegate
    public class var shared: Self! {
        return UIApplication.shared.delegate as? Self
    }
    
    /// 应用主window
    open var window: UIWindow?
    
    // MARK: - Override
    /// 初始化应用配置，子类重写
    open func setupApplication(_ application: UIApplication, options: [UIApplication.LaunchOptionsKey : Any]? = nil) {
        /*
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
         */
        
        /*
        NotificationManager.shared.clearNotificationBadges()
        if let remoteNotification = options?[.remoteNotification] {
            NotificationManager.shared.handleRemoteNotification(remoteNotification)
        }
        if let localNotification = options?[.localNotification] {
            NotificationManager.shared.handleLocalNotification(localNotification)
        }
         */
        
        /*
        NotificationManager.shared.registerNotificationHandler()
        NotificationManager.shared.requestAuthorize(nil)
         */
    }
    
    /// 初始化根控制器，子类重写
    open func setupController() {
        /*
        window?.rootViewController = TabBarController()
         */
    }
    
    /// 初始化基础服务，子类重写
    open func setupService(options: [UIApplication.LaunchOptionsKey : Any]? = nil) {
        /*
        预加载启动广告、检查App更新等
         */
    }
    
    /// 重新加载根控制器，子类可重写
    open func reloadController() {
        setupController()
    }
    
    // MARK: - UIApplicationDelegate
    open func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        Mediator.setupAllModules()
        Mediator.checkAllModules(selector: #selector(UIApplicationDelegate.application(_:willFinishLaunchingWithOptions:)), arguments: [application, launchOptions ?? NSNull()])
        return true
    }
    
    open func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        Mediator.checkAllModules(selector: #selector(UIApplicationDelegate.application(_:didFinishLaunchingWithOptions:)), arguments: [application, launchOptions ?? NSNull()])
        setupApplication(application, options: launchOptions)
        setupController()
        setupService(options: launchOptions)
        return true
    }
    
    open func applicationWillResignActive(_ application: UIApplication) {
        Mediator.checkAllModules(selector: #selector(UIApplicationDelegate.applicationWillResignActive(_:)), arguments: [application])
    }
    
    open func applicationDidEnterBackground(_ application: UIApplication) {
        Mediator.checkAllModules(selector: #selector(UIApplicationDelegate.applicationDidEnterBackground(_:)), arguments: [application])
    }
    
    open func applicationWillEnterForeground(_ application: UIApplication) {
        Mediator.checkAllModules(selector: #selector(UIApplicationDelegate.applicationWillEnterForeground(_:)), arguments: [application])
    }
    
    open func applicationDidBecomeActive(_ application: UIApplication) {
        Mediator.checkAllModules(selector: #selector(UIApplicationDelegate.applicationDidBecomeActive(_:)), arguments: [application])
    }
    
    open func applicationWillTerminate(_ application: UIApplication) {
        Mediator.checkAllModules(selector: #selector(UIApplicationDelegate.applicationWillTerminate(_:)), arguments: [application])
    }
    
    // MARK: - Notification
    open func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Mediator.checkAllModules(selector: #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:)), arguments: [application, deviceToken])
        /*
        UIDevice.fw_setDeviceTokenData(deviceToken)
         */
    }
    
    open func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Mediator.checkAllModules(selector: #selector(UIApplicationDelegate.application(_:didFailToRegisterForRemoteNotificationsWithError:)), arguments: [application, error])
        /*
        UIDevice.fw_setDeviceTokenData(nil)
         */
    }
    
    open func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Mediator.checkAllModules(selector: #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:)), arguments: [application, userInfo, completionHandler])
        /*
        NotificationManager.shared.handleRemoteNotification(userInfo)
        completionHandler(.newData)
         */
    }
    
    // MARK: - URL
    open func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return Mediator.checkAllModules(selector: #selector(UIApplicationDelegate.application(_:open:options:)), arguments: [app, url, options])
        /*
        Router.openURL(url)
        return true
         */
    }
    
    open func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return Mediator.checkAllModules(selector: #selector(UIApplicationDelegate.application(_:continue:restorationHandler:)), arguments: [application, userActivity, restorationHandler])
        /*
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let webpageURL = userActivity.webpageURL {
            Router.openURL(webpageURL)
            return true
        }
        return false
         */
    }
    
}
