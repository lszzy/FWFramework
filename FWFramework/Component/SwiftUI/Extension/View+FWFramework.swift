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
    /// 转换为AnyView
    func fwEraseToAnyView() -> AnyView {
        AnyView(self)
    }
    
    /// 设置不规则圆角效果
    func fwCornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(FWRoundedCornerShape(radius: radius, corners: corners))
    }
}

#endif
#endif
