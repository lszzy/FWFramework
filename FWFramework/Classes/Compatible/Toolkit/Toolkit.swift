//
//  Toolkit.swift
//  FWFramework
//
//  Created by wuyong on 2020/10/22.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import UIKit
#if FWMacroSPM
import FWFramework
#endif

// MARK: - FW+Toolkit
extension FW {
    /// 从16进制创建UIColor
    ///
    /// - Parameters:
    ///   - hex: 十六进制值，格式0xFFFFFF
    ///   - alpha: 透明度可选，默认1.0
    /// - Returns: UIColor
    public static func color(_ hex: Int, _ alpha: CGFloat = 1.0) -> UIColor {
        return UIColor(red: CGFloat((hex & 0xFF0000) >> 16) / 255.0, green: CGFloat((hex & 0xFF00) >> 8) / 255.0, blue: CGFloat(hex & 0xFF) / 255.0, alpha: alpha)
    }

    /// 从RGB创建UIColor
    ///
    /// - Parameters:
    ///   - red: 红色值
    ///   - green: 绿色值
    ///   - blue: 蓝色值
    ///   - alpha: 透明度可选，默认1.0
    /// - Returns: UIColor
    public static func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1.0) -> UIColor {
        return UIColor(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: alpha)
    }

    /// 快速创建系统字体
    ///
    /// - Parameters:
    ///   - size: 字体字号
    ///   - weight: 字重可选，默认Regular
    /// - Returns: UIFont
    public static func font(_ size: CGFloat, _ weight: UIFont.Weight = .regular) -> UIFont {
        return UIFont.__fw.font(ofSize: size, weight: weight)
    }
    
    /// 快速创建图标对象
    ///
    /// - Parameters:
    ///   - named: 图标名称
    ///   - size: 图标大小
    /// - Returns: FWIcon对象
    public static func icon(_ named: String, _ size: CGFloat) -> Icon? {
        return Icon(named: named, size: size)
    }
    
    /// 快速创建图标图像
    /// 
    /// - Parameters:
    ///   - name: 图标名称
    ///   - size: 图片大小
    /// - Returns: UIImage对象
    public static func iconImage(_ name: String, _ size: CGFloat) -> UIImage? {
        return Icon.iconImage(name, size: size)
    }
}

// MARK: - UIApplication+Toolkit
/// 注意Info.plist文件URL SCHEME配置项只影响canOpenUrl方法，不影响openUrl。微信返回app就是获取sourceUrl，直接openUrl实现。因为跳转微信的时候，来源app肯定已打开过，可以跳转，只要不检查canOpenUrl，就可以跳转回app
extension Wrapper where Base: UIApplication {
    
    /// 能否打开URL(NSString|NSURL)，需配置对应URL SCHEME到Info.plist才能返回YES
    public static func canOpenURL(_ url: Any) -> Bool {
        return Base.__fw.canOpenURL(url)
    }

    /// 打开URL，支持NSString|NSURL，完成时回调，即使未配置URL SCHEME，实际也能打开成功，只要调用时已打开过对应App
    public static func openURL(_ url: Any, completionHandler: ((Bool) -> Void)? = nil) {
        Base.__fw.openURL(url, completionHandler: completionHandler)
    }

    /// 打开通用链接URL，支持NSString|NSURL，完成时回调。如果是iOS10+通用链接且安装了App，打开并回调YES，否则回调NO
    public static func openUniversalLinks(_ url: Any, completionHandler: ((Bool) -> Void)? = nil) {
        Base.__fw.openUniversalLinks(url, completionHandler: completionHandler)
    }

    /// 判断URL是否是系统链接(如AppStore|电话|设置等)，支持NSString|NSURL
    public static func isSystemURL(_ url: Any) -> Bool {
        return Base.__fw.isSystemURL(url)
    }

    /// 判断URL是否HTTP链接，支持NSString|NSURL
    public static func isHttpURL(_ url: Any) -> Bool {
        return Base.__fw.isHttpURL(url)
    }

    /// 判断URL是否是AppStore链接，支持NSString|NSURL
    public static func isAppStoreURL(_ url: Any) -> Bool {
        return Base.__fw.isAppStoreURL(url)
    }

