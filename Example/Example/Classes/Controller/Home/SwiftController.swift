//
//  SwiftController.swift
//  Example
//
//  Created by wuyong on 2018/3/2.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

import UIKit
import SwiftUI

// MARK: - SwiftController

@objcMembers class SwiftController: UIViewController {
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // FIXME: hotfix
        navigationItem.title = String(describing: type(of: self))
        edgesForExtendedLayout = []
        view.backgroundColor = UIColor.white

        // TODO: feature
        let objcButton = UIButton(type: .system)
        objcButton.setTitle("SwiftUIController", for: .normal)
        objcButton.addTarget(self, action: #selector(onSwiftUI), for: .touchUpInside)
        view.addSubview(objcButton)
        objcButton.fwLayoutChain.top(20).size(CGSize(width: 150, height: 30)).centerX()
        view.fwAddTapGesture(withTarget: self, action: #selector(onClose))
    }

    // MARK: - Action

    func onSwiftUI() {
        let viewController = UIHostingController(rootView: LandmarkHome().environmentObject(UserData()))
        viewController.modalPresentationStyle = .fullScreen
        present(viewController, animated: true, completion: nil)
    }

    func onClose() {
        fwClose(animated: true)
    }
}
