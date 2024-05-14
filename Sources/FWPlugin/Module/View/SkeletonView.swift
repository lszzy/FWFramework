//
//  SkeletonView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - Wrapper+UIView
/// 视图显示骨架屏扩展
extension Wrapper where Base: UIView {
    /// 显示骨架屏，指定布局代理
    public func showSkeleton(delegate: SkeletonViewDelegate?) {
        showSkeleton(delegate: delegate, block: nil)
    }
    
    /// 显示骨架屏，指定布局句柄
    public func showSkeleton(block: ((SkeletonLayout) -> Void)?) {
        showSkeleton(delegate: nil, block: block)
    }
    
    /// 显示骨架屏，默认布局代理为self
    public func showSkeleton() {
        showSkeleton(delegate: base as? SkeletonViewDelegate)
    }
    
    /// 隐藏骨架屏
    public func hideSkeleton() {
        // UITableView|UICollectionView调用addSubview不会显示，此处使用父视图
        if base is UITableView || base is UICollectionView {
            base.superview?.fw.hideSkeleton()
            return
        }
        
        if let layout = base.subviews.first(where: { $0.tag == 2051 }) as? SkeletonLayout {
            layout.removeFromSuperview()
        }
    }
    
    /// 是否正在显示骨架屏
    public var hasSkeleton: Bool {
        // UITableView|UICollectionView调用addSubview不会显示，此处使用父视图
        if base is UITableView || base is UICollectionView {
            return base.superview?.fw.hasSkeleton ?? false
        }
        
        return base.subviews.firstIndex(where: { $0.tag == 2051 }) != nil
    }
    
    private func showSkeleton(delegate: SkeletonViewDelegate? = nil, block: ((SkeletonLayout) -> Void)? = nil) {
        // UITableView|UICollectionView调用addSubview不会显示，此处使用父视图
        if base is UITableView || base is UICollectionView {
            base.superview?.fw.showSkeleton(delegate: delegate, block: block)
            return
        }
        
        hideSkeleton()
        base.setNeedsLayout()
        base.layoutIfNeeded()
        
        let layout = SkeletonLayout(layoutView: base)
        layout.tag = 2051
        base.addSubview(layout)
        layout.fw.pinEdges()
        
        delegate?.skeletonViewLayout(layout)
        block?(layout)
        
        layout.setNeedsLayout()
        layout.layoutIfNeeded()
    }
}

// MARK: - Wrapper+UIViewController
/// 控制器显示骨架屏扩展
extension Wrapper where Base: UIViewController {
    /// 显示view骨架屏，指定布局代理
    public func showSkeleton(delegate: SkeletonViewDelegate?) {
        base.view.fw.showSkeleton(delegate: delegate)
    }
    
    /// 显示view骨架屏，指定布局句柄
    public func showSkeleton(block: ((SkeletonLayout) -> Void)?) {
        base.view.fw.showSkeleton(block: block)
    }
    
    /// 显示view骨架屏，默认布局代理为self
    public func showSkeleton() {
        showSkeleton(delegate: base as? SkeletonViewDelegate)
    }
    
    /// 隐藏view骨架屏
    public func hideSkeleton() {
        base.view.fw.hideSkeleton()
    }
    
    /// 是否正在显示view骨架屏
    public var hasSkeleton: Bool {
        return base.view.fw.hasSkeleton
    }
}

// MARK: - SkeletonAnimation
/// 骨架屏动画协议
public protocol SkeletonAnimationProtocol {
    func skeletonAnimationStart(_ gradientLayer: CAGradientLayer)
    func skeletonAnimationStop(_ gradientLayer: CAGradientLayer)
}

/// 骨架屏自带动画类型
public enum SkeletonAnimationType: Int {
    /// 闪光灯动画
    case shimmer
    /// 呼吸灯动画
    case solid
    /// 伸缩动画
    case scale
}

/// 骨架屏自带动画方向
public enum SkeletonAnimationDirection: Int {
    case right
    case left
    case down
    case up
}

/// 骨架屏自带动画
open class SkeletonAnimation: NSObject, SkeletonAnimationProtocol {
    public static let shimmer = SkeletonAnimation(type: .shimmer)
    public static let solid = SkeletonAnimation(type: .solid)
    public static let scale = SkeletonAnimation(type: .scale)
    
