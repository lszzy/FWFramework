//
//  UIViewController+FWAlert.swift
//  FWFramework
//
//  Created by wuyong on 2020/4/22.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import Foundation

/// UIAlertAction链式调用扩展
extension UIAlertAction {
    /// 快捷设置首选行为
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
}
