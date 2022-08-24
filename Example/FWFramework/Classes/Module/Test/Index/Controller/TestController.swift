//
//  TestController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/5/10.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestController: UIViewController {
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavbar()
        setupSubviews()
        setupLayout()
    }
    
}

// MARK: - Setup
private extension TestController {
    
    private func setupNavbar() {
        title = NSLocalizedString("testTitle", comment: "测试")
    }
   
    private func setupSubviews() {
        
    }
    
    private func setupLayout() {
        
    }
    
}
