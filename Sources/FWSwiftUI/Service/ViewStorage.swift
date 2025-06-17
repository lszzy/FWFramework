//
//  ViewStorage.swift
//  FWFramework
//
//  Created by wuyong on 2025/3/12.
//

import Combine
import SwiftUI

// MARK: - ViewStorage
/// 和State类似，只是不触发UI自动刷新
///
/// [SwiftUIX](https://github.com/SwiftUIX/SwiftUIX)
@frozen
@propertyWrapper
public struct ViewStorage<Value>: Identifiable, DynamicProperty, @unchecked Sendable {
    public final class ValueBox: ViewStorageValue<Value>, @unchecked Sendable {
        @Published fileprivate var value: Value

        override public var wrappedValue: Value {
            get {
                value
            } set {
                value = newValue
            }
        }

        fileprivate init(_ value: Value) {
            self.value = value
            super.init()
        }
    }

    public var id: ObjectIdentifier {
        ObjectIdentifier(valueBox)
    }

    @State fileprivate var _valueBox: ValueBox

    public var wrappedValue: Value {
        get {
            _valueBox.value
        } nonmutating set {
            _valueBox.value = newValue
        }
    }

    public var projectedValue: ViewStorage<Value> {
        self
    }

    public var valueBox: ValueBox {
        _valueBox
    }

    public init(wrappedValue value: @autoclosure @escaping () -> Value) {
        self.__valueBox = .init(wrappedValue: ValueBox(value()))
    }

    // MARK: - Public
    public var binding: Binding<Value> {
        .init(
            get: { valueBox.value },
            set: { valueBox.value = $0 }
        )
    }

    public var publisher: Published<Value>.Publisher {
        valueBox.$value
    }
}

extension ViewStorage: Equatable where Value: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}

extension ViewStorage: Hashable where Value: Hashable {
    public func hash(into hasher: inout Hasher) {
        wrappedValue.hash(into: &hasher)
    }
}

// MARK: - ViewStorageValue
@dynamicMemberLookup
public class ViewStorageValue<Value>: ObservableObject, @unchecked Sendable {
    public var wrappedValue: Value {
        get {
            fatalError()
        } set {
            fatalError()
        }
    }

    init() {}

    public subscript<Subject>(
        dynamicMember keyPath: WritableKeyPath<Value, Subject>
    ) -> ViewStorageValue<Subject> {
        ViewStorageMember(root: self, keyPath: keyPath)
    }

    @_disfavoredOverload
    public subscript<Subject>(
        dynamicMember keyPath: WritableKeyPath<Value, Subject>
    ) -> Binding<Subject> {
        Binding<Subject>(
            get: { self.wrappedValue[keyPath: keyPath] },
            set: { self.wrappedValue[keyPath: keyPath] = $0 }
        )
    }
}

// MARK: - ViewStorageMember
final class ViewStorageMember<Root, Value>: ViewStorageValue<Value>, @unchecked Sendable {
    unowned let root: ViewStorageValue<Root>

    let keyPath: WritableKeyPath<Root, Value>
    var subscription: AnyCancellable?

    override var wrappedValue: Value {
        get {
            root.wrappedValue[keyPath: keyPath]
        } set {
            objectWillChange.send()
            root.wrappedValue[keyPath: keyPath] = newValue
        }
    }

    public init(
        root: ViewStorageValue<Root>,
        keyPath: WritableKeyPath<Root, Value>
    ) {
        self.root = root
        self.keyPath = keyPath
        self.subscription = nil
        super.init()

        self.subscription = root.objectWillChange.sink(receiveValue: { [weak self] _ in
            guard let self else { return }
            objectWillChange.send()
        })
    }
}

// MARK: - View+OnChangeOfFrame
@MainActor extension View {
    /// Frame改变时触发动作
    public func onChangeOfFrame(
        threshold: CGFloat? = nil,
        onAppear: Bool = false,
        perform action: @escaping (CGSize) -> Void
    ) -> some View {
        modifier(OnChangeOfFrame(threshold: threshold, action: action, onAppear: onAppear))
    }

    @_disfavoredOverload
    @inlinable
    public func background<Background: View>(
        alignment: Alignment = .center,
        @ViewBuilder _ background: () -> Background
    ) -> some View {
        self.background(background(), alignment: alignment)
    }

    @ViewBuilder
    public func _onChange<V: Equatable>(
        of value: V,
        perform action: @escaping (V) -> Void
    ) -> some View {
        if #available(iOS 17.0, *) {
            self.onChange(of: value) { _, newValue in
                action(newValue)
            }
        } else if #available(iOS 14.0, *) {
            onChange(of: value, perform: action)
        } else {
            OnChangeOfValue(base: self, value: value, action: action)
        }
    }
}

private struct OnChangeOfFrame: ViewModifier {
    let threshold: CGFloat?
    let action: (CGSize) -> Void
    let onAppear: Bool

    @ViewStorage var oldSize: CGSize? = nil

    func body(content: Content) -> some View {
        content.background {
            GeometryReader { proxy in
                Color.black.opacity(0.0001)
                    .frame(width: 0, height: 0)
                    .onAppear {
                        oldSize = proxy.size

                        if onAppear {
                            action(proxy.size)
                        }
                    }
                    ._onChange(of: proxy.size) { newSize in
                        if let oldSize {
                            if let threshold {
                                guard !(abs(oldSize.width - newSize.width) < threshold && abs(oldSize.height - newSize.height) < threshold) else {
                                    return
                                }
                            } else {
                                guard oldSize != newSize else {
                                    return
                                }
                            }

                            action(newSize)
                            self.oldSize = newSize
                        } else {
                            oldSize = newSize
                        }
                    }
            }
            .allowsHitTesting(false)
            .accessibility(hidden: true)
        }
    }
}

private struct OnChangeOfValue<Base: View, Value: Equatable>: View {
    private class ValueBox {
        private var savedValue: Value?

        func update(value: Value) -> Bool {
            guard value != savedValue else {
                return false
            }
            savedValue = value
            return true
        }
    }

    let base: Base
    let value: Value
    let action: (Value) -> Void

    @State private var valueBox = ValueBox()
    @State private var oldValue: Value?

    public var body: some View {
        if valueBox.update(value: value) {
            DispatchQueue.main.async {
                action(value)
                oldValue = value
            }
        }
        return base
    }
}
