//
//  Theme.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

// MARK: - UIColor+Theme
extension Wrapper where Base: UIColor {
    
    /// 获取当前主题样式对应静态颜色，主要用于iOS13以下兼容主题切换
    public var color: UIColor {
        if #available(iOS 13.0, *) {
            return base
        } else {
            return themeObject?.object ?? base
        }
    }

    /// 指定主题样式获取对应静态颜色，iOS13+可跟随系统改变
    public func color(forStyle style: ThemeStyle) -> UIColor {
        if let themeObject = themeObject {
            return themeObject.object(forStyle: style) ?? base
        }
        
        if #available(iOS 13.0, *) {
            let traitCollection = UITraitCollection(userInterfaceStyle: style == .dark ? .dark : .light)
            return base.resolvedColor(with: traitCollection)
        } else {
            return base
        }
    }

    /// 是否是主题颜色，仅支持判断使用fwTheme创建的颜色
    public var isThemeColor: Bool {
        return themeObject != nil
    }
    
    private var themeObject: ThemeObject<UIColor>? {
        get { property(forName: "themeObject") as? ThemeObject<UIColor> }
        set { setProperty(newValue, forName: "themeObject") }
    }
    
    /// 动态创建主题色，分别指定浅色和深色
    public static func themeLight(_ light: UIColor, dark: UIColor) -> UIColor {
        return themeColor { style in
            return style == .dark ? dark : light
        }
    }

    /// 动态创建主题色，指定提供句柄
    public static func themeColor(_ provider: @escaping (ThemeStyle) -> UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            let color = UIColor { traitCollection in
                return provider(ThemeManager.shared.style(for: traitCollection))
            }
            color.fw.themeObject = ThemeObject(provider: provider)
            return color
        } else {
            var color = provider(ThemeManager.shared.style)
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            if !color.getRed(&r, green: &g, blue: &b, alpha: &a) {
                if color.getWhite(&r, alpha: &a) {
                    g = r
                    b = r
                }
            }
            color = UIColor(red: r, green: g, blue: b, alpha: a)
            color.fw.themeObject = ThemeObject(provider: provider)
            return color
        }
    }

    /// 动态创建主题色，指定名称，兼容iOS11+系统方式(仅iOS13+支持动态颜色)和手工指定。失败时返回clear防止崩溃
    public static func themeNamed(_ name: String) -> UIColor {
        return themeNamed(name, bundle: nil)
    }

    /// 动态创建主题色，指定名称和bundle，兼容iOS11+系统方式(仅iOS13+支持动态颜色)和手工指定。失败时返回clear防止崩溃
    public static func themeNamed(_ name: String, bundle: Bundle?) -> UIColor {
        if let themeColor = UIColor.__themeColors[name] {
            return themeColor
        }
        
        return themeColor { style in
            if #available(iOS 13.0, *) {
                if let color = UIColor(named: name, in: bundle, compatibleWith: nil) {
                    let traitCollection = UITraitCollection(userInterfaceStyle: style == .dark ? .dark : .light)
                    return color.resolvedColor(with: traitCollection)
                }
                return .clear
            } else {
                let color = UIColor(named: name, in: bundle, compatibleWith: nil)
                return color ?? .clear
            }
        }
    }

    /// 手工单个注册主题色，未配置主题色或者需兼容iOS11以下时可使用本方式
    public static func setThemeColor(_ color: UIColor?, forName name: String) {
        UIColor.__themeColors[name] = color
    }

    /// 手工批量注册主题色，未配置主题色或者需兼容iOS11以下时可使用本方式
    public static func setThemeColors(_ nameColors: [String: UIColor]) {
        UIColor.__themeColors.merge(nameColors) { _, last in last }
    }
    
}

extension UIColor {
    
    fileprivate static var __themeColors: [String: UIColor] = [:]
    
}

