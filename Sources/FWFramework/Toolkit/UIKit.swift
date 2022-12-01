//
//  UIKit.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif
#if FWMacroTracking
import AdSupport
#endif

// MARK: - UIBezierPath+UIKit
@_spi(FW) @objc extension UIBezierPath {
    
    /// 绘制形状图片，自定义画笔宽度、画笔颜色、填充颜色，填充颜色为nil时不执行填充
    public func fw_shapeImage(_ size: CGSize, strokeWidth: CGFloat, strokeColor: UIColor, fillColor: UIColor?) -> UIImage? {
        return self.__fw_shapeImage(size, strokeWidth: strokeWidth, stroke: strokeColor, fill: fillColor)
    }

    /// 绘制形状Layer，自定义画笔宽度、画笔颜色、填充颜色，填充颜色为nil时不执行填充
    public func fw_shapeLayer(_ rect: CGRect, strokeWidth: CGFloat, strokeColor: UIColor, fillColor: UIColor?) -> CAShapeLayer {
        return self.__fw_shapeLayer(rect, strokeWidth: strokeWidth, stroke: strokeColor, fill: fillColor)
    }

    /// 根据点计算折线路径(NSValue点)
    public static func fw_lines(points: [NSValue]) -> UIBezierPath {
        return Self.__fw_lines(withPoints: points)
    }

    /// 根据点计算贝塞尔曲线路径
    public static func fw_quadCurvedPath(points: [NSValue]) -> UIBezierPath {
        return Self.__fw_quadCurvedPath(withPoints: points)
    }
    
    /// 计算两点的中心点
    public static func fw_middlePoint(_ p1: CGPoint, with p2: CGPoint) -> CGPoint {
        return Self.__fw_middlePoint(p1, with: p2)
    }

    /// 计算两点的贝塞尔曲线控制点
    public static func fw_controlPoint(_ p1: CGPoint, with p2: CGPoint) -> CGPoint {
        return Self.__fw_controlPoint(p1, with: p2)
    }
    
    /// 将角度(0~360)转换为弧度，周长为2*M_PI*r
    public static func fw_radian(degree: CGFloat) -> CGFloat {
        return Self.__fw_radian(withDegree: degree)
    }
    
    /// 将弧度转换为角度(0~360)
    public static func fw_degree(radian: CGFloat) -> CGFloat {
        return Self.__fw_degree(withRadian: radian)
    }
    
    /// 根据滑动方向计算rect的线段起点、终点中心点坐标数组(示范：田)。默认从上到下滑动
    public static func fw_linePoints(rect: CGRect, direction: UISwipeGestureRecognizer.Direction) -> [NSValue] {
        return Self.__fw_linePoints(with: rect, direction: direction)
    }
    
}

// MARK: - UIDevice+UIKit
@_spi(FW) @objc extension UIDevice {
    
    /// 设置设备token原始Data，格式化并保存
    public static func fw_setDeviceTokenData(_ tokenData: Data?) {
        if let tokenData = tokenData {
            fw_deviceToken = tokenData.map{ String(format: "%02.0hhx", $0) }.joined()
        } else {
            fw_deviceToken = nil
        }
    }

    /// 获取设备Token格式化后的字符串
    public static var fw_deviceToken: String? {
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

    /// 获取设备模型，格式："iPhone6,1"
    public static var fw_deviceModel: String? {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let deviceModel = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return deviceModel
    }

    /// 获取设备IDFV(内部使用)，同账号应用全删除后会改变，可通过keychain持久化
    public static var fw_deviceIDFV: String? {
        return UIDevice.current.identifierForVendor?.uuidString
    }

    /// 获取设备IDFA(外部使用)，重置广告或系统后会改变，需先检测广告追踪权限，启用Tracking子模块后生效
    public static var fw_deviceIDFA: String? {
        #if FWMacroTracking
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
        #else
        return nil
        #endif
    }
    
    /// 获取或设置设备UUID，自动keychain持久化。默认获取IDFV(未使用IDFA，避免额外权限)，失败则随机生成一个
    public static var fw_deviceUUID: String {
        get {
            if let deviceUUID = UIDevice.fw_staticDeviceUUID {
                return deviceUUID
            }
            
            if let deviceUUID = KeychainManager.shared.password(forService: "FWDeviceUUID", account: Bundle.main.bundleIdentifier) {
                UIDevice.fw_staticDeviceUUID = deviceUUID
                return deviceUUID
            }
            
            let deviceUUID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            UIDevice.fw_staticDeviceUUID = deviceUUID
            KeychainManager.shared.setPassword(deviceUUID, forService: "FWDeviceUUID", account: Bundle.main.bundleIdentifier)
            return deviceUUID
        }
        set {
            UIDevice.fw_staticDeviceUUID = newValue
            KeychainManager.shared.setPassword(newValue, forService: "FWDeviceUUID", account: Bundle.main.bundleIdentifier)
        }
    }
    
    private static var fw_staticDeviceUUID: String?
    
    /// 是否越狱
    public static var fw_isJailbroken: Bool {
        return Self.__fw_isJailbroken
    }
    
    /// 本地IP地址
    public static var fw_ipAddress: String? {
        return Self.__fw_ipAddress
    }
    
    /// 本地主机名称
    public static var fw_hostName: String? {
        return Self.__fw_hostName
    }
    
    /// 手机运营商名称
    public static var fw_carrierName: String? {
        return Self.__fw_carrierName
    }
    
    /// 手机蜂窝网络类型，仅区分2G|3G|4G|5G
    public static var fw_networkType: String? {
        return Self.__fw_networkType
    }
    
}

// MARK: - UIView+UIKit
/// 事件穿透实现方法：重写-hitTest:withEvent:方法，当为指定视图(如self)时返回nil排除即可
@_spi(FW) @objc extension UIView {
    
    /// 视图是否可见，视图hidden为NO、alpha>0.01、window存在且size不为0才认为可见
    public var fw_isViewVisible: Bool {
        return self.__fw_isViewVisible
    }

    /// 获取响应的视图控制器
    public var fw_viewController: UIViewController? {
        return self.__fw_viewController
    }

    /// 设置额外热区(点击区域)
    public var fw_touchInsets: UIEdgeInsets {
        get { return self.__fw_touchInsets }
        set { self.__fw_touchInsets = newValue }
    }

    /// 设置自动计算适合高度的frame，需实现sizeThatFits:方法
    public var fw_fitFrame: CGRect {
        get { return self.__fw_fitFrame }
        set { self.__fw_fitFrame = newValue }
    }

    /// 计算当前视图适合大小，需实现sizeThatFits:方法
    public var fw_fitSize: CGSize {
        return self.__fw_fitSize
    }

