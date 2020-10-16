//
//  FWPromise.swift
//  FWFramework
//
//  Created by wuyong on 2020/10/16.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import Foundation
import Dispatch

private class Locker {
    let lockQueueSpecificKey: DispatchSpecificKey<Void>
    let lockQueue: DispatchQueue
    init() {
        lockQueueSpecificKey = DispatchSpecificKey<Void>()
        lockQueue = DispatchQueue(label: "com.freshOS.then.lockQueue", qos: .userInitiated)
        lockQueue.setSpecific(key: lockQueueSpecificKey, value: ())
    }
  
    var isOnLockQueue: Bool {
        return DispatchQueue.getSpecific(key: lockQueueSpecificKey) != nil
    }
}

/// https://github.com/freshOS/Then
public class Promise<T> {
    
    // MARK: - Protected properties
    
    internal var numberOfRetries: UInt = 0

    private var threadUnsafeState: PromiseState<T>
    
    private var threadUnsafeBlocks: PromiseBlocks<T> = PromiseBlocks<T>()

    private var initialPromiseStart:(() -> Void)?
    private var initialPromiseStarted = false
    
    internal typealias ProgressCallBack = (_ resolve: @escaping ((T) -> Void),
        _ reject: @escaping ((Error) -> Void),
        _ progress: @escaping ((Float) -> Void)) -> Void
    
    private var promiseProgressCallBack: ProgressCallBack?
    
    // MARK: - Lock
  
    private let locker = Locker()
    private var lockQueue: DispatchQueue {
        return locker.lockQueue
    }
    private func _synchronize<U>(_ action: () -> U) -> U {
        if locker.isOnLockQueue {
            return action()
        } else {
            return lockQueue.sync(execute: action)
        }
    }
    
    private func _asynchronize(_ action: @escaping () -> Void) {
        lockQueue.async(execute: action)
    }
    
    // MARK: - Intializers
    
    public init() {
        threadUnsafeState = .dormant
    }
    
    public init(_ value: T) {
        threadUnsafeState = .fulfilled(value: value)
    }
    
    public init(error: Error) {
        threadUnsafeState = PromiseState.rejected(error: error)
    }

    public convenience init(callback: @escaping (
                            _ resolve: @escaping ((T) -> Void),
                            _ reject: @escaping ((Error) -> Void)) -> Void) {
        self.init()
        promiseProgressCallBack = { resolve, reject, progress in
            callback(resolve, reject)
        }
    }
    
    public convenience init(callback: @escaping (
                            _ resolve: @escaping ((T) -> Void),
                            _ reject: @escaping ((Error) -> Void),
                            _ progress: @escaping ((Float) -> Void)) -> Void) {
        self.init()
        promiseProgressCallBack = { resolve, reject, progress in
            callback(resolve, reject, progress)
        }
    }
    
    // MARK: - Private atomic operations
    
    private func _updateFirstPromiseStartFunctionAndState(from startBody: @escaping () -> Void, isStarted: Bool) {
        _synchronize {
            initialPromiseStart = startBody
            initialPromiseStarted = isStarted
        }
    }
    
    // MARK: - Public interfaces
    
    public func start() {
        _synchronize({ return _start() })?()
    }

    public func fulfill(_ value: T) {
        _synchronize({ () -> (() -> Void)? in
            let action = _updateState(.fulfilled(value: value))
            threadUnsafeBlocks = .init()
            promiseProgressCallBack = nil
            return action
        })?()
    }
    
    public func reject(_ anError: Error) {
        _synchronize({ () -> (() -> Void)? in
            let action = _updateState(.rejected(error: anError))
            // Only release callbacks if no retries a registered.
            if numberOfRetries == 0 {
                threadUnsafeBlocks = .init()
                promiseProgressCallBack = nil
            }
            return action
        })?()
    }
    
    // MARK: - Internal interfaces
    
    internal func synchronize<U>(
        _ action: (_ currentState: PromiseState<T>, _ blocks: inout PromiseBlocks<T>) -> U) -> U {
        return _synchronize {
            return action(threadUnsafeState, &threadUnsafeBlocks)
        }
    }
    
    internal func resetState() {
        _synchronize {
            threadUnsafeState = .dormant
        }
    }
    
