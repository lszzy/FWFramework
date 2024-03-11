//
//  BarAppearance.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

// MARK: - Wrapper+UINavigationBar
/// 导航栏视图分类，全局设置用[UINavigationBar appearance]。默认iOS15+启用appearance，iOS14及以下使用旧版本api
extension Wrapper where Base: UINavigationBar {
    /// 是否强制iOS13+启用新版样式，默认false，仅iOS15+才启用
    public static var appearanceEnabled: Bool {
        get { Base.fw_appearanceEnabled }
        set { Base.fw_appearanceEnabled = newValue }
    }
    
    /// 设置全局按钮样式属性，nil时系统默认
    public static var buttonAttributes: [NSAttributedString.Key: Any]? {
        get { Base.fw_buttonAttributes }
        set { Base.fw_buttonAttributes = newValue }
    }
    
    /// 导航栏iOS13+样式对象，用于自定义样式，默认透明
    public var appearance: UINavigationBarAppearance {
        return base.fw_appearance
    }

    /// 手工更新导航栏样式
    public func updateAppearance() {
        base.fw_updateAppearance()
    }

    /// 导航栏是否半透明，会重置背景，需优先设置，默认NO；背景色需带有alpha时半透明才会生效
    public var isTranslucent: Bool {
        get { base.fw_isTranslucent }
        set { base.fw_isTranslucent = newValue }
    }

    /// 设置前景颜色，包含文字和按钮等
    public var foregroundColor: UIColor? {
        get { base.fw_foregroundColor }
        set { base.fw_foregroundColor = newValue }
    }

    /// 单独设置标题颜色，nil时显示前景颜色
    public var titleAttributes: [NSAttributedString.Key: Any]? {
        get { base.fw_titleAttributes }
        set { base.fw_titleAttributes = newValue }
    }
    
    /// 单独设置按钮样式属性，nil时系统默认。仅iOS15+生效，iOS14及以下请使用UIBarButtonItem
    public var buttonAttributes: [NSAttributedString.Key: Any]? {
        get { base.fw_buttonAttributes }
        set { base.fw_buttonAttributes = newValue }
    }

    /// 设置背景颜色(nil时透明)，兼容主题颜色，后设置生效
    public var backgroundColor: UIColor? {
        get { base.fw_backgroundColor }
        set { base.fw_backgroundColor = newValue }
    }

    /// 设置背景图片(nil时透明)，兼容主题图片，后设置生效
    public var backgroundImage: UIImage? {
        get { base.fw_backgroundImage }
        set { base.fw_backgroundImage = newValue }
    }

    /// 设置背景是否全透明，默认NO，后设置生效
    public var backgroundTransparent: Bool {
        get { base.fw_backgroundTransparent }
        set { base.fw_backgroundTransparent = newValue }
    }

    /// 设置阴影颜色(nil时透明)，兼容主题颜色，后设置生效
    public var shadowColor: UIColor? {
        get { base.fw_shadowColor }
        set { base.fw_shadowColor = newValue }
    }

    /// 设置阴影图片(nil时透明)，兼容主题图片，后设置生效
    public var shadowImage: UIImage? {
        get { base.fw_shadowImage }
        set { base.fw_shadowImage = newValue }
    }

    /// 设置返回按钮图片，包含图片和转场Mask图片，自动偏移和系统左侧按钮位置保持一致
    public var backImage: UIImage? {
        get { base.fw_backImage }
        set { base.fw_backImage = newValue }
    }
}

// MARK: - Wrapper+UITabBar
/// 标签栏视图分类，全局设置用[UITabBar appearance]。iOS15+启用appearance，iOS14及以下使用旧版本api
extension Wrapper where Base: UITabBar {
    /// 标签栏iOS13+样式对象，用于自定义样式，默认透明
    public var appearance: UITabBarAppearance {
        return base.fw_appearance
    }

    /// 手工更新标签栏样式
    public func updateAppearance() {
        base.fw_updateAppearance()
    }

    /// 标签栏是否半透明，会重置背景，需优先设置，默认NO；背景色需带有alpha时半透明才会生效
    public var isTranslucent: Bool {
        get { base.fw_isTranslucent }
        set { base.fw_isTranslucent = newValue }
    }

    /// 设置前景颜色，包含文字和按钮等
    public var foregroundColor: UIColor? {
        get { base.fw_foregroundColor }
        set { base.fw_foregroundColor = newValue }
    }

    /// 设置背景颜色，兼容主题颜色，后设置生效
    public var backgroundColor: UIColor? {
        get { base.fw_backgroundColor }
        set { base.fw_backgroundColor = newValue }
    }

    /// 设置背景图片，兼容主题图片，后设置生效
    public var backgroundImage: UIImage? {
        get { base.fw_backgroundImage }
        set { base.fw_backgroundImage = newValue }
    }

    /// 设置背景是否全透明，默认NO，后设置生效
    public var backgroundTransparent: Bool {
        get { base.fw_backgroundTransparent }
        set { base.fw_backgroundTransparent = newValue }
    }

    /// 设置阴影颜色(nil时透明)，兼容主题颜色，后设置生效
    public var shadowColor: UIColor? {
        get { base.fw_shadowColor }
        set { base.fw_shadowColor = newValue }
    }

