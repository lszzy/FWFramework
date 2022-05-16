//
//  AutoLayout.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/29.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import UIKit
#if FWMacroSPM
import FWFramework
#endif

/// UIView自动布局分类，兼容UIView和UILayoutGuide(iOS9)
/// 如果约束条件完全相同，会自动更新约束而不是重新添加。
/// 另外，默认布局方式使用LTR，如果需要RTL布局，可通过fwAutoLayoutRTL统一启用
extension Wrapper where Base: UIView {
    
    /// 是否启用自动布局适配RTL，启用后自动将Left|Right转换为Leading|Trailing，默认NO
    ///
    /// 如果项目兼容阿拉伯语等，需要启用RTL从右向左布局，开启此开关即可，无需修改布局代码
    /// 手工切换视图左右布局方法：[UIView appearance].semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    public static var autoLayoutRTL: Bool {
        get { return Base.__fw.autoLayoutRTL }
        set { Base.__fw.autoLayoutRTL = newValue }
    }
    
    // MARK: - AutoLayout
    /// 是否启用自动布局
    public var autoLayout: Bool {
        get { return base.__fw.autoLayout }
        set { base.__fw.autoLayout = newValue }
    }

    /// 执行子视图自动布局，自动计算子视图尺寸。需先将视图添加到界面(如设置为tableHeaderView)，再调用即可(iOS8+)
    public func autoLayoutSubviews() {
        base.__fw.autoLayoutSubviews()
    }

    /// 计算动态布局视图指定宽度时的高度。使用AutoLayout必须约束完整，不使用AutoLayout会调用view的sizeThatFits:方法
    public func layoutHeight(width: CGFloat) -> CGFloat {
        return base.__fw.layoutHeight(withWidth: width)
    }

    /// 计算动态布局视图指定高度时的宽度。使用AutoLayout必须约束完整，不使用AutoLayout会调用view的sizeThatFits:方法
    public func layoutWidth(height: CGFloat) -> CGFloat {
        return base.__fw.layoutWidth(withHeight: height)
    }
    
    // MARK: - Compression
    /// 设置水平方向抗压缩优先级
    public var compressionHorizontal: UILayoutPriority {
        get { return base.__fw.compressionHorizontal }
        set { base.__fw.compressionHorizontal = newValue }
    }

    /// 设置垂直方向抗压缩优先级
    public var compressionVertical: UILayoutPriority {
        get { return base.__fw.compressionVertical }
        set { base.__fw.compressionVertical = newValue }
    }

    /// 设置水平方向抗拉伸优先级
    public var huggingHorizontal: UILayoutPriority {
        get { return base.__fw.huggingHorizontal }
        set { base.__fw.huggingHorizontal = newValue }
    }

    /// 设置垂直方向抗拉伸优先级
    public var huggingVertical: UILayoutPriority {
        get { return base.__fw.huggingVertical }
        set { base.__fw.huggingVertical = newValue }
    }
    
    // MARK: - Collapse
    /// 设置视图是否收缩，默认NO，YES时常量值为0，NO时常量值为原始值
    public var collapsed: Bool {
        get { return base.__fw.collapsed }
        set { base.__fw.collapsed = newValue }
    }

    /// 设置视图是否自动收缩，如image为nil，text为nil、@""时自动收缩，默认NO
    public var autoCollapse: Bool {
        get { return base.__fw.autoCollapse }
        set { base.__fw.autoCollapse = newValue }
    }

    /// 设置视图是否隐藏时自动收缩、显示时自动展开，默认NO
    public var hiddenCollapse: Bool {
        get { return base.__fw.hiddenCollapse }
        set { base.__fw.hiddenCollapse = newValue }
    }

    /// 添加视图的收缩常量，必须先添加才能生效
    ///
    /// - see: [UIView-FDCollapsibleConstraints](https://github.com/forkingdog/UIView-FDCollapsibleConstraints)
    public func addCollapse(_ constraint: NSLayoutConstraint) {
        base.__fw.addCollapse(constraint)
    }
    
    // MARK: - Axis
    /// 父视图居中，可指定偏移距离
    /// - Parameter offset: 偏移距离，默认zero
    /// - Returns: 约束数组
    @discardableResult
    public func alignCenter(toSuperview offset: CGPoint = .zero) -> [NSLayoutConstraint] {
        return base.__fw.alignCenterToSuperview(withOffset: offset)
    }
    
    /// 父视图属性居中，可指定偏移距离
    /// - Parameters:
    ///   - axis: 居中属性
    ///   - offset: 偏移距离，默认0
    /// - Returns: 布局约束
    @discardableResult
    public func alignAxis(toSuperview axis: NSLayoutConstraint.Attribute, offset: CGFloat = 0) -> NSLayoutConstraint {
        return base.__fw.alignAxis(toSuperview: axis, withOffset: offset)
    }
    
    /// 与另一视图居中相同，可指定偏移距离
    /// - Parameters:
    ///   - axis: 居中属性
    ///   - toView: 另一视图或UILayoutGuide，下同
    ///   - offset: 偏移距离，默认0
    /// - Returns: 布局约束
    @discardableResult
    public func alignAxis(_ axis: NSLayoutConstraint.Attribute, toView: Any, offset: CGFloat = 0) -> NSLayoutConstraint {
        return base.__fw.alignAxis(axis, toView: toView, withOffset: offset)
    }

    /// 与另一视图居中指定比例
    /// - Parameters:
    ///   - axis: 居中属性
    ///   - toView: 另一视图
    ///   - multiplier: 指定比例
    /// - Returns: 布局约束
    @discardableResult
    public func alignAxis(_ axis: NSLayoutConstraint.Attribute, toView: Any, multiplier: CGFloat) -> NSLayoutConstraint {
        return base.__fw.alignAxis(axis, toView: toView, withMultiplier: multiplier)
    }
    
    // MARK: - Edge
    /// 与父视图四条边属性相同，可指定insets距离
    /// - Parameter insets: 指定距离insets，默认zero
    /// - Returns: 约束数组
    @discardableResult
    public func pinEdges(toSuperview insets: UIEdgeInsets = .zero) -> [NSLayoutConstraint] {
        return base.__fw.pinEdgesToSuperview(with: insets)
    }

    /// 与父视图三条边属性距离指定距离
    /// - Parameters:
    ///   - insets: 指定距离insets
    ///   - excludingEdge: 排除的边
    /// - Returns: 约束数组
    @discardableResult
    public func pinEdges(toSuperview insets: UIEdgeInsets, excludingEdge: NSLayoutConstraint.Attribute) -> [NSLayoutConstraint] {
        return base.__fw.pinEdgesToSuperview(with: insets, excludingEdge: excludingEdge)
    }
    
    /// 与父视图水平方向两条边属性相同，可指定偏移距离
    /// - Parameters:
    ///   - inset: 偏移距离
    /// - Returns: 约束数组
    @discardableResult
    public func pinEdgesHorizontal(toSuperview inset: CGFloat) -> [NSLayoutConstraint] {
        return base.__fw.pinEdgesToSuperviewHorizontal(withInset: inset)
    }
    
    /// 与父视图垂直方向两条边属性相同，可指定偏移距离
    /// - Parameters:
    ///   - inset: 偏移距离
    /// - Returns: 约束数组
    @discardableResult
    public func pinEdgesVertical(toSuperview inset: CGFloat) -> [NSLayoutConstraint] {
        return base.__fw.pinEdgesToSuperviewVertical(withInset: inset)
    }
    
    /// 与父视图边属性相同，可指定偏移距离和关系
    /// - Parameters:
    ///   - edge: 指定边属性
    ///   - inset: 偏移距离，默认0
    ///   - relation: 约束关系，默认相等
    /// - Returns: 布局约束
    @discardableResult
    public func pinEdge(toSuperview edge: NSLayoutConstraint.Attribute, inset: CGFloat = .zero, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        return base.__fw.pinEdge(toSuperview: edge, withInset: inset, relation: relation)
    }

    /// 与指定视图边属性相同，可指定偏移距离和关系
    /// - Parameters:
    ///   - edge: 指定边属性
    ///   - toEdge: 另一视图边属性
    ///   - ofView: 另一视图
    ///   - offset: 偏移距离，默认0
    ///   - relation: 约束关系，默认相等
    /// - Returns: 布局约束
    @discardableResult
    public func pinEdge(_ edge: NSLayoutConstraint.Attribute, toEdge: NSLayoutConstraint.Attribute, ofView: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        return base.__fw.pinEdge(edge, toEdge: toEdge, ofView: ofView, withOffset: offset, relation: relation)
    }
    
    // MARK: - SafeArea
    /// 父视图安全区域居中，可指定偏移距离。iOS11以下使用Superview实现，下同
    /// - Parameter offset: 偏移距离
    /// - Returns: 约束数组
    @discardableResult
    public func alignCenter(toSafeArea offset: CGPoint) -> [NSLayoutConstraint] {
        return base.__fw.alignCenterToSuperviewSafeArea(withOffset: offset)
    }
    
    /// 父视图安全区域属性居中，可指定偏移距离
    /// - Parameters:
    ///   - axis: 居中属性
    ///   - offset: 偏移距离，默认0
    /// - Returns: 布局约束
    @discardableResult
    public func alignAxis(toSafeArea axis: NSLayoutConstraint.Attribute, offset: CGFloat = .zero) -> NSLayoutConstraint {
        return base.__fw.alignAxis(toSuperviewSafeArea: axis, withOffset: offset)
    }

    /// 与父视图安全区域四条边属性相同，可指定距离insets
    /// - Parameter insets: 指定距离insets
    /// - Returns: 约束数组
    @discardableResult
    public func pinEdges(toSafeArea insets: UIEdgeInsets) -> [NSLayoutConstraint] {
        return base.__fw.pinEdgesToSuperviewSafeArea(with: insets)
    }

    /// 与父视图安全区域三条边属性距离指定距离
    /// - Parameters:
    ///   - insets: 指定距离insets
    ///   - excludingEdge: 排除的边
    /// - Returns: 约束数组
    @discardableResult
    public func pinEdges(toSafeArea insets: UIEdgeInsets, excludingEdge: NSLayoutConstraint.Attribute) -> [NSLayoutConstraint] {
        return base.__fw.pinEdgesToSuperviewSafeArea(with: insets, excludingEdge: excludingEdge)
    }

    /// 与父视图安全区域水平方向两条边属性相同，可指定偏移距离
    /// - Parameters:
    ///   - inset: 偏移距离
    /// - Returns: 约束数组
    @discardableResult
    public func pinEdgesHorizontal(toSafeArea inset: CGFloat) -> [NSLayoutConstraint] {
        return base.__fw.pinEdgesToSuperviewSafeAreaHorizontal(withInset: inset)
    }
    
    /// 与父视图安全区域垂直方向两条边属性相同，可指定偏移距离
    /// - Parameters:
    ///   - inset: 偏移距离
    /// - Returns: 约束数组
    @discardableResult
    public func pinEdgesVertical(toSafeArea inset: CGFloat) -> [NSLayoutConstraint] {
        return base.__fw.pinEdgesToSuperviewSafeAreaVertical(withInset: inset)
    }
    
    /// 与父视图安全区域边属性相同，可指定偏移距离和关系
    /// - Parameters:
    ///   - edge: 指定边属性
    ///   - inset: 偏移距离，默认0
    ///   - relation: 约束关系，默认相等
    /// - Returns: 布局约束
    @discardableResult
    public func pinEdge(toSafeArea edge: NSLayoutConstraint.Attribute, inset: CGFloat = .zero, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        return base.__fw.pinEdge(toSuperviewSafeArea: edge, withInset: inset, relation: relation)
    }
    
}

