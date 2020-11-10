//
//  UIKitController.swift
//  AppClip
//
//  Created by wuyong on 2020/9/2.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import UIKit
import SwiftUI
import WebKit
import FWFramework

class UIKitController: UIViewController {
    
    override func viewDidLoad() {
        view.addSubview(button)
    }
    
    lazy var button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Open SwiftUI View", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 30)
        button.setTitleColor(.orange, for: .normal)
        button.sizeToFit()
        button.center = view.center
        button.addTarget(self, action: #selector(openContentView),
                         for: .touchUpInside)
        return button
    }()
    
    @objc func openContentView() {
        let hostVC = UIHostingController(rootView: FWViewWrapper<WKWebView>({ () -> WKWebView in
            let webView = WKWebView()
            let req = URLRequest(url: URL(string: "https://www.baidu.com")!)
            webView.load(req)
            return webView
        }))
        present(hostVC, animated: true, completion: nil)
    }
    
}
