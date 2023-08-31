//
//  Promise.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation

// MARK: - WrapperGlobal+Promise
extension WrapperGlobal {
    
    /// 仿协程异步执行方法
    @discardableResult
    public static func async(_ block: @escaping () throws -> Any?) -> Promise {
        return Promise.async(block)
    }

    /// 仿协程同步返回结果
    @discardableResult
    public static func await(_ promise: Promise) throws -> Any? {
        return try Promise.await(promise)
    }
    
}

// MARK: - Promise
/// 约定错误
public enum PromiseError: Int, Swift.Error, CustomNSError {
    case failed = 2001
    case validation = 2002
    case timeout = 2003
    
    public static var errorDomain: String { "site.wuyong.error.promise" }
    public var errorCode: Int { self.rawValue }
    public var errorUserInfo: [String: Any] {
        switch self {
        case .failed:
            return [NSLocalizedDescriptionKey: "Promise failed."]
        case .validation:
            return [NSLocalizedDescriptionKey: "Promise validation failed."]
        case .timeout:
            return [NSLocalizedDescriptionKey: "Promise timeout."]
        }
    }
}

/// 约定类
public class Promise {
    
    // MARK: - Accessor
    /// 约定回调队列，默认main队列
    public static var completionQueue: DispatchQueue = .main
    /// 约定默认错误，约定失败时可选使用，可用于错误判断，支持自定义
    public static var defaultError: Error = PromiseError.failed
    /// 约定验证错误，验证失败时默认使用，可用于错误判断，支持自定义
    public static var validationError: Error = PromiseError.validation
    /// 约定超时错误，约定超时时默认使用，可用于错误判断，支持自定义
    public static var timeoutError: Error = PromiseError.timeout
    
    /// 约定内部属性
    private let operation: (@escaping (_ result: Any?) -> Void) -> Void
    private var finished: Bool = false
    private struct Progress { var value: Double }
    
    // MARK: - Lifecycle
    /// 指定操作完成句柄初始化
    public init(completion: @escaping (_ completion: @escaping (_ result: Any?) -> Void) -> Void) {
        self.operation = completion
    }
    
    /// 指定操作成功和失败句柄初始化
    public convenience init(block: @escaping (_ resolve: @escaping (_ value: Any?) -> Void, _ reject: @escaping (_ error: Error) -> Void) -> Void) {
        self.init(completion: { completion in
            block(completion, completion)
        })
    }
    
    /// 指定操作成功、失败句柄和进度句柄初始化
    public convenience init(progress: @escaping (_ resolve: @escaping (_ value: Any?) -> Void, _ reject: @escaping (_ error: Error) -> Void, _ progress: @escaping (_ value : Double) -> Void) -> Void) {
        self.init(completion: { completion in
            progress(completion, completion, { value in
                completion(Progress(value: value))
            })
        })
    }
    
    /// 快速创建成功实例
    public convenience init(value: Any?) {
        self.init(completion: { completion in
            completion(value)
        })
    }
    
    /// 快速创建失败实例
    public convenience init(error: Error) {
        self.init(completion: { completion in
            completion(error)
        })
    }
    
    // MARK: - Await
    /// 仿协程异步执行方法
    @discardableResult
    public static func async(_ block: @escaping () throws -> Any?) -> Promise {
        return Promise { completion in
            DispatchQueue(label: "site.wuyong.queue.promise.async", attributes: .concurrent).async {
                do {
                    let value = try block()
                    completion(value)
                } catch {
                    completion(error)
                }
            }
        }
    }
    
    /// 仿协程同步返回结果
    @discardableResult
    public static func await(_ promise: Promise) throws -> Any? {
        var result: Any?
        var error: Error?
        let group = DispatchGroup()
        group.enter()
        promise.done({ value in
            result = value
            group.leave()
        }, catch: { e in
            error = e
            group.leave()
        })
        group.wait()
        if let e = error {
            throw e
        }
        return result
    }
    
}

// MARK: - Public
extension Promise {
    
