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
        VStack {
            switch viewModel.state {
            case .idle:
                EmptyView()
            case .loading:
                ProgressView()
                    .padding()
            case let .loaded(items):
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .frame(height: 50)
                }
                
                Button("Refresh") {
                    self.viewModel.send(.refresh)
                }
            case let .error(error):
                Text(error.localizedDescription)
                
                Button("Refresh") {
                    self.viewModel.send(.refresh)
                }
            }
        }
        .navigationBarTitle("ViewModel", displayMode: .inline)
        .onAppear {
            self.viewModel.send(.refresh)
        }
    }
}

struct LandmarkModelView_Previews: PreviewProvider {
    static var previews: some View {
        LandmarkModelView()
    }
}
