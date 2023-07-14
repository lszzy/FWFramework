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
        result.fw_autoScale = false
        return result
    }()
    
    /// 顶部视图，延迟加载
    open lazy var topView: UIView = {
        let result = UIView()
        result.clipsToBounds = true
        result.fw_autoScale = false
        addSubview(result)
        
        result.fw_pinHorizontal()
        result.fw_pinEdge(toSuperview: .top)
        result.fw_pinEdge(.bottom, toEdge: .top, ofView: menuView)
        return result
    }()
    
    /// 菜单视图，初始加载
    open lazy var menuView: ToolbarMenuView = {
        let result = ToolbarMenuView()
        result.equalWidth = (type == .tabBar)
        result.titleView = (type == .navBar) ? ToolbarTitleView() : nil
        result.fw_autoScale = false
        return result
    }()
    
    /// 底部视图，延迟加载
    open lazy var bottomView: UIView = {
        let result = UIView()
        result.clipsToBounds = true
        result.fw_autoScale = false
        addSubview(result)
        
        result.fw_pinHorizontal()
        result.fw_pinEdge(toSuperview: .bottom)
        result.fw_pinEdge(.top, toEdge: .bottom, ofView: menuView)
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
        backgroundView.fw_pinEdges()
        menuView.fw_pinHorizontal()
        menuView.fw_pinEdge(toSuperview: .top, inset: topHeight)
        menuView.fw_pinEdge(toSuperview: .bottom, inset: bottomHeight)
        menuView.fw_setDimension(.height, size: menuHeight)
    }
    
    private func updateHeight(_ isFirst: Bool) {
        switch type {
        case .navBar:
            topHeight = UIScreen.fw_statusBarHeight
            menuHeight = UIScreen.fw_navigationBarHeight
        case .tabBar:
            menuHeight = UIScreen.fw_tabBarHeight - UIScreen.fw_safeAreaInsets.bottom
            bottomHeight = UIScreen.fw_safeAreaInsets.bottom
        case .custom:
            if isFirst {
                menuHeight = 44
            }
        default:
            menuHeight = UIScreen.fw_toolBarHeight - UIScreen.fw_safeAreaInsets.bottom
            bottomHeight = UIScreen.fw_safeAreaInsets.bottom
        }
    }
    
    private func updateLayout(_ animated: Bool) {
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
        
        let isLandscape = UIApplication.shared.statusBarOrientation.isLandscape
        if isLandscape != self.isLandscape {
            self.isLandscape = isLandscape
            updateHeight(false)
        }
        updateLayout(false)
    }
    
    open override func updateConstraints() {
        super.updateConstraints()
        
        let toolbarHidden = self.isHidden || self.toolbarHidden
        menuView.fw_pinEdge(toSuperview: .top, inset: toolbarHidden || topHidden ? 0 : topHeight)
        menuView.fw_pinEdge(toSuperview: .bottom, inset: toolbarHidden || bottomHidden ? 0 : bottomHeight)
        menuView.fw_setDimension(.height, size: toolbarHidden || menuHidden ? 0 : menuHeight)
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
                contentView.fw_autoScale = false
                contentView.fw_pinEdges(toSuperview: contentInset)
                setNeedsLayout()
            }
        }
    }
    
    /// 导航栏内容间距，默认{0,16,0,16}，超出区域不可点击
    open var contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16) {
        didSet {
            if let contentView = contentView {
                contentView.fw_pinEdges(toSuperview: contentInset)
                setNeedsLayout()
            }
        }
    }
    
    /// 内部最大适配间距，大于该间距无需处理，iOS16+系统默认16，iOS15-系统默认8，取较大值
    private var maximumFittingSpacing: CGFloat = 16
    
    /// 初始化，默认导航栏尺寸
    public required init() {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.fw_screenWidth, height: UIScreen.fw_navigationBarHeight))
    }
    
    /// 指定frame并初始化
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    /// 解码初始化，默认导航栏尺寸
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        frame = CGRect(x: 0, y: 0, width: UIScreen.fw_screenWidth, height: UIScreen.fw_navigationBarHeight)
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
        contentView?.fw_pinEdges(toSuperview: inset)
    }
    
    private func searchNavigationBar(_ child: UIView) -> UINavigationBar? {
        guard let parent = child.superview else { return nil }
        if let navigationBar = parent as? UINavigationBar { return navigationBar }
        return searchNavigationBar(parent)
    }
    
}
