//
//  Runtime.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

import Foundation

/// 运行时类
@objcMembers
public class Runtime: NSObject {
    
    private static var classCaches: [String: [String]] = [:]
    
}

// MARK: - Public
extension Runtime {
    
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
    
}

// MARK: - Private
extension Runtime {
    
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