    internal func passAlongFirstPromiseStartFunctionAndStateTo<X>(_ promise: Promise<X>) {
        let (startBlock, isStarted) = _synchronize {
            return (self.initialPromiseStart ?? self.start, self.initialPromiseStarted)
        }
        promise._updateFirstPromiseStartFunctionAndState(from: startBlock, isStarted: isStarted)
    }
    
    internal func tryStartInitialPromiseAndStartIfneeded() {
        var actions: [(() -> Void)?] = []
        _synchronize {
            actions = [
                _startInitialPromiseIfNeeded(),
                _start()
            ]
        }
        actions.forEach { $0?() }
    }
    
    internal func updateState(_ newState: PromiseState<T>) {
        _synchronize({ return _updateState(newState) })?()
    }
    
    internal func setProgressCallBack(_ promiseProgressCallBack: @escaping ProgressCallBack) {
        _synchronize {
            self.promiseProgressCallBack = promiseProgressCallBack
        }
    }
    
    internal func newLinkedPromise() -> Promise<T> {
        let p = Promise<T>()
        passAlongFirstPromiseStartFunctionAndStateTo(p)
        return p
    }
    
    internal func syncStateWithCallBacks(success: @escaping ((T) -> Void),
                                         failure: @escaping ((Error) -> Void),
                                         progress: @escaping ((Float) -> Void)) {
        _synchronize {
            switch threadUnsafeState {
            case let .fulfilled(value):
                success(value)
            case let .rejected(error):
                failure(error)
            case .dormant, .pending:
                threadUnsafeBlocks.success.append(success)
                threadUnsafeBlocks.fail.append(failure)
                threadUnsafeBlocks.progress.append(progress)
            }
        }
    }
    
    // MARK: - Private non-atomic operations
    
    private func _startInitialPromiseIfNeeded() -> (() -> Void)? {
        guard !initialPromiseStarted else { return nil }
        initialPromiseStarted = true
        let body = self.initialPromiseStart
        return body
    }
    
    private func _start() -> (() -> Void)? {
        guard threadUnsafeState.isDormant else { return nil }
        
        let updateAction = _updateState(.pending(progress: 0))
        guard let p = promiseProgressCallBack else { return updateAction }
        return {
            updateAction?()
            p(self.fulfill, self.reject, self.setProgress)
        }
//            promiseProgressCallBack = nil //Remove callba
    }
    
    private func _updateState(_ newState: PromiseState<T>) -> (() -> Void)? {
        if threadUnsafeState.isPendingOrDormant {
            threadUnsafeState = newState
        }
        return launchCallbacksIfNeeded()
    }
    
    private func launchCallbacksIfNeeded() -> (() -> Void)? {
        switch threadUnsafeState {
        case .dormant:
            return nil
        case .pending(let progress):
            if progress != 0 {
                return threadUnsafeBlocks.updateProgress(progress)
            } else {
                return nil
            }
        case .fulfilled(let value):
            initialPromiseStart = nil
            return threadUnsafeBlocks.fulfill(value: value)
        case .rejected(let anError):
            initialPromiseStart = nil
            return threadUnsafeBlocks.reject(error: anError)
        }
    }
}

// MARK: - Helpers
extension Promise {
    
    var isStarted: Bool {
        return synchronize { state, _ in
            switch state {
            case .dormant:
                return false
            default:
                return true
            }
        }
    }
}

// MARK: - Extension
public typealias EmptyPromise = Promise<Void>
public typealias Async<T> = Promise<T>
public typealias AsyncTask = Async<Void>

public extension Promise {
    
    func bridgeError(to myError: Error) -> Promise<T> {
        let p = newLinkedPromise()
        syncStateWithCallBacks(
            success: p.fulfill,
            failure: { _ in
                p.reject(myError)
            },
            progress: p.setProgress)
        return p
    }
    
    func bridgeError(_ errorType: Error, to myError: Error) -> Promise<T> {
        let p = newLinkedPromise()
        syncStateWithCallBacks(
            success: p.fulfill,
            failure: { e in
                if e._code == errorType._code && e._domain == errorType._domain {
                    p.reject(myError)
                } else {
                    p.reject(e)
                }
            },
            progress: p.setProgress)
        return p
    }
    
    func bridgeError(_ block:@escaping (Error) throws -> Void) -> Promise<T> {
        let p = newLinkedPromise()
        syncStateWithCallBacks(
            success: p.fulfill,
            failure: { e in
                do {
                    try block(e)
                } catch {
                    p.reject(error)
                }
            },
            progress: p.setProgress)
        return p
    }
}

