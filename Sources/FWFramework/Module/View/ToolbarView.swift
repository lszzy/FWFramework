//
//  ToolbarView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - ToolbarView
public enum ToolbarViewType: Int {
    
    /// 默认工具栏，含菜单和底部，无titleView，自动兼容横屏
    case `default` = 0
    /// 导航栏类型，含顶部和菜单，自带titleView，自动兼容横屏
    case navBar
    /// 标签栏类型，含菜单和底部，水平等分，自动兼容横屏
    case tabBar
    /// 自定义类型，无顶部和底部，初始高度44，需手工兼容横屏
    case custom
    
}

/// 自定义工具栏视图，使用非等比例缩放布局，高度自动布局(总高度toolbarHeight)，可设置toolbarHidden隐藏(总高度0)
///
/// 根据toolbarPosition自动设置默认高度，可自定义，如下：
/// 顶部：topView，高度为topHeight，可设置topHidden隐藏
/// 中间：menuView，高度为menuHeight，可设置menuHidden隐藏
/// 底部：bottomView，高度为bottomHeight，可设置bottomHidden隐藏
open class ToolbarView: UIView {

    // MARK: - Accessor
    /// 当前工具栏类型，只读，默认default
    open private(set) var type: ToolbarViewType = .default

    /// 顶部高度，根据类型初始化
    open var topHeight: CGFloat = 0 {
        didSet {
            if topHeight != oldValue {
                updateLayout(false)
            }
        }
    }
    
    /// 菜单高度，根据类型初始化
    open var menuHeight: CGFloat = 0 {
        didSet {
            if menuHeight != oldValue {
                updateLayout(false)
            }
        }
    }
    
    /// 底部高度，根据类型初始化
    open var bottomHeight: CGFloat = 0 {
        didSet {
            if bottomHeight != oldValue {
                updateLayout(false)
            }
        }
    }
    
    /// 工具栏总高度，topHeight+menuHeight+bottomHeight，隐藏时为0
    open var toolbarHeight: CGFloat {
        var height: CGFloat = 0
        if isHidden || toolbarHidden { return height }
        if !topHidden { height += topHeight }
        if !menuHidden { height += menuHeight }
        if !bottomHidden { height += bottomHeight }
        return height
    }

    /// 顶部栏是否隐藏，默认NO
    open var topHidden: Bool {
        get { _topHidden }
        set { setTopHidden(newValue, animated: false) }
    }
    private var _topHidden: Bool = false
    
    /// 菜单是否隐藏，默认NO
    open var menuHidden: Bool {
        get { _menuHidden }
        set { setMenuHidden(newValue, animated: false) }
    }
    private var _menuHidden: Bool = false
    
    /// 底部栏是否隐藏，默认NO
    open var bottomHidden: Bool {
        get { _bottomHidden }
        set { setBottomHidden(newValue, animated: false) }
    }
    private var _bottomHidden: Bool = false
    
    /// 工具栏是否隐藏，默认NO，推荐使用(系统hidden切换时无动画)
    open var toolbarHidden: Bool {
        get { _toolbarHidden }
        set { setToolbarHidden(newValue, animated: false) }
    }
    private var _toolbarHidden: Bool = false
    
    open override var isHidden: Bool {
        didSet {
            if isHidden != oldValue {
                updateLayout(false)
            }
        }
    }
    
    private var isLandscape: Bool = false
    
    // MARK: - Subviews
    /// 背景图片视图，用于设置背景图片
    open lazy var backgroundView: UIImageView = {
        let result = UIImageView()
        result.clipsToBounds = true
        return result
    }()
    
    /// 顶部视图，延迟加载
    open lazy var topView: UIView = {
        let result = UIView()
        result.clipsToBounds = true
        addSubview(result)
        
        result.fw.pinHorizontal(autoScale: false)
        result.fw.pinEdge(toSuperview: .top, autoScale: false)
        result.fw.pinEdge(.bottom, toEdge: .top, ofView: menuView, autoScale: false)
        return result
    }()
    
    /// 菜单视图，初始加载
    open lazy var menuView: ToolbarMenuView = {
        let result = ToolbarMenuView()
        result.equalWidth = (type == .tabBar)
        result.titleView = (type == .navBar) ? ToolbarTitleView() : nil
        return result
    }()
    
    /// 底部视图，延迟加载
    open lazy var bottomView: UIView = {
        let result = UIView()
        result.clipsToBounds = true
        addSubview(result)
        
        result.fw.pinHorizontal(autoScale: false)
        result.fw.pinEdge(toSuperview: .bottom, autoScale: false)
        result.fw.pinEdge(.top, toEdge: .bottom, ofView: menuView, autoScale: false)
        return result
    }()
    
    // MARK: - Lifecycle
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        didInitialize(type: .default)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        didInitialize(type: .default)
    }
    
    /// 指定类型初始化，会设置默认高度和视图
    public init(type: ToolbarViewType) {
        super.init(frame: .zero)
        
        didInitialize(type: type)
    }
    
    private func didInitialize(type: ToolbarViewType) {
        self.type = type
        updateHeight(true)
        
        addSubview(backgroundView)
        addSubview(menuView)
        backgroundView.fw.pinEdges(autoScale: false)
        menuView.fw.pinHorizontal(autoScale: false)
        menuView.fw.pinEdge(toSuperview: .top, inset: topHeight, autoScale: false)
        menuView.fw.pinEdge(toSuperview: .bottom, inset: bottomHeight, autoScale: false)
        menuView.fw.setDimension(.height, size: menuHeight, autoScale: false)
    }
    
    // MARK: - Public
    open func updateHeight(_ isInitialize: Bool) {
        switch type {
        case .navBar:
            topHeight = UIScreen.fw.statusBarHeight
            menuHeight = UIScreen.fw.navigationBarHeight
        case .tabBar:
            menuHeight = UIScreen.fw.tabBarHeight - UIScreen.fw.safeAreaInsets.bottom
            bottomHeight = UIScreen.fw.safeAreaInsets.bottom
        case .custom:
            if isInitialize {
                menuHeight = 44
            }
        default:
            menuHeight = UIScreen.fw.toolBarHeight - UIScreen.fw.safeAreaInsets.bottom
            bottomHeight = UIScreen.fw.safeAreaInsets.bottom
        }
    }
    
    open func updateLayout(_ animated: Bool) {
        setNeedsUpdateConstraints()
        invalidateIntrinsicContentSize()
        
        if animated, superview != nil {
            UIView.animate(withDuration: 0.25) {
                self.superview?.layoutIfNeeded()
            }
        }
    }
    
    open override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        
        let isLandscape = UIDevice.fw.isLandscape
        if isLandscape != self.isLandscape {
            self.isLandscape = isLandscape
            updateHeight(false)
        }
        updateLayout(false)
    }
    
    open override func updateConstraints() {
        super.updateConstraints()
        
        let toolbarHidden = self.isHidden || self.toolbarHidden
        menuView.fw.pinEdge(toSuperview: .top, inset: toolbarHidden || topHidden ? 0 : topHeight, autoScale: false)
        menuView.fw.pinEdge(toSuperview: .bottom, inset: toolbarHidden || bottomHidden ? 0 : bottomHeight, autoScale: false)
        menuView.fw.setDimension(.height, size: toolbarHidden || menuHidden ? 0 : menuHeight, autoScale: false)
    }
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        let maxWidth = CGRectGetWidth(bounds) > 0 ? CGRectGetWidth(bounds) : UIScreen.main.bounds.size.width
        return CGSize(width: min(size.width, maxWidth), height: toolbarHeight)
    }
    
    open override var intrinsicContentSize: CGSize {
        return sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
    }
    
    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var pointInside = super.point(inside: point, with: event)
        if !pointInside && menuView.verticalOverflow {
            if menuView.point(inside: CGPoint(x: point.x - menuView.frame.origin.x, y: point.y - menuView.frame.origin.y), with: event) {
                pointInside = true
            }
        }
        return pointInside
    }

    // MARK: - Public
    /// 动态隐藏顶部栏
    open func setTopHidden(_ hidden: Bool, animated: Bool) {
        guard hidden != _topHidden else { return }
        _topHidden = hidden
        updateLayout(animated)
    }
    
    /// 动态隐藏菜单栏
    open func setMenuHidden(_ hidden: Bool, animated: Bool) {
        guard hidden != _menuHidden else { return }
        _menuHidden = hidden
        updateLayout(animated)
    }
    
    /// 动态隐藏底部栏
    open func setBottomHidden(_ hidden: Bool, animated: Bool) {
        guard hidden != _bottomHidden else { return }
        _bottomHidden = hidden
        updateLayout(animated)
    }
    
    /// 动态隐藏工具栏
    open func setToolbarHidden(_ hidden: Bool, animated: Bool) {
        guard hidden != _toolbarHidden else { return }
        _toolbarHidden = hidden
        updateLayout(animated)
    }
    
}

