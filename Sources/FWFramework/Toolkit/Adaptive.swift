//
//  Adaptive.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

// MARK: - WrapperGlobal
extension WrapperGlobal {
    // MARK: - UIApplication
    /// 是否是调试模式
    public static var isDebug: Bool { UIApplication.fw.isDebug }

    // MARK: - UIDevice
    /// 是否是模拟器
    public static var isSimulator: Bool { UIDevice.fw.isSimulator }

    /// 是否是iPhone设备
    public static var isIphone: Bool { UIDevice.fw.isIphone }
    /// 是否是iPad设备
    public static var isIpad: Bool { UIDevice.fw.isIpad }
    /// 是否是Mac设备
    public static var isMac: Bool { UIDevice.fw.isMac }

    /// iOS系统版本
    public static var iosVersion: Double { UIDevice.fw.iosVersion }
    /// 是否是指定iOS主版本
    public static func isIos(_ version: Int) -> Bool { UIDevice.fw.isIos(version) }
    /// 是否是大于等于指定iOS主版本
    public static func isIosLater(_ version: Int) -> Bool { UIDevice.fw.isIosLater(version) }

    /// 设备尺寸，跟横竖屏无关
    public static var deviceSize: CGSize { UIDevice.fw.deviceSize }
    /// 设备宽度，跟横竖屏无关
    public static var deviceWidth: CGFloat { UIDevice.fw.deviceWidth }
    /// 设备高度，跟横竖屏无关
    public static var deviceHeight: CGFloat { UIDevice.fw.deviceHeight }
    /// 设备分辨率，跟横竖屏无关
    public static var deviceResolution: CGSize { UIDevice.fw.deviceResolution }
    /// 设备是否横屏，无论支不支持横屏
    public static var isDeviceLandscape: Bool { UIDevice.fw.isDeviceLandscape }

    // MARK: - UIScreen
    /// 屏幕尺寸
    public static var screenSize: CGSize { UIScreen.fw.screenSize }
    /// 屏幕宽度
    public static var screenWidth: CGFloat { UIScreen.fw.screenWidth }
    /// 屏幕高度
    public static var screenHeight: CGFloat { UIScreen.fw.screenHeight }
    /// 屏幕像素比例
    public static var screenScale: CGFloat { UIScreen.fw.screenScale }
    /// 判断屏幕英寸，需同步适配新机型
    public static func isScreenInch(_ inch: ScreenInch) -> Bool { UIScreen.fw.isScreenInch(inch) }
    /// 界面是否横屏
    public static var isInterfaceLandscape: Bool { UIScreen.fw.isInterfaceLandscape }
    /// 是否是全面屏屏幕
    @MainActor public static var isNotchedScreen: Bool { UIScreen.fw.isNotchedScreen }
    /// 是否是灵动岛屏幕
    @MainActor public static var isDynamicIsland: Bool { UIScreen.fw.isDynamicIsland }
    /// 屏幕一像素的大小
    public static var pixelOne: CGFloat { UIScreen.fw.pixelOne }
    /// 屏幕安全区域距离
    @MainActor public static var safeAreaInsets: UIEdgeInsets { UIScreen.fw.safeAreaInsets }

    /// 状态栏高度，与是否隐藏无关
    @MainActor public static var statusBarHeight: CGFloat { UIScreen.fw.statusBarHeight }
    /// 导航栏高度，与是否隐藏无关
    @MainActor public static var navigationBarHeight: CGFloat { UIScreen.fw.navigationBarHeight }
    /// 顶部栏高度，包含状态栏、导航栏，与是否隐藏无关
    @MainActor public static var topBarHeight: CGFloat { UIScreen.fw.topBarHeight }
    /// 标签栏高度，与是否隐藏无关
    @MainActor public static var tabBarHeight: CGFloat { UIScreen.fw.tabBarHeight }
    /// 工具栏高度，与是否隐藏无关
    @MainActor public static var toolBarHeight: CGFloat { UIScreen.fw.toolBarHeight }

    /// 当前等比例缩放参考设计图宽度，默认375
    public static var referenceWidth: CGFloat { UIScreen.fw.referenceSize.width }
    /// 当前等比例缩放参考设计图高度，默认812
    public static var referenceHeight: CGFloat { UIScreen.fw.referenceSize.height }
    /// 当前屏幕宽度缩放比例
    public static var relativeScale: CGFloat { UIScreen.fw.relativeScale }
    /// 当前屏幕高度缩放比例
    public static var relativeHeightScale: CGFloat { UIScreen.fw.relativeHeightScale }

    /// 获取相对设计图宽度等比例缩放值
    public static func relative(_ value: CGFloat, flat: Bool = false) -> CGFloat {
        UIScreen.fw.relativeValue(value, flat: flat)
    }

    /// 获取相对设计图等比例缩放size
    public static func relative(_ size: CGSize, flat: Bool = false) -> CGSize {
        CGSize(width: relative(size.width, flat: flat), height: relative(size.height, flat: flat))
    }

    /// 获取相对设计图等比例缩放point
    public static func relative(_ point: CGPoint, flat: Bool = false) -> CGPoint {
        CGPoint(x: relative(point.x, flat: flat), y: relative(point.y, flat: flat))
    }

    /// 获取相对设计图等比例缩放rect
    public static func relative(_ rect: CGRect, flat: Bool = false) -> CGRect {
        CGRect(origin: relative(rect.origin, flat: flat), size: relative(rect.size, flat: flat))
    }

