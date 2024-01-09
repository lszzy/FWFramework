//
//  Autoloader+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/30.
//

import Foundation

extension WrapperGlobal {
    
    /// 自动加载Swift类并调用autoload方法，参数为Class或String
    @discardableResult
    public static func autoload(_ clazz: Any) -> Bool {
        return Autoloader.autoload(clazz)
    }
    
}
