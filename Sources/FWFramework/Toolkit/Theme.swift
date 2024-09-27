//
//  Theme.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

// MARK: - Wrapper+UIColor
extension Wrapper where Base: UIColor {
    /// 指定主题样式获取对应静态颜色，iOS13+可跟随系统改变
    public func color(forStyle style: ThemeStyle) -> UIColor {
        if let themeObject {
            return themeObject.object(for: style) ?? base
        }

        let traitCollection = UITraitCollection(userInterfaceStyle: style == .dark ? .dark : .light)
        return base.resolvedColor(with: traitCollection)
    }

    /// 是否是主题颜色，仅支持判断使用fwTheme创建的颜色
    public var isThemeColor: Bool {
        themeObject != nil
    }

    private var themeObject: ThemeObject<UIColor>? {
        get { property(forName: "themeObject") as? ThemeObject<UIColor> }
        set { setProperty(newValue, forName: "themeObject") }
    }

    /// 动态创建主题色，分别指定浅色和深色
    public static func themeLight(_ light: UIColor, dark: UIColor) -> UIColor {
        themeColor { style in
            style == .dark ? dark : light
        }
    }

    /// 动态创建主题色，指定提供句柄
    public static func themeColor(_ provider: @escaping (ThemeStyle) -> UIColor) -> UIColor {
        let color = UIColor { traitCollection in
            provider(ThemeManager.shared.style(for: traitCollection))
        }
        color.fw.themeObject = ThemeObject(provider: provider)
        return color
    }

    /// 动态创建主题色，指定名称和bundle，兼容iOS11+系统方式(仅iOS13+支持动态颜色)和手工指定。失败时返回clear防止崩溃
    public static func themeNamed(_ name: String, bundle: Bundle? = nil) -> UIColor {
        if let themeColor = ThemeManager.shared.themeColors[name] {
            return themeColor
        }

        return themeColor { style in
            if let color = UIColor(named: name, in: bundle, compatibleWith: nil) {
                let traitCollection = UITraitCollection(userInterfaceStyle: style == .dark ? .dark : .light)
                return color.resolvedColor(with: traitCollection)
            }
            return .clear
        }
    }

    /// 手工单个注册主题色，未配置主题色或者需兼容iOS11以下时可使用本方式
    public static func setThemeColor(_ color: UIColor?, forName name: String) {
        ThemeManager.shared.themeColors[name] = color
    }

    /// 手工批量注册主题色，未配置主题色或者需兼容iOS11以下时可使用本方式
    public static func setThemeColors(_ nameColors: [String: UIColor]) {
        ThemeManager.shared.themeColors.merge(nameColors) { _, last in last }
    }
}

// MARK: - Wrapper+UIImage
/// 注意UIImage默认只有name方式且配置了any和dark才支持动态切换，否则只能重新赋值才会变化。
/// 为避免内存泄漏，通过fwTheme方式创建的主题图片不能直接用于显示，显示时请调用fwImage方法
extension Wrapper where Base: UIImage {
    /// 获取当前主题样式对应静态图片用于显示，iOS13+可跟随系统改变
    public var image: UIImage? {
        if let themeObject {
            return themeObject.object
        } else {
            return base
        }
    }

    /// 指定主题样式获取对应静态图片用于显示，iOS13+可跟随系统改变
    public func image(forStyle style: ThemeStyle) -> UIImage? {
        if let themeObject {
            return themeObject.object(for: style)
        } else {
            return base
        }
    }

    /// 是否是主题图片，仅支持判断使用fwTheme创建的图片
    public var isThemeImage: Bool {
        themeObject != nil
    }

    private var themeObject: ThemeObject<UIImage>? {
        get { property(forName: "themeObject") as? ThemeObject<UIImage> }
        set { setProperty(newValue, forName: "themeObject") }
    }

    // MARK: - Color
    /// 快速生成当前图片对应的默认主题图片
    public var themeImage: UIImage {
        themeImage(color: UIImage.fw.themeImageColor)
    }

