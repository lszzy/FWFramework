//
//  LandmarkDetail.swift
//  AppClip
//
//  Created by wuyong on 2020/8/19.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI

struct LandmarkDetail: View {
    var landmark: Landmark
    
    var body: some View {
        VStack {
            MapView()
                .edgesIgnoringSafeArea(.top)
                .frame(height:300)
            
            CircleImage(image: landmark.image)
                .offset(y: -130)
                .padding(.bottom, -130)
            
            VStack(alignment:.leading) {
                Text("Hello, world!")
                    .font(.title)
                HStack {
                    Text("SwiftUI!")
                        .font(.subheadline)
                    Spacer()
                    Text("Location")
                        .font(.subheadline)
                }
            }
            .padding()
            
            Spacer()
        }
    }
}

struct LandmarkDetail_Previews: PreviewProvider {
    static var previews: some View {
        LandmarkDetail(landmark: landmarkData[0])
    }
}
