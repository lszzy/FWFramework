//
//  TabBarController.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - TabBarController
/// https://github.com/eggswift/ESTabBarController
open class TabBarController: UITabBarController, TabBarDelegate {
    /// 打印异常
    public static func printError(_ description: String) {
        #if DEBUG
        print("ERROR: FWTabBarController catch an error '\(description)' \n")
        #endif
    }

    /// 当前tabBarController是否存在"More"tab
    public static func isShowingMore(_ tabBarController: UITabBarController?) -> Bool {
        tabBarController?.moreNavigationController.parent != nil
    }

    /// Ignore next selection or not.
    fileprivate var ignoreNextSelection = false

    /// Should hijack select action or not.
    open var shouldHijackHandler: ((_ tabBarController: UITabBarController, _ viewController: UIViewController, _ index: Int) -> (Bool))?
    /// Hijack select action.
    open var didHijackHandler: ((_ tabBarController: UITabBarController, _ viewController: UIViewController, _ index: Int) -> Void)?

    /// Observer tabBarController's selectedViewController. change its selection when it will-set.
    override open var selectedViewController: UIViewController? {
        willSet {
            guard let newValue else {
                // if newValue == nil ...
                return
            }
            guard !ignoreNextSelection else {
                ignoreNextSelection = false
                return
            }
            guard let tabBar = tabBar as? TabBar, let items = tabBar.items, let index = viewControllers?.firstIndex(of: newValue) else {
                return
            }
            let value = (TabBarController.isShowingMore(self) && index > items.count - 1) ? items.count - 1 : index
            tabBar.select(itemAtIndex: value, animated: false)
        }
    }

    /// Observer tabBarController's selectedIndex. change its selection when it will-set.
    override open var selectedIndex: Int {
        willSet {
            guard !ignoreNextSelection else {
                ignoreNextSelection = false
                return
            }
            guard let tabBar = tabBar as? TabBar, let items = tabBar.items else {
                return
            }
            let value = (TabBarController.isShowingMore(self) && newValue > items.count - 1) ? items.count - 1 : newValue
            tabBar.select(itemAtIndex: value, animated: false)
        }
    }

    /// Customize set tabBar use KVC.
    override open func viewDidLoad() {
        super.viewDidLoad()
        let tabBar = { () -> TabBar in
            let tabBar = TabBar()
            tabBar.delegate = self
            tabBar.customDelegate = self
            tabBar.tabBarController = self
            return tabBar
        }()
        setValue(tabBar, forKey: "tabBar")
    }

    // MARK: - UITabBar delegate
    override open func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let idx = tabBar.items?.firstIndex(of: item) else {
            return
        }
        if idx == tabBar.items!.count - 1, TabBarController.isShowingMore(self) {
            ignoreNextSelection = true
            selectedViewController = moreNavigationController
            return
        }
        if let vc = viewControllers?[idx] {
            ignoreNextSelection = true
            selectedIndex = idx
            delegate?.tabBarController?(self, didSelect: vc)
        }
    }

    override open func tabBar(_ tabBar: UITabBar, willBeginCustomizing items: [UITabBarItem]) {
        if let tabBar = tabBar as? TabBar {
            tabBar.updateLayout()
        }
    }

    override open func tabBar(_ tabBar: UITabBar, didEndCustomizing items: [UITabBarItem], changed: Bool) {
        if let tabBar = tabBar as? TabBar {
            tabBar.updateLayout()
        }
    }

    // MARK: - FWTabBar delegate
    func tabBar(_ tabBar: UITabBar, shouldSelect item: UITabBarItem) -> Bool {
        if let idx = tabBar.items?.firstIndex(of: item), let vc = viewControllers?[idx] {
            return delegate?.tabBarController?(self, shouldSelect: vc) ?? true
        }
        return true
    }

    func tabBar(_ tabBar: UITabBar, shouldHijack item: UITabBarItem) -> Bool {
        if let idx = tabBar.items?.firstIndex(of: item), let vc = viewControllers?[idx] {
            return shouldHijackHandler?(self, vc, idx) ?? false
        }
        return false
    }

    func tabBar(_ tabBar: UITabBar, didHijack item: UITabBarItem) {
        if let idx = tabBar.items?.firstIndex(of: item), let vc = viewControllers?[idx] {
            didHijackHandler?(self, vc, idx)
        }
    }
}

// MARK: - TabBarItemPositioning
/// 对原生的UITabBarItemPositioning进行扩展，通过UITabBarItemPositioning设置时，系统会自动添加insets，这使得添加背景样式的需求变得不可能实现。TabBarItemPositioning完全支持原有的item Position 类型，除此之外还支持完全fill模式。
///
/// - automatic: UITabBarItemPositioning.automatic
/// - fill: UITabBarItemPositioning.fill
/// - centered: UITabBarItemPositioning.centered
/// - fillExcludeSeparator: 完全fill模式，布局不覆盖tabBar顶部分割线
/// - fillIncludeSeparator: 完全fill模式，布局覆盖tabBar顶部分割线
public enum TabBarItemPositioning: Int, Sendable {
    case automatic

    case fill

    case centered

    case fillExcludeSeparator

