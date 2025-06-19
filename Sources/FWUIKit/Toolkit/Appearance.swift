//
//  Appearance.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - Wrapper+NSObject
extension Wrapper where Base: NSObject {
    /// 从 appearance 里取值并赋值给当前实例，通常在对象的 init 里调用。支持的属性需标记为\@objc dynamic才生效
    public func applyAppearance() {
        let aClass: AnyClass = type(of: base)
        guard aClass.responds(to: NSSelectorFromString("appearance")) else { return }

        let appearanceGuideClassSelector = NSSelectorFromString(String(format: "%@%@%@", "_a", "ppearanceG", "uideClass"))
        if !class_respondsToSelector(aClass, appearanceGuideClassSelector) {
            let typeEncoding = method_getTypeEncoding(class_getInstanceMethod(UIView.self, appearanceGuideClassSelector)!)
            let impBlock: @convention(block) () -> AnyClass? = { nil }
            class_addMethod(aClass, appearanceGuideClassSelector, imp_implementationWithBlock(impBlock), typeEncoding)
        }

        let selector = NSSelectorFromString(String(format: "_%@:%@:", "applyInvocationsTo", "window"))
        if let appearanceClass = NSClassFromString(String(format: "%@%@%@", "_U", "IAppea", "rance")),
           appearanceClass.responds(to: selector) {
            _ = (appearanceClass as AnyObject).perform(selector, with: base, with: nil)
        }
    }
}

// MARK: - Appearance
/// UIAppearance扩展类，支持任意NSObject对象使用UIAppearance能力
///
/// 系统默认时机是在didMoveToWindow处理UIAppearance
/// 注意：Swift只有标记\@objc dynamic的属性才支持UIAppearance
/// [QMUI_iOS](https://github.com/Tencent/QMUI_iOS)
public class Appearance {
    /// 获取指定 Class 的 appearance 对象，每个 Class 全局只会存在一个 appearance 对象
    public static func appearance(for aClass: AnyClass) -> AnyObject? {
        let className = NSStringFromClass(aClass)
        if let appearance = FrameworkConfiguration.classAppearances[className] {
            return appearance
        }

        let selector = NSSelectorFromString(String(format: "_%@:%@:", "appearanceForClass", "withContainerList"))
        guard let appearanceClass = NSClassFromString(String(format: "%@%@%@", "_U", "IAppea", "rance")),
              appearanceClass.responds(to: selector),
              let appearance = (appearanceClass as AnyObject).perform(selector, with: aClass, with: nil)?.takeUnretainedValue() else {
            return nil
        }

        FrameworkConfiguration.classAppearances[className] = appearance
        return appearance
    }

    /// 获取指定 appearance 对象的关联 Class，通过解析_UIAppearance对象获取
    public static func `class`(for appearance: AnyObject) -> AnyClass {
        var selector = NSSelectorFromString(String(format: "_%@%@", "customizable", "ClassInfo"))
        guard appearance.responds(to: selector) else {
            return type(of: appearance)
        }

        let classInfo = appearance.perform(selector)?.takeUnretainedValue() as? AnyObject
        selector = NSSelectorFromString(String(format: "_%@%@", "customizable", "ViewClass"))
        guard let classInfo, classInfo.responds(to: selector) else {
            return type(of: appearance)
        }

        let viewClass: AnyClass? = classInfo.perform(selector)?.takeUnretainedValue() as? AnyClass
        if let viewClass, object_isClass(viewClass) {
            return viewClass
        }
        return type(of: appearance)
    }
}

// MARK: - FrameworkConfiguration+Appearance
extension FrameworkConfiguration {
    fileprivate static var classAppearances: [String: AnyObject] = [:]
}
