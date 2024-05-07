//
//  BarAppearance.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

// MARK: - Wrapper+UINavigationBar
/// 导航栏视图分类，默认iOS15+启用appearance，iOS14及以下使用旧版本api
///
/// 注意：默认不支持全局设置UINavigationBar.appearance，如需支持appearance请自行扩展实现。
/// 实现时需要支持appearance的属性必须标记为objc，否则不会生效
extension Wrapper where Base: UINavigationBar {
    /// 是否强制iOS13+启用新版样式，默认false，仅iOS15+才启用
    public static var appearanceEnabled: Bool {
        get {
            if #available(iOS 15.0, *) {
                return true
            }
            return ToolbarDelegate.appearanceEnabled
        }
        set {
            ToolbarDelegate.appearanceEnabled = newValue
        }
    }
    
    /// 设置全局按钮样式属性，nil时系统默认
    public static var buttonAttributes: [NSAttributedString.Key: Any]? {
        get {
            return ToolbarDelegate.buttonAttributes
        }
        set {
            ToolbarDelegate.buttonAttributes = newValue
            guard let buttonAttributes = newValue else { return }
            
            if !UINavigationBar.fw.appearanceEnabled {
                let itemAppearance = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
                let states: [UIControl.State] = [.normal, .highlighted, .disabled, .focused]
                for state in states {
                    var attributes = itemAppearance.titleTextAttributes(for: state) ?? [:]
                    attributes.merge(buttonAttributes) { _, last in last }
                    itemAppearance.setTitleTextAttributes(attributes, for: state)
                }
            }
        }
    }
    
    /// 导航栏iOS13+样式对象，用于自定义样式，默认透明
    public var appearance: UINavigationBarAppearance {
        if let appearance = property(forName: "appearance") as? UINavigationBarAppearance {
            return appearance
        } else {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            setProperty(appearance, forName: "appearance")
            return appearance
        }
    }

    /// 手工更新导航栏样式
    public func updateAppearance() {
        base.standardAppearance = appearance
        base.compactAppearance = appearance
        base.scrollEdgeAppearance = appearance
        if #available(iOS 15.0, *) {
            base.compactScrollEdgeAppearance = appearance
        }
    }

    /// 导航栏是否半透明，会重置背景，需优先设置，默认NO；背景色需带有alpha时半透明才会生效
    public var isTranslucent: Bool {
        get {
            return propertyBool(forName: "isTranslucent")
        }
        set {
            setPropertyBool(newValue, forName: "isTranslucent")
            if UINavigationBar.fw.appearanceEnabled {
                if newValue {
                    appearance.configureWithDefaultBackground()
                } else {
                    appearance.configureWithTransparentBackground()
                }
                updateAppearance()
            } else {
                if newValue {
                    base.setBackgroundImage(nil, for: .default)
                } else {
                    base.barTintColor = nil
                }
            }
        }
    }

    /// 设置前景颜色，包含文字和按钮等
    public var foregroundColor: UIColor? {
        get {
            return base.tintColor
        }
        set {
            base.tintColor = newValue
            updateTitleAttributes()
            updateButtonAttributes()
        }
    }

    /// 单独设置标题颜色，nil时显示前景颜色
    public var titleAttributes: [NSAttributedString.Key: Any]? {
        get {
            return property(forName: "titleAttributes") as? [NSAttributedString.Key: Any]
        }
        set {
            setProperty(newValue, forName: "titleAttributes")
            updateTitleAttributes()
        }
    }
    
    /// 单独设置按钮样式属性，nil时系统默认。仅iOS15+生效，iOS14及以下请使用UIBarButtonItem
    public var buttonAttributes: [NSAttributedString.Key: Any]? {
        get {
            return property(forName: "buttonAttributes") as? [NSAttributedString.Key: Any]
        }
        set {
            setProperty(newValue, forName: "buttonAttributes")
            updateButtonAttributes()
        }
    }
    
    private func updateTitleAttributes() {
        if UINavigationBar.fw.appearanceEnabled {
            var attributes = appearance.titleTextAttributes
            attributes[NSAttributedString.Key.foregroundColor] = base.tintColor
            if let titleAttributes = titleAttributes {
                attributes.merge(titleAttributes) { _, last in last }
            }
            appearance.titleTextAttributes = attributes
            
            var largeAttributes = appearance.largeTitleTextAttributes
            largeAttributes[NSAttributedString.Key.foregroundColor] = base.tintColor
            if let titleAttributes = titleAttributes {
                largeAttributes.merge(titleAttributes) { _, last in last }
            }
            appearance.largeTitleTextAttributes = largeAttributes
            updateAppearance()
        } else {
            var attributes = base.titleTextAttributes ?? [:]
            attributes[NSAttributedString.Key.foregroundColor] = base.tintColor
            if let titleAttributes = titleAttributes {
                attributes.merge(titleAttributes) { _, last in last }
            }
            base.titleTextAttributes = attributes
            
            var largeAttributes = base.largeTitleTextAttributes ?? [:]
            largeAttributes[NSAttributedString.Key.foregroundColor] = base.tintColor
            if let titleAttributes = titleAttributes {
                largeAttributes.merge(titleAttributes) { _, last in last }
            }
            base.largeTitleTextAttributes = largeAttributes
        }
    }
    
    private func updateButtonAttributes() {
        if UINavigationBar.fw.appearanceEnabled {
            guard let buttonAttributes = buttonAttributes ?? ToolbarDelegate.buttonAttributes else { return }
            
            let buttonAppearances = [appearance.buttonAppearance, appearance.doneButtonAppearance, appearance.backButtonAppearance]
            for buttonAppearance in buttonAppearances {
                let stateAppearances = [buttonAppearance.normal, buttonAppearance.highlighted, buttonAppearance.disabled]
                for stateAppearance in stateAppearances {
                    var attributes = stateAppearance.titleTextAttributes
                    attributes.merge(buttonAttributes) { _, last in last }
                    stateAppearance.titleTextAttributes = attributes
                }
            }
            updateAppearance()
        }
    }

    /// 设置背景颜色(nil时透明)，兼容主题颜色，后设置生效
    public var backgroundColor: UIColor? {
        get {
            return property(forName: "backgroundColor") as? UIColor
        }
        set {
            setProperty(newValue, forName: "backgroundColor")
            setProperty(nil, forName: "backgroundImage")
            if UINavigationBar.fw.appearanceEnabled {
                if isTranslucent {
                    appearance.backgroundColor = newValue
                    appearance.backgroundImage = nil
                } else {
                    var image: UIImage?
                    if let color = newValue {
                        image = UIImage.fw.image(color: color)
                    }
                    appearance.backgroundColor = nil
                    appearance.backgroundImage = image ?? UIImage()
                }
                updateAppearance()
            } else {
                if isTranslucent {
                    base.barTintColor = nil
                    base.setBackgroundImage(nil, for: .default)
                } else {
                    base.barTintColor = nil
                    var image: UIImage?
                    if let color = newValue {
                        image = UIImage.fw.image(color: color)
                    }
                    base.setBackgroundImage(image ?? UIImage(), for: .default)
                }
            }
        }
    }

    /// 设置背景图片(nil时透明)，兼容主题图片，后设置生效
    public var backgroundImage: UIImage? {
        get {
            return property(forName: "backgroundImage") as? UIImage
        }
        set {
            setProperty(nil, forName: "backgroundColor")
            setProperty(newValue, forName: "backgroundImage")
            let image = newValue?.fw.image ?? UIImage()
            if UINavigationBar.fw.appearanceEnabled {
                appearance.backgroundColor = nil
                appearance.backgroundImage = image
                updateAppearance()
            } else {
                base.barTintColor = nil
                base.setBackgroundImage(image, for: .default)
            }
        }
    }

    /// 设置背景是否全透明，默认NO，后设置生效
    public var backgroundTransparent: Bool {
        get {
            return propertyBool(forName: "backgroundTransparent")
        }
        set {
            setPropertyBool(newValue, forName: "backgroundTransparent")
            setProperty(nil, forName: "backgroundColor")
            setProperty(nil, forName: "backgroundImage")
            let image = newValue ? UIImage() : nil
            if UINavigationBar.fw.appearanceEnabled {
                appearance.backgroundColor = nil
                appearance.backgroundImage = image
                updateAppearance()
            } else {
                base.barTintColor = nil
                base.setBackgroundImage(image, for: .default)
            }
        }
    }

    /// 设置阴影颜色(nil时透明)，兼容主题颜色，后设置生效
    public var shadowColor: UIColor? {
        get {
            return property(forName: "shadowColor") as? UIColor
        }
        set {
            setProperty(newValue, forName: "shadowColor")
            setProperty(nil, forName: "shadowImage")
            if UINavigationBar.fw.appearanceEnabled {
                appearance.shadowColor = newValue
                appearance.shadowImage = nil
                updateAppearance()
            } else {
                var image: UIImage?
                if let color = newValue {
                    image = UIImage.fw.image(color: color)
                }
                base.shadowImage = image ?? UIImage()
            }
        }
    }

    /// 设置阴影图片(nil时透明)，兼容主题图片，后设置生效
    public var shadowImage: UIImage? {
        get {
            return property(forName: "shadowImage") as? UIImage
        }
        set {
            setProperty(newValue, forName: "shadowImage")
            setProperty(nil, forName: "shadowColor")
            if UINavigationBar.fw.appearanceEnabled {
                appearance.shadowColor = nil
                appearance.shadowImage = newValue?.fw.image
                updateAppearance()
            } else {
                base.shadowImage = newValue?.fw.image ?? UIImage()
            }
        }
    }

    /// 设置返回按钮图片，包含图片和转场Mask图片，自动偏移和系统左侧按钮位置保持一致
    public var backImage: UIImage? {
        get {
            if UINavigationBar.fw.appearanceEnabled {
                return appearance.backIndicatorImage
            }
            return base.backIndicatorImage
        }
        set {
            let image = newValue?.fw.image(insets: UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0))
            if UINavigationBar.fw.appearanceEnabled {
                appearance.setBackIndicatorImage(image, transitionMaskImage: image)
                updateAppearance()
            } else {
                base.backIndicatorImage = image
                base.backIndicatorTransitionMaskImage = image
            }
        }
    }
    
    fileprivate func themeChanged(_ style: ThemeStyle) {
        if let backgroundColor = backgroundColor, backgroundColor.fw.isThemeColor {
            if UINavigationBar.fw.appearanceEnabled {
                if isTranslucent {
                    appearance.backgroundColor = backgroundColor.fw.color
                    appearance.backgroundImage = nil
                } else {
                    let image = UIImage.fw.image(color: backgroundColor.fw.color) ?? UIImage()
                    appearance.backgroundColor = nil
                    appearance.backgroundImage = image
                }
                updateAppearance()
            } else {
                if isTranslucent {
                    base.barTintColor = backgroundColor.fw.color
                    base.setBackgroundImage(nil, for: .default)
                } else {
                    let image = UIImage.fw.image(color: backgroundColor.fw.color) ?? UIImage()
                    base.barTintColor = nil
                    base.setBackgroundImage(image, for: .default)
                }
            }
        }
        
        if let backgroundImage = backgroundImage, backgroundImage.fw.isThemeImage {
            let image = backgroundImage.fw.image ?? UIImage()
            if UINavigationBar.fw.appearanceEnabled {
                appearance.backgroundColor = nil
                appearance.backgroundImage = image
                updateAppearance()
            } else {
                base.barTintColor = nil
                base.setBackgroundImage(image, for: .default)
            }
        }
        
        if let shadowColor = shadowColor, shadowColor.fw.isThemeColor {
            if UINavigationBar.fw.appearanceEnabled {
                appearance.shadowColor = shadowColor.fw.color
                appearance.shadowImage = nil
                updateAppearance()
            } else {
                base.shadowImage = UIImage.fw.image(color: shadowColor.fw.color) ?? UIImage()
            }
        }
        
        if let shadowImage = shadowImage, shadowImage.fw.isThemeImage {
            if UINavigationBar.fw.appearanceEnabled {
                appearance.shadowColor = nil
                appearance.shadowImage = shadowImage.fw.image
                updateAppearance()
            } else {
                base.shadowImage = shadowImage.fw.image ?? UIImage()
            }
        }
    }
}

