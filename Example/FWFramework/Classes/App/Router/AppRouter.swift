//
//  AppRouter.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/5/10.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

@objcMembers class AppRouter: NSObject {
    
    static let homeUrl = "app://home"
    static let testUrl = "app://test"
    static let settingsUrl = "app://settings"
    
    static let httpUrl = "http://*"
    static let httpsUrl = "https://*"
    
}

// MARK: - Public
extension AppRouter {
    
    class func homeRouter(_ context: Router.Context) -> Any? {
        let viewController = HomeController()
        return viewController
    }
    
    class func testRouter(_ context: Router.Context) -> Any? {
        let viewController = TestController()
        return viewController
    }
    
    class func settingsRouter(_ context: Router.Context) -> Any? {
        let viewController = SettingsController()
        return viewController
    }
    
    class func httpRouter(_ context: Router.Context) -> Any? {
        return httpsRouter(context)
    }
    
    class func httpsRouter(_ context: Router.Context) -> Any? {
        let viewController = WebController(requestUrl: context.url)
        return viewController
    }
    
}
