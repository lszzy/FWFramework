//
//  UIKit.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit
import CoreTelephony

// MARK: - Wrapper+UIBezierPath
extension Wrapper where Base: UIBezierPath {
    /// 绘制形状图片，自定义画笔宽度、画笔颜色、填充颜色，填充颜色为nil时不执行填充
    public func shapeImage(_ size: CGSize, strokeWidth: CGFloat, strokeColor: UIColor, fillColor: UIColor?) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.setLineWidth(strokeWidth)
        context.setLineCap(.round)
        strokeColor.setStroke()
        context.addPath(base.cgPath)
        context.strokePath()
        
        if let fillColor = fillColor {
            fillColor.setFill()
            context.addPath(base.cgPath)
            context.fillPath()
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 绘制形状Layer，自定义画笔宽度、画笔颜色、填充颜色，填充颜色为nil时不执行填充
    public func shapeLayer(_ rect: CGRect, strokeWidth: CGFloat, strokeColor: UIColor, fillColor: UIColor?) -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.frame = rect
        layer.lineWidth = strokeWidth
        layer.lineCap = .round
        layer.strokeColor = strokeColor.cgColor
        if let fillColor = fillColor {
            layer.fillColor = fillColor.cgColor
        }
        layer.path = base.cgPath
        return layer
    }

    /// 根据点计算折线路径(NSValue点)
    public static func lines(points: [NSValue]) -> UIBezierPath {
        let path = UIBezierPath()
        var value = points.first ?? NSValue(cgPoint: .zero)
        path.move(to: value.cgPointValue)
        
        for i in 1 ..< points.count {
            value = points[i]
            path.addLine(to: value.cgPointValue)
        }
        return path
    }

    /// 根据点计算贝塞尔曲线路径
    public static func quadCurvedPath(points: [NSValue]) -> UIBezierPath {
        let path = UIBezierPath()
        var value = points.first ?? NSValue(cgPoint: .zero)
        var p1 = value.cgPointValue
        path.move(to: p1)
        
        if points.count == 2 {
            value = points[1]
            path.addLine(to: value.cgPointValue)
            return path
        }
        
        for i in 1 ..< points.count {
            value = points[i]
            let p2 = value.cgPointValue
            
            let midPoint = middlePoint(p1, with: p2)
            path.addQuadCurve(to: midPoint, controlPoint: controlPoint(midPoint, with: p1))
            path.addQuadCurve(to: p2, controlPoint: controlPoint(midPoint, with: p2))
            
            p1 = p2
        }
        return path
    }
    
    /// 计算两点的中心点
    public static func middlePoint(_ p1: CGPoint, with p2: CGPoint) -> CGPoint {
        return CGPoint(x: (p1.x + p2.x) / 2.0, y: (p1.y + p2.y) / 2.0)
    }

    /// 计算两点的贝塞尔曲线控制点
    public static func controlPoint(_ p1: CGPoint, with p2: CGPoint) -> CGPoint {
        var controlPoint = middlePoint(p1, with: p2)
        let diffY = abs(p2.y - controlPoint.y)
        if p1.y < p2.y {
            controlPoint.y += diffY
        } else if p1.y > p2.y {
            controlPoint.y -= diffY
        }
        return controlPoint
    }
    
    /// 将角度(0~360)转换为弧度，周长为2*M_PI*r
    public static func radian(degree: CGFloat) -> CGFloat {
        return (CGFloat.pi * degree) / 180.0
    }
    
    /// 将弧度转换为角度(0~360)
    public static func degree(radian: CGFloat) -> CGFloat {
        return (radian * 180.0) / CGFloat.pi
    }
    
    /// 根据滑动方向计算rect的线段起点、终点中心点坐标数组(示范：田)。默认从上到下滑动
    public static func linePoints(rect: CGRect, direction: UISwipeGestureRecognizer.Direction) -> [NSValue] {
        var startPoint: CGPoint = .zero
        var endPoint: CGPoint = .zero
        switch direction {
        case .right:
            startPoint = CGPoint(x: CGRectGetMinX(rect), y: CGRectGetMidY(rect))
            endPoint = CGPoint(x: CGRectGetMaxX(rect), y: CGRectGetMidY(rect))
        case .up:
            startPoint = CGPoint(x: CGRectGetMidX(rect), y: CGRectGetMaxY(rect))
            endPoint = CGPoint(x: CGRectGetMidX(rect), y: CGRectGetMinY(rect))
        case .left:
            startPoint = CGPoint(x: CGRectGetMaxX(rect), y: CGRectGetMidY(rect))
            endPoint = CGPoint(x: CGRectGetMinX(rect), y: CGRectGetMidY(rect))
        case .down:
            startPoint = CGPoint(x: CGRectGetMidX(rect), y: CGRectGetMinY(rect))
            endPoint = CGPoint(x: CGRectGetMidX(rect), y: CGRectGetMaxY(rect))
        default:
            startPoint = CGPoint(x: CGRectGetMidX(rect), y: CGRectGetMinY(rect))
            endPoint = CGPoint(x: CGRectGetMidX(rect), y: CGRectGetMaxY(rect))
        }
        return [NSValue(cgPoint: startPoint), NSValue(cgPoint: endPoint)]
    }
}

// MARK: - Wrapper+UIDevice
extension Wrapper where Base: UIDevice {
    /// 设置设备token原始Data，格式化并保存
    public static func setDeviceTokenData(_ tokenData: Data?) {
        if let tokenData = tokenData {
            deviceToken = tokenData.map{ String(format: "%02.0hhx", $0) }.joined()
        } else {
            deviceToken = nil
        }
    }

    /// 获取设备Token格式化后的字符串
    public static var deviceToken: String? {
        get {
            return UserDefaults.standard.string(forKey: "FWDeviceToken")
        }
        set {
            if let deviceToken = newValue {
                UserDefaults.standard.set(deviceToken, forKey: "FWDeviceToken")
                UserDefaults.standard.synchronize()
            } else {
                UserDefaults.standard.removeObject(forKey: "FWDeviceToken")
                UserDefaults.standard.synchronize()
            }
        }
    }

    /// 获取设备IDFV(内部使用)，同账号应用全删除后会改变，可通过keychain持久化
    public static var deviceIDFV: String? {
        return UIDevice.current.identifierForVendor?.uuidString
    }
    
    /// 获取或设置设备UUID，自动keychain持久化。默认获取IDFV(未使用IDFA，避免额外权限)，失败则随机生成一个
    public static var deviceUUID: String {
        get {
            if let deviceUUID = UIDevice.innerDeviceUUID {
                return deviceUUID
            }
            
            if let deviceUUID = KeychainManager.shared.password(forService: "FWDeviceUUID", account: Bundle.main.bundleIdentifier) {
                UIDevice.innerDeviceUUID = deviceUUID
                return deviceUUID
            }
            
            let deviceUUID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            UIDevice.innerDeviceUUID = deviceUUID
            KeychainManager.shared.setPassword(deviceUUID, forService: "FWDeviceUUID", account: Bundle.main.bundleIdentifier)
            return deviceUUID
        }
        set {
            UIDevice.innerDeviceUUID = newValue
            KeychainManager.shared.setPassword(newValue, forService: "FWDeviceUUID", account: Bundle.main.bundleIdentifier)
        }
    }
    
    /// 是否越狱
    public static var isJailbroken: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        // 1
        let paths = [
            "/Applications/Cydia.app",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/stash"
        ]
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }

        // 2
        if let bash = fopen("/bin/bash", "r") {
            fclose(bash)
            return true
        }

        // 3
        let uuidString = UUID().uuidString
        let path = "/private/\(uuidString)"
        do {
            try "test".write(toFile: path, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: path)
            return true
        } catch {
            return false
        }
        #endif
    }
    
    /// 本地IP地址
    public static var ipAddress: String? {
        var ipAddr: String?
        var addrs: UnsafeMutablePointer<ifaddrs>? = nil
        
        let ret = getifaddrs(&addrs)
        if 0 == ret {
            var cursor = addrs
            
            while cursor != nil {
                if AF_INET == cursor!.pointee.ifa_addr.pointee.sa_family && 0 == (cursor!.pointee.ifa_flags & UInt32(IFF_LOOPBACK)) {
                    ipAddr = String(cString: inet_ntoa(UnsafeMutablePointer<sockaddr_in>(OpaquePointer(cursor!.pointee.ifa_addr)).pointee.sin_addr))
                    break
                }
                
                cursor = cursor!.pointee.ifa_next
            }
            
            freeifaddrs(addrs)
        }
        
        return ipAddr
    }
    
    /// 本地主机名称
    public static var hostName: String? {
        var hostName = [CChar](repeating: 0, count: 256)
        let success = gethostname(&hostName, 255)
        if success != 0 { return nil }
        hostName[255] = 0

        #if targetEnvironment(simulator)
        return String(cString: hostName)
        #else
        return String(format: "%s.local", hostName)
        #endif
    }
    
    /// 手机蜂窝网络类型列表，仅区分2G|3G|4G|5G
    public static var networkTypes: [String]? {
        guard let currentRadio = UIDevice.innerNetworkInfo.serviceCurrentRadioAccessTechnology else {
            return nil
        }
        
        return currentRadio.values.compactMap { networkType($0) }
    }
    
    private static func networkType(_ accessTechnology: String) -> String? {
        let types2G = [
            CTRadioAccessTechnologyGPRS,
            CTRadioAccessTechnologyEdge,
            CTRadioAccessTechnologyCDMA1x
        ]
        let types3G = [
            CTRadioAccessTechnologyWCDMA,
            CTRadioAccessTechnologyHSDPA,
            CTRadioAccessTechnologyHSUPA,
            CTRadioAccessTechnologyCDMAEVDORev0,
            CTRadioAccessTechnologyCDMAEVDORevA,
            CTRadioAccessTechnologyCDMAEVDORevB,
            CTRadioAccessTechnologyeHRPD
        ]
        let types4G = [
            CTRadioAccessTechnologyLTE
        ]
        var types5G: [String] = []
        if #available(iOS 14.1, *) {
            types5G = [
                CTRadioAccessTechnologyNRNSA,
                CTRadioAccessTechnologyNR
            ]
        }
        
        var networkType: String?
        if types5G.contains(accessTechnology) {
            networkType = "5G"
        } else if types4G.contains(accessTechnology) {
            networkType = "4G"
        } else if types3G.contains(accessTechnology) {
            networkType = "3G"
        } else if types2G.contains(accessTechnology) {
            networkType = "2G"
        }
        return networkType
    }
}

// MARK: - Wrapper+UIView
/// 事件穿透实现方法：重写-hitTest:withEvent:方法，当为指定视图(如base)时返回nil排除即可
extension Wrapper where Base: UIView {
    /// 视图是否可见，视图hidden为NO、alpha>0.01、window存在且size不为0才认为可见
    public var isViewVisible: Bool {
        if base.isHidden || base.alpha <= 0.01 || base.window == nil { return false }
        if base.bounds.width == 0 || base.bounds.height == 0 { return false }
        return true
    }

    /// 获取响应的视图控制器
    public var viewController: UIViewController? {
        var responder = base.next
        while responder != nil {
            if let viewController = responder as? UIViewController {
                return viewController
            }
            responder = responder?.next
        }
        return nil
    }

    /// 设置额外热区(点击区域)
    public var touchInsets: UIEdgeInsets {
        get {
            if let value = property(forName: "touchInsets") as? NSValue {
                return value.uiEdgeInsetsValue
            }
            return .zero
        }
        set {
            setProperty(NSValue(uiEdgeInsets: newValue), forName: "touchInsets")
        }
    }
    
    /// 设置视图是否允许检测子视图pointInside，默认false
    public var pointInsideSubviews: Bool {
        get { return propertyBool(forName: "pointInsideSubviews") }
        set { setPropertyBool(newValue, forName: "pointInsideSubviews") }
    }
    
    /// 设置视图是否可穿透(子视图响应)
    public var isPenetrable: Bool {
        get { return propertyBool(forName: "isPenetrable") }
        set { setPropertyBool(newValue, forName: "isPenetrable") }
    }

    /// 设置自动计算适合高度的frame，需实现sizeThatFits:方法
    public var fitFrame: CGRect {
        get {
            return base.frame
        }
        set {
            var fitFrame = newValue
            fitFrame.size = fitSize(drawSize: CGSize(width: fitFrame.size.width, height: .greatestFiniteMagnitude))
            base.frame = fitFrame
        }
    }

    /// 计算当前视图适合大小，需实现sizeThatFits:方法
    public var fitSize: CGSize {
        if base.frame.size.equalTo(.zero) {
            base.setNeedsLayout()
            base.layoutIfNeeded()
        }
        
        let drawSize = CGSize(width: base.frame.size.width, height: .greatestFiniteMagnitude)
        return fitSize(drawSize: drawSize)
    }

    /// 计算指定边界，当前视图适合大小，需实现sizeThatFits:方法
    public func fitSize(drawSize: CGSize) -> CGSize {
        let size = base.sizeThatFits(drawSize)
        return CGSize(width: min(drawSize.width, ceil(size.width)), height: min(drawSize.height, ceil(size.height)))
    }
    
    /// 根据tag查找subview，仅从subviews中查找
    public func subview(tag: Int) -> UIView? {
        var subview: UIView?
        for obj in base.subviews {
            if obj.tag == tag {
                subview = obj
                break
            }
        }
        return subview
    }
    
    /// 根据accessibilityIdentifier查找subview，仅从subviews中查找
    public func subview(identifier: String) -> UIView? {
        var subview: UIView?
        for obj in base.subviews {
            if obj.accessibilityIdentifier == identifier {
                subview = obj
                break
            }
        }
        return subview
    }

    /// 设置阴影颜色、偏移和半径
    public func setShadowColor(_ color: UIColor?, offset: CGSize, radius: CGFloat) {
        base.layer.shadowColor = color?.cgColor
        base.layer.shadowOffset = offset
        base.layer.shadowRadius = radius
        base.layer.shadowOpacity = 1.0
    }

    /// 绘制四边边框
    public func setBorderColor(_ color: UIColor?, width: CGFloat) {
        base.layer.borderColor = color?.cgColor
        base.layer.borderWidth = width
    }

    /// 绘制四边边框和四角圆角
    public func setBorderColor(_ color: UIColor?, width: CGFloat, cornerRadius: CGFloat) {
        setBorderColor(color, width: width)
        setCornerRadius(cornerRadius)
    }

    /// 绘制四角圆角
    public func setCornerRadius(_ radius: CGFloat) {
        base.layer.cornerRadius = radius
        base.layer.masksToBounds = true
    }

    /// 绘制单边或多边边框Layer。frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
    public func setBorderLayer(_ edge: UIRectEdge, color: UIColor?, width: CGFloat) {
        setBorderLayer(edge, color: color, width: width, leftInset: 0, rightInset: 0)
    }

    /// 绘制单边或多边边框Layer。frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
    public func setBorderLayer(_ edge: UIRectEdge, color: UIColor?, width: CGFloat, leftInset: CGFloat, rightInset: CGFloat) {
        if edge.contains(.top) {
            let borderLayer = borderLayer("borderLayerTop")
            borderLayer.frame = CGRect(x: leftInset, y: 0, width: base.bounds.size.width - leftInset - rightInset, height: width)
            borderLayer.backgroundColor = color?.cgColor
        }
        
        if edge.contains(.left) {
            let borderLayer = borderLayer("borderLayerLeft")
            borderLayer.frame = CGRect(x: 0, y: leftInset, width: width, height: base.bounds.size.height - leftInset - rightInset)
            borderLayer.backgroundColor = color?.cgColor
        }
        
        if edge.contains(.bottom) {
            let borderLayer = borderLayer("borderLayerBottom")
            borderLayer.frame = CGRect(x: leftInset, y: base.bounds.size.height - width, width: base.bounds.size.width - leftInset - rightInset, height: width)
            borderLayer.backgroundColor = color?.cgColor
        }
        
        if edge.contains(.right) {
            let borderLayer = borderLayer("borderLayerRight")
            borderLayer.frame = CGRect(x: base.bounds.size.width - width, y: leftInset, width: width, height: base.bounds.size.height - leftInset - rightInset)
            borderLayer.backgroundColor = color?.cgColor
        }
    }
    
    private func borderLayer(_ edgeKey: String) -> CALayer {
        if let borderLayer = property(forName: edgeKey) as? CALayer {
            return borderLayer
        } else {
            let borderLayer = CALayer()
            base.layer.addSublayer(borderLayer)
            setProperty(borderLayer, forName: edgeKey)
            return borderLayer
        }
    }
    
    /// 绘制四边虚线边框和四角圆角。frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
    public func setDashBorderLayer(color: UIColor?, width: CGFloat, cornerRadius: CGFloat, lineLength: CGFloat, lineSpacing: CGFloat) {
        var borderLayer: CAShapeLayer
        if let layer = property(forName: "dashBorderLayer") as? CAShapeLayer {
            borderLayer = layer
        } else {
            borderLayer = CAShapeLayer()
            base.layer.addSublayer(borderLayer)
            setProperty(borderLayer, forName: "dashBorderLayer")
        }
        
        borderLayer.frame = base.bounds
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = color?.cgColor
        borderLayer.lineWidth = width
        borderLayer.lineJoin = .round
        borderLayer.lineDashPattern = [NSNumber(value: lineLength), NSNumber(value: lineSpacing)]
        borderLayer.position = CGPoint(x: CGRectGetMidX(base.bounds), y: CGRectGetMidY(base.bounds))
        borderLayer.path = UIBezierPath(roundedRect: CGRect(x: width / 2.0, y: width / 2.0, width: max(0, CGRectGetWidth(base.bounds) - width), height: max(0, CGRectGetHeight(base.bounds) - width)), cornerRadius: cornerRadius).cgPath
    }

    /// 绘制单个或多个边框圆角，frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
    public func setCornerLayer(_ corner: UIRectCorner, radius: CGFloat) {
        let cornerLayer = CAShapeLayer()
        let path = UIBezierPath(roundedRect: base.bounds, byRoundingCorners: corner, cornerRadii: CGSize(width: radius, height: radius))
        cornerLayer.frame = base.bounds
        cornerLayer.path = path.cgPath
        base.layer.mask = cornerLayer
    }

    /// 绘制单个或多个边框圆角和四边边框，frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
    public func setCornerLayer(_ corner: UIRectCorner, radius: CGFloat, borderColor: UIColor?, width: CGFloat) {
        setCornerLayer(corner, radius: radius)
        
        var borderLayer: CAShapeLayer
        if let layer = property(forName: "borderLayerCorner") as? CAShapeLayer {
            borderLayer = layer
        } else {
            borderLayer = CAShapeLayer()
            base.layer.addSublayer(borderLayer)
            setProperty(borderLayer, forName: "borderLayerCorner")
        }
        
        let path = UIBezierPath(roundedRect: base.bounds, byRoundingCorners: corner, cornerRadii: CGSize(width: radius, height: radius))
        borderLayer.frame = base.bounds
        borderLayer.path = path.cgPath
        borderLayer.strokeColor = borderColor?.cgColor
        borderLayer.lineWidth = width * 2.0
        borderLayer.fillColor = nil
    }
    
