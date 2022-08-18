//
//  AppTheme.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/5/10.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

public typealias APP = FW

extension WrapperCompatible {
    public static var app: Wrapper<Self>.Type { get { fw } set {} }
    public var app: Wrapper<Self> { get { fw } set {} }
}

class AppTheme {
    
}
