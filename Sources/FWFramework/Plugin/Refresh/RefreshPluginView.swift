//
//  RefreshPluginView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - PullRefreshView
/// 下拉刷新状态枚举
public enum PullRefreshState: Int, Sendable {
    case idle = 0
    case triggered
    case loading
    case all
}

/// 下拉刷新视图，默认高度60。如果indicatorView为自定义指示器时会自动隐藏标题和箭头，仅显示指示器视图
///
/// [SVPullToRefresh](https://github.com/samvermette/SVPullToRefresh)
open class PullRefreshView: UIView {
    // MARK: - Accessor
    /// 全局高度设置
    public static var height: CGFloat = 60

    /// 当前高度，默认全局高度
    open var height: CGFloat {
        get {
            _height > 0 ? _height : PullRefreshView.height
        }
        set {
            _height = newValue

            var newFrame = frame
            newFrame.size.height = newValue > 0 ? newValue : PullRefreshView.height
            newFrame.origin.y = -newFrame.size.height
            frame = newFrame
        }
    }

    private var _height: CGFloat = 0

    /// 原始边距
    open var originalInset: UIEdgeInsets = .zero

    /// 箭头颜色
    open var arrowColor: UIColor? {
        get { arrowView.arrowColor }
        set { arrowView.arrowColor = newValue }
    }

    /// 文本颜色
    open var textColor: UIColor? {
        get {
            titleLabel.textColor
        }
        set {
            titleLabel.textColor = newValue
            subtitleLabel.textColor = newValue
        }
    }

    /// 指示器颜色
    open var indicatorColor: UIColor? {
        get { indicatorView.indicatorColor }
        set { indicatorView.indicatorColor = newValue }
    }

