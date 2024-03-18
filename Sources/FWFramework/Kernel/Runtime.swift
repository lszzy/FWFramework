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

// MARK: - Wrapper+AnyObject
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
    /// 获取当前对象的反射字典(含父类直至NSObject)，不含nil值
    public var mirrorDictionary: [String: Any] {
        return base.fw_mirrorDictionary
    }
}

// MARK: - Wrapper+NSObject
extension Wrapper where Base: NSObject {
    // MARK: - Class
    /// 获取指定类的metaClass
    /// - Parameter clazz: 支持AnyClass|NSObject对象
    /// - Returns: 参数为AnyClass时，返回metaClass；参数为NSObject对象时，返回NSObject类
    public static func metaClass(_ clazz: Any?) -> AnyClass? {
        return Base.fw_metaClass(clazz)
    }
    
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
    /// 执行任意对象的反射属性句柄(含父类)
    public static func mirrorMap(_ object: Any, block: (String, Any) throws -> Void) rethrows -> Void {
        try Base.fw_mirrorMap(object, block: block)
    }
    
    /// 获取任意对象的反射字典(含父类直至NSObject)，不含nil值
    public static func mirrorDictionary(_ object: Any?) -> [String: Any] {
        return Base.fw_mirrorDictionary(object)
    }
}

// MARK: - AnyObject+Runtime
@_spi(FW) extension WrapperCompatible where Self: AnyObject {
    
    // MARK: - Module
    /// 获取类所在的模块名称，兼容主应用和framework等(可能不准确)
    public static var fw_moduleName: String {
        return Bundle(for: self).executableURL?.lastPathComponent ?? ""
    }
    
    // MARK: - Runtime
    /// 安全调用方法，如果不能响应，则忽略之
    /// - Parameter selector: 要执行的方法
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    @discardableResult
    public func fw_invokeMethod(_ selector: Selector) -> Any? {
        return ObjCBridge.invokeMethod(self, selector: selector)
    }
    
    /// 安全调用方法，如果不能响应，则忽略之
    /// - Parameters:
    ///   - selector: 要执行的方法
    ///   - object: 传递的方法参数，非id类型可使用桥接，如int a = 1;(__bridge id)(void *)a
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    @discardableResult
    public func fw_invokeMethod(_ selector: Selector, object: Any?) -> Any? {
        return ObjCBridge.invokeMethod(self, selector: selector, object: object)
    }
    
    /// 安全调用方法，如果不能响应，则忽略之
    /// - Parameters:
    ///   - selector: 要执行的方法
    ///   - object1: 传递的方法参数1，非id类型可使用桥接，如int a = 1;(__bridge id)(void *)a
    ///   - object2: 传递的方法参数2，非id类型可使用桥接，如int a = 1;(__bridge id)(void *)a
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    @discardableResult
    public func fw_invokeMethod(_ selector: Selector, object object1: Any?, object object2: Any?) -> Any? {
        return ObjCBridge.invokeMethod(self, selector: selector, object: object1, object: object2)
    }
    
    /// 安全调用方法，支持多个参数
    /// - Parameters:
    ///   - selector: 要执行的方法
    ///   - objects: 传递的参数数组
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    @discardableResult
    public func fw_invokeMethod(_ selector: Selector, objects: [Any]) -> Any? {
        return ObjCBridge.invokeMethod(self, selector: selector, objects: objects)
    }
    
    /// 安全调用内部属性获取方法，如果属性不存在，则忽略之
    ///
    /// 如果iOS13系统UIView调用部分valueForKey:方法闪退，且没有好的替代方案，可尝试调用此方法
    /// - Parameter name: 内部属性名称
    /// - Returns: 属性值
    public func fw_invokeGetter(_ name: String) -> Any? {
        return ObjCBridge.invokeGetter(self, name: name)
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
        return ObjCBridge.invokeSetter(self, name: name, object: object)
    }
    
