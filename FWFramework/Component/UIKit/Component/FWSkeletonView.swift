//
//  FWSkeletonView.swift
//  FWFramework
//
//  Created by wuyong on 2020/7/29.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import UIKit

// MARK: - FWSkeletonAnimation

/// 骨架屏动画协议
@objc public protocol FWSkeletonAnimation {
    func skeletonAnimationStart(_ gradientLayer: CAGradientLayer)
    func skeletonAnimationStop(_ gradientLayer: CAGradientLayer)
}

/// 骨架屏空动画
@objcMembers public class FWSkeletonAnimationNone: NSObject, FWSkeletonAnimation {
    public static let sharedInstance = FWSkeletonAnimationNone()
    
    public func skeletonAnimationStart(_ gradientLayer: CAGradientLayer) { }

    public func skeletonAnimationStop(_ gradientLayer: CAGradientLayer) { }
}

/// 呼吸灯动画
@objcMembers public class FWSkeletonAnimationSolid: NSObject, FWSkeletonAnimation {
    public static let sharedInstance = FWSkeletonAnimationSolid()
    public var duration: TimeInterval = 1
    
    public func skeletonAnimationStart(_ gradientLayer: CAGradientLayer) {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.1
        animation.toValue = 0.6
        animation.autoreverses = true
        animation.duration = duration
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        gradientLayer.add(animation, forKey: "FWSkeletonAnimationSolid")
    }

    public func skeletonAnimationStop(_ gradientLayer: CAGradientLayer) {
        gradientLayer.removeAnimation(forKey: "FWSkeletonAnimationSolid")
    }
}

/// 闪光灯方向
@objc public enum FWSkeletonAnimationShimmerDirection: Int {
    case leftToRight
    case rightToLeft
    case topToBottom
    case bottomToTop
    case topLeftToBottomRight
    case bottomRightToTopLeft
}

/// 闪光灯动画
@objcMembers public class FWSkeletonAnimationShimmer: NSObject, FWSkeletonAnimation {
    public static let sharedInstance = FWSkeletonAnimationShimmer()
    public var duration: TimeInterval = 1
    public var direction: FWSkeletonAnimationShimmerDirection = .leftToRight
    
    var startPoint: (from: CGPoint, to: CGPoint) {
        switch direction {
        case .leftToRight:
            return (from: CGPoint(x:-1, y:0.5), to: CGPoint(x:1, y:0.5))
        case .rightToLeft:
            return (from: CGPoint(x:1, y:0.5), to: CGPoint(x:-1, y:0.5))
        case .topToBottom:
            return (from: CGPoint(x:0.5, y:-1), to: CGPoint(x:0.5, y:1))
        case .bottomToTop:
            return (from: CGPoint(x:0.5, y:1), to: CGPoint(x:0.5, y:-1))
        case .topLeftToBottomRight:
            return (from: CGPoint(x:-1, y:-1), to: CGPoint(x:1, y:1))
        case .bottomRightToTopLeft:
            return (from: CGPoint(x:1, y:1), to: CGPoint(x:-1, y:-1))
        }
    }
    
    var endPoint: (from: CGPoint, to: CGPoint) {
        switch direction {
        case .leftToRight:
            return (from: CGPoint(x:0, y:0.5), to: CGPoint(x:2, y:0.5))
        case .rightToLeft:
            return ( from: CGPoint(x:2, y:0.5), to: CGPoint(x:0, y:0.5))
        case .topToBottom:
            return ( from: CGPoint(x:0.5, y:0), to: CGPoint(x:0.5, y:2))
        case .bottomToTop:
            return ( from: CGPoint(x:0.5, y:2), to: CGPoint(x:0.5, y:0))
        case .topLeftToBottomRight:
            return ( from: CGPoint(x:0, y:0), to: CGPoint(x:2, y:2))
        case .bottomRightToTopLeft:
            return ( from: CGPoint(x:2, y:2), to: CGPoint(x:0, y:0))
        }
    }
    
    public func skeletonAnimationStart(_ gradientLayer: CAGradientLayer) {
        let startAnimation = CABasicAnimation(keyPath: "startPoint")
        startAnimation.fromValue = NSValue(cgPoint: startPoint.from)
        startAnimation.toValue = NSValue(cgPoint: startPoint.to)
        
        let endAnimation = CABasicAnimation(keyPath: "endPoint")
        endAnimation.fromValue = NSValue(cgPoint: endPoint.from)
        endAnimation.toValue = NSValue(cgPoint: endPoint.to)
        
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [startAnimation, endAnimation]
        animationGroup.duration = duration
        animationGroup.timingFunction = CAMediaTimingFunction(name: .easeIn)
        animationGroup.repeatCount = .infinity
        gradientLayer.add(animationGroup, forKey: "FWSkeletonAnimationShimmer")
    }
    
    public func skeletonAnimationStop(_ gradientLayer: CAGradientLayer) {
        gradientLayer.removeAnimation(forKey: "FWSkeletonAnimationShimmer")
    }
}

// MARK: - FWSkeletonConfig

