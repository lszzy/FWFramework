//
//  Error.swift
//  FWFramework
//
//  Created by wuyong on 2023/8/14.
//

import Foundation

// MARK: - Notification+Exception
extension Notification.Name {
    /// 错误捕获通知，object为Error对象，userInfo为附加信息(function|file|line|remark|crashed|symbols)
    public static let ErrorCaptured = Notification.Name("FWErrorCapturedNotification")
}

// MARK: - ErrorManager
/// 错误异常捕获类
///
/// [JJException](https://github.com/jezzmemo/JJException)
/// [AvoidCrash](https://github.com/chenfanfang/AvoidCrash)
public class ErrorManager: @unchecked Sendable {
    /// 自定义需要捕获未定义方法异常的类，默认[NSNull, NSNumber, NSString, NSArray, NSDictionary]
    public static var captureClasses: [AnyClass] {
        get { shared.captureClasses }
        set { shared.captureClasses = newValue }
    }

    /// 自定义需要捕获的Signal字典，默认[SIGABRT, SIGSEGV, SIGBUS, SIGTRAP, SIGILL]
    public static var captureSignals: [Int32: String] {
        get { shared.captureSignals }
        set { shared.captureSignals = newValue }
    }

    /// 可选tryCatch句柄，需应用自行桥接ObjC实现，默认nil；
    /// 目前仅startCapture方法可选使用、PlayerCache 13.4以下系统可选使用，可不处理
    ///
    /// ObjC桥接代码示例：
    /// ```objc
    /// // ObjCBridge.h
    /// NS_ASSUME_NONNULL_BEGIN
    /// @interface ObjCBridge : NSObject
    /// + (void)tryCatch:(void (NS_NOESCAPE ^)(void))block exceptionHandler:(void (NS_NOESCAPE ^)(NSException *exception))exceptionHandler;
    /// @end
    /// NS_ASSUME_NONNULL_END
    ///
    /// // ObjCBridge.m
    /// @implementation ObjCBridge
    /// + (void)tryCatch:(void (NS_NOESCAPE ^)(void))block exceptionHandler:(void (NS_NOESCAPE ^)(NSException * _Nonnull))exceptionHandler {
    ///     @try {
    ///         if (block) block();
    ///     } @catch (NSException *exception) {
    ///         if (exceptionHandler) exceptionHandler(exception);
    ///     }
    /// }
    /// @end
    /// ```
    ///
    /// swift绑定代码示例：
    /// ```swift
    /// ErrorManager.tryCatchHandler = { ObjCBridge.tryCatch($0, exceptionHandler: $1) }
    /// ```
    public static var tryCatchHandler: (@Sendable (_ block: () -> Void, _ exceptionHandler: (NSException) -> Void) -> Void)? {
        get { shared.tryCatchHandler }
        set { shared.tryCatchHandler = newValue }
    }

    private static let shared = ErrorManager()
    private var captureClasses: [AnyClass] = [
        NSNull.self, NSNumber.self, NSString.self, NSArray.self, NSDictionary.self
    ]
    private var captureSignals: [Int32: String] = [
        SIGABRT: "SIGABRT",
        SIGSEGV: "SIGSEGV",
        SIGBUS: "SIGBUS",
        SIGTRAP: "SIGTRAP",
        SIGILL: "SIGILL"
    ]
    private var tryCatchHandler: (@Sendable (_ block: () -> Void, _ exceptionHandler: (NSException) -> Void) -> Void)?

    private var isStarted = false
    private var isExceptionStarted = false
    private var isSignalStarted = false

    private var isRegistered = false
    private var isExceptionRegistered = false
    private var isCrashHandled = false
    private var previousExceptionHandler: (@convention(c) (NSException) -> Void)?

