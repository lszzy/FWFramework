//
//  Swizzle.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/19.
//

import Foundation

// MARK: - Wrapper+NSObject
/// 实现block必须返回一个block，返回的block将被当成originalSelector的新实现，所以要在内部自己处理对super的调用，以及对当前调用方法的self的class的保护判断（因为如果originalClass的originalSelector是继承自父类的，originalClass内部并没有重写这个方法，则我们这个函数最终重写的其实是父类的originalSelector，所以会产生预期之外的class的影响，例如originalClass传进来UIButton.class，则最终可能会影响到UIView.class）。block的参数里第一个为你要修改的class，也即等同于originalClass，第二个参数为你要修改的selector，也即等同于originalSelector，第三个参数是一个block，用于获取originalSelector原本的实现，由于IMP可以直接当成C函数调用，所以可利用它来实现“调用 super”的效果，但由于originalSelector的参数个数、参数类型、返回值类型，都会影响IMP的调用写法，所以这个调用只能由业务自己写
extension Wrapper where Base: NSObject {
    // MARK: - Exchange
    /// 交换类实例方法。复杂情况可能会冲突
    /// - Parameters:
    ///   - originalClass: 目标类
    ///   - originalSelector: 原始方法
    ///   - swizzleSelector: 交换方法
    /// - Returns: 是否成功
    @discardableResult
    public static func exchangeInstanceMethod(
        _ originalClass: AnyClass,
        originalSelector: Selector,
        swizzleSelector: Selector
    ) -> Bool {
        let originalMethod = class_getInstanceMethod(originalClass, originalSelector)
        guard let swizzleMethod = class_getInstanceMethod(originalClass, swizzleSelector) else { return false }
        
        if let originalMethod = originalMethod {
            class_addMethod(originalClass, originalSelector, class_getMethodImplementation(originalClass, originalSelector)!, method_getTypeEncoding(originalMethod))
        } else {
            let impBlock: @convention(block) (Any) -> Void = { _ in }
            class_addMethod(originalClass, originalSelector, imp_implementationWithBlock(impBlock as Any), "v@:")
        }
        class_addMethod(originalClass, swizzleSelector, class_getMethodImplementation(originalClass, swizzleSelector)!, method_getTypeEncoding(swizzleMethod))
        method_exchangeImplementations(class_getInstanceMethod(originalClass, originalSelector)!, class_getInstanceMethod(originalClass, swizzleSelector)!)
        return true
    }
    
    /// 交换类静态方法。复杂情况可能会冲突
    /// - Parameters:
    ///   - originalClass: 目标类
    ///   - originalSelector: 原始方法
    ///   - swizzleSelector: 交换方法
    /// - Returns: 是否成功
    @discardableResult
    public static func exchangeClassMethod(
        _ originalClass: AnyClass,
        originalSelector: Selector,
        swizzleSelector: Selector
    ) -> Bool {
        guard let metaClass = object_getClass(originalClass) else { return false }
        return exchangeInstanceMethod(metaClass, originalSelector: originalSelector, swizzleSelector: swizzleSelector)
    }
    
    /// 交换类实例方法为block实现。复杂情况可能会冲突
    ///
    /// swizzleBlock示例：
    /// ```objc
    /// ^(__unsafe_unretained UIViewController *selfObject, BOOL animated){ ((void(*)(id, SEL, BOOL))objc_msgSend)(selfObject, swizzleSelector, animated); }
    /// ```
    ///
    /// - Parameters:
    ///   - originalClass: 目标类
    ///   - originalSelector: 原始方法
    ///   - swizzleSelector: 交换方法
    ///   - block: 实现block
    /// - Returns: 是否成功
    @discardableResult
    public static func exchangeInstanceMethod(
        _ originalClass: AnyClass,
        originalSelector: Selector,
        swizzleSelector: Selector,
        block: Any
    ) -> Bool {
        guard let originalMethod = class_getInstanceMethod(originalClass, originalSelector) else { return false }
        let swizzleMethod = class_getInstanceMethod(originalClass, swizzleSelector)
        guard swizzleMethod == nil else { return false }
        
        class_addMethod(originalClass, originalSelector, class_getMethodImplementation(originalClass, originalSelector)!, method_getTypeEncoding(originalMethod))
        class_addMethod(originalClass, swizzleSelector, imp_implementationWithBlock(block), method_getTypeEncoding(originalMethod))
        method_exchangeImplementations(class_getInstanceMethod(originalClass, originalSelector)!, class_getInstanceMethod(originalClass, swizzleSelector)!)
        return true
    }

