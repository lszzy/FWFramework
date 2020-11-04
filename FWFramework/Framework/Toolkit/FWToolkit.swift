//
//  FWToolkit.swift
//  FWFramework
//
//  Created by wuyong on 2020/10/22.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import UIKit
import SwiftUI

// MARK: - UIColor+FWToolkit

/// 从16进制创建UIColor
///
/// - Parameters:
///   - hex: 十六进制值，格式0xFFFFFF
///   - alpha: 透明度可选，默认1.0
/// - Returns: UIColor
public func FWColorHex(_ hex: Int, _ alpha: CGFloat = 1.0) -> UIColor {
    return UIColor(red: CGFloat((hex & 0xFF0000) >> 16) / 255.0, green: CGFloat((hex & 0xFF00) >> 8) / 255.0, blue: CGFloat(hex & 0xFF) / 255.0, alpha: alpha)
}

/// 从RGB创建UIColor
///
/// - Parameters:
///   - red: 红色值
///   - green: 绿色值
///   - blue: 蓝色值
///   - alpha: 透明度可选，默认1.0
/// - Returns: UIColor
public func FWColorRgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1.0) -> UIColor {
    return UIColor(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: alpha)
}

// MARK: - UIFont+FWToolkit

/// 快速创建系统字体
///
/// - Parameters:
///   - size: 字体字号
///   - weight: 字重可选，默认Regular
/// - Returns: UIFont
public func FWFontSize(_ size: CGFloat, _ weight: UIFont.Weight = .regular) -> UIFont {
    return UIFont.fwFont(ofSize: size, weight: weight)
}

// MARK: - Color+FWToolkit

@available(iOS 13.0, *)
public extension Color {
    
    /// 从16进制创建Color
    /// - Parameters:
    ///   - hex: 十六进制值，格式0xFFFFFF
    ///   - opacity: 透明度可选，默认1
    /// - Returns: Color
    static func fwColor(_ hex: Int, _ opacity: Double = 1) -> Color {
        return Color(red: Double((hex & 0xFF0000) >> 16) / 255.0, green: Double((hex & 0xFF00) >> 8) / 255.0, blue: Double(hex & 0xFF) / 255.0, opacity: opacity)
    }
    
    /// 从RGB创建Color
    /// - Parameters:
    ///   - red: 红色值
    ///   - green: 绿色值
    ///   - blue: 蓝色值
    ///   - opacity: 透明度可选，默认1
    /// - Returns: Color
    static func fwColor(_ red: Double, _ green: Double, _ blue: Double, _ opacity: Double = 1) -> Color {
        return Color(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, opacity: opacity)
    }
    
    /// 从十六进制字符串初始化，支持RGB、RGBA|ARGB，格式："20B2AA", "#FFFFFF"，失败时返回clear
    /// - Parameters:
    ///   - hexString: 十六进制字符串
    ///   - opacity: 透明度可选，默认1
    /// - Returns: Color
    static func fwColor(_ hexString: String, _ opacity: Double = 1) -> Color {
        return Color(UIColor.fwColor(withHexString: hexString, alpha: CGFloat(opacity)))
    }
}

// MARK: - Font+FWToolkit

@available(iOS 13.0, *)
public extension Font {
    
    /// 快速创建系统字体
    /// - Parameters:
    ///   - size: 字体字号
    ///   - weight: 字重可选，默认regular
    /// - Returns: Font
    static func fwFont(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        return .system(size: size, weight: weight)
    }
}

// MARK: - Image+FWToolkit

@available(iOS 13.0, *)
public extension Image {
    
    /// 使用文件名方式加载Image，不支持动图。会被系统缓存，适用于大量复用的小资源图
    /// - Parameters:
    ///   - name: 文件名
    /// - Returns: Image
    static func fwImage(_ name: String) -> Image {
        return Image(uiImage: UIImage.fwImage(withName: name) ?? UIImage())
    }
    
    /// 从图片文件加载Image，支持动图，支持绝对路径和bundle路径，文件不存在时会尝试name方式。不会被系统缓存，适用于不被复用的图片，特别是大图
    /// - Parameters:
    ///   - file: 文件名
    /// - Returns: Image
    static func fwImage(file: String) -> Image {
        return Image(uiImage: UIImage.fwImage(withFile: file) ?? UIImage())
    }
    
    /// 从图片数据解码创建UIImage，scale默认为1，支持动图
    /// - Parameters:
    ///   - name: 文件名
    ///   - scale: 图片scale
    /// - Returns: Image
    static func fwImage(data: Data?, scale: CGFloat = 1) -> Image {
        return Image(uiImage: UIImage.fwImage(with: data, scale: scale) ?? UIImage())
    }
}
