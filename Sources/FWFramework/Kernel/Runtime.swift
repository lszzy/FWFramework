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

// MARK: - NSObject+Runtime
@_spi(FW) @objc extension NSObject {
    
    // MARK: - Class
    /// 获取类方法列表，支持meta类(objc_getMetaClass)
    /// - Parameters:
    ///   - clazz: 指定类
    ///   - superclass: 是否包含父类，包含则递归到NSObject，默认false
    /// - Returns: 方法列表
    public static func fw_classMethods(_ clazz: AnyClass, superclass: Bool = false) -> [String] {
        let cacheKey = fw_classCacheKey(clazz, superclass: superclass, type: "M")
        if let cacheNames = NSObject.fw_classCaches[cacheKey] {
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
        
        NSObject.fw_classCaches[cacheKey] = resultNames
        return resultNames
    }
    
    /// 获取类属性列表，支持meta类(objc_getMetaClass)
    /// - Parameters:
    ///   - clazz: 指定类
    ///   - superclass: 是否包含父类，包含则递归到NSObject，默认false
    /// - Returns: 属性列表
    public static func fw_classProperties(_ clazz: AnyClass, superclass: Bool = false) -> [String] {
        let cacheKey = fw_classCacheKey(clazz, superclass: superclass, type: "P")
        if let cacheNames = NSObject.fw_classCaches[cacheKey] {
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
        
        NSObject.fw_classCaches[cacheKey] = resultNames
        return resultNames
    }
    
    /// 获取类Ivar列表，支持meta类(objc_getMetaClass)
    /// - Parameters:
    ///   - clazz: 指定类
    ///   - superclass: 是否包含父类，包含则递归到NSObject，默认false
    /// - Returns: Ivar列表
    public static func fw_classIvars(_ clazz: AnyClass, superclass: Bool = false) -> [String] {
        let cacheKey = fw_classCacheKey(clazz, superclass: superclass, type: "V")
        if let cacheNames = NSObject.fw_classCaches[cacheKey] {
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
        
        NSObject.fw_classCaches[cacheKey] = resultNames
        return resultNames
    }
    
    private static func fw_classCacheKey(
        _ clazz: AnyClass,
        superclass: Bool,
        type: String
    ) -> String {
        let cacheKey = NSStringFromClass(clazz) + "."
            + (class_isMetaClass(clazz) ? "M" : "C")
            + (superclass ? "S" : "C") + type
        return cacheKey
    }
    
    private static var fw_classCaches: [String: [String]] = [:]
    
    // MARK: - Runtime
    /// 安全调用方法，如果不能响应，则忽略之
    /// - Parameter selector: 要执行的方法
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    @discardableResult
    public func fw_invokeMethod(_ selector: Selector) -> Any? {
        return __FWRuntime.invokeMethod(self, selector: selector)
    }
    
    /// 安全调用方法，如果不能响应，则忽略之
    /// - Parameters:
    ///   - selector: 要执行的方法
    ///   - object: 传递的方法参数，非id类型可使用桥接，如int a = 1;(__bridge id)(void *)a
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    @discardableResult
    public func fw_invokeMethod(_ selector: Selector, object: Any?) -> Any? {
        return __FWRuntime.invokeMethod(self, selector: selector, object: object)
    }
    
    /// 安全调用方法，支持多个参数
    /// - Parameters:
    ///   - selector: 要执行的方法
    ///   - objects: 传递的参数数组
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    @discardableResult
    public func fw_invokeMethod(_ selector: Selector, objects: [Any]) -> Any? {
        return __FWRuntime.invokeMethod(self, selector: selector, objects: objects)
    }
    
    /// 安全调用内部属性获取方法，如果属性不存在，则忽略之
    ///
    /// 如果iOS13系统UIView调用部分valueForKey:方法闪退，且没有好的替代方案，可尝试调用此方法
    /// - Parameter name: 内部属性名称
    /// - Returns: 属性值
    public func fw_invokeGetter(_ name: String) -> Any? {
        return __FWRuntime.invokeGetter(self, name: name)
    }
    
    /// 安全调用内部属性设置方法，如果属性不存在，则忽略之
    ///
    /// 如果iOS13系统UIView调用部分valueForKey:方法闪退，且没有好的替代方案，可尝试调用此方法
    /// - Parameters:
    ///   - name: 内部属性名称
    ///   - object: 传递的方法参数
    /// - Returns: 方法执行后返回的值
    @discardableResult
    public func fw_invokeSetter(_ name: String, object: Any?) -> Any? {
        return __FWRuntime.invokeSetter(self, name: name, object: object)
    }
    
    // MARK: - Property
    /// 临时对象，强引用，支持KVO
    public var fw_tempObject: Any? {
        get { return fw_property(forName: "fw_tempObject") }
        set { fw_setProperty(newValue, forName: "fw_tempObject") }
    }
    
    /// 读取关联属性
    /// - Parameter forName: 属性名称
    /// - Returns: 属性值
    public func fw_property(forName: String) -> Any? {
        return __FWRuntime.getProperty(self, forName: forName)
    }
    
    /// 读取Bool关联属性，默认false
    /// - Parameter forName: 属性名称
    /// - Returns: 属性值
    public func fw_propertyBool(forName: String) -> Bool {
        if let number = fw_property(forName: forName) as? NSNumber {
            return number.boolValue
        }
        return false
    }
    
    /// 读取Int关联属性，默认0
    /// - Parameter forName: 属性名称
    /// - Returns: 属性值
    public func fw_propertyInt(forName: String) -> Int {
        if let number = fw_property(forName: forName) as? NSNumber {
            return number.intValue
        }
        return .zero
    }
    
    /// 读取Double关联属性，默认0
    /// - Parameter forName: 属性名称
    /// - Returns: 属性值
    public func fw_propertyDouble(forName: String) -> Double {
        if let number = fw_property(forName: forName) as? NSNumber {
            return number.doubleValue
        }
        return .zero
    }
    
    /// 设置强关联属性，支持KVO
    /// - Parameters:
    ///   - object: 属性值
    ///   - forName: 属性名称
    public func fw_setProperty(_ object: Any?, forName: String) {
        __FWRuntime.setPropertyPolicy(self, with: object, policy: .OBJC_ASSOCIATION_RETAIN_NONATOMIC, forName: forName)
    }
    
    /// 设置赋值关联属性，支持KVO，注意可能会产生野指针
    /// - Parameters:
    ///   - object: 属性值
    ///   - forName: 属性名称
    public func fw_setPropertyAssign(_ object: Any?, forName: String) {
        __FWRuntime.setPropertyPolicy(self, with: object, policy: .OBJC_ASSOCIATION_ASSIGN, forName: forName)
    }
    
    /// 设置拷贝关联属性，支持KVO
    /// - Parameters:
    ///   - object: 属性值
    ///   - forName: 属性名称
    public func fw_setPropertyCopy(_ object: Any?, forName: String) {
        __FWRuntime.setPropertyPolicy(self, with: object, policy: .OBJC_ASSOCIATION_COPY_NONATOMIC, forName: forName)
    }
    
    /// 设置弱引用关联属性，支持KVO，OC不支持weak关联属性
    /// - Parameters:
    ///   - object: 属性值
    ///   - forName: 属性名称
    public func fw_setPropertyWeak(_ object: Any?, forName: String) {
        __FWRuntime.setPropertyWeak(self, with: object, forName: forName)
    }
    
    /// 设置Bool关联属性
    /// - Parameters:
    ///   - value: 属性值
    ///   - forName: 属性名称
    public func fw_setPropertyBool(_ value: Bool, forName: String) {
        fw_setProperty(NSNumber(value: value), forName: forName)
    }
    
    /// 设置Int关联属性
    /// - Parameters:
    ///   - value: 属性值
    ///   - forName: 属性名称
    public func fw_setPropertyInt(_ value: Int, forName: String) {
        fw_setProperty(NSNumber(value: value), forName: forName)
    }
    
    /// 设置Double关联属性
    /// - Parameters:
    ///   - value: 属性值
    ///   - forName: 属性名称
    public func fw_setPropertyDouble(_ value: Double, forName: String) {
        fw_setProperty(NSNumber(value: value), forName: forName)
    }
    
    // MARK: - Bind
    
    /// 给对象绑定上另一个对象以供后续取出使用，如果 object 传入 nil 则会清除该 key 之前绑定的对象
    /// - Parameters:
    ///   - object: 对象，会被 strong 强引用
    ///   - forKey: 键名
    public func fw_bindObject(_ object: Any?, forKey: String) {
        if let object = object {
            fw_allBoundObjects.setObject(object, forKey: forKey as NSString)
        } else {
            fw_allBoundObjects.removeObject(forKey: forKey)
        }
    }
    
    /// 给对象绑定上另一个弱引用对象以供后续取出使用，如果 object 传入 nil 则会清除该 key 之前绑定的对象
    /// - Parameters:
    ///   - object: 对象，不会被 strong 强引用
    ///   - forKey: 键名
    public func fw_bindObjectWeak(_ object: Any?, forKey: String) {
        if let object = object {
            fw_allBoundObjects.setObject(__FWWeakObject(object: object), forKey: forKey as NSString)
        } else {
            fw_allBoundObjects.removeObject(forKey: forKey)
        }
    }
    
    /// 取出之前使用 bind 方法绑定的对象
    /// - Parameter forKey: 键名
    /// - Returns: 绑定的对象
    public func fw_boundObject(forKey: String) -> Any? {
        let object = fw_allBoundObjects.object(forKey: forKey)
        if let weakObject = object as? __FWWeakObject {
            return weakObject.object
        }
        return object
    }
    
    /// 给对象绑定上一个 double 值以供后续取出使用
    /// - Parameters:
    ///   - value: double值
    ///   - forKey: 键名
    public func fw_bindDouble(_ value: Double, forKey: String) {
        fw_bindObject(NSNumber(value: value), forKey: forKey)
    }
    
    /// 取出之前用 bindDouble:forKey: 绑定的值
    /// - Parameter forKey: 键名
    /// - Returns: 绑定的值
    public func fw_boundDouble(forKey: String) -> Double {
        if let number = fw_boundObject(forKey: forKey) as? NSNumber {
            return number.doubleValue
        }
        return .zero
    }

    /// 给对象绑定上一个 BOOL 值以供后续取出使用
    /// - Parameters:
    ///   - value: 布尔值
    ///   - forKey: 键名
    public func fw_bindBool(_ value: Bool, forKey: String) {
        fw_bindObject(NSNumber(value: value), forKey: forKey)
    }
    
    /// 取出之前用 bindBool:forKey: 绑定的值
    /// - Parameter forKey: 键名
    /// - Returns: 绑定的值
    public func fw_boundBool(forKey: String) -> Bool {
        if let number = fw_boundObject(forKey: forKey) as? NSNumber {
            return number.boolValue
        }
        return false
    }

    /// 给对象绑定上一个 NSInteger 值以供后续取出使用
    /// - Parameters:
    ///   - value: 整数值
    ///   - forKey: 键名
    public func fw_bindInt(_ value: Int, forKey: String) {
        fw_bindObject(NSNumber(value: value), forKey: forKey)
    }
    
    /// 取出之前用 bindInt:forKey: 绑定的值
    /// - Parameter forKey: 键名
    /// - Returns: 绑定的值
    public func fw_boundInt(forKey: String) -> Int {
        if let number = fw_boundObject(forKey: forKey) as? NSNumber {
            return number.intValue
        }
        return .zero
    }
    
    /// 移除之前使用 bind 方法绑定的对象
    /// - Parameter forKey: 键名
    public func fw_removeBinding(forKey: String) {
        fw_allBoundObjects.removeObject(forKey: forKey)
    }
    
    /// 移除之前使用 bind 方法绑定的所有对象
    public func fw_removeAllBindings() {
        fw_allBoundObjects.removeAllObjects()
    }

    /// 返回当前有绑定对象存在的所有的 key 的数组，数组中元素的顺序是随机的，如果不存在任何 key，则返回一个空数组
    public func fw_allBindingKeys() -> [String] {
        return fw_allBoundObjects.allKeys as? [String] ?? []
    }
    
    /// 返回是否设置了某个 key
    /// - Parameter key: 键名
    /// - Returns: 是否绑定
    public func fw_hasBindingKey(_ key: String) -> Bool {
        return fw_allBindingKeys().contains(key)
    }
    
    private var fw_allBoundObjects: NSMutableDictionary {
        if let boundObjects = fw_property(forName: "fw_allBoundObjects") as? NSMutableDictionary {
            return boundObjects
        }
        
        let boundObjects = NSMutableDictionary()
        fw_setProperty(boundObjects, forName: "fw_allBoundObjects")
        return boundObjects
    }
    
}
