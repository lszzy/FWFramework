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
        get { return UIView.__autoLayoutRTL }
        set { UIView.__autoLayoutRTL = newValue }
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
        get { return UIView.__autoScaleLayout }
        set { UIView.__autoScaleLayout = newValue }
    }
    
    // MARK: - AutoLayout
    /// 视图是否自动等比例缩放布局，默认依次查找当前视图及其父视图，都未设置时返回全局开关
    public var autoScale: Bool {
        get {
            var autoScale = UIView.__autoScaleLayout
            if !UIView.__autoScaleView { return autoScale }
            
            var targetView: UIView? = base
            while targetView != nil {
                if let number = targetView?.fw.property(forName: "autoScale") as? NSNumber {
                    autoScale = number.boolValue
                    break
                }
                targetView = targetView?.superview
            }
            return autoScale
        }
        set {
            setProperty(NSNumber(value: newValue), forName: "autoScale")
            if !UIView.__autoScaleView { UIView.__autoScaleView = true }
        }
    }

    /// 执行子视图自动布局，自动计算子视图尺寸。需先将视图添加到界面(如设置为tableHeaderView)，再调用即可(iOS8+)
    public func autoLayoutSubviews() {
        // 保存当前的自动布局配置
        let translateConstraint = base.translatesAutoresizingMaskIntoConstraints
        
        // 启动自动布局，计算子视图尺寸
        base.translatesAutoresizingMaskIntoConstraints = false
        base.setNeedsLayout()
        base.layoutIfNeeded()
        
        // 还原自动布局设置
        base.translatesAutoresizingMaskIntoConstraints = translateConstraint
    }

    /// 计算动态布局视图指定宽度时的高度。使用AutoLayout必须约束完整，不使用AutoLayout会调用view的sizeThatFits:方法
    public func layoutHeight(width: CGFloat) -> CGFloat {
        var fittingHeight: CGFloat = 0
        
        // 添加固定的width约束，从而使动态视图(如UILabel)纵向扩张。而不是水平增长，flow-layout的方式
        let widthFenceConstraint = NSLayoutConstraint(item: base, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: width)
        base.addConstraint(widthFenceConstraint)
        // 自动布局引擎计算
        fittingHeight = base.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        base.removeConstraint(widthFenceConstraint)
        
        if (fittingHeight == 0) {
            // 尝试frame布局，调用sizeThatFits:
            fittingHeight = base.sizeThatFits(CGSize(width: width, height: 0)).height
        }
        return fittingHeight
    }

    /// 计算动态布局视图指定高度时的宽度。使用AutoLayout必须约束完整，不使用AutoLayout会调用view的sizeThatFits:方法
    public func layoutWidth(height: CGFloat) -> CGFloat {
        var fittingWidth: CGFloat = 0
        
        // 添加固定的height约束，从而使动态视图(如UILabel)横向扩张。而不是纵向增长，flow-layout的方式
        let heightFenceConstraint = NSLayoutConstraint(item: base, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: height)
        base.addConstraint(heightFenceConstraint)
        // 自动布局引擎计算
        fittingWidth = base.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width
        base.removeConstraint(heightFenceConstraint)
        
        if (fittingWidth == 0) {
            // 尝试frame布局，调用sizeThatFits:
            fittingWidth = base.sizeThatFits(CGSize(width: 0, height: height)).width
        }
        return fittingWidth
    }
    
    // MARK: - Compression
    /// 设置水平方向抗压缩优先级
    public var compressionHorizontal: UILayoutPriority {
        get { base.contentCompressionResistancePriority(for: .horizontal) }
        set { base.setContentCompressionResistancePriority(newValue, for: .horizontal) }
    }

    /// 设置垂直方向抗压缩优先级
    public var compressionVertical: UILayoutPriority {
        get { base.contentCompressionResistancePriority(for: .vertical) }
        set { base.setContentCompressionResistancePriority(newValue, for: .vertical) }
    }

    /// 设置水平方向抗拉伸优先级
    public var huggingHorizontal: UILayoutPriority {
        get { base.contentHuggingPriority(for: .horizontal) }
        set { base.setContentHuggingPriority(newValue, for: .horizontal) }
    }

    /// 设置垂直方向抗拉伸优先级
    public var huggingVertical: UILayoutPriority {
        get { base.contentHuggingPriority(for: .vertical) }
        set { base.setContentHuggingPriority(newValue, for: .vertical) }
    }
    
    // MARK: - Collapse
    /// 设置视图是否收缩，默认NO，YES时常量值为0，NO时常量值为原始值
    public var collapsed: Bool {
        get {
            return propertyBool(forName: "collapsed")
        }
        set {
            innerCollapseConstraints.enumerateObjects { constraint, _, _ in
                guard let constraint = constraint as? NSLayoutConstraint else { return }
                constraint.constant = newValue ? 0 : constraint.fw.originalConstant
            }
            
            setPropertyBool(newValue, forName: "collapsed")
        }
    }

    /// 设置视图是否自动收缩，如image为nil，text为nil、@""时自动收缩，默认NO
    public var autoCollapse: Bool {
        get { propertyBool(forName: "autoCollapse") }
        set { setPropertyBool(newValue, forName: "autoCollapse") }
    }

    /// 设置视图是否隐藏时自动收缩、显示时自动展开，默认NO
    public var hiddenCollapse: Bool {
        get { propertyBool(forName: "hiddenCollapse") }
        set { setPropertyBool(newValue, forName: "hiddenCollapse") }
    }

    /// 添加视图的收缩常量，必须先添加才能生效
    ///
    /// - see: [UIView-FDCollapsibleConstraints](https://github.com/forkingdog/UIView-FDCollapsibleConstraints)
    public func addCollapseConstraint(_ constraint: NSLayoutConstraint) {
        constraint.fw.originalConstant = constraint.constant
        if !innerCollapseConstraints.contains(constraint) {
            innerCollapseConstraints.add(constraint)
        }
    }
    
    fileprivate var innerCollapseConstraints: NSMutableArray {
        if let constraints = property(forName: "innerCollapseConstraints") as? NSMutableArray {
            return constraints
        } else {
            let constraints = NSMutableArray()
            setProperty(constraints, forName: "innerCollapseConstraints")
            return constraints
        }
    }
    
    // MARK: - Axis
    /// 父视图居中，可指定偏移距离
    /// - Parameter offset: 偏移距离，默认zero
    /// - Returns: 约束数组
    @discardableResult
    public func alignCenter(toSuperview offset: CGPoint = .zero) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        constraints.append(alignAxis(toSuperview: .centerX, offset: offset.x))
        constraints.append(alignAxis(toSuperview: .centerY, offset: offset.y))
        innerLastConstraints.setArray(constraints)
        return constraints
    }
    
    /// 父视图属性居中，可指定偏移距离
    /// - Parameters:
    ///   - axis: 居中属性
    ///   - offset: 偏移距离，默认0
    /// - Returns: 布局约束
    @discardableResult
    public func alignAxis(toSuperview axis: NSLayoutConstraint.Attribute, offset: CGFloat = 0) -> NSLayoutConstraint {
        return constrainAttribute(axis, toSuperview: base.superview, offset: offset, relation: .equal, priority: .required)
    }
    
    /// 与另一视图居中相同，可指定偏移距离
    /// - Parameters:
    ///   - axis: 居中属性
    ///   - toView: 另一视图或UILayoutGuide，下同
    ///   - offset: 偏移距离，默认0
    /// - Returns: 布局约束
    @discardableResult
    public func alignAxis(_ axis: NSLayoutConstraint.Attribute, toView: Any, offset: CGFloat = 0) -> NSLayoutConstraint {
        return constrainAttribute(axis, toAttribute: axis, ofView: toView, offset: offset)
    }

    /// 与另一视图居中指定比例
    /// - Parameters:
    ///   - axis: 居中属性
    ///   - toView: 另一视图
    ///   - multiplier: 指定比例
    /// - Returns: 布局约束
    @discardableResult
    public func alignAxis(_ axis: NSLayoutConstraint.Attribute, toView: Any, multiplier: CGFloat) -> NSLayoutConstraint {
        return constrainAttribute(axis, toAttribute: axis, ofView: toView, multiplier: multiplier)
    }
    
    // MARK: - Edge
    /// 与父视图四条边属性相同，可指定insets距离
    /// - Parameter insets: 指定距离insets，默认zero
    /// - Returns: 约束数组
    @discardableResult
    public func pinEdges(toSuperview insets: UIEdgeInsets = .zero) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        constraints.append(pinEdge(toSuperview: .top, inset: insets.top))
        constraints.append(pinEdge(toSuperview: .left, inset: insets.left))
        constraints.append(pinEdge(toSuperview: .bottom, inset: insets.bottom))
        constraints.append(pinEdge(toSuperview: .right, inset: insets.right))
        innerLastConstraints.setArray(constraints)
        return constraints
    }

    /// 与父视图三条边属性距离指定距离
    /// - Parameters:
    ///   - insets: 指定距离insets
    ///   - excludingEdge: 排除的边
    /// - Returns: 约束数组
    @discardableResult
    public func pinEdges(toSuperview insets: UIEdgeInsets = .zero, excludingEdge: NSLayoutConstraint.Attribute) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        if excludingEdge != .top {
            constraints.append(pinEdge(toSuperview: .top, inset: insets.top))
        }
        if excludingEdge != .leading && excludingEdge != .left {
            constraints.append(pinEdge(toSuperview: .left, inset: insets.left))
        }
        if excludingEdge != .bottom {
            constraints.append(pinEdge(toSuperview: .bottom, inset: insets.bottom))
        }
        if excludingEdge != .trailing && excludingEdge != .right {
            constraints.append(pinEdge(toSuperview: .right, inset: insets.right))
        }
        innerLastConstraints.setArray(constraints)
        return constraints
    }
    
    /// 与父视图水平方向两条边属性相同，可指定偏移距离
    /// - Parameters:
    ///   - inset: 偏移距离
    /// - Returns: 约束数组
    @discardableResult
    public func pinHorizontal(toSuperview inset: CGFloat = .zero) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        constraints.append(pinEdge(toSuperview: .left, inset: inset))
        constraints.append(pinEdge(toSuperview: .right, inset: inset))
        innerLastConstraints.setArray(constraints)
        return constraints
    }
    
    /// 与父视图垂直方向两条边属性相同，可指定偏移距离
    /// - Parameters:
    ///   - inset: 偏移距离
    /// - Returns: 约束数组
    @discardableResult
    public func pinVertical(toSuperview inset: CGFloat = .zero) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        constraints.append(pinEdge(toSuperview: .top, inset: inset))
        constraints.append(pinEdge(toSuperview: .bottom, inset: inset))
        innerLastConstraints.setArray(constraints)
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
    public func pinEdge(toSuperview edge: NSLayoutConstraint.Attribute, inset: CGFloat = .zero, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
        return constrainAttribute(edge, toSuperview: base.superview, offset: inset, relation: relation, priority: priority)
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
        return constrainAttribute(edge, toAttribute: toEdge, ofView: ofView, offset: offset, relation: relation, priority: priority)
    }
    
    // MARK: - SafeArea
    /// 父视图安全区域居中，可指定偏移距离。iOS11以下使用Superview实现，下同
    /// - Parameter offset: 偏移距离
    /// - Returns: 约束数组
    @discardableResult
    public func alignCenter(toSafeArea offset: CGPoint) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        constraints.append(alignAxis(toSafeArea: .centerX, offset: offset.x))
        constraints.append(alignAxis(toSafeArea: .centerY, offset: offset.y))
        innerLastConstraints.setArray(constraints)
        return constraints
    }
    
    /// 父视图安全区域属性居中，可指定偏移距离
    /// - Parameters:
    ///   - axis: 居中属性
    ///   - offset: 偏移距离，默认0
    /// - Returns: 布局约束
    @discardableResult
    public func alignAxis(toSafeArea axis: NSLayoutConstraint.Attribute, offset: CGFloat = .zero) -> NSLayoutConstraint {
        return constrainAttribute(axis, toSuperview: base.superview?.safeAreaLayoutGuide, offset: offset, relation: .equal, priority: .required)
    }

    /// 与父视图安全区域四条边属性相同，可指定距离insets
    /// - Parameter insets: 指定距离insets
    /// - Returns: 约束数组
    @discardableResult
    public func pinEdges(toSafeArea insets: UIEdgeInsets) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        constraints.append(pinEdge(toSafeArea: .top, inset: insets.top))
        constraints.append(pinEdge(toSafeArea: .left, inset: insets.left))
        constraints.append(pinEdge(toSafeArea: .bottom, inset: insets.bottom))
        constraints.append(pinEdge(toSafeArea: .right, inset: insets.right))
        innerLastConstraints.setArray(constraints)
        return constraints
    }

    /// 与父视图安全区域三条边属性距离指定距离
    /// - Parameters:
    ///   - insets: 指定距离insets
    ///   - excludingEdge: 排除的边
    /// - Returns: 约束数组
    @discardableResult
    public func pinEdges(toSafeArea insets: UIEdgeInsets, excludingEdge: NSLayoutConstraint.Attribute) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        if excludingEdge != .top {
            constraints.append(pinEdge(toSafeArea: .top, inset: insets.top))
        }
        if excludingEdge != .leading && excludingEdge != .left {
            constraints.append(pinEdge(toSafeArea: .left, inset: insets.left))
        }
        if excludingEdge != .bottom {
            constraints.append(pinEdge(toSafeArea: .bottom, inset: insets.bottom))
        }
        if excludingEdge != .trailing && excludingEdge != .right {
            constraints.append(pinEdge(toSafeArea: .right, inset: insets.right))
        }
        innerLastConstraints.setArray(constraints)
        return constraints
    }

    /// 与父视图安全区域水平方向两条边属性相同，可指定偏移距离
    /// - Parameters:
    ///   - inset: 偏移距离
    /// - Returns: 约束数组
    @discardableResult
    public func pinHorizontal(toSafeArea inset: CGFloat) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        constraints.append(pinEdge(toSafeArea: .left, inset: inset))
        constraints.append(pinEdge(toSafeArea: .right, inset: inset))
        innerLastConstraints.setArray(constraints)
        return constraints
    }
    
    /// 与父视图安全区域垂直方向两条边属性相同，可指定偏移距离
    /// - Parameters:
    ///   - inset: 偏移距离
    /// - Returns: 约束数组
    @discardableResult
    public func pinVertical(toSafeArea inset: CGFloat) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        constraints.append(pinEdge(toSafeArea: .top, inset: inset))
        constraints.append(pinEdge(toSafeArea: .bottom, inset: inset))
        innerLastConstraints.setArray(constraints)
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
    public func pinEdge(toSafeArea edge: NSLayoutConstraint.Attribute, inset: CGFloat = .zero, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
        return constrainAttribute(edge, toSuperview: base.superview?.safeAreaLayoutGuide, offset: inset, relation: relation, priority: priority)
    }
    
    // MARK: - Dimension
    /// 设置宽高尺寸
    /// - Parameter size: 尺寸大小
    /// - Returns: 约束数组
    @discardableResult
    public func setDimensions(_ size: CGSize) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        constraints.append(setDimension(.width, size: size.width))
        constraints.append(setDimension(.height, size: size.height))
        innerLastConstraints.setArray(constraints)
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
    public func setDimension(_ dimension: NSLayoutConstraint.Attribute, size: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
        return constrainAttribute(dimension, toAttribute: .notAnAttribute, ofView: nil, multiplier: 0, offset: size, relation: relation, priority: priority)
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
        return matchDimension(dimension, toDimension: toDimension, ofView: base, multiplier: multiplier, relation: relation, priority: priority)
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
        return constrainAttribute(dimension, toAttribute: toDimension, ofView: ofView, offset: offset, relation: relation, priority: priority)
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
        return constrainAttribute(dimension, toAttribute: toDimension, ofView: ofView, multiplier: multiplier, relation: relation, priority: priority)
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
        return constrainAttribute(attribute, toAttribute: toAttribute, ofView: ofView, multiplier: 1.0, offset: offset, relation: relation, priority: priority)
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
        return constrainAttribute(attribute, toAttribute: toAttribute, ofView: ofView, multiplier: multiplier, offset: 0, relation: relation, priority: priority)
    }
    
    // MARK: - Constraint
    /// 获取添加的与父视图属性的约束，指定关系
    /// - Parameters:
    ///   - attribute: 指定属性
    ///   - relation: 约束关系
    /// - Returns: 布局约束
    public func constraint(toSuperview attribute: NSLayoutConstraint.Attribute, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint? {
        return constraint(attribute, toSuperview: base.superview, relation: relation)
    }

    /// 获取添加的与父视图安全区域属性的约束，指定关系
    /// - Parameters:
    ///   - attribute: 指定属性
    ///   - relation: 约束关系
    /// - Returns: 布局约束
    public func constraint(toSafeArea attribute: NSLayoutConstraint.Attribute, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint? {
        return constraint(attribute, toSuperview: base.superview?.safeAreaLayoutGuide, relation: relation)
    }
    
    private func constraint(_ attribute: NSLayoutConstraint.Attribute, toSuperview superview: Any?, relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint? {
        assert(base.superview != nil, "View's superview must not be nil.\nView: \(base)")
        var targetRelation = relation
        if attribute == .bottom || attribute == .right || attribute == .trailing {
            if relation == .lessThanOrEqual {
                targetRelation = .greaterThanOrEqual
            } else if relation == .greaterThanOrEqual {
                targetRelation = .lessThanOrEqual
            }
        }
        return constraint(attribute, toAttribute: attribute, ofView: superview, multiplier: 1.0, relation: targetRelation)
    }

    /// 获取添加的与指定视图属性的约束，指定关系
    /// - Parameters:
    ///   - attribute: 指定属性
    ///   - toAttribute: 目标视图属性
    ///   - ofView: 目标视图
    ///   - relation: 约束关系
    /// - Returns: 布局约束
    public func constraint(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView: Any?, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint? {
        return constraint(attribute, toAttribute: toAttribute, ofView: ofView, multiplier: 1.0, relation: relation)
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
        var targetAttribute = attribute
        var targetToAttribute = toAttribute
        if UIView.__autoLayoutRTL {
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
        let constraintIdentifier = constraintIdentifier(targetAttribute, toAttribute: targetToAttribute, ofView: ofView, multiplier: multiplier, relation: relation)
        return constraint(identifier: constraintIdentifier)
    }
    
    /// 根据唯一标志获取布局约束
    /// - Parameters:
    ///   - identifier: 唯一标志
    /// - Returns: 布局约束
    public func constraint(identifier: String?) -> NSLayoutConstraint? {
        guard let identifier = identifier, !identifier.isEmpty else { return nil }
        let constraint = innerLayoutConstraints.first { obj in
            guard let obj = obj as? NSLayoutConstraint else { return false }
            return obj.identifier == identifier
        }
        return constraint as? NSLayoutConstraint
    }
    
    /// 最近一批添加或更新的布局约束
    public var lastConstraints: [NSLayoutConstraint] {
        return innerLastConstraints as? [NSLayoutConstraint] ?? []
    }
    
    /// 获取当前所有约束
    public var allConstraints: [NSLayoutConstraint] {
        return innerLayoutConstraints as? [NSLayoutConstraint] ?? []
    }
    
    /// 移除当前指定约束数组
    /// - Parameter constraints: 布局约束数组
    public func removeConstraints(_ constraints: [NSLayoutConstraint]?) {
        guard let constraints = constraints, !constraints.isEmpty else { return }
        NSLayoutConstraint.deactivate(constraints)
        innerLayoutConstraints.removeObjects(in: constraints)
        innerLastConstraints.removeObjects(in: constraints)
    }
    
    // MARK: - Private
    private func constrainAttribute(_ attribute: NSLayoutConstraint.Attribute, toSuperview superview: Any?, offset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority) -> NSLayoutConstraint {
        assert(base.superview != nil, "View's superview must not be nil.\nView: \(base)")
        var isOpposite = false
        var targetOffset = offset
        var targetRelation = relation
        if attribute == .bottom || attribute == .right || attribute == .trailing {
            isOpposite = true
            targetOffset = -offset
            if relation == .lessThanOrEqual {
                targetRelation = .greaterThanOrEqual
            } else if relation == .greaterThanOrEqual {
                targetRelation = .lessThanOrEqual
            }
        }
        
        let constraint = constrainAttribute(attribute, toAttribute: attribute, ofView: superview, multiplier: 1.0, offset: targetOffset, relation: targetRelation, priority: priority)
        constraint.fw.isOpposite = isOpposite
        return constraint
    }
    
    private func constrainAttribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView: Any?, multiplier: CGFloat, offset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority) -> NSLayoutConstraint {
        let targetOffset = autoScale ? UIScreen.fw.relativeValue(offset) : offset
        var targetAttribute = attribute
        var targetToAttribute = toAttribute
        if UIView.__autoLayoutRTL {
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
        
        base.translatesAutoresizingMaskIntoConstraints = false
        // 自动生成唯一约束标记，存在则更新，否则添加
        let constraintIdentifier = constraintIdentifier(targetAttribute, toAttribute: targetToAttribute, ofView: ofView, multiplier: multiplier, relation: relation)
        var targetConstraint: NSLayoutConstraint
        if let constraint = constraint(identifier: constraintIdentifier) {
            targetConstraint = constraint
            if targetConstraint.constant != targetOffset {
                targetConstraint.constant = targetOffset
            }
        } else {
            targetConstraint = NSLayoutConstraint(item: base, attribute: targetAttribute, relatedBy: relation, toItem: ofView, attribute: targetToAttribute, multiplier: multiplier, constant: targetOffset)
            targetConstraint.identifier = constraintIdentifier
            innerLayoutConstraints.add(targetConstraint)
        }
        innerLastConstraints.setArray([targetConstraint])
        if targetConstraint.priority != priority {
            targetConstraint.fw.priority = priority
        }
        targetConstraint.isActive = true
        return targetConstraint
    }
    
    private func constraintIdentifier(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView: Any?, multiplier: CGFloat, relation: NSLayoutConstraint.Relation) -> String {
        var viewHash = ""
        if let ofView = ofView as? NSObject {
            viewHash = "\(ofView.hash)"
        } else if let ofView = ofView {
            viewHash = String(describing: ofView)
        }
        return String(format: "%ld-%ld-%@-%ld-%@", attribute.rawValue, relation.rawValue, viewHash, toAttribute.rawValue, NSNumber(value: multiplier))
    }
    
    private var innerLayoutConstraints: NSMutableArray {
        if let constraints = property(forName: "innerLayoutConstraints") as? NSMutableArray {
            return constraints
        } else {
            let constraints = NSMutableArray()
            setProperty(constraints, forName: "innerLayoutConstraints")
            return constraints
        }
    }
    
    private var innerLastConstraints: NSMutableArray {
        if let constraints = property(forName: "innerLastConstraints") as? NSMutableArray {
            return constraints
        } else {
            let constraints = NSMutableArray()
            setProperty(constraints, forName: "innerLastConstraints")
            return constraints
        }
    }
    
}

extension UIView {
    
    fileprivate static var __autoLayoutRTL = false
    fileprivate static var __autoScaleLayout = false
    fileprivate static var __autoScaleView = false
    
}

// MARK: - NSLayoutConstraint+AutoLayout
extension Wrapper where Base: NSLayoutConstraint {
    
    /// 标记是否是相反的约束，一般相对于父视图
    public var isOpposite: Bool {
        get { propertyBool(forName: "isOpposite") }
        set { setPropertyBool(newValue, forName: "isOpposite") }
    }
    
    /// 设置内间距值，如果是相反的约束，会自动取反
    public var inset: CGFloat {
        get { isOpposite ? -base.constant : base.constant }
        set { base.constant = isOpposite ? -newValue : newValue }
    }
    
    /// 安全修改优先级，防止iOS13以下已激活约束修改Required崩溃
    public var priority: UILayoutPriority {
        get {
            return base.priority
        }
        set {
            __Runtime.tryCatch {
                base.priority = newValue
            } exceptionHandler: { exception in
                NSLog("%@", exception)
            }
        }
    }
    
    fileprivate var originalConstant: CGFloat {
        get { propertyDouble(forName: "originalConstant") }
        set { setPropertyDouble(newValue, forName: "originalConstant") }
    }
    
}

// MARK: - AutoLayoutAutoloader
internal class AutoLayoutAutoloader: AutoloadProtocol {
    
    static func autoload() {
        NSObject.fw.swizzleInstanceMethod(
            UIView.self,
            selector: #selector(UIView.updateConstraints),
            methodSignature: (@convention(c) (UIView, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UIView) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            
            if selfObject.fw.autoCollapse && selfObject.fw.innerCollapseConstraints.count > 0 {
                // Absent意味着视图没有固有size，即{-1, -1}
                let absentIntrinsicContentSize = CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
                // 计算固有尺寸
                let contentSize = selfObject.intrinsicContentSize
                // 如果视图没有固定尺寸，自动设置约束
                if contentSize.equalTo(absentIntrinsicContentSize) || contentSize.equalTo(.zero) {
                    selfObject.fw.collapsed = true
                } else {
                    selfObject.fw.collapsed = false
                }
            }
        }}
        
        NSObject.fw.swizzleInstanceMethod(
            UIView.self,
            selector: #selector(setter: UIView.isHidden),
            methodSignature: (@convention(c) (UIView, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) (UIView, Bool) -> Void).self
        ) { store in { selfObject, hidden in
            store.original(selfObject, store.selector, hidden)
            
            if selfObject.fw.hiddenCollapse && selfObject.fw.innerCollapseConstraints.count > 0 {
                selfObject.fw.collapsed = hidden
            }
        }}
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
        view?.fw.removeConstraints(view?.fw.allConstraints)
        return self
    }
    
    @discardableResult
    public func autoScale(_ autoScale: Bool) -> Self {
        view?.fw.autoScale = autoScale
        return self
    }

    // MARK: - Compression
    @discardableResult
    public func compression(horizontal priority: UILayoutPriority) -> Self {
        view?.fw.compressionHorizontal = priority
        return self
    }

    @discardableResult
    public func compression(vertical priority: UILayoutPriority) -> Self {
        view?.fw.compressionVertical = priority
        return self
    }
    
    @discardableResult
    public func hugging(horizontal priority: UILayoutPriority) -> Self {
        view?.fw.huggingHorizontal = priority
        return self
    }

    @discardableResult
    public func hugging(vertical priority: UILayoutPriority) -> Self {
        view?.fw.huggingVertical = priority
        return self
    }
    
    // MARK: - Collapse
    @discardableResult
    public func collapsed(_ collapsed: Bool) -> Self {
        view?.fw.collapsed = collapsed
        return self
    }

    @discardableResult
    public func autoCollapse(_ autoCollapse: Bool) -> Self {
        view?.fw.autoCollapse = autoCollapse
        return self
    }
    
    @discardableResult
    public func hiddenCollapse(_ hiddenCollapse: Bool) -> Self {
        view?.fw.hiddenCollapse = hiddenCollapse
        return self
    }

    // MARK: - Axis
    @discardableResult
    public func center(_ offset: CGPoint = .zero) -> Self {
        view?.fw.alignCenter(toSuperview: offset)
        return self
    }

    @discardableResult
    public func centerX(_ offset: CGFloat = .zero) -> Self {
        view?.fw.alignAxis(toSuperview: .centerX, offset: offset)
        return self
    }

    @discardableResult
    public func centerY(_ offset: CGFloat = .zero) -> Self {
        view?.fw.alignAxis(toSuperview: .centerY, offset: offset)
        return self
    }

    @discardableResult
    public func center(toView view: Any) -> Self {
        self.view?.fw.alignAxis(.centerX, toView: view)
        self.view?.fw.alignAxis(.centerY, toView: view)
        return self
    }

    @discardableResult
    public func centerX(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.fw.alignAxis(.centerX, toView: view, offset: offset)
        return self
    }

    @discardableResult
    public func centerY(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.fw.alignAxis(.centerY, toView: view, offset: offset)
        return self
    }

    @discardableResult
    public func centerX(toView view: Any, multiplier: CGFloat) -> Self {
        self.view?.fw.alignAxis(.centerX, toView: view, multiplier: multiplier)
        return self
    }

    @discardableResult
    public func centerY(toView view: Any, multiplier: CGFloat) -> Self {
        self.view?.fw.alignAxis(.centerY, toView: view, multiplier: multiplier)
        return self
    }

    // MARK: - Edge
    @discardableResult
    public func edges(_ insets: UIEdgeInsets = UIEdgeInsets.zero) -> Self {
        view?.fw.pinEdges(toSuperview: insets)
        return self
    }
    
    @discardableResult
    public func edges(_ insets: UIEdgeInsets = UIEdgeInsets.zero, excludingEdge edge: NSLayoutConstraint.Attribute) -> Self {
        view?.fw.pinEdges(toSuperview: insets, excludingEdge: edge)
        return self
    }

    @discardableResult
    public func horizontal(_ inset: CGFloat = .zero) -> Self {
        view?.fw.pinHorizontal(toSuperview: inset)
        return self
    }

    @discardableResult
    public func vertical(_ inset: CGFloat = .zero) -> Self {
        view?.fw.pinVertical(toSuperview: inset)
        return self
    }

    @discardableResult
    public func top(_ inset: CGFloat = 0) -> Self {
        view?.fw.pinEdge(toSuperview: .top, inset: inset)
        return self
    }
    
    @discardableResult
    public func top(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        view?.fw.pinEdge(toSuperview: .top, inset: inset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func bottom(_ inset: CGFloat = 0) -> Self {
        view?.fw.pinEdge(toSuperview: .bottom, inset: inset)
        return self
    }
    
    @discardableResult
    public func bottom(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        view?.fw.pinEdge(toSuperview: .bottom, inset: inset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func left(_ inset: CGFloat = 0) -> Self {
        view?.fw.pinEdge(toSuperview: .left, inset: inset)
        return self
    }
    
    @discardableResult
    public func left(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        view?.fw.pinEdge(toSuperview: .left, inset: inset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func right(_ inset: CGFloat = 0) -> Self {
        view?.fw.pinEdge(toSuperview: .right, inset: inset)
        return self
    }
    
    @discardableResult
    public func right(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        view?.fw.pinEdge(toSuperview: .right, inset: inset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func top(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.fw.pinEdge(.top, toEdge: .top, ofView: view, offset: offset)
        return self
    }
    
    @discardableResult
    public func top(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw.pinEdge(.top, toEdge: .top, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func bottom(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.fw.pinEdge(.bottom, toEdge: .bottom, ofView: view, offset: offset)
        return self
    }
    
    @discardableResult
    public func bottom(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw.pinEdge(.bottom, toEdge: .bottom, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func left(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.fw.pinEdge(.left, toEdge: .left, ofView: view, offset: offset)
        return self
    }
    
    @discardableResult
    public func left(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw.pinEdge(.left, toEdge: .left, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func right(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.fw.pinEdge(.right, toEdge: .right, ofView: view, offset: offset)
        return self
    }
    
    @discardableResult
    public func right(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw.pinEdge(.right, toEdge: .right, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func top(toViewBottom view: Any, offset: CGFloat = 0) -> Self {
        self.view?.fw.pinEdge(.top, toEdge: .bottom, ofView: view, offset: offset)
        return self
    }
    
    @discardableResult
    public func top(toViewBottom view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw.pinEdge(.top, toEdge: .bottom, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func bottom(toViewTop view: Any, offset: CGFloat = 0) -> Self {
        self.view?.fw.pinEdge(.bottom, toEdge: .top, ofView: view, offset: offset)
        return self
    }

    @discardableResult
    public func bottom(toViewTop view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw.pinEdge(.bottom, toEdge: .top, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func left(toViewRight view: Any, offset: CGFloat = 0) -> Self {
        self.view?.fw.pinEdge(.left, toEdge: .right, ofView: view, offset: offset)
        return self
    }
    
    @discardableResult
    public func left(toViewRight view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw.pinEdge(.left, toEdge: .right, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func right(toViewLeft view: Any, offset: CGFloat = 0) -> Self {
        self.view?.fw.pinEdge(.right, toEdge: .left, ofView: view, offset: offset)
        return self
    }

    @discardableResult
    public func right(toViewLeft view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw.pinEdge(.right, toEdge: .left, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    // MARK: - SafeArea
    @discardableResult
    public func center(toSafeArea offset: CGPoint) -> Self {
        view?.fw.alignCenter(toSafeArea: offset)
        return self
    }

    @discardableResult
    public func centerX(toSafeArea offset: CGFloat) -> Self {
        view?.fw.alignAxis(toSafeArea: .centerX, offset: offset)
        return self
    }

    @discardableResult
    public func centerY(toSafeArea offset: CGFloat) -> Self {
        view?.fw.alignAxis(toSafeArea: .centerY, offset: offset)
        return self
    }

    @discardableResult
    public func edges(toSafeArea insets: UIEdgeInsets) -> Self {
        view?.fw.pinEdges(toSafeArea: insets)
        return self
    }
    
    @discardableResult
    public func edges(toSafeArea insets: UIEdgeInsets, excludingEdge edge: NSLayoutConstraint.Attribute) -> Self {
        view?.fw.pinEdges(toSafeArea: insets, excludingEdge: edge)
        return self
    }

    @discardableResult
    public func horizontal(toSafeArea inset: CGFloat) -> Self {
        view?.fw.pinHorizontal(toSafeArea: inset)
        return self
    }

    @discardableResult
    public func vertical(toSafeArea inset: CGFloat) -> Self {
        view?.fw.pinVertical(toSafeArea: inset)
        return self
    }

    @discardableResult
    public func top(toSafeArea inset: CGFloat) -> Self {
        view?.fw.pinEdge(toSafeArea: .top, inset: inset)
        return self
    }
    
    @discardableResult
    public func top(toSafeArea inset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        view?.fw.pinEdge(toSafeArea: .top, inset: inset, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func bottom(toSafeArea inset: CGFloat) -> Self {
        view?.fw.pinEdge(toSafeArea: .bottom, inset: inset)
        return self
    }

    @discardableResult
    public func bottom(toSafeArea inset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        view?.fw.pinEdge(toSafeArea: .bottom, inset: inset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func left(toSafeArea inset: CGFloat) -> Self {
        view?.fw.pinEdge(toSafeArea: .left, inset: inset)
        return self
    }
    
    @discardableResult
    public func left(toSafeArea inset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        view?.fw.pinEdge(toSafeArea: .left, inset: inset, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func right(toSafeArea inset: CGFloat) -> Self {
        view?.fw.pinEdge(toSafeArea: .right, inset: inset)
        return self
    }

    @discardableResult
    public func right(toSafeArea inset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        view?.fw.pinEdge(toSafeArea: .right, inset: inset, relation: relation, priority: priority)
        return self
    }

    // MARK: - Dimension
    @discardableResult
    public func size(_ size: CGSize) -> Self {
        view?.fw.setDimensions(size)
        return self
    }

    @discardableResult
    public func width(_ width: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw.setDimension(.width, size: width, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func height(_ height: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw.setDimension(.height, size: height, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func width(toHeight multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw.matchDimension(.width, toDimension: .height, multiplier: multiplier, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func height(toWidth multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw.matchDimension(.height, toDimension: .width, multiplier: multiplier, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func size(toView view: Any) -> Self {
        self.view?.fw.matchDimension(.width, toDimension: .width, ofView: view)
        self.view?.fw.matchDimension(.height, toDimension: .height, ofView: view)
        return self
    }

    @discardableResult
    public func width(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.fw.matchDimension(.width, toDimension: .width, ofView: view, offset: offset)
        return self
    }
    
    @discardableResult
    public func width(toView view: Any, offset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw.matchDimension(.width, toDimension: .width, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func height(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.fw.matchDimension(.height, toDimension: .height, ofView: view, offset: offset)
        return self
    }

    @discardableResult
    public func height(toView view: Any, offset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw.matchDimension(.height, toDimension: .height, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func width(toView view: Any, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw.matchDimension(.width, toDimension: .width, ofView: view, multiplier: multiplier, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func height(toView view: Any, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw.matchDimension(.height, toDimension: .height, ofView: view, multiplier: multiplier, relation: relation, priority: priority)
        return self
    }

    // MARK: - Attribute
    @discardableResult
    public func attribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, offset: CGFloat = 0) -> Self {
        self.view?.fw.constrainAttribute(attribute, toAttribute: toAttribute, ofView: view, offset: offset)
        return self
    }
    
    @discardableResult
    public func attribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, offset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw.constrainAttribute(attribute, toAttribute: toAttribute, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func attribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw.constrainAttribute(attribute, toAttribute: toAttribute, ofView: view, multiplier: multiplier, relation: relation, priority: priority)
        return self
    }
    
    // MARK: - Offset
    @discardableResult
    public func offset(_ offset: CGFloat) -> Self {
        self.view?.fw.lastConstraints.forEach({ obj in
            obj.constant = offset
        })
        return self
    }
    
    @discardableResult
    public func inset(_ inset: CGFloat) -> Self {
        self.view?.fw.lastConstraints.forEach({ obj in
            obj.fw.inset = inset
        })
        return self
    }
    
    @discardableResult
    public func priority(_ priority: UILayoutPriority) -> Self {
        self.view?.fw.lastConstraints.forEach({ obj in
            obj.fw.priority = priority
        })
        return self
    }
    
    @discardableResult
    public func identifier(_ identifier: String?) -> Self {
        self.view?.fw.lastConstraints.forEach({ obj in
            obj.identifier = identifier
        })
        return self
    }
    
    @discardableResult
    public func active(_ active: Bool) -> Self {
        self.view?.fw.lastConstraints.forEach({ obj in
            obj.isActive = active
        })
        return self
    }
    
    @discardableResult
    public func remove() -> Self {
        self.view?.fw.removeConstraints(self.view?.fw.lastConstraints)
        return self
    }
    
    // MARK: - Constraint
    public var constraints: [NSLayoutConstraint] {
        return self.view?.fw.lastConstraints ?? []
    }
    
    public var constraint: NSLayoutConstraint? {
        return self.view?.fw.lastConstraints.last
    }
    
    public func constraint(_ attribute: NSLayoutConstraint.Attribute, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> NSLayoutConstraint? {
        return self.view?.fw.constraint(toSuperview: attribute, relation: relation)
    }
    
    public func constraint(toSafeArea attribute: NSLayoutConstraint.Attribute, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> NSLayoutConstraint? {
        return self.view?.fw.constraint(toSafeArea: attribute, relation: relation)
    }

    public func constraint(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> NSLayoutConstraint? {
        return self.view?.fw.constraint(attribute, toAttribute: toAttribute, ofView: view, relation: relation)
    }
    
    public func constraint(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> NSLayoutConstraint? {
        return self.view?.fw.constraint(attribute, toAttribute: toAttribute, ofView: view, multiplier: multiplier, relation: relation)
    }
    
    public func constraint(identifier: String?) -> NSLayoutConstraint? {
        return self.view?.fw.constraint(identifier: identifier)
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