// MARK: - Wrapper+UITabBar
/// 标签栏视图分类，iOS15+启用appearance，iOS14及以下使用旧版本api
///
/// 注意：默认不支持全局设置UITabBar.appearance，如需支持appearance请自行扩展实现。
/// 实现时需要支持appearance的属性必须标记为objc，否则不会生效
extension Wrapper where Base: UITabBar {
    /// 标签栏iOS13+样式对象，用于自定义样式，默认透明
    public var appearance: UITabBarAppearance {
        if let appearance = property(forName: "appearance") as? UITabBarAppearance {
            return appearance
        } else {
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            setProperty(appearance, forName: "appearance")
            return appearance
        }
    }

    /// 手工更新标签栏样式
    public func updateAppearance() {
        base.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            base.scrollEdgeAppearance = appearance
        }
    }

    /// 标签栏是否半透明，会重置背景，需优先设置，默认NO；背景色需带有alpha时半透明才会生效
    public var isTranslucent: Bool {
        get {
            return propertyBool(forName: "isTranslucent")
        }
        set {
            setPropertyBool(newValue, forName: "isTranslucent")
            if UINavigationBar.fw.appearanceEnabled {
                if newValue {
                    appearance.configureWithDefaultBackground()
                } else {
                    appearance.configureWithTransparentBackground()
                }
                updateAppearance()
            } else {
                if newValue {
                    base.backgroundImage = nil
                } else {
                    base.barTintColor = nil
                }
            }
        }
    }

    /// 设置前景颜色，包含文字和按钮等
    public var foregroundColor: UIColor? {
        get { return base.tintColor }
        set { base.tintColor = newValue }
    }

    /// 设置背景颜色，兼容主题颜色，后设置生效
    public var backgroundColor: UIColor? {
        get {
            return property(forName: "backgroundColor") as? UIColor
        }
        set {
            setProperty(newValue, forName: "backgroundColor")
            setProperty(nil, forName: "backgroundImage")
            if UINavigationBar.fw.appearanceEnabled {
                if isTranslucent {
                    appearance.backgroundColor = newValue
                    appearance.backgroundImage = nil
                } else {
                    var image: UIImage?
                    if let color = newValue {
                        image = UIImage.fw.image(color: color)
                    }
                    appearance.backgroundColor = nil
                    appearance.backgroundImage = image
                }
                updateAppearance()
            } else {
                if isTranslucent {
                    base.barTintColor = nil
                    base.backgroundImage = nil
                } else {
                    base.barTintColor = nil
                    var image: UIImage?
                    if let color = newValue {
                        image = UIImage.fw.image(color: color)
                    }
                    base.backgroundImage = image
                }
            }
        }
    }

    /// 设置背景图片，兼容主题图片，后设置生效
    public var backgroundImage: UIImage? {
        get {
            return property(forName: "backgroundImage") as? UIImage
        }
        set {
            setProperty(nil, forName: "backgroundColor")
            setProperty(newValue, forName: "backgroundImage")
            if UINavigationBar.fw.appearanceEnabled {
                appearance.backgroundColor = nil
                appearance.backgroundImage = newValue?.fw.image
                updateAppearance()
            } else {
                base.barTintColor = nil
                base.backgroundImage = newValue?.fw.image
            }
        }
    }

    /// 设置背景是否全透明，默认NO，后设置生效
    public var backgroundTransparent: Bool {
        get {
            return propertyBool(forName: "backgroundTransparent")
        }
        set {
            setPropertyBool(newValue, forName: "backgroundTransparent")
            setProperty(nil, forName: "backgroundColor")
            setProperty(nil, forName: "backgroundImage")
            let image = newValue ? UIImage() : nil
            if UINavigationBar.fw.appearanceEnabled {
                appearance.backgroundColor = nil
                appearance.backgroundImage = image
                updateAppearance()
            } else {
                base.barTintColor = nil
                base.backgroundImage = image
            }
        }
    }

    /// 设置阴影颜色(nil时透明)，兼容主题颜色，后设置生效
    public var shadowColor: UIColor? {
        get {
            return property(forName: "shadowColor") as? UIColor
        }
        set {
            setProperty(newValue, forName: "shadowColor")
            setProperty(nil, forName: "shadowImage")
            if UINavigationBar.fw.appearanceEnabled {
                appearance.shadowColor = newValue
                appearance.shadowImage = nil
                updateAppearance()
            } else {
                var image: UIImage?
                if let color = newValue {
                    image = UIImage.fw.image(color: color)
                }
                base.shadowImage = image ?? UIImage()
            }
        }
    }

    /// 设置阴影图片(nil时透明)，兼容主题图片，后设置生效
    public var shadowImage: UIImage? {
        get {
            return property(forName: "shadowImage") as? UIImage
        }
        set {
            setProperty(newValue, forName: "shadowImage")
            setProperty(nil, forName: "shadowColor")
            if UINavigationBar.fw.appearanceEnabled {
                appearance.shadowColor = nil
                appearance.shadowImage = newValue?.fw.image
                updateAppearance()
            } else {
                base.shadowImage = newValue?.fw.image ?? UIImage()
            }
        }
    }
    
    fileprivate func themeChanged(_ style: ThemeStyle) {
        if let backgroundColor = backgroundColor, backgroundColor.fw.isThemeColor {
            if UINavigationBar.fw.appearanceEnabled {
                if isTranslucent {
                    appearance.backgroundColor = backgroundColor.fw.color
                    appearance.backgroundImage = nil
                } else {
                    appearance.backgroundColor = nil
                    appearance.backgroundImage = UIImage.fw.image(color: backgroundColor.fw.color)
                }
                updateAppearance()
            } else {
                if isTranslucent {
                    base.barTintColor = backgroundColor.fw.color
                    base.backgroundImage = nil
                } else {
                    base.barTintColor = nil
                    base.backgroundImage = UIImage.fw.image(color: backgroundColor.fw.color)
                }
            }
        }
        
        if let backgroundImage = backgroundImage, backgroundImage.fw.isThemeImage {
            if UINavigationBar.fw.appearanceEnabled {
                appearance.backgroundColor = nil
                appearance.backgroundImage = backgroundImage.fw.image
                updateAppearance()
            } else {
                base.barTintColor = nil
                base.backgroundImage = backgroundImage.fw.image
            }
        }
        
        if let shadowColor = shadowColor, shadowColor.fw.isThemeColor {
            if UINavigationBar.fw.appearanceEnabled {
                appearance.shadowColor = shadowColor.fw.color
                appearance.shadowImage = nil
                updateAppearance()
            } else {
                base.shadowImage = UIImage.fw.image(color: shadowColor.fw.color) ?? UIImage()
            }
        }
        
        if let shadowImage = shadowImage, shadowImage.fw.isThemeImage {
            if UINavigationBar.fw.appearanceEnabled {
                appearance.shadowColor = nil
                appearance.shadowImage = shadowImage.fw.image
                updateAppearance()
            } else {
                base.shadowImage = shadowImage.fw.image ?? UIImage()
            }
        }
    }
}

