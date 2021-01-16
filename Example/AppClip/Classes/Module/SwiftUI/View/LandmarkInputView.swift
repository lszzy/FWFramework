//
//  LandmarkInputView.swift
//  AppClip
//
//  Created by wuyong on 2020/12/24.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI
import FWFramework

struct LandmarkInputView: View {
    @State var text: String = ""
    
    var body: some View {
        FWKeyboardObservingView {
            VStack {
                Image("AccentImage")
                    .frame(width: 80, height: 80, alignment: .center)
                    .aspectRatio(contentMode: .fill)
                    .clipped()
                
                FWImageWrapper()
                    .url("https://picsum.photos/50/50?i=\(arc4random_uniform(30) + 1)")
                    .placeholder(FWImageFile("test.webp"))
                    .frame(width: 50, height: 50)
                
                FWWebImage("https://picsum.photos/50/50?i=30")
                    .placeholder({ Image("AccentImage") })
                    .resizable()
                    .frame(width: 80, height: 80, alignment: .center)
                
                Button("Hide Keyboard") {
                    UIWindow.fwMain()?.endEditing(true)
                }
                
                TextField("Input", text: $text)
                    .frame(width: 200)
            }
            .padding(.top, 290)
        }
        .fwNavigationBarColor(backgroundColor: .tertiarySystemBackground)
        .navigationTitle("Keyboard Observing")
    }
}

struct LandmarkInputView_Previews: PreviewProvider {
    static var previews: some View {
        LandmarkInputView()
    }
}
