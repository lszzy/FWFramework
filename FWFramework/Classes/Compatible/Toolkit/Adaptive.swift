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
    public static let isDebug: Bool = UIApplication.__fw.isDebug
    
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
    public static var isMac: Bool { return UIDevice.__fw.isMac }

    /// 界面是否横屏
    public static var isLandscape: Bool { return UIApplication.shared.statusBarOrientation.isLandscape }
    /// 设备是否横屏，无论支不支持横屏
    public static var isDeviceLandscape: Bool { return UIDevice.current.orientation.isLandscape }

    /// iOS系统版本
    public static var iosVersion: Double { return UIDevice.__fw.iosVersion }
    /// 是否是指定iOS主版本
    public static func isIos(_ version: Int) -> Bool { return UIDevice.__fw.isIos(version) }
    /// 是否是大于等于指定iOS主版本
    public static func isIosLater(_ version: Int) -> Bool { return UIDevice.__fw.isIosLater(version) }

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
    public static func isScreenInch(_ inch: ScreenInch) -> Bool { return UIScreen.__fw.isScreenInch(inch) }
    /// 是否是全面屏屏幕
    public static var isNotchedScreen: Bool { return UIScreen.__fw.isNotchedScreen }
    /// 屏幕一像素的大小
    public static var pixelOne: CGFloat { return UIScreen.__fw.pixelOne }
    /// 屏幕安全区域距离
    public static var safeAreaInsets: UIEdgeInsets { return UIScreen.__fw.safeAreaInsets }

    /// 状态栏高度，与是否隐藏无关
    public static var statusBarHeight: CGFloat { return UIScreen.__fw.statusBarHeight }
    /// 导航栏高度，与是否隐藏无关
    public static var navigationBarHeight: CGFloat { return UIScreen.__fw.navigationBarHeight }
    /// 顶部栏高度，包含状态栏、导航栏，与是否隐藏无关
    public static var topBarHeight: CGFloat { return UIScreen.__fw.topBarHeight }
    /// 标签栏高度，与是否隐藏无关
    public static var tabBarHeight: CGFloat { return UIScreen.__fw.tabBarHeight }
    /// 工具栏高度，与是否隐藏无关
    public static var toolBarHeight: CGFloat { return UIScreen.__fw.toolBarHeight }

    /// 当前屏幕宽度缩放比例
    public static var relativeScale: CGFloat { return UIScreen.__fw.relativeScale }
    /// 当前屏幕高度缩放比例
    public static var relativeHeightScale: CGFloat { return UIScreen.__fw.relativeHeightScale }

    /// 获取相对设计图宽度等比例缩放值
    public static func relative(_ value: CGFloat) -> CGFloat {
        return UIScreen.__fw.relativeValue(value)
    }
    /// 获取相对设计图高度等比例缩放值
    public static func relativeHeight(_ value: CGFloat) -> CGFloat {
        return UIScreen.__fw.relativeHeight(value)
    }
    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    public static func fixed(_ value: CGFloat) -> CGFloat {
        return UIScreen.__fw.fixedValue(value)
    }
    /// 获取相对设计图高度等比例缩放时的固定高度值
    public static func fixedHeight(_ value: CGFloat) -> CGFloat {
        return UIScreen.__fw.fixedHeight(value)
    }
    /// 获取相对设计图等比例缩放size
    public static func relative(_ size: CGSize) -> CGSize {
        return CGSize(width: relative(size.width), height: relative(size.height))
    }
    /// 获取相对设计图等比例缩放point
    public static func relative(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: relative(point.x), y: relative(point.y))
    }
    /// 获取相对设计图等比例缩放rect
    public static func relative(_ rect: CGRect) -> CGRect {
        return CGRect(origin: relative(rect.origin), size: relative(rect.size))
    }
    /// 获取相对设计图等比例缩放insets
    public static func relative(_ insets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets(top: relative(insets.top), left: relative(insets.left), bottom: relative(insets.bottom), right: relative(insets.right))
    }

    /// 基于指定的倍数(0取当前设备)，对传进来的floatValue进行像素取整
    public static func flat(_ value: CGFloat, scale: CGFloat = 0) -> CGFloat {
        return UIScreen.__fw.flatValue(value, scale: scale)
    }
}