// MARK: - Wrapper+UIToolbar
/// 工具栏样式分类，iOS15+启用appearance，iOS14及以下使用旧版本api
/// 工具栏高度建议用sizeToFit自动获取(示例44)，contentView为内容视图(示例44)，backgroundView为背景视图(示例78)
///
/// 注意：默认不支持全局设置UIToolbar.appearance，如需支持appearance请自行扩展实现。
/// 实现时需要支持appearance的属性必须标记为objc，否则不会生效
extension Wrapper where Base: UIToolbar {
    /// 工具栏iOS13+样式对象，用于自定义样式，默认透明
    public var appearance: UIToolbarAppearance {
        if let appearance = property(forName: "appearance") as? UIToolbarAppearance {
            return appearance
        } else {
            let appearance = UIToolbarAppearance()
            appearance.configureWithTransparentBackground()
            setProperty(appearance, forName: "appearance")
            return appearance
        }
    }

    /// 手工更新工具栏样式
    public func updateAppearance() {
        base.standardAppearance = appearance
        base.compactAppearance = appearance
        if #available(iOS 15.0, *) {
            base.scrollEdgeAppearance = appearance
            base.compactScrollEdgeAppearance = appearance
        }
    }

    /// 工具栏是否半透明，会重置背景，需优先设置，默认NO；背景色需带有alpha时半透明才会生效
    public var isTranslucent: Bool {
        get {
            return propertyBool(forName: "isTranslucent")
        }
        set {
            setPropertyBool(newValue, forName: "isTranslucent")
            if UINavigationBar.fw.appearanceEnabled {
                if newValue {
                    appearance.configureWithDefaultBackground()
                } else {
                    appearance.configureWithTransparentBackground()
                }
                updateAppearance()
            } else {
                if newValue {
                    base.setBackgroundImage(nil, forToolbarPosition: .any, barMetrics: .default)
                } else {
                    base.barTintColor = nil
                }
            }
        }
    }

    /// 设置前景颜色，包含文字和按钮等
    public var foregroundColor: UIColor? {
        get {
            return base.tintColor
        }
        set {
            base.tintColor = newValue
            if UINavigationBar.fw.appearanceEnabled {
                updateAppearance()
            }
        }
    }
    
    /// 单独设置按钮样式属性，nil时系统默认。仅iOS15+生效，iOS14及以下请使用UIBarButtonItem
    public var buttonAttributes: [NSAttributedString.Key: Any]? {
        get {
            return property(forName: "buttonAttributes") as? [NSAttributedString.Key: Any]
        }
        set {
            setProperty(newValue, forName: "buttonAttributes")
            updateButtonAttributes()
        }
    }
    
    private func updateButtonAttributes() {
        if UINavigationBar.fw.appearanceEnabled {
            guard let buttonAttributes = buttonAttributes else { return }
            
            let buttonAppearances = [appearance.buttonAppearance, appearance.doneButtonAppearance]
            for buttonAppearance in buttonAppearances {
                let stateAppearances = [buttonAppearance.normal, buttonAppearance.highlighted, buttonAppearance.disabled]
                for stateAppearance in stateAppearances {
                    var attributes = stateAppearance.titleTextAttributes
                    attributes.merge(buttonAttributes) { _, last in last }
                    stateAppearance.titleTextAttributes = attributes
                }
            }
            updateAppearance()
        }
    }

    /// 设置背景颜色，兼容主题颜色，后设置生效
    public var backgroundColor: UIColor? {
        get {
            return property(forName: "backgroundColor") as? UIColor
        }
        set {
            setProperty(newValue, forName: "backgroundColor")
            setProperty(nil, forName: "backgroundImage")
            if UINavigationBar.fw.appearanceEnabled {
                if isTranslucent {
                    appearance.backgroundColor = newValue
                    appearance.backgroundImage = nil
                } else {
                    var image: UIImage?
                    if let color = newValue {
                        image = UIImage.fw.image(color: color)
                    }
                    appearance.backgroundColor = nil
                    appearance.backgroundImage = image
                }
                updateAppearance()
            } else {
                if isTranslucent {
                    base.barTintColor = nil
                    base.setBackgroundImage(nil, forToolbarPosition: .any, barMetrics: .default)
                } else {
                    base.barTintColor = nil
                    var image: UIImage?
                    if let color = newValue {
                        image = UIImage.fw.image(color: color)
                    }
                    base.setBackgroundImage(image, forToolbarPosition: .any, barMetrics: .default)
                }
            }
        }
    }

    /// 设置背景图片，兼容主题图片，后设置生效
    public var backgroundImage: UIImage? {
        get {
            return property(forName: "backgroundImage") as? UIImage
        }
        set {
            setProperty(nil, forName: "backgroundColor")
            setProperty(newValue, forName: "backgroundImage")
            if UINavigationBar.fw.appearanceEnabled {
                appearance.backgroundColor = nil
                appearance.backgroundImage = newValue?.fw.image
                updateAppearance()
            } else {
                base.barTintColor = nil
                base.setBackgroundImage(newValue?.fw.image, forToolbarPosition: .any, barMetrics: .default)
            }
        }
    }

    /// 设置背景是否全透明，默认NO，后设置生效
    public var backgroundTransparent: Bool {
        get {
            return propertyBool(forName: "backgroundTransparent")
        }
        set {
            setPropertyBool(newValue, forName: "backgroundTransparent")
            setProperty(nil, forName: "backgroundColor")
            setProperty(nil, forName: "backgroundImage")
            let image = newValue ? UIImage() : nil
            if UINavigationBar.fw.appearanceEnabled {
                appearance.backgroundColor = nil
                appearance.backgroundImage = image
                updateAppearance()
            } else {
                base.barTintColor = nil
                base.setBackgroundImage(image, forToolbarPosition: .any, barMetrics: .default)
            }
        }
    }

    /// 设置阴影颜色(nil时透明)，兼容主题颜色，后设置生效
    public var shadowColor: UIColor? {
        get {
            return property(forName: "shadowColor") as? UIColor
        }
        set {
            setProperty(newValue, forName: "shadowColor")
            setProperty(nil, forName: "shadowImage")
            if UINavigationBar.fw.appearanceEnabled {
                appearance.shadowColor = newValue
                appearance.shadowImage = nil
                updateAppearance()
            } else {
                var image: UIImage?
                if let color = newValue {
                    image = UIImage.fw.image(color: color)
                }
                base.setShadowImage(image ?? UIImage(), forToolbarPosition: .any)
            }
        }
    }

    /// 设置阴影图片(nil时透明)，兼容主题图片，后设置生效
    public var shadowImage: UIImage? {
        get {
            return property(forName: "shadowImage") as? UIImage
        }
        set {
            setProperty(newValue, forName: "shadowImage")
            setProperty(nil, forName: "shadowColor")
            if UINavigationBar.fw.appearanceEnabled {
                appearance.shadowColor = nil
                appearance.shadowImage = newValue?.fw.image
                updateAppearance()
            } else {
                base.setShadowImage(newValue?.fw.image ?? UIImage(), forToolbarPosition: .any)
            }
        }
    }

    /// 自定义工具栏位置，调用后才生效，会自动设置delegate。Bottom时背景自动向下延伸，TopAttached时背景自动向上延伸
    public var barPosition: UIBarPosition {
        get {
            return .init(rawValue: propertyInt(forName: "barPosition")) ?? .any
        }
        set {
            setPropertyInt(newValue.rawValue, forName: "barPosition")
            toolbarDelegate.barPosition = newValue
        }
    }
    
    private var toolbarDelegate: ToolbarDelegate {
        if let delegate = property(forName: "toolbarDelegate") as? ToolbarDelegate {
            return delegate
        } else {
            let delegate = ToolbarDelegate()
            base.delegate = delegate
            setProperty(delegate, forName: "toolbarDelegate")
            return delegate
        }
    }
    
    fileprivate func themeChanged(_ style: ThemeStyle) {
        if let backgroundColor = backgroundColor, backgroundColor.fw.isThemeColor {
            if UINavigationBar.fw.appearanceEnabled {
                if isTranslucent {
                    appearance.backgroundColor = backgroundColor.fw.color
                    appearance.backgroundImage = nil
                } else {
                    appearance.backgroundColor = nil
                    appearance.backgroundImage = UIImage.fw.image(color: backgroundColor.fw.color)
                }
                updateAppearance()
            } else {
                if isTranslucent {
                    base.barTintColor = backgroundColor.fw.color
                    base.setBackgroundImage(nil, forToolbarPosition: .any, barMetrics: .default)
                } else {
                    base.barTintColor = nil
                    base.setBackgroundImage(UIImage.fw.image(color: backgroundColor.fw.color), forToolbarPosition: .any, barMetrics: .default)
                }
            }
        }
        
        if let backgroundImage = backgroundImage, backgroundImage.fw.isThemeImage {
            if UINavigationBar.fw.appearanceEnabled {
                appearance.backgroundColor = nil
                appearance.backgroundImage = backgroundImage.fw.image
                updateAppearance()
            } else {
                base.barTintColor = nil
                base.setBackgroundImage(backgroundImage.fw.image, forToolbarPosition: .any, barMetrics: .default)
            }
        }
        
        if let shadowColor = shadowColor, shadowColor.fw.isThemeColor {
            if UINavigationBar.fw.appearanceEnabled {
                appearance.shadowColor = shadowColor.fw.color
                appearance.shadowImage = nil
                updateAppearance()
            } else {
                base.setShadowImage(UIImage.fw.image(color: shadowColor.fw.color) ?? UIImage(), forToolbarPosition: .any)
            }
        }
        
        if let shadowImage = shadowImage, shadowImage.fw.isThemeImage {
            if UINavigationBar.fw.appearanceEnabled {
                appearance.shadowColor = nil
                appearance.shadowImage = shadowImage.fw.image
                updateAppearance()
            } else {
                base.setShadowImage(shadowImage.fw.image ?? UIImage(), forToolbarPosition: .any)
            }
        }
    }
}

// MARK: - ToolbarDelegate
fileprivate class ToolbarDelegate: NSObject, UIToolbarDelegate {
    static var appearanceEnabled = false
    static var buttonAttributes: [NSAttributedString.Key: Any]?
    
    var barPosition: UIBarPosition = .any
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return barPosition
    }
}

// MARK: - UINavigationBar+BarAppearance
extension UINavigationBar {
    
    open override func themeChanged(_ style: ThemeStyle) {
        super.themeChanged(style)
        
        fw.themeChanged(style)
    }
    
}

// MARK: - UITabBar+BarAppearance
extension UITabBar {
    
    open override func themeChanged(_ style: ThemeStyle) {
        super.themeChanged(style)
        
        fw.themeChanged(style)
    }
    
}

// MARK: - UIToolbar+BarAppearance
extension UIToolbar {
    
    open override func themeChanged(_ style: ThemeStyle) {
        super.themeChanged(style)
        
        fw.themeChanged(style)
    }
    
}
