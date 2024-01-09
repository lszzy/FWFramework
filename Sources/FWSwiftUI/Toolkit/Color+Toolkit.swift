//
//  Color+Toolkit.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#if canImport(SwiftUI)
import SwiftUI
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

extension Color {
    
    /// 从16进制创建Color
    /// - Parameters:
    ///   - hex: 十六进制值，格式0xFFFFFF
    ///   - alpha: 透明度可选，默认1
    /// - Returns: Color
    public static func color(_ hex: Int, _ alpha: Double = 1) -> Color {
        return Color(red: Double((hex & 0xFF0000) >> 16) / 255.0, green: Double((hex & 0xFF00) >> 8) / 255.0, blue: Double(hex & 0xFF) / 255.0, opacity: alpha)
    }
    
    /// 从RGB创建Color
    /// - Parameters:
    ///   - red: 红色值
    ///   - green: 绿色值
    ///   - blue: 蓝色值
    ///   - alpha: 透明度可选，默认1
    /// - Returns: Color
    public static func color(_ red: Double, _ green: Double, _ blue: Double, _ alpha: Double = 1) -> Color {
        return Color(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, opacity: alpha)
    }
    
    /// 从十六进制字符串初始化，支持RGB、RGBA|ARGB，格式："20B2AA", "#FFFFFF"，失败时返回clear
    /// - Parameters:
    ///   - hexString: 十六进制字符串
    ///   - alpha: 透明度可选，默认1
    /// - Returns: Color
    public static func color(_ hexString: String, _ alpha: Double = 1) -> Color {
        return Color(UIColor.fw_color(hexString: hexString, alpha: alpha))
    }
    
    /// 几乎透明的颜色，常用于clear不起作用的场景
    public static var almostClear: Color {
        return Color.black.opacity(0.0001)
    }
    
    /// 获取透明度为1.0的RGB随机颜色
    public static var randomColor: Color {
        let red = arc4random() % 255
        let green = arc4random() % 255
        let blue = arc4random() % 255
        return Color(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, opacity: 1.0)
    }
    
    // MARK: - UIColor
    /// Color转换为UIColor，失败时返回clear
    /// - Returns: UIColor
    public func toUIColor() -> UIColor {
        if let cachedResult = Self.colorCaches[self] {
            return cachedResult
        } else {
            var result: UIColor
            if #available(iOS 14.0, *) {
                result = UIColor(self)
            } else {
                result = toUIColor1() ?? toUIColor2() ?? .clear
            }
            Self.colorCaches[self] = result
            return result
        }
    }
    
    private static var colorCaches: [Color: UIColor] = [:]
    
    private func toUIColor1() -> UIColor? {
        switch self {
            case .clear:
                return UIColor.clear
            case .black:
                return UIColor.black
            case .white:
                return UIColor.white
            case .gray:
                return UIColor.systemGray
            case .red:
                return UIColor.systemRed
            case .green:
                return UIColor.systemGreen
            case .blue:
                return UIColor.systemBlue
            case .orange:
                return UIColor.systemOrange
            case .yellow:
                return UIColor.systemYellow
            case .pink:
                return UIColor.systemPink
            case .purple:
                return UIColor.systemPurple
            case .primary:
                return UIColor.label
            case .secondary:
                return UIColor.secondaryLabel
            default:
                return nil
        }
    }
    
    private func toUIColor2() -> UIColor? {
        let children = Mirror(reflecting: self).children
        let _provider = children.filter { $0.label == "provider" }.first
        guard let provider = _provider?.value else {
            return nil
        }
        
        let providerChildren = Mirror(reflecting: provider).children
        let _base = providerChildren.filter { $0.label == "base" }.first
        guard let base = _base?.value else {
            return nil
        }
        if let uiColor = base as? UIColor {
            return uiColor
        }
        
        if String(describing: type(of: base)) == "NamedColor" {
            let baseMirror = Mirror(reflecting: base)
            if let name = baseMirror.descendant("name") as? String {
                let bundle = baseMirror.descendant("bundle") as? Bundle
                if let color = UIColor(named: name, in: bundle, compatibleWith: nil) {
                    return color
                }
            }
        }
        
        if String(describing: type(of: base)) == "OpacityColor" {
            let baseOpacity = Mirror(reflecting: base)
            if let opacity = baseOpacity.descendant("opacity") as? Double,
               let colorBase = baseOpacity.descendant("base") as? Color {
                return colorBase.toUIColor().withAlphaComponent(CGFloat(opacity))
            }
        }
        
        var baseValue: String = ""
        dump(base, to: &baseValue)
        guard let firstLine = baseValue.split(separator: "\n").first,
              let hexString = firstLine.split(separator: " ")[1] as Substring? else {
            return nil
        }
        
        return UIColor.fw_color(hexString: hexString.trimmingCharacters(in: .newlines))
    }
    
}

#endif