    /// 绘制单边或多边边框视图。使用AutoLayout
    public func setBorderView(_ edge: UIRectEdge, color: UIColor?, width: CGFloat) {
        setBorderView(edge, color: color, width: width, leftInset: 0, rightInset: 0)
    }

    /// 绘制单边或多边边框。使用AutoLayout
    public func setBorderView(_ edge: UIRectEdge, color: UIColor?, width: CGFloat, leftInset: CGFloat, rightInset: CGFloat) {
        if edge.contains(.top) {
            let borderView = borderView("borderViewTop", edge: .top)
            borderView.fw.setDimension(.height, size: width, autoScale: false)
            borderView.fw.pinEdge(toSuperview: .left, inset: leftInset, autoScale: false)
            borderView.fw.pinEdge(toSuperview: .right, inset: rightInset, autoScale: false)
            borderView.backgroundColor = color
        }
        
        if edge.contains(.left) {
            let borderView = borderView("borderViewLeft", edge: .left)
            borderView.fw.setDimension(.width, size: width, autoScale: false)
            borderView.fw.pinEdge(toSuperview: .top, inset: leftInset, autoScale: false)
            borderView.fw.pinEdge(toSuperview: .bottom, inset: rightInset, autoScale: false)
            borderView.backgroundColor = color
        }
        
        if edge.contains(.bottom) {
            let borderView = borderView("borderViewBottom", edge: .bottom)
            borderView.fw.setDimension(.height, size: width, autoScale: false)
            borderView.fw.pinEdge(toSuperview: .left, inset: leftInset, autoScale: false)
            borderView.fw.pinEdge(toSuperview: .right, inset: rightInset, autoScale: false)
            borderView.backgroundColor = color
        }
        
        if edge.contains(.right) {
            let borderView = borderView("borderViewRight", edge: .right)
            borderView.fw.setDimension(.width, size: width, autoScale: false)
            borderView.fw.pinEdge(toSuperview: .top, inset: leftInset, autoScale: false)
            borderView.fw.pinEdge(toSuperview: .bottom, inset: rightInset, autoScale: false)
            borderView.backgroundColor = color
        }
    }
    
    private func borderView(_ edgeKey: String, edge: UIRectEdge) -> UIView {
        if let borderView = property(forName: edgeKey) as? UIView {
            return borderView
        } else {
            let borderView = UIView()
            base.addSubview(borderView)
            setProperty(borderView, forName: edgeKey)
            
            if edge == .top || edge == .bottom {
                borderView.fw.pinEdge(toSuperview: edge == .top ? .top : .bottom, inset: 0, autoScale: false)
                borderView.fw.setDimension(.height, size: 0, autoScale: false)
                borderView.fw.pinEdge(toSuperview: .left, inset: 0, autoScale: false)
                borderView.fw.pinEdge(toSuperview: .right, inset: 0, autoScale: false)
            } else {
                borderView.fw.pinEdge(toSuperview: edge == .left ? .left : .right, inset: 0, autoScale: false)
                borderView.fw.setDimension(.width, size: 0, autoScale: false)
                borderView.fw.pinEdge(toSuperview: .top, inset: 0, autoScale: false)
                borderView.fw.pinEdge(toSuperview: .bottom, inset: 0, autoScale: false)
            }
            return borderView
        }
    }
    
    /// 开始倒计时，从window移除时自动取消，回调参数为剩余时间
    @discardableResult
    public func startCountDown(_ seconds: Int, block: @escaping (Int) -> Void) -> DispatchSourceTimer {
        let queue = DispatchQueue.global()
        let timer = DispatchSource.makeTimerSource(flags: [], queue: queue)
        timer.schedule(wallDeadline: .now(), repeating: 1.0, leeway: .seconds(0))
        
        let startTime = Date.fw.currentTime
        var hasWindow = false
        timer.setEventHandler { [weak base] in
            DispatchQueue.main.async {
                var countDown = seconds - Int(round(Date.fw.currentTime - startTime))
                if countDown <= 0 {
                    timer.cancel()
                }
                
                // 按钮从window移除时自动cancel倒计时
                if !hasWindow && base?.window != nil {
                    hasWindow = true
                } else if hasWindow && base?.window == nil {
                    hasWindow = false
                    countDown = 0
                    timer.cancel()
                }
                
                block(countDown <= 0 ? 0 : countDown)
            }
        }
        timer.resume()
        return timer
    }
    
    /// 设置毛玻璃效果，使用UIVisualEffectView。内容需要添加到UIVisualEffectView.contentView
    @discardableResult
    public func setBlurEffect(_ style: UIBlurEffect.Style) -> UIVisualEffectView? {
        for subview in base.subviews {
            if subview is UIVisualEffectView {
                subview.removeFromSuperview()
            }
        }
        
        if style.rawValue > -1 {
            let effect = UIBlurEffect(style: style)
            let effectView = UIVisualEffectView(effect: effect)
            base.addSubview(effectView)
            effectView.fw.pinEdges(autoScale: false)
            return effectView
        }
        return nil
    }
    
    /// 移除所有子视图
    public func removeAllSubviews() {
        base.subviews.forEach { $0.removeFromSuperview() }
    }

    /// 递归查找指定子类的第一个子视图(含自身)
    public func recursiveSubview<T: UIView>(of type: T.Type) -> T? {
        return recursiveSubview { $0 is T } as? T
    }
    
    /// 递归查找指定条件的第一个子视图(含自身)
    public func recursiveSubview(block: (UIView) -> Bool) -> UIView? {
        if block(base) { return base }
        
        /* 如果需要顺序查找所有子视图，失败后再递归查找，参考此代码即可
        for subview in base.subviews {
            if block(subview) {
                return subview
            }
        } */
        
        for subview in base.subviews {
            if let resultView = subview.fw.recursiveSubview(block: block) {
                return resultView
            }
        }
        return nil
    }
    
    /// 递归查找指定父类的第一个父视图(含自身)
    public func recursiveSuperview<T: UIView>(of type: T.Type) -> T? {
        return recursiveSuperview { $0 is T } as? T
    }
    
    /// 递归查找指定条件的第一个父视图(含自身)
    public func recursiveSuperview(block: (UIView) -> Bool) -> UIView? {
        var resultView: UIView?
        var superview: UIView? = base
        while let view = superview {
            if block(view) {
                resultView = view
                break
            }
            superview = view.superview
        }
        return resultView
    }

    /// 图片截图
    public var snapshotImage: UIImage? {
        return UIImage.fw.image(view: base)
    }

    /// Pdf截图
    public var snapshotPdf: Data? {
        var bounds = base.bounds
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &bounds, nil) else { return nil }
        context.beginPDFPage(nil)
        context.translateBy(x: 0, y: bounds.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        base.layer.render(in: context)
        context.endPDFPage()
        context.closePDF()
        return data as Data
    }
    
    /// 将要设置的frame按照view的anchorPoint(.5, .5)处理后再设置，而系统默认按照(0, 0)方式计算
    public var frameApplyTransform: CGRect {
        get { return base.frame }
        set { base.frame = UIView.fw.rectApplyTransform(newValue, transform: base.transform, anchorPoint: base.layer.anchorPoint) }
    }
    
    /// 计算目标点 targetPoint 围绕坐标点 coordinatePoint 通过 transform 之后此点的坐标。@see https://github.com/Tencent/QMUI_iOS
    private static func pointApplyTransform(_ coordinatePoint: CGPoint, targetPoint: CGPoint, transform: CGAffineTransform) -> CGPoint {
        var p = CGPoint()
        p.x = (targetPoint.x - coordinatePoint.x) * transform.a + (targetPoint.y - coordinatePoint.y) * transform.c + coordinatePoint.x
        p.y = (targetPoint.x - coordinatePoint.x) * transform.b + (targetPoint.y - coordinatePoint.y) * transform.d + coordinatePoint.y
        p.x += transform.tx
        p.y += transform.ty
        return p
    }
    
    /// 系统的 CGRectApplyAffineTransform 只会按照 anchorPoint 为 (0, 0) 的方式去计算，但通常情况下我们面对的是 UIView/CALayer，它们默认的 anchorPoint 为 (.5, .5)，所以增加这个函数，在计算 transform 时可以考虑上 anchorPoint 的影响。@see https://github.com/Tencent/QMUI_iOS
    private static func rectApplyTransform(_ rect: CGRect, transform: CGAffineTransform, anchorPoint: CGPoint) -> CGRect {
        let width = CGRectGetWidth(rect)
        let height = CGRectGetHeight(rect)
        let oPoint = CGPoint(x: rect.origin.x + width * anchorPoint.x, y: rect.origin.y + height * anchorPoint.y)
        let top_left = pointApplyTransform(oPoint, targetPoint: CGPoint(x: rect.origin.x, y: rect.origin.y), transform: transform)
        let bottom_left = pointApplyTransform(oPoint, targetPoint: CGPoint(x: rect.origin.x, y: rect.origin.y + height), transform: transform)
        let top_right = pointApplyTransform(oPoint, targetPoint: CGPoint(x: rect.origin.x + width, y: rect.origin.y), transform: transform)
        let bottom_right = pointApplyTransform(oPoint, targetPoint: CGPoint(x: rect.origin.x + width, y: rect.origin.y + height), transform: transform)
        let minX = min(min(min(top_left.x, bottom_left.x), top_right.x), bottom_right.x)
        let maxX = max(max(max(top_left.x, bottom_left.x), top_right.x), bottom_right.x)
        let minY = min(min(min(top_left.y, bottom_left.y), top_right.y), bottom_right.y)
        let maxY = max(max(max(top_left.y, bottom_left.y), top_right.y), bottom_right.y)
        let newWidth = maxX - minX
        let newHeight = maxY - minY
        let result = CGRect(x: minX, y: minY, width: newWidth, height: newHeight)
        return result
    }
    
    /// 自定义视图排序索引，需结合sortSubviews使用，默认0不处理
    public var sortIndex: Int {
        get { propertyInt(forName: "sortIndex") }
        set { setPropertyInt(newValue, forName: "sortIndex") }
    }

    /// 根据sortIndex排序subviews，需结合sortIndex使用
    public func sortSubviews() {
        var sortViews: [UIView] = []
        for subview in base.subviews {
            if subview.fw.sortIndex != 0 {
                sortViews.append(subview)
            }
        }
        guard sortViews.count > 0 else { return }
        
        sortViews.sort { view1, view2 in
            if view1.fw.sortIndex < 0 && view2.fw.sortIndex < 0 {
                return view2.fw.sortIndex < view1.fw.sortIndex
            } else {
                return view1.fw.sortIndex < view2.fw.sortIndex
            }
        }
        for subview in sortViews {
            if subview.fw.sortIndex < 0 {
                base.sendSubviewToBack(subview)
            } else {
                base.bringSubviewToFront(subview)
            }
        }
    }
    
    /// 是否显示灰色视图，仅支持iOS13+
    public var hasGrayView: Bool {
        let grayView = base.subviews.first { $0 is SaturationGrayView }
        return grayView != nil
    }
    
    /// 显示灰色视图，仅支持iOS13+
    public func showGrayView() {
        hideGrayView()
        
        let overlay = SaturationGrayView()
        overlay.isUserInteractionEnabled = false
        overlay.backgroundColor = UIColor.lightGray
        overlay.layer.compositingFilter = "saturationBlendMode"
        overlay.layer.zPosition = CGFloat(Float.greatestFiniteMagnitude)
        base.addSubview(overlay)
        overlay.fw.pinEdges(autoScale: false)
    }
    
    /// 隐藏灰色视图，仅支持iOS13+
    public func hideGrayView() {
        for subview in base.subviews {
            if subview is SaturationGrayView {
                subview.removeFromSuperview()
            }
        }
    }
    
    /// 定义类通用样式实现句柄，默认样式default
    public static func defineStyle(_ style: ViewStyle = .default, block: @escaping (Base) -> Void) {
        let styleBlock: (UIView) -> Void = { view in
            if let target = view as? Base { block(target) }
        }
        let styleKey = "viewStyleBlock_\(style.rawValue)"
        NSObject.fw.setAssociatedObject(Base.self, key: styleKey, value: styleBlock, policy: .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }
    
    /// 应用类通用样式，默认样式default
    public func addStyle(_ style: ViewStyle = .default) {
        let styleKey = "viewStyleBlock_\(style.rawValue)"
        var styleBlock: ((UIView) -> Void)?
        var styleClass: AnyClass? = type(of: base)
        while let targetClass = styleClass, targetClass != UIResponder.self {
            styleBlock = NSObject.fw.getAssociatedObject(targetClass, key: styleKey) as? (UIView) -> Void
            if styleBlock != nil {
                break
            }
            styleClass = targetClass.superclass()
        }
        styleBlock?(base)
    }
}

// MARK: - Wrapper+UIImageView
extension Wrapper where Base: UIImageView {
    /// 设置图片模式为scaleAspectFill，短边拉伸不变形，超过区域隐藏，一般用于宽度和高度都固定的场景
    public func scaleAspectFill() {
        base.contentMode = .scaleAspectFill
        base.layer.masksToBounds = true
    }
    
    /// 设置图片模式为scaleAspectFit，长边拉伸不变形，超过区域隐藏，一般用于仅宽度或高度固定的场景
    public func scaleAspectFit() {
        base.contentMode = .scaleAspectFit
        base.layer.masksToBounds = true
    }
    
    /// 优化图片人脸显示，参考：https://github.com/croath/UIImageView-BetterFace
    public func faceAware() {
        guard let image = base.image else { return }
        
        DispatchQueue.global(qos: .default).async { [weak base] in
            var ciImage = image.ciImage
            if ciImage == nil, let cgImage = image.cgImage {
                ciImage = CIImage(cgImage: cgImage)
            }
            
            if let ciImage = ciImage,
               let cgImage = image.cgImage,
               let features = UIImageView.innerFaceDetector?.features(in: ciImage),
               !features.isEmpty {
                DispatchQueue.main.async {
                    base?.fw.faceMark(features, size: CGSize(width: cgImage.width, height: cgImage.height))
                }
            } else {
                DispatchQueue.main.async {
                    base?.fw.faceLayer(false)?.removeFromSuperlayer()
                }
            }
        }
    }
    
    private func faceMark(_ features: [CIFeature], size: CGSize) {
        var fixedRect = CGRect(x: CGFloat.greatestFiniteMagnitude, y: CGFloat.greatestFiniteMagnitude, width: 0, height: 0)
        var rightBorder: CGFloat = 0
        var bottomBorder: CGFloat = 0

        for feature in features {
            var oneRect = feature.bounds
            oneRect.origin.y = size.height - oneRect.origin.y - oneRect.size.height

            fixedRect.origin.x = min(oneRect.origin.x, fixedRect.origin.x)
            fixedRect.origin.y = min(oneRect.origin.y, fixedRect.origin.y)

            rightBorder = max(oneRect.origin.x + oneRect.size.width, rightBorder)
            bottomBorder = max(oneRect.origin.y + oneRect.size.height, bottomBorder)
        }

        fixedRect.size.width = rightBorder - fixedRect.origin.x
        fixedRect.size.height = bottomBorder - fixedRect.origin.y

        var fixedCenter = CGPoint(x: fixedRect.origin.x + fixedRect.size.width / 2.0,
                                  y: fixedRect.origin.y + fixedRect.size.height / 2.0)
        var offset = CGPoint.zero
        var finalSize = size

        if size.width / size.height > base.bounds.size.width / base.bounds.size.height {
            finalSize.height = base.bounds.size.height
            finalSize.width = size.width / size.height * finalSize.height
            fixedCenter.x = finalSize.width / size.width * fixedCenter.x
            fixedCenter.y = finalSize.width / size.width * fixedCenter.y

            offset.x = fixedCenter.x - base.bounds.size.width * 0.5
            if offset.x < 0 {
                offset.x = 0
            } else if offset.x + base.bounds.size.width > finalSize.width {
                offset.x = finalSize.width - base.bounds.size.width
            }
            offset.x = -offset.x
        } else {
            finalSize.width = base.bounds.size.width
            finalSize.height = size.height / size.width * finalSize.width
            fixedCenter.x = finalSize.width / size.width * fixedCenter.x
            fixedCenter.y = finalSize.width / size.width * fixedCenter.y

            offset.y = fixedCenter.y - base.bounds.size.height * (1 - 0.618)
            if offset.y < 0 {
                offset.y = 0
            } else if offset.y + base.bounds.size.height > finalSize.height {
                offset.y = finalSize.height - base.bounds.size.height
            }
            offset.y = -offset.y
        }
        
        let sublayer = faceLayer(true)
        sublayer?.frame = CGRect(origin: offset, size: finalSize)
        sublayer?.contents = base.image?.cgImage
    }
    
    private func faceLayer(_ lazyload: Bool) -> CALayer? {
        if let sublayer = base.layer.sublayers?.first(where: { $0.name == "FWFaceLayer" }) {
            return sublayer
        }
        
        if lazyload {
            let sublayer = CALayer()
            sublayer.name = "FWFaceLayer"
            sublayer.actions = ["contents": NSNull(), "bounds": NSNull(), "position": NSNull()]
            base.layer.addSublayer(sublayer)
            return sublayer
        }
        
        return nil
    }

    /// 倒影效果
    public func reflect() {
        var frame = base.frame
        frame.origin.y += frame.size.height + 1
        
        let reflectImageView = UIImageView(frame: frame)
        base.clipsToBounds = true
        reflectImageView.contentMode = base.contentMode
        reflectImageView.image = base.image
        reflectImageView.transform = CGAffineTransform(scaleX: 1.0, y: -1.0)
        
        let reflectLayer = reflectImageView.layer
        let gradientLayer = CAGradientLayer()
        gradientLayer.bounds = reflectLayer.bounds
        gradientLayer.position = CGPoint(x: reflectLayer.bounds.size.width / 2.0, y: reflectLayer.bounds.size.height / 2.0)
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3).cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        reflectLayer.mask = gradientLayer
        
        base.superview?.addSubview(reflectImageView)
    }

    /// 图片水印
    public func setImage(_ image: UIImage, watermarkImage: UIImage, in rect: CGRect) {
        UIGraphicsBeginImageContextWithOptions(base.frame.size, false, 0)
        image.draw(in: base.bounds)
        watermarkImage.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        base.image = newImage
    }

    /// 文字水印，指定区域
    public func setImage(_ image: UIImage, watermarkString: NSAttributedString, in rect: CGRect) {
        UIGraphicsBeginImageContextWithOptions(base.frame.size, false, 0)
        image.draw(in: base.bounds)
        watermarkString.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        base.image = newImage
    }

    /// 文字水印，指定坐标
    public func setImage(_ image: UIImage, watermarkString: NSAttributedString, at point: CGPoint) {
        UIGraphicsBeginImageContextWithOptions(base.frame.size, false, 0)
        image.draw(in: base.bounds)
        watermarkString.draw(at: point)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        base.image = newImage
    }
}