    /// 安全调用类方法，如果不能响应，则忽略之
    /// - Parameter selector: 要执行的方法
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    @discardableResult
    public static func fw_invokeMethod(_ selector: Selector) -> Any? {
        return ObjCBridge.invokeMethod(self, selector: selector)
    }
    
    /// 安全调用类方法，如果不能响应，则忽略之
    /// - Parameters:
    ///   - selector: 要执行的方法
    ///   - object: 传递的方法参数，非id类型可使用桥接，如int a = 1;(__bridge id)(void *)a
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    @discardableResult
    public static func fw_invokeMethod(_ selector: Selector, object: Any?) -> Any? {
        return ObjCBridge.invokeMethod(self, selector: selector, object: object)
    }
    
    /// 安全调用类方法，如果不能响应，则忽略之
    /// - Parameters:
    ///   - selector: 要执行的方法
    ///   - object1: 传递的方法参数1，非id类型可使用桥接，如int a = 1;(__bridge id)(void *)a
    ///   - object2: 传递的方法参数2，非id类型可使用桥接，如int a = 1;(__bridge id)(void *)a
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    @discardableResult
    public static func fw_invokeMethod(_ selector: Selector, object object1: Any?, object object2: Any?) -> Any? {
        return ObjCBridge.invokeMethod(self, selector: selector, object: object1, object: object2)
    }
    
    /// 安全调用类方法，支持多个参数
    /// - Parameters:
    ///   - selector: 要执行的方法
    ///   - objects: 传递的参数数组
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    @discardableResult
    public static func fw_invokeMethod(_ selector: Selector, objects: [Any]) -> Any? {
        return ObjCBridge.invokeMethod(self, selector: selector, objects: objects)
    }
    
