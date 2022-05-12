//
//  AppTheme.swift
//  Example
//
//  Created by wuyong on 2022/5/12.
//  Copyright © 2022 site.wuyong. All rights reserved.
//

import FWFramework

public typealias APP = FWWrapper

extension FWWrapperExtended {
    public static var app: FWWrapperExtension<Self>.Type { get { fw } set {} }
    public var app: FWWrapperExtension<Self> { get { fw } set {} }
}

class AppTheme {
    
}
