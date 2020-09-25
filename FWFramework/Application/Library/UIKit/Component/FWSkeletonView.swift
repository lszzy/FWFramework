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
@objcMembers public class FWSkeletonAnimation: NSObject, FWSkeletonAnimationProtocol {
    public static let shimmer = FWSkeletonAnimation(type: .shimmer)
    public static let solid = FWSkeletonAnimation(type: .solid)
    public static let scale = FWSkeletonAnimation(type: .scale)
    
    public var fromValue: Any?
    public var toValue: Any?
    public var colors: [UIColor]?
    public var duration: TimeInterval = 1
    public var direction: FWSkeletonAnimationDirection = .right
    
    private var type: FWSkeletonAnimationType = .shimmer
    
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
            let lightColor = UIColor.fwColor(withHex: 0xDFDFDF)
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
    
    public func skeletonAnimationStart(_ gradientLayer: CAGradientLayer) {
        switch type {
        case .solid:
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.autoreverses = true
            animation.repeatCount = .infinity
            animation.duration = duration
            animation.fromValue = fromValue
            animation.toValue = toValue
            animation.timingFunction = CAMediaTimingFunction(name: .easeIn)
            gradientLayer.add(animation, forKey: "skeletonAnimation")
        case .scale:
            let animation = CABasicAnimation()
            switch direction {
            case .right:
                animation.keyPath = "transform.scale.x"
                gradientLayer.anchorPoint = CGPoint(x: 0, y: 0.5)
                gradientLayer.position.x -= gradientLayer.bounds.size.width / 2.0
            case .left:
                animation.keyPath = "transform.scale.x"
                gradientLayer.anchorPoint = CGPoint(x: 1, y: 0.5)
                gradientLayer.position.x += gradientLayer.bounds.size.width / 2.0
            case .down:
                animation.keyPath = "transform.scale.y"
                gradientLayer.anchorPoint = CGPoint(x: 0.5, y: 0)
                gradientLayer.position.y -= gradientLayer.bounds.size.height / 2.0
            case .up:
                animation.keyPath = "transform.scale.y"
                gradientLayer.anchorPoint = CGPoint(x: 0.5, y: 1)
                gradientLayer.position.y += gradientLayer.bounds.size.height / 2.0
            }
            
            animation.autoreverses = true
            animation.repeatCount = .infinity
            animation.duration = duration
            animation.fromValue = fromValue
            animation.toValue = toValue
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            gradientLayer.add(animation, forKey: "skeletonAnimation")
        default:
            let startAnimation = CABasicAnimation(keyPath: "startPoint")
            let endAnimation = CABasicAnimation(keyPath: "endPoint")
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
            animationGroup.repeatCount = .infinity
            animationGroup.animations = [startAnimation, endAnimation]
            animationGroup.duration = duration
            animationGroup.timingFunction = CAMediaTimingFunction(name: .easeIn)
            gradientLayer.fwThemeColors = colors
            gradientLayer.add(animationGroup, forKey: "skeletonAnimation")
        }
    }
    
    public func skeletonAnimationStop(_ gradientLayer: CAGradientLayer) {
        gradientLayer.removeAnimation(forKey: "skeletonAnimation")
    }
}

// MARK: - FWSkeletonView

/// 骨架屏视图数据源协议
@objc public protocol FWSkeletonViewDataSource {
    func skeletonViewProvider() -> FWSkeletonView?
}

/// 骨架屏视图代理协议
@objc public protocol FWSkeletonViewDelegate {
    func skeletonViewLayout(_ layout: FWSkeletonLayout)
}

/// 骨架屏通用样式
@objcMembers public class FWSkeletonAppearance: NSObject {
    /// 单例对象
    public static let appearance = FWSkeletonAppearance()
    
    /// 骨架动画，默认闪光灯
    public var animation: FWSkeletonAnimationProtocol? = FWSkeletonAnimation.shimmer
    
    /// 骨架背景色，默认自动适配
    public var backgroundColor: UIColor = UIColor.fwThemeLight(UIColor.white, dark: UIColor.black)
    /// 骨架颜色，默认自动适配
    public var skeletonColor: UIColor = UIColor.fwThemeLight(UIColor.fwColor(withHex: 0xEEEEEE), dark: UIColor.fwColor(withHex: 0x282828))
    
