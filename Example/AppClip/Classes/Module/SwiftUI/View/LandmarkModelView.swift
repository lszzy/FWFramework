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
    
    @State private var headerRefreshing: Bool = false
    @State private var footerRefreshing: Bool = false
    @State private var noMore: Bool = false
    
    var body: some View {
        ScrollView {
            if viewModel.items.count > 0 {
                RefreshHeader(refreshing: $headerRefreshing, action: {
                    self.reload()
                }) { progress in
                    if self.headerRefreshing {
                        ProgressView()
                    } else {
                        Text("Pull to refresh")
                    }
                }
            }
            
            ForEach(viewModel.items, id: \.self) { item in
                Text(item)
                    .frame(height: 500)
            }
             
            if viewModel.items.count > 0 {
                RefreshFooter(refreshing: $footerRefreshing, action: {
                    self.loadMore()
                }) {
                    if self.noMore {
                        Text("No more data !")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ProgressView()
                            .padding()
                    }
                }
                .noMore(noMore)
                .preload(offset: 50)
            }
        }
        .enableRefresh()
        .overlay(Group {
            if viewModel.items.count == 0 {
                ProgressView()
            } else {
                EmptyView()
            }
        })
        .onAppear {
            self.reload()
        }
    }
    
    func reload() {
        viewModel.refreshData {
            self.headerRefreshing = false
            self.noMore = false
        }
    }
    
    func loadMore() {
        viewModel.loadData {
            self.footerRefreshing = false
            self.noMore = self.viewModel.items.count > 10
        }
    }
}

struct LandmarkModelView_Previews: PreviewProvider {
    static var previews: some View {
        LandmarkModelView()
    }
}
