//
//  Error.swift
//  FWFramework
//
//  Created by wuyong on 2023/8/14.
//

import Foundation

// MARK: - Notification+Exception
extension Notification.Name {
    
    /// 错误捕获通知，object为Error对象，userInfo为附加信息(function|file|line|remark|symbols)
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
        NSNull.self,
        NSNumber.self,
        NSString.self,
        NSArray.self,
        NSDictionary.self,
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
    
    private static var isCaptureStarted = false
    
    /// 开启框架自带错误异常捕获功能，默认关闭
    public static func startCapture() {
        guard !isCaptureStarted else { return }
        isCaptureStarted = true
        
        NSObject.fw_swizzleInstanceMethod(
            NSObject.self,
            selector: ObjCClassBridge.methodSignatureSelector,
            methodSignature: (@convention(c) (NSObject, Selector, Selector) -> AnyObject?).self,
            swizzleSignature: (@convention(block) (NSObject, Selector) -> AnyObject?).self
        ) { store in { selfObject, selector in
            var methodSignature = store.original(selfObject, store.selector, selector)
            if methodSignature == nil {
                var isCaptured = false
                for captureClass in captureClasses {
                    if selfObject.isKind(of: captureClass) {
                        isCaptured = true
                        break
                    }
                }
                
                if isCaptured, let signatureClass = ObjCClassBridge.methodSignatureClass {
                    methodSignature = signatureClass.objcSignature(withObjCTypes: "v@:@")
                }
            }
            return methodSignature
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            NSObject.self,
            selector: ObjCClassBridge.forwardInvocationSelector,
            methodSignature: (@convention(c) (NSObject, Selector, ObjCInvocationBridge) -> Void).self,
            swizzleSignature: (@convention(block) (NSObject, ObjCInvocationBridge) -> Void).self
        ) { store in { selfObject, invocation in
            var isCaptured = false
            for captureClass in captureClasses {
                if selfObject.isKind(of: captureClass) {
                    isCaptured = true
                    break
                }
            }
            
            if isCaptured {
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
            } else {
                store.original(selfObject, store.selector, invocation)
            }
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            NSObject.self,
            selector: #selector(NSObject.setValue(_:forKey:)),
            methodSignature: (@convention(c) (NSObject, Selector, Any?, String) -> Void).self,
            swizzleSignature: (@convention(block) (NSObject, Any?, String) -> Void).self
        ) { store in { selfObject, value, key in
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
            do {
                try tryCatch { store.original(selfObject, store.selector, keyedValues) }
            } catch {
                captureError(error)
            }
        }}
    }
    
    /// 捕获自定义错误并在当前线程发送通知，可设置备注
    public static func captureError(
        _ error: Error,
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
            "symbols": Thread.callStackSymbols,
        ]
        
        #if DEBUG
        let nserror = error as NSError
        Logger.debug(group: Logger.fw_moduleName, "\n========== ERROR ==========\ndomain: %@\n  code: %d\nreason: %@\nmethod: %@ #%d %@\nremark: %@\n========== ERROR ==========", nserror.domain, nserror.code, nserror.localizedDescription, fileName, line, function, remark ?? "-")
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
    
}
