//
//  Toolkit.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit
import AVFoundation
import AudioToolbox
import AVKit
import MessageUI
import SafariServices
import Accelerate
import StoreKit
#if FWMacroSPM
import FWObjC
#endif

// MARK: - WrapperGlobal+Toolkit
extension WrapperGlobal {
    
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
        return Icon.iconNamed(named, size: size)
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
/// 注意Info.plist文件URL SCHEME配置项只影响canOpenUrl方法，不影响openUrl。微信返回app就是获取sourceUrl，直接openUrl实现。因为跳转微信的时候，来源app肯定已打开过，可以跳转，只要不检查canOpenUrl，就可以跳转回app。
/// 为了防止系统启动图缓存，每次更换启动图时建议修改启动图名称(比如添加日期等)，防止刚更新App时新图不生效
@_spi(FW) extension UIApplication {
    
    private class SafariViewControllerDelegate: NSObject, SFSafariViewControllerDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, SKStoreProductViewControllerDelegate {
        
        static let shared = SafariViewControllerDelegate()
        
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            let completion = controller.fw_property(forName: "safariViewControllerDidFinish") as? () -> Void
            completion?()
        }
        
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            let completion = controller.fw_property(forName: "messageComposeViewController") as? (Bool) -> Void
            controller.dismiss(animated: true) {
                completion?(result == .sent)
            }
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            let completion = controller.fw_property(forName: "mailComposeController") as? (Bool) -> Void
            controller.dismiss(animated: true) {
                completion?(result == .sent)
            }
        }
        
