//
//  FWSwizzle.swift
//  FWFramework
//
//  Created by wuyong on 2022/5/12.
//

import UIKit

extension WrapperExtension where Base: NSObject {
    /// 临时对象，强引用
    public var tempObject: Any? {
        get {
            return self.base.__fw_tempObject
        }
        set {
            self.base.__fw_tempObject = newValue
        }
    }
}
