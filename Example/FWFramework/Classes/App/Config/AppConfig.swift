//
//  AppConfig.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/5/10.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class AppConfig: Configuration {
    
    var appId = ""
    
}

extension AppConfig {
    
    class Network {
        nonisolated(unsafe) static var apiUrl = ""
    }
    
    var network: Network.Type { Network.self }
    
}

class AppConfigTemplate: ConfigurationTemplate {
    
    override func applyConfiguration() {
        AppConfig.shared.appId = "appId"
        AppConfig.shared.network.apiUrl = "apiUrl"
    }
    
}
