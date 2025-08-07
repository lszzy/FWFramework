//
//  SceneDelegate.swift
//  FWFramework
//
//  Created by wuyong on 05/07/2025.
//  Copyright (c) 2025 wuyong. All rights reserved.
//

import FWFramework

class SceneDelegate: SceneResponder {
    override func setupController() {
        window?.backgroundColor = AppTheme.backgroundColor
        window?.rootViewController = TabController()
    }

    override func reloadController() {
        window?.app.addTransition(type: .init(rawValue: "oglFlip"), subtype: .fromLeft, timingFunction: .init(name: .easeInEaseOut), duration: 0.5)
        super.reloadController()
    }
}
