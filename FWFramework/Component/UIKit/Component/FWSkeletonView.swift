//
//  FWSkeletonView.swift
//  FWFramework
//
//  Created by wuyong on 2020/7/29.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import UIKit

// MARK: - FWSkeletonAnimation

/// 骨架屏动画协议
@objc public protocol FWSkeletonAnimationProtocol {
    func skeletonAnimationStart(_ gradientLayer: CAGradientLayer)
    func skeletonAnimationStop(_ gradientLayer: CAGradientLayer)
}

/// 骨架屏自带动画类型
@objc public enum FWSkeletonAnimationType: Int {
    /// 闪光灯动画
    case shimmer
    /// 呼吸灯动画
    case solid
    /// 伸缩动画
    case scale
}

/// 骨架屏自带动画方向
@objc public enum FWSkeletonAnimationDirection: Int {
    case right
    case left
    case down
    case up
}

/// 骨架屏自带动画
@objcMembers open class FWSkeletonAnimation: NSObject,
                                             NSCopying, NSMutableCopying,
                                             FWSkeletonAnimationProtocol {
    public static let shimmer = FWSkeletonAnimation(type: .shimmer)
    public static let solid = FWSkeletonAnimation(type: .solid)
    public static let scale = FWSkeletonAnimation(type: .scale)
    
    open var fromValue: Any?
    open var toValue: Any?
    open var colors: [UIColor]?
    open var duration: TimeInterval = 1
    open var delay: TimeInterval = 0
    open var repeatCount: Float = .infinity
    open var direction: FWSkeletonAnimationDirection = .right
    
    private var type: FWSkeletonAnimationType = .shimmer
    
    // MARK: - Lifecycle
    
    public override init() {
        super.init()
        setupAnimation()
    }
    
    public init(type: FWSkeletonAnimationType) {
        super.init()
        self.type = type
        setupAnimation()
    }
    
    private func setupAnimation() {
        switch type {
        case .solid:
            fromValue = 1.1
            toValue = 0.6
        case .scale:
            duration = 0.7
            fromValue = 0.6
            toValue = 1
        default:
            let lightColor = UIColor.fwColor(withHex: 0xEEEEEE)
            let lightBrightness: CGFloat = 0.92
            let darkColor = UIColor.fwColor(withHex: 0x282828)
            let darkBrightness: CGFloat = 0.5
            colors = [
                UIColor.fwThemeLight(lightColor, dark: darkColor),
                UIColor.fwThemeLight(lightColor.fwBrightnessColor(lightBrightness), dark: darkColor.fwBrightnessColor(darkBrightness)),
                UIColor.fwThemeLight(lightColor, dark: darkColor)
            ]
        }
    }
    
    // MARK: - NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let animation = FWSkeletonAnimation(type: type)
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.colors = colors
        animation.duration = duration
        animation.delay = delay
        animation.repeatCount = repeatCount
        animation.direction = direction
        return animation
    }
    
    public func mutableCopy(with zone: NSZone? = nil) -> Any {
        let animation = FWSkeletonAnimation(type: type)
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.colors = colors
        animation.duration = duration
        animation.delay = delay
        animation.repeatCount = repeatCount
        animation.direction = direction
        return animation
    }
    
    // MARK: - FWSkeletonAnimationProtocol
    
    open func skeletonAnimationStart(_ gradientLayer: CAGradientLayer) {
        var animation: CAAnimation
        switch type {
        case .solid:
            let basicAnimation = CABasicAnimation(keyPath: "opacity")
            basicAnimation.fromValue = fromValue
            basicAnimation.toValue = toValue
            basicAnimation.autoreverses = true
            basicAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)
            animation = basicAnimation
        case .scale:
            let basicAnimation = CABasicAnimation()
            switch direction {
            case .right:
                basicAnimation.keyPath = "transform.scale.x"
                gradientLayer.anchorPoint = CGPoint(x: 0, y: 0.5)
                gradientLayer.position.x -= gradientLayer.bounds.size.width / 2.0
            case .left:
                basicAnimation.keyPath = "transform.scale.x"
                gradientLayer.anchorPoint = CGPoint(x: 1, y: 0.5)
                gradientLayer.position.x += gradientLayer.bounds.size.width / 2.0
            case .down:
                basicAnimation.keyPath = "transform.scale.y"
                gradientLayer.anchorPoint = CGPoint(x: 0.5, y: 0)
                gradientLayer.position.y -= gradientLayer.bounds.size.height / 2.0
            case .up:
                basicAnimation.keyPath = "transform.scale.y"
                gradientLayer.anchorPoint = CGPoint(x: 0.5, y: 1)
                gradientLayer.position.y += gradientLayer.bounds.size.height / 2.0
            }
            
            basicAnimation.fromValue = fromValue
            basicAnimation.toValue = toValue
            basicAnimation.autoreverses = true
            basicAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animation = basicAnimation
        default:
            let startAnimation = CABasicAnimation(keyPath: "startPoint")
            let endAnimation = CABasicAnimation(keyPath: "endPoint")
            gradientLayer.fwThemeColors = colors
            switch direction {
            case .right:
                startAnimation.fromValue = NSValue(cgPoint: CGPoint(x:-1, y:0.5))
                startAnimation.toValue = NSValue(cgPoint: CGPoint(x:1, y:0.5))
                endAnimation.fromValue = NSValue(cgPoint: CGPoint(x:0, y:0.5))
                endAnimation.toValue = NSValue(cgPoint: CGPoint(x:2, y:0.5))
            case .left:
                startAnimation.fromValue = NSValue(cgPoint: CGPoint(x:1, y:0.5))
                startAnimation.toValue = NSValue(cgPoint: CGPoint(x:-1, y:0.5))
                endAnimation.fromValue = NSValue(cgPoint: CGPoint(x:2, y:0.5))
                endAnimation.toValue = NSValue(cgPoint: CGPoint(x:0, y:0.5))
            case .down:
                startAnimation.fromValue = NSValue(cgPoint: CGPoint(x:0.5, y:-1))
                startAnimation.toValue = NSValue(cgPoint: CGPoint(x:0.5, y:1))
                endAnimation.fromValue = NSValue(cgPoint: CGPoint(x:0.5, y:0))
                endAnimation.toValue = NSValue(cgPoint: CGPoint(x:0.5, y:2))
            case .up:
                startAnimation.fromValue = NSValue(cgPoint: CGPoint(x:0.5, y:1))
                startAnimation.toValue = NSValue(cgPoint: CGPoint(x:0.5, y:-1))
                endAnimation.fromValue = NSValue(cgPoint: CGPoint(x:0.5, y:2))
                endAnimation.toValue = NSValue(cgPoint: CGPoint(x:0.5, y:0))
            }
            
            let animationGroup = CAAnimationGroup()
            animationGroup.animations = [startAnimation, endAnimation]
            animationGroup.timingFunction = CAMediaTimingFunction(name: .easeIn)
            animation = animationGroup
        }
        
        animation.repeatCount = repeatCount
        animation.beginTime = delay > 0 ? CACurrentMediaTime() + delay : 0
        animation.duration = duration
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        gradientLayer.add(animation, forKey: "skeletonAnimation")
    }
    
    open func skeletonAnimationStop(_ gradientLayer: CAGradientLayer) {
        gradientLayer.removeAnimation(forKey: "skeletonAnimation")
    }
}

