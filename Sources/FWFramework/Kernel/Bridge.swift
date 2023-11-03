//
//  Bridge.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/20.
//

import UIKit

@_spi(FW) @objc extension NSObject {
    
    public static func __fw_bundleImage(_ name: String) -> UIImage? {
        return AppBundle.imageNamed(name)
    }
    
    public static func __fw_bundleString(_ key: String) -> String {
        return AppBundle.localizedString(key)
    }
    
    public func __fw_invokeGetter(_ name: String) -> Any? {
        return fw_invokeGetter(name)
    }
    
    @discardableResult
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

@_spi(FW) @objc extension NSDate {
    
    public static func __fw_formatServerDate(_ dateString: String) -> TimeInterval {
        return Date.fw_formatServerDate(dateString)
    }
    
}

@_spi(FW) @objc extension CALayer {
    
    public func __fw_removeDefaultAnimations() {
        fw_removeDefaultAnimations()
    }
    
}

@_spi(FW) @objc extension UIView {
    
    public static func __fw_progressViewWithPreview() -> UIView & ProgressViewPlugin {
        return fw_progressView(style: .imagePreview)
    }
    
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

@_spi(FW) @objc extension UIControl {
    
    @discardableResult
    public func __fw_addTouch(block: @escaping (Any) -> Void) -> String {
        fw_addTouch(block: block)
    }
    
}

@_spi(FW) @objc extension UIView {

    public func __fw_setImage(url: Any?, placeholderImage: UIImage?, avoidSetImage: Bool, setImageBlock: ((UIImage?) -> Void)?, completion: ((UIImage?, Error?) -> Void)?, progress: ((Double) -> Void)?) {
        fw_setImage(url: url, placeholderImage: placeholderImage, options: avoidSetImage ? [.avoidSetImage] : [], context: nil, setImageBlock: setImageBlock, completion: completion, progress: progress)
    }

    public func __fw_cancelImageRequest() {
        fw_cancelImageRequest()
    }
    
    public func __fw_loadImageCache(url: Any?) -> UIImage? {
        return fw_loadImageCache(url: url)
    }
    
    public var __fw_hidesImageIndicator: Bool {
        get { fw_hidesImageIndicator }
        set { fw_hidesImageIndicator = newValue }
    }
    
}

@_spi(FW) @objc extension UIImageView {
    
    public static func __fw_animatedImageView() -> UIImageView {
        return fw_animatedImageView()
    }
    
}

@_spi(FW) @objc extension UIActivityIndicatorView {
    
    public static func __fw_indicatorView(color: UIColor?) -> UIActivityIndicatorView {
        return fw_indicatorView(color: color)
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
        cancel: Any? = nil,
        cancelBlock: (() -> Void)? = nil
    ) {
        fw_showAlert(title: title, message: message, style: .default, cancel: cancel, cancelBlock: cancelBlock)
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
    
    public func __fw_showLoading(text: Any? = nil, cancelBlock: (() -> Void)? = nil) {
        fw_showLoading(text: text, cancelBlock: cancelBlock)
    }

    public func __fw_hideLoading(delayed: Bool = false) {
        fw_hideLoading(delayed: delayed)
    }
    
}
