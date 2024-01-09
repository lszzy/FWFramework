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
extension View {
    
    /// 设置不规则圆角效果
    public func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
    
    /// 同时设置边框和圆角
    public func border<S: ShapeStyle>(_ content: S, width lineWidth: CGFloat, cornerRadius: CGFloat) -> some View {
        self.cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .circular)
                    .stroke(content, lineWidth: lineWidth)
            )
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
    public func then(_ body: (Self) -> AnyView) -> some View {
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
    
    /// 值不为空时执行闭包并返回新的视图
    public func then<T: View, Value>(_ value: Value?, body: (Self, Value) -> T) -> some View {
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

#endif
