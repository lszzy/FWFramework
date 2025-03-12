//
//  ViewStorage.swift
//  FWFramework
//
//  Created by wuyong on 2025/3/12.
//

#if canImport(SwiftUI)
import SwiftUI
import Combine
import Dispatch

// MARK: - ViewStorage
/// [SwiftUIX](https://github.com/SwiftUIX/SwiftUIX)
@frozen
@propertyWrapper
public struct ViewStorage<Value>: Identifiable, DynamicProperty {
    public final class ValueBox: AnyObservableValue<Value> {
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
            
            super.init(configuration: AnyObservableValue.Configuration())
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
}

// MARK: - Conformances
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

// MARK: - API
extension ViewStorage {
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

public protocol _SwiftUIX_AnyIndirectValueBox<Value> {
    associatedtype Value
    
    var wrappedValue: Value { get nonmutating set }
}

@dynamicMemberLookup
public class AnyObservableValue<Value>: _SwiftUIX_AnyIndirectValueBox, ObservableObject {
    public struct Configuration {
        public var deferUpdates: Bool
        
        public init(
            deferUpdates: Bool?
        ) {
            self.deferUpdates = deferUpdates ?? false
        }
        
        public init() {
            self.init(
                deferUpdates: nil
            )
        }
    }
    
    public var configuration = Configuration()
    
    public var wrappedValue: Value {
        get {
            fatalError() // abstract
        } set {
            fatalError() // abstract
        }
    }
    
    init(configuration: Configuration) {
        self.configuration = configuration
    }

    public subscript<Subject>(
        dynamicMember keyPath: WritableKeyPath<Value, Subject>
    ) -> AnyObservableValue<Subject> {
        ValueMember(root: self, keyPath: keyPath)
    }
    
    @_disfavoredOverload
    public subscript<Subject>(dynamicMember keyPath: WritableKeyPath<Value, Subject>) -> Binding<Subject> {
        return Binding<Subject>(
            get: { self.wrappedValue[keyPath: keyPath] },
            set: { self.wrappedValue[keyPath: keyPath] = $0 }
        )
    }
}

final class ValueMember<Root, Value>: AnyObservableValue<Value> {
    unowned let root: AnyObservableValue<Root>
    
    let keyPath: WritableKeyPath<Root, Value>
    var subscription: AnyCancellable?
    
    override var wrappedValue: Value {
        get {
            root.wrappedValue[keyPath: keyPath]
        } set {
            _objectWillChange_send(deferred: configuration.deferUpdates)

            root.wrappedValue[keyPath: keyPath] = newValue
        }
    }
    
    public init(
        root: AnyObservableValue<Root>,
        keyPath: WritableKeyPath<Root, Value>,
        configuration: AnyObservableValue<Value>.Configuration = .init()
    ) {
        self.root = root
        self.keyPath = keyPath
        self.subscription = nil
        
        super.init(configuration: configuration)
        
        subscription = root.objectWillChange.sink(receiveValue: { [weak self] _ in
            guard let `self` = self else {
                return
            }
            
            self._objectWillChange_send(deferred: self.configuration.deferUpdates)
        })
    }
}

extension ObservableObject {
    public func _objectWillChange_send(
        deferred: Bool = false
    ) where ObjectWillChangePublisher == ObservableObjectPublisher {
        if deferred {
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                self.objectWillChange.send()
            }
        } else {
            objectWillChange.send()
        }
    }
}

#endif
