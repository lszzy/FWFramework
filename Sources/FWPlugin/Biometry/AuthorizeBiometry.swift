//
//  AuthorizeBiometry.swift
//  FWFramework
//
//  Created by wuyong on 2024/5/17.
//

import LocalAuthentication
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - AuthorizeType+Biometry
extension AuthorizeType {
    /// 生物识别，Info.plist需配置NSFaceIDUsageDescription
    public static let biometry: AuthorizeType = .init("biometry")
}

// MARK: - AuthorizeBiometry
/// 生物识别授权
public class AuthorizeBiometry: NSObject, AuthorizeProtocol {
    public static let shared = AuthorizeBiometry()
    
    /// 当前识别策略，默认生物识别认证
    public var policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics
    /// 本地化识别原因，默认身份验证，详见evaluatePolicy
    public var localizedReason: ((LABiometryType) -> String)?
    /// 本地化回滚标题，默认空串隐藏回滚操作按钮，也可设置为nil并手工处理LAError.userFallback错误，详见LAContext
    public var localizedFallbackTitle: ((LABiometryType) -> String?)?
    /// 自定义上下文配置句柄，默认nil
    public var customContextBlock: ((LAContext) -> Void)?
    /// 当前生物识别类型，如none|touchID|faceID|opticID，详见LAContext
    public var biometryType: LABiometryType { checkContext.biometryType }
    
    private lazy var checkContext: LAContext = .init()
    private var latestAuthorizeStatus: AuthorizeStatus?
    private var latestAuthorizeError: Error?
    
    /// 同步查询状态，默认返回最近一次认证状态，未认证时为notDetermined，不支持时为restricted
    public func authorizeStatus() -> AuthorizeStatus {
        if latestAuthorizeStatus == nil {
            var nserror: NSError?
            if !checkContext.canEvaluatePolicy(policy, error: &nserror) {
                latestAuthorizeStatus = .restricted
                latestAuthorizeError = nserror
            }
        }
        
        let status = latestAuthorizeStatus ?? .notDetermined
        return status
    }
    
    /// 异步查询状态，主线程回调，默认返回最近一次认证状态，未认证时为notDetermined，不支持时为restricted
    public func authorizeStatus(_ completion: ((AuthorizeStatus, Error?) -> Void)?) {
        if latestAuthorizeStatus == nil {
            var nserror: NSError?
            if !checkContext.canEvaluatePolicy(policy, error: &nserror) {
                latestAuthorizeStatus = .restricted
                latestAuthorizeError = nserror
            }
        }
        
        let status = latestAuthorizeStatus ?? .notDetermined
        let error = latestAuthorizeError
        DispatchQueue.fw.mainAsync {
            completion?(status, error)
        }
    }
    
    public func requestAuthorize(_ completion: ((AuthorizeStatus, Error?) -> Void)?) {
        let context = LAContext()
        var nserror: NSError?
        guard context.canEvaluatePolicy(policy, error: &nserror) else {
            latestAuthorizeStatus = .restricted
            latestAuthorizeError = nserror
            
            if completion != nil {
                DispatchQueue.main.async {
                    completion?(.restricted, nserror)
                }
            }
            return
        }
        
        let reason = localizedReason?(context.biometryType) ?? FrameworkBundle.biometryReasonTitle
        // 默认未设置localizedFallbackTitle句柄时设置为空串隐藏回滚操作按钮
        context.localizedFallbackTitle = localizedFallbackTitle != nil ? localizedFallbackTitle?(context.biometryType) : ""
        customContextBlock?(context)
        context.evaluatePolicy(policy, localizedReason: reason) { [weak self] success, error in
            let status: AuthorizeStatus = success ? .authorized : .denied
            self?.latestAuthorizeStatus = status
            self?.latestAuthorizeError = error
            
            if completion != nil {
                DispatchQueue.main.async {
                    completion?(status, error)
                }
            }
        }
    }
}

// MARK: - Autoloader+Biometry
@objc extension Autoloader {
    static func loadPlugin_Biometry() {
        AuthorizeManager.presetAuthorize(.biometry) { AuthorizeBiometry.shared }
    }
}
