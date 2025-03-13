//
//  ViewStorage.swift
//  FWFramework
//
//  Created by wuyong on 2025/3/12.
//

#if canImport(SwiftUI)
import SwiftUI
import Combine

// MARK: - ViewStorage
/// 和State类似，只是不触发UI自动刷新
///
/// [SwiftUIX](https://github.com/SwiftUIX/SwiftUIX)
@frozen
@propertyWrapper
public struct ViewStorage<Value>: Identifiable, DynamicProperty {
    public final class ValueBox: ViewStorageValue<Value> {
        @Published fileprivate var value: Value
        
        public override var wrappedValue: Value {
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
            get: { self.valueBox.value },
            set: { self.valueBox.value = $0 }
        )
    }
    
    public var publisher: Published<Value>.Publisher {
        valueBox.$value
    }
}

extension ViewStorage: Equatable where Value: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
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
public class ViewStorageValue<Value>: ObservableObject {
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
        return Binding<Subject>(
            get: { self.wrappedValue[keyPath: keyPath] },
            set: { self.wrappedValue[keyPath: keyPath] = $0 }
        )
    }
}

// MARK: - ViewStorageMember
final class ViewStorageMember<Root, Value>: ViewStorageValue<Value> {
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
        
        subscription = root.objectWillChange.sink(receiveValue: { [weak self] _ in
            guard let `self` = self else { return }
            self.objectWillChange.send()
        })
    }
}

#endif
