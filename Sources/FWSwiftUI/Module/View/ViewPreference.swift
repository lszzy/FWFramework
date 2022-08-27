//
//  ViewPreference.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#if canImport(SwiftUI)
import SwiftUI

// MARK: - ViewPreferenceKey
/// 通用视图配置Key类
@available(iOS 13.0, *)
open class ViewPreferenceKey<T: Equatable>: PreferenceKey {
    public typealias Value = T?
    
    public static var defaultValue: Value {
        return nil
    }
    
    public static func reduce(value: inout Value, nextValue: () -> Value) {
        let newValue = nextValue() ?? value
        if value != newValue {
            value = newValue
        }
    }
}

// MARK: - ViewSizePreferenceKey
@available(iOS 13.0, *)
private final class ViewSizePreferenceKey: ViewPreferenceKey<CGSize> {}

@available(iOS 13.0, *)
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
            if let size = size, binding.wrappedValue != size {
                binding.wrappedValue = size
            }
        }
        .preference(key: ViewSizePreferenceKey.self, value: nil)
    }
    
}

// MARK: - ViewContentOffsetPreferenceKey
@available(iOS 13.0, *)
private final class ViewContentOffsetPreferenceKey: ViewPreferenceKey<CGPoint> {}

@available(iOS 13.0, *)
extension View {
    
    /// 捕获当前滚动视图内容偏移，需滚动视图调用，且用GeometryReader包裹滚动视图
    ///
    /// 使用示例：
    /// GeometryReader { proxy in
    ///     List { ... }
    ///     .captureContentOffset(in: $contentOffsets)
    /// }
    public func captureContentOffset(in binding: Binding<CGPoint>) -> some View {
        self.onPreferenceChange(ViewContentOffsetPreferenceKey.self, perform: { value in
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
    
}

#endif