// MARK: - Wrapper+UIWindow
extension Wrapper where Base: UIWindow {
    /// 获取指定索引TabBar根视图控制器(非导航控制器)，找不到返回nil
    public func getTabBarController(index: Int) -> UIViewController? {
        guard let tabBarController = rootTabBarController() else { return nil }
        
        var targetController: UIViewController?
        if (tabBarController.viewControllers?.count ?? 0) > index, index >= 0 {
            targetController = tabBarController.viewControllers?[index]
        }
        
        if let navigationController = targetController as? UINavigationController {
            targetController = navigationController.viewControllers.first
        }
        return targetController
    }
    
    /// 获取指定类TabBar根视图控制器(非导航控制器)，找不到返回nil
    public func getTabBarController<T: UIViewController>(of type: T.Type) -> T? {
        guard let tabBarController = rootTabBarController() else { return nil }
        
        var targetController: T?
        let navigationControllers = tabBarController.viewControllers ?? []
        for navigationController in navigationControllers {
            var viewController: UIViewController? = navigationController
            if let navigationController = navigationController as? UINavigationController {
                viewController = navigationController.viewControllers.first
            }
            if let viewController = viewController as? T {
                targetController = viewController
                break
            }
        }
        return targetController
    }

    /// 获取指定条件TabBar根视图控制器(非导航控制器)，找不到返回nil
    public func getTabBarController(block: (UIViewController) -> Bool) -> UIViewController? {
        guard let tabBarController = rootTabBarController() else { return nil }
        
        var targetController: UIViewController?
        let navigationControllers = tabBarController.viewControllers ?? []
        for navigationController in navigationControllers {
            var viewController: UIViewController? = navigationController
            if let navigationController = navigationController as? UINavigationController {
                viewController = navigationController.viewControllers.first
            }
            if let viewController = viewController,
               block(viewController) {
                targetController = viewController
                break
            }
        }
        return targetController
    }
    
    /// 选中并获取指定索引TabBar根视图控制器(非导航控制器)，找不到返回nil
    @discardableResult
    public func selectTabBarController(index: Int) -> UIViewController? {
        guard let targetController = getTabBarController(index: index) else { return nil }
        return selectTabBarController(viewController: targetController)
    }

    /// 选中并获取指定类TabBar根视图控制器(非导航控制器)，找不到返回nil
    @discardableResult
    public func selectTabBarController<T: UIViewController>(of type: T.Type) -> T? {
        guard let targetController = getTabBarController(of: type) else { return nil }
        return selectTabBarController(viewController: targetController) as? T
    }

    /// 选中并获取指定条件TabBar根视图控制器(非导航控制器)，找不到返回nil
    @discardableResult
    public func selectTabBarController(block: (UIViewController) -> Bool) -> UIViewController? {
        guard let targetController = getTabBarController(block: block) else { return nil }
        return selectTabBarController(viewController: targetController)
    }
    
    private func rootTabBarController() -> UITabBarController? {
        if let tabBarController = base.rootViewController as? UITabBarController {
            return tabBarController
        }
        
        if let navigationController = base.rootViewController as? UINavigationController,
           let tabBarController = navigationController.viewControllers.first as? UITabBarController {
            return tabBarController
        }
        
        return nil
    }
    
    private func selectTabBarController(viewController: UIViewController) -> UIViewController? {
        guard let tabBarController = rootTabBarController() else { return nil }
        
        let targetNavigation = viewController.navigationController ?? viewController
        let currentNavigation = tabBarController.selectedViewController
        if currentNavigation != targetNavigation {
            if let navigationController = currentNavigation as? UINavigationController,
               navigationController.viewControllers.count > 1 {
                navigationController.popToRootViewController(animated: false)
            }
            tabBarController.selectedViewController = targetNavigation
        }
        
        if let navigationController = targetNavigation as? UINavigationController {
            if navigationController.viewControllers.count > 1 {
                navigationController.popToRootViewController(animated: false)
            }
        }
        return viewController
    }
}

// MARK: - Wrapper+UILabel
extension Wrapper where Base: UILabel {
    /// 快速设置attributedText样式，设置后调用setText:会自动转发到setAttributedText:方法
    public var textAttributes: [NSAttributedString.Key: Any]? {
        get {
            return property(forName: "textAttributes") as? [NSAttributedString.Key : Any]
        }
        set {
            let prevTextAttributes = textAttributes
            if (prevTextAttributes as? NSDictionary)?.isEqual(to: newValue ?? [:]) ?? false { return }
            
            setPropertyCopy(newValue, forName: "textAttributes")
            guard (base.text?.count ?? 0) > 0 else { return }
            
            let string = base.attributedText?.mutableCopy() as? NSMutableAttributedString
            let stringLength = string?.length ?? 0
            let fullRange = NSMakeRange(0, stringLength)
            if let prevTextAttributes = prevTextAttributes {
                var removeAttributes: [NSAttributedString.Key] = []
                string?.enumerateAttributes(in: fullRange, using: { attrs, range, _ in
                    if NSEqualRanges(range, NSMakeRange(0, stringLength - 1)),
                       let attrKern = attrs[.kern] as? NSNumber,
                       let prevKern = prevTextAttributes[.kern] as? NSNumber,
                       attrKern.isEqual(to: prevKern) {
                        string?.removeAttribute(.kern, range: NSMakeRange(0, stringLength - 1))
                    }
                    if !NSEqualRanges(range, fullRange) { return }
                    for (attr, value) in attrs {
                        if String.fw.safeString(prevTextAttributes[attr]) == String.fw.safeString(value) {
                            removeAttributes.append(attr)
                        }
                    }
                })
                for attr in removeAttributes {
                    string?.removeAttribute(attr, range: fullRange)
                }
            }
            
            if let textAttributes = newValue {
                string?.addAttributes(textAttributes, range: fullRange)
            }
            base.innerSwizzleSetAttributedText(adjustedAttributedString(string))
        }
    }
    
    fileprivate func adjustedAttributedString(_ string: NSAttributedString?) -> NSAttributedString? {
        guard let string = string, string.length > 0 else { return string }
        var attributedString: NSMutableAttributedString?
        if let mutableString = string as? NSMutableAttributedString {
            attributedString = mutableString
        } else {
            attributedString = string.mutableCopy() as? NSMutableAttributedString
        }
        let attributedLength = attributedString?.length ?? 0
        
        if textAttributes?[.kern] != nil {
            attributedString?.removeAttribute(.kern, range: NSMakeRange(string.length - 1, 1))
        }
        
        var shouldAdjustLineHeight = issetLineHeight
        attributedString?.enumerateAttribute(.paragraphStyle, in: NSMakeRange(0, attributedLength), using: { obj, range, stop in
            guard let style = obj as? NSParagraphStyle else { return }
            if NSEqualRanges(range, NSMakeRange(0, attributedLength)) {
                if style.maximumLineHeight != 0 || style.minimumLineHeight != 0 {
                    shouldAdjustLineHeight = false
                    stop.pointee = true
                }
            }
        })
        if shouldAdjustLineHeight {
            let paraStyle = NSMutableParagraphStyle()
            paraStyle.minimumLineHeight = lineHeight
            paraStyle.maximumLineHeight = lineHeight
            paraStyle.lineBreakMode = base.lineBreakMode
            paraStyle.alignment = base.textAlignment
            attributedString?.addAttribute(.paragraphStyle, value: paraStyle, range: NSMakeRange(0, attributedLength))
            
            let baselineOffset = (lineHeight - base.font.lineHeight) / 4.0
            attributedString?.addAttribute(.baselineOffset, value: baselineOffset, range: NSMakeRange(0, attributedLength))
        }
        return attributedString
    }

    /// 快速设置文字的行高，优先级低于fwTextAttributes，设置后调用setText:会自动转发到setAttributedText:方法。小于等于0时恢复默认行高
    public var lineHeight: CGFloat {
        get {
            if issetLineHeight {
                return propertyDouble(forName: "lineHeight")
            } else if (base.attributedText?.length ?? 0) > 0 {
                var result: CGFloat = 0
                if let string = base.attributedText?.mutableCopy() as? NSMutableAttributedString {
                    string.enumerateAttribute(.paragraphStyle, in: NSMakeRange(0, string.length), using: { obj, range, stop in
                        guard let style = obj as? NSParagraphStyle else { return }
                        if NSEqualRanges(range, NSMakeRange(0, string.length)) {
                            if style.maximumLineHeight != 0 || style.minimumLineHeight != 0 {
                                result = style.maximumLineHeight
                                stop.pointee = true
                            }
                        }
                    })
                }
                return result > 0 ? result : base.font.lineHeight
            } else {
                return base.font.lineHeight
            }
        }
        set {
            if newValue > 0 {
                setPropertyDouble(newValue, forName: "lineHeight")
            } else {
                setProperty(nil, forName: "lineHeight")
            }
            guard let string = base.attributedText?.string else { return }
            let attributedString = NSAttributedString(string: string, attributes: textAttributes)
            base.attributedText = adjustedAttributedString(attributedString)
        }
    }
    
    fileprivate var issetLineHeight: Bool {
        return property(forName: "lineHeight") != nil
    }

    /// 自定义内容边距，未设置时为系统默认。当内容为空时不参与intrinsicContentSize和sizeThatFits:计算，方便自动布局
    public var contentInset: UIEdgeInsets {
        get {
            if let value = property(forName: "contentInset") as? NSValue {
                return value.uiEdgeInsetsValue
            }
            return .zero
        }
        set {
            let insets = UIEdgeInsets(top: UIScreen.fw.flatValue(newValue.top), left: UIScreen.fw.flatValue(newValue.left), bottom: UIScreen.fw.flatValue(newValue.bottom), right: UIScreen.fw.flatValue(newValue.right))
            setProperty(NSValue(uiEdgeInsets: insets), forName: "contentInset")
            base.setNeedsDisplay()
        }
    }
    
    fileprivate var issetContentInset: Bool {
        return property(forName: "contentInset") != nil
    }

    /// 纵向分布方式，默认居中
    public var verticalAlignment: UIControl.ContentVerticalAlignment {
        get {
            let value = propertyInt(forName: "verticalAlignment")
            return .init(rawValue: value) ?? .center
        }
        set {
            setPropertyInt(newValue.rawValue, forName: "verticalAlignment")
            base.setNeedsDisplay()
        }
    }
    
    /// 添加点击手势并自动识别NSLinkAttributeName|URL属性，点击高亮时回调链接，点击其它区域回调nil
    @discardableResult
    public func addLinkGesture(block: @escaping (Any?) -> Void) -> UITapGestureRecognizer {
        base.isUserInteractionEnabled = true
        return addTapGesture { gesture in
            guard let label = gesture.view as? UILabel else { return }
            let attributes = label.fw.attributes(gesture: gesture, allowsSpacing: false)
            let link = attributes[.link] ?? attributes[NSAttributedString.Key("URL")]
            block(link)
        }
    }
    
    /// 获取手势触发位置的文本属性，可实现行内点击效果等，allowsSpacing默认为NO空白处不可点击
    public func attributes(
        gesture: UIGestureRecognizer,
        allowsSpacing: Bool
    ) -> [NSAttributedString.Key: Any] {
        guard let attributedString = base.attributedText?.mutableCopy() as? NSMutableAttributedString else { return [:] }
        let textContainer = NSTextContainer(size: base.bounds.size)
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = base.numberOfLines
        textContainer.lineBreakMode = base.lineBreakMode
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        
        attributedString.fw.addAttributeIfNotExist(.font, value: base.font as Any)
        attributedString.fw.setParagraphStyleValue(NSNumber(value: base.textAlignment.rawValue), forKey: "alignment")
        let textStorage = NSTextStorage(attributedString: attributedString)
        textStorage.addLayoutManager(layoutManager)
        
        let location = gesture.location(in: base)
        var distance: CGFloat = 0
        let index = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: &distance)
        if !allowsSpacing && distance >= 1 { return [:] }
        return attributedString.attributes(at: index, effectiveRange: nil)
    }
    
    /// 快速设置字体并指定行高
    public func setFont(
        _ font: UIFont?,
        lineHeight aLineHeight: CGFloat
    ) {
        if let font = font {
            base.font = font
            lineHeight = font.fw.lineHeight(expected: aLineHeight)
        } else {
            lineHeight = aLineHeight
        }
    }

    /// 快速设置标签并指定文本
    public func setFont(
        _ font: UIFont?,
        textColor: UIColor?,
        text: String? = nil,
        textAlignment: NSTextAlignment? = nil,
        numberOfLines: Int? = nil,
        lineHeight aLineHeight: CGFloat? = nil
    ) {
        if let font = font { base.font = font }
        if let textColor = textColor { base.textColor = textColor }
        if let text = text { base.text = text }
        if let textAlignment = textAlignment { base.textAlignment = textAlignment }
        if let numberOfLines = numberOfLines { base.numberOfLines = numberOfLines }
        if let aLineHeight = aLineHeight {
            if let font = font {
                lineHeight = font.fw.lineHeight(expected: aLineHeight)
            } else {
                lineHeight = aLineHeight
            }
        }
    }
    
    /// 快速创建标签并指定文本
    public static func label(
        font: UIFont?,
        textColor: UIColor?,
        text: String? = nil,
        textAlignment: NSTextAlignment? = nil,
        numberOfLines: Int? = nil,
        lineHeight: CGFloat? = nil
    ) -> Base {
        let label = Base.init()
        label.fw.setFont(font, textColor: textColor, text: text, textAlignment: textAlignment, numberOfLines: numberOfLines, lineHeight: lineHeight)
        return label
    }
    
    /// 自适应字体大小，可设置缩放因子等
    public func adjustsFontSize(
        minimumScaleFactor: CGFloat? = nil,
        baselineAdjustment: UIBaselineAdjustment? = nil
    ) {
        base.adjustsFontSizeToFitWidth = true
        if let minimumScaleFactor = minimumScaleFactor {
            base.minimumScaleFactor = minimumScaleFactor
        }
        if let baselineAdjustment = baselineAdjustment {
            base.baselineAdjustment = baselineAdjustment
        }
    }
    
    /// 获取当前标签是否非空，兼容attributedText|text
    public var isNotEmpty: Bool {
        if (base.attributedText?.length ?? 0) > 0 { return true }
        if (base.text?.count ?? 0) > 0 { return true }
        return false
    }
    
    /// 计算当前标签实际显示行数，兼容contentInset|lineHeight
    public var actualNumberOfLines: Int {
        if base.frame.size.equalTo(.zero) {
            base.setNeedsLayout()
            base.layoutIfNeeded()
        }
        
        let drawSize = CGSize(width: base.frame.size.width, height: .greatestFiniteMagnitude)
        return actualNumberOfLines(drawSize: drawSize)
    }
    
    /// 计算指定边界、内边距、行高、行数时，当前标签实际显示行数
    public func actualNumberOfLines(
        drawSize: CGSize,
        contentInset aContentInset: UIEdgeInsets? = nil,
        lineHeight aLineHeight: CGFloat? = nil,
        numberOfLines aNumberOfLines: Int? = nil
    ) -> Int {
        guard isNotEmpty else { return 0 }
        
        let aContentInset = aContentInset ?? contentInset
        let aLineHeight = aLineHeight ?? lineHeight
        let aNumberOfLines = aNumberOfLines ?? base.numberOfLines
        guard aLineHeight > 0 else { return 0 }
        
        let height = base.sizeThatFits(drawSize).height - aContentInset.top - aContentInset.bottom
        let lines = Int(round(height / aLineHeight))
        return aNumberOfLines > 0 ? min(lines, aNumberOfLines) : lines
    }
    
    /// 计算当前文本所占尺寸，需frame或者宽度布局完整
    public var textSize: CGSize {
        if base.frame.size.equalTo(.zero) {
            base.setNeedsLayout()
            base.layoutIfNeeded()
        }
        
        let drawSize = CGSize(width: base.frame.size.width, height: .greatestFiniteMagnitude)
        return textSize(drawSize: drawSize)
    }
    
    /// 计算指定边界时，当前文本所占尺寸
    public func textSize(
        drawSize: CGSize,
        contentInset aContentInset: UIEdgeInsets? = nil
    ) -> CGSize {
        var attrs: [NSAttributedString.Key: Any] = [:]
        attrs[.font] = base.font
        if base.lineBreakMode != .byWordWrapping {
            let paragraphStyle = NSMutableParagraphStyle()
            // 由于lineBreakMode默认值为TruncatingTail，多行显示时仍然按照WordWrapping计算
            if base.numberOfLines != 1 && base.lineBreakMode == .byTruncatingTail {
                paragraphStyle.lineBreakMode = .byWordWrapping
            } else {
                paragraphStyle.lineBreakMode = base.lineBreakMode
            }
            attrs[.paragraphStyle] = paragraphStyle
        }
        
        let inset = aContentInset ?? contentInset
        let size = (base.text as? NSString)?.boundingRect(with: CGSize(width: drawSize.width - inset.left - inset.right, height: drawSize.height - inset.top - inset.bottom), options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: attrs, context: nil).size ?? .zero
        return CGSize(width: min(drawSize.width, ceil(size.width)) + inset.left + inset.right, height: min(drawSize.height, ceil(size.height)) + inset.top + inset.bottom)
    }

    /// 计算当前属性文本所占尺寸，需frame或者宽度布局完整，attributedText需指定字体
    public var attributedTextSize: CGSize {
        if base.frame.size.equalTo(.zero) {
            base.setNeedsLayout()
            base.layoutIfNeeded()
        }
        
        let drawSize = CGSize(width: base.frame.size.width, height: .greatestFiniteMagnitude)
        return attributedTextSize(drawSize: drawSize)
    }

    /// 计算指定边界时，当前属性文本所占尺寸，attributedText需指定字体
    public func attributedTextSize(
        drawSize: CGSize,
        contentInset aContentInset: UIEdgeInsets? = nil
    ) -> CGSize {
        let inset = aContentInset ?? contentInset
        let size = base.attributedText?.boundingRect(with: CGSize(width: drawSize.width - inset.left - inset.right, height: drawSize.height - inset.top - inset.bottom), options: [.usesFontLeading, .usesLineFragmentOrigin], context: nil).size ?? .zero
        return CGSize(width: min(drawSize.width, ceil(size.width)) + inset.left + inset.right, height: min(drawSize.height, ceil(size.height)) + inset.top + inset.bottom)
    }
}

// MARK: - Wrapper+UIControl
/// 防重复点击可以手工控制enabled或userInteractionEnabled或loading，如request开始时禁用，结束时启用等
/// 注意：需要支持appearance的属性必须标记为objc，否则不会生效
extension Wrapper where Base: UIControl {
    // 设置Touch事件触发间隔，防止短时间多次触发事件，默认0
    public var touchEventInterval: TimeInterval {
        get { return base.innerTouchEventInterval }
        set { base.innerTouchEventInterval = newValue }
    }
    
    fileprivate var touchEventTimestamp: TimeInterval {
        get { propertyDouble(forName: "touchEventTimestamp") }
        set { setPropertyDouble(newValue, forName: "touchEventTimestamp") }
    }
}

// MARK: - Wrapper+UIButton
extension Wrapper where Base: UIButton {
    /// 全局自定义按钮高亮时的alpha配置，默认0.5
    public static var highlightedAlpha: CGFloat {
        get { return UIButton.innerHighlightedAlpha }
        set { UIButton.innerHighlightedAlpha = newValue }
    }
    