    /// 获取相对设计图等比例缩放insets
    public static func relative(_ insets: UIEdgeInsets, flat: Bool = false) -> UIEdgeInsets {
        UIEdgeInsets(top: relative(insets.top, flat: flat), left: relative(insets.left, flat: flat), bottom: relative(insets.bottom, flat: flat), right: relative(insets.right, flat: flat))
    }

    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    public static func fixed(_ value: CGFloat, flat: Bool = false) -> CGFloat {
        UIScreen.fw.fixedValue(value, flat: flat)
    }

    /// 获取相对设计图等比例缩放时的固定size
    public static func fixed(_ size: CGSize, flat: Bool = false) -> CGSize {
        CGSize(width: fixed(size.width, flat: flat), height: fixed(size.height, flat: flat))
    }

    /// 获取相对设计图等比例缩放时的固定point
    public static func fixed(_ point: CGPoint, flat: Bool = false) -> CGPoint {
        CGPoint(x: fixed(point.x, flat: flat), y: fixed(point.y, flat: flat))
    }

    /// 获取相对设计图等比例缩放时的固定rect
    public static func fixed(_ rect: CGRect, flat: Bool = false) -> CGRect {
        CGRect(origin: fixed(rect.origin, flat: flat), size: fixed(rect.size, flat: flat))
    }

    /// 获取相对设计图等比例缩放时的固定insets
    public static func fixed(_ insets: UIEdgeInsets, flat: Bool = false) -> UIEdgeInsets {
        UIEdgeInsets(top: fixed(insets.top, flat: flat), left: fixed(insets.left, flat: flat), bottom: fixed(insets.bottom, flat: flat), right: fixed(insets.right, flat: flat))
    }

    /// 获取相对设计图高度等比例缩放值
    public static func relativeHeight(_ value: CGFloat, flat: Bool = false) -> CGFloat {
        UIScreen.fw.relativeHeight(value, flat: flat)
    }

    /// 获取相对设计图高度等比例缩放时的固定高度值
    public static func fixedHeight(_ value: CGFloat, flat: Bool = false) -> CGFloat {
        UIScreen.fw.fixedHeight(value, flat: flat)
    }

    /// 基于指定的倍数(0取当前设备)，对传进来的floatValue进行像素取整
    public static func flat(_ value: CGFloat, scale: CGFloat = 0) -> CGFloat {
        UIScreen.fw.flatValue(value, scale: scale)
    }

    /// 基于指定的倍数(0取当前设备)，对传进来的size进行像素取整
    public static func flat(_ size: CGSize, scale: CGFloat = 0) -> CGSize {
        CGSize(width: flat(size.width, scale: scale), height: flat(size.height, scale: scale))
    }

    /// 基于指定的倍数(0取当前设备)，对传进来的point进行像素取整
    public static func flat(_ point: CGPoint, scale: CGFloat = 0) -> CGPoint {
        CGPoint(x: flat(point.x, scale: scale), y: flat(point.y, scale: scale))
    }

    /// 基于指定的倍数(0取当前设备)，对传进来的rect进行像素取整
    public static func flat(_ rect: CGRect, scale: CGFloat = 0) -> CGRect {
        CGRect(origin: flat(rect.origin, scale: scale), size: flat(rect.size, scale: scale))
    }

    /// 基于指定的倍数(0取当前设备)，对传进来的insets进行像素取整
    public static func flat(_ insets: UIEdgeInsets, scale: CGFloat = 0) -> UIEdgeInsets {
        UIEdgeInsets(top: flat(insets.top, scale: scale), left: flat(insets.left, scale: scale), bottom: flat(insets.bottom, scale: scale), right: flat(insets.right, scale: scale))
    }
}

// MARK: - Wrapper+UIApplication
extension Wrapper where Base: UIApplication {
    /// 是否是调试模式
    public static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}

