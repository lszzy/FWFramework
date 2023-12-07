//
//  Bridge.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/20.
//

import UIKit

@_spi(FW) @objc extension NSObject {
    
    public static func __fw_bundleString(_ key: String) -> String {
        return AppBundle.localizedString(key)
    }
    
}

@_spi(FW) @objc extension UIWindow {
    
    public static var __fw_mainWindow: UIWindow? {
        get { fw_mainWindow }
        set { fw_mainWindow = newValue }
    }
    
}

@_spi(FW) @objc extension UIImage {
    
    public func __fw_croppedImage(frame: CGRect, angle: Int, circular: Bool) -> UIImage? {
        return fw_croppedImage(frame: frame, angle: angle, circular: circular)
    }
    
}

@_spi(FW) @objc extension UIViewController {
    
    public func __fw_showSheet(
        title: String?,
        message: String?,
        cancel: String?,
        actions: [String]?,
        currentIndex: Int = -1,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        fw_showSheet(title: title, message: message, cancel: cancel, actions: actions, currentIndex: currentIndex, actionBlock: actionBlock, cancelBlock: cancelBlock)
    }
    
}