    open var fromValue: Any?
    open var toValue: Any?
    open var colors: [UIColor]?
    open var duration: TimeInterval = 1
    open var delay: TimeInterval = 0
    open var repeatCount: Float = .infinity
    open var direction: SkeletonAnimationDirection = .right
    
    private var type: SkeletonAnimationType = .shimmer
    
    // MARK: - Lifecycle
    public override init() {
        super.init()
        setupAnimation()
    }
    
    public init(type: SkeletonAnimationType) {
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
            let lightColor = UIColor.fw.color(hex: 0xEEEEEE)
            let lightBrightness: CGFloat = 0.92
            let darkColor = UIColor.fw.color(hex: 0x282828)
            let darkBrightness: CGFloat = 0.5
            colors = [
                UIColor.fw.themeLight(lightColor, dark: darkColor),
                UIColor.fw.themeLight(lightColor.fw.brightnessColor(lightBrightness), dark: darkColor.fw.brightnessColor(darkBrightness)),
                UIColor.fw.themeLight(lightColor, dark: darkColor)
            ]
        }
    }
    
    // MARK: - SkeletonAnimationProtocol
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
            gradientLayer.fw.themeColors = colors
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

// MARK: - SkeletonAppearance
/// 骨架屏通用样式
public class SkeletonAppearance: NSObject {
    /// 单例对象
    public static let appearance = SkeletonAppearance()
    
    /// 骨架动画，默认nil
    public var animation: SkeletonAnimationProtocol?
    
    /// 骨架背景色，默认自动适配
    public var backgroundColor: UIColor = UIColor.fw.themeLight(UIColor.white, dark: UIColor.black)
    /// 骨架颜色，默认自动适配
    public var skeletonColor: UIColor = UIColor.fw.themeLight(UIColor.fw.color(hex: 0xEEEEEE), dark: UIColor.fw.color(hex: 0x282828))
    
    /// 多行标签行高，默认15
    public var lineHeight: CGFloat = 15
    /// 多行标签固定间距，默认10
    public var lineSpacing: CGFloat = 10
    /// 多行标签最后一行百分比，默认0.7
    public var lastLinePercent: CGFloat = 0.7
    /// 多行标签圆角，默认0
    public var lineCornerRadius: CGFloat = 0
}

// MARK: - SkeletonView
/// 骨架屏视图数据源协议
@objc public protocol SkeletonViewDataSource {
    /// 骨架屏视图创建方法
    func skeletonViewProvider() -> SkeletonView?
}

/// 骨架屏视图代理协议
@objc public protocol SkeletonViewDelegate {
    /// 骨架屏视图布局方法
    func skeletonViewLayout(_ layout: SkeletonLayout)
}

/// 骨架屏视图，支持设置占位图片
open class SkeletonView: UIView {
    /// 自定义动画，默认通用样式
    open var animation: SkeletonAnimationProtocol? = SkeletonAppearance.appearance.animation
    
    /// 动画层列表
    open var animationLayers: [CAGradientLayer] = []
    
