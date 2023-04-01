//
//  PageControl.swift
//  FWFramework
//
//  Created by wuyong on 2023/3/29.
//

import UIKit

// MARK: - DotView
/// 点视图协议
public protocol DotViewProtocol {
    
    /// 选中状态改变方法
    func changeActivityState(_ active: Bool)
    
}

/// 自带点视图
open class DotView: UIView, DotViewProtocol {
    
    open var dotColor: UIColor = .white.withAlphaComponent(0.5)
    
    open var currentDotColor: UIColor = .white
    
    open var isAnimated = false
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        didInitialize()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        didInitialize()
    }
    
    fileprivate func didInitialize() {
        layer.cornerRadius = min(frame.width, frame.height) / 2.0
        layer.masksToBounds = true
        backgroundColor = dotColor
    }
    
    open func changeActivityState(_ active: Bool) {
        if !isAnimated {
            backgroundColor = active ? currentDotColor : dotColor
        } else {
            if active {
                UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: -20, options: .curveLinear, animations: {
                    self.backgroundColor = self.currentDotColor
                    self.transform = .init(scaleX: 1.4, y: 1.4)
                }, completion: nil)
            } else {
                UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveLinear, animations: {
                    self.backgroundColor = self.dotColor
                    self.transform = .identity
                }, completion: nil)
            }
        }
    }
    
}

/// 自带边框点视图
open class BorderDotView: DotView {
    
    open override var dotColor: UIColor {
        didSet {
            backgroundColor = dotColor
        }
    }
    
    open override var currentDotColor: UIColor {
        didSet {
            layer.borderColor = currentDotColor.cgColor
        }
    }
    
    override func didInitialize() {
        dotColor = .clear
        currentDotColor = .white
        layer.cornerRadius = min(frame.width, frame.height) / 2.0
        layer.borderWidth = 2
        layer.masksToBounds = true
        backgroundColor = dotColor
        layer.borderColor = currentDotColor.cgColor
    }
    
}
