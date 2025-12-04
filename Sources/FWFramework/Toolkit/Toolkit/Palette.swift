//
//  Palette.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

// MARK: - Palette+UIColor
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
    /// 纯黑背景
    public static var bgBlack: UIColor { paletteThemeColor("bgBlack") }
    /// 浅灰背景
    public static var bgGrayLight: UIColor { paletteThemeColor("bgGrayLight") }
    /// 深灰背景
    public static var bgGrayDark: UIColor { paletteThemeColor("bgGrayDark") }
    
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
        return PaletteManager.shared.lightTheme[name] ?? .clear
    }
    
    /// 从调色板生成深色
    public static func paletteDarkColor(_ name: String) -> UIColor {
        return PaletteManager.shared.darkTheme[name] ?? paletteLightColor(name)
    }
}

// MARK: - PaletteManager
/// 调色板管理器，支持从浅色自动生成深色变体
public class PaletteManager: @unchecked Sendable {
    /// 单例模式
    public static let shared = PaletteManager()
    
    /// 当前调色板样式
    public var paletteStyle: PaletteStyle {
        get {
            return _paletteStyle
        }
        set {
            guard newValue != _paletteStyle else { return }
            _paletteStyle = newValue

            UserDefaults.standard.set(NSNumber(value: newValue.rawValue), forKey: "FWPaletteStyle")
            UserDefaults.standard.synchronize()
            
            self.lightTheme = PaletteTheme.lightTheme(style: newValue)
            self.darkTheme = PaletteTheme.darkTheme(style: newValue)

            let themeStyle = ThemeManager.shared.style
            NotificationCenter.default.post(name: .ThemeChanged, object: self, userInfo: [NSKeyValueChangeKey.oldKey: themeStyle.rawValue, NSKeyValueChangeKey.newKey: themeStyle.rawValue])
            ThemeManager.shared.updateTheme()
        }
    }
    
    private var _paletteStyle: PaletteStyle = .default
    
    /// 当前浅色主题配置
    public var lightTheme: [String: UIColor] = [:]
    
    /// 当前深色主题配置
    public var darkTheme: [String: UIColor] = [:]
    
    /// 初始化方法
    public init() {
        self.paletteStyle = .init(UserDefaults.standard.integer(forKey: "FWPaletteStyle"))
        self.lightTheme = PaletteTheme.lightTheme(style: paletteStyle)
        self.darkTheme = PaletteTheme.darkTheme(style: paletteStyle)
    }
}

// MARK: - PaletteStyle
/// 可扩展调色板样式
public struct PaletteStyle: RawRepresentable, Equatable, Hashable, Sendable {
    public typealias RawValue = Int

    /// 默认调色板样式
    public static let `default`: PaletteStyle = .init(0)
    /// 霞光紫调色板样式
    public static let purple: PaletteStyle = .init(1)
    /// 清翠绿调色板样式
    public static let green: PaletteStyle = .init(2)
    /// 暖阳橙调色板样式
    public static let orange: PaletteStyle = .init(3)
    /// 午夜蓝调色板样式
    public static let blue: PaletteStyle = .init(4)

    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int) {
        self.rawValue = rawValue
    }
}

// MARK: - PaletteTheme
/// 调色板主题配置
public class PaletteTheme: @unchecked Sendable {
    /// 默认浅色调色板主题
    public nonisolated(unsafe) static var lightTheme: [String: UIColor] = [
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
        "bgBlack": UIColor.fw.color(hex: 0x000000),
        "bgGrayLight": UIColor.fw.color(hex: 0xf5f7fa),
        "bgGrayDark": UIColor.fw.color(hex: 0x2f343c),
    ]
    
    /// 默认深色调色板主题
    public nonisolated(unsafe) static var darkTheme: [String: UIColor] = [
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
        "bgBlack": UIColor.fw.color(hex: 0xffffff),
        "bgGrayLight": UIColor.fw.color(hex: 0x1a1a1a),
        "bgGrayDark": UIColor.fw.color(hex: 0xf5f7fa),
    ]
    
