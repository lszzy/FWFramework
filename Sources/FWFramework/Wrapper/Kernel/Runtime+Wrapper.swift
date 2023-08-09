//
//  Runtime+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

import Foundation

// MARK: - NSObject+Runtime
extension Wrapper where Base: NSObject {
    
    // MARK: - Module
    /// 获取类所在的模块名称，兼容主应用和framework等(可能不准确)
    public static var moduleName: String {
        return Base.fw_moduleName
    }
    
    // MARK: - Class
    /// 获取类方法列表(含父类直至NSObject)，支持meta类(objc_getMetaClass)
    /// - Parameters:
    ///   - clazz: 指定类
    /// - Returns: 方法列表
    public static func classMethods(_ clazz: AnyClass) -> [String] {
        return Base.fw_classMethods(clazz)
    }
    
    /// 获取类属性列表(含父类直至NSObject)，支持meta类(objc_getMetaClass)
    /// - Parameters:
    ///   - clazz: 指定类
    /// - Returns: 属性列表
    public static func classProperties(_ clazz: AnyClass) -> [String] {
        return Base.fw_classProperties(clazz)
    }
    
    /// 获取类Ivar列表(含父类直至NSObject)，支持meta类(objc_getMetaClass)
    /// - Parameters:
    ///   - clazz: 指定类
    /// - Returns: Ivar列表
    public static func classIvars(_ clazz: AnyClass) -> [String] {
        return Base.fw_classIvars(clazz)
    }
    
    // MARK: - Runtime
    /// 安全调用方法，如果不能响应，则忽略之
    /// - Parameter selector: 要执行的方法
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    @discardableResult
    public func invokeMethod(_ selector: Selector) -> Any? {
        return base.fw_invokeMethod(selector)
    }
    
    /// 安全调用方法，如果不能响应，则忽略之
    /// - Parameters:
    ///   - selector: 要执行的方法
    ///   - object: 传递的方法参数，非id类型可使用桥接，如int a = 1;(__bridge id)(void *)a
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    @discardableResult
    public func invokeMethod(_ selector: Selector, object: Any?) -> Any? {
        return base.fw_invokeMethod(selector, object: object)
    }
    
    /// 安全调用方法，如果不能响应，则忽略之
    /// - Parameters:
    ///   - selector: 要执行的方法
    ///   - object1: 传递的方法参数1，非id类型可使用桥接，如int a = 1;(__bridge id)(void *)a
    ///   - object2: 传递的方法参数2，非id类型可使用桥接，如int a = 1;(__bridge id)(void *)a
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    @discardableResult
    public func invokeMethod(_ selector: Selector, object object1: Any?, object object2: Any?) -> Any? {
        return base.fw_invokeMethod(selector, object: object1, object: object2)
    }
    
    /// 安全调用方法，支持多个参数
    /// - Parameters:
    ///   - selector: 要执行的方法
    ///   - objects: 传递的参数数组
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    @discardableResult
    public func invokeMethod(_ selector: Selector, objects: [Any]) -> Any? {
        return base.fw_invokeMethod(selector, objects: objects)
    }
    
    /// 安全调用内部属性获取方法，如果属性不存在，则忽略之
    ///
    /// 如果iOS13系统UIView调用部分valueForKey:方法闪退，且没有好的替代方案，可尝试调用此方法
    /// - Parameter name: 内部属性名称
    /// - Returns: 属性值
    public func invokeGetter(_ name: String) -> Any? {
        return base.fw_invokeGetter(name)
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
        return base.fw_invokeSetter(name, object: object)
    }
    
    /// 安全调用类方法，如果不能响应，则忽略之
    /// - Parameter selector: 要执行的方法
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    @discardableResult
    public static func invokeMethod(_ selector: Selector) -> Any? {
        return Base.fw_invokeMethod(selector)
    }
    
    /// 安全调用类方法，如果不能响应，则忽略之
    /// - Parameters:
    ///   - selector: 要执行的方法
    ///   - object: 传递的方法参数，非id类型可使用桥接，如int a = 1;(__bridge id)(void *)a
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    @discardableResult
    public static func invokeMethod(_ selector: Selector, object: Any?) -> Any? {
        return Base.fw_invokeMethod(selector, object: object)
    }
    
    /// 安全调用类方法，如果不能响应，则忽略之
    /// - Parameters:
    ///   - selector: 要执行的方法
    ///   - object1: 传递的方法参数1，非id类型可使用桥接，如int a = 1;(__bridge id)(void *)a
    ///   - object2: 传递的方法参数2，非id类型可使用桥接，如int a = 1;(__bridge id)(void *)a
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    @discardableResult
    public static func invokeMethod(_ selector: Selector, object object1: Any?, object object2: Any?) -> Any? {
        return Base.fw_invokeMethod(selector, object: object1, object: object2)
    }
    
