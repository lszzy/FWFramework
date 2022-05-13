//
//  Block.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/29.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import UIKit
#if FWMacroSPM
import FWFramework
#endif

// MARK: - Block
/// 通用无参数block
public typealias BlockVoid = () -> ()

/// 通用Any参数block
public typealias BlockParam = (Any?) -> ()

/// 通用Bool参数block
public typealias BlockBool = (Bool) -> ()

/// 通用Int参数block
public typealias BlockInt = (Int) -> ()

/// 通用Double参数block
public typealias BlockDouble = (Double) -> ()

/// 通用(Bool, Any)参数block
public typealias BlockBoolParam = (Bool, Any?) -> ()

// MARK: UIBarButtonItem+Block
extension Wrapper where Base: UIBarButtonItem {
    
    /// 使用指定对象和事件创建Item，支持UIImage|NSString|NSNumber|NSAttributedString等
    public static func item(object: Any?, target: Any?, action: Selector?) -> UIBarButtonItem {
        return UIBarButtonItem.__fw.item(with: object, target: target, action: action)
    }

    /// 使用指定对象和句柄创建Item，支持UIImage|NSString|NSNumber|NSAttributedString等
    public static func item(object: Any?, block: ((Any) -> Void)?) -> UIBarButtonItem {
        return UIBarButtonItem.__fw.item(with: object, block: block)
    }
    
}