    /// 打开AppStore下载页
    public static func openAppStore(_ appId: String) {
        Base.__fw.openAppStore(appId)
    }

    /// 打开AppStore评价页
    public static func openAppStoreReview(_ appId: String) {
        Base.__fw.openAppStore(appId)
    }

    /// 打开应用内评价，有次数限制
    public static func openAppReview() {
        Base.__fw.openAppReview()
    }

    /// 打开系统应用设置页
    public static func openAppSettings() {
        Base.__fw.openAppSettings()
    }

    /// 打开系统邮件App
    public static func openMailApp(_ email: String) {
        Base.__fw.openMailApp(email)
    }

    /// 打开系统短信App
    public static func openMessageApp(_ phone: String) {
        Base.__fw.openMessageApp(phone)
    }

    /// 打开系统电话App
    public static func openPhoneApp(_ phone: String) {
        Base.__fw.openPhoneApp(phone)
    }

    /// 打开系统分享
    public static func openActivityItems(_ activityItems: [Any], excludedTypes: [UIActivity.ActivityType]? = nil) {
        Base.__fw.openActivityItems(activityItems, excludedTypes: excludedTypes)
    }

    /// 打开内部浏览器，支持NSString|NSURL，点击完成时回调
    public static func openSafariController(_ url: Any, completionHandler: (() -> Void)? = nil) {
        Base.__fw.openSafariController(url, completionHandler: completionHandler)
    }

    /// 打开短信控制器，完成时回调
    public static func openMessageController(_ controller: MFMessageComposeViewController, completionHandler: ((Bool) -> Void)? = nil) {
        Base.__fw.openMessageController(controller, completionHandler: completionHandler)
    }

    /// 打开邮件控制器，完成时回调
    public static func openMailController(_ controller: MFMailComposeViewController, completionHandler: ((Bool) -> Void)? = nil) {
        Base.__fw.openMailController(controller, completionHandler: completionHandler)
    }

    /// 打开Store控制器，完成时回调
    public static func openStoreController(_ parameters: [String: Any], completionHandler: ((Bool) -> Void)? = nil) {
        Base.__fw.openStoreController(parameters, completionHandler: completionHandler)
    }

    /// 打开视频播放器，支持AVPlayerItem|NSURL|NSString
    public static func openVideoPlayer(_ url: Any) -> AVPlayerViewController? {
        return Base.__fw.openVideoPlayer(url)
    }

    /// 打开音频播放器，支持NSURL|NSString
    public static func openAudioPlayer(_ url: Any) -> AVAudioPlayer? {
        return Base.__fw.openAudioPlayer(url)
    }
    
}

// MARK: - UIColor+Toolkit
extension Wrapper where Base: UIColor {
    
    /// 获取当前颜色指定透明度的新颜色
    public func color(alpha: CGFloat) -> UIColor {
        return base.__fw.color(withAlpha: alpha)
    }

    /// 读取颜色的十六进制值RGB，不含透明度
    public var hexValue: Int {
        return base.__fw.hexValue
    }

    /// 读取颜色的透明度值，范围0~1
    public var alphaValue: CGFloat {
        return base.__fw.alphaValue
    }

    /// 读取颜色的十六进制字符串RGB，不含透明度
    public var hexString: String {
        return base.__fw.hexString
    }

    /// 读取颜色的十六进制字符串RGBA|ARGB(透明度为1时RGB)，包含透明度
    public var hexAlphaString: String {
        return base.__fw.hexAlphaString
    }
    
    /// 设置十六进制颜色标准为ARGB|RGBA，启用为ARGB，默认为RGBA
    public static var colorStandardARGB: Bool {
        get { return Base.__fw.colorStandardARGB }
        set { Base.__fw.colorStandardARGB = newValue }
    }

    /// 获取透明度为1.0的RGB随机颜色
    public static var randomColor: UIColor {
        return Base.__fw.randomColor
    }

    /// 从十六进制值初始化，格式：0x20B2AA，透明度默认1.0
    public static func color(hex: Int, alpha: CGFloat = 1.0) -> UIColor {
        return Base.__fw.color(withHex: hex, alpha: alpha)
    }