// MARK: - UIApplication+Adaptive
extension Wrapper where Base: UIApplication {
    
    /// 是否是调试模式
    public static var isDebug: Bool {
        return Base.__fw.isDebug
    }
    
}

// MARK: - UIDevice+Adaptive
extension Wrapper where Base: UIDevice {
    
    /// 是否是模拟器
    public static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    /// 是否是iPhone
    public static var isIphone: Bool {
        return UI_USER_INTERFACE_IDIOM() == .phone
    }
    
    /// 是否是iPad
    public static var isIpad: Bool {
        return UI_USER_INTERFACE_IDIOM() == .pad
    }
    
    /// 是否是Mac
    public static var isMac: Bool {
        return UIDevice.__fw.isMac
    }

    /// 界面是否横屏
    public static var isLandscape: Bool {
        return UIApplication.shared.statusBarOrientation.isLandscape
    }
    
    /// 设备是否横屏，无论支不支持横屏
    public static var isDeviceLandscape: Bool {
        return UIDevice.current.orientation.isLandscape
    }
    
    /// 设置界面方向，支持旋转方向时生效
    @discardableResult
    public static func setDeviceOrientation(_ orientation: UIDeviceOrientation) -> Bool {
        return Base.__fw.setDeviceOrientation(orientation)
    }

    /// iOS系统版本
    public static var iosVersion: Double {
        return UIDevice.__fw.iosVersion
    }
    
    /// 是否是指定iOS主版本
    public static func isIos(_ version: Int) -> Bool {
        return UIDevice.__fw.isIos(version)
    }
    
    /// 是否是大于等于指定iOS主版本
    public static func isIosLater(_ version: Int) -> Bool {
        return UIDevice.__fw.isIosLater(version)
    }

    /// 设备尺寸，跟横竖屏无关
    public static var deviceSize: CGSize {
        return CGSize(width: deviceWidth, height: deviceHeight)
    }
    
    /// 设备宽度，跟横竖屏无关
    public static var deviceWidth: CGFloat {
        return min(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
    }
    
    /// 设备高度，跟横竖屏无关
    public static var deviceHeight: CGFloat {
        return max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
    }
    
    /// 设备分辨率，跟横竖屏无关
    public static var deviceResolution: CGSize {
        return CGSize(width: deviceWidth * UIScreen.main.scale, height: deviceHeight * UIScreen.main.scale)
    }
    
}

// MARK: - UIScreen+Adaptive
extension Wrapper where Base: UIScreen {
    
    /// 屏幕尺寸
    public static var screenSize: CGSize {
        return UIScreen.main.bounds.size
    }
    
    /// 屏幕宽度
    public static var screenWidth: CGFloat {
        return UIScreen.main.bounds.size.width
    }
    
    /// 屏幕高度
    public static var screenHeight: CGFloat {
        return UIScreen.main.bounds.size.height
    }
    
    /// 屏幕像素比例
    public static var screenScale: CGFloat {
        return UIScreen.main.scale
    }
    
    /// 判断屏幕英寸
    public static func isScreenInch(_ inch: ScreenInch) -> Bool {
        return UIScreen.__fw.isScreenInch(inch)
    }
    
    /// 是否是全面屏屏幕
    public static var isNotchedScreen: Bool {
        return UIScreen.__fw.isNotchedScreen
    }
    
    /// 屏幕一像素的大小
    public static var pixelOne: CGFloat {
        return UIScreen.__fw.pixelOne
    }
    