public extension Promise {
    
    func chain(_ block:@escaping (T) -> Void) -> Promise<T> {
        let p = newLinkedPromise()
        syncStateWithCallBacks(success: { t in
            block(t)
            p.fulfill(t)
        }, failure: p.reject, progress: p.setProgress)
        return p
    }
}

extension Promise {
    
    public func delay(_ time: TimeInterval) -> Promise<T> {
        let p = newLinkedPromise()
        syncStateWithCallBacks(
            success: { t in
                Promises.callBackOnCallingQueueIn(time: time) {
                    p.fulfill(t)
                }
            },
            failure: p.reject,
            progress: p.setProgress)
        return p
    }
}

extension Promises {
    public static func delay(_ time: TimeInterval) -> Promise<Void> {
        return Promise { (resolve: @escaping (() -> Void), _: @escaping ((Error) -> Void)) in
            callBackOnCallingQueueIn(time: time, block: resolve)
        }
    }
}

extension Promises {

    static func callBackOnCallingQueueIn(time: TimeInterval, block: @escaping () -> Void) {
        if let callingQueue = OperationQueue.current?.underlyingQueue {
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).asyncAfter(deadline: .now() + time) {
                callingQueue.async {
                    block()
                }
            }
        } else {
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + time) {
                block()
            }
        }
    }
}

public extension Promise {
    
    @discardableResult func onError(_ block: @escaping (Error) -> Void) -> Promise<Void> {
        tryStartInitialPromiseAndStartIfneeded()
        return registerOnError(block)
    }
    
    @discardableResult func registerOnError(_ block: @escaping (Error) -> Void) -> Promise<Void> {
        let p = Promise<Void>()
        passAlongFirstPromiseStartFunctionAndStateTo(p)
        syncStateWithCallBacks(
            success: { _ in
                p.fulfill(())
            },
            failure: { e in
                block(e)
                p.fulfill(())
            },
            progress: p.setProgress
        )
        p.start()
        return p
    }
}

public extension Promise {
    
    func finally(_ block: @escaping () -> Void) {
        tryStartInitialPromiseAndStartIfneeded()
        registerFinally(block)
    }
    
    func registerFinally(_ block: @escaping () -> Void) {
        synchronize { state, blocks in
            switch state {
            case .rejected, .fulfilled:
                block()
            case .dormant, .pending:
                blocks.finally.append(block)
            }
        }
    }
}

extension Promise {
    public func first<E>() -> Promise<E> where T == [E] {
        return self.then { unwrap($0.first) }
    }
}

extension Promise {
    public func last<E>() -> Promise<E> where T == [E] {
        return self.then { unwrap($0.last) }
    }
}

public extension Promise {
    class func reject(_ error: Error = PromiseError.default) -> Promise<T> {
        return Promise { _, reject in reject(error) }
    }
}

public extension Promise {
    class func resolve(_ value: T) -> Promise<T> {
        return Promise { resolve, _ in resolve(value) }
    }
}

extension Promise where T == Void {
    public class func resolve() -> Promise<Void> {
        return Promise { resolve, _ in resolve() }
    }
}

public extension Promise {
    
    var value: T? {
        return synchronize { state, _ in
            return state.value
        }
    }
    
    var error: Error? {
        return synchronize { state, _ in
            return state.error
        }
    }
}

extension Promise {
    public func convertErrorToNil() -> Promise<T?> {
        return Promise<T?> { resolve, _ in
            self.then { t in
                resolve(t)
            }.onError { _ in
                resolve(nil)
            }
        }
    }
}

extension Promise {

    public func noMatterWhat(_ block: @escaping () -> Void) -> Promise<T> {
        let p = newLinkedPromise()
        syncStateWithCallBacks(
            success: { t in
                block()
                p.fulfill(t)
            },
            failure: { e in
                block()
                p.reject(e)
            },
            progress: p.setProgress)
        return p
    }
}

public extension Promise {
    
    @discardableResult func progress(_ block: @escaping (Float) -> Void) -> Promise<T> {
        tryStartInitialPromiseAndStartIfneeded()
        let p = newLinkedPromise()
        syncStateWithCallBacks(
            success: p.fulfill,
            failure: p.reject,
            progress: { f in
                block(f)
                p.setProgress(f)
            }
        )
        p.start()
        return p
    }
    