    // MARK: - Property
    /// 临时对象，强引用，支持KVO
    public var fw_tempObject: Any? {
        get { return fw_property(forName: #function) }
        set { fw_setProperty(newValue, forName: #function) }
    }
    
    /// 读取关联属性
    /// - Parameter name: 属性名称
    /// - Returns: 属性值
    public func fw_property(forName name: String) -> Any? {
        let value = NSObject.fw_getAssociatedObject(self, key: name)
        if let weakObject = value as? WeakObject {
            return weakObject.object
        }
        return value
    }
    
    /// 读取Bool关联属性，默认false
    /// - Parameter name: 属性名称
    /// - Returns: 属性值
    public func fw_propertyBool(forName name: String) -> Bool {
        let number = fw_propertyNumber(forName: name)
        return number?.boolValue ?? false
    }
    
    /// 读取Int关联属性，默认0
    /// - Parameter name: 属性名称
    /// - Returns: 属性值
    public func fw_propertyInt(forName name: String) -> Int {
        let number = fw_propertyNumber(forName: name)
        return number?.intValue ?? .zero
    }
    
    /// 读取Double关联属性，默认0
    /// - Parameter name: 属性名称
    /// - Returns: 属性值
    public func fw_propertyDouble(forName name: String) -> Double {
        let number = fw_propertyNumber(forName: name)
        return number?.doubleValue ?? .zero
    }
    
    /// 读取NSNumber关联属性，默认nil
    /// - Parameter name: 属性名称
    /// - Returns: 属性值
    public func fw_propertyNumber(forName name: String) -> NSNumber? {
        if let number = fw_property(forName: name) as? NSNumber {
            return number
        }
        return nil
    }
    
    /// 设置关联属性，可指定关联策略，支持KVO
    /// - Parameters:
    ///   - value: 属性值
    ///   - name: 属性名称
    ///   - policy: 关联策略，默认RETAIN_NONATOMIC
    public func fw_setProperty(_ value: Any?, forName name: String, policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
        NSObject.fw_setAssociatedObject(self, key: name, value: value, policy: policy)
    }
    
    /// 设置拷贝关联属性，支持KVO
    /// - Parameters:
    ///   - value: 属性值
    ///   - name: 属性名称
    public func fw_setPropertyCopy(_ value: Any?, forName name: String) {
        NSObject.fw_setAssociatedObject(self, key: name, value: value, policy: .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }
    
    /// 设置弱引用关联属性，支持KVO，OC不支持weak关联属性
    /// - Parameters:
    ///   - value: 属性值
    ///   - name: 属性名称
    public func fw_setPropertyWeak(_ value: AnyObject?, forName name: String) {
        NSObject.fw_setAssociatedObject(self, key: name, value: WeakObject(object: value), policy: .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    /// 设置Bool关联属性
    /// - Parameters:
    ///   - value: 属性值
    ///   - name: 属性名称
    public func fw_setPropertyBool(_ value: Bool, forName name: String) {
        fw_setPropertyNumber(NSNumber(value: value), forName: name)
    }
    
    /// 设置Int关联属性
    /// - Parameters:
    ///   - value: 属性值
    ///   - name: 属性名称
    public func fw_setPropertyInt(_ value: Int, forName name: String) {
        fw_setPropertyNumber(NSNumber(value: value), forName: name)
    }
    
    /// 设置Double关联属性
    /// - Parameters:
    ///   - value: 属性值
    ///   - name: 属性名称
    public func fw_setPropertyDouble(_ value: Double, forName name: String) {
        fw_setPropertyNumber(NSNumber(value: value), forName: name)
    }
    
    /// 设置NSNumber关联属性
    /// - Parameters:
    ///   - value: 属性值
    ///   - name: 属性名称
    public func fw_setPropertyNumber(_ value: NSNumber?, forName name: String) {
        fw_setProperty(value, forName: name)
    }
    
    /// 读取类关联属性
    /// - Parameter name: 属性名称
    /// - Returns: 属性值
    public static func fw_property(forName name: String) -> Any? {
        let value = NSObject.fw_getAssociatedObject(self, key: name)
        if let weakObject = value as? WeakObject {
            return weakObject.object
        }
        return value
    }
    
    /// 设置类关联属性，可指定关联策略
    /// - Parameters:
    ///   - value: 属性值
    ///   - name: 属性名称
    ///   - policy: 关联策略，默认RETAIN_NONATOMIC
    public static func fw_setProperty(_ value: Any?, forName name: String, policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
        NSObject.fw_setAssociatedObject(self, key: name, value: value, policy: policy)
    }
    
    /// 设置类拷贝关联属性
    /// - Parameters:
    ///   - value: 属性值
    ///   - name: 属性名称
    public static func fw_setPropertyCopy(_ value: Any?, forName name: String) {
        NSObject.fw_setAssociatedObject(self, key: name, value: value, policy: .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }
    
    /// 设置类弱引用关联属性，OC不支持weak关联属性
    /// - Parameters:
    ///   - value: 属性值
    ///   - name: 属性名称
    public static func fw_setPropertyWeak(_ value: AnyObject?, forName name: String) {
        NSObject.fw_setAssociatedObject(self, key: name, value: WeakObject(object: value), policy: .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
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
    public func fw_bindObjectWeak(_ object: AnyObject?, forKey: String) {
        if let object = object {
            fw_allBoundObjects.setObject(WeakObject(object: object), forKey: forKey as NSString)
        } else {
            fw_allBoundObjects.removeObject(forKey: forKey)
        }
    }
    
    /// 取出之前使用 bind 方法绑定的对象
    /// - Parameter forKey: 键名
    /// - Returns: 绑定的对象
    public func fw_boundObject(forKey: String) -> Any? {
        let object = fw_allBoundObjects.object(forKey: forKey)
        if let weakObject = object as? WeakObject {
            return weakObject.object
        }
        return object
    }
    
    /// 给对象绑定上一个 double 值以供后续取出使用
    /// - Parameters:
    ///   - value: double值
    ///   - forKey: 键名
    public func fw_bindDouble(_ value: Double, forKey: String) {
        fw_bindNumber(NSNumber(value: value), forKey: forKey)
    }
    
    /// 取出之前用 bindDouble:forKey: 绑定的值
    /// - Parameter forKey: 键名
    /// - Returns: 绑定的值
    public func fw_boundDouble(forKey: String) -> Double {
        let number = fw_boundNumber(forKey: forKey)
        return number?.doubleValue ?? .zero
    }

    /// 给对象绑定上一个 BOOL 值以供后续取出使用
    /// - Parameters:
    ///   - value: 布尔值
    ///   - forKey: 键名
    public func fw_bindBool(_ value: Bool, forKey: String) {
        fw_bindNumber(NSNumber(value: value), forKey: forKey)
    }
    
    /// 取出之前用 bindBool:forKey: 绑定的值
    /// - Parameter forKey: 键名
    /// - Returns: 绑定的值
    public func fw_boundBool(forKey: String) -> Bool {
        let number = fw_boundNumber(forKey: forKey)
        return number?.boolValue ?? false
    }

    /// 给对象绑定上一个 NSInteger 值以供后续取出使用
    /// - Parameters:
    ///   - value: 整数值
    ///   - forKey: 键名
    public func fw_bindInt(_ value: Int, forKey: String) {
        fw_bindNumber(NSNumber(value: value), forKey: forKey)
    }
    
    /// 取出之前用 bindInt:forKey: 绑定的值
    /// - Parameter forKey: 键名
    /// - Returns: 绑定的值
    public func fw_boundInt(forKey: String) -> Int {
        let number = fw_boundNumber(forKey: forKey)
        return number?.intValue ?? .zero
    }
    
    /// 给对象绑定上一个 NSNumber 值以供后续取出使用
    /// - Parameters:
    ///   - value: NSNumber值
    ///   - forKey: 键名
    public func fw_bindNumber(_ value: NSNumber?, forKey: String) {
        fw_bindObject(value, forKey: forKey)
    }
    
    /// 取出之前用 bindNumber:forKey: 绑定的值
    /// - Parameter forKey: 键名
    /// - Returns: 绑定的值
    public func fw_boundNumber(forKey: String) -> NSNumber? {
        if let number = fw_boundObject(forKey: forKey) as? NSNumber {
            return number
        }
        return nil
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
        if let boundObjects = fw_property(forName: #function) as? NSMutableDictionary {
            return boundObjects
        }
        
        let boundObjects = NSMutableDictionary()
        fw_setProperty(boundObjects, forName: #function)
        return boundObjects
    }
    
    // MARK: - Hash
    /// 获取当前对象的hashValue，等同于: ObjectIdentifier(self).hashValue
    public var fw_hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }
    
    // MARK: - Mirror
    /// 获取当前对象的反射字典(含父类直至NSObject)，不含nil值
    public var fw_mirrorDictionary: [String: Any] {
        return NSObject.fw_mirrorDictionary(self)
    }
    
}

// MARK: - NSObject+Runtime
@_spi(FW) extension NSObject {
    
    // MARK: - Class
    /// 获取指定类的metaClass
    /// - Parameter clazz: 支持AnyClass|NSObject对象
    /// - Returns: 参数为AnyClass时，返回metaClass；参数为NSObject对象时，返回NSObject类
    public static func fw_metaClass(_ clazz: Any?) -> AnyClass? {
        var metaClass: AnyClass?
        if let clazz = clazz as? AnyClass {
            if let className = (NSStringFromClass(clazz) as NSString).utf8String {
                metaClass = objc_getMetaClass(className) as? AnyClass
            }
        } else {
            metaClass = object_getClass(clazz)
        }
        return metaClass
    }
    
    /// 获取类方法列表(含父类直至NSObject)，支持meta类(objc_getMetaClass)
    /// - Parameters:
    ///   - clazz: 指定类
    /// - Returns: 方法列表
    public static func fw_classMethods(_ clazz: AnyClass) -> [String] {
        let cacheKey = fw_classCacheKey(clazz, type: "M")
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
            
            targetClass = class_getSuperclass(targetClass)
            if targetClass == nil || targetClass == NSObject.classForCoder() {
                break
            }
        }
        
        NSObject.fw_classCaches[cacheKey] = resultNames
        return resultNames
    }
    
    /// 获取类属性列表(含父类直至NSObject)，支持meta类(objc_getMetaClass)
    /// - Parameters:
    ///   - clazz: 指定类
    /// - Returns: 属性列表
    public static func fw_classProperties(_ clazz: AnyClass) -> [String] {
        let cacheKey = fw_classCacheKey(clazz, type: "P")
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
            
            targetClass = class_getSuperclass(targetClass)
            if targetClass == nil || targetClass == NSObject.classForCoder() {
                break
            }
        }
        
        NSObject.fw_classCaches[cacheKey] = resultNames
        return resultNames
    }
    
    /// 获取类Ivar列表(含父类直至NSObject)，支持meta类(objc_getMetaClass)
    /// - Parameters:
    ///   - clazz: 指定类
    /// - Returns: Ivar列表
    public static func fw_classIvars(_ clazz: AnyClass) -> [String] {
        let cacheKey = fw_classCacheKey(clazz, type: "V")
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
            
            targetClass = class_getSuperclass(targetClass)
            if targetClass == nil || targetClass == NSObject.classForCoder() {
                break
            }
        }
        
        NSObject.fw_classCaches[cacheKey] = resultNames
        return resultNames
    }
    
    private static func fw_classCacheKey(
        _ clazz: AnyClass,
        type: String
    ) -> String {
        let cacheKey = NSStringFromClass(clazz) + "."
            + (class_isMetaClass(clazz) ? "M" : "C") + type
        return cacheKey
    }
    
    private static var fw_classCaches: [String: [String]] = [:]
    
    // MARK: - Property
    /// 读取关联对象，key为字符串，一般可使用#function
    public static func fw_getAssociatedObject(_ object: Any, key: String) -> Any? {
        let pointer = unsafeBitCast(Selector(key), to: UnsafeRawPointer.self)
        return objc_getAssociatedObject(object, pointer)
    }
    
    /// 设置关联对象，key为字符串，一般可使用#function
    public static func fw_setAssociatedObject(_ object: Any, key: String, value: Any?, policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
        let pointer = unsafeBitCast(Selector(key), to: UnsafeRawPointer.self)
        objc_setAssociatedObject(object, pointer, value, policy)
    }
    
    // MARK: - Mirror
    /// 执行任意对象的反射属性句柄(含父类)
    public static func fw_mirrorMap(_ object: Any, block: (String, Any) throws -> Void) rethrows -> Void {
        var mirror: Mirror! = Mirror(reflecting: object)
        while mirror != nil {
            for child in mirror.children where child.label != nil {
                try block(child.label!, child.value)
            }
            mirror = mirror.superclassMirror
        }
    }
    
    /// 获取任意对象的反射字典(含父类直至NSObject)，不含nil值
    public static func fw_mirrorDictionary(_ object: Any?) -> [String: Any] {
        guard let object = object else { return [:] }
        var mirror = Mirror(reflecting: object)
        var children: [Mirror.Child] = []
        children += mirror.children
        while let superclassMirror = mirror.superclassMirror,
              superclassMirror.subjectType != NSObject.self {
            children += superclassMirror.children
            mirror = superclassMirror
        }
        
        var result: [String: Any] = [:]
        children.forEach { child in
            if let label = child.label, !label.isEmpty,
               !Optional<Any>.isNil(child.value) {
                result[label] = child.value
            }
        }
        return result
    }
    
}
