//
//  LoginViewModel.swift
//  FWFramework_Example
//
//  Created by wuyong on 2024/5/16.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation

class LoginViewModel {
    func login(nickName: String, completion: @escaping () -> Void) {
        var userModel = UserModel()
        userModel.userId = "1"
        userModel.userName = nickName

        UserService.shared.saveUserModel(userModel)
        completion()
    }
}
