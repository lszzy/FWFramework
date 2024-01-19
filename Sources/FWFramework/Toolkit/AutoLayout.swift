//
//  AutoLayout.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

// MARK: - UIView+AutoLayout
/// UIView自动布局分类，兼容UIView和UILayoutGuide(iOS9)
/// 如果约束条件完全相同，会自动更新约束而不是重新添加。
/// 另外，默认布局方式使用LTR，如果需要RTL布局，可通过fwAutoLayoutRTL统一启用
@_spi(FW) extension UIView {
    
    // MARK: - AutoLayout
    /// 是否启用自动布局适配RTL，启用后自动将Left|Right转换为Leading|Trailing，默认NO
    ///
    /// 如果项目兼容阿拉伯语等，需要启用RTL从右向左布局，开启此开关即可，无需修改布局代码
    /// 手工切换视图左右布局方法：[UIView appearance].semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    public static var fw_autoLayoutRTL = false
    
    /// 自定义全局自动等比例缩放适配句柄，默认nil
    ///
    /// 启用全局等比例缩放后，所有offset值都会调用该句柄，需注意可能产生的影响。
    /// 启用后注意事项如下：
    /// 1. 屏幕宽度约束不能使用screenWidth约束，需要使用375设计标准
    /// 2. 尽量不使用screenWidth固定屏幕宽度方式布局，推荐相对于父视图布局
    /// 2. 只会对offset值生效，其他属性不受影响
    /// 3. 某个视图如需固定offset值，可指定autoScaleLayout为false关闭该功能
    public static var fw_autoScaleBlock: ((CGFloat) -> CGFloat)?
    
    /// 快捷启用全局自动等比例缩放布局，自动设置默认autoScaleBlock
    public static var fw_autoScaleLayout: Bool {
        get {
            fw_autoScaleBlock != nil
        }
        set {
            guard newValue != fw_autoScaleLayout else { return }
            fw_autoScaleBlock = newValue ? { UIScreen.fw_relativeValue($0, flat: fw_autoFlatLayout) } : nil
        }
    }
    
    /// 是否启用全局自动像素取整布局，默认false
    public static var fw_autoFlatLayout = false
    
    /// 视图是否自动等比例缩放布局，默认未设置时检查autoScaleBlock
    public var fw_autoScaleLayout: Bool {
        get {
            if let number = fw_propertyNumber(forName: "fw_autoScaleLayout") {
                return number.boolValue
            }
            return UIView.fw_autoScaleBlock != nil
        }
        set {
            fw_setPropertyNumber(NSNumber(value: newValue), forName: "fw_autoScaleLayout")
        }
    }

    /// 执行子视图自动布局，自动计算子视图尺寸。需先将视图添加到界面(如设置为tableHeaderView)，再调用即可(iOS8+)
    public func fw_autoLayoutSubviews() {
        // 保存当前的自动布局配置
        let translateConstraint = self.translatesAutoresizingMaskIntoConstraints
        
        // 启动自动布局，计算子视图尺寸
        self.translatesAutoresizingMaskIntoConstraints = false
        self.setNeedsLayout()
        self.layoutIfNeeded()
        
        // 还原自动布局设置
        self.translatesAutoresizingMaskIntoConstraints = translateConstraint
    }
    
    // MARK: - Compression
    /// 设置水平方向抗压缩优先级
    public var fw_compressionHorizontal: UILayoutPriority {
        get { self.contentCompressionResistancePriority(for: .horizontal) }
        set { self.setContentCompressionResistancePriority(newValue, for: .horizontal) }
    }

    /// 设置垂直方向抗压缩优先级
    public var fw_compressionVertical: UILayoutPriority {
        get { self.contentCompressionResistancePriority(for: .vertical) }
        set { self.setContentCompressionResistancePriority(newValue, for: .vertical) }
    }

    /// 设置水平方向抗拉伸优先级
    public var fw_huggingHorizontal: UILayoutPriority {
        get { self.contentHuggingPriority(for: .horizontal) }
        set { self.setContentHuggingPriority(newValue, for: .horizontal) }
    }

    /// 设置垂直方向抗拉伸优先级
    public var fw_huggingVertical: UILayoutPriority {
        get { self.contentHuggingPriority(for: .vertical) }
        set { self.setContentHuggingPriority(newValue, for: .vertical) }
    }
    
    // MARK: - Collapse
    /// 设置视图是否收缩，默认NO为原始值，YES时为收缩值
    public var fw_isCollapsed: Bool {
        get {
            return fw_propertyBool(forName: "fw_isCollapsed")
        }
        set {
            // 为了防止修改active时约束冲突，始终将已激活的约束放到前面修改
            fw_collapseConstraints.sorted { constraint, _ in
                guard constraint.fw_shouldCollapseActive else { return false }
                return newValue ? constraint.fw_originalActive : !constraint.fw_originalActive
            }.forEach { constraint in
                constraint.fw_isCollapsed = newValue
            }
            
            fw_setPropertyBool(newValue, forName: "fw_isCollapsed")
        }
    }

    /// 设置视图是否自动收缩，如image为nil，text为nil、@""时自动收缩，默认NO
    public var fw_autoCollapse: Bool {
        get { fw_propertyBool(forName: "fw_autoCollapse") }
        set { fw_setPropertyBool(newValue, forName: "fw_autoCollapse") }
    }

    /// 设置视图是否隐藏时自动收缩、显示时自动展开，默认NO
    public var fw_hiddenCollapse: Bool {
        get { fw_propertyBool(forName: "fw_hiddenCollapse") }
        set { fw_setPropertyBool(newValue, forName: "fw_hiddenCollapse") }
    }

    /// 添加视图的偏移收缩约束，必须先添加才能生效
    ///
    /// - see: [UIView-FDCollapsibleConstraints](https://github.com/forkingdog/UIView-FDCollapsibleConstraints)
    public func fw_addCollapseConstraint(_ constraint: NSLayoutConstraint, offset: CGFloat? = nil) {
        if let offset = offset {
            constraint.fw_collapseOffset = offset
        }
        constraint.fw_shouldCollapseOffset = true
        if !fw_collapseConstraints.contains(constraint) {
            fw_collapseConstraints.append(constraint)
        }
    }
    
    /// 添加视图的有效性收缩约束，必须先添加才能生效
    public func fw_addCollapseActiveConstraint(_ constraint: NSLayoutConstraint, active: Bool? = nil) {
        if let active = active {
            constraint.isActive = active
        }
        constraint.fw_shouldCollapseActive = true
        if !fw_collapseConstraints.contains(constraint) {
            fw_collapseConstraints.append(constraint)
        }
    }
    
    /// 添加视图的优先级收缩约束，必须先添加才能生效
    public func fw_addCollapsePriorityConstraint(_ constraint: NSLayoutConstraint, priority: UILayoutPriority? = nil) {
        if let priority = priority {
            constraint.fw_collapsePriority = priority
        }
        constraint.fw_shouldCollapsePriority = true
        if !fw_collapseConstraints.contains(constraint) {
            fw_collapseConstraints.append(constraint)
        }
    }
    
    /// 移除指定的视图收缩约束
    public func fw_removeCollapseConstraint(_ constraint: NSLayoutConstraint) {
        fw_collapseConstraints.removeAll { $0 == constraint }
    }
    
    /// 移除所有的视图收缩约束
    public func fw_removeAllCollapseConstraints() {
        fw_collapseConstraints.removeAll()
    }
    
    fileprivate var fw_collapseConstraints: [NSLayoutConstraint] {
        get { return fw_property(forName: "fw_collapseConstraints") as? [NSLayoutConstraint] ?? [] }
        set { fw_setProperty(newValue, forName: "fw_collapseConstraints") }
    }
    
