//
//  LandmarkInputView.swift
//  AppClip
//
//  Created by wuyong on 2020/12/24.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI

struct LandmarkInputView: View {
    @State var text: String = ""
    
    var body: some View {
        FWKeyboardObservingView {
            VStack {
                Button("Hide Keyboard") {
                    UIWindow.fwMain()?.endEditing(true)
                }
                
                TextField("Input", text: $text)
                    .frame(width: 200)
            }
            .padding(.top, 500)
        }
    }
}

struct LandmarkInputView_Previews: PreviewProvider {
    static var previews: some View {
        LandmarkInputView()
    }
}
