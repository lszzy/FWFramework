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
/// 错误异常捕获类，子模块FWMacroBridge引入后无需设置tryCatchHandler
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
    
    /// 自定义tryCatch句柄，FWMacroBridge子模块引入后无需设置，详见FWMacroBridge
    public static var tryCatchHandler: ((_ block: () -> Void, _ exceptionHandler: (NSException) -> Void) -> Void)?
    
    private static var isCaptureStarted = false
    private static var isCaptureException: Bool {
        if tryCatchHandler != nil {
            return true
        }
        if let bridgeClass = ObjCClassBridge.macroBridgeClass,
           bridgeClass.responds(to: ObjCClassBridge.tryCatchSelector) {
            return true
        }
        return false
    }
    
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
                if isCaptureException {
                    do {
                        try tryCatch { store.original(selfObject, store.selector, invocation) }
                    } catch {
                        captureError(error)
                    }
                } else {
                    invocation.objcTarget = nil
                    invocation.objcInvoke()
                }
            } else {
                store.original(selfObject, store.selector, invocation)
            }
        }}
    }
    
    /// 捕获自定义错误并发送通知，可设置备注
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
        
        if let bridgeClass = ObjCClassBridge.macroBridgeClass,
           bridgeClass.responds(to: ObjCClassBridge.tryCatchSelector) {
            bridgeClass.objcTryCatch(block, exceptionHandler: exceptionHandler)
            return
        }
        
        block()
    }
    
}