// MARK: - ToolbarMenuView
/// 自定义工具栏菜单视图，使用非等比例缩放布局，支持完全自定义，默认最多只支持左右各两个按钮，如需更多按钮，请自行添加。
///
/// 水平分割时，按钮水平等分；非水平分割时，左右侧间距为8，同系统一致
open class ToolbarMenuView: UIView {
    
    // MARK: - Accessor
    /// 自定义左侧按钮，设置后才显示，非等分时左侧间距为8。建议使用ToolbarButton
    open var leftButton: UIView? {
        didSet {
            guard leftButton != oldValue else { return }
            
            oldValue?.removeFromSuperview()
            if let leftButton = leftButton {
                addSubview(leftButton)
            }
            setNeedsUpdateConstraints()
        }
    }

    /// 自定义左侧更多按钮，设置后才显示，非等分时左侧间距为8。建议使用ToolbarButton
    open var leftMoreButton: UIView? {
        didSet {
            guard leftMoreButton != oldValue else { return }
            
            oldValue?.removeFromSuperview()
            if let leftMoreButton = leftMoreButton {
                addSubview(leftMoreButton)
            }
            setNeedsUpdateConstraints()
        }
    }

    /// 自定义居中按钮，设置后才显示，非等分时左右最大间距为0。建议使用ToolbarTitleView或ToolbarButton
    open var centerButton: UIView? {
        didSet {
            guard centerButton != oldValue else { return }
            
            oldValue?.removeFromSuperview()
            if let centerButton = centerButton {
                addSubview(centerButton)
            }
            setNeedsUpdateConstraints()
        }
    }

    /// 自定义右侧更多按钮，设置后才显示，非等分时右侧间距为8。建议使用ToolbarButton
    open var rightMoreButton: UIView? {
        didSet {
            guard rightMoreButton != oldValue else { return }
            
            oldValue?.removeFromSuperview()
            if let rightMoreButton = rightMoreButton {
                addSubview(rightMoreButton)
            }
            setNeedsUpdateConstraints()
        }
    }

    /// 自定义右侧按钮，设置后才显示，非等分时右侧间距为8。建议使用ToolbarButton
    open var rightButton: UIView? {
        didSet {
            guard rightButton != oldValue else { return }
            
            oldValue?.removeFromSuperview()
            if let rightButton = rightButton {
                addSubview(rightButton)
            }
            setNeedsUpdateConstraints()
        }
    }

    /// 是否等宽布局(类似UITabBar)，不含安全区域；默认NO，左右布局(类似UIToolbar|UINavigationBar)
    open var equalWidth: Bool = false {
        didSet {
            guard equalWidth != oldValue else { return }
            
            setNeedsUpdateConstraints()
        }
    }

    /// 是否支持等宽布局时纵向溢出显示，可用于实现TabBar不规则按钮等，默认NO
    open var verticalOverflow: Bool = false {
        didSet {
            guard verticalOverflow != oldValue else { return }
            
            clipsToBounds = !verticalOverflow
            setNeedsUpdateConstraints()
        }
    }

    /// 是否左对齐，仅左右布局时生效，默认NO居中对齐
    open var alignmentLeft: Bool = false {
        didSet {
            guard alignmentLeft != oldValue else { return }
            
            setNeedsUpdateConstraints()
        }
    }

    /// 设置左右侧间距，默认为8，同系统一致
    open var horizontalSpacing: CGFloat = 8 {
        didSet {
            guard horizontalSpacing != oldValue else { return }
            
            setNeedsUpdateConstraints()
        }
    }

    /// 设置按钮间距，默认8，同系统一致
    open var buttonSpacing: CGFloat = 8 {
        didSet {
            guard buttonSpacing != oldValue else { return }
            
            setNeedsUpdateConstraints()
        }
    }

    /// 快捷访问ToolbarTitleView标题视图，同centerButton
    open var titleView: ToolbarTitleView? {
        get {
            return centerButton as? ToolbarTitleView
        }
        set {
            centerButton = newValue
        }
    }

    /// 快捷访问标题，titleView类型为ToolbarTitleViewProtocol时才生效
    open var title: String? {
        get {
            if let titleView = centerButton as? TitleViewProtocol {
                return titleView.title
            }
            return nil
        }
        set {
            if let titleView = centerButton as? TitleViewProtocol {
                titleView.title = newValue
            }
        }
    }
    
    private var subviewConstraints: [NSLayoutConstraint] = []
    
