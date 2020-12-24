//
//  LandmarkDetailModelView.swift
//  AppClip
//
//  Created by wuyong on 2020/12/2.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI

struct LandmarkDetailModelView: View {
    @ObservedObject var viewModel: LandmarkDetailViewModel
    
    var body: some View {
        content
            .fwNavigationBarColor(backgroundColor: .red)
            .onAppear { self.viewModel.send(event: .onAppear) }
    }
    
    private var content: some View {
        switch viewModel.state {
        case .idle:
            return Color.clear.fwEraseToAnyView()
        case .loading:
            return ProgressView()
                .padding()
                .fwEraseToAnyView()
        case .error(let error):
            return Text(error.localizedDescription).fwEraseToAnyView()
        case .loaded(let movie):
            return Text("\(movie.id)")
                .font(.largeTitle)
                .multilineTextAlignment(.center)
                .fwEraseToAnyView()
        }
    }
}

struct LandmarkDetailModelView_Previews: PreviewProvider {
    static var previews: some View {
        LandmarkDetailModelView(viewModel: LandmarkDetailViewModel(movieID: 1))
    }
}