// MARK: - FWSkeletonAppearance

/// 骨架屏通用样式
@objcMembers public class FWSkeletonAppearance: NSObject {
    /// 单例对象
    public static let appearance = FWSkeletonAppearance()
    
    /// 骨架动画，默认nil
    public var animation: FWSkeletonAnimationProtocol?
    
    /// 骨架背景色，默认自动适配
    public var backgroundColor: UIColor = UIColor.fwThemeLight(UIColor.white, dark: UIColor.black)
    /// 骨架颜色，默认自动适配
    public var skeletonColor: UIColor = UIColor.fwThemeLight(UIColor.fwColor(withHex: 0xEEEEEE), dark: UIColor.fwColor(withHex: 0x282828))
    
    /// 多行标签行高，默认15
    public var lineHeight: CGFloat = 15
    /// 多行标签固定间距，默认10
    public var lineSpacing: CGFloat = 10
    /// 多行标签最后一行百分比，默认0.7
    public var lastLinePercent: CGFloat = 0.7
    /// 多行标签圆角，默认0
    public var lineCornerRadius: CGFloat = 0
}

// MARK: - FWSkeletonView

/// 骨架屏视图数据源协议
@objc public protocol FWSkeletonViewDataSource {
    /// 骨架屏视图创建方法
    func skeletonViewProvider() -> FWSkeletonView?
}

/// 骨架屏视图代理协议
@objc public protocol FWSkeletonViewDelegate {
    /// 骨架屏视图布局方法
    func skeletonViewLayout(_ layout: FWSkeletonLayout)
}

/// 骨架屏视图，支持设置占位图片
@objcMembers open class FWSkeletonView: UIView {
    /// 自定义动画，默认通用样式
    open var animation: FWSkeletonAnimationProtocol? = FWSkeletonAppearance.appearance.animation
    
    /// 动画层列表，子类可覆写
    open var animationLayers: [CAGradientLayer] = []
    
    /// 骨架图片，默认空
    open var image: UIImage? {
        didSet {
            layer.fwThemeContents = image
            layer.contentsGravity = .resizeAspectFill
        }
    }
    
    open override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        animationLayers.append(layer as! CAGradientLayer)
        backgroundColor = FWSkeletonAppearance.appearance.skeletonColor
    }
    
    /// 解析视图样式
    open func parseView(_ view: UIView) {
        layer.masksToBounds = view.layer.masksToBounds
        layer.cornerRadius = view.layer.cornerRadius
        if view.layer.shadowOpacity > 0 {
            layer.shadowColor = view.layer.shadowColor
            layer.shadowOffset = view.layer.shadowOffset
            layer.shadowRadius = view.layer.shadowRadius
            layer.shadowPath = view.layer.shadowPath
            layer.shadowOpacity = view.layer.shadowOpacity
        }
    }
    
    /// 开始动画
    open func startAnimating() {
        animationLayers.forEach { (gradientLayer) in
            gradientLayer.fwThemeContext = self
            animation?.skeletonAnimationStart(gradientLayer)
        }
    }
    
    /// 停止动画
    open func stopAnimating() {
        animationLayers.forEach { (gradientLayer) in
            animation?.skeletonAnimationStop(gradientLayer)
        }
    }
}

// MARK: - FWSkeletonLabel

/// 骨架屏多行标签视图，可显示多行骨架
@objcMembers open class FWSkeletonLabel: FWSkeletonView {
    /// 行数，默认0
    open var numberOfLines: Int = 0
    /// 行高，默认15
    open var lineHeight: CGFloat = FWSkeletonAppearance.appearance.lineHeight
    /// 行圆角，默认0
    open var lineCornerRadius: CGFloat = FWSkeletonAppearance.appearance.lineCornerRadius
    /// 行固定间距，默认10
    open var lineSpacing: CGFloat = FWSkeletonAppearance.appearance.lineSpacing
    /// 最后一行显示百分比，默认0.7
    open var lastLinePercent: CGFloat = FWSkeletonAppearance.appearance.lastLinePercent
    /// 行颜色，默认骨架颜色
    open var lineColor: UIColor = FWSkeletonAppearance.appearance.skeletonColor
    /// 内容边距，默认zero
    open var contentInsets: UIEdgeInsets = .zero
    
