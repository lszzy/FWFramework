//
//  Loader.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation

// MARK: - Loader
/// 通用加载器错误
public enum LoaderError: Int, Swift.Error, CustomNSError {
    case failed = 2031

    public static var errorDomain: String { "site.wuyong.error.loader" }
    public var errorCode: Int { rawValue }
    public var errorUserInfo: [String: Any] {
        switch self {
        case .failed:
            return [NSLocalizedDescriptionKey: "Load failed"]
        }
    }
}

/// 通用加载器抽象类
open class LoaderAbstract<Input, Output>: Identifiable, Equatable, @unchecked Sendable {
    public init() {}
    
    /// 指定输入，加载输出，子类必须实现
    open func load(_ input: Input) throws -> Output {
        fatalError("load(_:) has not been implemented")
    }
    
    public static func == (lhs: LoaderAbstract<Input, Output>, rhs: LoaderAbstract<Input, Output>) -> Bool {
        return lhs.id == rhs.id
    }
}

/// 通用block加载器
public class LoaderBlock<Input, Output>: LoaderAbstract<Input, Output>, @unchecked Sendable {
    private let block: @Sendable (Input) throws -> Output
    
    public init(_ block: @escaping @Sendable (Input) throws -> Output) {
        self.block = block
    }
    
    /// 指定输入，加载输出
    public override func load(_ input: Input) throws -> Output {
        try block(input)
    }
}

/// 通用target-action加载器，兼容Output | Error | Result<Output,Error>
public class LoaderTargetAction<Input, Output>: LoaderAbstract<Input, Output>, @unchecked Sendable {
    private weak var target: AnyObject?
    private let action: Selector
    
    public init(target: AnyObject?, action: Selector) {
        self.target = target
        self.action = action
    }
    
    /// 指定输入，加载输出
    public override func load(_ input: Input) throws -> Output {
        var result: Result<Output, Error> = .failure(LoaderError.failed)
        if let target, target.responds(to: action),
           let value = target.perform(action, with: input)?.takeUnretainedValue() {
            if let output = value as? Output {
                result = .success(output)
            } else if let error = value as? Error {
                result = .failure(error)
            } else if let value = value as? Result<Output, Error> {
                result = value
            }
        }
        
        switch result {
            case let .success(output): return output
            case let .failure(error): throw error
        }
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
    public override func load(_ input: Input) throws -> Output {
        var result: Result<Output, Error> = .failure(LoaderError.failed)
        let loaders = allLoaders
        for loader in loaders {
            do {
                result = .success(try loader.load(input))
                break
            } catch {
                result = .failure(error)
            }
        }
        
        switch result {
            case let .success(output):
                return output
            case let .failure(error):
                throw error
        }
    }
}

// MARK: - AsyncLoader
/// 通用异步加载器抽象类
open class AsyncLoaderAbstract<Input, Output>: Identifiable, Equatable, @unchecked Sendable {
    public init() {}
    
    /// 指定输入，异步加载输出，必须调用completion，子类必须实现
    open func load(_ input: Input, completion: @escaping @Sendable (Result<Output, Error>) -> Void) {
        fatalError("load(_:completion:) has not been implemented")
    }
    
    public static func == (lhs: AsyncLoaderAbstract<Input, Output>, rhs: AsyncLoaderAbstract<Input, Output>) -> Bool {
        return lhs.id == rhs.id
    }
}

/// 通用异步block加载器
public class AsyncLoaderBlock<Input, Output>: AsyncLoaderAbstract<Input, Output>, @unchecked Sendable {
    private let block: @Sendable (_ input: Input, _ completion: @escaping @Sendable (Result<Output, Error>) -> Void) -> Void
    
    public init(_ block: @escaping @Sendable (_ input: Input, _ completion: @escaping @Sendable (Result<Output, Error>) -> Void) -> Void) {
        self.block = block
    }
    
    /// 指定输入，异步加载输出
    public override func load(_ input: Input, completion: @escaping @Sendable (Result<Output, Error>) -> Void) {
        block(input, completion)
    }
}

/// 通用异步target-action加载器，兼容Output | Error | Result<Output,Error>
public class AsyncLoaderTargetAction<Input, Output>: AsyncLoaderAbstract<Input, Output>, @unchecked Sendable {
    private weak var target: AnyObject?
    private let action: Selector
    
    public init(target: AnyObject?, action: Selector) {
        self.target = target
        self.action = action
    }
    
    /// 指定输入，异步加载输出
    public override func load(_ input: Input, completion: @escaping @Sendable (Result<Output, Error>) -> Void) {
        if let target, target.responds(to: action) {
            _ = target.perform(action, with: input, with: completion)
        } else {
            completion(.failure(LoaderError.failed))
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
    public override func load(_ input: Input, completion: @escaping @Sendable (Result<Output, Error>) -> Void) {
        load(input, using: allLoaders, error: nil, completion: completion)
    }
    
    private func load(_ input: Input, using loaders: [AsyncLoaderAbstract<Input, Output>], error: Error?, completion: @escaping @Sendable (Result<Output, Error>) -> Void) {
        guard let loader = loaders.first else {
            completion(.failure(error ?? LoaderError.failed))
            return
        }
        
        let sendableInput = SendableValue(input)
        loader.load(input) { result in
            switch result {
                case let .success(output):
                    completion(.success(output))
                case let .failure(error):
                    self.load(sendableInput.value, using: Array(loaders.suffix(from: 1)), error: error, completion: completion)
            }
        }
    }
}

// MARK: - Concurrency+AsyncLoaderAbstract
extension AsyncLoaderAbstract {
    /// 指定输入，协程方式异步加载输出，默认调用`load(_:completion:)`
    public func load(_ input: Input) async throws -> Output where Output: Sendable {
        try await withCheckedThrowingContinuation { continuation in
            load(input) { result in
                switch result {
                    case let .success(output):
                        continuation.resume(returning: output)
                    case let .failure(error):
                        continuation.resume(throwing: error)
                }
            }
        }
    }
}