    /// 全局自定义按钮禁用时的alpha配置，默认0.3
    public static var disabledAlpha: CGFloat {
        get { return UIButton.innerDisabledAlpha }
        set { UIButton.innerDisabledAlpha = newValue }
    }
    
    /// 自定义按钮禁用时的alpha，如0.3，默认0不生效
    public var disabledAlpha: CGFloat {
        get {
            return propertyDouble(forName: "disabledAlpha")
        }
        set {
            setPropertyDouble(newValue, forName: "disabledAlpha")
            if newValue > 0 {
                base.alpha = base.isEnabled ? 1 : newValue
            }
        }
    }

    /// 自定义按钮高亮时的alpha，如0.5，默认0不生效
    public var highlightedAlpha: CGFloat {
        get {
            return propertyDouble(forName: "highlightedAlpha")
        }
        set {
            setPropertyDouble(newValue, forName: "highlightedAlpha")
            if base.isEnabled && newValue > 0 {
                base.alpha = base.isHighlighted ? newValue : 1
            }
        }
    }
    
    /// 自定义按钮禁用状态改变时的句柄，默认nil
    public var disabledChanged: ((UIButton, Bool) -> Void)? {
        get {
            return property(forName: "disabledChanged") as? (UIButton, Bool) -> Void
        }
        set {
            setPropertyCopy(newValue, forName: "disabledChanged")
            if newValue != nil {
                newValue?(base, base.isEnabled)
            }
        }
    }
    
    /// 快速切换按钮是否可用
    public func toggleEnabled(_ enabled: Bool? = nil) {
        if let enabled = enabled {
            base.isEnabled = enabled
        } else {
            base.isEnabled = !base.isEnabled
        }
    }

    /// 自定义按钮高亮状态改变时的句柄，默认nil
    public var highlightedChanged: ((UIButton, Bool) -> Void)? {
        get {
            return property(forName: "highlightedChanged") as? (UIButton, Bool) -> Void
        }
        set {
            setPropertyCopy(newValue, forName: "highlightedChanged")
            if base.isEnabled && newValue != nil {
                newValue?(base, base.isHighlighted)
            }
        }
    }
    
    /// 获取当前按钮是否非空，兼容attributedTitle|title|image
    public var isNotEmpty: Bool {
        if (base.currentAttributedTitle?.length ?? 0) > 0 { return true }
        if (base.currentTitle?.count ?? 0) > 0 { return true }
        if base.currentImage != nil { return true }
        return false
    }
    
    /// 是否内容为空时收缩且不占用布局尺寸，兼容attributedTitle|title|image
    public var contentCollapse: Bool {
        get {
            propertyBool(forName: "contentCollapse")
        }
        set {
            setPropertyBool(newValue, forName: "contentCollapse")
            base.invalidateIntrinsicContentSize()
        }
    }
    
    /// 快速设置文本按钮
    public func setTitle(_ title: String?, font: UIFont?, titleColor: UIColor?) {
        if let title = title { base.setTitle(title, for: .normal) }
        if let font = font { base.titleLabel?.font = font }
        if let titleColor = titleColor { base.setTitleColor(titleColor, for: .normal) }
    }

    /// 快速设置文本
    public func setTitle(_ title: String?) {
        base.setTitle(title, for: .normal)
    }

    /// 快速设置图片
    public func setImage(_ image: UIImage?) {
        base.setImage(image, for: .normal)
    }

    /// 设置图片的居中边位置，需要在setImage和setTitle之后调用才生效，且button大小大于图片+文字+间距
    ///
    /// imageEdgeInsets: 仅有image时相对于button，都有时上左下相对于button，右相对于title，sizeThatFits不包含
    /// titleEdgeInsets: 仅有title时相对于button，都有时上右下相对于button，左相对于image，sizeThatFits不包含
    /// contentEdgeInsets: 内容边距，setImageEdge时不影响，sizeThatFits包含
    public func setImageEdge(_ edge: UIRectEdge, spacing: CGFloat) {
        let imageSize = base.imageView?.image?.size ?? .zero
        let labelSize = base.titleLabel?.intrinsicContentSize ?? .zero
        switch edge {
        case .left:
            base.imageEdgeInsets = UIEdgeInsets(top: 0, left: -spacing / 2.0, bottom: 0, right: spacing / 2.0)
            base.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing / 2.0, bottom: 0, right: -spacing / 2.0)
        case .right:
            base.imageEdgeInsets = UIEdgeInsets(top: 0, left: labelSize.width + spacing / 2.0, bottom: 0, right: -labelSize.width - spacing / 2.0)
            base.titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageSize.width - spacing / 2.0, bottom: 0, right: imageSize.width + spacing / 2.0)
        case .top:
            base.imageEdgeInsets = UIEdgeInsets(top: -labelSize.height - spacing / 2.0, left: 0, bottom: spacing / 2.0, right: -labelSize.width)
            base.titleEdgeInsets = UIEdgeInsets(top: spacing / 2.0, left: -imageSize.width, bottom: -imageSize.height - spacing / 2.0, right: 0)
        case .bottom:
            base.imageEdgeInsets = UIEdgeInsets(top: spacing / 2.0, left: 0, bottom: -labelSize.height - spacing / 2.0, right: -labelSize.width)
            base.titleEdgeInsets = UIEdgeInsets(top: -imageSize.height - spacing / 2.0, left: -imageSize.width, bottom: spacing / 2.0, right: 0)
        default:
            break
        }
    }
    
    /// 图文模式时自适应粗体文本，解决图文按钮文本显示不全(...)的兼容性问题
    public func adjustBoldText() {
        base.titleLabel?.lineBreakMode = .byClipping
    }
    
    /// 设置状态背景色
    public func setBackgroundColor(_ backgroundColor: UIColor?, for state: UIControl.State) {
        var image: UIImage?
        if let backgroundColor = backgroundColor {
            let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
            UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
            let context = UIGraphicsGetCurrentContext()
            context?.setFillColor(backgroundColor.cgColor)
            context?.fill(rect)
            image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        base.setBackgroundImage(image, for: state)
    }
    
    /// 快速创建文本按钮
    public static func button(title: String?, font: UIFont?, titleColor: UIColor?) -> Base {
        let button = Base.init(type: .custom)
        button.fw.setTitle(title, font: font, titleColor: titleColor)
        return button
    }

    /// 快速创建图片按钮
    public static func button(image: UIImage?) -> Base {
        let button = Base.init(type: .custom)
        button.setImage(image, for: .normal)
        return button
    }
    
    /// 设置按钮倒计时，从window移除时自动取消。等待时按钮disabled，非等待时enabled。时间支持格式化，示例：重新获取(%lds)
    @discardableResult
    public func startCountDown(_ seconds: Int, title: String, waitTitle: String) -> DispatchSourceTimer {
        return startCountDown(seconds) { [weak base] countDown in
            // 先设置titleLabel，再设置title，防止闪烁
            if countDown <= 0 {
                base?.titleLabel?.text = title
                base?.setTitle(title, for: .normal)
                base?.isEnabled = true
            } else {
                let waitText = String(format: waitTitle, countDown)
                base?.titleLabel?.text = waitText
                base?.setTitle(waitText, for: .normal)
                base?.isEnabled = false
            }
        }
    }
}

// MARK: - Wrapper+UIScrollView
extension Wrapper where Base: UIScrollView {
    /// 判断当前scrollView内容是否足够滚动
    public var canScroll: Bool {
        return canScrollVertical || canScrollHorizontal
    }

    /// 判断当前的scrollView内容是否足够水平滚动
    public var canScrollHorizontal: Bool {
        if base.bounds.size.width <= 0 { return false }
        return base.contentSize.width + base.adjustedContentInset.left + base.adjustedContentInset.right > CGRectGetWidth(base.bounds)
    }

    /// 判断当前的scrollView内容是否足够纵向滚动
    public var canScrollVertical: Bool {
        if base.bounds.size.height <= 0 { return false }
        return base.contentSize.height + base.adjustedContentInset.top + base.adjustedContentInset.bottom > CGRectGetHeight(base.bounds)
    }

    /// 当前scrollView滚动到指定边
    public func scroll(to edge: UIRectEdge, animated: Bool = true) {
        let contentOffset = contentOffset(of: edge)
        base.setContentOffset(contentOffset, animated: animated)
    }

    /// 是否已滚动到指定边
    public func isScroll(to edge: UIRectEdge) -> Bool {
        let contentOffset = contentOffset(of: edge)
        switch edge {
        case .top:
            return base.contentOffset.y <= contentOffset.y
        case .left:
            return base.contentOffset.x <= contentOffset.x
        case .bottom:
            return base.contentOffset.y >= contentOffset.y
        case .right:
            return base.contentOffset.x >= contentOffset.x
        default:
            return false
        }
    }

    /// 获取当前的scrollView滚动到指定边时的contentOffset(包含contentInset)
    public func contentOffset(of edge: UIRectEdge) -> CGPoint {
        var contentOffset = base.contentOffset
        switch edge {
        case .top:
            contentOffset.y = -base.adjustedContentInset.top
        case .left:
            contentOffset.x = -base.adjustedContentInset.left
        case .bottom:
            contentOffset.y = base.contentSize.height - base.bounds.size.height + base.adjustedContentInset.bottom
        case .right:
            contentOffset.x = base.contentSize.width - base.bounds.size.width + base.adjustedContentInset.right
        default:
            break
        }
        return contentOffset
    }

    /// 总页数，自动识别翻页方向
    public var totalPage: Int {
        if canScrollVertical {
            return Int(ceil(base.contentSize.height / base.frame.size.height))
        } else {
            return Int(ceil(base.contentSize.width / base.frame.size.width))
        }
    }

    /// 当前页数，不支持动画，自动识别翻页方向
    public var currentPage: Int {
        get {
            if canScrollVertical {
                let pageHeight = base.frame.size.height
                return Int(floor((base.contentOffset.y - pageHeight / 2) / pageHeight)) + 1
            } else {
                let pageWidth = base.frame.size.width
                return Int(floor((base.contentOffset.x - pageWidth / 2) / pageWidth)) + 1
            }
        }
        set {
            if canScrollVertical {
                let offset = base.frame.size.height * CGFloat(newValue)
                base.contentOffset = CGPoint(x: 0, y: offset)
            } else {
                let offset = base.frame.size.width * CGFloat(newValue)
                base.contentOffset = CGPoint(x: offset, y: 0)
            }
        }
    }

    /// 设置当前页数，支持动画，自动识别翻页方向
    public func setCurrentPage(_ page: Int, animated: Bool = true) {
        if canScrollVertical {
            let offset = base.frame.size.height * CGFloat(page)
            base.setContentOffset(CGPoint(x: 0, y: offset), animated: animated)
        } else {
            let offset = base.frame.size.width * CGFloat(page)
            base.setContentOffset(CGPoint(x: offset, y: 0), animated: animated)
        }
    }

    /// 是否是最后一页，自动识别翻页方向
    public var isLastPage: Bool {
        return currentPage == totalPage - 1
    }
    
    /// 快捷设置contentOffset.x
    public var contentOffsetX: CGFloat {
        get { return base.contentOffset.x }
        set { base.contentOffset = CGPoint(x: newValue, y: base.contentOffset.y) }
    }

    /// 快捷设置contentOffset.y
    public var contentOffsetY: CGFloat {
        get { return base.contentOffset.y }
        set { base.contentOffset = CGPoint(x: base.contentOffset.x, y: newValue) }
    }
    
    /// 滚动视图完整图片截图
    public var contentSnapshot: UIImage? {
        let size = base.contentSize
        guard size != .zero else { return nil }

        let strongBase = base
        return UIGraphicsImageRenderer(size: size).image { context in
            let previousFrame = strongBase.frame
            strongBase.frame = CGRect(origin: strongBase.frame.origin, size: size)
            strongBase.layer.render(in: context.cgContext)
            strongBase.frame = previousFrame
        }
    }
    
    /// 内容视图，子视图需添加到本视图，布局约束完整时可自动滚动
    ///
    /// 当启用等比例缩放布局、且scrollView和contentView都固定高度时，
    /// 为防止浮点数误差导致scrollView拖拽时出现纵向可滚动的兼容问题，解决方案如下：
    /// 1. 设置scrollView属性isDirectionalLockEnabled为true
    /// 2. 设置布局高度为固定ceil高度，如：FW.fixed(ceil(FW.relative(40)))
    public var contentView: UIView {
        if let contentView = property(forName: "contentView") as? UIView {
            return contentView
        } else {
            let contentView = UIView()
            setProperty(contentView, forName: "contentView")
            base.addSubview(contentView)
            contentView.fw.pinEdges(autoScale: false)
            return contentView
        }
    }
    
    /**
     设置自动布局视图悬停到指定父视图固定位置，在scrollViewDidScroll:中调用即可
     
     @param view 需要悬停的视图，须占满fromSuperview
     @param fromSuperview 起始的父视图，须是scrollView的子视图
     @param toSuperview 悬停的目标视图，须是scrollView的父级视图，一般控制器view
     @param toPosition 需要悬停的目标位置，相对于toSuperview的originY位置
     @return 相对于悬浮位置的距离，可用来设置导航栏透明度等
     */
    @discardableResult
    public func hoverView(_ view: UIView, fromSuperview: UIView, toSuperview: UIView, toPosition: CGFloat) -> CGFloat {
        let distance = (fromSuperview.superview?.convert(fromSuperview.frame.origin, to: toSuperview) ?? .zero).y - toPosition
        if distance <= 0 {
            if view.superview != toSuperview {
                view.removeFromSuperview()
                toSuperview.addSubview(view)
                view.fw.pinEdge(toSuperview: .left, inset: 0, autoScale: false)
                view.fw.pinEdge(toSuperview: .top, inset: toPosition, autoScale: false)
                view.fw.setDimensions(view.bounds.size, autoScale: false)
            }
        } else {
            if view.superview != fromSuperview {
                view.removeFromSuperview()
                fromSuperview.addSubview(view)
                view.fw.pinEdges(autoScale: false)
            }
        }
        return distance
    }
    
    /// 是否开始识别pan手势
    public var shouldBegin: ((UIGestureRecognizer) -> Bool)? {
        get {
            return property(forName: "shouldBegin") as? (UIGestureRecognizer) -> Bool
        }
        set {
            setPropertyCopy(newValue, forName: "shouldBegin")
            FrameworkAutoloader.swizzleUIKitScrollView()
        }
    }

    /// 是否允许同时识别多个手势
    public var shouldRecognizeSimultaneously: ((UIGestureRecognizer, UIGestureRecognizer) -> Bool)? {
        get {
            return property(forName: "shouldRecognizeSimultaneously") as? (UIGestureRecognizer, UIGestureRecognizer) -> Bool
        }
        set {
            setPropertyCopy(newValue, forName: "shouldRecognizeSimultaneously")
            FrameworkAutoloader.swizzleUIKitScrollView()
        }
    }

    /// 是否另一个手势识别失败后，才能识别pan手势
    public var shouldRequireFailure: ((UIGestureRecognizer, UIGestureRecognizer) -> Bool)? {
        get {
            return property(forName: "shouldRequireFailure") as? (UIGestureRecognizer, UIGestureRecognizer) -> Bool
        }
        set {
            setPropertyCopy(newValue, forName: "shouldRequireFailure")
            FrameworkAutoloader.swizzleUIKitScrollView()
        }
    }

    /// 是否pan手势识别失败后，才能识别另一个手势
    public var shouldBeRequiredToFail: ((UIGestureRecognizer, UIGestureRecognizer) -> Bool)? {
        get {
            return property(forName: "shouldBeRequiredToFail") as? (UIGestureRecognizer, UIGestureRecognizer) -> Bool
        }
        set {
            setPropertyCopy(newValue, forName: "shouldBeRequiredToFail")
            FrameworkAutoloader.swizzleUIKitScrollView()
        }
    }
}

// MARK: - Wrapper+UIGestureRecognizer
/// gestureRecognizerShouldBegin：是否继续进行手势识别，默认YES
/// shouldRecognizeSimultaneouslyWithGestureRecognizer: 是否支持多手势触发。默认NO
/// shouldRequireFailureOfGestureRecognizer：是否otherGestureRecognizer触发失败时，才开始触发gestureRecognizer。返回YES，第一个手势失败
/// shouldBeRequiredToFailByGestureRecognizer：在otherGestureRecognizer识别其手势之前，是否gestureRecognizer必须触发失败。返回YES，第二个手势失败
extension Wrapper where Base: UIGestureRecognizer {
    /// 获取手势直接作用的view，不同于view，此处是view的subview
    public weak var targetView: UIView? {
        return base.view?.hitTest(base.location(in: base.view), with: nil)
    }

    /// 是否正在拖动中：Began || Changed
    public var isTracking: Bool {
        return base.state == .began || base.state == .changed
    }

    /// 是否是激活状态: isEnabled && (Began || Changed)
    public var isActive: Bool {
        return base.isEnabled && (base.state == .began || base.state == .changed)
    }
    
    /// 判断手势是否正作用于指定视图
    public func hitTest(view: UIView?) -> Bool {
        return base.view?.hitTest(base.location(in: base.view), with: nil) != nil
    }
}

// MARK: - Wrapper+UIPanGestureRecognizer
extension Wrapper where Base: UIPanGestureRecognizer {
    /// 当前滑动方向，如果多个方向滑动，取绝对值较大的一方，失败返回0
    public var swipeDirection: UISwipeGestureRecognizer.Direction {
        let transition = base.translation(in: base.view)
        if abs(transition.x) > abs(transition.y) {
            if transition.x < 0 {
                return .left
            } else if transition.x > 0 {
                return .right
            }
        } else {
            if transition.y > 0 {
                return .down
            } else if transition.y < 0 {
                return .up
            }
        }
        return []
    }

    /// 当前滑动进度，滑动绝对值相对于手势视图的宽或高
    public var swipePercent: CGFloat {
        guard let view = base.view,
              view.bounds.width > 0, view.bounds.height > 0 else { return 0 }
        var percent: CGFloat = 0
        let transition = base.translation(in: view)
        if abs(transition.x) > abs(transition.y) {
            percent = abs(transition.x) / view.bounds.width
        } else {
            percent = abs(transition.y) / view.bounds.height
        }
        return max(0, min(percent, 1))
    }

    /// 计算指定方向的滑动进度
    public func swipePercent(of direction: UISwipeGestureRecognizer.Direction) -> CGFloat {
        guard let view = base.view,
              view.bounds.width > 0, view.bounds.height > 0 else { return 0 }
        var percent: CGFloat = 0
        let transition = base.translation(in: view)
        switch direction {
        case .left:
            percent = -transition.x / view.bounds.width
        case .right:
            percent = transition.x / view.bounds.width
        case .up:
            percent = -transition.y / view.bounds.height
        case .down:
            percent = transition.y / view.bounds.height
        default:
            percent = transition.y / view.bounds.height
        }
        return max(0, min(percent, 1))
    }
}