    /// 指示器偏移
    open var indicatorPadding: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }

    /// 是否显示标题文本
    open var showsTitleLabel = false {
        didSet {
            setNeedsLayout()
            layoutIfNeeded()
        }
    }

    /// 是否显示箭头视图
    open var showsArrowView = false {
        didSet {
            setNeedsLayout()
            layoutIfNeeded()
        }
    }

    /// 是否改变透明度，默认true
    open var shouldChangeAlpha = true

    /// 是否是用户触发
    open var userTriggered = false

    /// 自定义状态改变句柄
    open var stateBlock: ((_ view: PullRefreshView, _ state: PullRefreshState) -> Void)?

    /// 自定义进度句柄
    open var progressBlock: ((_ view: PullRefreshView, _ progress: CGFloat) -> Void)?

    /// 自定义下拉刷新句柄
    open var pullRefreshBlock: (() -> Void)?

    /// 自定义下拉刷新目标和动作
    open weak var target: AnyObject?
    open var action: Selector?

    /// 绑定滚动视图
    open weak var scrollView: UIScrollView?

    /// 是否已监听
    open var isObserving = false

    /// 下拉刷新状态
    open var state: PullRefreshState = .idle {
        didSet {
            if state == oldValue {
                return
            }

            setNeedsLayout()
            layoutIfNeeded()

            switch state {
            case .all, .idle:
                resetScrollViewContentInset()
            case .triggered:
                isActive = true
            case .loading:
                setScrollViewContentInsetForLoading()

                if oldValue == .triggered {
                    if let pullRefreshBlock {
                        pullRefreshBlock()
                    } else if let target, let action, target.responds(to: action) {
                        _ = target.perform(action)
                    }
                }
            }

            animationStateBlock?(self, state)
            stateBlock?(self, state)
        }
    }

    // MARK: - Subviews
    /// 标题文本
    open lazy var titleLabel: UILabel = {
        let result = UILabel(frame: CGRect(x: 0, y: 0, width: 210, height: 20))
        result.font = UIFont.boldSystemFont(ofSize: 14)
        result.backgroundColor = .clear
        result.textColor = .darkGray
        addSubview(result)
        return result
    }()

    /// 副标题文本
    open lazy var subtitleLabel: UILabel = {
        let result = UILabel(frame: CGRect(x: 0, y: 0, width: 210, height: 20))
        result.font = UIFont.systemFont(ofSize: 12)
        result.backgroundColor = .clear
        result.textColor = .darkGray
        addSubview(result)
        return result
    }()

    /// 指示器视图
    open lazy var indicatorView: UIView & IndicatorViewPlugin = {
        let style: IndicatorViewStyle = .refreshPulldown
        let result = UIView.fw.indicatorView(style: style)
        if style.indicatorColor == nil {
            result.indicatorColor = .gray
        }
        addSubview(result)
        return result
    }() {
        didSet {
            oldValue.removeFromSuperview()
            addSubview(indicatorView)

            if !(indicatorView is UIActivityIndicatorView) {
                showsTitleLabel = false
                showsArrowView = false
            }

            setNeedsLayout()
            layoutIfNeeded()
        }
    }

    private lazy var arrowView: PullRefreshArrowView = {
        let result = PullRefreshArrowView(frame: CGRect(x: 0, y: bounds.size.height - 47, width: 15, height: 40))
        result.backgroundColor = .clear
        addSubview(result)
        return result
    }()

    private var titles: [String] = [
        FrameworkBundle.localizedString("fw.refreshIdle"),
        FrameworkBundle.localizedString("fw.refreshTriggered"),
        FrameworkBundle.localizedString("fw.refreshLoading")
    ]
    private var subtitles: [String] = ["", "", ""]
    private var viewForState: [Any] = ["", "", ""]

    private weak var currentCustomView: UIView?
    private var animationStateBlock: ((PullRefreshView, PullRefreshState) -> Void)?
    private var animationProgressBlock: ((PullRefreshView, CGFloat) -> Void)?

    private var pullingPercent: CGFloat = 0 {
        didSet {
            alpha = shouldChangeAlpha ? pullingPercent : 1

            if pullingPercent > 0 && !showsArrowView {
                let customView = viewForState[state.rawValue] as? UIView
                let hasCustomView = customView != nil
                if !hasCustomView && !indicatorView.isAnimating {
                    indicatorView.startAnimating()
                }
            }
        }
    }

    var isActive = false

    // MARK: - Lifecycle
    override public init(frame: CGRect) {
        super.init(frame: frame)

        didInitialize()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        didInitialize()
    }

    private func didInitialize() {
        autoresizingMask = .flexibleWidth
        showsTitleLabel = indicatorView is UIActivityIndicatorView
        showsArrowView = showsTitleLabel
    }

    override open func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)

        if let scrollView = superview as? UIScrollView, newSuperview == nil,
           scrollView.fw.showPullRefresh {
            if isObserving {
                scrollView.removeObserver(self, forKeyPath: "contentOffset")
                scrollView.removeObserver(self, forKeyPath: "contentSize")
                scrollView.removeObserver(self, forKeyPath: "frame")
                scrollView.panGestureRecognizer.fw.unobserveProperty(\.state, target: self, action: #selector(gestureRecognizerStateChanged(_:)))
                isObserving = false
            }
        }
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        let customView = viewForState[state.rawValue] as? UIView
        let customViewChanged = customView != currentCustomView
        if customViewChanged || customView == nil {
            currentCustomView?.removeFromSuperview()
            currentCustomView = nil
        }

        titleLabel.isHidden = customView != nil || !showsTitleLabel
        subtitleLabel.isHidden = customView != nil || !showsTitleLabel
        arrowView.isHidden = customView != nil || !showsArrowView

        if let customView {
            if customViewChanged {
                currentCustomView = customView
                addSubview(customView)
            }
            let viewBounds = customView.bounds
            let origin = CGPoint(x: round((bounds.size.width - viewBounds.size.width) / 2), y: (indicatorPadding / 2) + round((bounds.size.height - viewBounds.size.height) / 2))
            customView.frame = CGRect(x: origin.x, y: origin.y, width: viewBounds.size.width, height: viewBounds.size.height)
        } else {
            switch state {
            case .all, .idle:
                indicatorView.stopAnimating()
                if showsArrowView {
                    rotateArrow(0, hide: false)
                }
            case .triggered:
                if showsArrowView {
                    rotateArrow(CGFloat.pi, hide: false)
                } else {
                    if !indicatorView.isAnimating {
                        indicatorView.startAnimating()
                    }
                }
            case .loading:
                indicatorView.startAnimating()
                if showsArrowView {
                    rotateArrow(0, hide: true)
                }
            }

            let leftViewWidth = max(arrowView.bounds.size.width, indicatorView.bounds.size.width)
            let margin: CGFloat = 10
            let marginY: CGFloat = 2
            let paddingY = indicatorPadding / 2
            let labelMaxWidth = bounds.size.width - margin - leftViewWidth

            titleLabel.text = showsTitleLabel ? titles[state.rawValue] : nil
            let subtitle = showsTitleLabel ? subtitles[state.rawValue] : nil
            subtitleLabel.text = (subtitle?.count ?? 0) > 0 ? subtitle : nil
            let titleSize = titleLabel.text?.boundingRect(
                with: CGSize(width: labelMaxWidth, height: titleLabel.font.lineHeight),
                options: [.usesFontLeading, .usesLineFragmentOrigin],
                attributes: [.font: titleLabel.font as Any],
                context: nil
            ).size ?? .zero
            let subtitleSize = subtitleLabel.text?.boundingRect(
                with: CGSize(width: labelMaxWidth, height: subtitleLabel.font.lineHeight),
                options: [.usesFontLeading, .usesLineFragmentOrigin],
                attributes: [.font: subtitleLabel.font as Any],
                context: nil
            ).size ?? .zero

            let maxLabelWidth = max(titleSize.width, subtitleSize.width)
            let totalMaxWidth = leftViewWidth + maxLabelWidth + (maxLabelWidth != 0 ? margin : 0)
            let labelX = (bounds.size.width / 2) - (totalMaxWidth / 2) + leftViewWidth + margin
            let totalHeight = subtitleSize.height > 0 ? (titleSize.height + subtitleSize.height + marginY) : titleSize.height
            let minY = (bounds.size.height / 2) - (totalHeight / 2)
            let titleY = minY

            titleLabel.frame = CGRectIntegral(CGRect(x: labelX, y: paddingY + titleY, width: titleSize.width, height: titleSize.height))
            subtitleLabel.frame = CGRectIntegral(CGRect(x: labelX, y: paddingY + titleY + titleSize.height + marginY, width: subtitleSize.width, height: subtitleSize.height))

            let arrowX = (bounds.size.width / 2) - (totalMaxWidth / 2) + (leftViewWidth - arrowView.bounds.size.width) / 2
            arrowView.frame = CGRect(x: arrowX, y: paddingY + (bounds.size.height / 2) - (arrowView.bounds.size.height / 2), width: arrowView.bounds.size.width, height: arrowView.bounds.size.height)

            if showsArrowView {
                indicatorView.center = arrowView.center
            } else {
                let indicatorOrigin = CGPoint(x: bounds.size.width / 2 - indicatorView.bounds.size.width / 2, y: paddingY + (bounds.size.height / 2 - indicatorView.bounds.size.height / 2))
                indicatorView.frame = CGRect(x: indicatorOrigin.x, y: indicatorOrigin.y, width: indicatorView.bounds.size.width, height: indicatorView.bounds.size.height)
            }
        }
    }

    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        let sendableChange = SendableValue(change)
        DispatchQueue.fw.mainAsync { [weak self] in
            guard let self, let scrollView else { return }

            if keyPath == "contentOffset" {
                guard let contentOffset = sendableChange.value?[.newKey] as? CGPoint else { return }

                if (scrollView.fw.infiniteScrollView?.isActive ?? false) ||
                    (contentOffset.y + scrollView.adjustedContentInset.top - scrollView.contentInset.top) > 0 {
                    if pullingPercent > 0 { pullingPercent = 0 }
                    if state != .idle {
                        state = .idle
                    }
                } else if state != .loading {
                    scrollViewDidScroll(contentOffset)
                } else {
                    var currentInset = scrollView.contentInset
                    currentInset.top = originalInset.top + bounds.size.height
                    scrollView.contentInset = currentInset
                }
            } else if keyPath == "contentSize" {
                layoutSubviews()
                frame = CGRect(x: 0, y: -height, width: bounds.size.width, height: height)
            } else if keyPath == "frame" {
                layoutSubviews()
            }
        }
    }

    // MARK: - Public
    /// 拖动手势状态监听回调方法
    @objc open func gestureRecognizerStateChanged(_ gestureRecognizer: UIPanGestureRecognizer) {
        if gestureRecognizer.state == .began {
            isActive = false
            scrollView?.fw.infiniteScrollView?.isActive = false
        }
    }

    /// 重置滚动视图contentInset
    open func resetScrollViewContentInset(animated: Bool = true) {
        guard let scrollView else { return }

        var currentInsets = scrollView.contentInset
        currentInsets.top = originalInset.top
        setScrollViewContentInset(currentInsets, pullingPercent: 0, animated: animated)
    }

    /// 自定义各状态的标题
    open func setTitle(_ title: String?, for state: PullRefreshState) {
        let title = title ?? ""
        if state == .all {
            titles = [title, title, title]
        } else {
            titles[state.rawValue] = title
        }

        setNeedsLayout()
        layoutIfNeeded()
    }

    /// 自定义各状态的副标题
    open func setSubtitle(_ subtitle: String?, for state: PullRefreshState) {
        let subtitle = subtitle ?? ""
        if state == .all {
            subtitles = [subtitle, subtitle, subtitle]
        } else {
            subtitles[state.rawValue] = subtitle
        }

        setNeedsLayout()
        layoutIfNeeded()
    }

    /// 自定义各状态的视图
    open func setCustomView(_ view: UIView?, for state: PullRefreshState) {
        let viewPlaceholder: Any = view ?? ""
        if state == .all {
            viewForState = [viewPlaceholder, viewPlaceholder, viewPlaceholder]
        } else {
            viewForState[state.rawValue] = viewPlaceholder
        }

        setNeedsLayout()
        layoutIfNeeded()
    }

    /// 自定义动画视图，自动绑定下拉刷新动画
    open func setAnimationView(_ animationView: UIView & ProgressViewPlugin & IndicatorViewPlugin) {
        setCustomView(animationView, for: .all)

        animationProgressBlock = { [weak animationView] view, progress in
            guard view.state != .loading else { return }
            animationView?.progress = progress
        }

        animationStateBlock = { [weak animationView] _, state in
            if state == .idle {
                animationView?.stopAnimating()
            } else if state == .loading {
                animationView?.startAnimating()
            }
        }
    }

    /// 开始加载动画
    open func startAnimating() {
        if let scrollView {
            scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: -(frame.size.height + originalInset.top)), animated: true)
        }

        state = .loading
    }

    /// 停止加载动画
    open func stopAnimating() {
        guard isAnimating else { return }

        state = .idle

        if let scrollView {
            scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: -originalInset.top), animated: true)
        }
    }

    /// 是否正在执行动画
    open var isAnimating: Bool {
        state != .idle
    }

    // MARK: - Private
    private func scrollViewDidScroll(_ contentOffset: CGPoint) {
        guard let scrollView else { return }

        let adjustedContentOffsetY = contentOffset.y + scrollView.adjustedContentInset.top - scrollView.contentInset.top
        let progress = -adjustedContentOffsetY / height
        if progress > 0 { isActive = true }
        animationProgressBlock?(self, max(min(progress, 1.0), 0.0))
        progressBlock?(self, max(min(progress, 1.0), 0.0))

        let scrollOffsetThreshold = frame.origin.y - originalInset.top
        if !scrollView.isDragging && state == .triggered {
            state = .loading
        } else if adjustedContentOffsetY < scrollOffsetThreshold && scrollView.isDragging && state == .idle {
            state = .triggered
            userTriggered = true
        } else if adjustedContentOffsetY >= scrollOffsetThreshold && state != .idle {
            state = .idle
        } else if adjustedContentOffsetY >= scrollOffsetThreshold && state == .idle {
            pullingPercent = max(min(-adjustedContentOffsetY / height, 1.0), 0.0)
        }
    }

    private func setScrollViewContentInsetForLoading() {
        guard let scrollView else { return }

        var currentInsets = scrollView.contentInset
        currentInsets.top = originalInset.top + bounds.size.height
        setScrollViewContentInset(currentInsets, pullingPercent: 1)
    }

    private func setScrollViewContentInset(_ contentInset: UIEdgeInsets, pullingPercent: CGFloat, animated: Bool = true) {
        UIView.animate(withDuration: animated ? 0.3 : 0, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
            self.scrollView?.contentInset = contentInset
        } completion: { _ in
            self.pullingPercent = pullingPercent
        }
    }

    private func rotateArrow(_ degrees: CGFloat, hide: Bool) {
        UIView.animate(withDuration: 0.2, delay: 0, options: .allowUserInteraction, animations: {
            self.arrowView.layer.transform = CATransform3DMakeRotation(degrees, 0, 0, 1)
            self.arrowView.layer.opacity = hide ? 0 : 1
        }, completion: nil)
    }
}

