//
//  View+FWFramework.swift
//  FWFramework
//
//  Created by wuyong on 2020/11/9.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#if DEBUG || arch(arm64)
#if canImport(SwiftUI)
import SwiftUI

// MARK: - FWNavigationBarModifier

@available(iOS 13.0, *)
struct FWNavigationBarModifier: ViewModifier {
    var backgroundColor: UIColor?

    init(backgroundColor: UIColor?) {
        self.backgroundColor = backgroundColor
    }

    func body(content: Content) -> some View {
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
}

// MARK: - FWRoundedCornerShape

@available(iOS 13.0, *)
struct FWRoundedCornerShape: Shape {
    var radius: CGFloat = 0
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

@available(iOS 13.0, *)
public extension View {
    /// 设置不规则圆角效果
    func fwCornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(FWRoundedCornerShape(radius: radius, corners: corners))
    }
}

#endif
#endif
