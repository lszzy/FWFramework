//
//  ProgressView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

/// 框架默认进度条视图
open class ProgressView: UIView, ProgressViewPlugin {

    /// 是否是环形，默认为true，false为扇形
    open var annular: Bool {
        get { progressLayer.annular }
        set { progressLayer.annular = newValue }
    }

    /// 进度颜色，默认为白色
    open var color: UIColor {
        get { progressLayer.color }
        set { progressLayer.color = newValue }
    }

    /// 设置或获取进度条大小，默认为{37, 37}
    open var size: CGSize {
        get { bounds.size }
        set { frame = CGRect(origin: frame.origin, size: newValue) }
    }

    /// 自定义线条颜色，默认为nil自动处理。环形时为color透明度0.1，扇形时为color
    open var lineColor: UIColor? {
        get { progressLayer.lineColor }
        set { progressLayer.lineColor = newValue }
    }

    /// 自定义线条宽度，默认为0自动处理。环形时为3，扇形时为1
    open var lineWidth: CGFloat {
        get { progressLayer.lineWidth }
        set { progressLayer.lineWidth = newValue }
    }

    /// 自定义线条样式，仅环形生效，默认为.kCGLineCapRound
    open var lineCap: CGLineCap {
        get { progressLayer.lineCap }
        set { progressLayer.lineCap = newValue }
    }

    /// 自定义填充颜色，默认为nil
    open var fillColor: UIColor? {
        get { progressLayer.fillColor }
        set { progressLayer.fillColor = newValue }
    }

    /// 自定义填充内边距，默认为0
    open var fillInset: CGFloat {
        get { progressLayer.fillInset }
        set { progressLayer.fillInset = newValue }
    }

    /// 进度动画时长，默认为0.5
    open var animationDuration: CFTimeInterval {
        get { progressLayer.animationDuration }
        set { progressLayer.animationDuration = newValue }
    }

    /// 当前进度，取值范围为0.0到1.0，默认为0
    open var progress: CGFloat {
        get { progressLayer.progress }
        set { setProgress(newValue, animated: false) }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        didInitialize()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        didInitialize()
    }
    
    private func didInitialize() {
        if frame.size.equalTo(.zero) {
            frame = CGRect(origin: frame.origin, size: CGSize(width: 37.0, height: 37.0))
        }

        backgroundColor = .clear
        layer.contentsScale = UIScreen.main.scale
        layer.setNeedsDisplay()
    }
    
    override open class var layerClass: AnyClass {
        return ProgressLayer.self
    }
    
    private var progressLayer: ProgressLayer {
        return layer as! ProgressLayer
    }
    
    open override var frame: CGRect {
        get {
            return super.frame
        }
        set {
            super.frame = newValue
            invalidateIntrinsicContentSize()
        }
    }
    
    open override var bounds: CGRect {
        get {
            return super.bounds
        }
        set {
            super.bounds = newValue
            invalidateIntrinsicContentSize()
        }
    }
    
    open override var intrinsicContentSize: CGSize {
        return bounds.size
    }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        return bounds.size
    }

    /// 设置当前进度，支持动画
    open func setProgress(_ progress: CGFloat, animated: Bool) {
        let clampedProgress = max(0.0, min(progress, 1.0))
        progressLayer.animated = animated
        progressLayer.progress = clampedProgress
    }
    
}

open class ProgressLayer: CALayer {
    
    @objc dynamic open var annular: Bool = true
    @objc dynamic open var color: UIColor = .white
    @objc dynamic open var lineColor: UIColor?
    @objc dynamic open var lineWidth: CGFloat = 0
    @objc dynamic open var lineCap: CGLineCap = .round
    @objc dynamic open var fillColor: UIColor?
    @objc dynamic open var fillInset: CGFloat = 0
    @objc dynamic open var animationDuration: CFTimeInterval = 0.5
    @objc dynamic open var progress: CGFloat = 0
    @objc dynamic open var animated: Bool = false
    
    open override class func needsDisplay(forKey key: String) -> Bool {
        return key == "progress" || super.needsDisplay(forKey: key)
    }
    
    open override func action(forKey event: String) -> CAAction? {
        if event == "progress" && animated {
            let animation = CABasicAnimation(keyPath: event)
            animation.fromValue = presentation()?.value(forKey: event)
            animation.duration = animationDuration
            return animation
        }
        return super.action(forKey: event)
    }
    
    open override func draw(in context: CGContext) {
        guard !CGRectIsEmpty(bounds) else { return }
        
        if annular {
            let lineColor = self.lineColor ?? color.withAlphaComponent(0.1)
            let lineWidth = self.lineWidth > 0 ? self.lineWidth : 3
            context.setLineWidth(lineWidth)
            context.setLineCap(.round)
            let center = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
            let radius = (min(bounds.size.width, bounds.size.height) - lineWidth) / 2
            let startAngle = -CGFloat.pi / 2
            var endAngle = 2 * CGFloat.pi + startAngle
            context.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            context.setStrokeColor(lineColor.cgColor)
            context.strokePath()
            
            if let fillColor = self.fillColor {
                let fillRadius = (min(bounds.size.width, bounds.size.height) - (lineWidth + fillInset) * 2) / 2
                context.addArc(center: center, radius: fillRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
                context.setFillColor(fillColor.cgColor)
                context.fillPath()
            }
            
            let bezierPath = UIBezierPath()
            bezierPath.lineWidth = lineWidth
            bezierPath.lineCapStyle = lineCap
            endAngle = progress * 2 * CGFloat.pi + startAngle
            bezierPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            context.setStrokeColor(color.cgColor)
            context.addPath(bezierPath.cgPath)
            context.strokePath()
        } else {
            let lineColor = self.lineColor ?? color
            let lineWidth = self.lineWidth > 0 ? self.lineWidth : 1
            let allRect = bounds
            let circleInset = lineWidth + fillInset
            context.setStrokeColor(lineColor.cgColor)
            context.setLineWidth(lineWidth)
            context.strokeEllipse(in: allRect.insetBy(dx: lineWidth / 2.0, dy: lineWidth / 2.0))
            
            if let fillColor = self.fillColor {
                context.setFillColor(fillColor.cgColor)
                context.fillEllipse(in: allRect.insetBy(dx: circleInset, dy: circleInset))
            }
            
            let center = CGPoint(x: allRect.size.width / 2.0, y: allRect.size.height / 2.0)
            let radius = (min(allRect.size.width, allRect.size.height) - circleInset * 2) / 2
            let startAngle = -CGFloat.pi / 2
            let endAngle = progress * 2 * CGFloat.pi + startAngle
            context.setFillColor(color.cgColor)
            context.move(to: center)
            context.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            context.closePath()
            context.fillPath()
        }
        
        super.draw(in: context)
    }
    
    open override func layoutSublayers() {
        super.layoutSublayers()
        cornerRadius = bounds.height / 2
    }
    
}
