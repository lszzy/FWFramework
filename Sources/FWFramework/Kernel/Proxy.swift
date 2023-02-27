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
public class WeakProxy: __FWWeakProxy {}

// MARK: - WeakObject
/// 弱引用对象容器类，用于解决关联对象weak引用等
public class WeakObject: __FWWeakObject {}

// MARK: - DelegateProxy
/// 事件协议代理基类，可继承重写事件代理方法
open class DelegateProxy<T>: __FWDelegateProxy {
    
    /// 泛型事件代理对象
    open var delegate: T? {
        get { return proxyDelegate as? T }
        set { proxyDelegate = newValue as? AnyObject }
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
    
    /// 过滤并调用delegates代理方法，返回是否调用成功，调用成功时立即停止
    @discardableResult
    public func filter(_ filter: (T) -> Bool) -> Bool {
        for delegate in delegates.allObjects {
            if filter(delegate as! T) {
                return true
            }
        }
        return false
    }
    
}