private class PullRefreshArrowView: UIView {
    var arrowColor: UIColor? = .gray {
        didSet {
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.move(to: CGPoint(x: 7.5, y: 8.5))
        context.addLine(to: CGPoint(x: 7.5, y: 31.5))
        context.move(to: CGPoint(x: 0, y: 24))
        context.addLine(to: CGPoint(x: 7.5, y: 31.5))
        context.addLine(to: CGPoint(x: 15, y: 24))
        context.setLineWidth(1.5)
        arrowColor?.setStroke()
        context.strokePath()
    }
}

// MARK: - InfiniteScrollView
/// 上拉追加状态枚举
public enum InfiniteScrollState: Int, Sendable {
    case idle = 0
    case triggered
    case loading
    case all
}

/// 上拉追加视图，默认高度60
///
/// [SVPullToRefresh](https://github.com/samvermette/SVPullToRefresh)
open class InfiniteScrollView: UIView {
    // MARK: - Accessor
    /// 全局高度设置
    public static var height: CGFloat = 60

    /// 当前高度，默认全局高度
    open var height: CGFloat {
        get {
            _height > 0 ? _height : InfiniteScrollView.height
        }
        set {
            _height = newValue

            var newFrame = frame
            newFrame.size.height = newValue > 0 ? newValue : InfiniteScrollView.height
            frame = newFrame
        }
    }