    override func setupView() {
        backgroundColor = UIColor.clear
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        animationLayers.removeAll()
        
        let layerHeight = lineHeight
        let layerSpacing = lineSpacing
        var layerCount = numberOfLines
        if numberOfLines != 1 {
            layerCount = Int(round((bounds.height + layerSpacing - contentInsets.top - contentInsets.bottom) / (layerHeight + layerSpacing)))
            if numberOfLines != 0, numberOfLines <= layerCount {
                layerCount = numberOfLines
            }
        }
        
        for layerIndex in 0 ..< layerCount {
            let lineLayer = CAGradientLayer()
            lineLayer.backgroundColor = lineColor.cgColor
            var layerWidth = bounds.width - contentInsets.left - contentInsets.right
            if layerCount > 1 && layerIndex == (layerCount - 1) {
                layerWidth = layerWidth * lastLinePercent
            }
            if lineCornerRadius > 0 {
                lineLayer.cornerRadius = lineCornerRadius
            }
            lineLayer.frame = CGRect(
                x: contentInsets.left,
                y: contentInsets.top + CGFloat(layerIndex) * (layerHeight + layerSpacing),
                width: layerWidth,
                height: layerHeight
            )
            layer.addSublayer(lineLayer)
            animationLayers.append(lineLayer)
        }
    }
}

// MARK: - FWSkeletonLayout

/// 骨架屏布局视图，可从视图生成骨架屏，嵌套到UIScrollView即可实现滚动
@objcMembers open class FWSkeletonLayout: FWSkeletonView {
    /// 相对布局视图
    open weak var layoutView: UIView? {
        didSet {
            if let view = layoutView {
                frame = view.bounds
                parseView(view)
            }
        }
    }
    
