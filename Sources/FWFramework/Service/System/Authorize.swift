//
//  Authorize.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit
import CoreLocation
import Photos
import AVFoundation
import UserNotifications

// MARK: - AuthorizeType
/// 可扩展权限类型
public struct AuthorizeType: RawRepresentable, Equatable, Hashable {
    
    public typealias RawValue = String
    
    /// 使用时定位，Info.plist需配置NSLocationWhenInUseUsageDescription
    public static let locationWhenInUse: AuthorizeType = .init("locationWhenInUse")
    /// 后台定位，Info.plist需配置NSLocationAlwaysUsageDescription和NSLocationAlwaysAndWhenInUseUsageDescription
    public static let locationAlways: AuthorizeType = .init("locationAlways")
    /// 相册，Info.plist需配置NSPhotoLibraryUsageDescription|NSPhotoLibraryAddUsageDescription
    public static let photoLibrary: AuthorizeType = .init("photoLibrary")
    /// 照相机，Info.plist需配置NSCameraUsageDescription
    public static let camera: AuthorizeType = .init("camera")
    /// 通知，远程推送需打开Push Notifications开关和Background Modes的Remote notifications开关
    public static let notifications: AuthorizeType = .init("notifications")
    
    public var rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
}

// MARK: - AuthorizeStatus
/// 权限状态枚举
public enum AuthorizeStatus: Int {
    /// 未确认
    case notDetermined = 0
    /// 受限制
    case restricted = 1
    /// 被拒绝
    case denied = 2
    /// 已授权
    case authorized = 3
}

// MARK: - AuthorizeProtocol
/// 权限授权协议
public protocol AuthorizeProtocol {
    /// 查询权限状态，必须实现。某些权限会阻塞当前线程，建议异步查询，如通知
    func authorizeStatus() -> AuthorizeStatus
    
    /// 执行权限授权，主线程回调，必须实现
    func authorize(_ completion: ((AuthorizeStatus) -> Void)?)
    
    /// 异步查询权限状态，当前线程回调，可选实现。某些权限建议异步查询，不会阻塞当前线程，如通知
    func authorizeStatus(_ completion: ((AuthorizeStatus) -> Void)?)
}

extension AuthorizeProtocol {
    /// 默认实现异步查询权限状态
    public func authorizeStatus(_ completion: ((AuthorizeStatus) -> Void)?) {
        completion?(authorizeStatus())
    }
}

// MARK: - AuthorizeManager
/// 权限管理器。由于打包上传ipa时会自动检查隐私库并提供Info.plist描述，所以默认关闭隐私库声明
///
/// 开启指定权限方法示例：
/// 1. Pod项目添加pod时指定子模块：pod 'FWFramework', :subspecs => ['FWExtension/Contacts']
/// 2. SPM项目勾选并引入指定子模块：import FWExtensionContacts
public class AuthorizeManager: NSObject {
    private static var managers: [AuthorizeType: AuthorizeProtocol] = [:]
    private static var blocks: [AuthorizeType: () -> AuthorizeProtocol] = [:]
    
    /// 注册指定类型的权限管理器创建句柄，用于动态扩展权限类型
    public static func registerAuthorize(_ type: AuthorizeType, block: @escaping () -> AuthorizeProtocol) {
        blocks[type] = block
    }
    
    /// 预置指定类型的权限管理器创建句柄，已注册时不生效，用于动态扩展权限类型
    @discardableResult
    public static func presetAuthorize(_ type: AuthorizeType, block: @escaping () -> AuthorizeProtocol) -> Bool {
        guard blocks[type] == nil else { return false }
        blocks[type] = block
        return true
    }
    
    /// 获取指定类型的权限管理器单例，部分权限未启用时返回nil
    public static func manager(type: AuthorizeType) -> AuthorizeProtocol? {
        if let manager = managers[type] { return manager }
        guard let manager = factory(type: type) else { return nil }
        managers[type] = manager
        return manager
    }
    
    private static func factory(type: AuthorizeType) -> AuthorizeProtocol? {
        if let block = blocks[type] {
            return block()
        }
        
        switch type {
        case .locationWhenInUse:
            return AuthorizeLocation(isAlways: false)
        case .locationAlways:
            return AuthorizeLocation(isAlways: true)
        case .photoLibrary:
            return AuthorizePhotoLibrary()
        case .camera:
            return AuthorizeCamera()
        case .notifications:
            return AuthorizeNotifications()
        default:
            return nil
        }
    }
}

// MARK: - AuthorizeLocation
/// 定位授权
private class AuthorizeLocation: NSObject, AuthorizeProtocol, CLLocationManagerDelegate {
    private lazy var locationManager: CLLocationManager = {
        let result = CLLocationManager()
        result.delegate = self
        return result
    }()
    
    private var completionBlock: ((AuthorizeStatus) -> Void)?
    private var changeIgnored: Bool = false
    private var isAlways: Bool = false
    
    init(isAlways: Bool) {
        super.init()
        self.isAlways = isAlways
    }
    
    func authorizeStatus() -> AuthorizeStatus {
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
    
    func authorize(_ completion: ((AuthorizeStatus) -> Void)?) {
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
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // 如果请求always权限且当前已经是WhenInUse权限，系统会先回调此方法一次，忽略之
        if isAlways && !changeIgnored {
            if status == .notDetermined || status == .authorizedWhenInUse {
                changeIgnored = true
                return
            }
        }
        
        // 主线程回调，仅一次
        if completionBlock != nil {
            DispatchQueue.main.async {
                self.completionBlock?(self.authorizeStatus())
                self.completionBlock = nil
            }
        }
    }
}

// MARK: - AuthorizePhotoLibrary
/// 相册授权
private class AuthorizePhotoLibrary: NSObject, AuthorizeProtocol {
    func authorizeStatus() -> AuthorizeStatus {
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
    
    func authorize(_ completion: ((AuthorizeStatus) -> Void)?) {
        PHPhotoLibrary.requestAuthorization { status in
            if completion != nil {
                DispatchQueue.main.async {
                    completion?(self.authorizeStatus())
                }
            }
        }
    }
}

// MARK: - AuthorizeCamera
/// 照相机授权
private class AuthorizeCamera: NSObject, AuthorizeProtocol {
    func authorizeStatus() -> AuthorizeStatus {
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
    
    func authorize(_ completion: ((AuthorizeStatus) -> Void)?) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if completion != nil {
                DispatchQueue.main.async {
                    completion?(self.authorizeStatus())
                }
            }
        }
    }
}

// MARK: - AuthorizeNotifications
/// 通知授权
internal class AuthorizeNotifications: NSObject, AuthorizeProtocol {
    static var authorizeOptions: UNAuthorizationOptions = [.badge, .sound, .alert]
    
    func authorizeStatus() -> AuthorizeStatus {
        var status: AuthorizeStatus = .notDetermined
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
    
    func authorizeStatus(_ completion: ((AuthorizeStatus) -> Void)?) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            var status: AuthorizeStatus = .notDetermined
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
    
    func authorize(_ completion: ((AuthorizeStatus) -> Void)?) {
        let options = AuthorizeNotifications.authorizeOptions
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            let status: AuthorizeStatus = granted ? .authorized : .denied
            if completion != nil {
                DispatchQueue.main.async {
                    completion?(status)
                }
            }
        }
        UIApplication.shared.registerForRemoteNotifications()
    }
}