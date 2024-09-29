//
//  Bundle.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - ModuleBundle
/// 业务模块Bundle基类，各模块可继承
///
/// 资源查找规则如下：
/// 1. ModuleBundle基类或主应用模块类只加载主Bundle
/// 2. ModuleBundle子模块类优先加载主应用的{模块名称}.bundle(可替换模块)，如主应用内FWFramework.bundle
/// 3. ModuleBundle子模块类其次加载该模块的{模块名称}.bundle，如框架内FWFramework.bundle
/// 4. ModuleBundle子模块类以上都不存在时返回nil加载主Bundle
open class ModuleBundle: NSObject {
    actor Configuration {
        static var imageNamedBlock: (@Sendable (_ name: String, _ bundle: Bundle?) -> UIImage?)?
    }

    private class Target: @unchecked Sendable {
        let identifier = UUID().uuidString
        var bundle: Bundle?
        var images: [String: Any] = [:]
        var colors: [String: Any] = [:]
        var strings: [String: [String: [String: String]]] = [:]
    }

    /// 获取当前模块Bundle并缓存，initializeBundle为空时默认主Bundle
    open class func bundle() -> Bundle {
        if let bundle = bundleTarget.bundle {
            return bundle
        } else {
            let bundle = initializeBundle() ?? .main
            bundleTarget.bundle = bundle
            didInitialize()
            return bundle
        }
    }

    /// 获取当前模块图片
    open class func imageNamed(_ name: String) -> UIImage? {
        if let image = Configuration.imageNamedBlock?(name, bundle()) {
            return image
        } else if let image = UIImage(named: name, in: bundle(), compatibleWith: nil) {
            return image
        }

        let value = bundleTarget.images[name]
        if let image = value as? UIImage {
            return image
        } else if let block = value as? @Sendable () -> UIImage? {
            return block()
        }
        return nil
    }

    /// 设置当前模块动态图片
    open class func addImage(_ name: String, image: UIImage?) {
        bundleTarget.images[name] = image
    }

    /// 设置当前模块动态图片句柄
    open class func addImage(_ name: String, block: (@Sendable () -> UIImage?)?) {
        bundleTarget.images[name] = block
    }

    /// 获取当前模块颜色，不存在时默认clear
    open class func colorNamed(_ name: String) -> UIColor {
        if let color = UIColor(named: name, in: bundle(), compatibleWith: nil) { return color }

        let value = bundleTarget.colors[name]
        if let color = value as? UIColor {
            return color
        } else if let block = value as? @Sendable () -> UIColor {
            return block()
        }
        return .clear
    }

    /// 设置当前模块动态颜色
    open class func addColor(_ name: String, color: UIColor?) {
        bundleTarget.colors[name] = color
    }

    /// 设置当前模块动态颜色句柄
    open class func addColor(_ name: String, block: (@Sendable () -> UIColor)?) {
        bundleTarget.colors[name] = block
    }

    /// 获取当前模块多语言，可指定文件
    open class func localizedString(_ key: String, table: String? = nil) -> String {
        let localized = bundle().localizedString(forKey: key, value: bundleTarget.identifier, table: table)
        if localized != bundleTarget.identifier { return localized }

        let tableKey = table ?? "Localizable"
        let languageKey = Bundle.fw.currentLanguage ?? "en"
        let tableStrings = bundleTarget.strings[tableKey]
        let languageStrings = tableStrings?[languageKey] ?? tableStrings?["en"]
        return languageStrings?[key] ?? key
    }

    /// 设置当前模块动态多语言
    open class func addStrings(_ language: String? = nil, table: String? = nil, strings: [String: String]) {
        let languageKey = language ?? "en"
        let tableKey = table ?? "Localizable"
        if bundleTarget.strings[tableKey] == nil {
            bundleTarget.strings[tableKey] = [:]
        }
        if bundleTarget.strings[tableKey]?[languageKey] == nil {
            bundleTarget.strings[tableKey]?[languageKey] = strings
        } else {
            bundleTarget.strings[tableKey]?[languageKey]?.merge(strings) { _, last in last }
        }
    }

    /// 获取当前模块资源文件路径
    open class func resourcePath(_ name: String, type: String? = nil) -> String? {
        bundle().path(forResource: name, ofType: type)
    }

    /// 获取当前模块资源文件URL
    open class func resourceURL(_ name: String, type: String? = nil) -> URL? {
        bundle().url(forResource: name, withExtension: type)
    }

    private class var bundleTarget: Target {
        if let target = NSObject.fw.getAssociatedObject(self, key: "bundleTarget") as? Target {
            return target
        } else {
            let target = Target()
            NSObject.fw.setAssociatedObject(self, key: "bundleTarget", value: target)
            return target
        }
    }

