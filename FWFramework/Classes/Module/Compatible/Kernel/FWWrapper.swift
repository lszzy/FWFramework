//
//  FWWrapper.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/29.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation
#if FWFrameworkSPM
import FWFramework
#endif

/// String实现包装器对象协议
extension String {
    
    /// 对象包装器
    public var fw: FWStringWrapper {
        return FWStringWrapper(base: self as NSString)
    }
    
}