    // MARK: - Lifecycle
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        clipsToBounds = true
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        clipsToBounds = true
    }
    
    open override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        
        setNeedsUpdateConstraints()
    }
    
    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var pointInside = super.point(inside: point, with: event)
        if !pointInside && verticalOverflow {
            for subview in subviews {
                if subview.point(inside: CGPoint(x: point.x - subview.frame.origin.x, y: point.y - subview.frame.origin.y), with: event) {
                    pointInside = true
                    break
                }
            }
        }
        return pointInside
    }
    
    open override func updateConstraints() {
        super.updateConstraints()
        
        if subviewConstraints.count > 0 {
            NSLayoutConstraint.deactivate(subviewConstraints)
            subviewConstraints.removeAll()
        }
        
        if equalWidth {
            var subviewButtons: [UIView] = []
            if let leftButton = leftButton { subviewButtons.append(leftButton) }
            if let leftMoreButton = leftMoreButton { subviewButtons.append(leftMoreButton) }
            if let centerButton = centerButton { subviewButtons.append(centerButton) }
            if let rightMoreButton = rightMoreButton { subviewButtons.append(rightMoreButton) }
            if let rightButton = rightButton { subviewButtons.append(rightButton) }
            if subviewButtons.count < 1 { return }
            
            var constraints: [NSLayoutConstraint] = []
            var previousButton: UIView?
            for subviewButton in subviewButtons {
                constraints.append(subviewButton.fw.pinEdge(toSuperview: .top, inset: 0, relation: verticalOverflow ? .lessThanOrEqual : .equal, autoScale: false))
                constraints.append(subviewButton.fw.pinEdge(toSuperview: .bottom, autoScale: false))
                if let previousButton = previousButton {
                    constraints.append(subviewButton.fw.pinEdge(.left, toEdge: .right, ofView: previousButton, autoScale: false))
                    constraints.append(subviewButton.fw.matchDimension(.width, toDimension: .width, ofView: previousButton, autoScale: false))
                } else {
                    constraints.append(subviewButton.fw.pinEdge(toSuperview: .left, inset: UIScreen.fw.safeAreaInsets.left, autoScale: false))
                }
                previousButton = subviewButton
            }
            if let previousButton = previousButton {
                constraints.append(previousButton.fw.pinEdge(toSuperview: .right, inset: UIScreen.fw.safeAreaInsets.right, autoScale: false))
            }
            subviewConstraints = constraints
            return
        }
        
        var constraints: [NSLayoutConstraint] = []
        let fitsSize = CGSize(width: bounds.size.width > 0 ? bounds.size.width : UIScreen.main.bounds.size.width, height: .greatestFiniteMagnitude)
        var leftWidth: CGFloat = 0
        let leftButton = self.leftButton ?? self.leftMoreButton
        let leftMoreButton = self.leftButton != nil && self.leftMoreButton != nil ? self.leftMoreButton : nil
        if let leftButton = leftButton {
            constraints.append(leftButton.fw.pinEdge(toSuperview: .left, inset: UIScreen.fw.safeAreaInsets.left + horizontalSpacing, autoScale: false))
            constraints.append(leftButton.fw.alignAxis(toSuperview: .centerY, autoScale: false))
            constraints.append(leftButton.fw.pinEdge(toSuperview: .top, inset: 0, relation: .greaterThanOrEqual, autoScale: false))
            constraints.append(leftButton.fw.pinEdge(toSuperview: .bottom, inset: 0, relation: .greaterThanOrEqual, autoScale: false))
            let buttonWidth = leftButton.frame.size.width > 0 ? leftButton.frame.size.width : leftButton.sizeThatFits(fitsSize).width
            leftWidth += UIScreen.fw.safeAreaInsets.left + horizontalSpacing + buttonWidth + buttonSpacing
        }
        if let leftButton = leftButton, let leftMoreButton = leftMoreButton {
            constraints.append(leftMoreButton.fw.pinEdge(.left, toEdge: .right, ofView: leftButton, offset: buttonSpacing, autoScale: false))
            constraints.append(leftMoreButton.fw.alignAxis(toSuperview: .centerY, autoScale: false))
            constraints.append(leftMoreButton.fw.pinEdge(toSuperview: .top, inset: 0, relation: .greaterThanOrEqual, autoScale: false))
            constraints.append(leftMoreButton.fw.pinEdge(toSuperview: .bottom, inset: 0, relation: .greaterThanOrEqual, autoScale: false))
            let buttonWidth = leftMoreButton.frame.size.width > 0 ? leftMoreButton.frame.size.width : leftMoreButton.sizeThatFits(fitsSize).width
            leftWidth += buttonWidth + buttonSpacing
        }
        
        var rightWidth: CGFloat = 0
        let rightButton = self.rightButton ?? self.rightMoreButton
        let rightMoreButton = self.rightButton != nil && self.rightMoreButton != nil ? self.rightMoreButton : nil
        if let rightButton = rightButton {
            constraints.append(rightButton.fw.pinEdge(toSuperview: .right, inset: horizontalSpacing + UIScreen.fw.safeAreaInsets.right, autoScale: false))
            constraints.append(rightButton.fw.alignAxis(toSuperview: .centerY, autoScale: false))
            constraints.append(rightButton.fw.pinEdge(toSuperview: .top, inset: 0, relation: .greaterThanOrEqual, autoScale: false))
            constraints.append(rightButton.fw.pinEdge(toSuperview: .bottom, inset: 0, relation: .greaterThanOrEqual, autoScale: false))
            let buttonWidth = rightButton.frame.size.width > 0 ? rightButton.frame.size.width : rightButton.sizeThatFits(fitsSize).width
            rightWidth += buttonSpacing + buttonWidth + horizontalSpacing + UIScreen.fw.safeAreaInsets.right
        }
        if let rightButton = rightButton, let rightMoreButton = rightMoreButton {
            constraints.append(rightMoreButton.fw.pinEdge(.right, toEdge: .left, ofView: rightButton, offset: -buttonSpacing, autoScale: false))
            constraints.append(rightMoreButton.fw.alignAxis(toSuperview: .centerY, autoScale: false))
            constraints.append(rightMoreButton.fw.pinEdge(toSuperview: .top, inset: 0, relation: .greaterThanOrEqual, autoScale: false))
            constraints.append(rightMoreButton.fw.pinEdge(toSuperview: .bottom, inset: 0, relation: .greaterThanOrEqual, autoScale: false))
            let buttonWidth = rightMoreButton.frame.size.width > 0 ? rightMoreButton.frame.size.width : rightMoreButton.sizeThatFits(fitsSize).width
            rightWidth += buttonSpacing + buttonWidth
        }
        
        if let centerButton = self.centerButton {
            if !alignmentLeft {
                constraints.append(centerButton.fw.alignAxis(toSuperview: .centerX, autoScale: false))
            }
            constraints.append(centerButton.fw.alignAxis(toSuperview: .centerY, autoScale: false))
            constraints.append(centerButton.fw.pinEdge(toSuperview: .top, inset: 0, relation: .greaterThanOrEqual, autoScale: false))
            constraints.append(centerButton.fw.pinEdge(toSuperview: .bottom, inset: 0, relation: .greaterThanOrEqual, autoScale: false))
            constraints.append(centerButton.fw.pinEdge(toSuperview: .left, inset: leftWidth, relation: .greaterThanOrEqual, autoScale: false))
            constraints.append(centerButton.fw.pinEdge(toSuperview: .right, inset: rightWidth, relation: .greaterThanOrEqual, autoScale: false))
        }
        subviewConstraints = constraints
    }
    
}

// MARK: - ToolbarTitleView
/// 自定义titleView事件代理
@objc public protocol ToolbarTitleViewDelegate {
    /// 点击 titleView 后的回调，只需设置 titleView.isUserInteractionEnabled = true 后即可使用
    /// - Parameters:
    ///   - titleView: 被点击的 titleView
    ///   - isActive: titleView 是否处于活跃状态
    @objc optional func didTouchTitleView(_ titleView: ToolbarTitleView, isActive: Bool)
    
    /// titleView 的活跃状态发生变化时会被调用，也即 [titleView setActive:] 被调用时。
    /// - Parameters:
    ///   - active: 是否处于活跃状态
    ///   - titleView: 变换状态的 titleView
    @objc optional func didChangedActive(_ active: Bool, for titleView: ToolbarTitleView)
}

