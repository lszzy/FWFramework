//
//  Mediator.swift
//  Mediator
//
//  Created by lingshizhuangzi@gmail.com on 01/01/2021.
//  Copyright (c) 2021 lingshizhuangzi@gmail.com. All rights reserved.
//

import FWFramework

@objcMembers public class Mediator: NSObject {
    @FWModuleAnnotation(TestModuleService.self)
    public static var testModule: TestModuleService
    
    @FWModuleAnnotation(UserModuleService.self)
    public static var userModule: UserModuleService
}
