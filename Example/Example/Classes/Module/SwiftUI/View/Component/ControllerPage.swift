//
//  ControllerPage.swift
//  AppClip
//
//  Created by wuyong on 2020/9/2.
//  Copyright © 2020 site.wuyong. All rights reserved.
//

import SwiftUI
import UIKit

@available(iOS 13.0, *)
struct ControllerPage<T: UIViewController>: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController
    
    func makeUIViewController(context: Context) -> UIViewController {
        return T()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        debugPrint("\(#function)：\(type(of: T.self))")
    }
}