        func productViewControllerDidFinish(_ controller: SKStoreProductViewController) {
            let completion = controller.fw_property(forName: "productViewControllerDidFinish") as? (Bool) -> Void
            controller.dismiss(animated: true) {
                completion?(true)
            }
        }
        
    }
    
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
        return appVersion ?? fw_appBuildVersion
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
    public static func fw_canOpenURL(_ url: Any?) -> Bool {
        guard let url = fw_url(string: url) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    /// 打开URL，支持NSString|NSURL，完成时回调，即使未配置URL SCHEME，实际也能打开成功，只要调用时已打开过对应App
    public static func fw_openURL(_ url: Any?, completionHandler: ((Bool) -> Void)? = nil) {
        guard let url = fw_url(string: url) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: completionHandler)
    }

    /// 打开通用链接URL，支持NSString|NSURL，完成时回调。如果是iOS10+通用链接且安装了App，打开并回调YES，否则回调NO
    public static func fw_openUniversalLinks(_ url: Any?, completionHandler: ((Bool) -> Void)? = nil) {
        guard let url = fw_url(string: url) else { return }
        UIApplication.shared.open(url, options: [.universalLinksOnly: true], completionHandler: completionHandler)
    }

    /// 判断URL是否是系统链接(如AppStore|电话|设置等)，支持NSString|NSURL
    public static func fw_isSystemURL(_ url: Any?) -> Bool {
        guard let url = fw_url(string: url) else { return false }
        if let scheme = url.scheme?.lowercased(),
           ["tel", "telprompt", "sms", "mailto"].contains(scheme) {
            return true
        }
        if fw_isAppStoreURL(url) {
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
    
    /// 判断URL是否是Scheme链接(非http|https|file链接)，支持String|URL，可指定判断scheme
    public static func fw_isSchemeURL(_ url: Any?, scheme: String? = nil) -> Bool {
        guard let url = fw_url(string: url),
              let urlScheme = url.scheme,
              !urlScheme.isEmpty else { return false }
        
        if let scheme = scheme {
            return urlScheme == scheme
        } else {
            if url.isFileURL || fw_isHttpURL(url) { return false }
            return true
        }
    }

    /// 判断URL是否HTTP链接，支持NSString|NSURL
    public static func fw_isHttpURL(_ url: Any?) -> Bool {
        var urlString = url as? String ?? ""
        if let url = url as? URL {
            urlString = url.absoluteString
        }
        return urlString.lowercased().hasPrefix("http://") || urlString.lowercased().hasPrefix("https://")
    }

    /// 判断URL是否是AppStore链接，支持NSString|NSURL
    public static func fw_isAppStoreURL(_ url: Any?) -> Bool {
        guard let url = fw_url(string: url) else { return false }
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
    public static func fw_openAppStore(_ appId: String, completionHandler: ((Bool) -> Void)? = nil) {
        // SKStoreProductViewController可以内部打开
        fw_openURL("https://apps.apple.com/app/id\(appId)", completionHandler: completionHandler)
    }

    /// 打开AppStore评价页
    public static func fw_openAppStoreReview(_ appId: String, completionHandler: ((Bool) -> Void)? = nil) {
        fw_openURL("https://apps.apple.com/app/id\(appId)?action=write-review", completionHandler: completionHandler)
    }

    /// 打开应用内评价，有次数限制
    public static func fw_openAppReview() {
        SKStoreReviewController.requestReview()
    }

    /// 打开系统应用设置页
    public static func fw_openAppSettings(_ completionHandler: ((Bool) -> Void)? = nil) {
        fw_openURL(UIApplication.openSettingsURLString, completionHandler: completionHandler)
    }
    
    /// 打开系统应用通知设置页
    public static func fw_openAppNotificationSettings(_ completionHandler: ((Bool) -> Void)? = nil) {
        if #available(iOS 16.0, *) {
            fw_openURL(UIApplication.openNotificationSettingsURLString, completionHandler: completionHandler)
        } else if #available(iOS 15.4, *) {
            fw_openURL(UIApplicationOpenNotificationSettingsURLString, completionHandler: completionHandler)
        } else {
            fw_openURL(UIApplication.openSettingsURLString, completionHandler: completionHandler)
        }
    }

    /// 打开系统邮件App
    public static func fw_openMailApp(_ email: String, completionHandler: ((Bool) -> Void)? = nil) {
        fw_openURL("mailto:" + email, completionHandler: completionHandler)
    }

    /// 打开系统短信App
    public static func fw_openMessageApp(_ phone: String, completionHandler: ((Bool) -> Void)? = nil) {
        fw_openURL("sms:" + phone, completionHandler: completionHandler)
    }

    /// 打开系统电话App
    public static func fw_openPhoneApp(_ phone: String, completionHandler: ((Bool) -> Void)? = nil) {
        // tel:为直接拨打电话
        fw_openURL("telprompt:" + phone, completionHandler: completionHandler)
    }

    /// 打开系统分享
    public static func fw_openActivityItems(_ activityItems: [Any], excludedTypes: [UIActivity.ActivityType]? = nil, customBlock: ((UIActivityViewController) -> Void)? = nil) {
        let activityController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityController.excludedActivityTypes = excludedTypes
        // 兼容iPad，默认居中显示
        let viewController = Navigator.topPresentedController
        if UIDevice.fw_isIpad, let viewController = viewController,
           let popoverController = activityController.popoverPresentationController {
            let ancestorView = viewController.fw_ancestorView
            popoverController.sourceView = ancestorView
            popoverController.sourceRect = CGRect(x: ancestorView.center.x, y: ancestorView.center.y, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        customBlock?(activityController)
        viewController?.present(activityController, animated: true)
    }

    /// 打开内部浏览器，支持NSString|NSURL，点击完成时回调
    public static func fw_openSafariController(_ url: Any?, completionHandler: (() -> Void)? = nil) {
        guard let url = fw_url(string: url), fw_isHttpURL(url) else { return }
        let safariController = SFSafariViewController(url: url)
        if completionHandler != nil {
            safariController.fw_setProperty(completionHandler, forName: "safariViewControllerDidFinish")
            safariController.delegate = SafariViewControllerDelegate.shared
        }
        Navigator.present(safariController, animated: true)
    }

    /// 打开短信控制器，完成时回调
    public static func fw_openMessageController(_ controller: MFMessageComposeViewController, completionHandler: ((Bool) -> Void)? = nil) {
        if !MFMessageComposeViewController.canSendText() {
            completionHandler?(false)
            return
        }
        
        if completionHandler != nil {
            controller.fw_setProperty(completionHandler, forName: "messageComposeViewController")
        }
        controller.messageComposeDelegate = SafariViewControllerDelegate.shared
        Navigator.present(controller, animated: true)
    }

    /// 打开邮件控制器，完成时回调
    public static func fw_openMailController(_ controller: MFMailComposeViewController, completionHandler: ((Bool) -> Void)? = nil) {
        if !MFMailComposeViewController.canSendMail() {
            completionHandler?(false)
            return
        }
        
        if completionHandler != nil {
            controller.fw_setProperty(completionHandler, forName: "mailComposeController")
        }
        controller.mailComposeDelegate = SafariViewControllerDelegate.shared
        Navigator.present(controller, animated: true)
    }

    /// 打开Store控制器，完成时回调
    public static func fw_openStoreController(_ parameters: [String: Any], completionHandler: ((Bool) -> Void)? = nil) {
        let controller = SKStoreProductViewController()
        controller.delegate = SafariViewControllerDelegate.shared
        controller.loadProduct(withParameters: parameters) { result, _ in
            if !result {
                completionHandler?(false)
                return
            }
            
            controller.fw_setProperty(completionHandler, forName: "productViewControllerDidFinish")
            Navigator.present(controller, animated: true)
        }
    }

    /// 打开视频播放器，支持AVPlayerItem|NSURL|NSString
    public static func fw_openVideoPlayer(_ url: Any?) -> AVPlayerViewController? {
        var player: AVPlayer?
        if let playerItem = url as? AVPlayerItem {
            player = AVPlayer(playerItem: playerItem)
        } else if let url = url as? URL {
            player = AVPlayer(url: url)
        } else if let videoUrl = fw_url(string: url) {
            player = AVPlayer(url: videoUrl)
        }
        guard player != nil else { return nil }
        
        let viewController = AVPlayerViewController()
        viewController.player = player
        return viewController
    }

    /// 打开音频播放器，支持NSURL|NSString
    public static func fw_openAudioPlayer(_ url: Any?) -> AVAudioPlayer? {
        // 设置播放模式示例
        // try? AVAudioSession.sharedInstance().setCategory(.ambient)
        
        var audioUrl: URL?
        if let url = url as? URL {
            audioUrl = url
        } else if let urlString = url as? String {
            if (urlString as NSString).isAbsolutePath {
                audioUrl = NSURL.fileURL(withPath: urlString)
            } else {
                audioUrl = Bundle.main.url(forResource: urlString, withExtension: nil)
            }
        }
        guard let audioUrl = audioUrl else { return nil }
        
        guard let audioPlayer = try? AVAudioPlayer(contentsOf: audioUrl) else { return nil }
        if !audioPlayer.prepareToPlay() { return nil }
        
        audioPlayer.play()
        return audioPlayer
    }
    
    private static func fw_url(string: Any?) -> URL? {
        guard let string = string else { return nil }
        if let url = string as? URL {
            return url
        } else {
            return URL.fw_url(string: string as? String)
        }
    }
    
    /// 播放内置声音文件
    @discardableResult
    public static func fw_playSystemSound(_ file: String, completionHandler: (() -> Void)? = nil) -> SystemSoundID {
        guard !file.isEmpty else { return 0 }
        
        var soundFile = file
        if !(file as NSString).isAbsolutePath {
            guard let resourceFile = Bundle.main.path(forResource: file, ofType: nil) else { return 0 }
            soundFile = resourceFile
        }
        if !FileManager.default.fileExists(atPath: soundFile) {
            return 0
        }
        
        let soundUrl = NSURL.fileURL(withPath: soundFile)
        var soundId: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(soundUrl as CFURL, &soundId)
        AudioServicesPlaySystemSoundWithCompletion(soundId, completionHandler)
        return soundId
    }

    /// 停止播放内置声音文件
    public static func fw_stopSystemSound(_ soundId: SystemSoundID) {
        if soundId == 0 { return }
        
        AudioServicesRemoveSystemSoundCompletion(soundId)
        AudioServicesDisposeSystemSoundID(soundId)
    }

    /// 播放内置震动
    public static func fw_playSystemVibrate(_ completionHandler: (() -> Void)? = nil) {
        AudioServicesPlaySystemSoundWithCompletion(kSystemSoundID_Vibrate, completionHandler)
    }
    
    /// 播放触控反馈
    public static func fw_playImpactFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: style)
        feedbackGenerator.impactOccurred()
    }

    /// 语音朗读文字，可指定语言(如zh-CN)
    public static func fw_playSpeechUtterance(_ string: String, language: String?) {
        let speechUtterance = AVSpeechUtterance(string: string)
        speechUtterance.rate = AVSpeechUtteranceDefaultSpeechRate
        speechUtterance.voice = AVSpeechSynthesisVoice(language: language)
        let speechSynthesizer = AVSpeechSynthesizer()
        speechSynthesizer.speak(speechUtterance)
    }
    
    /// 是否是盗版(不是从AppStore安装)
    public static var fw_isPirated: Bool {
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
        
        // 这方法可以运行时被替换掉，可以通过加密代码、修改方法名等提升检察性
        return false
        #endif
    }
    
    /// 是否是Testflight版本
    public static var fw_isTestflight: Bool {
        return Bundle.main.appStoreReceiptURL?.path.contains("sandboxReceipt") ?? false
    }
    
    /// 开始后台任务，task必须调用completionHandler
    public static func fw_beginBackgroundTask(_ task: (@escaping () -> Void) -> Void, expirationHandler: (() -> Void)? = nil) {
        var bgTask: UIBackgroundTaskIdentifier = .invalid
        bgTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            expirationHandler?()
            UIApplication.shared.endBackgroundTask(bgTask)
            bgTask = .invalid
        })
        
        task({
            UIApplication.shared.endBackgroundTask(bgTask)
            bgTask = .invalid
        })
    }
    
}

