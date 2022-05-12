//
//  FWAuthorize.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/27.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import UIKit
import CoreLocation
import Photos
import AVFoundation
import UserNotifications

// MARK: - FWAuthorizeManager

/// 权限类型枚举
@objc public enum FWAuthorizeType: Int {
    /// 使用时定位，Info.plist需配置NSLocationWhenInUseUsageDescription
    case locationWhenInUse = 1
    /// 后台定位，Info.plist需配置NSLocationAlwaysUsageDescription和NSLocationAlwaysAndWhenInUseUsageDescription
    case locationAlways = 2
    /// 麦克风，需启用Microphone子模块，Info.plist需配置NSMicrophoneUsageDescription
    case microphone = 3
    /// 相册，Info.plist需配置NSPhotoLibraryUsageDescription
    case photoLibrary = 4
    /// 照相机，Info.plist需配置NSCameraUsageDescription
    case camera = 5
    /// 联系人，需启用Contacts子模块，Info.plist需配置NSContactsUsageDescription
    case contacts = 6
    /// 日历，需启用Calendar子模块，Info.plist需配置NSCalendarsUsageDescription
    case calendars = 7
    /// 提醒，需启用Calendar子模块，Info.plist需配置NSRemindersUsageDescription
    case reminders = 8
    /// 音乐，需启用AppleMusic子模块，Info.plist需配置NSAppleMusicUsageDescription
    case appleMusic = 9
    /// 通知，远程推送需打开Push Notifications开关和Background Modes的Remote notifications开关
    case notifications = 10
    /// 广告跟踪，需启用Tracking子模块，Info.plist需配置NSUserTrackingUsageDescription
    case tracking = 11
}

/// 权限状态枚举
@objc public enum FWAuthorizeStatus: Int {
    /// 未确认
    case notDetermined = 0
    /// 受限制
    case restricted = 1
    /// 被拒绝
    case denied = 2
    /// 已授权
    case authorized = 3
}

/// 权限授权协议
@objc public protocol FWAuthorizeProtocol {
    /// 查询权限状态，必须实现。某些权限会阻塞当前线程，建议异步查询，如通知
    func authorizeStatus() -> FWAuthorizeStatus
    
    /// 执行权限授权，主线程回调，必须实现
    func authorize(_ completion: ((FWAuthorizeStatus) -> Void)?)
    
    /// 异步查询权限状态，当前线程回调，可选实现。某些权限建议异步查询，不会阻塞当前线程，如通知
    @objc optional func authorizeStatus(_ completion: ((FWAuthorizeStatus) -> Void)?)
}

/// 权限管理器。由于打包上传ipa时会自动检查隐私库并提供Info.plist描述，所以默认关闭隐私库声明
///
/// 开启指定权限方法：
/// 一、Pod项目：添加pod时同时指定
/// pod 'FWFramework', :subspecs => ['Contacts']
/// 二、SPM项目：添加依赖时选中target
/// FWFrameworkContacts
@objcMembers public class FWAuthorizeManager: NSObject {
    private static var managers: [FWAuthorizeType: FWAuthorizeProtocol] = [:]
    private static var blocks: [FWAuthorizeType: () -> FWAuthorizeProtocol] = [:]
    
    /// 获取指定类型的权限管理器单例，部分权限未启用时返回nil
    public static func manager(type: FWAuthorizeType) -> FWAuthorizeProtocol? {
        if let manager = managers[type] { return manager }
        guard let manager = factory(type: type) else { return nil }
        managers[type] = manager
        return manager
    }
    
    /// 注册指定类型的权限管理器创建句柄，用于动态扩展权限类型
    public static func registerAuthorize(_ type: FWAuthorizeType, withBlock block: @escaping () -> FWAuthorizeProtocol) {
        blocks[type] = block
    }
    
    private static func factory(type: FWAuthorizeType) -> FWAuthorizeProtocol? {
        if let block = blocks[type] {
            return block()
        }
        
        switch type {
        case .locationWhenInUse:
            return FWAuthorizeLocation(isAlways: false)
        case .locationAlways:
            return FWAuthorizeLocation(isAlways: true)
        case .photoLibrary:
            return FWAuthorizePhotoLibrary()
        case .camera:
            return FWAuthorizeCamera()
        case .notifications:
            return FWAuthorizeNotifications()
        default:
            return nil
        }
    }
}

// MARK: - FWAuthorizeLocation

/// 定位授权
@objcMembers public class FWAuthorizeLocation: NSObject, FWAuthorizeProtocol, CLLocationManagerDelegate {
    private lazy var locationManager: CLLocationManager = {
        let result = CLLocationManager()
        result.delegate = self
        return result
    }()
    
