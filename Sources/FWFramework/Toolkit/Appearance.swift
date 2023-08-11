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
/// UIAppearance扩展类，支持任意NSObject对象使用UIAppearance能力
///
/// 系统默认时机是在didMoveToWindow处理UIAppearance
/// 注意：Swift只有标记\@objc dynamic的属性才支持UIAppearance
/// [QMUI_iOS](https://github.com/Tencent/QMUI_iOS)
public class Appearance: NSObject {
    
    private static var appearances: [String: Any] = [:]
    
    /// 获取指定 Class 的 appearance 对象，每个 Class 全局只会存在一个 appearance 对象
    public static func appearance(for aClass: AnyClass) -> Any {
        let className = NSStringFromClass(aClass)
        if let appearance = appearances[className] {
            return appearance
        }
        
        let appearance = ObjCBridge.appearance(for: aClass)
        appearances[className] = appearance
        return appearance
    }

    /// 获取指定 appearance 对象的关联 Class，通过解析_UIAppearance对象获取
    public static func `class`(for appearance: Any) -> AnyClass {
        return ObjCBridge.class(forAppearance: appearance)
    }
    
}

// MARK: - NSObject+Appearance
@_spi(FW) extension NSObject {
    
    /// 从 appearance 里取值并赋值给当前实例，通常在对象的 init 里调用。支持的属性需标记为\@objc dynamic才生效
    public func fw_applyAppearance() {
        ObjCBridge.applyAppearance(self)
    }
    
}
