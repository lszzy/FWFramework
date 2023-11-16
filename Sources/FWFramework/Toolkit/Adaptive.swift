//
//  Adaptive.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

// MARK: - WrapperGlobal+Adaptive
extension WrapperGlobal {
    
    // MARK: - UIApplication
    /// 是否是调试模式
    public static var isDebug: Bool { UIApplication.fw_isDebug }
    
    // MARK: - UIDevice
    /// 是否是模拟器
    public static var isSimulator: Bool { UIDevice.fw_isSimulator }

    /// 是否是iPhone设备
    public static var isIphone: Bool { UIDevice.fw_isIphone }
    /// 是否是iPad设备
    public static var isIpad: Bool { UIDevice.fw_isIpad }
    /// 是否是Mac设备
    public static var isMac: Bool { UIDevice.fw_isMac }

    /// 界面是否横屏
    public static var isLandscape: Bool { UIDevice.fw_isLandscape }
    /// 设备是否横屏，无论支不支持横屏
    public static var isDeviceLandscape: Bool { UIDevice.fw_isDeviceLandscape }

    /// iOS系统版本
    public static var iosVersion: Double { UIDevice.fw_iosVersion }
    /// 是否是指定iOS主版本
    public static func isIos(_ version: Int) -> Bool { UIDevice.fw_isIos(version) }
    /// 是否是大于等于指定iOS主版本
    public static func isIosLater(_ version: Int) -> Bool { UIDevice.fw_isIosLater(version) }

    /// 设备尺寸，跟横竖屏无关
    public static var deviceSize: CGSize { UIDevice.fw_deviceSize }
    /// 设备宽度，跟横竖屏无关
    public static var deviceWidth: CGFloat { UIDevice.fw_deviceWidth }
    /// 设备高度，跟横竖屏无关
    public static var deviceHeight: CGFloat { UIDevice.fw_deviceHeight }
    /// 设备分辨率，跟横竖屏无关
    public static var deviceResolution: CGSize { UIDevice.fw_deviceResolution }

    // MARK: - UIScreen
    /// 屏幕尺寸
    public static var screenSize: CGSize { UIScreen.fw_screenSize }
    /// 屏幕宽度
    public static var screenWidth: CGFloat { UIScreen.fw_screenWidth }
    /// 屏幕高度
    public static var screenHeight: CGFloat { UIScreen.fw_screenHeight }
    /// 屏幕像素比例
    public static var screenScale: CGFloat { UIScreen.fw_screenScale }
    /// 判断屏幕英寸
    public static func isScreenInch(_ inch: ScreenInch) -> Bool { UIScreen.fw_isScreenInch(inch) }
    /// 是否是全面屏屏幕
    public static var isNotchedScreen: Bool { UIScreen.fw_isNotchedScreen }
    /// 是否是灵动岛屏幕
    public static var isDynamicIsland: Bool { UIScreen.fw_isDynamicIsland }
    /// 屏幕一像素的大小
    public static var pixelOne: CGFloat { UIScreen.fw_pixelOne }
    /// 屏幕安全区域距离
    public static var safeAreaInsets: UIEdgeInsets { UIScreen.fw_safeAreaInsets }

    /// 状态栏高度，与是否隐藏无关
    public static var statusBarHeight: CGFloat { UIScreen.fw_statusBarHeight }
    /// 导航栏高度，与是否隐藏无关
    public static var navigationBarHeight: CGFloat { UIScreen.fw_navigationBarHeight }
    /// 顶部栏高度，包含状态栏、导航栏，与是否隐藏无关
    public static var topBarHeight: CGFloat { UIScreen.fw_topBarHeight }
    /// 标签栏高度，与是否隐藏无关
    public static var tabBarHeight: CGFloat { UIScreen.fw_tabBarHeight }
    /// 工具栏高度，与是否隐藏无关
    public static var toolBarHeight: CGFloat { UIScreen.fw_toolBarHeight }

    /// 当前等比例缩放参考设计图宽度，默认375
    public static var referenceWidth: CGFloat { UIScreen.fw_referenceSize.width }
    /// 当前等比例缩放参考设计图高度，默认812
    public static var referenceHeight: CGFloat { UIScreen.fw_referenceSize.height }
    /// 当前屏幕宽度缩放比例
    public static var relativeScale: CGFloat { UIScreen.fw_relativeScale }
    /// 当前屏幕高度缩放比例
    public static var relativeHeightScale: CGFloat { UIScreen.fw_relativeHeightScale }

