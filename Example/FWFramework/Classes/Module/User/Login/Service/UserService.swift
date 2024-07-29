//
//  UserService.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/5/10.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

public class UserService: @unchecked Sendable {
    
    public static let shared = UserService()
    
    // MARK: - Notification
    public static let loginNotification = Notification.Name("loginNotification")
    public static let logoutNotification = Notification.Name("logoutNotification")
    
    // MARK: - Accessor
    @StoredValue("userModel")
    private var userModel: UserModel?
    
    // MARK: - Lifecycle
    private init() {
        ArchiveCoder.registerType(UserModel.self)
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
        NSObject.app.postNotification(UserService.loginNotification)
    }
    
    public func clearUserModel() {
        userModel = nil
        NSObject.app.postNotification(UserService.logoutNotification)
    }
    
    @MainActor public func login(_ completion: (() -> Void)? = nil) {
        let viewController = LoginController()
        viewController.completion = completion
        let navigationController = UINavigationController(rootViewController: viewController)
        Navigator.present(navigationController, animated: true, completion: nil)
    }
    
    @MainActor public func logout(_ completion: (() -> Void)? = nil) {
        let viewController = Navigator.topViewController
        viewController?.app.showConfirm(title: APP.localized("logoutConfirm"), message: nil) { [weak self] in
            self?.clearUserModel()
            completion?()
        }
    }
    
}