    /// 从十六进制字符串初始化，支持RGB、RGBA|ARGB，格式：@"20B2AA", @"#FFFFFF"，透明度默认1.0，失败时返回clear
    public static func color(hexString: String, alpha: CGFloat = 1.0) -> UIColor {
        return Base.__fw.color(withHexString: hexString, alpha: alpha)
    }

    /// 从颜色字符串初始化，支持十六进制和颜色值，透明度默认1.0，失败时返回clear
    public static func color(string: String, alpha: CGFloat = 1.0) -> UIColor {
        return Base.__fw.color(with: string, alpha: alpha)
    }
    
}

// MARK: - UIFont+Toolkit
extension Wrapper where Base: UIFont {
    
    /// 全局自定义字体句柄，优先调用
    public static var fontBlock: ((CGFloat, UIFont.Weight) -> UIFont)? {
        get { return Base.__fw.fontBlock }
        set { Base.__fw.fontBlock = newValue }
    }
    
    /// 是否自动等比例缩放字体，默认NO
    public static var autoScale: Bool {
        get { return Base.__fw.autoScale }
        set { Base.__fw.autoScale = newValue }
    }

    /// 返回系统Thin字体
    public static func thinFont(ofSize: CGFloat) -> UIFont {
        return Base.__fw.thinFont(ofSize: ofSize)
    }
    /// 返回系统Light字体
    public static func lightFont(ofSize: CGFloat) -> UIFont {
        return Base.__fw.lightFont(ofSize: ofSize)
    }
    /// 返回系统Regular字体
    public static func font(ofSize: CGFloat) -> UIFont {
        return Base.__fw.font(ofSize: ofSize)
    }
    /// 返回系统Medium字体
    public static func mediumFont(ofSize: CGFloat) -> UIFont {
        return Base.__fw.mediumFont(ofSize: ofSize)
    }
    /// 返回系统Semibold字体
    public static func semiboldFont(ofSize: CGFloat) -> UIFont {
        return Base.__fw.semiboldFont(ofSize: ofSize)
    }
    /// 返回系统Bold字体
    public static func boldFont(ofSize: CGFloat) -> UIFont {
        return Base.__fw.boldFont(ofSize: ofSize)
    }

    /// 创建指定尺寸和weight的系统字体
    public static func font(ofSize: CGFloat, weight: UIFont.Weight) -> UIFont {
        return Base.__fw.font(ofSize: ofSize, weight: weight)
    }
    
}

// MARK: - UIImage+Toolkit
extension Wrapper where Base: UIImage {
    
    /// 从当前图片创建指定透明度的图片
    public func image(alpha: CGFloat) -> UIImage? {
        return base.__fw.image(withAlpha: alpha)
    }

    /// 从当前UIImage混合颜色创建UIImage，可自定义模式，默认destinationIn
    public func image(tintColor: UIColor, blendMode: CGBlendMode = .destinationIn) -> UIImage? {
        return base.__fw.image(withTintColor: tintColor, blendMode: blendMode)
    }

    /// 缩放图片到指定大小
    public func image(scaleSize: CGSize) -> UIImage? {
        return base.__fw.image(withScale: scaleSize)
    }

    /// 缩放图片到指定大小，指定模式
    public func image(scaleSize: CGSize, contentMode: UIView.ContentMode) -> UIImage? {
        return base.__fw.image(withScale: scaleSize, contentMode: contentMode)
    }

    /// 按指定模式绘制图片
    public func draw(in rect: CGRect, contentMode: UIView.ContentMode, clipsToBounds: Bool) {
        base.__fw.draw(in: rect, with: contentMode, clipsToBounds: clipsToBounds)
    }

    /// 裁剪指定区域图片
    public func image(cropRect: CGRect) -> UIImage? {
        return base.__fw.image(withCropRect: cropRect)
    }

    /// 指定颜色填充图片边缘
    public func image(insets: UIEdgeInsets, color: UIColor?) -> UIImage? {
        return base.__fw.image(with: insets, color: color)
    }

    /// 拉伸图片(平铺模式)，指定端盖区域（不拉伸区域）
    public func image(capInsets: UIEdgeInsets) -> UIImage {
        return base.__fw.image(withCapInsets: capInsets)
    }