    /// 全部约定，所有约定成功才返回约定结果合集；如果某一个失败了，则返回该错误信息；约定进度为所有约定总进度
    public static func all(_ promises: [Promise]) -> Promise {
        return Promise { completion in
            var values: [Any?] = []
            var progress: [Int: Double] = [:]
            for promise in promises {
                promise.done({ value in
                    values.append(value)
                    if values.count == promises.count {
                        completion(values)
                    }
                }, catch: { error in
                    completion(error)
                }, progress: { value in
                    progress[ObjectIdentifier(promise).hashValue] = value
                    let sum = progress.values.reduce(0) { x, y in x + y }
                    completion(Progress(value: sum / Double(promises.count)))
                })
            }
        }
    }
    
    /// 某个约定，返回最先成功的约定结果；如果都失败了，返回最后一个错误信息；约定进度为最先成功的约定进度
    public static func any(_ promises: [Promise]) -> Promise {
        return Promise { completion in
            var failedCount = 0
            var progress: [Int: Double] = [:]
            for promise in promises {
                promise.done({ value in
                    completion(value)
                }, catch: { error in
                    failedCount += 1
                    if failedCount == promises.count {
                        completion(error)
                    }
                }, progress: { value in
                    progress[ObjectIdentifier(promise).hashValue] = value
                    completion(Progress(value: progress.values.max() ?? 0))
                })
            }
        }
    }
    
    /// 约定竞速，返回最先结束的约定结果，不管成功或失败；约定进度为最先结束的约定进度
    public static func race(_ promises: [Promise]) -> Promise {
        return Promise { completion in
            var progress: [Int: Double] = [:]
            for promise in promises {
                promise.done({ value in
                    completion(value)
                }, catch: { error in
                    completion(error)
                }, progress: { value in
                    progress[ObjectIdentifier(promise).hashValue] = value
                    completion(Progress(value: progress.values.max() ?? 0))
                })
            }
        }
    }
    
    /// 延时约定，延时完成时必定成功
    public static func delay(_ time: TimeInterval) -> Promise {
        return Promise { completion in
            Promise.delay(time) {
                completion(time)
            }
        }
    }
    
    /// 约定重试，block需返回新创建的约定，该约定失败时延迟指定时间后重新创建并执行，直至成功或达到最大重试次数(总次数retry+1)
    public static func retry(_ times: Int = 1, delay: TimeInterval = 0, block: @escaping () -> Promise) -> Promise {
        return retry(block(), times: times, delay: delay, block: block)
    }
    
    /// 执行约定并回调完成句柄
    public func done(_ completion: @escaping (_ result: Any?) -> Void) {
        self.execute(progress: false, completion: completion)
    }
    
    /// 执行约定并分别回调成功、失败句柄，统一回调收尾句柄
    public func done(_ done: @escaping (_ value: Any?) -> Void, catch: ((_ error: Error) -> Void)?, finally: (() -> Void)? = nil) {
        self.execute(progress: false) { result in
            if let error = result as? Error {
                `catch`?(error)
            } else {
                done(result)
            }
            finally?()
        }
    }
    
    /// 执行约定并分别回调成功、失败句柄、进度句柄，统一回调收尾句柄
    public func done(_ done: @escaping (_ value: Any?) -> Void, catch: ((_ error: Error) -> Void)?, progress: ((_ value: Double) -> Void)?, finally: (() -> Void)? = nil) {
        self.execute(progress: progress != nil) { result in
            if progress != nil, let prog = result as? Progress {
                progress?(prog.value)
            } else if let error = result as? Error {
                `catch`?(error)
                finally?()
            } else {
                done(result)
                finally?()
            }
        }
    }
    
    /// 执行当前约定，成功时调用句柄处理结果或者返回下一个约定
    public func then(_ block: @escaping (_ value: Any?) -> Any?) -> Promise {
        return Promise { completion in
            self.done({ value in
                let result = block(value)
                if let promise = result as? Promise {
                    promise.execute(progress: true, completion: completion)
                } else {
                    completion(result)
                }
            }, catch: { error in
                completion(error)
            }, progress: { value in
                completion(Progress(value: value))
            })
        }
    }
    
