//
//  UIAlertController+FWFramework.swift
//  FWFramework
//
//  Created by wuyong on 2020/4/25.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import Foundation

/// UIAlertAction链式调用扩展
extension UIAlertAction {
    /// 快捷设置首选动作
    @discardableResult
    public func fwPreferred(_ preferred: Bool) -> UIAlertAction {
        self.fwIsPreferred = preferred;
        return self;
    }
    
    /// 快捷设置是否禁用
    @discardableResult
    public func fwEnabled(_ enabled: Bool) -> UIAlertAction {
        self.isEnabled = enabled
        return self
    }
    
    /// 快捷设置标题颜色
    @discardableResult
    public func fwColor(_ color: UIColor?) -> UIAlertAction {
        self.fwTitleColor = color
        return self
    }
}
