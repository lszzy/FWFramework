//
//  ViewController.swift
//  User
//
//  Created by lingshizhuangzi@gmail.com on 01/01/2021.
//  Copyright (c) 2021 lingshizhuangzi@gmail.com. All rights reserved.
//

import FWFramework
import Mediator

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.fwAddTouch { (sender) in
            let userModule = FWMediator.loadModule(UserModuleService.self) as? UserModuleService
            userModule?.login({
                button.setTitle("已登录", for: .normal)
            })
        }
        self.view.addSubview(button)
        button.fwLayoutChain.center()
    }

}