    /// 霞光紫调色板主题
    public nonisolated(unsafe) static var purpleTheme: [String: UIColor] = lightTheme.merging([
        "primary": UIColor.fw.color(hex: 0x7c3aed),
        "primaryDark": UIColor.fw.color(hex: 0x6d28d9),
        "primaryDisabled": UIColor.fw.color(hex: 0xc4b5fd),
        "primaryLight": UIColor.fw.color(hex: 0xf3e8ff),
        "error": UIColor.fw.color(hex: 0xf43f5e),
        "errorDark": UIColor.fw.color(hex: 0xe11d48),
        "errorDisabled": UIColor.fw.color(hex: 0xfbcfe8),
        "errorLight": UIColor.fw.color(hex: 0xffe4e6),
        "warning": UIColor.fw.color(hex: 0xf59e0b),
        "warningDark": UIColor.fw.color(hex: 0xd97706),
        "warningDisabled": UIColor.fw.color(hex: 0xfde68a),
        "warningLight": UIColor.fw.color(hex: 0xfef3c7),
        "success": UIColor.fw.color(hex: 0x10b981),
        "successDark": UIColor.fw.color(hex: 0x059669),
        "successDisabled": UIColor.fw.color(hex: 0xa7f3d0),
        "successLight": UIColor.fw.color(hex: 0xd1fae5),
        "info": UIColor.fw.color(hex: 0x6b7280),
        "infoDark": UIColor.fw.color(hex: 0x4b5563),
        "infoDisabled": UIColor.fw.color(hex: 0xd1d5db),
        "infoLight": UIColor.fw.color(hex: 0xf3f4f6),
    ], uniquingKeysWith: { $1 })
    
    /// 清翠绿调色板主题
    public nonisolated(unsafe) static var greenTheme: [String: UIColor] = lightTheme.merging([
        "primary": UIColor.fw.color(hex: 0x059669),
        "primaryDark": UIColor.fw.color(hex: 0x047857),
        "primaryDisabled": UIColor.fw.color(hex: 0x6ee7b7),
        "primaryLight": UIColor.fw.color(hex: 0xecfdf5),
        "error": UIColor.fw.color(hex: 0xdc2626),
        "errorDark": UIColor.fw.color(hex: 0xb91c1c),
        "errorDisabled": UIColor.fw.color(hex: 0xfca5a5),
        "errorLight": UIColor.fw.color(hex: 0xfee2e2),
        "warning": UIColor.fw.color(hex: 0xeab308),
        "warningDark": UIColor.fw.color(hex: 0xca8a04),
        "warningDisabled": UIColor.fw.color(hex: 0xfacc15),
        "warningLight": UIColor.fw.color(hex: 0xfefce8),
        "success": UIColor.fw.color(hex: 0x16a34a),
        "successDark": UIColor.fw.color(hex: 0x15803d),
        "successDisabled": UIColor.fw.color(hex: 0x86efac),
        "successLight": UIColor.fw.color(hex: 0xdcfce7),
        "info": UIColor.fw.color(hex: 0x78716c),
        "infoDark": UIColor.fw.color(hex: 0x57534e),
        "infoDisabled": UIColor.fw.color(hex: 0xe7e5e4),
        "infoLight": UIColor.fw.color(hex: 0xfafaf9),
    ], uniquingKeysWith: { $1 })
    
    /// 暖阳橙调色板主题
    public nonisolated(unsafe) static var orangeTheme: [String: UIColor] = lightTheme.merging([
        "primary": UIColor.fw.color(hex: 0xf97316),
        "primaryDark": UIColor.fw.color(hex: 0xea580c),
        "primaryDisabled": UIColor.fw.color(hex: 0xfed7aa),
        "primaryLight": UIColor.fw.color(hex: 0xffedd5),
        "error": UIColor.fw.color(hex: 0xef4444),
        "errorDark": UIColor.fw.color(hex: 0xdc2626),
        "errorDisabled": UIColor.fw.color(hex: 0xfecaca),
        "errorLight": UIColor.fw.color(hex: 0xfee2e2),
        "warning": UIColor.fw.color(hex: 0xfbbf24),
        "warningDark": UIColor.fw.color(hex: 0xf59e0b),
        "warningDisabled": UIColor.fw.color(hex: 0xfde68a),
        "warningLight": UIColor.fw.color(hex: 0xfef3c7),
        "success": UIColor.fw.color(hex: 0x22c55e),
        "successDark": UIColor.fw.color(hex: 0x16a34a),
        "successDisabled": UIColor.fw.color(hex: 0x86efac),
        "successLight": UIColor.fw.color(hex: 0xdcfce7),
        "info": UIColor.fw.color(hex: 0x6366f1),
        "infoDark": UIColor.fw.color(hex: 0x4f46e5),
        "infoDisabled": UIColor.fw.color(hex: 0xc7d2fe),
        "infoLight": UIColor.fw.color(hex: 0xe0e7ff),
    ], uniquingKeysWith: { $1 })
    
