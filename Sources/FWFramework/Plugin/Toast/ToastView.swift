//
//  ToastView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

/// 吐司视图类型
public enum ToastViewType: Int {
    /// 自定义吐司
    case custom = 0
    /// 文本吐司
    case text
    /// 图片吐司
    case image
    /// 指示器吐司
    case indicator
    /// 进度条吐司
    case progress
}

/// 吐司视图，默认背景色透明
open class ToastView: UIControl {
    
    // MARK: - Accessor
    /// 当前吐司类型，只读
    open private(set) var type: ToastViewType = .custom
    /// 自定义视图，仅Custom生效
    open var customView: UIView?
    
    /// 内容背景色，默认#404040
    open var contentBackgroundColor: UIColor = UIColor(red: 64.0 / 255.0, green: 64.0 / 255.0, blue: 64.0 / 255.0, alpha: 1.0)
    /// 内容视图最小外间距，默认{10, 10, 10, 10}
    open var contentMarginInsets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    /// 内容视图内间距，默认{10, 10, 10, 10}
    open var contentInsets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    /// 视图和文本之间的间距，默认5.0
    open var contentSpacing: CGFloat = 5.0
    /// 内容圆角半径，默认5.0
    open var contentCornerRadius: CGFloat = 5.0
    /// 是否水平对齐，默认NO垂直对齐
    open var horizontalAlignment: Bool = false
    /// 如果不想要内容整体垂直居中，则可通过调整此属性来进行垂直偏移。默认为-30，即内容比中间略微偏上
    open var verticalOffset: CGFloat = -30.0
    /// 标题字体，默认16号
    open var titleFont: UIFont = UIFont.systemFont(ofSize: 16)
    /// 标题颜色，默认白色
    open var titleColor: UIColor = UIColor.white
    /// 指示器图片，支持动画图片，自适应大小，仅Image生效
    open var indicatorImage: UIImage?
    /// 指示器大小，默认根据类型处理
    open var indicatorSize: CGSize = .zero
    /// 指示器颜色，默认nil时不处理，仅Indicator生效
    open var indicatorColor: UIColor? {
        didSet {
            switch type {
            case .indicator:
                indicatorView.indicatorColor = indicatorColor
            case .progress:
                progressView.indicatorColor = indicatorColor
            default:
                break
            }
        }
    }
    
    /// 带属性标题文本，为空时不显示
    open var attributedTitle: NSAttributedString? {
        didSet {
            titleLabel.attributedText = attributedTitle
            setNeedsLayout()
        }
    }
    /// 当前指示器进度值，范围0~1，仅Progress生效
    open var progress: CGFloat = 0.0 {
        didSet {
            if type == .progress {
                progressView.progress = progress
            } else if let customView = customView as? UIView & ProgressViewPlugin {
                customView.progress = progress
            }
            setNeedsLayout()
        }
    }
    /// 手工点击取消时触发的句柄，默认nil不可点击取消
    open var cancelBlock: (() -> Void)? {
        didSet {
            if cancelBlock != nil, !touchEnabled {
                touchEnabled = true
                
                contentView.isUserInteractionEnabled = true
                contentView.fw_addTapGesture { [weak self] _ in
                    if let cancelBlock = self?.cancelBlock {
                        self?.hide()
                        cancelBlock()
                    }
                }
            }
        }
    }
    
    private weak var firstView: UIView?
    private var hideTimer: Timer?
    private var touchEnabled: Bool = false
    
    // MARK: - Subviews
    /// 内容视图，可设置背景色(默认#404040)、圆角(默认5)，只读
    open lazy var contentView: UIView = {
        let result = UIView()
        result.isUserInteractionEnabled = false
        result.layer.masksToBounds = true
        return result
    }()
    
    /// 图片视图，仅Image生效
    open lazy var imageView: UIImageView = {
        let result = UIImageView()
        result.isUserInteractionEnabled = false
        result.backgroundColor = .clear
        return result
    }()
    
    /// 指示器视图，可自定义，仅Indicator生效
    open lazy var indicatorView: UIView & IndicatorViewPlugin = {
        let result = UIView.fw_indicatorView(style: .default, scene: .toast)
        result.isUserInteractionEnabled = false
        return result
    }() {
        didSet {
            guard type == .indicator else { return }
            
            oldValue.removeFromSuperview()
            indicatorView.isUserInteractionEnabled = false
            contentView.addSubview(indicatorView)
            setNeedsLayout()
        }
    }
    
