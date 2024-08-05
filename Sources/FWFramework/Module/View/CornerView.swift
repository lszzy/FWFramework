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

// MARK: - CollapsedButton
/// 无内容自动收缩按钮，title、attributedTitle、image都为nil时不占用布局大小
open class CollapsedButton: UIButton {
    
    /// 获取当前按钮是否非空，兼容attributedTitle|title|image
    open var isNotEmpty: Bool {
        if (currentAttributedTitle?.length ?? 0) > 0 { return true }
        if (currentTitle?.count ?? 0) > 0 { return true }
        if currentImage != nil { return true }
        return false
    }
    
    open override var isEnabled: Bool {
        didSet { invalidateIntrinsicContentSize() }
    }
    
    open override var isSelected: Bool {
        didSet { invalidateIntrinsicContentSize() }
    }
    
    open override var isHighlighted: Bool {
        didSet { invalidateIntrinsicContentSize() }
    }
    
    open override func setTitle(_ title: String?, for state: UIControl.State) {
        super.setTitle(title, for: state)
        invalidateIntrinsicContentSize()
    }
    
    open override func setImage(_ image: UIImage?, for state: UIControl.State) {
        super.setImage(image, for: state)
        invalidateIntrinsicContentSize()
    }
    
    open override func setAttributedTitle(_ title: NSAttributedString?, for state: UIControl.State) {
        super.setAttributedTitle(title, for: state)
        invalidateIntrinsicContentSize()
    }
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard isNotEmpty else { return .zero }
        return super.sizeThatFits(size)
    }
    
    open override var intrinsicContentSize: CGSize {
        guard isNotEmpty else { return .zero }
        return super.intrinsicContentSize
    }
    
}
