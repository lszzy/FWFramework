//
//  Appearance.swift
//  FWFramework
//
//  Created by wuyong on 2022/5/16.
//

import UIKit

extension Wrapper where Base: NSObject {
    
    /// 从 appearance 里取值并赋值给当前实例，通常在对象的 init 里调用
    public func applyAppearance() {
        base.__fw.applyAppearance()
    }
    
}
