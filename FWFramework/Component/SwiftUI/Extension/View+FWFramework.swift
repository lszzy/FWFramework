//
//  View+FWFramework.swift
//  FWFramework
//
//  Created by wuyong on 2020/11/9.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#if canImport(SwiftUI)
import SwiftUI

// MARK: - FWNavigationBarModifier

/// 导航栏背景色修改器
@available(iOS 13.0, *)
public struct FWNavigationBarModifier: ViewModifier {
    var backgroundColor: UIColor?

    public init(backgroundColor: UIColor?) {
        self.backgroundColor = backgroundColor
    }

    public func body(content: Content) -> some View {
        ZStack{
            content
            VStack {
                GeometryReader { geometry in
                    Color(self.backgroundColor ?? .clear)
                        .frame(height: geometry.safeAreaInsets.top)
                        .edgesIgnoringSafeArea(.top)
                    Spacer()
                }
            }
        }
    }
}

// MARK: - FWLineShape

/// 线条形状，用于分割线、虚线等。自定义路径形状：Path { (path) in ... }
@available(iOS 13.0, *)
public struct FWLineShape: Shape {
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

// MARK: - FWRoundedCornerShape

/// 不规则圆角形状
@available(iOS 13.0, *)
public struct FWRoundedCornerShape: Shape {
    public var radius: CGFloat = 0
    public var corners: UIRectCorner = .allCorners

    public func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

@available(iOS 13.0, *)
public extension View {
    /// 设置导航栏通用样式。背景色有值时为全局样式，无法修改；为nil时透明，需各页面设置；文字颜色有值时为全局样式
    func fwNavigationBarAppearance(backgroundColor: UIColor?, titleColor: UIColor?) -> some View {
        let coloredAppearance = UINavigationBarAppearance()
        coloredAppearance.configureWithTransparentBackground()
        
        if let backgroundColor = backgroundColor {
            coloredAppearance.backgroundColor = backgroundColor
        }
        
        if let titleColor = titleColor {
            coloredAppearance.titleTextAttributes = [.foregroundColor: titleColor]
            coloredAppearance.largeTitleTextAttributes = [.foregroundColor: titleColor]
            UINavigationBar.appearance().tintColor = titleColor
        }
        
        UINavigationBar.appearance().standardAppearance = coloredAppearance
        UINavigationBar.appearance().compactAppearance = coloredAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
        return self
    }
    
    /// 设置单个页面导航栏背景色，未指定通用样式时生效
    func fwNavigationBarColor(backgroundColor: UIColor?) -> some View {
        self.modifier(FWNavigationBarModifier(backgroundColor: backgroundColor))
    }
    
    /// 设置不规则圆角效果
    func fwCornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(FWRoundedCornerShape(radius: radius, corners: corners))
    }
    
    /// 转换为AnyView
    func fwEraseToAnyView() -> AnyView {
        AnyView(self)
    }
}

#endif