    /// 计算指定边界，当前视图适合大小，需实现sizeThatFits:方法
    public func fw_fitSize(drawSize: CGSize) -> CGSize {
        return self.__fw_fitSize(withDraw: drawSize)
    }
    
    /// 根据tag查找subview，仅从subviews中查找
    public func fw_subview(tag: Int) -> UIView? {
        return self.__fw_subview(withTag: tag)
    }

    /// 设置阴影颜色、偏移和半径
    public func fw_setShadowColor(_ color: UIColor?, offset: CGSize, radius: CGFloat) {
        self.__fw_setShadowColor(color, offset: offset, radius: radius)
    }

    /// 绘制四边边框
    public func fw_setBorderColor(_ color: UIColor?, width: CGFloat) {
        self.__fw_setBorderColor(color, width: width)
    }

    /// 绘制四边边框和四角圆角
    public func fw_setBorderColor(_ color: UIColor?, width: CGFloat, cornerRadius: CGFloat) {
        self.__fw_setBorderColor(color, width: width, cornerRadius: cornerRadius)
    }

    /// 绘制四角圆角
    public func fw_setCornerRadius(_ radius: CGFloat) {
        self.__fw_setCornerRadius(radius)
    }

    /// 绘制单边或多边边框Layer。frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
    public func fw_setBorderLayer(_ edge: UIRectEdge, color: UIColor?, width: CGFloat) {
        self.__fw_setBorderLayer(edge, color: color, width: width)
    }

    /// 绘制单边或多边边框Layer。frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
    public func fw_setBorderLayer(_ edge: UIRectEdge, color: UIColor?, width: CGFloat, leftInset: CGFloat, rightInset: CGFloat) {
        self.__fw_setBorderLayer(edge, color: color, width: width, leftInset: leftInset, rightInset: rightInset)
    }
    
    /// 绘制四边虚线边框和四角圆角。frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
    public func fw_setDashBorderLayer(color: UIColor?, width: CGFloat, cornerRadius: CGFloat, lineLength: CGFloat, lineSpacing: CGFloat) {
        self.__fw_setDashBorderLayer(color, width: width, cornerRadius: cornerRadius, lineLength: lineLength, lineSpacing: lineSpacing)
    }

    /// 绘制单个或多个边框圆角，frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
    public func fw_setCornerLayer(_ corner: UIRectCorner, radius: CGFloat) {
        self.__fw_setCornerLayer(corner, radius: radius)
    }

    /// 绘制单个或多个边框圆角和四边边框，frame必须存在(添加视图后可调用layoutIfNeeded更新frame)
    public func fw_setCornerLayer(_ corner: UIRectCorner, radius: CGFloat, borderColor: UIColor?, width: CGFloat) {
        self.__fw_setCornerLayer(corner, radius: radius, borderColor: borderColor, width: width)
    }
    
    /// 绘制单边或多边边框视图。使用AutoLayout
    public func fw_setBorderView(_ edge: UIRectEdge, color: UIColor?, width: CGFloat) {
        self.__fw_setBorderView(edge, color: color, width: width)
    }

    /// 绘制单边或多边边框。使用AutoLayout
    public func fw_setBorderView(_ edge: UIRectEdge, color: UIColor?, width: CGFloat, leftInset: CGFloat, rightInset: CGFloat) {
        self.__fw_setBorderView(edge, color: color, width: width, leftInset: leftInset, rightInset: rightInset)
    }
    
    /// 开始倒计时，从window移除时自动取消，回调参数为剩余时间
    @discardableResult
    public func fw_startCountDown(_ seconds: Int, block: @escaping (Int) -> Void) -> DispatchSource {
        return self.__fw_startCountDown(seconds, block: block)
    }
    
    /// 设置毛玻璃效果，使用UIVisualEffectView。内容需要添加到UIVisualEffectView.contentView
    @discardableResult
    public func fw_setBlurEffect(_ style: UIBlurEffect.Style) -> UIVisualEffectView? {
        return self.__fw_setBlurEffect(style)
    }
    
    /// 移除所有子视图
    public func fw_removeAllSubviews() {
        self.__fw_removeAllSubviews()
    }

    /// 递归查找指定子类的第一个子视图(含自身)
    public func fw_subview(of clazz: AnyClass) -> UIView? {
        return self.__fw_subview(of: clazz)
    }

    /// 递归查找指定条件的第一个子视图(含自身)
    public func fw_subview(block: @escaping (UIView) -> Bool) -> UIView? {
        return self.__fw_subview(of: block)
    }
    
    /// 递归查找指定条件的第一个父视图(含自身)
    public func fw_superview(block: @escaping (UIView) -> Bool) -> UIView? {
        return self.__fw_superview(of: block)
    }

    /// 图片截图
    public var fw_snapshotImage: UIImage? {
        return self.__fw_snapshotImage
    }

    /// Pdf截图
    public var fw_snapshotPdf: Data? {
        return self.__fw_snapshotPdf
    }
    
    /// 自定义视图排序索引，需结合sortSubviews使用，默认0不处理
    public var fw_sortIndex: Int {
        get { return self.__fw_sortIndex }
        set { self.__fw_sortIndex = newValue }
    }

    /// 根据sortIndex排序subviews，需结合sortIndex使用
    public func fw_sortSubviews() {
        self.__fw_sortSubviews()
    }
    
}

// MARK: - UIImageView+UIKit
@_spi(FW) @objc extension UIImageView {
    
    /// 设置图片模式为ScaleAspectFill，自动拉伸不变形，超过区域隐藏。可通过appearance统一设置
    public func fw_setContentModeAspectFill() {
        self.__fw_setContentModeAspectFill()
    }
    
    /// 优化图片人脸显示，参考：https://github.com/croath/UIImageView-BetterFace
    public func fw_faceAware() {
        self.__fw_faceAware()
    }

    /// 倒影效果
    public func fw_reflect() {
        self.__fw_reflect()
    }

    /// 图片水印
    public func fw_setImage(_ image: UIImage, watermarkImage: UIImage, in rect: CGRect) {
        self.__fw_setImage(image, watermarkImage: watermarkImage, in: rect)
    }

    /// 文字水印，指定区域
    public func fw_setImage(_ image: UIImage, watermarkString: NSAttributedString, in rect: CGRect) {
        self.__fw_setImage(image, watermarkString: watermarkString, in: rect)
    }

    /// 文字水印，指定坐标
    public func fw_setImage(_ image: UIImage, watermarkString: NSAttributedString, at point: CGPoint) {
        self.__fw_setImage(image, watermarkString: watermarkString, at: point)
    }
    
}

// MARK: - UIWindow+UIKit
@_spi(FW) @objc extension UIWindow {
    