    /// 骨架图片，默认空
    open var image: UIImage? {
        didSet {
            layer.fw.themeContents = image
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
        super.init(coder: coder)
        setupView()
    }
    
    func setupView() {
        animationLayers.append(layer as! CAGradientLayer)
        backgroundColor = SkeletonAppearance.appearance.skeletonColor
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
    
    /// 自动开始和停止动画
    open override func didMoveToWindow() {
        super.didMoveToWindow()
        
        if window != nil {
            updateAnimationLayers()
            animationLayers.forEach { (gradientLayer) in
                gradientLayer.fw.themeContext = self
                animation?.skeletonAnimationStart(gradientLayer)
            }
        } else {
            animationLayers.forEach { (gradientLayer) in
                animation?.skeletonAnimationStop(gradientLayer)
            }
        }
    }
    
    /// 更新动画层列表，子类可覆写
    open func updateAnimationLayers() {}
}

// MARK: - SkeletonLabel
/// 骨架屏多行标签视图，可显示多行骨架
open class SkeletonLabel: SkeletonView {
    /// 行数，默认0
    open var numberOfLines: Int = 0
    /// 行高，默认15
    open var lineHeight: CGFloat = SkeletonAppearance.appearance.lineHeight
    /// 行圆角，默认0
    open var lineCornerRadius: CGFloat = SkeletonAppearance.appearance.lineCornerRadius
    /// 行固定间距，默认10
    open var lineSpacing: CGFloat = SkeletonAppearance.appearance.lineSpacing
    /// 最后一行显示百分比，默认0.7
    open var lastLinePercent: CGFloat = SkeletonAppearance.appearance.lastLinePercent
    /// 行颜色，默认骨架颜色
    open var lineColor: UIColor = SkeletonAppearance.appearance.skeletonColor
    /// 内容边距，默认zero
    open var contentInsets: UIEdgeInsets = .zero
    
    override func setupView() {
        backgroundColor = UIColor.clear
    }
    
    open override func updateAnimationLayers() {
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

// MARK: - SkeletonLayout
/// 骨架屏布局视图，可从视图生成骨架屏，嵌套到UIScrollView即可实现滚动
open class SkeletonLayout: SkeletonView {
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
        super.init(coder: coder)
    }
    
    override func setupView() {
        backgroundColor = SkeletonAppearance.appearance.backgroundColor
    }
    
    /// 设置相对滚动视图，实现跟随下拉刷新等效果。block参数为contentOffset.y(不大于0)，默认设置顶部布局跟随滚动
    open func setScrollView(_ scrollView: UIScrollView, scrollBlock: ((CGFloat) -> ())? = nil) {
        var block = scrollBlock
        if block == nil && superview != nil {
            let constraint = fw.constraint(toSuperview: .top)
            let constant = constraint?.constant ?? 0
            block = { (offsetY) in
                constraint?.constant = constant - offsetY
            }
        }
        
        if scrollView.contentOffset.y <= 0 && superview != nil {
            block?(scrollView.contentOffset.y)
        }
        scrollView.fw.observeProperty(\.contentOffset) { [weak self] scrollView, _ in
            if scrollView.contentOffset.y <= 0 && self?.superview != nil {
                block?(scrollView.contentOffset.y)
            }
        }
    }
    
    // MARK: - Skeleton
    /// 批量添加子视图(兼容骨架视图)，返回生成的骨架视图数组
    @discardableResult
    open func addSkeletonViews(_ views: [UIView]) -> [SkeletonView] {
        return addSkeletonViews(views, block: nil)
    }
    
    /// 批量添加子视图(兼容骨架视图)，支持自定义骨架，返回生成的骨架视图数组
    @discardableResult
    open func addSkeletonViews(_ views: [UIView], block: ((SkeletonView, Int) -> Void)?) -> [SkeletonView] {
        var resultViews: [SkeletonView] = []
        for (index, view) in views.enumerated() {
            resultViews.append(addSkeletonView(view, block: { (skeletonView) in
                block?(skeletonView, index)
            }))
        }
        return resultViews
    }
    
    /// 添加单个子视图(兼容骨架视图)，返回生成的骨架视图
    @discardableResult
    open func addSkeletonView(_ view: UIView) -> SkeletonView {
        return addSkeletonView(view, block: nil)
    }
    
    /// 添加单个子视图(兼容骨架视图)，支持自定义骨架，返回生成的骨架视图
    @discardableResult
    open func addSkeletonView(_ view: UIView, block: ((SkeletonView) -> Void)?) -> SkeletonView {
        let skeletonView = SkeletonLayout.parseSkeletonView(view)
        return addSkeletonView(view, skeletonView: skeletonView, block: block)
    }
    
    /// 添加骨架视图，内部方法
    private func addSkeletonView<T: SkeletonView>(_ view: UIView, skeletonView: T, block: ((T) -> Void)?) -> T {
        if layoutView != nil && view.isDescendant(of: layoutView!) {
            skeletonView.frame = view.convert(view.bounds, to: layoutView!)
        }
        if skeletonView.superview == nil {
            addSubview(skeletonView)
        }
        block?(skeletonView)
        return skeletonView
    }
    
    /// 添加单个布局视图(兼容骨架视图)，返回生成的骨架布局
    @discardableResult
    open func addSkeletonLayout(_ view: UIView) -> SkeletonLayout {
        return addSkeletonLayout(view, block: nil)
    }
    
    /// 添加单个布局视图(兼容骨架视图)，支持自定义骨架，返回生成的骨架布局
    @discardableResult
    open func addSkeletonLayout(_ view: UIView, block: ((SkeletonLayout) -> Void)?) -> SkeletonLayout {
        let skeletonView = SkeletonLayout.parseSkeletonLayout(view)
        return addSkeletonView(view, skeletonView: skeletonView, block: block)
    }
    
    // MARK: - Parser
    /// 解析视图为骨架视图
    open class func parseSkeletonView(_ view: UIView) -> SkeletonView {
        if view is SkeletonView {
            return view as! SkeletonView
        }
        
        if let skeletonDataSource = view as? SkeletonViewDataSource {
            if let skeletonView = skeletonDataSource.skeletonViewProvider() {
                return skeletonView
            }
        }
        
        if let skeletonDelegate = view as? SkeletonViewDelegate {
            let skeletonLayout = SkeletonLayout(layoutView: view)
            skeletonDelegate.skeletonViewLayout(skeletonLayout)
            return skeletonLayout
        }
        
        let skeletonView = SkeletonView()
        skeletonView.parseView(view)
        return skeletonView
    }
    
    /// 解析布局视图为骨架布局
    open class func parseSkeletonLayout(_ view: UIView) -> SkeletonLayout {
        if view is SkeletonLayout {
            return view as! SkeletonLayout
        }
        
        let skeletonLayout = SkeletonLayout(layoutView: view)
        if let skeletonDelegate = view as? SkeletonViewDelegate {
            skeletonDelegate.skeletonViewLayout(skeletonLayout)
            return skeletonLayout
        }
        
        skeletonLayout.addSkeletonViews(view.subviews)
        return skeletonLayout
    }
}

// MARK: - SkeletonTableView
/// 骨架屏表格视图，可生成表格骨架屏
open class SkeletonTableView: SkeletonLayout, UITableViewDataSource, UITableViewDelegate {
    /// 表格视图，默认不可滚动
    open lazy var tableView: UITableView = {
        let tableView = UITableView.fw.tableView(style)
        tableView.frame = bounds
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        return tableView
    }()
    
    /// 表格视图代理，快速生成表格
    open lazy var tableDelegate: TableViewDelegate = {
        return TableViewDelegate()
    }()
    
    /// 表格头视图
    open var tableHeaderView: UIView? {
        didSet {
            guard let layoutHeader = tableHeaderView else { return }
            
            let skeletonLayout = SkeletonLayout.parseSkeletonLayout(layoutHeader)
            tableView.tableHeaderView = skeletonLayout
        }
    }
    /// 表格尾视图
    open var tableFooterView: UIView? {
        didSet {
            guard let layoutFooter = tableFooterView else { return }
            
            let skeletonLayout = SkeletonLayout.parseSkeletonLayout(layoutFooter)
            tableView.tableFooterView = skeletonLayout
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
        super.init(coder: coder)
    }
    
    override func setupView() {
        backgroundColor = SkeletonAppearance.appearance.backgroundColor
        tableView.backgroundColor = SkeletonAppearance.appearance.backgroundColor
        
        addSubview(tableView)
        tableView.fw.pinEdges()
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
        let cell = UITableViewCell.fw.cell(tableView: tableView, style: .default, reuseIdentifier: "FWSkeletonCell")
        cell.selectionStyle = .none
        if let skeletonLayout = cell.contentView.viewWithTag(2052) as? SkeletonLayout {
            skeletonLayout.removeFromSuperview()
        }
        
        if layoutCell.superview == nil {
            let height = tableDelegate.tableView(tableView, heightForRowAt: indexPath)
            layoutCell.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: height)
            layoutCell.setNeedsLayout()
            layoutCell.layoutIfNeeded()
        }
        
        let skeletonLayout = SkeletonLayout.parseSkeletonLayout(layoutCell)
        skeletonLayout.tag = 2052
        cell.contentView.addSubview(skeletonLayout)
        skeletonLayout.fw.pinEdges()
        return cell
    }
    
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableDelegate.tableView(tableView, heightForRowAt: indexPath)
    }
    
    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let layoutHeader = tableDelegate.tableView(tableView, viewForHeaderInSection: section) else { return nil }
        let header = UITableViewHeaderFooterView.fw.headerFooterView(tableView: tableView, reuseIdentifier: "FWSkeletonHeader")
        if let skeletonLayout = header.contentView.viewWithTag(2052) as? SkeletonLayout {
            skeletonLayout.removeFromSuperview()
        }
        
        if layoutHeader.superview == nil {
            let height = tableDelegate.tableView(tableView, heightForHeaderInSection: section)
            layoutHeader.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: height)
            layoutHeader.setNeedsLayout()
            layoutHeader.layoutIfNeeded()
        }
        
        let skeletonLayout = SkeletonLayout.parseSkeletonLayout(layoutHeader)
        skeletonLayout.tag = 2052
        header.contentView.addSubview(skeletonLayout)
        skeletonLayout.fw.pinEdges()
        return header
    }
    
    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return tableDelegate.tableView(tableView, heightForHeaderInSection: section)
    }
    
    open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let layoutFooter = tableDelegate.tableView(tableView, viewForFooterInSection: section) else { return nil }
        let footer = UITableViewHeaderFooterView.fw.headerFooterView(tableView: tableView, reuseIdentifier: "FWSkeletonFooter")
        if let skeletonLayout = footer.contentView.viewWithTag(2052) as? SkeletonLayout {
            skeletonLayout.removeFromSuperview()
        }
        
        if layoutFooter.superview == nil {
            let height = tableDelegate.tableView(tableView, heightForFooterInSection: section)
            layoutFooter.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: height)
            layoutFooter.setNeedsLayout()
            layoutFooter.layoutIfNeeded()
        }
        
        let skeletonLayout = SkeletonLayout.parseSkeletonLayout(layoutFooter)
        skeletonLayout.tag = 2052
        footer.contentView.addSubview(skeletonLayout)
        skeletonLayout.fw.pinEdges()
        return footer
    }
    
    open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return tableDelegate.tableView(tableView, heightForFooterInSection: section)
    }
}

