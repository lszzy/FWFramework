//
//  FWAdaptive.swift
//  FWFramework
//
//  Created by wuyong on 2020/9/8.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import UIKit

// MARK: - UIApplication+FWAdaptive

/// 是否是调试模式
public let FWIsDebug: Bool = UIApplication.fwIsDebug()

// MARK: - UIDevice+FWAdaptive

#if targetEnvironment(simulator)
/// 是否是模拟器
public let FWIsSimulator: Bool = true
#else
/// 是否是模拟器
public let FWIsSimulator: Bool = false
#endif

/// 是否是iPhone设备
public var FWIsIphone: Bool { return UI_USER_INTERFACE_IDIOM() == .phone }
/// 是否是iPad设备
public var FWIsIpad: Bool { return UI_USER_INTERFACE_IDIOM() == .pad }
/// 是否是Mac设备
public var FWIsMac: Bool { return UIDevice.fwIsMac() }

/// 界面是否横屏
public var FWIsLandscape: Bool { return UIApplication.shared.statusBarOrientation.isLandscape }
/// 设备是否横屏，无论支不支持横屏
public var FWIsDeviceLandscape: Bool { return UIDevice.current.orientation.isLandscape }

/// iOS系统版本
public var FWIosVersion: Double { return UIDevice.fwIosVersion() }
/// 是否是指定iOS主版本
public func FWIsIos(_ version: Int) -> Bool { return UIDevice.fwIsIos(version) }
/// 是否是大于等于指定iOS主版本
public func FWIsIosLater(_ version: Int) -> Bool { return UIDevice.fwIsIosLater(version) }

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
public func FWIsScreenInch(_ inch: FWScreenInch) -> Bool { return UIScreen.fwIsScreenInch(inch) }
/// 是否是iPhoneX系列全面屏幕
public var FWIsScreenX: Bool { return UIScreen.fwIsScreenX() }

/// 状态栏高度
public var FWStatusBarHeight: CGFloat { return UIScreen.fwStatusBarHeight() }
/// 导航栏高度
public var FWNavigationBarHeight: CGFloat { return UIScreen.fwNavigationBarHeight() }
/// 标签栏高度
public var FWTabBarHeight: CGFloat { return UIScreen.fwTabBarHeight() }
/// 工具栏高度
public var FWToolBarHeight: CGFloat { return UIScreen.fwToolBarHeight() }
/// 顶部栏高度，包含状态栏、导航栏
public var FWTopBarHeight: CGFloat { return UIScreen.fwTopBarHeight() }
/// 底部栏高度，包含标签栏
public var FWBottomBarHeight: CGFloat { return UIScreen.fwBottomBarHeight() }

/// 当前屏幕宽度缩放比例
public var FWScaleFactorWidth: CGFloat { return UIScreen.fwScaleFactorWidth() }
/// 当前屏幕高度缩放比例
public var FWScaleFactorHeight: CGFloat { return UIScreen.fwScaleFactorHeight() }
