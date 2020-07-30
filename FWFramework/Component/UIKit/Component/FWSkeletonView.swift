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

/// 呼吸灯动画
@objcMembers public class FWSkeletonAnimationSolid: NSObject, FWSkeletonAnimation {
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

// MARK: - FWSkeletonView

/// 骨架屏样式设置
@objcMembers public class FWSkeletonAppearance: NSObject {
    /// 单例对象
    public static let appearance = FWSkeletonAppearance()
    
    /// 布局背景色，默认自动适配
    public var layoutColor: UIColor!
    /// 骨架颜色，默认自动适配
    public var skeletonColor: UIColor!
    
    /// 动画设置，默认闪光灯
    public var skeletonAnimation: FWSkeletonAnimation?
    /// 动画颜色，默认自动适配
    public var animationColors: [Any]?
    
    public override init() {
        super.init()
        
        skeletonAnimation = FWSkeletonAnimationShimmer()
        if #available(iOS 13.0, *) {
            layoutColor = UIColor.systemBackground
            skeletonColor = UIColor(dynamicProvider: { (trainCollection) -> UIColor in
                if trainCollection.userInterfaceStyle == .dark {
                    return UIColor.fwColor(withHex: 0x282828)
                } else {
                    return UIColor.fwColor(withHex: 0xEEEEEE)
                }
            })
            let animationColor = UIColor { (traitCollection) -> UIColor in
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
            animationColors = [animationColor.cgColor, brightnessColor.cgColor, animationColor.cgColor]
        } else {
            layoutColor = UIColor.white
            skeletonColor = UIColor.fwColor(withHex: 0xEEEEEE)
            let animationColor = UIColor.fwColor(withHex: 0xDFDFDF)
            animationColors = [animationColor.cgColor, animationColor.fwBrightnessColor(0.92).cgColor, animationColor.cgColor]
        }
    }
}

/// 骨架屏视图代理协议
@objc public protocol FWSkeletonViewDelegate {
    /// 骨架屏布局方法
    @objc optional func skeletonViewLayout(_ layoutView: FWSkeletonView)
    
    /// 骨架屏生成方法
    @objc optional func skeletonViewGenerator() -> FWSkeletonView
}

/// 骨架屏视图
@objcMembers public class FWSkeletonView: UIView {
    public var skeletonAnimation: FWSkeletonAnimation?
    
    weak var referenceView: UIView?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = FWSkeletonAppearance.appearance.skeletonColor
        skeletonAnimation = FWSkeletonAppearance.appearance.skeletonAnimation
        gradientLayer.colors = FWSkeletonAppearance.appearance.animationColors
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    public var gradientLayer: CAGradientLayer {
        return layer as! CAGradientLayer
    }
    
    public func copySubview(_ view: UIView?) {
        copySubview(view, block: nil)
    }
    
    public func copySubview(_ view: UIView?, block: ((_ skeletonView: FWSkeletonView) -> Void)?) {
        guard let childView = view else { return }
        guard let superView = referenceView else { return }
        guard childView.superview != nil else { return }
        
        let skeletonView = childView.skeletonViewGenerator()
        skeletonView.frame = childView.convert(childView.bounds, to: superView)
        addSubview(skeletonView)
        block?(skeletonView)
    }
    
    private func recursiveSearchSkeleton(block: (FWSkeletonView) -> Void) {
        subviews.forEach { (subview) in
            if subview is FWSkeletonView {
                block(subview as! FWSkeletonView)
            }
        }
    }
    
    public func startAnimating() {
        guard let animation = skeletonAnimation else { return }
        
        recursiveSearchSkeleton { (skeletonView) in
            animation.skeletonAnimationStart(skeletonView.gradientLayer)
        }
    }
    
    public func stopAnimating() {
        guard let animation = skeletonAnimation else { return }
        
        recursiveSearchSkeleton { (skeletonView) in
            animation.skeletonAnimationStop(skeletonView.gradientLayer)
        }
    }
    
    // image
    public var image: UIImage? = nil {
        didSet {
            layer.contents = image?.cgImage
        }
    }
}

@objc extension UIView: FWSkeletonViewDelegate {
    public func skeletonViewGenerator() -> FWSkeletonView {
        let skeletonView = FWSkeletonView()
        skeletonView.layer.masksToBounds = layer.masksToBounds
        skeletonView.layer.cornerRadius = layer.cornerRadius
        return skeletonView
    }
}

@objc extension UIView {
    private func fwShowSkeleton(delegate: FWSkeletonViewDelegate? = nil, block: ((_ layoutView: FWSkeletonView) -> Void)? = nil) {
        fwHideSkeleton()
        
        setNeedsLayout()
        layoutIfNeeded()
        
        let layoutView = FWSkeletonView()
        layoutView.referenceView = self
        layoutView.tag = 2051
        layoutView.backgroundColor = FWSkeletonAppearance.appearance.layoutColor
        layoutView.gradientLayer.colors = nil
        addSubview(layoutView)
        layoutView.fwLayoutChain.edges()
        
        delegate?.skeletonViewLayout?(layoutView)
        block?(layoutView)
        
        layoutView.setNeedsLayout()
        layoutView.layoutIfNeeded()
        layoutView.startAnimating()
    }
    
    public func fwShowSkeleton(delegate: FWSkeletonViewDelegate? = nil) {
        fwShowSkeleton(delegate: delegate, block: nil)
    }
    
    public func fwShowSkeleton(block: ((_ layoutView: FWSkeletonView) -> Void)? = nil) {
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
    
    public func fwShowSkeleton(block: ((_ layoutView: FWSkeletonView) -> Void)? = nil) {
        view.fwShowSkeleton(block: block)
    }
    
    public func fwHideSkeleton() {
        view.fwHideSkeleton()
    }
}
