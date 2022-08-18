//
//  Runtime.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

import Foundation

// MARK: - Runtime
/// 运行时类
public class Runtime {
    
    private static var classCaches: [String: [String]] = [:]
    
    // MARK: - Public
    /// 获取类方法列表，支持meta类(objc_getMetaClass)
    /// - Parameters:
    ///   - clazz: 指定类
    ///   - superclass: 是否包含父类，包含则递归到NSObject，默认false
    /// - Returns: 方法列表
    public static func classMethods(_ clazz: AnyClass, superclass: Bool = false) -> [String] {
        let cacheKey = classCacheKey(clazz, superclass: superclass, type: "M")
        if let cacheNames = classCaches[cacheKey] {
            return cacheNames
        }
        
        var resultNames: [String] = []
        var targetClass: AnyClass? = clazz
        while targetClass != nil {
            var resultCount: UInt32 = 0
            let methodList = class_copyMethodList(targetClass, &resultCount)
            for i in 0 ..< Int(resultCount) {
                if let method = methodList?[i],
                   let resultName = String(utf8String: sel_getName(method_getName(method))),
                   !resultName.isEmpty,
                   !resultNames.contains(resultName) {
                    resultNames.append(resultName)
                }
            }
            free(methodList)
            
            targetClass = superclass ? class_getSuperclass(targetClass) : nil
            if targetClass == nil || targetClass == NSObject.classForCoder() {
                break
            }
        }
        
        classCaches[cacheKey] = resultNames
        return resultNames
    }
    
    /// 获取类属性列表，支持meta类(objc_getMetaClass)
    /// - Parameters:
    ///   - clazz: 指定类
    ///   - superclass: 是否包含父类，包含则递归到NSObject，默认false
    /// - Returns: 属性列表
    public static func classProperties(_ clazz: AnyClass, superclass: Bool = false) -> [String] {
        let cacheKey = classCacheKey(clazz, superclass: superclass, type: "P")
        if let cacheNames = classCaches[cacheKey] {
            return cacheNames
        }
        
        var resultNames: [String] = []
        var targetClass: AnyClass? = clazz
        while targetClass != nil {
            var resultCount: UInt32 = 0
            let propertyList = class_copyPropertyList(targetClass, &resultCount)
            for i in 0 ..< Int(resultCount) {
                if let property = propertyList?[i],
                   let resultName = String(utf8String: property_getName(property)),
                   !resultName.isEmpty,
                   !resultNames.contains(resultName) {
                    resultNames.append(resultName)
                }
            }
            free(propertyList)
            
            targetClass = superclass ? class_getSuperclass(targetClass) : nil
            if targetClass == nil || targetClass == NSObject.classForCoder() {
                break
            }
        }
        
        classCaches[cacheKey] = resultNames
        return resultNames
    }
    
    /// 获取类Ivar列表，支持meta类(objc_getMetaClass)
    /// - Parameters:
    ///   - clazz: 指定类
    ///   - superclass: 是否包含父类，包含则递归到NSObject，默认false
    /// - Returns: Ivar列表
    public static func classIvars(_ clazz: AnyClass, superclass: Bool = false) -> [String] {
        let cacheKey = classCacheKey(clazz, superclass: superclass, type: "V")
        if let cacheNames = classCaches[cacheKey] {
            return cacheNames
        }
        
        var resultNames: [String] = []
        var targetClass: AnyClass? = clazz
        while targetClass != nil {
            var resultCount: UInt32 = 0
            let ivarList = class_copyIvarList(targetClass, &resultCount)
            for i in 0 ..< Int(resultCount) {
                if let ivar = ivarList?[i],
                   let ivarName = ivar_getName(ivar),
                   let resultName = String(utf8String: ivarName),
                   !resultName.isEmpty,
                   !resultNames.contains(resultName) {
                    resultNames.append(resultName)
                }
            }
            free(ivarList)
            
            targetClass = superclass ? class_getSuperclass(targetClass) : nil
            if targetClass == nil || targetClass == NSObject.classForCoder() {
                break
            }
        }
        
        classCaches[cacheKey] = resultNames
        return resultNames
    }
    
