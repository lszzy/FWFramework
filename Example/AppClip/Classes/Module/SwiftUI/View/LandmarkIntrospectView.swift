//
//  LandmarkIntrospectView.swift
//  AppClip
//
//  Created by wuyong on 2020/12/1.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI
import Combine

struct LandmarkIntrospectView: View {
    @ObservedObject var viewModel: LandmarkViewModel = LandmarkViewModel()
    
    var body: some View {
        ScrollView {
            if viewModel.data == nil {
                Text("Default")
            } else {
                Text(viewModel.data!)
            }
        }
        .onAppear(perform: {
            self.viewModel.apply(.onAppear)
        })
        .introspectScrollView { (scrollView) in
            scrollView.backgroundColor = UIColor.red
        }
    }
}
