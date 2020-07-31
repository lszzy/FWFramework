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
@objc public protocol FWSkeletonAnimationProtocol {
    func skeletonAnimationStart(_ gradientLayer: CAGradientLayer)
    func skeletonAnimationStop(_ gradientLayer: CAGradientLayer)
}

/// 骨架屏呼吸灯动画
@objcMembers public class FWSkeletonAnimationSolid: NSObject, FWSkeletonAnimationProtocol {
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

/// 骨架屏闪光灯动画方向
@objc public enum FWSkeletonAnimationShimmerDirection: Int {
    case leftToRight
    case rightToLeft
    case topToBottom
    case bottomToTop
    case topLeftToBottomRight
    case bottomRightToTopLeft
}

/// 骨架屏闪光灯动画
@objcMembers public class FWSkeletonAnimationShimmer: NSObject, FWSkeletonAnimationProtocol {
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
    
    // MARK: -
    
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

/// 骨架屏通用样式
@objcMembers public class FWSkeletonAppearance: NSObject {
    /// 单例对象
    public static let appearance = FWSkeletonAppearance()
    
    /// 布局背景色，默认自动适配
    public var layoutColor: UIColor!
    /// 骨架颜色，默认自动适配
    public var skeletonColor: UIColor!
    
    /// 动画设置，默认闪光灯
    public var skeletonAnimation: FWSkeletonAnimationProtocol?
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

/// 骨架屏视图，无代码侵入，支持设置占位图片
@objcMembers public class FWSkeletonView: UIView {
    public var skeletonAnimation: FWSkeletonAnimationProtocol?
    
    public var animationColors: [Any]? {
        didSet {
            animationLayers.forEach { (gradientLayer) in
                gradientLayer.colors = animationColors
            }
        }
    }
    
    public var skeletonImage: UIImage? {
        didSet {
            layer.contents = skeletonImage?.cgImage
        }
    }
    
    public var animationLayers: [CAGradientLayer] {
        let gradientLayer = layer as! CAGradientLayer
        return [gradientLayer]
    }
    
    public override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = FWSkeletonAppearance.appearance.skeletonColor
        skeletonAnimation = FWSkeletonAppearance.appearance.skeletonAnimation
        animationColors = FWSkeletonAppearance.appearance.animationColors
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func startAnimating() {
        animationLayers.forEach { (gradientLayer) in
            skeletonAnimation?.skeletonAnimationStart(gradientLayer)
        }
    }
    
    public func stopAnimating() {
        animationLayers.forEach { (gradientLayer) in
            skeletonAnimation?.skeletonAnimationStop(gradientLayer)
        }
    }
}

// MARK: - FWSkeletonLayout

/// 骨架屏布局代理协议
@objc public protocol FWSkeletonLayoutDelegate {
    func skeletonViewLayout(_ layout: FWSkeletonLayout)
}

/// 骨架屏布局
@objcMembers public class FWSkeletonLayout: UIView {
    public weak var layoutDelegate: FWSkeletonLayoutDelegate?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = FWSkeletonAppearance.appearance.layoutColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var skeletonViews: [FWSkeletonView] = []
    
    public func startAnimating() {
        skeletonViews.forEach { (skeletonView) in
            skeletonView.startAnimating()
        }
    }
    
    public func stopAnimating() {
        skeletonViews.forEach { (skeletonView) in
            skeletonView.stopAnimating()
        }
        skeletonViews.removeAll()
    }
    
    public func addSkeletonView(_ skeletonView: FWSkeletonView) {
        skeletonViews.append(skeletonView)
        if skeletonView.superview == nil {
            addSubview(skeletonView)
        }
    }
    
    // MARK: -
    
    weak var referenceSuperview: UIView? {
        didSet {
            if let referenceBounds = referenceSuperview?.bounds {
                frame = referenceBounds
            }
        }
    }
    
    public var referenceParser: ((UIView) -> FWSkeletonView?)?
    
    public func addReferenceView(_ view: UIView) {
        addReferenceView(view, block: nil)
    }
    
    public func addReferenceView(_ view: UIView, block: ((FWSkeletonView) -> Void)?) {
        guard let superView = referenceSuperview else { return }
        guard view.isDescendant(of: superView) else { return }
        
        guard let skeletonView = parseReferenceView(view) else { return }
        skeletonView.frame = view.convert(view.bounds, to: superView)
        block?(skeletonView)
        addSkeletonView(skeletonView)
    }
    
    private func parseReferenceView(_ view: UIView) -> FWSkeletonView? {
        if let resultView = referenceParser?(view) {
            return resultView
        }
        
        let skeletonView = FWSkeletonView()
        skeletonView.layer.masksToBounds = view.layer.masksToBounds
        skeletonView.layer.cornerRadius = view.layer.cornerRadius
        return skeletonView
    }
}

/// 视图显示骨架屏扩展
@objc extension UIView {
    private func fwShowSkeleton(layoutDelegate: FWSkeletonLayoutDelegate? = nil, layoutBlock: ((FWSkeletonLayout) -> Void)? = nil) {
        fwHideSkeleton()
        
        setNeedsLayout()
        layoutIfNeeded()
        
        let layout = FWSkeletonLayout()
        layout.tag = 2051
        layout.referenceSuperview = self
        layout.layoutDelegate = layoutDelegate
        layoutDelegate?.skeletonViewLayout(layout)
        layoutBlock?(layout)
        
        addSubview(layout)
        layout.fwPinEdgesToSuperview()
        layout.setNeedsLayout()
        layout.layoutIfNeeded()
        layout.startAnimating()
    }
    
    public func fwShowSkeleton(layoutDelegate: FWSkeletonLayoutDelegate? = nil) {
        fwShowSkeleton(layoutDelegate: layoutDelegate, layoutBlock: nil)
    }
    
    public func fwShowSkeleton(layoutBlock: ((FWSkeletonLayout) -> Void)? = nil) {
        fwShowSkeleton(layoutDelegate: nil, layoutBlock: layoutBlock)
    }
    
    public func fwShowSkeleton() {
        fwShowSkeleton(layoutDelegate: self as? FWSkeletonLayoutDelegate)
    }
    
    public func fwHideSkeleton() {
        if let layout = viewWithTag(2051) as? FWSkeletonLayout {
            layout.stopAnimating()
            layout.removeFromSuperview()
        }
    }
}

/// 控制器显示骨架屏扩展
@objc extension UIViewController {
    public func fwShowSkeleton(layoutDelegate: FWSkeletonLayoutDelegate? = nil) {
        view.fwShowSkeleton(layoutDelegate: layoutDelegate)
    }
    
    public func fwShowSkeleton(layoutBlock: ((FWSkeletonLayout) -> Void)? = nil) {
        view.fwShowSkeleton(layoutBlock: layoutBlock)
    }
    
    public func fwShowSkeleton() {
        fwShowSkeleton(layoutDelegate: self as? FWSkeletonLayoutDelegate)
    }
    
    public func fwHideSkeleton() {
        view.fwHideSkeleton()
    }
}
