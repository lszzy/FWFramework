//
//  SwiftController.swift
//  Example
//
//  Created by wuyong on 2018/3/2.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

import UIKit
import FWFramework

// MARK: - SwiftController
@objc class SwiftController: UIViewController {
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // FIXME: hotfix
        self.title = String(describing: type(of: self))
        self.edgesForExtendedLayout = []
        self.view.backgroundColor = UIColor.white
        
        // TODO: feature
        let objcButton = UIButton(type: .system)
        objcButton.setTitle("ObjcController", for: .normal)
        objcButton.addTarget(self, action: #selector(onObjc), for: .touchUpInside)
        objcButton.frame = CGRect(x: self.view.frame.size.width / 2 - 75, y: 20, width: 150, height: 30)
        self.view.addSubview(objcButton)
    }
    
    // MARK: - Action
    @discardableResult
    @objc func onObjc() -> Bool {
        let viewController = ObjcController()
        self.navigationController?.pushViewController(viewController, animated: true)
        return true
    }
}
