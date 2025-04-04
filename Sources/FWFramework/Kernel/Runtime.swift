//
//  Runtime.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

import Foundation

// MARK: - AnyObject+Runtime
extension Wrapper where Base: WrapperObject {
    // MARK: - Module
    /// 获取当前类所在的模块名称，兼容主应用和framework等(可能不准确)
    public static var moduleName: String {
        moduleName(for: Base.self)
    }

    /// 获取指定类所在的模块名称，兼容主应用和framework等(可能不准确)
    public static func moduleName(for aClass: AnyClass) -> String {
        Bundle(for: aClass).executableURL?.lastPathComponent ?? ""
    }

    /// 获取任意对象的类型字符串，含模块名称
    public static func typeName(for object: Any) -> String {
        if let clazz = object as? AnyClass {
            return NSStringFromClass(clazz)
        } else if let proto = object as? Protocol {
            return NSStringFromProtocol(proto)
        } else if let type = object as? Any.Type {
            return String(describing: type as AnyObject)
        } else if let clazz = type(of: object) as? AnyClass {
            return NSStringFromClass(clazz)
        } else {
            return String(describing: type(of: object) as AnyObject)
        }
    }

    // MARK: - Property
    /// 临时对象，强引用，线程安全，支持KVO
    public var tempObject: Any? {
        get {
            objc_sync_enter(base)
            defer { objc_sync_exit(base) }

            return property(forName: #function)
        }
        set {
            objc_sync_enter(base)
            defer { objc_sync_exit(base) }

            setProperty(newValue, forName: #function)
        }
    }

    /// 读取关联属性
    /// - Parameter name: 属性名称
    /// - Returns: 属性值
    public func property(forName name: String) -> Any? {
        let value = NSObject.fw.getAssociatedObject(base, key: name)
        if let weakValue = value as? WeakValue {
            return weakValue.value
        }
        return value
    }

    /// 读取Bool关联属性，默认false
    /// - Parameter name: 属性名称
    /// - Returns: 属性值
    public func propertyBool(forName name: String) -> Bool {
        let number = propertyNumber(forName: name)
        return number?.boolValue ?? false
    }

    /// 读取Int关联属性，默认0
    /// - Parameter name: 属性名称
    /// - Returns: 属性值
    public func propertyInt(forName name: String) -> Int {
        let number = propertyNumber(forName: name)
        return number?.intValue ?? .zero
    }

    /// 读取Double关联属性，默认0
    /// - Parameter name: 属性名称
    /// - Returns: 属性值
    public func propertyDouble(forName name: String) -> Double {
        let number = propertyNumber(forName: name)
        return number?.doubleValue ?? .zero
    }

    /// 读取NSNumber关联属性，默认nil
    /// - Parameter name: 属性名称
    /// - Returns: 属性值
    public func propertyNumber(forName name: String) -> NSNumber? {
        if let number = property(forName: name) as? NSNumber {
            return number
        }
        return nil
    }

    /// 设置关联属性，可指定关联策略，支持KVO
    /// - Parameters:
    ///   - value: 属性值
    ///   - name: 属性名称
    ///   - policy: 关联策略，默认RETAIN_NONATOMIC
    public func setProperty(_ value: Any?, forName name: String, policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
        NSObject.fw.setAssociatedObject(base, key: name, value: value, policy: policy)
    }

    /// 设置拷贝关联属性，支持KVO
    /// - Parameters:
    ///   - value: 属性值
    ///   - name: 属性名称
    public func setPropertyCopy(_ value: Any?, forName name: String) {
        NSObject.fw.setAssociatedObject(base, key: name, value: value, policy: .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }

    /// 设置弱引用关联属性，支持KVO，OC不支持weak关联属性
    /// - Parameters:
    ///   - value: 属性值
    ///   - name: 属性名称
    public func setPropertyWeak(_ value: AnyObject?, forName name: String) {
        NSObject.fw.setAssociatedObject(base, key: name, value: WeakValue(value), policy: .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /// 设置Bool关联属性
    /// - Parameters:
    ///   - value: 属性值
    ///   - name: 属性名称
    public func setPropertyBool(_ value: Bool, forName name: String) {
        setPropertyNumber(NSNumber(value: value), forName: name)
    }

    /// 设置Int关联属性
    /// - Parameters:
    ///   - value: 属性值
    ///   - name: 属性名称
    public func setPropertyInt(_ value: Int, forName name: String) {
        setPropertyNumber(NSNumber(value: value), forName: name)
    }

    /// 设置Double关联属性
    /// - Parameters:
    ///   - value: 属性值
    ///   - name: 属性名称
    public func setPropertyDouble(_ value: Double, forName name: String) {
        setPropertyNumber(NSNumber(value: value), forName: name)
    }

    /// 设置NSNumber关联属性
    /// - Parameters:
    ///   - value: 属性值
    ///   - name: 属性名称
    public func setPropertyNumber(_ value: NSNumber?, forName name: String) {
        setProperty(value, forName: name)
    }

    // MARK: - Bind
    /// 给对象绑定上另一个对象以供后续取出使用，如果 object 传入 nil 则会清除该 key 之前绑定的对象
    /// - Parameters:
    ///   - object: 对象，会被 strong 强引用
    ///   - key: 键名
    public func bindObject(_ object: Any?, forKey key: String) {
        if let object {
            allBoundObjects[key] = object
        } else {
            allBoundObjects.removeValue(forKey: key)
        }
    }

    /// 给对象绑定上另一个弱引用对象以供后续取出使用，如果 object 传入 nil 则会清除该 key 之前绑定的对象
    /// - Parameters:
    ///   - object: 对象，不会被 strong 强引用
    ///   - key: 键名
    public func bindObjectWeak(_ object: AnyObject?, forKey key: String) {
        if let object {
            allBoundObjects[key] = WeakValue(object)
        } else {
            allBoundObjects.removeValue(forKey: key)
        }
    }

    /// 取出之前使用 bind 方法绑定的对象
    /// - Parameter key: 键名
    /// - Returns: 绑定的对象
    public func boundObject(forKey key: String) -> Any? {
        let object = allBoundObjects[key]
        if let weakValue = object as? WeakValue {
            return weakValue.value
        }
        return object
    }

    /// 给对象绑定上一个 double 值以供后续取出使用
    /// - Parameters:
    ///   - value: double值
    ///   - forKey: 键名
    public func bindDouble(_ value: Double, forKey: String) {
        bindNumber(NSNumber(value: value), forKey: forKey)
    }

    /// 取出之前用 bindDouble:forKey: 绑定的值
    /// - Parameter forKey: 键名
    /// - Returns: 绑定的值
    public func boundDouble(forKey: String) -> Double {
        let number = boundNumber(forKey: forKey)
        return number?.doubleValue ?? .zero
    }

    /// 给对象绑定上一个 BOOL 值以供后续取出使用
    /// - Parameters:
    ///   - value: 布尔值
    ///   - forKey: 键名
    public func bindBool(_ value: Bool, forKey: String) {
        bindNumber(NSNumber(value: value), forKey: forKey)
    }

    /// 取出之前用 bindBool:forKey: 绑定的值
    /// - Parameter forKey: 键名
    /// - Returns: 绑定的值
    public func boundBool(forKey: String) -> Bool {
        let number = boundNumber(forKey: forKey)
        return number?.boolValue ?? false
    }

    /// 给对象绑定上一个 NSInteger 值以供后续取出使用
    /// - Parameters:
    ///   - value: 整数值
    ///   - forKey: 键名
    public func bindInt(_ value: Int, forKey: String) {
        bindNumber(NSNumber(value: value), forKey: forKey)
    }

    /// 取出之前用 bindInt:forKey: 绑定的值
    /// - Parameter forKey: 键名
    /// - Returns: 绑定的值
    public func boundInt(forKey: String) -> Int {
        let number = boundNumber(forKey: forKey)
        return number?.intValue ?? .zero
    }

    /// 给对象绑定上一个 NSNumber 值以供后续取出使用
    /// - Parameters:
    ///   - value: 整数值
    ///   - forKey: 键名
    public func bindNumber(_ value: NSNumber?, forKey: String) {
        bindObject(value, forKey: forKey)
    }

    /// 取出之前用 bindNumber:forKey: 绑定的值
    /// - Parameter forKey: 键名
    /// - Returns: 绑定的值
    public func boundNumber(forKey: String) -> NSNumber? {
        if let number = boundObject(forKey: forKey) as? NSNumber {
            return number
        }
        return nil
    }

    /// 移除之前使用 bind 方法绑定的对象
    /// - Parameter forKey: 键名
    public func removeBinding(forKey key: String) {
        allBoundObjects.removeValue(forKey: key)
    }

    /// 移除之前使用 bind 方法绑定的所有对象
    public func removeAllBindings() {
        allBoundObjects.removeAll()
    }

    /// 返回当前有绑定对象存在的所有的 key 的数组，数组中元素的顺序是随机的，如果不存在任何 key，则返回一个空数组
    public func allBindingKeys() -> [String] {
        Array(allBoundObjects.keys)
    }

    /// 返回是否设置了某个 key
    /// - Parameter key: 键名
    /// - Returns: 是否绑定
    public func hasBindingKey(_ key: String) -> Bool {
        allBoundObjects.index(forKey: key) != nil
    }

    private var allBoundObjects: [String: Any] {
        get {
            objc_sync_enter(base)
            defer { objc_sync_exit(base) }

            return property(forName: #function) as? [String: Any] ?? [:]
        }
        set {
            objc_sync_enter(base)
            defer { objc_sync_exit(base) }

            setProperty(newValue, forName: #function)
        }
    }

    // MARK: - Hash
    /// 获取当前对象的hashValue，等同于: ObjectIdentifier(base).hashValue
    public var hashValue: Int {
        ObjectIdentifier(base).hashValue
    }

    // MARK: - Mirror
    /// 获取当前对象的反射字典(含父类直至NSObject)，不含nil值
    public var mirrorDictionary: [String: Any] {
        NSObject.fw.mirrorDictionary(base)
    }
}

// MARK: - NSObject+Runtime
extension Wrapper where Base: NSObject {
    // MARK: - Class
    /// 获取指定类的metaClass
    /// - Parameter clazz: 支持AnyClass|NSObject对象
    /// - Returns: 参数为AnyClass时，返回metaClass；参数为NSObject对象时，返回NSObject类
    public static func metaClass(_ clazz: Any?) -> AnyClass? {
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

    /// 获取指定类的所有子类
    public static func allSubclasses(_ clazz: AnyClass) -> [AnyClass] {
        var classesCount: UInt32 = 0
        guard let classList = objc_copyClassList(&classesCount) else {
            return []
        }

        defer { free(UnsafeMutableRawPointer(classList)) }
        let classes = UnsafeBufferPointer(start: classList, count: Int(classesCount))
        guard classesCount > 0 else {
            return []
        }

        return classes.filter { isSubclass($0, of: clazz) }
    }

    private static func isSubclass(_ subclass: AnyClass, of superclass: AnyClass) -> Bool {
        var parentClass: AnyClass? = subclass
        while parentClass != nil {
            parentClass = class_getSuperclass(parentClass)
            if parentClass == superclass { return true }
        }
        return false
    }

    /// 获取类方法列表(含父类直至NSObject)，支持meta类(objc_getMetaClass)
    /// - Parameters:
    ///   - clazz: 指定类
    /// - Returns: 方法列表
    public static func classMethods(_ clazz: AnyClass) -> [String] {
        let cacheKey = classCacheKey(clazz, type: "M")
        if let cacheNames = FrameworkConfiguration.runtimeClassCaches[cacheKey] {
            return cacheNames
        }

        var resultNames: [String] = []
        var targetClass: AnyClass? = clazz
        while targetClass != nil {
            var resultCount: UInt32 = 0
            let methodList = class_copyMethodList(targetClass, &resultCount)
            for i in 0..<Int(resultCount) {
                if let method = methodList?[i],
                   let resultName = String(utf8String: sel_getName(method_getName(method))),
                   !resultName.isEmpty,
                   !resultNames.contains(resultName) {
                    resultNames.append(resultName)
                }
            }
            free(methodList)

            targetClass = class_getSuperclass(targetClass)
            if targetClass == nil || targetClass == NSObject.self {
                break
            }
        }

        FrameworkConfiguration.runtimeClassCaches[cacheKey] = resultNames
        return resultNames
    }

    /// 获取类属性列表(含父类直至NSObject)，支持meta类(objc_getMetaClass)
    /// - Parameters:
    ///   - clazz: 指定类
    /// - Returns: 属性列表
    public static func classProperties(_ clazz: AnyClass) -> [String] {
        let cacheKey = classCacheKey(clazz, type: "P")
        if let cacheNames = FrameworkConfiguration.runtimeClassCaches[cacheKey] {
            return cacheNames
        }

        var resultNames: [String] = []
        var targetClass: AnyClass? = clazz
        while targetClass != nil {
            var resultCount: UInt32 = 0
            let propertyList = class_copyPropertyList(targetClass, &resultCount)
            for i in 0..<Int(resultCount) {
                if let property = propertyList?[i],
                   let resultName = String(utf8String: property_getName(property)),
                   !resultName.isEmpty,
                   !resultNames.contains(resultName) {
                    resultNames.append(resultName)
                }
            }
            free(propertyList)

            targetClass = class_getSuperclass(targetClass)
            if targetClass == nil || targetClass == NSObject.self {
                break
            }
        }

        FrameworkConfiguration.runtimeClassCaches[cacheKey] = resultNames
        return resultNames
    }

    /// 获取类Ivar列表(含父类直至NSObject)，支持meta类(objc_getMetaClass)
    /// - Parameters:
    ///   - clazz: 指定类
    /// - Returns: Ivar列表
    public static func classIvars(_ clazz: AnyClass) -> [String] {
        let cacheKey = classCacheKey(clazz, type: "V")
        if let cacheNames = FrameworkConfiguration.runtimeClassCaches[cacheKey] {
            return cacheNames
        }

        var resultNames: [String] = []
        var targetClass: AnyClass? = clazz
        while targetClass != nil {
            var resultCount: UInt32 = 0
            let ivarList = class_copyIvarList(targetClass, &resultCount)
            for i in 0..<Int(resultCount) {
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
            if targetClass == nil || targetClass == NSObject.self {
                break
            }
        }

        FrameworkConfiguration.runtimeClassCaches[cacheKey] = resultNames
        return resultNames
    }

    private static func classCacheKey(
        _ clazz: AnyClass,
        type: String
    ) -> String {
        let cacheKey = NSStringFromClass(clazz) + "."
            + (class_isMetaClass(clazz) ? "M" : "C") + type
        return cacheKey
    }

    // MARK: - Property
    /// 读取关联对象，key为字符串，一般可使用#function
    public static func getAssociatedObject(_ object: Any, key: String) -> Any? {
        let pointer = unsafeBitCast(Selector(key), to: UnsafeRawPointer.self)
        return objc_getAssociatedObject(object, pointer)
    }

    /// 设置关联对象，key为字符串，一般可使用#function
    public static func setAssociatedObject(_ object: Any, key: String, value: Any?, policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
        let pointer = unsafeBitCast(Selector(key), to: UnsafeRawPointer.self)
        objc_setAssociatedObject(object, pointer, value, policy)
    }

    // MARK: - Method
    /// 安全调用内部属性获取方法，如果属性不存在，则忽略之
    ///
    /// 如果iOS13系统UIView调用部分valueForKey:方法闪退，且没有好的替代方案，可尝试调用此方法
    /// - Parameter name: 内部属性名称
    /// - Returns: 属性值
    public func invokeGetter(_ name: String) -> Any? {
        guard let selector = getterSelector(name) else { return nil }
        let result = base.perform(selector)?.takeUnretainedValue()
        return result as Any?
    }

    /// 安全调用内部属性设置方法，如果属性不存在，则忽略之
    ///
    /// 如果iOS13系统UIView调用部分valueForKey:方法闪退，且没有好的替代方案，可尝试调用此方法
    /// - Parameters:
    ///   - name: 内部属性名称
    ///   - object: 传递的方法参数
    public func invokeSetter(_ name: String, object: Any?) {
        guard let selector = setterSelector(name) else { return }
        _ = base.perform(selector, with: object)
    }

    private func getterSelector(_ name: String) -> Selector? {
        let name = name.hasPrefix("_") ? String(name.dropFirst()) : name
        guard !name.isEmpty else { return nil }

        let ucfirstName = String(name.prefix(1).uppercased() + name.dropFirst())
        let selectors = [
            NSSelectorFromString("get\(ucfirstName)"),
            NSSelectorFromString(name),
            NSSelectorFromString("is\(ucfirstName)"),
            NSSelectorFromString("_\(name)")
        ]

        for selector in selectors {
            if base.responds(to: selector) {
                return selector
            }
        }
        return nil
    }

    private func setterSelector(_ name: String) -> Selector? {
        let name = name.hasPrefix("_") ? String(name.dropFirst()) : name
        guard !name.isEmpty else { return nil }

        let ucfirstName = String(name.prefix(1).uppercased() + name.dropFirst())
        let selectors = [
            NSSelectorFromString("set\(ucfirstName):"),
            NSSelectorFromString("_set\(ucfirstName):")
        ]

        for selector in selectors {
            if base.responds(to: selector) {
                return selector
            }
        }
        return nil
    }

    /// 安全调用方法，支持多个参数
    /// - Parameters:
    ///   - selector: 要执行的方法
    ///   - objects: 传递的参数数组，默认空
    /// - Returns: 方法返回值
    @discardableResult
    public func invokeMethod(_ selector: Selector, objects: [Any]? = nil) -> Unmanaged<AnyObject>! {
        NSObject.fw.invokeMethod(base, selector: selector, objects: objects)
    }

    /// 安全调用类方法，支持多个参数
    /// - Parameters:
    ///   - target: 调用的目标
    ///   - selector: 要执行的方法
    ///   - objects: 传递的参数数组，默认空
    /// - Returns: 方法返回值
    @discardableResult
    public static func invokeMethod(_ target: AnyObject, selector: Selector, objects: [Any]? = nil) -> Unmanaged<AnyObject>! {
        guard target.responds(to: selector),
              let signature = object_getClass(target)?.objcInstanceMethodSignature(for: selector),
              let invocationClass = ObjCClassBridge.invocationClass else {
            return nil
        }

        let invocation = invocationClass.objcInvocation(withMethodSignature: signature)
        invocation.objcTarget = target
        invocation.objcSelector = selector

        // 转换为NSArray的原因：自动桥接Swift类型参数为ObjC参数
        let arguments = objects as? NSArray
        let argCount = min(Int(signature.objcNumberOfArguments) - 2, arguments?.count ?? 0)
        for i in 0..<argCount {
            let argIndex = i + 2
            var argument = arguments?[i]
            if let number = argument as? NSNumber {
                let argumentType = signature.objcGetArgumentType(at: UInt(argIndex))
                let typeEncoding = ObjCTypeEncodingBridge(rawValue: argumentType.pointee) ?? .undefined
                switch typeEncoding {
                case .char:
                    argument = number.int8Value
                case .bool:
                    argument = number.boolValue
                case .int, .short, .long:
                    argument = number.intValue
                case .longLong:
                    argument = number.int64Value
                case .unsignedChar:
                    argument = number.uint8Value
                case .unsignedInt, .unsignedShort, .unsignedLong:
                    argument = number.uintValue
                case .unsignedLongLong:
                    argument = number.uint64Value
                case .float:
                    argument = number.floatValue
                case .double:
                    argument = number.doubleValue
                default:
                    break
                }
            }

            if argument is NSNull { argument = nil }
            withUnsafeMutablePointer(to: &argument) { pointer in
                invocation.objcSetArgument(pointer, at: argIndex)
            }
        }

        invocation.objcInvoke()
        let returnType = signature.objcMethodReturnType
        let typeEncoding = ObjCTypeEncodingBridge(rawValue: returnType.pointee) ?? .undefined
        let returnTypeString = String(utf8String: returnType)
        guard returnTypeString != "v" else {
            return nil
        }

        if returnTypeString == "@" {
            var cfResult: CFTypeRef?
            withUnsafeMutablePointer(to: &cfResult) { pointer in
                invocation.objcGetReturnValue(pointer)
            }
            return cfResult != nil ? Unmanaged.passRetained(cfResult!) : nil
        }

        func extract<U>(_ type: U.Type) -> U {
            let pointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<U>.size, alignment: MemoryLayout<U>.alignment)
            defer { pointer.deallocate() }

            invocation.objcGetReturnValue(pointer)
            return pointer.assumingMemoryBound(to: type).pointee
        }

        let value: Any?
        switch typeEncoding {
        case .char:
            value = NSNumber(value: extract(CChar.self))
        case .int:
            value = NSNumber(value: extract(CInt.self))
        case .short:
            value = NSNumber(value: extract(CShort.self))
        case .long:
            value = NSNumber(value: extract(CLong.self))
        case .longLong:
            value = NSNumber(value: extract(CLongLong.self))
        case .unsignedChar:
            value = NSNumber(value: extract(CUnsignedChar.self))
        case .unsignedInt:
            value = NSNumber(value: extract(CUnsignedInt.self))
        case .unsignedShort:
            value = NSNumber(value: extract(CUnsignedShort.self))
        case .unsignedLong:
            value = NSNumber(value: extract(CUnsignedLong.self))
        case .unsignedLongLong:
            value = NSNumber(value: extract(CUnsignedLongLong.self))
        case .float:
            value = NSNumber(value: extract(CFloat.self))
        case .double:
            value = NSNumber(value: extract(CDouble.self))
        case .bool:
            value = NSNumber(value: extract(CBool.self))
        case .object:
            value = extract((AnyObject?).self)
        case .type:
            value = extract((AnyClass?).self)
        case .selector:
            value = extract((Selector?).self)
        case .undefined:
            var size = 0, alignment = 0
            NSGetSizeAndAlignment(returnType, &size, &alignment)
            let buffer = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: alignment)
            defer { buffer.deallocate() }

            invocation.objcGetReturnValue(buffer)
            value = NSValue(bytes: buffer, objCType: returnType)
        }
        return value != nil ? Unmanaged.passRetained(value as AnyObject) : nil
    }

    // MARK: - Value
    /// 安全获取当前对象的指定属性值(非keyPath)
    public func value(forKey key: String) -> Any? {
        guard getterSelector(key) != nil else { return nil }
        return base.value(forKey: key)
    }

    /// 安全设置当前对象的指定属性值(非keyPath)
    public func setValue(_ value: Any?, forKey key: String) {
        guard setterSelector(key) != nil else { return }
        base.setValue(value, forKey: key)
    }

    // MARK: - Mirror
    /// 执行任意对象的反射属性句柄(含父类)
    public static func mirrorMap(_ object: Any, block: (String, Any) throws -> Void) rethrows {
        var mirror: Mirror! = Mirror(reflecting: object)
        while mirror != nil {
            for child in mirror.children where child.label != nil {
                try block(child.label!, child.value)
            }
            mirror = mirror.superclassMirror
        }
    }

    /// 获取任意对象的反射字典(含父类直至NSObject)，不含nil值
    public static func mirrorDictionary(_ object: Any?) -> [String: Any] {
        guard let object else { return [:] }
        var mirror = Mirror(reflecting: object)
        var children: [Mirror.Child] = []
        children += mirror.children
        while let superclassMirror = mirror.superclassMirror,
              superclassMirror.subjectType != NSObject.self {
            children += superclassMirror.children
            mirror = superclassMirror
        }

        var result: [String: Any] = [:]
        for child in children {
            if let label = child.label, !label.isEmpty,
               !Optional<Any>.isNil(child.value) {
                result[label] = child.value
            }
        }
        return result
    }
}

// MARK: - FrameworkConfiguration+Runtime
extension FrameworkConfiguration {
    fileprivate static var runtimeClassCaches: [String: [String]] = [:]
}
