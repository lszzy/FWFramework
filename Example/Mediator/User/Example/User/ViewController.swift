//
//  ViewController.swift
//  User
//
//  Created by lingshizhuangzi@gmail.com on 01/01/2021.
//  Copyright (c) 2021 lingshizhuangzi@gmail.com. All rights reserved.
//

import FWFramework
import Mediator

class ViewController: UIViewController, FWViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "UserModule Example"
        
        let button = UIButton(type: .system)
        if Mediator.userModule.isLogin() {
            button.setTitle("Logout", for: .normal)
        } else {
            button.setTitle("Login", for: .normal)
        }
        button.fwAddTouch { (sender) in
            if (Mediator.userModule.isLogin()) {
                Mediator.userModule.logout {
                    button.setTitle("Login", for: .normal)
                }
            } else {
                Mediator.userModule.login {
                    button.setTitle("Logout", for: .normal)
                }
            }
        }
        self.view.addSubview(button)
        button.fwLayoutChain.center()
    }

}

