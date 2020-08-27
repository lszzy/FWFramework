//
//  LandmarkDetail.swift
//  AppClip
//
//  Created by wuyong on 2020/8/19.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI

extension AnyTransition {
    static var moveAndFade: AnyTransition {
        // AnyTransition.slide
        // AnyTransition.move(edge: .trailing)
        let insertion = AnyTransition.move(edge: .trailing)
            .combined(with: .opacity)
        let removal = AnyTransition.scale.combined(with: .opacity)
        return .asymmetric(insertion: insertion, removal: removal)
    }
}

struct LandmarkDetail: View {
    @EnvironmentObject var userData: UserData
    
    var landmark: Landmark
    
    var landmarkIndex: Int {
        userData.landmarks.firstIndex(where: { $0.id == landmark.id })!
    }
    
    var body: some View {
        VStack {
            MapView(coordinate: landmark.locationCoordinate)
                .edgesIgnoringSafeArea(.top)
                .frame(height:300)
            
            CircleView(image: landmark.image)
                .offset(y: -130)
                .padding(.bottom, -130)
                .transition(.moveAndFade)
            
            VStack(alignment:.leading) {
                HStack {
                    Text(landmark.name)
                        .font(.title)
                    
                    Button(action: {
                        withAnimation {
                            self.userData.landmarks[self.landmarkIndex].isFavorite.toggle()
                        }
                    }, label: {
                        if self.userData.landmarks[self.landmarkIndex].isFavorite {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .animation(.easeInOut(duration: 2))
                        } else {
                            Image(systemName: "star")
                                .foregroundColor(.gray)
                                .animation(Animation.spring(dampingFraction: 0.5)
                                            .speed(2)
                                            .delay(0.03 * Double(2)))
                        }
                    })
                }
                HStack(alignment: .top) {
                    Text(landmark.park)
                        .font(.subheadline)
                    Spacer()
                    Text(landmark.state)
                        .font(.subheadline)
                }
            }
            .padding()
            
            Spacer()
        }
        .navigationBarTitle(Text(landmark.name), displayMode: .inline)
    }
}

struct LandmarkDetail_Previews: PreviewProvider {
    static var previews: some View {
        LandmarkDetail(landmark: landmarkData[0])
            .environmentObject(UserData())
    }
}
