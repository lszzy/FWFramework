//
//  Proxy.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation
#if FWMacroSPM
import FWObjC
#endif

// MARK: - WeakProxy
/// 弱引用代理类，用于解决NSTimer等循环引用target问题(默认NSTimer会强引用target,直到invalidate)
public class WeakProxy: NSObject {
    
    public weak var target: AnyObject?
    
    public init(target: NSObject) {
        super.init()
        self.target = target
    }
    
    public override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return target
    }
    
    public override func responds(to aSelector: Selector!) -> Bool {
        return target?.responds(to: aSelector) ?? false
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        return target?.isEqual(object) ?? false
    }
    
    public override var hash: Int {
        return target?.hash ?? 0
    }
    
    public override var superclass: AnyClass? {
        return target?.superclass
    }
    
    public override func isProxy() -> Bool {
        return true
    }
    
    public override func isKind(of aClass: AnyClass) -> Bool {
        return target?.isKind(of: aClass) ?? false
    }
    
    public override func isMember(of aClass: AnyClass) -> Bool {
        return target?.isMember(of: aClass) ?? false
    }
    
    public override func conforms(to aProtocol: Protocol) -> Bool {
        return target?.conforms(to: aProtocol) ?? false
    }
    
    public override var description: String {
        return target?.description ?? ""
    }
    
    public override var debugDescription: String {
        return target?.debugDescription ?? ""
    }
    
}

// MARK: - DelegateProxy
/// 事件协议代理基类，可继承重写事件代理方法
open class DelegateProxy<T>: NSObject {
    
    open weak var target: AnyObject?
    
    open var delegate: T? {
        get { return target as? T }
        set { target = newValue as? AnyObject }
    }
    
    open override func isProxy() -> Bool {
        return true
    }
    
    open override func forwardingTarget(for aSelector: Selector!) -> Any? {
        target
    }
    
    open override func conforms(to aProtocol: Protocol) -> Bool {
        if target?.conforms(to: aProtocol) ?? false {
            return true
        }
        return super.conforms(to: aProtocol)
    }
    
    open override func responds(to aSelector: Selector!) -> Bool {
        if target?.responds(to: aSelector) ?? false {
            return true
        }
        return super.responds(to: aSelector)
    }
    
}

// MARK: - WeakObject
/// 弱引用对象容器类，用于解决关联对象weak引用等
public class WeakObject: NSObject {
    
    public private(set) weak var object: AnyObject?
    
    public init(object: AnyObject?) {
        super.init()
        self.object = object
    }
    
}

// MARK: - MulticastDelegate
/// 多代理转发类
public class MulticastDelegate<T> {
    
    // MARK: - Accessor
    private let delegates: NSHashTable<AnyObject>
    
    /// 是否是空，不包含delegate
    public var isEmpty: Bool {
        return delegates.allObjects.isEmpty
    }

    // MARK: - Lifecycle
    /// 初始化，是否强引用delegate，默认false
    public init(strongReferences: Bool = false) {
        delegates = strongReferences ? NSHashTable<AnyObject>() : NSHashTable<AnyObject>.weakObjects()
    }
    
    /// 初始化，自定义引用选项
    public init(options: NSPointerFunctions.Options) {
        delegates = NSHashTable<AnyObject>(options: options, capacity: 0)
    }
    
    // MARK: - Public
    /// 添加delegate
    public func add(_ delegate: T) {
        delegates.add(delegate as AnyObject)
    }
    
    /// 移除delegate
    public func remove(_ delegate: T) {
        delegates.remove(delegate as AnyObject)
    }
    
    /// 移除所有delegate
    public func removeAll() {
        delegates.removeAllObjects()
    }
    
    /// 是否包含delegate
    public func contains(_ delegate: T) -> Bool {
        return delegates.contains(delegate as AnyObject)
    }
    
    /// 调用所有delegates代理方法，忽略返回结果
    public func invoke(_ block: (T) -> Void) {
        for delegate in delegates.allObjects {
            block(delegate as! T)
        }
    }
    
    /// 过滤并调用delegates代理方法，返回是否继续执行，为false时立即停止执行
    @discardableResult
    public func filter(_ filter: (T) -> Bool) -> Bool {
        for delegate in delegates.allObjects {
            if !filter(delegate as! T) {
                return false
            }
        }
        return true
    }
    
}