    // MARK: - Override
    /// 初始化模块Bundle，子类可重写，用于加载自定义Bundle
    open class func initializeBundle() -> Bundle? {
        // 1. ModuleBundle基类或主应用模块类只加载主Bundle
        let bundleClass: AnyClass = self
        guard self != ModuleBundle.self,
              Bundle(for: bundleClass) != .main,
              let moduleName = Bundle(for: bundleClass).executableURL?.lastPathComponent else {
            return nil
        }

        // 2. ModuleBundle子模块类优先加载主应用的{模块名称}.bundle(可替换模块)，如主应用内FWFramework.bundle
        if let appBundle = Bundle.fw.bundle(name: moduleName) {
            return appBundle.fw.localizedBundle()
        }
        /// 3. ModuleBundle子模块类其次加载该模块的{模块名称}.bundle，如框架内FWFramework.bundle
        if let moduleBundle = Bundle.fw.bundle(with: bundleClass, name: moduleName) {
            return moduleBundle.fw.localizedBundle()
        }
        /// 4. ModuleBundle子模块类以上都不存在时返回nil加载主Bundle
        return nil
    }

    /// 初始化完成钩子，bundle方法自动调用一次，子类可重写，用于加载动态资源等
    open class func didInitialize() {}
}

// MARK: - FrameworkBundle
/// 框架内置应用Bundle类，应用可替换
///
/// 如果主应用存在FWFramework.bundle或主Bundle内包含对应图片|多语言，则优先使用；否则使用框架默认实现。
/// FWFramework本地化配置同App本地化一致即可，如zh-Hans|zh-Hant|en等
public class FrameworkBundle: ModuleBundle {
    // MARK: - Image
    /// 图片，导航栏返回，fw.navBack
    public static var navBackImage: UIImage? { imageNamed("fw.navBack") }
    /// 图片，导航栏关闭，fw.navClose
    public static var navCloseImage: UIImage? { imageNamed("fw.navClose") }
    /// 图片，视频播放大图，fw.videoPlay
    public static var videoPlayImage: UIImage? { imageNamed("fw.videoPlay") }
    /// 图片，视频暂停，fw.videoPause
    public static var videoPauseImage: UIImage? { imageNamed("fw.videoPause") }
    /// 图片，视频开始，fw.videoStart
    public static var videoStartImage: UIImage? { imageNamed("fw.videoStart") }
    /// 图片，相册多选，fw.pickerCheck
    public static var pickerCheckImage: UIImage? { imageNamed("fw.pickerCheck") }
    /// 图片，相册选中，fw.pickerChecked
    public static var pickerCheckedImage: UIImage? { imageNamed("fw.pickerChecked") }

    // MARK: - String
    /// 多语言，取消，fw.cancel
    public static var cancelButton: String { localizedString("fw.cancel") }
    /// 多语言，确定，fw.confirm
    public static var confirmButton: String { localizedString("fw.confirm") }
    /// 多语言，好的，fw.close
    public static var closeButton: String { localizedString("fw.close") }
    /// 多语言，完成，fw.done
    public static var doneButton: String { localizedString("fw.done") }
    /// 多语言，更多，fw.more
    public static var moreButton: String { localizedString("fw.more") }
    /// 多语言，编辑，fw.edit
    public static var editButton: String { localizedString("fw.edit") }
    /// 多语言，预览，fw.preview
    public static var previewButton: String { localizedString("fw.preview") }
    /// 多语言，原图，fw.original
    public static var originalButton: String { localizedString("fw.original") }

    /// 多语言，相册，fw.pickerAlbum
    public static var pickerAlbumTitle: String { localizedString("fw.pickerAlbum") }
    /// 多语言，无照片，fw.pickerEmpty
    public static var pickerEmptyTitle: String { localizedString("fw.pickerEmpty") }
    /// 多语言，无权限，fw.pickerDenied
    public static var pickerDeniedTitle: String { localizedString("fw.pickerDenied") }
    /// 多语言，超出数量，fw.pickerExceed
    public static var pickerExceedTitle: String { localizedString("fw.pickerExceed") }

    /// 多语言，下拉可以刷新，fw.refreshIdle
    public static var refreshIdleTitle: String { localizedString("fw.refreshIdle") }
    /// 多语言，松开立即刷新，fw.refreshTriggered
    public static var refreshTriggeredTitle: String { localizedString("fw.refreshTriggered") }
    /// 多语言，正在刷新数据，fw.refreshLoading
    public static var refreshLoadingTitle: String { localizedString("fw.refreshLoading") }
    /// 多语言，已经全部加载完毕，fw.refreshFinished
    public static var refreshFinishedTitle: String { localizedString("fw.refreshFinished") }
    /// 多语言，身份验证，fw.biometryReason
    public static var biometryReasonTitle: String { localizedString("fw.biometryReason") }