    /// 指定主题颜色，快速生成当前图片对应的主题图片
    public func themeImage(color themeColor: UIColor) -> UIImage {
        let strongBase = base
        return UIImage.fw.themeImage { style in
            guard let image = strongBase.fw.image(forStyle: style) else { return nil }
            let color = themeColor.fw.color(forStyle: style)

            UIGraphicsBeginImageContextWithOptions(image.size, false, 0)
            color.setFill()
            let bounds = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            UIRectFill(bounds)
            image.draw(in: bounds, blendMode: .destinationIn, alpha: 1.0)
            let themeImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return themeImage
        }
    }

    // MARK: - Theme
    /// 创建主题模拟动态图像，分别指定浅色和深色，不支持动态切换，需重新赋值才会变化
    public static func themeLight(_ light: UIImage?, dark: UIImage?) -> UIImage {
        themeImage { style in
            style == .dark ? dark : light
        }
    }

    /// 创建主题模拟动态图像，指定提供句柄，不支持动态切换，需重新赋值才会变化
    public static func themeImage(_ provider: @escaping (ThemeStyle) -> UIImage?) -> UIImage {
        let image = UIImage()
        image.fw.themeObject = ThemeObject(provider: provider)
        return image
    }

    /// 创建主题模拟动态图像，指定名称和bundle，兼容系统方式(仅iOS13+支持动态图像)和手工指定，支持动态切换，需配置any和dark
    public static func themeNamed(_ name: String, bundle: Bundle? = nil) -> UIImage {
        if let themeImage = ThemeManager.shared.themeImages[name] {
            return themeImage
        }

        return themeImage { style in
            var image = UIImage(named: name, in: bundle, compatibleWith: nil)
            let traitCollection = UITraitCollection(userInterfaceStyle: style == .dark ? .dark : .light)
            image = image?.withConfiguration(traitCollection.imageConfiguration)
            return image
        }
    }

    /// 手工单个注册主题图像，未配置主题图像时可使用本方式
    public static func setThemeImage(_ image: UIImage?, forName name: String) {
        ThemeManager.shared.themeImages[name] = image
    }

    /// 手工批量注册主题图像，未配置主题图像时可使用本方式
    public static func setThemeImages(_ nameImages: [String: UIImage]) {
        ThemeManager.shared.themeImages.merge(nameImages) { _, last in last }
    }

    // MARK: - Color
    /// 默认主题图片颜色，未设置时为浅色=>黑色，深色=>白色
    public static var themeImageColor: UIColor {
        themeImageColorConfiguration?() ?? UIColor.fw.themeLight(.black, dark: .white)
    }

    /// 默认主题图片颜色配置句柄，默认nil
    public static var themeImageColorConfiguration: (() -> UIColor)? {
        get { ThemeManager.shared.themeImageColorConfiguration }
        set { ThemeManager.shared.themeImageColorConfiguration = newValue }
    }
}

// MARK: - Wrapper+UIImageAsset
extension Wrapper where Base: UIImageAsset {
    /// 获取当前主题样式对应静态图片用于显示，iOS13+可跟随系统改变
    public var image: UIImage? {
        image(forStyle: ThemeManager.shared.style)
    }

    /// 指定主题样式获取对应静态图片用于显示，iOS13+可跟随系统改变
    public func image(forStyle style: ThemeStyle) -> UIImage? {
        let isThemeAsset = propertyBool(forName: "isThemeAsset")
        if isThemeAsset {
            let traitCollection = UITraitCollection(userInterfaceStyle: style == .dark ? .dark : .light)
            return base.image(with: traitCollection)
        }

        return themeObject?.object(for: style)
    }

    /// 是否是主题图片资源，仅支持判断使用fwTheme创建的图片资源
    public var isThemeAsset: Bool {
        let isThemeAsset = propertyBool(forName: "isThemeAsset")
        return isThemeAsset || themeObject != nil
    }

    private var themeObject: ThemeObject<UIImage>? {
        get { property(forName: "themeObject") as? ThemeObject<UIImage> }
        set { setProperty(newValue, forName: "themeObject") }
    }

