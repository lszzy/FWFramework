//
//  BarAppearance.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

// MARK: - UINavigationBar+BarAppearance
/// 导航栏视图分类，全局设置用[UINavigationBar appearance]。默认iOS15+启用appearance，iOS14及以下使用旧版本api
extension Wrapper where Base: UINavigationBar {
    
    /// 是否强制iOS13+启用新版样式，默认false，仅iOS15+才启用
    public static var appearanceEnabled: Bool {
        get { return Base.__fw_appearanceEnabled }
        set { Base.__fw_appearanceEnabled = newValue }
    }
    
    /// 设置全局按钮样式属性，nil时系统默认
    public static var buttonAttributes: [NSAttributedString.Key: Any]? {
        get { return Base.__fw_buttonAttributes }
        set { Base.__fw_buttonAttributes = newValue }
    }
    
    /// 导航栏iOS13+样式对象，用于自定义样式，默认透明
    @available(iOS 13.0, *)
    public var appearance: UINavigationBarAppearance {
        return base.__fw_appearance
    }

    /// 手工更新导航栏样式
    @available(iOS 13.0, *)
    public func updateAppearance() {
        base.__fw_updateAppearance()
    }

    /// 导航栏是否半透明，会重置背景，需优先设置，默认NO；背景色需带有alpha时半透明才会生效
    public var isTranslucent: Bool {
        get { return base.__fw_isTranslucent }
        set { base.__fw_isTranslucent = newValue }
    }

    /// 设置前景颜色，包含文字和按钮等
    public var foregroundColor: UIColor? {
        get { return base.__fw_foregroundColor }
        set { base.__fw_foregroundColor = newValue }
    }

    /// 单独设置标题颜色，nil时显示前景颜色
    public var titleAttributes: [NSAttributedString.Key: Any]? {
        get { return base.__fw_titleAttributes }
        set { base.__fw_titleAttributes = newValue }
    }
    
    /// 单独设置按钮样式属性，nil时系统默认。仅iOS15+生效，iOS14及以下请使用UIBarButtonItem
    public var buttonAttributes: [NSAttributedString.Key: Any]? {
        get { return base.__fw_buttonAttributes }
        set { base.__fw_buttonAttributes = newValue }
    }

    /// 设置背景颜色(nil时透明)，兼容主题颜色，后设置生效
    public var backgroundColor: UIColor? {
        get { return base.__fw_backgroundColor }
        set { base.__fw_backgroundColor = newValue }
    }

    /// 设置背景图片(nil时透明)，兼容主题图片，后设置生效
    public var backgroundImage: UIImage? {
        get { return base.__fw_backgroundImage }
        set { base.__fw_backgroundImage = newValue }
    }

    /// 设置背景是否全透明，默认NO，后设置生效
    public var backgroundTransparent: Bool {
        get { return base.__fw_backgroundTransparent }
        set { base.__fw_backgroundTransparent = newValue }
    }

    /// 设置阴影颜色(nil时透明)，兼容主题颜色，后设置生效
    public var shadowColor: UIColor? {
        get { return base.__fw_shadowColor }
        set { base.__fw_shadowColor = newValue }
    }

    /// 设置阴影图片(nil时透明)，兼容主题图片，后设置生效
    public var shadowImage: UIImage? {
        get { return base.__fw_shadowImage }
        set { base.__fw_shadowImage = newValue }
    }

    /// 设置返回按钮图片，包含图片和转场Mask图片，自动偏移和系统左侧按钮位置保持一致
    public var backImage: UIImage? {
        get { return base.__fw_backImage }
        set { base.__fw_backImage = newValue }
    }
    
}

// MARK: - UITabBar+BarAppearance
/// 标签栏视图分类，全局设置用[UITabBar appearance]。iOS15+启用appearance，iOS14及以下使用旧版本api
extension Wrapper where Base: UITabBar {
    
    /// 标签栏iOS13+样式对象，用于自定义样式，默认透明
    @available(iOS 13.0, *)
    public var appearance: UITabBarAppearance {
        return base.__fw_appearance
    }

    /// 手工更新标签栏样式
    @available(iOS 13.0, *)
    public func updateAppearance() {
        base.__fw_updateAppearance()
    }

    /// 标签栏是否半透明，会重置背景，需优先设置，默认NO；背景色需带有alpha时半透明才会生效
    public var isTranslucent: Bool {
        get { return base.__fw_isTranslucent }
        set { base.__fw_isTranslucent = newValue }
    }