    /// 多行标签行高，默认15
    public var lineHeight: CGFloat = 15
    /// 多行标签行距倍数，默认0不生效，和lineSpacing二选一
    public var lineSpacingPercent: CGFloat = 0
    /// 多行标签固定间距，默认10，和lineSpacingPercent二选一
    public var lineSpacing: CGFloat = 10
    /// 多行标签最后一行百分比，默认0.7
    public var lastLinePercent: CGFloat = 0.7
    /// 多行标签圆角，默认0
    public var lineCornerRadius: CGFloat = 0
}

/// 骨架屏视图，支持设置占位图片
@objcMembers public class FWSkeletonView: UIView {
    /// 自定义动画，默认通用样式
    public var animation: FWSkeletonAnimationProtocol? = FWSkeletonAppearance.appearance.animation
    
    /// 动画层列表，子类可覆写
    public var animationLayers: [CAGradientLayer] = []
    
    /// 骨架图片，默认空
    public var image: UIImage? {
        didSet {
            layer.fwThemeContents = image
            layer.contentsGravity = .resizeAspectFill
        }
    }
    
    public override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        animationLayers.append(layer as! CAGradientLayer)
        backgroundColor = FWSkeletonAppearance.appearance.skeletonColor
    }
    
    /// 开始动画
    public func startAnimating() {
        animationLayers.forEach { (gradientLayer) in
            gradientLayer.fwThemeContext = self
            animation?.skeletonAnimationStart(gradientLayer)
        }
    }
    
    /// 停止动画
    public func stopAnimating() {
        animationLayers.forEach { (gradientLayer) in
            animation?.skeletonAnimationStop(gradientLayer)
        }
    }
}

/// 骨架屏多行标签视图，可显示多行骨架
@objcMembers public class FWSkeletonLabel: FWSkeletonView {
    /// 行数，默认0
    public var numberOfLines: Int = 0
    /// 行高，默认15
    public var lineHeight: CGFloat = FWSkeletonAppearance.appearance.lineHeight
    /// 行圆角，默认0
    public var lineCornerRadius: CGFloat = FWSkeletonAppearance.appearance.lineCornerRadius
    /// 行间距比率，默认0
    public var lineSpacingPercent: CGFloat = FWSkeletonAppearance.appearance.lineSpacingPercent
    /// 行固定间距，默认10
    public var lineSpacing: CGFloat = FWSkeletonAppearance.appearance.lineSpacing
    /// 最后一行显示百分比，默认0.7
    public var lastLinePercent: CGFloat = FWSkeletonAppearance.appearance.lastLinePercent
    /// 行颜色，默认骨架颜色
    public var lineColor: UIColor = FWSkeletonAppearance.appearance.skeletonColor
    /// 内容边距，默认zero
    public var contentInsets: UIEdgeInsets = .zero
    