    /// 设置阴影图片(nil时透明)，兼容主题图片，后设置生效
    public var shadowImage: UIImage? {
        get { base.fw_shadowImage }
        set { base.fw_shadowImage = newValue }
    }
}

// MARK: - Wrapper+UIToolbar
/// 工具栏样式分类，全局设置用[UIToolbar appearance]。iOS15+启用appearance，iOS14及以下使用旧版本api
/// 工具栏高度建议用sizeToFit自动获取(示例44)，contentView为内容视图(示例44)，backgroundView为背景视图(示例78)
extension Wrapper where Base: UIToolbar {
    /// 工具栏iOS13+样式对象，用于自定义样式，默认透明
    public var appearance: UIToolbarAppearance {
        return base.fw_appearance
    }

    /// 手工更新工具栏样式
    public func updateAppearance() {
        base.fw_updateAppearance()
    }

    /// 工具栏是否半透明，会重置背景，需优先设置，默认NO；背景色需带有alpha时半透明才会生效
    public var isTranslucent: Bool {
        get { base.fw_isTranslucent }
        set { base.fw_isTranslucent = newValue }
    }

    /// 设置前景颜色，包含文字和按钮等
    public var foregroundColor: UIColor? {
        get { base.fw_foregroundColor }
        set { base.fw_foregroundColor = newValue }
    }
    
    /// 单独设置按钮样式属性，nil时系统默认。仅iOS15+生效，iOS14及以下请使用UIBarButtonItem
    public var buttonAttributes: [NSAttributedString.Key: Any]? {
        get { base.fw_buttonAttributes }
        set { base.fw_buttonAttributes = newValue }
    }

    /// 设置背景颜色，兼容主题颜色，后设置生效
    public var backgroundColor: UIColor? {
        get { base.fw_backgroundColor }
        set { base.fw_backgroundColor = newValue }
    }

    /// 设置背景图片，兼容主题图片，后设置生效
    public var backgroundImage: UIImage? {
        get { base.fw_backgroundImage }
        set { base.fw_backgroundImage = newValue }
    }

    /// 设置背景是否全透明，默认NO，后设置生效
    public var backgroundTransparent: Bool {
        get { base.fw_backgroundTransparent }
        set { base.fw_backgroundTransparent = newValue }
    }

    /// 设置阴影颜色(nil时透明)，兼容主题颜色，后设置生效
    public var shadowColor: UIColor? {
        get { base.fw_shadowColor }
        set { base.fw_shadowColor = newValue }
    }

    /// 设置阴影图片(nil时透明)，兼容主题图片，后设置生效
    public var shadowImage: UIImage? {
        get { base.fw_shadowImage }
        set { base.fw_shadowImage = newValue }
    }

    /// 自定义工具栏位置，调用后才生效，会自动设置delegate。Bottom时背景自动向下延伸，TopAttached时背景自动向上延伸
    public var barPosition: UIBarPosition {
        get { base.fw_barPosition }
        set { base.fw_barPosition = newValue }
    }
}

// MARK: - UINavigationBar+BarAppearance
/// 导航栏视图分类，全局设置用[UINavigationBar appearance]。默认iOS15+启用appearance，iOS14及以下使用旧版本api
/// 注意：需要支持appearance的属性必须标记为objc，否则不会生效
@_spi(FW) extension UINavigationBar {
    
