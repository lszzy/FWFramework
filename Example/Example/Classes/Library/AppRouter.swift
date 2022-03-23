//
//  AppRouter.swift
//  Example
//
//  Created by wuyong on 2022/3/23.
//  Copyright © 2022 site.wuyong. All rights reserved.
//

import UIKit
import FWFramework

@objcMembers class AppRouter: NSObject {
    
    // MARK: - Accessor
    static let routeHome = "app://home"
    
    static let routeTest = "app://test"

}

// MARK: - Public
extension AppRouter {
    
    class func routeHomeHandler(_ context: FWRouterContext) -> Any? {
        let viewController = HomeController()
        return viewController
    }
    
    class func routeTestHandler(_ context: FWRouterContext) -> Any? {
        let viewController = TestController()
        FWRouter.push(viewController, animated: true)
        return nil
    }
    
}

// MARK: - FWAutoloader
@objc private extension FWAutoloader {
    
    func loadAppRouter() {
        FWRouter.registerClass(AppRouter.self)
    }
    
}
