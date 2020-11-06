//
//  LandmarkRow.swift
//  AppClip
//
//  Created by wuyong on 2020/8/26.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI

struct LandmarkRow: View {
    var landmark: Landmark
    
    var body: some View {
        HStack {
            //FWWebImage()
                //.url("https://picsum.photos/50/50?i=\(arc4random_uniform(30) + 1)")
                //.placeholder(FWImageFile("test.webp"))
            landmark.image
                .resizable()
                .frame(width: 50, height: 50)
            Text(landmark.name)
            Spacer()
            
            if landmark.isFavorite {
                Image(systemName: "star.fill")
                    .imageScale(.medium)
                    .foregroundColor(.yellow)
            }
        }
        .frame(height: 200, alignment: .center)
    }
}

struct LandmarkRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LandmarkRow(landmark: landmarkData[0])
            LandmarkRow(landmark: landmarkData[1])
        }
        .previewLayout(.fixed(width: 300, height: 70))
    }
}
