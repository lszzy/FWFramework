//
//  BadgeView.swift
//  AppClip
//
//  Created by wuyong on 2020/8/27.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
struct BadgeView: View {
    static let rotationCount = 8
    var badgeSymbols: some View {
        ForEach(0 ..< BadgeView.rotationCount) { i in
            RotatedBadgeSymbol(angle: .degrees(Double(i) / Double(BadgeView.rotationCount)) * 360.0)
        }
        .opacity(0.5)
    }
    
    var body: some View {
        ZStack {
            BadgeBackground()
            
            GeometryReader { geometry in
                self.badgeSymbols
                    .scaleEffect(1.0 / 4.0, anchor: .top)
                    .position(x: geometry.size.width / 2.0, y: (3.0 / 4.0) * geometry.size.height)
            }
        }
        .scaledToFit()
    }
}

@available(iOS 13.0, *)
struct BadgeView_Previews: PreviewProvider {
    static var previews: some View {
        BadgeView()
    }
}
