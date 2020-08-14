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

/// 骨架屏自带动画类型
@objc public enum FWSkeletonAnimationType: Int {
    /// 闪光灯动画
    case shimmer
    /// 呼吸灯动画
    case solid
    /// 伸缩动画
    case scale
}

/// 骨架屏自带动画方向
@objc public enum FWSkeletonAnimationDirection: Int {
    case right
    case left
    case down
    case up
}

/// 骨架屏自带动画
@objcMembers public class FWSkeletonAnimation: NSObject, FWSkeletonAnimationProtocol {
    public static let shimmer = FWSkeletonAnimation(type: .shimmer)
    public static let solid = FWSkeletonAnimation(type: .solid)
    public static let scale = FWSkeletonAnimation(type: .scale)
    
    public var fromValue: Any?
    public var toValue: Any?
    public var colors: [UIColor]?
    public var duration: TimeInterval = 1
    public var direction: FWSkeletonAnimationDirection = .right
    
    // MARK: -
    
    private var type: FWSkeletonAnimationType = .shimmer
    
    public override init() {
        super.init()
        setup()
    }
    
    public init(type: FWSkeletonAnimationType) {
        super.init()
        self.type = type
        setup()
    }
    
    private func setup() {
        switch type {
        case .solid:
            fromValue = 1.1
            toValue = 0.6
        case .scale:
            duration = 0.7
            fromValue = 0.6
            toValue = 1
        default:
            if #available(iOS 13.0, *) {
                let color = UIColor(dynamicProvider: { (traitCollection) -> UIColor in
                    if traitCollection.userInterfaceStyle == .dark {
                        return UIColor.fwColor(withHex: 0x282828)
                    } else {
                        return UIColor.fwColor(withHex: 0xDFDFDF)
                    }
                })
                let brightnessColor = UIColor(dynamicProvider: { (traitCollection) -> UIColor in
                    if traitCollection.userInterfaceStyle == .dark {
                        return UIColor.fwColor(withHex: 0x282828).fwBrightnessColor(0.5)
                    } else {
                        return UIColor.fwColor(withHex: 0xDFDFDF).fwBrightnessColor(0.92)
                    }
                })
                colors = [color, brightnessColor, color]
            } else {
                let color = UIColor.fwColor(withHex: 0xDFDFDF)
                let brightnessColor = color.fwBrightnessColor(0.92)
                colors = [color, brightnessColor, color]
            }
        }
    }
    
    // MARK: -
    
    public func skeletonAnimationStart(_ gradientLayer: CAGradientLayer) {
        switch type {
        case .solid:
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.autoreverses = true
            animation.repeatCount = .infinity
            animation.duration = duration
            animation.fromValue = fromValue
            animation.toValue = toValue
            animation.timingFunction = CAMediaTimingFunction(name: .easeIn)
            gradientLayer.add(animation, forKey: "skeletonAnimation")
        case .scale:
            let animation = CABasicAnimation()
            switch direction {
            case .right:
                animation.keyPath = "transform.scale.x"
                gradientLayer.anchorPoint = CGPoint(x: 0, y: 0.5)
                gradientLayer.position.x -= gradientLayer.bounds.size.width / 2.0
            case .left:
                animation.keyPath = "transform.scale.x"
                gradientLayer.anchorPoint = CGPoint(x: 1, y: 0.5)
                gradientLayer.position.x += gradientLayer.bounds.size.width / 2.0
            case .down:
                animation.keyPath = "transform.scale.y"
                gradientLayer.anchorPoint = CGPoint(x: 0.5, y: 0)
                gradientLayer.position.y -= gradientLayer.bounds.size.height / 2.0
            case .up:
                animation.keyPath = "transform.scale.y"
                gradientLayer.anchorPoint = CGPoint(x: 0.5, y: 1)
                gradientLayer.position.y += gradientLayer.bounds.size.height / 2.0
            }
            
            animation.autoreverses = true
            animation.repeatCount = .infinity
            animation.duration = duration
            animation.fromValue = fromValue
            animation.toValue = toValue
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            gradientLayer.add(animation, forKey: "skeletonAnimation")
        default:
            let startAnimation = CABasicAnimation(keyPath: "startPoint")
            let endAnimation = CABasicAnimation(keyPath: "endPoint")
            switch direction {
            case .right:
                startAnimation.fromValue = NSValue(cgPoint: CGPoint(x:-1, y:0.5))
                startAnimation.toValue = NSValue(cgPoint: CGPoint(x:1, y:0.5))
                endAnimation.fromValue = NSValue(cgPoint: CGPoint(x:0, y:0.5))
                endAnimation.toValue = NSValue(cgPoint: CGPoint(x:2, y:0.5))
            case .left:
                startAnimation.fromValue = NSValue(cgPoint: CGPoint(x:1, y:0.5))
                startAnimation.toValue = NSValue(cgPoint: CGPoint(x:-1, y:0.5))
                endAnimation.fromValue = NSValue(cgPoint: CGPoint(x:2, y:0.5))
                endAnimation.toValue = NSValue(cgPoint: CGPoint(x:0, y:0.5))
            case .down:
                startAnimation.fromValue = NSValue(cgPoint: CGPoint(x:0.5, y:-1))
                startAnimation.toValue = NSValue(cgPoint: CGPoint(x:0.5, y:1))
                endAnimation.fromValue = NSValue(cgPoint: CGPoint(x:0.5, y:0))
                endAnimation.toValue = NSValue(cgPoint: CGPoint(x:0.5, y:2))
            case .up:
                startAnimation.fromValue = NSValue(cgPoint: CGPoint(x:0.5, y:1))
                startAnimation.toValue = NSValue(cgPoint: CGPoint(x:0.5, y:-1))
                endAnimation.fromValue = NSValue(cgPoint: CGPoint(x:0.5, y:2))
                endAnimation.toValue = NSValue(cgPoint: CGPoint(x:0.5, y:0))
            }
            
            let animationGroup = CAAnimationGroup()
            animationGroup.repeatCount = .infinity
            animationGroup.animations = [startAnimation, endAnimation]
            animationGroup.duration = duration
            animationGroup.timingFunction = CAMediaTimingFunction(name: .easeIn)
            gradientLayer.colors = colors?.map(){ $0.cgColor }
            gradientLayer.add(animationGroup, forKey: "skeletonAnimation")
        }
    }
    
    public func skeletonAnimationStop(_ gradientLayer: CAGradientLayer) {
        gradientLayer.removeAnimation(forKey: "skeletonAnimation")
    }
}