// MARK: - UIImage+Theme
/// 注意UIImage默认只有name方式且配置了any和dark才支持动态切换，否则只能重新赋值才会变化。
/// 为避免内存泄漏，通过fwTheme方式创建的主题图片不能直接用于显示，显示时请调用fwImage方法
extension Wrapper where Base: UIImage {
    
    /// 获取当前主题样式对应静态图片用于显示，iOS13+可跟随系统改变
    public var image: UIImage? {
        if let themeObject = themeObject {
            return themeObject.object
        } else {
            return base
        }
    }

    /// 指定主题样式获取对应静态图片用于显示，iOS13+可跟随系统改变
    public func image(forStyle style: ThemeStyle) -> UIImage? {
        if let themeObject = themeObject {
            return themeObject.object(forStyle: style)
        } else {
            return base
        }
    }

    /// 是否是主题图片，仅支持判断使用fwTheme创建的图片
    public var isThemeImage: Bool {
        return themeObject != nil
    }
    
    private var themeObject: ThemeObject<UIImage>? {
        get { property(forName: "themeObject") as? ThemeObject<UIImage> }
        set { setProperty(newValue, forName: "themeObject") }
    }
    
    // MARK: - Color
    /// 快速生成当前图片对应的默认主题图片
    public var themeImage: UIImage {
        return themeImage(color: UIImage.fw.themeImageColor)
    }

    /// 指定主题颜色，快速生成当前图片对应的主题图片
    public func themeImage(color themeColor: UIColor) -> UIImage {
        let weakBase = base
        return UIImage.fw.themeImage { style in
            guard let image = weakBase.fw.image(forStyle: style) else { return nil }
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
        return themeImage { style in
            return style == .dark ? dark : light
        }
    }

    /// 创建主题模拟动态图像，指定提供句柄，不支持动态切换，需重新赋值才会变化
    public static func themeImage(_ provider: @escaping (ThemeStyle) -> UIImage?) -> UIImage {
        let image = UIImage()
        image.fw.themeObject = ThemeObject(provider: provider)
        return image
    }

    /// 创建主题模拟动态图像，指定名称，兼容系统方式(仅iOS13+支持动态图像)和手工指定，支持动态切换，需配置any和dark
    public static func themeNamed(_ name: String) -> UIImage {
        return themeNamed(name, bundle: nil)
    }

    /// 创建主题模拟动态图像，指定名称和bundle，兼容系统方式(仅iOS13+支持动态图像)和手工指定，支持动态切换，需配置any和dark
    public static func themeNamed(_ name: String, bundle: Bundle?) -> UIImage {
        if let themeImage = UIImage.__themeImages[name] {
            return themeImage
        }
        
        return themeImage { style in
            var image = UIImage(named: name, in: bundle, compatibleWith: nil)
            if #available(iOS 13.0, *) {
                let traitCollection = UITraitCollection(userInterfaceStyle: style == .dark ? .dark : .light)
                image = image?.withConfiguration(traitCollection.imageConfiguration)
            }
            return image
        }
    }

    /// 手工单个注册主题图像，未配置主题图像时可使用本方式
    public static func setThemeImage(_ image: UIImage?, forName name: String) {
        UIImage.__themeImages[name] = image
    }

    /// 手工批量注册主题图像，未配置主题图像时可使用本方式
    public static func setThemeImages(_ nameImages: [String: UIImage]) {
        UIImage.__themeImages.merge(nameImages) { _, last in last }
    }

    // MARK: - Color
    /// 默认主题图片颜色，未设置时为浅色=>黑色，深色=>白色
    public static var themeImageColor: UIColor {
        get {
            return UIImage.__themeImageColor ?? UIColor.fw.themeLight(.black, dark: .white)
        }
        set {
            UIImage.__themeImageColor = newValue
        }
    }
    
}

extension UIImage {
    
    fileprivate static var __themeImages: [String: UIImage] = [:]
    fileprivate static var __themeImageColor: UIColor?
    
}

