//
//  AppRouter.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/5/10.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation

class AppRouter {
    
    static let homeUrl = "app://home"
    static let testUrl = "app://test"
    static let settingsUrl = "app://settings"
    
}

// MARK: - Public
extension AppRouter {
    
    class func homeRouter() -> Any? {
        let viewController = HomeController()
        return viewController
    }
    
    class func testRouter() -> Any? {
        let viewController = TestController()
        return viewController
    }
    
    class func settingsRouter() -> Any? {
        let viewController = SettingsController()
        return viewController
    }
    
}