// MARK: - FWSkeletonAppearance

/// 骨架屏通用样式
@objcMembers public class FWSkeletonAppearance: NSObject {
    /// 单例对象
    public static let appearance = FWSkeletonAppearance()
    
    /// 骨架动画，默认闪光灯
    public var animation: FWSkeletonAnimationProtocol? = FWSkeletonAnimation.shimmer
    
    /// 骨架背景色，默认自动适配
    public var backgroundColor: UIColor!
    /// 骨架颜色，默认自动适配
    public var skeletonColor: UIColor!
    
    /// 多行标签行高，默认15
    public var lineHeight: CGFloat = 15
    /// 多行标签间距，默认10
    public var lineSpacing: CGFloat = 10
    /// 多行标签最后一行百分比，默认0.7
    public var linePercent: CGFloat = 0.7
    /// 多行标签圆角，默认0
    public var lineCornerRadius: CGFloat = 0
    
    // MARK: -
    
    public override init() {
        super.init()
        
        if #available(iOS 13.0, *) {
            backgroundColor = UIColor.systemBackground
            skeletonColor = UIColor(dynamicProvider: { (traitCollection) -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    return UIColor.fwColor(withHex: 0x282828)
                } else {
                    return UIColor.fwColor(withHex: 0xEEEEEE)
                }
            })
        } else {
            backgroundColor = UIColor.white
            skeletonColor = UIColor.fwColor(withHex: 0xEEEEEE)
        }
    }
}

// MARK: - FWSkeletonView

/// 骨架屏视图，无代码侵入，支持设置占位图片
@objcMembers public class FWSkeletonView: UIView {
    /// 自定义动画，默认通用样式
    public var animation: FWSkeletonAnimationProtocol? = FWSkeletonAppearance.appearance.animation
    
    /// 动画层列表，子类可覆写
    public var animationLayers: [CAGradientLayer] {
        return [layer as! CAGradientLayer]
    }
    
    /// 骨架图片，默认空
    public var image: UIImage? {
        didSet {
            layer.contents = image?.cgImage
            layer.contentsGravity = .resizeAspectFill
        }
    }
    
    // MARK: -
    
    public override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = FWSkeletonAppearance.appearance.skeletonColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
//                let gradientColors = animationColors?.map(){ $0.cgColor }
//                animationLayers.forEach { (gradientLayer) in
//                    gradientLayer.colors = gradientColors
//                }
            }
        }
    }
    
    public func startAnimating() {
        animationLayers.forEach { (gradientLayer) in
            animation?.skeletonAnimationStart(gradientLayer)
        }
    }
    
    public func stopAnimating() {
        animationLayers.forEach { (gradientLayer) in
            animation?.skeletonAnimationStop(gradientLayer)
        }
    }
}

/// 骨架屏多行标签
@objcMembers public class FWSkeletonLabel: FWSkeletonView {
    /// 行数
    public var numberOfLines: Int = 0 {
        didSet { setNeedsDisplay() }
    }
    
    /// 行高
    public var lineHeight: CGFloat = FWSkeletonAppearance.appearance.lineHeight {
        didSet { setNeedsDisplay() }
    }
    
