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

// MARK: - LockingProtocol
/// 通用互斥锁协议
public protocol LockingProtocol {
    /// 加锁方法
    func lock()
    
    /// 解锁方法
    func unlock()
}

extension LockingProtocol {
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
}

// MARK: - NSLock
extension NSLock: LockingProtocol {}

// MARK: - UnfairLock
/// os_unfair_lock包装锁
public final class UnfairLock: LockingProtocol {
    private let unfairLock: os_unfair_lock_t

    public init() {
        self.unfairLock = .allocate(capacity: 1)
        unfairLock.initialize(to: os_unfair_lock())
    }

    deinit {
        unfairLock.deinitialize(count: 1)
        unfairLock.deallocate()
    }

    public func lock() {
        os_unfair_lock_lock(unfairLock)
    }

    public func unlock() {
        os_unfair_lock_unlock(unfairLock)
    }
}

// MARK: - SemaphoreLock
/// DispatchSemaphore包装锁
public final class SemaphoreLock: LockingProtocol {
    private let dispatchSemaphore: DispatchSemaphore

    public init() {
        self.dispatchSemaphore = DispatchSemaphore(value: 1)
    }

    public func lock() {
        dispatchSemaphore.wait()
    }

    public func unlock() {
        dispatchSemaphore.signal()
    }
}

// MARK: - ProtectedValue
/// 线程安全的受保护值包装器
///
/// [Alamofire](https://github.com/Alamofire/Alamofire)
@dynamicMemberLookup
public final class ProtectedValue<Value>: @unchecked Sendable {
    private let lock = UnfairLock()
    private var value: Value

    public init(_ value: Value) {
        self.value = value
    }
    
    /// 同步方式读取或设置值
    public var protectedValue: Value {
        get { read() }
        set { write(newValue) }
    }

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

extension ProtectedValue: Equatable where Value: Equatable {
    public static func ==(lhs: ProtectedValue<Value>, rhs: ProtectedValue<Value>) -> Bool {
        lhs.read { left in rhs.read { right in left == right }}
    }
}

extension ProtectedValue: Hashable where Value: Hashable {
    public func hash(into hasher: inout Hasher) {
        read { hasher.combine($0) }
    }
}
