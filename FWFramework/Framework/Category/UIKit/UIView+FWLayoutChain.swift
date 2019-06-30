//
//  UIView+FWLayoutChain.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/29.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation

// MARK: - FWLayoutChain
public class FWLayoutChain {
    /// weak引用内部视图
    fileprivate weak var view: UIView? = nil
    
    // MARK: - Install
    @discardableResult
    public func remake() -> FWLayoutChain {
        self.view?.fwRemoveAllConstraints()
        return self
    }
    
    // MARK: - Compression
    @discardableResult
    public func compressionHorizontal(_ priority: UILayoutPriority) -> FWLayoutChain {
        self.view?.fwSetCompressionHorizontalPriority(priority)
        return self
    }
    
    @discardableResult
    public func compressionVertical(_ priority: UILayoutPriority) -> FWLayoutChain {
        self.view?.fwSetCompressionVerticalPriority(priority)
        return self
    }
    
    // MARK: - Axis
    @discardableResult
    public func center() -> FWLayoutChain {
        self.view?.fwAlignCenterToSuperview()
        return self
    }
    
    @discardableResult
    public func centerX() -> FWLayoutChain {
        self.view?.fwAlignAxis(toSuperview: .centerX)
        return self
    }
    
    @discardableResult
    public func centerY() -> FWLayoutChain {
        self.view?.fwAlignAxis(toSuperview: .centerY)
        return self
    }
    
    @discardableResult
    public func centerToView(view: Any) -> FWLayoutChain {
        self.view?.fwAlignAxis(.centerX, toView: view)
        self.view?.fwAlignAxis(.centerY, toView: view)
        return self
    }
    
