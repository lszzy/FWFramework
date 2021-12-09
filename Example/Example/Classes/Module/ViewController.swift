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
    private var style: Int = 0 {
        didSet {
            let navigationBar = navigationController?.navigationBar
            navigationBar?.fwIsTranslucent = style == 1
            navigationBar?.fwShadowColor = nil
            navigationBar?.fwForegroundColor = UIColor.fwThemeLight(.black, dark: .white)
            if style == 0 {
                navigationBar?.fwBackgroundColor = UIColor.fwThemeLight(.fwColor(withHex: 0xFAFAFA), dark: .fwColor(withHex: 0x121212))
            } else if style == 1 {
                navigationBar?.fwBackgroundColor = UIColor.fwThemeLight(.fwColor(withHex: 0xFAFAFA, alpha: 0.5), dark: .fwColor(withHex: 0x121212, alpha: 0.5))
            } else {
                navigationBar?.fwBackgroundTransparent = true
            }
        }
    }
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: view.bounds)
        scrollView.contentSize = CGSize(width: view.bounds.width, height: view.bounds.height * 2)
        
        for i in 0 ..< 10 {
            let subview = UIView(frame: CGRect(x: 0, y: view.bounds.height / 5 * CGFloat(i), width: view.bounds.width, height: view.bounds.height / 5))
            subview.backgroundColor = UIColor(red: CGFloat(arc4random() % 255) / 255.0, green: CGFloat(arc4random() % 255) / 255.0, blue: CGFloat(arc4random() % 255) / 255.0, alpha: 1)
            scrollView.addSubview(subview)
        }
        return scrollView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        style = 0
        view.addSubview(scrollView)
        view.backgroundColor = UIColor.fwThemeLight(.white, dark: .black)
        view.fwAddTapGesture { [weak self] sender in
            guard let strongSelf = self else { return }
            strongSelf.style = strongSelf.style >= 2 ? 0 : strongSelf.style + 1;
        }
        
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