    case fillIncludeSeparator
}

// MARK: - TabBarDelegate
/// 对UITabBarDelegate进行扩展，以支持UITabBarControllerDelegate的相关方法桥接
@MainActor protocol TabBarDelegate: NSObjectProtocol {
    /// 当前item是否支持选中
    ///
    /// - Parameters:
    ///   - tabBar: tabBar
    ///   - item: 当前item
    /// - Returns: Bool
    func tabBar(_ tabBar: UITabBar, shouldSelect item: UITabBarItem) -> Bool

    /// 当前item是否需要被劫持
    ///
    /// - Parameters:
    ///   - tabBar: tabBar
    ///   - item: 当前item
    /// - Returns: Bool
    func tabBar(_ tabBar: UITabBar, shouldHijack item: UITabBarItem) -> Bool

    /// 当前item的点击被劫持
    ///
    /// - Parameters:
    ///   - tabBar: tabBar
    ///   - item: 当前item
    /// - Returns: Void
    func tabBar(_ tabBar: UITabBar, didHijack item: UITabBarItem)
}

// MARK: - TabBar
/// FWTabBar是高度自定义的UITabBar子类，通过添加UIControl的方式实现自定义tabBarItem的效果。目前支持tabBar的大部分属性的设置，例如delegate,items,selectedImge,itemPositioning,itemWidth,itemSpacing等，以后会更加细致的优化tabBar原有属性的设置效果。
open class TabBar: UITabBar {
    weak var customDelegate: TabBarDelegate?

    /// tabBar中items布局偏移量
    public var itemEdgeInsets = UIEdgeInsets.zero
    /// 是否设置为自定义布局方式，默认为空。如果为空，则通过itemPositioning属性来设置。如果不为空则忽略itemPositioning,所以当tabBar的itemCustomPositioning属性不为空时，如果想改变布局规则，请设置此属性而非itemPositioning。
    public var itemCustomPositioning: TabBarItemPositioning? {
        didSet {
            if let itemCustomPositioning {
                switch itemCustomPositioning {
                case .fill:
                    itemPositioning = .fill
                case .automatic:
                    itemPositioning = .automatic
                case .centered:
                    itemPositioning = .centered
                default:
                    break
                }
            }
            reload()
        }
    }

    /// tabBar自定义item的容器view
    var containers = [TabBarItemContainer]()
    /// 缓存当前tabBarController用来判断是否存在"More"Tab
    weak var tabBarController: UITabBarController?
    /// 自定义'More'按钮样式，继承自FWTabBarItemContentView
    open var moreContentView: TabBarItemContentView? = TabBarItemMoreContentView() {
        didSet { reload() }
    }

    override open var items: [UITabBarItem]? {
        didSet {
            reload()
        }
    }

    open var isEditing: Bool = false {
        didSet {
            if oldValue != isEditing {
                updateLayout()
            }
        }
    }

    override open func setItems(_ items: [UITabBarItem]?, animated: Bool) {
        super.setItems(items, animated: animated)
        reload()
    }

    override open func beginCustomizingItems(_ items: [UITabBarItem]) {
        TabBarController.printError("beginCustomizingItems(_:) is unsupported in FWTabBar.")
        super.beginCustomizingItems(items)
    }

    override open func endCustomizing(animated: Bool) -> Bool {
        TabBarController.printError("endCustomizing(_:) is unsupported in FWTabBar.")
        return super.endCustomizing(animated: animated)
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }

    override open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var b = super.point(inside: point, with: event)
        if !b {
            for container in containers {
                if container.point(inside: CGPoint(x: point.x - container.frame.origin.x, y: point.y - container.frame.origin.y), with: event) {
                    b = true
                    break
                }
            }
        }
        return b
    }
}

// MARK: - Layout
extension TabBar {
    func updateLayout() {
        guard let tabBarItems = items else {
            TabBarController.printError("empty items")
            return
        }

        let tabBarButtons = subviews.filter { subview -> Bool in
            if let cls = NSClassFromString("UITabBarButton") {
                return subview.isKind(of: cls)
            }
            return false
        }.sorted { subview1, subview2 -> Bool in
            return subview1.frame.origin.x < subview2.frame.origin.x
        }

        if isCustomizing {
            for (idx, _) in tabBarItems.enumerated() {
                tabBarButtons[idx].isHidden = false
                moreContentView?.isHidden = true
            }
            for (_, container) in containers.enumerated() {
                container.isHidden = true
            }
        } else {
            for (idx, item) in tabBarItems.enumerated() {
                if let _ = item as? TabBarItem {
                    tabBarButtons[idx].isHidden = true
                } else {
                    tabBarButtons[idx].isHidden = false
                }
                if isMoreItem(idx), let _ = moreContentView {
                    tabBarButtons[idx].isHidden = true
                }
            }
            for (_, container) in containers.enumerated() {
                container.isHidden = false
            }
        }

        var layoutBaseSystem = true
        if let itemCustomPositioning {
            switch itemCustomPositioning {
            case .fill, .automatic, .centered:
                break
            case .fillIncludeSeparator, .fillExcludeSeparator:
                layoutBaseSystem = false
            }
        }

        if layoutBaseSystem {
            // System itemPositioning
            for (idx, container) in containers.enumerated() {
                if !tabBarButtons[idx].frame.isEmpty {
                    container.frame = tabBarButtons[idx].frame
                }
            }
        } else {
            // Custom itemPositioning
            var x: CGFloat = itemEdgeInsets.left
            var y: CGFloat = itemEdgeInsets.top
            switch itemCustomPositioning! {
            case .fillExcludeSeparator:
                if y <= 0.0 {
                    y += 1.0
                }
            default:
                break
            }
            let width = bounds.size.width - itemEdgeInsets.left - itemEdgeInsets.right
            let height = bounds.size.height - y - itemEdgeInsets.bottom
            let eachWidth = itemWidth == 0.0 ? width / CGFloat(containers.count) : itemWidth
            let eachSpacing = itemSpacing == 0.0 ? 0.0 : itemSpacing

            for container in containers {
                container.frame = CGRect(x: x, y: y, width: eachWidth, height: height)
                x += eachWidth
                x += eachSpacing
            }
        }
    }
}