    // MARK: - Override
    override public class func didInitialize() {
        addImage("fw.navBack") {
            let size = CGSize(width: 12, height: 20)
            return UIImage.fw.image(size: size) { context in
                let color = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                context.setStrokeColor(color.cgColor)
                let lineWidth: CGFloat = 2
                let path = UIBezierPath()
                path.move(to: CGPoint(x: size.width - lineWidth / 2, y: lineWidth / 2))
                path.addLine(to: CGPoint(x: lineWidth / 2, y: size.height / 2.0))
                path.addLine(to: CGPoint(x: size.width - lineWidth / 2, y: size.height - lineWidth / 2))
                path.lineWidth = lineWidth
                path.stroke()
            }
        }

        addImage("fw.navClose") {
            let size = CGSize(width: 16, height: 16)
            return UIImage.fw.image(size: size) { context in
                let color = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                context.setStrokeColor(color.cgColor)
                let lineWidth: CGFloat = 2
                let path = UIBezierPath()
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: size.width, y: size.height))
                path.close()
                path.move(to: CGPoint(x: size.width, y: 0))
                path.addLine(to: CGPoint(x: 0, y: size.height))
                path.close()
                path.lineWidth = lineWidth
                path.lineCapStyle = .round
                path.stroke()
            }
        }

        addImage("fw.videoPlay") {
            let size = CGSize(width: 60, height: 60)
            return UIImage.fw.image(size: size) { context in
                let color = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                let fillColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25)
                context.setStrokeColor(color.cgColor)
                context.setFillColor(fillColor.cgColor)
                let lineWidth: CGFloat = 1
                let circle = UIBezierPath(ovalIn: CGRect(x: lineWidth / 2, y: lineWidth / 2, width: size.width - lineWidth, height: size.width - lineWidth))
                circle.lineWidth = lineWidth
                circle.stroke()
                circle.fill()

                context.setFillColor(color.cgColor)
                let triangleLength = size.width / 2.5
                let triangle = UIBezierPath()
                triangle.move(to: CGPoint.zero)
                triangle.addLine(to: CGPoint(x: triangleLength * cos(CGFloat.pi / 6), y: triangleLength / 2))
                triangle.addLine(to: CGPoint(x: 0, y: triangleLength))
                triangle.close()
                let offset = UIOffset(horizontal: size.width / 2 - triangleLength * tan(CGFloat.pi / 6) / 2, vertical: size.width / 2 - triangleLength / 2)
                triangle.apply(CGAffineTransformMakeTranslation(offset.horizontal, offset.vertical))
                triangle.fill()
            }
        }

        addImage("fw.videoPause") {
            let size = CGSize(width: 12, height: 18)
            return UIImage.fw.image(size: size) { context in
                let color = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                context.setStrokeColor(color.cgColor)
                let lineWidth: CGFloat = 2
                let path = UIBezierPath()
                path.move(to: CGPoint(x: lineWidth / 2, y: 0))
                path.addLine(to: CGPoint(x: lineWidth / 2, y: size.height))
                path.move(to: CGPoint(x: size.width - lineWidth / 2, y: 0))
                path.addLine(to: CGPoint(x: size.width - lineWidth / 2, y: size.height))
                path.lineWidth = lineWidth
                path.stroke()
            }
        }

        addImage("fw.videoStart") {
            let size = CGSize(width: 17, height: 17)
            return UIImage.fw.image(size: size) { context in
                let color = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                context.setStrokeColor(color.cgColor)
                let path = UIBezierPath()
                path.move(to: CGPoint.zero)
                path.addLine(to: CGPoint(x: size.width * cos(CGFloat.pi / 6), y: size.width / 2))
                path.addLine(to: CGPoint(x: 0, y: size.width))
                path.close()
                path.fill()
            }
        }

        addImage("fw.pickerCheck") {
            let size = CGSize(width: 20, height: 20)
            return UIImage.fw.image(size: size) { context in
                let color = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                let fillColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25)
                context.setStrokeColor(color.cgColor)
                context.setFillColor(fillColor.cgColor)
                let lineWidth: CGFloat = 2
                let circle = UIBezierPath(ovalIn: CGRect(x: lineWidth / 2, y: lineWidth / 2, width: size.width - lineWidth, height: size.width - lineWidth))
                circle.lineWidth = lineWidth
                circle.stroke()
                circle.fill()
            }
        }

        addImage("fw.pickerChecked") {
            let size = CGSize(width: 20, height: 20)
            return UIImage.fw.image(size: size) { context in
                let color = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                let fillColor = UIColor(red: 7.0 / 255.0, green: 193.0 / 255.0, blue: 96.0 / 255.0, alpha: 1.0)
                context.setStrokeColor(color.cgColor)
                context.setFillColor(fillColor.cgColor)
                let circle = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size.width, height: size.width))
                circle.fill()

                let checkSize = CGSize(width: 9, height: 7)
                let checkOrigin = CGPoint(x: (size.width - checkSize.width) / 2.0, y: (size.height - checkSize.height) / 2.0)
                let lineWidth: CGFloat = 1
                let lineAngle = CGFloat.pi / 4
                let path = UIBezierPath()
                path.move(to: CGPoint(x: checkOrigin.x, y: checkOrigin.y + checkSize.height / 2))
                path.addLine(to: CGPoint(x: checkOrigin.x + checkSize.width / 3, y: checkOrigin.y + checkSize.height))
                path.addLine(to: CGPoint(x: checkOrigin.x + checkSize.width, y: checkOrigin.y + lineWidth * sin(lineAngle)))
                path.addLine(to: CGPoint(x: checkOrigin.x + checkSize.width - lineWidth * cos(lineAngle), y: checkOrigin.y))
                path.addLine(to: CGPoint(x: checkOrigin.x + checkSize.width / 3, y: checkOrigin.y + checkSize.height - lineWidth / sin(lineAngle)))
                path.addLine(to: CGPoint(x: checkOrigin.x + lineWidth * sin(lineAngle), y: checkOrigin.y + checkSize.height / 2 - lineWidth * sin(lineAngle)))
                path.close()
                path.lineWidth = lineWidth
                path.stroke()
            }
        }

        addStrings("zh-Hans", strings: [
            "fw.done": "完成",
            "fw.close": "好的",
            "fw.confirm": "确定",
            "fw.cancel": "取消",
            "fw.more": "更多",
            "fw.original": "原图",
            "fw.edit": "编辑",
            "fw.preview": "预览",
            "fw.pickerAlbum": "相册",
            "fw.pickerEmpty": "无照片",
            "fw.pickerDenied": "请在iPhone的\"设置-隐私-照片\"选项中，允许%@访问你的照片",
            "fw.pickerExceed": "最多只能选择%@张图片",
            "fw.refreshIdle": "下拉可以刷新   ",
            "fw.refreshTriggered": "松开立即刷新   ",
            "fw.refreshLoading": "正在刷新数据...",
            "fw.refreshFinished": "已经全部加载完毕",
            "fw.biometryReason": "身份验证"
        ])

        addStrings("zh-Hant", strings: [
            "fw.done": "完成",
            "fw.close": "好的",
            "fw.confirm": "確定",
            "fw.cancel": "取消",
            "fw.more": "更多",
            "fw.original": "原圖",
            "fw.edit": "編輯",
            "fw.preview": "預覽",
            "fw.pickerAlbum": "相冊",
            "fw.pickerEmpty": "無照片",
            "fw.pickerDenied": "請在iPhone的\"設置-隱私-相冊\"選項中，允許%@訪問你的照片",
            "fw.pickerExceed": "最多只能選擇%@張圖片",
            "fw.refreshIdle": "下拉可以刷新   ",
            "fw.refreshTriggered": "鬆開立即刷新   ",
            "fw.refreshLoading": "正在刷新數據...",
            "fw.refreshFinished": "已經全部加載完畢",
            "fw.biometryReason": "身份驗證"
        ])

        addStrings("en", strings: [
            "fw.done": "Done",
            "fw.close": "OK",
            "fw.confirm": "Confirm",
            "fw.cancel": "Cancel",
            "fw.more": "More",
            "fw.original": "Original",
            "fw.edit": "Edit",
            "fw.preview": "Preview",
            "fw.pickerAlbum": "Album",
            "fw.pickerEmpty": "No Photo",
            "fw.pickerDenied": "Please allow %@ to access your album in \"Settings\"->\"Privacy\"->\"Photos\"",
            "fw.pickerExceed": "Max count for selection: %@",
            "fw.refreshIdle": "Pull down to refresh",
            "fw.refreshTriggered": "Release to refresh",
            "fw.refreshLoading": "Loading...",
            "fw.refreshFinished": "No more data",
            "fw.biometryReason": "Authenticate"
        ])
    }
}