// MARK: - LayoutChain
/// 视图链式布局类。如果约束条件完全相同，会自动更新约束而不是重新添加。
/// 另外，默认布局方式使用LTR，如果需要RTL布局，可通过autoLayoutRTL统一启用
public class LayoutChain {
    
    // MARK: - Accessor
    /// 布局视图
    public private(set) weak var view: UIView?
    
    /// 关联对象Key
    fileprivate struct AssociatedKeys {
        static var layoutChain = "layoutChain"
    }

    // MARK: - Lifecycle
    /// 构造方法
    public required init(view: UIView?) {
        self.view = view
    }

    // MARK: - Install
    @discardableResult
    public func remake() -> Self {
        view?.__fw.removeAllConstraints()
        return self
    }

    // MARK: - Compression
    @discardableResult
    public func compressionHorizontal(_ priority: UILayoutPriority) -> Self {
        view?.__fw.compressionHorizontal = priority
        return self
    }

    @discardableResult
    public func compressionVertical(_ priority: UILayoutPriority) -> Self {
        view?.__fw.compressionVertical = priority
        return self
    }
    
    @discardableResult
    public func huggingHorizontal(_ priority: UILayoutPriority) -> Self {
        view?.__fw.huggingHorizontal = priority
        return self
    }

    @discardableResult
    public func huggingVertical(_ priority: UILayoutPriority) -> Self {
        view?.__fw.huggingVertical = priority
        return self
    }
    