    /// 拉伸图片(指定模式)，指定端盖区域（不拉伸区域）。Tile为平铺模式，Stretch为拉伸模式
    public func image(capInsets: UIEdgeInsets, resizingMode: UIImage.ResizingMode) -> UIImage {
        return base.__fw.image(withCapInsets: capInsets, resizingMode: resizingMode)
    }

    /// 生成圆角图片
    public func image(cornerRadius: CGFloat) -> UIImage? {
        return base.__fw.image(withCornerRadius: cornerRadius)
    }

    /// 按角度常数(0~360)转动图片，指定图片尺寸是否延伸来适应内容，否则图片尺寸不变，内容被裁剪，默认true
    public func image(rotateDegree: CGFloat, fitSize: Bool = true) -> UIImage? {
        return base.__fw.image(withRotateDegree: rotateDegree, fitSize: fitSize)
    }

    /// 生成mark图片
    public func image(maskImage: UIImage) -> UIImage? {
        return base.__fw.image(withMaskImage: maskImage)
    }

    /// 图片合并，并制定叠加图片的起始位置
    public func image(mergeImage: UIImage, atPoint: CGPoint) -> UIImage? {
        return base.__fw.image(withMerge: mergeImage, at: atPoint)
    }

    /// 图片应用CIFilter滤镜处理
    public func image(filter: CIFilter) -> UIImage? {
        return base.__fw.image(with: filter)
    }

    /// 压缩图片到指定字节，图片太大时会改为JPG格式。不保证图片大小一定小于该大小
    public func compressImage(maxLength: Int) -> UIImage? {
        return base.__fw.compressImage(withMaxLength: maxLength)
    }

    /// 压缩图片到指定字节，图片太大时会改为JPG格式，可设置递减压缩率，默认0.1。不保证图片大小一定小于该大小
    public func compressData(maxLength: Int, compressRatio: CGFloat) -> Data? {
        return base.__fw.compressData(withMaxLength: maxLength, compressRatio: compressRatio)
    }

    /// 长边压缩图片尺寸，获取等比例的图片
    public func compressImage(maxWidth: Int) -> UIImage? {
        return base.__fw.compressImage(withMaxWidth: maxWidth)
    }

    /// 通过指定图片最长边，获取等比例的图片size
    public func scaleSize(maxWidth: CGFloat) -> CGSize {
        return base.__fw.scaleSize(withMaxWidth: maxWidth)
    }

    /// 获取原始渲染模式图片，始终显示原色，不显示tintColor。默认自动根据上下文
    public var originalImage: UIImage {
        return base.__fw.originalImage
    }

    /// 获取模板渲染模式图片，始终显示tintColor，不显示原色。默认自动根据上下文
    public var templateImage: UIImage {
        return base.__fw.templateImage
    }

    /// 判断图片是否有透明通道
    public var hasAlpha: Bool {
        return base.__fw.hasAlpha
    }

    /// 获取当前图片的像素大小，多倍图会放大到一倍
    public var pixelSize: CGSize {
        return base.__fw.pixelSize
    }
    
    /// 从视图创建UIImage，生成截图，主线程调用
    public static func image(view: UIView) -> UIImage? {
        return Base.__fw.image(with: view)
    }
    
    /// 从颜色创建UIImage，尺寸默认1x1
    public static func image(color: UIColor) -> UIImage? {
        return Base.__fw.image(with: color)
    }
    
    /// 从颜色创建UIImage，可指定尺寸和圆角，默认圆角0
    public static func image(color: UIColor, size: CGSize, cornerRadius: CGFloat = 0) -> UIImage? {
        return Base.__fw.image(with: color, size: size, cornerRadius: cornerRadius)
    }

    /// 从block创建UIImage，指定尺寸
    public static func image(size: CGSize, block: (CGContext) -> Void) -> UIImage? {
        return Base.__fw.image(with: size, block: block)
    }
    
}

// MARK: - UIView+Toolkit
extension Wrapper where Base: UIView {
    
    /// 顶部纵坐标，frame.origin.y
    public var top: CGFloat {
        get { return base.__fw.top }
        set { base.__fw.top = newValue }
    }

