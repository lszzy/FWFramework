//
//  ResultBuilder.swift
//  FWFramework
//
//  Created by wuyong on 2024/8/26.
//

import Foundation

// MARK: - ArrayResultBuilder
/// 常用ArrayResultBuilder
///
/// [SwiftUIX](https://github.com/swiftuix/SwiftUIX)
@resultBuilder
public struct ArrayResultBuilder<Element> {
    @_optimize(speed) @_transparent
    public static func buildBlock() -> [Element] {
        []
    }

    @_optimize(speed) @_transparent
    public static func buildBlock(_ element: Element) -> [Element] {
        [element]
    }

    @_optimize(speed) @_transparent
    public static func buildBlock(_ elements: Element...) -> [Element] {
        elements
    }

    @_optimize(speed) @_transparent
    public static func buildBlock(_ arrays: [Element]...) -> [Element] {
        arrays.flatMap { $0 }
    }

    @_optimize(speed) @_transparent
    public static func buildEither(first component: Element) -> [Element] {
        [component]
    }

    @_optimize(speed) @_transparent
    public static func buildEither(first component: [Element]) -> [Element] {
        component
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
        element.map { [$0] } ?? []
    }

    @_optimize(speed) @_transparent
    public static func buildExpression(_ elements: [Element]) -> [Element] {
        elements
    }

    @_optimize(speed) @_transparent
    public static func buildOptional(_ component: [Element]?) -> [Element] {
        component ?? []
    }

    @_optimize(speed) @_transparent
    public static func buildArray(_ contents: [[Element]]) -> [Element] {
        contents.flatMap { $0 }
    }
}

// MARK: - NSMutableAttributedString+ResultBuilder
extension NSMutableAttributedString {
    /// 拼接NSAttributedString
    public static func concatenate(
        @ArrayResultBuilder<AttributedStringParameter> _ items: () -> [AttributedStringParameter]
    ) -> Self {
        let result = Self()
        for item in items() {
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
        for item in items() {
            append(item.attributedStringValue)
        }
        return self
    }
}