    // MARK: - Collapse
    @discardableResult
    public func collapsed(_ collapsed: Bool) -> Self {
        view?.__fw.collapsed = collapsed
        return self
    }

    @discardableResult
    public func autoCollapse(_ autoCollapse: Bool) -> Self {
        view?.__fw.autoCollapse = autoCollapse
        return self
    }
    
    @discardableResult
    public func hiddenCollapse(_ hiddenCollapse: Bool) -> Self {
        view?.__fw.hiddenCollapse = hiddenCollapse
        return self
    }

    // MARK: - Axis
    @discardableResult
    public func center(_ offset: CGPoint = .zero) -> Self {
        view?.__fw.alignCenterToSuperview(withOffset: offset)
        return self
    }

    @discardableResult
    public func centerX(_ offset: CGFloat = .zero) -> Self {
        view?.__fw.alignAxis(toSuperview: .centerX, withOffset: offset)
        return self
    }

    @discardableResult
    public func centerY(_ offset: CGFloat = .zero) -> Self {
        view?.__fw.alignAxis(toSuperview: .centerY, withOffset: offset)
        return self
    }

    @discardableResult
    public func center(toView view: Any) -> Self {
        self.view?.__fw.alignAxis(.centerX, toView: view)
        self.view?.__fw.alignAxis(.centerY, toView: view)
        return self
    }

