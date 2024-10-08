//
//  ViewProtocol.swift
//  FWFramework
//
//  Created by wuyong on 2024/6/5.
//

import UIKit

// MARK: - SetupViewProtocol
/// 通用视图初始化协议，init自动调用
///
/// 渲染数据规范示例：
/// 1. 无需外部数据时，实现 setupData() ，示例如下：
/// ```swift
/// func setupData() {
///     ...
/// }
/// ```
///
/// 2. 需外部数据时，实现：configure(...)，示例如下：
/// ```swift
/// func configure(model: Model) {
///     ...
/// }
/// ```
@MainActor public protocol SetupViewProtocol {
    /// 初始化完成，init自动调用，默认空实现
    func didInitialize()

    /// 初始化子视图，init自动调用，默认空实现
    func setupSubviews()

    /// 初始化布局，init自动调用，默认空实现
    func setupLayout()
}

extension SetupViewProtocol where Self: UIView {
    /// 初始化完成，init自动调用，默认空实现
    public func didInitialize() {}

    /// 初始化子视图，init自动调用，默认空实现
    public func setupSubviews() {}

    /// 初始化布局，init自动调用，默认空实现
    public func setupLayout() {}
}

// MARK: - EventViewProtocol
/// 通用事件视图代理，可继承也可直接使用
@MainActor public protocol EventViewDelegate: AnyObject {
    /// 事件已触发代理方法，默认空实现
    func eventTriggered(_ view: UIView, event: Notification)
}

extension EventViewDelegate {
    /// 事件已触发代理方法，默认空实现
    public func eventTriggered(_ view: UIView, event: Notification) {}
}

/// 通用事件视图协议，可选使用
@MainActor public protocol EventViewProtocol {}

extension EventViewProtocol where Self: UIView {
    /// 弱引用事件代理
    public weak var eventDelegate: EventViewDelegate? {
        get { fw.property(forName: "eventDelegate") as? EventViewDelegate }
        set { fw.setPropertyWeak(newValue, forName: "eventDelegate") }
    }

    /// 事件已触发句柄，同eventDelegate.eventTriggered方法，句柄方式
    public var eventTriggered: ((Notification) -> Void)? {
        get { fw.property(forName: "eventTriggered") as? (Notification) -> Void }
        set { fw.setPropertyCopy(newValue, forName: "eventTriggered") }
    }

    /// 触发指定事件，通知代理，参数为通知对象
    public func triggerEvent(_ event: Notification) {
        eventTriggered?(event)
        eventDelegate?.eventTriggered(self, event: event)
    }

    /// 触发指定事件，通知代理，可附带对象和用户信息
    public func triggerEvent(_ name: Notification.Name, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        triggerEvent(Notification(name: name, object: object, userInfo: userInfo))
    }
}

// MARK: - FrameworkAutoloader+ViewProtocol
extension FrameworkAutoloader {
    @objc static func loadModule_ViewProtocol() {
        swizzleViewProtocol()
    }

    private static func swizzleViewProtocol() {
        NSObject.fw.swizzleInstanceMethod(
            UIView.self,
            selector: #selector(UIView.init(frame:)),
            methodSignature: (@convention(c) (UIView, Selector, CGRect) -> UIView).self,
            swizzleSignature: (@convention(block) @MainActor (UIView, CGRect) -> UIView).self
        ) { store in { selfObject, frame in
            let view = store.original(selfObject, store.selector, frame)

            if let viewProtocol = view as? SetupViewProtocol {
                viewProtocol.didInitialize()
                viewProtocol.setupSubviews()
                viewProtocol.setupLayout()
            }
            return view
        }}

        NSObject.fw.swizzleInstanceMethod(
            UIView.self,
            selector: #selector(UIView.init(coder:)),
            methodSignature: (@convention(c) (UIView, Selector, NSCoder) -> UIView?).self,
            swizzleSignature: (@convention(block) @MainActor (UIView, NSCoder) -> UIView?).self
        ) { store in { selfObject, coder in
            guard let view = store.original(selfObject, store.selector, coder) else { return nil }

            if let viewProtocol = view as? SetupViewProtocol {
                viewProtocol.didInitialize()
                viewProtocol.setupSubviews()
                viewProtocol.setupLayout()
            }
            return view
        }}
    }
}
