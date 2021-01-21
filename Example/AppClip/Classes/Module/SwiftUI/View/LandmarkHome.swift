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
    @State private var showingViewModel = false
    @State private var showingPage: String? = nil
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: LandmarkModelView(), isActive: $showingViewModel) {
                    Text("ViewModel")
                }
                
                NavigationLink(destination: LandmarkModelView(title: "ViewModel2"), tag: "ViewModel", selection: $showingPage) {
                    Text("ViewModel2")
                }
                
                NavigationLink(
                    destination: LandmarkTestDataView(),
                    label: {
                        Text("Codable Test")
                    })
                
                NavigationLink(
                    destination: LandmarkTestDatabaseView(),
                    label: {
                        Text("Database Test")
                    })
                
                NavigationLink(
                    destination: LandmarkInputView(),
                    label: {
                        Text("Keyboard Observing")
                    })
                
                NavigationLink(
                    destination: LandmarkLazyView(),
                    label: {
                        Text("LazyVStack")
                    })
            }
            .navigationTitle("AppClip Example")
            .navigationBarTitleDisplayMode(.inline)
            .fwNavigationBarAppearance(backgroundColor: nil, titleColor: .label)
            .fwNavigationBarColor(backgroundColor: .tertiarySystemBackground)
        }
    }
}

struct LandmarkHome_Previews: PreviewProvider {
    static var previews: some View {
        LandmarkHome()
    }
}