    @discardableResult
    public func centerX(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw.alignAxis(.centerX, toView: view, withOffset: offset)
        return self
    }

    @discardableResult
    public func centerY(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw.alignAxis(.centerY, toView: view, withOffset: offset)
        return self
    }

    @discardableResult
    public func centerX(toView view: Any, multiplier: CGFloat) -> Self {
        self.view?.__fw.alignAxis(.centerX, toView: view, withMultiplier: multiplier)
        return self
    }

    @discardableResult
    public func centerY(toView view: Any, multiplier: CGFloat) -> Self {
        self.view?.__fw.alignAxis(.centerY, toView: view, withMultiplier: multiplier)
        return self
    }

    // MARK: - Edge
    @discardableResult
    public func edges(_ insets: UIEdgeInsets = UIEdgeInsets.zero) -> Self {
        view?.__fw.pinEdgesToSuperview(with: insets)
        return self
    }
    
    @discardableResult
    public func edges(_ insets: UIEdgeInsets = UIEdgeInsets.zero, excludingEdge edge: NSLayoutConstraint.Attribute) -> Self {
        view?.__fw.pinEdgesToSuperview(with: insets, excludingEdge: edge)
        return self
    }

    @discardableResult
    public func edgesHorizontal(_ inset: CGFloat = .zero) -> Self {
        view?.__fw.pinEdgesToSuperviewHorizontal(withInset: inset)
        return self
    }