    /// 指定相对布局视图初始化
    public init(layoutView: UIView?) {
        super.init(frame: .zero)
        self.layoutView = layoutView
        
        if let view = layoutView {
            frame = view.bounds
            parseView(view)
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupView() {
        backgroundColor = FWSkeletonAppearance.appearance.backgroundColor
    }
    
    /// 设置相对滚动视图，实现跟随下拉刷新等效果。block参数为contentOffset.y(不大于0)，默认设置顶部布局跟随滚动
    open func setScrollView(_ scrollView: UIScrollView, scrollBlock: ((CGFloat) -> ())? = nil) {
        var block = scrollBlock
        if block == nil && superview != nil {
            let constraint = fwConstraint(toSuperview: .top)
            let constant = constraint?.constant ?? 0
            block = { (offsetY) in
                constraint?.constant = constant - offsetY
            }
        }
        
        if scrollView.contentOffset.y <= 0 && superview != nil {
            block?(scrollView.contentOffset.y)
        }
        scrollView.fwObserveProperty("contentOffset") { [weak self] (_, _) in
            if scrollView.contentOffset.y <= 0 && self?.superview != nil {
                block?(scrollView.contentOffset.y)
            }
        }
    }
    
    // MARK: - Animation
    
    private var animationViews: [FWSkeletonView] = []
    
    /// 添加动画视图，不会调用addSubview
    open func addAnimationViews(_ animationViews: [FWSkeletonView]) {
        for animationView in animationViews {
            addAnimationView(animationView)
        }
    }
    
    /// 添加动画视图，不会调用addSubview
    open func addAnimationView(_ animationView: FWSkeletonView) {
        if !animationViews.contains(animationView) {
            animationViews.append(animationView)
        }
    }
    
    /// 移除动画视图，不会调用removeFromSuperview
    open func removeAnimationView(_ animationView: FWSkeletonView) {
        animationViews.removeAll { (skeletonView) -> Bool in
            return skeletonView == animationView
        }
    }
    
    /// 批量开始动画
    open override func startAnimating() {
        animationViews.forEach { (animationView) in
            animationView.startAnimating()
        }
    }
    
    /// 批量停止动画
    open override func stopAnimating() {
        animationViews.forEach { (animationView) in
            animationView.stopAnimating()
        }
        animationViews.removeAll()
    }
    
    // MARK: - Skeleton
    
    /// 批量添加子视图(兼容骨架视图)，返回生成的骨架视图数组
    @discardableResult
    open func addSkeletonViews(_ views: [UIView]) -> [FWSkeletonView] {
        return addSkeletonViews(views, block: nil)
    }
    
    /// 批量添加子视图(兼容骨架视图)，支持自定义骨架，返回生成的骨架视图数组
    @discardableResult
    open func addSkeletonViews(_ views: [UIView], block: ((FWSkeletonView, Int) -> Void)?) -> [FWSkeletonView] {
        var resultViews: [FWSkeletonView] = []
        for (index, view) in views.enumerated() {
            resultViews.append(addSkeletonView(view, block: { (skeletonView) in
                block?(skeletonView, index)
            }))
        }
        return resultViews
    }
    
    /// 添加单个子视图(兼容骨架视图)，返回生成的骨架视图
    @discardableResult
    open func addSkeletonView(_ view: UIView) -> FWSkeletonView {
        return addSkeletonView(view, block: nil)
    }
    
    /// 添加单个子视图(兼容骨架视图)，支持自定义骨架，返回生成的骨架视图
    @discardableResult
    open func addSkeletonView(_ view: UIView, block: ((FWSkeletonView) -> Void)?) -> FWSkeletonView {
        let skeletonView = FWSkeletonLayout.parseSkeletonView(view)
        return addSkeletonView(view, skeletonView: skeletonView, block: block)
    }
    
    /// 添加骨架视图，内部方法
    private func addSkeletonView<T: FWSkeletonView>(_ view: UIView, skeletonView: T, block: ((T) -> Void)?) -> T {
        if layoutView != nil && view.isDescendant(of: layoutView!) {
            skeletonView.frame = view.convert(view.bounds, to: layoutView!)
        }
        if skeletonView.superview == nil {
            addSubview(skeletonView)
        }
        addAnimationView(skeletonView)
        block?(skeletonView)
        return skeletonView
    }
    
    /// 添加单个布局视图(兼容骨架视图)，返回生成的骨架布局
    @discardableResult
    open func addSkeletonLayout(_ view: UIView) -> FWSkeletonLayout {
        return addSkeletonLayout(view, block: nil)
    }
    
    /// 添加单个布局视图(兼容骨架视图)，支持自定义骨架，返回生成的骨架布局
    @discardableResult
    open func addSkeletonLayout(_ view: UIView, block: ((FWSkeletonLayout) -> Void)?) -> FWSkeletonLayout {
        let skeletonView = FWSkeletonLayout.parseSkeletonLayout(view)
        return addSkeletonView(view, skeletonView: skeletonView, block: block)
    }
    
    // MARK: - Parser
    
    /// 解析视图为骨架视图
    open class func parseSkeletonView(_ view: UIView) -> FWSkeletonView {
        if view is FWSkeletonView {
            return view as! FWSkeletonView
        }
        
        if let skeletonDataSource = view as? FWSkeletonViewDataSource {
            if let skeletonView = skeletonDataSource.skeletonViewProvider() {
                return skeletonView
            }
        }
        
        if let skeletonDelegate = view as? FWSkeletonViewDelegate {
            let skeletonLayout = FWSkeletonLayout(layoutView: view)
            skeletonDelegate.skeletonViewLayout(skeletonLayout)
            return skeletonLayout
        }
        
        let skeletonView = FWSkeletonView()
        skeletonView.parseView(view)
        return skeletonView
    }
    
    /// 解析布局视图为骨架布局
    open class func parseSkeletonLayout(_ view: UIView) -> FWSkeletonLayout {
        if view is FWSkeletonLayout {
            return view as! FWSkeletonLayout
        }
        
        let skeletonLayout = FWSkeletonLayout(layoutView: view)
        if let skeletonDelegate = view as? FWSkeletonViewDelegate {
            skeletonDelegate.skeletonViewLayout(skeletonLayout)
            return skeletonLayout
        }
        
        skeletonLayout.addSkeletonViews(view.subviews)
        return skeletonLayout
    }
}

// MARK: - FWSkeletonTableView

/// 骨架屏表格视图，可生成表格骨架屏
@objcMembers open class FWSkeletonTableView: FWSkeletonLayout, UITableViewDataSource, UITableViewDelegate {
    /// 表格视图，默认不可滚动
    open lazy var tableView: UITableView = {
        let tableView = UITableView.fwTableView(style)
        tableView.frame = bounds
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        return tableView
    }()
    
    /// 表格视图代理，快速生成表格
    open lazy var tableDelegate: FWTableViewDelegate = {
        let tableDelegate = FWTableViewDelegate()
        return tableDelegate
    }()
    
    /// 表格头视图
    open var tableHeaderView: UIView? {
        didSet {
            guard let layoutHeader = tableHeaderView else { return }
            
            let skeletonLayout = FWSkeletonLayout.parseSkeletonLayout(layoutHeader)
            tableView.tableHeaderView = skeletonLayout
            addAnimationView(skeletonLayout)
        }
    }
    /// 表格尾视图
    open var tableFooterView: UIView? {
        didSet {
            guard let layoutFooter = tableFooterView else { return }
            
            let skeletonLayout = FWSkeletonLayout.parseSkeletonLayout(layoutFooter)
            tableView.tableFooterView = skeletonLayout
            addAnimationView(skeletonLayout)
        }
    }
    
    private var style: UITableView.Style = .plain
    
    public init(style: UITableView.Style) {
        self.style = style
        super.init(frame: .zero)
    }
    
    public override init(layoutView: UIView?) {
        super.init(layoutView: layoutView)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupView() {
        backgroundColor = FWSkeletonAppearance.appearance.backgroundColor
        tableView.backgroundColor = FWSkeletonAppearance.appearance.backgroundColor
        
        addSubview(tableView)
        tableView.fwPinEdgesToSuperview()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData()
    }
    
    // MARK: - UITableView
    
    open func numberOfSections(in tableView: UITableView) -> Int {
        let count = tableDelegate.numberOfSections(in: tableView)
        return count > 0 ? count : 1
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = tableDelegate.tableView(tableView, numberOfRowsInSection: section)
        if count > 0 { return count }
        
        let height = tableDelegate.tableView(tableView, heightForRowAt: IndexPath(row: 0, section: section))
        return height > 0 ? Int(ceil(UIScreen.main.bounds.size.height / height)) : 0
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let layoutCell = tableDelegate.tableView(tableView, cellForRowAt: indexPath)
        let cell = UITableViewCell.fwCell(with: tableView)
        cell.selectionStyle = .none
        if let skeletonLayout = cell.contentView.viewWithTag(2052) as? FWSkeletonLayout {
            skeletonLayout.removeFromSuperview()
            removeAnimationView(skeletonLayout)
        }
        
        if layoutCell.superview == nil {
            let height = tableDelegate.tableView(tableView, heightForRowAt: indexPath)
            layoutCell.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: height)
            layoutCell.setNeedsLayout()
            layoutCell.layoutIfNeeded()
        }
        
        let skeletonLayout = FWSkeletonLayout.parseSkeletonLayout(layoutCell)
        skeletonLayout.tag = 2052
        cell.contentView.addSubview(skeletonLayout)
        skeletonLayout.fwPinEdgesToSuperview()
        addAnimationView(skeletonLayout)
        return cell
    }
    
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableDelegate.tableView(tableView, heightForRowAt: indexPath)
    }
    
    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let layoutHeader = tableDelegate.tableView(tableView, viewForHeaderInSection: section) else { return nil }
        let header = UITableViewHeaderFooterView.fwHeaderFooterView(with: tableView)
        if let skeletonLayout = header.contentView.viewWithTag(2052) as? FWSkeletonLayout {
            skeletonLayout.removeFromSuperview()
            removeAnimationView(skeletonLayout)
        }
        
        if layoutHeader.superview == nil {
            let height = tableDelegate.tableView(tableView, heightForHeaderInSection: section)
            layoutHeader.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: height)
            layoutHeader.setNeedsLayout()
            layoutHeader.layoutIfNeeded()
        }
        
