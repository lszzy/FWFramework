//
//  DrawerView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - Wrapper+UIView
/// 视图抽屉拖拽效果分类
@MainActor extension Wrapper where Base: UIView {
    /// 抽屉拖拽视图，绑定抽屉拖拽效果后才存在
    public var drawerView: DrawerView? {
        get {
            property(forName: "drawerView") as? DrawerView
        }
        set {
            setProperty(newValue, forName: "drawerView")
        }
    }

    /**
     设置抽屉拖拽效果。如果view为滚动视图，自动处理与滚动视图pan手势冲突的问题

     @param direction 拖拽方向，如向上拖动视图时为Up，默认向上
     @param positions 抽屉位置，至少两级，相对于view父视图的originY位置
     @param kickbackHeight 回弹高度，拖拽小于该高度执行回弹
     @param positionChanged 抽屉视图位移回调，参数为相对父视图的origin位置和是否拖拽完成的标记
     @return 抽屉拖拽视图
     */
    @discardableResult
    public func drawerView(
        _ direction: UISwipeGestureRecognizer.Direction,
        positions: [CGFloat],
        kickbackHeight: CGFloat,
        positionChanged: ((CGFloat, Bool) -> Void)? = nil
    ) -> DrawerView {
        let drawerView = DrawerView(view: base)
        if direction.rawValue > 0 {
            drawerView.direction = direction
        }
        drawerView.positions = positions
        drawerView.kickbackHeight = kickbackHeight
        drawerView.positionChanged = positionChanged
        return drawerView
    }
}

// MARK: - Wrapper+UIScrollView
/// 滚动视图纵向手势冲突无缝滑动分类，需允许同时识别多个手势
@MainActor extension Wrapper where Base: UIScrollView {
    /// 外部滚动视图是否位于顶部固定位置，在顶部时不能滚动
    public var drawerSuperviewFixed: Bool {
        get { propertyBool(forName: "drawerSuperviewFixed") }
        set { setPropertyBool(newValue, forName: "drawerSuperviewFixed") }
    }

    /// 外部滚动视图scrollViewDidScroll调用，参数为固定的位置
    public func drawerSuperviewDidScroll(_ position: CGFloat) {
        if base.contentOffset.y >= position {
            drawerSuperviewFixed = true
        }
        if drawerSuperviewFixed {
            base.contentOffset = CGPoint(x: base.contentOffset.x, y: position)
        }
    }

    /// 内嵌滚动视图scrollViewDidScroll调用，参数为外部滚动视图
    public func drawerSubviewDidScroll(_ superview: UIScrollView) {
        if base.contentOffset.y <= 0 {
            superview.fw.drawerSuperviewFixed = false
        }
        if !superview.fw.drawerSuperviewFixed {
            base.contentOffset = CGPoint(x: base.contentOffset.x, y: 0)
        }
    }
}

// MARK: - DrawerView
/// 抽屉拖拽视图事件代理
@MainActor public protocol DrawerViewDelegate: AnyObject {
    /// 抽屉视图位移回调，参数为相对view父视图的origin位置和是否拖拽完成的标记
    func drawerView(_ drawerView: DrawerView, positionChanged position: CGFloat, finished: Bool)
}

/// 抽屉拖拽视图
open class DrawerView: NSObject, UIGestureRecognizerDelegate, UIScrollViewDelegate {
    /// 事件代理，默认nil
    open weak var delegate: DrawerViewDelegate?

    /// 拖拽方向，如向上拖动视图时为Up，向下为Down，向右为Right，向左为Left。默认向上
    open var direction: UISwipeGestureRecognizer.Direction = .up {
        didSet {
            if let view {
                position = isVertical ? view.frame.origin.y : view.frame.origin.x
            }
        }
    }

    /// 抽屉位置，至少两级，相对于view父视图的originY位置，自动从小到大排序
    open var positions: [CGFloat] {
        get {
            _positions
        }
        set {
            if newValue.count < 2 { return }
            _positions = newValue.sorted(by: { $0 < $1 })
        }
    }

    private var _positions: [CGFloat] = []

    /// 回弹高度，拖拽小于该高度执行回弹，默认为0
    open var kickbackHeight: CGFloat = 0

