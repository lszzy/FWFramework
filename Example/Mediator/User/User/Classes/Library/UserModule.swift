//
//  UserModule.swift
//  User
//
//  Created by wuyong on 2021/1/1.
//

import FWFramework
import Mediator

@objcMembers public class UserBundle: FWModuleBundle {
    private static let sharedBundle: Bundle = {
        return Bundle.fwBundle(with: UserBundle.classForCoder(), name: "User")?.fwLocalized() ?? .main
    }()
    
    public override class func bundle() -> Bundle {
        return sharedBundle
    }
}

@objcMembers public class UserModule: NSObject, UserModuleService {
    private static let sharedModule = UserModule()
    
    public static func sharedInstance() -> Self {
        return sharedModule as! Self
    }
    
    public func setup() {
        FWLogDebug(#function)
    }
    
    public func login(_ completion: (() -> Void)?) {
        let viewController = UserLoginController()
        viewController.completion = completion
        let navigationController = UINavigationController(rootViewController: viewController)
        FWRouter.present(navigationController, animated: true, completion: nil)
    }
}