    internal func setProgress(_ value: Float) {
        updateState(PromiseState<T>.pending(progress: value))
    }
}

extension Promises {
    
    /// `Promise.race(p1, p2, p3, p4...)`Takes the state of the fastest returning promise.
    /// If the first fails, it fails. If the first resolves, it resolves.
    public static func race<T>(_ promises: Promise<T>...) -> Promise<T> {
        return Promise { resolve, reject in
            for p in promises {
                p.then { t in
                    resolve(t)
                }.onError { e in
                    reject(e)
                }
            }
        }
    }
}

extension Promise {
    
    public func recover(with value: T) -> Promise<T> {
        let p = newLinkedPromise()
        syncStateWithCallBacks(
            success: p.fulfill,
            failure: { _ in
                p.fulfill(value)
        }, progress: p.setProgress)
        return p
    }

    public func recover<E: Error>(_ errorType: E, with value: T) -> Promise<T> {
        let p = newLinkedPromise()
        syncStateWithCallBacks(
            success: p.fulfill,
            failure: { e in
                if errorMatchesExpectedError(e, expectedError: errorType) {
                    p.fulfill(value)
                } else {
                    p.reject(e)
                }
            },
            progress: p.setProgress)
        return p
    }
    
    public func recover<E: Error>(_ errorType: E, with value: T) -> Promise<T> where E: Equatable {
        let p = newLinkedPromise()
        syncStateWithCallBacks(
            success: p.fulfill,
            failure: { e in
                if errorMatchesExpectedError(e, expectedError: errorType) {
                    p.fulfill(value)
                } else {
                    p.reject(e)
                }
            },
            progress: p.setProgress)
        
        return p
    }
    
    public func recover(with promise: Promise<T>) -> Promise<T> {
        let p = newLinkedPromise()
        syncStateWithCallBacks(
            success: p.fulfill,
            failure: { _ in
                promise.then { t in
                    p.fulfill(t)
                }.onError { error in
                    p.reject(error)
                }
            },
            progress: p.setProgress)
        return p
    }
    
    public func recover(_ block:@escaping (Error) throws -> T) -> Promise<T> {
        let p = newLinkedPromise()
        syncStateWithCallBacks(
            success: p.fulfill,
            failure: { e in
                do {
                    let v = try block(e)
                    p.fulfill(v)
                } catch {
                    p.reject(error)
                }
        }, progress: p.setProgress)
        return p
    }

    public func recover(_ block:@escaping (Error) throws -> Promise<T>) -> Promise<T> {
        let p = newLinkedPromise()
        syncStateWithCallBacks(
            success: p.fulfill,
            failure: { e in
                do {
                    let promise = try block(e)
                    promise.then { t in
                        p.fulfill(t)
                    }.onError { error in
                        p.reject(error)
                    }
                } catch {
                    p.reject(error)
                }
        }, progress: p.setProgress)
        return p
    }

}

// Credits to Quick/Nimble for how to compare Errors
// https://github.com/Quick/Nimble/blob/db706fc1d7130f6ac96c56aaf0e635fa3217fe57/Sources/
// Nimble/Utils/Errors.swift#L37-L53
private func errorMatchesExpectedError<T: Error>(_ error: Error, expectedError: T) -> Bool {
    return error._domain == expectedError._domain && error._code   == expectedError._code
}

private func errorMatchesExpectedError<T: Error>(_ error: Error,
                                                 expectedError: T) -> Bool where T: Equatable {
    if let error = error as? T {
        return error == expectedError
    }
    return false
}

extension Promise {
    public func retry(_ nbOfTimes: UInt) -> Promise<T> {
        guard nbOfTimes > 0 else {
            return Promise.reject(PromiseError.retryInvalidInput)
        }
        let p = newLinkedPromise()
        self.numberOfRetries = nbOfTimes
        self.syncStateWithCallBacks(
            success: { [weak self] t in
                self?.numberOfRetries = 0
                p.fulfill(t)
            },
            failure: { [weak self] e in
                self?.numberOfRetries -= 1
                if self?.numberOfRetries == 0 {
                    p.reject(e)
                } else {
                    self?.resetState()
                    self?.start()
                }
            },
            progress: p.setProgress)
        return p
    }
}