    /// 是否启用拖拽，默认YES。其实就是设置手势的enabled
    open var enabled: Bool {
        get { gestureRecognizer.isEnabled }
        set { gestureRecognizer.isEnabled = newValue }
    }

    /// 是否自动检测滚动视图，默认YES。如需手工指定，请禁用之
    open var autoDetected: Bool = true

    /// 指定滚动视图，自动处理与滚动视图pan手势在指定方向的冲突。先尝试设置delegate为自身，尝试失败请手工调用scrollViewDidScroll
    open weak var scrollView: UIScrollView? {
        didSet {
            if let drawerView = oldValue?.delegate as? DrawerView, drawerView == self {
                oldValue?.delegate = nil
            }
            if let scrollView, scrollView.delegate == nil {
                scrollView.delegate = self
            }
        }
    }

    /// 抽屉视图，自动添加pan手势
    open private(set) weak var view: UIView?

    /// 抽屉拖拽手势，默认设置delegate为自身
    open private(set) lazy var gestureRecognizer: UIPanGestureRecognizer = {
        let result = UIPanGestureRecognizer(target: self, action: #selector(gestureRecognizerAction(_:)))
        result.delegate = self
        return result
    }()

    /// 抽屉视图当前位置
    open private(set) var position: CGFloat = 0

    /// 抽屉视图打开位置
    open var openPosition: CGFloat {
        (isReverse ? positions.first : positions.last) ?? .zero
    }

    /// 抽屉视图中间位置，建议单数时调用
    open var middlePosition: CGFloat {
        position(at: positions.count / 2)
    }

    /// 抽屉视图关闭位置
    open var closePosition: CGFloat {
        (isReverse ? positions.last : positions.first) ?? .zero
    }

    /// 抽屉视图位移回调，参数为相对view父视图的origin位置和是否拖拽完成的标记
    open var positionChanged: ((_ position: CGFloat, _ finished: Bool) -> Void)?

    /// 自定义动画句柄，动画必须调用animations和completion句柄
    open var animationBlock: ((_ animations: () -> Void, _ completion: (Bool) -> Void) -> Void)?

    /// 滚动视图过滤器，默认只处理可滚动视图的冲突。如需其它条件，可自定义此句柄
    open var scrollViewFilter: ((UIScrollView) -> Bool)?

    /// 自定义滚动视图允许滚动的位置，默认nil时仅openPosition可滚动
    open var scrollViewPositions: ((UIScrollView) -> [CGFloat])?

    /// 自定义滚动视图在各个位置的contentInset(从小到大，数量同positions)，默认nil时不处理。UITableView时也可使用tableFooterView等实现
    open var scrollViewInsets: ((UIScrollView) -> [UIEdgeInsets])?

    private var displayLink: CADisplayLink?
    private var panDisabled = false
    private var originPosition: CGFloat = .zero
    private var originOffset: CGPoint = .zero
    private var isOriginDraggable = false
    private var isOriginScrollable = false
    private var isOriginScrollView = false
    private var isOriginDirection = false

    private var isVertical: Bool {
        direction == .up || direction == .down
    }

    private var isReverse: Bool {
        direction == .up || direction == .left
    }

    private var scrollEdge: UIRectEdge {
        switch direction {
        case .up:
            return .top
        case .down:
            return .bottom
        case .left:
            return .left
        case .right:
            return .right
        default:
            return []
        }
    }

    // MARK: - Lifecycle
    /// 创建抽屉拖拽视图，view会强引用之。view为滚动视图时，详见scrollView属性
    public init(view: UIView) {
        super.init()
        self.view = view
        self.position = isVertical ? view.frame.origin.y : view.frame.origin.x

        if let scrollView = view as? UIScrollView {
            self.scrollView = scrollView
            if scrollView.delegate == nil {
                scrollView.delegate = self
            }
        }

        view.addGestureRecognizer(gestureRecognizer)
        view.fw.drawerView = self
    }

    // MARK: - Public
    /// 设置抽屉效果视图到指定位置，如果位置发生改变，会触发抽屉callback回调
    open func setPosition(_ position: CGFloat, animated: Bool = true) {
        guard self.position != position else { return }

        // 不执行动画
        if !animated {
            togglePosition(position)
            self.position = position
            notifyPosition(true)
            return
        }

        // 使用CADisplayLink监听动画过程中的位置
        if displayLink != nil {
            displayLink?.invalidate()
            displayLink = nil
        }
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkAction))
        displayLink?.add(to: .current, forMode: .common)

