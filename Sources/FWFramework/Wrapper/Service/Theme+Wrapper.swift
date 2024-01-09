//
//  Theme+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

// MARK: - UIColor+Theme
extension Wrapper where Base: UIColor {
    
    /// 获取当前主题样式对应静态颜色，主要用于iOS13以下兼容主题切换
    public var color: UIColor {
        return base.fw_color
    }

    /// 指定主题样式获取对应静态颜色，iOS13+可跟随系统改变
    public func color(forStyle style: ThemeStyle) -> UIColor {
        return base.fw_color(forStyle: style)
    }

    /// 是否是主题颜色，仅支持判断使用fwTheme创建的颜色
    public var isThemeColor: Bool {
        return base.fw_isThemeColor
    }
    
    /// 动态创建主题色，分别指定浅色和深色
    public static func themeLight(_ light: UIColor, dark: UIColor) -> UIColor {
        return Base.fw_themeLight(light, dark: dark)
    }

    /// 动态创建主题色，指定提供句柄
    public static func themeColor(_ provider: @escaping (ThemeStyle) -> UIColor) -> UIColor {
        return Base.fw_themeColor(provider)
    }

    /// 动态创建主题色，指定名称，兼容iOS11+系统方式(仅iOS13+支持动态颜色)和手工指定。失败时返回clear防止崩溃
    public static func themeNamed(_ name: String) -> UIColor {
        return Base.fw_themeNamed(name)
    }

    /// 动态创建主题色，指定名称和bundle，兼容iOS11+系统方式(仅iOS13+支持动态颜色)和手工指定。失败时返回clear防止崩溃
    public static func themeNamed(_ name: String, bundle: Bundle?) -> UIColor {
        return Base.fw_themeNamed(name, bundle: bundle)
    }

    /// 手工单个注册主题色，未配置主题色或者需兼容iOS11以下时可使用本方式
    public static func setThemeColor(_ color: UIColor?, forName name: String) {
        Base.fw_setThemeColor(color, forName: name)
    }

    /// 手工批量注册主题色，未配置主题色或者需兼容iOS11以下时可使用本方式
    public static func setThemeColors(_ nameColors: [String: UIColor]) {
        Base.fw_setThemeColors(nameColors)
    }
    
}

// MARK: - UIImage+Theme
/// 注意UIImage默认只有name方式且配置了any和dark才支持动态切换，否则只能重新赋值才会变化。
/// 为避免内存泄漏，通过fwTheme方式创建的主题图片不能直接用于显示，显示时请调用fwImage方法
extension Wrapper where Base: UIImage {
    
    /// 获取当前主题样式对应静态图片用于显示，iOS13+可跟随系统改变
    public var image: UIImage? {
        return base.fw_image
    }

    /// 指定主题样式获取对应静态图片用于显示，iOS13+可跟随系统改变
    public func image(forStyle style: ThemeStyle) -> UIImage? {
        return base.fw_image(forStyle: style)
    }

    /// 是否是主题图片，仅支持判断使用fwTheme创建的图片
    public var isThemeImage: Bool {
        return base.fw_isThemeImage
    }
    
    // MARK: - Color
    /// 快速生成当前图片对应的默认主题图片
    public var themeImage: UIImage {
        return base.fw_themeImage
    }

    /// 指定主题颜色，快速生成当前图片对应的主题图片
    public func themeImage(color themeColor: UIColor) -> UIImage {
        return base.fw_themeImage(color: themeColor)
    }
    
    // MARK: - Theme
    /// 创建主题模拟动态图像，分别指定浅色和深色，不支持动态切换，需重新赋值才会变化
    public static func themeLight(_ light: UIImage?, dark: UIImage?) -> UIImage {
        return Base.fw_themeLight(light, dark: dark)
    }

    /// 创建主题模拟动态图像，指定提供句柄，不支持动态切换，需重新赋值才会变化
    public static func themeImage(_ provider: @escaping (ThemeStyle) -> UIImage?) -> UIImage {
        return Base.fw_themeImage(provider)
    }

