//
//  AppConfig.swift
//  Example
//
//  Created by wuyong on 2021/1/17.
//  Copyright © 2021 site.wuyong. All rights reserved.
//

import Foundation

@objcMembers class AppConfig: NSObject {
    @FWUserDefaultAnnotation("rootNavBar", defaultValue: false)
    static var rootNavBar: Bool
}