/// 自定义titleView布局方式，默认水平布局
public enum ToolbarTitleViewStyle: Int {
    case horizontal = 0
    case vertical
}

/// 可作为导航栏标题控件，使用非等比例缩放布局，通过 navigationItem.titleView 来设置。也可当成单独的标题组件，脱离 UIViewController 使用
///
/// 默认情况下 titleView 是不支持点击的，如需点击，请把 `userInteractionEnabled` 设为 `YES`
/// [QMUI_iOS](https://github.com/Tencent/QMUI_iOS)
open class ToolbarTitleView: UIControl, TitleViewProtocol {
    
    /// 事件代理
    open weak var delegate: ToolbarTitleViewDelegate?
    
    /// 标题栏样式
    open var style: ToolbarTitleViewStyle = .horizontal {
        didSet {
            if style == .vertical {
                titleLabel.font = verticalTitleFont
                subtitleLabel.font = verticalSubtitleFont
            } else {
                titleLabel.font = horizontalTitleFont
                subtitleLabel.font = horizontalSubtitleFont
            }
            refreshLayout()
        }
    }
    
    /// 标题栏是否是激活状态，主要针对accessoryImage生效
    open var isActive: Bool {
        get { return _isActive }
        set { setActive(newValue, animated: false) }
    }
    private var _isActive: Bool = false
    
    /// 标题栏最大显示宽度，默认不限制
    open var maximumWidth: CGFloat = CGFloat.greatestFiniteMagnitude {
        didSet { refreshLayout() }
    }
    
    /// 标题文字
    open var title: String? {
        didSet {
            titleLabel.text = title
            refreshLayout()
        }
    }
    
    /// 副标题
    open var subtitle: String? {
        didSet {
            subtitleLabel.text = subtitle
            refreshLayout()
        }
    }
    
    /// 是否适应tintColor变化，影响titleLabel、subtitleLabel、loadingView，默认YES
    open var adjustsTintColor: Bool = true
    
    /// 水平布局下的标题字体，默认为 加粗17
    open var horizontalTitleFont: UIFont? = UIFont.boldSystemFont(ofSize: 17) {
        didSet {
            if style == .horizontal {
                titleLabel.font = horizontalTitleFont
                refreshLayout()
            }
        }
    }
    
    /// 水平布局下的副标题的字体，默认为 加粗17
    open var horizontalSubtitleFont: UIFont? = UIFont.boldSystemFont(ofSize: 17) {
        didSet {
            if style == .horizontal {
                subtitleLabel.font = horizontalSubtitleFont
                refreshLayout()
            }
        }
    }
    
    /// 垂直布局下的标题字体，默认为 15
    open var verticalTitleFont: UIFont? = UIFont.systemFont(ofSize: 15) {
        didSet {
            if style == .vertical {
                titleLabel.font = verticalTitleFont
                refreshLayout()
            }
        }
    }
    
    /// 垂直布局下的副标题字体，默认为 12
    open var verticalSubtitleFont: UIFont? = UIFont.systemFont(ofSize: 12, weight: .light) {
        didSet {
            if style == .vertical {
                subtitleLabel.font = verticalSubtitleFont
                refreshLayout()
            }
        }
    }
    
    /// 标题的上下左右间距，标题不显示时不参与计算大小，默认为 UIEdgeInsets.zero
    open var titleEdgeInsets: UIEdgeInsets = .zero {
        didSet { refreshLayout() }
    }
    
    /// 副标题的上下左右间距，副标题不显示时不参与计算大小，默认为 UIEdgeInsets.zero
    open var subtitleEdgeInsets: UIEdgeInsets = .zero {
        didSet { refreshLayout() }
    }
    
    /// 标题栏左侧loading视图，可自定义，开启loading后才存在
    open var loadingView: (UIView & IndicatorViewPlugin)? {
        didSet {
            if oldValue != nil {
                oldValue?.stopAnimating()
                oldValue?.removeFromSuperview()
            }
            if let loadingView = loadingView {
                loadingView.indicatorSize = loadingViewSize
                loadingView.indicatorColor = tintColor
                loadingView.stopAnimating()
                contentView.addSubview(loadingView)
            }
            refreshLayout()
        }
    }
    
    /// 是否显示loading视图，开启后才会显示，默认NO
    open var showsLoadingView: Bool = false {
        didSet {
            if showsLoadingView {
                if loadingView == nil {
                    loadingView = UIActivityIndicatorView.fw.indicatorView(color: nil)
                } else {
                    refreshLayout()
                }
            } else {
                if loadingView != nil {
                    loadingView = nil
                } else {
                    refreshLayout()
                }
            }
        }
    }
    
    /// 是否隐藏loading，开启之后生效，默认YES
    open var loadingViewHidden: Bool = true {
        didSet {
            if showsLoadingView {
                if loadingViewHidden {
                    loadingView?.stopAnimating()
                } else {
                    loadingView?.startAnimating()
                }
            }
            refreshLayout()
        }
    }
    
    /// 标题右侧是否显示和左侧loading一样的占位空间，默认YES
    open var showsLoadingPlaceholder: Bool = true {
        didSet { refreshLayout() }
    }
    
    /// loading视图指定大小，默认(18, 18)
    open var loadingViewSize: CGSize = CGSize(width: 18, height: 18)
    
    /// 指定loading右侧间距，默认3
    open var loadingViewSpacing: CGFloat = 3 {
        didSet { refreshLayout() }
    }
    