// MARK: - Wrapper+UIPageControl
extension Wrapper where Base: UIPageControl {
    /// 自定义圆点大小，默认{10, 10}
    public var preferredSize: CGSize {
        get {
            var size = base.bounds.size
            if size.height <= 0 {
                size = base.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
                if size.height <= 0 { size = CGSize(width: 10, height: 10) }
            }
            return size
        }
        set {
            let height = preferredSize.height
            let scale = newValue.height / height
            base.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }
}

// MARK: - Wrapper+UISlider
extension Wrapper where Base: UISlider {
    /// 中间圆球的大小，默认zero
    public var thumbSize: CGSize {
        get {
            if let value = property(forName: "thumbSize") as? NSValue {
                return value.cgSizeValue
            }
            return .zero
        }
        set {
            setProperty(NSValue(cgSize: newValue), forName: "thumbSize")
            updateThumbImage()
        }
    }

    /// 中间圆球的颜色，默认nil
    public var thumbColor: UIColor? {
        get {
            return property(forName: "thumbColor") as? UIColor
        }
        set {
            setProperty(newValue, forName: "thumbColor")
            updateThumbImage()
        }
    }
    
    private func updateThumbImage() {
        let thumbSize = thumbSize
        guard thumbSize.width > 0, thumbSize.height > 0 else { return }
        let thumbColor = thumbColor ?? (base.tintColor ?? .white)
        let thumbImage = UIImage.fw.image(size: thumbSize) { context in
            let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: thumbSize.width, height: thumbSize.height))
            context.setFillColor(thumbColor.cgColor)
            path.fill()
        }
        
        base.setThumbImage(thumbImage, for: .normal)
        base.setThumbImage(thumbImage, for: .highlighted)
    }
}

// MARK: - Wrapper+UISwitch
extension Wrapper where Base: UISwitch {
    /// 自定义尺寸大小，默认{51,31}
    public var preferredSize: CGSize {
        get {
            var size = base.bounds.size
            if size.height <= 0 {
                size = base.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
                if size.height <= 0 { size = CGSize(width: 51, height: 31) }
            }
            return size
        }
        set {
            let height = preferredSize.height
            let scale = newValue.height / height
            base.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }
    
    /// 自定义关闭时除圆点外的背景色
    public var offTintColor: UIColor? {
        get { return base.innerOffTintColor }
        set { base.innerOffTintColor = newValue }
    }
}

// MARK: - Wrapper+UITextField
extension Wrapper where Base: UITextField {
    /// 最大字数限制，0为无限制，二选一
    public var maxLength: Int {
        get { return inputTarget(false)?.maxLength ?? 0 }
        set { inputTarget(true)?.maxLength = newValue }
    }

    /// 最大Unicode字数限制(中文为1，英文为0.5)，0为无限制，二选一
    public var maxUnicodeLength: Int {
        get { return inputTarget(false)?.maxUnicodeLength ?? 0 }
        set { inputTarget(true)?.maxUnicodeLength = newValue }
    }
    
    /// 自定义文字改变处理句柄，自动trimString，默认nil
    public var textChangedBlock: ((String) -> Void)? {
        get { return inputTarget(false)?.textChangedBlock }
        set { inputTarget(true)?.textChangedBlock = newValue }
    }

    /// 文本长度发生改变，自动检测字数限制，用于代码设置text等场景
    public func textLengthChanged() {
        inputTarget(false)?.textLengthChanged()
    }

    /// 获取满足最大字数限制的过滤后的文本，无需再调用textLengthChanged
    public func filterText(_ text: String) -> String {
        if let target = inputTarget(false) {
            return target.filterText(text)
        }
        return text
    }

    /// 设置自动完成时间间隔，默认0.5秒，和autoCompleteBlock配套使用
    public var autoCompleteInterval: TimeInterval {
        get { return inputTarget(false)?.autoCompleteInterval ?? 0 }
        set { inputTarget(true)?.autoCompleteInterval = newValue > 0 ? newValue : 0.5 }
    }

    /// 设置自动完成处理句柄，自动trimString，默认nil，注意输入框内容为空时会立即触发
    public var autoCompleteBlock: ((String) -> Void)? {
        get { return inputTarget(false)?.autoCompleteBlock }
        set { inputTarget(true)?.autoCompleteBlock = newValue }
    }
    
    private func inputTarget(_ lazyload: Bool) -> InputTarget? {
        if let target = property(forName: "inputTarget") as? InputTarget {
            return target
        } else if lazyload {
            let target = InputTarget(textInput: base)
            base.addTarget(target, action: #selector(InputTarget.textChangedAction), for: .editingChanged)
            setProperty(target, forName: "inputTarget")
            return target
        }
        return nil
    }
    
    /// 是否禁用长按菜单(拷贝、选择、粘贴等)，默认NO
    public var menuDisabled: Bool {
        get { propertyBool(forName: "menuDisabled") }
        set { setPropertyBool(newValue, forName: "menuDisabled") }
    }

    /// 自定义光标偏移和大小，不为0才会生效，默认zero不生效
    public var cursorRect: CGRect {
        get {
            if let value = property(forName: "cursorRect") as? NSValue {
                return value.cgRectValue
            }
            return .zero
        }
        set {
            setProperty(NSValue(cgRect: newValue), forName: "cursorRect")
        }
    }

    /// 获取及设置当前选中文字范围
    public var selectedRange: NSRange {
        get {
            guard let selectedRange = base.selectedTextRange else {
                return NSRange(location: NSNotFound, length: 0)
            }
            let location = base.offset(from: base.beginningOfDocument, to: selectedRange.start)
            let length = base.offset(from: selectedRange.start, to: selectedRange.end)
            return NSRange(location: location, length: length)
        }
        set {
            guard newValue.location != NSNotFound else {
                base.selectedTextRange = nil
                return
            }
            let start = base.position(from: base.beginningOfDocument, offset: newValue.location)
            let end = base.position(from: base.beginningOfDocument, offset: NSMaxRange(newValue))
            if let start = start, let end = end {
                let selectionRange = base.textRange(from: start, to: end)
                base.selectedTextRange = selectionRange
            }
        }
    }

    /// 移动光标到最后
    public func selectAllRange() {
        let range = base.textRange(from: base.beginningOfDocument, to: base.endOfDocument)
        base.selectedTextRange = range
    }

    /// 移动光标到指定位置，兼容动态text赋值
    public func moveCursor(_ offset: Int) {
        DispatchQueue.main.async { [weak base] in
            guard let base = base else { return }
            if let position = base.position(from: base.beginningOfDocument, offset: offset) {
                base.selectedTextRange = base.textRange(from: position, to: position)
            }
        }
    }
}

// MARK: - Wrapper+UITextView
extension Wrapper where Base: UITextView {
    /// 最大字数限制，0为无限制，二选一
    public var maxLength: Int {
        get { return inputTarget(false)?.maxLength ?? 0 }
        set { inputTarget(true)?.maxLength = newValue }
    }

    /// 最大Unicode字数限制(中文为1，英文为0.5)，0为无限制，二选一
    public var maxUnicodeLength: Int {
        get { return inputTarget(false)?.maxUnicodeLength ?? 0 }
        set { inputTarget(true)?.maxUnicodeLength = newValue }
    }
    
    /// 自定义文字改变处理句柄，自动trimString，默认nil
    public var textChangedBlock: ((String) -> Void)? {
        get { return inputTarget(false)?.textChangedBlock }
        set { inputTarget(true)?.textChangedBlock = newValue }
    }

    /// 文本长度发生改变，自动检测字数限制，用于代码设置text等场景
    public func textLengthChanged() {
        inputTarget(false)?.textLengthChanged()
    }

    /// 获取满足最大字数限制的过滤后的文本，无需再调用textLengthChanged
    public func filterText(_ text: String) -> String {
        if let target = inputTarget(false) {
            return target.filterText(text)
        }
        return text
    }

    /// 设置自动完成时间间隔，默认0.5秒，和autoCompleteBlock配套使用
    public var autoCompleteInterval: TimeInterval {
        get { return inputTarget(false)?.autoCompleteInterval ?? 0 }
        set { inputTarget(true)?.autoCompleteInterval = newValue > 0 ? newValue : 0.5 }
    }

    /// 设置自动完成处理句柄，默认nil，注意输入框内容为空时会立即触发
    public var autoCompleteBlock: ((String) -> Void)? {
        get { return inputTarget(false)?.autoCompleteBlock }
        set { inputTarget(true)?.autoCompleteBlock = newValue }
    }
    
