//
//  Toolkit.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

// MARK: - FW+Toolkit
@objc extension FW {
    /// 从16进制创建UIColor
    ///
    /// - Parameters:
    ///   - hex: 十六进制值，格式0xFFFFFF
    ///   - alpha: 透明度可选，默认1.0
    /// - Returns: UIColor
    public static func color(_ hex: Int, _ alpha: CGFloat = 1.0) -> UIColor {
        return UIColor.fw_color(hex: hex, alpha: alpha)
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
        return UIFont.fw_font(ofSize: size, weight: weight)
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
@_spi(FW) @objc extension UIApplication {
    
    /// 读取应用名称
    public static var fw_appName: String {
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        return appName ?? ""
    }

    /// 读取应用显示名称，未配置时读取名称
    public static var fw_appDisplayName: String {
        let displayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        return displayName ?? fw_appName
    }

    /// 读取应用主版本号，示例：1.0.0
    public static var fw_appVersion: String {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return appVersion ?? ""
    }

    /// 读取应用构建版本号，示例：1.0.0.1
    public static var fw_appBuildVersion: String {
        let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        return buildVersion ?? ""
    }

    /// 读取应用唯一标识
    public static var fw_appIdentifier: String {
        let appIdentifier = Bundle.main.object(forInfoDictionaryKey: kCFBundleIdentifierKey as String) as? String
        return appIdentifier ?? ""
    }
    
    /// 读取应用可执行程序名称
    public static var fw_appExecutable: String {
        let appExecutable = Bundle.main.object(forInfoDictionaryKey: kCFBundleExecutableKey as String) as? String
        return appExecutable ?? fw_appIdentifier
    }
    
    /// 读取应用信息字典
    public static func fw_appInfo(_ key: String) -> Any? {
        return Bundle.main.object(forInfoDictionaryKey: key)
    }
    
    /// 读取应用启动URL
    public static func fw_appLaunchURL(_ options: [UIApplication.LaunchOptionsKey : Any]?) -> URL? {
        return Self.__fw_appLaunchURL(options)
    }
    
    /// 能否打开URL(NSString|NSURL)，需配置对应URL SCHEME到Info.plist才能返回YES
    public static func fw_canOpenURL(_ url: Any) -> Bool {
        return Self.__fw_canOpenURL(url)
    }

    /// 打开URL，支持NSString|NSURL，完成时回调，即使未配置URL SCHEME，实际也能打开成功，只要调用时已打开过对应App
    public static func fw_openURL(_ url: Any, completionHandler: ((Bool) -> Void)? = nil) {
        Self.__fw_openURL(url, completionHandler: completionHandler)
    }

    /// 打开通用链接URL，支持NSString|NSURL，完成时回调。如果是iOS10+通用链接且安装了App，打开并回调YES，否则回调NO
    public static func fw_openUniversalLinks(_ url: Any, completionHandler: ((Bool) -> Void)? = nil) {
        Self.__fw_openUniversalLinks(url, completionHandler: completionHandler)
    }

    /// 判断URL是否是系统链接(如AppStore|电话|设置等)，支持NSString|NSURL
    public static func fw_isSystemURL(_ url: Any) -> Bool {
        return Self.__fw_isSystemURL(url)
    }
    
    /// 判断URL是否是Scheme链接(非http|https|file链接)，支持NSString|NSURL
    public static func fw_isSchemeURL(_ url: Any) -> Bool {
        return Self.__fw_isSchemeURL(url)
    }

    /// 判断URL是否HTTP链接，支持NSString|NSURL
    public static func fw_isHttpURL(_ url: Any) -> Bool {
        return Self.__fw_isHttpURL(url)
    }

    /// 判断URL是否是AppStore链接，支持NSString|NSURL
    public static func fw_isAppStoreURL(_ url: Any) -> Bool {
        return Self.__fw_isAppStoreURL(url)
    }

    /// 打开AppStore下载页
    public static func fw_openAppStore(_ appId: String, completionHandler: ((Bool) -> Void)? = nil) {
        Self.__fw_openAppStore(appId, completionHandler: completionHandler)
    }

    /// 打开AppStore评价页
    public static func fw_openAppStoreReview(_ appId: String, completionHandler: ((Bool) -> Void)? = nil) {
        Self.__fw_openAppStore(appId, completionHandler: completionHandler)
    }

    /// 打开应用内评价，有次数限制
    public static func fw_openAppReview() {
        Self.__fw_openAppReview()
    }

    /// 打开系统应用设置页
    public static func fw_openAppSettings(_ completionHandler: ((Bool) -> Void)? = nil) {
        Self.__fw_openAppSettings(completionHandler)
    }

    /// 打开系统邮件App
    public static func fw_openMailApp(_ email: String, completionHandler: ((Bool) -> Void)? = nil) {
        Self.__fw_openMailApp(email, completionHandler: completionHandler)
    }

    /// 打开系统短信App
    public static func fw_openMessageApp(_ phone: String, completionHandler: ((Bool) -> Void)? = nil) {
        Self.__fw_openMessageApp(phone, completionHandler: completionHandler)
    }

    /// 打开系统电话App
    public static func fw_openPhoneApp(_ phone: String, completionHandler: ((Bool) -> Void)? = nil) {
        Self.__fw_openPhoneApp(phone, completionHandler: completionHandler)
    }

    /// 打开系统分享
    public static func fw_openActivityItems(_ activityItems: [Any], excludedTypes: [UIActivity.ActivityType]? = nil, customBlock: ((UIActivityViewController) -> Void)? = nil) {
        Self.__fw_openActivityItems(activityItems, excludedTypes: excludedTypes, customBlock: customBlock)
    }

    /// 打开内部浏览器，支持NSString|NSURL，点击完成时回调
    public static func fw_openSafariController(_ url: Any, completionHandler: (() -> Void)? = nil) {
        Self.__fw_openSafariController(url, completionHandler: completionHandler)
    }

    /// 打开短信控制器，完成时回调
    public static func fw_openMessageController(_ controller: MFMessageComposeViewController, completionHandler: ((Bool) -> Void)? = nil) {
        Self.__fw_openMessageController(controller, completionHandler: completionHandler)
    }

    /// 打开邮件控制器，完成时回调
    public static func fw_openMailController(_ controller: MFMailComposeViewController, completionHandler: ((Bool) -> Void)? = nil) {
        Self.__fw_openMailController(controller, completionHandler: completionHandler)
    }

    /// 打开Store控制器，完成时回调
    public static func fw_openStoreController(_ parameters: [String: Any], completionHandler: ((Bool) -> Void)? = nil) {
        Self.__fw_openStoreController(parameters, completionHandler: completionHandler)
    }

    /// 打开视频播放器，支持AVPlayerItem|NSURL|NSString
    public static func fw_openVideoPlayer(_ url: Any) -> AVPlayerViewController? {
        return Self.__fw_openVideoPlayer(url)
    }

    /// 打开音频播放器，支持NSURL|NSString
    public static func fw_openAudioPlayer(_ url: Any) -> AVAudioPlayer? {
        return Self.__fw_openAudioPlayer(url)
    }
    
    /// 播放内置声音文件
    @discardableResult
    public static func fw_playSystemSound(_ file: String) -> SystemSoundID {
        return Self.__fw_playSystemSound(file)
    }

    /// 停止播放内置声音文件
    public static func fw_stopSystemSound(_ soundId: SystemSoundID) {
        Self.__fw_stopSystemSound(soundId)
    }

    /// 播放内置震动
    public static func fw_playSystemVibrate() {
        Self.__fw_playSystemVibrate()
    }
    
    /// 播放触控反馈
    public static func fw_playImpactFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        Self.__fw_playImpactFeedback(style)
    }

    /// 语音朗读文字，可指定语言(如zh-CN)
    public static func fw_playSpeechUtterance(_ string: String, language: String?) {
        Self.__fw_playSpeechUtterance(string, language: language)
    }
    
    /// 是否是盗版(不是从AppStore安装)
    public static var fw_isPirated: Bool {
        return Self.__fw_isPirated
    }
    
    /// 是否是Testflight版本
    public static var fw_isTestflight: Bool {
        return Self.__fw_isTestflight
    }
    
}

// MARK: - UIColor+Toolkit
@_spi(FW) @objc extension UIColor {
    