    /// 执行当前约定，失败时调用句柄恢复结果或者返回下一个约定
    public func recover(_ block: @escaping (_ error: Error) -> Any?) -> Promise {
        return Promise { completion in
            self.done({ value in
                completion(value)
            }, catch: { error in
                let result = block(error)
                if let promise = result as? Promise {
                    promise.execute(progress: true, completion: completion)
                } else {
                    completion(result)
                }
            }, progress: { value in
                completion(Progress(value: value))
            })
        }
    }
    
    /// 验证约定，当前约定成功时验证结果，可返回Bool或Error?；验证通过时返回结果，验证失败时返回验证错误
    public func validate(_ block: @escaping (_ value: Any?) -> Any?) -> Promise {
        return Promise { completion in
            self.done({ value in
                let result = block(value)
                if let error = result as? Error {
                    completion(error)
                } else if let valid = result as? Bool, !valid {
                    completion(Promise.validationError)
                } else {
                    completion(value)
                }
            }, catch: { error in
                completion(error)
            }, progress: { value in
                completion(Progress(value: value))
            })
        }
    }
    
    /// 减少约定，当前约定结果作为初始值value，顺序使用value和数组值item调用reducer，产生新的value继续循环直至结束，类似数组reduce方法
    public func reduce(_ items: [Any], reducer: @escaping (_ value: Any?, _ item: Any) -> Any?) -> Promise {
        var promise = self
        for item in items {
            promise = promise.then({ value in
                return reducer(value, item)
            })
        }
        return promise
    }
    
    /// 约定延时，当前约定成功时延时返回结果；默认失败时不延时，可设置force强制失败时也延时
    public func delay(_ time: TimeInterval, force: Bool = false) -> Promise {
        return Promise { completion in
            self.done({ value in
                Promise.delay(time) {
                    completion(value)
                }
            }, catch: { error in
                if force {
                    Promise.delay(time) {
                        completion(error)
                    }
                } else {
                    completion(error)
                }
            }, progress: { value in
                completion(Progress(value: value))
            })
        }
    }
    
    /// 约定超时，当前约定未超时时返回结果；否则返回超时错误信息
    public func timeout(_ time: TimeInterval, error: Error? = nil) -> Promise {
        let promise = Promise { completion in
            Promise.delay(time) {
                completion(error ?? Promise.timeoutError)
            }
        }
        return Promise.race([self, promise])
    }
    
    /// 约定重试，block需返回新创建的约定，当前约定失败时延迟指定时间后调用block创建约定并执行，直至成功或达到最大重试次数
    public func retry(_ times: Int = 1, delay: TimeInterval = 0, block: @escaping () -> Promise) -> Promise {
        return Promise.retry(self, times: times, delay: delay, block: block)
    }
    
}

// MARK: - Private
extension Promise {
    
    /// 约定内部执行方法
    private func execute(progress: Bool, completion: @escaping (_ result: Any?) -> Void) {
        self.operation() { result in
            Promise.completionQueue.async {
                if !self.finished {
                    if result is Progress {
                        if progress { completion(result) }
                    } else {
                        self.finished = true
                        completion(result)
                    }
                }
            }
        }
    }
    
    /// 约定内部延时方法
    private static func delay(_ time: TimeInterval, block: @escaping () -> Void) {
        Promise.completionQueue.asyncAfter(deadline: .now() + time, execute: block)
    }
    
    /// 约定内部重试方法
    private static func retry(_ initialPromise: Promise?, times: Int, delay: TimeInterval, block: @escaping () -> Promise) -> Promise {
        let promise = initialPromise ?? Promise.delay(delay).then({ _ in block() })
        if times < 1 { return promise }
        return promise.recover { _ in
            Promise.retry(nil, times: times - 1, delay: delay, block: block)
        }
    }
    
}
