//
//  LoginController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/24.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class LoginController: UIViewController {
    
    // MARK: - Accessor
    var completion: (() -> Void)?
    
    private var viewModel = LoginViewModel()
    
}

// MARK: - ViewControllerProtocol
extension LoginController: ViewControllerProtocol {
    
    func setupNavbar() {
        navigationItem.title = APP.localized("mediatorLogin")
        app.setLeftBarItem(Icon.closeImage) { [weak self] (sender) in
            self?.app.close(animated: true)
        }
    }
    
    func setupSubviews() {
        let button = UIButton(type: .system)
        button.setTitle(APP.localized("mediatorLogin"), for: .normal)
        button.setImage(APP.iconImage("zmdi-var-account", 25), for: .normal)
        button.app.addTouch(target: self, action: #selector(loginButtonClicked))
        view.addSubview(button)
        button.app.layoutChain.center()
    }
    
}

// MARK: - Action
private extension LoginController {
    
    @objc func loginButtonClicked() {
        app.showPrompt(title: "mediatorPlaceholder".app.localized, message: nil) { [weak self] nickName in
            self?.viewModel.login(nickName: nickName, completion: {
                self?.dismiss(animated: true, completion: self?.completion)
            })
        }
    }
    
}