public extension Promise {
    
    @discardableResult func then<X>(_ block: @escaping (T) -> X) -> Promise<X> {
        let p = registerThen(block)
        tryStartInitialPromiseAndStartIfneeded()
        return p
    }
    
    @discardableResult func registerThen<X>(_ block: @escaping (T) -> X) -> Promise<X> {
        let p = Promise<X>()
        
        synchronize { state, blocks in
            switch state {
            case let .fulfilled(value):
                let x: X = block(value)
                p.fulfill(x)
            case let .rejected(error):
                p.reject(error)
            case .dormant, .pending:
                blocks.success.append({ t in
                    p.fulfill(block(t))
                })
                blocks.fail.append({ e in
                    p.reject(e)
                })
                blocks.progress.append({ f in
                    p.setProgress(f)
                })
            }
        }
        passAlongFirstPromiseStartFunctionAndStateTo(p)
        return p
    }
    
    @discardableResult func then<X>(_ block: @escaping (T) -> Promise<X>) -> Promise<X> {
        tryStartInitialPromiseAndStartIfneeded()
        return registerThen(block)
    }
    
    @discardableResult  func registerThen<X>(_ block: @escaping (T) -> Promise<X>)
        -> Promise<X> {
            let p = Promise<X>()
            
            synchronize { state, blocks in
                switch state {
                case let .fulfilled(value):
                    registerNextPromise(block, result: value,
                                        resolve: p.fulfill, reject: p.reject)
                case let .rejected(error):
                    p.reject(error)
                case .dormant, .pending:
                    blocks.success.append({ [weak self] t in
                        self?.registerNextPromise(block, result: t, resolve: p.fulfill,
                                                  reject: p.reject)
                    })
                    blocks.fail.append(p.reject)
                    blocks.progress.append(p.setProgress)
                }
            }
            p.start()
            passAlongFirstPromiseStartFunctionAndStateTo(p)
            return p
    }
    
    @discardableResult func then<X>(_ promise: Promise<X>) -> Promise<X> {
        return then { _ in promise }
    }
    
    @discardableResult func registerThen<X>(_ promise: Promise<X>) -> Promise<X> {
        return registerThen { _ in promise }
    }
    
    fileprivate func registerNextPromise<X>(_ block: (T) -> Promise<X>,
                                            result: T,
                                            resolve: @escaping (X) -> Void,
                                            reject: @escaping ((Error) -> Void)) {
        let nextPromise: Promise<X> = block(result)
        nextPromise.then { x in
            resolve(x)
        }.onError(reject)
    }
}

extension Promise {
    
    public func timeout(_ time: TimeInterval) -> Promise<T> {
        let timer: Promise<T> = Promises.delay(time).then {
            return Promise<T>.reject(PromiseError.timeout)
        }
        return Promises.race(timer, self)
    }
}

public func unwrap<T>(_ param: T?) -> Promise<T> {
    if let param = param {
        return Promise.resolve(param)
    } else {
        return Promise.reject(PromiseError.unwrappingFailed)
    }
}

extension Promise {
    
    @discardableResult
    public func validate(withError: Error = PromiseError.validationFailed,
                         _ assertionBlock:@escaping ((T) -> Bool)) -> Promise<T> {
        let p = newLinkedPromise()
        syncStateWithCallBacks(
            success: { t in
                if assertionBlock(t) {
                    p.fulfill(t)
                } else {
                    p.reject(withError)
                }
            },
            failure: p.reject,
            progress: p.setProgress)
        return p
    }
}

extension Promises {
    
