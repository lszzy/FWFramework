//
//  IndicatorPluginView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - IndicatorView
/// 自定义指示器视图
///
/// [DGActivityIndicatorView](https://github.com/gontovnik/DGActivityIndicatorView)
open class IndicatorView: UIView, IndicatorViewPlugin, ProgressViewPlugin {
    // MARK: - Accessor
    /// 当前动画类型
    open var type: IndicatorViewAnimationType = .lineSpin {
        didSet {
            if type != oldValue {
                setupAnimation()
            }
        }
    }

    /// 指示器颜色，默认白色
    open var indicatorColor: UIColor? = .white {
        didSet {
            if indicatorColor != oldValue {
                setupAnimation()
            }
        }
    }

    /// 设置或获取指示器大小，默认{37,37}
    open var indicatorSize: CGSize {
        get { bounds.size }
        set { frame = CGRect(origin: frame.origin, size: newValue) }
    }

    /// 指示器进度，大于0小于1时开始动画，其它值停止动画。同setProgress(_:animated:)
    open var progress: CGFloat {
        get { _progress }
        set { setProgress(newValue, animated: false) }
    }

    private var _progress: CGFloat = 0

    /// 停止动画时是否自动隐藏，默认YES
    open var hidesWhenStopped: Bool = true

    /// 是否正在动画
    open private(set) var isAnimating: Bool = false

    private lazy var animationLayer: CALayer = {
        let result = CALayer()
        return result
    }()

    // MARK: - Lifecycle
    /// 指定动画类型初始化
    public init(type: IndicatorViewAnimationType) {
        super.init(frame: CGRect(x: 0, y: 0, width: 37, height: 37))

        self.type = type
        setupLayer()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame.size.equalTo(.zero) ? CGRect(origin: frame.origin, size: CGSize(width: 37, height: 37)) : frame)

        setupLayer()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        setupLayer()
    }

    private func setupLayer() {
        isUserInteractionEnabled = false
        isHidden = true

        layer.addSublayer(animationLayer)
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
    }

    private func setupAnimation() {
        animationLayer.sublayers = nil

        let animation = animation()
        animation.setupAnimation(animationLayer, size: bounds.size, color: indicatorColor ?? .white)
        animationLayer.speed = 0.0
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        animationLayer.frame = bounds
        let isAnimating = isAnimating
        if isAnimating {
            stopAnimating()
        }
        setupAnimation()
        if isAnimating {
            startAnimating()
        }
    }

    override open var frame: CGRect {
        didSet { invalidateIntrinsicContentSize() }
    }

    override open var bounds: CGRect {
        didSet { invalidateIntrinsicContentSize() }
    }

    override open var intrinsicContentSize: CGSize {
        bounds.size
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        bounds.size
    }

    // MARK: - Public
    /// 开始动画
    open func startAnimating() {
        if isAnimating { return }
        if animationLayer.sublayers == nil {
            setupAnimation()
        }
        isHidden = false
        animationLayer.speed = 1.0
        isAnimating = true
    }

    /// 停止动画
    open func stopAnimating() {
        animationLayer.speed = 0.0
        isAnimating = false
        if hidesWhenStopped {
            isHidden = true
        }
    }

    /// 创建动画对象，子类可重写
    open func animation() -> IndicatorViewAnimationProtocol {
        switch type {
        case .linePulse:
            return IndicatorViewAnimationLinePulse()
        case .ballSpin:
            return IndicatorViewAnimationBallSpin()
        case .circleSpin:
            return IndicatorViewAnimationCircleSpin()
        case .ballPulse:
            return IndicatorViewAnimationBallPulse()
        case .ballTriangle:
            return IndicatorViewAnimationBallTriangle()
        case .triplePulse:
            return IndicatorViewAnimationTriplePulse()
        default:
            return IndicatorViewAnimationLineSpin()
        }
    }

    /// 设置指示器进度，大于0小于1时开始动画，其它值停止动画。同progress
    open func setProgress(_ progress: CGFloat, animated: Bool) {
        _progress = progress
        if progress > 0 && progress < 1 {
            if !isAnimating {
                startAnimating()
            }
        } else {
            if isAnimating {
                stopAnimating()
            }
        }
    }
}

// MARK: - IndicatorViewAnimation
/// 自定义指示器视图动画协议
@MainActor public protocol IndicatorViewAnimationProtocol: AnyObject {
    /// 初始化layer动画效果
    func setupAnimation(_ layer: CALayer, size: CGSize, color: UIColor)
}

