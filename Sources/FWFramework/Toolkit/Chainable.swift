//
//  Chainable.swift
//  FWFramework
//
//  Created by wuyong on 2024/8/17.
//

import UIKit

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

// MARK: - UIView+ResultBuilder
/// UIView兼容ArrayResultBuilder
public protocol ArrayResultBuilderCompatible {}

extension UIView: ArrayResultBuilderCompatible {}

@MainActor extension ArrayResultBuilderCompatible where Self: UIView {
    /// 初始化并批量配置子视图
    public init(
        frame: CGRect = .zero,
        @ArrayResultBuilder<UIView> _ subviews: () -> [UIView]
    ) {
        self.init(frame: frame)
        arrangeSubviews(subviews)
    }

    /// 批量配置子视图，支持链式调用
    @discardableResult
    public func arrangeSubviews(
        @ArrayResultBuilder<UIView> _ subviews: () -> [UIView]
    ) -> Self {
        for view in subviews() {
            if view.superview == nil {
                addSubview(view)
            }
        }
        return self
    }

    /// 调用布局句柄，支持链式调用
    @discardableResult
    public func arrangeLayout(
        _ block: (Self) -> Void
    ) -> Self {
        block(self)
        return self
    }
}