    /// 进度条视图，可自定义，仅Progress生效
    open lazy var progressView: UIView & ProgressViewPlugin = {
        let result = UIView.fw_progressView(style: .default, scene: .toast)
        result.isUserInteractionEnabled = false
        return result
    }() {
        didSet {
            guard type == .progress else { return }
            
            oldValue.removeFromSuperview()
            progressView.isUserInteractionEnabled = false
            contentView.addSubview(progressView)
            setNeedsLayout()
        }
    }
    
    /// 标题标签，都存在，有内容时才显示
    open lazy var titleLabel: UILabel = {
        let result = UILabel()
        result.textAlignment = .center
        result.numberOfLines = 0
        return result
    }()

    // MARK: - Lifecycle
    /// 初始化指定类型指示器
    public init(type: ToastViewType) {
        super.init(frame: .zero)
        
        self.type = type
        setupSubviews()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupSubviews()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupSubviews()
    }
    
    private func setupSubviews() {
        if type == .progress {
            indicatorSize = CGSize(width: 37.0, height: 37.0)
        }
        backgroundColor = .clear
        isUserInteractionEnabled = true
        
        addSubview(contentView)
        contentView.addSubview(titleLabel)
        
        switch type {
        case .image:
            contentView.addSubview(imageView)
        case .indicator:
            contentView.addSubview(indicatorView)
        case .progress:
            contentView.addSubview(progressView)
        default:
            break
        }
    }
    
