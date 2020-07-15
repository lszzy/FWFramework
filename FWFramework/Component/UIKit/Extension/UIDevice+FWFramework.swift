//
//  UIDevice+FWFramework.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/28.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation

#if targetEnvironment(simulator)
/// 是否是模拟器
public let FWIsSimulator: Bool = true
#else
/// 是否是模拟器
public let FWIsSimulator: Bool = false
#endif

/// 是否是iPhone设备
public var FWIsIphone: Bool {
    return UI_USER_INTERFACE_IDIOM() == .phone
}

/// 是否是iPad设备
public var FWIsIpad: Bool {
    return UI_USER_INTERFACE_IDIOM() == .pad
}

/// iOS系统版本
public var FWIosVersion: Float {
    return UIDevice.fwIosVersion()
}

/// 是否是指定iOS主版本
///
/// - Parameter version: 指定主版本号
/// - Returns: 比较结果
public func FWIsIos(_ version: Int) -> Bool {
    return UIDevice.fwIsIos(version)
}

/// 是否是大于等于指定iOS主版本
///
/// - Parameter version: 指定主版本号
/// - Returns: 比较结果
public func FWIsIosLater(_ version: Int) -> Bool {
    return UIDevice.fwIsIosLater(version)
}

/// 界面是否横屏
public var FWIsInterfaceLandscape: Bool {
    return UIApplication.shared.statusBarOrientation.isLandscape
}

/// 设备是否横屏，无论支不支持横屏
public var FWIsDeviceLandscape: Bool {
    return UIDevice.current.orientation.isLandscape
}
