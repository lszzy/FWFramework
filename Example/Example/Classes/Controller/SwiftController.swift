//
//  SwiftController.swift
//  Example
//
//  Created by wuyong on 2018/3/2.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

import UIKit

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
        objcButton.setTitle("ObjcController", for: .normal)
        objcButton.addTarget(self, action: #selector(onObjc), for: .touchUpInside)
        view.addSubview(objcButton)
        objcButton.fwLayoutChain.top(20).size(CGSize(width: 150, height: 30)).centerX()
        view.fwAddTapGesture(withTarget: self, action: #selector(onClose))
    }

    // MARK: - Action

    func onObjc() {
        let viewController = ObjcController()
        navigationController?.pushViewController(viewController, animated: true)
    }

    func onClose() {
        fwClose(animated: true)
    }
}