    /// 选中并获取指定索引TabBar根视图控制器，适用于Tabbar包含多个Navigation结构，找不到返回nil
    @discardableResult
    public func fw_selectTabBarIndex(_ index: UInt) -> UIViewController? {
        return self.__fw_selectTabBarIndex(index)
    }

    /// 选中并获取指定类TabBar根视图控制器，适用于Tabbar包含多个Navigation结构，找不到返回nil
    @discardableResult
    public func fw_selectTabBarController(_ viewController: AnyClass) -> UIViewController? {
        return self.__fw_selectTabBarController(viewController)
    }

    /// 选中并获取指定条件TabBar根视图控制器，适用于Tabbar包含多个Navigation结构，找不到返回nil
    @discardableResult
    public func fw_selectTabBarBlock(_ block: (UIViewController) -> Bool) -> UIViewController? {
        return self.__fw_selectTabBarBlock(block)
    }
    
}

// MARK: - UILabel+UIKit
@_spi(FW) @objc extension UILabel {
    
    /// 快速设置attributedText样式，设置后调用setText:会自动转发到setAttributedText:方法
    public var fw_textAttributes: [NSAttributedString.Key: Any]? {
        get {
            return fw_property(forName: "fw_textAttributes") as? [NSAttributedString.Key : Any]
        }
        set {
            let prevTextAttributes = self.fw_textAttributes
            if (prevTextAttributes as? NSDictionary)?.isEqual(to: newValue ?? [:]) ?? false { return }
            
            fw_setPropertyCopy(newValue, forName: "fw_textAttributes")
            guard (self.text?.count ?? 0) > 0 else { return }
            
            let string = self.attributedText?.mutableCopy() as? NSMutableAttributedString
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
                        if __Runtime.isEqual(prevTextAttributes[attr], with: value) {
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
            fw_innerSetAttributedText(fw_adjustedAttributedString(string))
        }
    }
    
    private func fw_adjustedAttributedString(_ string: NSAttributedString?) -> NSAttributedString? {
        guard let string = string, string.length > 0 else { return string }
        var attributedString: NSMutableAttributedString?
        if let mutableString = string as? NSMutableAttributedString {
            attributedString = mutableString
        } else {
            attributedString = string.mutableCopy() as? NSMutableAttributedString
        }
        let attributedLength = attributedString?.length ?? 0
        
        if self.fw_textAttributes?[.kern] != nil {
            attributedString?.removeAttribute(.kern, range: NSMakeRange(string.length - 1, 1))
        }
        
        var shouldAdjustLineHeight = self.fw_issetLineHeight
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
            paraStyle.minimumLineHeight = self.fw_lineHeight
            paraStyle.maximumLineHeight = self.fw_lineHeight
            paraStyle.lineBreakMode = self.lineBreakMode
            paraStyle.alignment = self.textAlignment
            attributedString?.addAttribute(.paragraphStyle, value: paraStyle, range: NSMakeRange(0, attributedLength))
            
            let baselineOffset = (self.fw_lineHeight - self.font.lineHeight) / 4.0
            attributedString?.addAttribute(.baselineOffset, value: baselineOffset, range: NSMakeRange(0, attributedLength))
        }
        return attributedString
    }

    /// 快速设置文字的行高，优先级低于fwTextAttributes，设置后调用setText:会自动转发到setAttributedText:方法。小于0时恢复默认行高
    public var fw_lineHeight: CGFloat {
        get {
            if self.fw_issetLineHeight {
                return fw_propertyDouble(forName: "fw_lineHeight")
            } else if (self.attributedText?.length ?? 0) > 0 {
                let string = self.attributedText?.mutableCopy() as? NSMutableAttributedString
                var result: CGFloat = 0
                string?.enumerateAttribute(.paragraphStyle, in: NSMakeRange(0, string?.length ?? 0), using: { obj, range, stop in
                    guard let style = obj as? NSParagraphStyle else { return }
                    if NSEqualRanges(range, NSMakeRange(0, string?.length ?? 0)) {
                        if style.maximumLineHeight != 0 || style.minimumLineHeight != 0 {
                            result = style.maximumLineHeight
                            stop.pointee = true
                        }
                    }
                })
                return result == 0 ? self.font.lineHeight : result
            } else if (self.text?.count ?? 0) > 0 {
                return self.font.lineHeight
            }
            return 0
        }
        set {
            if newValue < 0 {
                fw_setProperty(nil, forName: "fw_lineHeight")
            } else {
                fw_setPropertyDouble(newValue, forName: "fw_lineHeight")
            }
            guard let string = self.attributedText?.string else { return }
            let attributedString = NSAttributedString(string: string, attributes: self.fw_textAttributes)
            self.attributedText = fw_adjustedAttributedString(attributedString)
        }
    }
    
    private var fw_issetLineHeight: Bool {
        return fw_property(forName: "fw_lineHeight") != nil
    }

    /// 自定义内容边距，未设置时为系统默认。当内容为空时不参与intrinsicContentSize和sizeThatFits:计算，方便自动布局
    public var fw_contentInset: UIEdgeInsets {
        get {
            if let value = fw_property(forName: "fw_contentInset") as? NSValue {
                return value.uiEdgeInsetsValue
            }
            return .zero
        }
        set {
            fw_setProperty(NSValue(uiEdgeInsets: newValue), forName: "fw_contentInset")
            self.setNeedsDisplay()
        }
    }

    /// 纵向分布方式，默认居中
    public var fw_verticalAlignment: UIControl.ContentVerticalAlignment {
        get {
            let value = fw_propertyInt(forName: "fw_verticalAlignment")
            return .init(rawValue: value) ?? .center
        }
        set {
            fw_setPropertyInt(newValue.rawValue, forName: "fw_verticalAlignment")
            self.setNeedsDisplay()
        }
    }
    
    /// 添加点击手势并自动识别NSLinkAttributeName|URL属性，点击高亮时回调链接，点击其它区域回调nil
    public func fw_addLinkGesture(block: @escaping (Any?) -> Void) {
        self.isUserInteractionEnabled = true
        self.fw_addTapGesture { gesture in
            guard let gesture = gesture as? UITapGestureRecognizer,
                  let label = gesture.view as? UILabel else { return }
            let attributes = label.fw_attributes(gesture: gesture, allowsSpacing: false)
            let link = attributes[.link] ?? attributes[NSAttributedString.Key("URL")]
            block(link)
        }
    }
    
