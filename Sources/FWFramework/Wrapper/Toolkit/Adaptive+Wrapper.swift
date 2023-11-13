//
//  Adaptive+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

// MARK: - UIApplication+Adaptive
extension Wrapper where Base: UIApplication {
    
    /// 是否是调试模式
    public static var isDebug: Bool {
        return Base.fw_isDebug
    }
    
}

// MARK: - UIDevice+Adaptive
extension Wrapper where Base: UIDevice {
    
    /// 是否是模拟器
    public static var isSimulator: Bool {
        return Base.fw_isSimulator
    }

    /// 是否是iPhone
    public static var isIphone: Bool {
        return Base.fw_isIphone
    }
    
    /// 是否是iPad
    public static var isIpad: Bool {
        return Base.fw_isIpad
    }
    
    /// 是否是Mac
    public static var isMac: Bool {
        return Base.fw_isMac
    }

    /// 界面是否横屏
    public static var isLandscape: Bool {
        return Base.fw_isLandscape
    }
    
    /// 设备是否横屏，无论支不支持横屏
    public static var isDeviceLandscape: Bool {
        return Base.fw_isDeviceLandscape
    }
    
    /// 设置界面方向，支持旋转方向时生效
    @discardableResult
    public static func setDeviceOrientation(_ orientation: UIDeviceOrientation) -> Bool {
        return Base.fw_setDeviceOrientation(orientation)
    }

    /// iOS系统版本
    public static var iosVersion: Double {
        return Base.fw_iosVersion
    }
    
    /// 是否是指定iOS主版本
    public static func isIos(_ version: Int) -> Bool {
        return Base.fw_isIos(version)
    }
    
    /// 是否是大于等于指定iOS主版本
    public static func isIosLater(_ version: Int) -> Bool {
        return Base.fw_isIosLater(version)
    }

    /// 设备尺寸，跟横竖屏无关
    public static var deviceSize: CGSize {
        return Base.fw_deviceSize
    }
    
    /// 设备宽度，跟横竖屏无关
    public static var deviceWidth: CGFloat {
        return Base.fw_deviceWidth
    }
    
    /// 设备高度，跟横竖屏无关
    public static var deviceHeight: CGFloat {
        return Base.fw_deviceHeight
    }
    
    /// 设备分辨率，跟横竖屏无关
    public static var deviceResolution: CGSize {
        return Base.fw_deviceResolution
    }
    
}

// MARK: - UIScreen+Adaptive
extension Wrapper where Base: UIScreen {
    
    /// 屏幕尺寸
    public static var screenSize: CGSize {
        return Base.fw_screenSize
    }
    
    /// 屏幕宽度
    public static var screenWidth: CGFloat {
        return Base.fw_screenWidth
    }
    
    /// 屏幕高度
    public static var screenHeight: CGFloat {
        return Base.fw_screenHeight
    }
    
    /// 屏幕像素比例
    public static var screenScale: CGFloat {
        return Base.fw_screenScale
    }
    
    /// 判断屏幕英寸
    public static func isScreenInch(_ inch: ScreenInch) -> Bool {
        return Base.fw_isScreenInch(inch)
    }
    
    /// 是否是全面屏屏幕
    public static var isNotchedScreen: Bool {
        return Base.fw_isNotchedScreen
    }
    
    /// 是否是灵动岛屏幕
    public static var isDynamicIsland: Bool {
        return Base.fw_isDynamicIsland
    }
    
    /// 屏幕一像素的大小
    public static var pixelOne: CGFloat {
        return Base.fw_pixelOne
    }
    
    /// 检查是否含有安全区域，可用来判断iPhoneX
    public static var hasSafeAreaInsets: Bool {
        return Base.fw_hasSafeAreaInsets
    }
    
    /// 屏幕安全区域距离
    public static var safeAreaInsets: UIEdgeInsets {
        return Base.fw_safeAreaInsets
    }

