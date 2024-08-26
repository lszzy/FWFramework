//
//  GradientView.swift
//  FWFramework
//
//  Created by wuyong on 2023/1/4.
//

import QuartzCore
import UIKit

// MARK: - GradientView
/// 渐变View，无需设置渐变Layer的frame等，支持自动布局
open class GradientView: UIView {
    /// 渐变Layer
    open var gradientLayer: CAGradientLayer {
        layer as! CAGradientLayer
    }

    /// 渐变色，CGColor数组
    open var colors: [Any]? {
        get { gradientLayer.colors }
        set { gradientLayer.colors = newValue }
    }

    /// 渐变位置
    open var locations: [NSNumber]? {
        get { gradientLayer.locations }
        set { gradientLayer.locations = newValue }
    }

    /// 渐变开始点
    open var startPoint: CGPoint {
        get { gradientLayer.startPoint }
        set { gradientLayer.startPoint = newValue }
    }

    /// 渐变结束点
    open var endPoint: CGPoint {
        get { gradientLayer.endPoint }
        set { gradientLayer.endPoint = newValue }
    }

    /// 初始化并指定渐变颜色、位置和渐变方向
    public convenience init(colors: [UIColor]?, locations: [NSNumber]?, startPoint: CGPoint, endPoint: CGPoint) {
        self.init(frame: .zero)
        setColors(colors, locations: locations, startPoint: startPoint, endPoint: endPoint)
    }

    /// 指定layerClass为CAGradientLayer
    override open class var layerClass: AnyClass {
        CAGradientLayer.self
    }

    /// 设置渐变颜色、位置和渐变方向
    open func setColors(_ colors: [UIColor]?, locations: [NSNumber]?, startPoint: CGPoint, endPoint: CGPoint) {
        gradientLayer.colors = colors?.compactMap(\.cgColor)
        gradientLayer.locations = locations
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
    }
}