    // MARK: - Axis
    /// 父视图居中，可指定偏移距离
    /// - Parameter offset: 偏移距离，默认zero
    /// - Returns: 约束数组
    @discardableResult
    public func fw_alignCenter(toSuperview offset: CGPoint = .zero) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        constraints.append(fw_alignAxis(toSuperview: .centerX, offset: offset.x))
        constraints.append(fw_alignAxis(toSuperview: .centerY, offset: offset.y))
        fw_lastConstraints = constraints
        return constraints
    }
    
    /// 父视图属性居中，可指定偏移距离
    /// - Parameters:
    ///   - axis: 居中属性
    ///   - offset: 偏移距离，默认0
    /// - Returns: 布局约束
    @discardableResult
    public func fw_alignAxis(toSuperview axis: NSLayoutConstraint.Attribute, offset: CGFloat = 0) -> NSLayoutConstraint {
        return fw_constrainAttribute(axis, toSuperview: self.superview, offset: offset, relation: .equal, priority: .required)
    }
    
    /// 与另一视图居中相同，可指定偏移距离
    /// - Parameters:
    ///   - axis: 居中属性
    ///   - toView: 另一视图或UILayoutGuide，下同
    ///   - offset: 偏移距离，默认0
    /// - Returns: 布局约束
    @discardableResult
    public func fw_alignAxis(_ axis: NSLayoutConstraint.Attribute, toView: Any, offset: CGFloat = 0) -> NSLayoutConstraint {
        return fw_constrainAttribute(axis, toAttribute: axis, ofView: toView, offset: offset)
    }

    /// 与另一视图居中指定比例
    /// - Parameters:
    ///   - axis: 居中属性
    ///   - toView: 另一视图
    ///   - multiplier: 指定比例
    /// - Returns: 布局约束
    @discardableResult
    public func fw_alignAxis(_ axis: NSLayoutConstraint.Attribute, toView: Any, multiplier: CGFloat) -> NSLayoutConstraint {
        return fw_constrainAttribute(axis, toAttribute: axis, ofView: toView, multiplier: multiplier)
    }
    
    // MARK: - Edge
    /// 与父视图四条边属性相同，可指定insets距离
    /// - Parameter insets: 指定距离insets，默认zero
    /// - Returns: 约束数组
    @discardableResult
    public func fw_pinEdges(toSuperview insets: UIEdgeInsets = .zero) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        constraints.append(fw_pinEdge(toSuperview: .top, inset: insets.top))
        constraints.append(fw_pinEdge(toSuperview: .left, inset: insets.left))
        constraints.append(fw_pinEdge(toSuperview: .bottom, inset: insets.bottom))
        constraints.append(fw_pinEdge(toSuperview: .right, inset: insets.right))
        fw_lastConstraints = constraints
        return constraints
    }

    /// 与父视图三条边属性距离指定距离
    /// - Parameters:
    ///   - insets: 指定距离insets
    ///   - excludingEdge: 排除的边
    /// - Returns: 约束数组
    @discardableResult
    public func fw_pinEdges(toSuperview insets: UIEdgeInsets = .zero, excludingEdge: NSLayoutConstraint.Attribute) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        if excludingEdge != .top {
            constraints.append(fw_pinEdge(toSuperview: .top, inset: insets.top))
        }
        if excludingEdge != .leading && excludingEdge != .left {
            constraints.append(fw_pinEdge(toSuperview: .left, inset: insets.left))
        }
        if excludingEdge != .bottom {
            constraints.append(fw_pinEdge(toSuperview: .bottom, inset: insets.bottom))
        }
        if excludingEdge != .trailing && excludingEdge != .right {
            constraints.append(fw_pinEdge(toSuperview: .right, inset: insets.right))
        }
        fw_lastConstraints = constraints
        return constraints
    }
    
    /// 与父视图水平方向两条边属性相同，可指定偏移距离
    /// - Parameters:
    ///   - inset: 偏移距离
    /// - Returns: 约束数组
    @discardableResult
    public func fw_pinHorizontal(toSuperview inset: CGFloat = .zero) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        constraints.append(fw_pinEdge(toSuperview: .left, inset: inset))
        constraints.append(fw_pinEdge(toSuperview: .right, inset: inset))
        fw_lastConstraints = constraints
        return constraints
    }
    
    /// 与父视图垂直方向两条边属性相同，可指定偏移距离
    /// - Parameters:
    ///   - inset: 偏移距离
    /// - Returns: 约束数组
    @discardableResult
    public func fw_pinVertical(toSuperview inset: CGFloat = .zero) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        constraints.append(fw_pinEdge(toSuperview: .top, inset: inset))
        constraints.append(fw_pinEdge(toSuperview: .bottom, inset: inset))
        fw_lastConstraints = constraints
        return constraints
    }
    
    /// 与父视图边属性相同，可指定偏移距离和关系
    /// - Parameters:
    ///   - edge: 指定边属性
    ///   - inset: 偏移距离，默认0
    ///   - relation: 约束关系，默认相等
    ///   - priority: 约束优先级，默认required
    /// - Returns: 布局约束
    @discardableResult
    public func fw_pinEdge(toSuperview edge: NSLayoutConstraint.Attribute, inset: CGFloat = .zero, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
        return fw_constrainAttribute(edge, toSuperview: self.superview, offset: inset, relation: relation, priority: priority)
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
    public func fw_pinEdge(_ edge: NSLayoutConstraint.Attribute, toEdge: NSLayoutConstraint.Attribute, ofView: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
        return fw_constrainAttribute(edge, toAttribute: toEdge, ofView: ofView, offset: offset, relation: relation, priority: priority)
    }
    
    // MARK: - SafeArea
    /// 父视图安全区域居中，可指定偏移距离。iOS11以下使用Superview实现，下同
    /// - Parameter offset: 偏移距离
    /// - Returns: 约束数组
    @discardableResult
    public func fw_alignCenter(toSafeArea offset: CGPoint) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        constraints.append(fw_alignAxis(toSafeArea: .centerX, offset: offset.x))
        constraints.append(fw_alignAxis(toSafeArea: .centerY, offset: offset.y))
        fw_lastConstraints = constraints
        return constraints
    }
    
    /// 父视图安全区域属性居中，可指定偏移距离
    /// - Parameters:
    ///   - axis: 居中属性
    ///   - offset: 偏移距离，默认0
    /// - Returns: 布局约束
    @discardableResult
    public func fw_alignAxis(toSafeArea axis: NSLayoutConstraint.Attribute, offset: CGFloat = .zero) -> NSLayoutConstraint {
        return fw_constrainAttribute(axis, toSuperview: self.superview?.safeAreaLayoutGuide, offset: offset, relation: .equal, priority: .required)
    }

    /// 与父视图安全区域四条边属性相同，可指定距离insets
    /// - Parameter insets: 指定距离insets
    /// - Returns: 约束数组
    @discardableResult
    public func fw_pinEdges(toSafeArea insets: UIEdgeInsets) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        constraints.append(fw_pinEdge(toSafeArea: .top, inset: insets.top))
        constraints.append(fw_pinEdge(toSafeArea: .left, inset: insets.left))
        constraints.append(fw_pinEdge(toSafeArea: .bottom, inset: insets.bottom))
        constraints.append(fw_pinEdge(toSafeArea: .right, inset: insets.right))
        fw_lastConstraints = constraints
        return constraints
    }

    /// 与父视图安全区域三条边属性距离指定距离
    /// - Parameters:
    ///   - insets: 指定距离insets
    ///   - excludingEdge: 排除的边
    /// - Returns: 约束数组
    @discardableResult
    public func fw_pinEdges(toSafeArea insets: UIEdgeInsets, excludingEdge: NSLayoutConstraint.Attribute) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        if excludingEdge != .top {
            constraints.append(fw_pinEdge(toSafeArea: .top, inset: insets.top))
        }
        if excludingEdge != .leading && excludingEdge != .left {
            constraints.append(fw_pinEdge(toSafeArea: .left, inset: insets.left))
        }
        if excludingEdge != .bottom {
            constraints.append(fw_pinEdge(toSafeArea: .bottom, inset: insets.bottom))
        }
        if excludingEdge != .trailing && excludingEdge != .right {
            constraints.append(fw_pinEdge(toSafeArea: .right, inset: insets.right))
        }
        fw_lastConstraints = constraints
        return constraints
    }

    /// 与父视图安全区域水平方向两条边属性相同，可指定偏移距离
    /// - Parameters:
    ///   - inset: 偏移距离
    /// - Returns: 约束数组
    @discardableResult
    public func fw_pinHorizontal(toSafeArea inset: CGFloat) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        constraints.append(fw_pinEdge(toSafeArea: .left, inset: inset))
        constraints.append(fw_pinEdge(toSafeArea: .right, inset: inset))
        fw_lastConstraints = constraints
        return constraints
    }
    
    /// 与父视图安全区域垂直方向两条边属性相同，可指定偏移距离
    /// - Parameters:
    ///   - inset: 偏移距离
    /// - Returns: 约束数组
    @discardableResult
    public func fw_pinVertical(toSafeArea inset: CGFloat) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        constraints.append(fw_pinEdge(toSafeArea: .top, inset: inset))
        constraints.append(fw_pinEdge(toSafeArea: .bottom, inset: inset))
        fw_lastConstraints = constraints
        return constraints
    }
    
    /// 与父视图安全区域边属性相同，可指定偏移距离和关系
    /// - Parameters:
    ///   - edge: 指定边属性
    ///   - inset: 偏移距离，默认0
    ///   - relation: 约束关系，默认相等
    ///   - priority: 约束优先级，默认required
    /// - Returns: 布局约束
    @discardableResult
    public func fw_pinEdge(toSafeArea edge: NSLayoutConstraint.Attribute, inset: CGFloat = .zero, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
        return fw_constrainAttribute(edge, toSuperview: self.superview?.safeAreaLayoutGuide, offset: inset, relation: relation, priority: priority)
    }
    
    // MARK: - Dimension
    /// 设置宽高尺寸
    /// - Parameter size: 尺寸大小
    /// - Returns: 约束数组
    @discardableResult
    public func fw_setDimensions(_ size: CGSize) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        constraints.append(fw_setDimension(.width, size: size.width))
        constraints.append(fw_setDimension(.height, size: size.height))
        fw_lastConstraints = constraints
        return constraints
    }

    /// 设置某个尺寸，可指定关系
    /// - Parameters:
    ///   - dimension: 尺寸属性
    ///   - size: 尺寸大小
    ///   - relation: 约束关系，默认相等
    ///   - priority: 约束优先级，默认required
    /// - Returns: 布局约束
    @discardableResult
    public func fw_setDimension(_ dimension: NSLayoutConstraint.Attribute, size: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
        return fw_constrainAttribute(dimension, toAttribute: .notAnAttribute, ofView: nil, multiplier: 0, offset: size, relation: relation, priority: priority)
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
    public func fw_matchDimension(_ dimension: NSLayoutConstraint.Attribute, toDimension: NSLayoutConstraint.Attribute, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
        return fw_matchDimension(dimension, toDimension: toDimension, ofView: self, multiplier: multiplier, relation: relation, priority: priority)
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
    public func fw_matchDimension(_ dimension: NSLayoutConstraint.Attribute, toDimension: NSLayoutConstraint.Attribute, ofView: Any, offset: CGFloat = .zero, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
        return fw_constrainAttribute(dimension, toAttribute: toDimension, ofView: ofView, offset: offset, relation: relation, priority: priority)
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
    public func fw_matchDimension(_ dimension: NSLayoutConstraint.Attribute, toDimension: NSLayoutConstraint.Attribute, ofView: Any, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
        return fw_constrainAttribute(dimension, toAttribute: toDimension, ofView: ofView, multiplier: multiplier, relation: relation, priority: priority)
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
    public func fw_constrainAttribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView: Any?, offset: CGFloat = .zero, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
        return fw_constrainAttribute(attribute, toAttribute: toAttribute, ofView: ofView, multiplier: 1.0, offset: offset, relation: relation, priority: priority)
    }

    /// 与指定视图属性指定比例，指定关系
    /// - Parameters:
    ///   - attribute: 指定属性
    ///   - toAttribute: 目标视图属性
    ///   - ofView: 目标视图
    ///   - multiplier: 指定比例
    ///   - offset: 偏移距离
    ///   - relation: 约束关系
    ///   - priority: 约束优先级，默认required
    /// - Returns: 布局约束
    @discardableResult
    public func fw_constrainAttribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView: Any?, multiplier: CGFloat, offset: CGFloat = .zero, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
        return fw_constrainAttribute(attribute, toAttribute: toAttribute, ofView: ofView, multiplier: multiplier, offset: offset, relation: relation, priority: priority, isOpposite: false)
    }
    
    // MARK: - Constraint
    /// 获取添加的与父视图属性的约束，指定关系
    /// - Parameters:
    ///   - attribute: 指定属性
    ///   - relation: 约束关系
    /// - Returns: 布局约束
    public func fw_constraint(toSuperview attribute: NSLayoutConstraint.Attribute, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint? {
        return fw_constraint(attribute, toSuperview: self.superview, relation: relation)
    }

    /// 获取添加的与父视图安全区域属性的约束，指定关系
    /// - Parameters:
    ///   - attribute: 指定属性
    ///   - relation: 约束关系
    /// - Returns: 布局约束
    public func fw_constraint(toSafeArea attribute: NSLayoutConstraint.Attribute, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint? {
        return fw_constraint(attribute, toSuperview: self.superview?.safeAreaLayoutGuide, relation: relation)
    }
    
    private func fw_constraint(_ attribute: NSLayoutConstraint.Attribute, toSuperview superview: Any?, relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint? {
        assert(self.superview != nil, "View's superview must not be nil.\nView: \(self)")
        var targetRelation = relation
        if attribute == .bottom || attribute == .right || attribute == .trailing {
            if relation == .lessThanOrEqual {
                targetRelation = .greaterThanOrEqual
            } else if relation == .greaterThanOrEqual {
                targetRelation = .lessThanOrEqual
            }
        }
        return fw_constraint(attribute, toAttribute: attribute, ofView: superview, multiplier: 1.0, relation: targetRelation)
    }

    /// 获取添加的与指定视图属性的约束，指定关系
    /// - Parameters:
    ///   - attribute: 指定属性
    ///   - toAttribute: 目标视图属性
    ///   - ofView: 目标视图
    ///   - relation: 约束关系
    /// - Returns: 布局约束
    public func fw_constraint(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView: Any?, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint? {
        return fw_constraint(attribute, toAttribute: toAttribute, ofView: ofView, multiplier: 1.0, relation: relation)
    }

    /// 获取添加的与指定视图属性指定比例的约束，指定关系
    /// - Parameters:
    ///   - attribute: 指定属性
    ///   - toAttribute: 目标视图属性
    ///   - ofView: 目标视图
    ///   - multiplier: 指定比例
    ///   - relation: 约束关系
    /// - Returns: 布局约束
    public func fw_constraint(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView: Any?, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint? {
        var targetAttribute = attribute
        var targetToAttribute = toAttribute
        if UIView.fw_autoLayoutRTL {
            switch attribute {
            case .left:
                targetAttribute = .leading
            case .right:
                targetAttribute = .trailing
            case .leftMargin:
                targetAttribute = .leadingMargin
            case .rightMargin:
                targetAttribute = .trailingMargin
            default:
                break
            }
            switch toAttribute {
            case .left:
                targetToAttribute = .leading
            case .right:
                targetToAttribute = .trailing
            case .leftMargin:
                targetToAttribute = .leadingMargin
            case .rightMargin:
                targetToAttribute = .trailingMargin
            default:
                break
            }
        }
        
        // 自动生成唯一约束标记，存在则获取之
        let constraintIdentifier = fw_constraintIdentifier(targetAttribute, toAttribute: targetToAttribute, ofView: ofView, multiplier: multiplier, relation: relation)
        return fw_constraint(identifier: constraintIdentifier)
    }
    
    /// 根据唯一标志获取布局约束
    /// - Parameters:
    ///   - identifier: 唯一标志
    /// - Returns: 布局约束
    public func fw_constraint(identifier: String?) -> NSLayoutConstraint? {
        guard let identifier = identifier, !identifier.isEmpty else { return nil }
        return fw_allConstraints.first { obj in
            return identifier == obj.fw_layoutIdentifier || identifier == obj.identifier
        }
    }
    
    /// 最近一批添加或更新的布局约束
    public var fw_lastConstraints: [NSLayoutConstraint] {
        get { return fw_property(forName: "fw_lastConstraints") as? [NSLayoutConstraint] ?? [] }
        set { fw_setProperty(newValue, forName: "fw_lastConstraints") }
    }
    
    /// 获取当前所有约束
    public private(set) var fw_allConstraints: [NSLayoutConstraint] {
        get { return fw_property(forName: "fw_allConstraints") as? [NSLayoutConstraint] ?? [] }
        set { fw_setProperty(newValue, forName: "fw_allConstraints") }
    }
    
    /// 移除当前指定约束数组
    /// - Parameter constraints: 布局约束数组
    public func fw_removeConstraints(_ constraints: [NSLayoutConstraint]?) {
        guard let constraints = constraints, !constraints.isEmpty else { return }
        NSLayoutConstraint.deactivate(constraints)
        fw_allConstraints.removeAll { constraints.contains($0) }
        fw_lastConstraints.removeAll { constraints.contains($0) }
    }
    
    /// 移除当前所有约束
    public func fw_removeAllConstraints() {
        NSLayoutConstraint.deactivate(fw_allConstraints)
        fw_allConstraints.removeAll()
        fw_lastConstraints.removeAll()
    }
    
    // MARK: - Private
    private func fw_constrainAttribute(_ attribute: NSLayoutConstraint.Attribute, toSuperview superview: Any?, offset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority) -> NSLayoutConstraint {
        assert(self.superview != nil, "View's superview must not be nil.\nView: \(self)")
        var isOpposite = false
        var targetRelation = relation
        if attribute == .bottom || attribute == .right || attribute == .trailing {
            isOpposite = true
            if relation == .lessThanOrEqual {
                targetRelation = .greaterThanOrEqual
            } else if relation == .greaterThanOrEqual {
                targetRelation = .lessThanOrEqual
            }
        }
        
        return fw_constrainAttribute(attribute, toAttribute: attribute, ofView: superview, multiplier: 1.0, offset: offset, relation: targetRelation, priority: priority, isOpposite: isOpposite)
    }
    
    private func fw_constrainAttribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView: Any?, multiplier: CGFloat, offset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority, isOpposite: Bool) -> NSLayoutConstraint {
        var targetAttribute = attribute
        var targetToAttribute = toAttribute
        if UIView.fw_autoLayoutRTL {
            switch attribute {
            case .left:
                targetAttribute = .leading
            case .right:
                targetAttribute = .trailing
            case .leftMargin:
                targetAttribute = .leadingMargin
            case .rightMargin:
                targetAttribute = .trailingMargin
            default:
                break
            }
            switch toAttribute {
            case .left:
                targetToAttribute = .leading
            case .right:
                targetToAttribute = .trailing
            case .leftMargin:
                targetToAttribute = .leadingMargin
            case .rightMargin:
                targetToAttribute = .trailingMargin
            default:
                break
            }
        }
        
        self.translatesAutoresizingMaskIntoConstraints = false
        // 自动生成唯一约束标记，存在则更新，否则添加
        let constraintIdentifier = fw_constraintIdentifier(targetAttribute, toAttribute: targetToAttribute, ofView: ofView, multiplier: multiplier, relation: relation)
        var targetConstraint: NSLayoutConstraint
        if let constraint = fw_constraint(identifier: constraintIdentifier) {
            targetConstraint = constraint
        } else {
            targetConstraint = NSLayoutConstraint(item: self, attribute: targetAttribute, relatedBy: relation, toItem: ofView, attribute: targetToAttribute, multiplier: multiplier, constant: 0)
            targetConstraint.fw_isOpposite = isOpposite
            targetConstraint.fw_layoutIdentifier = constraintIdentifier
            targetConstraint.identifier = constraintIdentifier
            fw_allConstraints.append(targetConstraint)
        }
        fw_lastConstraints = [targetConstraint]
        targetConstraint.fw_offset = offset
        if targetConstraint.priority != priority {
            targetConstraint.priority = priority
        }
        if !targetConstraint.isActive {
            targetConstraint.isActive = true
        }
        return targetConstraint
    }
    
    private func fw_constraintIdentifier(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView: Any?, multiplier: CGFloat, relation: NSLayoutConstraint.Relation) -> String {
        var viewHash = ""
        if let ofView = ofView as? NSObject {
            viewHash = "\(ofView.hash)"
        } else if let ofView = ofView {
            viewHash = String(describing: ofView)
        }
        return String(format: "%ld-%ld-%@-%ld-%@", attribute.rawValue, relation.rawValue, viewHash, toAttribute.rawValue, NSNumber(value: multiplier))
    }
    
    fileprivate static func fw_swizzleAutoLayoutView() {
        NSObject.fw_swizzleInstanceMethod(
            UIView.self,
            selector: #selector(UIView.updateConstraints),
            methodSignature: (@convention(c) (UIView, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UIView) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            
            if selfObject.fw_autoCollapse && selfObject.fw_collapseConstraints.count > 0 {
                // Absent意味着视图没有固有size，即{-1, -1}
                let absentIntrinsicContentSize = CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
                // 计算固有尺寸
                let contentSize = selfObject.intrinsicContentSize
                // 如果视图没有固定尺寸，自动设置约束
                if contentSize.equalTo(absentIntrinsicContentSize) || contentSize.equalTo(.zero) {
                    selfObject.fw_isCollapsed = true
                } else {
                    selfObject.fw_isCollapsed = false
                }
            }
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UIView.self,
            selector: #selector(setter: UIView.isHidden),
            methodSignature: (@convention(c) (UIView, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) (UIView, Bool) -> Void).self
        ) { store in { selfObject, hidden in
            store.original(selfObject, store.selector, hidden)
            
            if selfObject.fw_hiddenCollapse && selfObject.fw_collapseConstraints.count > 0 {
                selfObject.fw_isCollapsed = hidden
            }
        }}
    }
    
}

// MARK: - UILayoutPriority+AutoLayout
extension UILayoutPriority {
    
    /// 中优先级，500
    public static let defaultMedium: UILayoutPriority = .init(500)
    
}

// MARK: - NSLayoutConstraint+AutoLayout
@_spi(FW) extension NSLayoutConstraint {
    
    /// 设置偏移值，根据配置自动等比例缩放和取反
    public var fw_offset: CGFloat {
        get {
            fw_propertyDouble(forName: "fw_offset")
        }
        set {
            fw_setPropertyDouble(newValue, forName: "fw_offset")
            
            var autoScaleLayout = UIView.fw_autoScaleLayout
            if let view = firstItem as? UIView {
                autoScaleLayout = view.fw_autoScaleLayout
            } else if let view = (firstItem as? UILayoutGuide)?.owningView {
                autoScaleLayout = view.fw_autoScaleLayout
            }
            let offset = autoScaleLayout ? (UIView.fw_autoScaleBlock?(newValue) ?? newValue) : newValue
            self.constant = fw_isOpposite ? -offset : offset
        }
    }
    
    /// 标记是否是相反的约束，一般相对于父视图
    public var fw_isOpposite: Bool {
        get { fw_propertyBool(forName: "fw_isOpposite") }
        set { fw_setPropertyBool(newValue, forName: "fw_isOpposite") }
    }
    
    /// 可收缩约束的收缩偏移值，默认0
    public var fw_collapseOffset: CGFloat {
        get { fw_propertyDouble(forName: "fw_collapseOffset") }
        set { fw_setPropertyDouble(newValue, forName: "fw_collapseOffset") }
    }
    
    /// 可收缩约束的原始偏移值，默认为添加收缩约束时的值，未添加时为0
    public var fw_originalOffset: CGFloat {
        get { fw_propertyDouble(forName: "fw_originalOffset") }
        set { fw_setPropertyDouble(newValue, forName: "fw_originalOffset") }
    }
    
    /// 可收缩约束的收缩优先级，默认defaultLow。注意Required不能修改，否则iOS13以下崩溃
    public var fw_collapsePriority: UILayoutPriority {
        get {
            if let number = fw_propertyNumber(forName: "fw_collapsePriority") {
                return .init(number.floatValue)
            }
            return .defaultLow
        }
        set {
            fw_setPropertyNumber(NSNumber(value: newValue.rawValue), forName: "fw_collapsePriority")
        }
    }
    
    /// 可收缩约束的原始优先级，默认为添加收缩约束时的值，未添加时为defaultHigh。注意Required不能修改，否则iOS13以下崩溃
    public var fw_originalPriority: UILayoutPriority {
        get {
            if let number = fw_propertyNumber(forName: "fw_originalPriority") {
                return .init(number.floatValue)
            }
            return .defaultHigh
        }
        set {
            fw_setPropertyNumber(NSNumber(value: priority.rawValue), forName: "fw_originalPriority")
        }
    }
    
    /// 可收缩约束的原始有效值，默认为添加收缩约束时的有效值，未添加时为false
    public var fw_originalActive: Bool {
        get {
            if let number = fw_propertyNumber(forName: "fw_originalActive") {
                return number.boolValue
            }
            return false
        }
        set {
            fw_setPropertyNumber(NSNumber(value: newValue), forName: "fw_originalActive")
        }
    }
    
    /// 约束偏移是否可收缩，默认false，开启时自动初始化originalOffset
    public var fw_shouldCollapseOffset: Bool {
        get {
            fw_propertyBool(forName: "fw_shouldCollapseOffset")
        }
        set {
            guard newValue != fw_shouldCollapseOffset else { return }
            if newValue { fw_originalOffset = self.fw_offset }
            fw_setPropertyBool(newValue, forName: "fw_shouldCollapseOffset")
        }
    }
    
    /// 约束有效性是否可收缩，默认false，开启时自动初始化originalActive
    public var fw_shouldCollapseActive: Bool {
        get {
            fw_propertyBool(forName: "fw_shouldCollapseActive")
        }
        set {
            guard newValue != fw_shouldCollapseActive else { return }
            if newValue { fw_originalActive = self.isActive }
            fw_setPropertyBool(newValue, forName: "fw_shouldCollapseActive")
        }
    }
    
    /// 约束优先级是否可收缩，默认false，开启时自动初始化originalPriority
    public var fw_shouldCollapsePriority: Bool {
        get {
            fw_propertyBool(forName: "fw_shouldCollapsePriority")
        }
        set {
            guard newValue != fw_shouldCollapsePriority else { return }
            if newValue { fw_originalPriority = self.priority }
            fw_setPropertyBool(newValue, forName: "fw_shouldCollapsePriority")
        }
    }
    
    /// 自动布局是否收缩，启用收缩后生效，默认NO为原始值，YES时为收缩值
    public var fw_isCollapsed: Bool {
        get {
            return fw_propertyBool(forName: "fw_isCollapsed")
        }
        set {
            if fw_shouldCollapseActive {
                self.isActive = newValue ? !fw_originalActive : fw_originalActive
            }
            if fw_shouldCollapsePriority {
                self.priority = newValue ? fw_collapsePriority : fw_originalPriority
            }
            if fw_shouldCollapseOffset {
                self.fw_offset = newValue ? fw_collapseOffset : fw_originalOffset
            }
            
            fw_setPropertyBool(newValue, forName: "fw_isCollapsed")
        }
    }
    
    fileprivate var fw_layoutIdentifier: String? {
        get { fw_property(forName: "fw_layoutIdentifier") as? String }
        set { fw_setPropertyCopy(newValue, forName: "fw_layoutIdentifier") }
    }
    
}

// MARK: - FrameworkAutoloader+AutoLayout
@objc extension FrameworkAutoloader {
    
    static func loadToolkit_AutoLayout() {
        UIView.fw_swizzleAutoLayoutView()
        if UIView.fw_autoLayoutDebug {
            UIView.fw_swizzleAutoLayoutDebug()
        }
    }
    
}

// MARK: - LayoutChain
/// 视图链式布局类。如果约束条件完全相同，会自动更新约束而不是重新添加。
/// 另外，默认布局方式使用LTR，如果需要RTL布局，可通过autoLayoutRTL统一启用
public class LayoutChain {
    
    // MARK: - Accessor
    /// 布局视图
    public private(set) weak var view: UIView?

    // MARK: - Lifecycle
    /// 构造方法
    public required init(view: UIView?) {
        self.view = view
    }

    // MARK: - Install
    @discardableResult
    public func remake() -> Self {
        view?.fw_removeAllConstraints()
        return self
    }
    
    @discardableResult
    public func autoScale(_ autoScale: Bool) -> Self {
        view?.fw_autoScaleLayout = autoScale
        return self
    }

    // MARK: - Compression
    @discardableResult
    public func compression(horizontal priority: UILayoutPriority) -> Self {
        view?.fw_compressionHorizontal = priority
        return self
    }

    @discardableResult
    public func compression(vertical priority: UILayoutPriority) -> Self {
        view?.fw_compressionVertical = priority
        return self
    }
    
    @discardableResult
    public func hugging(horizontal priority: UILayoutPriority) -> Self {
        view?.fw_huggingHorizontal = priority
        return self
    }

    @discardableResult
    public func hugging(vertical priority: UILayoutPriority) -> Self {
        view?.fw_huggingVertical = priority
        return self
    }
    
    // MARK: - Collapse
    @discardableResult
    public func isCollapsed(_ isCollapsed: Bool) -> Self {
        view?.fw_isCollapsed = isCollapsed
        return self
    }

    @discardableResult
    public func autoCollapse(_ autoCollapse: Bool) -> Self {
        view?.fw_autoCollapse = autoCollapse
        return self
    }
    
    @discardableResult
    public func hiddenCollapse(_ hiddenCollapse: Bool) -> Self {
        view?.fw_hiddenCollapse = hiddenCollapse
        return self
    }

    // MARK: - Axis
    @discardableResult
    public func center(_ offset: CGPoint = .zero) -> Self {
        view?.fw_alignCenter(toSuperview: offset)
        return self
    }

    @discardableResult
    public func centerX(_ offset: CGFloat = .zero) -> Self {
        view?.fw_alignAxis(toSuperview: .centerX, offset: offset)
        return self
    }

    @discardableResult
    public func centerY(_ offset: CGFloat = .zero) -> Self {
        view?.fw_alignAxis(toSuperview: .centerY, offset: offset)
        return self
    }

    @discardableResult
    public func center(toView view: Any) -> Self {
        var constraints: [NSLayoutConstraint] = []
        if let constraint = self.view?.fw_alignAxis(.centerX, toView: view) {
            constraints.append(constraint)
        }
        if let constraint = self.view?.fw_alignAxis(.centerY, toView: view) {
            constraints.append(constraint)
        }
        self.view?.fw_lastConstraints = constraints
        return self
    }

    @discardableResult
    public func centerX(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.fw_alignAxis(.centerX, toView: view, offset: offset)
        return self
    }

    @discardableResult
    public func centerY(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.fw_alignAxis(.centerY, toView: view, offset: offset)
        return self
    }

    @discardableResult
    public func centerX(toView view: Any, multiplier: CGFloat) -> Self {
        self.view?.fw_alignAxis(.centerX, toView: view, multiplier: multiplier)
        return self
    }

    @discardableResult
    public func centerY(toView view: Any, multiplier: CGFloat) -> Self {
        self.view?.fw_alignAxis(.centerY, toView: view, multiplier: multiplier)
        return self
    }

    // MARK: - Edge
    @discardableResult
    public func edges(_ insets: UIEdgeInsets = UIEdgeInsets.zero) -> Self {
        view?.fw_pinEdges(toSuperview: insets)
        return self
    }
    
    @discardableResult
    public func edges(_ insets: UIEdgeInsets = UIEdgeInsets.zero, excludingEdge edge: NSLayoutConstraint.Attribute) -> Self {
        view?.fw_pinEdges(toSuperview: insets, excludingEdge: edge)
        return self
    }

    @discardableResult
    public func horizontal(_ inset: CGFloat = .zero) -> Self {
        view?.fw_pinHorizontal(toSuperview: inset)
        return self
    }

    @discardableResult
    public func vertical(_ inset: CGFloat = .zero) -> Self {
        view?.fw_pinVertical(toSuperview: inset)
        return self
    }
    
    @discardableResult
    public func top(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw_pinEdge(toSuperview: .top, inset: inset, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func bottom(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw_pinEdge(toSuperview: .bottom, inset: inset, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func left(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw_pinEdge(toSuperview: .left, inset: inset, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func right(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw_pinEdge(toSuperview: .right, inset: inset, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func top(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw_pinEdge(.top, toEdge: .top, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func bottom(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw_pinEdge(.bottom, toEdge: .bottom, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func left(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw_pinEdge(.left, toEdge: .left, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func right(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw_pinEdge(.right, toEdge: .right, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func horizontal(toView view: Any) -> Self {
        var constraints: [NSLayoutConstraint] = []
        if let constraint = self.view?.fw_pinEdge(.left, toEdge: .left, ofView: view) {
            constraints.append(constraint)
        }
        if let constraint = self.view?.fw_pinEdge(.right, toEdge: .right, ofView: view) {
            constraints.append(constraint)
        }
        self.view?.fw_lastConstraints = constraints
        return self
    }
    
    @discardableResult
    public func vertical(toView view: Any) -> Self {
        var constraints: [NSLayoutConstraint] = []
        if let constraint = self.view?.fw_pinEdge(.top, toEdge: .top, ofView: view) {
            constraints.append(constraint)
        }
        if let constraint = self.view?.fw_pinEdge(.bottom, toEdge: .bottom, ofView: view) {
            constraints.append(constraint)
        }
        self.view?.fw_lastConstraints = constraints
        return self
    }
    
    @discardableResult
    public func top(toViewBottom view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw_pinEdge(.top, toEdge: .bottom, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func bottom(toViewTop view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw_pinEdge(.bottom, toEdge: .top, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func left(toViewRight view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw_pinEdge(.left, toEdge: .right, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func right(toViewLeft view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw_pinEdge(.right, toEdge: .left, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    // MARK: - SafeArea
    @discardableResult
    public func center(toSafeArea offset: CGPoint) -> Self {
        view?.fw_alignCenter(toSafeArea: offset)
        return self
    }

    @discardableResult
    public func centerX(toSafeArea offset: CGFloat) -> Self {
        view?.fw_alignAxis(toSafeArea: .centerX, offset: offset)
        return self
    }

    @discardableResult
    public func centerY(toSafeArea offset: CGFloat) -> Self {
        view?.fw_alignAxis(toSafeArea: .centerY, offset: offset)
        return self
    }

    @discardableResult
    public func edges(toSafeArea insets: UIEdgeInsets) -> Self {
        view?.fw_pinEdges(toSafeArea: insets)
        return self
    }
    
    @discardableResult
    public func edges(toSafeArea insets: UIEdgeInsets, excludingEdge edge: NSLayoutConstraint.Attribute) -> Self {
        view?.fw_pinEdges(toSafeArea: insets, excludingEdge: edge)
        return self
    }

    @discardableResult
    public func horizontal(toSafeArea inset: CGFloat) -> Self {
        view?.fw_pinHorizontal(toSafeArea: inset)
        return self
    }

    @discardableResult
    public func vertical(toSafeArea inset: CGFloat) -> Self {
        view?.fw_pinVertical(toSafeArea: inset)
        return self
    }
    
    @discardableResult
    public func top(toSafeArea inset: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw_pinEdge(toSafeArea: .top, inset: inset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func bottom(toSafeArea inset: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw_pinEdge(toSafeArea: .bottom, inset: inset, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func left(toSafeArea inset: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw_pinEdge(toSafeArea: .left, inset: inset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func right(toSafeArea inset: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw_pinEdge(toSafeArea: .right, inset: inset, relation: relation, priority: priority)
        return self
    }

    // MARK: - Dimension
    @discardableResult
    public func size(_ size: CGSize) -> Self {
        view?.fw_setDimensions(size)
        return self
    }
    
    @discardableResult
    public func size(width: CGFloat, height: CGFloat) -> Self {
        view?.fw_setDimensions(CGSize(width: width, height: height))
        return self
    }

    @discardableResult
    public func width(_ width: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw_setDimension(.width, size: width, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func height(_ height: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw_setDimension(.height, size: height, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func width(toHeight multiplier: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw_matchDimension(.width, toDimension: .height, multiplier: multiplier, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func height(toWidth multiplier: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw_matchDimension(.height, toDimension: .width, multiplier: multiplier, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func size(toView view: Any) -> Self {
        var constraints: [NSLayoutConstraint] = []
        if let constraint = self.view?.fw_matchDimension(.width, toDimension: .width, ofView: view) {
            constraints.append(constraint)
        }
        if let constraint = self.view?.fw_matchDimension(.height, toDimension: .height, ofView: view) {
            constraints.append(constraint)
        }
        self.view?.fw_lastConstraints = constraints
        return self
    }
    
    @discardableResult
    public func width(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw_matchDimension(.width, toDimension: .width, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func height(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw_matchDimension(.height, toDimension: .height, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func width(toView view: Any, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw_matchDimension(.width, toDimension: .width, ofView: view, multiplier: multiplier, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func height(toView view: Any, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw_matchDimension(.height, toDimension: .height, ofView: view, multiplier: multiplier, relation: relation, priority: priority)
        return self
    }

    // MARK: - Attribute
    @discardableResult
    public func attribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw_constrainAttribute(attribute, toAttribute: toAttribute, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func attribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, multiplier: CGFloat, offset: CGFloat = .zero, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw_constrainAttribute(attribute, toAttribute: toAttribute, ofView: view, multiplier: multiplier, offset: offset, relation: relation, priority: priority)
        return self
    }
    
    // MARK: - Subviews
    @discardableResult
    public func subviews(_ closure: (_ make: LayoutChain) -> Void) -> Self {
        self.view?.subviews.fw_layoutMaker(closure)
        return self
    }
    
    @discardableResult
    public func subviews(along axis: NSLayoutConstraint.Axis, itemSpacing: CGFloat, leadSpacing: CGFloat? = nil, tailSpacing: CGFloat? = nil, itemLength: CGFloat? = nil, equalLength: Bool = false) -> Self {
        self.view?.subviews.fw_layoutAlong(axis, itemSpacing: itemSpacing, leadSpacing: leadSpacing, tailSpacing: tailSpacing, itemLength: itemLength, equalLength: equalLength)
        return self
    }
    
    @discardableResult
    public func subviews(along axis: NSLayoutConstraint.Axis, itemLength: CGFloat, leadSpacing: CGFloat, tailSpacing: CGFloat) -> Self {
        self.view?.subviews.fw_layoutAlong(axis, itemLength: itemLength, leadSpacing: leadSpacing, tailSpacing: tailSpacing)
        return self
    }
    
    @discardableResult
    public func subviews(along axis: NSLayoutConstraint.Axis, alignCenter: Bool = false, itemWidth: CGFloat? = nil, leftSpacing: CGFloat? = nil, rightSpacing: CGFloat? = nil) -> Self {
        self.view?.subviews.fw_layoutAlong(axis, alignCenter: alignCenter, itemWidth: itemWidth, leftSpacing: leftSpacing, rightSpacing: rightSpacing)
        return self
    }
    
    // MARK: - Offset
    @discardableResult
    public func offset(_ offset: CGFloat) -> Self {
        self.view?.fw_lastConstraints.forEach({ obj in
            obj.fw_offset = offset
        })
        return self
    }
    
    @discardableResult
    public func constant(_ constant: CGFloat) -> Self {
        self.view?.fw_lastConstraints.forEach({ obj in
            obj.constant = constant
        })
        return self
    }
    
    @discardableResult
    public func priority(_ priority: UILayoutPriority) -> Self {
        self.view?.fw_lastConstraints.forEach({ obj in
            obj.priority = priority
        })
        return self
    }
    
    @discardableResult
    public func collapse(_ offset: CGFloat? = nil) -> Self {
        self.view?.fw_lastConstraints.forEach({ obj in
            self.view?.fw_addCollapseConstraint(obj, offset: offset)
        })
        return self
    }
    
    @discardableResult
    public func original(_ offset: CGFloat) -> Self {
        self.view?.fw_lastConstraints.forEach({ obj in
            obj.fw_originalOffset = offset
        })
        return self
    }
    
    @discardableResult
    public func collapseActive(_ active: Bool? = nil) -> Self {
        self.view?.fw_lastConstraints.forEach({ obj in
            self.view?.fw_addCollapseActiveConstraint(obj, active: active)
        })
        return self
    }
    
    @discardableResult
    public func collapsePriority(_ priority: UILayoutPriority? = nil) -> Self {
        self.view?.fw_lastConstraints.forEach({ obj in
            self.view?.fw_addCollapsePriorityConstraint(obj, priority: priority)
        })
        return self
    }
    
    @discardableResult
    public func originalPriority(_ priority: UILayoutPriority) -> Self {
        self.view?.fw_lastConstraints.forEach({ obj in
            obj.fw_originalPriority = priority
        })
        return self
    }
    
    @discardableResult
    public func identifier(_ identifier: String?) -> Self {
        self.view?.fw_lastConstraints.forEach({ obj in
            obj.identifier = identifier
        })
        return self
    }
    
    @discardableResult
    public func active(_ active: Bool) -> Self {
        self.view?.fw_lastConstraints.forEach({ obj in
            obj.isActive = active
        })
        return self
    }
    
    @discardableResult
    public func remove() -> Self {
        self.view?.fw_removeConstraints(self.view?.fw_lastConstraints)
        return self
    }
    
    // MARK: - Constraint
    public var constraints: [NSLayoutConstraint] {
        return self.view?.fw_lastConstraints ?? []
    }
    
    public var constraint: NSLayoutConstraint? {
        return self.view?.fw_lastConstraints.last
    }
    
    public func constraint(_ attribute: NSLayoutConstraint.Attribute, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> NSLayoutConstraint? {
        return self.view?.fw_constraint(toSuperview: attribute, relation: relation)
    }
    
    public func constraint(toSafeArea attribute: NSLayoutConstraint.Attribute, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> NSLayoutConstraint? {
        return self.view?.fw_constraint(toSafeArea: attribute, relation: relation)
    }

    public func constraint(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> NSLayoutConstraint? {
        return self.view?.fw_constraint(attribute, toAttribute: toAttribute, ofView: view, relation: relation)
    }
    
    public func constraint(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> NSLayoutConstraint? {
        return self.view?.fw_constraint(attribute, toAttribute: toAttribute, ofView: view, multiplier: multiplier, relation: relation)
    }
    
    public func constraint(identifier: String?) -> NSLayoutConstraint? {
        return self.view?.fw_constraint(identifier: identifier)
    }
    
    // MARK: - Debug
    @discardableResult
    public func layoutKey(_ layoutKey: String?) -> Self {
        view?.fw_layoutKey = layoutKey
        return self
    }
    
}

// MARK: - UIView+LayoutChain
@_spi(FW) extension UIView {

    /// 链式布局对象
    public var fw_layoutChain: LayoutChain {
        if let layoutChain = fw_property(forName: "fw_layoutChain") as? LayoutChain {
            return layoutChain
        }
        
        let layoutChain = LayoutChain(view: self)
        fw_setProperty(layoutChain, forName: "fw_layoutChain")
        return layoutChain
    }
    
    /// 链式布局闭包
    public func fw_layoutMaker(_ closure: (_ make: LayoutChain) -> Void) {
        closure(fw_layoutChain)
    }
    
}

// MARK: - Array+LayoutChain
@_spi(FW) extension Array where Element: UIView {
    
    /// 批量链式布局闭包
    public func fw_layoutMaker(_ closure: (_ make: LayoutChain) -> Void) {
        forEach { view in
            closure(view.fw_layoutChain)
        }
    }
    
    /// 批量对齐布局，适用于间距固定场景，尺寸未设置(可手工指定)，若只有一个则间距不生效
    public func fw_layoutAlong(_ axis: NSLayoutConstraint.Axis, itemSpacing: CGFloat, leadSpacing: CGFloat? = nil, tailSpacing: CGFloat? = nil, itemLength: CGFloat? = nil, equalLength: Bool = false) {
        guard self.count > 0 else { return }
        
        if axis == .horizontal {
            var prev: UIView?
            for (index, view) in self.enumerated() {
                if let prev = prev {
                    view.fw_pinEdge(.left, toEdge: .right, ofView: prev, offset: itemSpacing)
                    if let itemLength = itemLength {
                        view.fw_setDimension(.width, size: itemLength)
                    } else if equalLength {
                        view.fw_matchDimension(.width, toDimension: .width, ofView: prev)
                    }
                } else if let leadSpacing = leadSpacing {
                    view.fw_pinEdge(toSuperview: .left, inset: leadSpacing)
                }
                if index == self.count - 1, let tailSpacing = tailSpacing {
                    view.fw_pinEdge(toSuperview: .right, inset: tailSpacing)
                }
                prev = view
            }
        } else {
            var prev: UIView?
            for (index, view) in self.enumerated() {
                if let prev = prev {
                    view.fw_pinEdge(.top, toEdge: .bottom, ofView: prev, offset: itemSpacing)
                    if let itemLength = itemLength {
                        view.fw_setDimension(.height, size: itemLength)
                    } else if equalLength {
                        view.fw_matchDimension(.height, toDimension: .height, ofView: prev)
                    }
                } else if let leadSpacing = leadSpacing {
                    view.fw_pinEdge(toSuperview: .top, inset: leadSpacing)
                }
                if index == self.count - 1, let tailSpacing = tailSpacing {
                    view.fw_pinEdge(toSuperview: .bottom, inset: tailSpacing)
                }
                prev = view
            }
        }
    }
    
    /// 批量对齐布局，适用于尺寸固定场景，间距自适应，若只有一个则尺寸不生效
    public func fw_layoutAlong(_ axis: NSLayoutConstraint.Axis, itemLength: CGFloat, leadSpacing: CGFloat, tailSpacing: CGFloat) {
        guard self.count > 0 else { return }
        
        if axis == .horizontal {
            var prev: UIView?
            for (index, view) in self.enumerated() {
                if self.count > 1 {
                    view.fw_setDimension(.width, size: itemLength)
                }
                if prev != nil {
                    if index < self.count - 1 {
                        let offset = (CGFloat(1) - (CGFloat(index) / CGFloat(self.count - 1))) *
                            (itemLength + leadSpacing) -
                            CGFloat(index) * tailSpacing / CGFloat(self.count - 1)
                        view.fw_constrainAttribute(.right, toAttribute: .right, ofView: view.superview, multiplier: CGFloat(index) / CGFloat(self.count - 1), offset: offset)
                    }
                } else {
                    view.fw_pinEdge(toSuperview: .left, inset: leadSpacing)
                }
                if index == self.count - 1 {
                    view.fw_pinEdge(toSuperview: .right, inset: tailSpacing)
                }
                prev = view
            }
        } else {
            var prev: UIView?
            for (index, view) in self.enumerated() {
                if self.count > 1 {
                    view.fw_setDimension(.height, size: itemLength)
                }
                if prev != nil {
                    if index < self.count - 1 {
                        let offset = (CGFloat(1) - (CGFloat(index) / CGFloat(self.count - 1))) *
                            (itemLength + leadSpacing) -
                            CGFloat(index) * tailSpacing / CGFloat(self.count - 1)
                        view.fw_constrainAttribute(.bottom, toAttribute: .bottom, ofView: view.superview, multiplier: CGFloat(index) / CGFloat(self.count - 1), offset: offset)
                    }
                } else {
                    view.fw_pinEdge(toSuperview: .top, inset: leadSpacing)
                }
                if index == self.count - 1 {
                    view.fw_pinEdge(toSuperview: .bottom, inset: tailSpacing)
                }
                prev = view
            }
        }
    }
    
    /// 批量对齐布局，用于补齐Along之后该方向上的其他约束
    public func fw_layoutAlong(_ axis: NSLayoutConstraint.Axis, alignCenter: Bool = false, itemWidth: CGFloat? = nil, leftSpacing: CGFloat? = nil, rightSpacing: CGFloat? = nil) {
        guard self.count > 0 else { return }
        
        if axis == .horizontal {
            for view in self {
                if alignCenter {
                    view.fw_alignAxis(toSuperview: .centerY)
                }
                if let itemWidth = itemWidth {
                    view.fw_setDimension(.height, size: itemWidth)
                }
                if let leftSpacing = leftSpacing {
                    view.fw_pinEdge(toSuperview: .bottom, inset: leftSpacing)
                }
                if let rightSpacing = rightSpacing {
                    view.fw_pinEdge(toSuperview: .top, inset: rightSpacing)
                }
            }
        } else {
            for view in self {
                if alignCenter {
                    view.fw_alignAxis(toSuperview: .centerX)
                }
                if let itemWidth = itemWidth {
                    view.fw_setDimension(.width, size: itemWidth)
                }
                if let leftSpacing = leftSpacing {
                    view.fw_pinEdge(toSuperview: .left, inset: leftSpacing)
                }
                if let rightSpacing = rightSpacing {
                    view.fw_pinEdge(toSuperview: .right, inset: rightSpacing)
                }
            }
        }
    }
    
}

// MARK: - AutoLayout+Debug
@_spi(FW) extension UIView {
    
    /// 自动布局调试开关，默认调试打开，正式关闭
    public static var fw_autoLayoutDebug: Bool = {
        #if DEBUG
        true
        #else
        false
        #endif
    }() {
        didSet {
            if fw_autoLayoutDebug {
                fw_swizzleAutoLayoutDebug()
            }
        }
    }
    
    /// 布局调试Key
    public var fw_layoutKey: String? {
        get { fw_property(forName: "fw_layoutKey") as? String }
        set { fw_setPropertyCopy(newValue, forName: "fw_layoutKey") }
    }
    
    private static var fw_staticAutoLayoutDebugSwizzled = false
    
    fileprivate static func fw_swizzleAutoLayoutDebug() {
        guard !fw_staticAutoLayoutDebugSwizzled else { return }
        fw_staticAutoLayoutDebugSwizzled = true
        
        NSObject.fw_swizzleInstanceMethod(
            NSLayoutConstraint.self,
            selector: #selector(NSLayoutConstraint.description),
            methodSignature: (@convention(c) (NSLayoutConstraint, Selector) -> String).self,
            swizzleSignature: (@convention(block) (NSLayoutConstraint) -> String).self
        ) { store in { selfObject in
            guard UIView.fw_autoLayoutDebug else {
                return store.original(selfObject, store.selector)
            }
            
            return selfObject.fw_layoutDescription
        }}
    }
    
}

@_spi(FW) extension NSLayoutConstraint {
    
    /// 布局调试描述，参考：[Masonry](https://github.com/SnapKit/Masonry)
    fileprivate var fw_layoutDescription: String {
        var description = "<"
        description += Self.fw_layoutDescription(self)
        if let firstItem = firstItem {
            description += String(format: " %@", Self.fw_layoutDescription(firstItem))
        }
        if firstAttribute != .notAnAttribute {
            description += String(format: ".%@", (Self.fw_attributeDescriptions[firstAttribute] ?? NSNumber(value: firstAttribute.rawValue)))
        }
        description += String(format: " %@", (Self.fw_relationDescriptions[relation] ?? NSNumber(value: relation.rawValue)))
        if let secondItem = secondItem {
            description += String(format: " %@", Self.fw_layoutDescription(secondItem))
        }
        if secondAttribute != .notAnAttribute {
            description += String(format: ".%@", (Self.fw_attributeDescriptions[secondAttribute] ?? NSNumber(value: secondAttribute.rawValue)))
        }
        if multiplier != 1 {
            description += String(format: " * %g", multiplier)
        }
        if secondAttribute == .notAnAttribute {
            description += String(format: " %g", constant)
        } else {
            if constant != 0 {
                description += String(format: " %@ %g", (constant < 0 ? "-" : "+"), abs(constant))
            }
        }
        if priority != .required {
            description += String(format: " ^%@", Self.fw_priorityDescriptions[priority] ?? NSNumber(value: priority.rawValue))
        }
        description += ">"
        return description
    }
    
    private static func fw_layoutDescription(_ object: AnyObject) -> String {
        var objectDesc = ""
        if let constraint = object as? NSLayoutConstraint, let identifier = constraint.identifier {
            objectDesc = identifier
        } else if let view = object as? UIView, let layoutKey = view.fw_layoutKey {
            objectDesc = layoutKey
        } else if let guide = object as? UILayoutGuide, let layoutKey = guide.owningView?.fw_layoutKey {
            objectDesc = layoutKey
        }
        return String(format: "%@:%p%@", String(describing: type(of: object)), object as! CVarArg, !objectDesc.isEmpty ? " '\(objectDesc)'" : objectDesc)
    }
    
    private static var fw_relationDescriptions: [NSLayoutConstraint.Relation: String] = [
        .equal              : "==",
        .greaterThanOrEqual : ">=",
        .lessThanOrEqual    : "<=",
    ]
    
    private static var fw_attributeDescriptions: [NSLayoutConstraint.Attribute: String] = [
        .top                  : "top",
        .left                 : "left",
        .bottom               : "bottom",
        .right                : "right",
        .leading              : "leading",
        .trailing             : "trailing",
        .width                : "width",
        .height               : "height",
        .centerX              : "centerX",
        .centerY              : "centerY",
        .firstBaseline        : "firstBaseline",
        .lastBaseline         : "lastBaseline",
        .leftMargin           : "leftMargin",
        .rightMargin          : "rightMargin",
        .topMargin            : "topMargin",
        .bottomMargin         : "bottomMargin",
        .leadingMargin        : "leadingMargin",
        .trailingMargin       : "trailingMargin",
        .centerXWithinMargins : "centerXWithinMargins",
        .centerYWithinMargins : "centerYWithinMargins",
        .notAnAttribute       : "notAnAttribute",
    ]
    
    private static var fw_priorityDescriptions: [UILayoutPriority: String] = [
        .required                  : "required",
        .defaultHigh               : "defaultHigh",
        .defaultLow                : "defaultLow",
        .dragThatCanResizeScene    : "dragThatCanResizeScene",
        .dragThatCannotResizeScene : "dragThatCannotResizeScene",
        .sceneSizeStayPut          : "sceneSizeStayPut",
        .fittingSizeLevel          : "fittingSizeLevel",
    ]
    
}
