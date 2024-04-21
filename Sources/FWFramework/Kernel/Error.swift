//
//  Error.swift
//  FWFramework
//
//  Created by wuyong on 2023/8/14.
//

import Foundation

// MARK: - Notification+Exception
extension Notification.Name {
    
    /// 错误捕获通知，object为Error对象，userInfo为附加信息(function|file|line|remark|crash|symbols)
    public static let ErrorCaptured = Notification.Name("FWErrorCapturedNotification")
    
}

// MARK: - ErrorManager
/// 错误异常捕获类
///
/// [JJException](https://github.com/jezzmemo/JJException)
/// [AvoidCrash](https://github.com/chenfanfang/AvoidCrash)
public class ErrorManager: NSObject {
    
    /// 自定义需要捕获未定义方法异常的类，默认[NSNull, NSNumber, NSString, NSArray, NSDictionary]
    public static var captureClasses: [AnyClass] = [
        NSNull.self, NSNumber.self, NSString.self, NSArray.self, NSDictionary.self,
    ]
    
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
    public static var tryCatchHandler: ((_ block: () -> Void, _ exceptionHandler: (NSException) -> Void) -> Void)?
    
    private static var isStarted = false
    private static var isExceptionStarted = false
    private static var isSignalStarted = false
    
    private static var isRegistered = false
    private static var isExceptionRegistered = false
    private static var isSignalRegistered = false
    private static var isCrashHandled = false
    
    private static var previousExceptionHandler: (@convention(c) (NSException) -> Void)?
    private static var previousSignalHandlers: [Int32: @convention(c) (Int32) -> Void] = [:]
    
    /// 开启框架错误捕获功能，默认仅处理captureClasses崩溃保护
    /// - Parameters:
    ///   - captureException: 是否捕获全局Exception错误
    ///   - captureSignal: 是否捕获全局Signal错误
    public static func startCapture(captureException: Bool = false, captureSignal: Bool = false) {
        guard !isStarted else { return }
        
        isStarted = true
        isExceptionStarted = captureException
        isSignalStarted = captureSignal
        
        if !isRegistered {
            isRegistered = true
            registerHandler()
        }
        if isExceptionStarted, !isExceptionRegistered {
            isExceptionRegistered = true
            registerExceptionHandler()
        }
        if isSignalStarted, !isSignalRegistered {
            isSignalRegistered = true
            registerSignalHandler()
        }
    }
    
    /// 停止框架错误捕获功能
    ///
    /// 注意停止捕获时无需取消注册全局异常和Signal句柄，因为保存的previous句柄可能已经不是最新的句柄，可以更好的兼容三方SDK等注册全局异常和Signal句柄
    public static func stopCapture() {
        guard isStarted else { return }
        
        isStarted = false
        isExceptionStarted = false
        isSignalStarted = false
    }
    
    /// 捕获自定义错误并在当前线程发送通知，可设置备注
    public static func captureError(
        _ error: Error,
        crash: Bool = false,
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
            "crash": crash,
            "symbols": Thread.callStackSymbols,
        ]
        