// MARK: - UIColor+Toolkit
@_spi(FW) extension UIColor {
    
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
        // 处理参数
        var string = hexString.uppercased()
        if string.hasPrefix("0X") {
            string = string.fw_substring(from: 2)
        }
        if string.hasPrefix("#") {
            string = string.fw_substring(from: 1)
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
            if fw_colorStandardARGB && length == 4 {
                string = String(format: "%@%@", string.fw_substring(with: NSMakeRange(1, 3)), string.fw_substring(with: NSMakeRange(0, 1)))
            }
            // RGB|RGBA
            let tmpR = string.fw_substring(with: NSMakeRange(0, 1))
            let tmpG = string.fw_substring(with: NSMakeRange(1, 1))
            let tmpB = string.fw_substring(with: NSMakeRange(2, 1))
            strR = String(format: "%@%@", tmpR, tmpR)
            strG = String(format: "%@%@", tmpG, tmpG)
            strB = String(format: "%@%@", tmpB, tmpB)
            if length == 4 {
                let tmpA = string.fw_substring(with: NSMakeRange(3, 1))
                strA = String(format: "%@%@", tmpA, tmpA)
            }
        } else {
            // AARRGGBB
            if fw_colorStandardARGB && length == 8 {
                string = String(format: "%@%@", string.fw_substring(with: NSMakeRange(2, 6)), string.fw_substring(with: NSMakeRange(0, 2)))
            }
            // RRGGBB|RRGGBBAA
            strR = string.fw_substring(with: NSMakeRange(0, 2))
            strG = string.fw_substring(with: NSMakeRange(2, 2))
            strB = string.fw_substring(with: NSMakeRange(4, 2))
            if length == 8 {
                strA = string.fw_substring(with: NSMakeRange(6, 2))
            }
        }
        
        // 解析颜色
        var r: UInt64 = 0
        var g: UInt64 = 0
        var b: UInt64 = 0
        Scanner(string: strR).scanHexInt64(&r)
        Scanner(string: strG).scanHexInt64(&g)
        Scanner(string: strB).scanHexInt64(&b)
        let fr: CGFloat = CGFloat(r) / 255.0
        let fg: CGFloat = CGFloat(g) / 255.0
        let fb: CGFloat = CGFloat(b) / 255.0
        
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
    public func fw_addColor(_ color: UIColor, blendMode: CGBlendMode = .normal) -> UIColor {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        var pixel = Array<UInt32>(repeating: 0, count: 4)
        let context = CGContext(data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: bitmapInfo)
        context?.setFillColor(self.cgColor)
        context?.fill([CGRect(x: 0, y: 0, width: 1, height: 1)])
        context?.setBlendMode(blendMode)
        context?.setFillColor(color.cgColor)
        context?.fill([CGRect(x: 0, y: 0, width: 1, height: 1)])
        return UIColor(red: CGFloat(pixel[0]) / 255.0, green: CGFloat(pixel[1]) / 255.0, blue: CGFloat(pixel[2]) / 255.0, alpha: CGFloat(pixel[3]) / 255.0)
    }
    
    /// 当前颜色修改亮度比率的颜色
    public func fw_brightnessColor(_ ratio: CGFloat) -> UIColor {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: s, brightness: b * ratio, alpha: a)
    }
    
    /// 判断当前颜色是否为深色
    public var fw_isDarkColor: Bool {
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
    public static func fw_gradientColor(size: CGSize, colors: [Any], locations: UnsafePointer<CGFloat>?, direction: UISwipeGestureRecognizer.Direction) -> UIColor {
        let linePoints = UIBezierPath.fw_linePoints(rect: CGRect(x: 0, y: 0, width: size.width, height: size.height), direction: direction)
        let startPoint = linePoints.first?.cgPointValue ?? .zero
        let endPoint = linePoints.last?.cgPointValue ?? .zero
        return fw_gradientColor(size: size, colors: colors, locations: locations, startPoint: startPoint, endPoint: endPoint)
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
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations)
        if let context = context, let gradient = gradient {
            context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let image = image {
            return UIColor(patternImage: image)
        }
        return UIColor.clear
    }
    
}

// MARK: - UIFont+Toolkit
@_spi(FW) extension UIFont {
    
    /// 自定义全局自动等比例缩放适配句柄，默认nil，开启后如需固定大小调用fixed即可
    public static var fw_autoScaleBlock: ((CGFloat) -> CGFloat)?
    
    /// 快捷启用全局自动等比例缩放字体，自动设置默认autoScaleBlock
    public static var fw_autoScaleFont: Bool {
        get {
            fw_autoScaleBlock != nil
        }
        set {
            guard newValue != fw_autoScaleFont else { return }
            fw_autoScaleBlock = newValue ? { UIScreen.fw_relativeValue($0) } : nil
        }
    }
    
    /// 全局自定义字体句柄，优先调用，返回nil时使用系统字体
    public static var fw_fontBlock: ((CGFloat, UIFont.Weight) -> UIFont?)?

    /// 返回系统Thin字体，自动等比例缩放
    public static func fw_thinFont(ofSize: CGFloat) -> UIFont {
        return fw_font(ofSize: ofSize, weight: .thin)
    }
    /// 返回系统Light字体，自动等比例缩放
    public static func fw_lightFont(ofSize: CGFloat) -> UIFont {
        return fw_font(ofSize: ofSize, weight: .light)
    }
    /// 返回系统Regular字体，自动等比例缩放
    public static func fw_font(ofSize: CGFloat) -> UIFont {
        return fw_font(ofSize: ofSize, weight: .regular)
    }
    /// 返回系统Medium字体，自动等比例缩放
    public static func fw_mediumFont(ofSize: CGFloat) -> UIFont {
        return fw_font(ofSize: ofSize, weight: .medium)
    }
    /// 返回系统Semibold字体，自动等比例缩放
    public static func fw_semiboldFont(ofSize: CGFloat) -> UIFont {
        return fw_font(ofSize: ofSize, weight: .semibold)
    }
    /// 返回系统Bold字体，自动等比例缩放
    public static func fw_boldFont(ofSize: CGFloat) -> UIFont {
        return fw_font(ofSize: ofSize, weight: .bold)
    }

    /// 创建指定尺寸和weight的系统字体，自动等比例缩放
    public static func fw_font(ofSize: CGFloat, weight: UIFont.Weight) -> UIFont {
        let size = UIFont.fw_autoScaleBlock?(ofSize) ?? ofSize
        if let font = fw_fontBlock?(size, weight) { return font }
        return UIFont.systemFont(ofSize: size, weight: weight)
    }
    
    /// 获取指定名称、字重、斜体字体的完整规范名称
    public static func fw_fontName(_ name: String, weight: UIFont.Weight, italic: Bool = false) -> String {
        var fontName = name
        if let weightSuffix = fw_weightSuffixes[weight] {
            fontName += weightSuffix + (italic ? "Italic" : "")
        }
        return fontName
    }
    
    private static let fw_weightSuffixes: [UIFont.Weight: String] = [
        .ultraLight: "-Ultralight",
        .thin: "-Thin",
        .light: "-Light",
        .regular: "-Regular",
        .medium: "-Medium",
        .semibold: "-Semibold",
        .bold: "-Bold",
        .heavy: "-Heavy",
        .black: "-Black",
    ]
    