    /// 开启框架错误捕获功能，默认仅处理captureClasses崩溃保护
    /// - Parameters:
    ///   - captureException: 是否捕获全局Exception错误
    ///   - captureSignal: 是否捕获全局Signal错误
    public static func startCapture(captureException: Bool = false, captureSignal: Bool = false) {
        guard !shared.isStarted else { return }

        shared.isStarted = true
        shared.isExceptionStarted = captureException
        shared.isSignalStarted = captureSignal

        if !shared.isRegistered {
            shared.isRegistered = true

            registerHandler()
        }
        if shared.isExceptionStarted, !shared.isExceptionRegistered {
            shared.isExceptionRegistered = true

            shared.previousExceptionHandler = NSGetUncaughtExceptionHandler()
            NSSetUncaughtExceptionHandler { ErrorManager.exceptionHandler($0) }
        }
        if shared.isSignalStarted {
            for (captureSignal, _) in captureSignals {
                signal(captureSignal) { ErrorManager.signalHandler($0) }
            }
        }
    }

    /// 停止框架错误捕获功能
    public static func stopCapture() {
        guard shared.isStarted else { return }

        shared.isStarted = false
        // 此处为了更好的兼容三方SDK无需还原异常句柄，因为保存的previous句柄可能不是最新的
        if shared.isExceptionStarted {
            shared.isExceptionStarted = false
        }
        if shared.isSignalStarted {
            shared.isSignalStarted = false

            for (captureSignal, _) in captureSignals {
                signal(captureSignal, SIG_DFL)
            }
        }
    }

    /// 捕获自定义错误并在当前线程发送通知，可设置备注
    public static func captureError(
        _ error: Error,
        crashed: Bool = false,
        remark: String? = nil,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        let userInfo: [String: Any] = [
            "function": function,
            "file": fileName,
            "line": line,
            "remark": remark ?? "",
            "crashed": crashed,
            "symbols": Thread.callStackSymbols
        ]

        #if DEBUG
        let nserror = error as NSError
        Logger.error(group: Logger.fw.moduleName, "\n========== ERROR ==========\ndomain: %@\n  code: %d\nreason: %@\nmethod: %@ #%d %@\nremark: %@\ncrashed: %@\n========== ERROR ==========", nserror.domain, nserror.code, nserror.localizedDescription, fileName, line, function, remark ?? "", String(describing: crashed))
        #endif

        NotificationCenter.default.post(name: .ErrorCaptured, object: error, userInfo: userInfo)
    }

    /// 将NSException异常转换为Error
    public static func error(with exception: NSException) -> Error {
        var userInfo: [String: Any] = [:]
        if let reason = exception.reason {
            userInfo[NSLocalizedDescriptionKey] = reason
        }
        if let info = exception.userInfo as? [String: Any] {
            userInfo.merge(info) { _, key2 in key2 }
        }
        return NSError(domain: exception.name.rawValue, code: 0, userInfo: userInfo)
    }

    /// 安全执行ObjC桥接tryCatch代码块，失败时抛Error，详见tryCatchHandler
    public static func tryCatch(_ block: () -> Void) throws {
        var exception: NSException?
        tryCatch(block) { exception = $0 }
        if let exception {
            throw error(with: exception)
        }
    }

    /// 安全执行ObjC桥接tryCatch代码块，失败时调用exceptionHandler，详见tryCatchHandler
    public static func tryCatch(_ block: () -> Void, exceptionHandler: (NSException) -> Void) {
        if tryCatchHandler != nil {
            tryCatchHandler?(block, exceptionHandler)
            return
        }

        block()
    }