    private var _height: CGFloat = 0

    /// 是否启用，默认true
    open var enabled = true

    /// 原始边距
    open var originalInset: UIEdgeInsets = .zero

    /// 预加载高度，默认0
    open var preloadHeight: CGFloat = 0

    /// 指示器颜色
    open var indicatorColor: UIColor? {
        get { indicatorView.indicatorColor }
        set { indicatorView.indicatorColor = newValue }
    }

    /// 指示器偏移
    open var indicatorPadding: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }

    /// 是否显示完成视图，默认true
    open var showsFinishedView = true

    /// 自定义完成视图偏移
    open var finishedPadding: CGFloat = 0

    /// 是否是用户触发
    open var userTriggered = false

    /// 自定义状态改变句柄
    open var stateBlock: ((_ view: InfiniteScrollView, _ state: InfiniteScrollState) -> Void)?

    /// 自定义进度句柄
    open var progressBlock: ((_ view: InfiniteScrollView, _ progress: CGFloat) -> Void)?

    /// 自定义完成句柄
    open var finishedBlock: ((_ view: InfiniteScrollView, _ finished: Bool) -> Void)?

    /// 自定义数据是否为空句柄，返回true时不显示finishedView
    open var emptyDataBlock: ((_ scrollView: UIScrollView) -> Bool)?