    /// 自定义accessoryView，设置后accessoryImage无效，默认nil
    open var accessoryView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let accessoryView = accessoryView {
                accessoryImage = nil
                accessoryView.sizeToFit()
                contentView.addSubview(accessoryView)
            }
            refreshLayout()
        }
    }
    
    /// 自定义accessoryImage，accessoryView为空时才生效，默认nil
    open var accessoryImage: UIImage? {
        get {
            return _accessoryImage
        }
        set {
            let accessoryImage = accessoryView != nil ? nil : newValue
            _accessoryImage = accessoryImage
            
            if accessoryImage == nil {
                accessoryImageView?.removeFromSuperview()
                accessoryImageView = nil
                refreshLayout()
                return
            }
            
            if accessoryImageView == nil {
                accessoryImageView = UIImageView()
                accessoryImageView?.contentMode = .center
            }
            accessoryImageView?.image = accessoryImage
            accessoryImageView?.sizeToFit()
            if let accessoryImageView = accessoryImageView, accessoryImageView.superview == nil {
                contentView.addSubview(accessoryImageView)
            }
            refreshLayout()
        }
    }
    private var _accessoryImage: UIImage?
    
    /// 指定accessoryView偏移位置，默认(3, 0)
    open var accessoryViewOffset: CGPoint = CGPoint(x: 3, y: 0) {
        didSet { refreshLayout() }
    }
    
    /// 值为YES则title居中，`accessoryView`放在title的左边或右边；如果为NO，`accessoryView`和title整体居中；默认NO
    open var showsAccessoryPlaceholder: Bool = false {
        didSet { refreshLayout() }
    }
    
    /// 同 accessoryView，用于 subtitle 的 AccessoryView，仅Vertical样式生效
    open var subAccessoryView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let subAccessoryView = subAccessoryView {
                subAccessoryView.sizeToFit()
                contentView.addSubview(subAccessoryView)
            }
            refreshLayout()
        }
    }
    
    /// 指定subAccessoryView偏移位置，默认(3, 0)
    open var subAccessoryViewOffset: CGPoint = CGPoint(x: 3, y: 0) {
        didSet { refreshLayout() }
    }
    
    /// 同 showsAccessoryPlaceholder，用于 subtitle
    open var showsSubAccessoryPlaceholder: Bool = false {
        didSet { refreshLayout() }
    }
    
    /// 整个titleView是否左对齐，需结合isExpandedSize使用，默认NO居中对齐
    open var alignmentLeft: Bool = false {
        didSet {
            titleLabel.textAlignment = alignmentLeft ? .left : .center
            subtitleLabel.textAlignment = alignmentLeft ? .left : .center
            refreshLayout()
        }
    }
    
    /// 是否使用扩张尺寸，开启后会自动撑开到最大尺寸，默认NO
    open var isExpandedSize: Bool = false {
        didSet { refreshLayout() }
    }
    
    /// 当titleView用于navigationBar且左对齐时，指定titleView离左侧的最小距离，默认为16同系统
    open var minimumLeftMargin: CGFloat = 16 {
        didSet { refreshLayout() }
    }
    
    /// 标题标签
    open lazy var titleLabel: UILabel = {
        let result = UILabel()
        result.textAlignment = .center
        result.lineBreakMode = .byTruncatingTail
        result.accessibilityTraits = result.accessibilityTraits.union(.header)
        result.font = style == .horizontal ? horizontalTitleFont : verticalTitleFont
        return result
    }()
    
    /// 副标题标签
    open lazy var subtitleLabel: UILabel = {
        let result = UILabel()
        result.textAlignment = .center
        result.lineBreakMode = .byTruncatingTail
        result.accessibilityTraits = result.accessibilityTraits.union(.header)
        result.font = style == .horizontal ? horizontalSubtitleFont : verticalSubtitleFont
        return result
    }()
    
    private lazy var contentView: UIView = {
        let result = UIView()
        result.isUserInteractionEnabled = false
        return result
    }()
    
    private var titleLabelSize: CGSize = .zero
    private var subtitleLabelSize: CGSize = .zero
    private var accessoryImageView: UIImageView?
    
    /// 指定样式初始化
    public init(style: ToolbarTitleViewStyle) {
        super.init(frame: .zero)
        self.style = style
        didInitialize()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        didInitialize()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        didInitialize()
    }
    
    private func didInitialize() {
        addTarget(self, action: #selector(titleViewTouched), for: .touchUpInside)
        
        addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        
        isUserInteractionEnabled = false
        contentHorizontalAlignment = .center
    }
    
    open override var description: String {
        return String(format: "%@, title = %@, subtitle = %@", super.description, title ?? "", subtitle ?? "")
    }
    
    open override var contentHorizontalAlignment: UIControl.ContentHorizontalAlignment {
        get {
            super.contentHorizontalAlignment
        }
        set {
            super.contentHorizontalAlignment = newValue
            refreshLayout()
        }
    }
    
    open override var isHighlighted: Bool {
        get {
            super.isHighlighted
        }
        set {
            super.isHighlighted = newValue
            alpha = isHighlighted ? 0.5 : 1.0
        }
    }
    
    open override func setNeedsLayout() {
        updateTitleLabelSize()
        updateSubtitleLabelSize()
        updateSubAccessoryViewHidden()
        super.setNeedsLayout()
    }
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        var resultSize = contentSize
        if isExpandedSize {
            resultSize.width = min(UIScreen.main.bounds.width, maximumWidth)
        } else {
            resultSize.width = min(resultSize.width, maximumWidth)
        }
        return resultSize
    }
    
    open override var intrinsicContentSize: CGSize {
        if isExpandedSize {
            return UIView.layoutFittingExpandedSize
        } else {
            return sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        }
    }
    
    open override func tintColorDidChange() {
        super.tintColorDidChange()
        
        if adjustsTintColor {
            titleLabel.textColor = tintColor
            subtitleLabel.textColor = tintColor
            loadingView?.indicatorColor = tintColor
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size.width <= 0 || bounds.size.height <= 0 { return }
        contentView.frame = bounds
        
        let alignLeft = contentHorizontalAlignment == .left
        let alignRight = contentHorizontalAlignment == .right
        let maxSize = bounds.size
        var contentSize = self.contentSize
        contentSize.width = min(maxSize.width, contentSize.width)
        contentSize.height = min(maxSize.height, contentSize.height)
        
        var contentOffsetLeft = (maxSize.width - contentSize.width) / 2.0
        if alignmentLeft {
            contentOffsetLeft = 0
            // 处理navigationBar左侧按钮和标题视图位置，和系统一致
            if let navigationBar = searchNavigationBar(self) {
                let convertFrame = superview?.convert(frame, to: navigationBar) ?? .zero
                if convertFrame.minX < minimumLeftMargin {
                    contentOffsetLeft = minimumLeftMargin - convertFrame.minX
                }
            }
        }
        let contentOffsetRight = contentOffsetLeft
        
        let loadingViewSpace = loadingViewSpacingSize.width
        let accessoryView = self.accessoryView ?? self.accessoryImageView
        let accessoryViewSpace = accessorySpacingSize.width
        let isTitleLabelShowing = (titleLabel.text?.count ?? 0) > 0
        let isSubtitleLabelShowing = (subtitleLabel.text?.count ?? 0) > 0
        let isSubAccessoryViewShowing = isSubtitleLabelShowing && subAccessoryView != nil && !(subAccessoryView?.isHidden ?? false)
        let titleEdgeInsets = titleEdgeInsetsIfShowingTitleLabel
        let subtitleEdgeInsets = subtitleEdgeInsetsIfShowingSubtitleLabel
        
        if style == .vertical {
            let firstLineWidth = firstLineWidthInVerticalStyle
            var firstLineMinX: CGFloat = 0
            var firstLineMaxX: CGFloat = 0
            if alignLeft {
                firstLineMinX = contentOffsetLeft
            } else if alignRight {
                firstLineMinX = max(contentOffsetLeft, contentOffsetLeft + contentSize.width - firstLineWidth)
            } else {
                firstLineMinX = contentOffsetLeft + max(0, (contentSize.width - firstLineWidth) / 2.0)
            }
            firstLineMaxX = firstLineMinX + min(firstLineWidth, contentSize.width) - (showsLoadingPlaceholder ? loadingViewSpacingSize.width : 0)
            firstLineMinX += showsAccessoryPlaceholder ? accessoryViewSpace : 0
            
            if let loadingView = loadingView, (showsLoadingPlaceholder || !loadingViewHidden) {
                var loadingFrame = loadingView.frame
                loadingFrame.origin.x = firstLineMinX
                loadingFrame.origin.y = (titleLabelSize.height - loadingViewSize.height) / 2.0 + titleEdgeInsets.top
                loadingView.frame = loadingFrame
                firstLineMinX = loadingView.frame.maxX + loadingViewSpacing
            }
            
            if let accessoryView = accessoryView {
                var accessoryFrame = accessoryView.frame
                accessoryFrame.origin.x = firstLineMaxX - accessoryView.frame.width
                accessoryFrame.origin.y = (titleLabelSize.height - accessoryView.frame.height) / 2.0 + titleEdgeInsets.top + accessoryViewOffset.y
                accessoryView.frame = accessoryFrame
                firstLineMaxX = accessoryView.frame.minX - accessoryViewOffset.x
            }
            
            if isTitleLabelShowing {
                firstLineMinX += titleEdgeInsets.left
                firstLineMaxX -= titleEdgeInsets.right
                titleLabel.frame = CGRect(x: firstLineMinX, y: titleEdgeInsets.top, width: firstLineMaxX - firstLineMinX, height: titleLabelSize.height)
            } else {
                titleLabel.frame = CGRect.zero
            }
            
            if isSubtitleLabelShowing {
                let secondLineWidth = secondLineWidthInVerticalStyle
                var secondLineMinX: CGFloat = 0
                var secondLineMaxX: CGFloat = 0
                let secondLineMinY = subtitleEdgeInsets.top + (isTitleLabelShowing ? titleLabel.frame.maxY + titleEdgeInsets.bottom : 0)
                if alignLeft {
                    secondLineMinX = contentOffsetLeft
                } else if alignRight {
                    secondLineMinX = max(contentOffsetLeft, contentOffsetLeft + contentSize.width - secondLineWidth)
                } else {
                    secondLineMinX = contentOffsetLeft + max(0, (contentSize.width - secondLineWidth) / 2.0)
                }
                secondLineMaxX = secondLineMinX + min(secondLineWidth, contentSize.width)
                secondLineMinX += showsSubAccessoryPlaceholder ? subAccessorySpacingSize.width : 0
                
                if isSubAccessoryViewShowing, let subAccessoryView = subAccessoryView {
                    var subFrame = subAccessoryView.frame
                    subFrame.origin.x = secondLineMaxX - subAccessoryView.frame.width
                    subFrame.origin.y = secondLineMinY + (subtitleLabelSize.height - subAccessoryView.frame.height) / 2.0 + subAccessoryViewOffset.y
                    subAccessoryView.frame = subFrame
                    secondLineMaxX = subAccessoryView.frame.minX - subAccessoryViewOffset.x
                }
                subtitleLabel.frame = CGRect(x: secondLineMinX, y: secondLineMinY, width: secondLineMaxX - secondLineMinX, height: subtitleLabelSize.height)
            } else {
                subtitleLabel.frame = CGRect.zero
            }
        } else {
            var minX = contentOffsetLeft + (showsAccessoryPlaceholder ? accessoryViewSpace : 0)
            var maxX = maxSize.width - contentOffsetRight - (showsLoadingPlaceholder ? loadingViewSpace : 0)
            
            if let loadingView = loadingView, (showsLoadingPlaceholder || !loadingViewHidden) {
                var loadingFrame = loadingView.frame
                loadingFrame.origin.x = minX
                loadingFrame.origin.y = (maxSize.height - loadingViewSize.height) / 2.0
                loadingView.frame = loadingFrame
                minX = loadingView.frame.maxX + loadingViewSpacing
            }
            
            if let accessoryView = accessoryView {
                var accessoryFrame = accessoryView.frame
                accessoryFrame.origin.x = maxX - accessoryView.bounds.width
                accessoryFrame.origin.y = (maxSize.height - accessoryView.bounds.height) / 2.0 + accessoryViewOffset.y
                accessoryView.frame = accessoryFrame
                maxX = accessoryView.frame.minX - accessoryViewOffset.x
            }
            
            if isSubtitleLabelShowing {
                maxX -= subtitleEdgeInsets.right
                let shouldSubtitleLabelCenterVertically = subtitleLabelSize.height + (subtitleEdgeInsets.top + subtitleEdgeInsets.bottom) < contentSize.height
                let subtitleMinY = shouldSubtitleLabelCenterVertically ? (maxSize.height - subtitleLabelSize.height) / 2.0 + subtitleEdgeInsets.top - subtitleEdgeInsets.bottom : subtitleEdgeInsets.top
                subtitleLabel.frame = CGRect(x: max(minX + subtitleEdgeInsets.left, maxX - subtitleLabelSize.width), y: subtitleMinY, width: min(subtitleLabelSize.width, maxX - minX - subtitleEdgeInsets.left), height: subtitleLabelSize.height)
                maxX = subtitleLabel.frame.minX - subtitleEdgeInsets.left
            } else {
                subtitleLabel.frame = CGRect.zero
            }
            
            if isTitleLabelShowing {
                minX += titleEdgeInsets.left
                maxX -= titleEdgeInsets.right
                let shouldTitleLabelCenterVertically = titleLabelSize.height + (titleEdgeInsets.top + titleEdgeInsets.bottom) < contentSize.height
                let titleLabelMinY = shouldTitleLabelCenterVertically ? (maxSize.height - titleLabelSize.height) / 2.0 + titleEdgeInsets.top - titleEdgeInsets.bottom : titleEdgeInsets.top
                titleLabel.frame = CGRect(x: minX, y: titleLabelMinY, width: maxX - minX, height: titleLabelSize.height)
            } else {
                titleLabel.frame = CGRect.zero
            }
        }
        
        var offsetY: CGFloat = (maxSize.height - contentSize.height) / 2.0
        if contentVerticalAlignment == .top {
            offsetY = 0
        } else if contentVerticalAlignment == .bottom {
            offsetY = maxSize.height - contentSize.height
        }
        subviews.forEach { obj in
            if !CGRectIsEmpty(obj.frame) {
                var objFrame = obj.frame
                objFrame.origin.y = obj.frame.minY + offsetY
                obj.frame = objFrame
            }
        }
    }
    
    /// 动画方式设置标题栏是否激活，主要针对accessoryImage生效
    open func setActive(_ active: Bool, animated: Bool) {
        guard _isActive != active else { return }
        _isActive = active
        delegate?.didChangedActive?(active, for: self)
        if accessoryImage != nil {
            let rotationDegree: CGFloat = active ? -180 : -360
            UIView.animate(withDuration: animated ? 0.25 : 0, delay: 0, options: .init(rawValue: 8<<16)) {
                self.accessoryImageView?.transform = .init(rotationAngle: CGFloat.pi * rotationDegree / 180.0)
            }
        }
    }
    
    private var loadingViewSpacingSize: CGSize {
        if showsLoadingView {
            return CGSize(width: loadingViewSize.width + loadingViewSpacing, height: loadingViewSize.height)
        }
        return .zero
    }
    
    private var loadingViewSpacingSizeIfNeedsPlaceholder: CGSize {
        return CGSize(width: loadingViewSpacingSize.width * (showsLoadingPlaceholder ? 2 : 1), height: loadingViewSpacingSize.height)
    }
    
    private var accessorySpacingSize: CGSize {
        if let view = accessoryView ?? accessoryImageView {
            return CGSize(width: view.bounds.width + accessoryViewOffset.x, height: view.bounds.height)
        }
        return .zero
    }
    
    private var subAccessorySpacingSize: CGSize {
        if let view = subAccessoryView {
            return CGSize(width: view.bounds.width + subAccessoryViewOffset.x, height: view.bounds.height)
        }
        return .zero
    }
    
    private var accessorySpacingSizeIfNeedesPlaceholder: CGSize {
        return CGSize(width: accessorySpacingSize.width * (showsAccessoryPlaceholder ? 2 : 1), height: accessorySpacingSize.height)
    }
    
    private var subAccessorySpacingSizeIfNeedesPlaceholder: CGSize {
        return CGSize(width: subAccessorySpacingSize.width * (showsSubAccessoryPlaceholder ? 2 : 1), height: subAccessorySpacingSize.height)
    }
    
    private var titleEdgeInsetsIfShowingTitleLabel: UIEdgeInsets {
        return (titleLabelSize.width <= 0 || titleLabelSize.height <= 0) ? .zero : titleEdgeInsets
    }
    
    private var subtitleEdgeInsetsIfShowingSubtitleLabel: UIEdgeInsets {
        return (subtitleLabelSize.width <= 0 || subtitleLabelSize.height <= 0) ? .zero : subtitleEdgeInsets
    }
    
    private var firstLineWidthInVerticalStyle: CGFloat {
        var firstLineWidth: CGFloat = titleLabelSize.width + (titleEdgeInsetsIfShowingTitleLabel.left + titleEdgeInsetsIfShowingTitleLabel.right)
        firstLineWidth += loadingViewSpacingSizeIfNeedsPlaceholder.width
        firstLineWidth += accessorySpacingSizeIfNeedesPlaceholder.width
        return firstLineWidth
    }
    
    private var secondLineWidthInVerticalStyle: CGFloat {
        var secondLineWidth: CGFloat = subtitleLabelSize.width + (subtitleEdgeInsetsIfShowingSubtitleLabel.left + subtitleEdgeInsetsIfShowingSubtitleLabel.right)
        if subtitleLabelSize.width > 0, let subAccessoryView = subAccessoryView, !subAccessoryView.isHidden {
            secondLineWidth += subAccessorySpacingSizeIfNeedesPlaceholder.width
        }
        return secondLineWidth
    }
    
    private var contentSize: CGSize {
        if style == .vertical {
            var size = CGSize.zero
            let firstLineWidth = firstLineWidthInVerticalStyle
            let secondLineWidth = secondLineWidthInVerticalStyle
            size.width = max(firstLineWidth, secondLineWidth)
            size.height = titleLabelSize.height + (titleEdgeInsetsIfShowingTitleLabel.top + titleEdgeInsetsIfShowingTitleLabel.bottom) + subtitleLabelSize.height + (subtitleEdgeInsetsIfShowingSubtitleLabel.top + subtitleEdgeInsetsIfShowingSubtitleLabel.bottom)
            return CGSize(width: UIScreen.fw.flatValue(size.width), height: UIScreen.fw.flatValue(size.height))
        } else {
            var size = CGSize.zero
            size.width = titleLabelSize.width + (titleEdgeInsetsIfShowingTitleLabel.left + titleEdgeInsetsIfShowingTitleLabel.right) + subtitleLabelSize.width + (subtitleEdgeInsetsIfShowingSubtitleLabel.left + subtitleEdgeInsetsIfShowingSubtitleLabel.right)
            size.width += loadingViewSpacingSizeIfNeedsPlaceholder.width + accessorySpacingSizeIfNeedesPlaceholder.width
            size.height = max(titleLabelSize.height + (titleEdgeInsetsIfShowingTitleLabel.top + titleEdgeInsetsIfShowingTitleLabel.bottom), subtitleLabelSize.height + (subtitleEdgeInsetsIfShowingSubtitleLabel.top + subtitleEdgeInsetsIfShowingSubtitleLabel.bottom))
            size.height = max(size.height, loadingViewSpacingSizeIfNeedsPlaceholder.height)
            size.height = max(size.height, accessorySpacingSizeIfNeedesPlaceholder.height)
            return CGSize(width: UIScreen.fw.flatValue(size.width), height: UIScreen.fw.flatValue(size.height))
        }
    }
    
    private func refreshLayout() {
        let navigationBar = searchNavigationBar(self)
        navigationBar?.setNeedsLayout()
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }
    
    private func searchNavigationBar(_ child: UIView) -> UINavigationBar? {
        guard let parent = child.superview else { return nil }
        if let navigationBar = parent as? UINavigationBar { return navigationBar }
        return searchNavigationBar(parent)
    }
    
    private func updateTitleLabelSize() {
        if (titleLabel.text?.count ?? 0) > 0 {
            let size = titleLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
            titleLabelSize = CGSize(width: ceil(size.width), height: ceil(size.height))
        } else {
            titleLabelSize = .zero
        }
    }
    
    private func updateSubtitleLabelSize() {
        if (subtitleLabel.text?.count ?? 0) > 0 {
            let size = subtitleLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
            subtitleLabelSize = CGSize(width: ceil(size.width), height: ceil(size.height))
        } else {
            subtitleLabelSize = .zero
        }
    }
    
    private func updateSubAccessoryViewHidden() {
        if subAccessoryView != nil && (subtitleLabel.text?.count ?? 0) > 0 && style == .vertical {
            subAccessoryView?.isHidden = false
        } else {
            subAccessoryView?.isHidden = true
        }
    }
    
    @objc private func titleViewTouched() {
        let active = !isActive
        delegate?.didTouchTitleView?(self, isActive: active)
        setActive(active, animated: true)
        refreshLayout()
    }
    
}

