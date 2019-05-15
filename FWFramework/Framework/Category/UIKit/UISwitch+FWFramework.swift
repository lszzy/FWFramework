//
//  UISwitch+FWFramework.swift
//  FWFramework
//
//  Created by wuyong on 2019/5/15.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import UIKit

// MARK: - UISwitch+FWFramework
@objc extension UISwitch {
    
    /// 切换开关状态
    public func fwToggle() {
        self.setOn(!self.isOn, animated: true)
    }
}
