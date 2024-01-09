//
//  Swizzle+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/19.
//

import Foundation

// MARK: - NSObject+Swizzle
/// 实现block必须返回一个block，返回的block将被当成originalSelector的新实现，所以要在内部自己处理对super的调用，以及对当前调用方法的self的class的保护判断（因为如果originalClass的originalSelector是继承自父类的，originalClass内部并没有重写这个方法，则我们这个函数最终重写的其实是父类的originalSelector，所以会产生预期之外的class的影响，例如originalClass传进来UIButton.class，则最终可能会影响到UIView.class）。block的参数里第一个为你要修改的class，也即等同于originalClass，第二个参数为你要修改的selector，也即等同于originalSelector，第三个参数是一个block，用于获取originalSelector原本的实现，由于IMP可以直接当成C函数调用，所以可利用它来实现“调用 super”的效果，但由于originalSelector的参数个数、参数类型、返回值类型，都会影响IMP的调用写法，所以这个调用只能由业务自己写
extension Wrapper where Base: NSObject {
    
    // MARK: - Exchange
    /// 交换类实例方法。复杂情况可能会冲突
    /// - Parameters:
    ///   - originalSelector: 原始方法
    ///   - swizzleMethod: 交换方法
    /// - Returns: 是否成功
    @discardableResult
    public static func exchangeInstanceMethod(
        _ originalSelector: Selector,
        swizzleMethod: Selector
    ) -> Bool {
        return Base.fw_exchangeInstanceMethod(originalSelector, swizzleMethod: swizzleMethod)
    }
    
    /// 交换类静态方法。复杂情况可能会冲突
    /// - Parameters:
    ///   - originalSelector: 原始方法
    ///   - swizzleMethod: 交换方法
    /// - Returns: 是否成功
    @discardableResult
    public static func exchangeClassMethod(
        _ originalSelector: Selector,
        swizzleMethod: Selector
    ) -> Bool {
        return Base.fw_exchangeClassMethod(originalSelector, swizzleMethod: swizzleMethod)
    }
    
    /// 交换类实例方法为block实现。复杂情况可能会冲突
    ///
    /// swizzleBlock示例：
    /// ```objc
    /// ^(__unsafe_unretained UIViewController *selfObject, BOOL animated){ ((void(*)(id, SEL, BOOL))objc_msgSend)(selfObject, swizzleSelector, animated); }
    /// ```
    ///
    /// - Parameters:
    ///   - originalSelector: 原始方法
    ///   - swizzleMethod: 交换方法
    ///   - block: 实现block
    /// - Returns: 是否成功
    @discardableResult
    public static func exchangeInstanceMethod(
        _ originalSelector: Selector,
        swizzleMethod: Selector,
        block: Any
    ) -> Bool {
        return Base.fw_exchangeInstanceMethod(originalSelector, swizzleMethod: swizzleMethod, block: block)
    }

    /// 交换类静态方法为block实现。复杂情况可能会冲突
    ///
    /// - Parameters:
    ///   - originalSelector: 原始方法
    ///   - swizzleMethod: 交换方法
    ///   - block: 实现block
    /// - Returns: 是否成功
    @discardableResult
    public static func exchangeClassMethod(
        _ originalSelector: Selector,
        swizzleMethod: Selector,
        block: Any
    ) -> Bool {
        return Base.fw_exchangeClassMethod(originalSelector, swizzleMethod: swizzleMethod, block: block)
    }
    
    /// 生成原始方法对应的随机交换方法
    /// - Parameter selector: 原始方法
    /// - Returns: 交换方法
    public static func exchangeSwizzleSelector(
        _ selector: Selector
    ) -> Selector {
        return Base.fw_exchangeSwizzleSelector(selector)
    }

    // MARK: - Swizzle
    /// 通用swizzle替换方法为block实现，支持类和对象，identifier有值且相同时仅执行一次。复杂情况不会冲突，推荐使用
    ///
    /// Swift实现代码示例：
    /// ```swift
    /// NSObject.fw_swizzleMethod(
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
        return Base.fw_swizzleMethod(target, selector: selector, identifier: identifier, methodSignature: methodSignature, swizzleSignature: swizzleSignature, block: block)
    }
    
    /// 使用swizzle替换类实例方法为block实现，identifier有值且相同时仅执行一次。复杂情况不会冲突，推荐使用
    ///
    /// Swift实现代码示例：
    /// ```swift
    /// NSObject.fw_swizzleInstanceMethod(
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
        return Base.fw_swizzleInstanceMethod(originalClass, selector: selector, identifier: identifier, methodSignature: methodSignature, swizzleSignature: swizzleSignature, block: block)
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
        return Base.fw_swizzleClassMethod(originalClass, selector: selector, identifier: identifier, methodSignature: methodSignature, swizzleSignature: swizzleSignature, block: block)
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
        return base.fw_swizzleInstanceMethod(originalSelector, identifier: identifier, methodSignature: methodSignature, swizzleSignature: swizzleSignature, block: block)
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
        return base.fw_isSwizzleInstanceMethod(originalSelector, identifier: identifier)
    }
    
    /// 使用swizzle替换类实例dealloc方法为block实现，identifier有值且相同时仅执行一次。复杂情况不会冲突，推荐使用
    /// - Parameters:
    ///   - originalClass: 原始类
    ///   - identifier: 唯一标识，默认nil
    ///   - block: 实现句柄，参数为实例对象
    /// - Returns: 是否成功
    @discardableResult
    public static func swizzleDeallocMethod<T: NSObject>(
        _ originalClass: T.Type = T.self,
        identifier: String? = nil,
        block: @escaping (T) -> Void
    ) -> Bool {
        return Base.fw_swizzleDeallocMethod(originalClass, identifier: identifier) { object in
            block(object as! T)
        }
    }
    
}