    // MARK: - Private
    private static func classCacheKey(
        _ clazz: AnyClass,
        superclass: Bool,
        type: String
    ) -> String {
        let cacheKey = NSStringFromClass(clazz) + "."
            + (class_isMetaClass(clazz) ? "M" : "C")
            + (superclass ? "S" : "C") + type
        return cacheKey
    }
    
}

// MARK: - NSObject+Runtime
extension Wrapper where Base: NSObject {
    
    // MARK: - Property
    /// 读取关联属性
    /// - Parameter forName: 属性名称
    /// - Returns: 属性值
    public func property(forName: String) -> Any? {
        return base.__property(forName: forName)
    }
    
    /// 设置强关联属性，支持KVO
    /// - Parameters:
    ///   - object: 属性值
    ///   - forName: 属性名称
    public func setProperty(_ object: Any?, forName: String) {
        base.__setProperty(object, forName: forName)
    }
    
    /// 设置赋值关联属性，支持KVO，注意可能会产生野指针
    /// - Parameters:
    ///   - object: 属性值
    ///   - forName: 属性名称
    public func setPropertyAssign(_ object: Any?, forName: String) {
        base.__setPropertyAssign(object, forName: forName)
    }
    
    /// 设置拷贝关联属性，支持KVO
    /// - Parameters:
    ///   - object: 属性值
    ///   - forName: 属性名称
    public func setPropertyCopy(_ object: Any?, forName: String) {
        base.__setPropertyCopy(object, forName: forName)
    }
    
    /// 设置弱引用关联属性，支持KVO，OC不支持weak关联属性
    /// - Parameters:
    ///   - object: 属性值
    ///   - forName: 属性名称
    public func setPropertyWeak(_ object: Any?, forName: String) {
        base.__setPropertyWeak(object, forName: forName)
    }
    
    // MARK: - Method
    /// 安全调用方法，如果不能响应，则忽略之
    /// - Parameter selector: 要执行的方法
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    @discardableResult
    public func invokeMethod(_ selector: Selector) -> Any? {
        return base.__invokeMethod(selector)
    }
    
    /// 安全调用方法，如果不能响应，则忽略之
    /// - Parameters:
    ///   - selector: 要执行的方法
    ///   - object: 传递的方法参数，非id类型可使用桥接，如int a = 1;(__bridge id)(void *)a
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    @discardableResult
    public func invokeMethod(_ selector: Selector, object: Any?) -> Any? {
        return base.__invokeMethod(selector, with: object)
    }
    
    /// 安全调用方法，支持多个参数
    /// - Parameters:
    ///   - selector: 要执行的方法
    ///   - objects: 传递的参数数组
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    @discardableResult
    public func invokeMethod(_ selector: Selector, objects: [Any]) -> Any? {
        return base.__invokeMethod(selector, objects: objects)
    }
    
    /// 安全调用内部属性获取方法，如果属性不存在，则忽略之
    ///
    /// 如果iOS13系统UIView调用部分valueForKey:方法闪退，且没有好的替代方案，可尝试调用此方法
    /// - Parameter name: 内部属性名称
    /// - Returns: 属性值
    public func invokeGetter(_ name: String) -> Any? {
        return base.__invokeGetter(name)
    }
    
    /// 安全调用内部属性设置方法，如果属性不存在，则忽略之
    ///
    /// 如果iOS13系统UIView调用部分valueForKey:方法闪退，且没有好的替代方案，可尝试调用此方法
    /// - Parameters:
    ///   - name: 内部属性名称
    ///   - object: 传递的方法参数
    /// - Returns: 方法执行后返回的值
    @discardableResult
    public func invokeSetter(_ name: String, object: Any?) -> Any? {
        return base.__invokeSetter(name, with: object)
    }
    
}
