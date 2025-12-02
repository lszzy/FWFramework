//
//  Palette.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

// MARK: - Wrapper+UIColor
extension Wrapper where Base: UIColor {
    /// 主题色
    public static var primary: UIColor { paletteThemeColor("primary") }
    /// 主题色（深）
    public static var primaryDark: UIColor { paletteThemeColor("primaryDark") }
    /// 主题色（禁用）
    public static var primaryDisabled: UIColor { paletteThemeColor("primaryDisabled") }
    /// 主题色（淡）
    public static var primaryLight: UIColor { paletteThemeColor("primaryLight") }
    /// 成功色
    public static var success: UIColor { paletteThemeColor("success") }
    /// 成功色（深）
    public static var successDark: UIColor { paletteThemeColor("successDark") }
    /// 成功色（禁用）
    public static var successDisabled: UIColor { paletteThemeColor("successDisabled") }
    /// 成功色（淡）
    public static var successLight: UIColor { paletteThemeColor("successLight") }
    /// 警告色
    public static var warning: UIColor { paletteThemeColor("warning") }
    /// 警告色（深）
    public static var warningDark: UIColor { paletteThemeColor("warningDark") }
    /// 警告色（禁用）
    public static var warningDisabled: UIColor { paletteThemeColor("warningDisabled") }
    /// 警告色（淡）
    public static var warningLight: UIColor { paletteThemeColor("warningLight") }
    /// 错误色
    public static var error: UIColor { paletteThemeColor("error") }
    /// 错误色（深）
    public static var errorDark: UIColor { paletteThemeColor("errorDark") }
    /// 错误色（禁用）
    public static var errorDisabled: UIColor { paletteThemeColor("errorDisabled") }
    /// 错误色（淡）
    public static var errorLight: UIColor { paletteThemeColor("errorLight") }
    /// 信息色
    public static var info: UIColor { paletteThemeColor("info") }
    /// 信息色（深）
    public static var infoDark: UIColor { paletteThemeColor("infoDark") }
    /// 信息色（禁用）
    public static var infoDisabled: UIColor { paletteThemeColor("infoDisabled") }
    /// 信息色（淡）
    public static var infoLight: UIColor { paletteThemeColor("infoLight") }
    
    /// 纯白色值
    public static var whiteColor: UIColor { paletteThemeColor("whiteColor") }
    /// 纯黑色值
    public static var blackColor: UIColor { paletteThemeColor("blackColor") }
    /// 主要文字
    public static var mainColor: UIColor { paletteThemeColor("mainColor") }
    /// 常规文字
    public static var contentColor: UIColor { paletteThemeColor("contentColor") }
    /// 次要文字
    public static var tipsColor: UIColor { paletteThemeColor("tipsColor") }
    /// 占位文字
    public static var lightColor: UIColor { paletteThemeColor("lightColor") }
    /// 边框颜色
    public static var borderColor: UIColor { paletteThemeColor("borderColor") }
    /// 分割线
    public static var dividerColor: UIColor { paletteThemeColor("dividerColor") }
    /// 遮罩色
    public static var maskColor: UIColor { paletteThemeColor("maskColor") }
    /// 阴影颜色
    public static var shadowColor: UIColor { paletteThemeColor("shadowColor") }
    /// 背景色
    public static var bgColor: UIColor { paletteThemeColor("bgColor") }
    /// 纯白背景
    public static var bgWhite: UIColor { paletteThemeColor("bgWhite") }
    /// 浅灰背景
    public static var bgGrayLight: UIColor { paletteThemeColor("bgGrayLight") }
    /// 深灰背景
    public static var bgGrayDark: UIColor { paletteThemeColor("bgGrayDark") }
    /// 纯黑背景
    public static var bgBlack: UIColor { paletteThemeColor("bgBlack") }
    
    /// 浅色调色板配置（变体）
    public static var lightPalette: [String: UIColor] {
        get { UIColor.innerLightPalette }
        set { UIColor.innerLightPalette = newValue }
    }
    
    /// 深色调色板配置（变体）
    public static var darkPalette: [String: UIColor] {
        get { UIColor.innerDarkPalette }
        set { UIColor.innerDarkPalette = newValue }
    }
    
