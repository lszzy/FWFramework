//
//  UserModule.swift
//  User
//
//  Created by wuyong on 2021/1/1.
//

import FWFramework
import Mediator

@objcMembers class UserBundle: FWModuleBundle {
    private static let userBundle: Bundle = {
        return Bundle.fwBundle(with: UserBundle.classForCoder(), name: "User")?.fwLocalized() ?? .main
    }()
    
    override class func bundle() -> Bundle {
        return userBundle
    }
}

@objcMembers class UserModule: NSObject, UserModuleService {
    private static let shared: UserModule = UserModule()
    
    static func sharedInstance() -> Self {
        return shared as! Self
    }
    
    func setup() {
        FWLogDebug("UserModule.setup")
    }
    
    func login(_ completion: (() -> Void)?) {
        let viewController = UserLoginViewController()
        viewController.completion = completion
        let navigationController = UINavigationController(rootViewController: viewController)
        FWRouter.present(navigationController, animated: true, completion: nil)
    }
}
