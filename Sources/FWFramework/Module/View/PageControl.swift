//
//  PageControl.swift
//  FWFramework
//
//  Created by wuyong on 2023/3/29.
//

import UIKit

// MARK: - PageControl
/// 分页控件事件代理
@MainActor public protocol PageControlDelegate: NSObjectProtocol {
    /// 选中指定页回调方法
    func pageControl(_ pageControl: PageControl, didSelectPage page: Int)
}

/// 分页控件
///
/// [TAPageControl](https://github.com/TanguyAladenise/TAPageControl)
open class PageControl: UIControl {
    /// 点视图类
    open var dotViewClass: (UIView & DotViewProtocol).Type? = DotView.self {
        didSet {
            dotSize = .zero
            resetDotViews()
        }
    }

    /// 点视图句柄
    open var customDotView: (@MainActor @Sendable (UIView) -> Void)?

    /// 点图片
    open var dotImage: UIImage? {
        didSet {
            resetDotViews()
            dotViewClass = nil
        }
    }

    /// 当前点图片
    open var currentDotImage: UIImage? {
        didSet {
            resetDotViews()
            dotViewClass = nil
        }
    }

    /// 点大小
    open var dotSize: CGSize {
        get {
            if let dotImage, _dotSize.equalTo(.zero) {
                _dotSize = dotImage.size
            } else if dotViewClass != nil, _dotSize.equalTo(.zero) {
                _dotSize = CGSize(width: 8, height: 8)
            }
            return _dotSize
        }
        set {
            _dotSize = newValue
        }
    }

    private var _dotSize: CGSize = .init(width: 8, height: 8)

    /// 当前点大小，默认zero为点大小
    open var currentDotSize: CGSize {
        get {
            if let currentDotImage, _currentDotSize.equalTo(.zero) {
                _currentDotSize = currentDotImage.size
            } else if _currentDotSize.equalTo(.zero) {
                _currentDotSize = dotSize
            }
            return _currentDotSize
        }
        set {
            _currentDotSize = newValue
        }
    }

    private var _currentDotSize: CGSize = .zero

    /// 点颜色
    open var dotColor: UIColor?

    /// 当前点颜色
    open var currentDotColor: UIColor?

    /// 点间距
    open var spacingBetweenDots: CGFloat = 8 {
        didSet { resetDotViews() }
    }

    /// 事件代理
    open weak var delegate: PageControlDelegate?

    /// 总页数，默认0
    open var numberOfPages: Int = 0 {
        didSet { resetDotViews() }
    }

    /// 当前页数，默认0
    open var currentPage: Int {
        get {
            _currentPage
        }
        set {
            var page = newValue
            if numberOfPages == 0 || page == _currentPage {
                _currentPage = page
                return
            }

            if page > numberOfPages - 1 {
                page = numberOfPages - 1
            }

            changeActivity(false, at: _currentPage)
            _currentPage = page
            changeActivity(true, at: _currentPage)
        }
    }

    private var _currentPage: Int = 0

    /// 单页时是否隐藏，默认false
    open var hidesForSinglePage: Bool = false

    /// 是否resize保持居中，默认true
    open var shouldResizeFromCenter: Bool = true

    private var dots: [UIView] = []

