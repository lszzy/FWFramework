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
extension Wrapper where Base: NSObject {
    
    // MARK: - Class
    /// 获取类方法列表，支持meta类(objc_getMetaClass)
    /// - Parameters:
    ///   - clazz: 指定类
    ///   - superclass: 是否包含父类，包含则递归到NSObject，默认false
    /// - Returns: 方法列表
    public static func classMethods(_ clazz: AnyClass, superclass: Bool = false) -> [String] {
        return Base.__fw_classMethods(clazz, superclass: superclass)
    }
    
    /// 获取类属性列表，支持meta类(objc_getMetaClass)
    /// - Parameters:
    ///   - clazz: 指定类
    ///   - superclass: 是否包含父类，包含则递归到NSObject，默认false
    /// - Returns: 属性列表
    public static func classProperties(_ clazz: AnyClass, superclass: Bool = false) -> [String] {
        return Base.__fw_classProperties(clazz, superclass: superclass)
    }
    
    /// 获取类Ivar列表，支持meta类(objc_getMetaClass)
    /// - Parameters:
    ///   - clazz: 指定类
    ///   - superclass: 是否包含父类，包含则递归到NSObject，默认false
    /// - Returns: Ivar列表
    public static func classIvars(_ clazz: AnyClass, superclass: Bool = false) -> [String] {
        return Base.__fw_classIvars(clazz, superclass: superclass)
    }
    
    // MARK: - Runtime
    /// 安全调用方法，如果不能响应，则忽略之
    /// - Parameter selector: 要执行的方法
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    @discardableResult
    public func invokeMethod(_ selector: Selector) -> Any? {
        return base.__fw_invokeMethod(selector)
    }
    
    /// 安全调用方法，如果不能响应，则忽略之
    /// - Parameters:
    ///   - selector: 要执行的方法
    ///   - object: 传递的方法参数，非id类型可使用桥接，如int a = 1;(__bridge id)(void *)a
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    @discardableResult
    public func invokeMethod(_ selector: Selector, object: Any?) -> Any? {
        return base.__fw_invokeMethod(selector, with: object)
    }
    
    /// 安全调用方法，支持多个参数
    /// - Parameters:
    ///   - selector: 要执行的方法
    ///   - objects: 传递的参数数组
    /// - Returns: 方法执行后返回的值。如果无返回值，则为nil
    @discardableResult
    public func invokeMethod(_ selector: Selector, objects: [Any]) -> Any? {
        return base.__fw_invokeMethod(selector, objects: objects)
    }
    
    /// 对super发送消息
    /// - Parameter selector: 要执行的方法，需返回id类型
    /// - Returns: 方法执行后返回的值
    @discardableResult
    public func invokeSuperMethod(_ selector: Selector) -> Any? {
        return base.__fw_invokeSuperMethod(selector)
    }
    
    /// 对super发送消息，可传递参数
    /// - Parameters:
    ///   - selector: 要执行的方法，需返回id类型
    ///   - object: 传递的方法参数
    /// - Returns: 方法执行后返回的值
    @discardableResult
    public func invokeSuperMethod(_ selector: Selector, object: Any?) -> Any? {
        return base.__fw_invokeSuperMethod(selector, with: object)
    }
    
    /// 安全调用内部属性获取方法，如果属性不存在，则忽略之
    ///
    /// 如果iOS13系统UIView调用部分valueForKey:方法闪退，且没有好的替代方案，可尝试调用此方法
    /// - Parameter name: 内部属性名称
    /// - Returns: 属性值
    public func invokeGetter(_ name: String) -> Any? {
        return base.__fw_invokeGetter(name)
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
        return base.__fw_invokeSetter(name, with: object)
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
        get { return base.__fw_tempObject }
        set { base.__fw_tempObject = newValue }
    }
    
    /// 读取关联属性
    /// - Parameter forName: 属性名称
    /// - Returns: 属性值
    public func property(forName: String) -> Any? {
        return base.__fw_property(forName: forName)
    }
    
    /// 设置强关联属性，支持KVO
    /// - Parameters:
    ///   - object: 属性值
    ///   - forName: 属性名称
    public func setProperty(_ object: Any?, forName: String) {
        base.__fw_setProperty(object, forName: forName)
    }
    