    /// 获取手势触发位置的文本属性，可实现行内点击效果等，allowsSpacing默认为NO空白处不可点击。为了识别更准确，attributedText需指定font
    public func fw_attributes(gesture: UIGestureRecognizer, allowsSpacing: Bool) -> [NSAttributedString.Key: Any] {
        guard let attributedString = self.attributedText else { return [:] }
        let textContainer = NSTextContainer(size: self.bounds.size)
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = self.numberOfLines
        textContainer.lineBreakMode = self.lineBreakMode
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        let textStorage = NSTextStorage(attributedString: attributedString)
        textStorage.addLayoutManager(layoutManager)
        
        let point = gesture.location(in: self)
        var distance: CGFloat = 0
        let index = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: &distance)
        if !allowsSpacing && distance >= 1 { return [:] }
        return attributedString.attributes(at: index, effectiveRange: nil)
    }

    /// 快速设置标签并指定文本
    public func fw_setFont(_ font: UIFont?, textColor: UIColor?, text: String? = nil) {
        if let font = font { self.font = font }
        if let textColor = textColor { self.textColor = textColor }
        if let text = text { self.text = text }
    }
    
    /// 快速创建标签并指定文本
    public static func fw_label(font: UIFont?, textColor: UIColor?, text: String? = nil) -> Self {
        let label = Self()
        label.fw_setFont(font, textColor: textColor, text: text)
        return label
    }
    