    /// 是否强制iOS13+启用新版样式，默认false，仅iOS15+才启用
    public static var fw_appearanceEnabled: Bool {
        get {
            if #available(iOS 15.0, *) { 
                return true
            }
            return UINavigationBar.fw_staticAppearanceEnabled
        }
        set {
            UINavigationBar.fw_staticAppearanceEnabled = newValue
        }
    }
    
    /// 设置全局按钮样式属性，nil时系统默认
    public static var fw_buttonAttributes: [NSAttributedString.Key: Any]? {
        get {
            return UINavigationBar.fw_staticButtonAttributes
        }
        set {
            UINavigationBar.fw_staticButtonAttributes = newValue
            guard let buttonAttributes = newValue else { return }
            
            if !UINavigationBar.fw_appearanceEnabled {
                let appearance = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
                let states: [UIControl.State] = [.normal, .highlighted, .disabled, .focused]
                for state in states {
                    var attributes = appearance.titleTextAttributes(for: state) ?? [:]
                    attributes.merge(buttonAttributes) { _, last in last }
                    appearance.setTitleTextAttributes(attributes, for: state)
                }
            }
        }
    }
    
    private static var fw_staticAppearanceEnabled = false
    private static var fw_staticButtonAttributes: [NSAttributedString.Key: Any]?
    
    /// 导航栏iOS13+样式对象，用于自定义样式，默认透明
    public var fw_appearance: UINavigationBarAppearance {
        if let appearance = fw_property(forName: "fw_appearance") as? UINavigationBarAppearance {
            return appearance
        } else {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            fw_setProperty(appearance, forName: "fw_appearance")
            return appearance
        }
    }

    /// 手工更新导航栏样式
    public func fw_updateAppearance() {
        self.standardAppearance = fw_appearance
        self.compactAppearance = fw_appearance
        self.scrollEdgeAppearance = fw_appearance
        if #available(iOS 15.0, *) {
            self.compactScrollEdgeAppearance = fw_appearance
        }
    }

    /// 导航栏是否半透明，会重置背景，需优先设置，默认NO；背景色需带有alpha时半透明才会生效
    @objc dynamic public var fw_isTranslucent: Bool {
        get {
            return fw_propertyBool(forName: "fw_isTranslucent")
        }
        set {
            fw_setPropertyBool(newValue, forName: "fw_isTranslucent")
            if UINavigationBar.fw_appearanceEnabled {
                if newValue {
                    fw_appearance.configureWithDefaultBackground()
                } else {
                    fw_appearance.configureWithTransparentBackground()
                }
                fw_updateAppearance()
            } else {
                if newValue {
                    self.setBackgroundImage(nil, for: .default)
                } else {
                    self.barTintColor = nil
                }
            }
        }
    }

    /// 设置前景颜色，包含文字和按钮等
    @objc dynamic public var fw_foregroundColor: UIColor? {
        get {
            return self.tintColor
        }
        set {
            self.tintColor = newValue
            fw_updateTitleAttributes()
            fw_updateButtonAttributes()
        }
    }

    /// 单独设置标题颜色，nil时显示前景颜色
    @objc dynamic public var fw_titleAttributes: [NSAttributedString.Key: Any]? {
        get {
            return fw_property(forName: "fw_titleAttributes") as? [NSAttributedString.Key: Any]
        }
        set {
            fw_setProperty(newValue, forName: "fw_titleAttributes")
            fw_updateTitleAttributes()
        }
    }
    
    /// 单独设置按钮样式属性，nil时系统默认。仅iOS15+生效，iOS14及以下请使用UIBarButtonItem
    @objc dynamic public var fw_buttonAttributes: [NSAttributedString.Key: Any]? {
        get {
            return fw_property(forName: "fw_buttonAttributes") as? [NSAttributedString.Key: Any]
        }
        set {
            fw_setProperty(newValue, forName: "fw_buttonAttributes")
            fw_updateButtonAttributes()
        }
    }
    
    private func fw_updateTitleAttributes() {
        if UINavigationBar.fw_appearanceEnabled {
            var attributes = fw_appearance.titleTextAttributes
            attributes[NSAttributedString.Key.foregroundColor] = self.tintColor
            if let titleAttributes = fw_titleAttributes {
                attributes.merge(titleAttributes) { _, last in last }
            }
            fw_appearance.titleTextAttributes = attributes
            
            var largeAttributes = fw_appearance.largeTitleTextAttributes
            largeAttributes[NSAttributedString.Key.foregroundColor] = self.tintColor
            if let titleAttributes = fw_titleAttributes {
                largeAttributes.merge(titleAttributes) { _, last in last }
            }
            fw_appearance.largeTitleTextAttributes = largeAttributes
            fw_updateAppearance()
        } else {
            var attributes = self.titleTextAttributes ?? [:]
            attributes[NSAttributedString.Key.foregroundColor] = self.tintColor
            if let titleAttributes = fw_titleAttributes {
                attributes.merge(titleAttributes) { _, last in last }
            }
            self.titleTextAttributes = attributes
            
            var largeAttributes = self.largeTitleTextAttributes ?? [:]
            largeAttributes[NSAttributedString.Key.foregroundColor] = self.tintColor
            if let titleAttributes = fw_titleAttributes {
                largeAttributes.merge(titleAttributes) { _, last in last }
            }
            self.largeTitleTextAttributes = largeAttributes
        }
    }
    
    private func fw_updateButtonAttributes() {
        if UINavigationBar.fw_appearanceEnabled {
            guard let buttonAttributes = fw_buttonAttributes ?? UINavigationBar.fw_staticButtonAttributes else { return }
            
            let appearances = [fw_appearance.buttonAppearance, fw_appearance.doneButtonAppearance, fw_appearance.backButtonAppearance]
            for appearance in appearances {
                let stateAppearances = [appearance.normal, appearance.highlighted, appearance.disabled]
                for stateAppearance in stateAppearances {
                    var attributes = stateAppearance.titleTextAttributes
                    attributes.merge(buttonAttributes) { _, last in last }
                    stateAppearance.titleTextAttributes = attributes
                }
            }
            fw_updateAppearance()
        }
    }

    /// 设置背景颜色(nil时透明)，兼容主题颜色，后设置生效
    @objc dynamic public var fw_backgroundColor: UIColor? {
        get {
            return fw_property(forName: "fw_backgroundColor") as? UIColor
        }
        set {
            fw_setProperty(newValue, forName: "fw_backgroundColor")
            fw_setProperty(nil, forName: "fw_backgroundImage")
            if UINavigationBar.fw_appearanceEnabled {
                if fw_isTranslucent {
                    fw_appearance.backgroundColor = newValue
                    fw_appearance.backgroundImage = nil
                } else {
                    var image: UIImage?
                    if let color = newValue {
                        image = UIImage.fw_image(color: color)
                    }
                    fw_appearance.backgroundColor = nil
                    fw_appearance.backgroundImage = image ?? UIImage()
                }
                fw_updateAppearance()
            } else {
                if fw_isTranslucent {
                    self.barTintColor = nil
                    self.setBackgroundImage(nil, for: .default)
                } else {
                    self.barTintColor = nil
                    var image: UIImage?
                    if let color = newValue {
                        image = UIImage.fw_image(color: color)
                    }
                    self.setBackgroundImage(image ?? UIImage(), for: .default)
                }
            }
        }
    }

    /// 设置背景图片(nil时透明)，兼容主题图片，后设置生效
    @objc dynamic public var fw_backgroundImage: UIImage? {
        get {
            return fw_property(forName: "fw_backgroundImage") as? UIImage
        }
        set {
            fw_setProperty(nil, forName: "fw_backgroundColor")
            fw_setProperty(newValue, forName: "fw_backgroundImage")
            let image = newValue?.fw_image ?? UIImage()
            if UINavigationBar.fw_appearanceEnabled {
                fw_appearance.backgroundColor = nil
                fw_appearance.backgroundImage = image
                fw_updateAppearance()
            } else {
                self.barTintColor = nil
                self.setBackgroundImage(image, for: .default)
            }
        }
    }

    /// 设置背景是否全透明，默认NO，后设置生效
    @objc dynamic public var fw_backgroundTransparent: Bool {
        get {
            return fw_propertyBool(forName: "fw_backgroundTransparent")
        }
        set {
            fw_setPropertyBool(newValue, forName: "fw_backgroundTransparent")
            fw_setProperty(nil, forName: "fw_backgroundColor")
            fw_setProperty(nil, forName: "fw_backgroundImage")
            let image = newValue ? UIImage() : nil
            if UINavigationBar.fw_appearanceEnabled {
                fw_appearance.backgroundColor = nil
                fw_appearance.backgroundImage = image
                fw_updateAppearance()
            } else {
                self.barTintColor = nil
                self.setBackgroundImage(image, for: .default)
            }
        }
    }

    /// 设置阴影颜色(nil时透明)，兼容主题颜色，后设置生效。注意iOS13、14切换阴影图片时需保持图片高度一致，否则不生效
    @objc dynamic public var fw_shadowColor: UIColor? {
        get {
            return fw_property(forName: "fw_shadowColor") as? UIColor
        }
        set {
            fw_setProperty(newValue, forName: "fw_shadowColor")
            fw_setProperty(nil, forName: "fw_shadowImage")
            if UINavigationBar.fw_appearanceEnabled {
                fw_appearance.shadowColor = newValue
                fw_appearance.shadowImage = nil
                fw_updateAppearance()
            } else {
                var image: UIImage?
                if let color = newValue {
                    image = UIImage.fw_image(color: color)
                }
                self.shadowImage = image ?? UIImage()
            }
        }
    }

    /// 设置阴影图片(nil时透明)，兼容主题图片，后设置生效。注意iOS13、14切换阴影图片时需保持图片高度一致，否则不生效
    @objc dynamic public var fw_shadowImage: UIImage? {
        get {
            return fw_property(forName: "fw_shadowImage") as? UIImage
        }
        set {
            fw_setProperty(newValue, forName: "fw_shadowImage")
            fw_setProperty(nil, forName: "fw_shadowColor")
            if UINavigationBar.fw_appearanceEnabled {
                fw_appearance.shadowColor = nil
                fw_appearance.shadowImage = newValue?.fw_image
                fw_updateAppearance()
            } else {
                self.shadowImage = newValue?.fw_image ?? UIImage()
            }
        }
    }

    /// 设置返回按钮图片，包含图片和转场Mask图片，自动偏移和系统左侧按钮位置保持一致
    @objc dynamic public var fw_backImage: UIImage? {
        get {
            if UINavigationBar.fw_appearanceEnabled {
                return fw_appearance.backIndicatorImage
            }
            return self.backIndicatorImage
        }
        set {
            let image = newValue?.fw_image(insets: UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0))
            if UINavigationBar.fw_appearanceEnabled {
                fw_appearance.setBackIndicatorImage(image, transitionMaskImage: image)
                fw_updateAppearance()
            } else {
                self.backIndicatorImage = image
                self.backIndicatorTransitionMaskImage = image
            }
        }
    }
    
    open override func themeChanged(_ style: ThemeStyle) {
        super.themeChanged(style)
        
        if let backgroundColor = fw_backgroundColor, backgroundColor.fw_isThemeColor {
            if UINavigationBar.fw_appearanceEnabled {
                if fw_isTranslucent {
                    fw_appearance.backgroundColor = backgroundColor.fw_color
                    fw_appearance.backgroundImage = nil
                } else {
                    let image = UIImage.fw_image(color: backgroundColor.fw_color) ?? UIImage()
                    fw_appearance.backgroundColor = nil
                    fw_appearance.backgroundImage = image
                }
                fw_updateAppearance()
            } else {
                if fw_isTranslucent {
                    self.barTintColor = backgroundColor.fw_color
                    self.setBackgroundImage(nil, for: .default)
                } else {
                    let image = UIImage.fw_image(color: backgroundColor.fw_color) ?? UIImage()
                    self.barTintColor = nil
                    self.setBackgroundImage(image, for: .default)
                }
            }
        }
        
        if let backgroundImage = fw_backgroundImage, backgroundImage.fw_isThemeImage {
            let image = backgroundImage.fw_image ?? UIImage()
            if UINavigationBar.fw_appearanceEnabled {
                fw_appearance.backgroundColor = nil
                fw_appearance.backgroundImage = image
                fw_updateAppearance()
            } else {
                self.barTintColor = nil
                self.setBackgroundImage(image, for: .default)
            }
        }
        
        if let shadowColor = fw_shadowColor, shadowColor.fw_isThemeColor {
            if UINavigationBar.fw_appearanceEnabled {
                fw_appearance.shadowColor = shadowColor.fw_color
                fw_appearance.shadowImage = nil
                fw_updateAppearance()
            } else {
                self.shadowImage = UIImage.fw_image(color: shadowColor.fw_color) ?? UIImage()
            }
        }
        
        if let shadowImage = fw_shadowImage, shadowImage.fw_isThemeImage {
            if UINavigationBar.fw_appearanceEnabled {
                fw_appearance.shadowColor = nil
                fw_appearance.shadowImage = shadowImage.fw_image
                fw_updateAppearance()
            } else {
                self.shadowImage = shadowImage.fw_image ?? UIImage()
            }
        }
    }
    
}

