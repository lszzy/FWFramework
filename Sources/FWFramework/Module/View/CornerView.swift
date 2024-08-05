//
//  CornerView.swift
//  FWFramework
//
//  Created by wuyong on 2023/1/4.
//

import UIKit
import QuartzCore

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

// MARK: - RectCornerView
/// 不规则圆角View，无需frame快捷设置不规则圆角、边框等
open class RectCornerView: UIView {
    
    /// 自定义圆角位置，默认allCorners
    open var rectCorner: UIRectCorner = .allCorners {
        didSet { self.setNeedsLayout() }
    }
    
    /// 自定义圆角半径，默认0
    open var cornerRadius: CGFloat = 0 {
        didSet { self.setNeedsLayout() }
    }
    
    /// 自定义边框颜色，默认nil不生效
    open var borderColor: UIColor? {
        didSet { self.setNeedsLayout() }
    }
    
    /// 自定义边框宽度，默认0
    open var borderWidth: CGFloat = 0 {
        didSet { self.setNeedsLayout() }
    }
    
    /// 自定义layoutSubviews句柄，默认nil
    open var layoutSubviewsBlock: ((UIView) -> Void)? {
        didSet { self.setNeedsLayout() }
    }
    
    /// 快捷初始化不规则圆角
    public convenience init(rectCorner: UIRectCorner, cornerRadius: CGFloat) {
        self.init(frame: .zero)
        self.rectCorner = rectCorner
        self.cornerRadius = cornerRadius
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
        if let borderColor = borderColor {
            fw.setCornerLayer(rectCorner, radius: cornerRadius, borderColor: borderColor, width: borderWidth)
        } else {
            fw.setCornerLayer(rectCorner, radius: cornerRadius)
        }
        layoutSubviewsBlock?(self)
    }
    
}
