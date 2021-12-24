//
//  FWAutoLayout.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/29.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation
#if FWFrameworkSwift
import FWFramework
#endif

// MARK: - FWLayoutChain

/// 视图链式布局类。如果约束条件完全相同，会自动更新约束而不是重新添加。
/// 另外，默认布局方式使用LTR，如果需要RTL布局，可通过fwAutoLayoutRTL统一启用
public class FWLayoutChain {
    /// weak引用内部视图
    private weak var view: UIView?

    /// 构造方法
    public required init(view: UIView?) {
        self.view = view
    }

    // MARK: - Install

    @discardableResult
    public func remake() -> FWLayoutChain {
        view?.fwRemoveAllConstraints()
        return self
    }

    // MARK: - Compression

    @discardableResult
    public func compressionHorizontal(_ priority: UILayoutPriority) -> FWLayoutChain {
        view?.fwCompressionHorizontal = priority
        return self
    }

    @discardableResult
    public func compressionVertical(_ priority: UILayoutPriority) -> FWLayoutChain {
        view?.fwCompressionVertical = priority
        return self
    }
    
    @discardableResult
    public func huggingHorizontal(_ priority: UILayoutPriority) -> FWLayoutChain {
        view?.fwHuggingHorizontal = priority
        return self
    }

    @discardableResult
    public func huggingVertical(_ priority: UILayoutPriority) -> FWLayoutChain {
        view?.fwHuggingVertical = priority
        return self
    }
    
    // MARK: - Collapse

    @discardableResult
    public func collapsed(_ collapsed: Bool) -> FWLayoutChain {
        view?.fwCollapsed = collapsed
        return self
    }

    @discardableResult
    public func autoCollapse(_ autoCollapse: Bool) -> FWLayoutChain {
        view?.fwAutoCollapse = autoCollapse
        return self
    }
    
    @discardableResult
    public func hiddenCollapse(_ hiddenCollapse: Bool) -> FWLayoutChain {
        view?.fwHiddenCollapse = hiddenCollapse
        return self
    }

    // MARK: - Axis

    @discardableResult
    public func center() -> FWLayoutChain {
        view?.fwAlignCenterToSuperview()
        return self
    }

    @discardableResult
    public func centerX() -> FWLayoutChain {
        view?.fwAlignAxis(toSuperview: .centerX)
        return self
    }

    @discardableResult
    public func centerY() -> FWLayoutChain {
        view?.fwAlignAxis(toSuperview: .centerY)
        return self
    }

    @discardableResult
    public func centerToView(_ view: Any) -> FWLayoutChain {
        self.view?.fwAlignAxis(.centerX, toView: view)
        self.view?.fwAlignAxis(.centerY, toView: view)
        return self
    }

    @discardableResult
    public func centerXToView(_ view: Any, withOffset offset: CGFloat = 0) -> FWLayoutChain {
        self.view?.fwAlignAxis(.centerX, toView: view, withOffset: offset)
        return self
    }

    @discardableResult
    public func centerYToView(_ view: Any, withOffset offset: CGFloat = 0) -> FWLayoutChain {
        self.view?.fwAlignAxis(.centerY, toView: view, withOffset: offset)
        return self
    }

    @discardableResult
    public func centerXToView(_ view: Any, withMultiplier multiplier: CGFloat) -> FWLayoutChain {
        self.view?.fwAlignAxis(.centerX, toView: view, withMultiplier: multiplier)
        return self
    }

    @discardableResult
    public func centerYToView(_ view: Any, withMultiplier multiplier: CGFloat) -> FWLayoutChain {
        self.view?.fwAlignAxis(.centerY, toView: view, withMultiplier: multiplier)
        return self
    }

    // MARK: - Edge

    @discardableResult
    public func edges(_ insets: UIEdgeInsets = UIEdgeInsets.zero) -> FWLayoutChain {
        view?.fwPinEdgesToSuperview(with: insets)
        return self
    }
    
    @discardableResult
    public func edges(_ insets: UIEdgeInsets = UIEdgeInsets.zero, excludingEdge edge: NSLayoutConstraint.Attribute) -> FWLayoutChain {
        view?.fwPinEdgesToSuperview(with: insets, excludingEdge: edge)
        return self
    }

    @discardableResult
    public func edgesHorizontal() -> FWLayoutChain {
        view?.fwPinEdgesToSuperviewHorizontal()
        return self
    }