// MARK: - Action
extension TabBar {
    func isMoreItem(_ index: Int) -> Bool {
        TabBarController.isShowingMore(tabBarController) && (index == (items?.count ?? 0) - 1)
    }

    func removeAll() {
        for container in containers {
            container.removeFromSuperview()
        }
        containers.removeAll()
    }

    func reload() {
        removeAll()
        guard let tabBarItems = items else {
            TabBarController.printError("empty items")
            return
        }
        for (idx, item) in tabBarItems.enumerated() {
            let container = TabBarItemContainer(self, tag: 1000 + idx)
            addSubview(container)
            containers.append(container)

            if let item = item as? TabBarItem {
                container.addSubview(item.contentView)
            }
            if isMoreItem(idx), let moreContentView {
                container.addSubview(moreContentView)
            }
        }

        updateAccessibilityLabels()
        setNeedsLayout()
    }

    @objc func highlightAction(_ sender: AnyObject?) {
        guard let container = sender as? TabBarItemContainer else {
            return
        }
        let newIndex = max(0, container.tag - 1000)
        guard newIndex < items?.count ?? 0, let item = items?[newIndex], item.isEnabled == true else {
            return
        }

        if let item = item as? TabBarItem {
            item.contentView.highlight(animated: true, completion: nil)
        } else if isMoreItem(newIndex) {
            moreContentView?.highlight(animated: true, completion: nil)
        }
    }

    @objc func dehighlightAction(_ sender: AnyObject?) {
        guard let container = sender as? TabBarItemContainer else {
            return
        }
        let newIndex = max(0, container.tag - 1000)
        guard newIndex < items?.count ?? 0, let item = items?[newIndex], item.isEnabled == true else {
            return
        }

        if let item = item as? TabBarItem {
            item.contentView.dehighlight(animated: true, completion: nil)
        } else if isMoreItem(newIndex) {
            moreContentView?.dehighlight(animated: true, completion: nil)
        }
    }

    @objc func selectAction(_ sender: AnyObject?) {
        guard let container = sender as? TabBarItemContainer else {
            return
        }
        select(itemAtIndex: container.tag - 1000, animated: true)
    }

    @objc func select(itemAtIndex idx: Int, animated: Bool) {
        let newIndex = max(0, idx)
        let currentIndex = (selectedItem != nil) ? (items?.firstIndex(of: selectedItem!) ?? -1) : -1
        guard newIndex < items?.count ?? 0, let item = items?[newIndex], item.isEnabled == true else {
            return
        }

        if animated && ((customDelegate?.tabBar(self, shouldSelect: item) ?? true) == false) {
            return
        }

        if animated && ((customDelegate?.tabBar(self, shouldHijack: item) ?? false) == true) {
            customDelegate?.tabBar(self, didHijack: item)
            if animated {
                if let item = item as? TabBarItem {
                    item.contentView.select(animated: animated, completion: {
                        item.contentView.deselect(animated: false, completion: nil)
                    })
                } else if isMoreItem(newIndex) {
                    moreContentView?.select(animated: animated, completion: {
                        self.moreContentView?.deselect(animated: animated, completion: nil)
                    })
                }
            }
            return
        }

        if currentIndex != newIndex {
            if currentIndex != -1 && currentIndex < items?.count ?? 0 {
                if let currentItem = items?[currentIndex] as? TabBarItem {
                    currentItem.contentView.deselect(animated: animated, completion: nil)
                } else if isMoreItem(currentIndex) {
                    moreContentView?.deselect(animated: animated, completion: nil)
                }
            }
            if let item = item as? TabBarItem {
                item.contentView.select(animated: animated, completion: nil)
            } else if isMoreItem(newIndex) {
                moreContentView?.select(animated: animated, completion: nil)
            }
        } else if currentIndex == newIndex {
            if let item = item as? TabBarItem {
                item.contentView.reselect(animated: animated, completion: nil)
            } else if isMoreItem(newIndex) {
                moreContentView?.reselect(animated: animated, completion: nil)
            }

            if animated, let tabBarController {
                var navVC: UINavigationController?
                if let n = tabBarController.selectedViewController as? UINavigationController {
                    navVC = n
                } else if let n = tabBarController.selectedViewController?.navigationController {
                    navVC = n
                }

                if let navVC {
                    if navVC.viewControllers.contains(tabBarController) {
                        if navVC.viewControllers.count > 1 && navVC.viewControllers.last != tabBarController {
                            navVC.popToViewController(tabBarController, animated: true)
                        }
                    } else {
                        if navVC.viewControllers.count > 1 {
                            navVC.popToRootViewController(animated: animated)
                        }
                    }
                }
            }
        }

        if animated {
            delegate?.tabBar?(self, didSelect: item)
        }
        updateAccessibilityLabels()
    }