// MARK: - SkeletonCollectionView
/// 骨架屏集合视图，可生成集合骨架屏
open class SkeletonCollectionView: SkeletonLayout, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    /// 集合视图，默认不可滚动
    open lazy var collectionView: UICollectionView = {
        let collectionView: UICollectionView
        if let viewLayout = collectionViewLayout {
            collectionView = UICollectionView.fw.collectionView(viewLayout)
        } else {
            collectionView = UICollectionView.fw.collectionView()
        }
        collectionView.frame = bounds
        collectionView.isScrollEnabled = false
        return collectionView
    }()
    
    /// 集合视图代理，快速生成集合
    open lazy var collectionDelegate: CollectionViewDelegate = {
        return CollectionViewDelegate()
    }()
    
    private var collectionViewLayout: UICollectionViewLayout?
    
    public init(collectionViewLayout: UICollectionViewLayout) {
        self.collectionViewLayout = collectionViewLayout
        super.init(frame: .zero)
    }
    
    public override init(layoutView: UIView?) {
        super.init(layoutView: layoutView)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func setupView() {
        backgroundColor = SkeletonAppearance.appearance.backgroundColor
        collectionView.backgroundColor = SkeletonAppearance.appearance.backgroundColor
        
        addSubview(collectionView)
        collectionView.fw.pinEdges()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.reloadData()
    }
    
    // MARK: - UICollectionView
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        let count = collectionDelegate.numberOfSections(in: collectionView)
        return count > 0 ? count : 1
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = collectionDelegate.collectionView(collectionView, numberOfItemsInSection: section)
        if count > 0 { return count }
        
        let size = collectionDelegate.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: IndexPath(item: 0, section: section))
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout,
           flowLayout.scrollDirection == .horizontal {
            return size.width > 0 ? Int(ceil(UIScreen.main.bounds.size.width / size.width)) : 0
        } else {
            return size.height > 0 ? Int(ceil(UIScreen.main.bounds.size.height / size.height)) : 0
        }
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let layoutCell = collectionDelegate.collectionView(collectionView, cellForItemAt: indexPath)
        let cell = UICollectionViewCell.fw.cell(collectionView: collectionView, indexPath: indexPath, reuseIdentifier: "FWSkeletonCell")
        if let skeletonLayout = cell.contentView.viewWithTag(2052) as? SkeletonLayout {
            skeletonLayout.removeFromSuperview()
        }
        
        if layoutCell.superview == nil {
            let size = collectionDelegate.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: indexPath)
            layoutCell.frame = CGRect(origin: .zero, size: size)
            layoutCell.setNeedsLayout()
            layoutCell.layoutIfNeeded()
        }
        
        let skeletonLayout = SkeletonLayout.parseSkeletonLayout(layoutCell)
        skeletonLayout.tag = 2052
        cell.contentView.addSubview(skeletonLayout)
        skeletonLayout.fw.pinEdges()
        return cell
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionDelegate.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath)
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return collectionDelegate.collectionView(collectionView, layout: collectionViewLayout, insetForSectionAt: section)
    }
    
    open func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let layoutHeader = collectionDelegate.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
            let header = UICollectionReusableView.fw.reusableView(collectionView: collectionView, kind: kind, indexPath: indexPath, reuseIdentifier: "FWSkeletonHeader")
            if let skeletonLayout = header.viewWithTag(2052) as? SkeletonLayout {
                skeletonLayout.removeFromSuperview()
            }
            
            if layoutHeader.superview == nil {
                let size = collectionDelegate.collectionView(collectionView, layout: collectionView.collectionViewLayout, referenceSizeForHeaderInSection: indexPath.section)
                layoutHeader.frame = CGRect(origin: .zero, size: size)
                layoutHeader.setNeedsLayout()
                layoutHeader.layoutIfNeeded()
            }
            
            let skeletonLayout = SkeletonLayout.parseSkeletonLayout(layoutHeader)
            skeletonLayout.tag = 2052
            header.addSubview(skeletonLayout)
            skeletonLayout.fw.pinEdges()
            return header
        }
        
        if kind == UICollectionView.elementKindSectionFooter {
            let layoutFooter = collectionDelegate.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
            let footer = UICollectionReusableView.fw.reusableView(collectionView: collectionView, kind: kind, indexPath: indexPath, reuseIdentifier: "FWSkeletonFooter")
            if let skeletonLayout = footer.viewWithTag(2052) as? SkeletonLayout {
                skeletonLayout.removeFromSuperview()
            }
            
            if layoutFooter.superview == nil {
                let size = collectionDelegate.collectionView(collectionView, layout: collectionView.collectionViewLayout, referenceSizeForFooterInSection: indexPath.section)
                layoutFooter.frame = CGRect(origin: .zero, size: size)
                layoutFooter.setNeedsLayout()
                layoutFooter.layoutIfNeeded()
            }
            
            let skeletonLayout = SkeletonLayout.parseSkeletonLayout(layoutFooter)
            skeletonLayout.tag = 2052
            footer.addSubview(skeletonLayout)
            skeletonLayout.fw.pinEdges()
            return footer
        }
        
        return UICollectionReusableView()
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return collectionDelegate.collectionView(collectionView, layout: collectionViewLayout, referenceSizeForHeaderInSection: section)
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return collectionDelegate.collectionView(collectionView, layout: collectionViewLayout, referenceSizeForFooterInSection: section)
    }
}

