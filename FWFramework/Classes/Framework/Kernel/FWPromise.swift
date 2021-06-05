//
//  FWPromise.swift
//  FWFramework
//
//  Created by wuyong on 2021/06/03.
//  Copyright © 2021 wuyong.site. All rights reserved.
//

import Foundation

/// 仿协程异步执行方法
@discardableResult
public func fw_async(_ block: @escaping () throws -> Any?) -> FWPromise {
    return FWPromise.async(block)
}

/// 仿协程同步返回结果
@discardableResult
public func fw_await(_ promise: FWPromise) throws -> Any? {
    return try FWPromise.await(promise)
}

/// 框架约定类
@objcMembers public class FWPromise: NSObject {
    /// 约定回调队列，默认main队列
    public static var completionQueue: DispatchQueue = DispatchQueue.main
    /// 约定默认验证错误，可自定义
    public static var validationError: Error = NSError(domain: "FWPromise", code: 1, userInfo: nil)
    /// 约定默认超时错误，可自定义
    public static var timeoutError: Error = NSError(domain: "FWPromise", code: 2, userInfo: nil)
    
    /// 约定内部属性
    private let operation: (@escaping (Any?) -> Void) -> Void
    private var finished = false
    
    /// 约定内部方法
    private func execute(completion: @escaping (Any?) -> Void) {
        self.operation() { result in
            FWPromise.completionQueue.async {
                if !self.finished {
                    self.finished = true
                    completion(result)
                }
            }
        }
    }
    
    // MARK: - Public
    
    /// 指定操作完成句柄初始化
    public init(operation: @escaping (_ completion: @escaping (Any?) -> Void) -> Void) {
        self.operation = operation
    }
    
    /// 指定操作成功和失败句柄初始化
    public convenience init(_ operation: @escaping (_ resolve: @escaping (Any?) -> Void, _ reject: @escaping (Error) -> Void) -> Void) {
        self.init(operation: { completion in
            operation(completion, completion)
        })
    }
    
    /// 快速创建成功实例
    public convenience init(value: Any?) {
        self.init(operation: { completion in
            completion(value)
        })
    }
    
    /// 快速创建失败实例
    public convenience init(error: Error) {
        self.init(operation: { completion in
            completion(error)
        })
    }
    
    /// 执行约定并回调完成句柄
    public func done(completion: @escaping (Any?) -> Void) {
        self.execute { result in
            completion(result)
        }
    }
    
    /// 执行约定并分别回调成功、失败句柄
    public func done(_ done: @escaping (Any?) -> Void, catch: ((Error) -> Void)?) {
        self.done(done, catch: `catch`, finally: nil)
    }
    
    /// 执行约定并分别回调成功、失败句柄，统一回调收尾句柄
    public func done(_ done: @escaping (Any?) -> Void, catch: ((Error) -> Void)?, finally: (() -> Void)?) {
        self.execute { result in
            if let error = result as? Error {
                `catch`?(error)
            } else {
                done(result)
            }
            finally?()
        }
    }
    
    /// 执行当前约定，成功时调用句柄处理结果或者返回下一个约定
    public func then(_ block: @escaping (_ value: Any?) -> Any?) -> FWPromise {
        return FWPromise { completion in
            self.done { value in
                let result = block(value)
                if let promise = result as? FWPromise {
                    promise.done(completion: completion)
                } else {
                    completion(result)
                }
            } catch: { error in
                completion(error)
            }
        }
    }
    
    /// 执行当前约定，失败时调用句柄恢复结果或者返回下一个约定
    public func recover(_ block: @escaping (_ error: Error) -> Any?) -> FWPromise {
        return FWPromise { completion in
            self.done { value in
                completion(value)
            } catch: { error in
                let result = block(error)
                if let promise = result as? FWPromise {
                    promise.done(completion: completion)
                } else {
                    completion(result)
                }
            }
        }
    }
    
    /// 仿协程异步执行方法
    @discardableResult
    public static func async(_ block: @escaping () throws -> Any?) -> FWPromise {
        return FWPromise { completion in
            DispatchQueue(label: "site.wuyong.FWPromise.asyncQueue", attributes: .concurrent).async {
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
    public static func await(_ promise: FWPromise) throws -> Any? {
        var result: Any?
        var error: Error?
        let group = DispatchGroup()
        group.enter()
        promise.done { value in
            result = value
            group.leave()
        } catch: { e in
            error = e
            group.leave()
        }
        group.wait()
        if let e = error {
            throw e
        }
        return result
    }
    
    // MARK: - Extension
    
    /// 验证约定，当前约定成功时验证结果，可返回Bool或Error?；验证通过时返回结果，验证失败时返回验证错误
    public func validate(_ block: @escaping (_ value: Any?) -> Any?) -> FWPromise {
        return FWPromise { completion in
            self.done { value in
                let result = block(value)
                if let error = result as? Error {
                    completion(error)
                } else if let valid = result as? Bool, !valid {
                    completion(FWPromise.validationError)
                } else {
                    completion(value)
                }
            } catch: { error in
                completion(error)
            }
        }
    }
    
    /// 约定超时，当前约定未超时时返回结果；否则返回超时错误信息
    public func timeout(_ time: TimeInterval, error: Error? = nil) -> FWPromise {
        let promise = FWPromise { completion in
            FWPromise.delay(time) {
                completion(error ?? FWPromise.timeoutError)
            }
        }
        return FWPromise.race([self, promise])
    }
    
    /// 约定延时，当前约定成功时延时返回相同的结果；失败时不执行延时
    public func delay(_ time: TimeInterval) -> FWPromise {
        return FWPromise { completion in
            self.done { value in
                FWPromise.delay(time) {
                    completion(value)
                }
            } catch: { error in
                completion(error)
            }
        }
    }
    
    /// 全部约定，所有约定成功才返回约定结果合集；如果某一个失败了，则返回该错误信息
    public static func all(_ promises: [FWPromise]) -> FWPromise {
        return FWPromise { completion in
            var values: [Any?] = []
            for promise in promises {
                promise.done { value in
                    values.append(value)
                    if values.count == promises.count {
                        completion(values)
                    }
                } catch: { error in
                    completion(error)
                }
            }
        }
    }
    
    /// 某个约定，返回最先成功的约定结果；如果都失败了，返回最后一个错误信息
    public static func any(_ promises: [FWPromise]) -> FWPromise {
        return FWPromise { completion in
            var failedCount = 0
            for promise in promises {
                promise.done { value in
                    completion(value)
                } catch: { error in
                    failedCount += 1
                    if failedCount == promises.count {
                        completion(error)
                    }
                }
            }
        }
    }
    
    /// 约定竞速，返回最先结束的约定结果，不管成功或失败
    public static func race(_ promises: [FWPromise]) -> FWPromise {
        return FWPromise { completion in
            for promise in promises {
                promise.done { result in
                    completion(result)
                }
            }
        }
    }
    
    /// 延时约定，延时完成时必定成功
    public static func delay(_ time: TimeInterval) -> FWPromise {
        return FWPromise { completion in
            FWPromise.delay(time) {
                completion(time)
            }
        }
    }
    
    /// 约定内部延时方法
    private static func delay(_ time: TimeInterval, block: @escaping () -> Void) {
        FWPromise.completionQueue.asyncAfter(deadline: .now() + time, execute: block)
    }
}
