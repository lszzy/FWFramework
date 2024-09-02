//
//  Authorize.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import AVFoundation
import CoreLocation
import Photos
import UIKit
import UserNotifications

// MARK: - AuthorizeType
/// 可扩展权限类型
public struct AuthorizeType: RawRepresentable, Equatable, Hashable, Sendable {
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
public enum AuthorizeStatus: Int, Sendable {
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
    /// 同步查询权限状态，必须实现。某些权限会阻塞当前线程，建议异步查询，如通知
    func authorizeStatus() -> AuthorizeStatus

    /// 异步执行权限授权，主线程回调，必须实现
    func requestAuthorize(_ completion: (@MainActor @Sendable (AuthorizeStatus, Error?) -> Void)?)

    /// 异步查询权限状态，主线程回调，可选实现。某些权限建议异步查询，不会阻塞当前线程，如通知
    func authorizeStatus(_ completion: (@MainActor @Sendable (AuthorizeStatus, Error?) -> Void)?)
}

extension AuthorizeProtocol {
    /// 默认实现异步查询权限状态，主线程回调
    public func authorizeStatus(_ completion: (@MainActor @Sendable (AuthorizeStatus, Error?) -> Void)?) {
        let status = authorizeStatus()
        DispatchQueue.fw.mainAsync {
            completion?(status, nil)
        }
    }
}

// MARK: - AuthorizeManager
/// 权限管理器。由于打包上传ipa时会自动检查隐私库并提供Info.plist描述，所以默认关闭隐私库声明
///
/// 开启指定权限方法示例：
/// 1. Pod项目添加pod时指定子模块：pod 'FWFramework', :subspecs => ['FWPlugin/Contacts']
/// 2. SPM项目勾选并引入指定子模块：import FWPluginContacts
public class AuthorizeManager {
    private nonisolated(unsafe) static var blocks: [AuthorizeType: () -> AuthorizeProtocol] = [:]

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
        if let block = blocks[type] {
            return block()
        }

        switch type {
        case .locationWhenInUse:
            return AuthorizeLocation.shared
        case .locationAlways:
            return AuthorizeLocation.always
        case .photoLibrary:
            return AuthorizePhotoLibrary.shared
        case .camera:
            return AuthorizeCamera.shared
        case .notifications:
            return AuthorizeNotifications.shared
        default:
            return nil
        }
    }
}

// MARK: - AuthorizeLocation
/// 定位授权
public class AuthorizeLocation: NSObject, AuthorizeProtocol, CLLocationManagerDelegate, @unchecked Sendable {
    public static let shared = AuthorizeLocation()
    public static let always = AuthorizeLocation(isAlways: true)

    public lazy var locationManager: CLLocationManager = {
        let result = CLLocationManager()
        result.delegate = self
        return result
    }()

    private var isAlways: Bool = false
    private var completionBlock: (@MainActor @Sendable (AuthorizeStatus, Error?) -> Void)?

    public init(isAlways: Bool = false) {
        super.init()
        self.isAlways = isAlways
    }

    public static func authorizeStatus(for manager: CLLocationManager, isAlways: Bool = false) -> AuthorizeStatus {
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = manager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }

        switch status {
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorizedAlways:
            return .authorized
        case .authorizedWhenInUse:
            if isAlways {
                return .denied
            } else {
                return .authorized
            }
        default:
            return .notDetermined
        }
    }

    public func authorizeStatus() -> AuthorizeStatus {
        AuthorizeLocation.authorizeStatus(for: locationManager, isAlways: isAlways)
    }

    public func requestAuthorize(_ completion: (@MainActor @Sendable (AuthorizeStatus, Error?) -> Void)?) {
        let authorizeStatus = authorizeStatus()
        if authorizeStatus != .notDetermined {
            if completion != nil {
                DispatchQueue.fw.mainAsync {
                    completion?(authorizeStatus, nil)
                }
            }
            return
        }

        completionBlock = completion
        if isAlways {
            locationManager.requestAlwaysAuthorization()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let authorizeStatus = authorizeStatus()
        if authorizeStatus != .notDetermined, completionBlock != nil {
            DispatchQueue.fw.mainAsync {
                self.completionBlock?(authorizeStatus, nil)
                self.completionBlock = nil
            }
        }
    }

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let authorizeStatus = authorizeStatus()
        if authorizeStatus != .notDetermined, completionBlock != nil {
            DispatchQueue.fw.mainAsync {
                self.completionBlock?(authorizeStatus, nil)
                self.completionBlock = nil
            }
        }
    }
}

