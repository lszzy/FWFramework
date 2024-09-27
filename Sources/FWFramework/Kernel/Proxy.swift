//
//  Proxy.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation

// MARK: - WeakProxy
/// 弱引用代理类，用于解决NSTimer等循环引用target问题(默认NSTimer会强引用target,直到invalidate)
@objc(ObjCWeakProxy)
public class WeakProxy: NSObject {
    public weak var target: AnyObject?

    public init(target: NSObject) {
        super.init()
        self.target = target
    }

    override public func forwardingTarget(for aSelector: Selector!) -> Any? {
        target
    }

    override public func responds(to aSelector: Selector!) -> Bool {
        target?.responds(to: aSelector) ?? false
    }

    override public func isEqual(_ object: Any?) -> Bool {
        target?.isEqual(object) ?? false
    }

    override public var hash: Int {
        target?.hash ?? 0
    }

    override public var superclass: AnyClass? {
        target?.superclass
    }

    override public func isProxy() -> Bool {
        true
    }

    override public func isKind(of aClass: AnyClass) -> Bool {
        target?.isKind(of: aClass) ?? false
    }

    override public func isMember(of aClass: AnyClass) -> Bool {
        target?.isMember(of: aClass) ?? false
    }

    override public func conforms(to aProtocol: Protocol) -> Bool {
        target?.conforms(to: aProtocol) ?? false
    }

    override public var description: String {
        target?.description ?? ""
    }

    override public var debugDescription: String {
        target?.debugDescription ?? ""
    }
}

// MARK: - DelegateProxy
/// 事件协议代理基类，可继承重写事件代理方法
open class DelegateProxy<T>: NSObject {
    open weak var target: AnyObject?

    open var delegate: T? {
        get { target as? T }
        set { target = newValue as? AnyObject }
    }

    override open func isProxy() -> Bool {
        true
    }

    override open func forwardingTarget(for aSelector: Selector!) -> Any? {
        target
    }

    override open func conforms(to aProtocol: Protocol) -> Bool {
        if target?.conforms(to: aProtocol) ?? false {
            return true
        }
        return super.conforms(to: aProtocol)
    }

    override open func responds(to aSelector: Selector!) -> Bool {
        if target?.responds(to: aSelector) ?? false {
            return true
        }
        return super.responds(to: aSelector)
    }
}

// MARK: - WeakValue
/// 弱引用值容器类，用于解决关联值weak引用问题
public class WeakValue: @unchecked Sendable {
    public weak var value: AnyObject?

    public init(_ value: AnyObject? = nil) {
        self.value = value
    }
}

// MARK: - SendableValue
/// Sendable值容器类，用于解决任意值Sendable传参问题
public class SendableValue<T>: @unchecked Sendable {
    public var value: T {
        get {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            return _value
        }
        set {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            _value = newValue
        }
    }

    private var _value: T

    public init(_ value: T) {
        self._value = value
    }
}

// MARK: - MulticastDelegate
/// 多代理转发类
public class MulticastDelegate<T> {
    // MARK: - Accessor
    private let delegates: NSHashTable<AnyObject>

    /// 是否是空，不包含delegate
    public var isEmpty: Bool {
        delegates.allObjects.isEmpty
    }

    // MARK: - Lifecycle
    /// 初始化，是否强引用delegate，默认false
    public init(strongReferences: Bool = false) {
        self.delegates = strongReferences ? NSHashTable<AnyObject>() : NSHashTable<AnyObject>.weakObjects()
    }

    /// 初始化，自定义引用选项
    public init(options: NSPointerFunctions.Options) {
        self.delegates = NSHashTable<AnyObject>(options: options, capacity: 0)
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
        delegates.contains(delegate as AnyObject)
    }

    /// 调用所有delegates代理方法
    public func invoke(_ block: (T) -> Void) {
        for delegate in delegates.allObjects {
            block(delegate as! T)
        }
    }
}