    private func updateLayout() {
        contentView.backgroundColor = contentBackgroundColor
        contentView.layer.cornerRadius = contentCornerRadius
        titleLabel.font = titleFont
        titleLabel.textColor = titleColor
        titleLabel.attributedText = attributedTitle

        switch type {
        case .custom:
            firstView = customView
            if let customView = customView, customView.superview == nil {
                contentView.addSubview(customView)
            }
        case .image:
            firstView = imageView
            imageView.image = indicatorImage
        case .indicator:
            firstView = indicatorView
        case .progress:
            firstView = progressView
        default:
            break
        }

        setNeedsLayout()
        layoutIfNeeded()

        if let firstView = firstView as? UIView & IndicatorViewPlugin {
            firstView.startAnimating()
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()

        // contentView默认垂直居中于toastView
        let contentViewSize = self.contentViewSize
        if contentViewSize.equalTo(.zero) { return }
        contentView.frame = CGRect(
            x: (bounds.width - contentMarginInsets.left - contentMarginInsets.right - contentViewSize.width) / 2.0 + contentMarginInsets.left,
            y: (bounds.height - contentMarginInsets.top - contentMarginInsets.bottom - contentViewSize.height) / 2.0 + contentMarginInsets.top + verticalOffset,
            width: contentViewSize.width,
            height: contentViewSize.height
        )

        // 如果contentView要比toastView高，则置顶展示
        if contentView.bounds.height > bounds.height {
            var frame = contentView.frame
            frame.origin.y = 0
            contentView.frame = frame
        }

        if let firstView = firstView {
            if indicatorSize.width > 0 && indicatorSize.height > 0 {
                firstView.frame = CGRect(x: firstView.frame.origin.x, y: firstView.frame.origin.y, width: indicatorSize.width, height: indicatorSize.height)
            } else {
                firstView.sizeToFit()
            }
        }

        if !horizontalAlignment {
            var originY = contentInsets.top
            if let firstView = firstView {
                var frame = firstView.frame
                frame.origin = CGPoint(x: (contentViewSize.width - contentInsets.left - contentInsets.right - frame.size.width) / 2.0 + contentInsets.left, y: originY)
                firstView.frame = frame
                originY = firstView.frame.maxY
            }

            let maxTitleWidth = contentViewSize.width - contentInsets.left - contentInsets.right
            let titleLabelSize = titleLabel.sizeThatFits(CGSize(width: maxTitleWidth, height: CGFloat.greatestFiniteMagnitude))
            let firstViewSize = firstView?.frame.size ?? .zero
            titleLabel.frame = CGRect(x: (maxTitleWidth - titleLabelSize.width) / 2.0 + contentInsets.left, y: originY + (firstViewSize.height > 0 && titleLabelSize.height > 0 ? contentSpacing : 0), width: titleLabelSize.width, height: titleLabelSize.height)
        } else {
            var originX = contentInsets.left
            if let firstView = firstView {
                var frame = firstView.frame
                frame.origin = CGPoint(x: originX, y: (contentViewSize.height - contentInsets.top - contentInsets.bottom - frame.size.height) / 2.0 + contentInsets.top)
                firstView.frame = frame
                originX = firstView.frame.maxX
            }

            let firstViewSize = firstView?.frame.size ?? .zero
            let maxTitleWidth = contentViewSize.width - contentInsets.left - contentInsets.right - firstViewSize.width - (firstViewSize.width > 0 ? contentSpacing : 0)
            let titleLabelSize = titleLabel.sizeThatFits(CGSize(width: maxTitleWidth, height: CGFloat.greatestFiniteMagnitude))
            titleLabel.frame = CGRect(x: originX + (firstViewSize.width > 0 && titleLabelSize.width > 0 ? contentSpacing : 0), y: (contentViewSize.height - contentInsets.top - contentInsets.bottom - titleLabelSize.height) / 2.0 + contentInsets.top, width: titleLabelSize.width, height: titleLabelSize.height)
        }
    }
    
    // MARK: - Public
    /// 获取内容视图尺寸，需bounds存在时才有值
    open var contentViewSize: CGSize {
        if bounds.size.equalTo(.zero) { return .zero }

        var contentWidth = contentInsets.left + contentInsets.right
        var contentHeight = contentInsets.top + contentInsets.bottom
        let maxContentWidth = bounds.size.width - contentMarginInsets.left - contentMarginInsets.right - contentInsets.left - contentInsets.right

        var firstViewSize: CGSize = .zero
        if let firstView = firstView {
            firstViewSize = (indicatorSize.width > 0 && indicatorSize.height > 0) ? indicatorSize : firstView.sizeThatFits(CGSize(width: maxContentWidth, height: CGFloat.greatestFiniteMagnitude))
        }

        if !horizontalAlignment {
            let titleLabelSize = titleLabel.sizeThatFits(CGSize(width: maxContentWidth, height: CGFloat.greatestFiniteMagnitude))

            contentWidth += max(firstViewSize.width, titleLabelSize.width)
            contentHeight += firstViewSize.height + titleLabelSize.height
            if firstViewSize.height > 0 && titleLabelSize.height > 0 {
                contentHeight += contentSpacing
            }
            return CGSize(width: contentWidth, height: contentHeight)
        } else {
            let titleLabelSize = titleLabel.sizeThatFits(CGSize(width: maxContentWidth - firstViewSize.width - (firstViewSize.width > 0 ? contentSpacing : 0), height: CGFloat.greatestFiniteMagnitude))

            contentWidth += firstViewSize.width + titleLabelSize.width
            if firstViewSize.width > 0 && titleLabelSize.width > 0 {
                contentWidth += contentSpacing
            }
            contentHeight += max(firstViewSize.height, titleLabelSize.height)
            return CGSize(width: contentWidth, height: contentHeight)
        }
    }
    
    /// 显示吐司，不执行动画
    open func show() {
        show(animated: false)
    }

    /// 显示吐司，执行淡入渐变动画
    open func show(animated: Bool) {
        updateLayout()
        
        if animated {
            alpha = 0
            UIView.animate(withDuration: 0.25) {
                self.alpha = 1.0
            }
        }
    }

    /// 隐藏吐司。吐司不存在时返回NO
    @discardableResult
    open func hide() -> Bool {
        if superview != nil {
            if let indicatorView = firstView as? UIView & IndicatorViewPlugin {
                indicatorView.stopAnimating()
            }
            removeFromSuperview()
            invalidateTimer()

            return true
        }
        return false
    }

    /// 隐藏吐司，延迟指定时间后执行。吐司不存在时返回NO
    @discardableResult
    open func hide(afterDelay delay: TimeInterval, completion: (() -> Void)? = nil) -> Bool {
        if superview != nil {
            invalidateTimer()
            hideTimer = Timer.fw_commonTimer(timeInterval: delay, block: { [weak self] _ in
                let hideSuccess = self?.hide() ?? false
                if hideSuccess {
                    completion?()
                }
            }, repeats: false)
        }
        return false
    }

    /// 清理延迟隐藏吐司定时器
    open func invalidateTimer() {
        hideTimer?.invalidate()
        hideTimer = nil
    }
    
}