    /// 午夜蓝调色板主题
    public nonisolated(unsafe) static var blueTheme: [String: UIColor] = lightTheme.merging([
        "primary": UIColor.fw.color(hex: 0x0b3d91),
        "primaryDark": UIColor.fw.color(hex: 0x062a57),
        "primaryDisabled": UIColor.fw.color(hex: 0x274a7a),
        "primaryLight": UIColor.fw.color(hex: 0x081a33),
        "error": UIColor.fw.color(hex: 0xef5350),
        "errorDark": UIColor.fw.color(hex: 0xc62828),
        "errorDisabled": UIColor.fw.color(hex: 0xef9a9a),
        "errorLight": UIColor.fw.color(hex: 0x5e1914),
        "warning": UIColor.fw.color(hex: 0xffa726),
        "warningDark": UIColor.fw.color(hex: 0xe65100),
        "warningDisabled": UIColor.fw.color(hex: 0xffb74d),
        "warningLight": UIColor.fw.color(hex: 0x663c00),
        "success": UIColor.fw.color(hex: 0x66bb6a),
        "successDark": UIColor.fw.color(hex: 0x2e7d32),
        "successDisabled": UIColor.fw.color(hex: 0x81c784),
        "successLight": UIColor.fw.color(hex: 0x1b3a1b),
        "info": UIColor.fw.color(hex: 0x2196f3),
        "infoDark": UIColor.fw.color(hex: 0x01579b),
        "infoDisabled": UIColor.fw.color(hex: 0x4fc3f7),
        "infoLight": UIColor.fw.color(hex: 0x003d66),
    ], uniquingKeysWith: { $1 })
    
    /// 自定义调色板变色排除的名称列表
    public nonisolated(unsafe) static var variantExcludes: [String] = [
        "whiteColor", "blackColor", "mainColor", "contentColor", "tipsColor",
        "lightColor", "borderColor", "dividerColor", "maskColor", "shadowColor",
        "bgColor", "bgWhite", "bgBlack", "bgGrayLight", "bgGrayDark"
    ]
    
    /// 自定义调色板变色比率，默认0.6
    public nonisolated(unsafe) static var variantRatio: CGFloat = 0.6
    
    /// 自定义浅色主题句柄，默认nil
    public nonisolated(unsafe) static var customLightTheme: ((PaletteStyle) -> [String: UIColor]?)?
    
    /// 自定义深色主题句柄，默认nil
    public nonisolated(unsafe) static var customDarkTheme: ((PaletteStyle) -> [String: UIColor]?)?
    
    /// 从浅色模板自动生成深色主题变体
    public static func variantTheme(
        light: [String: UIColor],
        dark: [String: UIColor]? = nil
    ) -> [String: UIColor] {
        var paletteTheme = darkTheme.merging(dark ?? [:], uniquingKeysWith: { $1 })
        let lightTheme = light.filter { !variantExcludes.contains($0.key) }
        for (name, light) in lightTheme {
            if let dark = paletteTheme[name] {
                paletteTheme[name] = variantColor(light: light, dark: dark)
            }
        }
        return paletteTheme
    }
    
    /// 从指定浅色和深色自动生成变体色，不含透明度
    public static func variantColor(light: UIColor, dark: UIColor) -> UIColor {
        return UIColor.fw.variantColor(light: light, dark: dark, ratio: variantRatio)
    }
    
    /// 获取指定样式对应浅色主题
    public static func lightTheme(style: PaletteStyle) -> [String: UIColor] {
        if let theme = customLightTheme?(style) { return theme }
        
        switch style {
        case .purple:
            return purpleTheme
        case .green:
            return greenTheme
        case .orange:
            return orangeTheme
        case .blue:
            return blueTheme
        default:
            return lightTheme
        }
    }
    
    /// 获取指定样式对应深色主题
    public static func darkTheme(style: PaletteStyle) -> [String: UIColor] {
        if let theme = customDarkTheme?(style) { return theme }
        
        switch style {
        case .default:
            return darkTheme
        default:
            return variantTheme(light: lightTheme(style: style))
        }
    }
}
