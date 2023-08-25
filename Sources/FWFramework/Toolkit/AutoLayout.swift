//
//  AutoLayout.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

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
        get { return Base.__fw_autoLayoutRTL }
        set { Base.__fw_autoLayoutRTL = newValue }
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
        get { return Base.__fw_autoScale }
        set { Base.__fw_autoScale = newValue }
    }
    
    /// 是否自动等比例缩放后像素取整，默认NO
    public static var autoFlat: Bool {
        get { return Base.__fw_autoFlat }
        set { Base.__fw_autoFlat = newValue }
    }
    
    // MARK: - AutoLayout
    /// 当前视图是否自动等比例缩放布局，未设置时返回全局开关
    public var autoScale: Bool {
        get { return base.__fw_autoScale }
        set { base.__fw_autoScale = newValue }
    }

    /// 执行子视图自动布局，自动计算子视图尺寸。需先将视图添加到界面(如设置为tableHeaderView)，再调用即可(iOS8+)
    public func autoLayoutSubviews() {
        base.__fw_autoLayoutSubviews()
    }

    /// 计算动态布局视图指定宽度时的高度。使用AutoLayout必须约束完整，不使用AutoLayout会调用view的sizeThatFits:方法
    public func layoutHeight(width: CGFloat) -> CGFloat {
        return base.__fw_layoutHeight(withWidth: width)
    }

    /// 计算动态布局视图指定高度时的宽度。使用AutoLayout必须约束完整，不使用AutoLayout会调用view的sizeThatFits:方法
    public func layoutWidth(height: CGFloat) -> CGFloat {
        return base.__fw_layoutWidth(withHeight: height)
    }
    
    /// 计算动态AutoLayout布局视图指定宽度时的高度。
    ///
    /// 注意调用后会重置superview和frame，一般用于未添加到superview时的场景，cell等请使用DynamicLayout
    /// - Parameters:
    ///   - width: 指定宽度
    ///   - maxYViewExpanded: 最大Y视图是否撑开布局，需布局约束完整。默认false，无需撑开布局
    ///   - maxYViewPadding: 最大Y视图的底部内边距，maxYViewExpanded为true时不起作用，默认0
    ///   - maxYView: 指定最大Y视图，默认nil
    /// - Returns: 高度
    public func dynamicHeight(
        width: CGFloat,
        maxYViewExpanded: Bool = false,
        maxYViewPadding: CGFloat = 0,
        maxYView: UIView? = nil
    ) -> CGFloat {
        return base.__fw_dynamicHeight(withWidth: width, maxYViewExpanded: maxYViewExpanded, maxYViewPadding: maxYViewPadding, maxYView: maxYView)
    }
    
    /// 计算动态AutoLayout布局视图指定高度时的宽度。
    ///
    /// 注意调用后会重置superview和frame，一般用于未添加到superview时的场景，cell等请使用DynamicLayout
    /// - Parameters:
    ///   - height: 指定高度
    ///   - maxYViewExpanded: 最大Y视图是否撑开布局(横向时为X)，需布局约束完整。默认false，无需撑开布局
    ///   - maxYViewPadding: 最大Y视图的底部内边距(横向时为X)，maxYViewExpanded为true时不起作用，默认0
    ///   - maxYView: 指定最大Y视图(横向时为X)，默认nil
    /// - Returns: 宽度
    public func dynamicWidth(
        height: CGFloat,
        maxYViewExpanded: Bool = false,
        maxYViewPadding: CGFloat = 0,
        maxYView: UIView? = nil
    ) -> CGFloat {
        return base.__fw_dynamicWidth(withHeight: height, maxYViewExpanded: maxYViewExpanded, maxYViewPadding: maxYViewPadding, maxYView: maxYView)
    }
    
    // MARK: - Compression
    /// 设置水平方向抗压缩优先级
    public var compressionHorizontal: UILayoutPriority {
        get { return base.__fw_compressionHorizontal }
        set { base.__fw_compressionHorizontal = newValue }
    }

    /// 设置垂直方向抗压缩优先级
    public var compressionVertical: UILayoutPriority {
        get { return base.__fw_compressionVertical }
        set { base.__fw_compressionVertical = newValue }
    }

    /// 设置水平方向抗拉伸优先级
    public var huggingHorizontal: UILayoutPriority {
        get { return base.__fw_huggingHorizontal }
        set { base.__fw_huggingHorizontal = newValue }
    }

    /// 设置垂直方向抗拉伸优先级
    public var huggingVertical: UILayoutPriority {
        get { return base.__fw_huggingVertical }
        set { base.__fw_huggingVertical = newValue }
    }
    
    // MARK: - Collapse
    /// 设置视图是否收缩，默认NO为原始值，YES时为收缩值
    public var isCollapsed: Bool {
        get { return base.__fw_isCollapsed }
        set { base.__fw_isCollapsed = newValue }
    }

    /// 设置视图是否自动收缩，如image为nil，text为nil、@""时自动收缩，默认NO
    public var autoCollapse: Bool {
        get { return base.__fw_autoCollapse }
        set { base.__fw_autoCollapse = newValue }
    }

    /// 设置视图是否隐藏时自动收缩、显示时自动展开，默认NO
    public var hiddenCollapse: Bool {
        get { return base.__fw_hiddenCollapse }
        set { base.__fw_hiddenCollapse = newValue }
    }

    /// 添加视图的收缩常量，必须先添加才能生效
    ///
    /// - see: [UIView-FDCollapsibleConstraints](https://github.com/forkingdog/UIView-FDCollapsibleConstraints)
    public func addCollapseConstraint(_ constraint: NSLayoutConstraint) {
        base.__fw_addCollapseConstraint(constraint)
    }
    
    // MARK: - Inactive
    /// 设置可禁用布局是否禁用，默认NO为原始状态，YES时为相反状态
    public var isInactive: Bool {
        get { base.__fw_isInactive }
        set { base.__fw_isInactive = newValue }
    }

    /// 添加视图的可禁用布局，必须先添加才能生效
    public func addInactiveConstraint(_ constraint: NSLayoutConstraint) {
        base.__fw_addInactiveConstraint(constraint)
    }
    
    // MARK: - Axis
    /// 父视图居中，可指定偏移距离
    /// - Parameter offset: 偏移距离，默认zero
    /// - Returns: 约束数组
    @discardableResult
    public func alignCenter(toSuperview offset: CGPoint = .zero) -> [NSLayoutConstraint] {
        return base.__fw_alignCenterToSuperview(withOffset: offset)
    }
    
    /// 父视图属性居中，可指定偏移距离
    /// - Parameters:
    ///   - axis: 居中属性
    ///   - offset: 偏移距离，默认0
    /// - Returns: 布局约束
    @discardableResult
    public func alignAxis(toSuperview axis: NSLayoutConstraint.Attribute, offset: CGFloat = 0) -> NSLayoutConstraint {
        return base.__fw_alignAxis(toSuperview: axis, withOffset: offset)
    }
    
    /// 与另一视图居中相同，可指定偏移距离
    /// - Parameters:
    ///   - axis: 居中属性
    ///   - toView: 另一视图或UILayoutGuide，下同
    ///   - offset: 偏移距离，默认0
    /// - Returns: 布局约束
    @discardableResult
    public func alignAxis(_ axis: NSLayoutConstraint.Attribute, toView: Any, offset: CGFloat = 0) -> NSLayoutConstraint {
        return base.__fw_alignAxis(axis, toView: toView, withOffset: offset)
    }

    /// 与另一视图居中指定比例
    /// - Parameters:
    ///   - axis: 居中属性
    ///   - toView: 另一视图
    ///   - multiplier: 指定比例
    /// - Returns: 布局约束
    @discardableResult
    public func alignAxis(_ axis: NSLayoutConstraint.Attribute, toView: Any, multiplier: CGFloat) -> NSLayoutConstraint {
        return base.__fw_alignAxis(axis, toView: toView, withMultiplier: multiplier)
    }
    
    // MARK: - Edge
    /// 与父视图四条边属性相同，可指定insets距离
    /// - Parameter insets: 指定距离insets，默认zero
    /// - Returns: 约束数组
    @discardableResult
    public func pinEdges(toSuperview insets: UIEdgeInsets = .zero) -> [NSLayoutConstraint] {
        return base.__fw_pinEdgesToSuperview(with: insets)
    }

    /// 与父视图三条边属性距离指定距离
    /// - Parameters:
    ///   - insets: 指定距离insets
    ///   - excludingEdge: 排除的边
    /// - Returns: 约束数组
    @discardableResult
    public func pinEdges(toSuperview insets: UIEdgeInsets = .zero, excludingEdge: NSLayoutConstraint.Attribute) -> [NSLayoutConstraint] {
        return base.__fw_pinEdgesToSuperview(with: insets, excludingEdge: excludingEdge)
    }
    
    /// 与父视图水平方向两条边属性相同，可指定偏移距离
    /// - Parameters:
    ///   - inset: 偏移距离
    /// - Returns: 约束数组
    @discardableResult
    public func pinHorizontal(toSuperview inset: CGFloat = .zero) -> [NSLayoutConstraint] {
        return base.__fw_pinHorizontalToSuperview(withInset: inset)
    }
    
    /// 与父视图垂直方向两条边属性相同，可指定偏移距离
    /// - Parameters:
    ///   - inset: 偏移距离
    /// - Returns: 约束数组
    @discardableResult
    public func pinVertical(toSuperview inset: CGFloat = .zero) -> [NSLayoutConstraint] {
        return base.__fw_pinVerticalToSuperview(withInset: inset)
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
        return base.__fw_pinEdge(toSuperview: edge, withInset: inset, relation: relation, priority: priority)
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
        return base.__fw_pinEdge(edge, toEdge: toEdge, ofView: ofView, withOffset: offset, relation: relation, priority: priority)
    }
    
    // MARK: - SafeArea
    /// 父视图安全区域居中，可指定偏移距离。iOS11以下使用Superview实现，下同
    /// - Parameter offset: 偏移距离
    /// - Returns: 约束数组
    @discardableResult
    public func alignCenter(toSafeArea offset: CGPoint) -> [NSLayoutConstraint] {
        return base.__fw_alignCenterToSafeArea(withOffset: offset)
    }
    
    /// 父视图安全区域属性居中，可指定偏移距离
    /// - Parameters:
    ///   - axis: 居中属性
    ///   - offset: 偏移距离，默认0
    /// - Returns: 布局约束
    @discardableResult
    public func alignAxis(toSafeArea axis: NSLayoutConstraint.Attribute, offset: CGFloat = .zero) -> NSLayoutConstraint {
        return base.__fw_alignAxis(toSafeArea: axis, withOffset: offset)
    }

    /// 与父视图安全区域四条边属性相同，可指定距离insets
    /// - Parameter insets: 指定距离insets
    /// - Returns: 约束数组
    @discardableResult
    public func pinEdges(toSafeArea insets: UIEdgeInsets) -> [NSLayoutConstraint] {
        return base.__fw_pinEdgesToSafeArea(with: insets)
    }

    /// 与父视图安全区域三条边属性距离指定距离
    /// - Parameters:
    ///   - insets: 指定距离insets
    ///   - excludingEdge: 排除的边
    /// - Returns: 约束数组
    @discardableResult
    public func pinEdges(toSafeArea insets: UIEdgeInsets, excludingEdge: NSLayoutConstraint.Attribute) -> [NSLayoutConstraint] {
        return base.__fw_pinEdgesToSafeArea(with: insets, excludingEdge: excludingEdge)
    }

    /// 与父视图安全区域水平方向两条边属性相同，可指定偏移距离
    /// - Parameters:
    ///   - inset: 偏移距离
    /// - Returns: 约束数组
    @discardableResult
    public func pinHorizontal(toSafeArea inset: CGFloat) -> [NSLayoutConstraint] {
        return base.__fw_pinHorizontalToSafeArea(withInset: inset)
    }
    
    /// 与父视图安全区域垂直方向两条边属性相同，可指定偏移距离
    /// - Parameters:
    ///   - inset: 偏移距离
    /// - Returns: 约束数组
    @discardableResult
    public func pinVertical(toSafeArea inset: CGFloat) -> [NSLayoutConstraint] {
        return base.__fw_pinVerticalToSafeArea(withInset: inset)
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
        return base.__fw_pinEdge(toSafeArea: edge, withInset: inset, relation: relation, priority: priority)
    }
    
    // MARK: - Dimension
    /// 设置宽高尺寸
    /// - Parameter size: 尺寸大小
    /// - Returns: 约束数组
    @discardableResult
    public func setDimensions(_ size: CGSize) -> [NSLayoutConstraint] {
        return base.__fw_setDimensions(to: size)
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
        return base.__fw_setDimension(dimension, toSize: size, relation: relation, priority: priority)
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
        return base.__fw_matchDimension(dimension, toDimension: toDimension, withMultiplier: multiplier, relation: relation, priority: priority)
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
        return base.__fw_matchDimension(dimension, toDimension: toDimension, ofView: ofView, withOffset: offset, relation: relation, priority: priority)
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
        return base.__fw_matchDimension(dimension, toDimension: toDimension, ofView: ofView, withMultiplier: multiplier, relation: relation, priority: priority)
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
        return base.__fw_constrainAttribute(attribute, to: toAttribute, ofView: ofView, withOffset: offset, relation: relation, priority: priority)
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
        return base.__fw_constrainAttribute(attribute, to: toAttribute, ofView: ofView, withMultiplier: multiplier, relation: relation, priority: priority)
    }
    
    // MARK: - Constraint
    /// 获取添加的与父视图属性的约束，指定关系
    /// - Parameters:
    ///   - attribute: 指定属性
    ///   - relation: 约束关系
    /// - Returns: 布局约束
    public func constraint(toSuperview attribute: NSLayoutConstraint.Attribute, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint? {
        return base.__fw_constraint(toSuperview: attribute, relation: relation)
    }

    /// 获取添加的与父视图安全区域属性的约束，指定关系
    /// - Parameters:
    ///   - attribute: 指定属性
    ///   - relation: 约束关系
    /// - Returns: 布局约束
    public func constraint(toSafeArea attribute: NSLayoutConstraint.Attribute, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint? {
        return base.__fw_constraint(toSafeArea: attribute, relation: relation)
    }

    /// 获取添加的与指定视图属性的约束，指定关系
    /// - Parameters:
    ///   - attribute: 指定属性
    ///   - toAttribute: 目标视图属性
    ///   - ofView: 目标视图
    ///   - relation: 约束关系
    /// - Returns: 布局约束
    public func constraint(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView: Any?, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint? {
        return base.__fw_constraint(attribute, to: toAttribute, ofView: ofView, relation: relation)
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
        return base.__fw_constraint(attribute, to: toAttribute, ofView: ofView, withMultiplier: multiplier, relation: relation)
    }
    
    /// 根据唯一标志获取布局约束
    /// - Parameters:
    ///   - identifier: 唯一标志
    /// - Returns: 布局约束
    public func constraint(identifier: String?) -> NSLayoutConstraint? {
        return base.__fw_constraint(withIdentifier: identifier)
    }
    
    /// 最近一批添加或更新的布局约束
    public var lastConstraints: [NSLayoutConstraint] {
        get { return base.__fw_lastConstraints }
        set { base.__fw_lastConstraints = newValue }
    }
    
    /// 获取当前所有约束
    public var allConstraints: [NSLayoutConstraint] {
        return base.__fw_allConstraints
    }
    
    /// 移除当前指定约束数组
    /// - Parameter constraints: 布局约束数组
    public func removeConstraints(_ constraints: [NSLayoutConstraint]?) {
        base.__fw_removeConstraints(constraints)
    }
    
    // MARK: - Debug
    /// 自动布局调试开关，默认打开，仅调试生效
    public static var autoLayoutDebug: Bool {
        get { return UIView.__fw_autoLayoutDebug }
        set { UIView.__fw_autoLayoutDebug = newValue }
    }
    
    /// 布局调试Key
    public var layoutKey: String? {
        get { base.__fw_layoutKey }
        set { base.__fw_layoutKey = newValue }
    }
    
}

// MARK: - NSLayoutConstraint+AutoLayout
extension Wrapper where Base: NSLayoutConstraint {
    
    /// 设置偏移值，根据配置自动等比例缩放和取反
    public var offset: CGFloat {
        get { return base.__fw_offset }
        set { base.__fw_offset = newValue }
    }
    
    /// 标记是否是相反的约束，一般相对于父视图
    public var isOpposite: Bool {
        get { return base.__fw_isOpposite }
        set { base.__fw_isOpposite = newValue }
    }
    
    /// 安全修改优先级，防止iOS13以下已激活约束修改Required崩溃
    public var priority: UILayoutPriority {
        get { return base.__fw_priority }
        set { base.__fw_priority = newValue }
    }
    
    /// 可收缩约束的收缩偏移值，默认0
    public var collapseOffset: CGFloat {
        get { return base.__fw_collapseOffset }
        set { base.__fw_collapseOffset = newValue }
    }
    
    /// 可收缩约束的原始偏移值，默认为添加收缩约束时的值
    public var originalOffset: CGFloat {
        get { return base.__fw_originalOffset }
        set { base.__fw_originalOffset = newValue }
    }
    
    /// 可禁用约束的原始状态，默认为添加禁用约束时的状态
    public var originalActive: Bool {
        get { base.__fw_originalActive }
        set { base.__fw_originalActive = newValue }
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
        view?.__fw_removeConstraints(view?.__fw_allConstraints)
        return self
    }
    
    @discardableResult
    public func autoScale(_ autoScale: Bool) -> Self {
        view?.__fw_autoScale = autoScale
        return self
    }

    // MARK: - Compression
    @discardableResult
    public func compression(horizontal priority: UILayoutPriority) -> Self {
        view?.__fw_compressionHorizontal = priority
        return self
    }

    @discardableResult
    public func compression(vertical priority: UILayoutPriority) -> Self {
        view?.__fw_compressionVertical = priority
        return self
    }
    
    @discardableResult
    public func hugging(horizontal priority: UILayoutPriority) -> Self {
        view?.__fw_huggingHorizontal = priority
        return self
    }

    @discardableResult
    public func hugging(vertical priority: UILayoutPriority) -> Self {
        view?.__fw_huggingVertical = priority
        return self
    }
    
    // MARK: - Collapse
    @discardableResult
    public func isCollapsed(_ isCollapsed: Bool) -> Self {
        view?.__fw_isCollapsed = isCollapsed
        return self
    }

    @discardableResult
    public func autoCollapse(_ autoCollapse: Bool) -> Self {
        view?.__fw_autoCollapse = autoCollapse
        return self
    }
    
    @discardableResult
    public func hiddenCollapse(_ hiddenCollapse: Bool) -> Self {
        view?.__fw_hiddenCollapse = hiddenCollapse
        return self
    }
    
    // MARK: - Inactive
    @discardableResult
    public func isInactive(_ isInactive: Bool) -> Self {
        view?.__fw_isInactive = isInactive
        return self
    }

    // MARK: - Axis
    @discardableResult
    public func center(_ offset: CGPoint = .zero) -> Self {
        view?.__fw_alignCenterToSuperview(withOffset: offset)
        return self
    }

    @discardableResult
    public func centerX(_ offset: CGFloat = .zero) -> Self {
        view?.__fw_alignAxis(toSuperview: .centerX, withOffset: offset)
        return self
    }

    @discardableResult
    public func centerY(_ offset: CGFloat = .zero) -> Self {
        view?.__fw_alignAxis(toSuperview: .centerY, withOffset: offset)
        return self
    }

    @discardableResult
    public func center(toView view: Any) -> Self {
        var constraints: [NSLayoutConstraint] = []
        if let constraint = self.view?.__fw_alignAxis(.centerX, toView: view) {
            constraints.append(constraint)
        }
        if let constraint = self.view?.__fw_alignAxis(.centerY, toView: view) {
            constraints.append(constraint)
        }
        self.view?.__fw_lastConstraints = constraints
        return self
    }

    @discardableResult
    public func centerX(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw_alignAxis(.centerX, toView: view, withOffset: offset)
        return self
    }

    @discardableResult
    public func centerY(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw_alignAxis(.centerY, toView: view, withOffset: offset)
        return self
    }

    @discardableResult
    public func centerX(toView view: Any, multiplier: CGFloat) -> Self {
        self.view?.__fw_alignAxis(.centerX, toView: view, withMultiplier: multiplier)
        return self
    }

    @discardableResult
    public func centerY(toView view: Any, multiplier: CGFloat) -> Self {
        self.view?.__fw_alignAxis(.centerY, toView: view, withMultiplier: multiplier)
        return self
    }

    // MARK: - Edge
    @discardableResult
    public func edges(_ insets: UIEdgeInsets = UIEdgeInsets.zero) -> Self {
        view?.__fw_pinEdgesToSuperview(with: insets)
        return self
    }
    
    @discardableResult
    public func edges(_ insets: UIEdgeInsets = UIEdgeInsets.zero, excludingEdge edge: NSLayoutConstraint.Attribute) -> Self {
        view?.__fw_pinEdgesToSuperview(with: insets, excludingEdge: edge)
        return self
    }

    @discardableResult
    public func horizontal(_ inset: CGFloat = .zero) -> Self {
        view?.__fw_pinHorizontalToSuperview(withInset: inset)
        return self
    }

    @discardableResult
    public func vertical(_ inset: CGFloat = .zero) -> Self {
        view?.__fw_pinVerticalToSuperview(withInset: inset)
        return self
    }

    @discardableResult
    public func top(_ inset: CGFloat = 0) -> Self {
        view?.__fw_pinEdge(toSuperview: .top, withInset: inset)
        return self
    }
    
    @discardableResult
    public func top(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        view?.__fw_pinEdge(toSuperview: .top, withInset: inset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func bottom(_ inset: CGFloat = 0) -> Self {
        view?.__fw_pinEdge(toSuperview: .bottom, withInset: inset)
        return self
    }
    
    @discardableResult
    public func bottom(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        view?.__fw_pinEdge(toSuperview: .bottom, withInset: inset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func left(_ inset: CGFloat = 0) -> Self {
        view?.__fw_pinEdge(toSuperview: .left, withInset: inset)
        return self
    }
    
    @discardableResult
    public func left(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        view?.__fw_pinEdge(toSuperview: .left, withInset: inset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func right(_ inset: CGFloat = 0) -> Self {
        view?.__fw_pinEdge(toSuperview: .right, withInset: inset)
        return self
    }
    
    @discardableResult
    public func right(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        view?.__fw_pinEdge(toSuperview: .right, withInset: inset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func top(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw_pinEdge(.top, toEdge: .top, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func top(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.__fw_pinEdge(.top, toEdge: .top, ofView: view, withOffset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func bottom(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw_pinEdge(.bottom, toEdge: .bottom, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func bottom(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.__fw_pinEdge(.bottom, toEdge: .bottom, ofView: view, withOffset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func left(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw_pinEdge(.left, toEdge: .left, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func left(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.__fw_pinEdge(.left, toEdge: .left, ofView: view, withOffset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func right(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw_pinEdge(.right, toEdge: .right, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func right(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.__fw_pinEdge(.right, toEdge: .right, ofView: view, withOffset: offset, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func horizontal(toView view: Any) -> Self {
        var constraints: [NSLayoutConstraint] = []
        if let constraint = self.view?.__fw_pinEdge(.left, toEdge: .left, ofView: view) {
            constraints.append(constraint)
        }
        if let constraint = self.view?.__fw_pinEdge(.right, toEdge: .right, ofView: view) {
            constraints.append(constraint)
        }
        self.view?.__fw_lastConstraints = constraints
        return self
    }
    
    @discardableResult
    public func vertical(toView view: Any) -> Self {
        var constraints: [NSLayoutConstraint] = []
        if let constraint = self.view?.__fw_pinEdge(.top, toEdge: .top, ofView: view) {
            constraints.append(constraint)
        }
        if let constraint = self.view?.__fw_pinEdge(.bottom, toEdge: .bottom, ofView: view) {
            constraints.append(constraint)
        }
        self.view?.__fw_lastConstraints = constraints
        return self
    }

    @discardableResult
    public func top(toViewBottom view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw_pinEdge(.top, toEdge: .bottom, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func top(toViewBottom view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.__fw_pinEdge(.top, toEdge: .bottom, ofView: view, withOffset: offset, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func bottom(toViewTop view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw_pinEdge(.bottom, toEdge: .top, ofView: view, withOffset: offset)
        return self
    }

    @discardableResult
    public func bottom(toViewTop view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.__fw_pinEdge(.bottom, toEdge: .top, ofView: view, withOffset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func left(toViewRight view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw_pinEdge(.left, toEdge: .right, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func left(toViewRight view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.__fw_pinEdge(.left, toEdge: .right, ofView: view, withOffset: offset, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func right(toViewLeft view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw_pinEdge(.right, toEdge: .left, ofView: view, withOffset: offset)
        return self
    }

    @discardableResult
    public func right(toViewLeft view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.__fw_pinEdge(.right, toEdge: .left, ofView: view, withOffset: offset, relation: relation, priority: priority)
        return self
    }

    // MARK: - SafeArea
    @discardableResult
    public func center(toSafeArea offset: CGPoint) -> Self {
        view?.__fw_alignCenterToSafeArea(withOffset: offset)
        return self
    }

    @discardableResult
    public func centerX(toSafeArea offset: CGFloat) -> Self {
        view?.__fw_alignAxis(toSafeArea: .centerX, withOffset: offset)
        return self
    }

    @discardableResult
    public func centerY(toSafeArea offset: CGFloat) -> Self {
        view?.__fw_alignAxis(toSafeArea: .centerY, withOffset: offset)
        return self
    }

    @discardableResult
    public func edges(toSafeArea insets: UIEdgeInsets) -> Self {
        view?.__fw_pinEdgesToSafeArea(with: insets)
        return self
    }
    
    @discardableResult
    public func edges(toSafeArea insets: UIEdgeInsets, excludingEdge edge: NSLayoutConstraint.Attribute) -> Self {
        view?.__fw_pinEdgesToSafeArea(with: insets, excludingEdge: edge)
        return self
    }

    @discardableResult
    public func horizontal(toSafeArea inset: CGFloat) -> Self {
        view?.__fw_pinHorizontalToSafeArea(withInset: inset)
        return self
    }

    @discardableResult
    public func vertical(toSafeArea inset: CGFloat) -> Self {
        view?.__fw_pinVerticalToSafeArea(withInset: inset)
        return self
    }

    @discardableResult
    public func top(toSafeArea inset: CGFloat) -> Self {
        view?.__fw_pinEdge(toSafeArea: .top, withInset: inset)
        return self
    }
    
    @discardableResult
    public func top(toSafeArea inset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        view?.__fw_pinEdge(toSafeArea: .top, withInset: inset, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func bottom(toSafeArea inset: CGFloat) -> Self {
        view?.__fw_pinEdge(toSafeArea: .bottom, withInset: inset)
        return self
    }

    @discardableResult
    public func bottom(toSafeArea inset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        view?.__fw_pinEdge(toSafeArea: .bottom, withInset: inset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func left(toSafeArea inset: CGFloat) -> Self {
        view?.__fw_pinEdge(toSafeArea: .left, withInset: inset)
        return self
    }
    
    @discardableResult
    public func left(toSafeArea inset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        view?.__fw_pinEdge(toSafeArea: .left, withInset: inset, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func right(toSafeArea inset: CGFloat) -> Self {
        view?.__fw_pinEdge(toSafeArea: .right, withInset: inset)
        return self
    }

    @discardableResult
    public func right(toSafeArea inset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        view?.__fw_pinEdge(toSafeArea: .right, withInset: inset, relation: relation, priority: priority)
        return self
    }

    // MARK: - Dimension
    @discardableResult
    public func size(_ size: CGSize) -> Self {
        view?.__fw_setDimensions(to: size)
        return self
    }
    
    @discardableResult
    public func size(width: CGFloat, height: CGFloat) -> Self {
        view?.__fw_setDimensions(to: CGSize(width: width, height: height))
        return self
    }

    @discardableResult
    public func width(_ width: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal, priority: UILayoutPriority = .required) -> Self {
        view?.__fw_setDimension(.width, toSize: width, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func height(_ height: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal, priority: UILayoutPriority = .required) -> Self {
        view?.__fw_setDimension(.height, toSize: height, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func width(toHeight multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal, priority: UILayoutPriority = .required) -> Self {
        view?.__fw_matchDimension(.width, toDimension: .height, withMultiplier: multiplier, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func height(toWidth multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal, priority: UILayoutPriority = .required) -> Self {
        view?.__fw_matchDimension(.height, toDimension: .width, withMultiplier: multiplier, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func size(toView view: Any) -> Self {
        var constraints: [NSLayoutConstraint] = []
        if let constraint = self.view?.__fw_matchDimension(.width, toDimension: .width, ofView: view) {
            constraints.append(constraint)
        }
        if let constraint = self.view?.__fw_matchDimension(.height, toDimension: .height, ofView: view) {
            constraints.append(constraint)
        }
        self.view?.__fw_lastConstraints = constraints
        return self
    }

    @discardableResult
    public func width(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw_matchDimension(.width, toDimension: .width, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func width(toView view: Any, offset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.__fw_matchDimension(.width, toDimension: .width, ofView: view, withOffset: offset, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func height(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw_matchDimension(.height, toDimension: .height, ofView: view, withOffset: offset)
        return self
    }

    @discardableResult
    public func height(toView view: Any, offset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.__fw_matchDimension(.height, toDimension: .height, ofView: view, withOffset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func width(toView view: Any, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.__fw_matchDimension(.width, toDimension: .width, ofView: view, withMultiplier: multiplier, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func height(toView view: Any, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.__fw_matchDimension(.height, toDimension: .height, ofView: view, withMultiplier: multiplier, relation: relation, priority: priority)
        return self
    }

    // MARK: - Attribute
    @discardableResult
    public func attribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, offset: CGFloat = 0) -> Self {
        self.view?.__fw_constrainAttribute(attribute, to: toAttribute, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func attribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, offset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.__fw_constrainAttribute(attribute, to: toAttribute, ofView: view, withOffset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func attribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.__fw_constrainAttribute(attribute, to: toAttribute, ofView: view, withMultiplier: multiplier, relation: relation, priority: priority)
        return self
    }
    
    // MARK: - Subviews
    @discardableResult
    public func subviews(_ closure: (_ make: LayoutChain) -> Void) -> Self {
        self.view?.subviews.fw.layoutMaker(closure)
        return self
    }
    
    @discardableResult
    public func subviews(along axis: NSLayoutConstraint.Axis, itemSpacing: CGFloat, leadSpacing: CGFloat? = nil, tailSpacing: CGFloat? = nil, equalLength: Bool = false) -> Self {
        self.view?.subviews.fw.layoutAlong(axis, itemSpacing: itemSpacing, leadSpacing: leadSpacing, tailSpacing: tailSpacing, equalLength: equalLength)
        return self
    }
    
    @discardableResult
    public func subviews(along axis: NSLayoutConstraint.Axis, itemLength: CGFloat, leadSpacing: CGFloat, tailSpacing: CGFloat) -> Self {
        self.view?.subviews.fw.layoutAlong(axis, itemLength: itemLength, leadSpacing: leadSpacing, tailSpacing: tailSpacing)
        return self
    }
    
    @discardableResult
    public func subviews(along axis: NSLayoutConstraint.Axis, alignCenter: Bool = false, itemWidth: CGFloat? = nil, leftSpacing: CGFloat? = nil, rightSpacing: CGFloat? = nil) -> Self {
        self.view?.subviews.fw.layoutAlong(axis, alignCenter: alignCenter, itemWidth: itemWidth, leftSpacing: leftSpacing, rightSpacing: rightSpacing)
        return self
    }
    
    // MARK: - Offset
    @discardableResult
    public func offset(_ offset: CGFloat) -> Self {
        self.view?.__fw_lastConstraints.forEach({ obj in
            obj.__fw_offset = offset
        })
        return self
    }
    
    @discardableResult
    public func constant(_ constant: CGFloat) -> Self {
        self.view?.__fw_lastConstraints.forEach({ obj in
            obj.constant = constant
        })
        return self
    }
    
    @discardableResult
    public func priority(_ priority: UILayoutPriority) -> Self {
        self.view?.__fw_lastConstraints.forEach({ obj in
            obj.__fw_priority = priority
        })
        return self
    }
    
    @discardableResult
    public func collapse(_ offset: CGFloat? = nil) -> Self {
        self.view?.__fw_lastConstraints.forEach({ obj in
            self.view?.__fw_addCollapseConstraint(obj)
            if let offset = offset {
                obj.__fw_collapseOffset = offset
            }
        })
        return self
    }
    
    @discardableResult
    public func original(_ offset: CGFloat) -> Self {
        self.view?.__fw_lastConstraints.forEach({ obj in
            obj.__fw_originalOffset = offset
        })
        return self
    }
    
    @discardableResult
    public func toggle(_ active: Bool? = nil) -> Self {
        self.view?.__fw_lastConstraints.forEach({ obj in
            if let active = active {
                obj.isActive = active
            }
            self.view?.__fw_addInactiveConstraint(obj)
        })
        return self
    }
    
    @discardableResult
    public func identifier(_ identifier: String?) -> Self {
        self.view?.__fw_lastConstraints.forEach({ obj in
            obj.identifier = identifier
        })
        return self
    }
    
    @discardableResult
    public func active(_ active: Bool) -> Self {
        self.view?.__fw_lastConstraints.forEach({ obj in
            obj.isActive = active
        })
        return self
    }
    
    @discardableResult
    public func remove() -> Self {
        self.view?.__fw_removeConstraints(self.view?.__fw_lastConstraints)
        return self
    }
    
    // MARK: - Constraint
    public var constraints: [NSLayoutConstraint] {
        return self.view?.__fw_lastConstraints ?? []
    }
    
    public var constraint: NSLayoutConstraint? {
        return self.view?.__fw_lastConstraints.last
    }
    
    public func constraint(_ attribute: NSLayoutConstraint.Attribute, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> NSLayoutConstraint? {
        return self.view?.__fw_constraint(toSuperview: attribute, relation: relation)
    }
    
    public func constraint(toSafeArea attribute: NSLayoutConstraint.Attribute, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> NSLayoutConstraint? {
        return self.view?.__fw_constraint(toSafeArea: attribute, relation: relation)
    }

    public func constraint(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> NSLayoutConstraint? {
        return self.view?.__fw_constraint(attribute, to: toAttribute, ofView: view, relation: relation)
    }
    
    public func constraint(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> NSLayoutConstraint? {
        return self.view?.__fw_constraint(attribute, to: toAttribute, ofView: view, withMultiplier: multiplier, relation: relation)
    }
    
    public func constraint(identifier: String?) -> NSLayoutConstraint? {
        return self.view?.__fw_constraint(withIdentifier: identifier)
    }
    
    // MARK: - Debug
    @discardableResult
    public func layoutKey(_ layoutKey: String?) -> Self {
        self.view?.__fw_layoutKey = layoutKey
        return self
    }
    
}

// MARK: - UIView+LayoutChain
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

// MARK: - Array+LayoutChain
extension Wrapper where Base == Array<UIView> {
    
    /// 批量链式布局闭包
    public func layoutMaker(_ closure: (_ make: LayoutChain) -> Void) {
        base.forEach { view in
            closure(view.fw.layoutChain)
        }
    }
    
    /// 批量对齐布局，适用于间距固定场景，尺寸未设置，若只有一个则间距不生效
    public func layoutAlong(_ axis: NSLayoutConstraint.Axis, itemSpacing: CGFloat, leadSpacing: CGFloat? = nil, tailSpacing: CGFloat? = nil, equalLength: Bool = false) {
        guard base.count > 0 else { return }
        
        if axis == .horizontal {
            var prev: UIView?
            for (index, view) in base.enumerated() {
                if let prev = prev {
                    view.fw.pinEdge(.left, toEdge: .right, ofView: prev, offset: itemSpacing)
                    if equalLength {
                        view.fw.matchDimension(.width, toDimension: .width, ofView: prev)
                    }
                } else if let leadSpacing = leadSpacing {
                    view.fw.pinEdge(toSuperview: .left, inset: leadSpacing)
                }
                if index == base.count - 1, let tailSpacing = tailSpacing {
                    view.fw.pinEdge(toSuperview: .right, inset: tailSpacing)
                }
                prev = view
            }
        } else {
            var prev: UIView?
            for (index, view) in base.enumerated() {
                if let prev = prev {
                    view.fw.pinEdge(.top, toEdge: .bottom, ofView: prev, offset: itemSpacing)
                    if equalLength {
                        view.fw.matchDimension(.height, toDimension: .height, ofView: prev)
                    }
                } else if let leadSpacing = leadSpacing {
                    view.fw.pinEdge(toSuperview: .top, inset: leadSpacing)
                }
                if index == base.count - 1, let tailSpacing = tailSpacing {
                    view.fw.pinEdge(toSuperview: .bottom, inset: tailSpacing)
                }
                prev = view
            }
        }
    }
    
    /// 批量对齐布局，适用于尺寸固定场景，间距自适应，若只有一个则尺寸不生效
    public func layoutAlong(_ axis: NSLayoutConstraint.Axis, itemLength: CGFloat, leadSpacing: CGFloat, tailSpacing: CGFloat) {
        guard base.count > 0 else { return }
        
        if axis == .horizontal {
            var prev: UIView?
            for (index, view) in base.enumerated() {
                if base.count > 1 {
                    view.fw.setDimension(.width, size: itemLength)
                }
                if prev != nil {
                    if index < base.count - 1 {
                        let offset = (CGFloat(1) - (CGFloat(index) / CGFloat(base.count - 1))) *
                            (itemLength + leadSpacing) -
                            CGFloat(index) * tailSpacing / CGFloat(base.count - 1)
                        view.fw.constrainAttribute(.right, toAttribute: .right, ofView: view.superview, multiplier: CGFloat(index) / CGFloat(base.count - 1)).__fw_offset = offset
                    }
                } else {
                    view.fw.pinEdge(toSuperview: .left, inset: leadSpacing)
                }
                if index == base.count - 1 {
                    view.fw.pinEdge(toSuperview: .right, inset: tailSpacing)
                }
                prev = view
            }
        } else {
            var prev: UIView?
            for (index, view) in base.enumerated() {
                if base.count > 1 {
                    view.fw.setDimension(.height, size: itemLength)
                }
                if prev != nil {
                    if index < base.count - 1 {
                        let offset = (CGFloat(1) - (CGFloat(index) / CGFloat(base.count - 1))) *
                            (itemLength + leadSpacing) -
                            CGFloat(index) * tailSpacing / CGFloat(base.count - 1)
                        view.fw.constrainAttribute(.bottom, toAttribute: .bottom, ofView: view.superview, multiplier: CGFloat(index) / CGFloat(base.count - 1)).__fw_offset = offset
                    }
                } else {
                    view.fw.pinEdge(toSuperview: .top, inset: leadSpacing)
                }
                if index == base.count - 1 {
                    view.fw.pinEdge(toSuperview: .bottom, inset: tailSpacing)
                }
                prev = view
            }
        }
    }
    
    /// 批量对齐布局，用于补齐Along之后该方向上的其他约束
    public func layoutAlong(_ axis: NSLayoutConstraint.Axis, alignCenter: Bool = false, itemWidth: CGFloat? = nil, leftSpacing: CGFloat? = nil, rightSpacing: CGFloat? = nil) {
        guard base.count > 0 else { return }
        
        if axis == .horizontal {
            for view in base {
                if alignCenter {
                    view.fw.alignAxis(toSuperview: .centerY)
                }
                if let itemWidth = itemWidth {
                    view.fw.setDimension(.height, size: itemWidth)
                }
                if let leftSpacing = leftSpacing {
                    view.fw.pinEdge(toSuperview: .bottom, inset: leftSpacing)
                }
                if let rightSpacing = rightSpacing {
                    view.fw.pinEdge(toSuperview: .top, inset: rightSpacing)
                }
            }
        } else {
            for view in base {
                if alignCenter {
                    view.fw.alignAxis(toSuperview: .centerX)
                }
                if let itemWidth = itemWidth {
                    view.fw.setDimension(.width, size: itemWidth)
                }
                if let leftSpacing = leftSpacing {
                    view.fw.pinEdge(toSuperview: .left, inset: leftSpacing)
                }
                if let rightSpacing = rightSpacing {
                    view.fw.pinEdge(toSuperview: .right, inset: rightSpacing)
                }
            }
        }
    }
    
}