// MARK: - UITabBar+BarAppearance
/// 标签栏视图分类，全局设置用[UITabBar appearance]。iOS15+启用appearance，iOS14及以下使用旧版本api
/// 注意：需要支持appearance的属性必须标记为objc，否则不会生效
@_spi(FW) extension UITabBar {
    
    /// 标签栏iOS13+样式对象，用于自定义样式，默认透明
    public var fw_appearance: UITabBarAppearance {
        if let appearance = fw_property(forName: "fw_appearance") as? UITabBarAppearance {
            return appearance
        } else {
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            fw_setProperty(appearance, forName: "fw_appearance")
            return appearance
        }
    }

    /// 手工更新标签栏样式
    public func fw_updateAppearance() {
        self.standardAppearance = fw_appearance
        if #available(iOS 15.0, *) {
            self.scrollEdgeAppearance = fw_appearance
        }
    }

    /// 标签栏是否半透明，会重置背景，需优先设置，默认NO；背景色需带有alpha时半透明才会生效
    @objc dynamic public var fw_isTranslucent: Bool {
        get {
            return fw_propertyBool(forName: "fw_isTranslucent")
        }
        set {
            fw_setPropertyBool(newValue, forName: "fw_isTranslucent")
            if UINavigationBar.fw_appearanceEnabled {
                if newValue {
                    fw_appearance.configureWithDefaultBackground()
                } else {
                    fw_appearance.configureWithTransparentBackground()
                }
                fw_updateAppearance()
            } else {
                if newValue {
                    self.backgroundImage = nil
                } else {
                    self.barTintColor = nil
                }
            }
        }
    }

    /// 设置前景颜色，包含文字和按钮等
    @objc dynamic public var fw_foregroundColor: UIColor? {
        get { return self.tintColor }
        set { self.tintColor = newValue }
    }

    /// 设置背景颜色，兼容主题颜色，后设置生效
    @objc dynamic public var fw_backgroundColor: UIColor? {
        get {
            return fw_property(forName: "fw_backgroundColor") as? UIColor
        }
        set {
            fw_setProperty(newValue, forName: "fw_backgroundColor")
            fw_setProperty(nil, forName: "fw_backgroundImage")
            if UINavigationBar.fw_appearanceEnabled {
                if fw_isTranslucent {
                    fw_appearance.backgroundColor = newValue
                    fw_appearance.backgroundImage = nil
                } else {
                    var image: UIImage?
                    if let color = newValue {
                        image = UIImage.fw_image(color: color)
                    }
                    fw_appearance.backgroundColor = nil
                    fw_appearance.backgroundImage = image
                }
                fw_updateAppearance()
            } else {
                if fw_isTranslucent {
                    self.barTintColor = nil
                    self.backgroundImage = nil
                } else {
                    self.barTintColor = nil
                    var image: UIImage?
                    if let color = newValue {
                        image = UIImage.fw_image(color: color)
                    }
                    self.backgroundImage = image
                }
            }
        }
    }

    /// 设置背景图片，兼容主题图片，后设置生效
    @objc dynamic public var fw_backgroundImage: UIImage? {
        get {
            return fw_property(forName: "fw_backgroundImage") as? UIImage
        }
        set {
            fw_setProperty(nil, forName: "fw_backgroundColor")
            fw_setProperty(newValue, forName: "fw_backgroundImage")
            if UINavigationBar.fw_appearanceEnabled {
                fw_appearance.backgroundColor = nil
                fw_appearance.backgroundImage = newValue?.fw_image
                fw_updateAppearance()
            } else {
                self.barTintColor = nil
                self.backgroundImage = newValue?.fw_image
            }
        }
    }

    /// 设置背景是否全透明，默认NO，后设置生效
    @objc dynamic public var fw_backgroundTransparent: Bool {
        get {
            return fw_propertyBool(forName: "fw_backgroundTransparent")
        }
        set {
            fw_setPropertyBool(newValue, forName: "fw_backgroundTransparent")
            fw_setProperty(nil, forName: "fw_backgroundColor")
            fw_setProperty(nil, forName: "fw_backgroundImage")
            let image = newValue ? UIImage() : nil
            if UINavigationBar.fw_appearanceEnabled {
                fw_appearance.backgroundColor = nil
                fw_appearance.backgroundImage = image
                fw_updateAppearance()
            } else {
                self.barTintColor = nil
                self.backgroundImage = image
            }
        }
    }

    /// 设置阴影颜色(nil时透明)，兼容主题颜色，后设置生效
    @objc dynamic public var fw_shadowColor: UIColor? {
        get {
            return fw_property(forName: "fw_shadowColor") as? UIColor
        }
        set {
            fw_setProperty(newValue, forName: "fw_shadowColor")
            fw_setProperty(nil, forName: "fw_shadowImage")
            if UINavigationBar.fw_appearanceEnabled {
                fw_appearance.shadowColor = newValue
                fw_appearance.shadowImage = nil
                fw_updateAppearance()
            } else {
                var image: UIImage?
                if let color = newValue {
                    image = UIImage.fw_image(color: color)
                }
                self.shadowImage = image ?? UIImage()
            }
        }
    }

    /// 设置阴影图片(nil时透明)，兼容主题图片，后设置生效
    @objc dynamic public var fw_shadowImage: UIImage? {
        get {
            return fw_property(forName: "fw_shadowImage") as? UIImage
        }
        set {
            fw_setProperty(newValue, forName: "fw_shadowImage")
            fw_setProperty(nil, forName: "fw_shadowColor")
            if UINavigationBar.fw_appearanceEnabled {
                fw_appearance.shadowColor = nil
                fw_appearance.shadowImage = newValue?.fw_image
                fw_updateAppearance()
            } else {
                self.shadowImage = newValue?.fw_image ?? UIImage()
            }
        }
    }
    
    open override func themeChanged(_ style: ThemeStyle) {
        super.themeChanged(style)
        
        if let backgroundColor = fw_backgroundColor, backgroundColor.fw_isThemeColor {
            if UINavigationBar.fw_appearanceEnabled {
                if fw_isTranslucent {
                    fw_appearance.backgroundColor = backgroundColor.fw_color
                    fw_appearance.backgroundImage = nil
                } else {
                    fw_appearance.backgroundColor = nil
                    fw_appearance.backgroundImage = UIImage.fw_image(color: backgroundColor.fw_color)
                }
                fw_updateAppearance()
            } else {
                if fw_isTranslucent {
                    self.barTintColor = backgroundColor.fw_color
                    self.backgroundImage = nil
                } else {
                    self.barTintColor = nil
                    self.backgroundImage = UIImage.fw_image(color: backgroundColor.fw_color)
                }
            }
        }
        
        if let backgroundImage = fw_backgroundImage, backgroundImage.fw_isThemeImage {
            if UINavigationBar.fw_appearanceEnabled {
                fw_appearance.backgroundColor = nil
                fw_appearance.backgroundImage = backgroundImage.fw_image
                fw_updateAppearance()
            } else {
                self.barTintColor = nil
                self.backgroundImage = backgroundImage.fw_image
            }
        }
        
        if let shadowColor = fw_shadowColor, shadowColor.fw_isThemeColor {
            if UINavigationBar.fw_appearanceEnabled {
                fw_appearance.shadowColor = shadowColor.fw_color
                fw_appearance.shadowImage = nil
                fw_updateAppearance()
            } else {
                self.shadowImage = UIImage.fw_image(color: shadowColor.fw_color) ?? UIImage()
            }
        }
        
        if let shadowImage = fw_shadowImage, shadowImage.fw_isThemeImage {
            if UINavigationBar.fw_appearanceEnabled {
                fw_appearance.shadowColor = nil
                fw_appearance.shadowImage = shadowImage.fw_image
                fw_updateAppearance()
            } else {
                self.shadowImage = shadowImage.fw_image ?? UIImage()
            }
        }
    }
    
}