    /// 是否是粗体
    public var fw_isBold: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitBold)
    }

    /// 是否是斜体
    public var fw_isItalic: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitItalic)
    }

    /// 当前字体的粗体字体
    public var fw_boldFont: UIFont {
        let symbolicTraits = fontDescriptor.symbolicTraits.union(.traitBold)
        return UIFont(descriptor: fontDescriptor.withSymbolicTraits(symbolicTraits) ?? fontDescriptor, size: pointSize)
    }
    
    /// 当前字体的非粗体字体
    public var fw_nonBoldFont: UIFont {
        var symbolicTraits = fontDescriptor.symbolicTraits
        symbolicTraits.remove(.traitBold)
        return UIFont(descriptor: fontDescriptor.withSymbolicTraits(symbolicTraits) ?? fontDescriptor, size: pointSize)
    }
    
    /// 当前字体的斜体字体
    public var fw_italicFont: UIFont {
        let symbolicTraits = fontDescriptor.symbolicTraits.union(.traitItalic)
        return UIFont(descriptor: fontDescriptor.withSymbolicTraits(symbolicTraits) ?? fontDescriptor, size: pointSize)
    }
    
    /// 当前字体的非斜体字体
    public var fw_nonItalicFont: UIFont {
        var symbolicTraits = fontDescriptor.symbolicTraits
        symbolicTraits.remove(.traitItalic)
        return UIFont(descriptor: fontDescriptor.withSymbolicTraits(symbolicTraits) ?? fontDescriptor, size: pointSize)
    }
    
    /// 字体空白高度(上下之和)
    public var fw_spaceHeight: CGFloat {
        return lineHeight - pointSize
    }

    /// 根据字体计算指定倍数行间距的实际行距值(减去空白高度)，示例：行间距为0.5倍实际高度
    public func fw_lineSpacing(multiplier: CGFloat) -> CGFloat {
        return pointSize * multiplier - (lineHeight - pointSize)
    }

    /// 根据字体计算指定倍数行高的实际行高值(减去空白高度)，示例：行高为1.5倍实际高度
    public func fw_lineHeight(multiplier: CGFloat) -> CGFloat {
        return pointSize * multiplier
    }
    
    /// 计算指定期望高度下字体的实际行高值，取期望值和行高值的较大值
    public func fw_lineHeight(expected: CGFloat) -> CGFloat {
        return max(lineHeight, expected)
    }
    
    /// 计算指定期望高度下字体的实际高度值，取期望值和高度值的较大值
    public func fw_pointHeight(expected: CGFloat) -> CGFloat {
        return max(pointSize, expected)
    }

    /// 计算当前字体与指定字体居中对齐的偏移值
    public func fw_baselineOffset(_ font: UIFont) -> CGFloat {
        return (lineHeight - font.lineHeight) / 2.0 + (descender - font.descender)
    }
    
    /// 计算当前字体与指定行高居中对齐的偏移值
    public func fw_baselineOffset(lineHeight: CGFloat) -> CGFloat {
        return (lineHeight - self.lineHeight) / 4.0
    }
    
}

// MARK: - UIImage+Toolkit
@_spi(FW) extension UIImage {
    
