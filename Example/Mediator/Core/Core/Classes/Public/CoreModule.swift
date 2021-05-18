//
//  CoreModule.swift
//  Core
//
//  Created by wuyong on 2021/1/1.
//

import FWFramework

@objcMembers public class CoreBundle: FWModuleBundle {
    private static let sharedBundle: Bundle = {
        return Bundle.fwBundle(with: CoreBundle.classForCoder(), name: "Core")?.fwLocalized() ?? .main
    }()
    
    public override class func bundle() -> Bundle {
        return sharedBundle
    }
}

@objc protocol CoreService: FWModuleProtocol {}

class CoreModule: NSObject, CoreService {
    private static let sharedModule = CoreModule()
    
    static func sharedInstance() -> Self {
        return sharedModule as! Self
    }
    
    static func priority() -> UInt {
        return FWModulePriorityDefault + 1
    }
    
    static func setupSynchronously() -> Bool {
        return true
    }
    
    func setup() {
        Theme.setupTheme()
    }
}

@objc extension FWLoader {
    func loadCoreModule() {
        FWMediator.registerService(CoreService.self, withModule: CoreModule.self)
    }
}
