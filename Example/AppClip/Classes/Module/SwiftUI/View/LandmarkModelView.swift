//
//  LandmarkModelView.swift
//  AppClip
//
//  Created by wuyong on 2020/12/1.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI

struct LandmarkModelView: View {
    @ObservedObject var viewModel: LandmarkViewModel = LandmarkViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                switch viewModel.state {
                default:
                    ProgressView()
                        .padding()
                }
            }
        }
        .onAppear {
            self.viewModel.onRefreshing()
        }
    }
}

struct LandmarkModelView_Previews: PreviewProvider {
    static var previews: some View {
        LandmarkModelView()
    }
}
