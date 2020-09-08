//
//  FWToolkitManager.swift
//  FWFramework
//
//  Created by wuyong on 2020/9/8.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import UIKit

// MARK: - UIApplication+FWToolkit

/// 是否是调试模式
public let FWIsDebug: Bool = UIApplication.fwIsDebug()

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
    return UIFont.systemFont(ofSize: size, weight: weight)
}
