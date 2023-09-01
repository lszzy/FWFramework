//
//  Runtime+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

import Foundation

// MARK: - AnyObject+Runtime
extension Wrapper where Base: WrapperObject {
    
    // MARK: - Module
    /// 获取类所在的模块名称，兼容主应用和framework等(可能不准确)
    public static var moduleName: String {
        return Base.fw_moduleName
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
    /// - Parameter name: 属性名称
    /// - Returns: 属性值
    public func property(forName name: String) -> Any? {
        return base.fw_property(forName: name)
    }
    
    /// 读取Bool关联属性，默认false
    /// - Parameter name: 属性名称
    /// - Returns: 属性值
    public func propertyBool(forName name: String) -> Bool {
        return base.fw_propertyBool(forName: name)
    }
    
    /// 读取Int关联属性，默认0
    /// - Parameter name: 属性名称
    /// - Returns: 属性值
    public func propertyInt(forName name: String) -> Int {
        return base.fw_propertyInt(forName: name)
    }
    
    /// 读取Double关联属性，默认0
    /// - Parameter name: 属性名称
    /// - Returns: 属性值
    public func propertyDouble(forName name: String) -> Double {
        return base.fw_propertyDouble(forName: name)
    }
    
    /// 读取NSNumber关联属性，默认nil
    /// - Parameter name: 属性名称
    /// - Returns: 属性值
    public func propertyNumber(forName name: String) -> NSNumber? {
        return base.fw_propertyNumber(forName: name)
    }
    
    /// 设置关联属性，可指定关联策略，支持KVO
    /// - Parameters:
    ///   - object: 属性值
    ///   - name: 属性名称
    ///   - policy: 关联策略，默认RETAIN_NONATOMIC
    public func setProperty(_ object: Any?, forName name: String, policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
        base.fw_setProperty(object, forName: name, policy: policy)
    }
    
    /// 设置拷贝关联属性，支持KVO
    /// - Parameters:
    ///   - object: 属性值
    ///   - name: 属性名称
    public func setPropertyCopy(_ object: Any?, forName name: String) {
        base.fw_setPropertyCopy(object, forName: name)
    }
    
    /// 设置弱引用关联属性，支持KVO，OC不支持weak关联属性
    /// - Parameters:
    ///   - object: 属性值
    ///   - name: 属性名称
    public func setPropertyWeak(_ object: AnyObject?, forName name: String) {
        base.fw_setPropertyWeak(object, forName: name)
    }
    
    /// 设置Bool关联属性
    /// - Parameters:
    ///   - value: 属性值
    ///   - name: 属性名称
    public func setPropertyBool(_ value: Bool, forName name: String) {
        base.fw_setPropertyBool(value, forName: name)
    }
    
    /// 设置Int关联属性
    /// - Parameters:
    ///   - value: 属性值
    ///   - name: 属性名称
    public func setPropertyInt(_ value: Int, forName name: String) {
        base.fw_setPropertyInt(value, forName: name)
    }
    
    /// 设置Double关联属性
    /// - Parameters:
    ///   - value: 属性值
    ///   - name: 属性名称
    public func setPropertyDouble(_ value: Double, forName name: String) {
        base.fw_setPropertyDouble(value, forName: name)
    }
    
    /// 设置NSNumber关联属性
    /// - Parameters:
    ///   - value: 属性值
    ///   - name: 属性名称
    public func setPropertyNumber(_ value: NSNumber?, forName name: String) {
        base.fw_setPropertyNumber(value, forName: name)
    }
    
    /// 读取类关联属性
    /// - Parameter name: 属性名称
    /// - Returns: 属性值
    public static func property(forName name: String) -> Any? {
        return Base.fw_property(forName: name)
    }
    
    /// 设置类关联属性，可指定关联策略
    /// - Parameters:
    ///   - object: 属性值
    ///   - name: 属性名称
    ///   - policy: 关联策略，默认RETAIN_NONATOMIC
    public static func setProperty(_ object: Any?, forName name: String, policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
        Base.fw_setProperty(object, forName: name, policy: policy)
    }
    
    /// 设置类拷贝关联属性
    /// - Parameters:
    ///   - object: 属性值
    ///   - name: 属性名称
    public static func setPropertyCopy(_ object: Any?, forName name: String) {
        Base.fw_setPropertyCopy(object, forName: name)
    }
    
    /// 设置类弱引用关联属性，OC不支持weak关联属性
    /// - Parameters:
    ///   - object: 属性值
    ///   - name: 属性名称
    public static func setPropertyWeak(_ object: AnyObject?, forName name: String) {
        Base.fw_setPropertyWeak(object, forName: name)
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
    public func bindObjectWeak(_ object: AnyObject?, forKey: String) {
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
    
    // MARK: - Hash
    /// 获取当前对象的hashValue，等同于: ObjectIdentifier(self).hashValue
    public var hashValue: Int {
        return base.fw_hashValue
    }
    
    // MARK: - Mirror
    /// 非递归方式获取当前对象的反射字典(含父类直至NSObject，自动过滤_开头属性)，不含nil值
    public var mirrorDictionary: [String: Any] {
        return base.fw_mirrorDictionary
    }
    
}

// MARK: - NSObject+Runtime
extension Wrapper where Base: NSObject {
    
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
    
    // MARK: - Property
    /// 读取关联对象，key为字符串，一般可使用#function
    public static func getAssociatedObject(_ object: Any, key: String) -> Any? {
        return Base.fw_getAssociatedObject(object, key: key)
    }
    
    /// 设置关联对象，key为字符串，一般可使用#function
    public static func setAssociatedObject(_ object: Any, key: String, value: Any?, policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
        Base.fw_setAssociatedObject(object, key: key, value: value, policy: policy)
    }
    
    // MARK: - Mirror
    /// 非递归方式获取任意对象的反射字典(含父类直至NSObject，自动过滤_开头属性)，不含nil值
    public static func mirrorDictionary(_ object: Any?) -> [String: Any] {
        return Base.fw_mirrorDictionary(object)
    }
    
}
