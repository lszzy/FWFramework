//
//  Appearance+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

// MARK: - NSObject+Appearance
extension Wrapper where Base: NSObject {
    
    /// 从 appearance 里取值并赋值给当前实例，通常在对象的 init 里调用。支持的属性需标记为\@objc dynamic才生效
    public func applyAppearance() {
        base.fw_applyAppearance()
    }
    
}
