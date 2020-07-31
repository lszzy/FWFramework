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

// MARK: - FWSkeletonAppearance

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
    
    /// 自定义骨架屏解析器
    public var skeletonParser: ((UIView) -> FWSkeletonView?)?
    
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
    
    public func parseSkeletonView(_ view: UIView) -> FWSkeletonView {
        if let skeletonView = skeletonParser?(view) {
            return skeletonView
        }
        
        let skeletonView = FWSkeletonView.skeletonParseView(view)
        return skeletonView!
    }
}

// MARK: - FWSkeletonView

/// 骨架屏视图协议
@objc public protocol FWSkeletonViewProtocol {
    func skeletonStartAnimating()
    func skeletonStopAnimating()
    
    @objc optional static func skeletonParseView(_ view: UIView) -> FWSkeletonView?
}

/// 骨架屏视图，无代码侵入，支持设置占位图片
@objcMembers public class FWSkeletonView: UIView, FWSkeletonViewProtocol {
    /// 自定义动画，默认通用样式
    public var skeletonAnimation: FWSkeletonAnimationProtocol?
    
    /// 动画颜色，默认通用样式
    public var animationColors: [Any]?
    
    /// 骨架图片，默认空
    public var skeletonImage: UIImage? {
        didSet {
            layer.contents = skeletonImage?.cgImage
        }
    }
    
    /// 动画层列表，子类可覆写
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
        // 构造函数中设置属性不会触发didSet等方法
        animationColors = FWSkeletonAppearance.appearance.animationColors
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: -
    
    public func skeletonStartAnimating() {
        animationLayers.forEach { (gradientLayer) in
            gradientLayer.colors = animationColors
            skeletonAnimation?.skeletonAnimationStart(gradientLayer)
        }
    }
    
    public func skeletonStopAnimating() {
        animationLayers.forEach { (gradientLayer) in
            skeletonAnimation?.skeletonAnimationStop(gradientLayer)
        }
    }
    
    public static func skeletonParseView(_ view: UIView) -> FWSkeletonView? {
        let skeletonView = FWSkeletonView()
        skeletonView.layer.masksToBounds = view.layer.masksToBounds
        skeletonView.layer.cornerRadius = view.layer.cornerRadius
        return skeletonView
    }
}

// MARK: - FWSkeletonLayout

/// 骨架屏布局代理协议
@objc public protocol FWSkeletonLayoutDelegate {
    func skeletonViewLayout(_ layout: FWSkeletonLayout)
}

/// 骨架屏布局
@objcMembers public class FWSkeletonLayout: FWSkeletonView {
    public let layoutView: UIView
    
    public weak var layoutDelegate: FWSkeletonLayoutDelegate?
    
    private var skeletonViews: [FWSkeletonView] = []
    
    public init(layoutView: UIView) {
        self.layoutView = layoutView
        super.init(frame: layoutView.bounds)
        backgroundColor = FWSkeletonAppearance.appearance.layoutColor
    }
    
    public override init(frame: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @discardableResult
    public func addSkeletonViews(_ views: [UIView]) -> [FWSkeletonView] {
        return addSkeletonViews(views, block: nil)
    }
    
    @discardableResult
    public func addSkeletonViews(_ views: [UIView], block: ((FWSkeletonView) -> Void)?) -> [FWSkeletonView] {
        var resultViews: [FWSkeletonView] = []
        views.forEach { (view) in
            resultViews.append(addSkeletonView(view, block: block))
        }
        return resultViews
    }
    
    @discardableResult
    public func addSkeletonView(_ view: UIView) -> FWSkeletonView {
        return addSkeletonView(view, block: nil)
    }
    
    @discardableResult
    public func addSkeletonView(_ view: UIView, block: ((FWSkeletonView) -> Void)?) -> FWSkeletonView {
        if let resultView = view as? FWSkeletonView {
            skeletonViews.append(resultView)
            if resultView.superview == nil {
                addSubview(resultView)
            }
            block?(resultView)
            return resultView
        }
        
        let skeletonView = FWSkeletonAppearance.appearance.parseSkeletonView(view)
        if view.isDescendant(of: layoutView) {
            skeletonView.frame = view.convert(view.bounds, to: layoutView)
        }
        skeletonViews.append(skeletonView)
        if skeletonView.superview == nil {
            addSubview(skeletonView)
        }
        block?(skeletonView)
        return skeletonView
    }
    
    public override func skeletonStartAnimating() {
        skeletonViews.forEach { (skeletonView) in
            skeletonView.skeletonStartAnimating()
        }
    }
    
    public override func skeletonStopAnimating() {
        skeletonViews.forEach { (skeletonView) in
            skeletonView.skeletonStopAnimating()
        }
        skeletonViews.removeAll()
    }
}

// MARK: - UIKit+FWSkeletonView

/// 视图显示骨架屏扩展
@objc extension UIView {
    private func fwShowSkeleton(layoutDelegate: FWSkeletonLayoutDelegate? = nil, layoutBlock: ((FWSkeletonLayout) -> Void)? = nil) {
        fwHideSkeleton()
        setNeedsLayout()
        layoutIfNeeded()
        
        let layout = FWSkeletonLayout(layoutView: self)
        layout.tag = 2051
        layout.layoutDelegate = layoutDelegate
        addSubview(layout)
        layout.fwPinEdgesToSuperview()
        
        if layoutDelegate != nil {
            layoutDelegate?.skeletonViewLayout(layout)
        } else if layoutBlock != nil {
            layoutBlock?(layout)
        } else {
            layout.addSkeletonViews(subviews.filter({ $0 != layout }))
        }
        
        layout.setNeedsLayout()
        layout.layoutIfNeeded()
        layout.skeletonStartAnimating()
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
        if let layout = subviews.first(where: { $0.tag == 2051 }) as? FWSkeletonLayout {
            layout.skeletonStopAnimating()
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