    private func inputTarget(_ lazyload: Bool) -> InputTarget? {
        if let target = property(forName: "inputTarget") as? InputTarget {
            return target
        } else if lazyload {
            let target = InputTarget(textInput: base)
            observeNotification(UITextView.textDidChangeNotification, object: base, target: target, action: #selector(InputTarget.textChangedAction))
            setProperty(target, forName: "inputTarget")
            return target
        }
        return nil
    }
    
    /// 是否禁用长按菜单(拷贝、选择、粘贴等)，默认NO
    public var menuDisabled: Bool {
        get { propertyBool(forName: "menuDisabled") }
        set { setPropertyBool(newValue, forName: "menuDisabled") }
    }

    /// 自定义光标偏移和大小，不为0才会生效，默认zero不生效
    public var cursorRect: CGRect {
        get {
            if let value = property(forName: "cursorRect") as? NSValue {
                return value.cgRectValue
            }
            return .zero
        }
        set {
            setProperty(NSValue(cgRect: newValue), forName: "cursorRect")
        }
    }

    /// 获取及设置当前选中文字范围
    public var selectedRange: NSRange {
        get {
            guard let selectedRange = base.selectedTextRange else {
                return NSRange(location: NSNotFound, length: 0)
            }
            let location = base.offset(from: base.beginningOfDocument, to: selectedRange.start)
            let length = base.offset(from: selectedRange.start, to: selectedRange.end)
            return NSRange(location: location, length: length)
        }
        set {
            guard newValue.location != NSNotFound else {
                base.selectedTextRange = nil
                return
            }
            let start = base.position(from: base.beginningOfDocument, offset: newValue.location)
            let end = base.position(from: base.beginningOfDocument, offset: NSMaxRange(newValue))
            if let start = start, let end = end {
                let selectionRange = base.textRange(from: start, to: end)
                base.selectedTextRange = selectionRange
            }
        }
    }

    /// 移动光标到最后
    public func selectAllRange() {
        let range = base.textRange(from: base.beginningOfDocument, to: base.endOfDocument)
        base.selectedTextRange = range
    }

    /// 移动光标到指定位置，兼容动态text赋值
    public func moveCursor(_ offset: Int) {
        DispatchQueue.main.async { [weak base] in
            guard let base = base else { return }
            if let position = base.position(from: base.beginningOfDocument, offset: offset) {
                base.selectedTextRange = base.textRange(from: position, to: position)
            }
        }
    }

    /// 计算当前文本所占尺寸，包含textContainerInset，需frame或者宽度布局完整
    public var textSize: CGSize {
        if base.frame.size.equalTo(.zero) {
            base.setNeedsLayout()
            base.layoutIfNeeded()
        }
        
        let drawSize = CGSize(width: base.frame.size.width, height: .greatestFiniteMagnitude)
        return textSize(drawSize: drawSize)
    }
    
    /// 计算指定边界时，当前文本所占尺寸，包含textContainerInset
    public func textSize(drawSize: CGSize, contentInset: UIEdgeInsets? = nil) -> CGSize {
        var attrs: [NSAttributedString.Key: Any] = [:]
        attrs[.font] = base.font
        
        let inset = contentInset ?? base.textContainerInset
        let size = (base.text as? NSString)?.boundingRect(with: CGSize(width: drawSize.width - inset.left - inset.right, height: drawSize.height - inset.top - inset.bottom), options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: attrs, context: nil).size ?? .zero
        return CGSize(width: min(drawSize.width, ceil(size.width)) + inset.left + inset.right, height: min(drawSize.height, ceil(size.height)) + inset.top + inset.bottom)
    }

    /// 计算当前属性文本所占尺寸，包含textContainerInset，需frame或者宽度布局完整，attributedText需指定字体
    public var attributedTextSize: CGSize {
        if base.frame.size.equalTo(.zero) {
            base.setNeedsLayout()
            base.layoutIfNeeded()
        }
        
        let drawSize = CGSize(width: base.frame.size.width, height: .greatestFiniteMagnitude)
        return attributedTextSize(drawSize: drawSize)
    }

    /// 计算指定边界时，当前属性文本所占尺寸，包含textContainerInset，attributedText需指定字体
    public func attributedTextSize(drawSize: CGSize, contentInset: UIEdgeInsets? = nil) -> CGSize {
        let inset = contentInset ?? base.textContainerInset
        let size = base.attributedText?.boundingRect(with: CGSize(width: drawSize.width - inset.left - inset.right, height: drawSize.height - inset.top - inset.bottom), options: [.usesFontLeading, .usesLineFragmentOrigin], context: nil).size ?? .zero
        return CGSize(width: min(drawSize.width, ceil(size.width)) + inset.left + inset.right, height: min(drawSize.height, ceil(size.height)) + inset.top + inset.bottom)
    }
    
    /// 添加点击手势并自动识别NSLinkAttributeName|URL属性，点击高亮时回调链接，点击其它区域回调nil
    @discardableResult
    public func addLinkGesture(block: @escaping (Any?) -> Void) -> UITapGestureRecognizer {
        return addTapGesture { gesture in
            guard let textView = gesture.view as? UITextView else { return }
            let attributes = textView.fw.attributes(gesture: gesture, allowsSpacing: false)
            let link = attributes[.link] ?? attributes[NSAttributedString.Key("URL")]
            block(link)
        }
    }
    
    /// 获取手势触发位置的文本属性，可实现行内点击效果等，allowsSpacing默认为NO空白处不可点击
    public func attributes(
        gesture: UIGestureRecognizer,
        allowsSpacing: Bool
    ) -> [NSAttributedString.Key: Any] {
        guard let attributedString = base.attributedText else { return [:] }
        var location = gesture.location(in: base)
        location = CGPoint(x: location.x - base.textContainerInset.left, y: location.y - base.textContainerInset.top)
        var distance: CGFloat = 0
        let index = base.layoutManager.characterIndex(for: location, in: base.textContainer, fractionOfDistanceBetweenInsertionPoints: &distance)
        if !allowsSpacing && distance >= 1 { return [:] }
        return attributedString.attributes(at: index, effectiveRange: nil)
    }
    
    /// 快捷设置行高，兼容placeholder和typingAttributes。小于等于0时恢复默认行高
    public var lineHeight: CGFloat {
        get {
            if property(forName: "lineHeight") != nil {
                return propertyDouble(forName: "lineHeight")
            }
            
            var result: CGFloat = 0
            if let string = base.attributedText?.mutableCopy() as? NSMutableAttributedString {
                string.enumerateAttribute(.paragraphStyle, in: NSMakeRange(0, string.length), using: { obj, range, stop in
                    guard let style = obj as? NSParagraphStyle else { return }
                    if NSEqualRanges(range, NSMakeRange(0, string.length)) {
                        if style.maximumLineHeight != 0 || style.minimumLineHeight != 0 {
                            result = style.maximumLineHeight
                            stop.pointee = true
                        }
                    }
                })
            }
            
            if result <= 0, let style = base.typingAttributes[.paragraphStyle] as? NSParagraphStyle {
                if style.maximumLineHeight != 0 || style.minimumLineHeight != 0 {
                    result = style.maximumLineHeight
                }
            }
            return result > 0 ? result : (base.font?.lineHeight ?? 0)
        }
        set {
            if newValue > 0 {
                setPropertyDouble(newValue, forName: "lineHeight")
            } else {
                setProperty(nil, forName: "lineHeight")
            }
            
            placeholderLineHeight = newValue
            
            var typingAttributes = base.typingAttributes
            var paragraphStyle: NSMutableParagraphStyle
            if let style = typingAttributes[.paragraphStyle] as? NSMutableParagraphStyle {
                paragraphStyle = style
            } else if let style = (typingAttributes[.paragraphStyle] as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle {
                paragraphStyle = style
            } else {
                paragraphStyle = NSMutableParagraphStyle()
            }
            paragraphStyle.minimumLineHeight = newValue > 0 ? newValue : 0
            paragraphStyle.maximumLineHeight = newValue > 0 ? newValue : 0
            
            typingAttributes[.paragraphStyle] = paragraphStyle
            base.typingAttributes = typingAttributes
        }
    }
    
    /// 获取当前文本框是否非空，兼容attributedText|text
    public var isNotEmpty: Bool {
        if (base.attributedText?.length ?? 0) > 0 { return true }
        if (base.text?.count ?? 0) > 0 { return true }
        return false
    }
    
    /// 计算当前文本框实际显示行数，兼容textContainerInset|lineHeight
    public var actualNumberOfLines: Int {
        if base.frame.size.equalTo(.zero) {
            base.setNeedsLayout()
            base.layoutIfNeeded()
        }
        
        let drawSize = CGSize(width: base.frame.size.width, height: .greatestFiniteMagnitude)
        return actualNumberOfLines(drawSize: drawSize)
    }
    
    /// 计算指定边界、内边距、行高时，当前文本框实际显示行数
    public func actualNumberOfLines(
        drawSize: CGSize,
        contentInset: UIEdgeInsets? = nil,
        lineHeight aLineHeight: CGFloat? = nil
    ) -> Int {
        guard isNotEmpty else { return 0 }
        
        let inset = contentInset ?? base.textContainerInset
        let aLineHeight = aLineHeight ?? lineHeight
        guard aLineHeight > 0 else { return 0 }
        
        let height = base.sizeThatFits(drawSize).height - inset.top - inset.bottom
        let lines = Int(round(height / aLineHeight))
        return lines
    }
}

// MARK: - Wrapper+UITableView
/// 启用高度估算：设置rowHeight为automaticDimension并撑开布局即可，再设置estimatedRowHeight可提升性能
extension Wrapper where Base: UITableView {
    /// 全局清空TableView默认多余边距
    public static func resetTableStyle() {
        if #available(iOS 15.0, *) {
            UITableView.appearance().sectionHeaderTopPadding = 0
        }
    }
    
    /// 是否启动高度估算布局，启用后需要子视图布局完整，无需实现heightForRow方法(iOS11默认启用，会先cellForRow再heightForRow)
    public var estimatedLayout: Bool {
        get {
            return base.estimatedRowHeight == UITableView.automaticDimension
        }
        set {
            if newValue {
                base.estimatedRowHeight = UITableView.automaticDimension
                base.estimatedSectionHeaderHeight = UITableView.automaticDimension
                base.estimatedSectionFooterHeight = UITableView.automaticDimension
            } else {
                base.estimatedRowHeight = 0
                base.estimatedSectionHeaderHeight = 0
                base.estimatedSectionFooterHeight = 0
            }
        }
    }
    
    /// 清除Grouped等样式默认多余边距，注意CGFLOAT_MIN才会生效，0不会生效
    public func resetTableStyle() {
        base.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNonzeroMagnitude))
        base.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNonzeroMagnitude))
        if #available(iOS 15.0, *) {
            base.sectionHeaderTopPadding = 0
        }
        
        UITableView.fw.resetTableConfiguration?(base)
    }
    
    /// 配置全局resetTableStyle钩子句柄，默认nil
    public static var resetTableConfiguration: ((UITableView) -> Void)? {
        get { UITableView.innerResetTableConfiguration }
        set { UITableView.innerResetTableConfiguration = newValue }
    }
    
    /// reloadData完成回调
    public func reloadData(completion: (() -> Void)?) {
        let strongBase = base
        UIView.animate(withDuration: 0) {
            strongBase.reloadData()
            strongBase.layoutIfNeeded()
        } completion: { _ in
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    /// reloadData禁用动画
    public func reloadDataWithoutAnimation() {
        let strongBase = base
        UIView.performWithoutAnimation {
            strongBase.reloadData()
        }
    }
    
    /// 动态计算tableView内容总高度(不含contentInset，使用dataSource和delegate，必须实现heightForRow等方法)，即使tableView未reloadData也会返回新高度
    @MainActor public func totalContentHeight() -> CGFloat {
        var totalHeight: CGFloat = 0
        if let headerView = base.tableHeaderView {
            totalHeight += headerView.frame.height
        }
        if let footerView = base.tableFooterView {
            totalHeight += footerView.frame.height
        }
        
        var sections: Int = 1
        if let sectionCount = base.dataSource?.numberOfSections?(in: base) {
            sections = sectionCount
        }
        for section in 0 ..< sections {
            if let headerHeight = base.delegate?.tableView?(base, heightForHeaderInSection: section),
               headerHeight != UITableView.automaticDimension {
                totalHeight += headerHeight
            } else {
                totalHeight += base.rectForHeader(inSection: section).height
            }
            if let footerHeight = base.delegate?.tableView?(base, heightForFooterInSection: section),
               footerHeight != UITableView.automaticDimension {
                totalHeight += footerHeight
            } else {
                totalHeight += base.rectForFooter(inSection: section).height
            }
            
            if let rows = base.dataSource?.tableView(base, numberOfRowsInSection: section) {
                for row in 0 ..< rows {
                    if let rowHeight = base.delegate?.tableView?(base, heightForRowAt: IndexPath(row: row, section: section)),
                       rowHeight != UITableView.automaticDimension {
                        totalHeight += rowHeight
                    } else {
                        totalHeight += base.rectForRow(at: IndexPath(row: row, section: section)).height
                    }
                }
            }
        }
        return ceil(totalHeight)
    }
    
    /// 获取指定section的header视图frame，失败时为zero
    public func layoutHeaderFrame(for section: Int) -> CGRect {
        guard section >= 0, section < base.numberOfSections else { return .zero }
        return base.rectForHeader(inSection: section)
    }
    
    /// 获取指定section的footer视图frame，失败时为zero
    public func layoutFooterFrame(for section: Int) -> CGRect {
        guard section >= 0, section < base.numberOfSections else { return .zero }
        return base.rectForFooter(inSection: section)
    }
    
    /// 获取指定indexPath的cell视图frame，失败时为zero
    public func layoutCellFrame(for indexPath: IndexPath) -> CGRect {
        guard isValidIndexPath(indexPath) else { return .zero }
        return base.rectForRow(at: indexPath)
    }
    
    /// 判断indexPath是否有效
    public func isValidIndexPath(_ indexPath: IndexPath) -> Bool {
        guard indexPath.section >= 0, indexPath.row >= 0 else { return false }
        guard indexPath.section < base.numberOfSections else { return false }
        return indexPath.row < base.numberOfRows(inSection: indexPath.section)
    }
    
    /// 简单曝光方案，willDisplay调用即可，表格快速滑动、数据不变等情况不计曝光。如需完整曝光方案，请使用StatisticalView
    public func willDisplay(_ cell: UITableViewCell, at indexPath: IndexPath, key: AnyHashable? = nil, exposure: @escaping () -> Void) {
        let identifier = "\(indexPath.section).\(indexPath.row)-\(String.fw.safeString(key))"
        let block: (UITableViewCell) -> Void = { [weak base] cell in
            let previousIdentifier = cell.fw.property(forName: "willDisplayIdentifier") as? String
            guard base?.visibleCells.contains(cell) ?? false,
                  base?.indexPath(for: cell) != nil,
                  identifier != previousIdentifier else { return }
            
            exposure()
            cell.fw.setPropertyCopy(identifier, forName: "willDisplayIdentifier")
        }
        cell.fw.setPropertyCopy(block, forName: "willDisplay")
        
        NSObject.cancelPreviousPerformRequests(withTarget: base, selector: #selector(UITableView.innerWillDisplay(_:)), object: cell)
        base.perform(#selector(UITableView.innerWillDisplay(_:)), with: cell, afterDelay: 0.2, inModes: [.default])
    }
}

// MARK: - Wrapper+UITableViewCell
extension Wrapper where Base: UITableViewCell {
    /// 设置分割线内边距，iOS8+默认15.f，设为UIEdgeInsetsZero可去掉
    public var separatorInset: UIEdgeInsets {
        get {
            return base.separatorInset
        }
        set {
            base.separatorInset = newValue
            base.preservesSuperviewLayoutMargins = false
            base.layoutMargins = separatorInset
        }
    }
    
    /// 调整imageView的位置偏移，默认zero不生效，仅支持default|subtitle样式
    public var imageEdgeInsets: UIEdgeInsets {
        get {
            let value = property(forName: "imageEdgeInsets") as? NSValue
            return value?.uiEdgeInsetsValue ?? .zero
        }
        set {
            setProperty(NSValue(uiEdgeInsets: newValue), forName: "imageEdgeInsets")
            FrameworkAutoloader.swizzleUIKitTableViewCell()
        }
    }
    
    /// 调整textLabel的位置偏移，默认zero不生效，仅支持default|subtitle样式
    public var textEdgeInsets: UIEdgeInsets {
        get {
            let value = property(forName: "textEdgeInsets") as? NSValue
            return value?.uiEdgeInsetsValue ?? .zero
        }
        set {
            setProperty(NSValue(uiEdgeInsets: newValue), forName: "textEdgeInsets")
            FrameworkAutoloader.swizzleUIKitTableViewCell()
        }
    }
    
    /// 调整detailTextLabel的位置偏移，默认zero不生效，仅支持subtitle样式
    public var detailTextEdgeInsets: UIEdgeInsets {
        get {
            let value = property(forName: "detailTextEdgeInsets") as? NSValue
            return value?.uiEdgeInsetsValue ?? .zero
        }
        set {
            setProperty(NSValue(uiEdgeInsets: newValue), forName: "detailTextEdgeInsets")
            FrameworkAutoloader.swizzleUIKitTableViewCell()
        }
    }
    
    /// 调整accessoryView的位置偏移，默认zero不生效，仅对自定义accessoryView生效
    public var accessoryEdgeInsets: UIEdgeInsets {
        get {
            let value = property(forName: "accessoryEdgeInsets") as? NSValue
            return value?.uiEdgeInsetsValue ?? .zero
        }
        set {
            setProperty(NSValue(uiEdgeInsets: newValue), forName: "accessoryEdgeInsets")
            FrameworkAutoloader.swizzleUIKitTableViewCell()
        }
    }

    /// 获取当前所属tableView
    public weak var tableView: UITableView? {
        var superview = base.superview
        while superview != nil {
            if let tableView = superview as? UITableView {
                return tableView
            }
            superview = superview?.superview
        }
        return nil
    }

    /// 获取当前显示indexPath
    public var indexPath: IndexPath? {
        return tableView?.indexPath(for: base)
    }
    
    /// 执行所属tableView的批量更新
    public func performBatchUpdates(
        _ updates: ((UITableView, IndexPath?) -> Void)?,
        completion: ((UITableView, IndexPath?, Bool) -> Void)? = nil
    ) {
        guard let tableView = tableView else { return }
        
        tableView.performBatchUpdates(updates != nil ? { [weak base] in
            let indexPath = base != nil ? tableView.indexPath(for: base!) : nil
            updates?(tableView, indexPath)
        } : nil, completion: completion != nil ? { [weak base] finished in
            let indexPath = base != nil ? tableView.indexPath(for: base!) : nil
            completion?(tableView, indexPath, finished)
        } : nil)
    }
}

// MARK: - Wrapper+UICollectionView
extension Wrapper where Base: UICollectionView {
    /// reloadData完成回调
    public func reloadData(completion: (() -> Void)?) {
        let strongBase = base
        UIView.animate(withDuration: 0) {
            strongBase.reloadData()
            strongBase.layoutIfNeeded()
        } completion: { _ in
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    /// reloadData禁用动画
    public func reloadDataWithoutAnimation() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        base.reloadData()
        CATransaction.commit()
    }
    
    /// 获取指定indexPath的header视图frame，失败时为zero
    public func layoutHeaderFrame(for indexPath: IndexPath) -> CGRect {
        guard indexPath.section >= 0, indexPath.section < base.numberOfSections else { return .zero }
        return base.layoutAttributesForSupplementaryElement(ofKind: UICollectionView.elementKindSectionHeader, at: indexPath)?.frame ?? .zero
    }
    
    /// 获取指定indexPath的footer视图frame，失败时为zero
    public func layoutFooterFrame(for indexPath: IndexPath) -> CGRect {
        guard indexPath.section >= 0, indexPath.section < base.numberOfSections else { return .zero }
        return base.layoutAttributesForSupplementaryElement(ofKind: UICollectionView.elementKindSectionFooter, at: indexPath)?.frame ?? .zero
    }
    
    /// 获取指定indexPath的cell视图frame，失败时为zero
    public func layoutCellFrame(for indexPath: IndexPath) -> CGRect {
        guard isValidIndexPath(indexPath) else { return .zero }
        return base.layoutAttributesForItem(at: indexPath)?.frame ?? .zero
    }
    
    /// 判断indexPath是否有效
    public func isValidIndexPath(_ indexPath: IndexPath) -> Bool {
        guard indexPath.section >= 0, indexPath.item >= 0 else { return false }
        guard indexPath.section < base.numberOfSections else { return false }
        return indexPath.item < base.numberOfItems(inSection: indexPath.section)
    }
    
    /// 计算指定indexPath的frame，并转换为指定视图坐标(nil时默认window)
    public func layoutFrame(at indexPath: IndexPath, to view: UIView?) -> CGRect? {
        guard var layoutFrame = base.layoutAttributesForItem(at: indexPath)?.frame else {
            return nil
        }
        
        layoutFrame = base.convert(layoutFrame, to: view)
        return layoutFrame
    }
    
    /// 添加拖动排序手势，需结合canMove、moveItem、targetIndexPath使用
    @discardableResult
    public func addMovementGesture(customBlock: ((UILongPressGestureRecognizer) -> Bool)? = nil) -> UILongPressGestureRecognizer {
        movementGestureBlock = customBlock
        
        let movementGesture = UILongPressGestureRecognizer(target: base, action: #selector(UICollectionView.innerMovementGestureAction(_:)))
        base.addGestureRecognizer(movementGesture)
        return movementGesture
    }
    
    fileprivate var movementGestureBlock: ((UILongPressGestureRecognizer) -> Bool)? {
        get { return property(forName: #function) as? (UILongPressGestureRecognizer) -> Bool }
        set { setPropertyCopy(newValue, forName: #function) }
    }
    
    /// 简单曝光方案，willDisplay调用即可，集合快速滑动、数据不变等情况不计曝光。如需完整曝光方案，请使用StatisticalView
    public func willDisplay(_ cell: UICollectionViewCell, at indexPath: IndexPath, key: AnyHashable? = nil, exposure: @escaping () -> Void) {
        let identifier = "\(indexPath.section).\(indexPath.row)-\(String.fw.safeString(key))"
        let block: (UICollectionViewCell) -> Void = { [weak base] cell in
            let previousIdentifier = cell.fw.property(forName: "willDisplayIdentifier") as? String
            guard base?.visibleCells.contains(cell) ?? false,
                  base?.indexPath(for: cell) != nil,
                  identifier != previousIdentifier else { return }
            
            exposure()
            cell.fw.setPropertyCopy(identifier, forName: "willDisplayIdentifier")
        }
        cell.fw.setPropertyCopy(block, forName: "willDisplay")
        
        NSObject.cancelPreviousPerformRequests(withTarget: base, selector: #selector(UICollectionView.innerWillDisplay(_:)), object: cell)
        base.perform(#selector(UICollectionView.innerWillDisplay(_:)), with: cell, afterDelay: 0.2, inModes: [.default])
    }
}

// MARK: - Wrapper+UICollectionViewCell
extension Wrapper where Base: UICollectionViewCell {
    /// 获取当前所属collectionView
    public weak var collectionView: UICollectionView? {
        var superview = base.superview
        while superview != nil {
            if let collectionView = superview as? UICollectionView {
                return collectionView
            }
            superview = superview?.superview
        }
        return nil
    }

    /// 获取当前显示indexPath
    public var indexPath: IndexPath? {
        return collectionView?.indexPath(for: base)
    }
    
    /// 执行所属collectionView的批量更新
    public func performBatchUpdates(
        _ updates: ((UICollectionView, IndexPath?) -> Void)?,
        completion: ((UICollectionView, IndexPath?, Bool) -> Void)? = nil
    ) {
        guard let collectionView = collectionView else { return }
        
        collectionView.performBatchUpdates(updates != nil ? { [weak base] in
            let indexPath = base != nil ? collectionView.indexPath(for: base!) : nil
            updates?(collectionView, indexPath)
        } : nil, completion: completion != nil ? { [weak base] finished in
            let indexPath = base != nil ? collectionView.indexPath(for: base!) : nil
            completion?(collectionView, indexPath, finished)
        } : nil)
    }
}

// MARK: - Wrapper+UISearchBar
extension Wrapper where Base: UISearchBar {
    /// 自定义内容边距，可调整左右距离和TextField高度，未设置时为系统默认
    ///
    /// 如需设置UISearchBar为navigationItem.titleView，请使用ExpandedTitleView
    public var contentInset: UIEdgeInsets {
        get {
            if let value = property(forName: "contentInset") as? NSValue {
                return value.uiEdgeInsetsValue
            }
            return .zero
        }
        set {
            setProperty(NSValue(uiEdgeInsets: newValue), forName: "contentInset")
            base.setNeedsLayout()
        }
    }

    /// 自定义取消按钮边距，未设置时为系统默认
    public var cancelButtonInset: UIEdgeInsets {
        get {
            if let value = property(forName: "cancelButtonInset") as? NSValue {
                return value.uiEdgeInsetsValue
            }
            return .zero
        }
        set {
            setProperty(NSValue(uiEdgeInsets: newValue), forName: "cancelButtonInset")
            base.setNeedsLayout()
        }
    }

    /// 输入框内部视图
    public var textField: UISearchTextField {
        return base.searchTextField
    }

    /// 取消按钮内部视图，showsCancelButton开启后才存在
    public weak var cancelButton: UIButton? {
        return invokeGetter("cancelButton") as? UIButton
    }
    
    /// 输入框的文字颜色
    public var textColor: UIColor? {
        get {
            property(forName: #function) as? UIColor
        }
        set {
            setProperty(newValue, forName: #function)
            base.searchTextField.textColor = newValue
        }
    }
    
    /// 输入框的字体，会同时影响placeholder的字体
    public var font: UIFont? {
        get {
            property(forName: #function) as? UIFont
        }
        set {
            setProperty(newValue, forName: #function)
            if let placeholder = base.placeholder {
                base.placeholder = placeholder
            }
            base.searchTextField.font = newValue
        }
    }
    
    /// 输入框内placeholder的颜色
    public var placeholderColor: UIColor? {
        get {
            property(forName: #function) as? UIColor
        }
        set {
            setProperty(newValue, forName: #function)
            if let placeholder = base.placeholder {
                base.placeholder = placeholder
            }
        }
    }

    /// 设置整体背景色
    public var backgroundColor: UIColor? {
        get {
            return property(forName: "backgroundColor") as? UIColor
        }
        set {
            setProperty(newValue, forName: "backgroundColor")
            base.backgroundImage = UIImage.fw.image(color: newValue)
        }
    }

    /// 设置输入框背景色
    public var textFieldBackgroundColor: UIColor? {
        get { textField.backgroundColor }
        set { textField.backgroundColor = newValue }
    }

    /// 设置搜索图标离左侧的偏移位置，非居中时生效
    public var searchIconOffset: CGFloat {
        get {
            if let value = propertyNumber(forName: "searchIconOffset") {
                return value.doubleValue
            }
            return base.positionAdjustment(for: .search).horizontal
        }
        set {
            setPropertyNumber(NSNumber(value: newValue), forName: "searchIconOffset")
            base.setPositionAdjustment(UIOffset(horizontal: newValue, vertical: 0), for: .search)
        }
    }
    
    /// 设置清空图标离右侧的偏移位置
    public var clearIconOffset: CGFloat {
        get {
            if let value = propertyNumber(forName: "clearIconOffset") {
                return value.doubleValue
            }
            return base.positionAdjustment(for: .clear).horizontal
        }
        set {
            setPropertyNumber(NSNumber(value: newValue), forName: "clearIconOffset")
            base.setPositionAdjustment(UIOffset(horizontal: newValue, vertical: 0), for: .clear)
        }
    }

    /// 设置搜索文本离左侧图标的偏移位置
    public var searchTextOffset: CGFloat {
        get { return base.searchTextPositionAdjustment.horizontal }
        set { base.searchTextPositionAdjustment = UIOffset(horizontal: newValue, vertical: 0) }
    }

    /// 设置TextField搜索图标(placeholder)是否居中，否则居左
    public var searchIconCenter: Bool {
        get {
            return propertyBool(forName: "searchIconCenter")
        }
        set {
            setPropertyBool(newValue, forName: "searchIconCenter")
            base.setNeedsLayout()
            base.layoutIfNeeded()
        }
    }

    /// 强制取消按钮一直可点击，需在showsCancelButton设置之后生效。默认SearchBar失去焦点之后取消按钮不可点击
    public var forceCancelButtonEnabled: Bool {
        get {
            return propertyBool(forName: "forceCancelButtonEnabled")
        }
        set {
            setPropertyBool(newValue, forName: "forceCancelButtonEnabled")
            guard let cancelButton = cancelButton else { return }
            if newValue {
                cancelButton.isEnabled = true
                cancelButton.fw.observeProperty(\.isEnabled) { object, _ in
                    if !object.isEnabled { object.isEnabled = true }
                }
            } else {
                cancelButton.fw.unobserveProperty(\.isEnabled)
            }
        }
    }
}

// MARK: - Wrapper+UIViewController
extension Wrapper where Base: UIViewController {
    /// 判断当前控制器是否是头部控制器。如果是导航栏的第一个控制器或者不含有导航栏，则返回YES
    public var isHead: Bool {
        return base.navigationController == nil ||
            base.navigationController?.viewControllers.first == base
    }
    
    /// 判断当前控制器是否是尾部控制器。如果是导航栏的最后一个控制器或者不含有导航栏，则返回YES
    public var isTail: Bool {
        return base.navigationController == nil ||
            base.navigationController?.viewControllers.last == base
    }

    /// 判断当前控制器是否是子控制器。如果父控制器存在，且不是导航栏或标签栏控制器，则返回YES
    public var isChild: Bool {
        if let parent = base.parent,
           !(parent is UINavigationController),
           !(parent is UITabBarController) {
            return true
        }
        return false
    }

    /// 判断当前控制器是否是present弹出。如果是导航栏的第一个控制器且导航栏是present弹出，也返回YES
    public var isPresented: Bool {
        var viewController: UIViewController = base
        if let navigationController = base.navigationController {
            if navigationController.viewControllers.first != base { return false }
            viewController = navigationController
        }
        return viewController.presentingViewController?.presentedViewController == viewController
    }

    /// 判断当前控制器是否是iOS13+默认pageSheet弹出样式。该样式下导航栏高度等与默认样式不同
    public var isPageSheet: Bool {
        let controller: UIViewController = base.navigationController ?? base
        if controller.presentingViewController == nil { return false }
        let style = controller.modalPresentationStyle
        if style == .automatic || style == .pageSheet { return true }
        return false
    }

    /// 视图是否可见，viewWillAppear后为YES，viewDidDisappear后为NO
    public var isViewVisible: Bool {
        return base.isViewLoaded && base.view.window != nil
    }
    
    /// 控制器是否可见，视图可见、尾部控制器、且不含presented控制器时为YES
    public var isVisible: Bool {
        return isViewVisible && isTail && base.presentedViewController == nil
    }
    
    /// 获取祖先视图，标签栏存在时为标签栏根视图，导航栏存在时为导航栏根视图，否则为控制器根视图
    public var ancestorView: UIView {
        if let navigationController = base.tabBarController?.navigationController {
            return navigationController.view
        } else if let tabBarController = base.tabBarController {
            return tabBarController.view
        } else if let navigationController = base.navigationController {
            return navigationController.view
        } else {
            return base.view
        }
    }

    /// 是否已经加载完数据，默认NO，加载数据完成后可标记为YES，可用于第一次加载时显示loading等判断
    public var isDataLoaded: Bool {
        get { return propertyBool(forName: "isDataLoaded") }
        set { setPropertyBool(newValue, forName: "isDataLoaded") }
    }
    
    /// 移除子控制器，解决不能触发viewWillAppear等的bug
    public func removeChild(_ viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.removeFromParent()
        viewController.view.removeFromSuperview()
    }
    
    /// 添加子控制器到当前视图，解决不能触发viewWillAppear等的bug
    public func addChild(_ viewController: UIViewController, layout: ((UIView) -> Void)? = nil) {
        addChild(viewController, in: nil, layout: layout)
    }

    /// 添加子控制器到指定视图，解决不能触发viewWillAppear等的bug
    public func addChild(_ viewController: UIViewController, in view: UIView?, layout: ((UIView) -> Void)? = nil) {
        base.addChild(viewController)
        let superview: UIView = view ?? base.view
        superview.addSubview(viewController.view)
        if layout != nil {
            layout?(viewController.view)
        } else {
            viewController.view.fw.pinEdges(autoScale: false)
        }
        viewController.didMove(toParent: base)
    }
    
    /// 弹出popover控制器
    public func presentPopover(
        _ popover: UIViewController,
        sourcePoint: CGPoint,
        size: CGSize? = nil,
        delegate: (any UIPopoverPresentationControllerDelegate)? = nil,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        popover.modalPresentationStyle = .popover
        if let size = size {
            popover.preferredContentSize = size
        }
        
        if let presentation = popover.popoverPresentationController {
            presentation.sourceView = base.view
            presentation.sourceRect = CGRect(origin: sourcePoint, size: .zero)
            presentation.delegate = delegate
        }
        
        base.present(popover, animated: animated, completion: completion)
    }
}

// MARK: - ViewStyle
/// 视图样式可扩展枚举
public struct ViewStyle: RawRepresentable, Equatable, Hashable {
    
    public typealias RawValue = String
    
    /// 默认视图样式
    public static let `default`: ViewStyle = .init("default")
    
    public var rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
}

// MARK: - UIDevice+UIKit
extension UIDevice {
    
    fileprivate static var innerDeviceUUID: String?
    fileprivate static var innerNetworkInfo = CTTelephonyNetworkInfo()
    
}

// MARK: - UIImageView+UIKit
extension UIImageView {
    
    fileprivate static var innerFaceDetector: CIDetector? = {
        let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        return detector
    }()
    
}

// MARK: - UILabel+UIKit
extension UILabel {
    
    @objc fileprivate func innerSwizzleSetText(_ text: String?) {
        guard let text = text else {
            innerSwizzleSetText(text)
            return
        }
        if (fw.textAttributes?.count ?? 0) < 1 && !fw.issetLineHeight {
            innerSwizzleSetText(text)
            return
        }
        let attributedString = NSAttributedString(string: text, attributes: fw.textAttributes)
        innerSwizzleSetAttributedText(fw.adjustedAttributedString(attributedString))
    }
    
    @objc fileprivate func innerSwizzleSetAttributedText(_ text: NSAttributedString?) {
        guard let text = text else {
            innerSwizzleSetAttributedText(text)
            return
        }
        if (fw.textAttributes?.count ?? 0) < 1 && !fw.issetLineHeight {
            innerSwizzleSetAttributedText(text)
            return
        }
        var attributedString: NSMutableAttributedString? = NSMutableAttributedString(string: text.string, attributes: fw.textAttributes)
        attributedString = fw.adjustedAttributedString(attributedString)?.mutableCopy() as? NSMutableAttributedString
        text.enumerateAttributes(in: NSMakeRange(0, text.length)) { attrs, range, _ in
            attributedString?.addAttributes(attrs, range: range)
        }
        innerSwizzleSetAttributedText(attributedString)
    }
    
    @objc fileprivate func innerSwizzleSetLineBreakMode(_ lineBreakMode: NSLineBreakMode) {
        innerSwizzleSetLineBreakMode(lineBreakMode)
        guard var textAttributes = fw.textAttributes else { return }
        if let paragraphStyle = textAttributes[.paragraphStyle] as? NSParagraphStyle,
           let mutableStyle = paragraphStyle.mutableCopy() as? NSMutableParagraphStyle {
            mutableStyle.lineBreakMode = lineBreakMode
            textAttributes[.paragraphStyle] = mutableStyle
            fw.textAttributes = textAttributes
        }
    }
    
    @objc fileprivate func innerSwizzleSetTextAlignment(_ textAlignment: NSTextAlignment) {
        innerSwizzleSetTextAlignment(textAlignment)
        guard var textAttributes = fw.textAttributes else { return }
        if let paragraphStyle = textAttributes[.paragraphStyle] as? NSParagraphStyle,
           let mutableStyle = paragraphStyle.mutableCopy() as? NSMutableParagraphStyle {
            mutableStyle.alignment = textAlignment
            textAttributes[.paragraphStyle] = mutableStyle
            fw.textAttributes = textAttributes
        }
    }
    
}

// MARK: - UIControl+UIKit
extension UIControl {
    
    @objc dynamic fileprivate var innerTouchEventInterval: TimeInterval {
        get { fw.propertyDouble(forName: "touchEventInterval") }
        set { fw.setPropertyDouble(newValue, forName: "touchEventInterval") }
    }
    
}

// MARK: - UIButton+UIKit
extension UIButton {
    
    fileprivate static var innerHighlightedAlpha: CGFloat = 0.5
    fileprivate static var innerDisabledAlpha: CGFloat = 0.3
    
}

// MARK: - UIScrollView+UIKit
extension UIScrollView {
    
    @objc fileprivate func innerSwizzleGestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let shouldBlock = fw.shouldBegin {
            return shouldBlock(gestureRecognizer)
        }
        
        return innerSwizzleGestureRecognizerShouldBegin(gestureRecognizer)
    }
    
    @objc fileprivate func innerSwizzleGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let shouldBlock = fw.shouldRecognizeSimultaneously {
            return shouldBlock(gestureRecognizer, otherGestureRecognizer)
        }
        
        return innerSwizzleGestureRecognizer(gestureRecognizer, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer)
    }
    
    @objc fileprivate func innerSwizzleGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let shouldBlock = fw.shouldRequireFailure {
            return shouldBlock(gestureRecognizer, otherGestureRecognizer)
        }
        
        return innerSwizzleGestureRecognizer(gestureRecognizer, shouldRequireFailureOf: otherGestureRecognizer)
    }
    
    @objc fileprivate func innerSwizzleGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let shouldBlock = fw.shouldBeRequiredToFail {
            return shouldBlock(gestureRecognizer, otherGestureRecognizer)
        }
        
        return innerSwizzleGestureRecognizer(gestureRecognizer, shouldBeRequiredToFailBy: otherGestureRecognizer)
    }
    
}

// MARK: - UISwitch+UIKit
extension UISwitch {
    
    @objc dynamic fileprivate var innerOffTintColor: UIColor? {
        get {
            return fw.property(forName: "offTintColor") as? UIColor
        }
        set {
            let switchWellView = value(forKeyPath: "_visualElement._switchWellView") as? UIView
            var defaultOffTintColor = switchWellView?.fw.property(forName: "defaultOffTintColor") as? UIColor
            if defaultOffTintColor == nil {
                defaultOffTintColor = switchWellView?.backgroundColor
                switchWellView?.fw.setProperty(defaultOffTintColor, forName: "defaultOffTintColor")
            }
            switchWellView?.backgroundColor = newValue ?? defaultOffTintColor
            fw.setProperty(newValue, forName: "offTintColor")
        }
    }
    
}

// MARK: - UITableView+UIKit
extension UITableView {
    
    fileprivate static var innerResetTableConfiguration: ((UITableView) -> Void)?
    
    @objc fileprivate func innerWillDisplay(_ cell: UITableViewCell) {
        let block = cell.fw.property(forName: "willDisplay") as? (UITableViewCell) -> Void
        block?(cell)
    }
    
}

// MARK: - UICollectionView+UIKit
extension UICollectionView {
    
    @objc fileprivate func innerMovementGestureAction(_ gesture: UILongPressGestureRecognizer) {
        if let customBlock = fw.movementGestureBlock,
           !customBlock(gesture) { return }
        
        switch gesture.state {
        case .began:
            if let indexPath = indexPathForItem(at: gesture.location(in: self)) {
                beginInteractiveMovementForItem(at: indexPath)
            }
        case .changed:
            updateInteractiveMovementTargetPosition(gesture.location(in: self))
        case .ended:
            endInteractiveMovement()
        default:
            cancelInteractiveMovement()
        }
    }
    
    @objc fileprivate func innerWillDisplay(_ cell: UICollectionViewCell) {
        let block = cell.fw.property(forName: "willDisplay") as? (UICollectionViewCell) -> Void
        block?(cell)
    }
    
}

// MARK: - SaturationGrayView
fileprivate class SaturationGrayView: UIView {
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return nil
    }
    
}

// MARK: - InputTarget
fileprivate class InputTarget {
    weak var textInput: (UIView & UITextInput)?
    var maxLength: Int = 0
    var maxUnicodeLength: Int = 0
    var textChangedBlock: ((String) -> Void)?
    var autoCompleteInterval: TimeInterval = 0.5
    var autoCompleteTimestamp: TimeInterval = 0
    var autoCompleteBlock: ((String) -> Void)?
    
    private var shouldCheckLength: Bool {
        if let markedTextRange = textInput?.markedTextRange,
           textInput?.position(from: markedTextRange.start, offset: 0) != nil {
            return false
        }
        return true
    }
    private var textValue: String? {
        get {
            if let textField = textInput as? UITextField {
                return textField.text
            } else if let textView = textInput as? UITextView {
                return textView.text
            }
            return nil
        }
        set {
            if let textField = textInput as? UITextField {
                textField.text = newValue
            } else if let textView = textInput as? UITextView {
                textView.text = newValue
            }
        }
    }

    init(textInput: (UIView & UITextInput)?) {
        self.textInput = textInput
    }

    func textLengthChanged() {
        if maxLength > 0, shouldCheckLength {
            if (textValue?.count ?? 0) > maxLength {
                textValue = textValue?.fw.substring(to: maxLength)
            }
        }

        if maxUnicodeLength > 0, shouldCheckLength {
            if (textValue?.fw.unicodeLength ?? 0) > maxUnicodeLength {
                textValue = textValue?.fw.unicodeSubstring(maxUnicodeLength)
            }
        }
    }
    
    func filterText(_ text: String) -> String {
        var filterText = text
        if maxLength > 0, shouldCheckLength {
            if filterText.count > maxLength {
                filterText = filterText.fw.substring(to: maxLength)
            }
        }

        if maxUnicodeLength > 0, shouldCheckLength {
            if filterText.fw.unicodeLength > maxUnicodeLength {
                filterText = filterText.fw.unicodeSubstring(maxUnicodeLength)
            }
        }
        return filterText
    }

    @objc func textChangedAction() {
        textLengthChanged()
        
        if textChangedBlock != nil {
            let inputText = textValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            textChangedBlock?(inputText)
        }

        if autoCompleteBlock != nil {
            autoCompleteTimestamp = Date().timeIntervalSince1970
            let inputText = textValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if inputText.isEmpty {
                autoCompleteBlock?("")
            } else {
                let currentTimestamp = autoCompleteTimestamp
                DispatchQueue.main.asyncAfter(deadline: .now() + autoCompleteInterval) { [weak self] in
                    if currentTimestamp == self?.autoCompleteTimestamp {
                        self?.autoCompleteBlock?(inputText)
                    }
                }
            }
        }
    }
}

// MARK: - FrameworkAutoloader+UIKit
extension FrameworkAutoloader {
    
    @objc static func loadToolkit_UIKit() {
        swizzleUIKitView()
        swizzleUIKitLabel()
        swizzleUIKitControl()
        swizzleUIKitButton()
        swizzleUIKitSwitch()
        swizzleUIKitTextField()
        swizzleUIKitTextView()
        swizzleUIKitSearchBar()
    }
    
    private static func swizzleUIKitView() {
        NSObject.fw.swizzleInstanceMethod(
            UIView.self,
            selector: #selector(UIView.point(inside:with:)),
            methodSignature: (@convention(c) (UIView, Selector, CGPoint, UIEvent?) -> Bool).self,
            swizzleSignature: (@convention(block) (UIView, CGPoint, UIEvent?) -> Bool).self
        ) { store in { selfObject, point, event in
            if let insetsValue = selfObject.fw.property(forName: "touchInsets") as? NSValue {
                let touchInsets = insetsValue.uiEdgeInsetsValue
                var bounds = selfObject.bounds
                bounds = CGRect(x: bounds.origin.x - touchInsets.left, y: bounds.origin.y - touchInsets.top, width: bounds.size.width + touchInsets.left + touchInsets.right, height: bounds.size.height + touchInsets.top + touchInsets.bottom)
                return CGRectContainsPoint(bounds, point)
            }
            
            var pointInside = store.original(selfObject, store.selector, point, event)
            if (!pointInside && selfObject.fw.propertyBool(forName: "pointInsideSubviews")) {
                for subview in selfObject.subviews {
                    if subview.point(inside: CGPoint(x: point.x - subview.frame.origin.x, y: point.y - subview.frame.origin.y), with: event) {
                        pointInside = true
                        break
                    }
                }
            }
            return pointInside
        }}
        
        NSObject.fw.swizzleInstanceMethod(
            UIView.self,
            selector: #selector(UIView.hitTest(_:with:)),
            methodSignature: (@convention(c) (UIView, Selector, CGPoint, UIEvent?) -> UIView?).self,
            swizzleSignature: (@convention(block) (UIView, CGPoint, UIEvent?) -> UIView?).self
        ) { store in { selfObject, point, event in
            guard selfObject.fw.isPenetrable else {
                return store.original(selfObject, store.selector, point, event)
            }
            
            guard selfObject.fw.isViewVisible, !selfObject.subviews.isEmpty else { return nil }
            for subview in selfObject.subviews.reversed() {
                guard subview.isUserInteractionEnabled,
                      subview.frame.contains(point),
                      subview.fw.isViewVisible else { continue }
                
                let subPoint = selfObject.convert(point, to: subview)
                guard let hitView = subview.hitTest(subPoint, with: event) else { continue }
                return hitView
            }
            return nil
        }}
    }
    
    private static func swizzleUIKitLabel() {
        NSObject.fw.swizzleInstanceMethod(
            UILabel.self,
            selector: #selector(UILabel.drawText(in:)),
            methodSignature: (@convention(c) (UILabel, Selector, CGRect) -> Void).self,
            swizzleSignature: (@convention(block) (UILabel, CGRect) -> Void).self
        ) { store in { selfObject, aRect in
            var rect = aRect
            if selfObject.fw.issetContentInset {
                rect = rect.inset(by: selfObject.fw.contentInset)
            }
            
            let verticalAlignment = selfObject.fw.verticalAlignment
            if verticalAlignment == .top {
                let fitsSize = selfObject.sizeThatFits(rect.size)
                rect = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.size.width, height: fitsSize.height)
            } else if verticalAlignment == .bottom {
                let fitsSize = selfObject.sizeThatFits(rect.size)
                rect = CGRect(x: rect.origin.x, y: rect.origin.y + (rect.size.height - fitsSize.height), width: rect.size.width, height: fitsSize.height)
            }
            
            store.original(selfObject, store.selector, rect)
        }}
        
        NSObject.fw.swizzleInstanceMethod(
            UILabel.self,
            selector: #selector(getter: UILabel.intrinsicContentSize),
            methodSignature: (@convention(c) (UILabel, Selector) -> CGSize).self,
            swizzleSignature: (@convention(block) (UILabel) -> CGSize).self
        ) { store in { selfObject in
            if selfObject.fw.issetContentInset {
                let preferredMaxLayoutWidth = selfObject.preferredMaxLayoutWidth > 0 ? selfObject.preferredMaxLayoutWidth : .greatestFiniteMagnitude
                return selfObject.sizeThatFits(CGSize(width: preferredMaxLayoutWidth, height: .greatestFiniteMagnitude))
            }
            
            return store.original(selfObject, store.selector)
        }}
        
        NSObject.fw.swizzleInstanceMethod(
            UILabel.self,
            selector: #selector(UILabel.sizeThatFits(_:)),
            methodSignature: (@convention(c) (UILabel, Selector, CGSize) -> CGSize).self,
            swizzleSignature: (@convention(block) (UILabel, CGSize) -> CGSize).self
        ) { store in { selfObject, aSize in
            var size = aSize
            if selfObject.fw.issetContentInset {
                let contentInset = selfObject.fw.contentInset
                size = CGSize(width: size.width - contentInset.left - contentInset.right, height: size.height - contentInset.top - contentInset.bottom)
                var fitsSize = store.original(selfObject, store.selector, size)
                if !fitsSize.equalTo(.zero) {
                    fitsSize = CGSize(width: fitsSize.width + contentInset.left + contentInset.right, height: fitsSize.height + contentInset.top + contentInset.bottom)
                }
                return fitsSize
            }
            
            return store.original(selfObject, store.selector, size)
        }}
        
        NSObject.fw.exchangeInstanceMethod(UILabel.self, originalSelector: #selector(setter: UILabel.text), swizzleSelector: #selector(UILabel.innerSwizzleSetText(_:)))
        NSObject.fw.exchangeInstanceMethod(UILabel.self, originalSelector: #selector(setter: UILabel.attributedText), swizzleSelector: #selector(UILabel.innerSwizzleSetAttributedText(_:)))
        NSObject.fw.exchangeInstanceMethod(UILabel.self, originalSelector: #selector(setter: UILabel.lineBreakMode), swizzleSelector: #selector(UILabel.innerSwizzleSetLineBreakMode(_:)))
        NSObject.fw.exchangeInstanceMethod(UILabel.self, originalSelector: #selector(setter: UILabel.textAlignment), swizzleSelector: #selector(UILabel.innerSwizzleSetTextAlignment(_:)))
    }
    
    private static func swizzleUIKitControl() {
        NSObject.fw.swizzleInstanceMethod(
            UIControl.self,
            selector: #selector(UIControl.sendAction(_:to:for:)),
            methodSignature: (@convention(c) (UIControl, Selector, Selector, Any?, UIEvent?) -> Void).self,
            swizzleSignature: (@convention(block) (UIControl, Selector, Any?, UIEvent?) -> Void).self
        ) { store in { selfObject, action, target, event in
            // 仅拦截Touch事件，且配置了间隔时间的Event
            if let event = event, event.type == .touches, event.subtype == .none,
               selfObject.fw.touchEventInterval > 0 {
                if Date().timeIntervalSince1970 - selfObject.fw.touchEventTimestamp < selfObject.fw.touchEventInterval { return }
                selfObject.fw.touchEventTimestamp = Date().timeIntervalSince1970
            }
            
            store.original(selfObject, store.selector, action, target, event)
        }}
    }
    
    private static func swizzleUIKitButton() {
        NSObject.fw.swizzleInstanceMethod(
            UIButton.self,
            selector: #selector(setter: UIButton.isEnabled),
            methodSignature: (@convention(c) (UIButton, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) (UIButton, Bool) -> Void).self
        ) { store in { selfObject, enabled in
            store.original(selfObject, store.selector, enabled)
            
            if selfObject.fw.disabledAlpha > 0 {
                selfObject.alpha = enabled ? 1 : selfObject.fw.disabledAlpha
            }
            if selfObject.fw.disabledChanged != nil {
                selfObject.fw.disabledChanged?(selfObject, enabled)
            }
        }}
        
        NSObject.fw.swizzleInstanceMethod(
            UIButton.self,
            selector: #selector(setter: UIButton.isHighlighted),
            methodSignature: (@convention(c) (UIButton, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) (UIButton, Bool) -> Void).self
        ) { store in { selfObject, highlighted in
            store.original(selfObject, store.selector, highlighted)
            
            if selfObject.isEnabled && selfObject.fw.highlightedAlpha > 0 {
                selfObject.alpha = highlighted ? selfObject.fw.highlightedAlpha : 1
            }
            if selfObject.isEnabled && selfObject.fw.highlightedChanged != nil {
                selfObject.fw.highlightedChanged?(selfObject, highlighted)
            }
        }}
        
        NSObject.fw.swizzleInstanceMethod(
            UIButton.self,
            selector: #selector(getter: UIButton.intrinsicContentSize),
            methodSignature: (@convention(c) (UIButton, Selector) -> CGSize).self,
            swizzleSignature: (@convention(block) @MainActor (UIButton) -> CGSize).self
        ) { store in { selfObject in
            if selfObject.fw.contentCollapse, !selfObject.fw.isNotEmpty {
                return .zero
            }
            
            return store.original(selfObject, store.selector)
        }}
        
        NSObject.fw.swizzleInstanceMethod(
            UIButton.self,
            selector: #selector(UIButton.sizeThatFits(_:)),
            methodSignature: (@convention(c) (UIButton, Selector, CGSize) -> CGSize).self,
            swizzleSignature: (@convention(block) @MainActor (UIButton, CGSize) -> CGSize).self
        ) { store in { selfObject, size in
            if selfObject.fw.contentCollapse, !selfObject.fw.isNotEmpty {
                return .zero
            }
            
            return store.original(selfObject, store.selector, size)
        }}
    }
    
    private static func swizzleUIKitSwitch() {
        NSObject.fw.swizzleInstanceMethod(
            UISwitch.self,
            selector: #selector(UISwitch.traitCollectionDidChange(_:)),
            methodSignature: (@convention(c) (UISwitch, Selector, UITraitCollection?) -> Void).self,
            swizzleSignature: (@convention(block) (UISwitch, UITraitCollection?) -> Void).self
        ) { store in { selfObject, previousTraitCollection in
            store.original(selfObject, store.selector, previousTraitCollection)

            guard selfObject.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
            guard let offTintColor = selfObject.fw.offTintColor else { return }
            DispatchQueue.main.async {
                selfObject.fw.offTintColor = offTintColor
            }
        }}
    }
    
    private static func swizzleUIKitTextField() {
        NSObject.fw.swizzleInstanceMethod(
            UITextField.self,
            selector: #selector(UITextField.canPerformAction(_:withSender:)),
            methodSignature: (@convention(c) (UITextField, Selector, Selector, Any?) -> Bool).self,
            swizzleSignature: (@convention(block) (UITextField, Selector, Any?) -> Bool).self
        ) { store in { selfObject, action, sender in
            if selfObject.fw.menuDisabled { return false }
            
            return store.original(selfObject, store.selector, action, sender)
        }}
        
        NSObject.fw.swizzleInstanceMethod(
            UITextField.self,
            selector: #selector(UITextField.caretRect(for:)),
            methodSignature: (@convention(c) (UITextField, Selector, UITextPosition) -> CGRect).self,
            swizzleSignature: (@convention(block) (UITextField, UITextPosition) -> CGRect).self
        ) { store in { selfObject, position in
            var caretRect = store.original(selfObject, store.selector, position)
            guard let rectValue = selfObject.fw.property(forName: "cursorRect") as? NSValue else { return caretRect }
            
            let rect = rectValue.cgRectValue
            if rect.origin.x != 0 { caretRect.origin.x += rect.origin.x }
            if rect.origin.y != 0 { caretRect.origin.y += rect.origin.y }
            if rect.size.width != 0 { caretRect.size.width = rect.size.width }
            if rect.size.height != 0 { caretRect.size.height = rect.size.height }
            return caretRect
        }}
    }
    
    private static func swizzleUIKitTextView() {
        NSObject.fw.swizzleInstanceMethod(
            UITextView.self,
            selector: #selector(UITextView.canPerformAction(_:withSender:)),
            methodSignature: (@convention(c) (UITextView, Selector, Selector, Any?) -> Bool).self,
            swizzleSignature: (@convention(block) (UITextView, Selector, Any?) -> Bool).self
        ) { store in { selfObject, action, sender in
            if selfObject.fw.menuDisabled { return false }
            
            return store.original(selfObject, store.selector, action, sender)
        }}
        
        NSObject.fw.swizzleInstanceMethod(
            UITextView.self,
            selector: #selector(UITextView.caretRect(for:)),
            methodSignature: (@convention(c) (UITextView, Selector, UITextPosition) -> CGRect).self,
            swizzleSignature: (@convention(block) (UITextView, UITextPosition) -> CGRect).self
        ) { store in { selfObject, position in
            var caretRect = store.original(selfObject, store.selector, position)
            guard let rectValue = selfObject.fw.property(forName: "cursorRect") as? NSValue else { return caretRect }
            
            let rect = rectValue.cgRectValue
            if rect.origin.x != 0 { caretRect.origin.x += rect.origin.x }
            if rect.origin.y != 0 { caretRect.origin.y += rect.origin.y }
            if rect.size.width != 0 { caretRect.size.width = rect.size.width }
            if rect.size.height != 0 { caretRect.size.height = rect.size.height }
            return caretRect
        }}
    }
    
    private static func swizzleUIKitSearchBar() {
        NSObject.fw.swizzleInstanceMethod(
            UISearchBar.self,
            selector: #selector(UISearchBar.layoutSubviews),
            methodSignature: (@convention(c) (UISearchBar, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UISearchBar) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            
            if let isCenterValue = selfObject.fw.propertyNumber(forName: "searchIconCenter") {
                if !isCenterValue.boolValue {
                    let offset = selfObject.fw.propertyNumber(forName: "searchIconOffset")
                    selfObject.setPositionAdjustment(UIOffset(horizontal: offset?.doubleValue ?? 0, vertical: 0), for: .search)
                } else {
                    let textField = selfObject.searchTextField
                    var attributes: [NSAttributedString.Key: Any]?
                    if let font = textField.font {
                        attributes = [.font: font]
                    }
                    let placeholderWidth = (selfObject.placeholder as? NSString)?.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: attributes, context: nil).size.width ?? .zero
                    let textOffset = 4 + selfObject.searchTextPositionAdjustment.horizontal
                    let iconWidth = textField.leftView?.frame.size.width ?? 0
                    let targetWidth = textField.frame.size.width - ceil(placeholderWidth) - textOffset - iconWidth
                    let position = targetWidth / 2.0 - 6.0
                    selfObject.setPositionAdjustment(UIOffset(horizontal: position > 0 ? position : 0, vertical: 0), for: .search)
                }
            }
        }}
        
        NSObject.fw.swizzleInstanceMethod(
            UISearchBar.self,
            selector: #selector(setter: UISearchBar.placeholder),
            methodSignature: (@convention(c) (UISearchBar, Selector, String?) -> Void).self,
            swizzleSignature: (@convention(block) (UISearchBar, String?) -> Void).self
        ) { store in { selfObject, placeholder in
            store.original(selfObject, store.selector, placeholder)
            
            if selfObject.fw.placeholderColor != nil || selfObject.fw.font != nil {
                guard let attrString = selfObject.searchTextField.attributedPlaceholder?.mutableCopy() as? NSMutableAttributedString else { return }
                
                if let placeholderColor = selfObject.fw.placeholderColor {
                    attrString.addAttribute(.foregroundColor, value: placeholderColor, range: NSMakeRange(0, attrString.length))
                }
                if let font = selfObject.fw.font {
                    attrString.addAttribute(.font, value: font, range: NSMakeRange(0, attrString.length))
                }
                // 默认移除文字阴影
                attrString.removeAttribute(.shadow, range: NSMakeRange(0, attrString.length))
                selfObject.searchTextField.attributedPlaceholder = attrString
            }
        }}
        
        NSObject.fw.swizzleInstanceMethod(
            UISearchBar.self,
            selector: #selector(UISearchBar.didMoveToWindow),
            methodSignature: (@convention(c) (UISearchBar, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UISearchBar) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            
            if selfObject.fw.placeholderColor != nil {
                let placeholder = selfObject.placeholder
                selfObject.placeholder = placeholder
            }
        }}
        
        // iOS13因为层级关系变化，兼容处理
        NSObject.fw.swizzleMethod(
            objc_getClass("UISearchBarTextField"),
            selector: #selector(setter: UITextField.frame),
            methodSignature: (@convention(c) (UITextField, Selector, CGRect) -> Void).self,
            swizzleSignature: (@convention(block) (UITextField, CGRect) -> Void).self
        ) { store in { selfObject, aFrame in
            var frame = aFrame
            let searchBar = selfObject.superview?.superview?.superview as? UISearchBar
            if let searchBar = searchBar {
                var textFieldMaxX = searchBar.bounds.size.width
                if let cancelInsetValue = searchBar.fw.property(forName: "cancelButtonInset") as? NSValue,
                   let cancelButton = searchBar.fw.cancelButton {
                    let cancelInset = cancelInsetValue.uiEdgeInsetsValue
                    let cancelWidth = cancelButton.sizeThatFits(searchBar.bounds.size).width
                    textFieldMaxX = searchBar.bounds.size.width - cancelWidth - cancelInset.left - cancelInset.right
                    frame.size.width = textFieldMaxX - frame.origin.x
                }
                
                if let contentInsetValue = searchBar.fw.property(forName: "contentInset") as? NSValue {
                    let contentInset = contentInsetValue.uiEdgeInsetsValue
                    frame = CGRect(x: contentInset.left, y: contentInset.top, width: textFieldMaxX - contentInset.left - contentInset.right, height: searchBar.bounds.size.height - contentInset.top - contentInset.bottom)
                }
            }
            
            store.original(selfObject, store.selector, frame)
        }}
        
        NSObject.fw.swizzleMethod(
            objc_getClass("UINavigationButton"),
            selector: #selector(setter: UIButton.frame),
            methodSignature: (@convention(c) (UIButton, Selector, CGRect) -> Void).self,
            swizzleSignature: (@convention(block) (UIButton, CGRect) -> Void).self
        ) { store in { selfObject, aFrame in
            var frame = aFrame
            let searchBar: UISearchBar? = selfObject.superview?.superview?.superview as? UISearchBar
            if let searchBar = searchBar,
               let cancelInsetValue = searchBar.fw.property(forName: "cancelButtonInset") as? NSValue {
                let cancelInset = cancelInsetValue.uiEdgeInsetsValue
                let cancelWidth = selfObject.sizeThatFits(searchBar.bounds.size).width
                frame.origin.x = searchBar.bounds.size.width - cancelWidth - cancelInset.right
                frame.origin.y = cancelInset.top
                frame.size.height = searchBar.bounds.size.height - cancelInset.top - cancelInset.bottom
            }
            
            store.original(selfObject, store.selector, frame)
        }}
    }
    
    private static var swizzleUIKitScrollViewFinished = false
    
    fileprivate static func swizzleUIKitScrollView() {
        guard !swizzleUIKitScrollViewFinished else { return }
        swizzleUIKitScrollViewFinished = true
        
        NSObject.fw.exchangeInstanceMethod(UIScrollView.self, originalSelector: #selector(UIGestureRecognizerDelegate.gestureRecognizerShouldBegin(_:)), swizzleSelector: #selector(UIScrollView.innerSwizzleGestureRecognizerShouldBegin(_:)))
        NSObject.fw.exchangeInstanceMethod(UIScrollView.self, originalSelector: #selector(UIGestureRecognizerDelegate.gestureRecognizer(_:shouldRecognizeSimultaneouslyWith:)), swizzleSelector: #selector(UIScrollView.innerSwizzleGestureRecognizer(_:shouldRecognizeSimultaneouslyWith:)))
        NSObject.fw.exchangeInstanceMethod(UIScrollView.self, originalSelector: #selector(UIGestureRecognizerDelegate.gestureRecognizer(_:shouldRequireFailureOf:)), swizzleSelector: #selector(UIScrollView.innerSwizzleGestureRecognizer(_:shouldRequireFailureOf:)))
        NSObject.fw.exchangeInstanceMethod(UIScrollView.self, originalSelector: #selector(UIGestureRecognizerDelegate.gestureRecognizer(_:shouldBeRequiredToFailBy:)), swizzleSelector: #selector(UIScrollView.innerSwizzleGestureRecognizer(_:shouldBeRequiredToFailBy:)))
    }
    
    private static var swizzleUIKitTableViewCellFinished = false
    
    fileprivate static func swizzleUIKitTableViewCell() {
        guard !swizzleUIKitTableViewCellFinished else { return }
        swizzleUIKitTableViewCellFinished = true
        
        NSObject.fw.swizzleInstanceMethod(
            UITableViewCell.self,
            selector: #selector(UITableViewCell.layoutSubviews),
            methodSignature: (@convention(c) (UITableViewCell, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UITableViewCell) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            
            let hasAccessoryInset = selfObject.accessoryView?.superview != nil && selfObject.fw.accessoryEdgeInsets != .zero
            let hasImageInset = selfObject.imageView?.image != nil && selfObject.fw.imageEdgeInsets != .zero
            let hasTextInset = (selfObject.textLabel?.text?.count ?? 0) > 0 && selfObject.fw.textEdgeInsets != .zero
            let hasDetailTextInset = (selfObject.detailTextLabel?.text?.count ?? 0) > 0 && selfObject.fw.detailTextEdgeInsets != .zero
            guard hasAccessoryInset || hasImageInset || hasTextInset || hasDetailTextInset else {
                return
            }
            
            if hasAccessoryInset {
                var accessoryFrame = selfObject.accessoryView?.frame ?? .zero
                accessoryFrame.origin.x = accessoryFrame.minX - selfObject.fw.accessoryEdgeInsets.right
                accessoryFrame.origin.y = accessoryFrame.minY + selfObject.fw.accessoryEdgeInsets.top - selfObject.fw.accessoryEdgeInsets.bottom
                selfObject.accessoryView?.frame = accessoryFrame
                
                var contentFrame = selfObject.contentView.frame
                contentFrame.size.width = accessoryFrame.minX - selfObject.fw.accessoryEdgeInsets.left
                selfObject.contentView.frame = contentFrame
            }
            
            var imageFrame = selfObject.imageView?.frame ?? .zero
            var textFrame = selfObject.textLabel?.frame ?? .zero
            var detailTextFrame = selfObject.detailTextLabel?.frame ?? .zero
            
            if hasImageInset {
                imageFrame.origin.x += selfObject.fw.imageEdgeInsets.left - selfObject.fw.imageEdgeInsets.right
                imageFrame.origin.y += selfObject.fw.imageEdgeInsets.top - selfObject.fw.imageEdgeInsets.bottom
                
                textFrame.origin.x += selfObject.fw.imageEdgeInsets.left
                textFrame.size.width = min(textFrame.width, selfObject.contentView.bounds.width - textFrame.minX)
                
                detailTextFrame.origin.x += selfObject.fw.imageEdgeInsets.left
                detailTextFrame.size.width = min(detailTextFrame.width, selfObject.contentView.bounds.width - detailTextFrame.minX)
            }
            if hasTextInset {
                textFrame.origin.x += selfObject.fw.textEdgeInsets.left - selfObject.fw.textEdgeInsets.right
                textFrame.origin.y += selfObject.fw.textEdgeInsets.top - selfObject.fw.textEdgeInsets.bottom
                textFrame.size.width = min(textFrame.width, selfObject.contentView.bounds.width - textFrame.minX)
            }
            if hasDetailTextInset {
                detailTextFrame.origin.x += selfObject.fw.detailTextEdgeInsets.left - selfObject.fw.detailTextEdgeInsets.right
                detailTextFrame.origin.y += selfObject.fw.detailTextEdgeInsets.top - selfObject.fw.detailTextEdgeInsets.bottom
                detailTextFrame.size.width = min(detailTextFrame.width, selfObject.contentView.bounds.width - detailTextFrame.minX)
            }
            
            if hasImageInset {
                selfObject.imageView?.frame = imageFrame
            }
            if hasImageInset || hasTextInset {
                selfObject.textLabel?.frame = textFrame
            }
            if hasImageInset || hasDetailTextInset {
                selfObject.detailTextLabel?.frame = detailTextFrame
            }
            
            if hasAccessoryInset {
                if let textLabel = selfObject.textLabel, textLabel.frame.maxX > selfObject.contentView.bounds.width {
                    var textLabelFrame = textLabel.frame
                    textLabelFrame.size.width = selfObject.contentView.bounds.width - textLabelFrame.minX
                    textLabel.frame = textLabelFrame
                }
                if let detailTextLabel = selfObject.detailTextLabel, detailTextLabel.frame.maxX > selfObject.contentView.bounds.width {
                    var detailTextLabelFrame = detailTextLabel.frame
                    detailTextLabelFrame.size.width = selfObject.contentView.bounds.width - detailTextLabelFrame.minX
                    detailTextLabel.frame = detailTextLabelFrame
                }
            }
        }}
    }
    
}
