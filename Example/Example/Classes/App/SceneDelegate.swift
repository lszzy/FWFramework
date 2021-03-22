//
//  SceneDelegate.swift
//  Example
//
//  Created by wuyong on 2021/3/19.
//  Copyright © 2021 site.wuyong. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
class SceneDelegate: FWSceneDelegate {
    override func setupController() {
        // iOS13使用新的方式
        window?.backgroundColor = Theme.backgroundColor
        window?.rootViewController = UITabBarController.setupController()
    }
}
