//
//  Toolkit.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Accelerate
import AudioToolbox
import AVFoundation
import AVKit
import MessageUI
import SafariServices
import StoreKit
import UIKit

// MARK: - WrapperGlobal
extension WrapperGlobal {
    /// 从16进制创建UIColor
    ///
    /// - Parameters:
    ///   - hex: 十六进制值，格式0xFFFFFF
    ///   - alpha: 透明度可选，默认1.0
    /// - Returns: UIColor
    public static func color(_ hex: Int, _ alpha: CGFloat = 1.0) -> UIColor {
        UIColor.fw.color(hex: hex, alpha: alpha)
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
        UIColor(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: alpha)
    }

    /// 快速创建系统字体，自动等比例缩放
    ///
    /// - Parameters:
    ///   - size: 字体字号
    ///   - weight: 字重可选，默认Regular
    ///   - autoScale: 是否自动等比例缩放，默认全局配置
    /// - Returns: UIFont
    @MainActor public static func font(_ size: CGFloat, _ weight: UIFont.Weight = .regular, autoScale: Bool? = nil) -> UIFont {
        UIFont.fw.font(ofSize: size, weight: weight, autoScale: autoScale)
    }
    
    /// 快速创建设备纵向界面系统字体，自动等比例缩放
    ///
    /// - Parameters:
    ///   - size: 字体字号
    ///   - weight: 字重可选，默认Regular
    ///   - autoScale: 是否自动等比例缩放，默认全局配置
    /// - Returns: UIFont
    public static func portraitFont(_ size: CGFloat, _ weight: UIFont.Weight = .regular, autoScale: Bool? = nil) -> UIFont {
        UIFont.fw.portraitFont(ofSize: size, weight: weight, autoScale: autoScale)
    }
    
    /// 快速创建设备横向界面系统字体，自动等比例缩放
    ///
    /// - Parameters:
    ///   - size: 字体字号
    ///   - weight: 字重可选，默认Regular
    ///   - autoScale: 是否自动等比例缩放，默认全局配置
    /// - Returns: UIFont
    public static func landscapeFont(_ size: CGFloat, _ weight: UIFont.Weight = .regular, autoScale: Bool? = nil) -> UIFont {
        UIFont.fw.landscapeFont(ofSize: size, weight: weight, autoScale: autoScale)
    }
}

// MARK: - Wrapper+UIApplication
/// 注意Info.plist文件URL SCHEME配置项只影响canOpenUrl方法，不影响openUrl。微信返回app就是获取sourceUrl，直接openUrl实现。因为跳转微信的时候，来源app肯定已打开过，可以跳转，只要不检查canOpenUrl，就可以跳转回app。
/// 为了防止系统启动图缓存，每次更换启动图时建议修改启动图名称(比如添加日期等)，防止刚更新App时新图不生效
extension Wrapper where Base: UIApplication {
    /// 读取应用名称
    public static var appName: String {
        let appName = Bundle.main.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String
        return appName ?? ""
    }

    /// 读取应用显示名称，未配置时读取名称
    public static var appDisplayName: String {
        let displayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        return displayName ?? appName
    }

    /// 读取应用主版本号，可自定义，示例：1.0.0
    public static var appVersion: String {
        get {
            if let appVersion = UIApplication.innerAppVersion {
                return appVersion
            }
            let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            return appVersion ?? appBuildVersion
        }
        set {
            UIApplication.innerAppVersion = newValue
        }
    }

    /// 读取应用构建版本号，示例：1.0.0.1
    public static var appBuildVersion: String {
        let buildVersion = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
        return buildVersion ?? ""
    }

    /// 读取应用唯一标识
    public static var appIdentifier: String {
        let appIdentifier = Bundle.main.object(forInfoDictionaryKey: kCFBundleIdentifierKey as String) as? String
        return appIdentifier ?? ""
    }

    /// 读取应用可执行程序名称
    public static var appExecutable: String {
        let appExecutable = Bundle.main.object(forInfoDictionaryKey: kCFBundleExecutableKey as String) as? String
        return appExecutable ?? appIdentifier
    }

    /// 读取应用信息字典
    public static func appInfo(_ key: String) -> Any? {
        Bundle.main.object(forInfoDictionaryKey: key)
    }

    /// 读取应用启动URL
    public static func appLaunchURL(_ options: [UIApplication.LaunchOptionsKey: Any]?) -> URL? {
        if let url = options?[.url] as? URL {
            return url
        } else if let dict = options?[.userActivityDictionary] as? [AnyHashable: Any],
                  let userActivity = dict["UIApplicationLaunchOptionsUserActivityKey"] as? NSUserActivity,
                  userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            return userActivity.webpageURL
        }
        return nil
    }

    /// 能否打开URL(NSString|NSURL)，需配置对应URL SCHEME到Info.plist才能返回YES
    @MainActor public static func canOpenURL(_ url: URLParameter?) -> Bool {
        guard let url = url?.urlValue else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    /// 打开URL，支持NSString|NSURL，完成时回调，即使未配置URL SCHEME，实际也能打开成功，只要调用时已打开过对应App
    @MainActor public static func openURL(_ url: URLParameter?, completionHandler: (@MainActor @Sendable (Bool) -> Void)? = nil) {
        guard let url = url?.urlValue else {
            completionHandler?(false)
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: completionHandler)
    }

    /// 打开通用链接URL，支持NSString|NSURL，完成时回调。如果是iOS10+通用链接且安装了App，打开并回调YES，否则回调NO
    @MainActor public static func openUniversalLinks(_ url: URLParameter?, completionHandler: (@MainActor @Sendable (Bool) -> Void)? = nil) {
        guard let url = url?.urlValue else {
            completionHandler?(false)
            return
        }
        UIApplication.shared.open(url, options: [.universalLinksOnly: true], completionHandler: completionHandler)
    }

    /// 判断URL是否是系统链接(如AppStore|电话|设置等)，支持NSString|NSURL
    public static func isSystemURL(_ url: URLParameter?) -> Bool {
        guard let url = url?.urlValue else { return false }
        if let scheme = url.scheme?.lowercased(),
           ["tel", "telprompt", "sms", "mailto"].contains(scheme) {
            return true
        }
        if isAppStoreURL(url) {
            return true
        }
        if url.absoluteString == UIApplication.openSettingsURLString {
            return true
        }
        if #available(iOS 16.0, *) {
            if url.absoluteString == UIApplication.openNotificationSettingsURLString {
                return true
            }
        } else if #available(iOS 15.4, *) {
            if url.absoluteString == UIApplicationOpenNotificationSettingsURLString {
                return true
            }
        }
        return false
    }

    /// 判断URL是否在指定Scheme链接数组中，不区分大小写
    public static func isSchemeURL(_ url: URLParameter?, schemes: [String]) -> Bool {
        guard let url = url?.urlValue,
              let urlScheme = url.scheme?.lowercased(),
              !urlScheme.isEmpty else { return false }

        return schemes.contains { $0.lowercased() == urlScheme }
    }

    /// 判断URL是否HTTP链接，支持NSString|NSURL
    public static func isHttpURL(_ url: URLParameter?) -> Bool {
        let urlString = url?.urlValue.absoluteString ?? ""
        return urlString.lowercased().hasPrefix("http://") || urlString.lowercased().hasPrefix("https://")
    }

    /// 判断URL是否是AppStore链接，支持NSString|NSURL
    public static func isAppStoreURL(_ url: URLParameter?) -> Bool {
        guard let url = url?.urlValue else { return false }
        // itms-apps等
        if let scheme = url.scheme, scheme.lowercased().hasPrefix("itms") {
            return true
            // https://apps.apple.com/等
        } else if let host = url.host?.lowercased(), ["itunes.apple.com", "apps.apple.com"].contains(host) {
            return true
        }
        return false
    }

    /// 打开AppStore下载页
    @MainActor public static func openAppStore(_ appId: String, completionHandler: (@MainActor @Sendable (Bool) -> Void)? = nil) {
        // SKStoreProductViewController可以内部打开
        openURL("https://apps.apple.com/app/id\(appId)", completionHandler: completionHandler)
    }

    /// 打开AppStore评价页
    @MainActor public static func openAppStoreReview(_ appId: String, completionHandler: (@MainActor @Sendable (Bool) -> Void)? = nil) {
        openURL("https://apps.apple.com/app/id\(appId)?action=write-review", completionHandler: completionHandler)
    }

    /// 打开应用内评价，有次数限制
    public static func openAppReview() {
        SKStoreReviewController.requestReview()
    }

    /// 打开系统应用设置页
    @MainActor public static func openAppSettings(_ completionHandler: (@MainActor @Sendable (Bool) -> Void)? = nil) {
        openURL(UIApplication.openSettingsURLString, completionHandler: completionHandler)
    }

    /// 打开系统应用通知设置页
    @MainActor public static func openAppNotificationSettings(_ completionHandler: (@MainActor @Sendable (Bool) -> Void)? = nil) {
        if #available(iOS 16.0, *) {
            openURL(UIApplication.openNotificationSettingsURLString, completionHandler: completionHandler)
        } else if #available(iOS 15.4, *) {
            openURL(UIApplicationOpenNotificationSettingsURLString, completionHandler: completionHandler)
        } else {
            openURL(UIApplication.openSettingsURLString, completionHandler: completionHandler)
        }
    }

    /// 打开系统邮件App
    @MainActor public static func openMailApp(_ email: String, completionHandler: (@MainActor @Sendable (Bool) -> Void)? = nil) {
        openURL("mailto:" + email, completionHandler: completionHandler)
    }

    /// 打开系统短信App
    @MainActor public static func openMessageApp(_ phone: String, completionHandler: (@MainActor @Sendable (Bool) -> Void)? = nil) {
        openURL("sms:" + phone, completionHandler: completionHandler)
    }

    /// 打开系统电话App
    @MainActor public static func openPhoneApp(_ phone: String, completionHandler: (@MainActor @Sendable (Bool) -> Void)? = nil) {
        openURL("tel:" + phone, completionHandler: completionHandler)
    }

    /// 打开系统分享
    @MainActor public static func openActivityItems(
        _ activityItems: [Any],
        excludedTypes: [UIActivity.ActivityType]? = nil,
        completionHandler: UIActivityViewController.CompletionWithItemsHandler? = nil,
        customBlock: (@MainActor (UIActivityViewController) -> Void)? = nil
    ) {
        let activityController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityController.excludedActivityTypes = excludedTypes
        activityController.completionWithItemsHandler = completionHandler
        // 兼容iPad，默认居中显示
        let viewController = Navigator.topPresentedController
        if UIDevice.current.userInterfaceIdiom == .pad, let viewController,
           let popoverController = activityController.popoverPresentationController {
            let ancestorView = viewController.fw.ancestorView
            popoverController.sourceView = ancestorView
            popoverController.sourceRect = CGRect(x: ancestorView.center.x, y: ancestorView.center.y, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        customBlock?(activityController)
        viewController?.present(activityController, animated: true)
    }

    /// 打开内部浏览器，支持NSString|NSURL，点击完成时回调
    @MainActor public static func openSafariController(_ url: URLParameter?, completionHandler: (() -> Void)? = nil, customBlock: (@MainActor (SFSafariViewController) -> Void)? = nil) {
        guard let url = url?.urlValue, isHttpURL(url) else { return }
        let safariController = SFSafariViewController(url: url)
        if completionHandler != nil {
            safariController.fw.setProperty(completionHandler, forName: "safariViewControllerDidFinish")
            safariController.delegate = SafariViewControllerDelegate.shared
        }
        customBlock?(safariController)
        Navigator.present(safariController, animated: true)
    }

    /// 打开短信控制器，完成时回调
    @MainActor public static func openMessageController(_ controller: MFMessageComposeViewController, completionHandler: (@Sendable (Bool) -> Void)? = nil) {
        if !MFMessageComposeViewController.canSendText() {
            completionHandler?(false)
            return
        }

        if completionHandler != nil {
            controller.fw.setProperty(completionHandler, forName: "messageComposeViewController")
        }
        controller.messageComposeDelegate = SafariViewControllerDelegate.shared
        Navigator.present(controller, animated: true)
    }

    /// 打开邮件控制器，完成时回调
    @MainActor public static func openMailController(_ controller: MFMailComposeViewController, completionHandler: (@Sendable (Bool) -> Void)? = nil) {
        if !MFMailComposeViewController.canSendMail() {
            completionHandler?(false)
            return
        }

        if completionHandler != nil {
            controller.fw.setProperty(completionHandler, forName: "mailComposeController")
        }
        controller.mailComposeDelegate = SafariViewControllerDelegate.shared
        Navigator.present(controller, animated: true)
    }

    /// 打开Store控制器，完成时回调
    @MainActor public static func openStoreController(_ parameters: [String: Any], completionHandler: (@Sendable (Bool) -> Void)? = nil, customBlock: ((SKStoreProductViewController) -> Void)? = nil) {
        let controller = SKStoreProductViewController()
        controller.delegate = SafariViewControllerDelegate.shared
        controller.loadProduct(withParameters: parameters) { result, _ in
            if !result {
                completionHandler?(false)
                return
            }

            controller.fw.setProperty(completionHandler, forName: "productViewControllerDidFinish")
            customBlock?(controller)
            Navigator.present(controller, animated: true)
        }
    }

    /// 打开视频播放器，支持AVPlayerItem|NSURL|NSString
    @MainActor public static func openVideoPlayer(_ url: Any?) -> AVPlayerViewController? {
        var player: AVPlayer?
        if let playerItem = url as? AVPlayerItem {
            player = AVPlayer(playerItem: playerItem)
        } else if let url = url as? URL {
            player = AVPlayer(url: url)
        } else if let videoUrl = URL.fw.url(string: url as? String) {
            player = AVPlayer(url: videoUrl)
        }
        guard player != nil else { return nil }

        let viewController = AVPlayerViewController()
        viewController.player = player
        return viewController
    }

    /// 打开音频播放器，支持NSURL|NSString
    public static func openAudioPlayer(_ url: URLParameter?) -> AVAudioPlayer? {
        // 设置播放模式示例: ambient不支持后台，playback支持后台和混音(需配置后台audio模式)
        // try? AVAudioSession.sharedInstance().setCategory(.ambient)
        // try? AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)

        var audioUrl: URL?
        if let url = url as? URL {
            audioUrl = url
        } else if let urlString = url as? String {
            if (urlString as NSString).isAbsolutePath {
                audioUrl = URL(fileURLWithPath: urlString)
            } else {
                audioUrl = Bundle.main.url(forResource: urlString, withExtension: nil)
            }
        }
        guard let audioUrl else { return nil }

        guard let audioPlayer = try? AVAudioPlayer(contentsOf: audioUrl) else { return nil }
        if !audioPlayer.prepareToPlay() { return nil }

        audioPlayer.play()
        return audioPlayer
    }

    /// 播放内置声音文件，完成后回调
    @discardableResult
    public static func playSystemSound(_ file: String, completionHandler: (() -> Void)? = nil) -> SystemSoundID {
        guard !file.isEmpty else { return 0 }

        var soundFile = file
        if !(file as NSString).isAbsolutePath {
            guard let resourceFile = Bundle.main.path(forResource: file, ofType: nil) else { return 0 }
            soundFile = resourceFile
        }
        if !FileManager.default.fileExists(atPath: soundFile) {
            return 0
        }

        let soundUrl = URL(fileURLWithPath: soundFile)
        var soundId: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(soundUrl as CFURL, &soundId)
        AudioServicesPlaySystemSoundWithCompletion(soundId, completionHandler)
        return soundId
    }

    /// 停止播放内置声音文件
    public static func stopSystemSound(_ soundId: SystemSoundID) {
        if soundId == 0 { return }

        AudioServicesRemoveSystemSoundCompletion(soundId)
        AudioServicesDisposeSystemSoundID(soundId)
    }

    /// 播放内置震动，完成后回调
    public static func playSystemVibrate(_ completionHandler: (() -> Void)? = nil) {
        AudioServicesPlaySystemSoundWithCompletion(kSystemSoundID_Vibrate, completionHandler)
    }

    /// 播放触控反馈
    @MainActor public static func playImpactFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: style)
        feedbackGenerator.impactOccurred()
    }

    /// 语音朗读文字，可指定语言(如zh-CN)
    public static func playSpeechUtterance(_ string: String, language: String?) {
        let speechUtterance = AVSpeechUtterance(string: string)
        speechUtterance.rate = AVSpeechUtteranceDefaultSpeechRate
        speechUtterance.voice = AVSpeechSynthesisVoice(language: language)
        let speechSynthesizer = AVSpeechSynthesizer()
        speechSynthesizer.speak(speechUtterance)
    }

    /// 是否是盗版(不是从AppStore安装)
    public static var isPirated: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        if getgid() <= 10 {
            return true
        }

        if Bundle.main.object(forInfoDictionaryKey: "SignerIdentity") != nil {
            return true
        }

        let bundlePath = Bundle.main.bundlePath as NSString
        var path = bundlePath.appendingPathComponent(String(format: "%@%@%@", "_C", "odeSi", "gnature"))
        if !FileManager.default.fileExists(atPath: path) {
            return true
        }

        path = bundlePath.appendingPathComponent("SC_Info")
        if !FileManager.default.fileExists(atPath: path) {
            return true
        }

        return false
        #endif
    }

    /// 是否是Testflight版本(非AppStore)
    public static var isTestflight: Bool {
        inferredEnvironment == 1
    }

    /// 是否是AppStore版本
    public static var isAppStore: Bool {
        inferredEnvironment == 2
    }

    /// 推测的运行环境，0=>Debug, 1=>Testflight, 2=>AppStore
    private static var inferredEnvironment: Int {
        #if DEBUG
        return 0

        #elseif targetEnvironment(simulator)
        return 0

        #else
        if Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") != nil {
            return 1
        }
        guard let appStoreReceiptUrl = Bundle.main.appStoreReceiptURL else {
            return 0
        }
        if appStoreReceiptUrl.lastPathComponent.lowercased() == "sandboxreceipt" {
            return 1
        }
        if appStoreReceiptUrl.path.lowercased().contains("simulator") {
            return 0
        }
        return 2
        #endif
    }

    /// 开始后台任务，task必须调用completionHandler
    @MainActor public static func beginBackgroundTask(
        _ task: (@escaping @Sendable () -> Void) -> Void,
        name: String? = nil,
        expirationHandler: (@MainActor @Sendable () -> Void)? = nil
    ) {
        let bgTask = SendableObject<UIBackgroundTaskIdentifier>(.invalid)
        let application = UIApplication.shared
        bgTask.object = application.beginBackgroundTask(withName: name, expirationHandler: {
            expirationHandler?()
            application.endBackgroundTask(bgTask.object)
            bgTask.object = .invalid
        })

        task { @Sendable in
            application.endBackgroundTask(bgTask.object)
            bgTask.object = .invalid
        }
    }
}