// MARK: - UIToolbar+BarAppearance
/// 工具栏样式分类，全局设置用[UIToolbar appearance]。iOS15+启用appearance，iOS14及以下使用旧版本api
/// 工具栏高度建议用sizeToFit自动获取(示例44)，contentView为内容视图(示例44)，backgroundView为背景视图(示例78)
/// 注意：需要支持appearance的属性必须标记为objc，否则不会生效
@_spi(FW) extension UIToolbar {
    
    /// 工具栏iOS13+样式对象，用于自定义样式，默认透明
    public var fw_appearance: UIToolbarAppearance {
        if let appearance = fw_property(forName: "fw_appearance") as? UIToolbarAppearance {
            return appearance
        } else {
            let appearance = UIToolbarAppearance()
            appearance.configureWithTransparentBackground()
            fw_setProperty(appearance, forName: "fw_appearance")
            return appearance
        }
    }

    /// 手工更新工具栏样式
    public func fw_updateAppearance() {
        self.standardAppearance = fw_appearance
        self.compactAppearance = fw_appearance
        if #available(iOS 15.0, *) {
            self.scrollEdgeAppearance = fw_appearance
            self.compactScrollEdgeAppearance = fw_appearance
        }
    }

    /// 工具栏是否半透明，会重置背景，需优先设置，默认NO；背景色需带有alpha时半透明才会生效
    @objc dynamic public var fw_isTranslucent: Bool {
        get {
            return fw_propertyBool(forName: "fw_isTranslucent")
        }
        set {
            fw_setPropertyBool(newValue, forName: "fw_isTranslucent")
            if UINavigationBar.fw_appearanceEnabled {
                if newValue {
                    fw_appearance.configureWithDefaultBackground()
                } else {
                    fw_appearance.configureWithTransparentBackground()
                }
                fw_updateAppearance()
            } else {
                if newValue {
                    self.setBackgroundImage(nil, forToolbarPosition: .any, barMetrics: .default)
                } else {
                    self.barTintColor = nil
                }
            }
        }
    }

    /// 设置前景颜色，包含文字和按钮等
    @objc dynamic public var fw_foregroundColor: UIColor? {
        get {
            return self.tintColor
        }
        set {
            self.tintColor = newValue
            if UINavigationBar.fw_appearanceEnabled {
                fw_updateAppearance()
            }
        }
    }
    
    /// 单独设置按钮样式属性，nil时系统默认。仅iOS15+生效，iOS14及以下请使用UIBarButtonItem
    @objc dynamic public var fw_buttonAttributes: [NSAttributedString.Key: Any]? {
        get {
            return fw_property(forName: "fw_buttonAttributes") as? [NSAttributedString.Key: Any]
        }
        set {
            fw_setProperty(newValue, forName: "fw_buttonAttributes")
            fw_updateButtonAttributes()
        }
    }
    
    private func fw_updateButtonAttributes() {
        if UINavigationBar.fw_appearanceEnabled {
            guard let buttonAttributes = fw_buttonAttributes else { return }
            
            let appearances = [fw_appearance.buttonAppearance, fw_appearance.doneButtonAppearance]
            for appearance in appearances {
                let stateAppearances = [appearance.normal, appearance.highlighted, appearance.disabled]
                for stateAppearance in stateAppearances {
                    var attributes = stateAppearance.titleTextAttributes
                    attributes.merge(buttonAttributes) { _, last in last }
                    stateAppearance.titleTextAttributes = attributes
                }
            }
            fw_updateAppearance()
        }
    }

    /// 设置背景颜色，兼容主题颜色，后设置生效
    @objc dynamic public var fw_backgroundColor: UIColor? {
        get {
            return fw_property(forName: "fw_backgroundColor") as? UIColor
        }
        set {
            fw_setProperty(newValue, forName: "fw_backgroundColor")
            fw_setProperty(nil, forName: "fw_backgroundImage")
            if UINavigationBar.fw_appearanceEnabled {
                if fw_isTranslucent {
                    fw_appearance.backgroundColor = newValue
                    fw_appearance.backgroundImage = nil
                } else {
                    var image: UIImage?
                    if let color = newValue {
                        image = UIImage.fw_image(color: color)
                    }
                    fw_appearance.backgroundColor = nil
                    fw_appearance.backgroundImage = image
                }
                fw_updateAppearance()
            } else {
                if fw_isTranslucent {
                    self.barTintColor = nil
                    self.setBackgroundImage(nil, forToolbarPosition: .any, barMetrics: .default)
                } else {
                    self.barTintColor = nil
                    var image: UIImage?
                    if let color = newValue {
                        image = UIImage.fw_image(color: color)
                    }
                    self.setBackgroundImage(image, forToolbarPosition: .any, barMetrics: .default)
                }
            }
        }
    }

    /// 设置背景图片，兼容主题图片，后设置生效
    @objc dynamic public var fw_backgroundImage: UIImage? {
        get {
            return fw_property(forName: "fw_backgroundImage") as? UIImage
        }
        set {
            fw_setProperty(nil, forName: "fw_backgroundColor")
            fw_setProperty(newValue, forName: "fw_backgroundImage")
            if UINavigationBar.fw_appearanceEnabled {
                fw_appearance.backgroundColor = nil
                fw_appearance.backgroundImage = newValue?.fw_image
                fw_updateAppearance()
            } else {
                self.barTintColor = nil
                self.setBackgroundImage(newValue?.fw_image, forToolbarPosition: .any, barMetrics: .default)
            }
        }
    }

    /// 设置背景是否全透明，默认NO，后设置生效
    @objc dynamic public var fw_backgroundTransparent: Bool {
        get {
            return fw_propertyBool(forName: "fw_backgroundTransparent")
        }
        set {
            fw_setPropertyBool(newValue, forName: "fw_backgroundTransparent")
            fw_setProperty(nil, forName: "fw_backgroundColor")
            fw_setProperty(nil, forName: "fw_backgroundImage")
            let image = newValue ? UIImage() : nil
            if UINavigationBar.fw_appearanceEnabled {
                fw_appearance.backgroundColor = nil
                fw_appearance.backgroundImage = image
                fw_updateAppearance()
            } else {
                self.barTintColor = nil
                self.setBackgroundImage(image, forToolbarPosition: .any, barMetrics: .default)
            }
        }
    }

    /// 设置阴影颜色(nil时透明)，兼容主题颜色，后设置生效
    @objc dynamic public var fw_shadowColor: UIColor? {
        get {
            return fw_property(forName: "fw_shadowColor") as? UIColor
        }
        set {
            fw_setProperty(newValue, forName: "fw_shadowColor")
            fw_setProperty(nil, forName: "fw_shadowImage")
            if UINavigationBar.fw_appearanceEnabled {
                fw_appearance.shadowColor = newValue
                fw_appearance.shadowImage = nil
                fw_updateAppearance()
            } else {
                var image: UIImage?
                if let color = newValue {
                    image = UIImage.fw_image(color: color)
                }
                self.setShadowImage(image ?? UIImage(), forToolbarPosition: .any)
            }
        }
    }

    /// 设置阴影图片(nil时透明)，兼容主题图片，后设置生效
    @objc dynamic public var fw_shadowImage: UIImage? {
        get {
            return fw_property(forName: "fw_shadowImage") as? UIImage
        }
        set {
            fw_setProperty(newValue, forName: "fw_shadowImage")
            fw_setProperty(nil, forName: "fw_shadowColor")
            if UINavigationBar.fw_appearanceEnabled {
                fw_appearance.shadowColor = nil
                fw_appearance.shadowImage = newValue?.fw_image
                fw_updateAppearance()
            } else {
                self.setShadowImage(newValue?.fw_image ?? UIImage(), forToolbarPosition: .any)
            }
        }
    }
    
    open override func themeChanged(_ style: ThemeStyle) {
        super.themeChanged(style)
        
        if let backgroundColor = fw_backgroundColor, backgroundColor.fw_isThemeColor {
            if UINavigationBar.fw_appearanceEnabled {
                if fw_isTranslucent {
                    fw_appearance.backgroundColor = backgroundColor.fw_color
                    fw_appearance.backgroundImage = nil
                } else {
                    fw_appearance.backgroundColor = nil
                    fw_appearance.backgroundImage = UIImage.fw_image(color: backgroundColor.fw_color)
                }
                fw_updateAppearance()
            } else {
                if fw_isTranslucent {
                    self.barTintColor = backgroundColor.fw_color
                    self.setBackgroundImage(nil, forToolbarPosition: .any, barMetrics: .default)
                } else {
                    self.barTintColor = nil
                    self.setBackgroundImage(UIImage.fw_image(color: backgroundColor.fw_color), forToolbarPosition: .any, barMetrics: .default)
                }
            }
        }
        
        if let backgroundImage = fw_backgroundImage, backgroundImage.fw_isThemeImage {
            if UINavigationBar.fw_appearanceEnabled {
                fw_appearance.backgroundColor = nil
                fw_appearance.backgroundImage = backgroundImage.fw_image
                fw_updateAppearance()
            } else {
                self.barTintColor = nil
                self.setBackgroundImage(backgroundImage.fw_image, forToolbarPosition: .any, barMetrics: .default)
            }
        }
        
        if let shadowColor = fw_shadowColor, shadowColor.fw_isThemeColor {
            if UINavigationBar.fw_appearanceEnabled {
                fw_appearance.shadowColor = shadowColor.fw_color
                fw_appearance.shadowImage = nil
                fw_updateAppearance()
            } else {
                self.setShadowImage(UIImage.fw_image(color: shadowColor.fw_color) ?? UIImage(), forToolbarPosition: .any)
            }
        }
        
        if let shadowImage = fw_shadowImage, shadowImage.fw_isThemeImage {
            if UINavigationBar.fw_appearanceEnabled {
                fw_appearance.shadowColor = nil
                fw_appearance.shadowImage = shadowImage.fw_image
                fw_updateAppearance()
            } else {
                self.setShadowImage(shadowImage.fw_image ?? UIImage(), forToolbarPosition: .any)
            }
        }
    }

    /// 自定义工具栏位置，调用后才生效，会自动设置delegate。Bottom时背景自动向下延伸，TopAttached时背景自动向上延伸
    public var fw_barPosition: UIBarPosition {
        get {
            return .init(rawValue: fw_propertyInt(forName: "fw_barPosition")) ?? .any
        }
        set {
            fw_setPropertyInt(newValue.rawValue, forName: "fw_barPosition")
            fw_toolbarDelegate.barPosition = newValue
        }
    }
    
    private var fw_toolbarDelegate: ToolbarDelegate {
        if let delegate = fw_property(forName: "fw_toolbarDelegate") as? ToolbarDelegate {
            return delegate
        } else {
            let delegate = ToolbarDelegate()
            self.delegate = delegate
            fw_setProperty(delegate, forName: "fw_toolbarDelegate")
            return delegate
        }
    }
    
    private class ToolbarDelegate: NSObject, UIToolbarDelegate {
        
        var barPosition: UIBarPosition = .any
        
        func position(for bar: UIBarPositioning) -> UIBarPosition {
            return barPosition
        }
        
    }
    
}
