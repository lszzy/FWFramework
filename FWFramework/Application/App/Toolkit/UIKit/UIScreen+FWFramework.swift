//
//  UIScreen+FWFramework.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/28.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation

/// 屏幕尺寸
public var FWScreenSize: CGSize {
    return UIScreen.main.bounds.size
}

/// 屏幕宽度
public var FWScreenWidth: CGFloat {
    return UIScreen.main.bounds.size.width
}

/// 屏幕高度
public var FWScreenHeight: CGFloat {
    return UIScreen.main.bounds.size.height
}

/// 屏幕像素比例
public var FWScreenScale: CGFloat {
    return UIScreen.main.scale
}

/// 屏幕分辨率
public var FWScreenResolution: CGSize {
    return CGSize(width: UIScreen.main.bounds.size.width * UIScreen.main.scale, height: UIScreen.main.bounds.size.height * UIScreen.main.scale)
}

/// 判断屏幕尺寸
///
/// - Parameters:
///   - width: 屏幕宽度
///   - height: 屏幕高度
/// - Returns: 是否为该尺寸
public func FWIsScreenSize(_ width: CGFloat, _ height: CGFloat) -> Bool {
    return UIScreen.main.bounds.size.equalTo(CGSize(width: width, height: height))
}

/// 判断屏幕分辨率
///
/// - Parameters:
///   - width: 分辨率宽度
///   - height: 分辨率高度
/// - Returns: 是否为该分辨率
public func FWIsScreenResolution(_ width: CGFloat, _ height: CGFloat) -> Bool {
    return FWScreenResolution.equalTo(CGSize(width: width, height: height))
}

/// 是否是3.5英寸屏幕
public var FWIsScreen35: Bool {
    return FWIsScreenSize(320, 480)
}

/// 是否是4.0英寸屏幕
public var FWIsScreen40: Bool {
    return FWIsScreenSize(320, 568)
}

/// 是否是4.7英寸屏幕
public var FWIsScreen47: Bool {
    return FWIsScreenSize(375, 667)
}

/// 是否是5.5英寸屏幕
public var FWIsScreen55: Bool {
    return FWIsScreenSize(414, 736)
}

/// 是否是5.8英寸屏幕
public var FWIsScreen58: Bool {
    return FWIsScreenSize(375, 812)
}

/// 是否是6.1英寸屏幕
public var FWIsScreen61: Bool {
    return FWIsScreenResolution(828, 1792)
}

/// 是否是6.5英寸屏幕
public var FWIsScreen65: Bool {
    return FWIsScreenResolution(1242, 2688)
}

/// 是否是iPhoneX系列全面屏幕
public var FWIsScreenX: Bool {
    return FWIsScreenSize(375, 812) || FWIsScreenSize(414, 896)
}

/// 状态栏高度
public var FWStatusBarHeight: CGFloat {
    return FWIsScreenX ? 44.0 : 20.0
}

/// 导航栏高度
public let FWNavigationBarHeight: CGFloat = 44.0

/// 标签栏高度
public var FWTabBarHeight: CGFloat {
    return FWIsScreenX ? 83.0 : 49.0
}

/// 顶部栏高度，包含状态栏、导航栏
public var FWTopBarHeight: CGFloat {
    return FWStatusBarHeight + FWNavigationBarHeight;
}

/// 底部栏高度，包含标签栏
public var FWBottomBarHeight: CGFloat {
    return FWTabBarHeight
}