// MARK: - Wrapper+UIDevice
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
        deviceModel.hasPrefix("iPhone")
    }

    /// 是否是iPad
    public static var isIpad: Bool {
        deviceModel.hasPrefix("iPad")
    }

    /// 是否是Mac
    public static var isMac: Bool {
        if #available(iOS 14.0, *) {
            return ProcessInfo.processInfo.isiOSAppOnMac ||
                ProcessInfo.processInfo.isMacCatalystApp
        }
        return ProcessInfo.processInfo.isMacCatalystApp
    }

    /// iOS系统版本字符串
    public static var iosVersionString: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        var versionString = "\(version.majorVersion).\(version.minorVersion)"
        if version.patchVersion != 0 {
            versionString += ".\(version.patchVersion)"
        }
        return versionString
    }

    /// iOS系统版本浮点数
    public static var iosVersion: Double {
        (iosVersionString as NSString).doubleValue
    }

    /// 是否是指定iOS版本
    public static func isIos(_ major: Int, _ minor: Int? = nil, _ patch: Int? = nil) -> Bool {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        var result = version.majorVersion == major
        if result, let minor {
            result = result && version.minorVersion == minor
        }
        if result, let patch {
            result = result && version.patchVersion == patch
        }
        return result
    }

    /// 是否是大于等于指定iOS版本
    public static func isIosLater(_ major: Int, _ minor: Int? = nil, _ patch: Int? = nil) -> Bool {
        let version = OperatingSystemVersion(majorVersion: major, minorVersion: minor ?? 0, patchVersion: patch ?? 0)
        return ProcessInfo.processInfo.isOperatingSystemAtLeast(version)
    }

    /// 设备尺寸，跟横竖屏无关
    public static var deviceSize: CGSize {
        CGSize(width: deviceWidth, height: deviceHeight)
    }

    /// 设备宽度，跟横竖屏无关
    public static var deviceWidth: CGFloat {
        if let deviceWidth = UIDevice.innerDeviceWidth { return deviceWidth }

        let deviceWidth = DispatchQueue.fw.mainSyncIf {
            min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        } otherwise: {
            min(UIScreen.fw.screenSize.width, UIScreen.fw.screenSize.height)
        }
        UIDevice.innerDeviceWidth = deviceWidth
        return deviceWidth
    }

    /// 设备高度，跟横竖屏无关
    public static var deviceHeight: CGFloat {
        if let deviceHeight = UIDevice.innerDeviceHeight { return deviceHeight }

        let deviceHeight = DispatchQueue.fw.mainSyncIf {
            max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        } otherwise: {
            max(UIScreen.fw.screenSize.width, UIScreen.fw.screenSize.height)
        }
        UIDevice.innerDeviceHeight = deviceHeight
        return deviceHeight
    }

    /// 设备分辨率，跟横竖屏无关
    public static var deviceResolution: CGSize {
        CGSize(width: deviceWidth * UIScreen.fw.screenScale, height: deviceHeight * UIScreen.fw.screenScale)
    }

    /// 获取设备模型，格式："iPhone15,1"
    public static var deviceModel: String {
        if let deviceModel = UIDevice.innerDeviceModel {
            return deviceModel
        }

        #if targetEnvironment(simulator)
        let deviceModel = String(format: "%s", getenv("SIMULATOR_MODEL_IDENTIFIER"))
        #else
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let deviceModel = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        #endif
        UIDevice.innerDeviceModel = deviceModel
        return deviceModel
    }

    /// 设备是否横屏，无论支不支持横屏
    public static var isDeviceLandscape: Bool {
        let isLandscape = DispatchQueue.fw.mainSyncIf {
            UIDevice.current.orientation.isLandscape
        } otherwise: {
            if let orientationValue = UIDevice.innerCurrentDevice?.fw.value(forKey: "orientation") as? Int,
               let orientation = UIDeviceOrientation(rawValue: orientationValue) {
                return orientation.isLandscape
            }
            return false
        }
        return isLandscape
    }

    /// 设置界面方向，支持旋转方向时生效
    @discardableResult
    @MainActor public static func setDeviceOrientation(_ orientation: UIDeviceOrientation) -> Bool {
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

            UIWindow.fw.mainScene?.requestGeometryUpdate(.iOS(interfaceOrientations: orientationMask))
            return true
        }

        UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        return true
    }
}

// MARK: - Wrapper+UIScreen
@MainActor extension Wrapper where Base: UIScreen {
    /// 屏幕尺寸
    public nonisolated static var screenSize: CGSize {
        let screenBounds = DispatchQueue.fw.mainSyncIf {
            UIScreen.main.bounds
        } otherwise: {
            UIScreen.innerMainScreen?.fw.value(forKey: "bounds") as? CGRect ?? .zero
        }
        return screenBounds.size
    }

    /// 屏幕宽度
    public nonisolated static var screenWidth: CGFloat {
        screenSize.width
    }

    /// 屏幕高度
    public nonisolated static var screenHeight: CGFloat {
        screenSize.height
    }

    /// 屏幕像素比例
    public nonisolated static var screenScale: CGFloat {
        if let screenScale = UIScreen.innerScreenScale { return screenScale }

        let screenScale = DispatchQueue.fw.mainSyncIf {
            UIScreen.main.scale
        } otherwise: {
            UIScreen.innerMainScreen?.fw.value(forKey: "scale") as? CGFloat ?? 0
        }
        UIScreen.innerScreenScale = screenScale
        return screenScale
    }

    /// 判断屏幕英寸，需同步适配新机型
    public nonisolated static func isScreenInch(_ inch: ScreenInch) -> Bool {
        switch inch {
        case .inch35:
            return UIDevice.fw.deviceSize.equalTo(CGSize(width: 320, height: 480))
        case .inch40:
            return UIDevice.fw.deviceSize.equalTo(CGSize(width: 320, height: 568))
        case .inch47:
            return UIDevice.fw.deviceSize.equalTo(CGSize(width: 375, height: 667))
        case .inch54:
            return UIDevice.fw.deviceSize.equalTo(CGSize(width: 375, height: 812))
        case .inch55:
            return UIDevice.fw.deviceSize.equalTo(CGSize(width: 414, height: 736))
        case .inch58:
            return UIDevice.fw.deviceSize.equalTo(CGSize(width: 375, height: 812))
        case .inch61:
            return (UIDevice.fw.deviceSize.equalTo(CGSize(width: 414, height: 896)) && (UIDevice.fw.deviceModel == "iPhone11,8" || UIDevice.fw.deviceModel == "iPhone12,1")) ||
                UIDevice.fw.deviceSize.equalTo(CGSize(width: 390, height: 844)) ||
                UIDevice.fw.deviceSize.equalTo(CGSize(width: 393, height: 852))
        case .inch63:
            return UIDevice.fw.deviceSize.equalTo(CGSize(width: 402, height: 874))
        case .inch65:
            return UIDevice.fw.deviceSize.equalTo(CGSize(width: 414, height: 896)) && !isScreenInch(.inch61)
        case .inch67:
            return UIDevice.fw.deviceSize.equalTo(CGSize(width: 428, height: 926)) ||
                UIDevice.fw.deviceSize.equalTo(CGSize(width: 430, height: 932))
        case .inch69:
            return UIDevice.fw.deviceSize.equalTo(CGSize(width: 440, height: 956))
        default:
            return false
        }
    }

