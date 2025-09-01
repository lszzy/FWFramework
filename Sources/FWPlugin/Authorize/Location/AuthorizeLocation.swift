//
//  AuthorizeLocation.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import CoreLocation
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - AuthorizeType+Location
extension AuthorizeType {
    /// 使用时定位，Info.plist需配置NSLocationWhenInUseUsageDescription
    public static let locationWhenInUse: AuthorizeType = .init("locationWhenInUse")
    /// 后台定位，Info.plist需配置NSLocationAlwaysUsageDescription和NSLocationAlwaysAndWhenInUseUsageDescription
    public static let locationAlways: AuthorizeType = .init("locationAlways")
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

    private func authorizeStatus(for status: CLAuthorizationStatus, isAlways: Bool = false) -> AuthorizeStatus {
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
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = locationManager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        return authorizeStatus(for: status, isAlways: isAlways)
    }

    public func requestAuthorize(_ completion: (@MainActor @Sendable (AuthorizeStatus, Error?) -> Void)?) {
        completionBlock = completion
        if isAlways {
            locationManager.requestAlwaysAuthorization()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    @available(iOS 14.0, *)
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let authorizeStatus = authorizeStatus(for: manager.authorizationStatus, isAlways: isAlways)
        if authorizeStatus != .notDetermined, completionBlock != nil {
            DispatchQueue.fw.mainAsync {
                self.completionBlock?(authorizeStatus, nil)
                self.completionBlock = nil
            }
        }
    }

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let authorizeStatus = authorizeStatus(for: status, isAlways: isAlways)
        if authorizeStatus != .notDetermined, completionBlock != nil {
            DispatchQueue.fw.mainAsync {
                self.completionBlock?(authorizeStatus, nil)
                self.completionBlock = nil
            }
        }
    }
}

// MARK: - Autoloader+Location
@objc extension Autoloader {
    static func loadPlugin_Location() {
        AuthorizeManager.presetAuthorize(.locationWhenInUse) { AuthorizeLocation.shared }
        AuthorizeManager.presetAuthorize(.locationAlways) { AuthorizeLocation.always }
    }
}
