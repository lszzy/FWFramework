//
//  ViewContext.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import Combine
import SwiftUI

/// 视图上下文
public class ViewContext: ObservableObject {
    // MARK: - ViewController
    /// 当前视图控制器
    public weak var viewController: UIViewController?

    /// 获取当前导航栏控制器
    @MainActor public weak var navigationController: UINavigationController? {
        viewController?.navigationController
    }

    /// 获取当前UIView根视图
    @MainActor public weak var hostingView: UIView? {
        viewController?.view
    }

    /// 获取当前AnyView根视图
    @MainActor public var rootView: AnyView? {
        if let hostingController = viewController as? UIHostingController<AnyView> {
            return hostingController.rootView
        }
        return nil
    }

    // MARK: - Object
    /// 自定义对象，自动广播，订阅方式：onReceive(viewContext.$object)
    @Published public var object: Any?

    // MARK: - UserInfo
    /// 自定义用户信息，可初始化时设置，也可修改后手动广播
    public var userInfo: [AnyHashable: Any]?

    // MARK: - Subject
    /// 上下文Subject，可订阅，需手工触发send发送广播
    public let subject = PassthroughSubject<ViewContext, Never>()

    /// 手动发送广播，一般修改userInfo后调用
    public func send() {
        subject.send(self)
    }

    // MARK: - Lifecycle
    /// 初始化方法，可指定视图控制器、自定义对象和用户信息
    public init(_ viewController: UIViewController?, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        self.viewController = viewController
        self.object = object
        self.userInfo = userInfo
    }
}

extension EnvironmentValues {
    /// 视图上下文Key
    private struct ViewContextKey: EnvironmentKey {
        static var defaultValue: ViewContext {
            ViewContext(nil)
        }
    }

    /// 访问视图上下文
    public var viewContext: ViewContext {
        get { self[ViewContextKey.self] }
        set { self[ViewContextKey.self] = newValue }
    }
}

@MainActor extension View {
    /// 设置视图上下文，可指定自定义对象
    public func viewContext(_ viewController: UIViewController?, object: Any? = nil) -> some View {
        environment(\.viewContext, ViewContext(viewController, object: object))
    }

    /// 设置视图上下文，可指定自定义对象和用户信息
    public func viewContext(_ viewController: UIViewController?, object: Any? = nil, userInfo: [AnyHashable: Any]?) -> some View {
        environment(\.viewContext, ViewContext(viewController, object: object, userInfo: userInfo))
    }

    /// 转换视图上下文，内部可使用DispatchQueue.main.async执行异步方法
    ///
    /// 如果要监听上下文变化，可使用如下方式：
    /// 1. onReceive(viewContext.subject)
    /// 2. onReceive(viewContext.$object)
    /// 3. viewContext.$object.receive(on: RunLoop.main)
    public func transformViewContext(transform: @escaping (ViewContext) -> Void) -> some View {
        transformEnvironment(\.viewContext) { viewContext in
            transform(viewContext)
        }
    }

    /// 快速包装视图到上下文控制器
    public func wrappedContextController() -> UIHostingController<AnyView> {
        let hostingController = UIHostingController(rootView: AnyView(EmptyView()))
        hostingController.rootView = AnyView(viewContext(hostingController))
        return hostingController
    }
}

extension UIHostingController where Content == AnyView {
    /// 快速创建视图上下文控制器
    public static func contextController<T: View>(@ViewBuilder content: () -> T) -> UIHostingController<AnyView> {
        let hostingController = UIHostingController(rootView: AnyView(EmptyView()))
        hostingController.rootView = AnyView(content().viewContext(hostingController))
        return hostingController
    }
}