    /// 获取当前颜色指定透明度的新颜色
    public func fw_color(alpha: CGFloat) -> UIColor {
        return withAlphaComponent(alpha)
    }

    /// 读取颜色的十六进制值RGB，不含透明度
    public var fw_hexValue: Int {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        if !getRed(&r, green: &g, blue: &b, alpha: &a) {
            if getWhite(&r, alpha: &a) {
                g = r
                b = r
            }
        }
        
        let red = Int(r * 255)
        let green = Int(g * 255)
        let blue = Int(b * 255)
        return (red << 16) + (green << 8) + blue
    }

    /// 读取颜色的透明度值，范围0~1
    public var fw_alphaValue: CGFloat {
        return self.cgColor.alpha
    }

    /// 读取颜色的十六进制字符串RGB，不含透明度
    public var fw_hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        if !getRed(&r, green: &g, blue: &b, alpha: &a) {
            if getWhite(&r, alpha: &a) {
                g = r
                b = r
            }
        }
        
        return String(format: "#%02lX%02lX%02lX", lroundf(Float(r) * 255), lroundf(Float(g) * 255), lroundf(Float(b) * 255))
    }

    /// 读取颜色的十六进制字符串RGBA|ARGB(透明度为1时RGB)，包含透明度
    public var fw_hexAlphaString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        if !getRed(&r, green: &g, blue: &b, alpha: &a) {
            if getWhite(&r, alpha: &a) {
                g = r
                b = r
            }
        }
        