/// 自定义指示器视图动画类型枚举，可扩展
public struct IndicatorViewAnimationType: RawRepresentable, Equatable, Hashable, Sendable {
    public typealias RawValue = Int

    /// 八线条渐变旋转，类似系统，默认
    public static let lineSpin: IndicatorViewAnimationType = .init(0)
    /// 五线条跳动，类似音符
    public static let linePulse: IndicatorViewAnimationType = .init(1)
    /// 八圆球渐变旋转
    public static let ballSpin: IndicatorViewAnimationType = .init(2)
    /// 三圆球水平跳动
    public static let ballPulse: IndicatorViewAnimationType = .init(3)
    /// 三圆圈三角形旋转
    public static let ballTriangle: IndicatorViewAnimationType = .init(4)
    /// 单圆圈渐变旋转
    public static let circleSpin: IndicatorViewAnimationType = .init(5)
    /// 圆形向外扩散，类似水波纹
    public static let triplePulse: IndicatorViewAnimationType = .init(6)

    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int) {
        self.rawValue = rawValue
    }
}

class IndicatorViewAnimationLineSpin: NSObject, IndicatorViewAnimationProtocol {
    func setupAnimation(_ layer: CALayer, size: CGSize, color: UIColor) {
        let lineSpacing: CGFloat = 2
        let lineSize = CGSize(width: (size.width - lineSpacing * 4) / 5, height: (size.height - lineSpacing * 2) / 3)
        let x = (layer.bounds.size.width - size.width) / 2
        let y = (layer.bounds.size.height - size.height) / 2
        let duration: CFTimeInterval = 1.2
        let beginTime = CACurrentMediaTime()
        let beginTimes: [CFTimeInterval] = [0.12, 0.24, 0.36, 0.48, 0.6, 0.72, 0.84, 0.96]
        let timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        let animation = CAKeyframeAnimation(keyPath: "opacity")
        animation.keyTimes = [0, 0.5, 1]
        animation.timingFunctions = [timingFunction, timingFunction]
        animation.values = [1, 0.3, 1]
        animation.duration = duration
        animation.repeatCount = .greatestFiniteMagnitude
        animation.isRemovedOnCompletion = false

        for i in 0..<8 {
            let containerLayer = createLayer(.pi / 4 * Double(i), size: lineSize, origin: CGPoint(x: x, y: y), containerSize: size, color: color)
            animation.beginTime = beginTime + beginTimes[i]
            containerLayer.add(animation, forKey: "animation")
            layer.addSublayer(containerLayer)
        }
    }

    private func createLayer(_ angle: CGFloat, size: CGSize, origin: CGPoint, containerSize: CGSize, color: UIColor) -> CALayer {
        let radius = containerSize.width / 2 - max(size.width, size.height) / 2
        let layerSize = CGSize(width: max(size.width, size.height), height: max(size.width, size.height))
        let layer = CALayer()
        let layerFrame = CGRect(x: origin.x + radius * (cos(angle) + 1), y: origin.y + radius * (sin(angle) + 1), width: layerSize.width, height: layerSize.height)
        layer.frame = layerFrame

        let lineLayer = CAShapeLayer()
        let linePath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: size.width, height: size.height), cornerRadius: size.width / 2)
        lineLayer.fillColor = color.cgColor
        lineLayer.backgroundColor = nil
        lineLayer.path = linePath.cgPath
        lineLayer.frame = CGRect(x: (layerSize.width - size.width) / 2, y: (layerSize.height - size.height) / 2, width: size.width, height: size.height)
        layer.addSublayer(lineLayer)
        layer.sublayerTransform = CATransform3DMakeRotation(.pi / 2 + angle, 0, 0, 1)
        return layer
    }
}

