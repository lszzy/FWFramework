//
//  ViewPreference.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import SwiftUI

// MARK: - ViewPreferenceKey
/// 通用视图配置Key类
open class ViewPreferenceKey<T: Equatable>: PreferenceKey {
    public typealias Value = T?

    public static var defaultValue: Value {
        nil
    }

    public static func reduce(value: inout Value, nextValue: () -> Value) {
        let newValue = nextValue() ?? value
        if value != newValue {
            value = newValue
        }
    }
}

// MARK: - ViewSizePreferenceKey
private final class ViewSizePreferenceKey: ViewPreferenceKey<CGSize> {}

extension View {
    /// 捕获当前视图大小
    public func captureSize(in binding: Binding<CGSize>) -> some View {
        overlay(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: ViewSizePreferenceKey.self,
                    value: proxy.size
                )
                .onAppear {
                    if binding.wrappedValue != proxy.size {
                        binding.wrappedValue = proxy.size
                    }
                }
            }
        )
        .onPreferenceChange(ViewSizePreferenceKey.self) { size in
            if let size, binding.wrappedValue != size {
                binding.wrappedValue = size
            }
        }
        .preference(key: ViewSizePreferenceKey.self, value: nil)
    }
}

// MARK: - ViewContentOffsetPreferenceKey
private final class ViewContentOffsetPreferenceKey: ViewPreferenceKey<CGPoint> {}

extension View {
    /// 捕获当前滚动视图内容偏移，需滚动视图调用，且用GeometryReader包裹滚动视图
    ///
    /// 使用示例：
    /// GeometryReader { proxy in
    ///     List { ... }
    ///     .captureContentOffset(in: $contentOffsets)
    /// }
    public func captureContentOffset(in binding: Binding<CGPoint>) -> some View {
        onPreferenceChange(ViewContentOffsetPreferenceKey.self, perform: { value in
            binding.wrappedValue = value ?? .zero
        })
    }

    /// 捕获当前滚动视图内容偏移，需滚动视图第一个子视图调用
    ///
    /// 使用示例：
    /// GeometryReader { proxy in
    ///     List {
    ///       Cell
    ///       .captureContentOffset(proxy: proxy)
    ///
    ///       ...
    ///     }
    ///     .captureContentOffset(in: $contentOffsets)
    /// }
    public func captureContentOffset(proxy outsideProxy: GeometryProxy) -> some View {
        let outsideFrame = outsideProxy.frame(in: .global)

        return ZStack {
            GeometryReader { insideProxy in
                Color.clear.preference(
                    key: ViewContentOffsetPreferenceKey.self,
                    value: CGPoint(
                        x: outsideFrame.minX - insideProxy.frame(in: .global).minX,
                        y: outsideFrame.minY - insideProxy.frame(in: .global).minY
                    )
                )
                .frame(width: 0, height: 0)
            }
            self
        }
    }

    /// 监听当前滚动视图内容偏移实现悬停效果，需GeometryReader调用
    ///
    /// 使用示例：
    /// GeometryReader { proxy in
    ///     List {
    ///       Cell
    ///       .captureContentOffset(proxy: proxy)
    ///
    ///       ...
    ///     }
    ///     .captureContentOffset(in: $contentOffsets)
    /// }
    /// .hoverContentOffset(visible: contentOffset.y >= offset) {
    ///     ...
    /// }
    public func hoverContentOffset<Content: View>(
        alignment: Alignment = .top,
        visible: Bool = true,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            self

            content()
                .hidden(!visible)
        }
    }
}
