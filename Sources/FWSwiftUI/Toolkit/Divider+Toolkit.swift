//
//  Divider+Toolkit.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

#if canImport(SwiftUI)
import SwiftUI

// MARK: - Divider+Toolkit
/// 修改分割线颜色使用background方法即可，示例：background(Color.gray)
extension Divider {
    
    /// 分割线默认尺寸配置，未自定义时1像素，仅影响Divider和Rectangle的dividerStyle方法
    public static var defaultSize: CGFloat = 1.0 / UIScreen.main.scale
    
    /// 分割线默认颜色，未自定义时为灰色，仅影响Divider和Rectangle的dividerStyle方法
    public static var defaultColor: Color {
        return defaultColorConfiguration?() ??
            Color(red: 222.0 / 255.0, green: 224.0 / 255.0, blue: 226.0 / 255.0)
    }
    
    /// 自定义分割线默认颜色配置句柄，默认nil
    public static var defaultColorConfiguration: (() -> Color)?
    
    /// 自定义分割线尺寸，使用scale实现，参数nil时为Divider默认配置
    public func dividerStyle(size: CGFloat? = nil, color: Color? = nil) -> some View {
        self.scaleEffect(y: UIScreen.main.scale * (size ?? Divider.defaultSize))
            .frame(height: size ?? Divider.defaultSize)
            .background(color ?? Divider.defaultColor)
    }
    
}

// MARK: - Rectangle+Toolkit
/// 使用Rectangle实现分割线更灵活可控
extension Rectangle {
    
    /// 自定义线条样式，参数nil时为Divider默认配置
    public func dividerStyle(size: CGFloat? = nil, color: Color? = nil) -> some View {
        self.frame(height: size ?? Divider.defaultSize)
            .foregroundColor(color ?? Divider.defaultColor)
    }
    
}

#endif
