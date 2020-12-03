//
//  LandmarkHome.swift
//  AppClip
//
//  Created by wuyong on 2020/8/27.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI
import FWFramework

struct LandmarkHome: View {
    var categories: [String: [Landmark]] {
        Dictionary(grouping: landmarkData,
                   by: { $0.category.rawValue })
    }
    
    @State var showingProfile = false
    @EnvironmentObject var userData: UserData
    
    var profileButton: some View {
        Button(action: {
            self.showingProfile.toggle()
        }, label: {
            Image(systemName: "person.crop.circle")
                .imageScale(.large)
                .accessibility(label: Text("User Profile"))
                .padding()
        })
    }
    
    var body: some View {
        NavigationView {
            List {
                FeaturedLandmarks(landmarks: features)
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
                    .listRowInsets(EdgeInsets())
                
                ForEach(categories.keys.sorted(), id: \.self) { key in
                    CategoryRow(categoryName: key, items: self.categories[key]!)
                }
                .listRowInsets(EdgeInsets())
                
                NavigationLink(
                    destination: LandmarkList(),
                    label: {
                        Text("See All")
                    })
                
                NavigationLink(
                    destination: FWViewControllerWrapper<UIKitController>(),
                    label: {
                        HStack {
                            FWWebImage("https://picsum.photos/50/50?i=30")
                                .placeholder({ Image("AccentImage") })
                                .resizable()
                                .frame(width: 80, height: 80, alignment: .center)
                            Text("UIKitController")
                        }
                    })
                
                NavigationLink(destination: LandmarkModelView()) {
                    Text("ViewModel")
                }
            }
            .navigationBarTitle("Featured", displayMode: .inline)
            .navigationBarItems(trailing: profileButton)
            .navigationBarColor(backgroundColor: UIColor(.fwColorHex(0xFFDA00)), titleColor: .fwColor(withHex: 0x1C1C1E))
            .sheet(isPresented: $showingProfile, content: {
                ProfileHost()
                    .environmentObject(self.userData)
            })
        }
    }
}

struct FeaturedLandmarks: View {
    var landmarks: [Landmark]
    var body: some View {
        PageView(landmarks.map { landmark in
            NavigationLink(
                destination: LandmarkDetail(landmark: landmark),
                label: {
                    FeatureCard(landmark: landmark)
                })
        })
        .frame(height: 200)
        .scaledToFill()
    }
}

struct LandmarkHome_Previews: PreviewProvider {
    static var previews: some View {
        LandmarkHome()
            .environmentObject(UserData())
    }
}