    /// 创建主题动态图片资源，分别指定浅色和深色，系统方式，推荐使用
    public static func themeLight(_ light: UIImage?, dark: UIImage?) -> UIImageAsset {
        let asset = UIImageAsset()
        if let light {
            asset.register(light, with: UITraitCollection(userInterfaceStyle: .light))
        }
        if let dark {
            asset.register(dark, with: UITraitCollection(userInterfaceStyle: .dark))
        }
        asset.fw.setPropertyBool(true, forName: "isThemeAsset")
        return asset
    }

    /// 创建主题动态图片资源，指定提供句柄，内部使用ThemeObject实现
    public static func themeAsset(_ provider: @escaping (ThemeStyle) -> UIImage?) -> UIImageAsset {
        let asset = UIImageAsset()
        asset.fw.themeObject = ThemeObject(provider: provider)
        return asset
    }
}

// MARK: - Wrapper+NSObject
@MainActor extension Wrapper where Base: NSObject {
    /// 订阅主题通知并指定主题上下文(如vc|view)，非UITraitEnvironment等需指定后才能响应系统主题
    public weak var themeContext: (NSObject & UITraitEnvironment)? {
        get {
            property(forName: "themeContext") as? (NSObject & UITraitEnvironment)
        }
        set {
            let oldContext: NSObject? = themeContext
            setPropertyWeak(newValue, forName: "themeContext")

            if let oldContext {
                if let oldIdentifier = themeContextIdentifier {
                    oldContext.fw.removeThemeListener(oldIdentifier)
                }
                themeContextIdentifier = nil
            }

            let newContext: NSObject? = newValue
            if let newContext {
                let identifier = newContext.fw.addThemeListener { [weak base] style in
                    base?.fw.notifyThemeChanged(style)
                }
                themeContextIdentifier = identifier
            }
        }
    }

    /// 添加iOS13主题改变通知回调，返回订阅唯一标志，需订阅后才生效
    @discardableResult
    public func addThemeListener(_ listener: @escaping @MainActor @Sendable (ThemeStyle) -> Void) -> String {
        let identifier = UUID().uuidString
        themeListeners[identifier] = listener
        return identifier
    }

    /// iOS13根据订阅唯一标志移除主题通知回调
    public func removeThemeListener(_ identifier: String) {
        guard issetThemeListeners else { return }
        themeListeners.removeValue(forKey: identifier)
    }

    /// iOS13移除所有主题通知回调，一般用于cell重用
    public func removeAllThemeListeners() {
        guard issetThemeListeners else { return }
        themeListeners.removeAll()
    }

    private var themeContextIdentifier: String? {
        get { property(forName: "themeContextIdentifier") as? String }
        set { setPropertyCopy(newValue, forName: "themeContextIdentifier") }
    }

    private var issetThemeListeners: Bool {
        property(forName: "themeListeners") != nil
    }

    private var themeListeners: [String: @MainActor @Sendable (ThemeStyle) -> Void] {
        get { property(forName: "themeListeners") as? [String: @MainActor @Sendable (ThemeStyle) -> Void] ?? [:] }
        set { setProperty(newValue, forName: "themeListeners") }
    }

    fileprivate func notifyThemeChanged(_ style: ThemeStyle) {
        // 1. 调用themeChanged钩子
        base.themeChanged(style)

        // 2. 调用themeListeners句柄
        if issetThemeListeners {
            for (_, listener) in themeListeners {
                listener(style)
            }
        }

        // 3. 调用renderTheme渲染钩子
        base.renderTheme(style)
    }
}

// MARK: - Wrapper+UIImageView
@MainActor extension Wrapper where Base: UIImageView {
    /// 设置主题图片，自动跟随系统改变，清空时需置为nil，二选一
    public var themeImage: UIImage? {
        get {
            property(forName: "themeImage") as? UIImage
        }
        set {
            setProperty(newValue, forName: "themeImage")
            setProperty(nil, forName: "themeAsset")
            base.image = newValue?.fw.image
        }
    }

