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
@_spi(FW) @objc extension UIView {
    
    /// 是否启用自动布局适配RTL，启用后自动将Left|Right转换为Leading|Trailing，默认NO
    ///
    /// 如果项目兼容阿拉伯语等，需要启用RTL从右向左布局，开启此开关即可，无需修改布局代码
    /// 手工切换视图左右布局方法：[UIView appearance].semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    public static var fw_autoLayoutRTL = false
    
    /// 是否全局自动等比例缩放布局，默认NO
    ///
    /// 启用后所有offset值都会自动*relativeScale，注意可能产生的影响。
    /// 启用后注意事项：
    /// 1. 屏幕宽度约束不能使用screenWidth约束，需要使用375设计标准
    /// 2. 尽量不使用screenWidth固定屏幕宽度方式布局，推荐相对于父视图布局
    /// 2. 只会对offset值生效，其他属性不受影响
    /// 3. 如需特殊处理，可以指定某个视图关闭该功能
    public static var fw_autoScale = false
    
    /// 视图是否自动等比例缩放布局全局开关
    private static var fw_autoScaleView = false
    
    // MARK: - AutoLayout
    /// 视图是否自动等比例缩放布局，默认依次查找当前视图及其父视图，都未设置时返回全局开关
    public var fw_autoScale: Bool {
        get {
            var autoScale = UIView.fw_autoScale
            if !UIView.fw_autoScaleView { return autoScale }
            
            var targetView: UIView? = self
            while targetView != nil {
                if let number = targetView?.fw_property(forName: "fw_autoScale") as? NSNumber {
                    autoScale = number.boolValue
                    break
                }
                targetView = targetView?.superview
            }
            return autoScale
        }
        set {
            fw_setProperty(NSNumber(value: newValue), forName: "fw_autoScale")
            if !UIView.fw_autoScaleView { UIView.fw_autoScaleView = true }
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

    /// 计算动态布局视图指定宽度时的高度。使用AutoLayout必须约束完整，不使用AutoLayout会调用view的sizeThatFits:方法。注意UILabel可使用preferredMaxLayoutWidth限制多行文本自动布局时的最大宽度
    public func fw_layoutHeight(width: CGFloat) -> CGFloat {
        var fittingHeight: CGFloat = 0
        
        // 添加固定的width约束，从而使动态视图(如UILabel)纵向扩张。而不是水平增长，flow-layout的方式
        let widthFenceConstraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: width)
        self.addConstraint(widthFenceConstraint)
        // 自动布局引擎计算
        fittingHeight = self.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        self.removeConstraint(widthFenceConstraint)
        
        if (fittingHeight == 0) {
            // 尝试frame布局，调用sizeThatFits:
            fittingHeight = self.sizeThatFits(CGSize(width: width, height: 0)).height
        }
        return fittingHeight
    }

    /// 计算动态布局视图指定高度时的宽度。使用AutoLayout必须约束完整，不使用AutoLayout会调用view的sizeThatFits:方法
    public func fw_layoutWidth(height: CGFloat) -> CGFloat {
        var fittingWidth: CGFloat = 0
        
        // 添加固定的height约束，从而使动态视图(如UILabel)横向扩张。而不是纵向增长，flow-layout的方式
        let heightFenceConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: height)
        self.addConstraint(heightFenceConstraint)
        // 自动布局引擎计算
        fittingWidth = self.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width
        self.removeConstraint(heightFenceConstraint)
        
        if (fittingWidth == 0) {
            // 尝试frame布局，调用sizeThatFits:
            fittingWidth = self.sizeThatFits(CGSize(width: 0, height: height)).width
        }
        return fittingWidth
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
    /// 设置视图是否收缩，默认NO，YES时常量值为0，NO时常量值为原始值
    public var fw_collapsed: Bool {
        get {
            return fw_propertyBool(forName: "fw_collapsed")
        }
        set {
            fw_collapseConstraints.enumerateObjects { constraint, _, _ in
                guard let constraint = constraint as? NSLayoutConstraint else { return }
                constraint.constant = newValue ? 0 : constraint.fw_originalConstant
            }
            
            fw_setPropertyBool(newValue, forName: "fw_collapsed")
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

    /// 添加视图的收缩常量，必须先添加才能生效
    ///
    /// - see: [UIView-FDCollapsibleConstraints](https://github.com/forkingdog/UIView-FDCollapsibleConstraints)
    public func fw_addCollapseConstraint(_ constraint: NSLayoutConstraint) {
        constraint.fw_originalConstant = constraint.constant
        if !fw_collapseConstraints.contains(constraint) {
            fw_collapseConstraints.add(constraint)
        }
    }
    
    fileprivate var fw_collapseConstraints: NSMutableArray {
        if let constraints = fw_property(forName: "fw_collapseConstraints") as? NSMutableArray {
            return constraints
        } else {
            let constraints = NSMutableArray()
            fw_setProperty(constraints, forName: "fw_collapseConstraints")
            return constraints
        }
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
        fw_lastLayoutConstraints.setArray(constraints)
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
        fw_lastLayoutConstraints.setArray(constraints)
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
        fw_lastLayoutConstraints.setArray(constraints)
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
        fw_lastLayoutConstraints.setArray(constraints)
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
        fw_lastLayoutConstraints.setArray(constraints)
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
        fw_lastLayoutConstraints.setArray(constraints)
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
        fw_lastLayoutConstraints.setArray(constraints)
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
        fw_lastLayoutConstraints.setArray(constraints)
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
        fw_lastLayoutConstraints.setArray(constraints)
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
        fw_lastLayoutConstraints.setArray(constraints)
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
        fw_lastLayoutConstraints.setArray(constraints)
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
    ///   - relation: 约束关系
    ///   - priority: 约束优先级，默认required
    /// - Returns: 布局约束
    @discardableResult
    public func fw_constrainAttribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView: Any?, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
        return fw_constrainAttribute(attribute, toAttribute: toAttribute, ofView: ofView, multiplier: multiplier, offset: 0, relation: relation, priority: priority)
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
        let constraint = fw_allLayoutConstraints.first { obj in
            guard let obj = obj as? NSLayoutConstraint else { return false }
            return obj.identifier == identifier
        }
        return constraint as? NSLayoutConstraint
    }
    
    /// 最近一批添加或更新的布局约束
    public var fw_lastConstraints: [NSLayoutConstraint] {
        return fw_lastLayoutConstraints as? [NSLayoutConstraint] ?? []
    }
    
    /// 获取当前所有约束
    public var fw_allConstraints: [NSLayoutConstraint] {
        return fw_allLayoutConstraints as? [NSLayoutConstraint] ?? []
    }
    
    /// 移除当前指定约束数组
    /// - Parameter constraints: 布局约束数组
    public func fw_removeConstraints(_ constraints: [NSLayoutConstraint]?) {
        guard let constraints = constraints, !constraints.isEmpty else { return }
        NSLayoutConstraint.deactivate(constraints)
        fw_allLayoutConstraints.removeObjects(in: constraints)
        fw_lastLayoutConstraints.removeObjects(in: constraints)
    }
    
    // MARK: - Private
    private func fw_constrainAttribute(_ attribute: NSLayoutConstraint.Attribute, toSuperview superview: Any?, offset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority) -> NSLayoutConstraint {
        assert(self.superview != nil, "View's superview must not be nil.\nView: \(self)")
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
        
        let constraint = fw_constrainAttribute(attribute, toAttribute: attribute, ofView: superview, multiplier: 1.0, offset: targetOffset, relation: targetRelation, priority: priority)
        constraint.fw_isOpposite = isOpposite
        return constraint
    }
    
    private func fw_constrainAttribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView: Any?, multiplier: CGFloat, offset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority) -> NSLayoutConstraint {
        let targetOffset = fw_autoScale ? UIScreen.fw_relativeValue(offset) : offset
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
            if targetConstraint.constant != targetOffset {
                targetConstraint.constant = targetOffset
            }
        } else {
            targetConstraint = NSLayoutConstraint(item: self, attribute: targetAttribute, relatedBy: relation, toItem: ofView, attribute: targetToAttribute, multiplier: multiplier, constant: targetOffset)
            targetConstraint.identifier = constraintIdentifier
            fw_allLayoutConstraints.add(targetConstraint)
        }
        fw_lastLayoutConstraints.setArray([targetConstraint])
        if targetConstraint.priority != priority {
            targetConstraint.fw_priority = priority
        }
        targetConstraint.isActive = true
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
    
    private var fw_allLayoutConstraints: NSMutableArray {
        if let constraints = fw_property(forName: "fw_allLayoutConstraints") as? NSMutableArray {
            return constraints
        } else {
            let constraints = NSMutableArray()
            fw_setProperty(constraints, forName: "fw_allLayoutConstraints")
            return constraints
        }
    }
    
    private var fw_lastLayoutConstraints: NSMutableArray {
        if let constraints = fw_property(forName: "fw_lastLayoutConstraints") as? NSMutableArray {
            return constraints
        } else {
            let constraints = NSMutableArray()
            fw_setProperty(constraints, forName: "fw_lastLayoutConstraints")
            return constraints
        }
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
                    selfObject.fw_collapsed = true
                } else {
                    selfObject.fw_collapsed = false
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
                selfObject.fw_collapsed = hidden
            }
        }}
    }
    
}

