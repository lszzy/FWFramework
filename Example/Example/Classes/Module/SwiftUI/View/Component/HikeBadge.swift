//
//  HikeBadge.swift
//  AppClip
//
//  Created by wuyong on 2020/8/28.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
struct HikeBadge: View {
    var name: String
    var body: some View {
        VStack(alignment: .center) {
            BadgeView()
                .frame(width: 300, height: 300)
                .scaleEffect(1.0 / 3.0)
                .frame(width: 100, height: 100)
            Text(name)
                .font(.caption)
                .accessibility(label: Text("Badge for \(name)."))
        }
    }
}

@available(iOS 13.0, *)
struct HikeBadge_Previews: PreviewProvider {
    static var previews: some View {
        HikeBadge(name: "Preview Testing")
    }
}