    /// 交换类静态方法为block实现。复杂情况可能会冲突
    ///
    /// - Parameters:
    ///   - originalClass: 目标类
    ///   - originalSelector: 原始方法
    ///   - swizzleSelector: 交换方法
    ///   - block: 实现block
    /// - Returns: 是否成功
    @discardableResult
    public static func exchangeClassMethod(
        _ originalClass: AnyClass,
        originalSelector: Selector,
        swizzleSelector: Selector,
        block: Any
    ) -> Bool {
        guard let metaClass = object_getClass(originalClass) else { return false }
        return exchangeInstanceMethod(metaClass, originalSelector: originalSelector, swizzleSelector: swizzleSelector, block: block)
    }
    
    /// 生成原始方法对应的随机交换方法
    /// - Parameter selector: 原始方法
    /// - Returns: 交换方法
    public static func exchangeSwizzleSelector(
        _ selector: Selector
    ) -> Selector {
        return NSSelectorFromString("swizzle_\(arc4random())_\(NSStringFromSelector(selector))")
    }

    // MARK: - SwizzleStore
    /// 通用swizzle替换方法为block实现，支持类和对象，identifier有值且相同时仅执行一次。复杂情况不会冲突，推荐使用
    ///
    /// Swift实现代码示例：
    /// ```swift
    /// NSObject.fw.swizzleMethod(
    ///     UIViewController.self,
    ///     selector: #selector(UIViewController.viewDidLoad)
    /// ) { (store: SwizzleStore
    ///      <@convention(c) (UIViewController, Selector) -> Void,
    ///      @convention(block) (UIViewController) -> Void>) in {
    ///     store.original($0, store.selector)
    ///     // ...
    /// }}
    /// ```
    ///
    /// - Parameters:
    ///   - target: 目标类或对象
    ///   - selector: 原始方法
    ///   - identifier: 唯一标识，有值且相同时仅执行一次，默认nil
    ///   - methodSignature: 原始方法签名，示例：(@convention(c) (AnyObject, Selector) -> String).self
    ///   - swizzleSignature: 交换方法签名，示例：(@convention(block) (AnyObject) -> String).self
    ///   - block: 实现句柄，示例：{ store in { selfObject in return store.original(selfObject, store.selector) } }
    /// - Returns: 是否成功
    @discardableResult
    public static func swizzleMethod<MethodSignature, SwizzleSignature>(
        _ target: Any?,
        selector: Selector,
        identifier: String? = nil,
        methodSignature: MethodSignature.Type = MethodSignature.self,
        swizzleSignature: SwizzleSignature.Type = SwizzleSignature.self,
        block: @escaping (SwizzleStore<MethodSignature, SwizzleSignature>) -> SwizzleSignature
    ) -> Bool {
        let swizzleBlock = swizzleBlock(methodSignature: methodSignature, swizzleSignature: swizzleSignature, block: block)
        return swizzleMethod(target, selector: selector, identifier: identifier, block: swizzleBlock)
    }
    
    /// 使用swizzle替换类实例方法为block实现，identifier有值且相同时仅执行一次。复杂情况不会冲突，推荐使用
    ///
    /// Swift实现代码示例：
    /// ```swift
    /// NSObject.fw.swizzleInstanceMethod(
    ///     UIViewController.self,
    ///     selector: #selector(UIViewController.viewDidLoad),
    ///     methodSignature: (@convention(c) (UIViewController, Selector) -> Void).self,
    ///     swizzleSignature: (@convention(block) (UIViewController) -> Void).self
    /// ) { store in { selfObject in
    ///     store.original(selfObject, store.selector)
    ///     // ...
    /// }}
    /// ```
    ///
    /// - Parameters:
    ///   - originalClass: 原始类
    ///   - selector: 原始方法
    ///   - identifier: 唯一标识，默认nil
    ///   - methodSignature: 原始方法签名，示例：(@convention(c) (AnyObject, Selector) -> String).self
    ///   - swizzleSignature: 交换方法签名，示例：(@convention(block) (AnyObject) -> String).self
    ///   - block: 实现句柄，示例：{ store in { selfObject in return store.original(selfObject, store.selector) } }
    /// - Returns: 是否成功
    @discardableResult
    public static func swizzleInstanceMethod<MethodSignature, SwizzleSignature>(
        _ originalClass: AnyClass,
        selector: Selector,
        identifier: String? = nil,
        methodSignature: MethodSignature.Type = MethodSignature.self,
        swizzleSignature: SwizzleSignature.Type = SwizzleSignature.self,
        block: @escaping (SwizzleStore<MethodSignature, SwizzleSignature>) -> SwizzleSignature
    ) -> Bool {
        let swizzleBlock = swizzleBlock(methodSignature: methodSignature, swizzleSignature: swizzleSignature, block: block)
        return swizzleInstanceMethod(originalClass, selector: selector, identifier: identifier, block: swizzleBlock)
    }