    /// 界面是否横屏
    public nonisolated static var isInterfaceLandscape: Bool {
        let isLandscape = DispatchQueue.fw.mainSyncIf {
            UIWindow.fw.mainScene?.interfaceOrientation.isLandscape ?? false
        } otherwise: {
            screenHeight <= screenWidth
        }
        return isLandscape
    }

    /// 是否是全面屏屏幕
    public static var isNotchedScreen: Bool {
        safeAreaInsets.bottom > 0
    }

    /// 是否是灵动岛屏幕
    public static var isDynamicIsland: Bool {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return false }
        if UIScreen.main.bounds.height > UIScreen.main.bounds.width {
            return safeAreaInsets.top >= 59.0
        } else {
            return safeAreaInsets.left >= 59.0
        }
    }

    /// 屏幕一像素的大小
    public nonisolated static var pixelOne: CGFloat {
        1.0 / screenScale
    }

    /// 检查是否含有安全区域，可用来判断iPhoneX
    public static var hasSafeAreaInsets: Bool {
        safeAreaInsets.bottom > 0
    }

    /// 屏幕安全区域距离
    public static var safeAreaInsets: UIEdgeInsets {
        var mainWindow = UIWindow.fw.main
        if mainWindow != nil {
            if UIScreen.innerMainWindow != nil { UIScreen.innerMainWindow = nil }
        } else {
            if UIScreen.innerMainWindow == nil { UIScreen.innerMainWindow = UIWindow(frame: UIScreen.main.bounds) }
            mainWindow = UIScreen.innerMainWindow
        }
        return mainWindow?.safeAreaInsets ?? .zero
    }

    /// 状态栏高度，与是否隐藏无关，可自定义
    public static var statusBarHeight: CGFloat {
        // 1. 读取自定义状态栏高度，优先级最高
        let orientation = UIWindow.fw.mainScene?.interfaceOrientation ?? .unknown
        if let height = UIScreen.innerCustomStatusBarHeights[orientation] { return height }

        // 2. 获取实时statusBarManager状态栏高度并缓存
        let statusBarManager = UIWindow.fw.mainScene?.statusBarManager
        if let statusBarManager, !statusBarManager.isStatusBarHidden {
            let height = statusBarManager.statusBarFrame.height
            UIScreen.innerCachedStatusBarHeights[orientation] = height
            return height
        }

        // 3. 当获取不到实时状态栏高度时读取缓存
        if let height = UIScreen.innerCachedStatusBarHeights[orientation] {
            return height
        }

        // 4. 调用statusBarManager默认高度方法并缓存
        let heightSelector = NSSelectorFromString("defaultStatusBarHeightInOrientation:")
        if let statusBarManager, statusBarManager.responds(to: heightSelector),
           let height = statusBarManager.fw.invokeMethod(heightSelector, objects: [orientation.rawValue])?.takeUnretainedValue() as? CGFloat {
            UIScreen.innerCachedStatusBarHeights[orientation] = height
            return height
        }

        // 5. 兜底算法，需同步适配新机型
        if UIDevice.fw.isIpad { return isNotchedScreen ? 24 : 20 }
        if isInterfaceLandscape { return 0 }
        if !isNotchedScreen { return 20 }
        if isDynamicIsland { return 54 }
        if UIDevice.fw.deviceModel == "iPhone12,1" { return 48 }
        if UIDevice.fw.deviceSize.equalTo(CGSize(width: 390, height: 844)) { return 47 }
        if isScreenInch(.inch67) { return 47 }
        if isScreenInch(.inch54) && UIDevice.fw.iosVersion >= 15.0 { return 50 }
        return 44
    }

    /// 导航栏高度，与是否隐藏无关，可自定义
    public static var navigationBarHeight: CGFloat {
        // 1. 读取自定义导航栏高度，优先级最高
        let orientation = UIWindow.fw.mainScene?.interfaceOrientation ?? .unknown
        if let height = UIScreen.innerCustomNavigationBarHeights[orientation] { return height }

        // 2. 获取实时根导航控制器高度并缓存
        if let navController = firstRootController(of: UINavigationController.self),
           !navController.navigationBar.prefersLargeTitles {
            let height = navController.navigationBar.frame.height
            UIScreen.innerCachedNavigationBarHeights[orientation] = height
            return height
        }

        // 3. 当获取不到实时导航栏高度时读取缓存
        if let height = UIScreen.innerCachedNavigationBarHeights[orientation] {
            return height
        }

        // 4. 兜底算法，需同步适配新机型
        if UIDevice.fw.isIpad { return 50 }
        if isInterfaceLandscape { return isRegularScreen ? 44 : 32 }
        return 44
    }

    /// 顶部栏高度，包含状态栏、导航栏，与是否隐藏无关
    public static var topBarHeight: CGFloat {
        statusBarHeight + navigationBarHeight
    }

    /// 标签栏高度，与是否隐藏无关，可自定义
    public static var tabBarHeight: CGFloat {
        // 1. 读取自定义标签栏高度，优先级最高
        let orientation = UIWindow.fw.mainScene?.interfaceOrientation ?? .unknown
        if let height = UIScreen.innerCustomTabBarHeights[orientation] { return height }

        // 2. 获取实时根标签控制器高度并缓存
        if let tabController = firstRootController(of: UITabBarController.self) {
            let height = tabController.tabBar.frame.height
            UIScreen.innerCachedTabBarHeights[orientation] = height
            return height
        }

        // 3. 当获取不到实时标签栏高度时读取缓存
        if let height = UIScreen.innerCachedTabBarHeights[orientation] {
            return height
        }

        // 4. 兜底算法，需同步适配新机型
        if UIDevice.fw.isIpad { return isNotchedScreen ? 65 : 50 }
        if isInterfaceLandscape { return (isRegularScreen ? 49 : 32) + safeAreaInsets.bottom }
        return 49 + safeAreaInsets.bottom
    }

    /// 工具栏高度，与是否隐藏无关，可自定义
    public static var toolBarHeight: CGFloat {
        // 1. 读取自定义工具栏高度，优先级最高
        let orientation = UIWindow.fw.mainScene?.interfaceOrientation ?? .unknown
        if let height = UIScreen.innerCustomToolBarHeights[orientation] { return height }

        // 2. 获取实时根导航控制器工具栏高度并缓存
        if let navController = firstRootController(of: UINavigationController.self) {
            let height = navController.toolbar.frame.height + safeAreaInsets.bottom
            UIScreen.innerCachedToolBarHeights[orientation] = height
            return height
        }

        // 3. 当获取不到实时工具栏高度时读取缓存
        if let height = UIScreen.innerCachedToolBarHeights[orientation] {
            return height
        }

        // 4. 兜底算法，需同步适配新机型
        if UIDevice.fw.isIpad { return isNotchedScreen ? 70 : 50 }
        if isInterfaceLandscape { return (isRegularScreen ? 44 : 32) + safeAreaInsets.bottom }
        return 44 + safeAreaInsets.bottom
    }

    /// 自定义指定界面方向状态栏高度，小于等于0时清空
    public static func setStatusBarHeight(_ height: CGFloat, for orientation: UIInterfaceOrientation) {
        UIScreen.innerCustomStatusBarHeights[orientation] = height > 0 ? height : nil
    }

    /// 自定义指定界面方向导航栏高度，小于等于0时清空
    public static func setNavigationBarHeight(_ height: CGFloat, for orientation: UIInterfaceOrientation) {
        UIScreen.innerCustomNavigationBarHeights[orientation] = height > 0 ? height : nil
    }

    /// 自定义指定界面方向标签栏高度，小于等于0时清空
    public static func setTabBarHeight(_ height: CGFloat, for orientation: UIInterfaceOrientation) {
        UIScreen.innerCustomTabBarHeights[orientation] = height > 0 ? height : nil
    }

    /// 自定义指定界面方向工具栏高度，小于等于0时清空
    public static func setToolBarHeight(_ height: CGFloat, for orientation: UIInterfaceOrientation) {
        UIScreen.innerCustomToolBarHeights[orientation] = height > 0 ? height : nil
    }

    private static func firstRootController<T>(of type: T.Type) -> T? {
        let rootController = UIWindow.fw.main?.rootViewController
        if let result = rootController as? T {
            return result
        }
        if let tabBarController = rootController as? UITabBarController {
            if let result = tabBarController.selectedViewController as? T { return result }
            return tabBarController.viewControllers?.first(where: { $0 is T }) as? T
        }
        if let navigationController = rootController as? UINavigationController {
            return navigationController.viewControllers.first(where: { $0 is T }) as? T
        }
        return nil
    }

    private static var isRegularScreen: Bool {
        // https://github.com/Tencent/QMUI_iOS
        if UIDevice.fw.isIpad { return true }
        if isDynamicIsland { return true }

        var isZoomedMode = false
        if UIDevice.fw.isIphone {
            let nativeScale = UIScreen.main.nativeScale
            var scale = UIScreen.main.scale
            if CGSize(width: 1080, height: 1920).equalTo(UIScreen.main.nativeBounds.size) {
                scale /= 1.15
            }
            isZoomedMode = nativeScale > scale
        }
        if isZoomedMode { return false }

        if isScreenInch(.inch67) || isScreenInch(.inch65) || isScreenInch(.inch55) { return true }
        if UIDevice.fw.deviceSize.equalTo(CGSize(width: 414, height: 896)) && (UIDevice.fw.deviceModel == "iPhone11,8" || UIDevice.fw.deviceModel == "iPhone12,1") { return true }
        return false
    }

    /// 指定等比例缩放参考设计图尺寸，默认{375,812}，宽度常用
    public nonisolated static var referenceSize: CGSize {
        get { UIScreen.innerReferenceSize }
        set { UIScreen.innerReferenceSize = newValue }
    }

    /// 全局自定义屏幕宽度缩放比例句柄，默认nil
    public nonisolated static var relativeScaleBlock: (@Sendable () -> CGFloat)? {
        get { UIScreen.innerRelativeScaleBlock }
        set { UIScreen.innerRelativeScaleBlock = newValue }
    }

    /// 全局自定义屏幕高度缩放比例句柄，默认nil
    public nonisolated static var relativeHeightScaleBlock: (@Sendable () -> CGFloat)? {
        get { UIScreen.innerRelativeHeightScaleBlock }
        set { UIScreen.innerRelativeHeightScaleBlock = newValue }
    }

    /// 获取当前屏幕宽度缩放比例，宽度常用
    public nonisolated static var relativeScale: CGFloat {
        if let block = relativeScaleBlock {
            return block()
        }

        if screenHeight > screenWidth {
            return screenWidth / referenceSize.width
        } else {
            return screenWidth / referenceSize.height
        }
    }

    /// 获取当前屏幕高度缩放比例，高度不常用
    public nonisolated static var relativeHeightScale: CGFloat {
        if let block = relativeHeightScaleBlock {
            return block()
        }

        if screenHeight > screenWidth {
            return screenHeight / referenceSize.height
        } else {
            return screenHeight / referenceSize.width
        }
    }

    /// 获取相对设计图宽度等比例缩放值
    public nonisolated static func relativeValue(_ value: CGFloat, flat: Bool = false) -> CGFloat {
        let result = value * relativeScale
        return flat ? flatValue(result) : result
    }

    /// 获取相对设计图高度等比例缩放值
    public nonisolated static func relativeHeight(_ value: CGFloat, flat: Bool = false) -> CGFloat {
        let result = value * relativeHeightScale
        return flat ? flatValue(result) : result
    }

    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    public nonisolated static func fixedValue(_ value: CGFloat, flat: Bool = false) -> CGFloat {
        let result = value / relativeScale
        return flat ? flatValue(result) : result
    }

    /// 获取相对设计图高度等比例缩放时的固定高度值
    public nonisolated static func fixedHeight(_ value: CGFloat, flat: Bool = false) -> CGFloat {
        let result = value / relativeHeightScale
        return flat ? flatValue(result) : result
    }

    /// 基于指定的倍数(0取当前设备)，对传进来的floatValue进行像素取整
    public nonisolated static func flatValue(_ value: CGFloat, scale: CGFloat = 0) -> CGFloat {
        let floatValue: CGFloat = (value == .leastNonzeroMagnitude || value == .leastNormalMagnitude) ? 0 : value
        let scaleValue: CGFloat = scale > 0 ? scale : screenScale
        return ceil(floatValue * scaleValue) / scaleValue
    }
}

