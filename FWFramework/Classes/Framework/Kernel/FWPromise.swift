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
    private let operation: (@escaping (Any?) -> Void) -> Void
    
    /// 指定完成句柄初始化
    public init(block: @escaping (_ completion: @escaping (Any?) -> Void) -> Void) {
        self.operation = block
    }
    
    /// 指定成功和失败句柄初始化
    public convenience init(_ block: @escaping (_ resolve: @escaping (Any?) -> Void, _ reject: @escaping (Error) -> Void) -> Void) {
        self.init(block: { completion in
            block(completion, completion)
        })
    }
    
    /// 快速创建成功实例
    public convenience init(value: Any?) {
        self.init(block: { completion in
            completion(value)
        })
    }
    
    /// 快速创建失败实例
    public convenience init(error: Error) {
        self.init(block: { completion in
            completion(error)
        })
    }
    
    /// 执行约定并回调完成句柄
    public func done(completion: @escaping (Any?) -> Void) {
        self.operation() { result in
            completion(result)
        }
    }
    
    /// 执行约定并分别回调成功、失败句柄
    public func done(_ done: @escaping (Any?) -> Void, catch: ((Error) -> Void)?) {
        self.done(done, catch: `catch`, finally: nil)
    }
    
    /// 执行约定并分别回调成功、失败句柄，统一回调收尾句柄
    public func done(_ done: @escaping (Any?) -> Void, catch: ((Error) -> Void)?, finally: (() -> Void)?) {
        self.operation() { result in
            if let error = result as? Error {
                `catch`?(error)
            } else {
                done(result)
            }
            finally?()
        }
    }
    
    /// 执行当前约定并返回下一个约定
    public func then(_ block: @escaping (_ value: Any?) -> FWPromise) -> FWPromise {
        return FWPromise { completion in
            self.done { value in
                block(value).done(completion: completion)
            } catch: { error in
                completion(error)
            }
        }
    }
    
    /// 仿协程异步执行方法
    @discardableResult
    public static func async(_ block: @escaping () throws -> Any?) -> FWPromise {
        return FWPromise { completion in
            DispatchQueue(label: "FWPromise.async.queue", attributes: .concurrent).async {
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
}

/// 常用约定方法
@objc public extension FWPromise {
    /// 映射当前约定的结果并返回下一个约定
    func map(_ block: @escaping (_ value: Any?) -> Any?) -> FWPromise {
        return FWPromise { completion in
            self.done { value in
                completion(block(value))
            } catch: { error in
                completion(error)
            }
        }
    }
    
    /// 全部约定，所有约定成功才返回约定结果合集；如果某一个失败了，则返回该错误信息
    @discardableResult
    static func all(_ promises: [FWPromise]) -> FWPromise {
        return FWPromise { completion in
            var finished = false
            var values: [Any?] = []
            let semaphore = DispatchSemaphore(value: 1)
            for promise in promises {
                promise.done { value in
                    semaphore.wait()
                    if !finished {
                        values.append(value)
                        if values.count == promises.count {
                            finished = true
                            completion(values)
                        }
                    }
                    semaphore.signal()
                } catch: { error in
                    semaphore.wait()
                    if !finished {
                        finished = true
                        completion(error)
                    }
                    semaphore.signal()
                }
            }
        }
    }
    
    /// 某个约定，返回最先成功的约定结果；如果都失败了，返回最后一个错误信息
    @discardableResult
    static func any(_ promises: [FWPromise]) -> FWPromise {
        return FWPromise { completion in
            var finished = false
            var failedCount = 0
            let semaphore = DispatchSemaphore(value: 1)
            for promise in promises {
                promise.done { value in
                    semaphore.wait()
                    if !finished {
                        finished = true
                        completion(value)
                    }
                    semaphore.signal()
                } catch: { error in
                    semaphore.wait()
                    if !finished {
                        failedCount += 1
                        if failedCount == promises.count {
                            finished = true
                            completion(error)
                        }
                    }
                    semaphore.signal()
                }
            }
        }
    }
    
    /// 约定竞速，返回最先结束的约定结果，不管成功或失败
    @discardableResult
    static func race(_ promises: [FWPromise]) -> FWPromise {
        return FWPromise { completion in
            var finished = false
            let semaphore = DispatchSemaphore(value: 1)
            for promise in promises {
                promise.done { result in
                    semaphore.wait()
                    if !finished {
                        finished = true
                        completion(result)
                    }
                    semaphore.signal()
                }
            }
        }
    }
}
