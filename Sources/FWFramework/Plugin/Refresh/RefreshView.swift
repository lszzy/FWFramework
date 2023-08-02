//
//  RefreshView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - PullRefreshView
/// 下拉刷新状态枚举
public enum PullRefreshState: Int {
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
    
    /// 指示器边距
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
                    if let pullRefreshBlock = pullRefreshBlock {
                        pullRefreshBlock()
                    } else if let target = self.target, let action = self.action, target.responds(to: action) {
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
        let result = UIView.fw_indicatorView(style: .refresh)
        result.indicatorColor = .gray
        addSubview(result)
        return result
    }() {
        didSet {
            let indicatorColor = indicatorView.indicatorColor
            oldValue.removeFromSuperview()
            indicatorView.indicatorColor = indicatorColor
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
        AppBundle.localizedString("fw.refreshIdle"),
        AppBundle.localizedString("fw.refreshTriggered"),
        AppBundle.localizedString("fw.refreshLoading"),
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
    public override init(frame: CGRect) {
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
    
    open override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        if let scrollView = superview as? UIScrollView, newSuperview == nil,
           scrollView.fw_showPullRefresh {
            if isObserving {
                scrollView.removeObserver(self, forKeyPath: "contentOffset")
                scrollView.removeObserver(self, forKeyPath: "contentSize")
                scrollView.removeObserver(self, forKeyPath: "frame")
                scrollView.panGestureRecognizer.fw_unobserveProperty("state", target: self, action: #selector(gestureRecognizer(_:stateChanged:)))
                isObserving = false
            }
        }
    }
    
    open override func layoutSubviews() {
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
        
        if let customView = customView {
            if customViewChanged {
                currentCustomView = customView
                addSubview(customView)
            }
            let viewBounds = customView.bounds
            let paddingY = indicatorPadding > 0 ? (indicatorPadding / 2) : 0
            let origin = CGPoint(x: round((bounds.size.width - viewBounds.size.width) / 2), y: paddingY + round((bounds.size.height - viewBounds.size.height) / 2))
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
            let paddingY = indicatorPadding > 0 ? (indicatorPadding / 2) : 0
            let labelMaxWidth = bounds.size.width - margin - leftViewWidth
            
            titleLabel.text = showsTitleLabel ? titles[state.rawValue] : nil
            subtitleLabel.text = showsTitleLabel ? subtitles[state.rawValue] : nil
            let titleSize = titleLabel.text?.boundingRect(
                with: CGSize(width: labelMaxWidth, height: titleLabel.font.lineHeight),
                options: [.usesFontLeading, .usesLineFragmentOrigin],
                attributes: [.font: titleLabel.font as Any],
                context: nil).size ?? .zero
            let subtitleSize = subtitleLabel.text?.boundingRect(
                with: CGSize(width: labelMaxWidth, height: subtitleLabel.font.lineHeight),
                options: [.usesFontLeading, .usesLineFragmentOrigin],
                attributes: [.font: subtitleLabel.font as Any],
                context: nil).size ?? .zero
            
            let maxLabelWidth = max(titleSize.width, subtitleSize.width)
            let totalMaxWidth = leftViewWidth + maxLabelWidth + (maxLabelWidth > 0 ? margin : 0)
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
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let scrollView = scrollView else { return }

        if keyPath == "contentOffset" {
            guard let contentOffset = change?[.newKey] as? CGPoint else { return }

            if (scrollView.fw_infiniteScrollView?.isActive ?? false) ||
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
            frame = CGRect(x: 0, y: -scrollView.fw_pullRefreshHeight, width: bounds.size.width, height: scrollView.fw_pullRefreshHeight)
        } else if keyPath == "frame" {
            layoutSubviews()
        }
    }

    // MARK: - Public
    /// 拖动手势状态监听回调方法
    @objc open func gestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer, stateChanged change: [AnyHashable: Any]) {
        let state = change[NSKeyValueChangeKey.newKey] as? Int ?? 0
        if state == UIGestureRecognizer.State.began.rawValue {
            isActive = false
            scrollView?.fw_infiniteScrollView?.isActive = false
        }
    }
    
    /// 重置滚动视图contentInset
    open func resetScrollViewContentInset() {
        guard let scrollView = scrollView else { return }
        
        var currentInsets = scrollView.contentInset
        currentInsets.top = originalInset.top
        setScrollViewContentInset(currentInsets, pullingPercent: 0)
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

        animationProgressBlock = { [weak animationView] (view, progress) in
            guard view.state != .loading else { return }
            animationView?.progress = progress
        }

        animationStateBlock = { [weak animationView] (view, state) in
            if state == .idle {
                animationView?.stopAnimating()
            } else if state == .loading {
                animationView?.startAnimating()
            }
        }
    }

    /// 开始加载动画
    open func startAnimating() {
        if let scrollView = scrollView {
            scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: -(frame.size.height + originalInset.top)), animated: true)
        }
        
        state = .loading
    }
    
    /// 停止加载动画
    open func stopAnimating() {
        guard isAnimating else { return }

        state = .idle

        if let scrollView = scrollView {
            scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: -originalInset.top), animated: true)
        }
    }
    
    /// 是否正在动画
    open var isAnimating: Bool {
        return state != .idle
    }
    
    // MARK: - Private
    private func scrollViewDidScroll(_ contentOffset: CGPoint) {
        guard let scrollView = scrollView else { return }
        
        let adjustedContentOffsetY = contentOffset.y + scrollView.adjustedContentInset.top - scrollView.contentInset.top
        let progress = -adjustedContentOffsetY / scrollView.fw_pullRefreshHeight
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
            pullingPercent = max(min(-adjustedContentOffsetY / scrollView.fw_pullRefreshHeight, 1.0), 0.0)
        }
    }
    
    private func setScrollViewContentInsetForLoading() {
        guard let scrollView = scrollView else { return }
        
        var currentInsets = scrollView.contentInset
        currentInsets.top = originalInset.top + bounds.size.height
        setScrollViewContentInset(currentInsets, pullingPercent: 1)
    }
    
    private func setScrollViewContentInset(_ contentInset: UIEdgeInsets, pullingPercent: CGFloat) {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
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

// MARK: - InfiniteScrollView
/// 上拉追加状态枚举
public enum InfiniteScrollState: Int {
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
    public static var height: CGFloat = 60
    
    open var enabled = true
    open var originalInset: UIEdgeInsets = .zero
    open var preloadHeight: CGFloat = 0
    open var indicatorColor: UIColor? {
        get { indicatorView.indicatorColor }
        set {
            indicatorView.indicatorColor = newValue
        }
    }
    open var indicatorPadding: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }
    open var finished = false {
        didSet {
            if finished == oldValue { return }
            
            if showsFinishedView {
                finishedView.isHidden = !finished
            } else {
                if finished {
                    resetScrollViewContentInset()
                } else {
                    setScrollViewContentInsetForInfiniteScrolling()
                }
            }
            finishedBlock?(self, finished)
        }
    }
    open var showsFinishedView = true
    open var finishedPadding: CGFloat = 0
    
    open var state: InfiniteScrollState = .idle {
        didSet {
            guard state != oldValue else { return }

            let customView = self.viewForState[state.rawValue] as? UIView
            let hasCustomView = customView != nil
            let customViewChanged = customView != currentCustomView

            if customViewChanged || !hasCustomView {
                currentCustomView?.removeFromSuperview()
                currentCustomView = nil
            }

            if hasCustomView {
                if customViewChanged {
                    currentCustomView = customView
                    addSubview(customView!)
                }

                let viewBounds = customView!.bounds
                let paddingY = indicatorPadding > 0 ? (indicatorPadding / 2) : 0
                let origin = CGPoint(x: round((bounds.size.width - viewBounds.size.width) / 2), y: paddingY + round((bounds.size.height - viewBounds.size.height) / 2))
                customView!.frame = CGRect(x: origin.x, y: origin.y, width: viewBounds.size.width, height: viewBounds.size.height)

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
                let paddingY = indicatorPadding > 0 ? (indicatorPadding / 2) : 0
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
                if let infiniteScrollBlock = self.infiniteScrollBlock {
                    infiniteScrollBlock()
                } else if let target = self.target, let action = self.action, target.responds(to: action) {
                    _ = target.perform(action)
                }
            }

            animationStateBlock?(self, state)
            stateBlock?(self, state)
        }
    }
    open var userTriggered = false
    open var stateBlock: ((_ view: InfiniteScrollView, _ state: InfiniteScrollState) -> Void)?
    open var progressBlock: ((_ view: InfiniteScrollView, _ progress: CGFloat) -> Void)?
    open var finishedBlock: ((_ view: InfiniteScrollView, _ finished: Bool) -> Void)?
    open var infiniteScrollBlock: (() -> Void)?
    open weak var target: AnyObject?
    open var action: Selector?
    open weak var scrollView: UIScrollView?
    open var isObserving = false
    
    // MARK: - Subviews
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
    
    open lazy var indicatorView: UIView & IndicatorViewPlugin = {
        let result = UIView.fw_indicatorView(style: .refresh)
        result.indicatorColor = .gray
        addSubview(result)
        return result
    }() {
        didSet {
            let indicatorColor = indicatorView.indicatorColor
            oldValue.removeFromSuperview()
            indicatorView.indicatorColor = indicatorColor
            addSubview(indicatorView)
            
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    open lazy var finishedLabel: UILabel = {
        let result = UILabel()
        result.font = UIFont.systemFont(ofSize: 14)
        result.textAlignment = .center
        result.textColor = .gray
        result.text = AppBundle.localizedString("fw.refreshFinished")
        result.sizeToFit()
        return result
    }()
    
    private var viewForState: [Any] = ["", "", "", ""]
    private weak var currentCustomView: UIView?
    private var animationStateBlock: ((InfiniteScrollView, InfiniteScrollState) -> Void)?
    private var animationProgressBlock: ((InfiniteScrollView, CGFloat) -> Void)?
    var isActive = false
    
    // MARK: - Lifecycle
    public override init(frame: CGRect) {
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
    
    open override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        if let scrollView = self.superview as? UIScrollView {
            if scrollView.fw_showInfiniteScroll {
                if self.isObserving {
                    scrollView.removeObserver(self, forKeyPath: "contentOffset")
                    scrollView.removeObserver(self, forKeyPath: "contentSize")
                    scrollView.panGestureRecognizer.fw_unobserveProperty("state", target: self, action: #selector(gestureRecognizer(_:stateChanged:)))
                    self.isObserving = false
                }
            }
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        let paddingY = self.indicatorPadding > 0 ? (self.indicatorPadding / 2) : 0
        let indicatorOrigin = CGPoint(x: self.bounds.size.width / 2 - self.indicatorView.bounds.size.width / 2, y: paddingY + (self.bounds.size.height / 2 - self.indicatorView.bounds.size.height / 2))
        self.indicatorView.frame = CGRect(x: indicatorOrigin.x, y: indicatorOrigin.y, width: self.indicatorView.bounds.size.width, height: self.indicatorView.bounds.size.height)

        let finishedPaddingY = self.finishedPadding > 0 ? (self.finishedPadding / 2) : 0
        let finishedOrigin = CGPoint(x: self.bounds.size.width / 2 - self.finishedView.bounds.size.width / 2, y: finishedPaddingY + (self.bounds.size.height / 2 - self.finishedView.bounds.size.height / 2))
        self.finishedView.frame = CGRect(x: finishedOrigin.x, y: finishedOrigin.y, width: self.finishedView.bounds.size.width, height: self.finishedView.bounds.size.height)
    }
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath, let scrollView = scrollView else { return }

        if keyPath == "contentOffset" {
            if finished { return }

            guard let contentOffset = change?[.newKey] as? CGPoint else { return }

            if (scrollView.fw_pullRefreshView?.isActive ?? false) ||
                (contentOffset.y + ceil(scrollView.adjustedContentInset.top) - scrollView.contentInset.top) < 0 {
                if state != .idle {
                    state = .idle
                }
            } else if state != .loading && enabled {
                scrollViewDidScroll(contentOffset)
            }
        } else if keyPath == "contentSize" {
            layoutSubviews()
            frame = CGRect(x: 0, y: scrollView.contentSize.height, width: bounds.size.width, height: scrollView.fw_infiniteScrollHeight)
        }
    }
    
    // MARK: - Public
    @objc open func gestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer, stateChanged change: [AnyHashable: Any]) {
        if self.finished {
            return
        }

        let state = (change[NSKeyValueChangeKey.newKey] as? Int) ?? 0
        if state == UIGestureRecognizer.State.began.rawValue {
            self.isActive = false
            self.scrollView?.fw_pullRefreshView?.isActive = false
        } else if state == UIGestureRecognizer.State.ended.rawValue && self.state == .triggered {
            if let scrollView = scrollView, (scrollView.contentOffset.y + scrollView.adjustedContentInset.top - scrollView.contentInset.top) >= 0 {
                self.state = .loading
            } else {
                self.state = .idle
            }
        }
    }
    
    func scrollViewDidScroll(_ contentOffset: CGPoint) {
        guard let scrollView = scrollView else { return }
        
        let adjustedContentOffsetY = contentOffset.y + (scrollView.adjustedContentInset.top - scrollView.contentInset.top)
        if animationProgressBlock != nil || progressBlock != nil {
            let scrollHeight = max(scrollView.contentSize.height - scrollView.bounds.size.height + (scrollView.adjustedContentInset.top - scrollView.contentInset.top) + scrollView.contentInset.bottom, scrollView.fw_infiniteScrollHeight)
            let progress = (scrollView.fw_infiniteScrollHeight + adjustedContentOffsetY - scrollHeight) / scrollView.fw_infiniteScrollHeight
            if let animationProgressBlock = animationProgressBlock {
                animationProgressBlock(self, max(min(progress, 1.0), 0.0))
            }
            if let progressBlock = progressBlock {
                progressBlock(self, max(min(progress, 1.0), 0.0))
            }
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
    
    open func resetScrollViewContentInset() {
        guard let scrollView = scrollView else { return }
        
        var currentInsets = scrollView.contentInset
        currentInsets.bottom = originalInset.bottom
        setScrollViewContentInset(currentInsets)
    }
    open func setScrollViewContentInsetForInfiniteScrolling() {
        guard let scrollView = scrollView else { return }
        
        var currentInsets = scrollView.contentInset
        currentInsets.bottom = originalInset.bottom + scrollView.fw_infiniteScrollHeight
        setScrollViewContentInset(currentInsets)
    }
    
    open func setCustomView(_ view: UIView?, for state: InfiniteScrollState) {
        let viewPlaceholder: Any = view ?? ""
        if state == .all {
            viewForState = [viewPlaceholder, viewPlaceholder, viewPlaceholder]
        } else {
            viewForState[state.rawValue] = viewPlaceholder
        }

        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    open func setAnimationView(_ animationView: UIView & ProgressViewPlugin & IndicatorViewPlugin) {
        self.setCustomView(animationView, for: .all)

        self.animationProgressBlock = { [weak animationView] view, progress in
            guard view.state != .loading else { return }
            animationView?.progress = progress
        }

        self.animationStateBlock = { [weak animationView] view, state in
            if state == .idle {
                animationView?.stopAnimating()
            } else if state == .loading {
                animationView?.startAnimating()
            }
        }
    }
    
    open func startAnimating() {
        state = .loading
    }
    
    open func stopAnimating() {
        state = .idle
    }
    
    open var isAnimating: Bool {
        return state != .idle
    }
    
    // MARK: - Private
    private func setScrollViewContentInset(_ contentInset: UIEdgeInsets) {
        guard contentInset != (scrollView?.contentInset ?? .zero) else { return }

        UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
            self.scrollView?.contentInset = contentInset
        }, completion: nil)
    }
    
}

// MARK: - PullRefreshArrowView
fileprivate class PullRefreshArrowView: UIView {
    
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
