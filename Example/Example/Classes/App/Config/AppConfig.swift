//
//  AppConfig.swift
//  Example
//
//  Created by wuyong on 2022/5/12.
//  Copyright © 2022 site.wuyong. All rights reserved.
//

import UIKit

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