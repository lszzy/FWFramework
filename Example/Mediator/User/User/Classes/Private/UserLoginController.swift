//
//  UserLoginController.swift
//  User
//
//  Created by wuyong on 2021/1/1.
//

import FWFramework
import Mediator
import Core

@objcMembers class UserLoginController: UIViewController, FWViewController {
    var completion: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = UserBundle.localizedString("loginButton")
        
        let testButton = UIButton(type: .system)
        testButton.setTitle(UserBundle.localizedString("testButton"), for: .normal)
        testButton.setImage(UserBundle.imageNamed("test")?.fwCompressImage(withMaxWidth: 25), for: .normal)
        testButton.fwAddTouch { [weak self] (sender) in
            self?.navigationController?.pushViewController(Mediator.testModule.testViewController(), animated: true)
        }
        self.view.addSubview(testButton)
        testButton.fwLayoutChain.centerX().centerYToView(self.view as Any, withOffset: -80)
        
        let button = UIButton(type: .system)
        button.setTitle(UserBundle.localizedString("loginButton"), for: .normal)
        button.setImage(UserBundle.imageNamed("user")?.fwCompressImage(withMaxWidth: 25), for: .normal)
        button.fwAddTouch { [weak self] (sender) in
            self?.dismiss(animated: true, completion: self?.completion)
        }
        self.view.addSubview(button)
        button.fwLayoutChain.center()
    }
}
