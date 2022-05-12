//
//  AppRouter.swift
//  Example
//
//  Created by wuyong on 2022/5/12.
//  Copyright © 2022 site.wuyong. All rights reserved.
//

import FWFramework

@objcMembers class AppRouter: NSObject {
    
    static let homeUrl = "app://home"
    static let testUrl = "app://test"
    static let settingsUrl = "app://settings"
    
}

// MARK: - Public
extension AppRouter {
    
    class func homeRouter(_ context: FWRouterContext) -> Any? {
        let viewController = HomeController()
        viewController.hidesBottomBarWhenPushed = true
        return viewController
    }
    
    class func testRouter(_ context: FWRouterContext) -> Any? {
        let viewController = TestController()
        viewController.hidesBottomBarWhenPushed = true
        if !context.isOpening { return viewController }
        
        FWRouter.push(viewController, animated: true)
        return nil
    }
    
    class func settingsRouter(_ context: FWRouterContext) -> Any? {
        let viewController = SettingsController()
        viewController.hidesBottomBarWhenPushed = true
        return viewController
    }
    
}