// MARK: - AuthorizePhotoLibrary
/// 相册授权
public class AuthorizePhotoLibrary: NSObject, AuthorizeProtocol, @unchecked Sendable {
    public static let shared = AuthorizePhotoLibrary()
    public static let addOnly = AuthorizePhotoLibrary(addOnly: true)
    
    private var addOnly = false
    
    public init(addOnly: Bool = false) {
        super.init()
        self.addOnly = addOnly
    }

    public func authorizeStatus() -> AuthorizeStatus {
        let status: PHAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = PHPhotoLibrary.authorizationStatus(for: addOnly ? .addOnly : .readWrite)
        } else {
            status = PHPhotoLibrary.authorizationStatus()
        }
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

    public func requestAuthorize(_ completion: (@MainActor @Sendable (AuthorizeStatus, Error?) -> Void)?) {
        if #available(iOS 14.0, *) {
            PHPhotoLibrary.requestAuthorization(for: addOnly ? .addOnly : .readWrite) { _ in
                if completion != nil {
                    DispatchQueue.fw.mainAsync {
                        completion?(self.authorizeStatus(), nil)
                    }
                }
            }
        } else {
            PHPhotoLibrary.requestAuthorization { _ in
                if completion != nil {
                    DispatchQueue.fw.mainAsync {
                        completion?(self.authorizeStatus(), nil)
                    }
                }
            }
        }
    }
}

// MARK: - AuthorizeCamera
/// 照相机授权
public class AuthorizeCamera: NSObject, AuthorizeProtocol, @unchecked Sendable {
    public static let shared = AuthorizeCamera()

    public func authorizeStatus() -> AuthorizeStatus {
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

    public func requestAuthorize(_ completion: (@MainActor @Sendable (AuthorizeStatus, Error?) -> Void)?) {
        AVCaptureDevice.requestAccess(for: .video) { _ in
            if completion != nil {
                DispatchQueue.fw.mainAsync {
                    completion?(self.authorizeStatus(), nil)
                }
            }
        }
    }
}

// MARK: - AuthorizeNotifications
/// 通知授权
public class AuthorizeNotifications: NSObject, AuthorizeProtocol, @unchecked Sendable {
    public static let shared = AuthorizeNotifications()

    public var authorizeOptions: UNAuthorizationOptions = [.badge, .sound, .alert]

    public func authorizeStatus() -> AuthorizeStatus {
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

    public func authorizeStatus(_ completion: (@MainActor @Sendable (AuthorizeStatus, Error?) -> Void)?) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let status: AuthorizeStatus
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

            DispatchQueue.fw.mainAsync {
                completion?(status, nil)
            }
        }
    }

    public func requestAuthorize(_ completion: (@MainActor @Sendable (AuthorizeStatus, Error?) -> Void)?) {
        UNUserNotificationCenter.current().requestAuthorization(options: authorizeOptions) { granted, error in
            let status: AuthorizeStatus = granted ? .authorized : .denied
            if completion != nil {
                DispatchQueue.fw.mainAsync {
                    completion?(status, error)
                }
            }
        }
        DispatchQueue.fw.mainAsync {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

// MARK: - Concurrency+Authorize
#if canImport(_Concurrency)
extension AuthorizeProtocol {
    /// 异步查询权限状态
    public func authorizeStatus() async -> (status: AuthorizeStatus, error: Error?) {
        await withCheckedContinuation { continuation in
            authorizeStatus { status, error in
                continuation.resume(returning: (status: status, error: error))
            }
        }
    }

    /// 异步执行权限授权
    public func requestAuthorize() async -> (status: AuthorizeStatus, error: Error?) {
        await withCheckedContinuation { continuation in
            requestAuthorize { status, error in
                continuation.resume(returning: (status: status, error: error))
            }
        }
    }
}
#endif