    /// 获取相对设计图宽度等比例缩放值
    public static func relative(_ value: CGFloat, flat: Bool = false) -> CGFloat {
        return UIScreen.fw_relativeValue(value, flat: flat)
    }
    /// 获取相对设计图等比例缩放size
    public static func relative(_ size: CGSize, flat: Bool = false) -> CGSize {
        return CGSize(width: relative(size.width, flat: flat), height: relative(size.height, flat: flat))
    }
    /// 获取相对设计图等比例缩放point
    public static func relative(_ point: CGPoint, flat: Bool = false) -> CGPoint {
        return CGPoint(x: relative(point.x, flat: flat), y: relative(point.y, flat: flat))
    }
    /// 获取相对设计图等比例缩放rect
    public static func relative(_ rect: CGRect, flat: Bool = false) -> CGRect {
        return CGRect(origin: relative(rect.origin, flat: flat), size: relative(rect.size, flat: flat))
    }
    /// 获取相对设计图等比例缩放insets
    public static func relative(_ insets: UIEdgeInsets, flat: Bool = false) -> UIEdgeInsets {
        return UIEdgeInsets(top: relative(insets.top, flat: flat), left: relative(insets.left, flat: flat), bottom: relative(insets.bottom, flat: flat), right: relative(insets.right, flat: flat))
    }
    
    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    public static func fixed(_ value: CGFloat, flat: Bool = false) -> CGFloat {
        return UIScreen.fw_fixedValue(value, flat: flat)
    }
    /// 获取相对设计图等比例缩放时的固定size
    public static func fixed(_ size: CGSize, flat: Bool = false) -> CGSize {
        return CGSize(width: fixed(size.width, flat: flat), height: fixed(size.height, flat: flat))
    }
    /// 获取相对设计图等比例缩放时的固定point
    public static func fixed(_ point: CGPoint, flat: Bool = false) -> CGPoint {
        return CGPoint(x: fixed(point.x, flat: flat), y: fixed(point.y, flat: flat))
    }
    /// 获取相对设计图等比例缩放时的固定rect
    public static func fixed(_ rect: CGRect, flat: Bool = false) -> CGRect {
        return CGRect(origin: fixed(rect.origin, flat: flat), size: fixed(rect.size, flat: flat))
    }
    /// 获取相对设计图等比例缩放时的固定insets
    public static func fixed(_ insets: UIEdgeInsets, flat: Bool = false) -> UIEdgeInsets {
        return UIEdgeInsets(top: fixed(insets.top, flat: flat), left: fixed(insets.left, flat: flat), bottom: fixed(insets.bottom, flat: flat), right: fixed(insets.right, flat: flat))
    }
    
    /// 获取相对设计图高度等比例缩放值
    public static func relativeHeight(_ value: CGFloat, flat: Bool = false) -> CGFloat {
        return UIScreen.fw_relativeHeight(value, flat: flat)
    }
    /// 获取相对设计图高度等比例缩放时的固定高度值
    public static func fixedHeight(_ value: CGFloat, flat: Bool = false) -> CGFloat {
        return UIScreen.fw_fixedHeight(value, flat: flat)
    }

    /// 基于指定的倍数(0取当前设备)，对传进来的floatValue进行像素取整
    public static func flat(_ value: CGFloat, scale: CGFloat = 0) -> CGFloat {
        return UIScreen.fw_flatValue(value, scale: scale)
    }
    /// 基于指定的倍数(0取当前设备)，对传进来的size进行像素取整
    public static func flat(_ size: CGSize, scale: CGFloat = 0) -> CGSize {
        return CGSize(width: flat(size.width, scale: scale), height: flat(size.height, scale: scale))
    }
    /// 基于指定的倍数(0取当前设备)，对传进来的point进行像素取整
    public static func flat(_ point: CGPoint, scale: CGFloat = 0) -> CGPoint {
        return CGPoint(x: flat(point.x, scale: scale), y: flat(point.y, scale: scale))
    }
    /// 基于指定的倍数(0取当前设备)，对传进来的rect进行像素取整
    public static func flat(_ rect: CGRect, scale: CGFloat = 0) -> CGRect {
        return CGRect(origin: flat(rect.origin, scale: scale), size: flat(rect.size, scale: scale))
    }
    /// 基于指定的倍数(0取当前设备)，对传进来的insets进行像素取整
    public static func flat(_ insets: UIEdgeInsets, scale: CGFloat = 0) -> UIEdgeInsets {
        return UIEdgeInsets(top: flat(insets.top, scale: scale), left: flat(insets.left, scale: scale), bottom: flat(insets.bottom, scale: scale), right: flat(insets.right, scale: scale))
    }
    
}