class IndicatorViewAnimationLinePulse: NSObject, IndicatorViewAnimationProtocol {
    func setupAnimation(_ layer: CALayer, size: CGSize, color: UIColor) {
        let duration: CFTimeInterval = 1.0
        let beginTimes: [CFTimeInterval] = [0.4, 0.2, 0.0, 0.2, 0.4]
        let timingFunction = CAMediaTimingFunction(controlPoints: 0.85, 0.25, 0.37, 0.85)
        let lineSize = size.width / 9
        let x = (layer.bounds.size.width - size.width) / 2
        let y = (layer.bounds.size.height - size.height) / 2

        let animation = CAKeyframeAnimation(keyPath: "transform.scale.y")
        animation.isRemovedOnCompletion = false
        animation.keyTimes = [0.0, 0.5, 1.0]
        animation.values = [1.0, 0.4, 1.0]
        animation.timingFunctions = [timingFunction, timingFunction]
        animation.repeatCount = .greatestFiniteMagnitude
        animation.duration = duration

        for i in 0..<5 {
            let line = CAShapeLayer()
            let linePath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: lineSize, height: size.height), cornerRadius: lineSize / 2)
            animation.beginTime = beginTimes[i]
            line.fillColor = color.cgColor
            line.path = linePath.cgPath
            line.add(animation, forKey: "animation")
            line.frame = CGRect(x: x + lineSize * 2 * CGFloat(i), y: y, width: lineSize, height: size.height)
            layer.addSublayer(line)
        }
    }
}

class IndicatorViewAnimationBallSpin: NSObject, IndicatorViewAnimationProtocol {
    func setupAnimation(_ layer: CALayer, size: CGSize, color: UIColor) {
        let circleSpacing: CGFloat = -2
        let circleSize = (size.width - 4 * circleSpacing) / 5
        let x = (layer.bounds.size.width - size.width) / 2
        let y = (layer.bounds.size.height - size.height) / 2
        let duration: CFTimeInterval = 1
        let beginTime = CACurrentMediaTime()
        let beginTimes: [CFTimeInterval] = [0, 0.12, 0.24, 0.36, 0.48, 0.6, 0.72, 0.84]

        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnimation.isRemovedOnCompletion = false
        scaleAnimation.keyTimes = [0, 0.5, 1]
        scaleAnimation.values = [1, 0.4, 1]
        scaleAnimation.duration = duration

        let opacityAnimaton = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimaton.isRemovedOnCompletion = false
        opacityAnimaton.keyTimes = [0, 0.5, 1]
        opacityAnimaton.values = [1, 0.3, 1]
        opacityAnimaton.duration = duration

        let animationGroup = CAAnimationGroup()
        animationGroup.isRemovedOnCompletion = false
        animationGroup.animations = [scaleAnimation, opacityAnimaton]
        animationGroup.timingFunction = CAMediaTimingFunction(name: .linear)
        animationGroup.duration = duration
        animationGroup.repeatCount = .greatestFiniteMagnitude

        for i in 0..<8 {
            let circle = circleLayer(CGFloat.pi / 4 * CGFloat(i), size: circleSize, origin: CGPoint(x: x, y: y), containerSize: size, color: color)
            animationGroup.beginTime = beginTime + beginTimes[i]
            layer.addSublayer(circle)
            circle.add(animationGroup, forKey: "animation")
        }
    }

    private func circleLayer(_ angle: CGFloat, size: CGFloat, origin: CGPoint, containerSize: CGSize, color: UIColor) -> CALayer {
        let radius = containerSize.width / 2 - size / 2
        let circle = createLayer(CGSize(width: size, height: size), color: color)
        let frame = CGRect(x: origin.x + radius * (cos(angle) + 1), y: origin.y + radius * (sin(angle) + 1), width: size, height: size)
        circle.frame = frame
        return circle
    }

    private func createLayer(_ size: CGSize, color: UIColor) -> CALayer {
        let layer = CAShapeLayer()
        let path = UIBezierPath()
        path.addArc(withCenter: CGPoint(x: size.width / 2, y: size.height / 2), radius: size.width / 2, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: false)
        layer.fillColor = color.cgColor
        layer.backgroundColor = nil
        layer.path = path.cgPath
        return layer
    }
}

