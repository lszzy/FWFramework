//
//  SettingsController.swift
//  FWSwift_Example
//
//  Created by wuyong on 2022/5/10.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

class SettingsController: UIViewController {
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavbar()
        setupSubviews()
        setupLayout()
    }
    
}

// MARK: - Setup
private extension SettingsController {
    
    private func setupNavbar() {
        navigationItem.title = NSLocalizedString("settings.title", comment: "设置")
    }
   
    private func setupSubviews() {
        
    }
    
    private func setupLayout() {
        
    }
    
}