    /// 自定义上拉追加句柄
    open var infiniteScrollBlock: (() -> Void)?

    /// 自定义上拉追加目标和动作
    open weak var target: AnyObject?
    open var action: Selector?

    /// 绑定滚动视图
    open weak var scrollView: UIScrollView?

    /// 是否已监听
    open var isObserving = false

    /// 是否已完成追加
    open var finished = false {
        didSet {
            if showsFinishedView {
                finishedView.isHidden = !finished || isDataEmpty
                finishedBlock?(self, finished)
                return
            }

            guard finished != oldValue else { return }
            finishedView.isHidden = true
            if finished {
                resetScrollViewContentInset()
            } else {
                setScrollViewContentInsetForInfiniteScrolling()
            }
            finishedBlock?(self, finished)
        }
    }

    /// 数据是否为空，为空时始终隐藏finishedView。默认自动判断totalDataCount，可自定义
    open var isDataEmpty: Bool {
        guard let scrollView else { return true }

        if let emptyDataBlock {
            return emptyDataBlock(scrollView)
        }

        return scrollView.fw.totalDataCount <= 0
    }

    /// 上拉追加状态
    open var state: InfiniteScrollState = .idle {
        didSet {
            guard state != oldValue else { return }

            let customView = viewForState[state.rawValue] as? UIView
            let customViewChanged = customView != currentCustomView
            if customViewChanged || customView == nil {
                currentCustomView?.removeFromSuperview()
                currentCustomView = nil
            }

            if let customView {
                if customViewChanged {
                    currentCustomView = customView
                    addSubview(customView)
                }

                let viewBounds = customView.bounds
                let paddingY = indicatorPadding / 2
                let origin = CGPoint(x: round((bounds.size.width - viewBounds.size.width) / 2), y: paddingY + round((bounds.size.height - viewBounds.size.height) / 2))
                customView.frame = CGRect(x: origin.x, y: origin.y, width: viewBounds.size.width, height: viewBounds.size.height)

                switch state {
                case .idle:
                    if !customViewChanged {
                        currentCustomView?.removeFromSuperview()
                        currentCustomView = nil
                    }
                case .triggered:
                    isActive = true
                case .loading:
                    break
                default:
                    break
                }
            } else {
                let viewBounds = indicatorView.bounds
                let paddingY = indicatorPadding / 2
                let origin = CGPoint(x: round((bounds.size.width - viewBounds.size.width) / 2), y: paddingY + round((bounds.size.height - viewBounds.size.height) / 2))
                indicatorView.frame = CGRect(x: origin.x, y: origin.y, width: viewBounds.size.width, height: viewBounds.size.height)

                switch state {
                case .idle:
                    indicatorView.stopAnimating()
                case .triggered:
                    isActive = true
                    indicatorView.startAnimating()
                case .loading:
                    indicatorView.startAnimating()
                default:
                    break
                }
            }

            if oldValue == .triggered && state == .loading && enabled {
                if let infiniteScrollBlock {
                    infiniteScrollBlock()
                } else if let target, let action, target.responds(to: action) {
                    _ = target.perform(action)
                }
            }

            animationStateBlock?(self, state)
            stateBlock?(self, state)
        }
    }

