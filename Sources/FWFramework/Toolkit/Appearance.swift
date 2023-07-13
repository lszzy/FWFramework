//
//  Appearance.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

// MARK: - Appearance
/// UIAppearance扩展协议，配合applyAppearance使用
///
/// 注意：属性必须标记为\@objc和dynamic才生效
public protocol AppearanceProtocol {
    
    /// 初始化默认UIAppearance，调用applyAppearance时自动触发
    static func setDefaultAppearance()
    
}

/// UIAppearance扩展类，支持任意NSObject对象使用UIAppearance能力
///
/// 系统默认时机是在didMoveToWindow处理UIAppearance
/// [QMUI_iOS](https://github.com/Tencent/QMUI_iOS)
public class Appearance: NSObject {
    
    private static var appearances: [String: Any] = [:]
    
    /// 获取指定 Class 的 appearance 对象，每个 Class 全局只会存在一个 appearance 对象
    public static func appearance(for aClass: AnyClass) -> Any {
        let className = NSStringFromClass(aClass)
        if let appearance = appearances[className] {
            return appearance
        }
        
        let appearance = __FWRuntime.appearance(for: aClass)
        appearances[className] = appearance
        return appearance
    }

    /// 获取指定 appearance 对象的关联 Class，通过解析_UIAppearance对象获取
    public static func `class`(for appearance: Any) -> AnyClass {
        return __FWRuntime.class(forAppearance: appearance)
    }
    
}

// MARK: - NSObject+Appearance
@_spi(FW) extension NSObject {
    
    /// 从 appearance 里取值并赋值给当前实例，通常在对象的 init 里调用，自动触发setDefaultAppearance
    public func fw_applyAppearance() {
        if let appearanceClass = classForCoder as? AppearanceProtocol.Type,
           __FWRuntime.getProperty(classForCoder, forName: "fw_applyAppearance") == nil {
            __FWRuntime.setPropertyPolicy(classForCoder, with: NSNumber(value: true), policy: .OBJC_ASSOCIATION_RETAIN_NONATOMIC, forName: "fw_applyAppearance")
            
            appearanceClass.setDefaultAppearance()
        }
        
        __FWRuntime.applyAppearance(self)
    }
    
}