// MARK: - Wrapper+UIView
@MainActor extension Wrapper where Base: UIView {
    /// 是否自动等比例缩放方式设置transform，默认NO
    public var autoScaleTransform: Bool {
        get {
            propertyBool(forName: "autoScaleTransform")
        }
        set {
            setPropertyBool(newValue, forName: "autoScaleTransform")
            if newValue {
                let scaleX = UIScreen.fw.relativeScale
                let scaleY = UIScreen.fw.relativeHeightScale
                let scale = scaleX > scaleY ? scaleY : scaleX
                base.transform = .init(scaleX: scale, y: scale)
            } else {
                base.transform = .identity
            }
        }
    }
}

// MARK: - Wrapper+UIViewController
@MainActor extension Wrapper where Base: UIViewController {
    /// 当前状态栏布局高度，导航栏隐藏时为0，推荐使用
    public var statusBarHeight: CGFloat {
        // 1. 导航栏隐藏时不占用布局高度始终为0
        guard base.navigationController != nil else { return 0 }
        guard !navigationBarHidden else { return 0 }

        // 2. 竖屏且为iOS13+弹出pageSheet样式时布局高度为0
        let isPortrait = !UIScreen.fw.isInterfaceLandscape
        if isPortrait && isPageSheet { return 0 }

        // 3. 竖屏且异形屏，导航栏显示时布局高度固定
        if isPortrait && UIScreen.fw.isNotchedScreen {
            // 也可以这样计算：navController.navigationBar.frame.minY
            return UIScreen.fw.statusBarHeight
        }

        // 4. 其他情况状态栏显示时布局高度固定，隐藏时布局高度为0
        let statusBarManager = UIWindow.fw.mainScene?.statusBarManager
        if statusBarManager?.isStatusBarHidden ?? false { return 0 }
        return statusBarManager?.statusBarFrame.height ?? 0
    }

