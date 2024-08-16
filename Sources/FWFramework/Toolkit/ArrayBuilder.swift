//
//  ArrayBuilder.swift
//  FWFramework
//
//  Created by wuyong on 2024/8/26.
//

import UIKit

// MARK: - ArrayBuilder
/// 常用ArrayBuilder
///
/// [SwiftUIX](https://github.com/swiftuix/SwiftUIX)
@resultBuilder
public struct ArrayBuilder<Element> {
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