        if a >= 1.0 {
            return String(format: "#%02lX%02lX%02lX", lroundf(Float(r) * 255), lroundf(Float(g) * 255), lroundf(Float(b) * 255))
        } else if UIColor.fw_colorStandardARGB {
            return String(format: "#%02lX%02lX%02lX%02lX", lround(a * 255), lroundf(Float(r) * 255), lroundf(Float(g) * 255), lroundf(Float(b) * 255))
        } else {
            return String(format: "#%02lX%02lX%02lX%02lX", lroundf(Float(r) * 255), lroundf(Float(g) * 255), lroundf(Float(b) * 255), lround(a * 255))
        }
    }
    
    /// 设置十六进制颜色标准为ARGB|RGBA，启用为ARGB，默认为RGBA
    public static var fw_colorStandardARGB = false

    /// 获取透明度为1.0的RGB随机颜色
    public static var fw_randomColor: UIColor {
        let red = arc4random() % 255
        let green = arc4random() % 255
        let blue = arc4random() % 255
        return UIColor(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }

    /// 从十六进制值初始化，格式：0x20B2AA，透明度默认1.0
    public static func fw_color(hex: Int, alpha: CGFloat = 1.0) -> UIColor {
        return UIColor(red: CGFloat((hex & 0xFF0000) >> 16) / 255.0, green: CGFloat((hex & 0xFF00) >> 8) / 255.0, blue: CGFloat(hex & 0xFF) / 255.0, alpha: alpha)
    }

    /// 从十六进制字符串初始化，支持RGB、RGBA|ARGB，格式：@"20B2AA", @"#FFFFFF"，透明度默认1.0，失败时返回clear
    public static func fw_color(hexString: String, alpha: CGFloat = 1.0) -> UIColor {
        return Self.__fw_color(withHexString: hexString, alpha: alpha)
    }
    
    /// 以指定模式添加混合颜色，默认normal模式
    public func fw_addColor(_ color: UIColor, blendMode: CGBlendMode = .normal) -> UIColor {
        return self.__fw_add(color, blendMode: blendMode)
    }
    
    /// 当前颜色修改亮度比率的颜色
    public func fw_brightnessColor(_ ratio: CGFloat) -> UIColor {
        return self.__fw_brightnessColor(ratio)
    }
    
    /// 判断当前颜色是否为深色
    public var fw_isDarkColor: Bool {
        return self.__fw_isDarkColor
    }
    
    /**
     创建渐变颜色，支持四个方向，默认向下Down
     
     @param size 渐变尺寸，非渐变边可以设置为1。如CGSizeMake(1, 50)
     @param colors 渐变颜色，CGColor数组，如：@[(__bridge id)[UIColor redColor].CGColor, (__bridge id)[UIColor blueColor].CGColor]
     @param locations 渐变位置，传NULL时均分，如：CGFloat locations[] = {0.0, 1.0};
     @param direction 渐变方向，自动计算startPoint和endPoint，支持四个方向，默认向下Down
     @return 渐变色
     */
    public static func fw_gradientColor(size: CGSize, colors: [Any], locations: UnsafePointer<CGFloat>?, direction: UISwipeGestureRecognizer.Direction) -> UIColor {
        return Self.__fw_gradientColor(with: size, colors: colors, locations: locations, direction: direction)
    }

    /**
     创建渐变颜色
     
     @param size 渐变尺寸，非渐变边可以设置为1。如CGSizeMake(1, 50)
     @param colors 渐变颜色，CGColor数组，如：@[(__bridge id)[UIColor redColor].CGColor, (__bridge id)[UIColor blueColor].CGColor]
     @param locations 渐变位置，传NULL时均分，如：CGFloat locations[] = {0.0, 1.0};
     @param startPoint 渐变开始点，需要根据rect计算
     @param endPoint 渐变结束点，需要根据rect计算
     @return 渐变色
     */
    public static func fw_gradientColor(size: CGSize, colors: [Any], locations: UnsafePointer<CGFloat>?, startPoint: CGPoint, endPoint: CGPoint) -> UIColor {
        return Self.__fw_gradientColor(with: size, colors: colors, locations: locations, start: startPoint, end: endPoint)
    }
    
}