    func updateAccessibilityLabels() {
        guard let tabBarItems = items, tabBarItems.count == self.containers.count else {
            return
        }

        for (idx, item) in tabBarItems.enumerated() {
            let container = containers[idx]
            container.accessibilityIdentifier = item.accessibilityIdentifier
            container.accessibilityTraits = item.accessibilityTraits

            if item == selectedItem {
                container.accessibilityTraits = container.accessibilityTraits.union(.selected)
            }

            if let explicitLabel = item.accessibilityLabel {
                container.accessibilityLabel = explicitLabel
                container.accessibilityHint = item.accessibilityHint ?? container.accessibilityHint
            } else {
                var accessibilityTitle = "tabbarItem"
                if let item = item as? TabBarItem {
                    accessibilityTitle = item.accessibilityLabel ?? item.title ?? ""
                }
                if isMoreItem(idx) {
                    accessibilityTitle = FrameworkBundle.moreButton
                }
                container.accessibilityLabel = accessibilityTitle
            }
        }
    }
}

// MARK: - TabBarItem
/// FWTabBarItem inherits from UITabBarItem, the purpose is to provide UITabBarItem property settings for FWTabBarItemContentView.
/// Support most commonly used attributes, such as image, selectedImage, title, tag etc.
///
/// Unsupport properties:
/// MARK: UIBarItem properties
///     1. var landscapeImagePhone: UIImage?
///     2. var imageInsets: UIEdgeInsets
///     3. var landscapeImagePhoneInsets: UIEdgeInsets
///     4. func setTitleTextAttributes(_ attributes: [String : Any]?, for state: UIControlState)
///     5. func titleTextAttributes(for state: UIControlState) -> [String : Any]?
/// MARK: UITabBarItem properties
///     1. func setBadgeTextAttributes(_ textAttributes: [String : Any]?, for state: UIControlState)
///     2. func badgeTextAttributes(for state: UIControlState) -> [String : Any]?
open class TabBarItem: UITabBarItem {
    // MARK: UIView properties

    /// The receiver’s tag, an application-supplied integer that you can use to identify bar item objects in your application. default is `0`
    override open var tag: Int {
        didSet { contentView.tag = tag }
    }

    // MARK: UIBarItem properties

    /// A Boolean value indicating whether the item is enabled, default is `YES`.
    override open var isEnabled: Bool {
        didSet { contentView.enabled = isEnabled }
    }

    /// The title displayed on the item, default is `nil`
    override open var title: String? {
        didSet { contentView.title = title }
    }

    /// The image used to represent the item, default is `nil`
    override open var image: UIImage? {
        didSet { contentView.image = image }
    }

    /// The imageURL used to represent the item, default is `nil`
    open var imageURL: String? {
        didSet { contentView.imageURL = imageURL }
    }

    // MARK: UITabBarItem properties

    /// The image displayed when the tab bar item is selected, default is `nil`.
    override open var selectedImage: UIImage? {
        get { contentView.selectedImage }
        set(newValue) { contentView.selectedImage = newValue }
    }

    /// The imageURL displayed when the tab bar item is selected, default is `nil`.
    open var selectedImageURL: String? {
        get { contentView.selectedImageURL }
        set(newValue) { contentView.selectedImageURL = newValue }
    }

    /// Text that is displayed in the upper-right corner of the item with a surrounding red oval, default is `nil`.
    override open var badgeValue: String? {
        get { contentView.badgeValue }
        set(newValue) { contentView.badgeValue = newValue }
    }

    /// The offset to use to adjust the title position, default is `UIOffset.zero`.
    override open var titlePositionAdjustment: UIOffset {
        get { contentView.titlePositionAdjustment }
        set(newValue) { contentView.titlePositionAdjustment = newValue }
    }

    /// The background color to apply to the badge, make it available for iOS8.0 and later. If this item displays a badge, this color will be used for the badge's background. If set to nil, the default background color will be used instead.
    override open var badgeColor: UIColor? {
        get { contentView.badgeColor }
        set(newValue) { contentView.badgeColor = newValue }
    }

    // MARK: FWTabBarItem properties

    /// Customize content view, default is `TabBarItemContentView`
    open var contentView: TabBarItemContentView = .init() {
        didSet {
            contentView.updateLayout()
            contentView.updateDisplay()
        }
    }

