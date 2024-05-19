//
//  UserService.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/5/10.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

public class UserService {
    
    public static let shared = UserService()
    
    // MARK: - Notification
    public static let loginNotification = Notification.Name("loginNotification")
    public static let logoutNotification = Notification.Name("logoutNotification")
    
    // MARK: - Accessor
    private var userModel: UserModel?
    
    // 测试方案1：无需处理，自动归档保存到UserDefaults
    @ArchivedValue("userModel")
    private var archivableModel: UserModel?
    
    // 测试方案2：自行解码Data并保存到UserDefaults
    @StoredValue("userData")
    private var userData: Data?
    
    // 随机测试方案1和方案2
    private var isArchived = [true, false].randomElement()!
    
    // MARK: - Lifecycle
    private init() {
        Logger.debug("UserModel: \(isArchived ? "AnyArchivable" : "Codable")")
        
        if isArchived {
            AnyArchiver.registerType(UserModel.self)
            userModel = archivableModel
        } else {
            if let userData = userData {
                userModel = try? UserModel.decoded(from: userData)
            }
        }
    }
    
}

extension UserService {
    
    public func isLogin() -> Bool {
        return userModel != nil
    }
    
    public func getUserModel() -> UserModel? {
        guard var model = userModel else { return nil }
        
        if model.userName.isEmpty {
            model.userName = APP.localized("mediatorNickname")
        }
        return model
    }
    
    public func saveUserModel(_ model: UserModel) {
        userModel = model
        
        // 同时保存测试方案一和方案2数据
        archivableModel = model
        userData = try? model.encoded()
        
        NSObject.app.postNotification(UserService.loginNotification)
    }
    
    public func clearUserModel() {
        userModel = nil
        
        // 同时清除测试方案一和方案2数据
        archivableModel = nil
        userData = nil
        
        NSObject.app.postNotification(UserService.logoutNotification)
    }
    
    public func login(_ completion: (() -> Void)? = nil) {
        let viewController = LoginController()
        viewController.completion = completion
        let navigationController = UINavigationController(rootViewController: viewController)
        Navigator.present(navigationController, animated: true, completion: nil)
    }
    
    public func logout(_ completion: (() -> Void)? = nil) {
        let viewController = Navigator.topViewController
        viewController?.app.showConfirm(title: APP.localized("logoutConfirm"), message: nil) { [weak self] in
            self?.clearUserModel()
            completion?()
        }
    }
    
}
