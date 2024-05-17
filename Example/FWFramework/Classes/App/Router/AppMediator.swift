//
//  AppMediator.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/24.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework
#if DEBUG
import FWDebug
#endif

protocol AppModuleProtocol: ModuleProtocol {
    func moduleMethod()
}

@objc extension Autoloader {
    static func loadApp_AppModule() {
        Mediator.registerService(AppModuleProtocol.self, module: AppModule.self)
    }
}

/*final*/ class AppModule: NSObject, AppModuleProtocol {
    
    /*public static let shared = AppModule()*/
    
    func setup() {
        #if DEBUG
        FWDebugManager.sharedInstance().openUrl = { (url) in
            if let scheme = URL.app.url(string: url)?.scheme, scheme.count > 0 {
                Router.openURL(url)
                return true
            }
            return false
        }
        #endif
        
        DispatchQueue.main.async {
            ThemeManager.shared.overrideWindow = true
        }
    }
    
    func moduleMethod() {
        APP.debug("AppModule.moduleMethod")
    }
    
    // MARK: - UIApplicationDelegate
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        NotificationManager.shared.clearNotificationBadges()
        if let remoteNotification = launchOptions?[.remoteNotification] {
            NotificationManager.shared.handleRemoteNotification(remoteNotification)
        }
        
        NotificationManager.shared.registerNotificationHandler()
        NotificationManager.shared.requestAuthorize(nil)
        NotificationManager.shared.remoteNotificationHandler = { (userInfo, notification) in
            NotificationManager.shared.clearNotificationBadges()
            
            var title: String?
            if let response = notification as? UNNotificationResponse {
                title = response.notification.request.content.title
            }
            UIWindow.app.showMessage(text: "收到远程通知：\(title ?? "")\n\(APP.safeString(userInfo))")
        }
        NotificationManager.shared.localNotificationHandler = { (userInfo, notification) in
            NotificationManager.shared.clearNotificationBadges()
            
            var title: String?
            if let response = notification as? UNNotificationResponse {
                title = response.notification.request.content.title
            }
            UIWindow.app.showMessage(text: "收到本地通知：\(title ?? "")\n\(APP.safeString(userInfo))")
        }
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        NotificationManager.shared.clearNotificationBadges()
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        UIDevice.app.setDeviceTokenData(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        UIDevice.app.setDeviceTokenData(nil)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        NotificationManager.shared.handleRemoteNotification(userInfo)
        completionHandler(.newData)
    }
}