        let skeletonLayout = FWSkeletonLayout.parseSkeletonLayout(layoutHeader)
        skeletonLayout.tag = 2052
        header.contentView.addSubview(skeletonLayout)
        skeletonLayout.fwPinEdgesToSuperview()
        addAnimationView(skeletonLayout)
        return header
    }
    
    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return tableDelegate.tableView(tableView, heightForHeaderInSection: section)
    }
    
    open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let layoutFooter = tableDelegate.tableView(tableView, viewForFooterInSection: section) else { return nil }
        let footer = UITableViewHeaderFooterView.fwHeaderFooterView(with: tableView)
        if let skeletonLayout = footer.contentView.viewWithTag(2052) as? FWSkeletonLayout {
            skeletonLayout.removeFromSuperview()
            removeAnimationView(skeletonLayout)
        }
        
        if layoutFooter.superview == nil {
            let height = tableDelegate.tableView(tableView, heightForFooterInSection: section)
            layoutFooter.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: height)
            layoutFooter.setNeedsLayout()
            layoutFooter.layoutIfNeeded()
        }
        
        let skeletonLayout = FWSkeletonLayout.parseSkeletonLayout(layoutFooter)
        skeletonLayout.tag = 2052
        footer.contentView.addSubview(skeletonLayout)
        skeletonLayout.fwPinEdgesToSuperview()
        addAnimationView(skeletonLayout)
        return footer
    }
    
    open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return tableDelegate.tableView(tableView, heightForFooterInSection: section)
    }
}

// MARK: - FWSkeletonCollectionView

