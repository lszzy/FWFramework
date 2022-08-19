//
//  Swizzle.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/19.
//

import Foundation
#if FWMacroSPM
import FWObjC
#endif

// MARK: - Swizzle
/// 方法交换类
///
/// 实现block必须返回一个block，返回的block将被当成originalSelector的新实现，所以要在内部自己处理对super的调用，以及对当前调用方法的self的class的保护判断（因为如果originalClass的originalSelector是继承自父类的，originalClass内部并没有重写这个方法，则我们这个函数最终重写的其实是父类的originalSelector，所以会产生预期之外的class的影响，例如originalClass传进来UIButton.class，则最终可能会影响到UIView.class）。block的参数里第一个为你要修改的class，也即等同于originalClass，第二个参数为你要修改的selector，也即等同于originalSelector，第三个参数是一个block，用于获取originalSelector原本的实现，由于IMP可以直接当成C函数调用，所以可利用它来实现“调用 super”的效果，但由于originalSelector的参数个数、参数类型、返回值类型，都会影响IMP的调用写法，所以这个调用只能由业务自己写
public class Swizzle {
    
    /// 通用swizzle替换方法为block实现，支持类和对象，identifier有值且相同时仅执行一次。复杂情况不会冲突，推荐使用
    /// - Parameters:
    ///   - target: 目标类或对象
    ///   - selector: 原始方法
    ///   - identifier: 唯一标识，有值且相同时仅执行一次
    ///   - block: 实现句柄
    /// - Returns: 是否成功
    @discardableResult
    public static func swizzleMethod(_ target: Any?, selector: Selector, identifier: String?, block: @escaping (AnyClass, Selector, @escaping () -> IMP) -> Any) -> Bool {
        guard let target = target else { return false }

        if object_isClass(target), let targetClass = target as? AnyClass {
            if let identifier = identifier, !identifier.isEmpty {
                return swizzleInstanceMethod(targetClass, selector: selector, identifier: identifier, block: block)
            } else {
                return swizzleInstanceMethod(targetClass, selector: selector, block: block)
            }
        } else {
            guard let objectClass = object_getClass(target) else { return false }
            let swizzleIdentifier = swizzleIdentifier(target, selector: selector, identifier: identifier ?? "")
            __Runtime.setPropertyPolicy(target, with: true, policy: .OBJC_ASSOCIATION_RETAIN_NONATOMIC, forName: swizzleIdentifier)
            return swizzleInstanceMethod(objectClass, selector: selector, identifier: identifier ?? "", block: block)
        }
    }
    
    /// 使用swizzle替换类实例方法为block实现。复杂情况不会冲突，推荐使用
    ///
    /// Swift实现代码示例：
    /// Swizzle.swizzleInstanceMethod(UIViewController.self, selector: NSSelectorFromString("viewDidLoad")) { targetClass, originalCMD, originalIMP in
    ///     let swizzleIMP: @convention(block)(UIViewController) -> Void = { selfObject in
    ///         typealias originalMSGType = @convention(c)(UIViewController, Selector) -> Void
    ///         let originalMSG: originalMSGType = unsafeBitCast(originalIMP(), to: originalMSGType.self)
    ///         originalMSG(selfObject, originalCMD)
    ///
    ///         // ...
    ///     }
    ///     return unsafeBitCast(swizzleIMP, to: AnyObject.self)
    /// }
    /// - Parameters:
    ///   - originalClass: 原始类
    ///   - selector: 原始方法
    ///   - block: 实现句柄
    /// - Returns: 是否成功
    @discardableResult
    public static func swizzleInstanceMethod(_ originalClass: AnyClass, selector: Selector, block: @escaping (AnyClass, Selector, @escaping () -> IMP) -> Any) -> Bool {
        return __Swizzle.swizzleInstanceMethod(originalClass, selector: selector, with: block)
    }
    
    /// 使用swizzle替换类静态方法为block实现。复杂情况不会冲突，推荐使用
    /// - Parameters:
    ///   - originalClass: 原始类
    ///   - selector: 原始方法
    ///   - block: 实现句柄
    /// - Returns: 是否成功
    @discardableResult
    public static func swizzleClassMethod(_ originalClass: AnyClass, selector: Selector, block: @escaping (AnyClass, Selector, @escaping () -> IMP) -> Any) -> Bool {
        guard let metaClass = object_getClass(originalClass) else { return false }
        return swizzleInstanceMethod(metaClass, selector: selector, block: block)
    }
    
    /// 使用swizzle替换类实例方法为block实现，identifier相同时仅执行一次。复杂情况不会冲突，推荐使用
    /// - Parameters:
    ///   - originalClass: 原始类
    ///   - selector: 原始方法
    ///   - identifier: 唯一标识
    ///   - block: 实现句柄
    /// - Returns: 是否成功
    @discardableResult
    public static func swizzleInstanceMethod(_ originalClass: AnyClass, selector: Selector, identifier: String, block: @escaping (AnyClass, Selector, @escaping () -> IMP) -> Any) -> Bool {
        return __Swizzle.swizzleInstanceMethod(originalClass, selector: selector, identifier: identifier, with: block)
    }

    /// 使用swizzle替换类静态方法为block实现，identifier相同时仅执行一次。复杂情况不会冲突，推荐使用
    /// - Parameters:
    ///   - originalClass: 原始类
    ///   - selector: 原始方法
    ///   - identifier: 唯一标识
    ///   - block: 实现句柄
    /// - Returns: 是否成功
    @discardableResult
    public static func swizzleClassMethod(_ originalClass: AnyClass, selector: Selector, identifier: String, block: @escaping (AnyClass, Selector, @escaping () -> IMP) -> Any) -> Bool {
        guard let metaClass = object_getClass(originalClass) else { return false }
        return __Swizzle.swizzleInstanceMethod(metaClass, selector: selector, identifier: identifier, with: block)
    }
    