// MARK: - UIFont+Toolkit
@_spi(FW) @objc extension UIFont {
    
    /// 全局自定义字体句柄，优先调用
    public static var fw_fontBlock: ((CGFloat, UIFont.Weight) -> UIFont)? {
        get { return Self.__fw_fontBlock }
        set { Self.__fw_fontBlock = newValue }
    }
    
    /// 是否自动等比例缩放字体，默认NO
    public static var fw_autoScale: Bool {
        get { return Self.__fw_autoScale }
        set { Self.__fw_autoScale = newValue }
    }

    /// 返回系统Thin字体
    public static func fw_thinFont(ofSize: CGFloat) -> UIFont {
        return Self.__fw_thinFont(ofSize: ofSize)
    }
    /// 返回系统Light字体
    public static func fw_lightFont(ofSize: CGFloat) -> UIFont {
        return Self.__fw_lightFont(ofSize: ofSize)
    }
    /// 返回系统Regular字体
    public static func fw_font(ofSize: CGFloat) -> UIFont {
        return Self.__fw_font(ofSize: ofSize)
    }
    /// 返回系统Medium字体
    public static func fw_mediumFont(ofSize: CGFloat) -> UIFont {
        return Self.__fw_mediumFont(ofSize: ofSize)
    }
    /// 返回系统Semibold字体
    public static func fw_semiboldFont(ofSize: CGFloat) -> UIFont {
        return Self.__fw_semiboldFont(ofSize: ofSize)
    }
    /// 返回系统Bold字体
    public static func fw_boldFont(ofSize: CGFloat) -> UIFont {
        return Self.__fw_boldFont(ofSize: ofSize)
    }

    /// 创建指定尺寸和weight的系统字体
    public static func fw_font(ofSize: CGFloat, weight: UIFont.Weight) -> UIFont {
        return Self.__fw_font(ofSize: ofSize, weight: weight)
    }
    
    /// 是否是粗体
    public var fw_isBold: Bool {
        return self.__fw_isBold
    }

    /// 是否是斜体
    public var fw_isItalic: Bool {
        return self.__fw_isItalic
    }

    /// 当前字体的粗体字体
    public var fw_boldFont: UIFont {
        return self.__fw_bold
    }
    
    /// 当前字体的非粗体字体
    public var fw_nonBoldFont: UIFont {
        return self.__fw_nonBold
    }
    
