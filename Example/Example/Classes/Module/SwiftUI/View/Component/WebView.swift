//
//  WebView.swift
//  AppClip
//
//  Created by wuyong on 2020/9/2.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    typealias UIViewType = WKWebView
    
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let req = URLRequest(url: URL(string: "https://www.baidu.com")!)
        uiView.load(req)
    }
}

struct WebView_Previews: PreviewProvider {
    static var previews: some View {
        WebView()
    }
}
