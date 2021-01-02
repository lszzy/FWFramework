//
//  Mediator.swift
//  Mediator
//
//  Created by lingshizhuangzi@gmail.com on 01/01/2021.
//  Copyright (c) 2021 lingshizhuangzi@gmail.com. All rights reserved.
//

import UIKit

@objc public protocol UserModuleService {
    func login(_ completion: (() -> Void)?)
}

@objc public protocol TestModuleService {
    func testViewController() -> UIViewController
}
