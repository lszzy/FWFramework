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
    
    /// 默认浅色调色板
    public static var lightPalette: [String: UIColor] { UIColor.innerLightPalette }
    /// 默认深色调色板
    public static var darkPalette: [String: UIColor] { UIColor.innerDarkPalette }
    /// 霞光紫调色板
    public static var purplePalette: [String: UIColor] { UIColor.innerPurplePalette }
    /// 清翠绿调色板
    public static var greenPalette: [String: UIColor] { UIColor.innerGreenPalette }
    /// 暖阳橙调色板
    public static var orangePalette: [String: UIColor] { UIColor.innerOrangePalette }
    /// 午夜蓝调色板
    public static var bluePalette: [String: UIColor] { UIColor.innerBluePalette }
    
    /// 浅色主题配置
    public static var lightTheme: [String: UIColor] {
        get { UIColor.innerLightTheme }
        set { UIColor.innerLightTheme = newValue }
    }
    
    /// 深色主题配置
    public static var darkTheme: [String: UIColor] {
        get { UIColor.innerDarkTheme }
        set { UIColor.innerDarkTheme = newValue }
    }
    
    /// 自定义调色板变形比率，默认0.6
    public static var paletteRatio: CGFloat {
        get { UIColor.innerPaletteRatio }
        set { UIColor.innerPaletteRatio = newValue }
    }
    
    /// 自定义调色板排除的变体色
    public static var paletteExcludes: [String] {
        get { UIColor.innerPaletteExcludes }
        set { UIColor.innerPaletteExcludes = newValue }
    }
    
    /// 从浅色主题自动生成深色变体主题
    public static func paletteTheme(
        lightTheme: [String: UIColor],
        darkTheme: [String: UIColor]? = nil
    ) -> [String: UIColor] {
        var paletteTheme = darkPalette.merging(darkTheme ?? [:], uniquingKeysWith: { $1 })
        let lightColors = lightTheme.filter { !paletteExcludes.contains($0.key) }
        for (name, light) in lightColors {
            if let dark = paletteTheme[name] {
                paletteTheme[name] = paletteColor(light: light, dark: dark)
            }
        }
        return paletteTheme
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
        return lightTheme[name] ?? .clear
    }
    
    /// 从调色板生成深色
    public static func paletteDarkColor(_ name: String) -> UIColor {
        let dark = darkTheme[name]
        if let dark, !paletteExcludes.contains(name) {
            return paletteColor(light: paletteLightColor(name), dark: dark)
        }
        return dark ?? paletteLightColor(name)
    }
    
    /// 从指定浅色和深色自动生成变体色，不含透明度，可自定义比率
    public static func paletteColor(light: UIColor, dark: UIColor, ratio: CGFloat? = nil) -> UIColor {
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
    fileprivate nonisolated(unsafe) static var innerLightTheme = innerLightPalette
    fileprivate nonisolated(unsafe) static var innerDarkTheme = innerDarkPalette
    
    fileprivate nonisolated(unsafe) static var innerPaletteRatio: CGFloat = 0.6
    fileprivate nonisolated(unsafe) static var innerPaletteExcludes: [String] = [
        "whiteColor", "blackColor", "mainColor", "contentColor", "tipsColor",
        "lightColor", "borderColor", "dividerColor", "maskColor", "shadowColor",
        "bgColor", "bgWhite", "bgGrayLight", "bgGrayDark", "bgBlack"
    ]
    
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
        "infoLight": UIColor.fw.color(hex: 0xf4f4f5),
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
        "infoLight": UIColor.fw.color(hex: 0x1d2029),
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
    
    fileprivate nonisolated(unsafe) static var innerPurplePalette = innerLightPalette.merging([
        "primary": UIColor.fw.color(hex: 0x7c3aed),
        "error": UIColor.fw.color(hex: 0xf43f5e),
        "warning": UIColor.fw.color(hex: 0xf59e0b),
        "success": UIColor.fw.color(hex: 0x10b981),
        "info": UIColor.fw.color(hex: 0x6b7280),
        "primaryLight": UIColor.fw.color(hex: 0xf3e8ff),
        "errorLight": UIColor.fw.color(hex: 0xffe4e6),
        "warningLight": UIColor.fw.color(hex: 0xfef3c7),
        "successLight": UIColor.fw.color(hex: 0xd1fae5),
        "infoLight": UIColor.fw.color(hex: 0xf3f4f6),
        "primaryDark": UIColor.fw.color(hex: 0x6d28d9),
        "errorDark": UIColor.fw.color(hex: 0xe11d48),
        "warningDark": UIColor.fw.color(hex: 0xd97706),
        "successDark": UIColor.fw.color(hex: 0x059669),
        "infoDark": UIColor.fw.color(hex: 0x4b5563),
        "primaryDisabled": UIColor.fw.color(hex: 0xc4b5fd),
        "errorDisabled": UIColor.fw.color(hex: 0xfbcfe8),
        "warningDisabled": UIColor.fw.color(hex: 0xfde68a),
        "successDisabled": UIColor.fw.color(hex: 0xa7f3d0),
        "infoDisabled": UIColor.fw.color(hex: 0xd1d5db)
    ], uniquingKeysWith: { $1 })
    
    fileprivate nonisolated(unsafe) static var innerGreenPalette = innerLightPalette.merging([
        "primary": UIColor.fw.color(hex: 0x059669),
        "error": UIColor.fw.color(hex: 0xdc2626),
        "warning": UIColor.fw.color(hex: 0xeab308),
        "success": UIColor.fw.color(hex: 0x16a34a),
        "info": UIColor.fw.color(hex: 0x78716c),
        "primaryLight": UIColor.fw.color(hex: 0xecfdf5),
        "errorLight": UIColor.fw.color(hex: 0xfee2e2),
        "warningLight": UIColor.fw.color(hex: 0xfefce8),
        "successLight": UIColor.fw.color(hex: 0xdcfce7),
        "infoLight": UIColor.fw.color(hex: 0xfafaf9),
        "primaryDark": UIColor.fw.color(hex: 0x047857),
        "errorDark": UIColor.fw.color(hex: 0xb91c1c),
        "warningDark": UIColor.fw.color(hex: 0xca8a04),
        "successDark": UIColor.fw.color(hex: 0x15803d),
        "infoDark": UIColor.fw.color(hex: 0x57534e),
        "primaryDisabled": UIColor.fw.color(hex: 0x6ee7b7),
        "errorDisabled": UIColor.fw.color(hex: 0xfca5a5),
        "warningDisabled": UIColor.fw.color(hex: 0xfacc15),
        "successDisabled": UIColor.fw.color(hex: 0x86efac),
        "infoDisabled": UIColor.fw.color(hex: 0xe7e5e4)
    ], uniquingKeysWith: { $1 })
    
    fileprivate nonisolated(unsafe) static var innerOrangePalette = innerLightPalette.merging([
        "primary": UIColor.fw.color(hex: 0xf97316),
        "error": UIColor.fw.color(hex: 0xef4444),
        "warning": UIColor.fw.color(hex: 0xfbbf24),
        "success": UIColor.fw.color(hex: 0x22c55e),
        "info": UIColor.fw.color(hex: 0x6366f1),
        "primaryLight": UIColor.fw.color(hex: 0xffedd5),
        "errorLight": UIColor.fw.color(hex: 0xfee2e2),
        "warningLight": UIColor.fw.color(hex: 0xfef3c7),
        "successLight": UIColor.fw.color(hex: 0xdcfce7),
        "infoLight": UIColor.fw.color(hex: 0xe0e7ff),
        "primaryDark": UIColor.fw.color(hex: 0xea580c),
        "errorDark": UIColor.fw.color(hex: 0xdc2626),
        "warningDark": UIColor.fw.color(hex: 0xf59e0b),
        "successDark": UIColor.fw.color(hex: 0x16a34a),
        "infoDark": UIColor.fw.color(hex: 0x4f46e5),
        "primaryDisabled": UIColor.fw.color(hex: 0xfed7aa),
        "errorDisabled": UIColor.fw.color(hex: 0xfecaca),
        "warningDisabled": UIColor.fw.color(hex: 0xfde68a),
        "successDisabled": UIColor.fw.color(hex: 0x86efac),
        "infoDisabled": UIColor.fw.color(hex: 0xc7d2fe)
    ], uniquingKeysWith: { $1 })
    
    fileprivate nonisolated(unsafe) static var innerBluePalette = innerLightPalette.merging([
        "primary": UIColor.fw.color(hex: 0x0b3d91),
        "error": UIColor.fw.color(hex: 0xef5350),
        "warning": UIColor.fw.color(hex: 0xffa726),
        "success": UIColor.fw.color(hex: 0x66bb6a),
        "info": UIColor.fw.color(hex: 0x2196f3),
        "primaryLight": UIColor.fw.color(hex: 0x081a33),
        "errorLight": UIColor.fw.color(hex: 0x5e1914),
        "warningLight": UIColor.fw.color(hex: 0x663c00),
        "successLight": UIColor.fw.color(hex: 0x1b3a1b),
        "infoLight": UIColor.fw.color(hex: 0x003d66),
        "primaryDark": UIColor.fw.color(hex: 0x062a57),
        "errorDark": UIColor.fw.color(hex: 0xc62828),
        "warningDark": UIColor.fw.color(hex: 0xe65100),
        "successDark": UIColor.fw.color(hex: 0x2e7d32),
        "infoDark": UIColor.fw.color(hex: 0x01579b),
        "primaryDisabled": UIColor.fw.color(hex: 0x274a7a),
        "errorDisabled": UIColor.fw.color(hex: 0xef9a9a),
        "warningDisabled": UIColor.fw.color(hex: 0xffb74d),
        "successDisabled": UIColor.fw.color(hex: 0x81c784),
        "infoDisabled": UIColor.fw.color(hex: 0x4fc3f7)
    ], uniquingKeysWith: { $1 })
}
