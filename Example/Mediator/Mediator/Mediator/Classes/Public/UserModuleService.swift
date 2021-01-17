//
//  Mediator.swift
//  Mediator
//
//  Created by lingshizhuangzi@gmail.com on 01/01/2021.
//  Copyright (c) 2021 lingshizhuangzi@gmail.com. All rights reserved.
//

import FWFramework

@objcMembers public class UserInfo: NSObject {
    public var userId: String = ""
    public var userName: String = ""
    public var userAvatar: UIImage?
}

@objc public protocol UserModuleService: FWModuleProtocol {
    func isLogin() -> Bool
    
    func userInfo() -> UserInfo?
    
    func login(_ completion: (() -> Void)?)
    
    func logout(_ completion: (() -> Void)?)
}