/// 骨架屏集合视图，可生成集合骨架屏
@objcMembers open class FWSkeletonCollectionView: FWSkeletonLayout, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    /// 集合视图，默认不可滚动
    open lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: bounds, collectionViewLayout: collectionViewLayout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isScrollEnabled = false
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        return collectionView
    }()
    
    /// 集合布局，默认UICollectionViewFlowLayout
    open var collectionViewLayout: UICollectionViewLayout
    
    /// 集合section数，默认1
    open var numberOfSections: Int = 1
    /// 集合section边距，默认zero
    open var insetForSectionArray: [UIEdgeInsets]?
    /// 单section边距
    open var insetForSection: UIEdgeInsets {
        get { return insetForSectionArray?.first ?? .zero }
        set { insetForSectionArray = [newValue] }
    }
    
    /// 集合section头视图数组，支持UIView或UICollectionReusableView.Type(fwViewModel值为nil)
    open var viewForHeaderArray: [Any]?
    /// 集合section头尺寸数组，不指定时默认使用FWDynamicLayout自动计算(fwViewModel值为nil)
    open var sizeForHeaderArray: [CGSize]?
    /// 单section头视图，支持UIView或UICollectionReusableView.Type
    open var viewForHeader: Any? {
        get { return viewForHeaderArray?.first }
        set { viewForHeaderArray = newValue != nil ? [newValue!] : nil }
    }
    /// 单section头尺寸
    open var sizeForHeader: CGSize {
        get { return sizeForHeaderArray?.first ?? .zero }
        set { sizeForHeaderArray = [newValue] }
    }
    
    /// 集合section尾视图数组，支持UIView或UICollectionReusableView.Type(fwViewModel值为nil)
    open var viewForFooterArray: [Any]?
    /// 集合section尾尺寸数组，不指定时默认使用FWDynamicLayout自动计算(fwViewModel值为nil)
    open var sizeForFooterArray: [CGSize]?
    /// 单section尾视图，支持UIView或UICollectionReusableView.Type
    open var viewForFooter: Any? {
        get { return viewForFooterArray?.first }
        set { viewForFooterArray = newValue != nil ? [newValue!] : nil }
    }
    /// 单section尾尺寸
    open var sizeForFooter: CGSize {
        get { return sizeForFooterArray?.first ?? .zero }
        set { sizeForFooterArray = [newValue] }
    }
    
    /// 集合item数组，默认自动计算
    open var numberOfItemsArray: [Int]?
    /// 集合cell数组，section内相同，支持UICollectionViewCell或UICollectionViewCell.Type(fwViewModel值为nil)
    open var cellForItemArray: [Any]?
    /// 集合cell尺寸数组，section内相同，不指定时默认使用FWDynamicLayout自动计算(fwViewModel值为nil)
    open var sizeForItemArray: [CGSize]?
    /// 单section集合item数，默认自动计算
    open var numberOfItems: Int {
        get { return numberOfItemsArray?.first ?? 0 }
        set { numberOfItemsArray = [newValue] }
    }
    /// 单section集合cell，section内相同，支持UICollectionViewCell或UICollectionViewCell.Type
    open var cellForItem: Any? {
        get { return cellForItemArray?.first }
        set { cellForItemArray = newValue != nil ? [newValue!] : nil }
    }
    /// 单section集合cell尺寸，section内相同
    open var sizeForItem: CGSize {
        get { return sizeForItemArray?.first ?? .zero }
        set { sizeForItemArray = [newValue] }
    }
    
    public init(collectionViewLayout: UICollectionViewLayout) {
        self.collectionViewLayout = collectionViewLayout
        super.init(frame: .zero)
    }
    
    public override init(layoutView: UIView?) {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        
        self.collectionViewLayout = flowLayout
        super.init(layoutView: layoutView)
    }
    
    public override init(frame: CGRect) {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        
        self.collectionViewLayout = flowLayout
        super.init(frame: frame)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupView() {
        backgroundColor = FWSkeletonAppearance.appearance.backgroundColor
        collectionView.backgroundColor = FWSkeletonAppearance.appearance.backgroundColor
        
        addSubview(collectionView)
        collectionView.fwPinEdgesToSuperview()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.reloadData()
    }
    
    private func sizeForItem(_ section: Int) -> CGSize {
        if let sizeArray = sizeForItemArray, sizeArray.count > section,
           sizeArray[section].width > 0, sizeArray[section].height > 0 {
            return sizeArray[section]
        }
        
        if let sectionArray = cellForItemArray, sectionArray.count > section {
            let object = sectionArray[section]
            if let view = object as? UIView {
                return view.frame.size
            }
            if let clazz = object as? UICollectionViewCell.Type {
                let sectionInset = sectionEdgeInset(section)
                var width: CGFloat = 0
                if sectionInset != .zero && collectionView.frame.size.width > 0 {
                    width = collectionView.frame.size.width - sectionInset.left - sectionInset.right
                }
                return collectionView.fwSize(withCellClass: clazz, width: width, cacheByKey: NSNumber(value: section)) { (cell) in
                    cell.fwViewModel = nil
                }
            }
        }
        return .zero
    }
    
    private func sizeForHeader(_ section: Int) -> CGSize {
        if let sizeArray = sizeForHeaderArray, sizeArray.count > section,
           sizeArray[section].width > 0, sizeArray[section].height > 0 {
            return sizeArray[section]
        }
        
        if let sectionArray = viewForHeaderArray, sectionArray.count > section {
            let object = sectionArray[section]
            if let view = object as? UIView {
                return view.frame.size
            }
            if let clazz = object as? UICollectionReusableView.Type {
                return collectionView.fwSize(withReusableViewClass: clazz, kind: UICollectionView.elementKindSectionHeader, cacheBySection: section) { (header) in
                    header.fwViewModel = nil
                }
            }
        }
        return .zero
    }
    
    private func sizeForFooter(_ section: Int) -> CGSize {
        if let sizeArray = sizeForFooterArray, sizeArray.count > section,
           sizeArray[section].width > 0, sizeArray[section].height > 0 {
            return sizeArray[section]
        }
        
        if let sectionArray = viewForFooterArray, sectionArray.count > section {
            let object = sectionArray[section]
            if let view = object as? UIView {
                return view.frame.size
            }
            if let clazz = object as? UICollectionReusableView.Type {
                return collectionView.fwSize(withReusableViewClass: clazz, kind: UICollectionView.elementKindSectionFooter, cacheBySection: section) { (footer) in
                    footer.fwViewModel = nil
                }
            }
        }
        return .zero
    }
    
    private func sectionEdgeInset(_ section: Int) -> UIEdgeInsets {
        if let insetArray = insetForSectionArray, insetArray.count > section {
            return insetArray[section]
        }
        
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            return flowLayout.sectionInset
        }
        return .zero
    }
    
    // MARK: - UICollectionView
    
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return numberOfSections
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let numberArray = numberOfItemsArray, numberArray.count > section, numberArray[section] > 0 {
            return numberArray[section]
        }
        
        let size = sizeForItem(section)
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout,
           flowLayout.scrollDirection == .horizontal {
            return size.width > 0 ? Int(ceil(UIScreen.main.bounds.size.width / size.width)) : 0
        } else {
            return size.height > 0 ? Int(ceil(UIScreen.main.bounds.size.height / size.height)) : 0
        }
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = UICollectionViewCell.fwCell(with: collectionView, indexPath: indexPath, reuseIdentifier: "FWSkeletonCell\(indexPath.section)")
        guard let sectionArray = cellForItemArray, sectionArray.count > indexPath.section else { return cell }
        guard cell.fwBoundBool(forKey: "FWSkeletonCell") == false else { return cell }
        
        var layout: FWSkeletonLayout?
        let object = sectionArray[indexPath.section]
        if let view = object as? UIView {
            layout = FWSkeletonLayout.parseSkeletonLayout(view)
        } else if let clazz = object as? UICollectionViewCell.Type {
            let contentView = clazz.init(frame: .zero)
            contentView.fwViewModel = nil
            let contentSize = sizeForItem(indexPath.section)
            contentView.frame = CGRect(origin: .zero, size: contentSize)
            contentView.setNeedsLayout()
            contentView.layoutIfNeeded()
            layout = FWSkeletonLayout.parseSkeletonLayout(contentView)
        }
        
        if let skeletonLayout = layout {
            cell.contentView.addSubview(skeletonLayout)
            skeletonLayout.fwPinEdgesToSuperview()
            addAnimationView(skeletonLayout)
        }
        cell.fwBindBool(true, forKey: "FWSkeletonCell")
        return cell
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return sizeForItem(indexPath.section)
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionEdgeInset(section)
    }
    
    open func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            guard let sectionArray = viewForHeaderArray, sectionArray.count > indexPath.section else { return UICollectionReusableView() }
            
            let header = UICollectionReusableView.fwReusableView(with: collectionView, kind: kind, indexPath: indexPath, reuseIdentifier: "FWSkeletonHeader\(indexPath.section)")
            guard header.fwBoundBool(forKey: "FWSkeletonHeader") == false else { return header }
            
            var layout: FWSkeletonLayout?
            let object = sectionArray[indexPath.section]
            if let view = object as? UIView {
                layout = FWSkeletonLayout.parseSkeletonLayout(view)
            } else if let clazz = object as? UICollectionReusableView.Type {
                let contentView = clazz.init(frame: .zero)
                contentView.fwViewModel = nil
                let contentSize = sizeForHeader(indexPath.section)
                contentView.frame = CGRect(origin: .zero, size: contentSize)
                contentView.setNeedsLayout()
                contentView.layoutIfNeeded()
                layout = FWSkeletonLayout.parseSkeletonLayout(contentView)
            }
            
            if let skeletonLayout = layout {
                header.addSubview(skeletonLayout)
                skeletonLayout.fwPinEdgesToSuperview()
                addAnimationView(skeletonLayout)
            }
            header.fwBindBool(true, forKey: "FWSkeletonHeader")
            return header
        } else if kind == UICollectionView.elementKindSectionFooter {
            guard let sectionArray = viewForFooterArray, sectionArray.count > indexPath.section else { return UICollectionReusableView() }
            
            let footer = UICollectionReusableView.fwReusableView(with: collectionView, kind: kind, indexPath: indexPath, reuseIdentifier: "FWSkeletonFooter\(indexPath.section)")
            guard footer.fwBoundBool(forKey: "FWSkeletonFooter") == false else { return footer }
            
            var layout: FWSkeletonLayout?
            let object = sectionArray[indexPath.section]
            if let view = object as? UIView {
                layout = FWSkeletonLayout.parseSkeletonLayout(view)
            } else if let clazz = object as? UICollectionReusableView.Type {
                let contentView = clazz.init(frame: .zero)
                contentView.fwViewModel = nil
                let contentSize = sizeForFooter(indexPath.section)
                contentView.frame = CGRect(origin: .zero, size: contentSize)
                contentView.setNeedsLayout()
                contentView.layoutIfNeeded()
                layout = FWSkeletonLayout.parseSkeletonLayout(contentView)
            }
            
            if let skeletonLayout = layout {
                footer.addSubview(skeletonLayout)
                skeletonLayout.fwPinEdgesToSuperview()
                addAnimationView(skeletonLayout)
            }
            footer.fwBindBool(true, forKey: "FWSkeletonFooter")
            return footer
        }
        return UICollectionReusableView()
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return sizeForHeader(section)
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return sizeForFooter(section)
    }
}

