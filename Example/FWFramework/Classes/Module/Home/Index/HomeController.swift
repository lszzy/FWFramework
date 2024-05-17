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
    private lazy var mediatorButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(onMediator), for: .touchUpInside)
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
        view.addSubview(mediatorButton)
    }
    
    func setupLayout() {
        mediatorButton.app.layoutChain
            .horizontal()
            .top(toSafeArea: 20)
            .height(30)
    }
    
    private func renderData() {
        setupNavbar()
        
        if UserService.shared.isLogin() {
            mediatorButton.setTitle(String(format: APP.localized("backTitle"), UserService.shared.getUserModel()?.userName ?? ""), for: .normal)
        } else {
            mediatorButton.setTitle(APP.localized("welcomeTitle"), for: .normal)
        }
    }
    
}

// MARK: - Action
extension HomeController {
    
    @objc func onMediator() {
        if UserService.shared.isLogin() {
            UserService.shared.logout { [weak self] in
                self?.renderData()
            }
        } else {
            UserService.shared.login { [weak self] in
                self?.renderData()
            }
        }
    }
    
}
