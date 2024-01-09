//
//  GradientView.swift
//  FWFramework
//
//  Created by wuyong on 2023/1/4.
//

import UIKit
import QuartzCore

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
