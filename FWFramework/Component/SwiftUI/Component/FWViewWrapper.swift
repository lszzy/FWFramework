//
//  FWViewWrapper.swift
//  FWFramework
//
//  Created by wuyong on 2020/11/9.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#if canImport(SwiftUI)
import SwiftUI

// MARK: - FWViewWrapper

/// SwiftUI通用UIView包装器
@available(iOS 13.0, *)
public struct FWViewWrapper<T: UIView>: UIViewRepresentable {
    
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
    public func maker(_ maker: @escaping () -> T) -> FWViewWrapper<T> {
        var result = self
        result.maker = maker
        return result
    }
    
    /// 设置updateUIView闭包
    public func updater(_ updater: @escaping (T) -> Void) -> FWViewWrapper<T> {
        var result = self
        result.updater = updater
        return result
    }
    
    // MARK: - UIViewRepresentable
    
    public typealias UIViewType = T
    
    public func makeUIView(context: Context) -> T {
        return maker?() ?? T()
    }
    
    public func updateUIView(_ uiView: T, context: Context) {
        updater?(uiView)
    }
}

// MARK: - FWViewControllerWrapper

/// SwiftUI通用UIViewController包装器
@available(iOS 13.0, *)
public struct FWViewControllerWrapper<T: UIViewController>: UIViewControllerRepresentable {
    
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
    public func maker(_ maker: @escaping () -> T) -> FWViewControllerWrapper<T> {
        var result = self
        result.maker = maker
        return result
    }
    
    /// 设置updateUIViewController闭包
    public func updater(_ updater: @escaping (T) -> Void) -> FWViewControllerWrapper<T> {
        var result = self
        result.updater = updater
        return result
    }
    
    // MARK: - UIViewControllerRepresentable
    
    public typealias UIViewControllerType = T
    
    public func makeUIViewController(context: Context) -> T {
        return maker?() ?? T()
    }
    
    public func updateUIViewController(_ uiViewController: T, context: Context) {
        updater?(uiViewController)
    }
}

#endif
