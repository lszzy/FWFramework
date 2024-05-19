//
//  UserModel.swift
//  FWFramework_Example
//
//  Created by wuyong on 2024/5/16.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import FWFramework

public struct UserModel: Codable, AnyArchivable {
    public var userId: String = ""
    public var userName: String = ""
    
    public init() {}
}
