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
    /// 开始动画
    func skeletonAnimationStart(_ layer: CALayer)
    /// 停止动画
    func skeletonAnimationStop(_ layer: CALayer)
}

/// 骨架屏动画基类，默认无动画
@objcMembers public class FWSkeletonAnimation: NSObject, FWSkeletonAnimationProtocol {
    public static let animationKey = "FWSkeletonAnimation"
    public lazy var animationLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        let color = UIColor.fwColor(withHex: 0xDFDFDF)
        layer.colors = [color.cgColor, self.adjust(by: 0.92, color: color).cgColor, color.cgColor]
        return layer
    }()
    
    func adjust(by percent: CGFloat, color: UIColor) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: s, brightness: b * percent, alpha: a)
    }
    
    public func skeletonAnimationStart(_ layer: CALayer) {
        layer.backgroundColor = UIColor.fwColor(withHex: 0xEEEEEE).cgColor
        layer.masksToBounds = true
        
        animationLayer.frame = layer.bounds
        layer.addSublayer(animationLayer)
    }
    
    public func skeletonAnimationStop(_ layer: CALayer) {
        animationLayer.removeAnimation(forKey: FWSkeletonAnimation.animationKey)
        animationLayer.removeFromSuperlayer()
    }
}

/// 闪光灯动画
@objcMembers public class FWSkeletonAnimationShimmer: FWSkeletonAnimation {
    public var duration: TimeInterval = 1
    
    public override func skeletonAnimationStart(_ layer: CALayer) {
        super.skeletonAnimationStart(layer)
        
        let startAnimation = CABasicAnimation(keyPath: "startPoint")
        startAnimation.fromValue = NSValue(cgPoint: CGPoint(x: -1, y: 0.5))
        startAnimation.toValue = NSValue(cgPoint: CGPoint(x: 1, y: 0.5))
        
        let endAnimation = CABasicAnimation(keyPath: "endPoint")
        endAnimation.fromValue = NSValue(cgPoint: CGPoint(x: 0, y: 0.5))
        endAnimation.toValue = NSValue(cgPoint: CGPoint(x: 2, y: 0.5))
        
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [startAnimation, endAnimation]
        animationGroup.duration = duration
        animationGroup.timingFunction = CAMediaTimingFunction(name: .easeIn)
        animationGroup.repeatCount = .infinity
        animationLayer.add(animationGroup, forKey: FWSkeletonAnimation.animationKey)
    }
}

/// 骨架屏CALayer动画扩展
@objc extension CALayer {
    private enum FWSkeletonAssociatedKeys {
        static var skeletonAnimation = "FWSkeletonAnimation"
    }
    
    public func fwStartSkeletonAnimation(_ animation: FWSkeletonAnimationProtocol) {
        objc_setAssociatedObject(self, &FWSkeletonAssociatedKeys.skeletonAnimation, animation, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        animation.skeletonAnimationStart(self)
    }
    
    public func fwStopSkeletonAnimation() {
        guard let animation = objc_getAssociatedObject(self, &FWSkeletonAssociatedKeys.skeletonAnimation) as? FWSkeletonAnimationProtocol else { return }
        animation.skeletonAnimationStop(self)
    }
}
