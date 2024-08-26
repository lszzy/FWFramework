//
//  AppRouter.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/5/10.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

@MainActor class AppRouter: NSObject {
    @objc static let homeUrl = "app://home"
    @objc static let testUrl = "app://test"
    @objc static let settingsUrl = "app://settings"

    @objc static let httpUrl = "http://*"
    @objc static let httpsUrl = "https://*"
}

extension AppRouter {
    @objc static func homeRouter(_ context: Router.Context) -> Any? {
        let viewController = HomeController()
        return viewController
    }

    @objc static func testRouter(_ context: Router.Context) -> Any? {
        let viewController = TestController()
        return viewController
    }

    @objc static func settingsRouter(_ context: Router.Context) -> Any? {
        let viewController = SettingsController()
        return viewController
    }

    @objc static func httpRouter(_ context: Router.Context) -> Any? {
        httpsRouter(context)
    }

    @objc static func httpsRouter(_ context: Router.Context) -> Any? {
        let viewController = WebController(requestUrl: context.url)
        return viewController
    }
}