    /// 设置主题图片资源，自动跟随系统改变，清空时需置为nil，二选一
    public var themeAsset: UIImageAsset? {
        get {
            property(forName: "themeAsset") as? UIImageAsset
        }
        set {
            setProperty(newValue, forName: "themeAsset")
            setProperty(nil, forName: "themeImage")
            base.image = newValue?.fw.image
        }
    }
}

// MARK: - ThemeManager
/// 可扩展主题样式(采用class实现是为了NSObject子类可重写)
public class ThemeStyle: NSObject, RawRepresentable, @unchecked Sendable {
    public typealias RawValue = Int

    /// 浅色样式
    public static let light: ThemeStyle = .init(1)
    /// 深色样式
    public static let dark: ThemeStyle = .init(2)

    public var rawValue: Int

    public required init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int) {
        self.rawValue = rawValue
    }

    override public func isEqual(_ object: Any?) -> Bool {
        if let style = object as? ThemeStyle {
            return rawValue == style.rawValue
        }
        return super.isEqual(object)
    }
}

/// 可扩展主题模式(扩展值与样式值相同即可)
public struct ThemeMode: RawRepresentable, Equatable, Hashable, Sendable {
    public typealias RawValue = Int

    /// 跟随系统模式，iOS13以上动态切换，iOS13以下固定浅色，默认
    public static let system: ThemeMode = .init(0)
    /// 固定浅色模式
    public static let light: ThemeMode = .init(ThemeStyle.light.rawValue)
    /// 固定深色模式
    public static let dark: ThemeMode = .init(ThemeStyle.dark.rawValue)

    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int) {
        self.rawValue = rawValue
    }
}

extension Notification.Name {
    /// iOS13主题改变通知，object为ThemeManager时表示手工切换，object为UIScreen时为系统切换
    public static let ThemeChanged = Notification.Name("FWThemeChangedNotification")
}

/// 主题管理器，iOS13+可跟随系统改变
///
/// 框架默认只拦截了UIView|UIViewController|UIScreen|UIImageView|UILabel类，满足条件会自动触发themeChanged；如果不满足条件或者拦截未生效，需先设置主题上下文fw.themeContext才能生效。
/// 注意事项：iOS13以下默认不支持主题切换；如需支持，请使用fw.color相关方法
public class ThemeManager: @unchecked Sendable {
    /// 单例模式
    public static let shared = ThemeManager()

    /// 当前主题模式，默认跟随系统模式
    public var mode: ThemeMode {
        get {
            _mode
        }
        set {
            guard newValue != _mode else { return }
            let oldStyle = style
            _mode = newValue
            let style = style

            UserDefaults.standard.set(NSNumber(value: newValue.rawValue), forKey: "FWThemeMode")
            UserDefaults.standard.synchronize()

            if style != oldStyle {
                NotificationCenter.default.post(name: .ThemeChanged, object: self, userInfo: [NSKeyValueChangeKey.oldKey: oldStyle.rawValue, NSKeyValueChangeKey.newKey: style.rawValue])
            }
            if overrideWindow {
                _overrideWindow = false
                overrideWindow = true
            }
        }
    }

    private var _mode: ThemeMode = .system

    /// iOS13切换主题模式时是否覆盖主window样式(立即生效)，默认false。如果固定主题模式时颜色不正常，可尝试开启本属性
    public var overrideWindow: Bool {
        get {
            _overrideWindow
        }
        set {
            guard newValue != _overrideWindow else { return }
            _overrideWindow = newValue

            let style: UIUserInterfaceStyle
            if newValue && mode != .system {
                style = mode == .dark ? .dark : .light
            } else {
                style = .unspecified
            }
            DispatchQueue.fw.mainAsync {
                UIWindow.fw.main?.overrideUserInterfaceStyle = style
            }
        }
    }

    private var _overrideWindow = false
    
    fileprivate var themeColors: [String: UIColor] = [:]
    fileprivate var themeImages: [String: UIImage] = [:]
    fileprivate var themeImageColorConfiguration: (() -> UIColor)?

    /// 初始化方法
    public init() {
        self._mode = .init(UserDefaults.standard.integer(forKey: "FWThemeMode"))
    }

