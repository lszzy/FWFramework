//
//  HomeController.swift
//  FWFramework_Example
//
//  Created by wuyong on 05/07/2022.
//  Copyright (c) 2022 wuyong. All rights reserved.
//

import UIKit

class HomeController: UIViewController {

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavbar()
        setupSubviews()
        setupLayout()
    }

}

// MARK: - Setup
private extension HomeController {
    
    private func setupNavbar() {
        title = NSLocalizedString("home.title", comment: "首页")
    }
   
    private func setupSubviews() {
        
    }
    
    private func setupLayout() {
        
    }
    
}
