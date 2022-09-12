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
    
    // MARK: - AutoLayout
    /// 视图是否自动等比例缩放布局，默认返回全局开关
    public var autoScale: Bool {
        get { return base.__fw_autoScale }
        set { base.__fw_autoScale = newValue }
    }
    
    /// 是否启用自动布局
    public var autoLayout: Bool {
        get { return base.__fw_autoLayout }
        set { base.__fw_autoLayout = newValue }
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
    /// 设置视图是否收缩，默认NO，YES时常量值为0，NO时常量值为原始值
    public var collapsed: Bool {
        get { return base.__fw_collapsed }
        set { base.__fw_collapsed = newValue }
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
    /// - Returns: 布局约束
    @discardableResult
    public func pinEdge(toSuperview edge: NSLayoutConstraint.Attribute, inset: CGFloat = .zero, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        return base.__fw_pinEdge(toSuperview: edge, withInset: inset, relation: relation)
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
        return base.__fw_pinEdge(edge, toEdge: toEdge, ofView: ofView, withOffset: offset, relation: relation)
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
    /// - Returns: 布局约束
    @discardableResult
    public func pinEdge(toSafeArea edge: NSLayoutConstraint.Attribute, inset: CGFloat = .zero, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        return base.__fw_pinEdge(toSafeArea: edge, withInset: inset, relation: relation)
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
    /// - Returns: 布局约束
    @discardableResult
    public func setDimension(_ dimension: NSLayoutConstraint.Attribute, size: CGFloat, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        return base.__fw_setDimension(dimension, toSize: size, relation: relation)
    }

    /// 与视图自身尺寸属性指定比例，指定关系
    /// - Parameters:
    ///   - dimension: 尺寸属性
    ///   - toDimension: 目标尺寸属性
    ///   - multiplier: 指定比例
    ///   - relation: 约束关系
    /// - Returns: 布局约束
    @discardableResult
    public func matchDimension(_ dimension: NSLayoutConstraint.Attribute, toDimension: NSLayoutConstraint.Attribute, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        return base.__fw_matchDimension(dimension, toDimension: toDimension, withMultiplier: multiplier, relation: relation)
    }

    /// 与指定视图尺寸属性相同，可指定相差大小和关系
    /// - Parameters:
    ///   - dimension: 尺寸属性
    ///   - toDimension: 目标尺寸属性
    ///   - ofView: 目标视图
    ///   - offset: 相差大小，默认0
    ///   - relation: 约束关系，默认相等
    /// - Returns: 布局约束
    @discardableResult
    public func matchDimension(_ dimension: NSLayoutConstraint.Attribute, toDimension: NSLayoutConstraint.Attribute, ofView: Any, offset: CGFloat = .zero, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        return base.__fw_matchDimension(dimension, toDimension: toDimension, ofView: ofView, withOffset: offset, relation: relation)
    }

    /// 与指定视图尺寸属性指定比例，可指定关系
    /// - Parameters:
    ///   - dimension: 尺寸属性
    ///   - toDimension: 目标尺寸属性
    ///   - ofView: 目标视图
    ///   - multiplier: 指定比例
    ///   - relation: 约束关系，默认相等
    /// - Returns: 布局约束
    @discardableResult
    public func matchDimension(_ dimension: NSLayoutConstraint.Attribute, toDimension: NSLayoutConstraint.Attribute, ofView: Any, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        return base.__fw_matchDimension(dimension, toDimension: toDimension, ofView: ofView, withMultiplier: multiplier, relation: relation)
    }
    
    // MARK: - Constrain
    /// 与指定视图属性偏移指定距离，指定关系
    /// - Parameters:
    ///   - attribute: 指定属性
    ///   - toAttribute: 目标视图属性
    ///   - ofView: 目标视图
    ///   - offset: 偏移距离
    ///   - relation: 约束关系
    /// - Returns: 布局约束
    @discardableResult
    public func constrainAttribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView: Any?, offset: CGFloat = .zero, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        return base.__fw_constrainAttribute(attribute, to: toAttribute, ofView: ofView, withOffset: offset, relation: relation)
    }

    /// 与指定视图属性指定比例，指定关系
    /// - Parameters:
    ///   - attribute: 指定属性
    ///   - toAttribute: 目标视图属性
    ///   - ofView: 目标视图
    ///   - multiplier: 指定比例
    ///   - relation: 约束关系
    /// - Returns: 布局约束
    @discardableResult
    public func constrainAttribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView: Any?, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        return base.__fw_constrainAttribute(attribute, to: toAttribute, ofView: ofView, withMultiplier: multiplier, relation: relation)
    }
    
    // MARK: - Offset
    /// 修改最近一批添加或更新的布局约束偏移值
    @discardableResult
    public func setOffset(_ offset: CGFloat) -> [NSLayoutConstraint] {
        return base.__fw_setOffset(offset)
    }

    /// 修改最近一批添加或更新的布局约束内间距值
    @discardableResult
    public func setInset(_ inset: CGFloat) -> [NSLayoutConstraint] {
        return base.__fw_setInset(inset)
    }

    /// 修改最近一批添加或更新的布局约束优先级(iOS12以下必须未激活才生效)
    @discardableResult
    public func setPriority(_ priority: UILayoutPriority) -> [NSLayoutConstraint] {
        return base.__fw_setPriority(priority)
    }
    
    /// 修改最近一批添加或更新的布局约束有效性
    @discardableResult
    public func setActive(_ active: Bool) -> [NSLayoutConstraint] {
        return base.__fw_setActive(active)
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
    
    /// 设置约束保存键名，方便更新约束常量
    /// - Parameters:
    ///   - constraint: 布局约束
    ///   - forKey: 保存key
    public func setConstraint(_ constraint: NSLayoutConstraint?, forKey: NSCopying) {
        base.__fw_setConstraint(constraint, forKey: forKey)
    }

    /// 获取键名对应约束
    /// - Parameter forKey: 保存key
    /// - Returns: 布局约束
    public func constraint(forKey: NSCopying) -> NSLayoutConstraint? {
        return base.__fw_constraint(forKey: forKey)
    }
    
    /// 最近一批添加或更新的布局约束
    public var lastConstraints: [NSLayoutConstraint] {
        return base.__fw_lastConstraints
    }
    
    /// 最近一条添加或更新的布局约束
    public var lastConstraint: NSLayoutConstraint? {
        return base.__fw_lastConstraint
    }
    
    /// 获取当前所有约束，不包含Key
    public var allConstraints: [NSLayoutConstraint] {
        return base.__fw_allConstraints
    }

    /// 移除当前指定约束，不包含Key
    /// - Parameter constraint: 布局约束
    public func removeConstraint(_ constraint: NSLayoutConstraint) {
        base.__fw_removeConstraint(constraint)
    }
    
    /// 移除当前指定约束数组，不包含Key
    /// - Parameter constraints: 布局约束数组
    public func removeConstraints(_ constraints: [NSLayoutConstraint]) {
        base.__fw_removeConstraints(constraints)
    }

    /// 移除当前所有约束，不包含Key
    public func removeAllConstraints() {
        base.__fw_removeAllConstraints()
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
        view?.__fw_removeAllConstraints()
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
    public func collapsed(_ collapsed: Bool) -> Self {
        view?.__fw_collapsed = collapsed
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
        self.view?.__fw_alignAxis(.centerX, toView: view)
        self.view?.__fw_alignAxis(.centerY, toView: view)
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
    public func top(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> Self {
        view?.__fw_pinEdge(toSuperview: .top, withInset: inset, relation: relation)
        return self
    }

    @discardableResult
    public func bottom(_ inset: CGFloat = 0) -> Self {
        view?.__fw_pinEdge(toSuperview: .bottom, withInset: inset)
        return self
    }
    
    @discardableResult
    public func bottom(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> Self {
        view?.__fw_pinEdge(toSuperview: .bottom, withInset: inset, relation: relation)
        return self
    }

    @discardableResult
    public func left(_ inset: CGFloat = 0) -> Self {
        view?.__fw_pinEdge(toSuperview: .left, withInset: inset)
        return self
    }
    
    @discardableResult
    public func left(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> Self {
        view?.__fw_pinEdge(toSuperview: .left, withInset: inset, relation: relation)
        return self
    }

    @discardableResult
    public func right(_ inset: CGFloat = 0) -> Self {
        view?.__fw_pinEdge(toSuperview: .right, withInset: inset)
        return self
    }
    
    @discardableResult
    public func right(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> Self {
        view?.__fw_pinEdge(toSuperview: .right, withInset: inset, relation: relation)
        return self
    }

    @discardableResult
    public func top(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw_pinEdge(.top, toEdge: .top, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func top(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> Self {
        self.view?.__fw_pinEdge(.top, toEdge: .top, ofView: view, withOffset: offset, relation: relation)
        return self
    }

    @discardableResult
    public func bottom(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw_pinEdge(.bottom, toEdge: .bottom, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func bottom(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> Self {
        self.view?.__fw_pinEdge(.bottom, toEdge: .bottom, ofView: view, withOffset: offset, relation: relation)
        return self
    }

    @discardableResult
    public func left(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw_pinEdge(.left, toEdge: .left, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func left(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> Self {
        self.view?.__fw_pinEdge(.left, toEdge: .left, ofView: view, withOffset: offset, relation: relation)
        return self
    }

    @discardableResult
    public func right(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw_pinEdge(.right, toEdge: .right, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func right(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> Self {
        self.view?.__fw_pinEdge(.right, toEdge: .right, ofView: view, withOffset: offset, relation: relation)
        return self
    }

    @discardableResult
    public func top(toViewBottom view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw_pinEdge(.top, toEdge: .bottom, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func top(toViewBottom view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> Self {
        self.view?.__fw_pinEdge(.top, toEdge: .bottom, ofView: view, withOffset: offset, relation: relation)
        return self
    }
    
    @discardableResult
    public func bottom(toViewTop view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw_pinEdge(.bottom, toEdge: .top, ofView: view, withOffset: offset)
        return self
    }

    @discardableResult
    public func bottom(toViewTop view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> Self {
        self.view?.__fw_pinEdge(.bottom, toEdge: .top, ofView: view, withOffset: offset, relation: relation)
        return self
    }

    @discardableResult
    public func left(toViewRight view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw_pinEdge(.left, toEdge: .right, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func left(toViewRight view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> Self {
        self.view?.__fw_pinEdge(.left, toEdge: .right, ofView: view, withOffset: offset, relation: relation)
        return self
    }
    
    @discardableResult
    public func right(toViewLeft view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw_pinEdge(.right, toEdge: .left, ofView: view, withOffset: offset)
        return self
    }

    @discardableResult
    public func right(toViewLeft view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation) -> Self {
        self.view?.__fw_pinEdge(.right, toEdge: .left, ofView: view, withOffset: offset, relation: relation)
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
    public func top(toSafeArea inset: CGFloat, relation: NSLayoutConstraint.Relation) -> Self {
        view?.__fw_pinEdge(toSafeArea: .top, withInset: inset, relation: relation)
        return self
    }
    
    @discardableResult
    public func bottom(toSafeArea inset: CGFloat) -> Self {
        view?.__fw_pinEdge(toSafeArea: .bottom, withInset: inset)
        return self
    }

    @discardableResult
    public func bottom(toSafeArea inset: CGFloat, relation: NSLayoutConstraint.Relation) -> Self {
        view?.__fw_pinEdge(toSafeArea: .bottom, withInset: inset, relation: relation)
        return self
    }

    @discardableResult
    public func left(toSafeArea inset: CGFloat) -> Self {
        view?.__fw_pinEdge(toSafeArea: .left, withInset: inset)
        return self
    }
    
    @discardableResult
    public func left(toSafeArea inset: CGFloat, relation: NSLayoutConstraint.Relation) -> Self {
        view?.__fw_pinEdge(toSafeArea: .left, withInset: inset, relation: relation)
        return self
    }
    
    @discardableResult
    public func right(toSafeArea inset: CGFloat) -> Self {
        view?.__fw_pinEdge(toSafeArea: .right, withInset: inset)
        return self
    }

    @discardableResult
    public func right(toSafeArea inset: CGFloat, relation: NSLayoutConstraint.Relation) -> Self {
        view?.__fw_pinEdge(toSafeArea: .right, withInset: inset, relation: relation)
        return self
    }

    // MARK: - Dimension
    @discardableResult
    public func size(_ size: CGSize) -> Self {
        view?.__fw_setDimensions(to: size)
        return self
    }

    @discardableResult
    public func width(_ width: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> Self {
        view?.__fw_setDimension(.width, toSize: width, relation: relation)
        return self
    }

    @discardableResult
    public func height(_ height: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> Self {
        view?.__fw_setDimension(.height, toSize: height, relation: relation)
        return self
    }
    
    @discardableResult
    public func width(toHeight multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> Self {
        view?.__fw_matchDimension(.width, toDimension: .height, withMultiplier: multiplier, relation: relation)
        return self
    }
    
    @discardableResult
    public func height(toWidth multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> Self {
        view?.__fw_matchDimension(.height, toDimension: .width, withMultiplier: multiplier, relation: relation)
        return self
    }

    @discardableResult
    public func size(toView view: Any) -> Self {
        self.view?.__fw_matchDimension(.width, toDimension: .width, ofView: view)
        self.view?.__fw_matchDimension(.height, toDimension: .height, ofView: view)
        return self
    }

    @discardableResult
    public func width(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw_matchDimension(.width, toDimension: .width, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func width(toView view: Any, offset: CGFloat, relation: NSLayoutConstraint.Relation) -> Self {
        self.view?.__fw_matchDimension(.width, toDimension: .width, ofView: view, withOffset: offset, relation: relation)
        return self
    }
    
    @discardableResult
    public func height(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.__fw_matchDimension(.height, toDimension: .height, ofView: view, withOffset: offset)
        return self
    }

    @discardableResult
    public func height(toView view: Any, offset: CGFloat, relation: NSLayoutConstraint.Relation) -> Self {
        self.view?.__fw_matchDimension(.height, toDimension: .height, ofView: view, withOffset: offset, relation: relation)
        return self
    }

    @discardableResult
    public func width(toView view: Any, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> Self {
        self.view?.__fw_matchDimension(.width, toDimension: .width, ofView: view, withMultiplier: multiplier, relation: relation)
        return self
    }

    @discardableResult
    public func height(toView view: Any, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> Self {
        self.view?.__fw_matchDimension(.height, toDimension: .height, ofView: view, withMultiplier: multiplier, relation: relation)
        return self
    }

    // MARK: - Attribute
    @discardableResult
    public func attribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, offset: CGFloat = 0) -> Self {
        self.view?.__fw_constrainAttribute(attribute, to: toAttribute, ofView: view, withOffset: offset)
        return self
    }
    
    @discardableResult
    public func attribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, offset: CGFloat, relation: NSLayoutConstraint.Relation) -> Self {
        self.view?.__fw_constrainAttribute(attribute, to: toAttribute, ofView: view, withOffset: offset, relation: relation)
        return self
    }

    @discardableResult
    public func attribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> Self {
        self.view?.__fw_constrainAttribute(attribute, to: toAttribute, ofView: view, withMultiplier: multiplier, relation: relation)
        return self
    }
    
    // MARK: - Offset
    @discardableResult
    public func offset(_ offset: CGFloat) -> Self {
        self.view?.__fw_setOffset(offset)
        return self
    }
    
    @discardableResult
    public func inset(_ inset: CGFloat) -> Self {
        self.view?.__fw_setInset(inset)
        return self
    }
    
    @discardableResult
    public func priority(_ priority: UILayoutPriority) -> Self {
        self.view?.__fw_setPriority(priority)
        return self
    }
    
    @discardableResult
    public func active(_ active: Bool) -> Self {
        self.view?.__fw_setActive(active)
        return self
    }
    
    @discardableResult
    public func remove() -> Self {
        if let constraints = self.view?.__fw_lastConstraints, !constraints.isEmpty {
            self.view?.__fw_removeConstraints(constraints)
        }
        return self
    }
    
    // MARK: - Constraint
    public var constraints: [NSLayoutConstraint] {
        return self.view?.__fw_lastConstraints ?? []
    }
    
    public var constraint: NSLayoutConstraint? {
        return self.view?.__fw_lastConstraint
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