// MARK: - NSLayoutConstraint+AutoLayout
@_spi(FW) extension NSLayoutConstraint {
    
    /// 标记是否是相反的约束，一般相对于父视图
    public var fw_isOpposite: Bool {
        get { fw_propertyBool(forName: "fw_isOpposite") }
        set { fw_setPropertyBool(newValue, forName: "fw_isOpposite") }
    }
    
    /// 设置内间距值，如果是相反的约束，会自动取反
    public var fw_inset: CGFloat {
        get { fw_isOpposite ? -self.constant : self.constant }
        set { self.constant = fw_isOpposite ? -newValue : newValue }
    }
    
    /// 安全修改优先级，防止iOS13以下已激活约束修改Required崩溃
    public var fw_priority: UILayoutPriority {
        get {
            return self.priority
        }
        set {
            __FWRuntime.tryCatch {
                self.priority = newValue
            } exceptionHandler: { exception in
                NSLog("%@", exception)
            }
        }
    }
    
    fileprivate var fw_originalConstant: CGFloat {
        get { fw_propertyDouble(forName: "fw_originalConstant") }
        set { fw_setPropertyDouble(newValue, forName: "fw_originalConstant") }
    }
    
}

// MARK: - AutoLayoutAutoloader
internal class AutoLayoutAutoloader: AutoloadProtocol {
    
