//
//  AppMediator.swift
//  Example
//
//  Created by wuyong on 2021/2/8.
//  Copyright © 2021 site.wuyong. All rights reserved.
//

import Foundation
import SDWebImage
import SDWebImageWebPCoder
import SDWebImageSVGKitPlugin
#if DEBUG
import FWDebug
#endif

@objc protocol AppService: FWModuleProtocol {}

@objc extension FWLoader {
    func loadAppModule() {
        FWMediator.registerService(AppService.self, withModule: AppModule.self)
    }
}

class AppModule: NSObject, AppService {
    private static let sharedModule = AppModule()
    
    public static func sharedInstance() -> Self {
        return sharedModule as! Self
    }
    
    func setup() {
        #if DEBUG
        FWDebugManager.sharedInstance().openUrl = { (url) in
            if let scheme = NSURL.fwURL(with: url)?.scheme, scheme.count > 0 {
                FWRouter.openURL(url)
                return true
            }
            return false
        }
        #endif
        
        SDImageCodersManager.shared.addCoder(SDImageWebPCoder.shared)
        SDImageCodersManager.shared.addCoder(SDImageSVGKCoder.shared)
        
        DispatchQueue.main.async {
            FWThemeManager.sharedInstance.overrideWindow = true
        }
    }
    
    // MARK: - UIApplicationDelegate
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FWNotificationManager.sharedInstance.clearNotificationBadges()
        if let remoteNotification = launchOptions?[.remoteNotification] {
            FWNotificationManager.sharedInstance.handleRemoteNotification(remoteNotification)
        }
        
        FWNotificationManager.sharedInstance.registerNotificationHandler()
        FWNotificationManager.sharedInstance.requestAuthorize(nil)
        FWNotificationManager.sharedInstance.remoteNotificationHandler = { (userInfo, notification) in
            FWNotificationManager.sharedInstance.clearNotificationBadges()
            
            var title: String?
            if let response = notification as? UNNotificationResponse {
                title = response.notification.request.content.title
            }
            UIWindow.fwMain?.fwShowMessage(withText: "收到远程通知：\(title ?? "")\n\(userInfo ?? [:])")
        }
        FWNotificationManager.sharedInstance.localNotificationHandler = { (userInfo, notification) in
            FWNotificationManager.sharedInstance.clearNotificationBadges()
            
            var title: String?
            if let response = notification as? UNNotificationResponse {
                title = response.notification.request.content.title
            }
            UIWindow.fwMain?.fwShowMessage(withText: "收到本地通知：\(title ?? "")\n\(userInfo ?? [:])")
        }
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        UIDevice.fwSetDeviceTokenData(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        UIDevice.fwSetDeviceTokenData(nil)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        FWNotificationManager.sharedInstance.handleRemoteNotification(userInfo)
        completionHandler(.newData)
    }
}
