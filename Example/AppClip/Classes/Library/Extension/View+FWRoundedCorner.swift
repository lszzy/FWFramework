//
//  View+FWRoundedCorner.swift
//  AppClip
//
//  Created by wuyong on 2020/12/12.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI

struct FWRoundedCorner: Shape {

    var radius: CGFloat = 0
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func fwCornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(FWRoundedCorner(radius: radius, corners: corners))
    }
}
