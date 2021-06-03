//
//  FWPromise.swift
//  FWFramework
//
//  Created by wuyong on 2021/06/03.
//  Copyright © 2021 wuyong.site. All rights reserved.
//

import Foundation

@discardableResult
public func fw_async(_ block: @escaping () throws -> Any?) -> FWPromise {
    return FWPromise.async(block)
}

@discardableResult
public func fw_await(_ promise: FWPromise) throws -> Any? {
    return try FWPromise.await(promise)
}

/// 框架约定类
///
/// 参考：https://github.com/AladinWay/PromisedFuture
@objcMembers public class FWPromise: NSObject {
    private let operation: (@escaping (Any?) -> Void) -> Void
    
    public init(operation: @escaping (_ completion: @escaping (Any?) -> Void) -> Void) {
        self.operation = operation
    }
    
    public convenience init(value: Any?) {
        self.init(operation: { completion in
            completion(value)
        })
    }
    
    public convenience init(error: Error) {
        self.init(operation: { completion in
            completion(error)
        })
    }
    
    public func done(completion: @escaping (Any?) -> Void) {
        self.operation() { result in
            completion(result)
        }
    }
    
    public func done(_ done: @escaping (Any?) -> Void, catch: ((Error) -> Void)? = nil) {
        self.done(done, catch: `catch`, finally: nil)
    }
    
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
    
    public func then(_ block: @escaping (_ value: Any?) -> FWPromise) -> FWPromise {
        return FWPromise { completion in
            self.done { value in
                block(value).done(completion: completion)
            } catch: { error in
                completion(error)
            }
        }
    }
    
    public func map(_ block: @escaping (_ value: Any?) -> Any?) -> FWPromise {
        return FWPromise { completion in
            self.done { value in
                completion(block(value))
            } catch: { error in
                completion(error)
            }
        }
    }
    
    @discardableResult
    public static func async(_ block: @escaping () throws -> Any?) -> FWPromise {
        let promise = FWPromise { completion in
            DispatchQueue(label: "FWPromise.async.queue", attributes: .concurrent).async {
                do {
                    let value = try block()
                    completion(value)
                } catch {
                    completion(error)
                }
            }
        }
        return promise
    }
    
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
