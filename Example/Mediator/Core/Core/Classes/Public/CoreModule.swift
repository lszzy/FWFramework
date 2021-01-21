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
