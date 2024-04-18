//
//  Exception.swift
//  FWFramework
//
//  Created by wuyong on 2023/8/14.
//

import Foundation

// MARK: - Notification+Exception
extension Notification.Name {
    
    /// 异常捕获通知，object为NSException对象，userInfo为附加信息(function|file|line|remark|symbols)
    public static let ExceptionCaptured = Notification.Name("FWExceptionCapturedNotification")
    /// 错误捕获通知，object为Error对象，userInfo为附加信息(function|file|line|remark|symbols)
    public static let ErrorCaptured = Notification.Name("FWErrorCapturedNotification")
    
}

// MARK: - ExceptionManager
/// 异常|错误捕获类
///
/// [JJException](https://github.com/jezzmemo/JJException)
/// [AvoidCrash](https://github.com/chenfanfang/AvoidCrash)
public class ExceptionManager: NSObject {
    
    /// 自定义需要捕获未定义方法异常的类，默认[NSNull, NSNumber, NSString, NSArray, NSDictionary]
    public static var captureClasses: [AnyClass] = [
        NSNull.self,
        NSNumber.self,
        NSString.self,
        NSArray.self,
        NSDictionary.self,
    ]
    
    private static var captureStarted = false
    
    /// 开启框架自带异常捕获功能，默认关闭
    public static func startCaptureExceptions() {
        guard !captureStarted else { return }
        captureStarted = true
        
        NSObject.fw_swizzleInstanceMethod(
            NSObject.self,
            selector: NSSelectorFromString("methodSignatureForSelector:"),
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
                
                if isCaptured, let signatureClass = NSClassFromString("NSMethodSignature") {
                    methodSignature = signatureClass.objcSignature(withObjCTypes: "v@:@")
                }
            }
            return methodSignature
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            NSObject.self,
            selector: NSSelectorFromString("forwardInvocation:"),
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
                invocation.objcTarget = nil
                invocation.objcInvoke()
            } else {
                store.original(selfObject, store.selector, invocation)
            }
        }}
    }
    
    /// 捕获自定义异常并发送通知，可设置备注
    public static func captureException(
        _ exception: NSException,
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
        Logger.debug(group: Logger.fw_moduleName, "\n========== EXCEPTION ==========\n  name: %@\nreason: %@\nmethod: %@ #%d %@\nremark: %@\n========== EXCEPTION ==========", exception.name.rawValue, exception.reason ?? "-", fileName, line, function, remark ?? "-")
        #endif
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .ExceptionCaptured, object: exception, userInfo: userInfo)
        }
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
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .ErrorCaptured, object: error, userInfo: userInfo)
        }
    }
    
}
