//
//  FWViewWrapper.swift
//  FWFramework
//
//  Created by wuyong on 2020/11/9.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#if canImport(SwiftUI)
import SwiftUI
#endif

// MARK: - FWViewWrapper

/// SwiftUI通用UIView包装器
@available(iOS 13.0, *)
public struct FWViewWrapper<T: UIView>: UIViewRepresentable {
    
    var maker: (() -> T)?
    var updater: ((T) -> Void)?
    
    public init(_ maker: (() -> T)? = nil) {
        self.maker = maker
    }
    
    public init(updater: @escaping (T) -> Void) {
        self.updater = updater
    }
    
    public init(_ maker: @escaping () -> T, updater: @escaping (T) -> Void) {
        self.maker = maker
        self.updater = updater
    }
    
    public func maker(_ maker: @escaping () -> T) -> FWViewWrapper<T> {
        var result = self
        result.maker = maker
        return result
    }
    
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
    
    public init(_ maker: (() -> T)? = nil) {
        self.maker = maker
    }
    
    public init(updater: @escaping (T) -> Void) {
        self.updater = updater
    }
    
    public init(_ maker: @escaping () -> T, updater: @escaping (T) -> Void) {
        self.maker = maker
        self.updater = updater
    }
    
    public func maker(_ maker: @escaping () -> T) -> FWViewControllerWrapper<T> {
        var result = self
        result.maker = maker
        return result
    }
    
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