    /// 当前字体的斜体字体
    public var fw_italicFont: UIFont {
        return self.__fw_italic
    }
    
    /// 当前字体的非斜体字体
    public var fw_nonItalicFont: UIFont {
        return self.__fw_nonItalic
    }
    
    /// 字体空白高度(上下之和)
    public var fw_spaceHeight: CGFloat {
        return self.__fw_spaceHeight
    }

    /// 根据字体计算指定倍数行间距的实际行距值(减去空白高度)，示例：行间距为0.5倍实际高度
    public func fw_lineSpacing(multiplier: CGFloat) -> CGFloat {
        return self.__fw_lineSpacing(withMultiplier: multiplier)
    }

    /// 根据字体计算指定倍数行高的实际行高值(减去空白高度)，示例：行高为1.5倍实际高度
    public func fw_lineHeight(multiplier: CGFloat) -> CGFloat {
        return self.__fw_lineHeight(withMultiplier: multiplier)
    }

    /// 计算当前字体与指定字体居中对齐的偏移值
    public func fw_baselineOffset(_ font: UIFont) -> CGFloat {
        return self.__fw_baselineOffset(font)
    }
    
}

// MARK: - UIImage+Toolkit
@_spi(FW) @objc extension UIImage {
    
    /// 从当前图片创建指定透明度的图片
    public func fw_image(alpha: CGFloat) -> UIImage? {
        return self.__fw_image(withAlpha: alpha)
    }

    /// 从当前UIImage混合颜色创建UIImage，可自定义模式，默认destinationIn
    public func fw_image(tintColor: UIColor, blendMode: CGBlendMode = .destinationIn) -> UIImage? {
        return self.__fw_image(withTintColor: tintColor, blendMode: blendMode)
    }

    /// 缩放图片到指定大小
    public func fw_image(scaleSize: CGSize) -> UIImage? {
        return self.__fw_image(withScale: scaleSize)
    }

    /// 缩放图片到指定大小，指定模式
    public func fw_image(scaleSize: CGSize, contentMode: UIView.ContentMode) -> UIImage? {
        return self.__fw_image(withScale: scaleSize, contentMode: contentMode)
    }

    /// 按指定模式绘制图片
    public func fw_draw(in rect: CGRect, contentMode: UIView.ContentMode, clipsToBounds: Bool) {
        self.__fw_draw(in: rect, with: contentMode, clipsToBounds: clipsToBounds)
    }

    /// 裁剪指定区域图片
    public func fw_image(cropRect: CGRect) -> UIImage? {
        return self.__fw_image(withCropRect: cropRect)
    }

    /// 指定颜色填充图片边缘
    public func fw_image(insets: UIEdgeInsets, color: UIColor?) -> UIImage? {
        return self.__fw_image(with: insets, color: color)
    }

    /// 拉伸图片(平铺模式)，指定端盖区域（不拉伸区域）
    public func fw_image(capInsets: UIEdgeInsets) -> UIImage {
        return self.__fw_image(withCapInsets: capInsets)
    }

    /// 拉伸图片(指定模式)，指定端盖区域（不拉伸区域）。Tile为平铺模式，Stretch为拉伸模式
    public func fw_image(capInsets: UIEdgeInsets, resizingMode: UIImage.ResizingMode) -> UIImage {
        return self.__fw_image(withCapInsets: capInsets, resizingMode: resizingMode)
    }

    /// 生成圆角图片
    public func fw_image(cornerRadius: CGFloat) -> UIImage? {
        return self.__fw_image(withCornerRadius: cornerRadius)
    }

    /// 按角度常数(0~360)转动图片，指定图片尺寸是否延伸来适应内容，否则图片尺寸不变，内容被裁剪，默认true
    public func fw_image(rotateDegree: CGFloat, fitSize: Bool = true) -> UIImage? {
        return self.__fw_image(withRotateDegree: rotateDegree, fitSize: fitSize)
    }

    /// 生成mark图片
    public func fw_image(maskImage: UIImage) -> UIImage? {
        return self.__fw_image(withMaskImage: maskImage)
    }

