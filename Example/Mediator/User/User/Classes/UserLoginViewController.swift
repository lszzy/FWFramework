//
//  UserLoginViewController.swift
//  User
//
//  Created by wuyong on 2021/1/1.
//

import FWFramework
import Mediator

@objcMembers class UserLoginViewController: UIViewController {
    var completion: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        navigationItem.title = UserBundle.localizedString("userModule")
        
        let testButton = UIButton(type: .system)
        testButton.setTitle(UserBundle.localizedString("testButton"), for: .normal)
        testButton.setImage(UserBundle.imageNamed("testIcon")?.fwCompressImage(withMaxWidth: 25), for: .normal)
        testButton.fwAddTouch { (sender) in
            let testModule = FWMediator.module(byService: TestModuleService.self) as? TestModuleService
            if let viewController = testModule?.testViewController() {
                FWRouter.push(viewController, animated: true)
            }
        }
        self.view.addSubview(testButton)
        testButton.fwLayoutChain.centerX().centerYToView(self.view, withOffset: -80)
        
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
