//
//  Loader.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation

// MARK: - Loader
/// 通用加载器抽象类
open class LoaderAbstract<Input, Output>: Identifiable, Equatable {
    public init() {}
    
    /// 指定输入，加载输出，子类必须实现
    open func load(_ input: Input) -> Output? {
        fatalError("load(_:) has not been implemented")
    }
    
    public static func == (lhs: LoaderAbstract<Input, Output>, rhs: LoaderAbstract<Input, Output>) -> Bool {
        return lhs.id == rhs.id
    }
}

/// 通用block加载器
public class LoaderBlock<Input, Output>: LoaderAbstract<Input, Output> {
    private let block: @Sendable (Input) -> Output?
    
    public init(_ block: @escaping @Sendable (Input) -> Output?) {
        self.block = block
    }
    
    /// 指定输入，加载输出
    public override func load(_ input: Input) -> Output? {
        block(input)
    }
}

/// 通用target-action加载器
public class LoaderTargetAction<Input, Output>: LoaderAbstract<Input, Output> {
    private weak var target: AnyObject?
    private let action: Selector
    
    public init(target: AnyObject?, action: Selector) {
        self.target = target
        self.action = action
    }
    
    /// 指定输入，加载输出
    public override func load(_ input: Input) -> Output? {
        if let target, target.responds(to: action) {
            return target.perform(action, with: input)?.takeUnretainedValue() as? Output
        }
        return nil
    }
}

/// 通用加载管理器，添加加载器后指定输入即可加载输出
public class Loader<Input, Output>: LoaderAbstract<Input, Output>, @unchecked Sendable {
    private var allLoaders: [LoaderAbstract<Input, Output>] = []

    /// 添加loader加载器，返回标志id
    @discardableResult
    public func append(_ loader: LoaderAbstract<Input, Output>) -> ObjectIdentifier {
        allLoaders.append(loader)
        return loader.id
    }

    /// 指定标志id移除加载器
    public func remove(_ identifier: ObjectIdentifier) {
        allLoaders.removeAll { $0.id == identifier }
    }
    
    /// 移除指定加载器
    public func remove(_ loader: LoaderAbstract<Input, Output>) {
        allLoaders.removeAll { $0 == loader }
    }

    /// 移除所有的加载器
    public func removeAll() {
        allLoaders.removeAll()
    }

    /// 依次执行加载器，直到加载成功
    public override func load(_ input: Input) -> Output? {
        var output: Output?
        for loader in allLoaders {
            output = loader.load(input)
            if output != nil { break }
        }
        return output
    }
}

// MARK: - AsyncLoader
/// 通用异步加载器抽象类
open class AsyncLoaderAbstract<Input, Output>: Identifiable, Equatable {
    public init() {}
    
    /// 指定输入，异步加载输出，必须调用completion，子类必须实现
    open func load(_ input: Input, completion: @escaping @Sendable (Output?) -> Void) {
        fatalError("load(_:completion:) has not been implemented")
    }
    
    public static func == (lhs: AsyncLoaderAbstract<Input, Output>, rhs: AsyncLoaderAbstract<Input, Output>) -> Bool {
        return lhs.id == rhs.id
    }
}

/// 通用异步block加载器
public class AsyncLoaderBlock<Input, Output>: AsyncLoaderAbstract<Input, Output> {
    private let block: @Sendable (_ input: Input, _ completion: @escaping @Sendable (Output?) -> Void) -> Void
    
    public init(_ block: @escaping @Sendable (_ input: Input, _ completion: @escaping @Sendable (Output?) -> Void) -> Void) {
        self.block = block
    }
    
    /// 指定输入，异步加载输出
    public override func load(_ input: Input, completion: @escaping @Sendable (Output?) -> Void) {
        block(input, completion)
    }
}

/// 通用异步target-action加载器
public class AsyncLoaderTargetAction<Input, Output>: AsyncLoaderAbstract<Input, Output> {
    private weak var target: AnyObject?
    private let action: Selector
    
    public init(target: AnyObject?, action: Selector) {
        self.target = target
        self.action = action
    }
    
    /// 指定输入，异步加载输出
    public override func load(_ input: Input, completion: @escaping @Sendable (Output?) -> Void) {
        if let target, target.responds(to: action) {
            _ = target.perform(action, with: input, with: completion)
        } else {
            completion(nil)
        }
    }
}

/// 通用异步加载管理器，添加加载器后指定输入即可加载输出
public class AsyncLoader<Input, Output>: AsyncLoaderAbstract<Input, Output>, @unchecked Sendable {
    private var allLoaders: [AsyncLoaderAbstract<Input, Output>] = []

    /// 添加loader加载器，返回标志id
    @discardableResult
    public func append(_ loader: AsyncLoaderAbstract<Input, Output>) -> ObjectIdentifier {
        allLoaders.append(loader)
        return loader.id
    }

    /// 指定标志id移除加载器
    public func remove(_ identifier: ObjectIdentifier) {
        allLoaders.removeAll { $0.id == identifier }
    }
    
    /// 移除指定加载器
    public func remove(_ loader: AsyncLoaderAbstract<Input, Output>) {
        allLoaders.removeAll { $0 == loader }
    }

    /// 移除所有的加载器
    public func removeAll() {
        allLoaders.removeAll()
    }

    /// 依次执行加载器，直到加载成功
    public override func load(_ input: Input, completion: @escaping @Sendable (Output?) -> Void) {
        load(input, using: allLoaders, completion: completion)
    }
    
    private func load(_ input: Input, using loaders: [AsyncLoaderAbstract<Input, Output>], completion: @escaping @Sendable (Output?) -> Void) {
        guard let loader = loaders.first else {
            completion(nil)
            return
        }
        
        loader.load(input) { output in
            if output != nil {
                completion(output)
            } else {
                self.load(input, using: Array(loaders.suffix(from: 1)), completion: completion)
            }
        }
    }
}

// MARK: - Concurrency+AsyncLoaderAbstract
extension AsyncLoaderAbstract {
    /// 指定输入，协程方式异步加载输出，默认调用`load(_:completion:)`
    public func load(_ input: Input) async -> Output? {
        await withCheckedContinuation { continuation in
            load(input) { output in
                continuation.resume(returning: output)
            }
        }
    }
}
