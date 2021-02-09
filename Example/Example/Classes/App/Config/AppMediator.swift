//
//  AppMediator.swift
//  Example
//
//  Created by wuyong on 2021/2/8.
//  Copyright © 2021 site.wuyong. All rights reserved.
//

import Foundation

@objc protocol NotificationService: FWModuleProtocol {}

@objc extension FWAutoloader {
    func loadNotificationModule() {
        FWMediator.registerService(NotificationService.self, withModule: NotificationModule.self)
    }
}

@objcMembers class NotificationModule: NSObject, NotificationService {
    private static let sharedModule = NotificationModule()
    
    public static func sharedInstance() -> Self {
        return sharedModule as! Self
    }
    
    public func setup() {
        FWLogDebug(#function)
    }
    
    // MARK: - UIApplicationDelegate
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FWNotificationManager.sharedInstance.clearNotificationBadges()
        if let remoteNotification = launchOptions?[.remoteNotification] {
            FWNotificationManager.sharedInstance.handleRemoteNotification(remoteNotification)
        }
        if let localNotification = launchOptions?[.localNotification] {
            FWNotificationManager.sharedInstance.handleLocalNotification(localNotification)
        }
        
        FWNotificationManager.sharedInstance.registerNotificationHandler()
        FWNotificationManager.sharedInstance.requestAuthorize(nil)
        FWNotificationManager.sharedInstance.remoteNotificationHandler = { (userInfo, notification) in
            FWNotificationManager.sharedInstance.clearNotificationBadges()
            
            var title: String?
            if #available(iOS 10.0, *) {
                if let response = notification as? UNNotificationResponse {
                    title = response.notification.request.content.title
                }
            }
            UIWindow.fwMain()?.fwShowMessage(withText: "收到远程通知：\(title ?? "")\n\(userInfo ?? [:])")
        }
        FWNotificationManager.sharedInstance.localNotificationHandler = { (userInfo, notification) in
            FWNotificationManager.sharedInstance.clearNotificationBadges()
            
            var title: String?
            if #available(iOS 10.0, *) {
                if let response = notification as? UNNotificationResponse {
                    title = response.notification.request.content.title
                }
            } else {
                if let local = notification as? UILocalNotification {
                    title = local.alertTitle ?? local.alertBody
                }
            }
            UIWindow.fwMain()?.fwShowMessage(withText: "收到本地通知：\(title ?? "")\n\(userInfo ?? [:])")
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
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        FWNotificationManager.sharedInstance.handleLocalNotification(notification)
    }
}