    /// 浅色调色板配置（结构体）
    public static var lightStructuralPalette: [String: UIColor] {
        get { UIColor.innerLightStructuralPalette }
        set { UIColor.innerLightStructuralPalette = newValue }
    }
    
    /// 深色调色板配置（结构体）
    public static var darkStructuralPalette: [String: UIColor] {
        get { UIColor.innerDarkStructuralPalette }
        set { UIColor.innerDarkStructuralPalette = newValue }
    }
    
    /// 自定义调色板变形比率，默认0.6
    public static var paletteRatio: CGFloat {
        get { UIColor.innerPaletteRatio }
        set { UIColor.innerPaletteRatio = newValue }
    }
    
    /// 从调色板生成主题色
    public static func paletteThemeColor(_ name: String) -> UIColor {
        return UIColor.fw.themeColor { style in
            if style == .dark {
                return paletteDarkColor(name)
            } else {
                return paletteLightColor(name)
            }
        }
    }
    
    /// 从调色板生成浅色
    public static func paletteLightColor(_ name: String) -> UIColor {
        let light = lightPalette[name] ?? lightStructuralPalette[name]
        return light ?? .clear
    }
    
    /// 从调色板生成深色
    public static func paletteDarkColor(_ name: String) -> UIColor {
        if let dark = darkPalette[name] {
            return paletteVariantColor(light: paletteLightColor(name), dark: dark)
        }
        return darkStructuralPalette[name] ?? paletteLightColor(name)
    }
    
