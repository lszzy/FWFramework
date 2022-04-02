//
//  FWAdaptive.swift
//  FWFramework
//
//  Created by wuyong on 2020/9/8.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import UIKit
#if FWFrameworkSPM
import FWFramework
#endif

// MARK: - UIApplication+FWAdaptive

/// 是否是调试模式
public let FWIsDebug: Bool = UIApplication.fw.isDebug

// MARK: - UIDevice+FWAdaptive

/// 是否是模拟器
public var FWIsSimulator: Bool {
    #if targetEnvironment(simulator)
    return true
    #else
    return false
    #endif
}

/// 是否是iPhone设备
public var FWIsIphone: Bool { return UI_USER_INTERFACE_IDIOM() == .phone }
/// 是否是iPad设备
public var FWIsIpad: Bool { return UI_USER_INTERFACE_IDIOM() == .pad }
/// 是否是Mac设备
public var FWIsMac: Bool { return UIDevice.fw.isMac }

/// 界面是否横屏
public var FWIsLandscape: Bool { return UIApplication.shared.statusBarOrientation.isLandscape }
/// 设备是否横屏，无论支不支持横屏
public var FWIsDeviceLandscape: Bool { return UIDevice.current.orientation.isLandscape }

/// iOS系统版本
public var FWIosVersion: Double { return UIDevice.fw.iosVersion }
/// 是否是指定iOS主版本
public func FWIsIos(_ version: Int) -> Bool { return UIDevice.fw.isIos(version) }
/// 是否是大于等于指定iOS主版本
public func FWIsIosLater(_ version: Int) -> Bool { return UIDevice.fw.isIosLater(version) }

/// 设备尺寸，跟横竖屏无关
public var FWDeviceSize: CGSize { return CGSize(width: FWDeviceWidth, height: FWDeviceHeight) }
/// 设备宽度，跟横竖屏无关
public var FWDeviceWidth: CGFloat { return min(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height) }
/// 设备高度，跟横竖屏无关
public var FWDeviceHeight: CGFloat { return max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height) }
/// 设备分辨率，跟横竖屏无关
public var FWDeviceResolution: CGSize { return CGSize(width: FWDeviceWidth * UIScreen.main.scale, height: FWDeviceHeight * UIScreen.main.scale) }

// MARK: - UIScreen+FWAdaptive

/// 屏幕尺寸
public var FWScreenSize: CGSize { return UIScreen.main.bounds.size }
/// 屏幕宽度
public var FWScreenWidth: CGFloat { return UIScreen.main.bounds.size.width }
/// 屏幕高度
public var FWScreenHeight: CGFloat { return UIScreen.main.bounds.size.height }
/// 屏幕像素比例
public var FWScreenScale: CGFloat { return UIScreen.main.scale }
/// 判断屏幕英寸
public func FWIsScreenInch(_ inch: FWScreenInch) -> Bool { return UIScreen.fw.isScreenInch(inch) }
/// 是否是全面屏屏幕
public var FWIsNotchedScreen: Bool { return UIScreen.fw.isNotchedScreen }
/// 屏幕一像素的大小
public var FWPixelOne: CGFloat { return UIScreen.fw.pixelOne }
/// 屏幕安全区域距离
public var FWSafeAreaInsets: UIEdgeInsets { return UIScreen.fw.safeAreaInsets }

/// 状态栏高度，与是否隐藏无关
public var FWStatusBarHeight: CGFloat { return UIScreen.fw.statusBarHeight }
/// 导航栏高度，与是否隐藏无关
public var FWNavigationBarHeight: CGFloat { return UIScreen.fw.navigationBarHeight }
/// 顶部栏高度，包含状态栏、导航栏，与是否隐藏无关
public var FWTopBarHeight: CGFloat { return UIScreen.fw.topBarHeight }
/// 标签栏高度，与是否隐藏无关
public var FWTabBarHeight: CGFloat { return UIScreen.fw.tabBarHeight }
/// 工具栏高度，与是否隐藏无关
public var FWToolBarHeight: CGFloat { return UIScreen.fw.toolBarHeight }

/// 当前屏幕宽度缩放比例
public var FWRelativeScale: CGFloat { return UIScreen.fw.relativeScale }
/// 当前屏幕高度缩放比例
public var FWRelativeHeightScale: CGFloat { return UIScreen.fw.relativeHeightScale }

/// 获取相对设计图宽度等比例缩放值
public func FWRelativeValue(_ value: CGFloat) -> CGFloat {
    return UIScreen.fw.relativeValue(value)
}
/// 获取相对设计图高度等比例缩放值
public func FWRelativeHeight(_ value: CGFloat) -> CGFloat {
    return UIScreen.fw.relativeHeight(value)
}
/// 获取相对设计图等比例缩放size
public func FWRelativeValue(_ size: CGSize) -> CGSize {
    return CGSize(width: FWRelativeValue(size.width), height: FWRelativeValue(size.height))
}
/// 获取相对设计图等比例缩放point
public func FWRelativeValue(_ point: CGPoint) -> CGPoint {
    return CGPoint(x: FWRelativeValue(point.x), y: FWRelativeValue(point.y))
}
/// 获取相对设计图等比例缩放rect
public func FWRelativeValue(_ rect: CGRect) -> CGRect {
    return CGRect(origin: FWRelativeValue(rect.origin), size: FWRelativeValue(rect.size))
}
/// 获取相对设计图等比例缩放insets
public func FWRelativeValue(_ insets: UIEdgeInsets) -> UIEdgeInsets {
    return UIEdgeInsets(top: FWRelativeValue(insets.top), left: FWRelativeValue(insets.left), bottom: FWRelativeValue(insets.bottom), right: FWRelativeValue(insets.right))
}
