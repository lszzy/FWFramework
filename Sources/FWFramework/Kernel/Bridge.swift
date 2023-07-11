//
//  Bridge.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/20.
//

import UIKit

@_spi(FW) @objc extension NSObject {
    
    public static func __fw_logDebug(_ message: String) {
        #if DEBUG
        Logger.log(.debug, group: Logger.fw_moduleName, message: message)
        #endif
    }
    
    public static func __fw_bundleImage(_ name: String) -> UIImage? {
        return AppBundle.imageNamed(name)
    }
    
    public static func __fw_bundleString(_ key: String) -> String {
        return AppBundle.localizedString(key)
    }
    
    public func __fw_observeProperty(_ property: String, block: @escaping (Any, [NSKeyValueChangeKey: Any]) -> Void) -> NSObjectProtocol {
        return fw_observeProperty(property, block: block)
    }
    
    public func __fw_unobserveProperty(_ property: String, target: Any?, action: Selector?) {
        fw_unobserveProperty(property, target: target, action: action)
    }
    
    public static func __fw_classMethods(_ clazz: AnyClass) -> [String] {
        return fw_classMethods(clazz)
    }
    
    public func __fw_invokeGetter(_ name: String) -> Any? {
        return fw_invokeGetter(name)
    }
    
    public static func __fw_swizzleMethod(
        _ target: Any?,
        selector: Selector,
        identifier: String? = nil,
        block: @escaping (AnyClass, Selector, @escaping () -> IMP) -> Any
    ) -> Bool {
        return fw_swizzleMethod(target, selector: selector, identifier: identifier, block: block)
    }
    
    public func __fw_applyAppearance() {
        fw_applyAppearance()
    }
    
}

@_spi(FW) @objc extension CALayer {
    
    public func __fw_removeDefaultAnimations() {
        fw_removeDefaultAnimations()
    }
    
}

@_spi(FW) @objc extension UIView {
    
    public func __fw_statisticalTrackClick(indexPath: IndexPath? = nil, event: StatisticalEvent? = nil) -> Bool {
        return fw_statisticalTrackClick(indexPath: indexPath, event: event)
    }
    
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

@_spi(FW) @objc extension UICollectionViewFlowLayout {
    
    public func __fw_sectionConfigPrepareLayout() {
        fw_sectionConfigPrepareLayout()
    }

    public func __fw_sectionConfigLayoutAttributes(forElementsIn rect: CGRect) -> [UICollectionViewLayoutAttributes] {
        return fw_sectionConfigLayoutAttributes(forElementsIn: rect)
    }

}

@_spi(FW) @objc extension UIViewController {
    
    public func __fw_isInvisibleState() -> Bool {
        if self.fw_lifecycleState.rawValue < ViewControllerLifecycleState.didAppear.rawValue ||
            self.fw_lifecycleState.rawValue >= ViewControllerLifecycleState.didDisappear.rawValue {
            return true
        }
        return false
    }
    
    public func __fw_showAlert(
        title: Any?,
        message: Any?,
        style: AlertStyle = .default,
        cancel: Any? = nil,
        cancelBlock: (() -> Void)? = nil
    ) {
        fw_showAlert(title: title, message: message, style: style, cancel: cancel, cancelBlock: cancelBlock)
    }
    
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
    
    public func __fw_showEmptyView(text: Any? = nil, detail: Any? = nil, image: UIImage? = nil, action: Any? = nil, block: ((Any) -> Void)? = nil) {
        fw_showEmptyView(text: text, detail: detail, image: image, action: action, block: block)
    }
    
}