    @discardableResult
    public func edgesVertical() -> FWLayoutChain {
        view?.fwPinEdgesToSuperviewVertical()
        return self
    }

    @discardableResult
    public func top(_ inset: CGFloat = 0) -> FWLayoutChain {
        view?.fwPinEdge(toSuperview: .top, withInset: inset)
        return self
    }
    
    @discardableResult
    public func top(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> FWLayoutChain {
        view?.fwPinEdge(toSuperview: .top, withInset: inset, relation: relation)
        return self
    }

    @discardableResult
    public func bottom(_ inset: CGFloat = 0) -> FWLayoutChain {
        view?.fwPinEdge(toSuperview: .bottom, withInset: inset)
        return self
    }
    
    @discardableResult
    public func bottom(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> FWLayoutChain {
        view?.fwPinEdge(toSuperview: .bottom, withInset: inset, relation: relation)
        return self
    }

    @discardableResult
    public func left(_ inset: CGFloat = 0) -> FWLayoutChain {
        view?.fwPinEdge(toSuperview: .left, withInset: inset)
        return self
    }
    
    @discardableResult
    public func left(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> FWLayoutChain {
        view?.fwPinEdge(toSuperview: .left, withInset: inset, relation: relation)
        return self
    }

    @discardableResult
    public func right(_ inset: CGFloat = 0) -> FWLayoutChain {
        view?.fwPinEdge(toSuperview: .right, withInset: inset)
        return self
    }
    
    @discardableResult
    public func right(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> FWLayoutChain {
        view?.fwPinEdge(toSuperview: .right, withInset: inset, relation: relation)
        return self
    }

    @discardableResult
    public func topToView(_ view: Any, withOffset offset: CGFloat = 0) -> FWLayoutChain {
        self.view?.fwPinEdge(.top, toEdge: .top, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func topToView(_ view: Any, withOffset offset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> FWLayoutChain {
        self.view?.fwPinEdge(.top, toEdge: .top, ofView: view, withOffset: offset, relation: relation)
        return self
    }

    @discardableResult
    public func bottomToView(_ view: Any, withOffset offset: CGFloat = 0) -> FWLayoutChain {
        self.view?.fwPinEdge(.bottom, toEdge: .bottom, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func bottomToView(_ view: Any, withOffset offset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> FWLayoutChain {
        self.view?.fwPinEdge(.bottom, toEdge: .bottom, ofView: view, withOffset: offset, relation: relation)
        return self
    }

    @discardableResult
    public func leftToView(_ view: Any, withOffset offset: CGFloat = 0) -> FWLayoutChain {
        self.view?.fwPinEdge(.left, toEdge: .left, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func leftToView(_ view: Any, withOffset offset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> FWLayoutChain {
        self.view?.fwPinEdge(.left, toEdge: .left, ofView: view, withOffset: offset, relation: relation)
        return self
    }

    @discardableResult
    public func rightToView(_ view: Any, withOffset offset: CGFloat = 0) -> FWLayoutChain {
        self.view?.fwPinEdge(.right, toEdge: .right, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func rightToView(_ view: Any, withOffset offset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> FWLayoutChain {
        self.view?.fwPinEdge(.right, toEdge: .right, ofView: view, withOffset: offset, relation: relation)
        return self
    }

    @discardableResult
    public func topToBottomOfView(_ view: Any, withOffset offset: CGFloat = 0) -> FWLayoutChain {
        self.view?.fwPinEdge(.top, toEdge: .bottom, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func topToBottomOfView(_ view: Any, withOffset offset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> FWLayoutChain {
        self.view?.fwPinEdge(.top, toEdge: .bottom, ofView: view, withOffset: offset, relation: relation)
        return self
    }
    
    @discardableResult
    public func bottomToTopOfView(_ view: Any, withOffset offset: CGFloat = 0) -> FWLayoutChain {
        self.view?.fwPinEdge(.bottom, toEdge: .top, ofView: view, withOffset: offset)
        return self
    }

    @discardableResult
    public func bottomToTopOfView(_ view: Any, withOffset offset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> FWLayoutChain {
        self.view?.fwPinEdge(.bottom, toEdge: .top, ofView: view, withOffset: offset, relation: relation)
        return self
    }

    @discardableResult
    public func leftToRightOfView(_ view: Any, withOffset offset: CGFloat = 0) -> FWLayoutChain {
        self.view?.fwPinEdge(.left, toEdge: .right, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func leftToRightOfView(_ view: Any, withOffset offset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> FWLayoutChain {
        self.view?.fwPinEdge(.left, toEdge: .right, ofView: view, withOffset: offset, relation: relation)
        return self
    }
    
    @discardableResult
    public func rightToLeftOfView(_ view: Any, withOffset offset: CGFloat = 0) -> FWLayoutChain {
        self.view?.fwPinEdge(.right, toEdge: .left, ofView: view, withOffset: offset)
        return self
    }

    @discardableResult
    public func rightToLeftOfView(_ view: Any, withOffset offset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> FWLayoutChain {
        self.view?.fwPinEdge(.right, toEdge: .left, ofView: view, withOffset: offset, relation: relation)
        return self
    }

    // MARK: - SafeArea

    @discardableResult
    public func centerToSafeArea(_ offset: CGPoint = CGPoint.zero) -> FWLayoutChain {
        view?.fwAlignCenterToSuperviewSafeArea(withOffset: offset)
        return self
    }

    @discardableResult
    public func centerXToSafeArea(_ offset: CGFloat = 0) -> FWLayoutChain {
        view?.fwAlignAxis(toSuperviewSafeArea: .centerX, withOffset: offset)
        return self
    }

    @discardableResult
    public func centerYToSafeArea(_ offset: CGFloat = 0) -> FWLayoutChain {
        view?.fwAlignAxis(toSuperviewSafeArea: .centerY, withOffset: offset)
        return self
    }

    @discardableResult
    public func edgesToSafeArea(_ insets: UIEdgeInsets = UIEdgeInsets.zero) -> FWLayoutChain {
        view?.fwPinEdgesToSuperviewSafeArea(with: insets)
        return self
    }
    
    @discardableResult
    public func edgesToSafeArea(_ insets: UIEdgeInsets = UIEdgeInsets.zero, excludingEdge edge: NSLayoutConstraint.Attribute) -> FWLayoutChain {
        view?.fwPinEdgesToSuperviewSafeArea(with: insets, excludingEdge: edge)
        return self
    }

    @discardableResult
    public func edgesToSafeAreaHorizontal() -> FWLayoutChain {
        view?.fwPinEdgesToSuperviewSafeAreaHorizontal()
        return self
    }

    @discardableResult
    public func edgesToSafeAreaVertical() -> FWLayoutChain {
        view?.fwPinEdgesToSuperviewSafeAreaVertical()
        return self
    }

    @discardableResult
    public func topToSafeArea(_ inset: CGFloat = 0) -> FWLayoutChain {
        view?.fwPinEdge(toSuperviewSafeArea: .top, withInset: inset)
        return self
    }
    
    @discardableResult
    public func topToSafeArea(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> FWLayoutChain {
        view?.fwPinEdge(toSuperviewSafeArea: .top, withInset: inset, relation: relation)
        return self
    }
    
    @discardableResult
    public func bottomToSafeArea(_ inset: CGFloat = 0) -> FWLayoutChain {
        view?.fwPinEdge(toSuperviewSafeArea: .bottom, withInset: inset)
        return self
    }

    @discardableResult
    public func bottomToSafeArea(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> FWLayoutChain {
        view?.fwPinEdge(toSuperviewSafeArea: .bottom, withInset: inset, relation: relation)
        return self
    }

    @discardableResult
    public func leftToSafeArea(_ inset: CGFloat = 0) -> FWLayoutChain {
        view?.fwPinEdge(toSuperviewSafeArea: .left, withInset: inset)
        return self
    }
    
    @discardableResult
    public func leftToSafeArea(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> FWLayoutChain {
        view?.fwPinEdge(toSuperviewSafeArea: .left, withInset: inset, relation: relation)
        return self
    }
    
    @discardableResult
    public func rightToSafeArea(_ inset: CGFloat = 0) -> FWLayoutChain {
        view?.fwPinEdge(toSuperviewSafeArea: .right, withInset: inset)
        return self
    }

    @discardableResult
    public func rightToSafeArea(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> FWLayoutChain {
        view?.fwPinEdge(toSuperviewSafeArea: .right, withInset: inset, relation: relation)
        return self
    }

    // MARK: - Dimension

    @discardableResult
    public func size(_ size: CGSize) -> FWLayoutChain {
        view?.fwSetDimensions(to: size)
        return self
    }

    @discardableResult
    public func width(_ width: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        view?.fwSetDimension(.width, toSize: width, relation: relation)
        return self
    }

    @discardableResult
    public func height(_ height: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        view?.fwSetDimension(.height, toSize: height, relation: relation)
        return self
    }
    
    @discardableResult
    public func widthToHeight(_ multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        view?.fwMatchDimension(.width, toDimension: .height, withMultiplier: multiplier, relation: relation)
        return self
    }
    
    @discardableResult
    public func heightToWidth(_ multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        view?.fwMatchDimension(.height, toDimension: .width, withMultiplier: multiplier, relation: relation)
        return self
    }

    @discardableResult
    public func sizeToView(_ view: Any) -> FWLayoutChain {
        self.view?.fwMatchDimension(.width, toDimension: .width, ofView: view)
        self.view?.fwMatchDimension(.height, toDimension: .height, ofView: view)
        return self
    }

    @discardableResult
    public func widthToView(_ view: Any, withOffset offset: CGFloat = 0) -> FWLayoutChain {
        self.view?.fwMatchDimension(.width, toDimension: .width, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func widthToView(_ view: Any, withOffset offset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> FWLayoutChain {
        self.view?.fwMatchDimension(.width, toDimension: .width, ofView: view, withOffset: offset, relation: relation)
        return self
    }
    
    @discardableResult
    public func heightToView(_ view: Any, withOffset offset: CGFloat = 0) -> FWLayoutChain {
        self.view?.fwMatchDimension(.height, toDimension: .height, ofView: view, withOffset: offset)
        return self
    }

    @discardableResult
    public func heightToView(_ view: Any, withOffset offset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> FWLayoutChain {
        self.view?.fwMatchDimension(.height, toDimension: .height, ofView: view, withOffset: offset, relation: relation)
        return self
    }

    @discardableResult
    public func widthToView(_ view: Any, withMultiplier multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwMatchDimension(.width, toDimension: .width, ofView: view, withMultiplier: multiplier, relation: relation)
        return self
    }

    @discardableResult
    public func heightToView(_ view: Any, withMultiplier multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwMatchDimension(.height, toDimension: .height, ofView: view, withMultiplier: multiplier, relation: relation)
        return self
    }

    // MARK: - Attribute

    @discardableResult
    public func attribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, withOffset offset: CGFloat = 0) -> FWLayoutChain {
        self.view?.fwConstrainAttribute(attribute, to: toAttribute, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func attribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, withOffset offset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> FWLayoutChain {
        self.view?.fwConstrainAttribute(attribute, to: toAttribute, ofView: view, withOffset: offset, relation: relation)
        return self
    }

    @discardableResult
    public func attribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, withMultiplier multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwConstrainAttribute(attribute, to: toAttribute, ofView: view, withMultiplier: multiplier, relation: relation)
        return self
    }
    
    // MARK: - Constraint
    
    public var constraint: NSLayoutConstraint? {
        return self.view?.fwLastConstraint
    }
    
    public func constraint(_ attribute: NSLayoutConstraint.Attribute, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> NSLayoutConstraint? {
        return self.view?.fwConstraint(toSuperview: attribute, relation: relation)
    }
    
    public func constraintToSafeArea(_ attribute: NSLayoutConstraint.Attribute, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> NSLayoutConstraint? {
        return self.view?.fwConstraint(toSuperviewSafeArea: attribute, relation: relation)
    }

    public func constraint(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> NSLayoutConstraint? {
        return self.view?.fwConstraint(attribute, to: toAttribute, ofView: view, relation: relation)
    }
    
    public func constraint(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, withMultiplier multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> NSLayoutConstraint? {
        return self.view?.fwConstraint(attribute, to: toAttribute, ofView: view, withMultiplier: multiplier, relation: relation)
    }
}

// MARK: - UIView+FWLayoutChain

/// 视图链式布局扩展
extension UIView {
    /// 关联对象Key
    private struct FWLayoutChainAssociatedKeys {
        static var layoutChainKey = "layoutChainKey"
    }

    /// 链式布局对象
    public var fwLayoutChain: FWLayoutChain {
        var layoutChain = objc_getAssociatedObject(self, &FWLayoutChainAssociatedKeys.layoutChainKey)
        if layoutChain == nil {
            layoutChain = FWLayoutChain(view: self)
            objc_setAssociatedObject(self, &FWLayoutChainAssociatedKeys.layoutChainKey, layoutChain, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        return layoutChain as! FWLayoutChain
    }
    
    /// 链式布局闭包
    public func fwLayoutMaker(_ closure: (_ make: FWLayoutChain) -> Void) {
        closure(fwLayoutChain)
    }
}