    /// 当前导航栏布局高度，隐藏时为0，推荐使用
    public var navigationBarHeight: CGFloat {
        // 系统导航栏
        guard let navController = base.navigationController else { return 0 }
        guard !navigationBarHidden else { return 0 }
        return navController.navigationBar.frame.height
    }

    /// 当前顶部栏布局高度，导航栏隐藏时为0，推荐使用
    public var topBarHeight: CGFloat {
        // 通常情况下导航栏显示时可以这样计算：navController.navigationBar.frame.maxY
        statusBarHeight + navigationBarHeight
    }

    /// 当前标签栏布局高度，隐藏时为0，推荐使用
    public var tabBarHeight: CGFloat {
        guard let tabController = base.tabBarController else { return 0 }
        guard !tabBarHidden else { return 0 }
        // 兼容hidesBottomBarWhenPushed开启且控制器转场时，标签栏高度应为0的场景
        if base.hidesBottomBarWhenPushed && !isHead && base.transitionCoordinator != nil { return 0 }
        return tabController.tabBar.frame.height
    }

    /// 当前工具栏布局高度，隐藏时为0，推荐使用
    public var toolBarHeight: CGFloat {
        guard let navController = base.navigationController,
              !navController.isToolbarHidden else { return 0 }
        // 如果未同时显示标签栏，高度需要加上安全区域高度
        var height = navController.toolbar.frame.height
        if tabBarHeight <= 0 {
            height += UIScreen.fw.safeAreaInsets.bottom
        }
        return height
    }

