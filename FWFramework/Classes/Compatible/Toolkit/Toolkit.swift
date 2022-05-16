//
//  Toolkit.swift
//  FWFramework
//
//  Created by wuyong on 2020/10/22.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import UIKit
#if FWMacroSPM
import FWFramework
#endif

// MARK: - FW+Toolkit
extension FW {
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
        return UIFont.__fw.font(ofSize: size, weight: weight)
    }
    
    /// 快速创建图标对象
    ///
    /// - Parameters:
    ///   - named: 图标名称
    ///   - size: 图标大小
    /// - Returns: FWIcon对象
    public static func icon(_ named: String, _ size: CGFloat) -> Icon? {
        return Icon(named: named, size: size)
    }
    
    /// 快速创建图标图像
    /// 
    /// - Parameters:
    ///   - name: 图标名称
    ///   - size: 图片大小
    /// - Returns: UIImage对象
    public static func iconImage(_ name: String, _ size: CGFloat) -> UIImage? {
        return Icon.iconImage(name, size: size)
    }
}

extension Wrapper where Base: UIColor {
    
    /// 设置十六进制颜色标准为ARGB|RGBA，启用为ARGB，默认为RGBA
    public static var colorStandardARGB: Bool {
        get { return UIColor.__fw.colorStandardARGB }
        set { UIColor.__fw.colorStandardARGB = newValue }
    }

    /// 获取透明度为1.0的RGB随机颜色
    public static var randomColor: UIColor {
        return UIColor.__fw.randomColor
    }

    /// 从十六进制值初始化，格式：0x20B2AA，透明度默认1.0
    public static func color(hex: Int, alpha: CGFloat = 1.0) -> UIColor {
        return UIColor.__fw.color(withHex: hex, alpha: alpha)
    }

    /// 从十六进制字符串初始化，支持RGB、RGBA|ARGB，格式：@"20B2AA", @"#FFFFFF"，透明度默认1.0，失败时返回clear
    public static func color(hexString: String, alpha: CGFloat = 1.0) -> UIColor {
        return UIColor.__fw.color(withHexString: hexString, alpha: alpha)
    }

    /// 从颜色字符串初始化，支持十六进制和颜色值，透明度默认1.0，失败时返回clear
    public static func color(string: String, alpha: CGFloat = 1.0) -> UIColor {
        return UIColor.__fw.color(with: string, alpha: alpha)
    }
    
}

/// 当自定义left按钮或隐藏导航栏之后，系统返回手势默认失效，可调用此方法全局开启返回代理。开启后自动将开关代理给顶部VC的shouldPopController、popGestureEnabled属性控制。interactivePop手势禁用时不生效
extension Wrapper where Base: UINavigationController {
    
    /// 单独启用返回代理拦截，优先级高于+enablePopProxy，启用后支持shouldPopController、allowsPopGesture功能，默认NO未启用
    public func enablePopProxy() {
        base.__fw.enablePopProxy()
    }
    
    /// 全局启用返回代理拦截，优先级低于-enablePopProxy，启用后支持shouldPopController、allowsPopGesture功能，默认NO未启用
    public static func enablePopProxy() {
        UINavigationController.__fw.enablePopProxy()
    }
    
}