    public static func zip<T, U>(_ p1: Promise<T>, _ p2: Promise<U>) -> Promise<(T, U)> {
        
        let p = Promise<(T, U)>()
        var t: T!
        var u: U!
        var error: Error?
        let group = DispatchGroup()
        
        // We run the promises concurrently on a concurent queue and go back
        // to a local queue to read/modify global variables.
        // .barrier blocks concurrency so that we can write values
        // without then beeing read at the same time.
        // It pauses reads until write are done
        let concurentQueue = DispatchQueue(label: "then.zip.concurrent", attributes: .concurrent)
        let localQueue = DispatchQueue(label: "then.zip.local", attributes: .concurrent)
        
        group.enter()
        concurentQueue.async {
            p1.then { aT in
                localQueue.async(flags: .barrier) {
                    t = aT
                }
                }.onError { e in
                    localQueue.async(flags: .barrier) {
                        error = e
                    }
                }.finally {
                    localQueue.async { // barrier needed?
                        group.leave()
                    }
            }
        }
        
        group.enter()
        concurentQueue.async {
            p2.then { aU in
                localQueue.async(flags: .barrier) {
                    u = aU
                }
                }.onError { e in
                    localQueue.async(flags: .barrier) {
                        error = e
                    }
                }.finally {
                    localQueue.async {
                        group.leave()
                    }
            }
        }
        
        let callingQueue = OperationQueue.current?.underlyingQueue
        let queue = callingQueue ?? DispatchQueue.main
        group.notify(queue: queue) {
            localQueue.async {
                if let e = error {
                    p.reject(e)
                } else {
                    p.fulfill((t, u))
                }
            }
        }
        return p
    }
    
    // zip 3
    public static func zip<T, U, V>(_ p1: Promise<T>, _ p2: Promise<U>, _ p3: Promise<V>) -> Promise<(T, U, V)> {
        return zip(zip(p1, p2), p3).then { ($0.0, $0.1, $1) }
    }
    
    // zip 4
    public static func zip<A, B, C, D>(_ p1: Promise<A>,
                                       _ p2: Promise<B>,
                                       _ p3: Promise<C>,
                                       _ p4: Promise<D>) -> Promise<(A, B, C, D)> {
        return zip(zip(p1, p2, p3), p4).then { ($0.0, $0.1, $0.2, $1) }
    }
    
    // zip 5
    public static func zip<A, B, C, D, E>(_ p1: Promise<A>,
                                          _ p2: Promise<B>,
                                          _ p3: Promise<C>,
                                          _ p4: Promise<D>,
                                          _ p5: Promise<E>) -> Promise<(A, B, C, D, E)> {
        return zip(zip(p1, p2, p3, p4), p5).then { ($0.0, $0.1, $0.2, $0.3, $1) }
    }
    
    // zip 6 swiftlint:disable function_parameter_count
    public static func zip<A, B, C, D, E, F>(_ p1: Promise<A>,
                                             _ p2: Promise<B>,
                                             _ p3: Promise<C>,
                                             _ p4: Promise<D>,
                                             _ p5: Promise<E>,
                                             _ p6: Promise<F>) -> Promise<(A, B, C, D, E, F)> {
        return zip(zip(p1, p2, p3, p4, p5), p6 ).then { ($0.0, $0.1, $0.2, $0.3, $0.4, $1) }
    }
    
    // zip 7
    public static func zip<A, B, C, D, E, F, G>(_ p1: Promise<A>,
                                                _ p2: Promise<B>,
                                                _ p3: Promise<C>,
                                                _ p4: Promise<D>,
                                                _ p5: Promise<E>,
                                                _ p6: Promise<F>,
                                                _ p7: Promise<G>) -> Promise<(A, B, C, D, E, F, G)> {
        return zip(zip(p1, p2, p3, p4, p5, p6), p7).then { ($0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $1) }
    }
    
    // zip 8
    public static func zip<A, B, C, D, E, F, G, H>(_ p1: Promise<A>,
                                                   _ p2: Promise<B>,
                                                   _ p3: Promise<C>,
                                                   _ p4: Promise<D>,
                                                   _ p5: Promise<E>,
                                                   _ p6: Promise<F>,
                                                   _ p7: Promise<G>,
                                                   _ p8: Promise<H>) -> Promise<(A, B, C, D, E, F, G, H)> {
        return zip(zip(p1, p2, p3, p4, p5, p6, p7), p8).then { ($0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $0.6, $1) }
    }
    // swiftlint:enable function_parameter_count
}

// MARK: - PromiseBlocks
struct PromiseBlocks<T> {
    
    typealias SuccessBlock = (T) -> Void
    typealias FailBlock = (Error) -> Void
    typealias ProgressBlock = (Float) -> Void
    typealias FinallyBlock = () -> Void
    
    var success = [SuccessBlock]()
    var fail = [FailBlock]()
    var progress = [ProgressBlock]()
    var finally = [FinallyBlock]()
}

extension PromiseBlocks {
    
    func updateProgress(_ progress: Float) -> () -> Void {
        let progressBlocks = self.progress
        return {
            progressBlocks.forEach { $0(progress) }
        }
    }
    