    /// 计算当前文本所占尺寸，需frame或者宽度布局完整
    public var fw_textSize: CGSize {
        if self.frame.size.equalTo(.zero) {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
        
        var attrs: [NSAttributedString.Key: Any] = [:]
        attrs[.font] = self.font
        if self.lineBreakMode != .byWordWrapping {
            let paragraphStyle = NSMutableParagraphStyle()
            // 由于lineBreakMode默认值为TruncatingTail，多行显示时仍然按照WordWrapping计算
            if self.numberOfLines != 1 && self.lineBreakMode == .byTruncatingTail {
                paragraphStyle.lineBreakMode = .byWordWrapping
            } else {
                paragraphStyle.lineBreakMode = self.lineBreakMode
            }
            attrs[.paragraphStyle] = paragraphStyle
        }
        
        let drawSize = CGSize(width: self.frame.size.width, height: .greatestFiniteMagnitude)
        let size = (self.text as? NSString)?.boundingRect(with: drawSize, options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: attrs, context: nil).size ?? .zero
        return CGSize(width: min(drawSize.width, ceil(size.width)), height: min(drawSize.height, ceil(size.height)))
    }

    /// 计算当前属性文本所占尺寸，需frame或者宽度布局完整，attributedText需指定字体
    public var fw_attributedTextSize: CGSize {
        if self.frame.size.equalTo(.zero) {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
        
        let drawSize = CGSize(width: self.frame.size.width, height: .greatestFiniteMagnitude)
        let size = self.attributedText?.boundingRect(with: drawSize, options: [.usesFontLeading, .usesLineFragmentOrigin], context: nil).size ?? .zero
        return CGSize(width: min(drawSize.width, ceil(size.width)), height: min(drawSize.height, ceil(size.height)))
    }
    
    func fw_innerSetText(_ text: String?) {
        guard let text = text else {
            fw_innerSetText(text)
            return
        }
        if (self.fw_textAttributes?.count ?? 0) < 1 && !self.fw_issetLineHeight {
            fw_innerSetText(text)
            return
        }
        let attributedString = NSAttributedString(string: text, attributes: self.fw_textAttributes)
        self.fw_innerSetAttributedText(fw_adjustedAttributedString(attributedString))
    }
    
    func fw_innerSetAttributedText(_ text: NSAttributedString?) {
        guard let text = text else {
            self.fw_innerSetAttributedText(text)
            return
        }
        if (self.fw_textAttributes?.count ?? 0) < 1 && !self.fw_issetLineHeight {
            self.fw_innerSetAttributedText(text)
            return
        }
        var attributedString: NSMutableAttributedString? = NSMutableAttributedString(string: text.string, attributes: self.fw_textAttributes)
        attributedString = fw_adjustedAttributedString(attributedString)?.mutableCopy() as? NSMutableAttributedString
        text.enumerateAttributes(in: NSMakeRange(0, text.length)) { attrs, range, _ in
            attributedString?.addAttributes(attrs, range: range)
        }
        self.fw_innerSetAttributedText(attributedString)
    }
    
    func fw_innerSetLineBreakMode(_ lineBreakMode: NSLineBreakMode) {
        self.fw_innerSetLineBreakMode(lineBreakMode)
        guard var textAttributes = self.fw_textAttributes else { return }
        if let paragraphStyle = textAttributes[.paragraphStyle] as? NSParagraphStyle,
           let mutableStyle = paragraphStyle.mutableCopy() as? NSMutableParagraphStyle {
            mutableStyle.lineBreakMode = lineBreakMode
            textAttributes[.paragraphStyle] = mutableStyle
            self.fw_textAttributes = textAttributes
        }
    }
    
    func fw_innerSetTextAlignment(_ textAlignment: NSTextAlignment) {
        self.fw_innerSetTextAlignment(textAlignment)
        guard var textAttributes = self.fw_textAttributes else { return }
        if let paragraphStyle = textAttributes[.paragraphStyle] as? NSParagraphStyle,
           let mutableStyle = paragraphStyle.mutableCopy() as? NSMutableParagraphStyle {
            mutableStyle.alignment = textAlignment
            textAttributes[.paragraphStyle] = mutableStyle
            self.fw_textAttributes = textAttributes
        }
    }
    
}

// MARK: - UIControl+UIKit
/// 防重复点击可以手工控制enabled或userInteractionEnabled或loading，如request开始时禁用，结束时启用等
@_spi(FW) @objc extension UIControl {
    
    // 设置Touch事件触发间隔，防止短时间多次触发事件，默认0
    public var fw_touchEventInterval: TimeInterval {
        get { return self.__fw_touchEventInterval }
        set { self.__fw_touchEventInterval = newValue }
    }
    
}

// MARK: - UIButton+UIKit
@_spi(FW) @objc extension UIButton {
    
    /// 自定义按钮禁用时的alpha，如0.5，默认0不生效
    public var fw_disabledAlpha: CGFloat {
        get { return self.__fw_disabledAlpha }
        set { self.__fw_disabledAlpha = newValue }
    }

    /// 自定义按钮高亮时的alpha，如0.5，默认0不生效
    public var fw_highlightedAlpha: CGFloat {
        get { return self.__fw_highlightedAlpha }
        set { self.__fw_highlightedAlpha = newValue }
    }

    /// 快速设置文本按钮
    public func fw_setTitle(_ title: String?, font: UIFont?, textColor: UIColor?) {
        self.__fw_setTitle(title, font: font, titleColor: textColor)
    }

    /// 快速设置文本
    public func fw_setTitle(_ title: String?) {
        self.__fw_setTitle(title)
    }

    /// 快速设置图片
    public func fw_setImage(_ image: UIImage?) {
        self.__fw_setImage(image)
    }

    /// 设置图片的居中边位置，需要在setImage和setTitle之后调用才生效，且button大小大于图片+文字+间距
    ///
    /// imageEdgeInsets: 仅有image时相对于button，都有时上左下相对于button，右相对于title
    /// titleEdgeInsets: 仅有title时相对于button，都有时上右下相对于button，左相对于image
    public func fw_setImageEdge(_ edge: UIRectEdge, spacing: CGFloat) {
        self.__fw_setImageEdge(edge, spacing: spacing)
    }
    
    /// 设置状态背景色
    public func fw_setBackgroundColor(_ backgroundColor: UIColor?, for state: UIControl.State) {
        self.__fw_setBackgroundColor(backgroundColor, for: state)
    }
    
    /// 快速创建文本按钮
    public static func fw_button(title: String?, font: UIFont?, titleColor: UIColor?) -> Self {
        return Self.__fw_button(withTitle: title, font: font, titleColor: titleColor)
    }

    /// 快速创建图片按钮
    public static func fw_button(image: UIImage?) -> Self {
        return Self.__fw_button(with: image)
    }
    
    /// 设置按钮倒计时，从window移除时自动取消。等待时按钮disabled，非等待时enabled。时间支持格式化，示例：重新获取(%lds)
    @discardableResult
    public func fw_startCountDown(_ seconds: Int, title: String, waitTitle: String) -> DispatchSource {
        return self.__fw_startCountDown(seconds, title: title, waitTitle: waitTitle)
    }
    
}

// MARK: - UIScrollView+UIKit
@_spi(FW) @objc extension UIScrollView {
    
    /// 判断当前scrollView内容是否足够滚动
    public var fw_canScroll: Bool {
        return self.__fw_canScroll
    }

    /// 判断当前的scrollView内容是否足够水平滚动
    public var fw_canScrollHorizontal: Bool {
        return self.__fw_canScrollHorizontal
    }

    /// 判断当前的scrollView内容是否足够纵向滚动
    public var fw_canScrollVertical: Bool {
        return self.__fw_canScrollVertical
    }

    /// 当前scrollView滚动到指定边
    public func fw_scroll(to edge: UIRectEdge, animated: Bool = true) {
        self.__fw_scroll(to: edge, animated: animated)
    }

    /// 是否已滚动到指定边
    public func fw_isScroll(to edge: UIRectEdge) -> Bool {
        return self.__fw_isScroll(to: edge)
    }

    /// 获取当前的scrollView滚动到指定边时的contentOffset(包含contentInset)
    public func fw_contentOffset(of edge: UIRectEdge) -> CGPoint {
        return self.__fw_contentOffset(of: edge)
    }

    /// 总页数，自动识别翻页方向
    public var fw_totalPage: Int {
        return self.__fw_totalPage
    }

    /// 当前页数，不支持动画，自动识别翻页方向
    public var fw_currentPage: Int {
        get { return self.__fw_currentPage }
        set { self.__fw_currentPage = newValue }
    }

    /// 设置当前页数，支持动画，自动识别翻页方向
    public func fw_setCurrentPage(_ page: Int, animated: Bool = true) {
        self.__fw_setCurrentPage(page, animated: animated)
    }

    /// 是否是最后一页，自动识别翻页方向
    public var fw_isLastPage: Bool {
        return self.__fw_isLastPage
    }
    
    /// 快捷设置contentOffset.x
    public var fw_contentOffsetX: CGFloat {
        get { return self.__fw_contentOffsetX }
        set { self.__fw_contentOffsetX = newValue }
    }

    /// 快捷设置contentOffset.y
    public var fw_contentOffsetY: CGFloat {
        get { return self.__fw_contentOffsetY }
        set { self.__fw_contentOffsetY = newValue }
    }
    
    /// 内容视图，子视图需添加到本视图，布局约束完整时可自动滚动
    public var fw_contentView: UIView {
        return self.__fw_contentView
    }
    
    /**
     设置自动布局视图悬停到指定父视图固定位置，在scrollViewDidScroll:中调用即可
     
     @param view 需要悬停的视图，须占满fromSuperview
     @param fromSuperview 起始的父视图，须是scrollView的子视图
     @param toSuperview 悬停的目标视图，须是scrollView的父级视图，一般控制器self.view
     @param toPosition 需要悬停的目标位置，相对于toSuperview的originY位置
     @return 相对于悬浮位置的距离，可用来设置导航栏透明度等
     */
    @discardableResult
    public func fw_hoverView(_ view: UIView, fromSuperview: UIView, toSuperview: UIView, toPosition: CGFloat) -> CGFloat {
        return self.__fw_hover(view, fromSuperview: fromSuperview, toSuperview: toSuperview, toPosition: toPosition)
    }
    
    /// 是否开始识别pan手势
    public var fw_shouldBegin: ((UIGestureRecognizer) -> Bool)? {
        get { return self.__fw_shouldBegin }
        set { self.__fw_shouldBegin = newValue }
    }

    /// 是否允许同时识别多个手势
    public var fw_shouldRecognizeSimultaneously: ((UIGestureRecognizer, UIGestureRecognizer) -> Bool)? {
        get { return self.__fw_shouldRecognizeSimultaneously }
        set { self.__fw_shouldRecognizeSimultaneously = newValue }
    }

    /// 是否另一个手势识别失败后，才能识别pan手势
    public var fw_shouldRequireFailure: ((UIGestureRecognizer, UIGestureRecognizer) -> Bool)? {
        get { return self.__fw_shouldRequireFailure }
        set { self.__fw_shouldRequireFailure = newValue }
    }

    /// 是否pan手势识别失败后，才能识别另一个手势
    public var fw_shouldBeRequiredToFail: ((UIGestureRecognizer, UIGestureRecognizer) -> Bool)? {
        get { return self.__fw_shouldBeRequiredToFail }
        set { self.__fw_shouldBeRequiredToFail = newValue }
    }
    
}

// MARK: - UIGestureRecognizer+UIKit
/// gestureRecognizerShouldBegin：是否继续进行手势识别，默认YES
/// shouldRecognizeSimultaneouslyWithGestureRecognizer: 是否支持多手势触发。默认NO
/// shouldRequireFailureOfGestureRecognizer：是否otherGestureRecognizer触发失败时，才开始触发gestureRecognizer。返回YES，第一个手势失败
/// shouldBeRequiredToFailByGestureRecognizer：在otherGestureRecognizer识别其手势之前，是否gestureRecognizer必须触发失败。返回YES，第二个手势失败
@_spi(FW) @objc extension UIGestureRecognizer {
    
    /// 获取手势直接作用的view，不同于view，此处是view的subview
    public weak var fw_targetView: UIView? {
        let location = self.location(in: self.view)
        let targetView = self.view?.hitTest(location, with: nil)
        return targetView
    }

    /// 是否正在拖动中：Began || Changed
    public var fw_isTracking: Bool {
        return state == .began || state == .changed
    }

    /// 是否是激活状态: isEnabled && (Began || Changed)
    public var fw_isActive: Bool {
        return isEnabled && (state == .began || state == .changed)
    }
    
}

// MARK: - UIPanGestureRecognizer+UIKit
@_spi(FW) @objc extension UIPanGestureRecognizer {
    
    /// 当前滑动方向，如果多个方向滑动，取绝对值较大的一方，失败返回0
    public var fw_swipeDirection: UISwipeGestureRecognizer.Direction {
        let transition = self.translation(in: self.view)
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
    public var fw_swipePercent: CGFloat {
        guard let view = self.view,
              view.bounds.width > 0, view.bounds.height > 0 else { return 0 }
        var percent: CGFloat = 0
        let transition = self.translation(in: view)
        if abs(transition.x) > abs(transition.y) {
            percent = abs(transition.x) / view.bounds.width
        } else {
            percent = abs(transition.y) / view.bounds.height
        }
        return max(0, min(percent, 1))
    }

    /// 计算指定方向的滑动进度
    public func fw_swipePercent(of direction: UISwipeGestureRecognizer.Direction) -> CGFloat {
        guard let view = self.view,
              view.bounds.width > 0, view.bounds.height > 0 else { return 0 }
        var percent: CGFloat = 0
        let transition = self.translation(in: view)
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

// MARK: - UIPageControl+UIKit
@_spi(FW) @objc extension UIPageControl {
    
    /// 自定义圆点大小，默认{10, 10}
    public var fw_preferredSize: CGSize {
        get {
            var size = self.bounds.size
            if size.height <= 0 {
                size = self.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
                if size.height <= 0 { size = CGSize(width: 10, height: 10) }
            }
            return size
        }
        set {
            let height = self.fw_preferredSize.height
            let scale = newValue.height / height
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }
    
}

// MARK: - UISlider+UIKit
@_spi(FW) @objc extension UISlider {
    
    /// 中间圆球的大小，默认zero
    public var fw_thumbSize: CGSize {
        get {
            if let value = fw_property(forName: "fw_thumbSize") as? NSValue {
                return value.cgSizeValue
            }
            return .zero
        }
        set {
            fw_setProperty(NSValue(cgSize: newValue), forName: "fw_thumbSize")
            fw_updateThumbImage()
        }
    }

    /// 中间圆球的颜色，默认nil
    public var fw_thumbColor: UIColor? {
        get {
            return fw_property(forName: "fw_thumbColor") as? UIColor
        }
        set {
            fw_setProperty(newValue, forName: "fw_thumbColor")
            self.fw_updateThumbImage()
        }
    }
    
    private func fw_updateThumbImage() {
        let thumbSize = self.fw_thumbSize
        guard thumbSize.width > 0, thumbSize.height > 0 else { return }
        let thumbColor = self.fw_thumbColor ?? (self.tintColor ?? .white)
        let thumbImage = UIImage.fw_image(size: thumbSize) { context in
            let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: thumbSize.width, height: thumbSize.height))
            context.setFillColor(thumbColor.cgColor)
            path.fill()
        }
        
        self.setThumbImage(thumbImage, for: .normal)
        self.setThumbImage(thumbImage, for: .highlighted)
    }
    
}

// MARK: - UISwitch+UIKit
@_spi(FW) @objc extension UISwitch {
    
    /// 自定义尺寸大小，默认{51,31}
    public var fw_preferredSize: CGSize {
        get {
            var size = self.bounds.size
            if size.height <= 0 {
                size = self.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
                if size.height <= 0 { size = CGSize(width: 51, height: 31) }
            }
            return size
        }
        set {
            let height = self.fw_preferredSize.height
            let scale = newValue.height / height
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }
    
}

// MARK: - UITextField+UIKit
@_spi(FW) @objc extension UITextField {
    
    /// 最大字数限制，0为无限制，二选一
    public var fw_maxLength: Int {
        get { return self.__fw_maxLength }
        set { self.__fw_maxLength = newValue }
    }

    /// 最大Unicode字数限制(中文为1，英文为0.5)，0为无限制，二选一
    public var fw_maxUnicodeLength: Int {
        get { return self.__fw_maxUnicodeLength }
        set { self.__fw_maxUnicodeLength = newValue }
    }
    
    /// 自定义文字改变处理句柄，自动trimString，默认nil
    public var fw_textChangedBlock: ((String) -> Void)? {
        get { return self.__fw_textChangedBlock }
        set { self.__fw_textChangedBlock = newValue }
    }

    /// 文本长度发生改变，自动检测字数限制，用于代码设置text等场景
    public func fw_textLengthChanged() {
        self.__fw_textLengthChanged()
    }

    /// 获取满足最大字数限制的过滤后的文本，无需再调用textLengthChanged
    public func fw_filterText(_ text: String) -> String {
        return self.__fw_filterText(text)
    }

    /// 设置自动完成时间间隔，默认0.5秒，和autoCompleteBlock配套使用
    public var fw_autoCompleteInterval: TimeInterval {
        get { return self.__fw_autoCompleteInterval }
        set { self.__fw_autoCompleteInterval = newValue }
    }

    /// 设置自动完成处理句柄，自动trimString，默认nil，注意输入框内容为空时会立即触发
    public var fw_autoCompleteBlock: ((String) -> Void)? {
        get { return self.__fw_autoCompleteBlock }
        set { self.__fw_autoCompleteBlock = newValue }
    }
    
    /// 是否禁用长按菜单(拷贝、选择、粘贴等)，默认NO
    public var fw_menuDisabled: Bool {
        get { return self.__fw_menuDisabled }
        set { self.__fw_menuDisabled = newValue }
    }

    /// 自定义光标大小，不为0才会生效，默认zero不生效
    public var fw_cursorRect: CGRect {
        get { return self.__fw_cursorRect }
        set { self.__fw_cursorRect = newValue }
    }

    /// 获取及设置当前选中文字范围
    public var fw_selectedRange: NSRange {
        get { return self.__fw_selectedRange }
        set { self.__fw_selectedRange = newValue }
    }

    /// 移动光标到最后
    public func fw_selectAllRange() {
        self.__fw_selectAllRange()
    }

    /// 移动光标到指定位置，兼容动态text赋值
    public func fw_moveCursor(_ offset: Int) {
        self.__fw_moveCursor(offset)
    }
    
}

// MARK: - UITextView+UIKit
@_spi(FW) @objc extension UITextView {
    
    /// 最大字数限制，0为无限制，二选一
    public var fw_maxLength: Int {
        get { return self.__fw_maxLength }
        set { self.__fw_maxLength = newValue }
    }

    /// 最大Unicode字数限制(中文为1，英文为0.5)，0为无限制，二选一
    public var fw_maxUnicodeLength: Int {
        get { return self.__fw_maxUnicodeLength }
        set { self.__fw_maxUnicodeLength = newValue }
    }
    
    /// 自定义文字改变处理句柄，自动trimString，默认nil
    public var fw_textChangedBlock: ((String) -> Void)? {
        get { return self.__fw_textChangedBlock }
        set { self.__fw_textChangedBlock = newValue }
    }

    /// 文本长度发生改变，自动检测字数限制，用于代码设置text等场景
    public func fw_textLengthChanged() {
        self.__fw_textLengthChanged()
    }

    /// 获取满足最大字数限制的过滤后的文本，无需再调用textLengthChanged
    public func fw_filterText(_ text: String) -> String {
        return self.__fw_filterText(text)
    }

    /// 设置自动完成时间间隔，默认0.5秒，和autoCompleteBlock配套使用
    public var fw_autoCompleteInterval: TimeInterval {
        get { return self.__fw_autoCompleteInterval }
        set { self.__fw_autoCompleteInterval = newValue }
    }

    /// 设置自动完成处理句柄，默认nil，注意输入框内容为空时会立即触发
    public var fw_autoCompleteBlock: ((String) -> Void)? {
        get { return self.__fw_autoCompleteBlock }
        set { self.__fw_autoCompleteBlock = newValue }
    }
    
    /// 是否禁用长按菜单(拷贝、选择、粘贴等)，默认NO
    public var fw_menuDisabled: Bool {
        get { return self.__fw_menuDisabled }
        set { self.__fw_menuDisabled = newValue }
    }

    /// 自定义光标大小，不为0才会生效，默认zero不生效
    public var fw_cursorRect: CGRect {
        get { return self.__fw_cursorRect }
        set { self.__fw_cursorRect = newValue }
    }

    /// 获取及设置当前选中文字范围
    public var fw_selectedRange: NSRange {
        get { return self.__fw_selectedRange }
        set { self.__fw_selectedRange = newValue }
    }

    /// 移动光标到最后
    public func fw_selectAllRange() {
        self.__fw_selectAllRange()
    }

    /// 移动光标到指定位置，兼容动态text赋值
    public func fw_moveCursor(_ offset: Int) {
        self.__fw_moveCursor(offset)
    }

    /// 计算当前文本所占尺寸，包含textContainerInset，需frame或者宽度布局完整
    public var fw_textSize: CGSize {
        return self.__fw_textSize
    }

    /// 计算当前属性文本所占尺寸，包含textContainerInset，需frame或者宽度布局完整，attributedText需指定字体
    public var fw_attributedTextSize: CGSize {
        return self.__fw_attributedTextSize
    }
    
}

// MARK: - UITableView+UIKit
@_spi(FW) @objc extension UITableView {
    
    /// 全局清空TableView默认多余边距
    public static func fw_resetTableStyle() {
        if #available(iOS 15.0, *) {
            UITableView.appearance().sectionHeaderTopPadding = 0
        }
    }
    
    /// 是否启动高度估算布局，启用后需要子视图布局完整，无需实现heightForRow方法(iOS11默认启用，会先cellForRow再heightForRow)
    public var fw_estimatedLayout: Bool {
        get {
            return self.estimatedRowHeight == UITableView.automaticDimension
        }
        set {
            if newValue {
                self.estimatedRowHeight = UITableView.automaticDimension
                self.estimatedSectionHeaderHeight = UITableView.automaticDimension
                self.estimatedSectionFooterHeight = UITableView.automaticDimension
            } else {
                self.estimatedRowHeight = 0
                self.estimatedSectionHeaderHeight = 0
                self.estimatedSectionFooterHeight = 0
            }
        }
    }
    
    /// 清空Grouped样式默认多余边距，注意CGFLOAT_MIN才会生效，0不会生效
    public func fw_resetGroupedStyle() {
        self.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNonzeroMagnitude))
        self.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNonzeroMagnitude))
        self.sectionHeaderHeight = 0
        self.sectionFooterHeight = 0
        if #available(iOS 15.0, *) {
            self.sectionHeaderTopPadding = 0
        }
    }
    
    /// reloadData完成回调
    public func fw_reloadData(completion: (() -> Void)?) {
        UIView.animate(withDuration: 0) {
            self.reloadData()
        } completion: { _ in
            completion?()
        }
    }
    
    /// reloadData禁用动画
    public func fw_reloadDataWithoutAnimation() {
        UIView.performWithoutAnimation {
            self.reloadData()
        }
    }
    
}