// MARK: - UIKit+SkeletonView
/// UILabel骨架屏视图数据源扩展
extension UILabel: SkeletonViewDataSource {
    open func skeletonViewProvider() -> SkeletonView? {
        let skeletonLabel = SkeletonLabel()
        skeletonLabel.lineHeight = font.pointSize
        if (font.lineHeight - font.pointSize) >= SkeletonAppearance.appearance.lineSpacing {
            skeletonLabel.lineSpacing = font.lineHeight - font.pointSize
        }
        skeletonLabel.numberOfLines = numberOfLines
        return skeletonLabel
    }
}

/// UITextView骨架屏视图数据源扩展
extension UITextView: SkeletonViewDataSource {
    open func skeletonViewProvider() -> SkeletonView? {
        let skeletonLabel = SkeletonLabel()
        if let textFont = font {
            skeletonLabel.lineHeight = textFont.pointSize
            if (textFont.lineHeight - textFont.pointSize) >= SkeletonAppearance.appearance.lineSpacing {
                skeletonLabel.lineSpacing = textFont.lineHeight - textFont.pointSize
            }
        }
        skeletonLabel.contentInsets = textContainerInset
        return skeletonLabel
    }
}

/// UITableView骨架屏视图数据源扩展
extension UITableView: SkeletonViewDataSource {
    open func skeletonViewProvider() -> SkeletonView? {
        let tableView = SkeletonTableView(style: style)
        tableView.layoutView = self
        tableView.tableHeaderView = tableHeaderView
        tableView.tableFooterView = tableFooterView
        tableView.tableDelegate.sectionCount = numberOfSections
        guard numberOfSections > 0 else { return tableView }
        
        tableView.tableDelegate.viewForHeader = { [weak self] (_, section) in
            return self?.headerView(forSection: section)
        }
        tableView.tableDelegate.heightForHeader = { [weak self] (_, section) in
            return self?.headerView(forSection: section)?.frame.size.height ?? 0
        }
        tableView.tableDelegate.viewForFooter = { [weak self] (_, section) in
            return self?.footerView(forSection: section)
        }
        tableView.tableDelegate.heightForFooter = { [weak self] (_, section) in
            return self?.footerView(forSection: section)?.frame.size.height ?? 0
        }
        tableView.tableDelegate.numberOfRows = { [weak self] (section) in
            return self?.numberOfRows(inSection: section) ?? 0
        }
        tableView.tableDelegate.cellForRow = { [weak self] (_, indexPath) in
            return self?.cellForRow(at: indexPath)
        }
        tableView.tableDelegate.heightForRow = { [weak self] (_, indexPath) in
            return self?.cellForRow(at: indexPath)?.frame.size.height ?? 0
        }
        return tableView
    }
}

