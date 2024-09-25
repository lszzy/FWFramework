//
//  ViewWrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#if canImport(SwiftUI)
import SwiftUI

// MARK: - ViewWrapper
/// 通用UIView包装器
public struct ViewWrapper<T: UIView>: UIViewRepresentable {
    var maker: (() -> T)?
    var updater: ((T) -> Void)?

    /// 指定makeUIView闭包初始化
    public init(_ maker: (() -> T)? = nil) {
        self.maker = maker
    }

    /// 指定updateUIView闭包初始化
    public init(updater: @escaping (T) -> Void) {
        self.updater = updater
    }

    /// 指定makeUIView闭包和updateUIView闭包初始化
    public init(_ maker: @escaping () -> T, updater: @escaping (T) -> Void) {
        self.maker = maker
        self.updater = updater
    }

    /// 设置makeUIView闭包
    public func maker(_ maker: @escaping () -> T) -> ViewWrapper<T> {
        var result = self
        result.maker = maker
        return result
    }

    /// 设置updateUIView闭包
    public func updater(_ updater: @escaping (T) -> Void) -> ViewWrapper<T> {
        var result = self
        result.updater = updater
        return result
    }

    // MARK: - UIViewRepresentable

    public typealias UIViewType = T

    public func makeUIView(context: Context) -> T {
        maker?() ?? T()
    }

    public func updateUIView(_ uiView: T, context: Context) {
        updater?(uiView)
    }
}

// MARK: - ViewControllerWrapper
/// 通用UIViewController包装器
public struct ViewControllerWrapper<T: UIViewController>: UIViewControllerRepresentable {
    var maker: (() -> T)?
    var updater: ((T) -> Void)?

    /// 指定makeUIViewController闭包初始化
    public init(_ maker: (() -> T)? = nil) {
        self.maker = maker
    }

    /// 指定updateUIViewController闭包初始化
    public init(updater: @escaping (T) -> Void) {
        self.updater = updater
    }

    /// 指定makeUIViewController闭包和updateUIViewController闭包初始化
    public init(_ maker: @escaping () -> T, updater: @escaping (T) -> Void) {
        self.maker = maker
        self.updater = updater
    }

    /// 设置makeUIViewController闭包
    public func maker(_ maker: @escaping () -> T) -> ViewControllerWrapper<T> {
        var result = self
        result.maker = maker
        return result
    }

    /// 设置updateUIViewController闭包
    public func updater(_ updater: @escaping (T) -> Void) -> ViewControllerWrapper<T> {
        var result = self
        result.updater = updater
        return result
    }

    // MARK: - UIViewControllerRepresentable

    public typealias UIViewControllerType = T

    public func makeUIViewController(context: Context) -> T {
        maker?() ?? T()
    }

    public func updateUIViewController(_ uiViewController: T, context: Context) {
        updater?(uiViewController)
    }
}

#endif