    override func setupView() {
        backgroundColor = UIColor.clear
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        animationLayers.removeAll()
        
        let layerHeight = lineHeight
        let layerSpacing = lineSpacingPercent > 0 ? lineHeight * lineSpacingPercent : lineSpacing
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

/// 骨架屏容器视图，可添加多个骨架动画视图
@objcMembers public class FWSkeletonStack: FWSkeletonView {
    private var animationViews: [FWSkeletonView] = []
    
    override func setupView() {
        backgroundColor = FWSkeletonAppearance.appearance.backgroundColor
    }
    
    /// 添加动画视图，不会调用addSubview
    public func addAnimationViews(_ animationViews: [FWSkeletonView]) {
        for animationView in animationViews {
            addAnimationView(animationView)
        }
    }
    
    /// 添加动画视图，不会调用addSubview
    public func addAnimationView(_ animationView: FWSkeletonView) {
        if !animationViews.contains(animationView) {
            animationViews.append(animationView)
        }
    }
    
    /// 批量开始动画
    public override func startAnimating() {
        animationViews.forEach { (animationView) in
            animationView.startAnimating()
        }
    }
    
    /// 批量停止动画
    public override func stopAnimating() {
        animationViews.forEach { (animationView) in
            animationView.stopAnimating()
        }
        animationViews.removeAll()
    }
}

/// 骨架屏布局视图，可从视图生成骨架屏，嵌套到UIScrollView即可实现滚动
@objcMembers public class FWSkeletonLayout: FWSkeletonStack {
    /// 相对布局视图
    public var layoutView: UIView?
    
    /// 指定相对布局视图初始化
    public init(layoutView: UIView) {
        super.init(frame: layoutView.bounds)
        self.layoutView = layoutView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 批量添加布局子视图(兼容骨架视图)，返回生成的骨架视图数组
    @discardableResult
    public func addSkeletonViews(_ views: [UIView]) -> [FWSkeletonView] {
        return addSkeletonViews(views, block: nil)
    }
    
    /// 批量添加布局子视图(兼容骨架视图)，支持自定义骨架，返回生成的骨架视图数组
    @discardableResult
    public func addSkeletonViews(_ views: [UIView], block: ((FWSkeletonView, Int) -> Void)?) -> [FWSkeletonView] {
        var resultViews: [FWSkeletonView] = []
        for (index, view) in views.enumerated() {
            resultViews.append(addSkeletonView(view, block: { (skeletonView) in
                block?(skeletonView, index)
            }))
        }
        return resultViews
    }
    
    /// 添加单个布局子视图(兼容骨架视图)，返回生成的骨架视图
    @discardableResult
    public func addSkeletonView(_ view: UIView) -> FWSkeletonView {
        return addSkeletonView(view, block: nil)
    }
    
    /// 添加单个布局子视图(兼容骨架视图)，支持自定义骨架，返回生成的骨架视图
    @discardableResult
    public func addSkeletonView(_ view: UIView, block: ((FWSkeletonView) -> Void)?) -> FWSkeletonView {
        let skeletonView = FWSkeletonLayout.parseSkeletonView(view)
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
    
    /// 解析布局子视图为骨架视图
    public class func parseSkeletonView(_ view: UIView) -> FWSkeletonView {
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
        skeletonView.layer.masksToBounds = view.layer.masksToBounds
        skeletonView.layer.cornerRadius = view.layer.cornerRadius
        if view.layer.shadowOpacity > 0 {
            skeletonView.layer.shadowColor = view.layer.shadowColor
            skeletonView.layer.shadowOffset = view.layer.shadowOffset
            skeletonView.layer.shadowRadius = view.layer.shadowRadius
            skeletonView.layer.shadowPath = view.layer.shadowPath
            skeletonView.layer.shadowOpacity = view.layer.shadowOpacity
        }
        return skeletonView
    }
    
    /// 解析布局子视图为骨架布局
    public class func parseSkeletonLayout(_ view: UIView) -> FWSkeletonLayout {
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

/// 骨架屏表格视图，可生成表格骨架屏
@objcMembers public class FWSkeletonTableView: FWSkeletonStack, UITableViewDataSource, UITableViewDelegate {
    /// 表格头视图
    public var tableHeaderView: UIView? {
        didSet {
            guard let headerView = tableHeaderView else { return }
            
            let skeletonLayout = FWSkeletonLayout.parseSkeletonLayout(headerView)
            tableView.tableHeaderView = skeletonLayout
            addAnimationView(skeletonLayout)
        }
    }
    /// 表格尾视图
    public var tableFooterView: UIView? {
        didSet {
            guard let footerView = tableFooterView else { return }
            
            let skeletonLayout = FWSkeletonLayout.parseSkeletonLayout(footerView)
            tableView.tableFooterView = skeletonLayout
            addAnimationView(skeletonLayout)
        }
    }
    
    /// 表格section数，默认1
    public var numberOfSections: Int = 1
    
    /// 表格section头视图，支持UIView或AnyClass
    public var sectionHeaderViewArray: [Any]?
    /// 表格section头高度
    public var sectionHeaderHeightArray: [CGFloat]?
    /// 单section头视图，支持UIView或AnyClass
    public var sectionHeaderView: Any? {
        get { return sectionHeaderViewArray?.first }
        set { sectionHeaderViewArray = newValue != nil ? [newValue!] : nil }
    }
    /// 单section头高度
    public var sectionHeaderHeight: CGFloat {
        get { return sectionHeaderHeightArray?.first ?? 0 }
        set { sectionHeaderHeightArray = [newValue] }
    }
    
    /// 表格section尾视图，支持UIView或AnyClass
    public var sectionFooterViewArray: [Any]?
    /// 表格section尾高度
    public var sectionFooterHeightArray: [CGFloat]?
    /// 单section尾视图，支持UIView或AnyClass
    public var sectionFooterView: Any? {
        get { return sectionFooterViewArray?.first }
        set { sectionFooterViewArray = newValue != nil ? [newValue!] : nil }
    }
    /// 单section尾高度
    public var sectionFooterHeight: CGFloat {
        get { return sectionFooterHeightArray?.first ?? 0 }
        set { sectionFooterHeightArray = [newValue] }
    }
    
    /// 表格row数，默认自动计算
    public var numberOfRowsArray: [Int]?
    /// 表格cell创建句柄，section内相同，支持UITableViewCell或AnyClass
    public var cellForRowArray: [Any]?
    /// 表格cell高度，section内相同
    public var heightForRowArray: [CGFloat]?
    /// 单section表格row数，默认自动计算
    public var numberOfRows: Int {
        get { return numberOfRowsArray?.first ?? 0 }
        set { numberOfRowsArray = [newValue] }
    }
    /// 单section表格cell创建句柄，section内相同，支持UITableViewCell或AnyClass
    public var cellForRow: Any? {
        get { return cellForRowArray?.first }
        set { cellForRowArray = newValue != nil ? [newValue!] : nil }
    }
    /// 单section表格cell高度，section内相同
    public var heightForRow: CGFloat {
        get { return heightForRowArray?.first ?? 0 }
        set { heightForRowArray = [newValue] }
    }
    
    /// 表格视图，默认不可滚动
    public lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.isScrollEnabled = false
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
        return tableView
    }()
    
    override func setupView() {
        backgroundColor = FWSkeletonAppearance.appearance.backgroundColor
        tableView.backgroundColor = FWSkeletonAppearance.appearance.backgroundColor
        
        addSubview(tableView)
        tableView.fwPinEdgesToSuperview()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData()
    }
    
    // MARK: - UITableView
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfSections
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var number: Int = 0
        if let numberArray = numberOfRowsArray, numberArray.count > section {
            number = numberArray[section]
        }
        if number < 1 {
            var height: CGFloat = 0
            if let heightArray = heightForRowArray, heightArray.count > section {
                height = heightArray[section]
            }
            if height > 0 {
                number = Int(ceil(UIScreen.main.bounds.size.height / height))
            }
        }
        return number
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "FWSkeletonCell\(indexPath.section)") {
            return cell
        }
        
        let cell = UITableViewCell(style: .default, reuseIdentifier: "FWSkeletonCell\(indexPath.section)")
        guard let cellArray = cellForRowArray, cellArray.count > indexPath.section else { return cell }
        
        var cellLayout: FWSkeletonLayout?
        let cellObject = cellArray[indexPath.section]
        if let cellView = cellObject as? UIView {
            cellLayout = FWSkeletonLayout.parseSkeletonLayout(cellView)
        } else if let cellClass = cellObject as? UITableViewCell.Type {
            let contentCell = cellClass.init(style: .default, reuseIdentifier: "FWSkeletonCell\(indexPath.section)")
            cellLayout = FWSkeletonLayout.parseSkeletonLayout(contentCell)
        }
        
        if let skeletonLayout = cellLayout {
            cell.contentView.addSubview(skeletonLayout)
            skeletonLayout.fwPinEdgesToSuperview()
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let heightArray = heightForRowArray, heightArray.count > indexPath.section {
            return heightArray[indexPath.section]
        }
        return 0
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let heightArray = sectionHeaderHeightArray, heightArray.count > section {
            return heightArray[section]
        }
        return 0
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if let heightArray = sectionFooterHeightArray, heightArray.count > section {
            return heightArray[section]
        }
        return 0
    }
}

// MARK: - UIKit+FWSkeletonView

/// 视图显示骨架屏扩展
@objc extension UIView {
    private func fwShowSkeleton(delegate: FWSkeletonViewDelegate? = nil, block: ((FWSkeletonLayout) -> Void)? = nil) {
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
    
    public func fwShowSkeleton(delegate: FWSkeletonViewDelegate? = nil) {
        fwShowSkeleton(delegate: delegate, block: nil)
    }
    
    public func fwShowSkeleton(block: ((FWSkeletonLayout) -> Void)? = nil) {
        fwShowSkeleton(delegate: nil, block: block)
    }
    
    public func fwShowSkeleton() {
        fwShowSkeleton(delegate: self as? FWSkeletonViewDelegate)
    }
    
    public func fwHideSkeleton() {
        if let layout = subviews.first(where: { $0.tag == 2051 }) as? FWSkeletonLayout {
            layout.stopAnimating()
            layout.removeFromSuperview()
        }
    }
}

/// 控制器显示骨架屏扩展
@objc extension UIViewController {
    public func fwShowSkeleton(delegate: FWSkeletonViewDelegate? = nil) {
        view.fwShowSkeleton(delegate: delegate)
    }
    
    public func fwShowSkeleton(block: ((FWSkeletonLayout) -> Void)? = nil) {
        view.fwShowSkeleton(block: block)
    }
    
    public func fwShowSkeleton() {
        fwShowSkeleton(delegate: self as? FWSkeletonViewDelegate)
    }
    
    public func fwHideSkeleton() {
        view.fwHideSkeleton()
    }
}

/// UILabel骨架屏视图数据源扩展
extension UILabel: FWSkeletonViewDataSource {
    public func skeletonViewProvider() -> FWSkeletonView? {
        let skeletonLabel = FWSkeletonLabel()
        skeletonLabel.lineHeight = font.pointSize
        // 系统字体默认行间距太小，暂不解析
        // skeletonLabel.lineSpacing = font.lineHeight - font.pointSize
        skeletonLabel.numberOfLines = numberOfLines
        return skeletonLabel
    }
}

/// UITextView骨架屏视图数据源扩展
extension UITextView: FWSkeletonViewDataSource {
    public func skeletonViewProvider() -> FWSkeletonView? {
        let skeletonLabel = FWSkeletonLabel()
        if let textFont = font {
            skeletonLabel.lineHeight = textFont.pointSize
            // 系统字体默认行间距太小，暂不解析
            // skeletonLabel.lineSpacing = textFont.lineHeight - textFont.pointSize
        }
        skeletonLabel.contentInsets = textContainerInset
        return skeletonLabel
    }
}

/// UITableView骨架屏视图数据源扩展
extension UITableView: FWSkeletonViewDataSource {
    public func skeletonViewProvider() -> FWSkeletonView? {
        let tableView = FWSkeletonTableView()
        
        tableView.tableHeaderView = tableHeaderView
        tableView.tableFooterView = tableFooterView
        
        tableView.numberOfSections = numberOfSections
        
        var numberOfRowsArray: [Int] = []
        for section in 0 ..< numberOfSections {
            numberOfRowsArray.append(numberOfRows(inSection: section))
        }
        tableView.numberOfRowsArray = numberOfRowsArray
        
        /*
        if let sectionHeaderView = headerView(forSection: 0) {
            tableView.sectionHeaderView = FWSkeletonLayout.parseSkeletonLayout(sectionHeaderView)
            tableView.sectionHeaderHeight = sectionHeaderView.frame.size.height
        }*/
        
        return tableView
    }
}

/// UITableViewCell骨架屏视图代理扩展
extension UITableViewCell: FWSkeletonViewDelegate {
    public func skeletonViewLayout(_ layout: FWSkeletonLayout) {
        layout.addSkeletonViews(contentView.subviews)
    }
}

/// UITableViewHeaderFooterView骨架屏视图代理扩展
extension UITableViewHeaderFooterView: FWSkeletonViewDelegate {
    public func skeletonViewLayout(_ layout: FWSkeletonLayout) {
        layout.addSkeletonViews(contentView.subviews)
    }
}
