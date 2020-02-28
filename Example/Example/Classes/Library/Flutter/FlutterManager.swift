//
//  FlutterManager.swift
//  Example2
//
//  Created by wuyong on 2020/2/29.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import Foundation
import Flutter
import FlutterPluginRegistrant

@objcMembers class FlutterManager: NSObject {
    static let sharedInstance = FlutterManager()
    
    lazy var flutterEngine = FlutterEngine(name: "example engine")
    
    func run() {
        flutterEngine.run()
        GeneratedPluginRegistrant.register(with: self.flutterEngine)
    }
    
    func present() {
        let flutterController = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
        FWRouter.present(flutterController, animated: true, completion: nil)
    }
}