    /// 图片合并，并制定叠加图片的起始位置
    public func fw_image(mergeImage: UIImage, atPoint: CGPoint) -> UIImage? {
        return self.__fw_image(withMerge: mergeImage, at: atPoint)
    }

    /// 图片应用CIFilter滤镜处理
    public func fw_image(filter: CIFilter) -> UIImage? {
        return self.__fw_image(with: filter)
    }

    /// 压缩图片到指定字节，图片太大时会改为JPG格式。不保证图片大小一定小于该大小
    public func fw_compressImage(maxLength: Int) -> UIImage? {
        return self.__fw_compressImage(withMaxLength: maxLength)
    }

    /// 压缩图片到指定字节，图片太大时会改为JPG格式，可设置递减压缩率，默认0.1。不保证图片大小一定小于该大小
    public func fw_compressData(maxLength: Int, compressRatio: CGFloat) -> Data? {
        return self.__fw_compressData(withMaxLength: maxLength, compressRatio: compressRatio)
    }

    /// 长边压缩图片尺寸，获取等比例的图片
    public func fw_compressImage(maxWidth: Int) -> UIImage? {
        return self.__fw_compressImage(withMaxWidth: maxWidth)
    }

    /// 通过指定图片最长边，获取等比例的图片size
    public func fw_scaleSize(maxWidth: CGFloat) -> CGSize {
        return self.__fw_scaleSize(withMaxWidth: maxWidth)
    }

    /// 获取原始渲染模式图片，始终显示原色，不显示tintColor。默认自动根据上下文
    public var fw_originalImage: UIImage {
        return self.__fw_original
    }

    /// 获取模板渲染模式图片，始终显示tintColor，不显示原色。默认自动根据上下文
    public var fw_templateImage: UIImage {
        return self.__fw_template
    }

    /// 判断图片是否有透明通道
    public var fw_hasAlpha: Bool {
        return self.__fw_hasAlpha
    }

    /// 获取当前图片的像素大小，多倍图会放大到一倍
    public var fw_pixelSize: CGSize {
        return self.__fw_pixelSize
    }
    
    /// 从视图创建UIImage，生成截图，主线程调用
    public static func fw_image(view: UIView) -> UIImage? {
        return Self.__fw_image(with: view)
    }
    
    /// 从颜色创建UIImage，尺寸默认1x1
    public static func fw_image(color: UIColor) -> UIImage? {
        return Self.__fw_image(with: color)
    }
    
    /// 从颜色创建UIImage，可指定尺寸和圆角，默认圆角0
    public static func fw_image(color: UIColor, size: CGSize, cornerRadius: CGFloat = 0) -> UIImage? {
        return Self.__fw_image(with: color, size: size, cornerRadius: cornerRadius)
    }

    /// 从block创建UIImage，指定尺寸
    public static func fw_image(size: CGSize, block: (CGContext) -> Void) -> UIImage? {
        return Self.__fw_image(with: size, block: block)
    }
    
    /// 保存图片到相册，保存成功时error为nil
    public func fw_saveImage(completion: ((Error?) -> Void)? = nil) {
        self.__fw_saveImage(completion: completion)
    }
    
    /// 保存视频到相册，保存成功时error为nil。如果视频地址为NSURL，需使用NSURL.path
    public static func fw_saveVideo(_ videoPath: String, completion: ((Error?) -> Void)? = nil) {
        Self.__fw_saveVideo(videoPath, withCompletion: completion)
    }
    
    /// 获取灰度图
    public var fw_grayImage: UIImage? {
        return self.__fw_gray
    }

    /// 获取图片的平均颜色
    public var fw_averageColor: UIColor {
        return self.__fw_averageColor
    }

    /// 倒影图片
    public func fw_image(reflectScale: CGFloat) -> UIImage? {
        return self.__fw_image(withReflectScale: reflectScale)
    }

    /// 倒影图片
    public func fw_image(reflectScale: CGFloat, gap: CGFloat, alpha: CGFloat) -> UIImage? {
        return self.__fw_image(withReflectScale: reflectScale, gap: gap, alpha: alpha)
    }

