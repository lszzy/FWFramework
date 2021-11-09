//
//  ViewController.swift
//  Example
//
//  Created by wuyong on 2021/3/19.
//  Copyright © 2021 site.wuyong. All rights reserved.
//

import FWFramework
import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let navigationBar = navigationController?.navigationBar
        navigationBar?.fwBackgroundColor = UIColor.fwThemeLight(.fwColor(withHex: 0xFAFAFA), dark: .fwColor(withHex: 0x121212))
        navigationBar?.fwForegroundColor = UIColor.fwThemeLight(.black, dark: .white)
        view.backgroundColor = UIColor.fwThemeLight(.white, dark: .black)
        
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