    // MARK: - Private
    private static func registerHandler() {
        NSObject.fw.swizzleInstanceMethod(
            NSObject.self,
            selector: ObjCClassBridge.methodSignatureSelector,
            methodSignature: (@convention(c) (NSObject, Selector, Selector) -> AnyObject?).self,
            swizzleSignature: (@convention(block) (NSObject, Selector) -> AnyObject?).self
        ) { store in { selfObject, selector in
            let isCaptured = shared.isStarted && captureClasses.contains(where: { selfObject.isKind(of: $0) })
            guard isCaptured else {
                return store.original(selfObject, store.selector, selector)
            }

            var methodSignature = store.original(selfObject, store.selector, selector)
            if methodSignature == nil, let signatureClass = ObjCClassBridge.methodSignatureClass {
                methodSignature = signatureClass.objcSignature(withObjCTypes: "v@:@")
            }
            return methodSignature
        }}

        NSObject.fw.swizzleInstanceMethod(
            NSObject.self,
            selector: ObjCClassBridge.forwardInvocationSelector,
            methodSignature: (@convention(c) (NSObject, Selector, ObjCInvocationBridge) -> Void).self,
            swizzleSignature: (@convention(block) (NSObject, ObjCInvocationBridge) -> Void).self
        ) { store in { selfObject, invocation in
            let isCaptured = shared.isStarted && captureClasses.contains(where: { selfObject.isKind(of: $0) })
            guard isCaptured else {
                store.original(selfObject, store.selector, invocation)
                return
            }

            if tryCatchHandler != nil {
                do {
                    try tryCatch { store.original(selfObject, store.selector, invocation) }
                } catch {
                    captureError(error)
                }
            } else {
                invocation.objcTarget = nil
                invocation.objcInvoke()

                let reason = String(format: "-[%@ %@]: unrecognized selector sent to instance %@", NSStringFromClass(type(of: selfObject)), NSStringFromSelector(invocation.objcSelector), String(describing: Unmanaged.passUnretained(selfObject).toOpaque()))
                let exception = NSException(name: .invalidArgumentException, reason: reason, userInfo: nil)
                captureError(error(with: exception))
            }
        }}

        NSObject.fw.swizzleInstanceMethod(
            NSObject.self,
            selector: #selector(NSObject.setValue(_:forKey:)),
            methodSignature: (@convention(c) (NSObject, Selector, Any?, String) -> Void).self,
            swizzleSignature: (@convention(block) (NSObject, Any?, String) -> Void).self
        ) { store in { selfObject, value, key in
            guard shared.isStarted else {
                store.original(selfObject, store.selector, value, key)
                return
            }

            do {
                try tryCatch { store.original(selfObject, store.selector, value, key) }
            } catch {
                captureError(error)
            }
        }}

        NSObject.fw.swizzleInstanceMethod(
            NSObject.self,
            selector: #selector(NSObject.setValue(_:forKeyPath:)),
            methodSignature: (@convention(c) (NSObject, Selector, Any?, String) -> Void).self,
            swizzleSignature: (@convention(block) (NSObject, Any?, String) -> Void).self
        ) { store in { selfObject, value, keyPath in
            guard shared.isStarted else {
                store.original(selfObject, store.selector, value, keyPath)
                return
            }

            do {
                try tryCatch { store.original(selfObject, store.selector, value, keyPath) }
            } catch {
                captureError(error)
            }
        }}

        NSObject.fw.swizzleInstanceMethod(
            NSObject.self,
            selector: #selector(NSObject.setValue(_:forUndefinedKey:)),
            methodSignature: (@convention(c) (NSObject, Selector, Any?, String) -> Void).self,
            swizzleSignature: (@convention(block) (NSObject, Any?, String) -> Void).self
        ) { store in { selfObject, value, key in
            guard shared.isStarted else {
                store.original(selfObject, store.selector, value, key)
                return
            }

            do {
                try tryCatch { store.original(selfObject, store.selector, value, key) }
            } catch {
                captureError(error)
            }
        }}

        NSObject.fw.swizzleInstanceMethod(
            NSObject.self,
            selector: #selector(NSObject.setValuesForKeys(_:)),
            methodSignature: (@convention(c) (NSObject, Selector, [String: Any]) -> Void).self,
            swizzleSignature: (@convention(block) (NSObject, [String: Any]) -> Void).self
        ) { store in { selfObject, keyedValues in
            guard shared.isStarted else {
                store.original(selfObject, store.selector, keyedValues)
                return
            }

            do {
                try tryCatch { store.original(selfObject, store.selector, keyedValues) }
            } catch {
                captureError(error)
            }
        }}
    }

    private static func exceptionHandler(_ exception: NSException) {
        // NSException异常导致的Crash也会产生Signal错误，此处只记录一次
        if shared.isExceptionStarted, !shared.isCrashHandled {
            shared.isCrashHandled = true
            captureError(ErrorManager.error(with: exception), crashed: true)
        }

        shared.previousExceptionHandler?(exception)
    }

    private static func signalHandler(_ signal: Int32) {
        if shared.isSignalStarted, !shared.isCrashHandled {
            shared.isCrashHandled = true
            captureError(NSError(domain: captureSignals[signal] ?? "\(signal)", code: Int(signal), userInfo: nil), crashed: true)
        }

        exit(signal)
    }
}