// MARK: - UIImageAsset+Theme
extension Wrapper where Base: UIImageAsset {
    
    /// 获取当前主题样式对应静态图片用于显示，iOS13+可跟随系统改变
    public var image: UIImage? {
        return image(forStyle: ThemeManager.shared.style)
    }

    /// 指定主题样式获取对应静态图片用于显示，iOS13+可跟随系统改变
    public func image(forStyle style: ThemeStyle) -> UIImage? {
        let isThemeAsset = propertyBool(forName: "isThemeAsset")
        if isThemeAsset {
            if #available(iOS 13.0, *) {
                let traitCollection = UITraitCollection(userInterfaceStyle: style == .dark ? .dark : .light)
                return base.image(with: traitCollection)
            }
        }
        
        return themeObject?.object(forStyle: style)
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
        if #available(iOS 13.0, *) {
            let asset = UIImageAsset()
            if let light = light {
                asset.register(light, with: UITraitCollection(userInterfaceStyle: .light))
            }
            if let dark = dark {
                asset.register(dark, with: UITraitCollection(userInterfaceStyle: .dark))
            }
            asset.fw.setPropertyBool(true, forName: "isThemeAsset")
            return asset
        } else {
            return themeAsset { style in
                return style == .dark ? dark : light
            }
        }
    }

    /// 创建主题动态图片资源，指定提供句柄，内部使用FWThemeObject实现
    public static func themeAsset(_ provider: @escaping (ThemeStyle) -> UIImage?) -> UIImageAsset {
        let asset = UIImageAsset()
        asset.fw.themeObject = ThemeObject(provider: provider)
        return asset
    }
    
}

// MARK: - NSObject+Theme
extension Wrapper where Base: NSObject {
    
    /// 订阅主题通知并指定主题上下文(如vc|view)，非UITraitEnvironment等需指定后才能响应系统主题
    public weak var themeContext: (NSObject & UITraitEnvironment)? {
        get {
            return property(forName: "themeContext") as? (NSObject & UITraitEnvironment)
        }
        set {
            if #available(iOS 13.0, *) {
                let oldContext: NSObject? = themeContext
                setPropertyWeak(newValue, forName: "themeContext")
                
                if let oldContext = oldContext {
                    oldContext.fw.removeThemeListener(themeContextIdentifier)
                    themeContextIdentifier = nil
                }
                
                let newContext: NSObject? = newValue
                if let newContext = newContext {
                    let weakBase = base
                    let identifier = newContext.fw.addThemeListener { [weak weakBase] style in
                        weakBase?.fw.notifyThemeChanged(style)
                    }
                    themeContextIdentifier = identifier
                }
            }
        }
    }

    /// 添加iOS13主题改变通知回调，返回订阅唯一标志，需订阅后才生效
    @discardableResult
    public func addThemeListener(_ listener: @escaping (ThemeStyle) -> Void) -> String? {
        if #available(iOS 13.0, *) {
            let identifier = UUID().uuidString
            let listeners = innerThemeListeners(true)
            listeners?.setObject(listener, forKey: identifier as NSString)
            return identifier
        }
        return nil
    }

    /// iOS13根据订阅唯一标志移除主题通知回调
    public func removeThemeListener(_ identifier: String?) {
        guard let identifier = identifier else { return }
        if #available(iOS 13.0, *) {
            let listeners = innerThemeListeners(false)
            listeners?.removeObject(forKey: identifier)
        }
    }

    /// iOS13移除所有主题通知回调，一般用于cell重用
    public func removeAllThemeListeners() {
        if #available(iOS 13.0, *) {
            let listeners = innerThemeListeners(false)
            listeners?.removeAllObjects()
        }
    }
    
    private var themeContextIdentifier: String? {
        get { property(forName: "themeContextIdentifier") as? String }
        set { setPropertyCopy(newValue, forName: "themeContextIdentifier") }
    }
    
    @available(iOS 13.0, *)
    private func innerThemeListeners(_ lazyload: Bool) -> NSMutableDictionary? {
        var listeners = property(forName: "innerThemeListeners") as? NSMutableDictionary
        if listeners == nil && lazyload {
            listeners = NSMutableDictionary()
            setProperty(listeners, forName: "innerThemeListeners")
        }
        return listeners
    }
    
    @available(iOS 13.0, *)
    fileprivate func notifyThemeChanged(_ style: ThemeStyle) {
        // 1. 调用themeChanged钩子
        base.themeChanged(style)
        
        // 2. 调用themeListeners句柄
        if let listeners = innerThemeListeners(false) {
            listeners.enumerateKeysAndObjects { _, obj, _ in
                let listener = obj as? (ThemeStyle) -> Void
                listener?(style)
            }
        }
    }
    
}

