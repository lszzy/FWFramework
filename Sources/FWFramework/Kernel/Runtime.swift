//
//  Runtime.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

import Foundation
#if FWMacroSPM
import FWObjC
#endif

// MARK: - Runtime
/// 运行时类
public class Runtime {
    
    private static var classCaches: [String: [String]] = [:]
    
    fileprivate struct AssociatedKeys {
        static var tempObject = "tempObject"
        static var boundObjects = "boundObjects"
    }
    
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
        return __Runtime.getProperty(base, forName: forName)
    }
    
    /// 设置强关联属性，支持KVO
    /// - Parameters:
    ///   - object: 属性值
    ///   - forName: 属性名称
    public func setProperty(_ object: Any?, forName: String) {
        __Runtime.setPropertyPolicy(base, with: object, policy: .OBJC_ASSOCIATION_RETAIN_NONATOMIC, forName: forName)
    }
    
    /// 设置赋值关联属性，支持KVO，注意可能会产生野指针
    /// - Parameters:
    ///   - object: 属性值
    ///   - forName: 属性名称
    public func setPropertyAssign(_ object: Any?, forName: String) {
        __Runtime.setPropertyPolicy(base, with: object, policy: .OBJC_ASSOCIATION_ASSIGN, forName: forName)
    }
    
    /// 设置拷贝关联属性，支持KVO
    /// - Parameters:
    ///   - object: 属性值
    ///   - forName: 属性名称
    public func setPropertyCopy(_ object: Any?, forName: String) {
        __Runtime.setPropertyPolicy(base, with: object, policy: .OBJC_ASSOCIATION_COPY_NONATOMIC, forName: forName)
    }
    
    /// 设置弱引用关联属性，支持KVO，OC不支持weak关联属性
    /// - Parameters:
    ///   - object: 属性值
    ///   - forName: 属性名称
    public func setPropertyWeak(_ object: Any?, forName: String) {
        __Runtime.setPropertyWeak(base, with: object, forName: forName)
    }
    
    // MARK: - Method
    /// 安全调用方法，如果不能响应，则忽略之
    /// - Parameter selector: 要执行的方法
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    @discardableResult
    public func invokeMethod(_ selector: Selector) -> Any? {
        return __Runtime.invokeMethod(base, selector: selector)
    }
    
    /// 安全调用方法，如果不能响应，则忽略之
    /// - Parameters:
    ///   - selector: 要执行的方法
    ///   - object: 传递的方法参数，非id类型可使用桥接，如int a = 1;(__bridge id)(void *)a
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    @discardableResult
    public func invokeMethod(_ selector: Selector, object: Any?) -> Any? {
        return __Runtime.invokeMethod(base, selector: selector, object: object)
    }
    
    /// 安全调用方法，支持多个参数
    /// - Parameters:
    ///   - selector: 要执行的方法
    ///   - objects: 传递的参数数组
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    @discardableResult
    public func invokeMethod(_ selector: Selector, objects: [Any]) -> Any? {
        return __Runtime.invokeMethod(base, selector: selector, objects: objects)
    }
    
    /// 安全调用内部属性获取方法，如果属性不存在，则忽略之
    ///
    /// 如果iOS13系统UIView调用部分valueForKey:方法闪退，且没有好的替代方案，可尝试调用此方法
    /// - Parameter name: 内部属性名称
    /// - Returns: 属性值
    public func invokeGetter(_ name: String) -> Any? {
        return __Runtime.invokeGetter(base, name: name)
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
        return __Runtime.invokeSetter(base, name: name, object: object)
    }
    
    // MARK: - Bind
    /// 临时对象，强引用，支持KVO
    public var tempObject: Any? {
        get { return objc_getAssociatedObject(base, &Runtime.AssociatedKeys.tempObject) }
        set { objc_setAssociatedObject(base, &Runtime.AssociatedKeys.tempObject, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    /// 给对象绑定上另一个对象以供后续取出使用，如果 object 传入 nil 则会清除该 key 之前绑定的对象
    /// - Parameters:
    ///   - object: 对象，会被 strong 强引用
    ///   - forKey: 键名
    public func bindObject(_ object: Any?, forKey: String) {
        if let object = object {
            allBoundObjects.setObject(object, forKey: forKey as NSString)
        } else {
            allBoundObjects.removeObject(forKey: forKey)
        }
    }
    
    /// 给对象绑定上另一个弱引用对象以供后续取出使用，如果 object 传入 nil 则会清除该 key 之前绑定的对象
    /// - Parameters:
    ///   - object: 对象，不会被 strong 强引用
    ///   - forKey: 键名
    public func bindObjectWeak(_ object: Any?, forKey: String) {
        if let object = object {
            allBoundObjects.setObject(__WeakObject(object: object), forKey: forKey as NSString)
        } else {
            allBoundObjects.removeObject(forKey: forKey)
        }
    }
    
    /// 取出之前使用 bind 方法绑定的对象
    /// - Parameter forKey: 键名
    /// - Returns: 绑定的对象
    public func boundObject(forKey: String) -> Any? {
        let object = allBoundObjects.object(forKey: forKey)
        if let weakObject = object as? __WeakObject {
            return weakObject.object
        }
        return object
    }
    
    /// 给对象绑定上一个 double 值以供后续取出使用
    /// - Parameters:
    ///   - value: double值
    ///   - forKey: 键名
    public func bindDouble(_ value: Double, forKey: String) {
        bindObject(NSNumber(value: value), forKey: forKey)
    }
    
    /// 取出之前用 bindDouble:forKey: 绑定的值
    /// - Parameter forKey: 键名
    /// - Returns: 绑定的值
    public func boundDouble(forKey: String) -> Double {
        if let number = boundObject(forKey: forKey) as? NSNumber {
            return number.doubleValue
        }
        return .zero
    }

    /// 给对象绑定上一个 BOOL 值以供后续取出使用
    /// - Parameters:
    ///   - value: 布尔值
    ///   - forKey: 键名
    public func bindBool(_ value: Bool, forKey: String) {
        bindObject(NSNumber(value: value), forKey: forKey)
    }
    
    /// 取出之前用 bindBool:forKey: 绑定的值
    /// - Parameter forKey: 键名
    /// - Returns: 绑定的值
    public func boundBool(forKey: String) -> Bool {
        if let number = boundObject(forKey: forKey) as? NSNumber {
            return number.boolValue
        }
        return false
    }

    /// 给对象绑定上一个 NSInteger 值以供后续取出使用
    /// - Parameters:
    ///   - value: 整数值
    ///   - forKey: 键名
    public func bindInt(_ value: Int, forKey: String) {
        bindObject(NSNumber(value: value), forKey: forKey)
    }
    
    /// 取出之前用 bindInt:forKey: 绑定的值
    /// - Parameter forKey: 键名
    /// - Returns: 绑定的值
    public func boundInt(forKey: String) -> Int {
        if let number = boundObject(forKey: forKey) as? NSNumber {
            return number.intValue
        }
        return .zero
    }
    
    /// 移除之前使用 bind 方法绑定的对象
    /// - Parameter forKey: 键名
    public func removeBinding(forKey: String) {
        allBoundObjects.removeObject(forKey: forKey)
    }
    
    /// 移除之前使用 bind 方法绑定的所有对象
    public func removeAllBindings() {
        allBoundObjects.removeAllObjects()
    }

    /// 返回当前有绑定对象存在的所有的 key 的数组，数组中元素的顺序是随机的，如果不存在任何 key，则返回一个空数组
    public func allBindingKeys() -> [String] {
        return allBoundObjects.allKeys as? [String] ?? []
    }
    
    /// 返回是否设置了某个 key
    /// - Parameter key: 键名
    /// - Returns: 是否绑定
    public func hasBindingKey(_ key: String) -> Bool {
        return allBindingKeys().contains(key)
    }
    
    private var allBoundObjects: NSMutableDictionary {
        if let boundObjects = objc_getAssociatedObject(base, &Runtime.AssociatedKeys.boundObjects) as? NSMutableDictionary {
            return boundObjects
        }
        
        let boundObjects = NSMutableDictionary()
        objc_setAssociatedObject(base, &Runtime.AssociatedKeys.boundObjects, boundObjects, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return boundObjects
    }
    
}
