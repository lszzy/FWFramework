//
//  Configuration.swift
//  FWFramework
//
//  Created by wuyong on 2022/6/10.
//

import Foundation
#if FWMacroSPM
import FWFramework
#endif

// MARK: - Configuration
extension Configuration {
    
    /// 单例模式对象
    public class var shared: Self {
        return Self.__sharedInstance()
    }
    
}