/// UICollectionView骨架屏视图数据源扩展
extension UICollectionView: SkeletonViewDataSource {
    open func skeletonViewProvider() -> SkeletonView? {
        let collectionView: SkeletonCollectionView
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
            collectionView = SkeletonCollectionView(collectionViewLayout: skeletonLayout)
        } else {
            collectionView = SkeletonCollectionView()
        }
        collectionView.layoutView = self
        collectionView.collectionDelegate.sectionCount = numberOfSections
        guard numberOfSections > 0 else { return collectionView }
        
        collectionView.collectionDelegate.viewForHeader = { [weak self] (_, indexPath) in
            return self?.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: indexPath)
        }
        collectionView.collectionDelegate.sizeForHeader = { [weak self] (_, section) in
            return self?.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: section))?.frame.size ?? .zero
        }
        collectionView.collectionDelegate.viewForFooter = { [weak self] (_, indexPath) in
            return self?.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter, at: indexPath)
        }
        collectionView.collectionDelegate.sizeForFooter = { [weak self] (_, section) in
            return self?.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter, at: IndexPath(item: 0, section: section))?.frame.size ?? .zero
        }
        collectionView.collectionDelegate.numberOfItems = { [weak self] (section) in
            return self?.numberOfItems(inSection: section) ?? 0
        }
        collectionView.collectionDelegate.cellForItem = { [weak self] (_, indexPath) in
            return self?.cellForItem(at: indexPath)
        }
        collectionView.collectionDelegate.sizeForItem = { [weak self] (_, indexPath) in
            return self?.cellForItem(at: indexPath)?.frame.size ?? .zero
        }
        return collectionView
    }
}

/// UITableViewCell骨架屏视图代理扩展
extension UITableViewCell: SkeletonViewDelegate {
    open func skeletonViewLayout(_ layout: SkeletonLayout) {
        layout.addSkeletonViews(contentView.subviews)
    }
}

/// UITableViewHeaderFooterView骨架屏视图代理扩展
extension UITableViewHeaderFooterView: SkeletonViewDelegate {
    open func skeletonViewLayout(_ layout: SkeletonLayout) {
        layout.addSkeletonViews(contentView.subviews)
    }
}

/// UICollectionReusableView骨架屏视图代理扩展
extension UICollectionReusableView: SkeletonViewDelegate {
    open func skeletonViewLayout(_ layout: SkeletonLayout) {
        layout.addSkeletonViews(subviews)
    }
}

/// UICollectionViewCell骨架屏视图代理扩展
extension UICollectionViewCell {
    open override func skeletonViewLayout(_ layout: SkeletonLayout) {
        layout.addSkeletonViews(contentView.subviews)
    }
}