// MARK: - ToolbarButton
/// 自定义工具栏按钮，使用非等比例缩放布局，兼容系统customView方式和自定义方式
///
/// UIBarButtonItem自定义导航栏时最左和最右间距为16，系统导航栏时为8；
/// ToolbarButton作为customView使用时，会自动调整按钮内间距，和系统表现一致；
/// ToolbarButton自动适配横竖屏切换，竖屏时默认内间距{8, 8, 8, 8}，横屏时默认内间距{0,8,0,8}
open class ToolbarButton: UIButton {
    
    /// UIBarButtonItem默认都是跟随tintColor的，所以这里声明是否让图片也是用AlwaysTemplate模式，默认YES
    open var adjustsTintColor: Bool = true {
        didSet {
            guard adjustsTintColor != oldValue, currentImage != nil else { return }
            
            let states: [UIControl.State] = [.normal, .highlighted, .selected, .disabled]
            for state in states {
                guard let image = image(for: state) else { continue }
                
                if adjustsTintColor {
                    setImage(image, for: state)
                } else {
                    setImage(image.withRenderingMode(.alwaysOriginal), for: state)
                }
            }
        }
    }
    
    private var highlightedImage: UIImage?
    private var disabledImage: UIImage?
    private var isLandscape = false
    
    /// 指定标题初始化，自适应内边距，可自定义
    public convenience init(title: String?) {
        self.init(image: nil, title: title)
    }
    
