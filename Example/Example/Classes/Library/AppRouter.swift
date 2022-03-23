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
    static let homeUrl = "app://home"
    
    static let testUrl = "app://test"

}

// MARK: - Public
extension AppRouter {
    
    class func homeHandler(_ context: FWRouterContext) -> Any? {
        let viewController = HomeController()
        return viewController
    }
    
    class func testHandler(_ context: FWRouterContext) -> Any? {
        let viewController = TestController()
        FWRouter.push(viewController, animated: true)
        return nil
    }
    
}
