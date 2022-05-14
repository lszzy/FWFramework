//
//  Swizzle.swift
//  FWFramework
//
//  Created by wuyong on 2022/5/12.
//

import UIKit

extension Wrapper where Base: NSObject {
    
    /// 使用swizzle替换对象实例方法为block实现，identifier相同时仅执行一次。结合isSwizzleInstanceMethod使用
    /// - Parameters:
    ///   - originalSelector: 原始方法
    ///   - identifier: 唯一标识
    ///   - block: 实现句柄
    /// - Returns: 是否成功
    @discardableResult
    public func swizzleInstanceMethod(_ originalSelector: Selector, identifier: String, block: @escaping (AnyClass, Selector, @escaping () -> IMP) -> Any) -> Bool {
        return base.__fw.swizzleInstanceMethod(originalSelector, identifier: identifier, with: block)
    }
    
    /// 判断对象是否使用swizzle替换过指定identifier实例方法。结合swizzleInstanceMethod使用
    ///
    /// 因为实际替换的是类方法，为了防止影响该类其它对象，需先判断该对象是否替换过，仅替换过才执行自定义流程
    /// - Parameters:
    ///   - originalSelector: 原始方法
    ///   - identifier: 唯一标识
    /// - Returns: 是否替换
    public func isSwizzleInstanceMethod(_ originalSelector: Selector, identifier: String) -> Bool {
        return base.__fw.isSwizzleInstanceMethod(originalSelector, identifier: identifier)
    }
    
    // MARK: - Runtime
    /// 安全调用方法，如果不能响应，则忽略之
    /// - Parameter selector: 要执行的方法
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    public func invokeMethod(_ selector: Selector) -> Any? {
        return base.__fw.invokeMethod(selector)
    }
    
    /// 安全调用方法，如果不能响应，则忽略之
    /// - Parameters:
    ///   - selector: 要执行的方法
    ///   - object: 传递的方法参数，非id类型可使用桥接，如int a = 1;(__bridge id)(void *)a
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    public func invokeMethod(_ selector: Selector, object: Any?) -> Any? {
        return base.__fw.invokeMethod(selector, with: object)
    }
    
    /// 对super发送消息
    /// - Parameter selector: 要执行的方法，需返回id类型
    /// - Returns: 方法执行后返回的值
    public func invokeSuperMethod(_ selector: Selector) -> Any? {
        return base.__fw.invokeSuperMethod(selector)
    }
    
    /// 对super发送消息，可传递参数
    /// - Parameters:
    ///   - selector: 要执行的方法，需返回id类型
    ///   - object: 传递的方法参数
    /// - Returns: 方法执行后返回的值
    public func invokeSuperMethod(_ selector: Selector, object: Any?) -> Any? {
        return base.__fw.invokeSuperMethod(selector, with: object)
    }
    
    /// 安全调用内部属性获取方法，如果属性不存在，则忽略之
    ///
    /// 如果iOS13系统UIView调用部分valueForKey:方法闪退，且没有好的替代方案，可尝试调用此方法
    /// - Parameter name: 内部属性名称
    /// - Returns: 属性值
    public func invokeGetter(_ name: String) -> Any? {
        return base.__fw.invokeGetter(name)
    }
    
    /// 安全调用内部属性设置方法，如果属性不存在，则忽略之
    ///
    /// 如果iOS13系统UIView调用部分valueForKey:方法闪退，且没有好的替代方案，可尝试调用此方法
    /// - Parameters:
    ///   - name: 内部属性名称
    ///   - object: 传递的方法参数
    /// - Returns: 方法执行后返回的值
    public func invokeSetter(_ name: String, object: Any?) -> Any? {
        return base.__fw.invokeSetter(name, with: object)
    }
    
    // MARK: - Property
    /// 临时对象，强引用，支持KVO
    ///
    /// 备注：key的几种形式的声明和使用，下同
    /// 1. 声明：static char kAssociatedObjectKey; 使用：&kAssociatedObjectKey
    /// 2. 声明：static void *kAssociatedObjectKey = &kAssociatedObjectKey; 使用：kAssociatedObjectKey
    /// 3. 声明和使用直接用getter方法的selector，如\@selector(xxx)、_cmd
    /// 4. 声明和使用直接用c字符串，如"kAssociatedObjectKey"
    public var tempObject: Any? {
        get { return base.__fw.tempObject }
        set { base.__fw.tempObject = newValue }
    }
    
    /// 读取关联属性
    /// - Parameter forName: 属性名称
    /// - Returns: 属性值
    public func property(forName: String) -> Any? {
        return base.__fw.property(forName:forName)
    }
    
    /// 设置强关联属性，支持KVO
    /// - Parameters:
    ///   - object: 属性值
    ///   - forName: 属性名称
    public func setProperty(_ object: Any?, forName: String) {
        base.__fw.setProperty(object, forName: forName)
    }
    
    /// 设置赋值关联属性，支持KVO，注意可能会产生野指针
    /// - Parameters:
    ///   - object: 属性值
    ///   - forName: 属性名称
    public func setPropertyAssign(_ object: Any?, forName: String) {
        base.__fw.setPropertyAssign(object, forName: forName)
    }
    
    /// 设置拷贝关联属性，支持KVO
    /// - Parameters:
    ///   - object: 属性值
    ///   - forName: 属性名称
    public func setPropertyCopy(_ object: Any?, forName: String) {
        base.__fw.setPropertyCopy(object, forName: forName)
    }
    
    /// 设置弱引用关联属性，支持KVO，OC不支持weak关联属性
    /// - Parameters:
    ///   - object: 属性值
    ///   - forName: 属性名称
    public func setPropertyWeak(_ object: Any?, forName: String) {
        base.__fw.setPropertyWeak(object, forName: forName)
    }
    
}
