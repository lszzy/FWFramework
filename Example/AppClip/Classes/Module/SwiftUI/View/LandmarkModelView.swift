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
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var title: String = "ViewModel"
    
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
                    NavigationLink(destination: LandmarkDetailModelView(viewModel: LandmarkDetailViewModel(movieID: Int(item)!))) {
                        Text("Detail - \(item)")
                            .frame(height: 50)
                    }
                }
            case let .error(error):
                Text(error.localizedDescription)
                
                Button("Refresh") {
                    self.viewModel.send(.refresh)
                }
                
                Button("Back") {
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .navigationBarTitle(title, displayMode: .inline)
        //.fwNavigationBarColor(backgroundColor: .green)
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
