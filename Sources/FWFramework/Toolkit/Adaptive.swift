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

    /// 界面是否横屏
    @MainActor public static var isLandscape: Bool { UIDevice.fw.isLandscape }
    /// 设备是否横屏，无论支不支持横屏
    @MainActor public static var isDeviceLandscape: Bool { UIDevice.fw.isDeviceLandscape }

    /// iOS系统版本
    public static var iosVersion: Double { UIDevice.fw.iosVersion }
    /// 是否是指定iOS主版本
    public static func isIos(_ version: Int) -> Bool { UIDevice.fw.isIos(version) }
    /// 是否是大于等于指定iOS主版本
    public static func isIosLater(_ version: Int) -> Bool { UIDevice.fw.isIosLater(version) }

    /// 设备尺寸，跟横竖屏无关
    @MainActor public static var deviceSize: CGSize { UIDevice.fw.deviceSize }
    /// 设备宽度，跟横竖屏无关
    @MainActor public static var deviceWidth: CGFloat { UIDevice.fw.deviceWidth }
    /// 设备高度，跟横竖屏无关
    @MainActor public static var deviceHeight: CGFloat { UIDevice.fw.deviceHeight }
    /// 设备分辨率，跟横竖屏无关
    @MainActor public static var deviceResolution: CGSize { UIDevice.fw.deviceResolution }

    // MARK: - UIScreen
    /// 屏幕尺寸
    @MainActor public static var screenSize: CGSize { UIScreen.fw.screenSize }
    /// 屏幕宽度
    @MainActor public static var screenWidth: CGFloat { UIScreen.fw.screenWidth }
    /// 屏幕高度
    @MainActor public static var screenHeight: CGFloat { UIScreen.fw.screenHeight }
    /// 屏幕像素比例
    public static var screenScale: CGFloat { UIScreen.fw.screenScale }
    /// 判断屏幕英寸
    @MainActor public static func isScreenInch(_ inch: ScreenInch) -> Bool { UIScreen.fw.isScreenInch(inch) }
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
    @MainActor public static var referenceWidth: CGFloat { UIScreen.fw.referenceSize.width }
    /// 当前等比例缩放参考设计图高度，默认812
    @MainActor public static var referenceHeight: CGFloat { UIScreen.fw.referenceSize.height }
    /// 当前屏幕宽度缩放比例
    @MainActor public static var relativeScale: CGFloat { UIScreen.fw.relativeScale }
    /// 当前屏幕高度缩放比例
    @MainActor public static var relativeHeightScale: CGFloat { UIScreen.fw.relativeHeightScale }

    /// 获取相对设计图宽度等比例缩放值
    @MainActor public static func relative(_ value: CGFloat, flat: Bool = false) -> CGFloat {
        return UIScreen.fw.relativeValue(value, flat: flat)
    }
    /// 获取相对设计图等比例缩放size
    @MainActor public static func relative(_ size: CGSize, flat: Bool = false) -> CGSize {
        return CGSize(width: relative(size.width, flat: flat), height: relative(size.height, flat: flat))
    }
    /// 获取相对设计图等比例缩放point
    @MainActor public static func relative(_ point: CGPoint, flat: Bool = false) -> CGPoint {
        return CGPoint(x: relative(point.x, flat: flat), y: relative(point.y, flat: flat))
    }
    /// 获取相对设计图等比例缩放rect
    @MainActor public static func relative(_ rect: CGRect, flat: Bool = false) -> CGRect {
        return CGRect(origin: relative(rect.origin, flat: flat), size: relative(rect.size, flat: flat))
    }
    /// 获取相对设计图等比例缩放insets
    @MainActor public static func relative(_ insets: UIEdgeInsets, flat: Bool = false) -> UIEdgeInsets {
        return UIEdgeInsets(top: relative(insets.top, flat: flat), left: relative(insets.left, flat: flat), bottom: relative(insets.bottom, flat: flat), right: relative(insets.right, flat: flat))
    }
    
    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    @MainActor public static func fixed(_ value: CGFloat, flat: Bool = false) -> CGFloat {
        return UIScreen.fw.fixedValue(value, flat: flat)
    }
    /// 获取相对设计图等比例缩放时的固定size
    @MainActor public static func fixed(_ size: CGSize, flat: Bool = false) -> CGSize {
        return CGSize(width: fixed(size.width, flat: flat), height: fixed(size.height, flat: flat))
    }
    /// 获取相对设计图等比例缩放时的固定point
    @MainActor public static func fixed(_ point: CGPoint, flat: Bool = false) -> CGPoint {
        return CGPoint(x: fixed(point.x, flat: flat), y: fixed(point.y, flat: flat))
    }
    /// 获取相对设计图等比例缩放时的固定rect
    @MainActor public static func fixed(_ rect: CGRect, flat: Bool = false) -> CGRect {
        return CGRect(origin: fixed(rect.origin, flat: flat), size: fixed(rect.size, flat: flat))
    }
    /// 获取相对设计图等比例缩放时的固定insets
    @MainActor public static func fixed(_ insets: UIEdgeInsets, flat: Bool = false) -> UIEdgeInsets {
        return UIEdgeInsets(top: fixed(insets.top, flat: flat), left: fixed(insets.left, flat: flat), bottom: fixed(insets.bottom, flat: flat), right: fixed(insets.right, flat: flat))
    }
    
    /// 获取相对设计图高度等比例缩放值
    @MainActor public static func relativeHeight(_ value: CGFloat, flat: Bool = false) -> CGFloat {
        return UIScreen.fw.relativeHeight(value, flat: flat)
    }
    /// 获取相对设计图高度等比例缩放时的固定高度值
    @MainActor public static func fixedHeight(_ value: CGFloat, flat: Bool = false) -> CGFloat {
        return UIScreen.fw.fixedHeight(value, flat: flat)
    }

    /// 基于指定的倍数(0取当前设备)，对传进来的floatValue进行像素取整
    public static func flat(_ value: CGFloat, scale: CGFloat = 0) -> CGFloat {
        return UIScreen.fw.flatValue(value, scale: scale)
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
        if UIDevice.innerIsIphone == nil {
            DispatchQueue.fw.mainSync {
                UIDevice.innerIsIphone = UIDevice.current.userInterfaceIdiom == .phone
            }
        }
        
        return UIDevice.innerIsIphone ?? false
    }
    
    /// 是否是iPad
    public static var isIpad: Bool {
        if UIDevice.innerIsIpad == nil {
            DispatchQueue.fw.mainSync {
                UIDevice.innerIsIpad = UIDevice.current.userInterfaceIdiom == .pad
            }
        }
        
        return UIDevice.innerIsIpad ?? false
    }
    
    /// 是否是Mac
    public static var isMac: Bool {
        if #available(iOS 14.0, *) {
            return ProcessInfo.processInfo.isiOSAppOnMac ||
                ProcessInfo.processInfo.isMacCatalystApp
        }
        return false
    }

    /// 界面是否横屏
    @MainActor public static var isLandscape: Bool {
        return UIWindow.fw.mainScene?.interfaceOrientation.isLandscape ?? false
    }
    
    /// 设备是否横屏，无论支不支持横屏
    @MainActor public static var isDeviceLandscape: Bool {
        return UIDevice.current.orientation.isLandscape
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
        return (iosVersionString as NSString).doubleValue
    }
    
    /// 是否是指定iOS版本
    public static func isIos(_ major: Int, _ minor: Int? = nil, _ patch: Int? = nil) -> Bool {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        var result = version.majorVersion == major
        if result, let minor = minor {
            result = result && version.minorVersion == minor
        }
        if result, let patch = patch {
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
    @MainActor public static var deviceSize: CGSize {
        return CGSize(width: deviceWidth, height: deviceHeight)
    }
    
    /// 设备宽度，跟横竖屏无关
    @MainActor public static var deviceWidth: CGFloat {
        return min(UIScreen.fw.screenWidth, UIScreen.fw.screenHeight)
    }
    
    /// 设备高度，跟横竖屏无关
    @MainActor public static var deviceHeight: CGFloat {
        return max(UIScreen.fw.screenWidth, UIScreen.fw.screenHeight)
    }
    
    /// 设备分辨率，跟横竖屏无关
    @MainActor public static var deviceResolution: CGSize {
        return CGSize(width: deviceWidth * UIScreen.fw.screenScale, height: deviceHeight * UIScreen.fw.screenScale)
    }
    
    /// 获取设备模型，格式："iPhone6,1"
    public static var deviceModel: String? {
        #if targetEnvironment(simulator)
        return String(format: "%s", getenv("SIMULATOR_MODEL_IDENTIFIER"))
        #else
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let deviceModel = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return deviceModel
        #endif
    }
}

// MARK: - Wrapper+UIScreen
@MainActor extension Wrapper where Base: UIScreen {
    /// 屏幕尺寸
    public static var screenSize: CGSize {
        return UIScreen.main.bounds.size
    }
    
    /// 屏幕宽度
    public static var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }
    
    /// 屏幕高度
    public static var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }
    
    /// 屏幕像素比例
    nonisolated public static var screenScale: CGFloat {
        if UIScreen.innerScreenScale == nil {
            DispatchQueue.fw.mainSync {
                UIScreen.innerScreenScale = UIScreen.main.scale
            }
        }
        
        return UIScreen.innerScreenScale ?? 0
    }
    
    /// 判断屏幕英寸
    public static func isScreenInch(_ inch: ScreenInch) -> Bool {
        switch inch {
        case .inch35:
            return UIDevice.fw.deviceSize.equalTo(CGSize(width: 320, height: 480))
        case .inch40:
            return UIDevice.fw.deviceSize.equalTo(CGSize(width: 320, height: 568))
        case .inch47:
            return UIDevice.fw.deviceSize.equalTo(CGSize(width: 375, height: 667))
        case .inch54:
            return UIDevice.fw.deviceSize.equalTo(CGSize(width: 360, height: 780))
        case .inch55:
            return UIDevice.fw.deviceSize.equalTo(CGSize(width: 414, height: 736))
        case .inch58:
            return UIDevice.fw.deviceSize.equalTo(CGSize(width: 375, height: 812))
        case .inch61:
            return (UIDevice.fw.deviceSize.equalTo(CGSize(width: 414, height: 896)) && (UIDevice.fw.deviceModel == "iPhone11,8" || UIDevice.fw.deviceModel == "iPhone12,1")) ||
            UIDevice.fw.deviceSize.equalTo(CGSize(width: 390, height: 844))
        case .inch65:
            return UIDevice.fw.deviceSize.equalTo(CGSize(width: 414, height: 896)) && !isScreenInch(.inch61)
        case .inch67:
            return UIDevice.fw.deviceSize.equalTo(CGSize(width: 428, height: 926)) ||
            UIDevice.fw.deviceSize.equalTo(CGSize(width: 430, height: 932))
        default:
            return false
        }
    }
    
    /// 是否是全面屏屏幕
    public static var isNotchedScreen: Bool {
        return safeAreaInsets.bottom > 0
    }
    
    /// 是否是灵动岛屏幕
    public static var isDynamicIsland: Bool {
        guard UIDevice.fw.isIphone else { return false }
        if UIScreen.main.bounds.height > UIScreen.main.bounds.width {
            return safeAreaInsets.top >= 59.0
        } else {
            return safeAreaInsets.left >= 59.0
        }
    }
    
    /// 屏幕一像素的大小
    nonisolated public static var pixelOne: CGFloat {
        return 1.0 / screenScale
    }
    
    /// 检查是否含有安全区域，可用来判断iPhoneX
    public static var hasSafeAreaInsets: Bool {
        return safeAreaInsets.bottom > 0
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

    /// 状态栏高度，与是否隐藏无关
    public static var statusBarHeight: CGFloat {
        if let statusBarManager = UIWindow.fw.mainScene?.statusBarManager,
           !statusBarManager.isStatusBarHidden {
            return statusBarManager.statusBarFrame.height
        }
        
        if UIDevice.fw.isIpad {
            return isNotchedScreen ? 24 : 20
        }
        
        if UIDevice.fw.isLandscape { return 0 }
        if !isNotchedScreen { return 20 }
        if isDynamicIsland { return 54 }
        if UIDevice.fw.deviceModel == "iPhone12,1" { return 48 }
        if UIDevice.fw.deviceSize.equalTo(CGSize(width: 390, height: 844)) { return 47 }
        if isScreenInch(.inch67) { return 47 }
        if isScreenInch(.inch54) && UIDevice.fw.iosVersion >= 15.0 { return 50 }
        return 44
    }
    
    /// 导航栏高度，与是否隐藏无关
    public static var navigationBarHeight: CGFloat {
        if UIDevice.fw.isIpad {
            return UIDevice.fw.iosVersion >= 12.0 ? 50 : 44
        }
        
        var height: CGFloat = 44
        if UIDevice.fw.isLandscape {
            height = isRegularScreen ? 44 : 32
        }
        return height
    }
    
    /// 顶部栏高度，包含状态栏、导航栏，与是否隐藏无关
    public static var topBarHeight: CGFloat {
        return statusBarHeight + navigationBarHeight
    }
    
    /// 标签栏高度，与是否隐藏无关
    public static var tabBarHeight: CGFloat {
        if UIDevice.fw.isIpad {
            if isNotchedScreen { return 65 }
            return UIDevice.fw.iosVersion >= 12.0 ? 50 : 49
        }
        
        var height: CGFloat = 49
        if UIDevice.fw.isLandscape {
            height = isRegularScreen ? 49 : 32
        }
        return height + safeAreaInsets.bottom
    }
    
    /// 工具栏高度，与是否隐藏无关
    public static var toolBarHeight: CGFloat {
        if UIDevice.fw.isIpad {
            if isNotchedScreen { return 70 }
            return UIDevice.fw.iosVersion >= 12.0 ? 50 : 44
        }
        
        var height: CGFloat = 44
        if UIDevice.fw.isLandscape {
            height = isRegularScreen ? 44 : 32
        }
        return height + safeAreaInsets.bottom
    }
    
    private static var isRegularScreen: Bool {
        // https://github.com/Tencent/QMUI_iOS
        if UIDevice.fw.isIpad { return true }
        
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
    public static var referenceSize: CGSize {
        get { return UIScreen.innerReferenceSize }
        set { UIScreen.innerReferenceSize = newValue }
    }
    
    /// 全局自定义屏幕宽度缩放比例句柄，默认nil
    public static var relativeScaleBlock: (() -> CGFloat)? {
        get { return UIScreen.innerRelativeScaleBlock }
        set { UIScreen.innerRelativeScaleBlock = newValue }
    }
    
    /// 全局自定义屏幕高度缩放比例句柄，默认nil
    public static var relativeHeightScaleBlock: (() -> CGFloat)? {
        get { return UIScreen.innerRelativeHeightScaleBlock }
        set { UIScreen.innerRelativeHeightScaleBlock = newValue }
    }
    
    /// 获取当前屏幕宽度缩放比例，宽度常用
    public static var relativeScale: CGFloat {
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
    public static var relativeHeightScale: CGFloat {
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
    public static func relativeValue(_ value: CGFloat, flat: Bool = false) -> CGFloat {
        let result = value * relativeScale
        return flat ? flatValue(result) : result
    }

    /// 获取相对设计图高度等比例缩放值
    public static func relativeHeight(_ value: CGFloat, flat: Bool = false) -> CGFloat {
        let result = value * relativeHeightScale
        return flat ? flatValue(result) : result
    }
    
    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    public static func fixedValue(_ value: CGFloat, flat: Bool = false) -> CGFloat {
        let result = value / relativeScale
        return flat ? flatValue(result) : result
    }

    /// 获取相对设计图高度等比例缩放时的固定高度值
    public static func fixedHeight(_ value: CGFloat, flat: Bool = false) -> CGFloat {
        let result = value / relativeHeightScale
        return flat ? flatValue(result) : result
    }

    /// 基于指定的倍数(0取当前设备)，对传进来的floatValue进行像素取整
    nonisolated public static func flatValue(_ value: CGFloat, scale: CGFloat = 0) -> CGFloat {
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
            return propertyBool(forName: "autoScaleTransform")
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
        let isPortrait = !UIDevice.fw.isLandscape
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
        return statusBarHeight + navigationBarHeight
    }

    /// 当前标签栏布局高度，隐藏时为0，推荐使用
    public var tabBarHeight: CGFloat {
        guard let tabController = base.tabBarController else { return 0 }
        guard !tabBarHidden else { return 0 }
        if base.hidesBottomBarWhenPushed && !isHead { return 0 }
        return tabController.tabBar.frame.height
    }

    /// 当前工具栏布局高度，隐藏时为0，推荐使用
    public var toolBarHeight: CGFloat {
        guard let navController = base.navigationController,
              !navController.isToolbarHidden else { return 0 }
        // 如果未同时显示标签栏，高度需要加上安全区域高度
        var height = navController.toolbar.frame.height
        if base.tabBarController != nil, !tabBarHidden,
           !(base.hidesBottomBarWhenPushed && !isHead) {
        } else {
            height += UIScreen.fw.safeAreaInsets.bottom
        }
        return height
    }

    /// 当前底部栏布局高度，包含标签栏和工具栏，隐藏时为0，推荐使用
    public var bottomBarHeight: CGFloat {
        return tabBarHeight + toolBarHeight
    }
}

// MARK: - Adaptive+Shortcut
extension CGFloat {
    
    /// 获取相对设计图宽度等比例缩放值
    @MainActor public var relative: CGFloat { UIScreen.fw.relativeValue(self) }
    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    @MainActor public var fixed: CGFloat { UIScreen.fw.fixedValue(self) }
    /// 获取基于当前设备的倍数像素取整值
    public var flat: CGFloat { UIScreen.fw.flatValue(self) }
    /// 获取向上取整值
    public var ceil: CGFloat { Darwin.ceil(self) }
    
}

extension CGSize {
    
    /// 获取相对设计图宽度等比例缩放size
    @MainActor public var relative: CGSize { CGSize(width: width.relative, height: height.relative) }
    /// 获取相对设计图宽度等比例缩放时的固定size
    @MainActor public var fixed: CGSize { CGSize(width: width.fixed, height: height.fixed) }
    /// 获取基于当前设备的倍数像素取整size
    public var flat: CGSize { CGSize(width: width.flat, height: height.flat) }
    /// 获取向上取整size
    public var ceil: CGSize { CGSize(width: width.ceil, height: height.ceil) }
    
}

extension CGPoint {
    
    /// 获取相对设计图宽度等比例缩放point
    @MainActor public var relative: CGPoint { CGPoint(x: x.relative, y: y.relative) }
    /// 获取相对设计图宽度等比例缩放时的固定point
    @MainActor public var fixed: CGPoint { CGPoint(x: x.fixed, y: y.fixed) }
    /// 获取基于当前设备的倍数像素取整point
    public var flat: CGPoint { CGPoint(x: x.flat, y: y.flat) }
    /// 获取向上取整point
    public var ceil: CGPoint { CGPoint(x: x.ceil, y: y.ceil) }
    
}

extension CGRect {
    
    /// 获取相对设计图宽度等比例缩放rect
    @MainActor public var relative: CGRect { CGRect(origin: origin.relative, size: size.relative) }
    /// 获取相对设计图宽度等比例缩放时的固定rect
    @MainActor public var fixed: CGRect { CGRect(origin: origin.fixed, size: size.fixed) }
    /// 获取基于当前设备的倍数像素取整rect
    public var flat: CGRect { CGRect(origin: origin.flat, size: size.flat) }
    /// 获取向上取整rect
    public var ceil: CGRect { CGRect(origin: origin.ceil, size: size.ceil) }
    
}

extension UIEdgeInsets {
    
    /// 获取相对设计图宽度等比例缩放insets
    @MainActor public var relative: UIEdgeInsets { UIEdgeInsets(top: top.relative, left: left.relative, bottom: bottom.relative, right: right.relative) }
    /// 获取相对设计图宽度等比例缩放时的固定insets
    @MainActor public var fixed: UIEdgeInsets { UIEdgeInsets(top: top.fixed, left: left.fixed, bottom: bottom.fixed, right: right.fixed) }
    /// 获取基于当前设备的倍数像素取整insets
    public var flat: UIEdgeInsets { UIEdgeInsets(top: top.flat, left: left.flat, bottom: bottom.flat, right: right.flat) }
    /// 获取向上取整insets
    public var ceil: UIEdgeInsets { UIEdgeInsets(top: top.ceil, left: left.ceil, bottom: bottom.ceil, right: right.ceil) }
    
}

extension Int {
    
    /// 获取相对设计图宽度等比例缩放值
    @MainActor public var relative: CGFloat { UIScreen.fw.relativeValue(CGFloat(self)) }
    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    @MainActor public var fixed: CGFloat { UIScreen.fw.fixedValue(CGFloat(self)) }
    /// 获取基于当前设备的倍数像素取整值
    public var flat: CGFloat { UIScreen.fw.flatValue(CGFloat(self)) }
    /// 获取向上取整值
    public var ceil: CGFloat { Darwin.ceil(CGFloat(self)) }
    
}

extension Float {
    
    /// 获取相对设计图宽度等比例缩放值
    @MainActor public var relative: CGFloat { UIScreen.fw.relativeValue(CGFloat(self)) }
    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    @MainActor public var fixed: CGFloat { UIScreen.fw.fixedValue(CGFloat(self)) }
    /// 获取基于当前设备的倍数像素取整值
    public var flat: CGFloat { UIScreen.fw.flatValue(CGFloat(self)) }
    /// 获取向上取整值
    public var ceil: CGFloat { Darwin.ceil(CGFloat(self)) }
    
}

extension Double {
    
    /// 获取相对设计图宽度等比例缩放值
    @MainActor public var relative: CGFloat { UIScreen.fw.relativeValue(CGFloat(self)) }
    /// 获取相对设计图宽度等比例缩放时的固定宽度值
    @MainActor public var fixed: CGFloat { UIScreen.fw.fixedValue(CGFloat(self)) }
    /// 获取基于当前设备的倍数像素取整值
    public var flat: CGFloat { UIScreen.fw.flatValue(CGFloat(self)) }
    /// 获取向上取整值
    public var ceil: CGFloat { Darwin.ceil(CGFloat(self)) }
    
}

// MARK: - UIDevice+Adaptive
extension UIDevice {
    
    nonisolated(unsafe) fileprivate static var innerIsIphone: Bool?
    nonisolated(unsafe) fileprivate static var innerIsIpad: Bool?
    nonisolated(unsafe) internal static var innerDeviceIDFV: String?
    
}

// MARK: - UIScreen+Adaptive
extension UIScreen {
    
    nonisolated(unsafe) fileprivate static var innerScreenScale: CGFloat?
    nonisolated(unsafe) fileprivate static var innerReferenceSize: CGSize = CGSize(width: 375, height: 812)
    nonisolated(unsafe) fileprivate static var innerRelativeScaleBlock: (() -> CGFloat)?
    nonisolated(unsafe) fileprivate static var innerRelativeHeightScaleBlock: (() -> CGFloat)?
    nonisolated(unsafe) fileprivate static var innerMainWindow: UIWindow?
    
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

// MARK: - FrameworkAutoloader+Adaptive
extension FrameworkAutoloader {
    
    @objc static func loadToolkit_Adaptive() {
        DispatchQueue.fw.mainAsync {
            UIDevice.innerIsIphone = UIDevice.current.userInterfaceIdiom == .phone
            UIDevice.innerIsIpad = UIDevice.current.userInterfaceIdiom == .pad
            UIScreen.innerScreenScale = UIScreen.main.scale
            UIDevice.innerDeviceIDFV = UIDevice.current.identifierForVendor?.uuidString ?? ""
        }
    }
    
}