    /// 底部纵坐标，frame.origin.y + frame.size.height
    public var bottom: CGFloat {
        get { return base.__fw.bottom }
        set { base.__fw.bottom = newValue }
    }

    /// 左边横坐标，frame.origin.x
    public var left: CGFloat {
        get { return base.__fw.left }
        set { base.__fw.left = newValue }
    }

    /// 右边横坐标，frame.origin.x + frame.size.width
    public var right: CGFloat {
        get { return base.__fw.right }
        set { base.__fw.right = newValue }
    }

    /// 宽度，frame.size.width
    public var width: CGFloat {
        get { return base.__fw.width }
        set { base.__fw.width = newValue }
    }

    /// 高度，frame.size.height
    public var height: CGFloat {
        get { return base.__fw.height }
        set { base.__fw.height = newValue }
    }

    /// 中心横坐标，center.x
    public var centerX: CGFloat {
        get { return base.__fw.centerX }
        set { base.__fw.centerX = newValue }
    }

    /// 中心纵坐标，center.y
    public var centerY: CGFloat {
        get { return base.__fw.centerY }
        set { base.__fw.centerY = newValue }
    }

    /// 起始横坐标，frame.origin.x
    public var x: CGFloat {
        get { return base.__fw.x }
        set { base.__fw.x = newValue }
    }

    /// 起始纵坐标，frame.origin.y
    public var y: CGFloat {
        get { return base.__fw.y }
        set { base.__fw.y = newValue }
    }

    /// 起始坐标，frame.origin
    public var origin: CGPoint {
        get { return base.__fw.origin }
        set { base.__fw.origin = newValue }
    }

    /// 大小，frame.size
    public var size: CGSize {
        get { return base.__fw.size }
        set { base.__fw.size = newValue }
    }
    
}

// MARK: - UIViewController+Toolkit
extension Wrapper where Base: UIViewController {
    
    /// 当前生命周期状态，默认Ready
    public var visibleState: ViewControllerVisibleState {
        return base.__fw.visibleState
    }

    /// 生命周期变化时通知句柄，默认nil
    public var visibleStateChanged: ((UIViewController, ViewControllerVisibleState) -> Void)? {
        get { return base.__fw.visibleStateChanged }
        set { base.__fw.visibleStateChanged = newValue }
    }

    /// 自定义完成结果对象，默认nil
    public var completionResult: Any? {
        get { return base.__fw.completionResult }
        set { base.__fw.completionResult = newValue }
    }

    /// 自定义完成句柄，默认nil，dealloc时自动调用，参数为fwCompletionResult。支持提前调用，调用后需置为nil
    public var completionHandler: ((Any?) -> Void)? {
        get { return base.__fw.completionHandler }
        set { base.__fw.completionHandler = newValue }
    }

    /// 自定义侧滑返回手势VC开关句柄，enablePopProxy启用后生效，仅处理边缘返回手势，优先级低，默认nil
    public var allowsPopGesture: (() -> Bool)? {
        get { return base.__fw.allowsPopGesture }
        set { base.__fw.allowsPopGesture = newValue }
    }

    /// 自定义控制器返回VC开关句柄，enablePopProxy启用后生效，统一处理返回按钮点击和边缘返回手势，优先级高，默认nil
    public var shouldPopController: (() -> Bool)? {
        get { return base.__fw.shouldPopController }
        set { base.__fw.shouldPopController = newValue }
    }
    
}

// MARK: - UINavigationController+Toolkit
/// 当自定义left按钮或隐藏导航栏之后，系统返回手势默认失效，可调用此方法全局开启返回代理。开启后自动将开关代理给顶部VC的shouldPopController、popGestureEnabled属性控制。interactivePop手势禁用时不生效
extension Wrapper where Base: UINavigationController {
    
    /// 单独启用返回代理拦截，优先级高于+enablePopProxy，启用后支持shouldPopController、allowsPopGesture功能，默认NO未启用
    public func enablePopProxy() {
        base.__fw.enablePopProxy()
    }
    
    /// 全局启用返回代理拦截，优先级低于-enablePopProxy，启用后支持shouldPopController、allowsPopGesture功能，默认NO未启用
    public static func enablePopProxy() {
        Base.__fw.enablePopProxy()
    }
    
}