    private var completionBlock: ((FWAuthorizeStatus) -> Void)?
    private var changeIgnored: Bool = false
    private var isAlways: Bool = false
    
    public init(isAlways: Bool) {
        super.init()
        self.isAlways = isAlways
    }
    
    public func authorizeStatus() -> FWAuthorizeStatus {
        // 定位功能未打开时返回Denied，可自行调用[CLLocationManager locationServicesEnabled]判断
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorizedAlways:
            return .authorized
        case .authorizedWhenInUse:
            if isAlways {
                let isAuthorized = UserDefaults.standard.object(forKey: "FWAuthorizeLocation")
                return isAuthorized != nil ? .denied : .notDetermined
            } else {
                return .authorized
            }
        default:
            return .notDetermined
        }
    }
    
    public func authorize(_ completion: ((FWAuthorizeStatus) -> Void)?) {
        completionBlock = completion
        
        if isAlways {
            locationManager.requestAlwaysAuthorization()
            // 标记已请求授权
            UserDefaults.standard.set(NSNumber(value: 1), forKey: "FWAuthorizeLocation")
            UserDefaults.standard.synchronize()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // 如果请求always权限且当前已经是WhenInUse权限，系统会先回调此方法一次，忽略之
        if isAlways && !changeIgnored {
            if status == .notDetermined || status == .authorizedWhenInUse {
                changeIgnored = true
                return
            }
        }
        
        // 主线程回调，仅一次
        if completionBlock != nil {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.completionBlock?(self.authorizeStatus())
                self.completionBlock = nil
            }
        }
    }
}

// MARK: - FWAuthorizePhotoLibrary

/// 相册授权
@objcMembers public class FWAuthorizePhotoLibrary: NSObject, FWAuthorizeProtocol {
    public func authorizeStatus() -> FWAuthorizeStatus {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        default:
            return .notDetermined
        }
    }
    
    public func authorize(_ completion: ((FWAuthorizeStatus) -> Void)?) {
        PHPhotoLibrary.requestAuthorization { status in
            if completion != nil {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    completion?(self.authorizeStatus())
                }
            }
        }
    }
}

// MARK: - FWAuthorizeCamera

/// 照相机授权
@objcMembers public class FWAuthorizeCamera: NSObject, FWAuthorizeProtocol {
    public func authorizeStatus() -> FWAuthorizeStatus {
        // 模拟器不支持照相机，返回受限制
        let mediaType = AVMediaType.video
        guard let device = AVCaptureDevice.default(for: mediaType) else { return .restricted }
        if !device.hasMediaType(mediaType) { return .restricted }
        
        let status = AVCaptureDevice.authorizationStatus(for: mediaType)
        switch status {
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        default:
            return .notDetermined
        }
    }
    
    public func authorize(_ completion: ((FWAuthorizeStatus) -> Void)?) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if completion != nil {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    completion?(self.authorizeStatus())
                }
            }
        }
    }
}

// MARK: - FWAuthorizeNotifications

/// 通知授权
@objcMembers public class FWAuthorizeNotifications: NSObject, FWAuthorizeProtocol {
    public func authorizeStatus() -> FWAuthorizeStatus {
        var status: FWAuthorizeStatus = .notDetermined
        // 由于查询授权为异步方法，此处使用信号量阻塞当前线程，同步返回查询结果
        let semaphore = DispatchSemaphore(value: 0)
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .denied:
                status = .denied
            case .authorized:
                status = .authorized
            case .provisional:
                status = .authorized
            default:
                status = .notDetermined
            }
            semaphore.signal()
        }
        semaphore.wait()
        return status
    }
    
    public func authorizeStatus(_ completion: ((FWAuthorizeStatus) -> Void)?) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            var status: FWAuthorizeStatus = .notDetermined
            switch settings.authorizationStatus {
            case .denied:
                status = .denied
            case .authorized:
                status = .authorized
            case .provisional:
                status = .authorized
            default:
                status = .notDetermined
            }
            
            if completion != nil {
                DispatchQueue.main.async {
                    completion?(status)
                }
            }
        }
    }
    
    public func authorize(_ completion: ((FWAuthorizeStatus) -> Void)?) {
        let options: UNAuthorizationOptions = [.badge, .sound, .alert]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            let status: FWAuthorizeStatus = granted ? .authorized : .denied
            if completion != nil {
                DispatchQueue.main.async {
                    completion?(status)
                }
            }
        }
        UIApplication.shared.registerForRemoteNotifications()
    }
}