    /// 安全调用类方法，支持多个参数
    /// - Parameters:
    ///   - selector: 要执行的方法
    ///   - objects: 传递的参数数组
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    @discardableResult
    public static func invokeMethod(_ selector: Selector, objects: [Any]) -> Any? {
        return Base.fw_invokeMethod(selector, objects: objects)
    }
    
    // MARK: - Property
    /// 临时对象，强引用，支持KVO
    public var tempObject: Any? {
        get { return base.fw_tempObject }
        set { base.fw_tempObject = newValue }
    }
    
    /// 读取关联属性
    /// - Parameter forName: 属性名称
    /// - Returns: 属性值
    public func property(forName: String) -> Any? {
        return base.fw_property(forName: forName)
    }
    
    /// 读取Bool关联属性，默认false
    /// - Parameter forName: 属性名称
    /// - Returns: 属性值
    public func propertyBool(forName: String) -> Bool {
        return base.fw_propertyBool(forName: forName)
    }
    
    /// 读取Int关联属性，默认0
    /// - Parameter forName: 属性名称
    /// - Returns: 属性值
    public func propertyInt(forName: String) -> Int {
        return base.fw_propertyInt(forName: forName)
    }
    
    /// 读取Double关联属性，默认0
    /// - Parameter forName: 属性名称
    /// - Returns: 属性值
    public func propertyDouble(forName: String) -> Double {
        return base.fw_propertyDouble(forName: forName)
    }
    
    /// 读取NSNumber关联属性，默认nil
    /// - Parameter forName: 属性名称
    /// - Returns: 属性值
    public func propertyNumber(forName: String) -> NSNumber? {
        return base.fw_propertyNumber(forName: forName)
    }
    
    /// 设置关联属性，可指定关联策略，支持KVO
    /// - Parameters:
    ///   - object: 属性值
    ///   - forName: 属性名称
    ///   - policy: 关联策略，默认RETAIN_NONATOMIC
    public func setProperty(_ object: Any?, forName: String, policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
        base.fw_setProperty(object, forName: forName, policy: policy)
    }
    
    /// 设置拷贝关联属性，支持KVO
    /// - Parameters:
    ///   - object: 属性值
    ///   - forName: 属性名称
    public func setPropertyCopy(_ object: Any?, forName: String) {
        base.fw_setPropertyCopy(object, forName: forName)
    }
    
    /// 设置弱引用关联属性，支持KVO，OC不支持weak关联属性
    /// - Parameters:
    ///   - object: 属性值
    ///   - forName: 属性名称
    public func setPropertyWeak(_ object: Any?, forName: String) {
        base.fw_setPropertyWeak(object, forName: forName)
    }
    
    /// 设置Bool关联属性
    /// - Parameters:
    ///   - value: 属性值
    ///   - forName: 属性名称
    public func setPropertyBool(_ value: Bool, forName: String) {
        base.fw_setPropertyBool(value, forName: forName)
    }
    
    /// 设置Int关联属性
    /// - Parameters:
    ///   - value: 属性值
    ///   - forName: 属性名称
    public func setPropertyInt(_ value: Int, forName: String) {
        base.fw_setPropertyInt(value, forName: forName)
    }
    
    /// 设置Double关联属性
    /// - Parameters:
    ///   - value: 属性值
    ///   - forName: 属性名称
    public func setPropertyDouble(_ value: Double, forName: String) {
        base.fw_setPropertyDouble(value, forName: forName)
    }
    
    /// 设置NSNumber关联属性
    /// - Parameters:
    ///   - value: 属性值
    ///   - forName: 属性名称
    public func setPropertyNumber(_ value: NSNumber?, forName: String) {
        base.fw_setPropertyNumber(value, forName: forName)
    }
    
    /// 读取类关联属性
    /// - Parameter forName: 属性名称
    /// - Returns: 属性值
    public static func property(forName: String) -> Any? {
        return Base.fw_property(forName: forName)
    }
    
    /// 设置类关联属性，可指定关联策略
    /// - Parameters:
    ///   - object: 属性值
    ///   - forName: 属性名称
    ///   - policy: 关联策略，默认RETAIN_NONATOMIC
    public static func setProperty(_ object: Any?, forName: String, policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
        Base.fw_setProperty(object, forName: forName, policy: policy)
    }
    
