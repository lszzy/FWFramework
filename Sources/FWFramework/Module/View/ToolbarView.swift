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
        result.fw_autoScaleLayout = false
        return result
    }()
    
    /// 顶部视图，延迟加载
    open lazy var topView: UIView = {
        let result = UIView()
        result.clipsToBounds = true
        result.fw_autoScaleLayout = false
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
        result.fw_autoScaleLayout = false
        return result
    }()
    
    /// 底部视图，延迟加载
    open lazy var bottomView: UIView = {
        let result = UIView()
        result.clipsToBounds = true
        result.fw_autoScaleLayout = false
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
        
        let isLandscape = UIDevice.fw_isLandscape
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
                leftButton.fw_autoScaleLayout = false
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
                leftMoreButton.fw_autoScaleLayout = false
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
                centerButton.fw_autoScaleLayout = false
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
                rightMoreButton.fw_autoScaleLayout = false
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
                rightButton.fw_autoScaleLayout = false
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
        fw_autoScaleLayout = false
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        clipsToBounds = true
        fw_autoScaleLayout = false
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
                constraints.append(subviewButton.fw_pinEdge(toSuperview: .top, inset: 0, relation: verticalOverflow ? .lessThanOrEqual : .equal))
                constraints.append(subviewButton.fw_pinEdge(toSuperview: .bottom))
                if let previousButton = previousButton {
                    constraints.append(subviewButton.fw_pinEdge(.left, toEdge: .right, ofView: previousButton))
                    constraints.append(subviewButton.fw_matchDimension(.width, toDimension: .width, ofView: previousButton))
                } else {
                    constraints.append(subviewButton.fw_pinEdge(toSuperview: .left, inset: UIScreen.fw_safeAreaInsets.left))
                }
                previousButton = subviewButton
            }
            if let previousButton = previousButton {
                constraints.append(previousButton.fw_pinEdge(toSuperview: .right, inset: UIScreen.fw_safeAreaInsets.right))
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
            constraints.append(leftButton.fw_pinEdge(toSuperview: .left, inset: UIScreen.fw_safeAreaInsets.left + horizontalSpacing))
            constraints.append(leftButton.fw_alignAxis(toSuperview: .centerY))
            constraints.append(leftButton.fw_pinEdge(toSuperview: .top, inset: 0, relation: .greaterThanOrEqual))
            constraints.append(leftButton.fw_pinEdge(toSuperview: .bottom, inset: 0, relation: .greaterThanOrEqual))
            let buttonWidth = leftButton.frame.size.width > 0 ? leftButton.frame.size.width : leftButton.sizeThatFits(fitsSize).width
            leftWidth += UIScreen.fw_safeAreaInsets.left + horizontalSpacing + buttonWidth + buttonSpacing
        }
        if let leftButton = leftButton, let leftMoreButton = leftMoreButton {
            constraints.append(leftMoreButton.fw_pinEdge(.left, toEdge: .right, ofView: leftButton, offset: buttonSpacing))
            constraints.append(leftMoreButton.fw_alignAxis(toSuperview: .centerY))
            constraints.append(leftMoreButton.fw_pinEdge(toSuperview: .top, inset: 0, relation: .greaterThanOrEqual))
            constraints.append(leftMoreButton.fw_pinEdge(toSuperview: .bottom, inset: 0, relation: .greaterThanOrEqual))
            let buttonWidth = leftMoreButton.frame.size.width > 0 ? leftMoreButton.frame.size.width : leftMoreButton.sizeThatFits(fitsSize).width
            leftWidth += buttonWidth + buttonSpacing
        }
        
        var rightWidth: CGFloat = 0
        let rightButton = self.rightButton ?? self.rightMoreButton
        let rightMoreButton = self.rightButton != nil && self.rightMoreButton != nil ? self.rightMoreButton : nil
        if let rightButton = rightButton {
            constraints.append(rightButton.fw_pinEdge(toSuperview: .right, inset: horizontalSpacing + UIScreen.fw_safeAreaInsets.right))
            constraints.append(rightButton.fw_alignAxis(toSuperview: .centerY))
            constraints.append(rightButton.fw_pinEdge(toSuperview: .top, inset: 0, relation: .greaterThanOrEqual))
            constraints.append(rightButton.fw_pinEdge(toSuperview: .bottom, inset: 0, relation: .greaterThanOrEqual))
            let buttonWidth = rightButton.frame.size.width > 0 ? rightButton.frame.size.width : rightButton.sizeThatFits(fitsSize).width
            rightWidth += buttonSpacing + buttonWidth + horizontalSpacing + UIScreen.fw_safeAreaInsets.right
        }
        if let rightButton = rightButton, let rightMoreButton = rightMoreButton {
            constraints.append(rightMoreButton.fw_pinEdge(.right, toEdge: .left, ofView: rightButton, offset: -buttonSpacing))
            constraints.append(rightMoreButton.fw_alignAxis(toSuperview: .centerY))
            constraints.append(rightMoreButton.fw_pinEdge(toSuperview: .top, inset: 0, relation: .greaterThanOrEqual))
            constraints.append(rightMoreButton.fw_pinEdge(toSuperview: .bottom, inset: 0, relation: .greaterThanOrEqual))
            let buttonWidth = rightMoreButton.frame.size.width > 0 ? rightMoreButton.frame.size.width : rightMoreButton.sizeThatFits(fitsSize).width
            rightWidth += buttonSpacing + buttonWidth
        }
        
        if let centerButton = self.centerButton {
            if !alignmentLeft {
                constraints.append(centerButton.fw_alignAxis(toSuperview: .centerX))
            }
            constraints.append(centerButton.fw_alignAxis(toSuperview: .centerY))
            constraints.append(centerButton.fw_pinEdge(toSuperview: .top, inset: 0, relation: .greaterThanOrEqual))
            constraints.append(centerButton.fw_pinEdge(toSuperview: .bottom, inset: 0, relation: .greaterThanOrEqual))
            constraints.append(centerButton.fw_pinEdge(toSuperview: .left, inset: leftWidth, relation: .greaterThanOrEqual))
            constraints.append(centerButton.fw_pinEdge(toSuperview: .right, inset: rightWidth, relation: .greaterThanOrEqual))
        }
        subviewConstraints = constraints
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
            
            var states: [UIControl.State] = [.normal, .highlighted, .selected, .disabled]
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
    public convenience init(object: Any?, block: ((Any) -> Void)?) {
        if let attributedString = object as? NSAttributedString {
            self.init(frame: .zero)
            setAttributedTitle(attributedString, for: .normal)
            sizeToFit()
        } else {
            self.init(image: object as? UIImage, title: object as? String)
        }
        if let block = block {
            fw_addTouch(block: block)
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
                self.highlightedImage = image.fw_image(alpha: 0.2)?.withRenderingMode(image.renderingMode)
                setImage(self.highlightedImage, for: .highlighted)
                self.disabledImage = image.fw_image(alpha: 0.2)?.withRenderingMode(image.renderingMode)
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
        let isLandscape = UIDevice.fw_isLandscape
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
                contentView.fw_autoScaleLayout = false
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
