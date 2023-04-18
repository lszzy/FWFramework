//
//  View+Toolkit.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

#if canImport(SwiftUI)
import SwiftUI

// MARK: - LineShape
/// 线条形状，用于分割线、虚线等。自定义路径形状：Path { (path) in ... }
/// 常用分割线：Rectangle.foregroundColor替代Divider组件
@available(iOS 13.0, *)
public struct LineShape: Shape {
    public var axes: Axis.Set = .horizontal
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        if axes == .horizontal {
            path.addLine(to: CGPoint(x: rect.width, y: 0))
        } else {
            path.addLine(to: CGPoint(x: 0, y: rect.height))
        }
        return path
    }
}

// MARK: - RoundedCornerShape
/// 不规则圆角形状
@available(iOS 13.0, *)
public struct RoundedCornerShape: Shape {
    public var radius: CGFloat = 0
    public var corners: UIRectCorner = .allCorners

    public func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - RemovableModifier
/// 视图移除性修改器
@available(iOS 13.0, *)
public struct RemovableModifier: ViewModifier {
    public let removable: Bool
    
    public init(removable: Bool) {
        self.removable = removable
    }
    
    public func body(content: Content) -> some View {
        Group {
            if !removable {
                content
            } else {
                EmptyView()
            }
        }
    }
}

// MARK: - View+Toolkit
/// 注意：iOS13系统View在dismiss时可能不会触发onDisappear，可在关闭按钮事件中处理
@available(iOS 13.0, *)
extension View {
    
    /// 设置不规则圆角效果
    public func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
    
    /// 同时设置边框和圆角
    public func border<S: ShapeStyle>(_ content: S, width lineWidth: CGFloat = 1, cornerRadius: CGFloat) -> some View {
        self.cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .circular)
                    .stroke(content, lineWidth: lineWidth)
            )
            .padding(lineWidth / 2)
    }
    
    /// 切换视图移除性
    public func removable(_ removable: Bool) -> some View {
        modifier(RemovableModifier(removable: removable))
    }
    
    /// 切换视图隐藏性
    public func hidden(_ isHidden: Bool) -> some View {
        Group {
            if isHidden {
                hidden()
            } else {
                self
            }
        }
    }
    
    /// 切换视图可见性
    public func visible(_ isVisible: Bool = true) -> some View {
        opacity(isVisible ? 1 : 0)
    }
    
    /// 动态切换裁剪性
    public func clipped(_ value: Bool) -> some View {
        if value {
            return AnyView(self.clipped())
        } else {
            return AnyView(self)
        }
    }
    
    /// 执行闭包并返回新的视图
    public func then<T: View>(_ body: (Self) -> T) -> T {
        return body(self)
    }
    
    /// 条件成立时执行闭包并返回新的视图
    public func then<T: View>(_ condition: Bool, body: (Self) -> T) -> some View {
        if condition {
            return AnyView(body(self))
        } else {
            return AnyView(self)
        }
    }
    
    /// 变量有值时执行闭包并返回新的视图
    public func then<T: View, V>(_ value: V?, body: (Self, V) -> T) -> some View {
        if let value = value {
            return AnyView(body(self, value))
        } else {
            return AnyView(self)
        }
    }
    
    /// 配置当前对象
    public func configure(_ body: (inout Self) -> Void) -> Self {
        var result = self
        body(&result)
        return result
    }
    
    /// 转换为AnyView
    public func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
    
}

// MARK: - Divider+Toolkit
/// 修改分割线颜色使用background方法即可，示例：background(Color.gray)
@available(iOS 13.0, *)
extension Divider {
    
    /// 分割线默认尺寸配置，未自定义时1像素，仅影响Divider和Rectangle的dividerStyle方法
    public static var defaultSize: CGFloat = 1.0 / UIScreen.main.scale
    
    /// 分割线默认颜色配置，未自定义时为灰色，仅影响Divider和Rectangle的dividerStyle方法
    public static var defaultColor: Color = Color(red: 222.0 / 255.0, green: 224.0 / 255.0, blue: 226.0 / 255.0)
    
    /// 自定义分割线尺寸，使用scale实现，参数nil时为Divider默认配置
    public func dividerStyle(size: CGFloat? = nil, color: Color? = nil) -> some View {
        self.scaleEffect(y: UIScreen.main.scale * (size ?? Divider.defaultSize))
            .frame(height: size ?? Divider.defaultSize)
            .background(color ?? Divider.defaultColor)
    }
    
}

// MARK: - Rectangle+Toolkit
/// 使用Rectangle实现分割线更灵活可控
@available(iOS 13.0, *)
extension Rectangle {
    
    /// 自定义线条样式，参数nil时为Divider默认配置
    public func dividerStyle(size: CGFloat? = nil, color: Color? = nil) -> some View {
        self.frame(height: size ?? Divider.defaultSize)
            .foregroundColor(color ?? Divider.defaultColor)
    }
    
}

#endif
