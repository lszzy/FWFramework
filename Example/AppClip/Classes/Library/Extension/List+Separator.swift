//
//  List+Separator.swift
//  AppClip
//
//  Created by wuyong on 2020/12/25.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI

public extension View {
    func listSeparatorNone(_ backgroundColor: Color = .white) -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .listRowInsets(EdgeInsets())
            .background(backgroundColor)
    }
}