// MARK: - UIKit+FWSkeletonLayout

/// 视图显示骨架屏扩展
@objc extension UIView {
    private func fwShowSkeleton(delegate: FWSkeletonViewDelegate? = nil, block: ((FWSkeletonLayout) -> Void)? = nil) {
        // UITableView|UICollectionView调用addSubview不会显示，此处使用父视图
        if self is UITableView || self is UICollectionView {
            superview?.fwShowSkeleton(delegate: delegate, block: block)
            return
        }
        
        fwHideSkeleton()
        setNeedsLayout()
        layoutIfNeeded()
        
        let layout = FWSkeletonLayout(layoutView: self)
        layout.tag = 2051
        addSubview(layout)
        layout.fwPinEdgesToSuperview()
        
        delegate?.skeletonViewLayout(layout)
        block?(layout)
        
        layout.setNeedsLayout()
        layout.layoutIfNeeded()
        layout.startAnimating()
    }
    
    /// 显示骨架屏，指定布局代理
    open func fwShowSkeleton(delegate: FWSkeletonViewDelegate? = nil) {
        fwShowSkeleton(delegate: delegate, block: nil)
    }
    
    /// 显示骨架屏，指定布局句柄
    open func fwShowSkeleton(block: ((FWSkeletonLayout) -> Void)? = nil) {
        fwShowSkeleton(delegate: nil, block: block)
    }
    
    /// 显示骨架屏，默认布局代理为self
    open func fwShowSkeleton() {
        fwShowSkeleton(delegate: self as? FWSkeletonViewDelegate)
    }
    
    /// 隐藏骨架屏
    open func fwHideSkeleton() {
        // UITableView|UICollectionView调用addSubview不会显示，此处使用父视图
        if self is UITableView || self is UICollectionView {
            superview?.fwHideSkeleton()
            return
        }
        
        if let layout = subviews.first(where: { $0.tag == 2051 }) as? FWSkeletonLayout {
            layout.stopAnimating()
            layout.removeFromSuperview()
        }
    }
}

/// 控制器显示骨架屏扩展
@objc extension UIViewController {
    /// 显示view骨架屏，指定布局代理
    open func fwShowSkeleton(delegate: FWSkeletonViewDelegate? = nil) {
        view.fwShowSkeleton(delegate: delegate)
    }
    
    /// 显示view骨架屏，指定布局句柄
    open func fwShowSkeleton(block: ((FWSkeletonLayout) -> Void)? = nil) {
        view.fwShowSkeleton(block: block)
    }
    
    /// 显示view骨架屏，默认布局代理为self
    open func fwShowSkeleton() {
        fwShowSkeleton(delegate: self as? FWSkeletonViewDelegate)
    }
    
    /// 隐藏view骨架屏
    open func fwHideSkeleton() {
        view.fwHideSkeleton()
    }
}

// MARK: - UIKit+FWSkeletonView

/// UILabel骨架屏视图数据源扩展
extension UILabel: FWSkeletonViewDataSource {
    open func skeletonViewProvider() -> FWSkeletonView? {
        let skeletonLabel = FWSkeletonLabel()
        skeletonLabel.lineHeight = font.pointSize
        if (font.lineHeight - font.pointSize) >= FWSkeletonAppearance.appearance.lineSpacing {
            skeletonLabel.lineSpacing = font.lineHeight - font.pointSize
        }
        skeletonLabel.numberOfLines = numberOfLines
        return skeletonLabel
    }
}

