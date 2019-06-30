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
    public func edges(with insets: UIEdgeInsets = UIEdgeInsets.zero, excludingEdge edge: NSLayoutConstraint.Attribute = NSLayoutConstraint.Attribute.notAnAttribute) -> FWLayoutChain {
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
    public func top(with inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwPinEdge(toSuperview: .top, withInset: inset, relation: relation)
        return self
    }
    
    @discardableResult
    public func bottom(with inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwPinEdge(toSuperview: .bottom, withInset: inset, relation: relation)
        return self
    }
    
    @discardableResult
    public func left(with inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
        self.view?.fwPinEdge(toSuperview: .left, withInset: inset, relation: relation)
        return self
    }
    
    @discardableResult
    public func right(with inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> FWLayoutChain {
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
    public func edgesToSafeArea(with insets: UIEdgeInsets = UIEdgeInsets.zero, excludingEdge edge: NSLayoutConstraint.Attribute = NSLayoutConstraint.Attribute.notAnAttribute) -> FWLayoutChain {
        if (edge == .notAnAttribute) {
            self.view?.fwPinEdgesToSuperviewSafeArea(with: insets)
        } else {
            self.view?.fwPinEdgesToSuperviewSafeArea(with: insets, excludingEdge: edge)
        }
        return self
    }
    
    /*
     
     - (id<FWLayoutChainProtocol> (^)(void))edgesToSafeAreaHorizontal
     {
     return ^id(void) {
     [self.view fwPinEdgesToSuperviewSafeAreaHorizontal];
     return self;
     };
     }
     
     - (id<FWLayoutChainProtocol> (^)(void))edgesToSafeAreaVertical
     {
     return ^id(void) {
     [self.view fwPinEdgesToSuperviewSafeAreaVertical];
     return self;
     };
     }
     
     - (id<FWLayoutChainProtocol> (^)(void))topToSafeArea
     {
     return ^id(void) {
     [self.view fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeTop];
     return self;
     };
     }
     
     - (id<FWLayoutChainProtocol> (^)(void))bottomToSafeArea
     {
     return ^id(void) {
     [self.view fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeBottom];
     return self;
     };
     }
     
     - (id<FWLayoutChainProtocol> (^)(void))leftToSafeArea
     {
     return ^id(void) {
     [self.view fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeLeft];
     return self;
     };
     }
     
     - (id<FWLayoutChainProtocol> (^)(void))rightToSafeArea
     {
     return ^id(void) {
     [self.view fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeRight];
     return self;
     };
     }
     
     - (id<FWLayoutChainProtocol> (^)(CGFloat))topToSafeAreaWithInset
     {
     return ^id(CGFloat inset) {
     [self.view fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeTop withInset:inset];
     return self;
     };
     }
     
     - (id<FWLayoutChainProtocol> (^)(CGFloat))bottomToSafeAreaWithInset
     {
     return ^id(CGFloat inset) {
     [self.view fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeBottom withInset:inset];
     return self;
     };
     }
     
     - (id<FWLayoutChainProtocol> (^)(CGFloat))leftToSafeAreaWithInset
     {
     return ^id(CGFloat inset) {
     [self.view fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeLeft withInset:inset];
     return self;
     };
     }
     
     - (id<FWLayoutChainProtocol> (^)(CGFloat))rightToSafeAreaWithInset
     {
     return ^id(CGFloat inset) {
     [self.view fwPinEdgeToSuperviewSafeArea:NSLayoutAttributeRight withInset:inset];
     return self;
     };
     }
     
     #pragma mark - Dimension
     
     - (id<FWLayoutChainProtocol> (^)(CGSize))size
     {
     return ^id(CGSize size) {
     [self.view fwSetDimensionsToSize:size];
     return self;
     };
     }
     
     - (id<FWLayoutChainProtocol> (^)(CGFloat))width
     {
     return ^id(CGFloat width) {
     [self.view fwSetDimension:NSLayoutAttributeWidth toSize:width];
     return self;
     };
     }
     
     - (id<FWLayoutChainProtocol> (^)(CGFloat))height
     {
     return ^id(CGFloat height) {
     [self.view fwSetDimension:NSLayoutAttributeHeight toSize:height];
     return self;
     };
     }
     
     - (id<FWLayoutChainProtocol> (^)(id))sizeToView
     {
     return ^id(id view) {
     [self.view fwMatchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:view];
     [self.view fwMatchDimension:NSLayoutAttributeHeight toDimension:NSLayoutAttributeHeight ofView:view];
     return self;
     };
     }
     
     - (id<FWLayoutChainProtocol> (^)(id))widthToView
     {
     return ^id(id view) {
     [self.view fwMatchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:view];
     return self;
     };
     }
     
     - (id<FWLayoutChainProtocol> (^)(id))heightToView
     {
     return ^id(id view) {
     [self.view fwMatchDimension:NSLayoutAttributeHeight toDimension:NSLayoutAttributeHeight ofView:view];
     return self;
     };
     }
     
     - (id<FWLayoutChainProtocol> (^)(id, CGFloat))widthToViewWithOffset
     {
     return ^id(id view, CGFloat offset) {
     [self.view fwMatchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:view withOffset:offset];
     return self;
     };
     }
     
     - (id<FWLayoutChainProtocol> (^)(id, CGFloat))heightToViewWithOffset
     {
     return ^id(id view, CGFloat offset) {
     [self.view fwMatchDimension:NSLayoutAttributeHeight toDimension:NSLayoutAttributeHeight ofView:view withOffset:offset];
     return self;
     };
     }
     
     - (id<FWLayoutChainProtocol> (^)(id, CGFloat))widthToViewWithMultiplier
     {
     return ^id(id view, CGFloat multiplier) {
     [self.view fwMatchDimension:NSLayoutAttributeWidth toDimension:NSLayoutAttributeWidth ofView:view withMultiplier:multiplier];
     return self;
     };
     }
     
     - (id<FWLayoutChainProtocol> (^)(id, CGFloat))heightToViewWithMultiplier
     {
     return ^id(id view, CGFloat multiplier) {
     [self.view fwMatchDimension:NSLayoutAttributeHeight toDimension:NSLayoutAttributeHeight ofView:view withMultiplier:multiplier];
     return self;
     };
     }
     
     #pragma mark - Attribute
     
     - (id<FWLayoutChainProtocol> (^)(NSLayoutAttribute, NSLayoutAttribute, id))attribute
     {
     return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView) {
     [self.view fwConstrainAttribute:attribute toAttribute:toAttribute ofView:ofView];
     return self;
     };
     }
     
     - (id<FWLayoutChainProtocol> (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat))attributeWithOffset
     {
     return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat offset) {
     [self.view fwConstrainAttribute:attribute toAttribute:toAttribute ofView:ofView withOffset:offset];
     return self;
     };
     }
     
     - (id<FWLayoutChainProtocol> (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat, NSLayoutRelation))attributeWithOffsetAndRelation
     {
     return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat offset, NSLayoutRelation relation) {
     [self.view fwConstrainAttribute:attribute toAttribute:toAttribute ofView:ofView withOffset:offset relation:relation];
     return self;
     };
     }
     
     - (id<FWLayoutChainProtocol> (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat))attributeWithMultiplier
     {
     return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat multiplier) {
     [self.view fwConstrainAttribute:attribute toAttribute:toAttribute ofView:ofView withMultiplier:multiplier];
     return self;
     };
     }
     
     - (id<FWLayoutChainProtocol> (^)(NSLayoutAttribute, NSLayoutAttribute, id, CGFloat, NSLayoutRelation))attributeWithMultiplierAndRelation
     {
     return ^id(NSLayoutAttribute attribute, NSLayoutAttribute toAttribute, id ofView, CGFloat multiplier, NSLayoutRelation relation) {
     [self.view fwConstrainAttribute:attribute toAttribute:toAttribute ofView:ofView withMultiplier:multiplier relation:relation];
     return self;
     };
     }
 */
    
    @discardableResult
    public func top(_ inset: CGFloat = 0) -> FWLayoutChain {
        self.view?.fwPinEdge(toSuperview: .top, withInset: inset)
        return self
    }
    
    @discardableResult
    public func centerX(toView view: UIView) -> FWLayoutChain {
        self.view?.fwAlignAxis(.centerX, toView: view)
        return self
    }
    
    @discardableResult
    public func size(_ size: CGSize) -> FWLayoutChain {
        self.view?.fwSetDimensions(to: size)
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
