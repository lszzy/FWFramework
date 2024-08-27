//
//  StateView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#if canImport(SwiftUI)
import SwiftUI
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - StateView
/// SwiftUI状态视图
///
/// \@State: 内部值传递，赋值时会触发View刷新
/// \@Binding: 外部引用传递，实现向外传递引用
/// \@ObservableObject: 可被订阅的对象，属性标记@Published时生效
/// \@ObservedObject: View订阅监听，收到通知时刷新View，不被View持有，随时可能被销毁，适合外部数据
/// \@EnvironmentObject: 全局环境对象，使用environmentObject方法绑定，View及其子层级可直接读取
/// \@StateObject: View引用对象，生命周期和View保持一致，刷新时数据会保持直到View被销毁
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
            case let .success(object):
                content(self, object)
            case let .failure(error):
                failure(self, error)
            }
        }
    }
}

// MARK: - InvisibleView
/// 不可见视图，当某个场景EmptyView不生效时可使用InvisibleView替代，比如EmptyView不触发onAppear
public struct InvisibleView: View {
    public init() {}

    public var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
            .accessibility(hidden: true)
    }
}

#endif