    /// 创建主题模拟动态图像，指定名称，兼容系统方式(仅iOS13+支持动态图像)和手工指定，支持动态切换，需配置any和dark
    public static func themeNamed(_ name: String) -> UIImage {
        return Base.fw_themeNamed(name)
    }

    /// 创建主题模拟动态图像，指定名称和bundle，兼容系统方式(仅iOS13+支持动态图像)和手工指定，支持动态切换，需配置any和dark
    public static func themeNamed(_ name: String, bundle: Bundle?) -> UIImage {
        return Base.fw_themeNamed(name, bundle: bundle)
    }

    /// 手工单个注册主题图像，未配置主题图像时可使用本方式
    public static func setThemeImage(_ image: UIImage?, forName name: String) {
        Base.fw_setThemeImage(image, forName: name)
    }

    /// 手工批量注册主题图像，未配置主题图像时可使用本方式
    public static func setThemeImages(_ nameImages: [String: UIImage]) {
        Base.fw_setThemeImages(nameImages)
    }

    // MARK: - Color
    /// 默认主题图片颜色，未设置时为浅色=>黑色，深色=>白色
    public static var themeImageColor: UIColor {
        return Base.fw_themeImageColor
    }
    
    /// 默认主题图片颜色配置句柄，默认nil
    public static var themeImageColorConfiguration: (() -> UIColor)? {
        get { Base.fw_themeImageColorConfiguration }
        set { Base.fw_themeImageColorConfiguration = newValue }
    }
    
}

// MARK: - UIImageAsset+Theme
extension Wrapper where Base: UIImageAsset {
    
    /// 获取当前主题样式对应静态图片用于显示，iOS13+可跟随系统改变
    public var image: UIImage? {
        return base.fw_image
    }

    /// 指定主题样式获取对应静态图片用于显示，iOS13+可跟随系统改变
    public func image(forStyle style: ThemeStyle) -> UIImage? {
        return base.fw_image(forStyle: style)
    }

    /// 是否是主题图片资源，仅支持判断使用fwTheme创建的图片资源
    public var isThemeAsset: Bool {
        return base.fw_isThemeAsset
    }
    
    /// 创建主题动态图片资源，分别指定浅色和深色，系统方式，推荐使用
    public static func themeLight(_ light: UIImage?, dark: UIImage?) -> UIImageAsset {
        return Base.fw_themeLight(light, dark: dark)
    }

    /// 创建主题动态图片资源，指定提供句柄，内部使用ThemeObject实现
    public static func themeAsset(_ provider: @escaping (ThemeStyle) -> UIImage?) -> UIImageAsset {
        return Base.fw_themeAsset(provider)
    }
    
}

// MARK: - NSObject+Theme
extension Wrapper where Base: NSObject {
    
    /// 订阅主题通知并指定主题上下文(如vc|view)，非UITraitEnvironment等需指定后才能响应系统主题
    public weak var themeContext: (NSObject & UITraitEnvironment)? {
        get { base.fw_themeContext }
        set { base.fw_themeContext = newValue }
    }

    /// 添加iOS13主题改变通知回调，返回订阅唯一标志，需订阅后才生效
    @discardableResult
    public func addThemeListener(_ listener: @escaping (ThemeStyle) -> Void) -> String {
        return base.fw_addThemeListener(listener)
    }

    /// iOS13根据订阅唯一标志移除主题通知回调
    public func removeThemeListener(_ identifier: String) {
        base.fw_removeThemeListener(identifier)
    }

    /// iOS13移除所有主题通知回调，一般用于cell重用
    public func removeAllThemeListeners() {
        base.fw_removeAllThemeListeners()
    }
    
}

// MARK: - UIImageView+Theme
extension Wrapper where Base: UIImageView {
    
    /// 设置主题图片，自动跟随系统改变，清空时需置为nil，二选一
    public var themeImage: UIImage? {
        get { base.fw_themeImage }
        set { base.fw_themeImage = newValue }
    }

    /// 设置主题图片资源，自动跟随系统改变，清空时需置为nil，二选一
    public var themeAsset: UIImageAsset? {
        get { base.fw_themeAsset }
        set { base.fw_themeAsset = newValue }
    }
    
}
