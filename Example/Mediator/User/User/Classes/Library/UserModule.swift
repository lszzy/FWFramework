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
    
    @FWUserDefaultAnnotation("userId", defaultValue: "")
    private var userId: String
    
    public static func sharedInstance() -> Self {
        return sharedModule as! Self
    }
    
    public func setup() {
        FWLogDebug(#function)
    }
    
    public func isLogin() -> Bool {
        return userId.count > 0
    }
    
    public func login(_ completion: (() -> Void)?) {
        let viewController = UserLoginController()
        viewController.completion = { [weak self] in
            self?.userId = "1"
            completion?()
        }
        let navigationController = UINavigationController(rootViewController: viewController)
        FWRouter.present(navigationController, animated: true, completion: nil)
    }
    
    public func logout(_ completion: (() -> Void)?) {
        userId = ""
        completion?()
    }
}