    /// 使用swizzle替换类静态方法为block实现，identifier有值且相同时仅执行一次。复杂情况不会冲突，推荐使用
    /// - Parameters:
    ///   - originalClass: 原始类
    ///   - selector: 原始方法
    ///   - identifier: 唯一标识，默认nil
    ///   - methodSignature: 原始方法签名，示例：(@convention(c) (AnyObject, Selector) -> String).self
    ///   - swizzleSignature: 交换方法签名，示例：(@convention(block) (AnyObject) -> String).self
    ///   - block: 实现句柄，示例：{ store in { selfObject in return store.original(selfObject, store.selector) } }
    /// - Returns: 是否成功
    @discardableResult
    public static func swizzleClassMethod<MethodSignature, SwizzleSignature>(
        _ originalClass: AnyClass,
        selector: Selector,
        identifier: String? = nil,
        methodSignature: MethodSignature.Type = MethodSignature.self,
        swizzleSignature: SwizzleSignature.Type = SwizzleSignature.self,
        block: @escaping (SwizzleStore<MethodSignature, SwizzleSignature>) -> SwizzleSignature
    ) -> Bool {
        let swizzleBlock = swizzleBlock(methodSignature: methodSignature, swizzleSignature: swizzleSignature, block: block)
        return swizzleClassMethod(originalClass, selector: selector, identifier: identifier, block: swizzleBlock)
    }
    
    /// 使用swizzle替换对象实例方法为block实现，identifier相同时仅执行一次。结合isSwizzleInstanceMethod使用
    /// - Parameters:
    ///   - originalSelector: 原始方法
    ///   - identifier: 唯一标识，默认空字符串
    ///   - methodSignature: 原始方法签名，示例：(@convention(c) (AnyObject, Selector) -> String).self
    ///   - swizzleSignature: 交换方法签名，示例：(@convention(block) (AnyObject) -> String).self
    ///   - block: 实现句柄，示例：{ store in { selfObject in return store.original(selfObject, store.selector) } }
    /// - Returns: 是否成功
    @discardableResult
    public func swizzleInstanceMethod<MethodSignature, SwizzleSignature>(
        _ originalSelector: Selector,
        identifier: String = "",
        methodSignature: MethodSignature.Type = MethodSignature.self,
        swizzleSignature: SwizzleSignature.Type = SwizzleSignature.self,
        block: @escaping (SwizzleStore<MethodSignature, SwizzleSignature>) -> SwizzleSignature
    ) -> Bool {
        let swizzleBlock = NSObject.fw.swizzleBlock(methodSignature: methodSignature, swizzleSignature: swizzleSignature, block: block)
        return swizzleInstanceMethod(originalSelector, identifier: identifier, block: swizzleBlock)
    }
    
    private static func swizzleBlock<MethodSignature, SwizzleSignature>(
        methodSignature: MethodSignature.Type = MethodSignature.self,
        swizzleSignature: SwizzleSignature.Type = SwizzleSignature.self,
        block: @escaping (SwizzleStore<MethodSignature, SwizzleSignature>) -> SwizzleSignature
    ) -> (AnyClass, Selector, @escaping () -> IMP) -> Any {
        return { targetClass, originalCMD, originalIMP in
            let originalMSG: MethodSignature = unsafeBitCast(originalIMP(), to: MethodSignature.self)
            let swizzleStore = SwizzleStore<MethodSignature, SwizzleSignature>(class: targetClass, selector: originalCMD, original: originalMSG)
            let swizzleIMP: SwizzleSignature = block(swizzleStore)
            return unsafeBitCast(swizzleIMP, to: AnyObject.self)
        }
    }
    
