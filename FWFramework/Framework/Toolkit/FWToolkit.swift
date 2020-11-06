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

// MARK: - Font+FWToolkit

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

// MARK: - Image+FWToolkit

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

// MARK: - FWViewWrapper

/// SwiftUI通用UIView包装器
@available(iOS 13.0, *)
public struct FWViewWrapper<Wrapper: UIView>: UIViewRepresentable {
    public typealias UIViewType = Wrapper
    
    var maker: () -> Wrapper
    var updater: (Wrapper) -> Void
    
    public init(_ maker: @escaping @autoclosure () -> Wrapper, updater: @escaping (Wrapper) -> Void) {
        self.maker = maker
        self.updater = updater
    }
    
    public func makeUIView(context: Context) -> Wrapper {
        return maker()
    }
    
    public func updateUIView(_ uiView: Wrapper, context: Context) {
        updater(uiView)
    }
}

// MARK: - FWViewControllerWrapper

/// SwiftUI通用UIViewController包装器
@available(iOS 13.0, *)
public struct FWViewControllerWrapper<Wrapper: UIViewController>: UIViewControllerRepresentable {
    public typealias UIViewControllerType = Wrapper
    
    var maker: () -> Wrapper
    var updater: (Wrapper) -> Void
    
    public init(_ maker: @escaping @autoclosure () -> Wrapper, updater: @escaping (Wrapper) -> Void) {
        self.maker = maker
        self.updater = updater
    }
    
    public func makeUIViewController(context: Context) -> Wrapper {
        return maker()
    }
    
    public func updateUIViewController(_ uiViewController: Wrapper, context: Context) {
        updater(uiViewController)
    }
}