        // 执行动画移动到指定位置，动画完成标记拖拽位置并回调
        if let animationBlock {
            animationBlock({ [weak self] in
                self?.togglePosition(position)
            }, { [weak self] _ in
                self?.animateComplete(position)
            })
        } else {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
                self.togglePosition(position)
            }, completion: { _ in
                self.animateComplete(position)
            })
        }
    }

    /// 获取抽屉视图指定索引位置(从小到大)，获取失败返回0
    open func position(at index: Int) -> CGFloat {
        guard index >= 0, index < positions.count else { return 0 }
        return positions[index]
    }

    /// 判断当前抽屉效果视图是否在指定索引位置(从小到大)
    open func isPosition(at index: Int) -> Bool {
        guard index >= 0, index < positions.count else { return false }
        return position == positions[index]
    }

    /// 设置抽屉效果视图到指定索引位置(从小到大)，如果位置发生改变，会触发抽屉callback回调
    open func setPosition(at index: Int, animated: Bool = true) {
        guard index >= 0, index < positions.count else { return }
        setPosition(positions[index], animated: animated)
    }

    // MARK: - UIScrollViewDelegate
    /// 如果scrollView已自定义delegate，需在scrollViewDidScroll手工调用本方法
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView, gestureRecognizer.isEnabled else { return }
        guard canScroll(scrollView) else { return }

        let positions = scrollViewPositions?(scrollView)
        if positions?.count ?? 0 > 0 {
            panDisabled = false
            if isOriginScrollable {
                if isOriginDraggable {
                    scrollView.fw.scroll(to: scrollEdge, animated: false)
                } else {
                    togglePosition(originPosition)
                    position = originPosition
                }
            } else {
                scrollView.contentOffset = originOffset
            }
            return
        }

        if scrollView.fw.isScroll(to: scrollEdge) {
            panDisabled = false
        }
        if !panDisabled {
            scrollView.fw.scroll(to: scrollEdge, animated: false)
        }
    }

    // MARK: - UIGestureRecognizerDelegate
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer is UIPanGestureRecognizer,
           let otherView = otherGestureRecognizer.view as? UIScrollView {
            if autoDetected {
                if canScroll(otherView) {
                    scrollView = otherView
                    return true
                }
            } else {
                if let scrollView, scrollView == otherView, canScroll(scrollView) {
                    return true
                }
            }
        }
        return false
    }

    // MARK: - Private
    private func isDirection(_ gestureRecognizer: UIPanGestureRecognizer) -> Bool {
        let swipeDirection = gestureRecognizer.fw.swipeDirection
        switch direction {
        case .up:
            return swipeDirection == .down
        case .down:
            return swipeDirection == .up
        case .left:
            return swipeDirection == .right
        case .right:
            return swipeDirection == .left
        default:
            return false
        }
    }

    private var nextPosition: CGFloat {
        var nextPosition: CGFloat = .zero
        if position > originPosition {
            for obj in positions {
                let maxKickback = (obj == positions.last) ? obj : obj + kickbackHeight
                if position <= maxKickback {
                    nextPosition = obj
                    break
                }
            }
        } else {
            for obj in positions.reversed() {
                let minKickback = (obj == positions.first) ? obj : obj - kickbackHeight
                if position >= minKickback {
                    nextPosition = obj
                    break
                }
            }
        }
        return nextPosition
    }

    private func canScroll(_ scrollView: UIScrollView) -> Bool {
        if let scrollViewFilter { return scrollViewFilter(scrollView) }
        if !scrollView.fw.isViewVisible || !scrollView.isScrollEnabled { return false }
        if isVertical {
            if !scrollView.fw.canScrollVertical { return false }
        } else {
            if !scrollView.fw.canScrollHorizontal { return false }
        }
        return true
    }

    private func togglePosition(_ position: CGFloat) {
        guard let view else { return }
        view.frame = CGRect(
            x: isVertical ? view.frame.origin.x : position,
            y: isVertical ? position : view.frame.origin.y,
            width: view.frame.size.width,
            height: view.frame.size.height
        )
    }

    private func notifyPosition(_ finished: Bool) {
        adjustScrollInset()

        positionChanged?(position, finished)
        delegate?.drawerView(self, positionChanged: position, finished: finished)
    }

    private func adjustScrollInset() {
        guard let scrollView, let insets = scrollViewInsets?(scrollView) else { return }
        if insets.count > 0 && insets.count == positions.count {
            for (idx, _) in positions.enumerated() {
                let next = idx < (positions.count - 1) ? positions[idx + 1] : nil
                if (next != nil && position < next!) || next == nil {
                    let inset = insets[idx]
                    if scrollView.contentInset != inset {
                        scrollView.contentInset = inset
                    }
                    break
                }
            }
        }
    }

    private func animateComplete(_ position: CGFloat) {
        // 动画完成时需释放displayLink
        if displayLink != nil {
            displayLink?.invalidate()
            displayLink = nil
        }

        togglePosition(position)
        self.position = position
        notifyPosition(true)
    }

    @objc private func displayLinkAction() {
        // 监听动画过程中的位置，访问view.layer.presentation即可
        position = (isVertical ? view?.layer.presentation()?.frame.origin.y : view?.layer.presentation()?.frame.origin.x) ?? .zero
        notifyPosition(false)
    }

    @objc private func gestureRecognizerAction(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        // 拖动开始时记录起始位置信息
        case .began:
            position = (isVertical ? view?.frame.origin.y : view?.frame.origin.x) ?? .zero
            originPosition = position

            isOriginScrollView = gestureRecognizer.fw.hitTest(view: scrollView)
            isOriginDirection = isDirection(gestureRecognizer) || (scrollView != nil && isDirection(scrollView!.panGestureRecognizer))
            originOffset = scrollView?.contentOffset ?? .zero
            isOriginDraggable = isOriginDirection && (scrollView?.fw.isScroll(to: scrollEdge) ?? false)
            let positions = scrollView != nil ? scrollViewPositions?(scrollView!) : nil
            isOriginScrollable = originPosition == openPosition || positions?.contains(originPosition) == true
        // 拖动改变时更新视图位置
        case .changed:
            // 记录并清空相对父视图的移动距离
            let transition = gestureRecognizer.translation(in: view?.superview)
            gestureRecognizer.setTranslation(.zero, in: view?.superview)

            // 视图跟随拖动移动指定距离，且移动时限制不超过范围
            var position = isVertical ? ((view?.frame.origin.y ?? 0) + transition.y) : ((view?.frame.origin.x ?? 0) + transition.x)
            if position < (positions.first ?? 0) {
                position = (positions.first ?? 0)
            } else if position > (positions.last ?? 0) {
                position = (positions.last ?? 0)
            }

            // 执行位移并回调
            togglePosition(position)
            self.position = position
            gestureRecognizerDidScroll()
            notifyPosition(false)
        // 拖动结束时停留指定位置
        case .failed, .ended:
            // 停留位置未发生改变时不执行动画，直接回调
            if position == originPosition {
                notifyPosition(true)
                // 停留位置发生改变时执行动画，动画完成后回调
            } else {
                setPosition(nextPosition, animated: true)
            }
        default:
            break
        }
    }

    private func gestureRecognizerDidScroll() {
        guard let scrollView, gestureRecognizer.isEnabled else { return }
        guard canScroll(scrollView) else { return }

        let positions = scrollViewPositions?(scrollView)
        if positions?.count ?? 0 > 0 {
            panDisabled = false
            if isOriginScrollable {
                if !isOriginDraggable && isOriginScrollView {
                    togglePosition(originPosition)
                    position = originPosition
                }
            }
            return
        }

        if position == openPosition {
            panDisabled = !isOriginDraggable && (isOriginScrollView || !isOriginDirection)
        }
        if panDisabled {
            togglePosition(openPosition)
            position = openPosition
        } else {
            scrollView.fw.scroll(to: scrollEdge, animated: false)
        }
    }
}
