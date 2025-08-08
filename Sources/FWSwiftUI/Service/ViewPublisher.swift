//
//  ViewPublisher.swift
//  FWFramework
//
//  Created by wuyong on 2025/8/9.
//

import Combine

/// [Conbini](https://github.com/dehesa/package-conbini)
extension Publisher where Self.Failure == Never {
    /// 将输出赋值到weak引用对象的指定属性
    @_transparent public func assign<Root>(to keyPath: ReferenceWritableKeyPath<Root, Output>, onWeak object: Root) -> AnyCancellable where Root: AnyObject {
        weak var cancellable: AnyCancellable? = nil
        let cleanup: (Subscribers.Completion<Never>) -> Void = { _ in
            cancellable?.cancel()
            cancellable = nil
        }

        let subscriber = Subscribers.Sink<Output, Never>(receiveCompletion: cleanup, receiveValue: { [weak object] value in
            guard let object else { return cleanup(.finished) }
            object[keyPath: keyPath] = value
        })

        let result = AnyCancellable(subscriber)
        cancellable = result
        subscribe(subscriber)
        return result
    }

    /// 将输出赋值到unowned引用对象的指定属性
    @_transparent public func assign<Root>(to keyPath: ReferenceWritableKeyPath<Root, Output>, onUnowned object: Root) -> AnyCancellable where Root: AnyObject {
        sink(receiveValue: { [unowned object] value in
            object[keyPath: keyPath] = value
        })
    }
}

extension Publisher where Self.Failure == Never {
    /// 绑定strong引用对象并调用该对象的指定方法
    @_transparent public func invoke<Root>(_ method: @escaping (Root) -> (Output) -> Void, on instance: Root) -> AnyCancellable {
        sink(receiveValue: { value in
            method(instance)(value)
        })
    }

    /// 绑定weak引用对象并调用该对象的指定方法
    @_transparent public func invoke<Root>(_ method: @escaping (Root) -> (Output) -> Void, onWeak object: Root) -> AnyCancellable where Root: AnyObject {
        weak var cancellable: AnyCancellable? = nil
        let cleanup: (Subscribers.Completion<Never>) -> Void = { _ in
            cancellable?.cancel()
            cancellable = nil
        }

        let subscriber = Subscribers.Sink<Output, Never>(receiveCompletion: cleanup, receiveValue: { [weak object] value in
            guard let object else { return cleanup(.finished) }
            method(object)(value)
        })

        let result = AnyCancellable(subscriber)
        cancellable = result
        subscribe(subscriber)
        return result
    }

    /// 绑定unowned引用对象并调用该对象的指定方法
    @_transparent public func invoke<Root>(_ method: @escaping (Root) -> (Output) -> Void, onUnowned object: Root) -> AnyCancellable where Root: AnyObject {
        sink(receiveValue: { [unowned object] value in
            method(object)(value)
        })
    }
}
