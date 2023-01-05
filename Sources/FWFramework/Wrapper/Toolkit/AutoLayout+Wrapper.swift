//
//  AutoLayout+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

// MARK: - UIView+AutoLayout
/// UIView自动布局分类，兼容UIView和UILayoutGuide(iOS9)
/// 如果约束条件完全相同，会自动更新约束而不是重新添加。
/// 另外，默认布局方式使用LTR，如果需要RTL布局，可通过fwAutoLayoutRTL统一启用
extension Wrapper where Base: UIView {
    
    /// 是否启用自动布局适配RTL，启用后自动将Left|Right转换为Leading|Trailing，默认NO
    ///
    /// 如果项目兼容阿拉伯语等，需要启用RTL从右向左布局，开启此开关即可，无需修改布局代码
    /// 手工切换视图左右布局方法：[UIView appearance].semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    public static var autoLayoutRTL: Bool {
        get { return UIView.fw_autoLayoutRTL }
        set { UIView.fw_autoLayoutRTL = newValue }
    }
    
    /// 是否全局自动等比例缩放布局，默认NO
    ///
    /// 启用后所有offset值都会自动*relativeScale，注意可能产生的影响。
    /// 启用后注意事项：
    /// 1. 屏幕宽度约束不能使用screenWidth约束，需要使用375设计标准
    /// 2. 尽量不使用screenWidth固定屏幕宽度方式布局，推荐相对于父视图布局
    /// 2. 只会对offset值生效，其他属性不受影响
    /// 3. 如需特殊处理，可以指定某个视图关闭该功能
    public static var autoScale: Bool {
        get { return UIView.fw_autoScale }
        set { UIView.fw_autoScale = newValue }
    }
    
    // MARK: - AutoLayout
    /// 视图是否自动等比例缩放布局，默认依次查找当前视图及其父视图，都未设置时返回全局开关
    public var autoScale: Bool {
        get { base.fw_autoScale }
        set { base.fw_autoScale = newValue }
    }

    /// 执行子视图自动布局，自动计算子视图尺寸。需先将视图添加到界面(如设置为tableHeaderView)，再调用即可(iOS8+)
    public func autoLayoutSubviews() {
        base.fw_autoLayoutSubviews()
    }

    /// 计算动态布局视图指定宽度时的高度。使用AutoLayout必须约束完整，不使用AutoLayout会调用view的sizeThatFits:方法
    public func layoutHeight(width: CGFloat) -> CGFloat {
        return base.fw_layoutHeight(width: width)
    }

    /// 计算动态布局视图指定高度时的宽度。使用AutoLayout必须约束完整，不使用AutoLayout会调用view的sizeThatFits:方法
    public func layoutWidth(height: CGFloat) -> CGFloat {
        return base.fw_layoutWidth(height: height)
    }
    
    // MARK: - Compression
    /// 设置水平方向抗压缩优先级
    public var compressionHorizontal: UILayoutPriority {
        get { base.fw_compressionHorizontal }
        set { base.fw_compressionHorizontal = newValue }
    }

    /// 设置垂直方向抗压缩优先级
    public var compressionVertical: UILayoutPriority {
        get { base.fw_compressionVertical }
        set { base.fw_compressionVertical = newValue }
    }

    /// 设置水平方向抗拉伸优先级
    public var huggingHorizontal: UILayoutPriority {
        get { base.fw_huggingHorizontal }
        set { base.fw_huggingHorizontal = newValue }
    }

    /// 设置垂直方向抗拉伸优先级
    public var huggingVertical: UILayoutPriority {
        get { base.fw_huggingVertical }
        set { base.fw_huggingVertical = newValue }
    }
    
    // MARK: - Collapse
    /// 设置视图是否收缩，默认NO，YES时常量值为0，NO时常量值为原始值
    public var collapsed: Bool {
        get { base.fw_collapsed }
        set { base.fw_collapsed = newValue }
    }

    /// 设置视图是否自动收缩，如image为nil，text为nil、@""时自动收缩，默认NO
    public var autoCollapse: Bool {
        get { base.fw_autoCollapse }
        set { base.fw_autoCollapse = newValue }
    }

    /// 设置视图是否隐藏时自动收缩、显示时自动展开，默认NO
    public var hiddenCollapse: Bool {
        get { base.fw_hiddenCollapse }
        set { base.fw_hiddenCollapse = newValue }
    }

    /// 添加视图的收缩常量，必须先添加才能生效
    ///
    /// - see: [UIView-FDCollapsibleConstraints](https://github.com/forkingdog/UIView-FDCollapsibleConstraints)
    public func addCollapseConstraint(_ constraint: NSLayoutConstraint) {
        base.fw_addCollapseConstraint(constraint)
    }
    
    // MARK: - Axis
    /// 父视图居中，可指定偏移距离
    /// - Parameter offset: 偏移距离，默认zero
    /// - Returns: 约束数组
    @discardableResult
    public func alignCenter(toSuperview offset: CGPoint = .zero) -> [NSLayoutConstraint] {
        return base.fw_alignCenter(toSuperview: offset)
    }
    
    /// 父视图属性居中，可指定偏移距离
    /// - Parameters:
    ///   - axis: 居中属性
    ///   - offset: 偏移距离，默认0
    /// - Returns: 布局约束
    @discardableResult
    public func alignAxis(toSuperview axis: NSLayoutConstraint.Attribute, offset: CGFloat = 0) -> NSLayoutConstraint {
        return base.fw_alignAxis(toSuperview: axis, offset: offset)
    }
    
    /// 与另一视图居中相同，可指定偏移距离
    /// - Parameters:
    ///   - axis: 居中属性
    ///   - toView: 另一视图或UILayoutGuide，下同
    ///   - offset: 偏移距离，默认0
    /// - Returns: 布局约束
    @discardableResult
    public func alignAxis(_ axis: NSLayoutConstraint.Attribute, toView: Any, offset: CGFloat = 0) -> NSLayoutConstraint {
        return base.fw_alignAxis(axis, toView: toView, offset: offset)
    }

    /// 与另一视图居中指定比例
    /// - Parameters:
    ///   - axis: 居中属性
    ///   - toView: 另一视图
    ///   - multiplier: 指定比例
    /// - Returns: 布局约束
    @discardableResult
    public func alignAxis(_ axis: NSLayoutConstraint.Attribute, toView: Any, multiplier: CGFloat) -> NSLayoutConstraint {
        return base.fw_alignAxis(axis, toView: toView, multiplier: multiplier)
    }
    
    // MARK: - Edge
    /// 与父视图四条边属性相同，可指定insets距离
    /// - Parameter insets: 指定距离insets，默认zero
    /// - Returns: 约束数组
    @discardableResult
    public func pinEdges(toSuperview insets: UIEdgeInsets = .zero) -> [NSLayoutConstraint] {
        return base.fw_pinEdges(toSuperview: insets)
    }

    /// 与父视图三条边属性距离指定距离
    /// - Parameters:
    ///   - insets: 指定距离insets
    ///   - excludingEdge: 排除的边
    /// - Returns: 约束数组
    @discardableResult
    public func pinEdges(toSuperview insets: UIEdgeInsets = .zero, excludingEdge: NSLayoutConstraint.Attribute) -> [NSLayoutConstraint] {
        return base.fw_pinEdges(toSuperview: insets, excludingEdge: excludingEdge)
    }
    
    /// 与父视图水平方向两条边属性相同，可指定偏移距离
    /// - Parameters:
    ///   - inset: 偏移距离
    /// - Returns: 约束数组
    @discardableResult
    public func pinHorizontal(toSuperview inset: CGFloat = .zero) -> [NSLayoutConstraint] {
        return base.fw_pinHorizontal(toSuperview: inset)
    }
    
    /// 与父视图垂直方向两条边属性相同，可指定偏移距离
    /// - Parameters:
    ///   - inset: 偏移距离
    /// - Returns: 约束数组
    @discardableResult
    public func pinVertical(toSuperview inset: CGFloat = .zero) -> [NSLayoutConstraint] {
        return base.fw_pinVertical(toSuperview: inset)
    }
    
    /// 与父视图边属性相同，可指定偏移距离和关系
    /// - Parameters:
    ///   - edge: 指定边属性
    ///   - inset: 偏移距离，默认0
    ///   - relation: 约束关系，默认相等
    ///   - priority: 约束优先级，默认required
    /// - Returns: 布局约束
    @discardableResult
    public func pinEdge(toSuperview edge: NSLayoutConstraint.Attribute, inset: CGFloat = .zero, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
        return base.fw_pinEdge(toSuperview: edge, inset: inset, relation: relation, priority: priority)
    }

    /// 与指定视图边属性相同，可指定偏移距离和关系
    /// - Parameters:
    ///   - edge: 指定边属性
    ///   - toEdge: 另一视图边属性
    ///   - ofView: 另一视图
    ///   - offset: 偏移距离，默认0
    ///   - relation: 约束关系，默认相等
    ///   - priority: 约束优先级，默认required
    /// - Returns: 布局约束
    @discardableResult
    public func pinEdge(_ edge: NSLayoutConstraint.Attribute, toEdge: NSLayoutConstraint.Attribute, ofView: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
        return base.fw_pinEdge(edge, toEdge: toEdge, ofView: ofView, offset: offset, relation: relation, priority: priority)
    }
    
    // MARK: - SafeArea
    /// 父视图安全区域居中，可指定偏移距离。iOS11以下使用Superview实现，下同
    /// - Parameter offset: 偏移距离
    /// - Returns: 约束数组
    @discardableResult
    public func alignCenter(toSafeArea offset: CGPoint) -> [NSLayoutConstraint] {
        return base.fw_alignCenter(toSafeArea: offset)
    }
    
    /// 父视图安全区域属性居中，可指定偏移距离
    /// - Parameters:
    ///   - axis: 居中属性
    ///   - offset: 偏移距离，默认0
    /// - Returns: 布局约束
    @discardableResult
    public func alignAxis(toSafeArea axis: NSLayoutConstraint.Attribute, offset: CGFloat = .zero) -> NSLayoutConstraint {
        return base.fw_alignAxis(toSafeArea: axis, offset: offset)
    }

    /// 与父视图安全区域四条边属性相同，可指定距离insets
    /// - Parameter insets: 指定距离insets
    /// - Returns: 约束数组
    @discardableResult
    public func pinEdges(toSafeArea insets: UIEdgeInsets) -> [NSLayoutConstraint] {
        return base.fw_pinEdges(toSafeArea: insets)
    }

    /// 与父视图安全区域三条边属性距离指定距离
    /// - Parameters:
    ///   - insets: 指定距离insets
    ///   - excludingEdge: 排除的边
    /// - Returns: 约束数组
    @discardableResult
    public func pinEdges(toSafeArea insets: UIEdgeInsets, excludingEdge: NSLayoutConstraint.Attribute) -> [NSLayoutConstraint] {
        return base.fw_pinEdges(toSafeArea: insets, excludingEdge: excludingEdge)
    }

    /// 与父视图安全区域水平方向两条边属性相同，可指定偏移距离
    /// - Parameters:
    ///   - inset: 偏移距离
    /// - Returns: 约束数组
    @discardableResult
    public func pinHorizontal(toSafeArea inset: CGFloat) -> [NSLayoutConstraint] {
        return base.fw_pinHorizontal(toSafeArea: inset)
    }
    
    /// 与父视图安全区域垂直方向两条边属性相同，可指定偏移距离
    /// - Parameters:
    ///   - inset: 偏移距离
    /// - Returns: 约束数组
    @discardableResult
    public func pinVertical(toSafeArea inset: CGFloat) -> [NSLayoutConstraint] {
        return base.fw_pinVertical(toSafeArea: inset)
    }
    
    /// 与父视图安全区域边属性相同，可指定偏移距离和关系
    /// - Parameters:
    ///   - edge: 指定边属性
    ///   - inset: 偏移距离，默认0
    ///   - relation: 约束关系，默认相等
    ///   - priority: 约束优先级，默认required
    /// - Returns: 布局约束
    @discardableResult
    public func pinEdge(toSafeArea edge: NSLayoutConstraint.Attribute, inset: CGFloat = .zero, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
        return base.fw_pinEdge(toSafeArea: edge, inset: inset, relation: relation, priority: priority)
    }
    
    // MARK: - Dimension
    /// 设置宽高尺寸
    /// - Parameter size: 尺寸大小
    /// - Returns: 约束数组
    @discardableResult
    public func setDimensions(_ size: CGSize) -> [NSLayoutConstraint] {
        return base.fw_setDimensions(size)
    }

    /// 设置某个尺寸，可指定关系
    /// - Parameters:
    ///   - dimension: 尺寸属性
    ///   - size: 尺寸大小
    ///   - relation: 约束关系，默认相等
    ///   - priority: 约束优先级，默认required
    /// - Returns: 布局约束
    @discardableResult
    public func setDimension(_ dimension: NSLayoutConstraint.Attribute, size: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
        return base.fw_setDimension(dimension, size: size, relation: relation, priority: priority)
    }

    /// 与视图自身尺寸属性指定比例，指定关系
    /// - Parameters:
    ///   - dimension: 尺寸属性
    ///   - toDimension: 目标尺寸属性
    ///   - multiplier: 指定比例
    ///   - relation: 约束关系
    ///   - priority: 约束优先级，默认required
    /// - Returns: 布局约束
    @discardableResult
    public func matchDimension(_ dimension: NSLayoutConstraint.Attribute, toDimension: NSLayoutConstraint.Attribute, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
        return base.fw_matchDimension(dimension, toDimension: toDimension, multiplier: multiplier, relation: relation, priority: priority)
    }

    /// 与指定视图尺寸属性相同，可指定相差大小和关系
    /// - Parameters:
    ///   - dimension: 尺寸属性
    ///   - toDimension: 目标尺寸属性
    ///   - ofView: 目标视图
    ///   - offset: 相差大小，默认0
    ///   - relation: 约束关系，默认相等
    ///   - priority: 约束优先级，默认required
    /// - Returns: 布局约束
    @discardableResult
    public func matchDimension(_ dimension: NSLayoutConstraint.Attribute, toDimension: NSLayoutConstraint.Attribute, ofView: Any, offset: CGFloat = .zero, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
        return base.fw_matchDimension(dimension, toDimension: toDimension, ofView: ofView, offset: offset, relation: relation, priority: priority)
    }

    /// 与指定视图尺寸属性指定比例，可指定关系
    /// - Parameters:
    ///   - dimension: 尺寸属性
    ///   - toDimension: 目标尺寸属性
    ///   - ofView: 目标视图
    ///   - multiplier: 指定比例
    ///   - relation: 约束关系，默认相等
    ///   - priority: 约束优先级，默认required
    /// - Returns: 布局约束
    @discardableResult
    public func matchDimension(_ dimension: NSLayoutConstraint.Attribute, toDimension: NSLayoutConstraint.Attribute, ofView: Any, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
        return base.fw_matchDimension(dimension, toDimension: toDimension, ofView: ofView, multiplier: multiplier, relation: relation, priority: priority)
    }
    
    // MARK: - Constrain
    /// 与指定视图属性偏移指定距离，指定关系
    /// - Parameters:
    ///   - attribute: 指定属性
    ///   - toAttribute: 目标视图属性
    ///   - ofView: 目标视图
    ///   - offset: 偏移距离
    ///   - relation: 约束关系
    ///   - priority: 约束优先级，默认required
    /// - Returns: 布局约束
    @discardableResult
    public func constrainAttribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView: Any?, offset: CGFloat = .zero, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
        return base.fw_constrainAttribute(attribute, toAttribute: toAttribute, ofView: ofView, offset: offset, relation: relation, priority: priority)
    }

    /// 与指定视图属性指定比例，指定关系
    /// - Parameters:
    ///   - attribute: 指定属性
    ///   - toAttribute: 目标视图属性
    ///   - ofView: 目标视图
    ///   - multiplier: 指定比例
    ///   - relation: 约束关系
    ///   - priority: 约束优先级，默认required
    /// - Returns: 布局约束
    @discardableResult
    public func constrainAttribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView: Any?, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
        return base.fw_constrainAttribute(attribute, toAttribute: toAttribute, ofView: ofView, multiplier: multiplier, relation: relation, priority: priority)
    }
    
    // MARK: - Constraint
    /// 获取添加的与父视图属性的约束，指定关系
    /// - Parameters:
    ///   - attribute: 指定属性
    ///   - relation: 约束关系
    /// - Returns: 布局约束
    public func constraint(toSuperview attribute: NSLayoutConstraint.Attribute, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint? {
        return base.fw_constraint(toSuperview: attribute, relation: relation)
    }

    /// 获取添加的与父视图安全区域属性的约束，指定关系
    /// - Parameters:
    ///   - attribute: 指定属性
    ///   - relation: 约束关系
    /// - Returns: 布局约束
    public func constraint(toSafeArea attribute: NSLayoutConstraint.Attribute, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint? {
        return base.fw_constraint(toSafeArea: attribute, relation: relation)
    }

    /// 获取添加的与指定视图属性的约束，指定关系
    /// - Parameters:
    ///   - attribute: 指定属性
    ///   - toAttribute: 目标视图属性
    ///   - ofView: 目标视图
    ///   - relation: 约束关系
    /// - Returns: 布局约束
    public func constraint(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView: Any?, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint? {
        return base.fw_constraint(attribute, toAttribute: toAttribute, ofView: ofView, relation: relation)
    }

    /// 获取添加的与指定视图属性指定比例的约束，指定关系
    /// - Parameters:
    ///   - attribute: 指定属性
    ///   - toAttribute: 目标视图属性
    ///   - ofView: 目标视图
    ///   - multiplier: 指定比例
    ///   - relation: 约束关系
    /// - Returns: 布局约束
    public func constraint(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView: Any?, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint? {
        base.fw_constraint(attribute, toAttribute: toAttribute, ofView: ofView, multiplier: multiplier, relation: relation)
    }
    
    /// 根据唯一标志获取布局约束
    /// - Parameters:
    ///   - identifier: 唯一标志
    /// - Returns: 布局约束
    public func constraint(identifier: String?) -> NSLayoutConstraint? {
        return base.fw_constraint(identifier: identifier)
    }
    
    /// 最近一批添加或更新的布局约束
    public var lastConstraints: [NSLayoutConstraint] {
        return base.fw_lastConstraints
    }
    
    /// 获取当前所有约束
    public var allConstraints: [NSLayoutConstraint] {
        return base.fw_allConstraints
    }
    
    /// 移除当前指定约束数组
    /// - Parameter constraints: 布局约束数组
    public func removeConstraints(_ constraints: [NSLayoutConstraint]?) {
        base.fw_removeConstraints(constraints)
    }
    
}

// MARK: - NSLayoutConstraint+AutoLayout
extension Wrapper where Base: NSLayoutConstraint {
    
    /// 标记是否是相反的约束，一般相对于父视图
    public var isOpposite: Bool {
        get { base.fw_isOpposite }
        set { base.fw_isOpposite = newValue }
    }
    
    /// 设置内间距值，如果是相反的约束，会自动取反
    public var inset: CGFloat {
        get { base.fw_inset }
        set { base.fw_inset = newValue }
    }
    
    /// 安全修改优先级，防止iOS13以下已激活约束修改Required崩溃
    public var priority: UILayoutPriority {
        get { base.fw_priority }
        set { base.fw_priority = newValue }
    }
    
}

// MARK: - UIView+LayoutChain
extension Wrapper where Base: UIView {

    /// 链式布局对象
    public var layoutChain: LayoutChain {
        return base.fw_layoutChain
    }
    
    /// 链式布局闭包
    public func layoutMaker(_ closure: (_ make: LayoutChain) -> Void) {
        base.fw_layoutMaker(closure)
    }
    
}