    /// 检查是否含有安全区域，可用来判断iPhoneX
    public static var hasSafeAreaInsets: Bool {
        return UIScreen.__fw.hasSafeAreaInsets
    }
    
    /// 屏幕安全区域距离
    public static var safeAreaInsets: UIEdgeInsets {
        return UIScreen.__fw.safeAreaInsets
    }

    /// 状态栏高度，与是否隐藏无关
    public static var statusBarHeight: CGFloat {
        return UIScreen.__fw.statusBarHeight
        
    }
    
    /// 导航栏高度，与是否隐藏无关
    public static var navigationBarHeight: CGFloat {
        return UIScreen.__fw.navigationBarHeight
        
    }
    
    /// 顶部栏高度，包含状态栏、导航栏，与是否隐藏无关
    public static var topBarHeight: CGFloat {
        return UIScreen.__fw.topBarHeight
        
    }
    
    /// 标签栏高度，与是否隐藏无关
    public static var tabBarHeight: CGFloat {
        return UIScreen.__fw.tabBarHeight
        
    }
    
    /// 工具栏高度，与是否隐藏无关
    public static var toolBarHeight: CGFloat {
        return UIScreen.__fw.toolBarHeight
    }

    /// 指定等比例缩放参考设计图尺寸，默认{375,812}，宽度常用
    public static var referenceSize: CGSize {
        get { return UIScreen.__fw.referenceSize }
        set { UIScreen.__fw.referenceSize = newValue }
    }
    
    /// 获取当前屏幕宽度缩放比例，宽度常用
    public static var relativeScale: CGFloat {
        return UIScreen.__fw.relativeScale
    }
    
    /// 获取当前屏幕高度缩放比例，高度不常用
    public static var relativeHeightScale: CGFloat {
        return UIScreen.__fw.relativeHeightScale
    }

    /// 获取相对设计图宽度等比例缩放值
    public static func relativeValue(_ value: CGFloat) -> CGFloat {
        return UIScreen.__fw.relativeValue(value)
    }

    /// 获取相对设计图高度等比例缩放值
    public static func relativeHeight(_ value: CGFloat) -> CGFloat {
        return UIScreen.__fw.relativeHeight(value)
    }
    
    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    public static func fixedValue(_ value: CGFloat) -> CGFloat {
        return UIScreen.__fw.fixedValue(value)
    }

    /// 获取相对设计图高度等比例缩放时的固定高度值
    public static func fixedHeight(_ value: CGFloat) -> CGFloat {
        return UIScreen.__fw.fixedHeight(value)
    }

    /// 基于指定的倍数(0取当前设备)，对传进来的floatValue进行像素取整
    public static func flatValue(_ value: CGFloat, scale: CGFloat = 0) -> CGFloat {
        return UIScreen.__fw.flatValue(value, scale: scale)
    }
    
}

// MARK: - UIViewController+Adaptive
extension Wrapper where Base: UIViewController {
    
    /// 当前状态栏布局高度，导航栏隐藏时为0，推荐使用
    public var statusBarHeight: CGFloat {
        return base.__fw.statusBarHeight
    }

    /// 当前导航栏布局高度，隐藏时为0，推荐使用
    public var navigationBarHeight: CGFloat {
        return base.__fw.navigationBarHeight
    }

    /// 当前顶部栏布局高度，导航栏隐藏时为0，推荐使用
    public var topBarHeight: CGFloat {
        return base.__fw.topBarHeight
    }

    /// 当前标签栏布局高度，隐藏时为0，推荐使用
    public var tabBarHeight: CGFloat {
        return base.__fw.tabBarHeight
    }

    /// 当前工具栏布局高度，隐藏时为0，推荐使用
    public var toolBarHeight: CGFloat {
        return base.__fw.toolBarHeight
    }

    /// 当前底部栏布局高度，包含标签栏和工具栏，隐藏时为0，推荐使用
    public var bottomBarHeight: CGFloat {
        return base.__fw.bottomBarHeight
    }
    
}
