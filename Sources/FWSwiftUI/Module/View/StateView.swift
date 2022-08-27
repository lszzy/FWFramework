//
//  StateView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#if canImport(SwiftUI)
import SwiftUI

// MARK: - StateView
/// SwiftUI视图状态枚举
@available(iOS 13.0, *)
public enum ViewState {
    case ready
    case loading
    case success(Any? = nil)
    case failure(Error? = nil)
}

/// SwiftUI状态视图
@available(iOS 13.0, *)
public struct StateView<Ready: View, Loading: View, Content: View, Failure: View>: View {
    
    @State public var state: ViewState = .ready
    
    @ViewBuilder var ready: (Self) -> Ready
    @ViewBuilder var loading: (Self) -> Loading
    @ViewBuilder var content: (Self, Any?) -> Content
    @ViewBuilder var failure: (Self, Error?) -> Failure
    
    public init(
        @ViewBuilder content: @escaping (Self, Any?) -> Content
    ) where Ready == AnyView, Loading == AnyView, Failure == AnyView {
        self.ready = { $0.transition(to: .success()) }
        self.loading = { $0.transition(to: .success()) }
        self.content = content
        self.failure = { stateView, _ in stateView.transition(to: .success()) }
    }
    
    public init(
        @ViewBuilder loading: @escaping (Self) -> Loading,
        @ViewBuilder content: @escaping (Self, Any?) -> Content,
        @ViewBuilder failure: @escaping (Self, Error?) -> Failure
    ) where Ready == AnyView {
        self.ready = { $0.transition(to: .loading) }
        self.loading = loading
        self.content = content
        self.failure = failure
    }
    
    public init(
        @ViewBuilder ready: @escaping (Self) -> Ready,
        @ViewBuilder loading: @escaping (Self) -> Loading,
        @ViewBuilder content: @escaping (Self, Any?) -> Content,
        @ViewBuilder failure: @escaping (Self, Error?) -> Failure
    ) {
        self.ready = ready
        self.loading = loading
        self.content = content
        self.failure = failure
    }
    
    private func transition(to newState: ViewState) -> AnyView {
        InvisibleView()
            .onAppear { state = newState }
            .eraseToAnyView()
    }
    
    public var body: some View {
        Group {
            switch state {
            case .ready:
                ready(self)
            case .loading:
                loading(self)
            case .success(let model):
                content(self, model)
            case .failure(let error):
                failure(self, error)
            }
        }
    }
    
}

#endif