// MARK: - Wrapper+UIColor
extension Wrapper where Base: UIColor {
    /// 获取当前颜色指定透明度的新颜色
    public func color(alpha: CGFloat) -> UIColor {
        base.withAlphaComponent(alpha)
    }

    /// 读取颜色的十六进制值RGB，不含透明度
    public var hexValue: Int {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        if !base.getRed(&r, green: &g, blue: &b, alpha: &a) {
            if base.getWhite(&r, alpha: &a) {
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
    public var alphaValue: CGFloat {
        base.cgColor.alpha
    }

    /// 读取颜色的十六进制字符串RGB，不含透明度
    public var hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        if !base.getRed(&r, green: &g, blue: &b, alpha: &a) {
            if base.getWhite(&r, alpha: &a) {
                g = r
                b = r
            }
        }

        return String(format: "#%02lX%02lX%02lX", lroundf(Float(r) * 255), lroundf(Float(g) * 255), lroundf(Float(b) * 255))
    }

    /// 读取颜色的十六进制字符串RGBA|ARGB(透明度为1时RGB)，包含透明度
    public var hexAlphaString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        if !base.getRed(&r, green: &g, blue: &b, alpha: &a) {
            if base.getWhite(&r, alpha: &a) {
                g = r
                b = r
            }
        }

        if a >= 1.0 {
            return String(format: "#%02lX%02lX%02lX", lroundf(Float(r) * 255), lroundf(Float(g) * 255), lroundf(Float(b) * 255))
        } else if UIColor.innerColorStandardARGB {
            return String(format: "#%02lX%02lX%02lX%02lX", lround(a * 255), lroundf(Float(r) * 255), lroundf(Float(g) * 255), lroundf(Float(b) * 255))
        } else {
            return String(format: "#%02lX%02lX%02lX%02lX", lroundf(Float(r) * 255), lroundf(Float(g) * 255), lroundf(Float(b) * 255), lround(a * 255))
        }
    }

    /// 设置十六进制颜色标准为ARGB|RGBA，启用为ARGB，默认为RGBA
    public static var colorStandardARGB: Bool {
        get { Base.innerColorStandardARGB }
        set { Base.innerColorStandardARGB = newValue }
    }

    /// 获取透明度为1.0的RGB随机颜色
    public static var randomColor: UIColor {
        let red = arc4random() % 255
        let green = arc4random() % 255
        let blue = arc4random() % 255
        return UIColor(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }

    /// 从十六进制值初始化，格式：0x20B2AA，透明度默认1.0
    public static func color(hex: Int, alpha: CGFloat = 1.0) -> UIColor {
        UIColor(red: CGFloat((hex & 0xFF0000) >> 16) / 255.0, green: CGFloat((hex & 0xFF00) >> 8) / 255.0, blue: CGFloat(hex & 0xFF) / 255.0, alpha: alpha)
    }

    /// 从十六进制字符串初始化，支持RGB、RGBA|ARGB，格式：@"20B2AA", @"#FFFFFF"，透明度默认1.0，失败时返回clear
    public static func color(hexString: String, alpha: CGFloat = 1.0) -> UIColor {
        // 处理参数
        var string = hexString.uppercased()
        if string.hasPrefix("0X") {
            string = string.fw.substring(from: 2)
        }
        if string.hasPrefix("#") {
            string = string.fw.substring(from: 1)
        }

        // 检查长度
        let length = string.count
        if length != 3 && length != 4 && length != 6 && length != 8 {
            return UIColor.clear
        }

        // 解析颜色
        var strR = ""
        var strG = ""
        var strB = ""
        var strA = ""
        if length < 5 {
            // ARGB
            if UIColor.innerColorStandardARGB && length == 4 {
                string = String(format: "%@%@", string.fw.substring(with: NSMakeRange(1, 3)), string.fw.substring(with: NSMakeRange(0, 1)))
            }
            // RGB|RGBA
            let tmpR = string.fw.substring(with: NSMakeRange(0, 1))
            let tmpG = string.fw.substring(with: NSMakeRange(1, 1))
            let tmpB = string.fw.substring(with: NSMakeRange(2, 1))
            strR = String(format: "%@%@", tmpR, tmpR)
            strG = String(format: "%@%@", tmpG, tmpG)
            strB = String(format: "%@%@", tmpB, tmpB)
            if length == 4 {
                let tmpA = string.fw.substring(with: NSMakeRange(3, 1))
                strA = String(format: "%@%@", tmpA, tmpA)
            }
        } else {
            // AARRGGBB
            if UIColor.innerColorStandardARGB && length == 8 {
                string = String(format: "%@%@", string.fw.substring(with: NSMakeRange(2, 6)), string.fw.substring(with: NSMakeRange(0, 2)))
            }
            // RRGGBB|RRGGBBAA
            strR = string.fw.substring(with: NSMakeRange(0, 2))
            strG = string.fw.substring(with: NSMakeRange(2, 2))
            strB = string.fw.substring(with: NSMakeRange(4, 2))
            if length == 8 {
                strA = string.fw.substring(with: NSMakeRange(6, 2))
            }
        }

        // 解析颜色
        var r: UInt64 = 0
        var g: UInt64 = 0
        var b: UInt64 = 0
        Scanner(string: strR).scanHexInt64(&r)
        Scanner(string: strG).scanHexInt64(&g)
        Scanner(string: strB).scanHexInt64(&b)
        let fr = CGFloat(r) / 255.0
        let fg = CGFloat(g) / 255.0
        let fb = CGFloat(b) / 255.0

        // 解析透明度，字符串的透明度优先级高于alpha参数
        var fa: CGFloat = alpha
        if !strA.isEmpty {
            var a: UInt64 = 0
            Scanner(string: strA).scanHexInt64(&a)
            fa = CGFloat(a) / 255.0
        }

        return UIColor(red: fr, green: fg, blue: fb, alpha: fa)
    }

    /// 以指定模式添加混合颜色，默认normal模式
    public func addColor(_ color: UIColor, blendMode: CGBlendMode = .normal) -> UIColor {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        var pixel = [UInt8](repeating: 0, count: 4)
        let context = CGContext(data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: bitmapInfo)
        context?.setFillColor(base.cgColor)
        context?.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        context?.setBlendMode(blendMode)
        context?.setFillColor(color.cgColor)
        context?.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        return UIColor(red: CGFloat(pixel[0]) / 255.0, green: CGFloat(pixel[1]) / 255.0, blue: CGFloat(pixel[2]) / 255.0, alpha: CGFloat(pixel[3]) / 255.0)
    }

    /// 当前颜色修改亮度比率的颜色
    public func brightnessColor(_ ratio: CGFloat) -> UIColor {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        base.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: s, brightness: b * ratio, alpha: a)
    }

    /// 判断当前颜色是否为深色
    public var isDarkColor: Bool {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        if !base.getRed(&r, green: &g, blue: &b, alpha: &a) {
            if base.getWhite(&r, alpha: &a) {
                g = r
                b = r
            }
        }

        let referenceValue: CGFloat = 0.411
        let colorDelta = r * 0.299 + g * 0.587 + b * 0.114
        return 1.0 - colorDelta > referenceValue
    }

    /**
     创建渐变颜色，支持四个方向，默认向下Down

     @param size 渐变尺寸，非渐变边可以设置为1。如CGSizeMake(1, 50)
     @param colors 渐变颜色，CGColor数组，如：@[(__bridge id)[UIColor redColor].CGColor, (__bridge id)[UIColor blueColor].CGColor]
     @param locations 渐变位置，传NULL时均分，如：CGFloat locations[] = {0.0, 1.0};
     @param direction 渐变方向，自动计算startPoint和endPoint，支持四个方向，默认向下Down
     @return 渐变色
     */
    public static func gradientColor(
        size: CGSize,
        colors: [Any],
        locations: UnsafePointer<CGFloat>?,
        direction: UISwipeGestureRecognizer.Direction
    ) -> UIColor {
        let linePoints = UIBezierPath.fw.linePoints(rect: CGRect(x: 0, y: 0, width: size.width, height: size.height), direction: direction)
        let startPoint = linePoints.first?.cgPointValue ?? .zero
        let endPoint = linePoints.last?.cgPointValue ?? .zero
        return gradientColor(size: size, colors: colors, locations: locations, startPoint: startPoint, endPoint: endPoint)
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
    public static func gradientColor(
        size: CGSize,
        colors: [Any],
        locations: UnsafePointer<CGFloat>?,
        startPoint: CGPoint,
        endPoint: CGPoint
    ) -> UIColor {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations)
        if let context, let gradient {
            context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if let image {
            return UIColor(patternImage: image)
        }
        return UIColor.clear
    }
}

// MARK: - Wrapper+UIFont
extension Wrapper where Base: UIFont {
    /// 自定义全局自动等比例缩放适配句柄，默认nil，开启后如需固定大小调用fixed即可
    public static var autoScaleBlock: (@MainActor @Sendable (CGFloat) -> CGFloat)? {
        get { Base.innerAutoScaleBlock }
        set { Base.innerAutoScaleBlock = newValue }
    }

    /// 快捷启用全局自动等比例缩放适配，自动设置默认autoScaleBlock
    public static var autoScaleFont: Bool {
        get {
            Base.innerAutoScaleBlock != nil
        }
        set {
            guard newValue != autoScaleFont else { return }
            Base.innerAutoScaleBlock = newValue ? { @MainActor @Sendable in UIScreen.fw.relativeValue($0, flat: autoFlatFont) } : nil
        }
    }

    /// 是否启用全局自动像素取整字体，默认false
    public static var autoFlatFont: Bool {
        get { Base.innerAutoFlatFont }
        set { Base.innerAutoFlatFont = newValue }
    }

    /// 全局自定义字体句柄，优先调用，返回nil时使用系统字体
    public static var fontBlock: ((CGFloat, UIFont.Weight) -> UIFont?)? {
        get { Base.innerFontBlock }
        set { Base.innerFontBlock = newValue }
    }

    /// 返回系统Thin字体，自动等比例缩放
    @MainActor public static func thinFont(ofSize: CGFloat, autoScale: Bool? = nil) -> UIFont {
        font(ofSize: ofSize, weight: .thin, autoScale: autoScale)
    }

    /// 返回系统Light字体，自动等比例缩放
    @MainActor public static func lightFont(ofSize: CGFloat, autoScale: Bool? = nil) -> UIFont {
        font(ofSize: ofSize, weight: .light, autoScale: autoScale)
    }

    /// 返回系统Medium字体，自动等比例缩放
    @MainActor public static func mediumFont(ofSize: CGFloat, autoScale: Bool? = nil) -> UIFont {
        font(ofSize: ofSize, weight: .medium, autoScale: autoScale)
    }

    /// 返回系统Semibold字体，自动等比例缩放
    @MainActor public static func semiboldFont(ofSize: CGFloat, autoScale: Bool? = nil) -> UIFont {
        font(ofSize: ofSize, weight: .semibold, autoScale: autoScale)
    }

    /// 返回系统Bold字体，自动等比例缩放
    @MainActor public static func boldFont(ofSize: CGFloat, autoScale: Bool? = nil) -> UIFont {
        font(ofSize: ofSize, weight: .bold, autoScale: autoScale)
    }

    /// 创建指定尺寸和weight的系统字体，自动等比例缩放
    @MainActor public static func font(ofSize size: CGFloat, weight: UIFont.Weight = .regular, autoScale: Bool? = nil) -> UIFont {
        var fontSize = size
        if (autoScale == nil && autoScaleFont) || autoScale == true {
            fontSize = autoScaleBlock?(size) ?? UIScreen.fw.relativeValue(size, flat: autoFlatFont)
        }

        return nonScaleFont(ofSize: fontSize, weight: weight)
    }
    
    /// 创建指定尺寸和weight的设备纵向界面系统字体，自动等比例缩放
    public static func portraitFont(ofSize size: CGFloat, weight: UIFont.Weight = .regular, autoScale: Bool? = nil) -> UIFont {
        var fontSize = size
        if (autoScale == nil && autoScaleFont) || autoScale == true {
            fontSize = UIDevice.fw.relativePortrait(size, flat: autoFlatFont)
        }

        return nonScaleFont(ofSize: fontSize, weight: weight)
    }
    
    /// 创建指定尺寸和weight的设备横向界面系统字体，自动等比例缩放
    public static func landscapeFont(ofSize size: CGFloat, weight: UIFont.Weight = .regular, autoScale: Bool? = nil) -> UIFont {
        var fontSize = size
        if (autoScale == nil && autoScaleFont) || autoScale == true {
            fontSize = UIDevice.fw.relativeLandscape(size, flat: autoFlatFont)
        }

        return nonScaleFont(ofSize: fontSize, weight: weight)
    }

    /// 创建指定尺寸和weight的不缩放系统字体
    public static func nonScaleFont(ofSize size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        if let font = fontBlock?(size, weight) { return font }
        return UIFont.systemFont(ofSize: size, weight: weight)
    }

    /// 获取指定名称、字重、斜体字体的完整规范名称
    public static func fontName(_ name: String, weight: UIFont.Weight, italic: Bool = false) -> String {
        var fontName = name
        if let weightSuffix = UIFont.innerWeightSuffixes[weight] {
            fontName += weightSuffix + (italic ? "Italic" : "")
        }
        return fontName
    }

    /// 是否是粗体
    public var isBold: Bool {
        base.fontDescriptor.symbolicTraits.contains(.traitBold)
    }

    /// 是否是斜体
    public var isItalic: Bool {
        base.fontDescriptor.symbolicTraits.contains(.traitItalic)
    }

    /// 当前字体的粗体字体
    public var boldFont: UIFont {
        let symbolicTraits = base.fontDescriptor.symbolicTraits.union(.traitBold)
        return UIFont(descriptor: base.fontDescriptor.withSymbolicTraits(symbolicTraits) ?? base.fontDescriptor, size: base.pointSize)
    }

    /// 当前字体的非粗体字体
    public var nonBoldFont: UIFont {
        var symbolicTraits = base.fontDescriptor.symbolicTraits
        symbolicTraits.remove(.traitBold)
        return UIFont(descriptor: base.fontDescriptor.withSymbolicTraits(symbolicTraits) ?? base.fontDescriptor, size: base.pointSize)
    }

    /// 当前字体的斜体字体
    public var italicFont: UIFont {
        let symbolicTraits = base.fontDescriptor.symbolicTraits.union(.traitItalic)
        return UIFont(descriptor: base.fontDescriptor.withSymbolicTraits(symbolicTraits) ?? base.fontDescriptor, size: base.pointSize)
    }

    /// 当前字体的非斜体字体
    public var nonItalicFont: UIFont {
        var symbolicTraits = base.fontDescriptor.symbolicTraits
        symbolicTraits.remove(.traitItalic)
        return UIFont(descriptor: base.fontDescriptor.withSymbolicTraits(symbolicTraits) ?? base.fontDescriptor, size: base.pointSize)
    }

    /// 字体空白高度(上下之和)
    public var spaceHeight: CGFloat {
        base.lineHeight - base.pointSize
    }

    /// 根据字体计算指定倍数行间距的实际行距值(减去空白高度)，示例：行间距为0.5倍实际高度
    public func lineSpacing(multiplier: CGFloat) -> CGFloat {
        base.pointSize * multiplier - (base.lineHeight - base.pointSize)
    }

    /// 根据字体计算指定倍数行高的实际行高值(减去空白高度)，示例：行高为1.5倍实际高度
    public func lineHeight(multiplier: CGFloat) -> CGFloat {
        base.pointSize * multiplier
    }

    /// 计算指定期望高度下字体的实际行高值，取期望值和行高值的较大值
    public func lineHeight(expected: CGFloat) -> CGFloat {
        max(base.lineHeight, expected)
    }

    /// 计算当前字体与指定字体居中对齐的偏移值
    public func baselineOffset(_ font: UIFont) -> CGFloat {
        (base.lineHeight - font.lineHeight) / 2.0 + (base.descender - font.descender)
    }

    /// 计算当前字体与指定行高居中对齐的偏移值
    public func baselineOffset(lineHeight: CGFloat) -> CGFloat {
        (lineHeight - base.lineHeight) / 4.0
    }
}

// MARK: - Wrapper+UIImage
extension Wrapper where Base: UIImage {
    /// 从当前图片创建指定透明度的图片
    public func image(alpha: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(base.size, false, base.scale)
        base.draw(in: CGRect(x: 0, y: 0, width: base.size.width, height: base.size.height), blendMode: .normal, alpha: alpha)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 从当前UIImage混合颜色创建UIImage，可自定义模式，默认destinationIn
    public func image(tintColor: UIColor, blendMode: CGBlendMode = .destinationIn) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(base.size, false, 0)
        tintColor.setFill()
        let bounds = CGRect(x: 0, y: 0, width: base.size.width, height: base.size.height)
        UIRectFill(bounds)
        base.draw(in: bounds, blendMode: blendMode, alpha: 1.0)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 缩放图片到指定大小
    public func image(scaleSize size: CGSize) -> UIImage? {
        guard size.width > 0, size.height > 0 else { return nil }
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        base.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 缩放图片到指定大小，指定模式
    public func image(scaleSize size: CGSize, contentMode: UIView.ContentMode) -> UIImage? {
        guard size.width > 0, size.height > 0 else { return nil }
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height), contentMode: contentMode, clipsToBounds: false)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 按指定模式绘制图片
    public func draw(in rect: CGRect, contentMode: UIView.ContentMode, clipsToBounds: Bool) {
        let drawRect = drawRect(contentMode: contentMode, rect: rect, size: base.size)
        if drawRect.size.width <= 0 || drawRect.size.height <= 0 { return }
        if clipsToBounds {
            if let context = UIGraphicsGetCurrentContext() {
                context.saveGState()
                context.addRect(rect)
                context.clip()
                base.draw(in: drawRect)
                context.restoreGState()
            }
        } else {
            base.draw(in: drawRect)
        }
    }

    private func drawRect(contentMode: UIView.ContentMode, rect: CGRect, size: CGSize) -> CGRect {
        var rect = CGRectStandardize(rect)
        var size = CGSize(width: size.width < 0 ? -size.width : size.width, height: size.height < 0 ? -size.height : size.height)
        let center = CGPoint(x: CGRectGetMidX(rect), y: CGRectGetMidY(rect))

        switch contentMode {
        case .scaleAspectFit, .scaleAspectFill:
            if rect.size.width < 0.01 || rect.size.height < 0.01 ||
                size.width < 0.01 || size.height < 0.01 {
                rect.origin = center
                rect.size = .zero
            } else {
                var scale: CGFloat = 0
                if contentMode == .scaleAspectFit {
                    if size.width / size.height < rect.size.width / rect.size.height {
                        scale = rect.size.height / size.height
                    } else {
                        scale = rect.size.width / size.width
                    }
                } else {
                    if size.width / size.height < rect.size.width / rect.size.height {
                        scale = rect.size.width / size.width
                    } else {
                        scale = rect.size.height / size.height
                    }
                }
                size.width *= scale
                size.height *= scale
                rect.size = size
                rect.origin = CGPoint(x: center.x - size.width * 0.5, y: center.y - size.height * 0.5)
            }
        case .center:
            rect.size = size
            rect.origin = CGPoint(x: center.x - size.width * 0.5, y: center.y - size.height * 0.5)
        case .top:
            rect.origin.x = center.x - size.width * 0.5
            rect.size = size
        case .bottom:
            rect.origin.x = center.x - size.width * 0.5
            rect.origin.y += rect.size.height - size.height
            rect.size = size
        case .left:
            rect.origin.y = center.y - size.height * 0.5
            rect.size = size
        case .right:
            rect.origin.y = center.y - size.height * 0.5
            rect.origin.x += rect.size.width - size.width
            rect.size = size
        case .topLeft:
            rect.size = size
        case .topRight:
            rect.origin.x += rect.size.width - size.width
            rect.size = size
        case .bottomLeft:
            rect.origin.y += rect.size.height - size.height
            rect.size = size
        case .bottomRight:
            rect.origin.x += rect.size.width - size.width
            rect.origin.y += rect.size.height - size.height
            rect.size = size
        case .scaleToFill, .redraw:
            break
        default:
            break
        }
        return rect
    }

    /// 裁剪指定区域图片
    public func image(cropRect: CGRect) -> UIImage? {
        var rect = cropRect
        rect.origin.x *= base.scale
        rect.origin.y *= base.scale
        rect.size.width *= base.scale
        rect.size.height *= base.scale
        guard rect.width > 0, rect.height > 0 else { return nil }

        guard let imageRef = base.cgImage?.cropping(to: rect) else { return nil }
        let image = UIImage(cgImage: imageRef, scale: base.scale, orientation: base.imageOrientation)
        return image
    }

    /// 指定颜色填充图片边缘
    public func image(insets: UIEdgeInsets, color: UIColor? = nil) -> UIImage? {
        guard insets != .zero else { return base }

        var size = base.size
        size.width -= insets.left + insets.right
        size.height -= insets.top + insets.bottom
        if size.width <= 0 || size.height <= 0 { return nil }
        let rect = CGRect(x: -insets.left, y: -insets.top, width: base.size.width, height: base.size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        if let color, let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(color.cgColor)
            let path = CGMutablePath()
            path.addRect(CGRect(x: 0, y: 0, width: size.width, height: size.height))
            path.addRect(rect)
            context.addPath(path)
            context.fillPath(using: .evenOdd)
        }
        base.draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 拉伸图片(平铺模式)，指定端盖区域（不拉伸区域）
    public func image(capInsets: UIEdgeInsets) -> UIImage {
        base.resizableImage(withCapInsets: capInsets)
    }

    /// 拉伸图片(指定模式)，指定端盖区域（不拉伸区域）。Tile为平铺模式，Stretch为拉伸模式
    public func image(capInsets: UIEdgeInsets, resizingMode: UIImage.ResizingMode) -> UIImage {
        base.resizableImage(withCapInsets: capInsets, resizingMode: resizingMode)
    }

    /// 生成圆角图片
    public func image(cornerRadius: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(base.size, false, 0)
        let rect = CGRect(x: 0, y: 0, width: base.size.width, height: base.size.height)
        UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
        base.draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 按角度常数(0~360)转动图片，指定图片尺寸是否延伸来适应内容，否则图片尺寸不变，内容被裁剪，默认true
    public func image(rotateDegree: CGFloat, fitSize: Bool = true) -> UIImage? {
        let radians = rotateDegree * .pi / 180.0
        let width = base.cgImage?.width ?? .zero
        let height = base.cgImage?.height ?? .zero
        let newRect = CGRectApplyAffineTransform(CGRect(x: 0, y: 0, width: width, height: height), fitSize ? CGAffineTransformMakeRotation(radians) : .identity)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: Int(newRect.size.width),
            height: Int(newRect.size.height),
            bitsPerComponent: 8,
            bytesPerRow: Int(newRect.size.width) * 4,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo.byteOrderDefault.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else { return nil }

        context.setShouldAntialias(true)
        context.setAllowsAntialiasing(true)
        context.interpolationQuality = .high
        context.translateBy(x: newRect.size.width * 0.5, y: newRect.size.height * 0.5)
        context.rotate(by: radians)

        guard let cgImage = base.cgImage else { return nil }
        context.draw(cgImage, in: CGRect(x: -(CGFloat(width) * 0.5), y: -(CGFloat(height) * 0.5), width: CGFloat(width), height: CGFloat(height)))
        guard let imageRef = context.makeImage() else { return nil }
        let image = UIImage(cgImage: imageRef, scale: base.scale, orientation: base.imageOrientation)
        return image
    }

    /// 生成mark图片
    public func image(maskImage: UIImage) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(base.size, false, 0)
        if let context = UIGraphicsGetCurrentContext(), let mask = maskImage.cgImage {
            context.clip(to: CGRect(x: 0, y: 0, width: base.size.width, height: base.size.height), mask: mask)
        }
        base.draw(at: .zero)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 图片合并，并制定叠加图片的起始位置
    public func image(mergeImage: UIImage, atPoint: CGPoint) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(base.size, false, 0)
        base.draw(in: CGRect(x: 0, y: 0, width: base.size.width, height: base.size.height))
        mergeImage.draw(at: atPoint)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 图片应用CIFilter滤镜处理
    public func image(filter: CIFilter) -> UIImage? {
        var inputImage: CIImage?
        if let ciImage = base.ciImage {
            inputImage = ciImage
        } else {
            guard let imageRef = base.cgImage else { return nil }
            inputImage = CIImage(cgImage: imageRef)
        }
        guard let inputImage else { return nil }

        let context = CIContext()
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        guard let outputImage = filter.outputImage else { return nil }

        guard let imageRef = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        let image = UIImage(cgImage: imageRef, scale: base.scale, orientation: base.imageOrientation)
        return image
    }

    /// 图片应用高斯模糊滤镜处理
    public func gaussianBlurImage(fuzzyValue: CGFloat = 10) -> UIImage? {
        filteredImage(fuzzyValue: fuzzyValue, filterName: "CIGaussianBlur")
    }

    /// 图片应用像素化滤镜处理
    public func pixellateImage(fuzzyValue: CGFloat = 10) -> UIImage? {
        filteredImage(fuzzyValue: fuzzyValue, filterName: "CIPixellate")
    }

    private func filteredImage(fuzzyValue: CGFloat, filterName: String) -> UIImage? {
        guard let ciImage = CIImage(image: base) else { return nil }
        guard let blurFilter = CIFilter(name: filterName) else { return nil }
        blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
        blurFilter.setValue(fuzzyValue, forKey: filterName == "CIPixellate" ? kCIInputScaleKey : kCIInputRadiusKey)
        guard let outputImage = blurFilter.outputImage else { return nil }
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    /// 压缩图片到指定字节，图片太大时会改为JPG格式。不保证图片大小一定小于该大小
    public func compressImage(maxLength: Int, compressRatio: CGFloat = 0) -> UIImage? {
        guard let data = compressData(maxLength: maxLength, compressRatio: compressRatio) else { return nil }
        return UIImage(data: data)
    }

    /// 压缩图片到指定字节，图片太大时会改为JPG格式，可设置递减压缩率，默认0.3。不保证图片大小一定小于该大小
    public func compressData(maxLength: Int, compressRatio: CGFloat = 0) -> Data? {
        var compress: CGFloat = 1.0
        let stepCompress: CGFloat = compressRatio > 0 ? compressRatio : 0.3
        var data = hasAlpha ? base.pngData() : base.jpegData(compressionQuality: compress)
        while (data?.count ?? 0) > maxLength && compress > stepCompress {
            compress -= stepCompress
            data = base.jpegData(compressionQuality: compress)
        }
        return data
    }

    /// 长边压缩图片尺寸，获取等比例的图片
    public func compressImage(maxWidth: CGFloat) -> UIImage? {
        let newSize = scaleSize(maxWidth: maxWidth)
        if newSize.equalTo(base.size) { return base }

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        base.draw(in: CGRect(origin: .zero, size: newSize))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 通过指定图片最长边，获取等比例的图片size
    public func scaleSize(maxWidth: CGFloat) -> CGSize {
        if maxWidth <= 0 { return base.size }

        let width = base.size.width
        let height = base.size.height
        if width > maxWidth || height > maxWidth {
            var newWidth: CGFloat = 0
            var newHeight: CGFloat = 0
            if width > height {
                newWidth = maxWidth
                newHeight = newWidth * height / width
            } else if height > width {
                newHeight = maxWidth
                newWidth = newHeight * width / height
            } else {
                newWidth = maxWidth
                newHeight = maxWidth
            }
            return CGSize(width: newWidth, height: newHeight)
        } else {
            return CGSize(width: width, height: height)
        }
    }

    /// 后台线程压缩图片，完成后主线程回调
    public static func compressImages(_ images: [UIImage], maxWidth: CGFloat, maxLength: Int, compressRatio: CGFloat = 0, completion: @escaping @MainActor @Sendable ([UIImage]) -> Void) {
        DispatchQueue.global().async {
            let compressImages = images.compactMap { image in
                image
                    .fw.compressImage(maxWidth: maxWidth)?
                    .fw.compressImage(maxLength: maxLength, compressRatio: compressRatio)
            }

            DispatchQueue.main.async {
                completion(compressImages)
            }
        }
    }

    /// 后台线程压缩图片数据，完成后主线程回调
    public static func compressDatas(_ images: [UIImage], maxWidth: CGFloat, maxLength: Int, compressRatio: CGFloat = 0, completion: @escaping @MainActor @Sendable ([Data]) -> Void) {
        DispatchQueue.global().async {
            let compressDatas = images.compactMap { image in
                image
                    .fw.compressImage(maxWidth: maxWidth)?
                    .fw.compressData(maxLength: maxLength, compressRatio: compressRatio)
            }

            DispatchQueue.main.async {
                completion(compressDatas)
            }
        }
    }

    /// 获取原始渲染模式图片，始终显示原色，不显示tintColor。默认自动根据上下文
    public var originalImage: UIImage {
        base.withRenderingMode(.alwaysOriginal)
    }

    /// 获取模板渲染模式图片，始终显示tintColor，不显示原色。默认自动根据上下文
    public var templateImage: UIImage {
        base.withRenderingMode(.alwaysTemplate)
    }

    /// 判断图片是否有透明通道
    public var hasAlpha: Bool {
        guard let cgImage = base.cgImage else { return false }
        let alpha = cgImage.alphaInfo
        return alpha == .first || alpha == .last ||
            alpha == .premultipliedFirst || alpha == .premultipliedLast
    }

    /// 获取当前图片的像素大小，多倍图会放大到一倍
    public var pixelSize: CGSize {
        CGSize(width: base.size.width * base.scale, height: base.size.height * base.scale)
    }

    /// 从视图创建UIImage，生成截图，主线程调用
    @MainActor public static func image(view: UIView) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
        if view.window != nil {
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        } else if let context = UIGraphicsGetCurrentContext() {
            view.layer.render(in: context)
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 从颜色创建UIImage，尺寸默认1x1
    public static func image(color: UIColor?) -> UIImage? {
        image(color: color, size: CGSize(width: 1.0, height: 1.0))
    }

    /// 从颜色创建UIImage，可指定尺寸和圆角，默认圆角0
    public static func image(color: UIColor?, size: CGSize, cornerRadius: CGFloat = 0) -> UIImage? {
        guard let color, size.width > 0, size.height > 0 else { return nil }

        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.setFillColor(color.cgColor)
        if cornerRadius > 0 {
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            path.addClip()
            path.fill()
        } else {
            context.fill(rect)
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 从block创建UIImage，指定尺寸
    public static func image(size: CGSize, block: (CGContext) -> Void) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        block(context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 保存图片到相册，保存成功时error为nil
    public func saveImage(completion: ((Error?) -> Void)? = nil) {
        setPropertyCopy(completion, forName: "saveImage")
        UIImageWriteToSavedPhotosAlbum(base, base, #selector(UIImage.innerSaveImage(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    /// 保存视频到相册，保存成功时error为nil。如果视频地址为NSURL，需使用NSURL.path
    public static func saveVideo(_ videoPath: String, completion: ((Error?) -> Void)? = nil) {
        NSObject.fw.setAssociatedObject(UIImage.self, key: "saveVideo", value: completion, policy: .OBJC_ASSOCIATION_COPY_NONATOMIC)
        if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoPath) {
            UISaveVideoAtPathToSavedPhotosAlbum(videoPath, UIImage.self, #selector(UIImage.innerSaveVideo(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }

    /// 获取灰度图
    public var grayImage: UIImage? {
        let width = Int(base.size.width)
        let height = Int(base.size.height)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue),
              let cgImage = base.cgImage else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let imageRef = context.makeImage() else { return nil }
        return UIImage(cgImage: imageRef)
    }

    /// 获取图片的平均颜色
    public var averageColor: UIColor? {
        guard let ciImage = base.ciImage ?? CIImage(image: base) else { return nil }

        let parameters = [kCIInputImageKey: ciImage, kCIInputExtentKey: CIVector(cgRect: ciImage.extent)]
        guard let outputImage = CIFilter(name: "CIAreaAverage", parameters: parameters)?.outputImage else {
            return nil
        }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let workingColorSpace: Any = base.cgImage?.colorSpace ?? NSNull()
        let context = CIContext(options: [.workingColorSpace: workingColorSpace])
        context.render(outputImage,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255.0,
                       green: CGFloat(bitmap[1]) / 255.0,
                       blue: CGFloat(bitmap[2]) / 255.0,
                       alpha: CGFloat(bitmap[3]) / 255.0)
    }

    /// 倒影图片
    public func image(reflectScale: CGFloat) -> UIImage? {
        var sharedMask: CGImage?
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 1, height: 256), true, 0)
        if let gradientContext = UIGraphicsGetCurrentContext() {
            var colors: [CGFloat] = [0, 1, 1, 1]
            let colorSpace = CGColorSpaceCreateDeviceGray()
            if let gradient = CGGradient(colorSpace: colorSpace, colorComponents: &colors, locations: nil, count: 2) {
                let gradientStartPoint = CGPoint(x: 0, y: 0)
                let gradientEndPoint = CGPoint(x: 0, y: 256)
                gradientContext.drawLinearGradient(gradient, start: gradientStartPoint, end: gradientEndPoint, options: .drawsAfterEndLocation)
            }
            sharedMask = gradientContext.makeImage()
            UIGraphicsEndImageContext()
        }

        let height = ceil(base.size.height * reflectScale)
        let size = CGSize(width: base.size.width, height: height)
        let bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        if let sharedMask {
            context?.clip(to: bounds, mask: sharedMask)
        }
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.translateBy(x: 0, y: -base.size.height)
        base.draw(in: CGRect(x: 0, y: 0, width: base.size.width, height: base.size.height))

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 倒影图片
    public func image(reflectScale: CGFloat, gap: CGFloat, alpha: CGFloat) -> UIImage? {
        let reflection = image(reflectScale: reflectScale)
        let reflectionOffset = (reflection?.size.height ?? 0) + gap
        UIGraphicsBeginImageContextWithOptions(CGSize(width: base.size.width, height: base.size.height + reflectionOffset * 2.0), false, 0)
        reflection?.draw(at: CGPoint(x: 0, y: reflectionOffset + base.size.height + gap), blendMode: .normal, alpha: alpha)
        base.draw(at: CGPoint(x: 0, y: reflectionOffset))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 阴影图片
    public func image(shadowColor: UIColor, offset: CGSize, blur: CGFloat) -> UIImage? {
        let border = CGSize(width: abs(offset.width) + blur, height: abs(offset.height) + blur)
        let size = CGSize(width: base.size.width + border.width * 2.0, height: base.size.height + border.height * 2.0)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        context?.setShadow(offset: offset, blur: blur, color: shadowColor.cgColor)
        base.draw(at: CGPoint(x: border.width, y: border.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 高斯模糊图片，默认模糊半径为10
    public func blurredImage(radius: CGFloat = 10) -> UIImage? {
        guard let cgImage = base.cgImage else {
            return base
        }

        let s = max(radius, 2.0)
        let pi2 = 2 * CGFloat.pi
        let sqrtPi2 = sqrt(pi2)
        var targetRadius = floor(s * 3.0 * sqrtPi2 / 4.0 + 0.5)
        if targetRadius.truncatingRemainder(dividingBy: 2.0) == 0 { targetRadius += 1 }

        let iterations: Int
        if radius < 0.5 {
            iterations = 1
        } else if radius < 1.5 {
            iterations = 2
        } else {
            iterations = 3
        }

        let size = base.size
        let w = Int(size.width)
        let h = Int(size.height)

        func createEffectBuffer(_ context: CGContext) -> vImage_Buffer {
            let data = context.data
            let width = vImagePixelCount(context.width)
            let height = vImagePixelCount(context.height)
            let rowBytes = context.bytesPerRow

            return vImage_Buffer(data: data, height: height, width: width, rowBytes: rowBytes)
        }

        UIGraphicsBeginImageContextWithOptions(size, false, base.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return base
        }
        context.scaleBy(x: 1.0, y: -1.0)
        context.translateBy(x: 0, y: -size.height)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
        UIGraphicsEndImageContext()
        var inBuffer = createEffectBuffer(context)

        UIGraphicsBeginImageContextWithOptions(size, false, base.scale)
        guard let outContext = UIGraphicsGetCurrentContext() else {
            return base
        }
        outContext.scaleBy(x: 1.0, y: -1.0)
        outContext.translateBy(x: 0, y: -size.height)
        defer { UIGraphicsEndImageContext() }
        var outBuffer = createEffectBuffer(outContext)

        for _ in 0..<iterations {
            let flag = vImage_Flags(kvImageEdgeExtend)
            vImageBoxConvolve_ARGB8888(
                &inBuffer, &outBuffer, nil, 0, 0, UInt32(targetRadius), UInt32(targetRadius), nil, flag
            )
            (inBuffer, outBuffer) = (outBuffer, inBuffer)
        }

        let result = outContext.makeImage().flatMap {
            UIImage(cgImage: $0, scale: base.scale, orientation: base.imageOrientation)
        }
        guard let blurredImage = result else {
            return base
        }
        return blurredImage
    }

    /// 图片裁剪，可指定frame、角度、圆形等
    @MainActor public func croppedImage(frame: CGRect, angle: Int, circular: Bool) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(frame.size, !hasAlpha && !circular, base.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        if circular {
            context.addEllipse(in: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
            context.clip()
        }

        if angle != 0 {
            let imageView = UIImageView(image: base)
            imageView.layer.minificationFilter = .nearest
            imageView.layer.magnificationFilter = .nearest
            imageView.transform = CGAffineTransformRotate(.identity, CGFloat(angle) * (CGFloat.pi / 180.0))
            let rotatedRect = CGRectApplyAffineTransform(imageView.bounds, imageView.transform)
            let containerView = UIView(frame: CGRect(x: 0, y: 0, width: rotatedRect.size.width, height: rotatedRect.size.height))
            containerView.addSubview(imageView)
            imageView.center = containerView.center
            context.translateBy(x: -frame.origin.x, y: -frame.origin.y)
            containerView.layer.render(in: context)
        } else {
            context.translateBy(x: -frame.origin.x, y: -frame.origin.y)
            base.draw(at: .zero)
        }

        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let cgImage = croppedImage?.cgImage else { return nil }
        return UIImage(cgImage: cgImage, scale: base.scale, orientation: .up)
    }

    /// 如果没有透明通道，增加透明通道
    public var alphaImage: UIImage {
        guard !hasAlpha,
              let imageRef = base.cgImage,
              let colorSpace = imageRef.colorSpace else { return base }

        let width = imageRef.width
        let height = imageRef.height
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGBitmapInfo.byteOrderDefault.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        context?.draw(imageRef, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let alphaImageRef = context?.makeImage() else { return base }
        let alphaImage = UIImage(cgImage: alphaImageRef)
        return alphaImage
    }

    /// 截取View所有视图，包括旋转缩放效果
    @MainActor public static func image(view: UIView, limitWidth: CGFloat) -> UIImage? {
        let oldTransform = view.transform
        var scaleTransform = CGAffineTransform.identity
        if !limitWidth.isNaN && limitWidth > 0 && CGRectGetWidth(view.frame) > 0 {
            let maxScale = limitWidth / CGRectGetWidth(view.frame)
            let transformScale = CGAffineTransform(scaleX: maxScale, y: maxScale)
            scaleTransform = CGAffineTransformConcat(oldTransform, transformScale)
        }
        if scaleTransform != .identity {
            view.transform = scaleTransform
        }

        let actureFrame = view.frame
        let actureBounds = view.bounds
        UIGraphicsBeginImageContextWithOptions(actureFrame.size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        context?.translateBy(x: actureFrame.size.width / 2.0, y: actureFrame.size.height / 2.0)
        context?.concatenate(view.transform)
        let anchorPoint = view.layer.anchorPoint
        context?.translateBy(x: -actureBounds.size.width * anchorPoint.x, y: -actureBounds.size.height * anchorPoint.y)
        if view.window != nil {
            // iOS7+：更新屏幕后再截图，防止刚添加还未显示时截图失败，效率高
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        } else if let context = UIGraphicsGetCurrentContext() {
            // iOS6+：截取当前状态，未添加到界面时也可截图，效率偏低
            view.layer.render(in: context)
        }

        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        view.transform = oldTransform
        return screenshot
    }

    /// 获取AppIcon图片
    public static func appIconImage() -> UIImage? {
        let infoPlist = Bundle.main.infoDictionary as? NSDictionary
        let iconFiles = infoPlist?.value(forKeyPath: "CFBundleIcons.CFBundlePrimaryIcon.CFBundleIconFiles") as? NSArray
        guard let iconName = iconFiles?.lastObject as? String else { return nil }
        return UIImage(named: iconName)
    }

    /// 获取AppIcon指定尺寸图片，名称格式：AppIcon60x60
    public static func appIconImage(size: CGSize) -> UIImage? {
        let iconName = String(format: "AppIcon%.0fx%.0f", size.width, size.height)
        return UIImage(named: iconName)
    }

    /// 从Pdf数据或者路径创建指定大小UIImage
    public static func image(pdf path: Any, size: CGSize = .zero) -> UIImage? {
        var pdf: CGPDFDocument?
        if let data = path as? Data {
            if let provider = CGDataProvider(data: data as CFData) {
                pdf = CGPDFDocument(provider)
            }
        } else if let path = path as? String {
            pdf = CGPDFDocument(URL(fileURLWithPath: path) as CFURL)
        }
        guard let pdf else { return nil }
        guard let page = pdf.page(at: 1) else { return nil }

        let pdfRect = page.getBoxRect(.cropBox)
        let pdfSize = size.equalTo(.zero) ? pdfRect.size : size
        let scale = UIScreen.fw.screenScale
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: nil, width: Int(pdfSize.width * scale), height: Int(pdfSize.height * scale), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGBitmapInfo.byteOrderDefault.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) else { return nil }

        context.scaleBy(x: scale, y: scale)
        context.translateBy(x: -pdfRect.origin.x, y: -pdfRect.origin.y)
        context.drawPDFPage(page)

        guard let imageRef = context.makeImage() else { return nil }
        let image = UIImage(cgImage: imageRef, scale: scale, orientation: .up)
        return image
    }

    /**
     创建渐变颜色UIImage，支持四个方向，默认向下Down

     @param size 图片大小
     @param colors 渐变颜色，CGColor数组，如：@[(__bridge id)[UIColor redColor].CGColor, (__bridge id)[UIColor blueColor].CGColor]
     @param locations 渐变位置，传NULL时均分，如：CGFloat locations[] = {0.0, 1.0};
     @param direction 渐变方向，自动计算startPoint和endPoint，支持四个方向，默认向下Down
     @return 渐变颜色UIImage
     */
    public static func gradientImage(
        size: CGSize,
        colors: [Any],
        locations: UnsafePointer<CGFloat>?,
        direction: UISwipeGestureRecognizer.Direction
    ) -> UIImage? {
        let linePoints = UIBezierPath.fw.linePoints(rect: CGRect(x: 0, y: 0, width: size.width, height: size.height), direction: direction)
        let startPoint = linePoints.first?.cgPointValue ?? .zero
        let endPoint = linePoints.last?.cgPointValue ?? .zero
        return gradientImage(size: size, colors: colors, locations: locations, startPoint: startPoint, endPoint: endPoint)
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
    public static func gradientImage(
        size: CGSize,
        colors: [Any],
        locations: UnsafePointer<CGFloat>?,
        startPoint: CGPoint,
        endPoint: CGPoint
    ) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        context.addRect(rect)
        context.clip()
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations) {
            context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
        }

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

// MARK: - Wrapper+UIView
@MainActor extension Wrapper where Base: UIView {
    /// 顶部纵坐标，frame.origin.y
    public var top: CGFloat {
        get {
            base.frame.origin.y
        }
        set {
            var frame = base.frame
            frame.origin.y = newValue
            base.frame = frame
        }
    }

    /// 底部纵坐标，frame.origin.y + frame.size.height
    public var bottom: CGFloat {
        get { top + height }
        set { top = newValue - height }
    }

    /// 左边横坐标，frame.origin.x
    public var left: CGFloat {
        get {
            base.frame.origin.x
        }
        set {
            var frame = base.frame
            frame.origin.x = newValue
            base.frame = frame
        }
    }

    /// 右边横坐标，frame.origin.x + frame.size.width
    public var right: CGFloat {
        get { left + width }
        set { left = newValue - width }
    }

    /// 宽度，frame.size.width
    public var width: CGFloat {
        get {
            base.frame.size.width
        }
        set {
            var frame = base.frame
            frame.size.width = newValue
            base.frame = frame
        }
    }

    /// 高度，frame.size.height
    public var height: CGFloat {
        get {
            base.frame.size.height
        }
        set {
            var frame = base.frame
            frame.size.height = newValue
            base.frame = frame
        }
    }

    /// 中心横坐标，center.x
    public var centerX: CGFloat {
        get { base.center.x }
        set { base.center = CGPoint(x: newValue, y: base.center.y) }
    }

    /// 中心纵坐标，center.y
    public var centerY: CGFloat {
        get { base.center.y }
        set { base.center = CGPoint(x: base.center.x, y: newValue) }
    }

    /// 起始横坐标，frame.origin.x
    public var x: CGFloat {
        get {
            base.frame.origin.x
        }
        set {
            var frame = base.frame
            frame.origin.x = newValue
            base.frame = frame
        }
    }

    /// 起始纵坐标，frame.origin.y
    public var y: CGFloat {
        get {
            base.frame.origin.y
        }
        set {
            var frame = base.frame
            frame.origin.y = newValue
            base.frame = frame
        }
    }

    /// 起始坐标，frame.origin
    public var origin: CGPoint {
        get {
            base.frame.origin
        }
        set {
            var frame = base.frame
            frame.origin = newValue
            base.frame = frame
        }
    }

    /// 大小，frame.size
    public var size: CGSize {
        get {
            base.frame.size
        }
        set {
            var frame = base.frame
            frame.size = newValue
            base.frame = frame
        }
    }
}

// MARK: - Wrapper+UIViewController
extension Wrapper where Base: UIViewController {
    /// 当前生命周期状态，需实现ViewControllerLifecycleObservable或手动添加监听后才有值，默认nil
    public var lifecycleState: ViewControllerLifecycleState? {
        get {
            guard issetLifecycleStateTarget else { return nil }
            return lifecycleStateTarget.state
        }
        set {
            guard let newValue else { return }
            lifecycleStateTarget.state = newValue
        }
    }

    /// 添加生命周期变化监听句柄(注意deinit不能访问runtime关联属性)，返回监听者observer
    @discardableResult
    public func observeLifecycleState(_ block: @escaping (Base, ViewControllerLifecycleState) -> Void) -> NSObjectProtocol {
        let target = LifecycleStateHandler()
        target.object = nil
        target.block = { viewController, state, _ in
            block(viewController as! Base, state)
        }
        lifecycleStateTarget.handlers.append(target)
        return target
    }

    /// 添加生命周期变化监听句柄，并携带自定义参数(注意deinit不能访问runtime关联属性)，返回监听者observer
    @discardableResult
    public func observeLifecycleState<T>(object: T, block: @escaping (Base, ViewControllerLifecycleState, T) -> Void) -> NSObjectProtocol {
        let target = LifecycleStateHandler()
        target.object = object
        target.block = { viewController, state, object in
            block(viewController as! Base, state, object as! T)
        }
        lifecycleStateTarget.handlers.append(target)
        return target
    }

    /// 移除生命周期监听者，传nil时移除所有
    @discardableResult
    public func unobserveLifecycleState(observer: Any? = nil) -> Bool {
        guard issetLifecycleStateTarget else { return false }

        if let observer = observer as? LifecycleStateHandler {
            let result = lifecycleStateTarget.handlers.contains(observer)
            lifecycleStateTarget.handlers.removeAll { $0 == observer }
            return result
        } else {
            lifecycleStateTarget.handlers.removeAll()
            return true
        }
    }

    /// 自定义完成结果对象，默认nil
    public var completionResult: Any? {
        get {
            guard issetLifecycleStateTarget else { return nil }
            return lifecycleStateTarget.completionResult
        }
        set {
            lifecycleStateTarget.completionResult = newValue
        }
    }

    /// 自定义完成句柄，默认nil，dealloc时自动调用，参数为completionResult。支持提前调用，调用后需置为nil
    public var completionHandler: ((Any?) -> Void)? {
        get {
            guard issetLifecycleStateTarget else { return nil }
            return lifecycleStateTarget.completionHandler
        }
        set {
            lifecycleStateTarget.completionHandler = newValue
        }
    }

    private var issetLifecycleStateTarget: Bool {
        property(forName: "lifecycleStateTarget") != nil
    }

    private var lifecycleStateTarget: LifecycleStateTarget {
        if let target = property(forName: "lifecycleStateTarget") as? LifecycleStateTarget {
            return target
        }

        let target = LifecycleStateTarget()
        target.viewController = base
        setProperty(target, forName: "lifecycleStateTarget")
        return target
    }

    /// 自定义侧滑返回手势VC开关句柄，enablePopProxy启用后生效，仅处理边缘返回手势，优先级低，默认nil
    public var allowsPopGesture: (() -> Bool)? {
        get { property(forName: "allowsPopGesture") as? () -> Bool }
        set { setPropertyCopy(newValue, forName: "allowsPopGesture") }
    }

    /// 自定义控制器返回VC开关句柄，enablePopProxy启用后生效，统一处理返回按钮点击和边缘返回手势，优先级高，默认nil
    public var shouldPopController: (() -> Bool)? {
        get { property(forName: "shouldPopController") as? () -> Bool }
        set { setPropertyCopy(newValue, forName: "shouldPopController") }
    }
}

// MARK: - Wrapper+UINavigationController
/// 当自定义left按钮或隐藏导航栏之后，系统返回手势默认失效，可调用此方法全局开启返回代理。开启后自动将开关代理给顶部VC的shouldPopController、popGestureEnabled属性控制。interactivePop手势禁用时不生效
@MainActor extension Wrapper where Base: UINavigationController {
    /// 单独启用返回代理拦截，优先级高于+enablePopProxy，启用后支持shouldPopController、allowsPopGesture功能，默认NO未启用
    public func enablePopProxy() {
        base.interactivePopGestureRecognizer?.delegate = popProxyTarget
        setPropertyBool(true, forName: "popProxyEnabled")
        FrameworkAutoloader.swizzleToolkitNavigationController()
    }

    /// 全局启用返回代理拦截，优先级低于-enablePopProxy，启用后支持shouldPopController、allowsPopGesture功能，默认NO未启用
    public static func enablePopProxy() {
        UINavigationController.innerPopProxyEnabled = true
        UINavigationController.innerChildProxyEnabled = true
        FrameworkAutoloader.swizzleToolkitNavigationController()
    }

    /// 是否全局启用child状态栏样式代理，enablePopProxy时自动启用，默认false
    public static var childProxyEnabled: Bool {
        get {
            UINavigationController.innerChildProxyEnabled
        }
        set {
            UINavigationController.innerChildProxyEnabled = newValue
            FrameworkAutoloader.swizzleToolkitNavigationController()
        }
    }

    fileprivate var popProxyEnabled: Bool {
        propertyBool(forName: "popProxyEnabled")
    }

    private var popProxyTarget: PopProxyTarget {
        if let proxy = property(forName: "popProxyTarget") as? PopProxyTarget {
            return proxy
        } else {
            let proxy = PopProxyTarget(navigationController: base)
            setProperty(proxy, forName: "popProxyTarget")
            return proxy
        }
    }

    fileprivate var delegateProxy: GestureRecognizerDelegateProxy {
        if let proxy = property(forName: "delegateProxy") as? GestureRecognizerDelegateProxy {
            return proxy
        } else {
            let proxy = GestureRecognizerDelegateProxy()
            setProperty(proxy, forName: "delegateProxy")
            return proxy
        }
    }
}

// MARK: - UIViewController+Toolkit
@objc extension UIViewController {
    /// 自定义侧滑返回手势VC开关，enablePopProxy启用后生效，仅处理边缘返回手势，优先级低，自动调用fw.allowsPopGesture，默认true
    open var allowsPopGesture: Bool {
        if let block = fw.allowsPopGesture {
            return block()
        }
        return true
    }

    /// 自定义控制器返回VC开关，enablePopProxy启用后生效，统一处理返回按钮点击和边缘返回手势，优先级高，自动调用fw.shouldPopController，默认true
    open var shouldPopController: Bool {
        if let block = fw.shouldPopController {
            return block()
        }
        return true
    }
}

// MARK: - UIApplication+Toolkit
extension UIApplication {
    fileprivate nonisolated(unsafe) static var innerAppVersion: String?
}

// MARK: - UIColor+Toolkit
extension UIColor {
    fileprivate nonisolated(unsafe) static var innerColorStandardARGB = false
}

// MARK: - UIFont+Toolkit
extension UIFont {
    fileprivate nonisolated(unsafe) static var innerAutoScaleBlock: (@MainActor @Sendable (CGFloat) -> CGFloat)?
    fileprivate nonisolated(unsafe) static var innerAutoFlatFont = false
    fileprivate nonisolated(unsafe) static var innerFontBlock: ((CGFloat, UIFont.Weight) -> UIFont?)?
    fileprivate static let innerWeightSuffixes: [UIFont.Weight: String] = [
        .ultraLight: "-Ultralight",
        .thin: "-Thin",
        .light: "-Light",
        .regular: "-Regular",
        .medium: "-Medium",
        .semibold: "-Semibold",
        .bold: "-Bold",
        .heavy: "-Heavy",
        .black: "-Black"
    ]
}

// MARK: - UIImage+Toolkit
extension UIImage {
    @objc fileprivate func innerSaveImage(_ image: UIImage?, didFinishSavingWithError error: Error?, contextInfo: Any?) {
        let block = fw.property(forName: "saveImage") as? (Error?) -> Void
        fw.setPropertyCopy(nil, forName: "saveImage")
        block?(error)
    }

    @objc fileprivate static func innerSaveVideo(_ videoPath: String?, didFinishSavingWithError error: Error?, contextInfo: Any?) {
        let block = NSObject.fw.getAssociatedObject(UIImage.self, key: "saveVideo") as? (Error?) -> Void
        NSObject.fw.setAssociatedObject(UIImage.self, key: "saveVideo", value: nil, policy: .OBJC_ASSOCIATION_COPY_NONATOMIC)
        block?(error)
    }
}

// MARK: - UINavigationController+Toolkit
extension UINavigationController {
    fileprivate static var innerPopProxyEnabled = false
    fileprivate static var innerChildProxyEnabled = false
}

// MARK: - ViewState
/// 视图状态枚举，兼容UIKit和SwiftUI
public enum ViewState: Equatable {
    case ready
    case loading
    case success(Any? = nil)
    case failure(Error? = nil)

    /// 获取成功状态的对象，其他状态返回nil
    public var object: Any? {
        if case let .success(object) = self {
            return object
        }
        return nil
    }

    /// 获取失败状态的错误，其他状态返回nil
    public var error: Error? {
        if case let .failure(error) = self {
            return error
        }
        return nil
    }

    /// 实现Equatable协议方法，仅比较状态，不比较值
    public static func ==(lhs: ViewState, rhs: ViewState) -> Bool {
        switch lhs {
        case .ready:
            if case .ready = rhs { return true }
        case .loading:
            if case .loading = rhs { return true }
        case .success:
            if case .success = rhs { return true }
        case .failure:
            if case .failure = rhs { return true }
        }
        return false
    }
}

// MARK: - ViewControllerLifecycleObservable
/// 视图控制器生命周期监听协议
public protocol ViewControllerLifecycleObservable {}

// MARK: - ViewControllerLifecycleState
/// 视图控制器常用生命周期状态枚举
///
/// 注意：didDeinit时请勿使用runtime关联属性(可能已被释放)，请使用object参数
public enum ViewControllerLifecycleState: Int, Sendable {
    case didInit = 0
    case didLoad = 1
    case willAppear = 2
    case isAppearing = 3
    case didAppear = 4
    case willDisappear = 5
    case didDisappear = 6
    /// didDeinit时请勿使用runtime关联属性(可能已被释放)，请使用object参数
    case didDeinit = 7
}

// MARK: - TitleViewProtocol
/// 自定义titleView协议
@MainActor @objc public protocol TitleViewProtocol {
    /// 当前标题文字，自动兼容VC.title和navigationItem.title调用
    var title: String? { get set }
}

// MARK: - LifecycleStateTarget
private class LifecycleStateTarget {
    unowned(unsafe) var viewController: UIViewController?
    var handlers: [LifecycleStateHandler] = []
    var completionResult: Any?
    var completionHandler: ((Any?) -> Void)?
    var state: ViewControllerLifecycleState = .didInit {
        didSet { stateChanged(from: oldValue, to: state) }
    }

    deinit {
        // 注意deinit不会触发属性的didSet，需手工调用stateChanged
        let oldState = state
        state = .didDeinit
        stateChanged(from: oldState, to: state)

        if completionHandler != nil {
            completionHandler?(completionResult)
        }

        #if DEBUG
        if let viewController {
            Logger.debug(group: Logger.fw.moduleName, "%@ deinit", NSStringFromClass(type(of: viewController)))
        }
        #endif
    }

    private func stateChanged(from oldState: ViewControllerLifecycleState, to newState: ViewControllerLifecycleState) {
        if let viewController, newState != oldState {
            handlers.forEach { $0.block?(viewController, newState, $0.object) }
        }
        if newState == .didDeinit {
            handlers.removeAll()
        }
    }
}

// MARK: - LifecycleStateHandler
private class LifecycleStateHandler: NSObject {
    var object: Any?
    var block: ((UIViewController, ViewControllerLifecycleState, Any?) -> Void)?
}

// MARK: - PopProxyTarget
private class PopProxyTarget: NSObject, UIGestureRecognizerDelegate {
    private weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let topController = navigationController?.topViewController else { return false }
        return topController.shouldPopController && topController.allowsPopGesture
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        gestureRecognizer is UIScreenEdgePanGestureRecognizer
    }
}

// MARK: - GestureRecognizerDelegateProxy
@MainActor @objc private protocol GestureRecognizerDelegateCompatible {
    @objc optional func _gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceiveEvent event: UIEvent) -> Bool
}

private class GestureRecognizerDelegateProxy: DelegateProxy<UIGestureRecognizerDelegate>, UIGestureRecognizerDelegate, GestureRecognizerDelegateCompatible {
    weak var navigationController: UINavigationController?

    func shouldForceReceive() -> Bool {
        if navigationController?.presentedViewController != nil { return false }
        if (navigationController?.viewControllers.count ?? 0) <= 1 { return false }
        if !(navigationController?.interactivePopGestureRecognizer?.isEnabled ?? false) { return false }
        return navigationController?.topViewController?.allowsPopGesture ?? false
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == navigationController?.interactivePopGestureRecognizer {
            // 调用钩子。如果返回NO，则不开始手势；如果返回YES，则使用系统方式
            let shouldPop = navigationController?.topViewController?.shouldPopController ?? false
            if shouldPop {
                if let shouldBegin = delegate?.gestureRecognizerShouldBegin?(gestureRecognizer) {
                    return shouldBegin
                }
            }
            return false
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer == navigationController?.interactivePopGestureRecognizer {
            if let shouldReceive = delegate?.gestureRecognizer?(gestureRecognizer, shouldReceive: touch) {
                if !shouldReceive && shouldForceReceive() {
                    return true
                }
                return shouldReceive
            }
        }
        return true
    }

    @objc func _gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceiveEvent event: UIEvent) -> Bool {
        // 修复iOS13.4拦截返回失效问题，返回YES才会走后续流程
        if gestureRecognizer == navigationController?.interactivePopGestureRecognizer {
            if delegate?.responds(to: #selector(_gestureRecognizer(_:shouldReceiveEvent:))) ?? false,
               let shouldReceive = target?._gestureRecognizer?(gestureRecognizer, shouldReceiveEvent: event) {
                if !shouldReceive && shouldForceReceive() {
                    return true
                }
                return shouldReceive
            }
        }
        return true
    }
}

// MARK: - SafariViewControllerDelegate
private class SafariViewControllerDelegate: NSObject, @unchecked Sendable, SFSafariViewControllerDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, SKStoreProductViewControllerDelegate {
    static let shared = SafariViewControllerDelegate()

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        let completion = controller.fw.property(forName: "safariViewControllerDidFinish") as? () -> Void
        completion?()
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        let completion = controller.fw.property(forName: "messageComposeViewController") as? @Sendable (Bool) -> Void
        DispatchQueue.fw.mainAsync {
            controller.dismiss(animated: true) {
                completion?(result == .sent)
            }
        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        let completion = controller.fw.property(forName: "mailComposeController") as? @Sendable (Bool) -> Void
        DispatchQueue.fw.mainAsync {
            controller.dismiss(animated: true) {
                completion?(result == .sent)
            }
        }
    }

    func productViewControllerDidFinish(_ controller: SKStoreProductViewController) {
        let completion = controller.fw.property(forName: "productViewControllerDidFinish") as? @Sendable (Bool) -> Void
        DispatchQueue.fw.mainAsync {
            controller.dismiss(animated: true) {
                completion?(true)
            }
        }
    }
}

// MARK: - FrameworkAutoloader+Toolkit
extension FrameworkAutoloader {
    @objc static func loadToolkit_Toolkit() {
        swizzleToolkitViewController()
        swizzleToolkitTitleView()
    }

    private static func swizzleToolkitViewController() {
        NSObject.fw.swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.init(nibName:bundle:)),
            methodSignature: (@convention(c) (UIViewController, Selector, String?, Bundle?) -> UIViewController).self,
            swizzleSignature: (@convention(block) (UIViewController, String?, Bundle?) -> UIViewController).self
        ) { store in { selfObject, nibNameOrNil, nibBundleOrNil in
            let viewController = store.original(selfObject, store.selector, nibNameOrNil, nibBundleOrNil)

            if viewController is ViewControllerLifecycleObservable ||
                viewController.fw.lifecycleState != nil {
                viewController.fw.lifecycleState = .didInit
            }
            return viewController
        }}

        NSObject.fw.swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.init(coder:)),
            methodSignature: (@convention(c) (UIViewController, Selector, NSCoder) -> UIViewController?).self,
            swizzleSignature: (@convention(block) (UIViewController, NSCoder) -> UIViewController?).self
        ) { store in { selfObject, coder in
            guard let viewController = store.original(selfObject, store.selector, coder) else { return nil }

            if viewController is ViewControllerLifecycleObservable ||
                viewController.fw.lifecycleState != nil {
                viewController.fw.lifecycleState = .didInit
            }
            return viewController
        }}

        NSObject.fw.swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.viewDidLoad),
            methodSignature: (@convention(c) (UIViewController, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UIViewController) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)

            if selfObject is ViewControllerLifecycleObservable ||
                selfObject.fw.lifecycleState != nil {
                selfObject.fw.lifecycleState = .didLoad
            }
        }}

        NSObject.fw.swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.viewWillAppear(_:)),
            methodSignature: (@convention(c) (UIViewController, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) (UIViewController, Bool) -> Void).self
        ) { store in { selfObject, animated in
            store.original(selfObject, store.selector, animated)

            if selfObject is ViewControllerLifecycleObservable ||
                selfObject.fw.lifecycleState != nil {
                selfObject.fw.lifecycleState = .willAppear
            }
        }}

        NSObject.fw.swizzleInstanceMethod(
            UIViewController.self,
            selector: NSSelectorFromString("viewIsAppearing:"),
            methodSignature: (@convention(c) (UIViewController, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) (UIViewController, Bool) -> Void).self
        ) { store in { selfObject, animated in
            store.original(selfObject, store.selector, animated)

            if selfObject is ViewControllerLifecycleObservable ||
                selfObject.fw.lifecycleState != nil {
                selfObject.fw.lifecycleState = .isAppearing
            }
        }}

        NSObject.fw.swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.viewDidAppear(_:)),
            methodSignature: (@convention(c) (UIViewController, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) (UIViewController, Bool) -> Void).self
        ) { store in { selfObject, animated in
            store.original(selfObject, store.selector, animated)

            if selfObject is ViewControllerLifecycleObservable ||
                selfObject.fw.lifecycleState != nil {
                selfObject.fw.lifecycleState = .didAppear
            }
        }}

        NSObject.fw.swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.viewWillDisappear(_:)),
            methodSignature: (@convention(c) (UIViewController, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) (UIViewController, Bool) -> Void).self
        ) { store in { selfObject, animated in
            store.original(selfObject, store.selector, animated)

            if selfObject is ViewControllerLifecycleObservable ||
                selfObject.fw.lifecycleState != nil {
                selfObject.fw.lifecycleState = .willDisappear
            }
        }}

        NSObject.fw.swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.viewDidDisappear(_:)),
            methodSignature: (@convention(c) (UIViewController, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) (UIViewController, Bool) -> Void).self
        ) { store in { selfObject, animated in
            store.original(selfObject, store.selector, animated)

            if selfObject is ViewControllerLifecycleObservable ||
                selfObject.fw.lifecycleState != nil {
                selfObject.fw.lifecycleState = .didDisappear
            }
        }}
    }

    private static func swizzleToolkitTitleView() {
        NSObject.fw.swizzleInstanceMethod(
            UINavigationBar.self,
            selector: #selector(UINavigationBar.layoutSubviews),
            methodSignature: (@convention(c) (UINavigationBar, Selector) -> Void).self,
            swizzleSignature: (@convention(block) @MainActor (UINavigationBar) -> Void).self
        ) { store in { selfObject in
            guard let titleView = selfObject.topItem?.titleView as? UIView & TitleViewProtocol else {
                store.original(selfObject, store.selector)
                return
            }

            let titleMaximumWidth = titleView.bounds.width
            var titleViewSize = titleView.sizeThatFits(CGSize(width: titleMaximumWidth, height: CGFloat.greatestFiniteMagnitude))
            titleViewSize.height = ceil(titleViewSize.height)

            if titleView.bounds.height != titleViewSize.height {
                let titleViewMinY: CGFloat = UIScreen.fw.flatValue(titleView.frame.minY - ((titleViewSize.height - titleView.bounds.height) / 2.0))
                titleView.frame = CGRect(x: titleView.frame.minX, y: titleViewMinY, width: min(titleMaximumWidth, titleViewSize.width), height: titleViewSize.height)
            }

            if titleView.bounds.width != titleViewSize.width {
                var titleFrame = titleView.frame
                titleFrame.size.width = titleViewSize.width
                titleView.frame = titleFrame
            }

            store.original(selfObject, store.selector)
        }}

        NSObject.fw.swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(setter: UIViewController.title),
            methodSignature: (@convention(c) (UIViewController, Selector, String?) -> Void).self,
            swizzleSignature: (@convention(block) @MainActor (UIViewController, String?) -> Void).self
        ) { store in { selfObject, title in
            store.original(selfObject, store.selector, title)

            if let titleView = selfObject.navigationItem.titleView as? TitleViewProtocol {
                titleView.title = title
            }
        }}

        NSObject.fw.swizzleInstanceMethod(
            UINavigationItem.self,
            selector: #selector(setter: UINavigationItem.title),
            methodSignature: (@convention(c) (UINavigationItem, Selector, String?) -> Void).self,
            swizzleSignature: (@convention(block) @MainActor (UINavigationItem, String?) -> Void).self
        ) { store in { selfObject, title in
            store.original(selfObject, store.selector, title)

            if let titleView = selfObject.titleView as? TitleViewProtocol {
                titleView.title = title
            }
        }}

        NSObject.fw.swizzleInstanceMethod(
            UINavigationItem.self,
            selector: #selector(setter: UINavigationItem.titleView),
            methodSignature: (@convention(c) (UINavigationItem, Selector, UIView?) -> Void).self,
            swizzleSignature: (@convention(block) @MainActor (UINavigationItem, UIView?) -> Void).self
        ) { store in { selfObject, titleView in
            store.original(selfObject, store.selector, titleView)

            if let titleView = titleView as? TitleViewProtocol {
                if (titleView.title?.count ?? 0) <= 0 {
                    titleView.title = selfObject.title
                }
            }
        }}
    }

    private nonisolated(unsafe) static var swizzleToolkitNavigationControllerFinished = false

    fileprivate static func swizzleToolkitNavigationController() {
        guard !swizzleToolkitNavigationControllerFinished else { return }
        swizzleToolkitNavigationControllerFinished = true

        NSObject.fw.swizzleInstanceMethod(
            UINavigationController.self,
            selector: #selector(UINavigationBarDelegate.navigationBar(_:shouldPop:)),
            methodSignature: (@convention(c) (UINavigationController, Selector, UINavigationBar, UINavigationItem) -> Bool).self,
            swizzleSignature: (@convention(block) @MainActor (UINavigationController, UINavigationBar, UINavigationItem) -> Bool).self
        ) { store in { selfObject, navigationBar, item in
            if UINavigationController.innerPopProxyEnabled || selfObject.fw.popProxyEnabled {
                // 检查并调用返回按钮钩子。如果返回NO，则不pop当前页面；如果返回YES，则使用默认方式
                if selfObject.viewControllers.count >= (navigationBar.items?.count ?? 0) &&
                    !(selfObject.topViewController?.shouldPopController ?? false) {
                    return false
                }
            }

            return store.original(selfObject, store.selector, navigationBar, item)
        }}

        NSObject.fw.swizzleInstanceMethod(
            UINavigationController.self,
            selector: #selector(UIViewController.viewDidLoad),
            methodSignature: (@convention(c) (UINavigationController, Selector) -> Void).self,
            swizzleSignature: (@convention(block) @MainActor (UINavigationController) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            if !UINavigationController.innerPopProxyEnabled || selfObject.fw.popProxyEnabled { return }

            // 拦截系统返回手势事件代理，加载自定义代理方法
            if !(selfObject.interactivePopGestureRecognizer?.delegate is GestureRecognizerDelegateProxy) {
                selfObject.fw.delegateProxy.delegate = selfObject.interactivePopGestureRecognizer?.delegate
                selfObject.fw.delegateProxy.navigationController = selfObject
                selfObject.interactivePopGestureRecognizer?.delegate = selfObject.fw.delegateProxy
            }
        }}

        NSObject.fw.swizzleInstanceMethod(
            UINavigationController.self,
            selector: #selector(getter: UINavigationController.childForStatusBarHidden),
            methodSignature: (@convention(c) (UINavigationController, Selector) -> UIViewController?).self,
            swizzleSignature: (@convention(block) @MainActor (UINavigationController) -> UIViewController?).self
        ) { store in { selfObject in
            var child = store.original(selfObject, store.selector)
            if UINavigationController.innerChildProxyEnabled, child == nil {
                // visible兼容presented导航栏页面，而top仅兼容当前堆栈页面
                child = selfObject.visibleViewController
            }
            return child
        }}

        NSObject.fw.swizzleInstanceMethod(
            UINavigationController.self,
            selector: #selector(getter: UINavigationController.childForStatusBarStyle),
            methodSignature: (@convention(c) (UINavigationController, Selector) -> UIViewController?).self,
            swizzleSignature: (@convention(block) @MainActor (UINavigationController) -> UIViewController?).self
        ) { store in { selfObject in
            var child = store.original(selfObject, store.selector)
            if UINavigationController.innerChildProxyEnabled, child == nil {
                // visible兼容presented导航栏页面，而top仅兼容当前堆栈页面
                child = selfObject.visibleViewController
            }
            return child
        }}
    }
}

// MARK: - Concurrency+Toolkit
#if canImport(_Concurrency)
@MainActor extension Wrapper where Base: UIApplication {
    /// 异步打开URL，支持NSString|NSURL，完成时回调，即使未配置URL SCHEME，实际也能打开成功，只要调用时已打开过对应App
    public static func openURL(_ url: URLParameter?) async -> Bool {
        await withCheckedContinuation { continuation in
            openURL(url) { success in
                continuation.resume(returning: success)
            }
        }
    }

    /// 异步打开通用链接URL，支持NSString|NSURL，完成时回调。如果是iOS10+通用链接且安装了App，打开并回调YES，否则回调NO
    public static func openUniversalLinks(_ url: URLParameter?) async -> Bool {
        await withCheckedContinuation { continuation in
            openUniversalLinks(url) { success in
                continuation.resume(returning: success)
            }
        }
    }

    /// 异步打开AppStore下载页
    public static func openAppStore(_ appId: String) async -> Bool {
        await withCheckedContinuation { continuation in
            openAppStore(appId) { success in
                continuation.resume(returning: success)
            }
        }
    }

    /// 异步打开AppStore评价页
    public static func openAppStoreReview(_ appId: String) async -> Bool {
        await withCheckedContinuation { continuation in
            openAppStoreReview(appId) { success in
                continuation.resume(returning: success)
            }
        }
    }

    /// 异步打开系统应用设置页
    public static func openAppSettings() async -> Bool {
        await withCheckedContinuation { continuation in
            openAppSettings { success in
                continuation.resume(returning: success)
            }
        }
    }

    /// 异步打开系统应用通知设置页
    public static func openAppNotificationSettings() async -> Bool {
        await withCheckedContinuation { continuation in
            openAppNotificationSettings { success in
                continuation.resume(returning: success)
            }
        }
    }

    /// 异步打开系统邮件App
    public static func openMailApp(_ email: String) async -> Bool {
        await withCheckedContinuation { continuation in
            openMailApp(email) { success in
                continuation.resume(returning: success)
            }
        }
    }

    /// 异步打开系统短信App
    public static func openMessageApp(_ phone: String) async -> Bool {
        await withCheckedContinuation { continuation in
            openMessageApp(phone) { success in
                continuation.resume(returning: success)
            }
        }
    }

    /// 异步打开系统电话App
    public static func openPhoneApp(_ phone: String) async -> Bool {
        await withCheckedContinuation { continuation in
            openPhoneApp(phone) { success in
                continuation.resume(returning: success)
            }
        }
    }
}
#endif