    /// 当前全局主题样式
    public var style: ThemeStyle {
        style(for: nil)
    }

    /// 指定traitCollection的实际显示样式，传nil时为全局样式
    public func style(for traitCollection: UITraitCollection?) -> ThemeStyle {
        if mode == .system {
            let traitCollection = traitCollection ?? .current
            return traitCollection.userInterfaceStyle == .dark ? .dark : .light
        } else {
            return mode.rawValue == ThemeStyle.light.rawValue ? .light : (mode.rawValue == ThemeStyle.dark.rawValue ? .dark : .init(mode.rawValue))
        }
    }
}

/// 主题动态对象，可获取当前主题静态对象
public class ThemeObject<T>: @unchecked Sendable {
    private var provider: ((ThemeStyle) -> T?)?

    /// 创建主题动态对象，指定提供句柄
    public init(provider: @escaping (ThemeStyle) -> T?) {
        self.provider = provider
    }

    /// 创建主题动态对象，分别指定浅色和深色
    public convenience init(light: T?, dark: T?) {
        self.init { style in
            style == .dark ? dark : light
        }
    }

    /// 获取当前主题静态对象，iOS13+可跟随系统改变
    public var object: T? {
        provider?(ThemeManager.shared.style)
    }

    /// 指定主题样式获取对应静态对象，iOS13+可跟随系统改变
    public func object(for style: ThemeStyle) -> T? {
        provider?(style)
    }
}

// MARK: - NSObject+Theme
@objc extension NSObject {
    /// iOS13主题改变包装器钩子，如果父类有重写，记得调用super，需订阅后才生效
    @MainActor open func themeChanged(_ style: ThemeStyle) {}

    /// iOS13主题改变渲染钩子，如果父类有重写，记得调用super，需订阅后才生效
    @MainActor open func renderTheme(_ style: ThemeStyle) {}
}

// MARK: - UIImageView+Theme
extension UIImageView {
    override open func themeChanged(_ style: ThemeStyle) {
        super.themeChanged(style)

        if let themeImage = fw.themeImage, themeImage.fw.isThemeImage {
            image = themeImage.fw.image
        }
        if let themeAsset = fw.themeAsset, themeAsset.fw.isThemeAsset {
            image = themeAsset.fw.image
        }
    }
}

// MARK: - FrameworkAutoloader+Theme
extension FrameworkAutoloader {
    @objc static func loadToolkit_Theme() {
        swizzleThemeClasses()
    }

    private static func swizzleThemeClasses() {
        swizzleThemeClass(UIScreen.self)
        swizzleThemeClass(UIView.self)
        swizzleThemeClass(UIViewController.self)
        // UIImageView|UILabel内部重写traitCollectionDidChange:时未调用super导致不回调themeChanged:
        swizzleThemeClass(UIImageView.self)
        swizzleThemeClass(UILabel.self)
    }

    private static func swizzleThemeClass(_ themeClass: AnyClass) {
        NSObject.fw.swizzleInstanceMethod(
            themeClass,
            selector: #selector(UITraitEnvironment.traitCollectionDidChange(_:)),
            methodSignature: (@convention(c) (NSObject & UITraitEnvironment, Selector, UITraitCollection?) -> Void).self,
            swizzleSignature: (@convention(block) @MainActor (NSObject & UITraitEnvironment, UITraitCollection?) -> Void).self
        ) { store in { selfObject, traitCollection in
            store.original(selfObject, store.selector, traitCollection)

            if !selfObject.traitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) { return }
            let style = ThemeManager.shared.style(for: selfObject.traitCollection)
            let oldStyle = ThemeManager.shared.style(for: traitCollection)
            if style == oldStyle { return }

            let notifyObject: NSObject = selfObject
            notifyObject.fw.notifyThemeChanged(style)
            if selfObject == UIScreen.main {
                NotificationCenter.default.post(name: .ThemeChanged, object: selfObject, userInfo: [NSKeyValueChangeKey.oldKey: oldStyle.rawValue, NSKeyValueChangeKey.newKey: style.rawValue])
            }
        }}
    }
}
