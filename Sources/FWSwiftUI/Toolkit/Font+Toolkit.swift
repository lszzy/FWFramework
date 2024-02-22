//
//  Font+Toolkit.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#if canImport(SwiftUI)
import SwiftUI
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

extension Font {
    
    /// 全局自定义字体句柄，优先调用
    public static var fontBlock: ((CGFloat, Font.Weight) -> Font?)?
    
    /// 返回系统Thin字体，自动等比例缩放
    public static func thinFont(size: CGFloat, autoScale: Bool? = nil) -> Font {
        return font(size: size, weight: .thin, autoScale: autoScale)
    }
    
    /// 返回系统Light字体，自动等比例缩放
    public static func lightFont(size: CGFloat, autoScale: Bool? = nil) -> Font {
        return font(size: size, weight: .light, autoScale: autoScale)
    }
    
    /// 返回系统Medium字体，自动等比例缩放
    public static func mediumFont(size: CGFloat, autoScale: Bool? = nil) -> Font {
        return font(size: size, weight: .medium, autoScale: autoScale)
    }
    
    /// 返回系统Semibold字体，自动等比例缩放
    public static func semiboldFont(size: CGFloat, autoScale: Bool? = nil) -> Font {
        return font(size: size, weight: .semibold, autoScale: autoScale)
    }
    
    /// 返回系统Bold字体，自动等比例缩放
    public static func boldFont(size: CGFloat, autoScale: Bool? = nil) -> Font {
        return font(size: size, weight: .bold, autoScale: autoScale)
    }

    /// 创建指定尺寸和weight的系统字体，自动等比例缩放
    public static func font(size: CGFloat, weight: Font.Weight = .regular, autoScale: Bool? = nil) -> Font {
        var fontSize = size
        if (autoScale == nil && UIFont.fw_autoScaleFont) || autoScale == true {
            fontSize = UIFont.fw_autoScaleBlock?(size) ?? UIScreen.fw_relativeValue(size, flat: UIFont.fw_autoFlatFont)
        }
        
        if let font = fontBlock?(fontSize, weight) { return font }
        return .system(size: fontSize, weight: weight)
    }
    
    /// 获取指定名称、字重、斜体字体的完整规范名称
    public static func fontName(_ name: String, weight: Font.Weight, italic: Bool = false) -> String {
        var fontName = name
        if let weightSuffix = weightSuffixes[weight] {
            fontName += weightSuffix + (italic ? "Italic" : "")
        }
        return fontName
    }
    
    private static let weightSuffixes: [Font.Weight: String] = [
        .ultraLight: "-Ultralight",
        .thin: "-Thin",
        .light: "-Light",
        .regular: "-Regular",
        .medium: "-Medium",
        .semibold: "-Semibold",
        .bold: "-Bold",
        .heavy: "-Heavy",
        .black: "-Black",
    ]
    
}

#endif