    @discardableResult
    public func edgesVertical(_ inset: CGFloat = .zero) -> Self {
        view?.__fw.pinEdgesToSuperviewVertical(withInset: inset)
        return self
    }

    @discardableResult
    public func top(_ inset: CGFloat = 0) -> Self {
        view?.__fw.pinEdge(toSuperview: .top, withInset: inset)
        return self
    }
    
    @discardableResult
    public func top(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> Self {
        view?.__fw.pinEdge(toSuperview: .top, withInset: inset, relation: relation)
        return self
    }

    @discardableResult
    public func bottom(_ inset: CGFloat = 0) -> Self {
        view?.__fw.pinEdge(toSuperview: .bottom, withInset: inset)
        return self
    }
    
    @discardableResult
    public func bottom(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> Self {
        view?.__fw.pinEdge(toSuperview: .bottom, withInset: inset, relation: relation)
        return self
    }

    @discardableResult
    public func left(_ inset: CGFloat = 0) -> Self {
        view?.__fw.pinEdge(toSuperview: .left, withInset: inset)
        return self
    }
    
    @discardableResult
    public func left(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> Self {
        view?.__fw.pinEdge(toSuperview: .left, withInset: inset, relation: relation)
        return self
    }

    @discardableResult
    public func right(_ inset: CGFloat = 0) -> Self {
        view?.__fw.pinEdge(toSuperview: .right, withInset: inset)
        return self
    }
    
    @discardableResult
    public func right(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> Self {
        view?.__fw.pinEdge(toSuperview: .right, withInset: inset, relation: relation)
        return self
    }

    @discardableResult
    public func top(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw.pinEdge(.top, toEdge: .top, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func top(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> Self {
        self.view?.__fw.pinEdge(.top, toEdge: .top, ofView: view, withOffset: offset, relation: relation)
        return self
    }

    @discardableResult
    public func bottom(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw.pinEdge(.bottom, toEdge: .bottom, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func bottom(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> Self {
        self.view?.__fw.pinEdge(.bottom, toEdge: .bottom, ofView: view, withOffset: offset, relation: relation)
        return self
    }

    @discardableResult
    public func left(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw.pinEdge(.left, toEdge: .left, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func left(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> Self {
        self.view?.__fw.pinEdge(.left, toEdge: .left, ofView: view, withOffset: offset, relation: relation)
        return self
    }

    @discardableResult
    public func right(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw.pinEdge(.right, toEdge: .right, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func right(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> Self {
        self.view?.__fw.pinEdge(.right, toEdge: .right, ofView: view, withOffset: offset, relation: relation)
        return self
    }

    @discardableResult
    public func topToBottom(ofView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw.pinEdge(.top, toEdge: .bottom, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func topToBottom(ofView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> Self {
        self.view?.__fw.pinEdge(.top, toEdge: .bottom, ofView: view, withOffset: offset, relation: relation)
        return self
    }
    
    @discardableResult
    public func bottomToTop(ofView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw.pinEdge(.bottom, toEdge: .top, ofView: view, withOffset: offset)
        return self
    }

    @discardableResult
    public func bottomToTop(ofView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> Self {
        self.view?.__fw.pinEdge(.bottom, toEdge: .top, ofView: view, withOffset: offset, relation: relation)
        return self
    }

    @discardableResult
    public func leftToRight(ofView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw.pinEdge(.left, toEdge: .right, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func leftToRight(ofView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> Self {
        self.view?.__fw.pinEdge(.left, toEdge: .right, ofView: view, withOffset: offset, relation: relation)
        return self
    }
    
    @discardableResult
    public func rightToLeft(ofView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw.pinEdge(.right, toEdge: .left, ofView: view, withOffset: offset)
        return self
    }

    @discardableResult
    public func rightToLeft(ofView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> Self {
        self.view?.__fw.pinEdge(.right, toEdge: .left, ofView: view, withOffset: offset, relation: relation)
        return self
    }

    // MARK: - SafeArea
    @discardableResult
    public func center(toSafeArea offset: CGPoint) -> Self {
        view?.__fw.alignCenterToSuperviewSafeArea(withOffset: offset)
        return self
    }

    @discardableResult
    public func centerX(toSafeArea offset: CGFloat) -> Self {
        view?.__fw.alignAxis(toSuperviewSafeArea: .centerX, withOffset: offset)
        return self
    }

    @discardableResult
    public func centerY(toSafeArea offset: CGFloat) -> Self {
        view?.__fw.alignAxis(toSuperviewSafeArea: .centerY, withOffset: offset)
        return self
    }

    @discardableResult
    public func edges(toSafeArea insets: UIEdgeInsets) -> Self {
        view?.__fw.pinEdgesToSuperviewSafeArea(with: insets)
        return self
    }
    
    @discardableResult
    public func edges(toSafeArea insets: UIEdgeInsets = UIEdgeInsets.zero, excludingEdge edge: NSLayoutConstraint.Attribute) -> Self {
        view?.__fw.pinEdgesToSuperviewSafeArea(with: insets, excludingEdge: edge)
        return self
    }

    @discardableResult
    public func edgesHorizontal(toSafeArea inset: CGFloat) -> Self {
        view?.__fw.pinEdgesToSuperviewSafeAreaHorizontal(withInset: inset)
        return self
    }

    @discardableResult
    public func edgesVertical(toSafeArea inset: CGFloat) -> Self {
        view?.__fw.pinEdgesToSuperviewSafeAreaVertical(withInset: inset)
        return self
    }

    @discardableResult
    public func top(toSafeArea inset: CGFloat) -> Self {
        view?.__fw.pinEdge(toSuperviewSafeArea: .top, withInset: inset)
        return self
    }
    
    @discardableResult
    public func top(toSafeArea inset: CGFloat, relation: NSLayoutConstraint.Relation) -> Self {
        view?.__fw.pinEdge(toSuperviewSafeArea: .top, withInset: inset, relation: relation)
        return self
    }
    
    @discardableResult
    public func bottom(toSafeArea inset: CGFloat) -> Self {
        view?.__fw.pinEdge(toSuperviewSafeArea: .bottom, withInset: inset)
        return self
    }

    @discardableResult
    public func bottom(toSafeArea inset: CGFloat, relation: NSLayoutConstraint.Relation) -> Self {
        view?.__fw.pinEdge(toSuperviewSafeArea: .bottom, withInset: inset, relation: relation)
        return self
    }

    @discardableResult
    public func left(toSafeArea inset: CGFloat) -> Self {
        view?.__fw.pinEdge(toSuperviewSafeArea: .left, withInset: inset)
        return self
    }
    
    @discardableResult
    public func left(toSafeArea inset: CGFloat, relation: NSLayoutConstraint.Relation) -> Self {
        view?.__fw.pinEdge(toSuperviewSafeArea: .left, withInset: inset, relation: relation)
        return self
    }
    
    @discardableResult
    public func right(toSafeArea inset: CGFloat) -> Self {
        view?.__fw.pinEdge(toSuperviewSafeArea: .right, withInset: inset)
        return self
    }

    @discardableResult
    public func right(toSafeArea inset: CGFloat, relation: NSLayoutConstraint.Relation) -> Self {
        view?.__fw.pinEdge(toSuperviewSafeArea: .right, withInset: inset, relation: relation)
        return self
    }

    // MARK: - Dimension
    @discardableResult
    public func size(_ size: CGSize) -> Self {
        view?.__fw.setDimensionsTo(size)
        return self
    }

    @discardableResult
    public func width(_ width: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> Self {
        view?.__fw.setDimension(.width, toSize: width, relation: relation)
        return self
    }

    @discardableResult
    public func height(_ height: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> Self {
        view?.__fw.setDimension(.height, toSize: height, relation: relation)
        return self
    }
    
    @discardableResult
    public func widthToHeight(_ multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> Self {
        view?.__fw.matchDimension(.width, toDimension: .height, withMultiplier: multiplier, relation: relation)
        return self
    }
    
    @discardableResult
    public func heightToWidth(_ multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> Self {
        view?.__fw.matchDimension(.height, toDimension: .width, withMultiplier: multiplier, relation: relation)
        return self
    }

    @discardableResult
    public func size(toView view: Any) -> Self {
        self.view?.__fw.matchDimension(.width, toDimension: .width, ofView: view)
        self.view?.__fw.matchDimension(.height, toDimension: .height, ofView: view)
        return self
    }

    @discardableResult
    public func width(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw.matchDimension(.width, toDimension: .width, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func width(toView view: Any, offset: CGFloat, relation: NSLayoutConstraint.Relation) -> Self {
        self.view?.__fw.matchDimension(.width, toDimension: .width, ofView: view, withOffset: offset, relation: relation)
        return self
    }
    
    @discardableResult
    public func height(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw.matchDimension(.height, toDimension: .height, ofView: view, withOffset: offset)
        return self
    }

    @discardableResult
    public func height(toView view: Any, offset: CGFloat, relation: NSLayoutConstraint.Relation) -> Self {
        self.view?.__fw.matchDimension(.height, toDimension: .height, ofView: view, withOffset: offset, relation: relation)
        return self
    }

    @discardableResult
    public func width(toView view: Any, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> Self {
        self.view?.__fw.matchDimension(.width, toDimension: .width, ofView: view, withMultiplier: multiplier, relation: relation)
        return self
    }

    @discardableResult
    public func height(toView view: Any, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> Self {
        self.view?.__fw.matchDimension(.height, toDimension: .height, ofView: view, withMultiplier: multiplier, relation: relation)
        return self
    }

    // MARK: - Attribute
    @discardableResult
    public func attribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, offset: CGFloat = 0) -> Self {
        self.view?.__fw.constrainAttribute(attribute, to: toAttribute, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func attribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, offset: CGFloat, relation: NSLayoutConstraint.Relation) -> Self {
        self.view?.__fw.constrainAttribute(attribute, to: toAttribute, ofView: view, withOffset: offset, relation: relation)
        return self
    }

    @discardableResult
    public func attribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> Self {
        self.view?.__fw.constrainAttribute(attribute, to: toAttribute, ofView: view, withMultiplier: multiplier, relation: relation)
        return self
    }
    
    // MARK: - Constraint
    public var constraint: NSLayoutConstraint? {
        return self.view?.__fw.lastConstraint
    }
    
    public func constraint(_ attribute: NSLayoutConstraint.Attribute, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> NSLayoutConstraint? {
        return self.view?.__fw.constraint(toSuperview: attribute, relation: relation)
    }
    
    public func constraint(toSafeArea attribute: NSLayoutConstraint.Attribute, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> NSLayoutConstraint? {
        return self.view?.__fw.constraint(toSuperviewSafeArea: attribute, relation: relation)
    }

    public func constraint(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> NSLayoutConstraint? {
        return self.view?.__fw.constraint(attribute, to: toAttribute, ofView: view, relation: relation)
    }
    
    public func constraint(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> NSLayoutConstraint? {
        return self.view?.__fw.constraint(attribute, to: toAttribute, ofView: view, withMultiplier: multiplier, relation: relation)
    }
    
}

// MARK: - Wrapper+LayoutChain
extension Wrapper where Base: UIView {

    /// 链式布局对象
    public var layoutChain: LayoutChain {
        if let layoutChain = objc_getAssociatedObject(base, &LayoutChain.AssociatedKeys.layoutChain) as? LayoutChain {
            return layoutChain
        }
        
        let layoutChain = LayoutChain(view: base)
        objc_setAssociatedObject(base, &LayoutChain.AssociatedKeys.layoutChain, layoutChain, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return layoutChain
    }
    
    /// 链式布局闭包
    public func layoutMaker(_ closure: (_ make: LayoutChain) -> Void) {
        closure(layoutChain)
    }
    
}