    override public init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let view = touches.first?.view, view != self else { return }
        if let index = dots.firstIndex(of: view) {
            delegate?.pageControl(self, didSelectPage: index)
        }
    }

    override open func sizeToFit() {
        updateFrame(true)
    }

    /// 计算指定页数时的显示尺寸
    open func sizeForNumberOfPages(_ pageCount: Int) -> CGSize {
        CGSize(width: (dotSize.width + spacingBetweenDots) * CGFloat(pageCount) - spacingBetweenDots + (currentDotSize.width - dotSize.width), height: max(dotSize.height, currentDotSize.height))
    }

    private func updateDots() {
        guard numberOfPages > 0 else { return }

        for i in 0..<numberOfPages {
            let dot = i < dots.count ? dots[i] : generateDotView()
            updateDotFrame(dot, at: i, active: false)
            changeActivity(false, at: i)
        }
        changeActivity(true, at: currentPage)

        hideForSinglePage()
    }

    private func updateFrame(_ overrideExistingFrame: Bool) {
        let center = center
        let requiredSize = sizeForNumberOfPages(numberOfPages)

        if overrideExistingFrame || ((CGRectGetWidth(frame) < requiredSize.width || CGRectGetHeight(frame) < requiredSize.height) && !overrideExistingFrame) {
            frame = CGRectMake(CGRectGetMinX(frame), CGRectGetMinY(frame), requiredSize.width, requiredSize.height)
            if shouldResizeFromCenter {
                self.center = center
            }
        }

        resetDotViews()
    }

    private func updateDotFrame(_ dot: UIView, at index: Int, active: Bool) {
        let size = (active && index == currentPage) ? currentDotSize : dotSize
        let x = ((CGRectGetWidth(frame) - sizeForNumberOfPages(numberOfPages).width) / 2) + (dotSize.width + spacingBetweenDots) * CGFloat(index) + ((active && index > currentPage) ? (currentDotSize.width - dotSize.width) : 0)
        let y = (CGRectGetHeight(frame) - size.height) / 2
        dot.frame = CGRectMake(x, y, size.width, size.height)
    }

    private func generateDotView() -> UIView {
        var dotView: UIView
        if let dotViewClass {
            dotView = dotViewClass.init(frame: CGRectMake(0, 0, dotSize.width, dotSize.height))
            if let dotView = dotView as? DotView {
                if let dotColor {
                    dotView.dotColor = dotColor
                }
                if let currentDotColor {
                    dotView.currentDotColor = currentDotColor
                }
            }
        } else {
            dotView = UIImageView(image: dotImage)
            dotView.frame = CGRectMake(0, 0, dotSize.width, dotSize.height)
        }
        customDotView?(dotView)

        addSubview(dotView)
        dots.append(dotView)
        dotView.isUserInteractionEnabled = true
        return dotView
    }

    private func changeActivity(_ active: Bool, at index: Int) {
        if active, !currentDotSize.equalTo(dotSize) {
            for i in 0..<dots.count {
                updateDotFrame(dots[i], at: i, active: true)
            }
        }

        if dotViewClass != nil {
            if let dotView = dots[index] as? DotViewProtocol {
                dotView.changeActivityState(active)
            }
        } else if dotImage != nil && currentDotImage != nil {
            if let dotView = dots[index] as? UIImageView {
                dotView.image = active ? currentDotImage : dotImage
            }
        }
    }

    private func resetDotViews() {
        for dotView in dots {
            dotView.removeFromSuperview()
        }

        dots.removeAll()
        updateDots()
    }

    private func hideForSinglePage() {
        if dots.count == 1 && hidesForSinglePage {
            isHidden = true
        } else {
            isHidden = false
        }
    }
}

// MARK: - DotView
/// 点视图协议
@MainActor public protocol DotViewProtocol {
    /// 选中状态改变方法
    func changeActivityState(_ active: Bool)
}

/// 自带点视图
open class DotView: UIView, DotViewProtocol {
    open var dotColor: UIColor = .white.withAlphaComponent(0.5)

    open var currentDotColor: UIColor = .white

    open var isAnimated = false

    override public init(frame: CGRect) {
        super.init(frame: frame)
        didInitialize()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        didInitialize()
    }

    fileprivate func didInitialize() {
        layer.cornerRadius = min(frame.width, frame.height) / 2.0
        layer.masksToBounds = true
        backgroundColor = dotColor
    }

    open func changeActivityState(_ active: Bool) {
        if !isAnimated {
            backgroundColor = active ? currentDotColor : dotColor
        } else {
            if active {
                UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: -20, options: .curveLinear, animations: {
                    self.backgroundColor = self.currentDotColor
                    self.transform = .init(scaleX: 1.4, y: 1.4)
                }, completion: nil)
            } else {
                UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveLinear, animations: {
                    self.backgroundColor = self.dotColor
                    self.transform = .identity
                }, completion: nil)
            }
        }
    }
}

/// 自带边框点视图
open class BorderDotView: DotView {
    override open var dotColor: UIColor {
        didSet {
            backgroundColor = dotColor
        }
    }

    override open var currentDotColor: UIColor {
        didSet {
            layer.borderColor = currentDotColor.cgColor
        }
    }

    override func didInitialize() {
        dotColor = .clear
        currentDotColor = .white
        layer.cornerRadius = min(frame.width, frame.height) / 2.0
        layer.borderWidth = 2
        layer.masksToBounds = true
        backgroundColor = dotColor
        layer.borderColor = currentDotColor.cgColor
    }
}
