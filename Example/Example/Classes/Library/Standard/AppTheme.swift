//
//  AppTheme.swift
//  Example
//
//  Created by wuyong on 2022/5/12.
//  Copyright © 2022 site.wuyong. All rights reserved.
//

import FWFramework

public typealias APP = FW

extension WrapperCompatible {
    public static var app: Wrapper<Self>.Type { get { fw } set {} }
    public var app: Wrapper<Self> { get { fw } set {} }
}

class AppTheme {
    
}