    /// 设置类拷贝关联属性
    /// - Parameters:
    ///   - object: 属性值
    ///   - forName: 属性名称
    public static func setPropertyCopy(_ object: Any?, forName: String) {
        Base.fw_setPropertyCopy(object, forName: forName)
    }
    
    /// 设置类弱引用关联属性，OC不支持weak关联属性
    /// - Parameters:
    ///   - object: 属性值
    ///   - forName: 属性名称
    public static func setPropertyWeak(_ object: Any?, forName: String) {
        Base.fw_setPropertyWeak(object, forName: forName)
    }
    
    // MARK: - Bind
    /// 给对象绑定上另一个对象以供后续取出使用，如果 object 传入 nil 则会清除该 key 之前绑定的对象
    /// - Parameters:
    ///   - object: 对象，会被 strong 强引用
    ///   - forKey: 键名
    public func bindObject(_ object: Any?, forKey: String) {
        base.fw_bindObject(object, forKey: forKey)
    }
    
    /// 给对象绑定上另一个弱引用对象以供后续取出使用，如果 object 传入 nil 则会清除该 key 之前绑定的对象
    /// - Parameters:
    ///   - object: 对象，不会被 strong 强引用
    ///   - forKey: 键名
    public func bindObjectWeak(_ object: Any?, forKey: String) {
        base.fw_bindObjectWeak(object, forKey: forKey)
    }
    
    /// 取出之前使用 bind 方法绑定的对象
    /// - Parameter forKey: 键名
    /// - Returns: 绑定的对象
    public func boundObject(forKey: String) -> Any? {
        return base.fw_boundObject(forKey: forKey)
    }
    
    /// 给对象绑定上一个 double 值以供后续取出使用
    /// - Parameters:
    ///   - value: double值
    ///   - forKey: 键名
    public func bindDouble(_ value: Double, forKey: String) {
        base.fw_bindDouble(value, forKey: forKey)
    }
    
    /// 取出之前用 bindDouble:forKey: 绑定的值
    /// - Parameter forKey: 键名
    /// - Returns: 绑定的值
    public func boundDouble(forKey: String) -> Double {
        return base.fw_boundDouble(forKey: forKey)
    }

    /// 给对象绑定上一个 BOOL 值以供后续取出使用
    /// - Parameters:
    ///   - value: 布尔值
    ///   - forKey: 键名
    public func bindBool(_ value: Bool, forKey: String) {
        base.fw_bindBool(value, forKey: forKey)
    }
    
    /// 取出之前用 bindBool:forKey: 绑定的值
    /// - Parameter forKey: 键名
    /// - Returns: 绑定的值
    public func boundBool(forKey: String) -> Bool {
        return base.fw_boundBool(forKey: forKey)
    }

    /// 给对象绑定上一个 NSInteger 值以供后续取出使用
    /// - Parameters:
    ///   - value: 整数值
    ///   - forKey: 键名
    public func bindInt(_ value: Int, forKey: String) {
        base.fw_bindInt(value, forKey: forKey)
    }
    
    /// 取出之前用 bindInt:forKey: 绑定的值
    /// - Parameter forKey: 键名
    /// - Returns: 绑定的值
    public func boundInt(forKey: String) -> Int {
        return base.fw_boundInt(forKey: forKey)
    }
    
    /// 给对象绑定上一个 NSNumber 值以供后续取出使用
    /// - Parameters:
    ///   - value: 整数值
    ///   - forKey: 键名
    public func bindNumber(_ value: NSNumber?, forKey: String) {
        base.fw_bindNumber(value, forKey: forKey)
    }
    
    /// 取出之前用 bindNumber:forKey: 绑定的值
    /// - Parameter forKey: 键名
    /// - Returns: 绑定的值
    public func boundNumber(forKey: String) -> NSNumber? {
        return base.fw_boundNumber(forKey: forKey)
    }
    
    /// 移除之前使用 bind 方法绑定的对象
    /// - Parameter forKey: 键名
    public func removeBinding(forKey: String) {
        base.fw_removeBinding(forKey: forKey)
    }
    
    /// 移除之前使用 bind 方法绑定的所有对象
    public func removeAllBindings() {
        base.fw_removeAllBindings()
    }

    /// 返回当前有绑定对象存在的所有的 key 的数组，数组中元素的顺序是随机的，如果不存在任何 key，则返回一个空数组
    public func allBindingKeys() -> [String] {
        return base.fw_allBindingKeys()
    }
    
    /// 返回是否设置了某个 key
    /// - Parameter key: 键名
    /// - Returns: 是否绑定
    public func hasBindingKey(_ key: String) -> Bool {
        return base.fw_hasBindingKey(key)
    }
    
}