// MARK: - UITableViewCell+UIKit
@_spi(FW) @objc extension UITableViewCell {
    
    /// 设置分割线内边距，iOS8+默认15.f，设为UIEdgeInsetsZero可去掉
    public var fw_separatorInset: UIEdgeInsets {
        get {
            return self.separatorInset
        }
        set {
            self.separatorInset = newValue
            self.preservesSuperviewLayoutMargins = false
            self.layoutMargins = separatorInset
        }
    }

    /// 获取当前所属tableView
    public weak var fw_tableView: UITableView? {
        var superview = self.superview
        while superview != nil {
            if let tableView = superview as? UITableView {
                return tableView
            }
            superview = superview?.superview
        }
        return nil
    }

    /// 获取当前显示indexPath
    public var fw_indexPath: IndexPath? {
        return fw_tableView?.indexPath(for: self)
    }
    
}

// MARK: - UICollectionView+UIKit
@_spi(FW) @objc extension UICollectionView {
    
    /// reloadData完成回调
    public func fw_reloadData(completion: (() -> Void)?) {
        UIView.animate(withDuration: 0) {
            self.reloadData()
        } completion: { _ in
            completion?()
        }
    }
    
    /// reloadData禁用动画
    public func fw_reloadDataWithoutAnimation() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.reloadData()
        CATransaction.commit()
    }
    
}