    /// The unselected image is autogenerated from the image argument. The selected image is autogenerated from the selectedImage if provided and the image argument otherwise. To prevent system coloring, provide images with UIImageRenderingModeAlwaysOriginal (see UIImage.h)
    public init(_ contentView: TabBarItemContentView = TabBarItemContentView(), title: String? = nil, image: Any? = nil, selectedImage: Any? = nil, tag: Int = 0) {
        super.init()
        self.contentView = contentView
        self.contentView.title = title
        if let imageURL = image as? String {
            self.contentView.imageURL = imageURL
        } else {
            self.contentView.image = image as? UIImage
        }
        if let selectedImageURL = selectedImage as? String {
            self.contentView.selectedImageURL = selectedImageURL
        } else {
            self.contentView.selectedImage = selectedImage as? UIImage
        }
        self.contentView.tag = tag
    }

    override public init() {
        super.init()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

// MARK: - TabBarItemContainer
class TabBarItemContainer: UIControl {
    init(_ target: AnyObject?, tag: Int) {
        super.init(frame: CGRect.zero)
        self.tag = tag
        addTarget(target, action: #selector(TabBar.selectAction(_:)), for: .touchUpInside)
        addTarget(target, action: #selector(TabBar.highlightAction(_:)), for: .touchDown)
        addTarget(target, action: #selector(TabBar.highlightAction(_:)), for: .touchDragEnter)
        addTarget(target, action: #selector(TabBar.dehighlightAction(_:)), for: .touchDragExit)
        backgroundColor = .clear
        isAccessibilityElement = true
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        for subview in subviews {
            if let subview = subview as? TabBarItemContentView {
                subview.frame = CGRect(x: subview.insets.left, y: subview.insets.top, width: bounds.size.width - subview.insets.left - subview.insets.right, height: bounds.size.height - subview.insets.top - subview.insets.bottom)
                subview.updateLayout()
            }
        }
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var b = super.point(inside: point, with: event)
        if !b {
            for subview in subviews {
                if subview.point(inside: CGPoint(x: point.x - subview.frame.origin.x, y: point.y - subview.frame.origin.y), with: event) {
                    b = true
                    break
                }
            }
        }
        return b
    }
}

// MARK: - TabBarItemContentMode
public enum TabBarItemContentMode: Int, Sendable {
    case alwaysOriginal // Always set the original image size

    case alwaysTemplate // Always set the image as a template image size
}

// MARK: - TabBarItemContentView
open class TabBarItemContentView: UIView {
    // MARK: - PROPERTY SETTING

    /// The title displayed on the item, default is `nil`
    open var title: String? {
        didSet {
            titleLabel.text = title
            updateLayout()
        }
    }

    /// The image used to represent the item, default is `nil`
    open var image: UIImage? {
        didSet {
            if !selected { updateDisplay() }
        }
    }

    /// The imageURL used to represent the item, default is `nil`
    open var imageURL: String? {
        didSet {
            if !selected { updateDisplay() }
        }
    }

    /// The image displayed when the tab bar item is selected, default is `nil`.
    open var selectedImage: UIImage? {
        didSet {
            if selected { updateDisplay() }
        }
    }

    /// The imageURL displayed when the tab bar item is selected, default is `nil`.
    open var selectedImageURL: String? {
        didSet {
            if selected { updateDisplay() }
        }
    }

    /// A Boolean value indicating whether the item is enabled, default is `YES`.
    open var enabled = true

    /// A Boolean value indicating whether the item is selected, default is `NO`.
    open var selected = false

    /// A Boolean value indicating whether the item is highlighted, default is `NO`.
    open var highlighted = false

    /// Text color, default is `UIColor(white: 0.57254902, alpha: 1.0)`.
    open var textColor = UIColor(white: 0.57254902, alpha: 1.0) {
        didSet {
            if !selected { titleLabel.textColor = textColor }
        }
    }

    /// Text color when highlighted, default is `UIColor(red: 0.0, green: 0.47843137, blue: 1.0, alpha: 1.0)`.
    open var highlightTextColor = UIColor(red: 0.0, green: 0.47843137, blue: 1.0, alpha: 1.0) {
        didSet {
            if selected { titleLabel.textColor = highlightIconColor }
        }
    }

    /// Icon color, default is `UIColor(white: 0.57254902, alpha: 1.0)`.
    open var iconColor = UIColor(white: 0.57254902, alpha: 1.0) {
        didSet {
            if !selected { imageView.tintColor = iconColor }
        }
    }

    /// Icon color when highlighted, default is `UIColor(red: 0.0, green: 0.47843137, blue: 1.0, alpha: 1.0)`.
    open var highlightIconColor = UIColor(red: 0.0, green: 0.47843137, blue: 1.0, alpha: 1.0) {
        didSet {
            if selected { imageView.tintColor = highlightIconColor }
        }
    }

    /// Background color, default is `UIColor.clear`.
    open var backdropColor = UIColor.clear {
        didSet {
            if !selected { backgroundColor = backdropColor }
        }
    }

    /// Background color when highlighted, default is `UIColor.clear`.
    open var highlightBackdropColor = UIColor.clear {
        didSet {
            if selected { backgroundColor = highlightBackdropColor }
        }
    }

    /// Icon imageView renderingMode, default is `.alwaysTemplate`.
    open var renderingMode: UIImage.RenderingMode = .alwaysTemplate {
        didSet {
            updateDisplay()
        }
    }

    /// Item content mode, default is `.alwaysTemplate`
    open var itemContentMode: TabBarItemContentMode = .alwaysTemplate {
        didSet {
            updateDisplay()
        }
    }

    /// The offset to use to adjust the title position, default is `UIOffset.zero`.
    open var titlePositionAdjustment: UIOffset = .zero {
        didSet {
            updateLayout()
        }
    }

    /// The insets that you use to determine the insets edge for contents, default is `UIEdgeInsets.zero`
    open var insets = UIEdgeInsets.zero {
        didSet {
            updateLayout()
        }
    }

    /// The insets that you use to determine the insets edge for image, default is `UIEdgeInsets.zero`
    open var imageInsets = UIEdgeInsets.zero {
        didSet {
            updateDisplay()
        }
    }

    open var imageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect.zero)
        imageView.backgroundColor = .clear
        return imageView
    }()

    open var titleLabel: UILabel = {
        let titleLabel = UILabel(frame: CGRect.zero)
        titleLabel.backgroundColor = .clear
        titleLabel.textColor = .clear
        titleLabel.textAlignment = .center
        return titleLabel
    }()

    /// Badge value, default is `nil`.
    open var badgeValue: String? {
        didSet {
            if let _ = badgeValue {
                badgeView.badgeValue = badgeValue
                addSubview(badgeView)
                updateLayout()
            } else {
                // Remove when nil.
                badgeView.removeFromSuperview()
            }
            badgeChanged(animated: true, completion: nil)
        }
    }

    /// Badge color, default is `nil`.
    open var badgeColor: UIColor? {
        didSet {
            if let _ = badgeColor {
                badgeView.badgeColor = badgeColor
            } else {
                badgeView.badgeColor = TabBarItemBadgeView.defaultBadgeColor
            }
        }
    }

    /// Badge view, default is `TabBarItemBadgeView()`.
    open var badgeView: TabBarItemBadgeView = .init() {
        willSet {
            if let _ = badgeView.superview {
                badgeView.removeFromSuperview()
            }
        }
        didSet {
            if let _ = badgeView.superview {
                updateLayout()
            }
        }
    }

    /// Badge offset, default is `UIOffset(horizontal: 6.0, vertical: -22.0)`.
    open var badgeOffset: UIOffset = .init(horizontal: 6.0, vertical: -22.0) {
        didSet {
            if badgeOffset != oldValue {
                updateLayout()
            }
        }
    }

    // MARK: -
    override public init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false

        addSubview(imageView)
        addSubview(titleLabel)

        titleLabel.textColor = textColor
        imageView.tintColor = iconColor
        backgroundColor = backdropColor
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    open func updateDisplay() {
        var currentImage = selected ? (selectedImage ?? image) : image
        if let targetImage = currentImage, targetImage.size.width > 0, targetImage.size.height > 0 {
            currentImage = targetImage.withRenderingMode(renderingMode).fw.image(insets: imageInsets)
        }
        if let currentImageURL = selected ? (selectedImageURL ?? imageURL) : imageURL {
            imageView.fw.setImage(url: currentImageURL, placeholderImage: currentImage, options: .avoidSetImage, context: nil, completion: { [weak self] image, _ in
                guard var image else { return }
                if let cgImage = image.cgImage {
                    image = UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: image.imageOrientation)
                }
                self?.imageView.image = image.withRenderingMode(self?.renderingMode ?? .alwaysTemplate).fw.image(insets: self?.imageInsets ?? .zero)
                self?.updateLayout()
            }, progress: nil)
        } else {
            imageView.image = currentImage
        }
        imageView.tintColor = selected ? highlightIconColor : iconColor
        titleLabel.textColor = selected ? highlightTextColor : textColor
        backgroundColor = selected ? highlightBackdropColor : backdropColor
    }

    open func updateLayout() {
        let w = bounds.size.width
        let h = bounds.size.height

        imageView.isHidden = (imageView.image == nil)
        titleLabel.isHidden = (titleLabel.text == nil)

        if itemContentMode == .alwaysTemplate {
            var s: CGFloat = 0.0 // image size
            var f: CGFloat = 0.0 // font
            var isLandscape = false
            if let window = UIWindow.fw.main {
                isLandscape = window.bounds.width > window.bounds.height
            }
            let isWide = isLandscape || traitCollection.horizontalSizeClass == .regular // is landscape or regular
            if isWide {
                s = UIScreen.main.scale == 3.0 ? 23.0 : 20.0
                f = UIScreen.main.scale == 3.0 ? 13.0 : 12.0
            } else {
                s = 23.0
                f = 10.0
            }

            if !imageView.isHidden && !titleLabel.isHidden {
                titleLabel.font = UIFont.systemFont(ofSize: f)
                titleLabel.sizeToFit()
                if isWide {
                    titleLabel.frame = CGRect(x: (w - titleLabel.bounds.size.width) / 2.0 + (UIScreen.main.scale == 3.0 ? 14.25 : 12.25) + titlePositionAdjustment.horizontal,
                                              y: (h - titleLabel.bounds.size.height) / 2.0 + titlePositionAdjustment.vertical,
                                              width: titleLabel.bounds.size.width,
                                              height: titleLabel.bounds.size.height)
                    imageView.frame = CGRect(x: titleLabel.frame.origin.x - s - (UIScreen.main.scale == 3.0 ? 6.0 : 5.0),
                                             y: (h - s) / 2.0,
                                             width: s,
                                             height: s)
                } else {
                    titleLabel.frame = CGRect(x: (w - titleLabel.bounds.size.width) / 2.0 + titlePositionAdjustment.horizontal,
                                              y: h - titleLabel.bounds.size.height - 1.0 + titlePositionAdjustment.vertical,
                                              width: titleLabel.bounds.size.width,
                                              height: titleLabel.bounds.size.height)
                    imageView.frame = CGRect(x: (w - s) / 2.0,
                                             y: (h - s) / 2.0 - 6.0,
                                             width: s,
                                             height: s)
                }
            } else if !imageView.isHidden {
                imageView.frame = CGRect(x: (w - s) / 2.0,
                                         y: (h - s) / 2.0,
                                         width: s,
                                         height: s)
            } else if !titleLabel.isHidden {
                titleLabel.font = UIFont.systemFont(ofSize: f)
                titleLabel.sizeToFit()
                titleLabel.frame = CGRect(x: (w - titleLabel.bounds.size.width) / 2.0 + titlePositionAdjustment.horizontal,
                                          y: (h - titleLabel.bounds.size.height) / 2.0 + titlePositionAdjustment.vertical,
                                          width: titleLabel.bounds.size.width,
                                          height: titleLabel.bounds.size.height)
            }

            if let _ = badgeView.superview {
                let size = badgeView.sizeThatFits(frame.size)
                if isWide {
                    badgeView.frame = CGRect(origin: CGPoint(x: imageView.frame.midX - 3 + badgeOffset.horizontal, y: imageView.frame.midY + 3 + badgeOffset.vertical), size: size)
                } else {
                    badgeView.frame = CGRect(origin: CGPoint(x: w / 2.0 + badgeOffset.horizontal, y: h / 2.0 + badgeOffset.vertical), size: size)
                }
                badgeView.setNeedsLayout()
            }
        } else {
            if !imageView.isHidden && !titleLabel.isHidden {
                titleLabel.sizeToFit()
                imageView.sizeToFit()
                titleLabel.frame = CGRect(x: (w - titleLabel.bounds.size.width) / 2.0 + titlePositionAdjustment.horizontal,
                                          y: h - titleLabel.bounds.size.height - 1.0 + titlePositionAdjustment.vertical,
                                          width: titleLabel.bounds.size.width,
                                          height: titleLabel.bounds.size.height)
                imageView.frame = CGRect(x: (w - imageView.bounds.size.width) / 2.0,
                                         y: (h - imageView.bounds.size.height) / 2.0 - 6.0,
                                         width: imageView.bounds.size.width,
                                         height: imageView.bounds.size.height)
            } else if !imageView.isHidden {
                imageView.sizeToFit()
                imageView.center = CGPoint(x: w / 2.0, y: h / 2.0)
            } else if !titleLabel.isHidden {
                titleLabel.sizeToFit()
                titleLabel.center = CGPoint(x: w / 2.0, y: h / 2.0)
            }

            if let _ = badgeView.superview {
                let size = badgeView.sizeThatFits(frame.size)
                badgeView.frame = CGRect(origin: CGPoint(x: w / 2.0 + badgeOffset.horizontal, y: h / 2.0 + badgeOffset.vertical), size: size)
                badgeView.setNeedsLayout()
            }
        }
    }

    // MARK: - INTERNAL METHODS
    final func select(animated: Bool, completion: (@MainActor @Sendable () -> Void)?) {
        selected = true
        if enabled && highlighted {
            highlighted = false
            dehighlightAnimation(animated: animated, completion: { [weak self] in
                self?.updateDisplay()
                self?.selectAnimation(animated: animated, completion: completion)
            })
        } else {
            updateDisplay()
            selectAnimation(animated: animated, completion: completion)
        }
    }

    final func deselect(animated: Bool, completion: (@MainActor @Sendable () -> Void)?) {
        selected = false
        updateDisplay()
        deselectAnimation(animated: animated, completion: completion)
    }

    final func reselect(animated: Bool, completion: (@MainActor @Sendable () -> Void)?) {
        if selected == false {
            select(animated: animated, completion: completion)
        } else {
            if enabled && highlighted {
                highlighted = false
                dehighlightAnimation(animated: animated, completion: { [weak self] in
                    self?.reselectAnimation(animated: animated, completion: completion)
                })
            } else {
                reselectAnimation(animated: animated, completion: completion)
            }
        }
    }

    final func highlight(animated: Bool, completion: (@MainActor @Sendable () -> Void)?) {
        if !enabled {
            return
        }
        if highlighted == true {
            return
        }
        highlighted = true
        highlightAnimation(animated: animated, completion: completion)
    }

    final func dehighlight(animated: Bool, completion: (@MainActor @Sendable () -> Void)?) {
        if !enabled {
            return
        }
        if !highlighted {
            return
        }
        highlighted = false
        dehighlightAnimation(animated: animated, completion: completion)
    }

    func badgeChanged(animated: Bool, completion: (@MainActor @Sendable () -> Void)?) {
        badgeChangedAnimation(animated: animated, completion: completion)
    }

    // MARK: - ANIMATION METHODS
    open func selectAnimation(animated: Bool, completion: (@MainActor @Sendable () -> Void)?) {
        completion?()
    }

    open func deselectAnimation(animated: Bool, completion: (@MainActor @Sendable () -> Void)?) {
        completion?()
    }

    open func reselectAnimation(animated: Bool, completion: (@MainActor @Sendable () -> Void)?) {
        completion?()
    }

    open func highlightAnimation(animated: Bool, completion: (@MainActor @Sendable () -> Void)?) {
        completion?()
    }

    open func dehighlightAnimation(animated: Bool, completion: (@MainActor @Sendable () -> Void)?) {
        completion?()
    }

    open func badgeChangedAnimation(animated: Bool, completion: (@MainActor @Sendable () -> Void)?) {
        completion?()
    }
}

// MARK: - TabBarItemMoreContentView
open class TabBarItemMoreContentView: TabBarItemContentView {
    override public init(frame: CGRect) {
        super.init(frame: frame)
        title = FrameworkBundle.moreButton
        image = systemMore(highlighted: false)
        selectedImage = systemMore(highlighted: true)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func systemMore(highlighted isHighlighted: Bool) -> UIImage? {
        let image = UIImage()
        let circleDiameter = isHighlighted ? 5.0 : 4.0

        UIGraphicsBeginImageContextWithOptions(CGSize(width: 32, height: 32), false, 0.0)

        if let context = UIGraphicsGetCurrentContext() {
            context.setLineWidth(1.0)
            for index in 0...2 {
                let tmpRect = CGRect(x: 5.0 + 9.0 * Double(index), y: 14.0, width: circleDiameter, height: circleDiameter)
                context.addEllipse(in: tmpRect)
                image.draw(in: tmpRect)
            }

            if isHighlighted {
                context.setFillColor(UIColor.blue.cgColor)
                context.fillPath()
            } else {
                context.strokePath()
            }

            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage
        }

        return nil
    }
}

// MARK: - TabBarItemBadgeView
/**
 * FWTabBarItemBadgeView
 * 这个类定义了item中使用的badge视图样式，默认为FWTabBarItemBadgeView类对象。
 * 你可以设置FWTabBarItemContentView的badgeView属性为自定义的FWTabBarItemBadgeView子类，这样就可以轻松实现 自定义通知样式了。
 */
open class TabBarItemBadgeView: UIView {
    /// 默认颜色
    public static var defaultBadgeColor = UIColor.red

    /// Badge color
    open var badgeColor: UIColor? = defaultBadgeColor {
        didSet {
            imageView.backgroundColor = badgeColor
        }
    }

    /// Badge value, supprot nil, "", "1", "someText". Hidden when nil. Show Little dot style when "".
    open var badgeValue: String? {
        didSet {
            badgeLabel.text = badgeValue
        }
    }

    /// Image view
    open var imageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect.zero)
        imageView.backgroundColor = .clear
        return imageView
    }()

    /// 显示badgeValue的Label
    open var badgeLabel: UILabel = {
        let badgeLabel = UILabel(frame: CGRect.zero)
        badgeLabel.backgroundColor = .clear
        badgeLabel.textColor = .white
        badgeLabel.font = UIFont.systemFont(ofSize: 13.0)
        badgeLabel.textAlignment = .center
        return badgeLabel
    }()

    /// Initializer
    override public init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        addSubview(badgeLabel)
        imageView.backgroundColor = badgeColor
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /*
     *  通过layoutSubviews()布局子视图，你可以通过重写此方法实现自定义布局。
     **/
    override open func layoutSubviews() {
        super.layoutSubviews()
        guard let badgeValue else {
            imageView.isHidden = true
            badgeLabel.isHidden = true
            return
        }

        imageView.isHidden = false
        badgeLabel.isHidden = false

        if badgeValue == "" {
            imageView.frame = CGRect(origin: CGPoint(x: (bounds.size.width - 10.0) / 2.0, y: (bounds.size.height - 10.0) / 2.0), size: CGSize(width: 10.0, height: 10.0))
        } else {
            imageView.frame = bounds
        }
        imageView.layer.cornerRadius = imageView.bounds.size.height / 2.0
        badgeLabel.sizeToFit()
        badgeLabel.center = imageView.center
    }

    /*
     *  通过此方法计算badge视图需要占用父视图的frame大小，通过重写此方法可以自定义badge视图的大小。
     *  如果你需要自定义badge视图在Content中的位置，可以设置Content的badgeOffset属性。
     */
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let _ = badgeValue else {
            return CGSize(width: 18.0, height: 18.0)
        }
        let textSize = badgeLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        return CGSize(width: max(18.0, textSize.width + 10.0), height: 18.0)
    }
}
