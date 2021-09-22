//
//  ViewController.swift
//  Example
//
//  Created by wuyong on 2021/3/19.
//  Copyright © 2021 site.wuyong. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if APP_PRODUCTION
        let envTitle = "Production"
        #elseif APP_STAGING
        let envTitle = "Staging"
        #elseif APP_TESTING
        let envTitle = "Testing"
        #else
        let envTitle = "Development"
        #endif
        title = "FWFramework - \(envTitle)"
    }
}
