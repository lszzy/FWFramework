//
//  UserModule.swift
//  User
//
//  Created by wuyong on 2021/1/1.
//

import FWFramework
import Mediator

@objcMembers class UserModule: NSObject, FWModuleProtocol {
    private static let shared: UserModule = UserModule()
    
    static func sharedInstance() -> Self {
        return shared as! Self
    }
    
    func setup() {
        print("UserModule.setup")
    }
}

extension UserModule: UserModuleService {
    func login(_ completion: (() -> Void)?) {
        let viewController = UserLoginViewController()
        viewController.completion = completion
        let navigationController = UINavigationController(rootViewController: viewController)
        FWRouter.present(navigationController, animated: true, completion: nil)
    }
}