    /// 当前底部栏布局高度，包含标签栏和工具栏，隐藏时为0，推荐使用
    public var bottomBarHeight: CGFloat {
        tabBarHeight + toolBarHeight
    }
}

// MARK: - ScreenInch
/// 可扩展屏幕尺寸
public struct ScreenInch: RawRepresentable, Equatable, Hashable, Sendable {
    public typealias RawValue = Int

    public static let inch35: ScreenInch = .init(35)
    public static let inch40: ScreenInch = .init(40)
    public static let inch47: ScreenInch = .init(47)
    public static let inch54: ScreenInch = .init(54)
    public static let inch55: ScreenInch = .init(55)
    public static let inch58: ScreenInch = .init(58)
    public static let inch61: ScreenInch = .init(61)
    public static let inch63: ScreenInch = .init(63)
    public static let inch65: ScreenInch = .init(65)
    public static let inch67: ScreenInch = .init(67)
    public static let inch69: ScreenInch = .init(69)

    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int) {
        self.rawValue = rawValue
    }
}

// MARK: - Adaptive+Shortcut
extension CGFloat {
    /// 获取相对设计图宽度等比例缩放值
    public var relativeValue: CGFloat { UIScreen.fw.relativeValue(self) }
    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    public var fixedValue: CGFloat { UIScreen.fw.fixedValue(self) }
    /// 获取基于当前设备的倍数像素取整值
    public var flatValue: CGFloat { UIScreen.fw.flatValue(self) }
    /// 获取向上取整值
    public var ceilValue: CGFloat { ceil(self) }
}

extension Double {
    /// 获取相对设计图宽度等比例缩放值
    public var relativeValue: CGFloat { UIScreen.fw.relativeValue(CGFloat(self)) }
    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    public var fixedValue: CGFloat { UIScreen.fw.fixedValue(CGFloat(self)) }
    /// 获取基于当前设备的倍数像素取整值
    public var flatValue: CGFloat { UIScreen.fw.flatValue(CGFloat(self)) }
    /// 获取向上取整值
    public var ceilValue: CGFloat { ceil(CGFloat(self)) }
}

extension Float {
    /// 获取相对设计图宽度等比例缩放值
    public var relativeValue: CGFloat { UIScreen.fw.relativeValue(CGFloat(self)) }
    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    public var fixedValue: CGFloat { UIScreen.fw.fixedValue(CGFloat(self)) }
    /// 获取基于当前设备的倍数像素取整值
    public var flatValue: CGFloat { UIScreen.fw.flatValue(CGFloat(self)) }
    /// 获取向上取整值
    public var ceilValue: CGFloat { ceil(CGFloat(self)) }
}

extension Int {
    /// 获取相对设计图宽度等比例缩放值
    public var relativeValue: CGFloat { UIScreen.fw.relativeValue(CGFloat(self)) }
    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    public var fixedValue: CGFloat { UIScreen.fw.fixedValue(CGFloat(self)) }
    /// 获取基于当前设备的倍数像素取整值
    public var flatValue: CGFloat { UIScreen.fw.flatValue(CGFloat(self)) }
    /// 获取向上取整值
    public var ceilValue: CGFloat { ceil(CGFloat(self)) }
}

extension CGSize {
    /// 获取相对设计图宽度等比例缩放size
    public var relativeValue: CGSize { CGSize(width: width.relativeValue, height: height.relativeValue) }
    /// 获取相对设计图宽度等比例缩放时的固定size
    public var fixedValue: CGSize { CGSize(width: width.fixedValue, height: height.fixedValue) }
    /// 获取基于当前设备的倍数像素取整size
    public var flatValue: CGSize { CGSize(width: width.flatValue, height: height.flatValue) }
    /// 获取向上取整size
    public var ceilValue: CGSize { CGSize(width: width.ceilValue, height: height.ceilValue) }
}

extension CGPoint {
    /// 获取相对设计图宽度等比例缩放point
    public var relativeValue: CGPoint { CGPoint(x: x.relativeValue, y: y.relativeValue) }
    /// 获取相对设计图宽度等比例缩放时的固定point
    public var fixedValue: CGPoint { CGPoint(x: x.fixedValue, y: y.fixedValue) }
    /// 获取基于当前设备的倍数像素取整point
    public var flatValue: CGPoint { CGPoint(x: x.flatValue, y: y.flatValue) }
    /// 获取向上取整point
    public var ceilValue: CGPoint { CGPoint(x: x.ceilValue, y: y.ceilValue) }
}

extension CGRect {
    /// 获取相对设计图宽度等比例缩放rect
    public var relativeValue: CGRect { CGRect(origin: origin.relativeValue, size: size.relativeValue) }
    /// 获取相对设计图宽度等比例缩放时的固定rect
    public var fixedValue: CGRect { CGRect(origin: origin.fixedValue, size: size.fixedValue) }
    /// 获取基于当前设备的倍数像素取整rect
    public var flatValue: CGRect { CGRect(origin: origin.flatValue, size: size.flatValue) }
    /// 获取向上取整rect
    public var ceilValue: CGRect { CGRect(origin: origin.ceilValue, size: size.ceilValue) }
}

