//
//  GradientView.swift
//  FWFramework
//
//  Created by wuyong on 2023/1/4.
//

import UIKit
import QuartzCore

// MARK: - GradientView
/// 渐变View，无需设置渐变Layer的frame等，支持自动布局
open class GradientView: UIView {

    /// 渐变Layer
    open var gradientLayer: CAGradientLayer {
        return self.layer as! CAGradientLayer
    }
    
    /// 渐变色，CGColor数组
    open var colors: [Any]? {
        get { return gradientLayer.colors }
        set { gradientLayer.colors = newValue }
    }
    
    /// 渐变位置
    open var locations: [NSNumber]? {
        get { return gradientLayer.locations }
        set { gradientLayer.locations = newValue }
    }
    
    /// 渐变开始点
    open var startPoint: CGPoint {
        get { return gradientLayer.startPoint }
        set { gradientLayer.startPoint = newValue }
    }
    
    /// 渐变结束点
    open var endPoint: CGPoint {
        get { return gradientLayer.endPoint }
        set { gradientLayer.endPoint = newValue }
    }
    
    /// 初始化并指定渐变颜色、位置和渐变方向
    public convenience init(colors: [UIColor]?, locations: [NSNumber]?, startPoint: CGPoint, endPoint: CGPoint) {
        self.init(frame: .zero)
        setColors(colors, locations: locations, startPoint: startPoint, endPoint: endPoint)
    }
    
    /// 指定layerClass为CAGradientLayer
    open override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    /// 设置渐变颜色、位置和渐变方向
    open func setColors(_ colors: [UIColor]?, locations: [NSNumber]?, startPoint: CGPoint, endPoint: CGPoint) {
        self.gradientLayer.colors = colors?.compactMap({ $0.cgColor })
        self.gradientLayer.locations = locations
        self.gradientLayer.startPoint = startPoint
        self.gradientLayer.endPoint = endPoint
    }

}

// MARK: - RoundedCornerView
/// 半圆圆角View，无需frame快捷设置半圆圆角、边框等
open class RoundedCornerView: UIView {
    
    /// 是否是半圆圆角，默认true
    open var isRoundedCorner: Bool = true {
        didSet { self.setNeedsLayout() }
    }
    
    /// 自定义圆角半径，优先级高，默认nil不生效
    open var cornerRadius: CGFloat? {
        didSet {
            if let cornerRadius = cornerRadius {
                self.layer.cornerRadius = cornerRadius
            }
            self.setNeedsLayout()
        }
    }
    
    /// 自定义边框颜色，默认nil不生效
    open var borderColor: UIColor? {
        didSet { self.layer.borderColor = borderColor?.cgColor }
    }
    
    /// 自定义边框宽度，默认0
    open var borderWidth: CGFloat = 0 {
        didSet { self.layer.borderWidth = borderWidth }
    }
    
    /// 自定义layoutSubviews句柄，默认nil
    open var layoutSubviewsBlock: ((UIView) -> Void)? {
        didSet { self.setNeedsLayout() }
    }
    
    /// 快捷初始化带边框半圆圆角
    public convenience init(borderColor: UIColor?, borderWidth: CGFloat) {
        self.init(frame: .zero)
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.layer.borderColor = borderColor?.cgColor
        self.layer.borderWidth = borderWidth
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.masksToBounds = true
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.layer.masksToBounds = true
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        if cornerRadius == nil, isRoundedCorner {
            self.layer.cornerRadius = self.bounds.height / 2.0
        }
        layoutSubviewsBlock?(self)
    }
    
}