    /// 指定图片和标题初始化，自适应内边距，可自定义
    public convenience init(image: UIImage?, title: String? = nil) {
        self.init(frame: .zero)
        setTitle(title, for: .normal)
        setImage(image, for: .normal)
        sizeToFit()
    }
    
    /// 指定对象初始化，支持UIImage|NSAttributedString|NSString(默认)，同时添加点击事件
    public convenience init(object: Any?, target: Any?, action: Selector?) {
        if let attributedString = object as? NSAttributedString {
            self.init(frame: .zero)
            setAttributedTitle(attributedString, for: .normal)
            sizeToFit()
        } else {
            self.init(image: object as? UIImage, title: object as? String)
        }
        if target != nil, let action = action {
            addTarget(target, action: action, for: .touchUpInside)
        }
    }
    
    /// 指定对象初始化，支持UIImage|NSString(默认)，同时添加点击句柄
    public convenience init(object: Any?, block: (@MainActor @Sendable (Any) -> Void)?) {
        if let attributedString = object as? NSAttributedString {
            self.init(frame: .zero)
            setAttributedTitle(attributedString, for: .normal)
            sizeToFit()
        } else {
            self.init(image: object as? UIImage, title: object as? String)
        }
        if let block = block {
            fw.addTouch(block: block)
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        didInitialize()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        didInitialize()
    }
    
    private func didInitialize() {
        titleLabel?.font = UIFont.systemFont(ofSize: 17)
        titleLabel?.backgroundColor = UIColor.clear
        titleLabel?.lineBreakMode = .byTruncatingTail
        contentMode = .center
        contentHorizontalAlignment = .center
        contentVerticalAlignment = .center
        adjustsImageWhenHighlighted = false
        adjustsImageWhenDisabled = false
        contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }
    
    open override func setImage(_ image: UIImage?, for state: UIControl.State) {
        var image = image
        if image != nil && adjustsTintColor {
            image = image?.withRenderingMode(.alwaysTemplate)
        }
        
        if let image = image, self.image(for: state) != image {
            if state == .normal {
                self.highlightedImage = image.fw.image(alpha: 0.2)?.withRenderingMode(image.renderingMode)
                setImage(self.highlightedImage, for: .highlighted)
                self.disabledImage = image.fw.image(alpha: 0.2)?.withRenderingMode(image.renderingMode)
                setImage(self.disabledImage, for: .disabled)
            } else {
                if image != self.highlightedImage && image != self.disabledImage {
                    if self.image(for: .highlighted) == self.highlightedImage && state != .highlighted {
                        setImage(nil, for: .highlighted)
                    }
                    if self.image(for: .disabled) == self.disabledImage && state != .disabled {
                        setImage(nil, for: .disabled)
                    }
                }
            }
        }
        
        super.setImage(image, for: state)
    }
    
    open override func tintColorDidChange() {
        super.tintColorDidChange()
        setTitleColor(tintColor, for: .normal)
        setTitleColor(tintColor?.withAlphaComponent(0.2), for: .highlighted)
        setTitleColor(tintColor?.withAlphaComponent(0.2), for: .disabled)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        // 横竖屏方向改变时才修改默认contentEdgeInsets，方便项目使用
        let isLandscape = UIDevice.fw.isLandscape
        if isLandscape != self.isLandscape {
            self.isLandscape = isLandscape
            var edgeInsets = self.contentEdgeInsets
            edgeInsets.top = isLandscape ? 0 : 8
            edgeInsets.bottom = isLandscape ? 0 : 8
            self.contentEdgeInsets = edgeInsets
        }
        
        // 处理navigationBar左侧第一个按钮和右侧第一个按钮位置，和系统一致
        guard let navigationBar = searchNavigationBar(self) else { return }
        
        let convertFrame = self.superview?.convert(self.frame, to: navigationBar) ?? .zero
        if convertFrame.minX == 16 {
            var edgeInsets = self.contentEdgeInsets
            edgeInsets.left = 0
            self.contentEdgeInsets = edgeInsets
        } else if convertFrame.maxX + 16 == navigationBar.bounds.width {
            var edgeInsets = self.contentEdgeInsets
            edgeInsets.right = 0
            self.contentEdgeInsets = edgeInsets
        }
    }
    
    private func searchNavigationBar(_ child: UIView) -> UINavigationBar? {
        guard let parent = child.superview else { return nil }
        if let navigationBar = parent as? UINavigationBar { return navigationBar }
        return searchNavigationBar(parent)
    }
    
}

// MARK: - ExpandedTitleView
/// 扩展titleView，可继承，用于navigationItem.titleView需要撑开的场景
///
/// 组件自动兼容各版本系统titleView左右间距(默认16)，具体差异如下：
/// iOS16+：系统titleView左右最小间距为16，组件默认处理为16
/// iOS15-：系统titleView左右最小间距为8，组件默认处理为16
/// 注意：扩展区域不可点击，如需点击，可使用isPenetrable实现
open class ExpandedTitleView: UIView {
    