/// UITextView骨架屏视图数据源扩展
extension UITextView: FWSkeletonViewDataSource {
    open func skeletonViewProvider() -> FWSkeletonView? {
        let skeletonLabel = FWSkeletonLabel()
        if let textFont = font {
            skeletonLabel.lineHeight = textFont.pointSize
            if (textFont.lineHeight - textFont.pointSize) >= FWSkeletonAppearance.appearance.lineSpacing {
                skeletonLabel.lineSpacing = textFont.lineHeight - textFont.pointSize
            }
        }
        skeletonLabel.contentInsets = textContainerInset
        return skeletonLabel
    }
}

/// UITableView骨架屏视图数据源扩展
extension UITableView: FWSkeletonViewDataSource {
    open func skeletonViewProvider() -> FWSkeletonView? {
        let tableView = FWSkeletonTableView(style: style)
        tableView.layoutView = self
        tableView.tableHeaderView = tableHeaderView
        tableView.tableFooterView = tableFooterView
        tableView.tableDelegate.sectionCount = numberOfSections
        guard numberOfSections > 0 else { return tableView }
        
        tableView.tableDelegate.viewForHeader = { [weak self] (section) in
            return self?.headerView(forSection: section)
        }
        tableView.tableDelegate.viewForFooter = { [weak self] (section) in
            return self?.footerView(forSection: section)
        }
        tableView.tableDelegate.countForRow = { [weak self] (section) in
            return self?.numberOfRows(inSection: section) ?? 0
        }
        tableView.tableDelegate.cellForRow = { [weak self] (indexPath) in
            return self?.cellForRow(at: indexPath)
        }
        return tableView
    }
}

/// UICollectionView骨架屏视图数据源扩展
extension UICollectionView: FWSkeletonViewDataSource {
    open func skeletonViewProvider() -> FWSkeletonView? {
        let collectionView: FWSkeletonCollectionView
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            let skeletonLayout = UICollectionViewFlowLayout()
            skeletonLayout.itemSize = flowLayout.itemSize
            skeletonLayout.estimatedItemSize = flowLayout.estimatedItemSize
            skeletonLayout.minimumLineSpacing = flowLayout.minimumLineSpacing
            skeletonLayout.minimumInteritemSpacing = flowLayout.minimumInteritemSpacing
            skeletonLayout.scrollDirection = flowLayout.scrollDirection
            skeletonLayout.headerReferenceSize = flowLayout.headerReferenceSize
            skeletonLayout.footerReferenceSize = flowLayout.footerReferenceSize
            skeletonLayout.sectionInset = flowLayout.sectionInset
            collectionView = FWSkeletonCollectionView(collectionViewLayout: skeletonLayout)
        } else {
            collectionView = FWSkeletonCollectionView()
        }
        collectionView.layoutView = self
        collectionView.numberOfSections = numberOfSections
        
        var viewForHeaderArray: [Any] = []
        var sizeForHeaderArray: [CGSize] = []
        var viewForFooterArray: [Any] = []
        var sizeForFooterArray: [CGSize] = []
        var numberOfItemsArray: [Int] = []
        var cellForItemArray: [Any] = []
        var sizeForItemArray: [CGSize] = []
        
        for section in 0 ..< numberOfSections {
            let viewForHeader: UIView? = supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: section))
            if viewForHeader != nil || numberOfSections > 1 {
                viewForHeaderArray.append(viewForHeader ?? UIView(frame: .zero))
                let sizeForHeader: CGSize? = viewForHeader?.frame.size
                sizeForHeaderArray.append(sizeForHeader ?? .zero)
            }
            
            let viewForFooter: UIView? = supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter, at: IndexPath(item: 0, section: section))
            if viewForFooter != nil || numberOfSections > 1 {
                viewForFooterArray.append(viewForFooter ?? UIView(frame: .zero))
                let sizeForFooter: CGSize? = viewForFooter?.frame.size
                sizeForFooterArray.append(sizeForFooter ?? .zero)
            }
            
            let number = numberOfItems(inSection: section)
            numberOfItemsArray.append(number)
            
            let indexPath: IndexPath? = (number > 0) ? IndexPath(row: 0, section: section) : nil
            let cell: UICollectionViewCell? = (indexPath != nil) ? cellForItem(at: indexPath!) : nil
            cellForItemArray.append((cell != nil) ? cell! : UICollectionViewCell(frame: .zero))
            
            let size: CGSize = (cell != nil) ? cell!.frame.size : .zero
            sizeForItemArray.append(size)
        }
        
        collectionView.viewForHeaderArray = viewForHeaderArray
        collectionView.sizeForHeaderArray = sizeForHeaderArray
        collectionView.viewForFooterArray = viewForFooterArray
        collectionView.sizeForFooterArray = sizeForFooterArray
        collectionView.numberOfItemsArray = numberOfItemsArray
        collectionView.cellForItemArray = cellForItemArray
        collectionView.sizeForItemArray = sizeForItemArray
        return collectionView
    }
}

/// UITableViewCell骨架屏视图代理扩展
extension UITableViewCell: FWSkeletonViewDelegate {
    open func skeletonViewLayout(_ layout: FWSkeletonLayout) {
        layout.addSkeletonViews(contentView.subviews)
    }
}

/// UITableViewHeaderFooterView骨架屏视图代理扩展
extension UITableViewHeaderFooterView: FWSkeletonViewDelegate {
    open func skeletonViewLayout(_ layout: FWSkeletonLayout) {
        layout.addSkeletonViews(contentView.subviews)
    }
}

/// UICollectionReusableView骨架屏视图代理扩展
extension UICollectionReusableView: FWSkeletonViewDelegate {
    open func skeletonViewLayout(_ layout: FWSkeletonLayout) {
        layout.addSkeletonViews(subviews)
    }
}

/// UICollectionViewCell骨架屏视图代理扩展
extension UICollectionViewCell {
    open override func skeletonViewLayout(_ layout: FWSkeletonLayout) {
        layout.addSkeletonViews(contentView.subviews)
    }
}
