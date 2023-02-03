//
//  Bridge.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/20.
//

import UIKit

/// NSObject内部Swift桥接方法
@_spi(FW) extension NSObject {
    
    /// 记录内部分组调试日志
    @objc public static func __fw_logDebug(_ message: String) {
        #if DEBUG
        Logger.log(.debug, group: Logger.fw_moduleName, message: message)
        #endif
    }
    
    /// 读取内部Bundle图片
    @objc public static func __fw_bundleImage(_ name: String) -> UIImage? {
        return AppBundle.imageNamed(name)
    }
    
    /// 读取内部Bundle多语言
    @objc public static func __fw_bundleString(_ key: String) -> String {
        return AppBundle.localizedString(key)
    }
    
    /// 动态预加载WebView
    @objc public static func __fw_preloadWebView(_ webView: UIView) {
        if ViewControllerManager.shared.webViewReuseIdentifier != nil {
            webView.fw_preloadReusableView()
        }
    }
    
}

/// UIViewController内部Swift桥接方法
@_spi(FW) extension UIViewController {
    
    /// 内部判断是否处于可见状态
    @objc public func __fw_isInvisibleState() -> Bool {
        if self.fw_state.rawValue < ViewControllerState.didAppear.rawValue ||
            self.fw_state.rawValue >= ViewControllerState.didDisappear.rawValue {
            return true
        }
        return false
    }
    
}
