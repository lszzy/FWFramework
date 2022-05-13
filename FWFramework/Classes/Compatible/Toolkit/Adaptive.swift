//
//  Adaptive.swift
//  FWFramework
//
//  Created by wuyong on 2020/9/8.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import UIKit
#if FWMacroSPM
import FWFramework
#endif

// MARK: - FW+Adaptive
extension FW {
    // MARK: - UIApplication
    /// 是否是调试模式
    public static let isDebug: Bool = UIApplication.fw.isDebug
    
    // MARK: - UIDevice
    /// 是否是模拟器
    public static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    /// 是否是iPhone设备
    public static var isIphone: Bool { return UI_USER_INTERFACE_IDIOM() == .phone }
    /// 是否是iPad设备
    public static var isIpad: Bool { return UI_USER_INTERFACE_IDIOM() == .pad }
    /// 是否是Mac设备
    public static var isMac: Bool { return UIDevice.fw.isMac }

    /// 界面是否横屏
    public static var isLandscape: Bool { return UIApplication.shared.statusBarOrientation.isLandscape }
    /// 设备是否横屏，无论支不支持横屏
    public static var isDeviceLandscape: Bool { return UIDevice.current.orientation.isLandscape }

    /// iOS系统版本
    public static var iosVersion: Double { return UIDevice.fw.iosVersion }
    /// 是否是指定iOS主版本
    public static func isIos(_ version: Int) -> Bool { return UIDevice.fw.isIos(version) }
    /// 是否是大于等于指定iOS主版本
    public static func isIosLater(_ version: Int) -> Bool { return UIDevice.fw.isIosLater(version) }

    /// 设备尺寸，跟横竖屏无关
    public static var deviceSize: CGSize { return CGSize(width: deviceWidth, height: deviceHeight) }
    /// 设备宽度，跟横竖屏无关
    public static var deviceWidth: CGFloat { return min(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height) }
    /// 设备高度，跟横竖屏无关
    public static var deviceHeight: CGFloat { return max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height) }
    /// 设备分辨率，跟横竖屏无关
    public static var deviceResolution: CGSize { return CGSize(width: deviceWidth * UIScreen.main.scale, height: deviceHeight * UIScreen.main.scale) }

    // MARK: - UIScreen
    /// 屏幕尺寸
    public static var screenSize: CGSize { return UIScreen.main.bounds.size }
    /// 屏幕宽度
    public static var screenWidth: CGFloat { return UIScreen.main.bounds.size.width }
    /// 屏幕高度
    public static var screenHeight: CGFloat { return UIScreen.main.bounds.size.height }
    /// 屏幕像素比例
    public static var screenScale: CGFloat { return UIScreen.main.scale }
    /// 判断屏幕英寸
    public static func isScreenInch(_ inch: FWScreenInch) -> Bool { return UIScreen.fw.isScreenInch(inch) }
    /// 是否是全面屏屏幕
    public static var isNotchedScreen: Bool { return UIScreen.fw.isNotchedScreen }
    /// 屏幕一像素的大小
    public static var pixelOne: CGFloat { return UIScreen.fw.pixelOne }
    /// 屏幕安全区域距离
    public static var safeAreaInsets: UIEdgeInsets { return UIScreen.fw.safeAreaInsets }

    /// 状态栏高度，与是否隐藏无关
    public static var statusBarHeight: CGFloat { return UIScreen.fw.statusBarHeight }
    /// 导航栏高度，与是否隐藏无关
    public static var navigationBarHeight: CGFloat { return UIScreen.fw.navigationBarHeight }
    /// 顶部栏高度，包含状态栏、导航栏，与是否隐藏无关
    public static var topBarHeight: CGFloat { return UIScreen.fw.topBarHeight }
    /// 标签栏高度，与是否隐藏无关
    public static var tabBarHeight: CGFloat { return UIScreen.fw.tabBarHeight }
    /// 工具栏高度，与是否隐藏无关
    public static var toolBarHeight: CGFloat { return UIScreen.fw.toolBarHeight }

    /// 当前屏幕宽度缩放比例
    public static var relativeScale: CGFloat { return UIScreen.fw.relativeScale }
    /// 当前屏幕高度缩放比例
    public static var relativeHeightScale: CGFloat { return UIScreen.fw.relativeHeightScale }

    /// 获取相对设计图宽度等比例缩放值
    public static func relativeValue(_ value: CGFloat) -> CGFloat {
        return UIScreen.fw.relativeValue(value)
    }
    /// 获取相对设计图高度等比例缩放值
    public static func relativeHeight(_ value: CGFloat) -> CGFloat {
        return UIScreen.fw.relativeHeight(value)
    }
    /// 获取相对设计图等比例缩放size
    public static func relativeValue(_ size: CGSize) -> CGSize {
        return CGSize(width: relativeValue(size.width), height: relativeValue(size.height))
    }
    /// 获取相对设计图等比例缩放point
    public static func relativeValue(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: relativeValue(point.x), y: relativeValue(point.y))
    }
    /// 获取相对设计图等比例缩放rect
    public static func relativeValue(_ rect: CGRect) -> CGRect {
        return CGRect(origin: relativeValue(rect.origin), size: relativeValue(rect.size))
    }
    /// 获取相对设计图等比例缩放insets
    public static func relativeValue(_ insets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets(top: relativeValue(insets.top), left: relativeValue(insets.left), bottom: relativeValue(insets.bottom), right: relativeValue(insets.right))
    }

    /// 基于指定的倍数(0取当前设备)，对传进来的floatValue进行像素取整
    public static func flatValue(_ value: CGFloat, scale: CGFloat = 0) -> CGFloat {
        return UIScreen.fw.flatValue(value, scale: scale)
    }
}
