//
//  AuthorizeBluetooth.swift
//  FWFramework
//
//  Created by wuyong on 2025/6/8.
//

import CoreBluetooth
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - AuthorizeType+Bluetooth
extension AuthorizeType {
    /// 蓝牙，Info.plist需配置NSBluetoothPeripheralUsageDescription或NSBluetoothAlwaysUsageDescription
    public static let bluetooth: AuthorizeType = .init("bluetooth")
}

// MARK: - AuthorizeBluetooth
/// 蓝牙授权
public class AuthorizeBluetooth: NSObject, AuthorizeProtocol, CBCentralManagerDelegate, @unchecked Sendable {
    public static let shared = AuthorizeBluetooth()

    private var centralManager: CBCentralManager?
    private var completionBlock: (@MainActor @Sendable (AuthorizeStatus, Error?) -> Void)?

    private func authorizeStatus(for status: CBManagerAuthorization) -> AuthorizeStatus {
        switch status {
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .allowedAlways:
            return .authorized
        default:
            return .notDetermined
        }
    }

    // MARK: - AuthorizeProtocol
    public func authorizeStatus() -> AuthorizeStatus {
        let status: CBManagerAuthorization
        if #available(iOS 13.1, *) {
            status = CBCentralManager.authorization
        } else {
            status = CBCentralManager().authorization
        }
        return authorizeStatus(for: status)
    }

    public func requestAuthorize(_ completion: (@MainActor @Sendable (AuthorizeStatus, Error?) -> Void)?) {
        completionBlock = completion
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // MARK: - CBCentralManagerDelegate
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let authorizeStatus = authorizeStatus(for: central.authorization)
        if authorizeStatus != .notDetermined, completionBlock != nil {
            DispatchQueue.fw.mainAsync {
                self.completionBlock?(authorizeStatus, nil)
                self.completionBlock = nil
                self.centralManager = nil
            }
        }
    }
}

// MARK: - Autoloader+Bluetooth
@objc extension Autoloader {
    static func loadPlugin_Bluetooth() {
        AuthorizeManager.presetAuthorize(.bluetooth) { AuthorizeBluetooth.shared }
    }
}