// MARK: - UIApplication+Adaptive
@_spi(FW) extension UIApplication {
    
    /// 是否是调试模式
    public static var fw_isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
}

// MARK: - UIDevice+Adaptive
@_spi(FW) extension UIDevice {
    
    /// 是否是模拟器
    public static var fw_isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    /// 是否是iPhone
    public static var fw_isIphone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    
    /// 是否是iPad
    public static var fw_isIpad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    /// 是否是Mac
    public static var fw_isMac: Bool {
        if #available(iOS 14.0, *) {
            return ProcessInfo.processInfo.isiOSAppOnMac ||
                ProcessInfo.processInfo.isMacCatalystApp
        }
        return false
    }

    /// 界面是否横屏
    public static var fw_isLandscape: Bool {
        return UIApplication.shared.statusBarOrientation.isLandscape
    }
    
    /// 设备是否横屏，无论支不支持横屏
    public static var fw_isDeviceLandscape: Bool {
        return UIDevice.current.orientation.isLandscape
    }
    
    /// 设置界面方向，支持旋转方向时生效
    @discardableResult
    public static func fw_setDeviceOrientation(_ orientation: UIDeviceOrientation) -> Bool {
        if UIDevice.current.orientation == orientation {
            UIViewController.attemptRotationToDeviceOrientation()
            return false
        }
        
        if #available(iOS 16.0, *) {
            var orientationMask: UIInterfaceOrientationMask = []
            switch orientation {
            case .portrait:
                orientationMask = .portrait
            case .portraitUpsideDown:
                orientationMask = .portraitUpsideDown
            case .landscapeLeft:
                orientationMask = .landscapeLeft
            case .landscapeRight:
                orientationMask = .landscapeRight
            default:
                break
            }
            
            UIWindow.fw_mainScene?.requestGeometryUpdate(.iOS(interfaceOrientations: orientationMask))
            return true
        }
        
        UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        return true
    }

    /// iOS系统版本
    public static var fw_iosVersion: Double {
        return (UIDevice.current.systemVersion as NSString).doubleValue
    }
    
    /// 是否是指定iOS主版本
    public static func fw_isIos(_ version: Int) -> Bool {
        return fw_iosVersion >= Double(version) && fw_iosVersion < Double(version + 1)
    }
    
    /// 是否是大于等于指定iOS主版本
    public static func fw_isIosLater(_ version: Int) -> Bool {
        return fw_iosVersion >= Double(version)
    }

    /// 设备尺寸，跟横竖屏无关
    public static var fw_deviceSize: CGSize {
        return CGSize(width: fw_deviceWidth, height: fw_deviceHeight)
    }
    
    /// 设备宽度，跟横竖屏无关
    public static var fw_deviceWidth: CGFloat {
        return min(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
    }
    
    /// 设备高度，跟横竖屏无关
    public static var fw_deviceHeight: CGFloat {
        return max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
    }
    
    /// 设备分辨率，跟横竖屏无关
    public static var fw_deviceResolution: CGSize {
        return CGSize(width: fw_deviceWidth * UIScreen.main.scale, height: fw_deviceHeight * UIScreen.main.scale)
    }
    
}

// MARK: - UIScreen+Adaptive
/// 可扩展屏幕尺寸
public struct ScreenInch: RawRepresentable, Equatable, Hashable {
    
    public typealias RawValue = Int
    
    public static let inch35: ScreenInch = .init(35)
    public static let inch40: ScreenInch = .init(40)
    public static let inch47: ScreenInch = .init(47)
    public static let inch54: ScreenInch = .init(54)
    public static let inch55: ScreenInch = .init(55)
    public static let inch58: ScreenInch = .init(58)
    public static let inch61: ScreenInch = .init(61)
    public static let inch65: ScreenInch = .init(65)
    public static let inch67: ScreenInch = .init(67)
    
    public var rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public init(_ rawValue: Int) {
        self.rawValue = rawValue
    }
    
}

@_spi(FW) extension UIScreen {
    
    /// 屏幕尺寸
    public static var fw_screenSize: CGSize {
        return UIScreen.main.bounds.size
    }
    
    /// 屏幕宽度
    public static var fw_screenWidth: CGFloat {
        return UIScreen.main.bounds.size.width
    }
    