// MARK: - UICollectionViewCell+UIKit
@_spi(FW) @objc extension UICollectionViewCell {
    
    /// 获取当前所属collectionView
    public weak var fw_collectionView: UICollectionView? {
        var superview = self.superview
        while superview != nil {
            if let collectionView = superview as? UICollectionView {
                return collectionView
            }
            superview = superview?.superview
        }
        return nil
    }

    /// 获取当前显示indexPath
    public var fw_indexPath: IndexPath? {
        return fw_collectionView?.indexPath(for: self)
    }
    
}

// MARK: - UISearchBar+UIKit
@_spi(FW) @objc extension UISearchBar {
    
    /// 自定义内容边距，可调整左右距离和TextField高度，未设置时为系统默认
    public var fw_contentInset: UIEdgeInsets {
        get { return self.__fw_contentInset }
        set { self.__fw_contentInset = newValue }
    }

    /// 自定义取消按钮边距，未设置时为系统默认
    public var fw_cancelButtonInset: UIEdgeInsets {
        get { return self.__fw_cancelButtonInset }
        set { self.__fw_cancelButtonInset = newValue }
    }

    /// 输入框内部视图
    public weak var fw_textField: UITextField? {
        return self.__fw_textField
    }

    /// 取消按钮内部视图，showsCancelButton开启后才存在
    public weak var fw_cancelButton: UIButton? {
        return self.__fw_cancelButton
    }