class IndicatorViewAnimationCircleSpin: NSObject, IndicatorViewAnimationProtocol {
    func setupAnimation(_ layer: CALayer, size: CGSize, color: UIColor) {
        let lineWidth: CGFloat = 3
        let bezierPath = UIBezierPath(arcCenter: CGPoint(x: size.width / 2, y: size.height / 2),
                                      radius: (size.width - lineWidth) / 2,
                                      startAngle: 0,
                                      endAngle: .pi * 2,
                                      clockwise: true)
        let shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = nil
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.lineWidth = lineWidth
        shapeLayer.strokeStart = 0
        shapeLayer.strokeEnd = 1
        shapeLayer.lineCap = .round
        shapeLayer.lineDashPhase = 0.8
        shapeLayer.path = bezierPath.cgPath
        layer.mask = shapeLayer

        var gradientLayer = CAGradientLayer()
        gradientLayer.shadowPath = bezierPath.cgPath
        gradientLayer.frame = CGRect(x: 0, y: 0, width: size.width / 2, height: size.height)
        gradientLayer.startPoint = CGPoint(x: 1, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.colors = [color.cgColor, color.withAlphaComponent(0.5).cgColor]
        layer.addSublayer(gradientLayer)

        gradientLayer = CAGradientLayer()
        gradientLayer.shadowPath = bezierPath.cgPath
        gradientLayer.frame = CGRect(x: size.width / 2, y: 0, width: size.width / 2, height: size.height)
        gradientLayer.startPoint = CGPoint(x: 0, y: 1)
        gradientLayer.endPoint = CGPoint(x: 0, y: 0)
        gradientLayer.colors = [color.withAlphaComponent(0.5).cgColor, color.withAlphaComponent(0).cgColor]
        layer.addSublayer(gradientLayer)

        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.isRemovedOnCompletion = false
        animation.fromValue = 0
        animation.toValue = CGFloat.pi * 2
        animation.repeatCount = .greatestFiniteMagnitude
        animation.duration = 1
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.fillMode = .forwards
        layer.add(animation, forKey: "animation")
    }
}

class IndicatorViewAnimationBallPulse: NSObject, IndicatorViewAnimationProtocol {
    func setupAnimation(_ layer: CALayer, size: CGSize, color: UIColor) {
        let circlePadding: CGFloat = 5.0
        let circleSize = (size.width - 2 * circlePadding) / 3
        let x = (layer.bounds.size.width - size.width) / 2
        let y = (layer.bounds.size.height - circleSize) / 2
        let duration: CFTimeInterval = 0.75
        let timeBegins: [CFTimeInterval] = [0.12, 0.24, 0.36]
        let timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.68, 0.18, 1.08)

        let animation = CAKeyframeAnimation(keyPath: "transform")
        animation.isRemovedOnCompletion = false
        animation.values = [
            NSValue(caTransform3D: CATransform3DMakeScale(1.0, 1.0, 1.0)),
            NSValue(caTransform3D: CATransform3DMakeScale(0.3, 0.3, 1.0)),
            NSValue(caTransform3D: CATransform3DMakeScale(1.0, 1.0, 1.0))
        ]
        animation.keyTimes = [0.0, 0.3, 1.0]
        animation.timingFunctions = [timingFunction, timingFunction]
        animation.duration = duration
        animation.repeatCount = .greatestFiniteMagnitude

        for i in 0..<3 {
            let circle = CALayer()
            circle.frame = CGRect(x: x + CGFloat(i) * circleSize + CGFloat(i) * circlePadding, y: y, width: circleSize, height: circleSize)
            circle.backgroundColor = color.cgColor
            circle.cornerRadius = circle.bounds.size.width / 2
            animation.beginTime = timeBegins[i]
            circle.add(animation, forKey: "animation")
            layer.addSublayer(circle)
        }
    }
}

class IndicatorViewAnimationBallTriangle: NSObject, IndicatorViewAnimationProtocol {
    func setupAnimation(_ layer: CALayer, size: CGSize, color: UIColor) {
        let duration: CFTimeInterval = 2.0
        let circleSize = size.width / 5
        let deltaX = size.width / 2 - circleSize / 2
        let deltaY = size.height / 2 - circleSize / 2
        let x = (layer.bounds.size.width - size.width) / 2
        let y = (layer.bounds.size.height - size.height) / 2
        let timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        let animation = CAKeyframeAnimation(keyPath: "transform")
        animation.isRemovedOnCompletion = false
        animation.keyTimes = [0.0, 0.33, 0.66, 1.0]
        animation.duration = duration
        animation.timingFunctions = [timingFunction, timingFunction, timingFunction]
        animation.repeatCount = .greatestFiniteMagnitude

        let topCenterCircle = createCircle(size: circleSize, color: color)
        changeAnimation(animation, values: ["{0,0}", "{hx,fy}", "{-hx,fy}", "{0,0}"], deltaX: deltaX, deltaY: deltaY)
        topCenterCircle.frame = CGRect(x: x + size.width / 2 - circleSize / 2, y: y, width: circleSize, height: circleSize)
        topCenterCircle.add(animation, forKey: "animation")
        layer.addSublayer(topCenterCircle)

        let bottomLeftCircle = createCircle(size: circleSize, color: color)
        changeAnimation(animation, values: ["{0,0}", "{hx,-fy}", "{fx,0}", "{0,0}"], deltaX: deltaX, deltaY: deltaY)
        bottomLeftCircle.frame = CGRect(x: x, y: y + size.height - circleSize, width: circleSize, height: circleSize)
        bottomLeftCircle.add(animation, forKey: "animation")
        layer.addSublayer(bottomLeftCircle)

        let bottomRightCircle = createCircle(size: circleSize, color: color)
        changeAnimation(animation, values: ["{0,0}", "{-fx,0}", "{-hx,-fy}", "{0,0}"], deltaX: deltaX, deltaY: deltaY)
        bottomRightCircle.frame = CGRect(x: x + size.width - circleSize, y: y + size.height - circleSize, width: circleSize, height: circleSize)
        bottomRightCircle.add(animation, forKey: "animation")
        layer.addSublayer(bottomRightCircle)
    }

