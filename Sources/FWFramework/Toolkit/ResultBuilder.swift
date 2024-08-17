//
//  ResultBuilder.swift
//  FWFramework
//
//  Created by wuyong on 2024/8/26.
//

import UIKit

// MARK: - ArrayResultBuilder
/// 常用ArrayResultBuilder
///
/// [SwiftUIX](https://github.com/swiftuix/SwiftUIX)
@resultBuilder
public struct ArrayResultBuilder<Element> {
    @_optimize(speed) @_transparent
    public static func buildBlock() -> [Element] {
        return []
    }

    @_optimize(speed) @_transparent
    public static func buildBlock(_ element: Element) -> [Element] {
        return [element]
    }

    @_optimize(speed) @_transparent
    public static func buildBlock(_ elements: Element...) -> [Element] {
        return elements
    }
    
    @_optimize(speed) @_transparent
    public static func buildBlock(_ arrays: [Element]...) -> [Element] {
        arrays.flatMap({ $0 })
    }

    @_optimize(speed) @_transparent
    public static func buildEither(first component: Element) -> [Element] {
        return [component]
    }

    @_optimize(speed) @_transparent
    public static func buildEither(first component: [Element]) -> [Element] {
        return component
    }

    @_optimize(speed) @_transparent
    public static func buildEither(second component: [Element]) -> [Element] {
        component
    }

    @_optimize(speed) @_transparent
    public static func buildExpression(_ element: Element) -> [Element] {
        [element]
    }

    @_optimize(speed) @_transparent
    public static func buildExpression(_ element: Element?) -> [Element] {
        element.map({ [$0] }) ?? []
    }

    @_optimize(speed) @_transparent
    public static func buildExpression(_ elements: [Element]) -> [Element] {
        elements
    }

    @_optimize(speed) @_transparent
    public static func buildOptional(_ component: [Element]?) -> [Element] {
        return component ?? []
    }

    @_optimize(speed) @_transparent
    public static func buildArray(_ contents: [[Element]]) -> [Element] {
        contents.flatMap({ $0 })
    }
}

// MARK: - NSMutableAttributedString+ResultBuilder
extension NSMutableAttributedString {
    
    /// 拼接NSAttributedString
    public static func concatenate(
        @ArrayResultBuilder<AttributedStringParameter> _ items: () -> [AttributedStringParameter]
    ) -> Self {
        let result = Self.init()
        items().forEach { item in
            result.append(item.attributedStringValue)
        }
        return result
    }
    
    /// 初始化并拼接NSAttributedString
    public convenience init(
        @ArrayResultBuilder<AttributedStringParameter> _ items: () -> [AttributedStringParameter]
    ) {
        self.init()
        concatenate(items)
    }
    
    /// 拼接NSAttributedString
    @discardableResult
    public func concatenate(
        @ArrayResultBuilder<AttributedStringParameter> _ items: () -> [AttributedStringParameter]
    ) -> Self {
        items().forEach { item in
            append(item.attributedStringValue)
        }
        return self
    }
    
}

// MARK: - UIView+ResultBuilder
/// UIView兼容ArrayResultBuilder
@MainActor public protocol ViewResultBuilderCompatible {
    @_spi(FW) var resultBuilderView: UIView? { get }
}

extension UIView: ViewResultBuilderCompatible {
    @_spi(FW) public var resultBuilderView: UIView? { self }
}
extension LayoutChain: ViewResultBuilderCompatible {
    @_spi(FW) public var resultBuilderView: UIView? { view }
}

extension ViewResultBuilderCompatible where Self: UIView {
    
    /// 初始化并批量配置子视图
    public init(
        frame: CGRect = .zero,
        @ArrayResultBuilder<ViewResultBuilderCompatible> _ items: () -> [ViewResultBuilderCompatible]
    ) {
        self.init(frame: frame)
        arrangeSubviews(items)
    }
    
    /// 调用句柄配置视图，支持链式调用，用于兼容ArrayResultBuilder
    @discardableResult
    public func arrangeBlock(
        _ closure: (Self) -> Void
    ) -> Self {
        closure(self)
        return self
    }
    
    /// 配置指定keyPath属性值，支持链式调用
    @discardableResult
    public func arrangeValue<Value>(
        _ keyPath: ReferenceWritableKeyPath<Self, Value>,
        _ value: Value
    ) -> Self {
        self[keyPath: keyPath] = value
        return self
    }
    
    /// 批量配置子视图，支持链式调用
    @discardableResult
    public func arrangeSubviews(
        @ArrayResultBuilder<ViewResultBuilderCompatible> _ items: () -> [ViewResultBuilderCompatible]
    ) -> Self {
        items().forEach { item in
            if let view = item.resultBuilderView, view.superview == nil {
                addSubview(view)
            }
        }
        return self
    }
    
    /// 批量布局子视图，支持链式调用
    @discardableResult
    public func arrangeLayout(
        @ArrayResultBuilder<ViewResultBuilderCompatible> _ items: () -> [ViewResultBuilderCompatible]
    ) -> Self {
        _ = items()
        return self
    }
    
}
