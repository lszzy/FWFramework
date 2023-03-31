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
public struct StateView: View {
    
    @State public var state: ViewState = .ready
    
    @ViewBuilder var ready: (Self) -> AnyView
    @ViewBuilder var loading: (Self) -> AnyView
    @ViewBuilder var content: (Self, Any?) -> AnyView
    @ViewBuilder var failure: (Self, Error?) -> AnyView
    
    public init<Content: View>(
        @ViewBuilder content: @escaping (Self, Any?) -> Content
    ) {
        self.ready = { $0.transition(to: .success()) }
        self.loading = { $0.transition(to: .success()) }
        self.content = { content($0, $1).eraseToAnyView() }
        self.failure = { $0.transition(to: .success($1)) }
    }
    
    public init<Loading: View, Content: View, Failure: View>(
        @ViewBuilder loading: @escaping (Self) -> Loading,
        @ViewBuilder content: @escaping (Self, Any?) -> Content,
        @ViewBuilder failure: @escaping (Self, Error?) -> Failure
    ) {
        self.ready = { $0.transition(to: .loading) }
        self.loading = { loading($0).eraseToAnyView() }
        self.content = { content($0, $1).eraseToAnyView() }
        self.failure = { failure($0, $1).eraseToAnyView() }
    }
    
    public init<Ready: View, Loading: View, Content: View, Failure: View>(
        @ViewBuilder ready: @escaping (Self) -> Ready,
        @ViewBuilder loading: @escaping (Self) -> Loading,
        @ViewBuilder content: @escaping (Self, Any?) -> Content,
        @ViewBuilder failure: @escaping (Self, Error?) -> Failure
    ) {
        self.ready = { ready($0).eraseToAnyView() }
        self.loading = { loading($0).eraseToAnyView() }
        self.content = { content($0, $1).eraseToAnyView() }
        self.failure = { failure($0, $1).eraseToAnyView() }
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