    /// 阴影图片
    public func fw_image(shadowColor: UIColor, offset: CGSize, blur: CGFloat) -> UIImage? {
        return self.__fw_image(withShadowColor: shadowColor, offset: offset, blur: blur)
    }

    /// 获取装饰图片
    public var fw_maskImage: UIImage {
        return self.__fw_mask
    }

    /// 高斯模糊图片，默认模糊半径为10，饱和度为1。注意CGContextDrawImage如果图片尺寸太大会导致内存不足闪退，建议先压缩再调用
    public func fw_image(blurRadius: CGFloat, saturationDelta: CGFloat, tintColor: UIColor?, maskImage: UIImage?) -> UIImage? {
        return self.__fw_image(withBlurRadius: blurRadius, saturationDelta: saturationDelta, tintColor: tintColor, maskImage: maskImage)
    }

    /// 如果没有透明通道，增加透明通道
    public var fw_alphaImage: UIImage {
        return self.__fw_alpha
    }

    /// 截取View所有视图，包括旋转缩放效果
    public static func fw_image(view: UIView, limitWidth: CGFloat) -> UIImage? {
        return Self.__fw_image(with: view, limitWidth: limitWidth)
    }

    /// 获取AppIcon图片
    public static func fw_appIconImage() -> UIImage? {
        return Self.__fw_appIcon()
    }

    /// 获取AppIcon指定尺寸图片，名称格式：AppIcon60x60
    public static func fw_appIconImage(size: CGSize) -> UIImage? {
        return Self.__fw_appIconImage(size)
    }

    /// 从Pdf数据或者路径创建指定大小UIImage
    public static func fw_image(pdf path: Any, size: CGSize = .zero) -> UIImage? {
        return Self.__fw_image(withPdf: path, size: size)
    }
    
    /**
     创建渐变颜色UIImage，支持四个方向，默认向下Down
     
     @param size 图片大小
     @param colors 渐变颜色，CGColor数组，如：@[(__bridge id)[UIColor redColor].CGColor, (__bridge id)[UIColor blueColor].CGColor]
     @param locations 渐变位置，传NULL时均分，如：CGFloat locations[] = {0.0, 1.0};
     @param direction 渐变方向，自动计算startPoint和endPoint，支持四个方向，默认向下Down
     @return 渐变颜色UIImage
     */
    public static func fw_gradientImage(size: CGSize, colors: [Any], locations: UnsafePointer<CGFloat>?, direction: UISwipeGestureRecognizer.Direction) -> UIImage? {
        return Self.__fw_gradientImage(with: size, colors: colors, locations: locations, direction: direction)
    }

    /**
     创建渐变颜色UIImage
     
     @param size 图片大小
     @param colors 渐变颜色，CGColor数组，如：@[(__bridge id)[UIColor redColor].CGColor, (__bridge id)[UIColor blueColor].CGColor]
     @param locations 渐变位置，传NULL时均分，如：CGFloat locations[] = {0.0, 1.0};
     @param startPoint 渐变开始点，需要根据rect计算
     @param endPoint 渐变结束点，需要根据rect计算
     @return 渐变颜色UIImage
     */
    public static func fw_gradientImage(size: CGSize, colors: [Any], locations: UnsafePointer<CGFloat>?, startPoint: CGPoint, endPoint: CGPoint) -> UIImage? {
        return Self.__fw_gradientImage(with: size, colors: colors, locations: locations, start: startPoint, end: endPoint)
    }
    
}

// MARK: - UIView+Toolkit
@_spi(FW) @objc extension UIView {
    
    /// 顶部纵坐标，frame.origin.y
    public var fw_top: CGFloat {
        get { return self.__fw_top }
        set { self.__fw_top = newValue }
    }

    /// 底部纵坐标，frame.origin.y + frame.size.height
    public var fw_bottom: CGFloat {
        get { return self.__fw_bottom }
        set { self.__fw_bottom = newValue }
    }

    /// 左边横坐标，frame.origin.x
    public var fw_left: CGFloat {
        get { return self.__fw_left }
        set { self.__fw_left = newValue }
    }