    /// 设置前景颜色，包含文字和按钮等
    public var foregroundColor: UIColor? {
        get { return base.__fw_foregroundColor }
        set { base.__fw_foregroundColor = newValue }
    }

    /// 设置背景颜色，兼容主题颜色，后设置生效
    public var backgroundColor: UIColor? {
        get { return base.__fw_backgroundColor }
        set { base.__fw_backgroundColor = newValue }
    }

    /// 设置背景图片，兼容主题图片，后设置生效
    public var backgroundImage: UIImage? {
        get { return base.__fw_backgroundImage }
        set { base.__fw_backgroundImage = newValue }
    }

    /// 设置背景是否全透明，默认NO，后设置生效
    public var backgroundTransparent: Bool {
        get { return base.__fw_backgroundTransparent }
        set { base.__fw_backgroundTransparent = newValue }
    }

    /// 设置阴影颜色(nil时透明)，兼容主题颜色，后设置生效
    public var shadowColor: UIColor? {
        get { return base.__fw_shadowColor }
        set { base.__fw_shadowColor = newValue }
    }

    /// 设置阴影图片(nil时透明)，兼容主题图片，后设置生效
    public var shadowImage: UIImage? {
        get { return base.__fw_shadowImage }
        set { base.__fw_shadowImage = newValue }
    }
    
}

// MARK: - UIToolbar+BarAppearance
/// 工具栏样式分类，全局设置用[UIToolbar appearance]。iOS15+启用appearance，iOS14及以下使用旧版本api
/// 工具栏高度建议用sizeToFit自动获取(示例44)，contentView为内容视图(示例44)，backgroundView为背景视图(示例78)
extension Wrapper where Base: UIToolbar {
    
    /// 工具栏iOS13+样式对象，用于自定义样式，默认透明
    @available(iOS 13.0, *)
    public var appearance: UIToolbarAppearance {
        return base.__fw_appearance
    }

    /// 手工更新工具栏样式
    @available(iOS 13.0, *)
    public func updateAppearance() {
        base.__fw_updateAppearance()
    }

    /// 工具栏是否半透明，会重置背景，需优先设置，默认NO；背景色需带有alpha时半透明才会生效
    public var isTranslucent: Bool {
        get { return base.__fw_isTranslucent }
        set { base.__fw_isTranslucent = newValue }
    }

    /// 设置前景颜色，包含文字和按钮等
    public var foregroundColor: UIColor? {
        get { return base.__fw_foregroundColor }
        set { base.__fw_foregroundColor = newValue }
    }
    
    /// 单独设置按钮样式属性，nil时系统默认。仅iOS15+生效，iOS14及以下请使用UIBarButtonItem
    public var buttonAttributes: [NSAttributedString.Key: Any]? {
        get { return base.__fw_buttonAttributes }
        set { base.__fw_buttonAttributes = newValue }
    }

    /// 设置背景颜色，兼容主题颜色，后设置生效
    public var backgroundColor: UIColor? {
        get { return base.__fw_backgroundColor }
        set { base.__fw_backgroundColor = newValue }
    }

    /// 设置背景图片，兼容主题图片，后设置生效
    public var backgroundImage: UIImage? {
        get { return base.__fw_backgroundImage }
        set { base.__fw_backgroundImage = newValue }
    }

    /// 设置背景是否全透明，默认NO，后设置生效
    public var backgroundTransparent: Bool {
        get { return base.__fw_backgroundTransparent }
        set { base.__fw_backgroundTransparent = newValue }
    }

    /// 设置阴影颜色(nil时透明)，兼容主题颜色，后设置生效
    public var shadowColor: UIColor? {
        get { return base.__fw_shadowColor }
        set { base.__fw_shadowColor = newValue }
    }

    /// 设置阴影图片(nil时透明)，兼容主题图片，后设置生效
    public var shadowImage: UIImage? {
        get { return base.__fw_shadowImage }
        set { base.__fw_shadowImage = newValue }
    }

    /// 自定义工具栏位置，调用后才生效，会自动设置delegate。Bottom时背景自动向下延伸，TopAttached时背景自动向上延伸
    public var barPosition: UIBarPosition {
        get { return base.__fw_barPosition }
        set { base.__fw_barPosition = newValue }
    }
    
}