    // MARK: - Swizzle
    /// 通用swizzle替换方法为block实现，支持类和对象，identifier有值且相同时仅执行一次。复杂情况不会冲突，推荐使用
    ///
    /// Swift实现代码示例：
    /// ```swift
    /// NSObject.fw.swizzleInstanceMethod(UIViewController.self, selector: NSSelectorFromString("viewDidLoad")) { targetClass, originalCMD, originalIMP in
    ///     let swizzleIMP: @convention(block)(UIViewController) -> Void = { selfObject in
    ///         let originalMSG = unsafeBitCast(originalIMP(), to: (@convention(c)(UIViewController, Selector) -> Void).self)
    ///         originalMSG(selfObject, originalCMD)
    ///
    ///         // ...
    ///     }
    ///     return unsafeBitCast(swizzleIMP, to: AnyObject.self)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - target: 目标类或对象
    ///   - selector: 原始方法
    ///   - identifier: 唯一标识，有值且相同时仅执行一次，默认nil
    ///   - block: 实现句柄
    /// - Returns: 是否成功
    @discardableResult
    public static func swizzleMethod(
        _ target: Any?,
        selector: Selector,
        identifier: String? = nil,
        block: @escaping (AnyClass, Selector, @escaping () -> IMP) -> Any
    ) -> Bool {
        guard let target = target else { return false }

        if object_isClass(target), let targetClass = target as? AnyClass {
            return swizzleInstanceMethod(targetClass, selector: selector, identifier: identifier, block: block)
        } else {
            guard let objectClass = object_getClass(target) else { return false }
            let swizzleIdentifier = swizzleIdentifier(target, selector: selector, identifier: identifier ?? "")
            NSObject.fw.setAssociatedObject(target, key: swizzleIdentifier, value: true, policy: .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return swizzleInstanceMethod(objectClass, selector: selector, identifier: identifier ?? "", block: block)
        }
    }
    
    /// 使用swizzle替换类实例方法为block实现，identifier有值且相同时仅执行一次。复杂情况不会冲突，推荐使用
    ///
    /// Swift实现代码示例：
    /// ```swift
    /// NSObject.fw.swizzleInstanceMethod(UIViewController.self, selector: NSSelectorFromString("viewDidLoad")) { targetClass, originalCMD, originalIMP in
    ///     let swizzleIMP: @convention(block)(UIViewController) -> Void = { selfObject in
    ///         let originalMSG = unsafeBitCast(originalIMP(), to: (@convention(c)(UIViewController, Selector) -> Void).self)
    ///         originalMSG(selfObject, originalCMD)
    ///
    ///         // ...
    ///     }
    ///     return unsafeBitCast(swizzleIMP, to: AnyObject.self)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - originalClass: 原始类
    ///   - selector: 原始方法
    ///   - identifier: 唯一标识，默认nil
    ///   - block: 实现句柄
    /// - Returns: 是否成功
    @discardableResult
    public static func swizzleInstanceMethod(
        _ originalClass: AnyClass,
        selector: Selector,
        identifier: String? = nil,
        block: @escaping (AnyClass, Selector, @escaping () -> IMP) -> Any
    ) -> Bool {
        guard let identifier = identifier, !identifier.isEmpty else {
            return swizzleClass(originalClass, selector: selector, block: block)
        }
        
        objc_sync_enter(NSObject.innerSwizzleIdentifiers)
        defer { objc_sync_exit(NSObject.innerSwizzleIdentifiers) }
        
        let swizzleIdentifier = String(format: "%@%@%@-%@", NSStringFromClass(originalClass), class_isMetaClass(originalClass) ? "+" : "-", NSStringFromSelector(selector), identifier)
        if !NSObject.innerSwizzleIdentifiers.contains(swizzleIdentifier) {
            NSObject.innerSwizzleIdentifiers.add(swizzleIdentifier)
            return swizzleClass(originalClass, selector: selector, block: block)
        }
        return false
    }

    /// 使用swizzle替换类静态方法为block实现，identifier有值且相同时仅执行一次。复杂情况不会冲突，推荐使用
    ///
    /// - Parameters:
    ///   - originalClass: 原始类
    ///   - selector: 原始方法
    ///   - identifier: 唯一标识，默认nil
    ///   - block: 实现句柄
    /// - Returns: 是否成功
    @discardableResult
    public static func swizzleClassMethod(
        _ originalClass: AnyClass,
        selector: Selector,
        identifier: String? = nil,
        block: @escaping (AnyClass, Selector, @escaping () -> IMP) -> Any
    ) -> Bool {
        guard let metaClass = object_getClass(originalClass) else { return false }
        return swizzleInstanceMethod(metaClass, selector: selector, identifier: identifier, block: block)
    }
    
    /// 使用swizzle替换对象实例方法为block实现，identifier相同时仅执行一次。结合isSwizzleInstanceMethod使用
    ///
    /// - Parameters:
    ///   - originalSelector: 原始方法
    ///   - identifier: 唯一标识，默认空字符串
    ///   - block: 实现句柄
    /// - Returns: 是否成功
    @discardableResult
    public func swizzleInstanceMethod(
        _ originalSelector: Selector,
        identifier: String = "",
        block: @escaping (AnyClass, Selector, @escaping () -> IMP) -> Any
    ) -> Bool {
        guard let objectClass = object_getClass(base) else { return false }
        let swizzleIdentifier = NSObject.fw.swizzleIdentifier(base, selector: originalSelector, identifier: identifier)
        setProperty(true, forName: swizzleIdentifier)
        return NSObject.fw.swizzleInstanceMethod(objectClass, selector: originalSelector, identifier: identifier, block: block)
    }
    
    /// 判断对象是否使用swizzle替换过指定identifier实例方法。结合swizzleInstanceMethod使用
    ///
    /// 因为实际替换的是类方法，为了防止影响该类其它对象，需先判断该对象是否替换过，仅替换过才执行自定义流程
    /// - Parameters:
    ///   - originalSelector: 原始方法
    ///   - identifier: 唯一标识，默认空字符串
    /// - Returns: 是否替换
    public func isSwizzleInstanceMethod(
        _ originalSelector: Selector,
        identifier: String = ""
    ) -> Bool {
        let swizzleIdentifier = NSObject.fw.swizzleIdentifier(base, selector: originalSelector, identifier: identifier)
        return property(forName: swizzleIdentifier) != nil
    }
    
    private static func swizzleIdentifier(_ object: Any, selector: Selector, identifier: String) -> String {
        var classIdentifier = ""
        if let objectClass = object_getClass(object) {
            classIdentifier = NSStringFromClass(objectClass)
        }
        return classIdentifier + "_" + NSStringFromSelector(selector) + "_" + identifier
    }
    
    private static func swizzleClass(
        _ originalClass: AnyClass,
        selector originalSelector: Selector,
        block: @escaping (AnyClass, Selector, @escaping () -> IMP) -> Any
    ) -> Bool {
        let originalMethod = class_getInstanceMethod(originalClass, originalSelector)
        let imp = originalMethod != nil ? method_getImplementation(originalMethod!) : nil
        var isOverride = false
        if let originalMethod = originalMethod {
            let superclassMethod = class_getInstanceMethod(class_getSuperclass(originalClass), originalSelector)
            if superclassMethod == nil {
                isOverride = true
            } else {
                isOverride = (originalMethod != superclassMethod)
            }
        }
        
        let originalIMP: () -> IMP = {
            var result: IMP?
            if isOverride {
                result = imp
            } else {
                let superclass: AnyClass? = class_getSuperclass(originalClass)
                result = class_getMethodImplementation(superclass, originalSelector)
            }
            if result == nil {
                let impBlock: @convention(block) (Any) -> Void = { _ in }
                result = imp_implementationWithBlock(impBlock)
            }
            return result!
        }
        
        if isOverride {
            method_setImplementation(originalMethod!, imp_implementationWithBlock(block(originalClass, originalSelector, originalIMP)))
        } else {
            var typeEncoding = originalMethod != nil ? method_getTypeEncoding(originalMethod!) : nil
            if typeEncoding == nil {
                let methodSignature = originalClass.objcInstanceMethodSignature(for: originalSelector)
                let typeSelector = NSSelectorFromString(String(format: "_%@String", "type"))
                let typeString = methodSignature.responds(to: typeSelector) ? methodSignature.perform(typeSelector)?.takeUnretainedValue() as? NSString : nil
                typeEncoding = typeString?.utf8String
            }
            
            class_addMethod(originalClass, originalSelector, imp_implementationWithBlock(block(originalClass, originalSelector, originalIMP)), typeEncoding)
        }
        return true
    }
}

// MARK: - NSObject+Swizzle
extension NSObject {
    
    fileprivate static var innerSwizzleIdentifiers = NSMutableSet()
    
}

// MARK: - SwizzleStore
/// 方法交换存储器
///
/// MethodSignature示例：(@convention(c) (NSObject, Selector) -> Void).self
/// SwizzleSignature示例：(@convention(block) (NSObject) -> Void).self
public class SwizzleStore<MethodSignature, SwizzleSignature>: @unchecked Sendable {
    
    /// 交换类
    public let `class`: AnyClass
    /// 交换方法
    public let selector: Selector
    /// 方法原始实现
    public let original: MethodSignature
    
    /// 内部初始化方法
    init(`class`: AnyClass, selector: Selector, original: MethodSignature) {
        self.class = `class`
        self.selector = selector
        self.original = original
    }
    
}