    // MARK: - Subviews
    /// 完成视图
    open lazy var finishedView: UIView = {
        let result = finishedLabel
        result.isHidden = true
        addSubview(result)
        return result
    }() {
        didSet {
            oldValue.removeFromSuperview()
            finishedView.isHidden = true
            addSubview(finishedView)

            setNeedsLayout()
            layoutIfNeeded()
        }
    }

    /// 指示器视图
    open lazy var indicatorView: UIView & IndicatorViewPlugin = {
        let style: IndicatorViewStyle = .refreshPullup
        let result = UIView.fw.indicatorView(style: style)
        if style.indicatorColor == nil {
            result.indicatorColor = .gray
        }
        addSubview(result)
        return result
    }() {
        didSet {
            oldValue.removeFromSuperview()
            addSubview(indicatorView)

            setNeedsLayout()
            layoutIfNeeded()
        }
    }

    /// 完成文本标签
    open lazy var finishedLabel: UILabel = {
        let result = UILabel()
        result.font = UIFont.systemFont(ofSize: 14)
        result.textAlignment = .center
        result.textColor = .gray
        result.text = FrameworkBundle.localizedString("fw.refreshFinished")
        result.sizeToFit()
        return result
    }()

    private var viewForState: [Any] = ["", "", ""]

    private weak var currentCustomView: UIView?
    private var animationStateBlock: ((InfiniteScrollView, InfiniteScrollState) -> Void)?
    private var animationProgressBlock: ((InfiniteScrollView, CGFloat) -> Void)?