        #if DEBUG
        let nserror = error as NSError
        Logger.debug(group: Logger.fw_moduleName, "\n========== ERROR ==========\ndomain: %@\n  code: %d\nreason: %@\nmethod: %@ #%d %@\nremark: %@\ncrash: %@\n========== ERROR ==========", nserror.domain, nserror.code, nserror.localizedDescription, fileName, line, function, remark ?? "", String(describing: crash))
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
            userInfo.merge(info) { key1, key2 in key2 }
        }
        return NSError(domain: exception.name.rawValue, code: 0, userInfo: userInfo)
    }
    
    /// 安全执行ObjC桥接tryCatch代码块，失败时抛Error，详见tryCatchHandler
    public static func tryCatch(_ block: () -> Void) throws {
        var exception: NSException?
        tryCatch(block) { exception = $0 }
        if let exception = exception {
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
        NSObject.fw_swizzleInstanceMethod(
            NSObject.self,
            selector: ObjCClassBridge.methodSignatureSelector,
            methodSignature: (@convention(c) (NSObject, Selector, Selector) -> AnyObject?).self,
            swizzleSignature: (@convention(block) (NSObject, Selector) -> AnyObject?).self
        ) { store in { selfObject, selector in
            let isCaptured = isStarted && captureClasses.contains(where: { selfObject.isKind(of: $0) })
            guard isCaptured else {
                return store.original(selfObject, store.selector, selector)
            }
            
            var methodSignature = store.original(selfObject, store.selector, selector)
            if methodSignature == nil, let signatureClass = ObjCClassBridge.methodSignatureClass {
                methodSignature = signatureClass.objcSignature(withObjCTypes: "v@:@")
            }
            return methodSignature
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            NSObject.self,
            selector: ObjCClassBridge.forwardInvocationSelector,
            methodSignature: (@convention(c) (NSObject, Selector, ObjCInvocationBridge) -> Void).self,
            swizzleSignature: (@convention(block) (NSObject, ObjCInvocationBridge) -> Void).self
        ) { store in { selfObject, invocation in
            let isCaptured = isStarted && captureClasses.contains(where: { selfObject.isKind(of: $0) })
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
        
        NSObject.fw_swizzleInstanceMethod(
            NSObject.self,
            selector: #selector(NSObject.setValue(_:forKey:)),
            methodSignature: (@convention(c) (NSObject, Selector, Any?, String) -> Void).self,
            swizzleSignature: (@convention(block) (NSObject, Any?, String) -> Void).self
        ) { store in { selfObject, value, key in
            guard isStarted else {
                store.original(selfObject, store.selector, value, key)
                return
            }
            
            do {
                try tryCatch { store.original(selfObject, store.selector, value, key) }
            } catch {
                captureError(error)
            }
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            NSObject.self,
            selector: #selector(NSObject.setValue(_:forKeyPath:)),
            methodSignature: (@convention(c) (NSObject, Selector, Any?, String) -> Void).self,
            swizzleSignature: (@convention(block) (NSObject, Any?, String) -> Void).self
        ) { store in { selfObject, value, keyPath in
            guard isStarted else {
                store.original(selfObject, store.selector, value, keyPath)
                return
            }
            
            do {
                try tryCatch { store.original(selfObject, store.selector, value, keyPath) }
            } catch {
                captureError(error)
            }
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            NSObject.self,
            selector: #selector(NSObject.setValue(_:forUndefinedKey:)),
            methodSignature: (@convention(c) (NSObject, Selector, Any?, String) -> Void).self,
            swizzleSignature: (@convention(block) (NSObject, Any?, String) -> Void).self
        ) { store in { selfObject, value, key in
            guard isStarted else {
                store.original(selfObject, store.selector, value, key)
                return
            }
            
            do {
                try tryCatch { store.original(selfObject, store.selector, value, key) }
            } catch {
                captureError(error)
            }
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            NSObject.self,
            selector: #selector(NSObject.setValuesForKeys(_:)),
            methodSignature: (@convention(c) (NSObject, Selector, [String : Any]) -> Void).self,
            swizzleSignature: (@convention(block) (NSObject, [String : Any]) -> Void).self
        ) { store in { selfObject, keyedValues in
            guard isStarted else {
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
    
    private static func registerExceptionHandler() {
        previousExceptionHandler = NSGetUncaughtExceptionHandler()
        NSSetUncaughtExceptionHandler { ErrorManager.exceptionHandler($0) }
    }
    
    private static func registerSignalHandler() {
        previousSignalHandlers[SIGABRT] = signal(SIGABRT, { ErrorManager.signalHandler($0, "SIGABRT", ErrorManager.previousSignalHandlers[SIGABRT]) })
        previousSignalHandlers[SIGSEGV] = signal(SIGSEGV, { ErrorManager.signalHandler($0, "SIGSEGV", ErrorManager.previousSignalHandlers[SIGSEGV]) })
        previousSignalHandlers[SIGBUS] = signal(SIGBUS, { ErrorManager.signalHandler($0, "SIGBUS", ErrorManager.previousSignalHandlers[SIGBUS]) })
        previousSignalHandlers[SIGTRAP] = signal(SIGTRAP, { ErrorManager.signalHandler($0, "SIGTRAP", ErrorManager.previousSignalHandlers[SIGTRAP]) })
        previousSignalHandlers[SIGILL] = signal(SIGILL, { ErrorManager.signalHandler($0, "SIGILL", ErrorManager.previousSignalHandlers[SIGILL]) })
    }
    
    private static func exceptionHandler(_ exception: NSException) {
        // NSException异常导致的Crash也会产生Signal错误，此处只记录一次
        if isExceptionStarted, !isCrashHandled {
            isCrashHandled = true
            captureError(ErrorManager.error(with: exception), crash: true)
        }
        
        previousExceptionHandler?(exception)
    }
    
    private static func signalHandler(_ signal: Int32, _ name: String, _ previousSignalHandler: (@convention(c) (Int32) -> Void)?) {
        if isSignalStarted, !isCrashHandled {
            isCrashHandled = true
            captureError(NSError(domain: name, code: Int(signal), userInfo: nil), crash: true)
        }
        
        previousSignalHandler?(signal)
    }
    
}
