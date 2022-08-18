//
//  AppConfig.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/5/10.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class AppConfig {
    
    enum Environment: Int {
        case production = 0
        case staging = 1
        case testing = 2
        case development = 3
    }
    
    static let environment: Environment = {
        #if APP_PRODUCTION
        .production
        #elseif APP_STAGING
        .staging
        #elseif APP_TESTING
        .testing
        #else
        .development
        #endif
    }()
    
}