    private func createCircle(size: CGFloat, color: UIColor) -> CALayer {
        let circle = CAShapeLayer()
        let circlePath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: size, height: size), cornerRadius: size / 2)
        circle.fillColor = nil
        circle.strokeColor = color.cgColor
        circle.lineWidth = 1
        circle.path = circlePath.cgPath
        return circle
    }

    private func changeAnimation(_ animation: CAKeyframeAnimation, values rawValues: [String], deltaX: CGFloat, deltaY: CGFloat) {
        var values = [NSValue]()
        for rawValue in rawValues {
            let point = NSCoder.cgPoint(for: translate(rawValue, deltaX: deltaX, deltaY: deltaY))
            values.append(NSValue(caTransform3D: CATransform3DMakeTranslation(point.x, point.y, 0)))
        }
        animation.values = values
    }

    private func translate(_ valueString: String, deltaX: CGFloat, deltaY: CGFloat) -> String {
        let valueMutableString = NSMutableString(string: valueString)
        let fullDeltaX = 2 * deltaX
        let fullDeltaY = 2 * deltaY
        var range = NSRange(location: 0, length: valueString.count)

        valueMutableString.replaceOccurrences(of: "hx", with: "\(deltaX)", options: .caseInsensitive, range: range)
        range.length = valueMutableString.length
        valueMutableString.replaceOccurrences(of: "fx", with: "\(fullDeltaX)", options: .caseInsensitive, range: range)
        range.length = valueMutableString.length
        valueMutableString.replaceOccurrences(of: "hy", with: "\(deltaY)", options: .caseInsensitive, range: range)
        range.length = valueMutableString.length
        valueMutableString.replaceOccurrences(of: "fy", with: "\(fullDeltaY)", options: .caseInsensitive, range: range)
        return valueMutableString as String
    }
}

class IndicatorViewAnimationTriplePulse: NSObject, IndicatorViewAnimationProtocol {
    func setupAnimation(_ layer: CALayer, size: CGSize, color: UIColor) {
        let duration: CFTimeInterval = 1
        let beginTime = CACurrentMediaTime()
        let beginTimes: [CFTimeInterval] = [0, 0.2, 0.4]

        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.duration = duration
        scaleAnimation.fromValue = 0
        scaleAnimation.toValue = 1

        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.duration = duration
        opacityAnimation.keyTimes = [0, 0.05, 1]
        opacityAnimation.values = [0, 1, 0]

        let animationGroup = CAAnimationGroup()
        animationGroup.isRemovedOnCompletion = false
        animationGroup.animations = [scaleAnimation, opacityAnimation]
        animationGroup.timingFunction = CAMediaTimingFunction(name: .linear)
        animationGroup.duration = duration
        animationGroup.repeatCount = .greatestFiniteMagnitude

        for i in 0..<3 {
            let circle = CAShapeLayer()
            let circlePath = UIBezierPath()
            circlePath.addArc(withCenter: CGPoint(x: size.width / 2, y: size.height / 2), radius: size.width / 2, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
            circle.fillColor = color.cgColor
            circle.backgroundColor = nil
            circle.path = circlePath.cgPath
            circle.frame = CGRect(x: (layer.bounds.size.width - size.width) / 2.0, y: (layer.bounds.size.height - size.height) / 2.0, width: size.width, height: size.height)
            circle.opacity = 0
            animationGroup.beginTime = beginTime + beginTimes[i]
            circle.add(animationGroup, forKey: "animation")
            layer.addSublayer(circle)
        }
    }
}
