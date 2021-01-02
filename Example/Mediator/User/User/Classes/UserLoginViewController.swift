//
//  UserLoginViewController.swift
//  User
//
//  Created by wuyong on 2021/1/1.
//

import UIKit

@objcMembers class UserLoginViewController: UIViewController {
    var completion: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "UserLoginViewController"
    }
}
