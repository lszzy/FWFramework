//
//  AutoLayout.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

// MARK: - Wrapper+UIView
/// UIView自动布局分类，兼容UIView和UILayoutGuide(iOS9)
/// 如果约束条件完全相同，会自动更新约束而不是重新添加。
/// 默认布局方式使用LTR，如果需要RTL布局，可通过fwAutoLayoutRTL统一启用
///
/// 另外，safeAreaLayoutGuide在iOS13+都包含顶部导航栏，所以布局时使用top(toSafeArea:)方式是安全的；
/// 但是，safeAreaLayoutGuide在iOS15+包含底部标签栏，在iOS14及以下却不包含，因此在含有标签栏的页面使用bottom(toSafeArea:)时需注意，兼容方法示例：
/// 1. 可以将控制器的edgesForExtendedLayout在标签栏页面(通常hidesBottomBarWhenPushed为false)时设置为top或[]，不扩展标签栏，这样在iOS14及以下不会被标签栏遮挡
/// 2. 也可以在标签栏页面布局时将下间距设置为bottomBarHeight，如需兼容横屏则屏幕方向变化时刷新布局即可
/// 3. 或者自定义控制器additionalSafeAreaInsets排除标签栏，如需兼容横屏则屏幕方向变化时刷新附加安全区域
@MainActor extension Wrapper where Base: UIView {
    // MARK: - AutoLayout
    /// 是否启用自动布局适配RTL，启用后自动将Left|Right转换为Leading|Trailing，默认NO
    ///
    /// 如果项目兼容阿拉伯语等，需要启用RTL从右向左布局，开启此开关即可，无需修改布局代码
    /// 手工切换视图左右布局方法：[UIView appearance].semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    public static var autoLayoutRTL: Bool {
        get { UIView.innerAutoLayoutRTL }
        set { UIView.innerAutoLayoutRTL = newValue }
    }

    /// 自定义全局自动等比例缩放适配句柄，默认nil
    ///
    /// 启用全局等比例缩放后，所有offset值都会调用该句柄，需注意可能产生的影响。
    /// 启用后注意事项如下：
    /// 1. 屏幕宽度约束不能使用screenWidth约束，需要使用375设计标准
    /// 2. 尽量不使用screenWidth固定屏幕宽度方式布局，推荐相对于父视图布局
    /// 2. 只会对offset值生效，其他属性不受影响
    /// 3. 某个视图如需固定offset值，可指定autoScaleLayout为false关闭该功能
    public static var autoScaleBlock: (@MainActor @Sendable (CGFloat) -> CGFloat)? {
        get { UIView.innerAutoScaleBlock }
        set { UIView.innerAutoScaleBlock = newValue }
    }

    /// 快捷启用全局自动等比例缩放布局，自动设置默认autoScaleBlock
    ///
    /// 框架仅BadgeView和ToolbarView默认关闭等比例缩放布局，采用固定值布局；
    /// 其余使用AutoLayout的场景统一使用全局等比例缩放布局开关设置
    public static var autoScaleLayout: Bool {
        get {
            autoScaleBlock != nil
        }
        set {
            guard newValue != autoScaleLayout else { return }
            autoScaleBlock = newValue ? { @MainActor @Sendable in UIScreen.fw.relativeValue($0, flat: autoFlatLayout) } : nil
        }
    }

    /// 是否启用全局自动像素取整布局，默认false
    public static var autoFlatLayout: Bool {
        get { UIView.innerAutoFlatLayout }
        set { UIView.innerAutoFlatLayout = newValue }
    }

    /// 当前视图是否自动等比例缩放布局，默认未设置时检查autoScaleBlock
    ///
    /// 框架仅BadgeView和ToolbarView默认关闭等比例缩放布局，采用固定值布局；
    /// 其余使用AutoLayout的场景统一使用全局等比例缩放布局开关设置
    public var autoScaleLayout: Bool {
        get {
            if let number = propertyNumber(forName: "autoScaleLayout") {
                return number.boolValue
            }
            return UIView.innerAutoScaleBlock != nil
        }
        set {
            setPropertyNumber(NSNumber(value: newValue), forName: "autoScaleLayout")
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
    /// 设置视图是否收缩，默认NO为原始值，YES时为收缩值
    public var isCollapsed: Bool {
        get {
            propertyBool(forName: "isCollapsed")
        }
        set {
            // 为了防止修改active时约束冲突，始终将已激活的约束放到前面修改
            collapseConstraints.sorted { constraint, _ in
                guard constraint.fw.shouldCollapseActive else { return false }
                return newValue ? constraint.fw.originalActive : !constraint.fw.originalActive
            }.forEach { constraint in
                constraint.fw.isCollapsed = newValue
            }

            setPropertyBool(newValue, forName: "isCollapsed")
        }
    }

    /// 设置视图是否自动收缩，如image为nil，text为nil、@""时自动收缩，默认NO
    public var autoCollapse: Bool {
        get { propertyBool(forName: "autoCollapse") }
        set { setPropertyBool(newValue, forName: "autoCollapse") }
    }

    /// 设置视图宽度或高度布局固定时，是否根据尺寸自适应另一边，默认false；
    /// 开启时当intrinsicContentSize有值时，会自动添加matchDimension约束
    public var autoMatchDimension: Bool {
        get { propertyBool(forName: "autoMatchDimension") }
        set {
            let oldValue = autoMatchDimension
            setPropertyBool(newValue, forName: "autoMatchDimension")
            if newValue != oldValue {
                base.setNeedsUpdateConstraints()
                base.updateConstraintsIfNeeded()
                base.invalidateIntrinsicContentSize()
            }
        }
    }

    /// 设置视图是否隐藏时自动收缩、显示时自动展开，默认NO
    public var hiddenCollapse: Bool {
        get { propertyBool(forName: "hiddenCollapse") }
        set { setPropertyBool(newValue, forName: "hiddenCollapse") }
    }

    /// 快速切换视图是否收缩
    public func toggleCollapsed(_ collapsed: Bool? = nil) {
        if let collapsed {
            isCollapsed = collapsed
        } else {
            isCollapsed = !isCollapsed
        }
    }

    /// 快速切换视图是否隐藏
    public func toggleHidden(_ hidden: Bool? = nil) {
        if let hidden {
            base.isHidden = hidden
        } else {
            base.isHidden = !base.isHidden
        }
    }

    /// 添加视图的偏移收缩约束，必须先添加才能生效
    ///
    /// - see: [UIView-FDCollapsibleConstraints](https://github.com/forkingdog/UIView-FDCollapsibleConstraints)
    public func addCollapseConstraint(_ constraint: NSLayoutConstraint, offset: CGFloat? = nil) {
        if let offset {
            constraint.fw.collapseOffset = offset
        }
        constraint.fw.shouldCollapseOffset = true
        if !collapseConstraints.contains(constraint) {
            collapseConstraints.append(constraint)
        }
    }

    /// 添加视图的有效性收缩约束，必须先添加才能生效
    public func addCollapseActiveConstraint(_ constraint: NSLayoutConstraint, active: Bool? = nil) {
        if let active {
            constraint.isActive = active
        }
        constraint.fw.shouldCollapseActive = true
        if !collapseConstraints.contains(constraint) {
            collapseConstraints.append(constraint)
        }
    }

    /// 添加视图的优先级收缩约束，必须先添加才能生效
    public func addCollapsePriorityConstraint(_ constraint: NSLayoutConstraint, priority: UILayoutPriority? = nil) {
        if let priority {
            constraint.fw.collapsePriority = priority
        }
        constraint.fw.shouldCollapsePriority = true
        if !collapseConstraints.contains(constraint) {
            collapseConstraints.append(constraint)
        }
    }

    /// 移除指定的视图收缩约束
    public func removeCollapseConstraint(_ constraint: NSLayoutConstraint) {
        collapseConstraints.removeAll { $0 == constraint }
    }

    /// 移除所有的视图收缩约束
    public func removeAllCollapseConstraints() {
        collapseConstraints.removeAll()
    }

    fileprivate var collapseConstraints: [NSLayoutConstraint] {
        get { property(forName: "collapseConstraints") as? [NSLayoutConstraint] ?? [] }
        set { setProperty(newValue, forName: "collapseConstraints") }
    }

    fileprivate var matchDimensionConstraint: NSLayoutConstraint? {
        get { property(forName: "matchDimensionConstraint") as? NSLayoutConstraint }
        set { setProperty(newValue, forName: "matchDimensionConstraint") }
    }

    // MARK: - Axis
    /// 父视图居中，可指定偏移距离
    /// - Parameters:
    ///   - offset: 偏移距离，默认zero
    ///   - autoScale: 是否自动等比例缩放偏移值，未设置时检查视图和全局配置
    /// - Returns: 约束数组
    @discardableResult
    public func alignCenter(
        toSuperview offset: CGPoint = .zero,
        autoScale: Bool? = nil
    ) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        constraints.append(alignAxis(toSuperview: .centerX, offset: offset.x, autoScale: autoScale))
        constraints.append(alignAxis(toSuperview: .centerY, offset: offset.y, autoScale: autoScale))
        lastConstraints = constraints
        return constraints
    }

    /// 父视图属性居中，可指定偏移距离
    /// - Parameters:
    ///   - axis: 居中属性
    ///   - offset: 偏移距离，默认0
    ///   - autoScale: 是否自动等比例缩放偏移值，未设置时检查视图和全局配置
    /// - Returns: 布局约束
    @discardableResult
    public func alignAxis(
        toSuperview axis: NSLayoutConstraint.Attribute,
        offset: CGFloat = 0,
        autoScale: Bool? = nil
    ) -> NSLayoutConstraint {
        constrainAttribute(axis, toSuperview: base.superview, offset: offset, relation: .equal, priority: .required, autoScale: autoScale)
    }

    /// 与另一视图居中相同，可指定偏移距离
    /// - Parameters:
    ///   - axis: 居中属性
    ///   - toView: 另一视图或UILayoutGuide，下同
    ///   - offset: 偏移距离，默认0
    ///   - autoScale: 是否自动等比例缩放偏移值，未设置时检查视图和全局配置
    /// - Returns: 布局约束
    @discardableResult
    public func alignAxis(
        _ axis: NSLayoutConstraint.Attribute,
        toView: Any,
        offset: CGFloat = 0,
        autoScale: Bool? = nil
    ) -> NSLayoutConstraint {
        constrainAttribute(axis, toAttribute: axis, ofView: toView, offset: offset, autoScale: autoScale)
    }

    /// 与另一视图居中指定比例
    /// - Parameters:
    ///   - axis: 居中属性
    ///   - toView: 另一视图
    ///   - multiplier: 指定比例
    ///   - autoScale: 是否自动等比例缩放偏移值，未设置时检查视图和全局配置
    /// - Returns: 布局约束
    @discardableResult
    public func alignAxis(
        _ axis: NSLayoutConstraint.Attribute,
        toView: Any,
        multiplier: CGFloat,
        autoScale: Bool? = nil
    ) -> NSLayoutConstraint {
        constrainAttribute(axis, toAttribute: axis, ofView: toView, multiplier: multiplier, autoScale: autoScale)
    }

    // MARK: - Edge
    /// 与父视图四条边属性相同，可指定insets距离
    /// - Parameters:
    ///   - insets: 指定距离insets，默认zero
    ///   - autoScale: 是否自动等比例缩放偏移值，未设置时检查视图和全局配置
    /// - Returns: 约束数组
    @discardableResult
    public func pinEdges(
        toSuperview insets: UIEdgeInsets = .zero,
        autoScale: Bool? = nil
    ) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        constraints.append(pinEdge(toSuperview: .top, inset: insets.top, autoScale: autoScale))
        constraints.append(pinEdge(toSuperview: .left, inset: insets.left, autoScale: autoScale))
        constraints.append(pinEdge(toSuperview: .bottom, inset: insets.bottom, autoScale: autoScale))
        constraints.append(pinEdge(toSuperview: .right, inset: insets.right, autoScale: autoScale))
        lastConstraints = constraints
        return constraints
    }

    /// 与父视图三条边属性距离指定距离
    /// - Parameters:
    ///   - insets: 指定距离insets
    ///   - excludingEdge: 排除的边
    ///   - autoScale: 是否自动等比例缩放偏移值，未设置时检查视图和全局配置
    /// - Returns: 约束数组
    @discardableResult
    public func pinEdges(
        toSuperview insets: UIEdgeInsets = .zero,
        excludingEdge: NSLayoutConstraint.Attribute,
        autoScale: Bool? = nil
    ) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        if excludingEdge != .top {
            constraints.append(pinEdge(toSuperview: .top, inset: insets.top, autoScale: autoScale))
        }
        if excludingEdge != .leading && excludingEdge != .left {
            constraints.append(pinEdge(toSuperview: .left, inset: insets.left, autoScale: autoScale))
        }
        if excludingEdge != .bottom {
            constraints.append(pinEdge(toSuperview: .bottom, inset: insets.bottom, autoScale: autoScale))
        }
        if excludingEdge != .trailing && excludingEdge != .right {
            constraints.append(pinEdge(toSuperview: .right, inset: insets.right, autoScale: autoScale))
        }
        lastConstraints = constraints
        return constraints
    }

    /// 与父视图水平方向两条边属性相同，可指定偏移距离
    /// - Parameters:
    ///   - inset: 偏移距离
    ///   - autoScale: 是否自动等比例缩放偏移值，未设置时检查视图和全局配置
    /// - Returns: 约束数组
    @discardableResult
    public func pinHorizontal(
        toSuperview inset: CGFloat = .zero,
        autoScale: Bool? = nil
    ) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        constraints.append(pinEdge(toSuperview: .left, inset: inset, autoScale: autoScale))
        constraints.append(pinEdge(toSuperview: .right, inset: inset, autoScale: autoScale))
        lastConstraints = constraints
        return constraints
    }

    /// 与父视图垂直方向两条边属性相同，可指定偏移距离
    /// - Parameters:
    ///   - inset: 偏移距离
    ///   - autoScale: 是否自动等比例缩放偏移值，未设置时检查视图和全局配置
    /// - Returns: 约束数组
    @discardableResult
    public func pinVertical(
        toSuperview inset: CGFloat = .zero,
        autoScale: Bool? = nil
    ) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        constraints.append(pinEdge(toSuperview: .top, inset: inset, autoScale: autoScale))
        constraints.append(pinEdge(toSuperview: .bottom, inset: inset, autoScale: autoScale))
        lastConstraints = constraints
        return constraints
    }

    /// 与父视图边属性相同，可指定偏移距离和关系
    /// - Parameters:
    ///   - edge: 指定边属性
    ///   - inset: 偏移距离，默认0
    ///   - relation: 约束关系，默认相等
    ///   - priority: 约束优先级，默认required
    ///   - autoScale: 是否自动等比例缩放偏移值，未设置时检查视图和全局配置
    /// - Returns: 布局约束
    @discardableResult
    public func pinEdge(
        toSuperview edge: NSLayoutConstraint.Attribute,
        inset: CGFloat = .zero,
        relation: NSLayoutConstraint.Relation = .equal,
        priority: UILayoutPriority = .required,
        autoScale: Bool? = nil
    ) -> NSLayoutConstraint {
        constrainAttribute(edge, toSuperview: base.superview, offset: inset, relation: relation, priority: priority, autoScale: autoScale)
    }

    /// 与指定视图边属性相同，可指定偏移距离和关系
    /// - Parameters:
    ///   - edge: 指定边属性
    ///   - toEdge: 另一视图边属性
    ///   - ofView: 另一视图
    ///   - offset: 偏移距离，默认0
    ///   - relation: 约束关系，默认相等
    ///   - priority: 约束优先级，默认required
    ///   - autoScale: 是否自动等比例缩放偏移值，未设置时检查视图和全局配置
    /// - Returns: 布局约束
    @discardableResult
    public func pinEdge(
        _ edge: NSLayoutConstraint.Attribute,
        toEdge: NSLayoutConstraint.Attribute,
        ofView: Any,
        offset: CGFloat = 0,
        relation: NSLayoutConstraint.Relation = .equal,
        priority: UILayoutPriority = .required,
        autoScale: Bool? = nil
    ) -> NSLayoutConstraint {
        constrainAttribute(edge, toAttribute: toEdge, ofView: ofView, offset: offset, relation: relation, priority: priority, autoScale: autoScale)
    }

    // MARK: - SafeArea
    /// 父视图安全区域居中，可指定偏移距离。iOS11以下使用Superview实现，下同
    /// - Parameters:
    ///   - offset: 偏移距离
    ///   - autoScale: 是否自动等比例缩放偏移值，未设置时检查视图和全局配置
    /// - Returns: 约束数组
    @discardableResult
    public func alignCenter(
        toSafeArea offset: CGPoint,
        autoScale: Bool? = nil
    ) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        constraints.append(alignAxis(toSafeArea: .centerX, offset: offset.x, autoScale: autoScale))
        constraints.append(alignAxis(toSafeArea: .centerY, offset: offset.y, autoScale: autoScale))
        lastConstraints = constraints
        return constraints
    }

    /// 父视图安全区域属性居中，可指定偏移距离
    /// - Parameters:
    ///   - axis: 居中属性
    ///   - offset: 偏移距离，默认0
    ///   - autoScale: 是否自动等比例缩放偏移值，未设置时检查视图和全局配置
    /// - Returns: 布局约束
    @discardableResult
    public func alignAxis(
        toSafeArea axis: NSLayoutConstraint.Attribute,
        offset: CGFloat = .zero,
        autoScale: Bool? = nil
    ) -> NSLayoutConstraint {
        constrainAttribute(axis, toSuperview: base.superview?.safeAreaLayoutGuide, offset: offset, relation: .equal, priority: .required, autoScale: autoScale)
    }

    /// 与父视图安全区域四条边属性相同，可指定距离insets
    /// - Parameters:
    ///   - insets: 指定距离insets
    ///   - autoScale: 是否自动等比例缩放偏移值，未设置时检查视图和全局配置
    /// - Returns: 约束数组
    @discardableResult
    public func pinEdges(
        toSafeArea insets: UIEdgeInsets,
        autoScale: Bool? = nil
    ) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        constraints.append(pinEdge(toSafeArea: .top, inset: insets.top, autoScale: autoScale))
        constraints.append(pinEdge(toSafeArea: .left, inset: insets.left, autoScale: autoScale))
        constraints.append(pinEdge(toSafeArea: .bottom, inset: insets.bottom, autoScale: autoScale))
        constraints.append(pinEdge(toSafeArea: .right, inset: insets.right, autoScale: autoScale))
        lastConstraints = constraints
        return constraints
    }

    /// 与父视图安全区域三条边属性距离指定距离
    /// - Parameters:
    ///   - insets: 指定距离insets
    ///   - excludingEdge: 排除的边
    ///   - autoScale: 是否自动等比例缩放偏移值，未设置时检查视图和全局配置
    /// - Returns: 约束数组
    @discardableResult
    public func pinEdges(
        toSafeArea insets: UIEdgeInsets,
        excludingEdge: NSLayoutConstraint.Attribute,
        autoScale: Bool? = nil
    ) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        if excludingEdge != .top {
            constraints.append(pinEdge(toSafeArea: .top, inset: insets.top, autoScale: autoScale))
        }
        if excludingEdge != .leading && excludingEdge != .left {
            constraints.append(pinEdge(toSafeArea: .left, inset: insets.left, autoScale: autoScale))
        }
        if excludingEdge != .bottom {
            constraints.append(pinEdge(toSafeArea: .bottom, inset: insets.bottom, autoScale: autoScale))
        }
        if excludingEdge != .trailing && excludingEdge != .right {
            constraints.append(pinEdge(toSafeArea: .right, inset: insets.right, autoScale: autoScale))
        }
        lastConstraints = constraints
        return constraints
    }

    /// 与父视图安全区域水平方向两条边属性相同，可指定偏移距离
    /// - Parameters:
    ///   - inset: 偏移距离
    ///   - autoScale: 是否自动等比例缩放偏移值，未设置时检查视图和全局配置
    /// - Returns: 约束数组
    @discardableResult
    public func pinHorizontal(
        toSafeArea inset: CGFloat,
        autoScale: Bool? = nil
    ) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        constraints.append(pinEdge(toSafeArea: .left, inset: inset, autoScale: autoScale))
        constraints.append(pinEdge(toSafeArea: .right, inset: inset, autoScale: autoScale))
        lastConstraints = constraints
        return constraints
    }

    /// 与父视图安全区域垂直方向两条边属性相同，可指定偏移距离
    /// - Parameters:
    ///   - inset: 偏移距离
    ///   - autoScale: 是否自动等比例缩放偏移值，未设置时检查视图和全局配置
    /// - Returns: 约束数组
    @discardableResult
    public func pinVertical(
        toSafeArea inset: CGFloat,
        autoScale: Bool? = nil
    ) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        constraints.append(pinEdge(toSafeArea: .top, inset: inset, autoScale: autoScale))
        constraints.append(pinEdge(toSafeArea: .bottom, inset: inset, autoScale: autoScale))
        lastConstraints = constraints
        return constraints
    }

    /// 与父视图安全区域边属性相同，可指定偏移距离和关系
    /// - Parameters:
    ///   - edge: 指定边属性
    ///   - inset: 偏移距离，默认0
    ///   - relation: 约束关系，默认相等
    ///   - priority: 约束优先级，默认required
    ///   - autoScale: 是否自动等比例缩放偏移值，未设置时检查视图和全局配置
    /// - Returns: 布局约束
    @discardableResult
    public func pinEdge(
        toSafeArea edge: NSLayoutConstraint.Attribute,
        inset: CGFloat = .zero,
        relation: NSLayoutConstraint.Relation = .equal,
        priority: UILayoutPriority = .required,
        autoScale: Bool? = nil
    ) -> NSLayoutConstraint {
        constrainAttribute(edge, toSuperview: base.superview?.safeAreaLayoutGuide, offset: inset, relation: relation, priority: priority, autoScale: autoScale)
    }

    // MARK: - Dimension
    /// 设置宽高尺寸
    /// - Parameters:
    ///   - size: 尺寸大小
    ///   - autoScale: 是否自动等比例缩放偏移值，未设置时检查视图和全局配置
    /// - Returns: 约束数组
    @discardableResult
    public func setDimensions(
        _ size: CGSize,
        autoScale: Bool? = nil
    ) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        constraints.append(setDimension(.width, size: size.width, autoScale: autoScale))
        constraints.append(setDimension(.height, size: size.height, autoScale: autoScale))
        lastConstraints = constraints
        return constraints
    }

    /// 设置某个尺寸，可指定关系
    /// - Parameters:
    ///   - dimension: 尺寸属性
    ///   - size: 尺寸大小
    ///   - relation: 约束关系，默认相等
    ///   - priority: 约束优先级，默认required
    ///   - autoScale: 是否自动等比例缩放偏移值，未设置时检查视图和全局配置
    /// - Returns: 布局约束
    @discardableResult
    public func setDimension(
        _ dimension: NSLayoutConstraint.Attribute,
        size: CGFloat,
        relation: NSLayoutConstraint.Relation = .equal,
        priority: UILayoutPriority = .required,
        autoScale: Bool? = nil
    ) -> NSLayoutConstraint {
        constrainAttribute(dimension, toAttribute: .notAnAttribute, ofView: nil, multiplier: 0, offset: size, relation: relation, priority: priority, autoScale: autoScale)
    }

    /// 与视图自身尺寸属性指定比例，指定关系
    /// - Parameters:
    ///   - dimension: 尺寸属性
    ///   - toDimension: 目标尺寸属性
    ///   - multiplier: 指定比例
    ///   - relation: 约束关系
    ///   - priority: 约束优先级，默认required
    ///   - autoScale: 是否自动等比例缩放偏移值，未设置时检查视图和全局配置
    /// - Returns: 布局约束
    @discardableResult
    public func matchDimension(
        _ dimension: NSLayoutConstraint.Attribute,
        toDimension: NSLayoutConstraint.Attribute,
        multiplier: CGFloat,
        relation: NSLayoutConstraint.Relation = .equal,
        priority: UILayoutPriority = .required,
        autoScale: Bool? = nil
    ) -> NSLayoutConstraint {
        matchDimension(dimension, toDimension: toDimension, ofView: base, multiplier: multiplier, relation: relation, priority: priority, autoScale: autoScale)
    }

    /// 与指定视图尺寸属性相同，可指定相差大小和关系
    /// - Parameters:
    ///   - dimension: 尺寸属性
    ///   - toDimension: 目标尺寸属性
    ///   - ofView: 目标视图
    ///   - offset: 相差大小，默认0
    ///   - relation: 约束关系，默认相等
    ///   - priority: 约束优先级，默认required
    ///   - autoScale: 是否自动等比例缩放偏移值，未设置时检查视图和全局配置
    /// - Returns: 布局约束
    @discardableResult
    public func matchDimension(
        _ dimension: NSLayoutConstraint.Attribute,
        toDimension: NSLayoutConstraint.Attribute,
        ofView: Any,
        offset: CGFloat = .zero,
        relation: NSLayoutConstraint.Relation = .equal,
        priority: UILayoutPriority = .required,
        autoScale: Bool? = nil
    ) -> NSLayoutConstraint {
        constrainAttribute(dimension, toAttribute: toDimension, ofView: ofView, offset: offset, relation: relation, priority: priority, autoScale: autoScale)
    }

    /// 与指定视图尺寸属性指定比例，可指定关系
    /// - Parameters:
    ///   - dimension: 尺寸属性
    ///   - toDimension: 目标尺寸属性
    ///   - ofView: 目标视图
    ///   - multiplier: 指定比例
    ///   - relation: 约束关系，默认相等
    ///   - priority: 约束优先级，默认required
    ///   - autoScale: 是否自动等比例缩放偏移值，未设置时检查视图和全局配置
    /// - Returns: 布局约束
    @discardableResult
    public func matchDimension(
        _ dimension: NSLayoutConstraint.Attribute,
        toDimension: NSLayoutConstraint.Attribute,
        ofView: Any,
        multiplier: CGFloat,
        relation: NSLayoutConstraint.Relation = .equal,
        priority: UILayoutPriority = .required,
        autoScale: Bool? = nil
    ) -> NSLayoutConstraint {
        constrainAttribute(dimension, toAttribute: toDimension, ofView: ofView, multiplier: multiplier, relation: relation, priority: priority, autoScale: autoScale)
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
    ///   - autoScale: 是否自动等比例缩放偏移值，未设置时检查视图和全局配置
    /// - Returns: 布局约束
    @discardableResult
    public func constrainAttribute(
        _ attribute: NSLayoutConstraint.Attribute,
        toAttribute: NSLayoutConstraint.Attribute,
        ofView: Any?,
        offset: CGFloat = .zero,
        relation: NSLayoutConstraint.Relation = .equal,
        priority: UILayoutPriority = .required,
        autoScale: Bool? = nil
    ) -> NSLayoutConstraint {
        constrainAttribute(attribute, toAttribute: toAttribute, ofView: ofView, multiplier: 1.0, offset: offset, relation: relation, priority: priority, autoScale: autoScale)
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
    ///   - autoScale: 是否自动等比例缩放偏移值，未设置时检查视图和全局配置
    /// - Returns: 布局约束
    @discardableResult
    public func constrainAttribute(
        _ attribute: NSLayoutConstraint.Attribute,
        toAttribute: NSLayoutConstraint.Attribute,
        ofView: Any?,
        multiplier: CGFloat,
        offset: CGFloat = .zero,
        relation: NSLayoutConstraint.Relation = .equal,
        priority: UILayoutPriority = .required,
        autoScale: Bool? = nil
    ) -> NSLayoutConstraint {
        constrainAttribute(attribute, toAttribute: toAttribute, ofView: ofView, multiplier: multiplier, offset: offset, relation: relation, priority: priority, isOpposite: false, autoScale: autoScale)
    }

    // MARK: - Constraint
    /// 获取添加的与父视图属性的约束，指定关系
    /// - Parameters:
    ///   - attribute: 指定属性
    ///   - relation: 约束关系
    /// - Returns: 布局约束
    public func constraint(toSuperview attribute: NSLayoutConstraint.Attribute, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint? {
        constraint(attribute, toSuperview: base.superview, relation: relation)
    }

    /// 获取添加的与父视图安全区域属性的约束，指定关系
    /// - Parameters:
    ///   - attribute: 指定属性
    ///   - relation: 约束关系
    /// - Returns: 布局约束
    public func constraint(toSafeArea attribute: NSLayoutConstraint.Attribute, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint? {
        constraint(attribute, toSuperview: base.superview?.safeAreaLayoutGuide, relation: relation)
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
        constraint(attribute, toAttribute: toAttribute, ofView: ofView, multiplier: 1.0, relation: relation)
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
        if UIView.innerAutoLayoutRTL {
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
        guard let identifier, !identifier.isEmpty else { return nil }
        return allConstraints.first { obj in
            identifier == obj.fw.layoutIdentifier || identifier == obj.identifier
        }
    }

    /// 最近一批添加或更新的布局约束
    public var lastConstraints: [NSLayoutConstraint] {
        get { property(forName: "lastConstraints") as? [NSLayoutConstraint] ?? [] }
        set { setProperty(newValue, forName: "lastConstraints") }
    }

    /// 获取当前所有约束
    public private(set) var allConstraints: [NSLayoutConstraint] {
        get { property(forName: "allConstraints") as? [NSLayoutConstraint] ?? [] }
        set { setProperty(newValue, forName: "allConstraints") }
    }

    /// 移除当前指定约束数组
    /// - Parameter constraints: 布局约束数组
    public func removeConstraints(_ constraints: [NSLayoutConstraint]?) {
        guard let constraints, !constraints.isEmpty else { return }
        NSLayoutConstraint.deactivate(constraints)
        allConstraints.removeAll { constraints.contains($0) }
        lastConstraints.removeAll { constraints.contains($0) }
    }

    /// 移除当前所有约束
    public func removeAllConstraints() {
        NSLayoutConstraint.deactivate(allConstraints)
        allConstraints.removeAll()
        lastConstraints.removeAll()
    }

    private func constrainAttribute(_ attribute: NSLayoutConstraint.Attribute, toSuperview superview: Any?, offset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority, autoScale: Bool?) -> NSLayoutConstraint {
        assert(base.superview != nil, "View's superview must not be nil.\nView: \(base)")
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

        return constrainAttribute(attribute, toAttribute: attribute, ofView: superview, multiplier: 1.0, offset: offset, relation: targetRelation, priority: priority, isOpposite: isOpposite, autoScale: autoScale)
    }

    private func constrainAttribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView: Any?, multiplier: CGFloat, offset: CGFloat, relation: NSLayoutConstraint.Relation, priority: UILayoutPriority, isOpposite: Bool, autoScale: Bool?) -> NSLayoutConstraint {
        var targetAttribute = attribute
        var targetToAttribute = toAttribute
        if UIView.innerAutoLayoutRTL {
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
        } else {
            targetConstraint = NSLayoutConstraint(item: base, attribute: targetAttribute, relatedBy: relation, toItem: ofView, attribute: targetToAttribute, multiplier: multiplier, constant: 0)
            targetConstraint.fw.isOpposite = isOpposite
            targetConstraint.fw.layoutIdentifier = constraintIdentifier
            targetConstraint.identifier = constraintIdentifier
            allConstraints.append(targetConstraint)
        }
        lastConstraints = [targetConstraint]
        if let autoScale {
            targetConstraint.fw.autoScaleLayout = autoScale
        }
        targetConstraint.fw.offset = offset
        if targetConstraint.priority != priority {
            targetConstraint.priority = priority
        }
        if !targetConstraint.isActive {
            targetConstraint.isActive = true
        }
        return targetConstraint
    }

    private func constraintIdentifier(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, multiplier: CGFloat, relation: NSLayoutConstraint.Relation) -> String {
        var viewHash = ""
        if let view = view as? NSObject {
            viewHash = "\(view.hash)"
        } else if let view {
            viewHash = String(describing: view)
        }
        return String(format: "%ld-%ld-%@-%ld-%@", attribute.rawValue, relation.rawValue, viewHash, toAttribute.rawValue, NSNumber(value: multiplier))
    }

    // MARK: - Debug
    /// 自动布局调试开关，默认调试打开，正式关闭
    public static var autoLayoutDebug: Bool {
        get {
            UIView.innerAutoLayoutDebug
        }
        set {
            UIView.innerAutoLayoutDebug = newValue
            if newValue { FrameworkAutoloader.swizzleAutoLayoutDebug() }
        }
    }

    /// 布局调试Key，默认accessibilityIdentifier
    public var layoutKey: String? {
        get { property(forName: "layoutKey") as? String ?? base.accessibilityIdentifier }
        set { setPropertyCopy(newValue, forName: "layoutKey") }
    }
}

// MARK: - Wrapper+NSLayoutConstraint
@MainActor extension Wrapper where Base: NSLayoutConstraint {
    /// 是否自动等比例缩放偏移值，默认未设置时检查视图和全局配置
    public var autoScaleLayout: Bool {
        get {
            if let number = propertyNumber(forName: "autoScaleLayout") {
                return number.boolValue
            }

            var autoScaleLayout = UIView.fw.autoScaleLayout
            if let view = base.firstItem as? UIView {
                autoScaleLayout = view.fw.autoScaleLayout
            } else if let view = (base.firstItem as? UILayoutGuide)?.owningView {
                autoScaleLayout = view.fw.autoScaleLayout
            }
            return autoScaleLayout
        }
        set {
            setPropertyNumber(NSNumber(value: newValue), forName: "autoScaleLayout")

            if let offsetNumber = propertyNumber(forName: "offset") {
                offset = offsetNumber.doubleValue
            }
        }
    }

    /// 设置偏移值，根据配置自动等比例缩放和取反
    public var offset: CGFloat {
        get {
            let number = propertyNumber(forName: "offset")
            return number?.doubleValue ?? .zero
        }
        set {
            setPropertyNumber(NSNumber(value: newValue), forName: "offset")

            var offset = newValue
            if autoScaleLayout {
                offset = UIView.innerAutoScaleBlock?(newValue) ?? UIScreen.fw.relativeValue(newValue, flat: UIView.innerAutoFlatLayout)
            }
            base.constant = isOpposite ? -offset : offset
        }
    }

    /// 标记是否是相反的约束，一般相对于父视图
    public var isOpposite: Bool {
        get { propertyBool(forName: "isOpposite") }
        set { setPropertyBool(newValue, forName: "isOpposite") }
    }

    /// 可收缩约束的收缩偏移值，默认0
    public var collapseOffset: CGFloat {
        get { propertyDouble(forName: "collapseOffset") }
        set { setPropertyDouble(newValue, forName: "collapseOffset") }
    }

    /// 可收缩约束的原始偏移值，默认为添加收缩约束时的值，未添加时为0
    public var originalOffset: CGFloat {
        get { propertyDouble(forName: "originalOffset") }
        set { setPropertyDouble(newValue, forName: "originalOffset") }
    }

    /// 可收缩约束的收缩优先级，默认defaultLow。注意Required不能修改，否则iOS13以下崩溃
    public var collapsePriority: UILayoutPriority {
        get {
            if let number = propertyNumber(forName: "collapsePriority") {
                return .init(number.floatValue)
            }
            return .defaultLow
        }
        set {
            setPropertyNumber(NSNumber(value: newValue.rawValue), forName: "collapsePriority")
        }
    }

    /// 可收缩约束的原始优先级，默认为添加收缩约束时的值，未添加时为defaultHigh。注意Required不能修改，否则iOS13以下崩溃
    public var originalPriority: UILayoutPriority {
        get {
            if let number = propertyNumber(forName: "originalPriority") {
                return .init(number.floatValue)
            }
            return .defaultHigh
        }
        set {
            setPropertyNumber(NSNumber(value: newValue.rawValue), forName: "originalPriority")
        }
    }

    /// 可收缩约束的原始有效值，默认为添加收缩约束时的有效值，未添加时为false
    public var originalActive: Bool {
        get {
            if let number = propertyNumber(forName: "originalActive") {
                return number.boolValue
            }
            return false
        }
        set {
            setPropertyNumber(NSNumber(value: newValue), forName: "originalActive")
        }
    }

    /// 约束偏移是否可收缩，默认false，开启时自动初始化originalOffset
    public var shouldCollapseOffset: Bool {
        get {
            propertyBool(forName: "shouldCollapseOffset")
        }
        set {
            guard newValue != shouldCollapseOffset else { return }
            if newValue { originalOffset = offset }
            setPropertyBool(newValue, forName: "shouldCollapseOffset")
        }
    }

    /// 约束有效性是否可收缩，默认false，开启时自动初始化originalActive
    public var shouldCollapseActive: Bool {
        get {
            propertyBool(forName: "shouldCollapseActive")
        }
        set {
            guard newValue != shouldCollapseActive else { return }
            if newValue { originalActive = base.isActive }
            setPropertyBool(newValue, forName: "shouldCollapseActive")
        }
    }

    /// 约束优先级是否可收缩，默认false，开启时自动初始化originalPriority
    public var shouldCollapsePriority: Bool {
        get {
            propertyBool(forName: "shouldCollapsePriority")
        }
        set {
            guard newValue != shouldCollapsePriority else { return }
            if newValue { originalPriority = base.priority }
            setPropertyBool(newValue, forName: "shouldCollapsePriority")
        }
    }

    /// 自动布局是否收缩，启用收缩后生效，默认NO为原始值，YES时为收缩值
    public var isCollapsed: Bool {
        get {
            propertyBool(forName: "isCollapsed")
        }
        set {
            if shouldCollapseActive {
                base.isActive = newValue ? !originalActive : originalActive
            }
            if shouldCollapsePriority {
                base.priority = newValue ? collapsePriority : originalPriority
            }
            if shouldCollapseOffset {
                offset = newValue ? collapseOffset : originalOffset
            }

            setPropertyBool(newValue, forName: "isCollapsed")
        }
    }

    fileprivate var layoutIdentifier: String? {
        get { property(forName: "layoutIdentifier") as? String }
        set { setPropertyCopy(newValue, forName: "layoutIdentifier") }
    }

    /// 布局调试描述，参考：[Masonry](https://github.com/SnapKit/Masonry)
    fileprivate var layoutDescription: String {
        var description = "<"
        description += NSLayoutConstraint.fw.layoutDescription(base)
        if let firstItem = base.firstItem {
            description += String(format: " %@", NSLayoutConstraint.fw.layoutDescription(firstItem))
        }
        if base.firstAttribute != .notAnAttribute {
            description += String(format: ".%@", UIView.innerAttributeDescriptions[base.firstAttribute] ?? NSNumber(value: base.firstAttribute.rawValue))
        }
        description += String(format: " %@", UIView.innerRelationDescriptions[base.relation] ?? NSNumber(value: base.relation.rawValue))
        if let secondItem = base.secondItem {
            description += String(format: " %@", NSLayoutConstraint.fw.layoutDescription(secondItem))
        }
        if base.secondAttribute != .notAnAttribute {
            description += String(format: ".%@", UIView.innerAttributeDescriptions[base.secondAttribute] ?? NSNumber(value: base.secondAttribute.rawValue))
        }
        if base.multiplier != 1 {
            description += String(format: " * %g", base.multiplier)
        }
        if base.secondAttribute == .notAnAttribute {
            description += String(format: " %g", base.constant)
        } else {
            if base.constant != 0 {
                description += String(format: " %@ %g", base.constant < 0 ? "-" : "+", abs(base.constant))
            }
        }
        if base.priority != .required {
            description += String(format: " ^%@", UIView.innerPriorityDescriptions[base.priority] ?? NSNumber(value: base.priority.rawValue))
        }
        description += ">"
        return description
    }

    private static func layoutDescription(_ object: AnyObject) -> String {
        var objectDesc = ""
        if let constraint = object as? NSLayoutConstraint, let identifier = constraint.identifier {
            objectDesc = identifier
        } else if let view = object as? UIView, let layoutKey = view.fw.layoutKey {
            objectDesc = layoutKey
        } else if let guide = object as? UILayoutGuide, let layoutKey = guide.owningView?.fw.layoutKey {
            objectDesc = layoutKey
        }
        return String(format: "%@:%p%@", String(describing: type(of: object)), object as! CVarArg, !objectDesc.isEmpty ? " '\(objectDesc)'" : objectDesc)
    }
}

// MARK: - Wrapper+UIView
@MainActor extension Wrapper where Base: UIView {
    /// 链式布局对象
    public var layoutChain: LayoutChain {
        if let layoutChain = property(forName: "layoutChain") as? LayoutChain {
            return layoutChain
        }

        let layoutChain = LayoutChain(view: base)
        setProperty(layoutChain, forName: "layoutChain")
        return layoutChain
    }

    /// 链式布局闭包
    public func layoutMaker(_ closure: (_ make: LayoutChain) -> Void) {
        closure(layoutChain)
    }
}

// MARK: - Wrapper+Array<UIView>
@MainActor extension Wrapper where Base == [UIView] {
    /// 批量链式布局闭包
    public func layoutMaker(_ closure: (_ make: LayoutChain) -> Void) {
        for view in base {
            closure(view.fw.layoutChain)
        }
    }

    /// 批量对齐布局，适用于间距固定场景，尺寸未设置(可手工指定)，若只有一个则间距不生效
    public func layoutAlong(
        _ axis: NSLayoutConstraint.Axis,
        itemSpacing: CGFloat,
        leadSpacing: CGFloat? = nil,
        tailSpacing: CGFloat? = nil,
        itemLength: CGFloat? = nil,
        equalLength: Bool = false,
        autoScale: Bool? = nil
    ) {
        guard base.count > 0 else { return }

        if axis == .horizontal {
            var prev: UIView?
            for (index, view) in base.enumerated() {
                if let prev {
                    view.fw.pinEdge(.left, toEdge: .right, ofView: prev, offset: itemSpacing, autoScale: autoScale)
                    if let itemLength {
                        view.fw.setDimension(.width, size: itemLength, autoScale: autoScale)
                    } else if equalLength {
                        view.fw.matchDimension(.width, toDimension: .width, ofView: prev, autoScale: autoScale)
                    }
                } else {
                    if let leadSpacing {
                        view.fw.pinEdge(toSuperview: .left, inset: leadSpacing, autoScale: autoScale)
                    }
                    if let itemLength {
                        view.fw.setDimension(.width, size: itemLength, autoScale: autoScale)
                    }
                }
                if index == base.count - 1, let tailSpacing {
                    view.fw.pinEdge(toSuperview: .right, inset: tailSpacing, autoScale: autoScale)
                }
                prev = view
            }
        } else {
            var prev: UIView?
            for (index, view) in base.enumerated() {
                if let prev {
                    view.fw.pinEdge(.top, toEdge: .bottom, ofView: prev, offset: itemSpacing, autoScale: autoScale)
                    if let itemLength {
                        view.fw.setDimension(.height, size: itemLength, autoScale: autoScale)
                    } else if equalLength {
                        view.fw.matchDimension(.height, toDimension: .height, ofView: prev, autoScale: autoScale)
                    }
                } else {
                    if let leadSpacing {
                        view.fw.pinEdge(toSuperview: .top, inset: leadSpacing, autoScale: autoScale)
                    }
                    if let itemLength {
                        view.fw.setDimension(.height, size: itemLength, autoScale: autoScale)
                    }
                }
                if index == base.count - 1, let tailSpacing {
                    view.fw.pinEdge(toSuperview: .bottom, inset: tailSpacing, autoScale: autoScale)
                }
                prev = view
            }
        }
    }

    /// 批量对齐布局，适用于尺寸固定场景，间距自适应，若只有一个则尺寸不生效
    public func layoutAlong(
        _ axis: NSLayoutConstraint.Axis,
        itemLength: CGFloat,
        leadSpacing: CGFloat,
        tailSpacing: CGFloat,
        autoScale: Bool? = nil
    ) {
        guard base.count > 0 else { return }

        if axis == .horizontal {
            var prev: UIView?
            for (index, view) in base.enumerated() {
                if base.count > 1 {
                    view.fw.setDimension(.width, size: itemLength, autoScale: autoScale)
                }
                if prev != nil {
                    if index < base.count - 1 {
                        let offset = (CGFloat(1) - (CGFloat(index) / CGFloat(base.count - 1))) *
                            (itemLength + leadSpacing) -
                            CGFloat(index) * tailSpacing / CGFloat(base.count - 1)
                        view.fw.constrainAttribute(.right, toAttribute: .right, ofView: view.superview, multiplier: CGFloat(index) / CGFloat(base.count - 1), offset: offset, autoScale: autoScale)
                    }
                } else {
                    view.fw.pinEdge(toSuperview: .left, inset: leadSpacing, autoScale: autoScale)
                }
                if index == base.count - 1 {
                    view.fw.pinEdge(toSuperview: .right, inset: tailSpacing, autoScale: autoScale)
                }
                prev = view
            }
        } else {
            var prev: UIView?
            for (index, view) in base.enumerated() {
                if base.count > 1 {
                    view.fw.setDimension(.height, size: itemLength, autoScale: autoScale)
                }
                if prev != nil {
                    if index < base.count - 1 {
                        let offset = (CGFloat(1) - (CGFloat(index) / CGFloat(base.count - 1))) *
                            (itemLength + leadSpacing) -
                            CGFloat(index) * tailSpacing / CGFloat(base.count - 1)
                        view.fw.constrainAttribute(.bottom, toAttribute: .bottom, ofView: view.superview, multiplier: CGFloat(index) / CGFloat(base.count - 1), offset: offset, autoScale: autoScale)
                    }
                } else {
                    view.fw.pinEdge(toSuperview: .top, inset: leadSpacing, autoScale: autoScale)
                }
                if index == base.count - 1 {
                    view.fw.pinEdge(toSuperview: .bottom, inset: tailSpacing, autoScale: autoScale)
                }
                prev = view
            }
        }
    }

    /// 批量对齐布局，用于补齐Along之后该方向上的其他约束
    public func layoutAlong(
        _ axis: NSLayoutConstraint.Axis,
        alignCenter: Bool = false,
        itemWidth: CGFloat? = nil,
        leftSpacing: CGFloat? = nil,
        rightSpacing: CGFloat? = nil,
        autoScale: Bool? = nil
    ) {
        guard base.count > 0 else { return }

        if axis == .horizontal {
            for view in base {
                if alignCenter {
                    view.fw.alignAxis(toSuperview: .centerY, autoScale: autoScale)
                }
                if let itemWidth {
                    view.fw.setDimension(.height, size: itemWidth, autoScale: autoScale)
                }
                if let leftSpacing {
                    view.fw.pinEdge(toSuperview: .bottom, inset: leftSpacing, autoScale: autoScale)
                }
                if let rightSpacing {
                    view.fw.pinEdge(toSuperview: .top, inset: rightSpacing, autoScale: autoScale)
                }
            }
        } else {
            for view in base {
                if alignCenter {
                    view.fw.alignAxis(toSuperview: .centerX, autoScale: autoScale)
                }
                if let itemWidth {
                    view.fw.setDimension(.width, size: itemWidth, autoScale: autoScale)
                }
                if let leftSpacing {
                    view.fw.pinEdge(toSuperview: .left, inset: leftSpacing, autoScale: autoScale)
                }
                if let rightSpacing {
                    view.fw.pinEdge(toSuperview: .right, inset: rightSpacing, autoScale: autoScale)
                }
            }
        }
    }
}

// MARK: - UILayoutPriority+Shortcut
extension UILayoutPriority {
    /// 中优先级，500
    public static let defaultMedium: UILayoutPriority = .init(500)
}

// MARK: - UIView+Shortcut
extension UIView {
    /// 链式布局对象
    public var layoutChain: LayoutChain { fw.layoutChain }

    /// 链式布局闭包
    @discardableResult
    public func layoutMaker(_ closure: (_ make: LayoutChain) -> Void) -> Self {
        fw.layoutMaker(closure)
        return self
    }
}

// MARK: - UIView+AutoLayout
extension UIView {
    fileprivate static var innerAutoLayoutRTL = false
    fileprivate static var innerAutoScaleBlock: (@MainActor @Sendable (CGFloat) -> CGFloat)?
    fileprivate static var innerAutoFlatLayout = false

    fileprivate nonisolated(unsafe) static var innerAutoLayoutDebug: Bool = {
        #if DEBUG
        true
        #else
        false
        #endif
    }()

    fileprivate static var innerRelationDescriptions: [NSLayoutConstraint.Relation: String] = [
        .equal: "==",
        .greaterThanOrEqual: ">=",
        .lessThanOrEqual: "<="
    ]

    fileprivate static var innerAttributeDescriptions: [NSLayoutConstraint.Attribute: String] = [
        .top: "top",
        .left: "left",
        .bottom: "bottom",
        .right: "right",
        .leading: "leading",
        .trailing: "trailing",
        .width: "width",
        .height: "height",
        .centerX: "centerX",
        .centerY: "centerY",
        .firstBaseline: "firstBaseline",
        .lastBaseline: "lastBaseline",
        .leftMargin: "leftMargin",
        .rightMargin: "rightMargin",
        .topMargin: "topMargin",
        .bottomMargin: "bottomMargin",
        .leadingMargin: "leadingMargin",
        .trailingMargin: "trailingMargin",
        .centerXWithinMargins: "centerXWithinMargins",
        .centerYWithinMargins: "centerYWithinMargins",
        .notAnAttribute: "notAnAttribute"
    ]

    fileprivate static var innerPriorityDescriptions: [UILayoutPriority: String] = [
        .required: "required",
        .defaultHigh: "defaultHigh",
        .defaultLow: "defaultLow",
        .dragThatCanResizeScene: "dragThatCanResizeScene",
        .dragThatCannotResizeScene: "dragThatCannotResizeScene",
        .sceneSizeStayPut: "sceneSizeStayPut",
        .fittingSizeLevel: "fittingSizeLevel"
    ]
}

// MARK: - LayoutChain
/// 视图链式布局类。如果约束条件完全相同，会自动更新约束而不是重新添加。
/// 另外，默认布局方式使用LTR，如果需要RTL布局，可通过autoLayoutRTL统一启用
@MainActor public class LayoutChain {
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
        view?.fw.removeAllConstraints()
        return self
    }

    @discardableResult
    public func autoScale(_ autoScale: Bool) -> Self {
        view?.fw.autoScaleLayout = autoScale
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
    public func isCollapsed(_ isCollapsed: Bool) -> Self {
        view?.fw.isCollapsed = isCollapsed
        return self
    }

    @discardableResult
    public func autoCollapse(_ autoCollapse: Bool) -> Self {
        view?.fw.autoCollapse = autoCollapse
        return self
    }

    @discardableResult
    public func autoMatchDimension(_ matchDimension: Bool) -> Self {
        view?.fw.autoMatchDimension = matchDimension
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
        var constraints: [NSLayoutConstraint] = []
        if let constraint = self.view?.fw.alignAxis(.centerX, toView: view) {
            constraints.append(constraint)
        }
        if let constraint = self.view?.fw.alignAxis(.centerY, toView: view) {
            constraints.append(constraint)
        }
        self.view?.fw.lastConstraints = constraints
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
    public func top(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw.pinEdge(toSuperview: .top, inset: inset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func bottom(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw.pinEdge(toSuperview: .bottom, inset: inset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func left(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw.pinEdge(toSuperview: .left, inset: inset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func right(_ inset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw.pinEdge(toSuperview: .right, inset: inset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func top(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw.pinEdge(.top, toEdge: .top, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func bottom(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw.pinEdge(.bottom, toEdge: .bottom, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func left(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw.pinEdge(.left, toEdge: .left, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func right(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw.pinEdge(.right, toEdge: .right, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func horizontal(toView view: Any) -> Self {
        var constraints: [NSLayoutConstraint] = []
        if let constraint = self.view?.fw.pinEdge(.left, toEdge: .left, ofView: view) {
            constraints.append(constraint)
        }
        if let constraint = self.view?.fw.pinEdge(.right, toEdge: .right, ofView: view) {
            constraints.append(constraint)
        }
        self.view?.fw.lastConstraints = constraints
        return self
    }

    @discardableResult
    public func vertical(toView view: Any) -> Self {
        var constraints: [NSLayoutConstraint] = []
        if let constraint = self.view?.fw.pinEdge(.top, toEdge: .top, ofView: view) {
            constraints.append(constraint)
        }
        if let constraint = self.view?.fw.pinEdge(.bottom, toEdge: .bottom, ofView: view) {
            constraints.append(constraint)
        }
        self.view?.fw.lastConstraints = constraints
        return self
    }

    @discardableResult
    public func top(toViewBottom view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw.pinEdge(.top, toEdge: .bottom, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func bottom(toViewTop view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw.pinEdge(.bottom, toEdge: .top, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func left(toViewRight view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw.pinEdge(.left, toEdge: .right, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func right(toViewLeft view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
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
    public func top(toSafeArea inset: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw.pinEdge(toSafeArea: .top, inset: inset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func bottom(toSafeArea inset: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw.pinEdge(toSafeArea: .bottom, inset: inset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func left(toSafeArea inset: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw.pinEdge(toSafeArea: .left, inset: inset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func right(toSafeArea inset: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
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
    public func size(width: CGFloat, height: CGFloat) -> Self {
        view?.fw.setDimensions(CGSize(width: width, height: height))
        return self
    }

    @discardableResult
    public func width(_ width: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw.setDimension(.width, size: width, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func height(_ height: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw.setDimension(.height, size: height, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func width(toHeight multiplier: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw.matchDimension(.width, toDimension: .height, multiplier: multiplier, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func height(toWidth multiplier: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        view?.fw.matchDimension(.height, toDimension: .width, multiplier: multiplier, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func size(toView view: Any) -> Self {
        var constraints: [NSLayoutConstraint] = []
        if let constraint = self.view?.fw.matchDimension(.width, toDimension: .width, ofView: view) {
            constraints.append(constraint)
        }
        if let constraint = self.view?.fw.matchDimension(.height, toDimension: .height, ofView: view) {
            constraints.append(constraint)
        }
        self.view?.fw.lastConstraints = constraints
        return self
    }

    @discardableResult
    public func width(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw.matchDimension(.width, toDimension: .width, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func height(toView view: Any, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw.matchDimension(.height, toDimension: .height, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func width(toView view: Any, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw.matchDimension(.width, toDimension: .width, ofView: view, multiplier: multiplier, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func height(toView view: Any, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw.matchDimension(.height, toDimension: .height, ofView: view, multiplier: multiplier, relation: relation, priority: priority)
        return self
    }

    // MARK: - Attribute
    @discardableResult
    public func attribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, offset: CGFloat = 0, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw.constrainAttribute(attribute, toAttribute: toAttribute, ofView: view, offset: offset, relation: relation, priority: priority)
        return self
    }

    @discardableResult
    public func attribute(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, multiplier: CGFloat, offset: CGFloat = .zero, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> Self {
        self.view?.fw.constrainAttribute(attribute, toAttribute: toAttribute, ofView: view, multiplier: multiplier, offset: offset, relation: relation, priority: priority)
        return self
    }

    // MARK: - Subviews
    @discardableResult
    public func subviews(_ closure: (_ make: LayoutChain) -> Void) -> Self {
        view?.subviews.fw.layoutMaker(closure)
        return self
    }

    @discardableResult
    public func subviews(along axis: NSLayoutConstraint.Axis, itemSpacing: CGFloat, leadSpacing: CGFloat? = nil, tailSpacing: CGFloat? = nil, itemLength: CGFloat? = nil, equalLength: Bool = false) -> Self {
        view?.subviews.fw.layoutAlong(axis, itemSpacing: itemSpacing, leadSpacing: leadSpacing, tailSpacing: tailSpacing, itemLength: itemLength, equalLength: equalLength)
        return self
    }

    @discardableResult
    public func subviews(along axis: NSLayoutConstraint.Axis, itemLength: CGFloat, leadSpacing: CGFloat, tailSpacing: CGFloat) -> Self {
        view?.subviews.fw.layoutAlong(axis, itemLength: itemLength, leadSpacing: leadSpacing, tailSpacing: tailSpacing)
        return self
    }

    @discardableResult
    public func subviews(along axis: NSLayoutConstraint.Axis, alignCenter: Bool = false, itemWidth: CGFloat? = nil, leftSpacing: CGFloat? = nil, rightSpacing: CGFloat? = nil) -> Self {
        view?.subviews.fw.layoutAlong(axis, alignCenter: alignCenter, itemWidth: itemWidth, leftSpacing: leftSpacing, rightSpacing: rightSpacing)
        return self
    }

    // MARK: - Offset
    @discardableResult
    public func relative() -> Self {
        view?.fw.lastConstraints.forEach { obj in
            obj.fw.autoScaleLayout = true
        }
        return self
    }

    @discardableResult
    public func fixed() -> Self {
        view?.fw.lastConstraints.forEach { obj in
            obj.fw.autoScaleLayout = false
        }
        return self
    }

    @discardableResult
    public func offset(_ offset: CGFloat) -> Self {
        view?.fw.lastConstraints.forEach { obj in
            obj.fw.offset = offset
        }
        return self
    }

    @discardableResult
    public func constant(_ constant: CGFloat) -> Self {
        view?.fw.lastConstraints.forEach { obj in
            obj.constant = constant
        }
        return self
    }

    @discardableResult
    public func priority(_ priority: UILayoutPriority) -> Self {
        view?.fw.lastConstraints.forEach { obj in
            obj.priority = priority
        }
        return self
    }

    @discardableResult
    public func collapse(_ offset: CGFloat? = nil) -> Self {
        view?.fw.lastConstraints.forEach { obj in
            self.view?.fw.addCollapseConstraint(obj, offset: offset)
        }
        return self
    }

    @discardableResult
    public func original(_ offset: CGFloat) -> Self {
        view?.fw.lastConstraints.forEach { obj in
            obj.fw.originalOffset = offset
        }
        return self
    }

    @discardableResult
    public func collapseActive(_ active: Bool? = nil) -> Self {
        view?.fw.lastConstraints.forEach { obj in
            self.view?.fw.addCollapseActiveConstraint(obj, active: active)
        }
        return self
    }

    @discardableResult
    public func collapsePriority(_ priority: UILayoutPriority? = nil) -> Self {
        view?.fw.lastConstraints.forEach { obj in
            self.view?.fw.addCollapsePriorityConstraint(obj, priority: priority)
        }
        return self
    }

    @discardableResult
    public func originalPriority(_ priority: UILayoutPriority) -> Self {
        view?.fw.lastConstraints.forEach { obj in
            obj.fw.originalPriority = priority
        }
        return self
    }

    @discardableResult
    public func identifier(_ identifier: String?) -> Self {
        view?.fw.lastConstraints.forEach { obj in
            obj.identifier = identifier
        }
        return self
    }

    @discardableResult
    public func active(_ active: Bool) -> Self {
        view?.fw.lastConstraints.forEach { obj in
            obj.isActive = active
        }
        return self
    }

    @discardableResult
    public func remove() -> Self {
        view?.fw.removeConstraints(view?.fw.lastConstraints)
        return self
    }

    // MARK: - Constraint
    public var constraints: [NSLayoutConstraint] {
        view?.fw.lastConstraints ?? []
    }

    public var constraint: NSLayoutConstraint? {
        view?.fw.lastConstraints.last
    }

    public func constraint(_ attribute: NSLayoutConstraint.Attribute, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> NSLayoutConstraint? {
        view?.fw.constraint(toSuperview: attribute, relation: relation)
    }

    public func constraint(toSafeArea attribute: NSLayoutConstraint.Attribute, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> NSLayoutConstraint? {
        view?.fw.constraint(toSafeArea: attribute, relation: relation)
    }

    public func constraint(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> NSLayoutConstraint? {
        self.view?.fw.constraint(attribute, toAttribute: toAttribute, ofView: view, relation: relation)
    }

    public func constraint(_ attribute: NSLayoutConstraint.Attribute, toAttribute: NSLayoutConstraint.Attribute, ofView view: Any?, multiplier: CGFloat, relation: NSLayoutConstraint.Relation = NSLayoutConstraint.Relation.equal) -> NSLayoutConstraint? {
        self.view?.fw.constraint(attribute, toAttribute: toAttribute, ofView: view, multiplier: multiplier, relation: relation)
    }

    public func constraint(identifier: String?) -> NSLayoutConstraint? {
        view?.fw.constraint(identifier: identifier)
    }

    // MARK: - Debug
    @discardableResult
    public func layoutKey(_ layoutKey: String?) -> Self {
        view?.fw.layoutKey = layoutKey
        return self
    }
}

// MARK: - FrameworkStorage+AutoLayout
extension FrameworkStorage {
    fileprivate static var swizzleAutoLayoutDebugFinished = false
}

// MARK: - FrameworkAutoloader+AutoLayout
extension FrameworkAutoloader {
    @objc static func loadToolkit_AutoLayout() {
        swizzleAutoLayoutView()

        if UIView.innerAutoLayoutDebug {
            swizzleAutoLayoutDebug()
        }
    }

    private static func swizzleAutoLayoutView() {
        NSObject.fw.swizzleInstanceMethod(
            UIView.self,
            selector: #selector(UIView.updateConstraints),
            methodSignature: (@convention(c) (UIView, Selector) -> Void).self,
            swizzleSignature: (@convention(block) @MainActor (UIView) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)

            if selfObject.fw.autoCollapse && selfObject.fw.collapseConstraints.count > 0 {
                let contentSize = selfObject.intrinsicContentSize
                if !contentSize.equalTo(CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)) && contentSize.width > 0 && contentSize.height > 0 {
                    selfObject.fw.isCollapsed = false
                } else {
                    selfObject.fw.isCollapsed = true
                }
            }

            if let constraint = selfObject.fw.matchDimensionConstraint {
                selfObject.fw.removeConstraints([constraint])
                selfObject.fw.matchDimensionConstraint = nil
            }
            if selfObject.fw.autoMatchDimension {
                let contentSize = selfObject.intrinsicContentSize
                if !contentSize.equalTo(CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)) && contentSize.width > 0 && contentSize.height > 0 {
                    selfObject.fw.matchDimensionConstraint = selfObject.fw.matchDimension(.width, toDimension: .height, multiplier: contentSize.width / contentSize.height, autoScale: false)
                }
            }
        }}

        NSObject.fw.swizzleInstanceMethod(
            UIView.self,
            selector: #selector(setter: UIView.isHidden),
            methodSignature: (@convention(c) (UIView, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) @MainActor (UIView, Bool) -> Void).self
        ) { store in { selfObject, hidden in
            store.original(selfObject, store.selector, hidden)

            if selfObject.fw.hiddenCollapse && selfObject.fw.collapseConstraints.count > 0 {
                selfObject.fw.isCollapsed = hidden
            }
        }}
    }

    fileprivate static func swizzleAutoLayoutDebug() {
        guard !FrameworkStorage.swizzleAutoLayoutDebugFinished else { return }
        FrameworkStorage.swizzleAutoLayoutDebugFinished = true

        NSObject.fw.swizzleInstanceMethod(
            NSLayoutConstraint.self,
            selector: #selector(NSLayoutConstraint.description),
            methodSignature: (@convention(c) (NSLayoutConstraint, Selector) -> String).self,
            swizzleSignature: (@convention(block) @MainActor (NSLayoutConstraint) -> String).self
        ) { store in { selfObject in
            guard UIView.innerAutoLayoutDebug else {
                return store.original(selfObject, store.selector)
            }

            return selfObject.fw.layoutDescription
        }}
    }
}