    /// 屏幕高度
    public static var fw_screenHeight: CGFloat {
        return UIScreen.main.bounds.size.height
    }
    
    /// 屏幕像素比例
    public static var fw_screenScale: CGFloat {
        return UIScreen.main.scale
    }
    
    /// 判断屏幕英寸
    public static func fw_isScreenInch(_ inch: ScreenInch) -> Bool {
        switch inch {
        case .inch35:
            return UIDevice.fw_deviceSize.equalTo(CGSize(width: 320, height: 480))
        case .inch40:
            return UIDevice.fw_deviceSize.equalTo(CGSize(width: 320, height: 568))
        case .inch47:
            return UIDevice.fw_deviceSize.equalTo(CGSize(width: 375, height: 667))
        case .inch54:
            return UIDevice.fw_deviceSize.equalTo(CGSize(width: 360, height: 780))
        case .inch55:
            return UIDevice.fw_deviceSize.equalTo(CGSize(width: 414, height: 736))
        case .inch58:
            return UIDevice.fw_deviceSize.equalTo(CGSize(width: 375, height: 812))
        case .inch61:
            return (UIDevice.fw_deviceSize.equalTo(CGSize(width: 414, height: 896)) && (UIDevice.fw_deviceModel == "iPhone11,8" || UIDevice.fw_deviceModel == "iPhone12,1")) ||
                UIDevice.fw_deviceSize.equalTo(CGSize(width: 390, height: 844))
        case .inch65:
            return UIDevice.fw_deviceSize.equalTo(CGSize(width: 414, height: 896)) && !fw_isScreenInch(.inch61)
        case .inch67:
            return UIDevice.fw_deviceSize.equalTo(CGSize(width: 428, height: 926)) ||
                UIDevice.fw_deviceSize.equalTo(CGSize(width: 430, height: 932))
        default:
            return false
        }
    }
    
    /// 是否是全面屏屏幕
    public static var fw_isNotchedScreen: Bool {
        return fw_safeAreaInsets.bottom > 0
    }
    
    /// 是否是灵动岛屏幕
    public static var fw_isDynamicIsland: Bool {
        guard UIDevice.fw_isIphone else { return false }
        if UIScreen.main.bounds.height > UIScreen.main.bounds.width {
            return fw_safeAreaInsets.top >= 59.0
        } else {
            return fw_safeAreaInsets.left >= 59.0
        }
    }
    
    /// 屏幕一像素的大小
    public static var fw_pixelOne: CGFloat {
        return 1.0 / UIScreen.main.scale
    }
    
    /// 检查是否含有安全区域，可用来判断iPhoneX
    public static var fw_hasSafeAreaInsets: Bool {
        return fw_safeAreaInsets.bottom > 0
    }
    
    /// 屏幕安全区域距离
    @objc(__fw_safeAreaInsets)
    public static var fw_safeAreaInsets: UIEdgeInsets {
        var mainWindow = UIWindow.fw_mainWindow
        if mainWindow != nil {
            if UIScreen.fw_staticWindow != nil { UIScreen.fw_staticWindow = nil }
        } else {
            if UIScreen.fw_staticWindow == nil { UIScreen.fw_staticWindow = UIWindow(frame: UIScreen.main.bounds) }
            mainWindow = UIScreen.fw_staticWindow
        }
        return mainWindow?.safeAreaInsets ?? .zero
    }
    
    private static var fw_staticWindow: UIWindow?

    /// 状态栏高度，与是否隐藏无关
    @objc(__fw_statusBarHeight)
    public static var fw_statusBarHeight: CGFloat {
        if !UIApplication.shared.isStatusBarHidden {
            return UIApplication.shared.statusBarFrame.height
        }
        
        if UIDevice.fw_isIpad {
            return fw_isNotchedScreen ? 24 : 20
        }
        
        if UIDevice.fw_isLandscape { return 0 }
        if !fw_isNotchedScreen { return 20 }
        if fw_isDynamicIsland { return 54 }
        if UIDevice.fw_deviceModel == "iPhone12,1" { return 48 }
        if UIDevice.fw_deviceSize.equalTo(CGSize(width: 390, height: 844)) { return 47 }
        if fw_isScreenInch(.inch67) { return 47 }
        if fw_isScreenInch(.inch54) && UIDevice.fw_iosVersion >= 15.0 { return 50 }
        return 44
    }
    