    /// 设置整体背景色
    public var fw_backgroundColor: UIColor? {
        get { return self.__fw_backgroundColor }
        set { self.__fw_backgroundColor = newValue }
    }

    /// 设置输入框背景色
    public var fw_textFieldBackgroundColor: UIColor? {
        get { return self.__fw_textFieldBackgroundColor }
        set { self.__fw_textFieldBackgroundColor = newValue }
    }

    /// 设置搜索图标离左侧的偏移位置，非居中时生效
    public var fw_searchIconOffset: CGFloat {
        get { return self.__fw_searchIconOffset }
        set { self.__fw_searchIconOffset = newValue }
    }

    /// 设置搜索文本离左侧图标的偏移位置
    public var fw_searchTextOffset: CGFloat {
        get { return self.__fw_searchTextOffset }
        set { self.__fw_searchTextOffset = newValue }
    }

    /// 设置TextField搜索图标(placeholder)是否居中，否则居左
    public var fw_searchIconCenter: Bool {
        get { return self.__fw_searchIconCenter }
        set { self.__fw_searchIconCenter = newValue }
    }

    /// 强制取消按钮一直可点击，需在showsCancelButton设置之后生效。默认SearchBar失去焦点之后取消按钮不可点击
    public var fw_forceCancelButtonEnabled: Bool {
        get { return self.__fw_forceCancelButtonEnabled }
        set { self.__fw_forceCancelButtonEnabled = newValue }
    }
    
}

// MARK: - UIViewController+UIKit
@_spi(FW) @objc extension UIViewController {
    
    /// 判断当前控制器是否是根控制器。如果是导航栏的第一个控制器或者不含有导航栏，则返回YES
    public var fw_isRoot: Bool {
        return self.navigationController == nil ||
            self.navigationController?.viewControllers.first == self
    }

    /// 判断当前控制器是否是子控制器。如果父控制器存在，且不是导航栏或标签栏控制器，则返回YES
    public var fw_isChild: Bool {
        if let parent = self.parent,
           !(parent is UINavigationController),
           !(parent is UITabBarController) {
            return true
        }
        return false
    }

    /// 判断当前控制器是否是present弹出。如果是导航栏的第一个控制器且导航栏是present弹出，也返回YES
    public var fw_isPresented: Bool {
        var viewController: UIViewController = self
        if let navigationController = self.navigationController {
            if navigationController.viewControllers.first != self { return false }
            viewController = navigationController
        }
        return viewController.presentingViewController?.presentedViewController == viewController
    }

    /// 判断当前控制器是否是iOS13+默认pageSheet弹出样式。该样式下导航栏高度等与默认样式不同
    public var fw_isPageSheet: Bool {
        if #available(iOS 13.0, *) {
            let controller: UIViewController = self.navigationController ?? self
            if controller.presentingViewController == nil { return false }
            let style = controller.modalPresentationStyle
            if style == .automatic || style == .pageSheet { return true }
        }
        return false
    }

    /// 视图是否可见，viewWillAppear后为YES，viewDidDisappear后为NO
    public var fw_isViewVisible: Bool {
        return self.isViewLoaded && self.view.window != nil
    }
    
    /// 获取祖先视图，标签栏存在时为标签栏根视图，导航栏存在时为导航栏根视图，否则为控制器根视图
    public var fw_ancestorView: UIView {
        if let navigationController = self.tabBarController?.navigationController {
            return navigationController.view
        } else if let tabBarController = self.tabBarController {
            return tabBarController.view
        } else if let navigationController = self.navigationController {
            return navigationController.view
        } else {
            return self.view
        }
    }

    /// 是否已经加载完，默认NO，加载完成后可标记为YES，可用于第一次加载时显示loading等判断
    public var fw_isLoaded: Bool {
        get { return fw_propertyBool(forName: "fw_isLoaded") }
        set { fw_setPropertyBool(newValue, forName: "fw_isLoaded") }
    }
    
    /// 移除子控制器，解决不能触发viewWillAppear等的bug
    public func fw_removeChildViewController(_ viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.removeFromParent()
        viewController.view.removeFromSuperview()
    }
    
    /// 添加子控制器到当前视图，解决不能触发viewWillAppear等的bug
    public func fw_addChildViewController(_ viewController: UIViewController, layout: ((UIView) -> Void)? = nil) {
        fw_addChildViewController(viewController, in: nil, layout: layout)
    }

    /// 添加子控制器到指定视图，解决不能触发viewWillAppear等的bug
    public func fw_addChildViewController(_ viewController: UIViewController, in view: UIView?, layout: ((UIView) -> Void)? = nil) {
        self.addChild(viewController)
        let superview: UIView = view ?? self.view
        superview.addSubview(viewController.view)
        if layout != nil {
            layout?(viewController.view)
        } else {
            viewController.view.fw_pinEdges()
        }
        viewController.didMove(toParent: self)
    }
    
}

// MARK: - UIKitAutoloader
internal class UIKitAutoloader: AutoloadProtocol {
    
    static func autoload() {
        UILabel.fw_exchangeInstanceMethod(#selector(setter: UILabel.text), swizzleMethod: #selector(UILabel.fw_innerSetText(_:)))
        UILabel.fw_exchangeInstanceMethod(#selector(setter: UILabel.attributedText), swizzleMethod: #selector(UILabel.fw_innerSetAttributedText(_:)))
        UILabel.fw_exchangeInstanceMethod(#selector(setter: UILabel.lineBreakMode), swizzleMethod: #selector(UILabel.fw_innerSetLineBreakMode(_:)))
        UILabel.fw_exchangeInstanceMethod(#selector(setter: UILabel.textAlignment), swizzleMethod: #selector(UILabel.fw_innerSetTextAlignment(_:)))
    }
    
}
