//
//  UserLoginController.swift
//  User
//
//  Created by wuyong on 2021/1/1.
//

import FWFramework
import Mediator

@objcMembers class UserLoginController: UIViewController {
    var completion: (() -> Void)?
    
    @FWModuleAnnotation(TestModuleService.self)
    private var testModule: TestModuleService
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        navigationItem.title = UserBundle.localizedString("userModule")
        
        let testButton = UIButton(type: .system)
        testButton.setTitle(UserBundle.localizedString("testButton"), for: .normal)
        testButton.setImage(UserBundle.imageNamed("testIcon")?.fwCompressImage(withMaxWidth: 25), for: .normal)
        testButton.fwAddTouch { [weak self] (sender) in
            if let viewController = self?.testModule.testViewController() {
                self?.navigationController?.pushViewController(viewController, animated: true)
            }
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