    @discardableResult
    public func centerXToView(view: Any, withOffset offset: CGFloat = 0) -> FWLayoutChain {
        self.view?.fwAlignAxis(.centerX, toView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func centerYToView(view: Any, withOffset offset: CGFloat = 0) -> FWLayoutChain {
        self.view?.fwAlignAxis(.centerY, toView: view, withOffset:offset)
        return self
    }
    
    @discardableResult
    public func centerXToView(view: Any, withMultiplier multiplier: CGFloat) -> FWLayoutChain {
        self.view?.fwAlignAxis(.centerX, toView: view, withMultiplier: multiplier)
        return self
    }
    
    @discardableResult
    public func centerYToView(view: Any, withMultiplier multiplier: CGFloat) -> FWLayoutChain {
        self.view?.fwAlignAxis(.centerY, toView: view, withMultiplier: multiplier)
        return self
    }
    
    // MARK: - Edge
    @discardableResult
    public func edges(_ insets: UIEdgeInsets = UIEdgeInsets.zero, excludingEdge edge: NSLayoutConstraint.Attribute = NSLayoutConstraint.Attribute.notAnAttribute) -> FWLayoutChain {
        if (edge == .notAnAttribute) {
            self.view?.fwPinEdgesToSuperview(with: insets)
        } else {
            self.view?.fwPinEdgesToSuperview(with: insets, excludingEdge: edge)
        }
        return self
    }
    
    @discardableResult
    public func edgesHorizontal() -> FWLayoutChain {
        self.view?.fwPinEdgesToSuperviewHorizontal()
        return self
    }
    
    @discardableResult
    public func edgesVertical() -> FWLayoutChain {
        self.view?.fwPinEdgesToSuperviewVertical()
        return self
    }
    
    @discardableResult
    public func top(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwPinEdge(toSuperview: .top, withInset: inset, relation: relation)
        return self
    }
    
    @discardableResult
    public func bottom(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwPinEdge(toSuperview: .bottom, withInset: inset, relation: relation)
        return self
    }
    
    @discardableResult
    public func left(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwPinEdge(toSuperview: .left, withInset: inset, relation: relation)
        return self
    }
    
    @discardableResult
    public func right(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwPinEdge(toSuperview: .right, withInset: inset, relation: relation)
        return self
    }
    
    @discardableResult
    public func topToView(view: Any, withOffset offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwPinEdge(.top, toEdge: .top, ofView: view, withOffset: offset, relation: relation)
        return self
    }
    
    @discardableResult
    public func bottomToView(view: Any, withOffset offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwPinEdge(.bottom, toEdge: .bottom, ofView: view, withOffset: offset, relation: relation)
        return self
    }
    
    @discardableResult
    public func leftToView(view: Any, withOffset offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwPinEdge(.left, toEdge: .left, ofView: view, withOffset: offset, relation: relation)
        return self
    }
    
    @discardableResult
    public func rightToView(view: Any, withOffset offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwPinEdge(.right, toEdge: .right, ofView: view, withOffset: offset, relation: relation)
        return self
    }
    
    @discardableResult
    public func topToBottomOfView(view: Any, withOffset offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwPinEdge(.top, toEdge: .bottom, ofView: view, withOffset: offset, relation: relation)
        return self
    }
    
    @discardableResult
    public func bottomToTopOfView(view: Any, withOffset offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwPinEdge(.bottom, toEdge: .top, ofView: view, withOffset: offset, relation: relation)
        return self
    }
    
    @discardableResult
    public func leftToRightOfView(view: Any, withOffset offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwPinEdge(.left, toEdge: .right, ofView: view, withOffset: offset, relation: relation)
        return self
    }
    
    @discardableResult
    public func rightToLeftOfView(view: Any, withOffset offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwPinEdge(.right, toEdge: .left, ofView: view, withOffset: offset, relation: relation)
        return self
    }
    
    // MARK: - SafeArea
    @discardableResult
    public func centerToSafeArea() -> FWLayoutChain {
        self.view?.fwAlignCenterToSuperviewSafeArea()
        return self
    }
    
    @discardableResult
    public func centerXToSafeArea() -> FWLayoutChain {
        self.view?.fwAlignAxis(toSuperviewSafeArea: .centerX)
        return self
    }
    
    @discardableResult
    public func centerYToSafeArea() -> FWLayoutChain {
        self.view?.fwAlignAxis(toSuperviewSafeArea: .centerY)
        return self
    }
    
    @discardableResult
    public func edgesToSafeArea(_ insets: UIEdgeInsets = UIEdgeInsets.zero, excludingEdge edge: NSLayoutConstraint.Attribute = NSLayoutConstraint.Attribute.notAnAttribute) -> FWLayoutChain {
        if (edge == .notAnAttribute) {
            self.view?.fwPinEdgesToSuperviewSafeArea(with: insets)
        } else {
            self.view?.fwPinEdgesToSuperviewSafeArea(with: insets, excludingEdge: edge)
        }
        return self
    }
    
    @discardableResult
    public func edgesToSafeAreaHorizontal() -> FWLayoutChain {
        self.view?.fwPinEdgesToSuperviewSafeAreaHorizontal()
        return self
    }
    
    @discardableResult
    public func edgesToSafeAreaVertical() -> FWLayoutChain {
        self.view?.fwPinEdgesToSuperviewSafeAreaVertical()
        return self
    }
    
    @discardableResult
    public func topToSafeArea(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwPinEdge(toSuperviewSafeArea: .top, withInset: inset, relation: relation)
        return self
    }
    
    @discardableResult
    public func bottomToSafeArea(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwPinEdge(toSuperviewSafeArea: .bottom, withInset: inset, relation: relation)
        return self
    }
    
    @discardableResult
    public func leftToSafeArea(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwPinEdge(toSuperviewSafeArea: .left, withInset: inset, relation: relation)
        return self
    }
    
    @discardableResult
    public func rightToSafeArea(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwPinEdge(toSuperviewSafeArea: .right, withInset: inset, relation: relation)
        return self
    }
    
    // MARK: - Dimension
    @discardableResult
    public func size(_ size: CGSize) -> FWLayoutChain {
        self.view?.fwSetDimensions(to: size)
        return self
    }
    
    @discardableResult
    public func width(_ width: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwSetDimension(.width, toSize: width, relation: relation)
        return self
    }
    
    @discardableResult
    public func height(_ height: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwSetDimension(.height, toSize: height, relation: relation)
        return self
    }
    
    @discardableResult
    public func sizeToView(view: Any) -> FWLayoutChain {
        self.view?.fwMatchDimension(.width, toDimension: .width, ofView: view)
        self.view?.fwMatchDimension(.height, toDimension: .height, ofView: view)
        return self
    }
    
    @discardableResult
    public func widthToView(view: Any, withOffset offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwMatchDimension(.width, toDimension: .width, ofView: view, withOffset: offset, relation: relation)
        return self
    }
    
    @discardableResult
    public func heightToView(view: Any, withOffset offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwMatchDimension(.height, toDimension: .height, ofView: view, withOffset: offset, relation: relation)
        return self
    }
    
    @discardableResult
    public func widthToView(view: Any, withMultiplier multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwMatchDimension(.width, toDimension: .width, ofView: view, withMultiplier: multiplier, relation: relation)
        return self
    }
    
    @discardableResult
    public func heightToView(view: Any, withMultiplier multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwMatchDimension(.height, toDimension: .height, ofView: view, withMultiplier: multiplier, relation: relation)
        return self
    }
    
    // MARK: - Attribute
    @discardableResult
    public func attribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any, withOffset offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwConstrainAttribute(attribute, to: toAttribute, ofView: view, withOffset: offset, relation: relation)
        return self
    }
    
    @discardableResult
    public func attribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any, withMultiplier multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwConstrainAttribute(attribute, to: toAttribute, ofView: view, withMultiplier: multiplier, relation: relation)
        return self
    }
}

// MARK: - UIView+FWLayoutChain
extension UIView {
    /// 关联对象Key
    private struct AssociatedKeys {
        static var layoutChainKey = "layoutChainKey"
    }
    
    /// 链式布局对象
    public var fwLayoutChain: FWLayoutChain {
        var layoutChain = objc_getAssociatedObject(self, &AssociatedKeys.layoutChainKey)
        if layoutChain == nil {
            let tempChain = FWLayoutChain()
            tempChain.view = self
            layoutChain = tempChain
            objc_setAssociatedObject(self, &AssociatedKeys.layoutChainKey, layoutChain, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        return layoutChain as! FWLayoutChain
    }
}
