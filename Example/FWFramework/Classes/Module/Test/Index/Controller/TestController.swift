//
//  TestController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/5/10.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

class TestController: UIViewController {
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavbar()
        setupSubviews()
        setupConstraints()
    }
    
}

// MARK: - Setup
private extension TestController {
    
    private func setupNavbar() {
        title = NSLocalizedString("test.title", comment: "测试")
    }
   
    private func setupSubviews() {
        
    }
    
    private func setupConstraints() {
        
    }
    
}