    /// 状态栏高度，与是否隐藏无关
    public static var statusBarHeight: CGFloat {
        return Base.fw_statusBarHeight
    }
    
    /// 导航栏高度，与是否隐藏无关
    public static var navigationBarHeight: CGFloat {
        return Base.fw_navigationBarHeight
    }
    
    /// 顶部栏高度，包含状态栏、导航栏，与是否隐藏无关
    public static var topBarHeight: CGFloat {
        return Base.fw_topBarHeight
    }
    
    /// 标签栏高度，与是否隐藏无关
    public static var tabBarHeight: CGFloat {
        return Base.fw_tabBarHeight
    }
    
    /// 工具栏高度，与是否隐藏无关
    public static var toolBarHeight: CGFloat {
        return Base.fw_toolBarHeight
    }

    /// 指定等比例缩放参考设计图尺寸，默认{375,812}，宽度常用
    public static var referenceSize: CGSize {
        get { return Base.fw_referenceSize }
        set { Base.fw_referenceSize = newValue }
    }
    
    /// 获取当前屏幕宽度缩放比例，宽度常用
    public static var relativeScale: CGFloat {
        return Base.fw_relativeScale
    }
    
    /// 获取当前屏幕高度缩放比例，高度不常用
    public static var relativeHeightScale: CGFloat {
        return Base.fw_relativeHeightScale
    }

    /// 获取相对设计图宽度等比例缩放值
    public static func relativeValue(_ value: CGFloat, flat: Bool = false) -> CGFloat {
        return Base.fw_relativeValue(value, flat: flat)
    }

    /// 获取相对设计图高度等比例缩放值
    public static func relativeHeight(_ value: CGFloat, flat: Bool = false) -> CGFloat {
        return Base.fw_relativeHeight(value, flat: flat)
    }
    
    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    public static func fixedValue(_ value: CGFloat, flat: Bool = false) -> CGFloat {
        return Base.fw_fixedValue(value, flat: flat)
    }

    /// 获取相对设计图高度等比例缩放时的固定高度值
    public static func fixedHeight(_ value: CGFloat, flat: Bool = false) -> CGFloat {
        return Base.fw_fixedHeight(value, flat: flat)
    }

    /// 基于指定的倍数(0取当前设备)，对传进来的floatValue进行像素取整
    public static func flatValue(_ value: CGFloat, scale: CGFloat = 0) -> CGFloat {
        return Base.fw_flatValue(value, scale: scale)
    }
    
}

// MARK: - UIView+Adaptive
extension Wrapper where Base: UIView {
    
    /// 是否自动等比例缩放方式设置transform，默认NO
    public var autoScaleTransform: Bool {
        get { base.fw_autoScaleTransform }
        set { base.fw_autoScaleTransform = newValue }
    }
    
}

// MARK: - UIViewController+Adaptive
extension Wrapper where Base: UIViewController {
    
    /// 当前状态栏布局高度，导航栏隐藏时为0，推荐使用
    public var statusBarHeight: CGFloat {
        return base.fw_statusBarHeight
    }

    /// 当前导航栏布局高度，隐藏时为0，推荐使用
    public var navigationBarHeight: CGFloat {
        return base.fw_navigationBarHeight
    }

    /// 当前顶部栏布局高度，导航栏隐藏时为0，推荐使用
    public var topBarHeight: CGFloat {
        return base.fw_topBarHeight
    }

    /// 当前标签栏布局高度，隐藏时为0，推荐使用
    public var tabBarHeight: CGFloat {
        return base.fw_tabBarHeight
    }

    /// 当前工具栏布局高度，隐藏时为0，推荐使用
    public var toolBarHeight: CGFloat {
        return base.fw_toolBarHeight
    }

    /// 当前底部栏布局高度，包含标签栏和工具栏，隐藏时为0，推荐使用
    public var bottomBarHeight: CGFloat {
        return base.fw_bottomBarHeight
    }
    
}
