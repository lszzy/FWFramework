//
//  FWNotification.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/27.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import UserNotifications
#if FWMacroSPM
import FWFramework
#endif

/// 通知管理器
@objcMembers public class FWNotificationManager: NSObject, UNUserNotificationCenterDelegate {
    /// 单例模式
    public static let sharedInstance = FWNotificationManager()
    
    // MARK: - Authorize
    
    /// 异步查询通知权限状态，当前线程回调
    public func authorizeStatus(_ completion: ((FWAuthorizeStatus) -> Void)?) {
        FWAuthorizeManager.manager(type: .notifications)?.authorizeStatus?(completion)
    }
    
    /// 执行通知权限授权，主线程回调
    public func requestAuthorize(_ completion: ((FWAuthorizeStatus) -> Void)?) {
        FWAuthorizeManager.manager(type: .notifications)?.authorize(completion)
    }
    
    // MARK: - Badge
    
    /// 清空图标通知计数
    public func clearNotificationBadges() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    // MARK: - Handler
    
    /// 设置远程推送处理句柄，参数为userInfo和原始通知对象
    public var remoteNotificationHandler: (([AnyHashable: Any]?, Any) -> Void)?
    
    /// 设置本地推送处理句柄，参数为userInfo和原始通知对象
    public var localNotificationHandler: (([AnyHashable: Any]?, Any) -> Void)?
    
    /// 注册通知处理器，iOS10+生效，iOS10以下详见UIApplicationDelegate
    public func registerNotificationHandler() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    /// 处理远程推送通知，支持NSDictionary|UNNotification|UNNotificationResponse
    public func handleRemoteNotification(_ notification: Any) {
        guard remoteNotificationHandler != nil else { return }
        
        var userInfo: [AnyHashable: Any]?
        if let dictionary = notification as? [AnyHashable: Any] {
            userInfo = dictionary
        } else if let response = notification as? UNNotificationResponse {
            userInfo = response.notification.request.content.userInfo
        } else if let notify = notification as? UNNotification {
            userInfo = notify.request.content.userInfo
        }
        remoteNotificationHandler?(userInfo, notification)
    }
    
    /// 处理本地通知，支持NSDictionary|UNNotification|UNNotificationResponse
    public func handleLocalNotification(_ notification: Any) {
        guard localNotificationHandler != nil else { return }
        
        var userInfo: [AnyHashable: Any]?
        if let dictionary = notification as? [AnyHashable: Any] {
            userInfo = dictionary
        } else if let response = notification as? UNNotificationResponse {
            userInfo = response.notification.request.content.userInfo
        } else if let notify = notification as? UNNotification {
            userInfo = notify.request.content.userInfo
        }
        localNotificationHandler?(userInfo, notification)
    }
    
    // MARK: - Local
    
    /// 注册本地通知，badge为0时不改变，soundName为default时为默认声音，timeInterval为触发时间间隔(0为立即触发)，block为自定义内容句柄，iOS15+支持时效性通知，需entitlements配置开启
    public func registerLocalNotification(_ identifier: String, title: String?, subtitle: String?, body: String?, userInfo: [AnyHashable: Any]?, badge: Int, soundName: String?, timeInterval: TimeInterval, repeats: Bool, block: ((UNMutableNotificationContent) -> Void)?) {
        let notification = UNMutableNotificationContent()
        if let title = title { notification.title = title }
        if let subtitle = subtitle { notification.subtitle = subtitle }
        if let body = body { notification.body = body }
        if let userInfo = userInfo { notification.userInfo = userInfo }
        notification.badge = badge > 0 ? NSNumber(value: badge) : nil
        if let soundName = soundName { notification.sound = (soundName == "default") ? .default : UNNotificationSound(named: UNNotificationSoundName(soundName)) }
        block?(notification)
        
        let trigger = timeInterval > 0 ? UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: repeats) : nil
        let request = UNNotificationRequest(identifier: identifier, content: notification, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    /// 批量删除本地通知(未发出和已发出)
    public func removeLocalNotification(_ identifiers: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    
    /// 删除所有本地通知(未发出和已发出)
    public func removeAllLocalNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    /// 前台收到推送
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 远程推送
        if notification.request.trigger is UNPushNotificationTrigger {
            completionHandler([.badge, .sound, .alert])
        // 本地推送
        } else {
            completionHandler([.badge, .sound, .alert])
        }
    }
    
    /// 后台收到推送
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // 远程推送
        if response.notification.request.trigger is UNPushNotificationTrigger {
            handleRemoteNotification(response)
            completionHandler()
        // 本地推送
        } else {
            handleLocalNotification(response)
            completionHandler()
        }
    }
}
