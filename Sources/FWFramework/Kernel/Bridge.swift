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

@_spi(FW) @objc extension NSDate {
    
    public static func __fw_formatServerDate(_ dateString: String) -> TimeInterval {
        return Date.fw_formatServerDate(dateString)
    }
    
}

@_spi(FW) @objc extension UIView {
    
    @discardableResult
    public func __fw_statisticalTrackClick(indexPath: IndexPath? = nil, event: StatisticalEvent? = nil) -> Bool {
        return fw_statisticalTrackClick(indexPath: indexPath, event: event)
    }
    
    @discardableResult
    public func __fw_statisticalBindExposure(_ containerView: UIView? = nil) -> Bool {
        return fw_statisticalBindExposure(containerView)
    }
    
    public func __fw_statisticalCheckExposure() {
        fw_statisticalCheckExposure()
    }
    
}

@_spi(FW) @objc extension UIWindow {
    
    public static var __fw_mainWindow: UIWindow? {
        get { fw_mainWindow }
        set { fw_mainWindow = newValue }
    }
    
}

@_spi(FW) @objc extension UIImage {
    
    public func __fw_image(alpha: CGFloat) -> UIImage? {
        return fw_image(alpha: alpha)
    }
    
    public func __fw_image(scaleSize size: CGSize) -> UIImage? {
        return fw_image(scaleSize: size)
    }
    
    public func __fw_croppedImage(frame: CGRect, angle: Int, circular: Bool) -> UIImage? {
        return fw_croppedImage(frame: frame, angle: angle, circular: circular)
    }
    
    public static func __fw_image(data: Data?, scale: CGFloat = 1, options: [AnyHashable: Any]? = nil) -> UIImage? {
        var targetOptions: [ImageCoderOptions: Any]?
        if let options = options {
            targetOptions = [:]
            for (key, value) in options {
                if let option = key as? ImageCoderOptions {
                    targetOptions?[option] = value
                } else {
                    targetOptions?[.init("\(key)")] = value
                }
            }
        }
        return fw_image(data: data, scale: scale, options: targetOptions)
    }
    
}

@_spi(FW) @objc extension UIViewController {
    
    public func __fw_showSheet(
        title: Any?,
        message: Any?,
        cancel: Any?,
        actions: [Any]?,
        currentIndex: Int = -1,
        actionBlock: ((Int) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        fw_showSheet(title: title, message: message, cancel: cancel, actions: actions, currentIndex: currentIndex, actionBlock: actionBlock, cancelBlock: cancelBlock)
    }
    
}
