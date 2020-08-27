//
//  AppClipApp.swift
//  AppClip
//
//  Created by wuyong on 2020/8/19.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI

/// 如果是UIKit方式，示例代码：window.rootViewController = UIHostingController(rootView: LandmarkList())
@main
struct AppClipApp: App {
    var body: some Scene {
        WindowGroup {
            LandmarkList()
                .environmentObject(UserData())
        }
    }
}