    static func autoload() {
        UIView.fw_swizzleAutoLayoutView()
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
        view?.fw_removeConstraints(view?.fw_allConstraints)
        return self
    }
    
    @discardableResult
    public func autoScale(_ autoScale: Bool) -> Self {
        view?.fw_autoScale = autoScale
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
    public func collapsed(_ collapsed: Bool) -> Self {
        view?.fw_collapsed = collapsed
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
        self.view?.fw_alignAxis(.centerX, toView: view)
        self.view?.fw_alignAxis(.centerY, toView: view)
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
    public func top(_ inset: CGFloat = 0) -> Self {
        view?.fw_pinEdge(toSuperview: .top, inset: inset)
        return self
    }
    
    @discardableResult
    public func top(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        view?.fw_pinEdge(toSuperview: .top, inset: inset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func bottom(_ inset: CGFloat = 0) -> Self {
        view?.fw_pinEdge(toSuperview: .bottom, inset: inset)
        return self
    }
    
    @discardableResult
    public func bottom(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        view?.fw_pinEdge(toSuperview: .bottom, inset: inset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func left(_ inset: CGFloat = 0) -> Self {
        view?.fw_pinEdge(toSuperview: .left, inset: inset)
        return self
    }
    
    @discardableResult
    public func left(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        view?.fw_pinEdge(toSuperview: .left, inset: inset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func right(_ inset: CGFloat = 0) -> Self {
        view?.fw_pinEdge(toSuperview: .right, inset: inset)
        return self
    }
    
    @discardableResult
    public func right(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        view?.fw_pinEdge(toSuperview: .right, inset: inset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func top(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.fw_pinEdge(.top, toEdge: .top, ofView: view, offset: offset)
        return self
    }
    
    @discardableResult
    public func top(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw_pinEdge(.top, toEdge: .top, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func bottom(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.fw_pinEdge(.bottom, toEdge: .bottom, ofView: view, offset: offset)
        return self
    }
    
    @discardableResult
    public func bottom(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw_pinEdge(.bottom, toEdge: .bottom, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func left(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.fw_pinEdge(.left, toEdge: .left, ofView: view, offset: offset)
        return self
    }
    
    @discardableResult
    public func left(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw_pinEdge(.left, toEdge: .left, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func right(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.fw_pinEdge(.right, toEdge: .right, ofView: view, offset: offset)
        return self
    }
    
    @discardableResult
    public func right(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw_pinEdge(.right, toEdge: .right, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func top(toViewBottom view: Any, offset: CGFloat = 0) -> Self {
        self.view?.fw_pinEdge(.top, toEdge: .bottom, ofView: view, offset: offset)
        return self
    }
    
    @discardableResult
    public func top(toViewBottom view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw_pinEdge(.top, toEdge: .bottom, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func bottom(toViewTop view: Any, offset: CGFloat = 0) -> Self {
        self.view?.fw_pinEdge(.bottom, toEdge: .top, ofView: view, offset: offset)
        return self
    }

    @discardableResult
    public func bottom(toViewTop view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw_pinEdge(.bottom, toEdge: .top, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func left(toViewRight view: Any, offset: CGFloat = 0) -> Self {
        self.view?.fw_pinEdge(.left, toEdge: .right, ofView: view, offset: offset)
        return self
    }
    
    @discardableResult
    public func left(toViewRight view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw_pinEdge(.left, toEdge: .right, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func right(toViewLeft view: Any, offset: CGFloat = 0) -> Self {
        self.view?.fw_pinEdge(.right, toEdge: .left, ofView: view, offset: offset)
        return self
    }

    @discardableResult
    public func right(toViewLeft view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
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
    public func top(toSafeArea inset: CGFloat) -> Self {
        view?.fw_pinEdge(toSafeArea: .top, inset: inset)
        return self
    }
    
    @discardableResult
    public func top(toSafeArea inset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        view?.fw_pinEdge(toSafeArea: .top, inset: inset, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func bottom(toSafeArea inset: CGFloat) -> Self {
        view?.fw_pinEdge(toSafeArea: .bottom, inset: inset)
        return self
    }

    @discardableResult
    public func bottom(toSafeArea inset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        view?.fw_pinEdge(toSafeArea: .bottom, inset: inset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func left(toSafeArea inset: CGFloat) -> Self {
        view?.fw_pinEdge(toSafeArea: .left, inset: inset)
        return self
    }
    
    @discardableResult
    public func left(toSafeArea inset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        view?.fw_pinEdge(toSafeArea: .left, inset: inset, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func right(toSafeArea inset: CGFloat) -> Self {
        view?.fw_pinEdge(toSafeArea: .right, inset: inset)
        return self
    }

    @discardableResult
    public func right(toSafeArea inset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
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
    public func width(_ width: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw_setDimension(.width, size: width, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func height(_ height: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw_setDimension(.height, size: height, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func width(toHeight multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw_matchDimension(.width, toDimension: .height, multiplier: multiplier, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func height(toWidth multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw_matchDimension(.height, toDimension: .width, multiplier: multiplier, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func size(toView view: Any) -> Self {
        self.view?.fw_matchDimension(.width, toDimension: .width, ofView: view)
        self.view?.fw_matchDimension(.height, toDimension: .height, ofView: view)
        return self
    }

    @discardableResult
    public func width(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.fw_matchDimension(.width, toDimension: .width, ofView: view, offset: offset)
        return self
    }
    
    @discardableResult
    public func width(toView view: Any, offset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw_matchDimension(.width, toDimension: .width, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }
    
    @discardableResult
    public func height(toView view: Any, offset: CGFloat = 0) -> Self {
        self.view?.fw_matchDimension(.height, toDimension: .height, ofView: view, offset: offset)
        return self
    }

    @discardableResult
    public func height(toView view: Any, offset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw_matchDimension(.height, toDimension: .height, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func width(toView view: Any, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw_matchDimension(.width, toDimension: .width, ofView: view, multiplier: multiplier, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func height(toView view: Any, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw_matchDimension(.height, toDimension: .height, ofView: view, multiplier: multiplier, relation: relation, priority: priority)
        return self
    }

    // MARK: - Attribute
    @discardableResult
    public func attribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, offset: CGFloat = 0) -> Self {
        self.view?.fw_constrainAttribute(attribute, toAttribute: toAttribute, ofView: view, offset: offset)
        return self
    }
    
    @discardableResult
    public func attribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, offset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw_constrainAttribute(attribute, toAttribute: toAttribute, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func attribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw_constrainAttribute(attribute, toAttribute: toAttribute, ofView: view, multiplier: multiplier, relation: relation, priority: priority)
        return self
    }
    
    // MARK: - Offset
    @discardableResult
    public func offset(_ offset: CGFloat) -> Self {
        self.view?.fw_lastConstraints.forEach({ obj in
            obj.constant = offset
        })
        return self
    }
    
    @discardableResult
    public func inset(_ inset: CGFloat) -> Self {
        self.view?.fw_lastConstraints.forEach({ obj in
            obj.fw_inset = inset
        })
        return self
    }
    
    @discardableResult
    public func priority(_ priority: UILayoutPriority) -> Self {
        self.view?.fw_lastConstraints.forEach({ obj in
            obj.fw_priority = priority
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
    
}

// MARK: - UIView+LayoutChain
@_spi(FW) extension UIView {

    /// 链式布局对象
    public var fw_layoutChain: LayoutChain {
        if let layoutChain = objc_getAssociatedObject(self, &UIView.fw_layoutChainKey) as? LayoutChain {
            return layoutChain
        }
        
        let layoutChain = LayoutChain(view: self)
        objc_setAssociatedObject(self, &UIView.fw_layoutChainKey, layoutChain, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return layoutChain
    }
    
    /// 链式布局闭包
    public func fw_layoutMaker(_ closure: (_ make: LayoutChain) -> Void) {
        closure(fw_layoutChain)
    }
    
    /// 关联对象Key
    private static var fw_layoutChainKey = "fw_layoutChain"
    
}
