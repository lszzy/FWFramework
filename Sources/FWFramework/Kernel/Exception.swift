//
//  Exception.swift
//  FWFramework
//
//  Created by wuyong on 2023/8/14.
//

import Foundation
#if FWMacroSPM
import FWObjC
#endif

// MARK: - Notification+Exception
extension Notification.Name {
    
    /// 异常捕获通知，object为NSException对象，userInfo为附加信息(function|file|line|remark|symbols)
    public static let ExceptionCaptured = NSNotification.Name("FWExceptionCapturedNotification")
    /// 错误捕获通知，object为Error对象，userInfo为附加信息(function|file|line|remark|symbols)
    public static let ErrorCaptured = NSNotification.Name("FWErrorCapturedNotification")
    
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
    
    /// 开启框架自带异常捕获功能，默认关闭
    public static func startCaptureExceptions() {
        ObjCBridge.captureExceptions(captureClasses) { exception, clazz, selector, file, line in
            let function = String(format: "%@[%@ %@]", class_isMetaClass(clazz) ? "+" : "-", NSStringFromClass(clazz), NSStringFromSelector(selector))
            captureException(exception, remark: nil, function: function, file: file, line: line)
        }
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
