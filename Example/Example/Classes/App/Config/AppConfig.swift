//
//  AppConfig.swift
//  Example
//
//  Created by wuyong on 2021/1/17.
//  Copyright © 2021 site.wuyong. All rights reserved.
//

@_exported import FWFramework
@_exported import Core
@_exported import Mediator

class AppConfig: NSObject {
    @FWUserDefaultAnnotation("isRootNavigation", defaultValue: false)
    static var isRootNavigation: Bool
    
    @FWUserDefaultAnnotation("isRootCustom", defaultValue: false)
    static var isRootCustom: Bool
    
    @FWUserDefaultAnnotation("isRootLogin", defaultValue: false)
    static var isRootLogin: Bool
}
