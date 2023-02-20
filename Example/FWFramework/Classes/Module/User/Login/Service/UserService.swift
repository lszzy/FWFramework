//
//  UserService.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/5/10.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class UserService {
    
    class UserInfo {
        public var userId: String = ""
        public var userName: String = ""
    }
    
    static let shared = UserService()
    
    @StoredValue("userId")
    private var userId: String = ""
    @StoredValue("userName")
    private var userName: String = ""
    
}

extension UserService {
    
    public func isLogin() -> Bool {
        return userId.count > 0
    }
    
    public func userInfo() -> UserInfo? {
        if userId.count < 1 { return nil }
        
        let userInfo = UserInfo()
        userInfo.userId = userId
        userInfo.userName = userName
        return userInfo
    }
    
    public func login(_ completion: (() -> Void)?) {
        let viewController = LoginController()
        viewController.completion = { [weak self] in
            self?.userId = "1"
            self?.userName = "test"
            completion?()
        }
        let navigationController = UINavigationController(rootViewController: viewController)
        Navigator.present(navigationController, animated: true, completion: nil)
    }
    
    public func logout(_ completion: (() -> Void)?) {
        userId = ""
        userName = ""
        completion?()
    }
    
}
