//
//  Binding+Toolkit.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#if canImport(SwiftUI)
import SwiftUI

/// [SwiftUIX](https://github.com/SwiftUIX/SwiftUIX)
extension Binding {
    
    public func onSet(_ body: @escaping (Value) -> ()) -> Self {
        return .init(
            get: { self.wrappedValue },
            set: { self.wrappedValue = $0; body($0) }
        )
    }
    
    public func onChange(perform action: @escaping (Value) -> ()) -> Self where Value: Equatable {
        return .init(
            get: { self.wrappedValue },
            set: { newValue in
                let oldValue = self.wrappedValue
                self.wrappedValue = newValue
                
                if newValue != oldValue  {
                    action(newValue)
                }
            }
        )
    }
    
    public func onChange(toggle value: Binding<Bool>) -> Self where Value: Equatable {
        onChange { _ in
            value.wrappedValue.toggle()
        }
    }
    
    public func withDefaultValue<T>(_ defaultValue: T) -> Binding<T> where Value == Optional<T> {
        return .init(
            get: { self.wrappedValue ?? defaultValue },
            set: { self.wrappedValue = $0 }
        )
    }
    
}

#endif
