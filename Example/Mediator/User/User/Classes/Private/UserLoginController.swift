//
//  UserLoginController.swift
//  User
//
//  Created by wuyong on 2021/1/1.
//

import FWFramework
import Core

@objcMembers class UserLoginController: UIViewController, FWViewController {
    var completion: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = UserBundle.localizedString("loginButton")
        fwSetLeftBarItem(CoreBundle.imageNamed("close")) { [weak self] (sender) in
            self?.fwClose(animated: true)
        }
        
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