    /// 行圆角
    public var lineCornerRadius: CGFloat = FWSkeletonAppearance.appearance.lineCornerRadius {
        didSet { setNeedsDisplay() }
    }
    
    /// 行间距
    public var lineSpacing: CGFloat = FWSkeletonAppearance.appearance.lineSpacing {
        didSet { setNeedsDisplay() }
    }
    
    /// 行显示比率，单个时指定最后一行，数组时指定所有行
    public var linePercent: Any = FWSkeletonAppearance.appearance.linePercent {
        didSet { setNeedsDisplay() }
    }
    
    /// 行颜色
    public var lineColor: UIColor = FWSkeletonAppearance.appearance.skeletonColor {
        didSet { setNeedsDisplay() }
    }
    
    /// 内容边距
    public var contentInsets: UIEdgeInsets = .zero {
        didSet { setNeedsDisplay() }
    }
    
    private var lineLayers: [CAGradientLayer] = []
    
    // MARK: -
    
    public override var animationLayers: [CAGradientLayer] {
        return lineLayers
    }
    
    public override class var layerClass: AnyClass {
        return CALayer.self
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        lineLayers.forEach { (lineLayer) in
            lineLayer.removeFromSuperlayer()
        }
        
        let lineLayer = CAGradientLayer()
        lineLayer.backgroundColor = lineColor.cgColor
        lineLayer.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height)
        layer.addSublayer(lineLayer)
        lineLayers.append(lineLayer)
    }
}

// MARK: - FWSkeletonParser

/// 骨架屏解析器协议
@objc public protocol FWSkeletonParserProtocol {
    func skeletonParseView(_ view: UIView) -> FWSkeletonView?
}

/// 骨架屏解析器
@objcMembers public class FWSkeletonParser: NSObject, FWSkeletonParserProtocol {
    /// 单例对象
    public static let sharedInstance = FWSkeletonParser()
    
    /// 自定义解析器数组
    public var parsers: [FWSkeletonParserProtocol] = []
    
    /// 解析视图到骨架视图
    public func parse(_ view: UIView) -> FWSkeletonView {
        for parser in parsers {
            if let skeletonView = parser.skeletonParseView(view) {
                return skeletonView
            }
        }
        
        return skeletonParseView(view)!
    }
    
    // MARK: -
    
    public func skeletonParseView(_ view: UIView) -> FWSkeletonView? {
        if let label = view as? UILabel {
            let skeletonLabel = FWSkeletonLabel()
            skeletonLabel.lineHeight = label.font.lineHeight
            skeletonLabel.numberOfLines = label.numberOfLines
            return skeletonLabel
        }
        
        if let textView = view as? UITextView {
            let skeletonLabel = FWSkeletonLabel()
            if let textFont = textView.font {
                skeletonLabel.lineHeight = textFont.lineHeight
            }
            skeletonLabel.contentInsets = textView.textContainerInset
            return skeletonLabel
        }
        
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
    public var layoutView: UIView?
    
    public weak var layoutDelegate: FWSkeletonLayoutDelegate?
    
    private var skeletonViews: [FWSkeletonView] = []
    
    // MARK: -
    
    public init(layoutView: UIView) {
        super.init(frame: layoutView.bounds)
        
        self.layoutView = layoutView
        backgroundColor = FWSkeletonAppearance.appearance.backgroundColor
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = FWSkeletonAppearance.appearance.backgroundColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @discardableResult
    public func addSkeletonViews(_ views: [UIView]) -> [FWSkeletonView] {
        return addSkeletonViews(views, block: nil)
    }
    
    @discardableResult
    public func addSkeletonViews(_ views: [UIView], block: ((FWSkeletonView, Int) -> Void)?) -> [FWSkeletonView] {
        var resultViews: [FWSkeletonView] = []
        for (index, view) in views.enumerated() {
            resultViews.append(addSkeletonView(view, block: { (skeletonView) in
                block?(skeletonView, index)
            }))
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
        
        let skeletonView = FWSkeletonParser.sharedInstance.parse(view)
        if layoutView != nil && view.isDescendant(of: layoutView!) {
            skeletonView.frame = view.convert(view.bounds, to: layoutView!)
        }
        skeletonViews.append(skeletonView)
        if skeletonView.superview == nil {
            addSubview(skeletonView)
        }
        block?(skeletonView)
        return skeletonView
    }
    
    public override func startAnimating() {
        skeletonViews.forEach { (skeletonView) in
            skeletonView.startAnimating()
        }
    }
    
    public override func stopAnimating() {
        skeletonViews.forEach { (skeletonView) in
            skeletonView.stopAnimating()
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
        if let layout = subviews.first(where: { $0.tag == 2051 }) as? FWSkeletonLayout {
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
