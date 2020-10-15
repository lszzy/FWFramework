//
//  CircleImage.swift
//  AppClip
//
//  Created by wuyong on 2020/8/26.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI

struct CircleView: View {
    var image: Image
    
    var body: some View {
        image
            .resizable()
            .frame(width: 300, height: 300)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 4))
            .shadow(radius: 10)
    }
}

struct CircleImage_Previews: PreviewProvider {
    static var previews: some View {
        CircleView(image: Image("AccentImage"))
    }
}
