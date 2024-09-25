//
//  Chainable.swift
//  FWFramework
//
//  Created by wuyong on 2024/8/17.
//

import Foundation

// MARK: - AnyChainable
public protocol AnyChainable {}

extension NSObject: AnyChainable {}

extension AnyChainable {
    /// 链式方式指定keyPath对应值，返回新对象
    public func chainValue<Value>(
        _ keyPath: WritableKeyPath<Self, Value>,
        _ value: Value
    ) -> Self {
        var result = self
        result[keyPath: keyPath] = value
        return result
    }

    /// 链式方式调用句柄，返回新对象
    public func chainBlock(
        _ closure: (inout Self) -> Void
    ) -> Self {
        var result = self
        closure(&result)
        return result
    }
}

extension AnyChainable where Self: AnyObject {
    /// 链式方式指定keyPath对应值，返回自身
    @discardableResult
    public func chainValue<Value>(
        _ keyPath: ReferenceWritableKeyPath<Self, Value>,
        _ value: Value
    ) -> Self {
        self[keyPath: keyPath] = value
        return self
    }

    /// 链式方式调用句柄，返回自身
    @discardableResult
    public func chainBlock(
        _ closure: (Self) -> Void
    ) -> Self {
        closure(self)
        return self
    }
}

// MARK: - Dictionary+Chainable
extension Dictionary {
    /// 链式方式指定key对应值，返回新字典
    public func chainValue(
        _ key: Key,
        _ value: Value?
    ) -> Self {
        var result = self
        result[key] = value
        return result
    }

    /// 链式方式调用句柄，返回新字典
    public func chainBlock(
        _ closure: (inout Self) -> Void
    ) -> Self {
        var result = self
        closure(&result)
        return result
    }
}