    /// 设置赋值关联属性，支持KVO，注意可能会产生野指针
    /// - Parameters:
    ///   - object: 属性值
    ///   - forName: 属性名称
    public func setPropertyAssign(_ object: Any?, forName: String) {
        base.__fw_setPropertyAssign(object, forName: forName)
    }
    
    /// 设置拷贝关联属性，支持KVO
    /// - Parameters:
    ///   - object: 属性值
    ///   - forName: 属性名称
    public func setPropertyCopy(_ object: Any?, forName: String) {
        base.__fw_setPropertyCopy(object, forName: forName)
    }
    
    /// 设置弱引用关联属性，支持KVO，OC不支持weak关联属性
    /// - Parameters:
    ///   - object: 属性值
    ///   - forName: 属性名称
    public func setPropertyWeak(_ object: Any?, forName: String) {
        base.__fw_setPropertyWeak(object, forName: forName)
    }
    
    // MARK: - Bind
    
    /// 给对象绑定上另一个对象以供后续取出使用，如果 object 传入 nil 则会清除该 key 之前绑定的对象
    /// - Parameters:
    ///   - object: 对象，会被 strong 强引用
    ///   - forKey: 键名
    public func bindObject(_ object: Any?, forKey: String) {
        base.__fw_bindObject(object, forKey: forKey)
    }
    
    /// 给对象绑定上另一个弱引用对象以供后续取出使用，如果 object 传入 nil 则会清除该 key 之前绑定的对象
    /// - Parameters:
    ///   - object: 对象，不会被 strong 强引用
    ///   - forKey: 键名
    public func bindObjectWeak(_ object: Any?, forKey: String) {
        base.__fw_bindObjectWeak(object, forKey: forKey)
    }
    
    /// 取出之前使用 bind 方法绑定的对象
    /// - Parameter forKey: 键名
    /// - Returns: 绑定的对象
    public func boundObject(forKey: String) -> Any? {
        return base.__fw_boundObject(forKey: forKey)
    }
    
    /// 给对象绑定上一个 double 值以供后续取出使用
    /// - Parameters:
    ///   - value: double值
    ///   - forKey: 键名
    public func bindDouble(_ value: Double, forKey: String) {
        base.__fw_bindDouble(value, forKey: forKey)
    }
    
    /// 取出之前用 bindDouble:forKey: 绑定的值
    /// - Parameter forKey: 键名
    /// - Returns: 绑定的值
    public func boundDouble(forKey: String) -> Double {
        return base.__fw_boundDouble(forKey: forKey)
    }

    /// 给对象绑定上一个 BOOL 值以供后续取出使用
    /// - Parameters:
    ///   - value: 布尔值
    ///   - forKey: 键名
    public func bindBool(_ value: Bool, forKey: String) {
        base.__fw_bindBool(value, forKey: forKey)
    }
    
    /// 取出之前用 bindBool:forKey: 绑定的值
    /// - Parameter forKey: 键名
    /// - Returns: 绑定的值
    public func boundBool(forKey: String) -> Bool {
        return base.__fw_boundBool(forKey: forKey)
    }

    /// 给对象绑定上一个 NSInteger 值以供后续取出使用
    /// - Parameters:
    ///   - value: 整数值
    ///   - forKey: 键名
    public func bindInt(_ value: Int, forKey: String) {
        base.__fw_bindInt(value, forKey: forKey)
    }
    
    /// 取出之前用 bindInt:forKey: 绑定的值
    /// - Parameter forKey: 键名
    /// - Returns: 绑定的值
    public func boundInt(forKey: String) -> Int {
        return base.__fw_boundInt(forKey: forKey)
    }
    
    /// 移除之前使用 bind 方法绑定的对象
    /// - Parameter forKey: 键名
    public func removeBinding(forKey: String) {
        base.__fw_removeBinding(forKey: forKey)
    }
    
    /// 移除之前使用 bind 方法绑定的所有对象
    public func removeAllBindings() {
        base.__fw_removeAllBindings()
    }

    /// 返回当前有绑定对象存在的所有的 key 的数组，数组中元素的顺序是随机的，如果不存在任何 key，则返回一个空数组
    public func allBindingKeys() -> [String] {
        return base.__fw_allBindingKeys()
    }
    
    /// 返回是否设置了某个 key
    /// - Parameter key: 键名
    /// - Returns: 是否绑定
    public func hasBindingKey(_ key: String) -> Bool {
        return base.__fw_hasBindingKey(key)
    }
    
}