@objc extension NSObject {
    
    /// iOS13主题改变包装器钩子，如果父类有重写，记得调用super，需订阅后才生效
    open func themeChanged(_ style: ThemeStyle) {}
    
}

internal class ThemeAutoloader: AutoloadProtocol {
    
    static func autoload() {
        if #available(iOS 13.0, *) {
            swizzleThemeClass(UIScreen.self)
            swizzleThemeClass(UIView.self)
            swizzleThemeClass(UIViewController.self)
            // UIImageView|UILabel内部重写traitCollectionDidChange:时未调用super导致不回调themeChanged:
            swizzleThemeClass(UIImageView.self)
            swizzleThemeClass(UILabel.self)
        }
    }
    
    @available(iOS 13.0, *)
    static func swizzleThemeClass(_ themeClass: AnyClass) {
        NSObject.fw.swizzleInstanceMethod(
            themeClass,
            selector: #selector(UITraitEnvironment.traitCollectionDidChange(_:)),
            methodSignature: (@convention(c) (NSObject & UITraitEnvironment, Selector, UITraitCollection) -> Void).self,
            swizzleSignature: (@convention(block) (NSObject & UITraitEnvironment, UITraitCollection) -> Void).self
        ) { store in { selfObject, traitCollection in
            store.original(selfObject, store.selector, traitCollection)
            
            if !selfObject.traitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) { return }
            let style = ThemeManager.shared.style(for: selfObject.traitCollection)
            let oldStyle = ThemeManager.shared.style(for: traitCollection)
            if style == oldStyle { return }
            
            let notifyObject: NSObject = selfObject
            notifyObject.fw.notifyThemeChanged(style)
            if selfObject == UIScreen.main {
                NotificationCenter.default.post(
                    name: .ThemeChanged,
                    object: selfObject,
                    userInfo: [
                        NSKeyValueChangeKey.oldKey.rawValue: oldStyle.rawValue,
                        NSKeyValueChangeKey.newKey.rawValue: style.rawValue
                    ]
                )
            }
        }}
    }
    
}

// MARK: - UIImageView+Theme
extension Wrapper where Base: UIImageView {
    
    /// 设置主题图片，自动跟随系统改变，清空时需置为nil，二选一
    public var themeImage: UIImage? {
        get {
            return property(forName: "themeImage") as? UIImage
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
            return property(forName: "themeAsset") as? UIImageAsset
        }
        set {
            setProperty(newValue, forName: "themeAsset")
            setProperty(nil, forName: "themeImage")
            base.image = newValue?.fw.image
        }
    }
    
}

@objc extension UIImageView {
    
    open override func themeChanged(_ style: ThemeStyle) {
        super.themeChanged(style)
        
        if let themeImage = fw.themeImage, themeImage.fw.isThemeImage {
            self.image = themeImage.fw.image
        }
        if let themeAsset = fw.themeAsset, themeAsset.fw.isThemeAsset {
            self.image = themeAsset.fw.image
        }
    }
    
}