    func fulfill(value: T) -> () -> Void {
        let successBlocks = self.success
        let finallyBlocks = self.finally
        return {
            successBlocks.forEach { $0(value) }
            finallyBlocks.forEach { $0() }
        }
    }
    
    func reject(error: Error) -> () -> Void {
        let failureBlocks = self.fail
        let finallyBlocks = self.finally
        return {
            failureBlocks.forEach { $0(error) }
            finallyBlocks.forEach { $0() }
        }
    }
}

// MARK: - PromiseError
public enum PromiseError: Error {
    case `default`
    case validationFailed
    case retryInvalidInput
    case unwrappingFailed
    case timeout
}

extension PromiseError: Equatable { }

public func == (lhs: PromiseError, rhs: PromiseError) -> Bool {
    switch (lhs, rhs) {
    case (.default, .default):
            return true
    case (.validationFailed, .validationFailed):
        return true
    case (.retryInvalidInput, .retryInvalidInput):
        return true
    case (.unwrappingFailed, .unwrappingFailed):
        return true
    default:
        return false
    }
}

// MARK: - PromiseState
public enum PromiseState<T> {
    case dormant
    case pending(progress: Float)
    case fulfilled(value: T)
    case rejected(error: Error)
}

extension PromiseState {
    
    var value: T? {
        if case let .fulfilled(value) = self {
            return value
        }
        return nil
    }
    
    var error: Error? {
        if case let .rejected(error) = self {
            return error
        }
        return nil
    }
    
    var isDormant: Bool {
        if case .dormant = self {
            return true
        }
        return false
    }
    
    var isPendingOrDormant: Bool {
        return !isFulfilled && !isRejected
    }
    
    var isFulfilled: Bool {
        if case .fulfilled = self {
            return true
        }
        return false
    }
    
    var isRejected: Bool {
        if case .rejected = self {
            return true
        }
        return false
    }
}

// MARK: - VoidPromise
extension Promise where T == Void {
    
    public convenience init(callback: @escaping (
        _ resolve: @escaping (() -> Void),
        _ reject: @escaping ((Error) -> Void)) -> Void) {
        self.init()
        setProgressCallBack { resolve, reject, _ in
            let wrapped = { resolve(()) }
            callback(wrapped, reject)
        }
    }
    
    public convenience init(callback2: @escaping (
        _ resolve: @escaping (() -> Void),
        _ reject: @escaping ((Error) -> Void),
        _ progress: @escaping ((Float) -> Void)) -> Void) {
        self.init()
        setProgressCallBack { resolve, reject, progress in
            let wrapped = { resolve(()) }
            callback2(wrapped, reject, progress)
        }
    }
}

// MARK: - WhenAll
public class Promises {}

extension Promises {
    
    public static func whenAll<T>(_ promises: [Promise<T>], callbackQueue: DispatchQueue? = nil) -> Promise<[T]> {
        return reduceWhenAll(promises, callbackQueue: callbackQueue) { (result, element) in
            result.append(element)
        }
    }
    
    public static func whenAll<T>(_ promises: Promise<T>..., callbackQueue: DispatchQueue? = nil) -> Promise<[T]> {
        return whenAll(promises, callbackQueue: callbackQueue)
    }
    
    public static func lazyWhenAll<T>(_ promises: [Promise<T>], callbackQueue: DispatchQueue? = nil) -> Promise<[T]> {
        return lazyReduceWhenAll(promises, callbackQueue: callbackQueue) { (result, element) in
            result.append(element)
        }
    }
    
    public static func lazyWhenAll<T>(_ promises: Promise<T>..., callbackQueue: DispatchQueue? = nil) -> Promise<[T]> {
        return lazyWhenAll(promises, callbackQueue: callbackQueue)
    }
    
    // Array version
    
    public static func whenAll<T>(_ promises: [Promise<[T]>], callbackQueue: DispatchQueue? = nil) -> Promise<[T]> {
        return reduceWhenAll(promises, callbackQueue: callbackQueue) { (result, element) in
            result.append(contentsOf: element)
        }
    }
    
    public static func whenAll<T>(_ promises: Promise<[T]>..., callbackQueue: DispatchQueue? = nil) -> Promise<[T]> {
        return whenAll(promises, callbackQueue: callbackQueue)
    }
    
