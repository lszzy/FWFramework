//
//  Color+Hex.swift
//  AppClip
//
//  Created by wuyong on 2020/11/4.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
public extension Color {
    
    /// 从16进制创建Color
    /// - Parameters:
    ///   - hex: 十六进制值，格式0xFFFFFF
    ///   - opacity: 透明度可选，默认1
    /// - Returns: Color
    static func hex(_ hex: Int, _ opacity: Double = 1) -> Color {
        return Color(red: Double((hex & 0xFF0000) >> 16) / 255.0, green: Double((hex & 0xFF00) >> 8) / 255.0, blue: Double(hex & 0xFF) / 255.0, opacity: opacity)
    }
    
    /// 从RGB创建Color
    /// - Parameters:
    ///   - red: 红色值
    ///   - green: 绿色值
    ///   - blue: 蓝色值
    ///   - opacity: 透明度可选，默认1
    /// - Returns: Color
    static func rgb(_ red: Double, _ green: Double, _ blue: Double, _ opacity: Double = 1) -> Color {
        return Color(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, opacity: opacity)
    }
}