    /// 导航栏高度，与是否隐藏无关
    @objc(__fw_navigationBarHeight)
    public static var fw_navigationBarHeight: CGFloat {
        if UIDevice.fw_isIpad {
            return UIDevice.fw_iosVersion >= 12.0 ? 50 : 44
        }
        
        var height: CGFloat = 44
        if UIDevice.fw_isLandscape {
            height = fw_isRegularScreen ? 44 : 32
        }
        return height
    }
    
    /// 顶部栏高度，包含状态栏、导航栏，与是否隐藏无关
    @objc(__fw_topBarHeight)
    public static var fw_topBarHeight: CGFloat {
        return fw_statusBarHeight + fw_navigationBarHeight
    }
    
    /// 标签栏高度，与是否隐藏无关
    @objc(__fw_tabBarHeight)
    public static var fw_tabBarHeight: CGFloat {
        if UIDevice.fw_isIpad {
            if fw_isNotchedScreen { return 65 }
            return UIDevice.fw_iosVersion >= 12.0 ? 50 : 49
        }
        
        var height: CGFloat = 49
        if UIDevice.fw_isLandscape {
            height = fw_isRegularScreen ? 49 : 32
        }
        return height + fw_safeAreaInsets.bottom
    }
    
    /// 工具栏高度，与是否隐藏无关
    @objc(__fw_toolBarHeight)
    public static var fw_toolBarHeight: CGFloat {
        if UIDevice.fw_isIpad {
            if fw_isNotchedScreen { return 70 }
            return UIDevice.fw_iosVersion >= 12.0 ? 50 : 44
        }
        
        var height: CGFloat = 44
        if UIDevice.fw_isLandscape {
            height = fw_isRegularScreen ? 44 : 32
        }
        return height + fw_safeAreaInsets.bottom
    }
    
    private static var fw_isRegularScreen: Bool {
        // https://github.com/Tencent/QMUI_iOS
        if UIDevice.fw_isIpad { return true }
        
        var isZoomedMode = false
        if UIDevice.fw_isIphone {
            let nativeScale = UIScreen.main.nativeScale
            var scale = UIScreen.main.scale
            if CGSize(width: 1080, height: 1920).equalTo(UIScreen.main.nativeBounds.size) {
                scale /= 1.15
            }
            isZoomedMode = nativeScale > scale
        }
        if isZoomedMode { return false }
        
        if fw_isScreenInch(.inch67) || fw_isScreenInch(.inch65) || fw_isScreenInch(.inch55) { return true }
        if UIDevice.fw_deviceSize.equalTo(CGSize(width: 414, height: 896)) && (UIDevice.fw_deviceModel == "iPhone11,8" || UIDevice.fw_deviceModel == "iPhone12,1") { return true }
        return false
    }

    /// 指定等比例缩放参考设计图尺寸，默认{375,812}，宽度常用
    public static var fw_referenceSize: CGSize = CGSize(width: 375, height: 812)
    
    /// 获取当前屏幕宽度缩放比例，宽度常用
    public static var fw_relativeScale: CGFloat {
        if UIScreen.main.bounds.height > UIScreen.main.bounds.width {
            return UIScreen.main.bounds.width / UIScreen.fw_referenceSize.width
        } else {
            return UIScreen.main.bounds.width / UIScreen.fw_referenceSize.height
        }
    }
    
    /// 获取当前屏幕高度缩放比例，高度不常用
    public static var fw_relativeHeightScale: CGFloat {
        if UIScreen.main.bounds.height > UIScreen.main.bounds.width {
            return UIScreen.main.bounds.height / UIScreen.fw_referenceSize.height
        } else {
            return UIScreen.main.bounds.height / UIScreen.fw_referenceSize.width
        }
    }

    /// 获取相对设计图宽度等比例缩放值
    public static func fw_relativeValue(_ value: CGFloat, flat: Bool = false) -> CGFloat {
        let result = value * fw_relativeScale
        return flat ? UIScreen.fw_flatValue(result) : result
    }

    /// 获取相对设计图高度等比例缩放值
    public static func fw_relativeHeight(_ value: CGFloat, flat: Bool = false) -> CGFloat {
        let result = value * fw_relativeHeightScale
        return flat ? UIScreen.fw_flatValue(result) : result
    }
    
    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    public static func fw_fixedValue(_ value: CGFloat, flat: Bool = false) -> CGFloat {
        let result = value / fw_relativeScale
        return flat ? UIScreen.fw_flatValue(result) : result
    }

