//
//  HomeController.swift
//  FWFramework_Example
//
//  Created by wuyong on 05/07/2022.
//  Copyright (c) 2022 wuyong. All rights reserved.
//

import FWFramework

class HomeController: UIViewController {
    
    // MARK: - Accessor
    private lazy var loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(onLogin), for: .touchUpInside)
        return button
    }()

    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        renderData()
    }

}

extension HomeController: ViewControllerProtocol {
    
    func setupNavbar() {
        #if RELEASE
        let envTitle = APP.localized("envProduction")
        #elseif STAGING
        let envTitle = APP.localized("envStaging")
        #elseif TESTING
        let envTitle = APP.localized("envTesting")
        #else
        let envTitle = APP.localized("envDevelopment")
        #endif
        navigationItem.title = "\(APP.localized("homeTitle")) - \(envTitle)"
    }
   
    func setupSubviews() {
        view.addSubview(loginButton)
    }
    
    func setupLayout() {
        loginButton.app.layoutChain
            .horizontal()
            .top(toSafeArea: 20)
            .height(30)
    }
    
    private func renderData() {
        setupNavbar()
        if UserService.shared.isLogin() {
            loginButton.setTitle(APP.localized("backTitle"), for: .normal)
        } else {
            loginButton.setTitle(APP.localized("welcomeTitle"), for: .normal)
        }
    }
    
}

// MARK: - Action
extension HomeController {
    
    @objc func onLogin() {
        if UserService.shared.isLogin() { return }
        
        UserService.shared.login { [weak self] in
            self?.renderData()
        }
    }
    
}
