//
//  FWBlock.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/29.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import UIKit
#if FWFrameworkSPM
import FWFramework
#endif

// MARK: - FWBlock

/// 通用无参数block
public typealias FWBlockVoid = () -> ()

/// 通用Any参数block
public typealias FWBlockParam = (Any?) -> ()

/// 通用Bool参数block
public typealias FWBlockBool = (Bool) -> ()

/// 通用Int参数block
public typealias FWBlockInt = (Int) -> ()

/// 通用Double参数block
public typealias FWBlockDouble = (Double) -> ()

/// 通用(Bool, Any)参数block
public typealias FWBlockBoolParam = (Bool, Any?) -> ()
