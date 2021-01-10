//
//  Mediator.swift
//  Mediator
//
//  Created by lingshizhuangzi@gmail.com on 01/01/2021.
//  Copyright (c) 2021 lingshizhuangzi@gmail.com. All rights reserved.
//

import FWFramework

@objc public protocol UserModuleService: FWModuleProtocol {
    func isLogin() -> Bool
    
    func login(_ completion: (() -> Void)?)
    
    func logout(_ completion: (() -> Void)?)
}

@objc public protocol TestModuleService: FWModuleProtocol {
    func testViewController() -> UIViewController
}