extension UIEdgeInsets {
    /// 获取相对设计图宽度等比例缩放insets
    public var relativeValue: UIEdgeInsets { UIEdgeInsets(top: top.relativeValue, left: left.relativeValue, bottom: bottom.relativeValue, right: right.relativeValue) }
    /// 获取相对设计图宽度等比例缩放时的固定insets
    public var fixedValue: UIEdgeInsets { UIEdgeInsets(top: top.fixedValue, left: left.fixedValue, bottom: bottom.fixedValue, right: right.fixedValue) }
    /// 获取基于当前设备的倍数像素取整insets
    public var flatValue: UIEdgeInsets { UIEdgeInsets(top: top.flatValue, left: left.flatValue, bottom: bottom.flatValue, right: right.flatValue) }
    /// 获取向上取整insets
    public var ceilValue: UIEdgeInsets { UIEdgeInsets(top: top.ceilValue, left: left.ceilValue, bottom: bottom.ceilValue, right: right.ceilValue) }
}

// MARK: - UIDevice+Adaptive
extension UIDevice {
    private nonisolated(unsafe) static var innerCachedCurrentDevice: UIDevice?
    nonisolated static var innerCurrentDevice: UIDevice? {
        get {
            if let currentDevice = innerCachedCurrentDevice { return currentDevice }

            let currentDevice = DispatchQueue.fw.mainSyncIf {
                UIDevice.current
            } otherwise: {
                UIDevice.perform(#selector(getter: UIDevice.current))?.takeUnretainedValue() as? UIDevice
            }
            innerCachedCurrentDevice = currentDevice
            return currentDevice
        }
        set {
            innerCachedCurrentDevice = newValue
        }
    }

    fileprivate nonisolated(unsafe) static var innerDeviceWidth: CGFloat?
    fileprivate nonisolated(unsafe) static var innerDeviceHeight: CGFloat?
    fileprivate nonisolated(unsafe) static var innerDeviceModel: String?
    fileprivate nonisolated(unsafe) static var innerRelativePortraitScaleBlock: (@Sendable () -> CGFloat)?
    fileprivate nonisolated(unsafe) static var innerRelativeLandscapeScaleBlock: (@Sendable () -> CGFloat)?
}

// MARK: - UIScreen+Adaptive
extension UIScreen {
    private nonisolated(unsafe) static var innerCachedMainScreen: UIScreen?
    fileprivate nonisolated static var innerMainScreen: UIScreen? {
        get {
            if let mainScreen = innerCachedMainScreen { return mainScreen }

            let mainScreen = DispatchQueue.fw.mainSyncIf {
                UIScreen.main
            } otherwise: {
                UIScreen.perform(#selector(getter: UIScreen.main))?.takeUnretainedValue() as? UIScreen
            }
            innerCachedMainScreen = mainScreen
            return mainScreen
        }
        set {
            innerCachedMainScreen = newValue
        }
    }

    fileprivate nonisolated(unsafe) static var innerScreenScale: CGFloat?
    fileprivate nonisolated(unsafe) static var innerReferenceSize: CGSize = .init(width: 375, height: 812)
    fileprivate nonisolated(unsafe) static var innerRelativeScaleBlock: (@Sendable () -> CGFloat)?
    fileprivate nonisolated(unsafe) static var innerRelativeHeightScaleBlock: (@Sendable () -> CGFloat)?
    fileprivate nonisolated(unsafe) static var innerMainWindow: UIWindow?
    fileprivate nonisolated(unsafe) static var innerCustomStatusBarHeights: [UIInterfaceOrientation: CGFloat] = [:]
    fileprivate nonisolated(unsafe) static var innerCustomNavigationBarHeights: [UIInterfaceOrientation: CGFloat] = [:]
    fileprivate nonisolated(unsafe) static var innerCustomTabBarHeights: [UIInterfaceOrientation: CGFloat] = [:]
    fileprivate nonisolated(unsafe) static var innerCustomToolBarHeights: [UIInterfaceOrientation: CGFloat] = [:]
    fileprivate nonisolated(unsafe) static var innerCachedStatusBarHeights: [UIInterfaceOrientation: CGFloat] = [:]
    fileprivate nonisolated(unsafe) static var innerCachedNavigationBarHeights: [UIInterfaceOrientation: CGFloat] = [:]
    fileprivate nonisolated(unsafe) static var innerCachedTabBarHeights: [UIInterfaceOrientation: CGFloat] = [:]
    fileprivate nonisolated(unsafe) static var innerCachedToolBarHeights: [UIInterfaceOrientation: CGFloat] = [:]
}

// MARK: - FrameworkAutoloader+Adaptive
extension FrameworkAutoloader {
    @objc static func loadToolkit_Adaptive() {
        DispatchQueue.fw.mainAsync {
            UIDevice.innerCurrentDevice = UIDevice.current
            UIScreen.innerMainScreen = UIScreen.main
            UIDevice.innerDeviceWidth = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
            UIDevice.innerDeviceHeight = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
            UIScreen.innerScreenScale = UIScreen.main.scale
        }
    }
}
