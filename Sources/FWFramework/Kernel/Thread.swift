//
//  Thread.swift
//  FWFramework
//
//  Created by wuyong on 2024/9/27.
//

import Foundation

// MARK: - Wrapper+DispatchQueue
extension Wrapper where Base: DispatchQueue {
    /// 主线程安全异步执行句柄
    public static func mainAsync(execute block: @escaping @MainActor @Sendable () -> Void) {
        MainActor.runAsync(execute: block)
    }

    /// 当主线程时执行句柄，非主线程不执行
    public static func mainSyncIf(execute block: @MainActor () -> Void) {
        MainActor.runSyncIf(execute: block)
    }

    /// 当主线程时执行句柄，非主线程执行另一个句柄
    public static func mainSyncIf<T>(execute block: @MainActor () -> T, otherwise: () -> T) -> T where T: Sendable {
        MainActor.runSyncIf(execute: block, otherwise: otherwise)
    }
}

// MARK: - MainActor+Task
extension MainActor {
    /// 主Actor安全异步执行句柄
    public static func runAsync(execute block: @escaping @MainActor @Sendable () -> Void) {
        if Thread.isMainThread {
            MainActor.assumeIsolated(block)
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }

    /// 当主线程时执行句柄，非主线程不执行
    public static func runSyncIf(execute block: @MainActor () -> Void) {
        if Thread.isMainThread {
            MainActor.assumeIsolated(block)
        }
    }

    /// 当主线程时执行句柄，非主线程执行另一个句柄
    public static func runSyncIf<T>(execute block: @MainActor () -> T, otherwise: () -> T) -> T where T: Sendable {
        if Thread.isMainThread {
            MainActor.assumeIsolated(block)
        } else {
            otherwise()
        }
    }
}

// MARK: - MutableState
/// 可写状态包装器，线程安全
///
/// [Alamofire](https://github.com/Alamofire/Alamofire)
@dynamicMemberLookup
public final class MutableState<Value> {
    // MARK: - Lock
    /// 可写状态锁，os_unfair_lock包装器
    public final class Lock {
        private let unfairLock: os_unfair_lock_t

        public init() {
            self.unfairLock = .allocate(capacity: 1)
            unfairLock.initialize(to: os_unfair_lock())
        }

        deinit {
            unfairLock.deinitialize(count: 1)
            unfairLock.deallocate()
        }
        
        /// 加锁方式执行闭包并返回值
        public func around<T>(_ closure: () throws -> T) rethrows -> T {
            lock(); defer { unlock() }
            return try closure()
        }

        /// 加锁方式执行闭包
        public func around(_ closure: () throws -> Void) rethrows {
            lock(); defer { unlock() }
            try closure()
        }

        private func lock() {
            os_unfair_lock_lock(unfairLock)
        }

        private func unlock() {
            os_unfair_lock_unlock(unfairLock)
        }
    }
    
    // MARK: - Accessor
    private let lock = Lock()
    private var value: Value

    // MARK: - Lifecycle
    public init(_ value: Value) {
        self.value = value
    }

    // MARK: - Public
    /// 同步闭包方式读取或转换值
    public func read<U>(_ closure: (Value) throws -> U) rethrows -> U {
        try lock.around { try closure(self.value) }
    }
    
    /// 同步方式读取值
    public func read() -> Value {
        read { $0 }
    }

    /// 同步闭包方式修改值
    @discardableResult
    public func write<U>(_ closure: (inout Value) throws -> U) rethrows -> U {
        try lock.around { try closure(&self.value) }
    }

    /// 同步方式修改值
    public func write(_ value: Value) {
        write { $0 = value }
    }

    public subscript<Property>(dynamicMember keyPath: WritableKeyPath<Value, Property>) -> Property {
        get { lock.around { value[keyPath: keyPath] } }
        set { lock.around { value[keyPath: keyPath] = newValue } }
    }

    public subscript<Property>(dynamicMember keyPath: KeyPath<Value, Property>) -> Property {
        lock.around { value[keyPath: keyPath] }
    }
}

extension MutableState: Equatable where Value: Equatable {
    public static func ==(lhs: MutableState<Value>, rhs: MutableState<Value>) -> Bool {
        lhs.read { left in rhs.read { right in left == right }}
    }
}

extension MutableState: Hashable where Value: Hashable {
    public func hash(into hasher: inout Hasher) {
        read { hasher.combine($0) }
    }
}