    /// 从当前图片创建指定透明度的图片
    public func fw_image(alpha: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height), blendMode: .normal, alpha: alpha)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 从当前UIImage混合颜色创建UIImage，可自定义模式，默认destinationIn
    public func fw_image(tintColor: UIColor, blendMode: CGBlendMode = .destinationIn) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0)
        tintColor.setFill()
        let bounds = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        UIRectFill(bounds)
        self.draw(in: bounds, blendMode: blendMode, alpha: 1.0)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 缩放图片到指定大小
    public func fw_image(scaleSize size: CGSize) -> UIImage? {
        guard size.width > 0, size.height > 0 else { return nil }
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 缩放图片到指定大小，指定模式
    public func fw_image(scaleSize size: CGSize, contentMode: UIView.ContentMode) -> UIImage? {
        guard size.width > 0, size.height > 0 else { return nil }
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        fw_draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height), contentMode: contentMode, clipsToBounds: false)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 按指定模式绘制图片
    public func fw_draw(in rect: CGRect, contentMode: UIView.ContentMode, clipsToBounds: Bool) {
        let drawRect = fw_rect(contentMode: contentMode, rect: rect, size: self.size)
        if drawRect.size.width <= 0 || drawRect.size.height <= 0 { return }
        if clipsToBounds {
            if let context = UIGraphicsGetCurrentContext() {
                context.saveGState()
                context.addRect(rect)
                context.clip()
                self.draw(in: drawRect)
                context.restoreGState()
            }
        } else {
            self.draw(in: drawRect)
        }
    }
    
    private func fw_rect(contentMode: UIView.ContentMode, rect: CGRect, size: CGSize) -> CGRect {
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
    public func fw_image(cropRect: CGRect) -> UIImage? {
        var rect = cropRect
        rect.origin.x *= self.scale
        rect.origin.y *= self.scale
        rect.size.width *= self.scale
        rect.size.height *= self.scale
        guard rect.width > 0, rect.height > 0 else { return nil }
        
        guard let imageRef = self.cgImage?.cropping(to: rect) else { return nil }
        let image = UIImage(cgImage: imageRef, scale: self.scale, orientation: self.imageOrientation)
        return image
    }

    /// 指定颜色填充图片边缘
    public func fw_image(insets: UIEdgeInsets, color: UIColor?) -> UIImage? {
        var size = self.size
        size.width -= insets.left + insets.right
        size.height -= insets.top + insets.bottom
        if size.width <= 0 || size.height <= 0 { return nil }
        let rect = CGRect(x: -insets.left, y: -insets.top, width: self.size.width, height: self.size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        if let color = color, let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(color.cgColor)
            let path = CGMutablePath()
            path.addRect(CGRect(x: 0, y: 0, width: size.width, height: size.height))
            path.addRect(rect)
            context.addPath(path)
            context.fillPath(using: .evenOdd)
        }
        self.draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 拉伸图片(平铺模式)，指定端盖区域（不拉伸区域）
    public func fw_image(capInsets: UIEdgeInsets) -> UIImage {
        return resizableImage(withCapInsets: capInsets)
    }

    /// 拉伸图片(指定模式)，指定端盖区域（不拉伸区域）。Tile为平铺模式，Stretch为拉伸模式
    public func fw_image(capInsets: UIEdgeInsets, resizingMode: UIImage.ResizingMode) -> UIImage {
        return resizableImage(withCapInsets: capInsets, resizingMode: resizingMode)
    }

    /// 生成圆角图片
    public func fw_image(cornerRadius: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0)
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
        self.draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 按角度常数(0~360)转动图片，指定图片尺寸是否延伸来适应内容，否则图片尺寸不变，内容被裁剪，默认true
    public func fw_image(rotateDegree: CGFloat, fitSize: Bool = true) -> UIImage? {
        let radians = rotateDegree * .pi / 180.0
        let width = self.cgImage?.width ?? .zero
        let height = self.cgImage?.height ?? .zero
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
        
        guard let cgImage = self.cgImage else { return nil }
        context.draw(cgImage, in: CGRect(x: -(CGFloat(width) * 0.5), y: -(CGFloat(height) * 0.5), width: CGFloat(width), height: CGFloat(height)))
        guard let imageRef = context.makeImage() else { return nil }
        let image = UIImage(cgImage: imageRef, scale: self.scale, orientation: self.imageOrientation)
        return image
    }

    /// 生成mark图片
    public func fw_image(maskImage: UIImage) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0)
        if let context = UIGraphicsGetCurrentContext(), let mask = maskImage.cgImage {
            context.clip(to: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height), mask: mask)
        }
        self.draw(at: .zero)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 图片合并，并制定叠加图片的起始位置
    public func fw_image(mergeImage: UIImage, atPoint: CGPoint) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        mergeImage.draw(at: atPoint)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 图片应用CIFilter滤镜处理
    public func fw_image(filter: CIFilter) -> UIImage? {
        var inputImage: CIImage?
        if let ciImage = self.ciImage {
            inputImage = ciImage
        } else {
            guard let imageRef = self.cgImage else { return nil }
            inputImage = CIImage(cgImage: imageRef)
        }
        guard let inputImage = inputImage else { return nil }
        
        let context = CIContext()
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        guard let outputImage = filter.outputImage else { return nil }
        
        guard let imageRef = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        let image = UIImage(cgImage: imageRef, scale: self.scale, orientation: self.imageOrientation)
        return image
    }
    
    /// 图片应用高斯模糊滤镜处理
    public func fw_gaussianBlurImage(fuzzyValue: CGFloat = 10) -> UIImage? {
        return fw_filteredImage(fuzzyValue: fuzzyValue, filterName: "CIGaussianBlur")
    }
    
    /// 图片应用像素化滤镜处理
    public func fw_pixellateImage(fuzzyValue: CGFloat = 10) -> UIImage? {
        return fw_filteredImage(fuzzyValue: fuzzyValue, filterName: "CIPixellate")
    }
    
    private func fw_filteredImage(fuzzyValue: CGFloat, filterName: String) -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return nil }
        guard let blurFilter = CIFilter(name: filterName) else { return nil }
        blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
        blurFilter.setValue(fuzzyValue, forKey: filterName == "CIPixellate" ? kCIInputScaleKey : kCIInputRadiusKey)
        guard let outputImage = blurFilter.outputImage else { return nil }
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    /// 压缩图片到指定字节，图片太大时会改为JPG格式。不保证图片大小一定小于该大小
    public func fw_compressImage(maxLength: Int, compressRatio: CGFloat = 0) -> UIImage? {
        guard let data = fw_compressData(maxLength: maxLength, compressRatio: compressRatio) else { return nil }
        return UIImage(data: data)
    }

    /// 压缩图片到指定字节，图片太大时会改为JPG格式，可设置递减压缩率，默认0.3。不保证图片大小一定小于该大小
    public func fw_compressData(maxLength: Int, compressRatio: CGFloat = 0) -> Data? {
        var compress: CGFloat = 1.0
        let stepCompress: CGFloat = compressRatio > 0 ? compressRatio : 0.3
        var data = fw_hasAlpha ? self.pngData() : self.jpegData(compressionQuality: compress)
        while (data?.count ?? 0) > maxLength && compress > stepCompress {
            compress -= stepCompress
            data = self.jpegData(compressionQuality: compress)
        }
        return data
    }

    /// 长边压缩图片尺寸，获取等比例的图片
    public func fw_compressImage(maxWidth: CGFloat) -> UIImage? {
        let newSize = fw_scaleSize(maxWidth: maxWidth)
        if newSize.equalTo(self.size) { return self }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 通过指定图片最长边，获取等比例的图片size
    public func fw_scaleSize(maxWidth: CGFloat) -> CGSize {
        if maxWidth <= 0 { return self.size }
        
        let width = self.size.width
        let height = self.size.height
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
    public static func fw_compressImages(_ images: [UIImage], maxWidth: CGFloat, maxLength: Int, compressRatio: CGFloat = 0, completion: @escaping ([UIImage]) -> Void) {
        DispatchQueue.global().async {
            var compressImages: [UIImage] = []
            for image in images {
                if let compressImage = image
                    .fw_compressImage(maxWidth: maxWidth)?
                    .fw_compressImage(maxLength: maxLength, compressRatio: compressRatio) {
                    compressImages.append(compressImage)
                }
            }
            
            DispatchQueue.main.async {
                completion(compressImages)
            }
        }
    }

    /// 后台线程压缩图片数据，完成后主线程回调
    public static func fw_compressDatas(_ images: [UIImage], maxWidth: CGFloat, maxLength: Int, compressRatio: CGFloat = 0, completion: @escaping ([Data]) -> Void) {
        DispatchQueue.global().async {
            var compressDatas: [Data] = []
            for image in images {
                if let compressData = image
                    .fw_compressImage(maxWidth: maxWidth)?
                    .fw_compressData(maxLength: maxLength, compressRatio: compressRatio) {
                    compressDatas.append(compressData)
                }
            }
            
            DispatchQueue.main.async {
                completion(compressDatas)
            }
        }
    }

    /// 获取原始渲染模式图片，始终显示原色，不显示tintColor。默认自动根据上下文
    public var fw_originalImage: UIImage {
        return withRenderingMode(.alwaysOriginal)
    }

    /// 获取模板渲染模式图片，始终显示tintColor，不显示原色。默认自动根据上下文
    public var fw_templateImage: UIImage {
        return withRenderingMode(.alwaysTemplate)
    }

    /// 判断图片是否有透明通道
    public var fw_hasAlpha: Bool {
        guard let cgImage = self.cgImage else { return false }
        let alpha = cgImage.alphaInfo
        return alpha == .first || alpha == .last ||
            alpha == .premultipliedFirst || alpha == .premultipliedLast
    }

    /// 获取当前图片的像素大小，多倍图会放大到一倍
    public var fw_pixelSize: CGSize {
        return CGSize(width: self.size.width * self.scale, height: self.size.height * self.scale)
    }
    
    /// 从视图创建UIImage，生成截图，主线程调用
    public static func fw_image(view: UIView) -> UIImage? {
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
    public static func fw_image(color: UIColor?) -> UIImage? {
        return fw_image(color: color, size: CGSize(width: 1.0, height: 1.0))
    }
    
    /// 从颜色创建UIImage，可指定尺寸和圆角，默认圆角0
    public static func fw_image(color: UIColor?, size: CGSize, cornerRadius: CGFloat = 0) -> UIImage? {
        guard let color = color, size.width > 0, size.height > 0 else { return nil }
        
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.setFillColor(color.cgColor)
        if cornerRadius > 0 {
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            path.addClip()
            path.fill()
        } else {
            context.fill([rect])
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 从block创建UIImage，指定尺寸
    public static func fw_image(size: CGSize, block: (CGContext) -> Void) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        block(context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    /// 保存图片到相册，保存成功时error为nil
    public func fw_saveImage(completion: ((Error?) -> Void)? = nil) {
        fw_setPropertyCopy(completion, forName: "fw_saveImage")
        UIImageWriteToSavedPhotosAlbum(self, self, #selector(fw_saveImage(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    /// 保存视频到相册，保存成功时error为nil。如果视频地址为NSURL，需使用NSURL.path
    public static func fw_saveVideo(_ videoPath: String, completion: ((Error?) -> Void)? = nil) {
        UIImage.fw_setPropertyCopy(completion, forName: "fw_saveVideo")
        if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoPath) {
            UISaveVideoAtPathToSavedPhotosAlbum(videoPath, self, #selector(fw_saveVideo(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    @objc private func fw_saveImage(_ image: UIImage?, didFinishSavingWithError error: Error?, contextInfo: Any?) {
        let block = fw_property(forName: "fw_saveImage") as? (Error?) -> Void
        fw_setPropertyCopy(nil, forName: "fw_saveImage")
        block?(error)
    }
    
    @objc private static func fw_saveVideo(_ videoPath: String?, didFinishSavingWithError error: Error?, contextInfo: Any?) {
        let block = UIImage.fw_property(forName: "fw_saveVideo") as? (Error?) -> Void
        UIImage.fw_setPropertyCopy(nil, forName: "fw_saveVideo")
        block?(error)
    }
    
    /// 获取灰度图
    public var fw_grayImage: UIImage? {
        let width: Int = Int(self.size.width)
        let height: Int = Int(self.size.height)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue),
              let cgImage = self.cgImage else { return nil }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let imageRef = context.makeImage() else { return nil }
        return UIImage(cgImage: imageRef)
    }

    /// 获取图片的平均颜色
    public var fw_averageColor: UIColor? {
        guard let ciImage = ciImage ?? CIImage(image: self) else { return nil }

        let parameters = [kCIInputImageKey: ciImage, kCIInputExtentKey: CIVector(cgRect: ciImage.extent)]
        guard let outputImage = CIFilter(name: "CIAreaAverage", parameters: parameters)?.outputImage else {
            return nil
        }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let workingColorSpace: Any = cgImage?.colorSpace ?? NSNull()
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
    public func fw_image(reflectScale: CGFloat) -> UIImage? {
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
        
        let height = ceil(self.size.height * reflectScale)
        let size = CGSize(width: self.size.width, height: height)
        let bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        if let sharedMask = sharedMask {
            context?.clip(to: bounds, mask: sharedMask)
        }
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.translateBy(x: 0, y: -self.size.height)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 倒影图片
    public func fw_image(reflectScale: CGFloat, gap: CGFloat, alpha: CGFloat) -> UIImage? {
        let reflection = fw_image(reflectScale: reflectScale)
        let reflectionOffset = (reflection?.size.height ?? 0) + gap
        UIGraphicsBeginImageContextWithOptions(CGSize(width: self.size.width, height: self.size.height + reflectionOffset * 2.0), false, 0)
        reflection?.draw(at: CGPoint(x: 0, y: reflectionOffset + self.size.height + gap), blendMode: .normal, alpha: alpha)
        self.draw(at: CGPoint(x: 0, y: reflectionOffset))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 阴影图片
    public func fw_image(shadowColor: UIColor, offset: CGSize, blur: CGFloat) -> UIImage? {
        let border = CGSize(width: abs(offset.width) + blur, height: abs(offset.height) + blur)
        let size = CGSize(width: self.size.width + border.width * 2.0, height: self.size.height + border.height * 2.0)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        context?.setShadow(offset: offset, blur: blur, color: shadowColor.cgColor)
        self.draw(at: CGPoint(x: border.width, y: border.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 高斯模糊图片，默认模糊半径为10
    public func fw_blurredImage(radius: CGFloat = 10) -> UIImage? {
        guard let cgImage = cgImage else {
            return self
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
        
        let w = Int(size.width)
        let h = Int(size.height)
        
        func createEffectBuffer(_ context: CGContext) -> vImage_Buffer {
            let data = context.data
            let width = vImagePixelCount(context.width)
            let height = vImagePixelCount(context.height)
            let rowBytes = context.bytesPerRow
            
            return vImage_Buffer(data: data, height: height, width: width, rowBytes: rowBytes)
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return self
        }
        context.scaleBy(x: 1.0, y: -1.0)
        context.translateBy(x: 0, y: -size.height)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
        UIGraphicsEndImageContext()
        var inBuffer = createEffectBuffer(context)
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        guard let outContext = UIGraphicsGetCurrentContext() else {
            return self
        }
        outContext.scaleBy(x: 1.0, y: -1.0)
        outContext.translateBy(x: 0, y: -size.height)
        defer { UIGraphicsEndImageContext() }
        var outBuffer = createEffectBuffer(outContext)
        
        for _ in 0 ..< iterations {
            let flag = vImage_Flags(kvImageEdgeExtend)
            vImageBoxConvolve_ARGB8888(
                &inBuffer, &outBuffer, nil, 0, 0, UInt32(targetRadius), UInt32(targetRadius), nil, flag)
            (inBuffer, outBuffer) = (outBuffer, inBuffer)
        }
        
        let result = outContext.makeImage().flatMap {
            UIImage(cgImage: $0, scale: self.scale, orientation: self.imageOrientation)
        }
        guard let blurredImage = result else {
            return self
        }
        return blurredImage
    }
    
    /// 图片裁剪，可指定frame、角度、圆形等
    public func fw_croppedImage(frame: CGRect, angle: Int, circular: Bool) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(frame.size, !self.fw_hasAlpha && !circular, self.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        if circular {
            context.addEllipse(in: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
            context.clip()
        }
        
        if angle != 0 {
            let imageView = UIImageView(image: self)
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
            self.draw(at: .zero)
        }
        
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = croppedImage?.cgImage else { return nil }
        return UIImage(cgImage: cgImage, scale: self.scale, orientation: .up)
    }

    /// 如果没有透明通道，增加透明通道
    public var fw_alphaImage: UIImage {
        guard !fw_hasAlpha,
              let imageRef = self.cgImage,
              let colorSpace = imageRef.colorSpace else { return self }
        
        let width = imageRef.width
        let height = imageRef.height
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGBitmapInfo.byteOrderDefault.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        context?.draw(imageRef, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let alphaImageRef = context?.makeImage() else { return self }
        let alphaImage = UIImage(cgImage: alphaImageRef)
        return alphaImage
    }

    /// 截取View所有视图，包括旋转缩放效果
    public static func fw_image(view: UIView, limitWidth: CGFloat) -> UIImage? {
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
    public static func fw_appIconImage() -> UIImage? {
        let infoPlist = Bundle.main.infoDictionary as? NSDictionary
        let iconFiles = infoPlist?.value(forKeyPath: "CFBundleIcons.CFBundlePrimaryIcon.CFBundleIconFiles") as? NSArray
        guard let iconName = iconFiles?.lastObject as? String else { return nil }
        return UIImage(named: iconName)
    }

    /// 获取AppIcon指定尺寸图片，名称格式：AppIcon60x60
    public static func fw_appIconImage(size: CGSize) -> UIImage? {
        let iconName = String(format: "AppIcon%.0fx%.0f", size.width, size.height)
        return UIImage(named: iconName)
    }

    /// 从Pdf数据或者路径创建指定大小UIImage
    public static func fw_image(pdf path: Any, size: CGSize = .zero) -> UIImage? {
        var pdf: CGPDFDocument?
        if let data = path as? Data {
            if let provider = CGDataProvider(data: data as CFData) {
                pdf = CGPDFDocument(provider)
            }
        } else if let path = path as? String {
            pdf = CGPDFDocument(NSURL.fileURL(withPath: path) as CFURL)
        }
        guard let pdf = pdf else { return nil }
        guard let page = pdf.page(at: 1) else { return nil }
        
        let pdfRect = page.getBoxRect(.cropBox)
        let pdfSize = size.equalTo(.zero) ? pdfRect.size : size
        let scale = UIScreen.main.scale
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
    public static func fw_gradientImage(size: CGSize, colors: [Any], locations: UnsafePointer<CGFloat>?, direction: UISwipeGestureRecognizer.Direction) -> UIImage? {
        let linePoints = UIBezierPath.fw_linePoints(rect: CGRect(x: 0, y: 0, width: size.width, height: size.height), direction: direction)
        let startPoint = linePoints.first?.cgPointValue ?? .zero
        let endPoint = linePoints.last?.cgPointValue ?? .zero
        return fw_gradientImage(size: size, colors: colors, locations: locations, startPoint: startPoint, endPoint: endPoint)
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

// MARK: - UIView+Toolkit
/// 视图状态枚举，兼容UIKit和SwiftUI
public enum ViewState: Equatable {
    
    case ready
    case loading
    case success(Any? = nil)
    case failure(Error? = nil)
    
    /// 获取成功状态的对象，其他状态返回nil
    public var object: Any? {
        if case .success(let object) = self {
            return object
        }
        return nil
    }
    
    /// 获取失败状态的错误，其他状态返回nil
    public var error: Error? {
        if case .failure(let error) = self {
            return error
        }
        return nil
    }
    
    /// 实现Equatable协议方法，仅比较状态，不比较值
    public static func == (lhs: ViewState, rhs: ViewState) -> Bool {
        switch lhs {
        case .ready:
            if case .ready = rhs { return true }
        case .loading:
            if case .loading = rhs { return true }
        case .success(_):
            if case .success(_) = rhs { return true }
        case .failure(_):
            if case .failure(_) = rhs { return true }
        }
        return false
    }
    
}

@_spi(FW) extension UIView {
    
    /// 顶部纵坐标，frame.origin.y
    public var fw_top: CGFloat {
        get {
            return self.frame.origin.y
        }
        set {
            var frame = self.frame
            frame.origin.y = newValue
            self.frame = frame
        }
    }

    /// 底部纵坐标，frame.origin.y + frame.size.height
    public var fw_bottom: CGFloat {
        get {
            return self.fw_top + self.fw_height
        }
        set {
            self.fw_top = newValue - self.fw_height
        }
    }

    /// 左边横坐标，frame.origin.x
    public var fw_left: CGFloat {
        get {
            return self.frame.origin.x
        }
        set {
            var frame = self.frame
            frame.origin.x = newValue
            self.frame = frame
        }
    }

    /// 右边横坐标，frame.origin.x + frame.size.width
    public var fw_right: CGFloat {
        get {
            return self.fw_left + self.fw_width
        }
        set {
            self.fw_left = newValue - self.fw_width
        }
    }

    /// 宽度，frame.size.width
    public var fw_width: CGFloat {
        get {
            return self.frame.size.width
        }
        set {
            var frame = self.frame
            frame.size.width = newValue
            self.frame = frame
        }
    }

    /// 高度，frame.size.height
    public var fw_height: CGFloat {
        get {
            return self.frame.size.height
        }
        set {
            var frame = self.frame
            frame.size.height = newValue
            self.frame = frame
        }
    }

    /// 中心横坐标，center.x
    public var fw_centerX: CGFloat {
        get {
            return self.center.x
        }
        set {
            self.center = CGPoint(x: newValue, y: self.center.y)
        }
    }

    /// 中心纵坐标，center.y
    public var fw_centerY: CGFloat {
        get {
            return self.center.y
        }
        set {
            self.center = CGPoint(x: self.center.x, y: newValue)
        }
    }

    /// 起始横坐标，frame.origin.x
    public var fw_x: CGFloat {
        get {
            return self.frame.origin.x
        }
        set {
            var frame = self.frame
            frame.origin.x = newValue
            self.frame = frame
        }
    }

    /// 起始纵坐标，frame.origin.y
    public var fw_y: CGFloat {
        get {
            return self.frame.origin.y
        }
        set {
            var frame = self.frame
            frame.origin.y = newValue
            self.frame = frame
        }
    }

    /// 起始坐标，frame.origin
    public var fw_origin: CGPoint {
        get {
            return self.frame.origin
        }
        set {
            var frame = self.frame
            frame.origin = newValue
            self.frame = frame
        }
    }

    /// 大小，frame.size
    public var fw_size: CGSize {
        get {
            return self.frame.size
        }
        set {
            var frame = self.frame
            frame.size = newValue
            self.frame = frame
        }
    }
    
}

// MARK: - UIViewController+Toolkit
/// 视图控制器常用生命周期状态枚举
public enum ViewControllerLifecycleState: Int {
    case didInit = 0
    case didLoad = 1
    case willAppear = 2
    case isAppearing = 3
    case didLayoutSubviews = 4
    case didAppear = 5
    case willDisappear = 6
    case didDisappear = 7
    case didDeinit = 8
}

/// 为提升性能，触发lifecycleState改变等的swizzle代码统一放到了ViewController
@_spi(FW) extension UIViewController {
    
    private class LifecycleStateTarget: NSObject {
        var block: ((UIViewController, ViewControllerLifecycleState) -> Void)?
    }
    
    /// 当前生命周期状态，默认didInit
    public internal(set) var fw_lifecycleState: ViewControllerLifecycleState {
        get {
            let value = fw_propertyInt(forName: "fw_lifecycleState")
            return .init(rawValue: value) ?? .didInit
        }
        set {
            let valueChanged = self.fw_lifecycleState != newValue
            fw_setPropertyInt(newValue.rawValue, forName: "fw_lifecycleState")
            
            if valueChanged, let targets = fw_lifecycleStateTargets(false) {
                for (_, elem) in targets.enumerated() {
                    if let target = elem as? LifecycleStateTarget {
                        target.block?(self, newValue)
                    }
                }
            }
        }
    }

    /// 添加生命周期变化监听句柄，返回监听者observer
    @discardableResult
    public func fw_observeLifecycleState(_ block: @escaping (UIViewController, ViewControllerLifecycleState) -> Void) -> NSObjectProtocol {
        let targets = fw_lifecycleStateTargets(true)
        let target = LifecycleStateTarget()
        target.block = block
        targets?.add(target)
        return target
    }
    
    /// 移除生命周期监听者，传nil时移除所有
    @discardableResult
    public func fw_unobserveLifecycleState(observer: Any? = nil) -> Bool {
        guard let targets = fw_lifecycleStateTargets(false) else { return false }
        
        if let observer = observer as? LifecycleStateTarget {
            var result = false
            for (_, elem) in targets.enumerated() {
                if let target = elem as? LifecycleStateTarget, observer == target {
                    targets.remove(target)
                    result = true
                }
            }
            return result
        } else {
            targets.removeAllObjects()
            return true
        }
    }
    
    private func fw_lifecycleStateTargets(_ lazyload: Bool) -> NSMutableArray? {
        var targets = fw_property(forName: "fw_lifecycleStateTargets") as? NSMutableArray
        if targets == nil && lazyload {
            targets = NSMutableArray()
            fw_setProperty(targets, forName: "fw_lifecycleStateTargets")
        }
        return targets
    }

    /// 自定义完成结果对象，默认nil
    public var fw_completionResult: Any? {
        get { fw_property(forName: "fw_completionResult") }
        set { fw_setProperty(newValue, forName: "fw_completionResult") }
    }

    /// 自定义完成句柄，默认nil，dealloc时自动调用，参数为fwCompletionResult。支持提前调用，调用后需置为nil
    public var fw_completionHandler: ((Any?) -> Void)? {
        get { fw_property(forName: "fw_completionHandler") as? (Any?) -> Void }
        set { fw_setPropertyCopy(newValue, forName: "fw_completionHandler") }
    }

    /// 自定义侧滑返回手势VC开关句柄，enablePopProxy启用后生效，仅处理边缘返回手势，优先级低，默认nil
    public var fw_allowsPopGesture: (() -> Bool)? {
        get { fw_property(forName: "fw_allowsPopGesture") as? () -> Bool }
        set { fw_setPropertyCopy(newValue, forName: "fw_allowsPopGesture") }
    }

    /// 自定义控制器返回VC开关句柄，enablePopProxy启用后生效，统一处理返回按钮点击和边缘返回手势，优先级高，默认nil
    public var fw_shouldPopController: (() -> Bool)? {
        get { fw_property(forName: "fw_shouldPopController") as? () -> Bool }
        set { fw_setPropertyCopy(newValue, forName: "fw_shouldPopController") }
    }
    
}

@objc extension UIViewController {
    
    /// 自定义侧滑返回手势VC开关，enablePopProxy启用后生效，仅处理边缘返回手势，优先级低，自动调用fw.allowsPopGesture，默认true
    open var allowsPopGesture: Bool {
        if let block = fw_allowsPopGesture {
            return block()
        }
        return true
    }
    
    /// 自定义控制器返回VC开关，enablePopProxy启用后生效，统一处理返回按钮点击和边缘返回手势，优先级高，自动调用fw.shouldPopController，默认true
    open var shouldPopController: Bool {
        if let block = fw_shouldPopController {
            return block()
        }
        return true
    }
    
}

// MARK: - UINavigationController+Toolkit
@objc fileprivate protocol GestureRecognizerDelegateCompatible {
    
    @objc optional func _gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceiveEvent event: UIEvent) -> Bool
    
}

/// 当自定义left按钮或隐藏导航栏之后，系统返回手势默认失效，可调用此方法全局开启返回代理。开启后自动将开关代理给顶部VC的shouldPopController、popGestureEnabled属性控制。interactivePop手势禁用时不生效
@_spi(FW) extension UINavigationController {
    
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
            return true
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return gestureRecognizer is UIScreenEdgePanGestureRecognizer
        }
        
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
                    if let shouldBegin = self.delegate?.gestureRecognizerShouldBegin?(gestureRecognizer) {
                        return shouldBegin
                    }
                }
                return false
            }
            return true
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            if gestureRecognizer == navigationController?.interactivePopGestureRecognizer {
                if let shouldReceive = self.delegate?.gestureRecognizer?(gestureRecognizer, shouldReceive: touch) {
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
            if gestureRecognizer == self.navigationController?.interactivePopGestureRecognizer {
                if self.delegate?.responds(to: #selector(_gestureRecognizer(_:shouldReceiveEvent:))) ?? false,
                   let shouldReceive = self.target?._gestureRecognizer?(gestureRecognizer, shouldReceiveEvent: event) {
                    if !shouldReceive && shouldForceReceive() {
                        return true
                    }
                    return shouldReceive
                }
            }
            return true
        }
        
    }
    
    /// 单独启用返回代理拦截，优先级高于+enablePopProxy，启用后支持shouldPopController、allowsPopGesture功能，默认NO未启用
    public func fw_enablePopProxy() {
        self.interactivePopGestureRecognizer?.delegate = self.fw_popProxyTarget
        fw_setPropertyBool(true, forName: "fw_popProxyEnabled")
        UINavigationController.fw_swizzleToolkitNavigationController()
    }
    
    /// 全局启用返回代理拦截，优先级低于-enablePopProxy，启用后支持shouldPopController、allowsPopGesture功能，默认NO未启用
    public static func fw_enablePopProxy() {
        fw_staticPopProxyEnabled = true
        fw_swizzleToolkitNavigationController()
    }
    
    private var fw_popProxyEnabled: Bool {
        return fw_propertyBool(forName: "fw_popProxyEnabled")
    }
    
    private var fw_popProxyTarget: PopProxyTarget {
        if let proxy = fw_property(forName: "fw_popProxyTarget") as? PopProxyTarget {
            return proxy
        } else {
            let proxy = PopProxyTarget(navigationController: self)
            fw_setProperty(proxy, forName: "fw_popProxyTarget")
            return proxy
        }
    }
    
    private var fw_delegateProxy: GestureRecognizerDelegateProxy {
        if let proxy = fw_property(forName: "fw_delegateProxy") as? GestureRecognizerDelegateProxy {
            return proxy
        } else {
            let proxy = GestureRecognizerDelegateProxy()
            fw_setProperty(proxy, forName: "fw_delegateProxy")
            return proxy
        }
    }
    
    private static var fw_staticPopProxyEnabled = false
    private static var fw_staticPopProxySwizzled = false
    
    private static func fw_swizzleToolkitNavigationController() {
        guard !fw_staticPopProxySwizzled else { return }
        fw_staticPopProxySwizzled = true
        
        NSObject.fw_swizzleInstanceMethod(
            UINavigationController.self,
            selector: #selector(UINavigationBarDelegate.navigationBar(_:shouldPop:)),
            methodSignature: (@convention(c) (UINavigationController, Selector, UINavigationBar, UINavigationItem) -> Bool).self,
            swizzleSignature: (@convention(block) (UINavigationController, UINavigationBar, UINavigationItem) -> Bool).self
        ) { store in { selfObject, navigationBar, item in
            if fw_staticPopProxyEnabled || selfObject.fw_popProxyEnabled {
                // 检查并调用返回按钮钩子。如果返回NO，则不pop当前页面；如果返回YES，则使用默认方式
                if selfObject.viewControllers.count >= (navigationBar.items?.count ?? 0) &&
                    !(selfObject.topViewController?.shouldPopController ?? false) {
                    return false
                }
            }
            
            return store.original(selfObject, store.selector, navigationBar, item)
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UINavigationController.self,
            selector: #selector(UIViewController.viewDidLoad),
            methodSignature: (@convention(c) (UINavigationController, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UINavigationController) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            if !fw_staticPopProxyEnabled || selfObject.fw_popProxyEnabled { return }
            
            // 拦截系统返回手势事件代理，加载自定义代理方法
            if !(selfObject.interactivePopGestureRecognizer?.delegate is GestureRecognizerDelegateProxy) {
                selfObject.fw_delegateProxy.delegate = selfObject.interactivePopGestureRecognizer?.delegate
                selfObject.fw_delegateProxy.navigationController = selfObject
                selfObject.interactivePopGestureRecognizer?.delegate = selfObject.fw_delegateProxy
            }
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UINavigationController.self,
            selector: #selector(getter: UINavigationController.childForStatusBarHidden),
            methodSignature: (@convention(c) (UINavigationController, Selector) -> UIViewController?).self,
            swizzleSignature: (@convention(block) (UINavigationController) -> UIViewController?).self
        ) { store in { selfObject in
            if fw_staticPopProxyEnabled && selfObject.topViewController != nil {
                return selfObject.topViewController
            } else {
                return store.original(selfObject, store.selector)
            }
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UINavigationController.self,
            selector: #selector(getter: UINavigationController.childForStatusBarStyle),
            methodSignature: (@convention(c) (UINavigationController, Selector) -> UIViewController?).self,
            swizzleSignature: (@convention(block) (UINavigationController) -> UIViewController?).self
        ) { store in { selfObject in
            if fw_staticPopProxyEnabled && selfObject.topViewController != nil {
                return selfObject.topViewController
            } else {
                return store.original(selfObject, store.selector)
            }
        }}
    }
    
}
