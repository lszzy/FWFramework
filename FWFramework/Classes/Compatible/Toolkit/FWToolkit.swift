//
//  FWToolkit.swift
//  FWFramework
//
//  Created by wuyong on 2020/10/22.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import UIKit
#if FWMacroSPM
import FWFramework
#endif

// MARK: - FWWrapper+FWToolkit

extension Wrapper {
    /// 从16进制创建UIColor
    ///
    /// - Parameters:
    ///   - hex: 十六进制值，格式0xFFFFFF
    ///   - alpha: 透明度可选，默认1.0
    /// - Returns: UIColor
    public static func color(_ hex: Int, _ alpha: CGFloat = 1.0) -> UIColor {
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
    public static func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1.0) -> UIColor {
        return UIColor(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: alpha)
    }

    /// 快速创建系统字体
    ///
    /// - Parameters:
    ///   - size: 字体字号
    ///   - weight: 字重可选，默认Regular
    /// - Returns: UIFont
    public static func font(_ size: CGFloat, _ weight: UIFont.Weight = .regular) -> UIFont {
        return UIFont.fw.font(ofSize: size, weight: weight)
    }
    
    /// 快速创建图标对象
    ///
    /// - Parameters:
    ///   - named: 图标名称
    ///   - size: 图标大小
    /// - Returns: FWIcon对象
    public static func icon(_ named: String, _ size: CGFloat) -> FWIcon? {
        return FWIcon(named: named, size: size)
    }
    
    /// 快速创建图标图像
    /// 
    /// - Parameters:
    ///   - name: 图标名称
    ///   - size: 图片大小
    /// - Returns: UIImage对象
    public static func iconImage(_ name: String, _ size: CGFloat) -> UIImage? {
        return FWIcon.iconImage(name, size: size)
    }
}

// MARK: - UIDevice+FWToolkit

#if FWMacroTracking
import AdSupport

extension WrapperExtension where Base: UIDevice {
    /// 获取设备IDFA(外部使用)，重置广告或系统后会改变，需先检测广告追踪权限，启用Tracking子模块后生效
    public static var deviceIDFA: String {
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
}
#endif