/// 骨架屏配置
@objcMembers public class FWSkeletonConfig: NSObject {
    public class var sharedInstance: FWSkeletonConfig {
        let instance = FWSkeletonConfig()
        instance.skeletonAnimation = FWSkeletonAnimationSolid.sharedInstance
        if #available(iOS 13.0, *) {
            instance.containerColor = UIColor.systemBackground
            instance.skeletonColor = UIColor(dynamicProvider: { (trainCollection) -> UIColor in
                if trainCollection.userInterfaceStyle == .dark {
                    return UIColor.fwColor(withHex: 0x282828)
                } else {
                    return UIColor.fwColor(withHex: 0xEEEEEE)
                }
            })
            let gradientColor = UIColor { (traitCollection) -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    return UIColor.fwColor(withHex: 0x282828)
                } else {
                    return UIColor.fwColor(withHex: 0xDFDFDF)
                }
            }
            let brightnessColor = UIColor { (traitCollection) -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    return UIColor.fwColor(withHex: 0x282828).fwBrightnessColor(0.5)
                } else {
                    return UIColor.fwColor(withHex: 0xDFDFDF).fwBrightnessColor(0.92)
                }
            }
            instance.gradientColors = [gradientColor, brightnessColor, gradientColor]
        } else {
            instance.containerColor = UIColor.white
            instance.skeletonColor = UIColor.fwColor(withHex: 0xEEEEEE)
            let gradientColor = UIColor.fwColor(withHex: 0xDFDFDF)
            instance.gradientColors = [gradientColor, gradientColor.fwBrightnessColor(0.92), gradientColor]
        }
        return instance
    }
    
    /// 动画设置
    public var skeletonAnimation: FWSkeletonAnimation?
    
    /// 背景色
    public var containerColor: UIColor?
    
    /// 骨架色
    public var skeletonColor: UIColor?
    
    /// 渐变色
    public var gradientColors: [UIColor]?
}

// MARK: - FWSkeletonView

/// 骨架屏视图代理协议
@objc public protocol FWSkeletonViewDelegate {
    func skeletonViewLayout(_ container: FWSkeletonView)
}

/// 骨架屏视图
@objcMembers public class FWSkeletonView: UIView {
    public override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    public var gradientLayers: [CAGradientLayer] {
        var gradientLayers: [CAGradientLayer] = []
        let gradientColors: [UIColor]? = skeletonConfig?.gradientColors ?? FWSkeletonConfig.sharedInstance.gradientColors
        var colors: [Any]? = []
        gradientColors?.forEach({ (color) in
            colors?.append(color.cgColor)
        })
        
        subviews.forEach { (subview) in
            if subview is FWSkeletonView {
                let gradientLayer = subview.layer as! CAGradientLayer
                gradientLayer.colors = colors
                gradientLayers.append(gradientLayer)
            }
        }
        return gradientLayers
    }
    
    public var skeletonConfig: FWSkeletonConfig? = nil
    
    weak var referenceView: UIView?
    
    public func copySubview(_ view: UIView?) {
        guard let childView = view else { return }
        guard let superView = referenceView else { return }
        guard childView.superview != nil else { return }
        
        let frame = childView.convert(childView.bounds, to: superView)
        let skeletonView = makeSkeletonView(childView, frame: frame)
        addSubview(skeletonView)
    }
    
    private func makeSkeletonView(_ view: UIView, frame: CGRect) -> FWSkeletonView {
        let skeletonView = FWSkeletonView(frame: frame)
        skeletonView.backgroundColor = skeletonConfig?.skeletonColor ?? FWSkeletonConfig.sharedInstance.skeletonColor
        skeletonView.layer.masksToBounds = view.layer.masksToBounds
        skeletonView.layer.cornerRadius = view.layer.cornerRadius
        return skeletonView
    }
    
    public func startAnimating() {
        guard let skeletonAnimation = (skeletonConfig?.skeletonAnimation ?? FWSkeletonConfig.sharedInstance.skeletonAnimation) else { return }
        
        gradientLayers.forEach { (gradientLayer) in
            skeletonAnimation.skeletonAnimationStart(gradientLayer)
        }
    }
    
    public func stopAnimating() {
        guard let skeletonAnimation = (skeletonConfig?.skeletonAnimation ?? FWSkeletonConfig.sharedInstance.skeletonAnimation) else { return }
        
        gradientLayers.forEach { (gradientLayer) in
            skeletonAnimation.skeletonAnimationStop(gradientLayer)
        }
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
    }
}

@objc extension UIView {
    private func fwShowSkeleton(delegate: FWSkeletonViewDelegate? = nil, block: ((_ container: FWSkeletonView) -> Void)? = nil) {
        fwHideSkeleton()
        
        setNeedsLayout()
        layoutIfNeeded()
        
        let container = FWSkeletonView()
        container.referenceView = self
        container.tag = 2051
        container.backgroundColor = FWSkeletonConfig.sharedInstance.containerColor
        addSubview(container)
        container.fwLayoutChain.edges()
        
        delegate?.skeletonViewLayout(container)
        block?(container)
        container.startAnimating()
    }
    
    public func fwShowSkeleton(delegate: FWSkeletonViewDelegate? = nil) {
        fwShowSkeleton(delegate: delegate, block: nil)
    }
    
    public func fwShowSkeleton(block: ((_ container: FWSkeletonView) -> Void)? = nil) {
        fwShowSkeleton(delegate: nil, block: block)
    }
    
    public func fwHideSkeleton() {
        guard let container = viewWithTag(2051) as? FWSkeletonView else { return }
        container.stopAnimating()
        container.removeFromSuperview()
    }
}

@objc extension UIViewController {
    public func fwShowSkeleton(delegate: FWSkeletonViewDelegate? = nil) {
        view.fwShowSkeleton(delegate: delegate)
    }
    
    public func fwShowSkeleton(block: ((_ container: FWSkeletonView) -> Void)? = nil) {
        view.fwShowSkeleton(block: block)
    }
    
    public func fwHideSkeleton() {
        view.fwHideSkeleton()
    }
}