    public static func lazyWhenAll<T>(_ promises: [Promise<[T]>], callbackQueue: DispatchQueue? = nil) -> Promise<[T]> {
        return lazyReduceWhenAll(promises, callbackQueue: callbackQueue) { (result, element) in
            result.append(contentsOf: element)
        }
    }
    
    public static func lazyWhenAll<T>(
        _ promises: Promise<[T]>...,
        callbackQueue: DispatchQueue? = nil) -> Promise<[T]> {
        return lazyWhenAll(promises, callbackQueue: callbackQueue)
    }
    
    // Private implementations
    
    private static func lazyReduceWhenAll<Result, Source>(
        _ promises: [Promise<Source>],
        callbackQueue: DispatchQueue?,
        updatePartialResult: @escaping (_ result: inout [Result], _ element: Source) -> Void) -> Promise<[Result]> {
        return Promise { fulfill, reject in
            reducePromises(
                promises,
                callbackQueue: callbackQueue,
                fulfill: fulfill,
                reject: reject,
                updatePartialResult: updatePartialResult)
        }
    }
    
    private static func reduceWhenAll<Result, Source>(
        _ promises: [Promise<Source>],
        callbackQueue: DispatchQueue?,
        updatePartialResult: @escaping (_ result: inout [Result], _ element: Source) -> Void) -> Promise<[Result]> {
        
        let p = Promise<[Result]>()
        reducePromises(
            promises,
            callbackQueue: callbackQueue,
            fulfill: p.fulfill,
            reject: p.reject,
            updatePartialResult: updatePartialResult)
        return p
    }
    
    private static func reducePromises<Result, Source>(
        _ promises: [Promise<Source>],
        callbackQueue: DispatchQueue?,
        fulfill: @escaping ([Result]) -> Void,
        reject: @escaping (Error) -> Void,
        updatePartialResult: @escaping (_ result: inout [Result], _ element: Source) -> Void) {
        
        let ts = ArrayContainer<Result>()
        var error: Error?
        let group = DispatchGroup()
        for p in promises {
            group.enter()
            p.then { element in
                ts.updateArray({ updatePartialResult(&$0, element) })
                }
                .onError { error = $0 }
                .finally { group.leave() }
        }
        let callingQueue = OperationQueue.current?.underlyingQueue
        let queue = callbackQueue ?? callingQueue ??  DispatchQueue.main
        group.notify(queue: queue) {
            if let e = error {
                reject(e)
            } else {
                fulfill(ts.array)
            }
        }
    }
    
    private class ArrayContainer<T> {
        private var _array: [T] = []
        private let lockQueue = DispatchQueue(label: "com.freshOS.then.whenAll.lockQueue", qos: .userInitiated)
        
        func updateArray(_ updates: @escaping (_ result: inout [T]) -> Void) {
            lockQueue.async {
                updates(&self._array)
            }
        }
      
        var array: [T] {
            return lockQueue.sync {
                _array
            }
        }
    }
}

// MARK: - Async
@discardableResult
public func async<T>(block:@escaping () throws -> T) -> Async<T> {
    let p = Promise<T> { resolve, reject in
        DispatchQueue(label: "then.async.queue", attributes: .concurrent).async {
            do {
                let t = try block()
                resolve(t)
            } catch {
                reject(error)
            }
        }
    }
    p.start()
    return p
}

// MARK: - Await
@discardableResult public func await<T>(_ promise: Promise<T>) throws -> T {
    var result: T!
    var error: Error?
    let group = DispatchGroup()
    group.enter()
    promise.then { t in
        result = t
        group.leave()
    }.onError { e in
        error = e
        group.leave()
    }
    group.wait()
    if let e = error {
        throw e
    }
    return result
}

prefix operator ..

public prefix func .. <T>(promise: Promise<T>) throws -> T {
    return try await(promise)
}

public prefix func .. <T>(promise: Promise<T>?) throws -> T {
    guard let promise = promise else { throw PromiseError.unwrappingFailed }
    return try await(promise)
}

prefix operator ..?

public prefix func ..? <T>(promise: Promise<T>) -> T? {
    do {
        return try await(promise)
    } catch {
        return nil
    }
}

public prefix func ..? <T>(promise: Promise<T>?) -> T? {
    guard let promise = promise else { return nil }
    do {
        return try await(promise)
    } catch {
        return nil
    }
}
