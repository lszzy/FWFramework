//
//  HomeController.swift
//  Example
//
//  Created by wuyong on 2022/3/23.
//  Copyright © 2022 site.wuyong. All rights reserved.
//

import UIKit
import FWFramework

class HomeController: UIViewController {
    
    // MARK: - Accessor
    private var style: Int = 0 {
        didSet {
            renderStyle()
        }
    }
    
    // MARK: - Subviews
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

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavbar()
        setupSubviews()
        setupConstraints()
        
        renderData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        style = 0
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        style = 0
    }
    
}

// MARK: - Setup
private extension HomeController {
    
    private func setupNavbar() {
        navigationItem.backBarButtonItem = UIBarButtonItem(image: UIImage(), style: .plain, target: nil, action: nil)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem.fwBarItem(with: "home.btnStyle".fw.localized, target: self, action: #selector(leftItemClicked(_:)))
        
        let isChinese = Bundle.fw.currentLanguage?.hasPrefix("zh") ?? false
        navigationItem.rightBarButtonItem = UIBarButtonItem.fwBarItem(with: isChinese ? "中文" : "English", target: self, action: #selector(rightItemClicked(_:)))
    }
   
    private func setupSubviews() {
        view.addSubview(scrollView)
        view.backgroundColor = UIColor.fwThemeLight(.white, dark: .black)
        view.fwAddTapGesture(withTarget: self, action: #selector(testViewClicked))
    }
    
    private func setupConstraints() {
        
    }
}

// MARK: - Action
@objc private extension HomeController {
    
    func leftItemClicked(_ sender: Any) {
        style = style >= 2 ? 0 : style + 1
    }
    
    func rightItemClicked(_ sender: Any) {
        let isChinese = Bundle.fw.currentLanguage?.hasPrefix("zh") ?? false
        Bundle.fw.localizedLanguage = isChinese ? "en" : "zh-Hans"
        
        navigationItem.leftBarButtonItem?.title = "home.btnStyle".fw.localized
        if let buttonItem = sender as? UIBarButtonItem {
            buttonItem.title = isChinese ? "English" : "中文"
        }
        
        renderData()
    }
    
    func testViewClicked() {
        FWRouter.openURL(AppRouter.testUrl)
    }
    
}

// MARK: - Private
private extension HomeController {
    
    func renderData() {
        #if APP_PRODUCTION
        let envTitle = "home.envProduction".fw.localized
        #elseif APP_STAGING
        let envTitle = "home.envStaging".fw.localized
        #elseif APP_TESTING
        let envTitle = "home.envTesting".fw.localized
        #else
        let envTitle = "home.envDevelopment".fw.localized
        #endif
        title = "FWFramework - \(envTitle)"
    }
    
    func renderStyle() {
        switch style {
        case 0:
            navigationController?.navigationBar.fwIsTranslucent = false
            navigationController?.navigationBar.fwBackgroundColor = UIColor.fwThemeLight(.fwColor(withHex: 0xFAFAFA), dark: .fwColor(withHex: 0x121212))
        case 1:
            navigationController?.navigationBar.fwIsTranslucent = true
            navigationController?.navigationBar.fwBackgroundColor = UIColor.fwThemeLight(.fwColor(withHex: 0xFAFAFA, alpha: 0.5), dark: .fwColor(withHex: 0x121212, alpha: 0.5))
        default:
            navigationController?.navigationBar.fwIsTranslucent = false
            navigationController?.navigationBar.fwBackgroundTransparent = true
        }
    }
    
}
