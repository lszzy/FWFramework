//
//  FWToolkit+FWFramework.swift
//  FWFramework
//
//  Created by wuyong on 2020/11/9.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 13.0, *)
public extension Color {
    
    /// 从16进制创建Color
    /// - Parameters:
    ///   - hex: 十六进制值，格式0xFFFFFF
    ///   - opacity: 透明度可选，默认1
    /// - Returns: Color
    static func fwColorHex(_ hex: Int, _ opacity: Double = 1) -> Color {
        return Color(red: Double((hex & 0xFF0000) >> 16) / 255.0, green: Double((hex & 0xFF00) >> 8) / 255.0, blue: Double(hex & 0xFF) / 255.0, opacity: opacity)
    }
    
    /// 从RGB创建Color
    /// - Parameters:
    ///   - red: 红色值
    ///   - green: 绿色值
    ///   - blue: 蓝色值
    ///   - opacity: 透明度可选，默认1
    /// - Returns: Color
    static func fwColorRgb(_ red: Double, _ green: Double, _ blue: Double, _ opacity: Double = 1) -> Color {
        return Color(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, opacity: opacity)
    }
    
    /// 从十六进制字符串初始化，支持RGB、RGBA|ARGB，格式："20B2AA", "#FFFFFF"，失败时返回clear
    /// - Parameters:
    ///   - hexString: 十六进制字符串
    ///   - opacity: 透明度可选，默认1
    /// - Returns: Color
    static func fwColorHex(_ hexString: String, _ opacity: Double = 1) -> Color {
        return Color(UIColor.fwColor(withHexString: hexString, alpha: CGFloat(opacity)))
    }
    
    /// 从主Bundle指定名称初始化颜色
    /// - Parameter name: 颜色名称
    /// - Returns: Color
    static func fwColorNamed(_ name: String) -> Color {
        return Color(name)
    }
}

@available(iOS 13.0, *)
public extension Font {
    
    /// 快速创建系统字体
    /// - Parameters:
    ///   - size: 字体字号
    ///   - weight: 字重可选，默认regular
    /// - Returns: Font
    static func fwFontSize(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        return .system(size: size, weight: weight)
    }
}

@available(iOS 13.0, *)
public extension Image {
    
    /// 从主Bundle指定名称初始化图片
    /// - Parameters:
    ///   - name: 图片名称
    /// - Returns: Image
    static func fwImageNamed(_ name: String) -> Image {
        return Image(name)
    }
}

#endif