    /// 指定内容视图并快速创建titleView
    open class func titleView(_ contentView: UIView) -> Self {
        let titleView = self.init()
        titleView.contentView = contentView
        return titleView
    }
    
    /// 指定并添加内容视图，使用非等比例缩放布局
    open weak var contentView: UIView? {
        didSet {
            guard contentView != oldValue else { return }
            oldValue?.removeFromSuperview()
            if let contentView = contentView, contentView.superview == nil {
                addSubview(contentView)
                contentView.fw.pinEdges(toSuperview: contentInset, autoScale: false)
                setNeedsLayout()
            }
        }
    }
    
    /// 导航栏内容间距，默认{0,16,0,16}，超出区域不可点击
    open var contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16) {
        didSet {
            if let contentView = contentView {
                contentView.fw.pinEdges(toSuperview: contentInset, autoScale: false)
                setNeedsLayout()
            }
        }
    }
    
    /// 内部最大适配间距，大于该间距无需处理，iOS16+系统默认16，iOS15-系统默认8，取较大值
    private var maximumFittingSpacing: CGFloat = 16
    
    /// 初始化，默认导航栏尺寸
    public required init() {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.fw.screenWidth, height: UIScreen.fw.navigationBarHeight))
    }
    
    /// 指定frame并初始化
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    /// 解码初始化，默认导航栏尺寸
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        frame = CGRect(x: 0, y: 0, width: UIScreen.fw.screenWidth, height: UIScreen.fw.navigationBarHeight)
    }
    
    open override var intrinsicContentSize: CGSize {
        return UIView.layoutFittingExpandedSize
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let navigationBar = searchNavigationBar(self) else { return }
        let contentFrame = convert(bounds, to: navigationBar)
        if contentFrame.width > navigationBar.frame.width { return }
        
        let leftSpacing = contentFrame.minX
        let rightSpacing = navigationBar.frame.width - contentFrame.maxX
        var inset = UIEdgeInsets(top: contentInset.top, left: 0, bottom: contentInset.bottom, right: 0)
        if leftSpacing >= 0 && leftSpacing <= maximumFittingSpacing {
            inset.left = contentInset.left - leftSpacing
        }
        if rightSpacing >= 0 && rightSpacing <= maximumFittingSpacing {
            inset.right = contentInset.right - rightSpacing
        }
        contentView?.fw.pinEdges(toSuperview: inset, autoScale: false)
    }
    
    private func searchNavigationBar(_ child: UIView) -> UINavigationBar? {
        guard let parent = child.superview else { return nil }
        if let navigationBar = parent as? UINavigationBar { return navigationBar }
        return searchNavigationBar(parent)
    }
    
}
