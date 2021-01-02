//
//  UserLoginViewController.swift
//  User
//
//  Created by wuyong on 2021/1/1.
//

import FWFramework

@objcMembers class UserLoginViewController: UIViewController {
    var completion: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        navigationItem.title = "UserLoginViewController"
        
        let button = UIButton(type: .system)
        button.setTitle("完成登录", for: .normal)
        button.fwAddTouch { [weak self] (sender) in
            self?.dismiss(animated: true, completion: self?.completion)
        }
        self.view.addSubview(button)
        button.fwLayoutChain.center()
    }
}
