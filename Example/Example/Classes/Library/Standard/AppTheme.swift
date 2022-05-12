//
//  AppTheme.swift
//  Example
//
//  Created by wuyong on 2022/5/12.
//  Copyright © 2022 site.wuyong. All rights reserved.
//

import FWFramework

public typealias APP = Wrapper

extension WrapperExtended {
    
    public static var app: WrapperExtension<Self>.Type { get { fw } set {} }
    public var app: WrapperExtension<Self> { get { fw } set {} }
    
}

class AppTheme {
    
}