    fileprivate static func swizzleIdentifier(_ object: Any, selector: Selector, identifier: String) -> String {
        var classIdentifier = ""
        if let objectClass = object_getClass(object) {
            classIdentifier = NSStringFromClass(objectClass)
        }
        return classIdentifier + "_" + NSStringFromSelector(selector) + "_" + identifier
    }
    
    // MARK: - Exchange
    /// 交换类实例方法。复杂情况可能会冲突
    /// - Parameters:
    ///   - originalClass: 原始类
    ///   - originalSelector: 原始方法
    ///   - swizzleSelector: 交换方法
    /// - Returns: 是否成功
    @discardableResult
    public static func exchangeInstanceMethod(_ originalClass: AnyClass, originalSelector: Selector, swizzleSelector: Selector) -> Bool {
        return __Swizzle.exchangeInstanceMethod(originalClass, originalSelector: originalSelector, swizzleSelector: swizzleSelector)
    }
    
    /// 交换类静态方法。复杂情况可能会冲突
    /// - Parameters:
    ///   - originalClass: 原始类
    ///   - originalSelector: 原始方法
    ///   - swizzleSelector: 交换方法
    /// - Returns: 是否成功
    @discardableResult
    public static func exchangeClassMethod(_ originalClass: AnyClass, originalSelector: Selector, swizzleSelector: Selector) -> Bool {
        guard let metaClass = object_getClass(originalClass) else { return false }
        return __Swizzle.exchangeInstanceMethod(metaClass, originalSelector: originalSelector, swizzleSelector: swizzleSelector)
    }
    
    /// 交换类实例方法为block实现。复杂情况可能会冲突
    ///
    /// swizzleBlock示例：^(__unsafe_unretained UIViewController *selfObject, BOOL animated){ ((void(*)(id, SEL, BOOL))objc_msgSend)(selfObject, swizzleSelector, animated); }
    /// - Parameters:
    ///   - originalClass: 原始类
    ///   - originalSelector: 原始方法
    ///   - swizzleSelector: 交换方法
    ///   - block: 实现block
    /// - Returns: 是否成功
    @discardableResult
    public static func exchangeInstanceMethod(_ originalClass: AnyClass, originalSelector: Selector, swizzleSelector: Selector, block: Any) -> Bool {
        return __Swizzle.exchangeInstanceMethod(originalClass, originalSelector: originalSelector, swizzleSelector: swizzleSelector, withBlock: block)
    }

    /// 交换类静态方法为block实现。复杂情况可能会冲突
    ///
    /// swizzleBlock示例：^(__unsafe_unretained Class selfClass, BOOL animated){ ((void(*)(id, SEL, BOOL))objc_msgSend)(selfClass, swizzleSelector, animated); }
    /// - Parameters:
    ///   - originalClass: 原始类
    ///   - originalSelector: 原始方法
    ///   - swizzleSelector: 交换方法
    ///   - block: 实现block
    /// - Returns: 是否成功
    @discardableResult
    public static func exchangeClassMethod(_ originalClass: AnyClass, originalSelector: Selector, swizzleSelector: Selector, block: Any) -> Bool {
        guard let metaClass = object_getClass(originalClass) else { return false }
        return __Swizzle.exchangeInstanceMethod(metaClass, originalSelector: originalSelector, swizzleSelector: swizzleSelector, withBlock: block)
    }
    
    /// 生成原始方法对应的随机交换方法
    /// - Parameter selector: 原始方法
    /// - Returns: 交换方法
    public static func exchangeSwizzleSelector(_ selector: Selector) -> Selector {
        return NSSelectorFromString("fw_swizzle_\(arc4random())_\(NSStringFromSelector(selector))")
    }
    
}

// MARK: - NSObject+Swizzle
extension Wrapper where Base: NSObject {
    
    /// 使用swizzle替换对象实例方法为block实现，identifier相同时仅执行一次。结合isSwizzleInstanceMethod使用
    /// - Parameters:
    ///   - originalSelector: 原始方法
    ///   - identifier: 唯一标识
    ///   - block: 实现句柄
    /// - Returns: 是否成功
    @discardableResult
    public func swizzleInstanceMethod(_ originalSelector: Selector, identifier: String, block: @escaping (AnyClass, Selector, @escaping () -> IMP) -> Any) -> Bool {
        guard let objectClass = object_getClass(base) else { return false }
        let swizzleIdentifier = Swizzle.swizzleIdentifier(base, selector: originalSelector, identifier: identifier)
        __Runtime.setPropertyPolicy(base, with: true, policy: .OBJC_ASSOCIATION_RETAIN_NONATOMIC, forName: swizzleIdentifier)
        return Swizzle.swizzleInstanceMethod(objectClass, selector: originalSelector, identifier: identifier, block: block)
    }
    
    /// 判断对象是否使用swizzle替换过指定identifier实例方法。结合swizzleInstanceMethod使用
    ///
    /// 因为实际替换的是类方法，为了防止影响该类其它对象，需先判断该对象是否替换过，仅替换过才执行自定义流程
    /// - Parameters:
    ///   - originalSelector: 原始方法
    ///   - identifier: 唯一标识
    /// - Returns: 是否替换
    public func isSwizzleInstanceMethod(_ originalSelector: Selector, identifier: String) -> Bool {
        let swizzleIdentifier = Swizzle.swizzleIdentifier(base, selector: originalSelector, identifier: identifier)
        return __Runtime.getProperty(base, forName: swizzleIdentifier) != nil
    }
    
}