    var isActive = false

    // MARK: - Lifecycle
    override public init(frame: CGRect) {
        super.init(frame: frame)

        didInitialize()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        didInitialize()
    }

    private func didInitialize() {
        autoresizingMask = .flexibleWidth
    }

    override open func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)

        if let scrollView = superview as? UIScrollView, newSuperview == nil,
           scrollView.fw.showInfiniteScroll {
            if isObserving {
                scrollView.removeObserver(self, forKeyPath: "contentOffset")
                scrollView.removeObserver(self, forKeyPath: "contentSize")
                scrollView.panGestureRecognizer.fw.unobserveProperty(\.state, target: self, action: #selector(gestureRecognizerStateChanged(_:)))
                isObserving = false
            }
        }
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        let paddingY = indicatorPadding / 2
        let indicatorOrigin = CGPoint(x: bounds.size.width / 2 - indicatorView.bounds.size.width / 2, y: paddingY + (bounds.size.height / 2 - indicatorView.bounds.size.height / 2))
        indicatorView.frame = CGRect(x: indicatorOrigin.x, y: indicatorOrigin.y, width: indicatorView.bounds.size.width, height: indicatorView.bounds.size.height)

        let finishedOrigin = CGPoint(x: bounds.size.width / 2 - finishedView.bounds.size.width / 2, y: (finishedPadding / 2) + (bounds.size.height / 2 - finishedView.bounds.size.height / 2))
        finishedView.frame = CGRect(x: finishedOrigin.x, y: finishedOrigin.y, width: finishedView.bounds.size.width, height: finishedView.bounds.size.height)
    }

    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        let sendableChange = SendableValue(change)
        DispatchQueue.fw.mainAsync { [weak self] in
            guard let self, let scrollView else { return }

            if keyPath == "contentOffset" {
                if finished { return }
                guard let contentOffset = sendableChange.value?[.newKey] as? CGPoint else { return }

                if (scrollView.fw.pullRefreshView?.isActive ?? false) ||
                    (contentOffset.y + ceil(scrollView.adjustedContentInset.top) - scrollView.contentInset.top) < 0 {
                    if state != .idle {
                        state = .idle
                    }
                } else if state != .loading && enabled {
                    scrollViewDidScroll(contentOffset)
                }
            } else if keyPath == "contentSize" {
                layoutSubviews()
                frame = CGRect(x: 0, y: scrollView.contentSize.height, width: bounds.size.width, height: height)
            }
        }
    }

    // MARK: - Public
    /// 拖动手势状态监听回调方法
    @objc open func gestureRecognizerStateChanged(_ gestureRecognizer: UIPanGestureRecognizer) {
        if finished { return }

        if gestureRecognizer.state == .began {
            isActive = false
            scrollView?.fw.pullRefreshView?.isActive = false
        } else if gestureRecognizer.state == .ended && state == .triggered {
            if let scrollView, (scrollView.contentOffset.y + scrollView.adjustedContentInset.top - scrollView.contentInset.top) >= 0 {
                state = .loading
            } else {
                state = .idle
            }
        }
    }

    /// 重置滚动视图contentInset
    open func resetScrollViewContentInset(animated: Bool = true) {
        guard let scrollView else { return }

        var currentInsets = scrollView.contentInset
        currentInsets.bottom = originalInset.bottom
        setScrollViewContentInset(currentInsets, animated: animated)
    }

    /// 设置滚动视图contentInset到追加位置
    open func setScrollViewContentInsetForInfiniteScrolling(animated: Bool = true) {
        guard let scrollView else { return }

        var currentInsets = scrollView.contentInset
        currentInsets.bottom = originalInset.bottom + height
        setScrollViewContentInset(currentInsets, animated: animated)
    }

    /// 自定义各状态的视图
    open func setCustomView(_ view: UIView?, for state: InfiniteScrollState) {
        let viewPlaceholder: Any = view ?? ""
        if state == .all {
            viewForState = [viewPlaceholder, viewPlaceholder, viewPlaceholder]
        } else {
            viewForState[state.rawValue] = viewPlaceholder
        }

        setNeedsLayout()
        layoutIfNeeded()
    }

    /// 自定义动画视图，自动绑定上拉追加动画
    open func setAnimationView(_ animationView: UIView & ProgressViewPlugin & IndicatorViewPlugin) {
        setCustomView(animationView, for: .all)

        animationProgressBlock = { [weak animationView] view, progress in
            guard view.state != .loading else { return }
            animationView?.progress = progress
        }

        animationStateBlock = { [weak animationView] _, state in
            if state == .idle {
                animationView?.stopAnimating()
            } else if state == .loading {
                animationView?.startAnimating()
            }
        }
    }

    /// 开始追加动画
    open func startAnimating() {
        state = .loading
    }

    /// 停止动画
    open func stopAnimating() {
        state = .idle
    }

    /// 是否正在执行动画
    open var isAnimating: Bool {
        state != .idle
    }

    // MARK: - Private
    private func scrollViewDidScroll(_ contentOffset: CGPoint) {
        guard let scrollView else { return }

        let adjustedContentOffsetY = contentOffset.y + (scrollView.adjustedContentInset.top - scrollView.contentInset.top)
        if animationProgressBlock != nil || progressBlock != nil {
            let scrollHeight = max(scrollView.contentSize.height - scrollView.bounds.size.height + (scrollView.adjustedContentInset.top - scrollView.contentInset.top) + scrollView.contentInset.bottom, height)
            let progress = (height + adjustedContentOffsetY - scrollHeight) / height
            animationProgressBlock?(self, max(min(progress, 1.0), 0.0))
            progressBlock?(self, max(min(progress, 1.0), 0.0))
        }

        let scrollOffsetThreshold = max(scrollView.contentSize.height - scrollView.bounds.size.height + (scrollView.adjustedContentInset.top - scrollView.contentInset.top) - preloadHeight, 0)
        if !scrollView.isDragging && state == .triggered {
            state = .loading
        } else if adjustedContentOffsetY > scrollOffsetThreshold && state == .idle && scrollView.isDragging {
            state = .triggered
            userTriggered = true
        } else if adjustedContentOffsetY < scrollOffsetThreshold && state != .idle {
            state = .idle
        }
    }

    private func setScrollViewContentInset(_ contentInset: UIEdgeInsets, animated: Bool = true) {
        guard let scrollView, contentInset != scrollView.contentInset else { return }

        UIView.animate(withDuration: animated ? 0.3 : 0, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
            scrollView.contentInset = contentInset
        }, completion: nil)
    }
}
