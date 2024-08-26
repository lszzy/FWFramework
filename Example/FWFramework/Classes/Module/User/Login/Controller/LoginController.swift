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

    // MARK: - Subviews
    private lazy var nicknameField: UITextField = {
        let result = UITextField()
        result.app.addStyle(.default)
        result.placeholder = "mediatorPlaceholder".app.localized
        return result
    }()

    private lazy var loginButton: UIButton = {
        let button = AppTheme.largeButton()
        button.setTitle(APP.localized("mediatorLogin"), for: .normal)
        button.app.addTouch(target: self, action: #selector(loginButtonClicked))
        return button
    }()
}

// MARK: - ViewControllerProtocol
extension LoginController: ViewControllerProtocol {
    func setupNavbar() {
        navigationItem.title = APP.localized("mediatorLogin")
        app.setLeftBarItem(Icon.closeImage) { [weak self] _ in
            self?.app.close(animated: true)
        }
    }

    func setupSubviews() {
        view.addSubview(nicknameField)
        view.addSubview(loginButton)
    }

    func setupLayout() {
        nicknameField.layoutChain
            .width(APP.screenWidth - 30)
            .height(50)
            .top(toSafeArea: 20)
            .centerX()

        loginButton.layoutChain
            .top(toViewBottom: nicknameField, offset: 20)
            .centerX()
    }
}

// MARK: - Action
extension LoginController {
    @objc private func loginButtonClicked() {
        let nickname = nicknameField.text?.app.trimString ?? ""
        viewModel.login(nickName: nickname, completion: { [weak self] in
            self?.dismiss(animated: true, completion: self?.completion)
        })
    }
}