    /// 获取相对设计图高度等比例缩放时的固定高度值
    public static func fw_fixedHeight(_ value: CGFloat, flat: Bool = false) -> CGFloat {
        let result = value / fw_relativeHeightScale
        return flat ? UIScreen.fw_flatValue(result) : result
    }

    /// 基于指定的倍数(0取当前设备)，对传进来的floatValue进行像素取整
    @objc(__fw_flatValue:scale:)
    public static func fw_flatValue(_ value: CGFloat, scale: CGFloat = 0) -> CGFloat {
        let floatValue: CGFloat = (value == .leastNonzeroMagnitude || value == .leastNormalMagnitude) ? 0 : value
        let scaleValue: CGFloat = scale > 0 ? scale : UIScreen.main.scale
        return ceil(floatValue * scaleValue) / scaleValue
    }
    
}

// MARK: - UIView+Adaptive
@_spi(FW) extension UIView {
    
    /// 是否自动等比例缩放方式设置transform，默认NO
    public var fw_autoScaleTransform: Bool {
        get {
            return fw_propertyBool(forName: "fw_autoScaleTransform")
        }
        set {
            fw_setPropertyBool(newValue, forName: "fw_autoScaleTransform")
            if newValue {
                let scaleX = UIScreen.fw_relativeScale
                let scaleY = UIScreen.fw_relativeHeightScale
                let scale = scaleX > scaleY ? scaleY : scaleX
                self.transform = .init(scaleX: scale, y: scale)
            } else {
                self.transform = .identity
            }
        }
    }
    
}

// MARK: - UIViewController+Adaptive
@_spi(FW) extension UIViewController {
    
    /// 当前状态栏布局高度，导航栏隐藏时为0，推荐使用
    public var fw_statusBarHeight: CGFloat {
        // 1. 导航栏隐藏时不占用布局高度始终为0
        guard let navController = self.navigationController,
              !navController.isNavigationBarHidden else { return 0 }
        
        // 2. 竖屏且为iOS13+弹出pageSheet样式时布局高度为0
        let isPortrait = !UIDevice.fw_isLandscape
        if isPortrait && fw_isPageSheet { return 0 }
        
        // 3. 竖屏且异形屏，导航栏显示时布局高度固定
        if isPortrait && UIScreen.fw_isNotchedScreen {
            // 也可以这样计算：navController.navigationBar.frame.minY
            return UIScreen.fw_statusBarHeight
        }
        
        // 4. 其他情况状态栏显示时布局高度固定，隐藏时布局高度为0
        if UIApplication.shared.isStatusBarHidden { return 0 }
        return UIApplication.shared.statusBarFrame.height
    }

    /// 当前导航栏布局高度，隐藏时为0，推荐使用
    public var fw_navigationBarHeight: CGFloat {
        // 系统导航栏
        guard let navController = self.navigationController,
              !navController.isNavigationBarHidden else { return 0 }
        return navController.navigationBar.frame.height
    }

    /// 当前顶部栏布局高度，导航栏隐藏时为0，推荐使用
    public var fw_topBarHeight: CGFloat {
        // 通常情况下导航栏显示时可以这样计算：navController.navigationBar.frame.maxY
        return fw_statusBarHeight + fw_navigationBarHeight
    }

    /// 当前标签栏布局高度，隐藏时为0，推荐使用
    public var fw_tabBarHeight: CGFloat {
        guard let tabController = self.tabBarController,
              !tabController.tabBar.isHidden else { return 0 }
        if self.hidesBottomBarWhenPushed && !fw_isHead { return 0 }
        return tabController.tabBar.frame.height
    }

    /// 当前工具栏布局高度，隐藏时为0，推荐使用
    public var fw_toolBarHeight: CGFloat {
        guard let navController = self.navigationController,
              !navController.isToolbarHidden else { return 0 }
        // 如果未同时显示标签栏，高度需要加上安全区域高度
        var height = navController.toolbar.frame.height
        if let tabController = self.tabBarController,
           !tabController.tabBar.isHidden,
           !(self.hidesBottomBarWhenPushed && !fw_isHead) {
        } else {
            height += UIScreen.fw_safeAreaInsets.bottom
        }
        return height
    }

    /// 当前底部栏布局高度，包含标签栏和工具栏，隐藏时为0，推荐使用
    public var fw_bottomBarHeight: CGFloat {
        return fw_tabBarHeight + fw_toolBarHeight
    }
    
}