    /// 从指定浅色和深色自动生成变体色，不含透明度，可自定义比率
    public static func paletteVariantColor(light: UIColor, dark: UIColor, ratio: CGFloat? = nil) -> UIColor {
        let from = light.fw.rgbaValue
        let to = dark.fw.rgbaValue
        let ratio = ratio ?? paletteRatio
        let clamp: (CGFloat) -> Int = { val in max(0, min(lround(val), 255)) }
        let red = clamp((1.0 - ratio) * CGFloat(from.r) + ratio * CGFloat(to.r))
        let green = clamp((1.0 - ratio) * CGFloat(from.g) + ratio * CGFloat(to.g))
        let blue = clamp((1.0 - ratio) * CGFloat(from.b) + ratio * CGFloat(to.b))
        return UIColor(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
}

// MARK: - UIColor+Palette
extension UIColor {
    fileprivate nonisolated(unsafe) static var innerPaletteRatio: CGFloat = 0.6
    
    fileprivate nonisolated(unsafe) static var innerLightPalette = [
        "primary": UIColor.fw.color(hex: 0x2979ff),
        "primaryDark": UIColor.fw.color(hex: 0x2b85e4),
        "primaryDisabled": UIColor.fw.color(hex: 0xa0cfff),
        "primaryLight": UIColor.fw.color(hex: 0xecf5ff),
        "success": UIColor.fw.color(hex: 0x19be6b),
        "successDark": UIColor.fw.color(hex: 0x18b566),
        "successDisabled": UIColor.fw.color(hex: 0x71d5a1),
        "successLight": UIColor.fw.color(hex: 0xdbf1e1),
        "warning": UIColor.fw.color(hex: 0xff9900),
        "warningDark": UIColor.fw.color(hex: 0xf29100),
        "warningDisabled": UIColor.fw.color(hex: 0xfcbd71),
        "warningLight": UIColor.fw.color(hex: 0xfdf6ec),
        "error": UIColor.fw.color(hex: 0xfa3534),
        "errorDark": UIColor.fw.color(hex: 0xdd6161),
        "errorDisabled": UIColor.fw.color(hex: 0xfab6b6),
        "errorLight": UIColor.fw.color(hex: 0xfef0f0),
        "info": UIColor.fw.color(hex: 0x909399),
        "infoDark": UIColor.fw.color(hex: 0x82848a),
        "infoDisabled": UIColor.fw.color(hex: 0xc8c9cc),
        "infoLight": UIColor.fw.color(hex: 0xf4f4f5)
    ]
    
    fileprivate nonisolated(unsafe) static var innerDarkPalette = [
        "primary": UIColor.fw.color(hex: 0x8ab4ff),
        "primaryDark": UIColor.fw.color(hex: 0x5f8dff),
        "primaryDisabled": UIColor.fw.color(hex: 0x3d4f74),
        "primaryLight": UIColor.fw.color(hex: 0x1d273f),
        "success": UIColor.fw.color(hex: 0x4ade80),
        "successDark": UIColor.fw.color(hex: 0x1f9d57),
        "successDisabled": UIColor.fw.color(hex: 0x2f4d3d),
        "successLight": UIColor.fw.color(hex: 0x10291f),
        "warning": UIColor.fw.color(hex: 0xfbbf24),
        "warningDark": UIColor.fw.color(hex: 0xc88f00),
        "warningDisabled": UIColor.fw.color(hex: 0x4a3b17),
        "warningLight": UIColor.fw.color(hex: 0x2b1f05),
        "error": UIColor.fw.color(hex: 0xff6b6b),
        "errorDark": UIColor.fw.color(hex: 0xd83a3a),
        "errorDisabled": UIColor.fw.color(hex: 0x4f2323),
        "errorLight": UIColor.fw.color(hex: 0x2d1414),
        "info": UIColor.fw.color(hex: 0xa0a7b8),
        "infoDark": UIColor.fw.color(hex: 0x7c8394),
        "infoDisabled": UIColor.fw.color(hex: 0x3b3f4c),
        "infoLight": UIColor.fw.color(hex: 0x1d2029)
    ]
    
    fileprivate nonisolated(unsafe) static var innerLightStructuralPalette = [
        "whiteColor": UIColor.fw.color(hex: 0xffffff),
        "blackColor": UIColor.fw.color(hex: 0x000000),
        "mainColor": UIColor.fw.color(hex: 0x303133),
        "contentColor": UIColor.fw.color(hex: 0x606266),
        "tipsColor": UIColor.fw.color(hex: 0x909399),
        "lightColor": UIColor.fw.color(hex: 0xc0c4cc),
        "borderColor": UIColor.fw.color(hex: 0xdcdfe6),
        "dividerColor": UIColor.fw.color(hex: 0xe4e7ed),
        "maskColor": UIColor.fw.color(hex: 0x000000, alpha: 0.4),
        "shadowColor": UIColor.fw.color(hex: 0x000000, alpha: 0.1),
        "bgColor": UIColor.fw.color(hex: 0xf3f4f6),
        "bgWhite": UIColor.fw.color(hex: 0xffffff),
        "bgGrayLight": UIColor.fw.color(hex: 0xf5f7fa),
        "bgGrayDark": UIColor.fw.color(hex: 0x2f343c),
        "bgBlack": UIColor.fw.color(hex: 0x000000)
    ]
    
    fileprivate nonisolated(unsafe) static var innerDarkStructuralPalette = [
        "whiteColor": UIColor.fw.color(hex: 0xf5f6f7),
        "blackColor": UIColor.fw.color(hex: 0xf5f6f7),
        "mainColor": UIColor.fw.color(hex: 0xf5f6f7),
        "contentColor": UIColor.fw.color(hex: 0xcfd3dc),
        "tipsColor": UIColor.fw.color(hex: 0x9aa1af),
        "lightColor": UIColor.fw.color(hex: 0x6b7082),
        "borderColor": UIColor.fw.color(hex: 0x3a4251),
        "dividerColor": UIColor.fw.color(hex: 0x3a4251),
        "maskColor": UIColor.fw.color(hex: 0x000000, alpha: 0.6),
        "shadowColor": UIColor.fw.color(hex: 0x000000, alpha: 0.3),
        "bgColor": UIColor.fw.color(hex: 0x111827),
        "bgWhite": UIColor.fw.color(hex: 0x000000),
        "bgGrayLight": UIColor.fw.color(hex: 0x1a1a1a),
        "bgGrayDark": UIColor.fw.color(hex: 0xf5f7fa),
        "bgBlack": UIColor.fw.color(hex: 0xffffff)
    ]
}
