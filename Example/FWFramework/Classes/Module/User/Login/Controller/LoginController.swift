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
        result.font = UIFont.app.font(ofSize: 15)
        result.textColor = AppTheme.textColor
        result.tintColor = AppTheme.textColor
        result.backgroundColor = AppTheme.backgroundColor
        result.placeholder = "mediatorPlaceholder".app.localized
        result.clearButtonMode = .whileEditing
        result.app.setBorderColor(AppTheme.borderColor, width: 0.5, cornerRadius: 5)
        result.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        result.leftViewMode = .always
        result.app.keyboardManager = true
        result.app.touchResign = true
        result.app.keyboardResign = true
        result.app.returnResign = true
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
        app.setLeftBarItem(Icon.closeImage) { [weak self] (sender) in
            self?.app.close(animated: true)
        }
    }
    
    func setupSubviews() {
        view.addSubview(nicknameField)
        view.addSubview(loginButton)
    }
    
    func setupLayout() {
        nicknameField.chain
            .width(APP.screenWidth - 30)
            .height(50)
            .top(toSafeArea: 20)
            .centerX()
        
        loginButton.chain
            .top(toViewBottom: nicknameField, offset: 20)
            .centerX()
    }
    
}

// MARK: - Action
private extension LoginController {
    
    @objc func loginButtonClicked() {
        let nickname = nicknameField.text?.app.trimString ?? ""
        viewModel.login(nickName: nickname, completion: { [weak self] in
            self?.dismiss(animated: true, completion: self?.completion)
        })
    }
    
}