    /// 右边横坐标，frame.origin.x + frame.size.width
    public var fw_right: CGFloat {
        get { return self.__fw_right }
        set { self.__fw_right = newValue }
    }

    /// 宽度，frame.size.width
    public var fw_width: CGFloat {
        get { return self.__fw_width }
        set { self.__fw_width = newValue }
    }

    /// 高度，frame.size.height
    public var fw_height: CGFloat {
        get { return self.__fw_height }
        set { self.__fw_height = newValue }
    }

    /// 中心横坐标，center.x
    public var fw_centerX: CGFloat {
        get { return self.__fw_centerX }
        set { self.__fw_centerX = newValue }
    }

    /// 中心纵坐标，center.y
    public var fw_centerY: CGFloat {
        get { return self.__fw_centerY }
        set { self.__fw_centerY = newValue }
    }

    /// 起始横坐标，frame.origin.x
    public var fw_x: CGFloat {
        get { return self.__fw_x }
        set { self.__fw_x = newValue }
    }

    /// 起始纵坐标，frame.origin.y
    public var fw_y: CGFloat {
        get { return self.__fw_y }
        set { self.__fw_y = newValue }
    }

    /// 起始坐标，frame.origin
    public var fw_origin: CGPoint {
        get { return self.__fw_origin }
        set { self.__fw_origin = newValue }
    }

    /// 大小，frame.size
    public var fw_size: CGSize {
        get { return self.__fw_size }
        set { self.__fw_size = newValue }
    }
    
}

// MARK: - UIViewController+Toolkit
@_spi(FW) @objc extension UIViewController {
    
    /// 当前生命周期状态，默认Ready
    public var fw_visibleState: ViewControllerVisibleState {
        return self.__fw_visibleState
    }

    /// 生命周期变化时通知句柄，默认nil
    public var fw_visibleStateChanged: ((UIViewController, ViewControllerVisibleState) -> Void)? {
        get { return self.__fw_visibleStateChanged }
        set { self.__fw_visibleStateChanged = newValue }
    }

    /// 自定义完成结果对象，默认nil
    public var fw_completionResult: Any? {
        get { return self.__fw_completionResult }
        set { self.__fw_completionResult = newValue }
    }

    /// 自定义完成句柄，默认nil，dealloc时自动调用，参数为fwCompletionResult。支持提前调用，调用后需置为nil
    public var fw_completionHandler: ((Any?) -> Void)? {
        get { return self.__fw_completionHandler }
        set { self.__fw_completionHandler = newValue }
    }

    /// 自定义侧滑返回手势VC开关句柄，enablePopProxy启用后生效，仅处理边缘返回手势，优先级低，默认nil
    public var fw_allowsPopGesture: (() -> Bool)? {
        get { return self.__fw_allowsPopGesture }
        set { self.__fw_allowsPopGesture = newValue }
    }

    /// 自定义控制器返回VC开关句柄，enablePopProxy启用后生效，统一处理返回按钮点击和边缘返回手势，优先级高，默认nil
    public var fw_shouldPopController: (() -> Bool)? {
        get { return self.__fw_shouldPopController }
        set { self.__fw_shouldPopController = newValue }
    }
    
}

// MARK: - UINavigationController+Toolkit
/// 当自定义left按钮或隐藏导航栏之后，系统返回手势默认失效，可调用此方法全局开启返回代理。开启后自动将开关代理给顶部VC的shouldPopController、popGestureEnabled属性控制。interactivePop手势禁用时不生效
@_spi(FW) @objc extension UINavigationController {
    
    /// 单独启用返回代理拦截，优先级高于+enablePopProxy，启用后支持shouldPopController、allowsPopGesture功能，默认NO未启用
    public func fw_enablePopProxy() {
        self.__fw_enablePopProxy()
    }
    
    /// 全局启用返回代理拦截，优先级低于-enablePopProxy，启用后支持shouldPopController、allowsPopGesture功能，默认NO未启用
    public static func fw_enablePopProxy() {
        Self.__fw_enablePopProxy()
    }
    
}
