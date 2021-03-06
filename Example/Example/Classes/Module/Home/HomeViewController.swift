//
//  HomeViewController.swift
//  Example
//
//  Created by wuyong on 2021/3/19.
//  Copyright © 2021 site.wuyong. All rights reserved.
//

import Foundation

class HomeViewController: UIViewController, FWViewController {
    private lazy var loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 0, y: 20, width: FWScreenWidth, height: 30)
        button.addTarget(self, action: #selector(onLogin), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // FIXME: hotfix
        edgesForExtendedLayout = []
        // TODO: feature
        view.addSubview(loginButton)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        renderData()
    }
    
    func renderData() {
        #if APP_PROD
        let envTitle = FWLocalizedString("envProd")
        #elseif APP_TEST
        let envTitle = FWLocalizedString("envTest")
        #else
        let envTitle = FWLocalizedString("envDev")
        #endif
        fwBarTitle = "\(FWLocalizedString("homeTitle")) - \(envTitle)"
        
        if Mediator.userModule.isLogin() {
            loginButton.setTitle(FWLocalizedString("backTitle"), for: .normal)
        } else {
            loginButton.setTitle(FWLocalizedString("welcomeTitle"), for: .normal)
        }
    }
    
    // MARK: - Action
    @objc func onLogin() {
        if Mediator.userModule.isLogin() { return }
        
        Mediator.userModule.login { [weak self] in
            self?.renderData()
        }
    }
}
