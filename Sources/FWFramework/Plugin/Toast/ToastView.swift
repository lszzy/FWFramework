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

/// 吐司视图位置
public enum ToastViewPosition: Int {
    /// 中心
    case center = 0
    /// 顶部
    case top
    /// 底部
    case bottom
}

/// 吐司视图，默认背景色透明
open class ToastView: UIControl {
    
    // MARK: - Accessor
    /// 当前吐司类型，默认custom，切换时需优先设置
    open var type: ToastViewType = .custom {
        didSet {
            if type == .progress {
                indicatorSize = CGSize(width: 37.0, height: 37.0)
            }
            setNeedsLayout()
        }
    }
    /// 关联吐司样式，仅用于判断，默认default
    open var style: ToastStyle = .default
    /// 吐司位置，默认center
    open var position: ToastViewPosition = .center
    /// 自定义视图，仅Custom生效
    open var customView: UIView? {
        didSet { setNeedsLayout() }
    }
    
    /// 内容背景色，默认#404040
    open var contentBackgroundColor: UIColor = UIColor(red: 64.0 / 255.0, green: 64.0 / 255.0, blue: 64.0 / 255.0, alpha: 1.0)
    /// 内容视图最小外间距，默认{10, 10, 10, 10}
    open var contentMarginInsets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    /// 内容视图内间距，默认{10, 10, 10, 10}
    open var contentInsets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    /// 视图和文本之间的间距，默认5.0
    open var contentSpacing: CGFloat = 5.0
    /// 文本和消息之间的间距，默认5.0
    open var textSpacing: CGFloat = 5.0
    /// 内容圆角半径，默认5.0
    open var contentCornerRadius: CGFloat = 5.0
    /// 是否水平对齐，默认NO垂直对齐
    open var horizontalAlignment: Bool = false
    /// 自定义内容垂直偏移，默认nil时自动处理，center时为-30，top时为10，bottom时为-10
    open var verticalOffset: CGFloat?
    /// 自定义内容垂直偏移句柄，参数为内容高度，默认nil
    open var verticalOffsetBlock: ((CGFloat) -> CGFloat)?
    /// 标题字体，默认16号
    open var titleFont: UIFont = UIFont.systemFont(ofSize: 16)
    /// 标题颜色，默认白色
    open var titleColor: UIColor = UIColor.white
    /// 消息字体，默认15号
    open var messageFont: UIFont = UIFont.systemFont(ofSize: 15)
    /// 消息颜色，默认白色
    open var messageColor: UIColor = UIColor.white
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
    /// 带属性消息文本，为空时不显示
    open var attributedMessage: NSAttributedString? {
        didSet {
            messageLabel.attributedText = attributedMessage
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
    /// 手动点击取消时触发的句柄，默认nil不可点击取消
    open var cancelBlock: (() -> Void)? {
        didSet {
            if cancelBlock != nil, !touchEnabled {
                touchEnabled = true
                
                if !isUserInteractionEnabled {
                    contentPenetrable = true
                }
                contentView.isUserInteractionEnabled = true
                contentView.fw.addTapGesture { [weak self] _ in
                    if let cancelBlock = self?.cancelBlock {
                        self?.hide()
                        cancelBlock()
                    }
                }
            }
        }
    }
    /// 当吐司视图禁止交互时，是否允许contentView可穿透点击，默认false
    open var contentPenetrable = false
    
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
        let result = UIView.fw.indicatorView(style: .toast)
        result.isUserInteractionEnabled = false
        return result
    }() {
        didSet {
            indicatorView.isUserInteractionEnabled = false
            setNeedsLayout()
        }
    }
    
    /// 进度条视图，可自定义，仅Progress生效
    open lazy var progressView: UIView & ProgressViewPlugin = {
        let result = UIView.fw.progressView(style: .toast)
        result.isUserInteractionEnabled = false
        return result
    }() {
        didSet {
            progressView.isUserInteractionEnabled = false
            setNeedsLayout()
        }
    }
    
    /// 标题标签，都存在，有内容时才显示
    open lazy var titleLabel: UILabel = {
        let result = UILabel()
        result.textAlignment = .center
        result.numberOfLines = 0
        result.isUserInteractionEnabled = false
        return result
    }()
    
    /// 消息标签，都存在，有内容时才显示
    open lazy var messageLabel: UILabel = {
        let result = UILabel()
        result.textAlignment = .center
        result.numberOfLines = 0
        result.isUserInteractionEnabled = false
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
        contentView.addSubview(messageLabel)
    }
    
    private func updateLayout() {
        contentView.backgroundColor = contentBackgroundColor
        contentView.layer.cornerRadius = contentCornerRadius
        titleLabel.font = titleFont
        titleLabel.textColor = titleColor
        titleLabel.attributedText = attributedTitle
        messageLabel.font = messageFont
        messageLabel.textColor = messageColor
        messageLabel.attributedText = attributedMessage

        switch type {
        case .custom:
            firstView = customView
            if let customView = customView, customView.superview == nil {
                contentView.addSubview(customView)
            }
        case .image:
            firstView = imageView
            if indicatorImage != nil {
                imageView.image = indicatorImage
            }
            if imageView.superview == nil {
                contentView.addSubview(imageView)
            }
        case .indicator:
            firstView = indicatorView
            if indicatorView.superview == nil {
                contentView.addSubview(indicatorView)
            }
        case .progress:
            firstView = progressView
            if progressView.superview == nil {
                contentView.addSubview(progressView)
            }
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
        
        let contentViewSize = self.contentViewSize
        if contentViewSize.equalTo(.zero) { return }
        
        // contentView默认垂直居中于toastView
        let originYOffset = verticalOffsetBlock?(contentViewSize.height) ?? verticalOffset
        var contentOriginY: CGFloat = 0
        switch position {
        case .top:
            contentOriginY = contentMarginInsets.top + safeAreaInsets.top + (originYOffset ?? 10.0)
        case .bottom:
            contentOriginY = bounds.height - contentMarginInsets.bottom - contentViewSize.height - safeAreaInsets.bottom + (originYOffset ?? -10.0)
        default:
            contentOriginY = (bounds.height - contentMarginInsets.top - contentMarginInsets.bottom - contentViewSize.height) / 2.0 + contentMarginInsets.top + (originYOffset ?? -30.0)
        }
        // 如果contentView要比toastView高，则置顶展示
        if contentView.bounds.height > bounds.height {
            contentOriginY = 0
        }
        contentView.frame = CGRect(
            x: (bounds.width - contentMarginInsets.left - contentMarginInsets.right - contentViewSize.width) / 2.0 + contentMarginInsets.left,
            y: contentOriginY,
            width: contentViewSize.width,
            height: contentViewSize.height
        )

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
            let messageLabelSize = messageLabel.sizeThatFits(CGSize(width: maxTitleWidth, height: CGFloat.greatestFiniteMagnitude))
            let firstViewSize = firstView?.frame.size ?? .zero
            titleLabel.frame = CGRect(x: (maxTitleWidth - titleLabelSize.width) / 2.0 + contentInsets.left, y: originY + (firstViewSize.height > 0 && titleLabelSize.height > 0 ? contentSpacing : 0), width: titleLabelSize.width, height: titleLabelSize.height)
            messageLabel.frame = CGRect(x: (maxTitleWidth - messageLabelSize.width) / 2.0 + contentInsets.left, y: titleLabel.frame.maxY + (titleLabelSize.height > 0 && messageLabelSize.height > 0 ? textSpacing : 0), width: messageLabelSize.width, height: messageLabelSize.height)
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
            let messageLabelSize = messageLabel.sizeThatFits(CGSize(width: maxTitleWidth, height: CGFloat.greatestFiniteMagnitude))
            let textWidth = max(titleLabelSize.width, messageLabelSize.width)
            var textHeight = titleLabelSize.height + messageLabelSize.height
            if titleLabelSize.height > 0 && messageLabelSize.height > 0 {
                textHeight += textSpacing
            }
            
            originX += (firstViewSize.width > 0 && textWidth > 0) ? contentSpacing : 0
            titleLabel.frame = CGRect(x: originX + (textWidth - titleLabelSize.width) / 2.0, y: (contentViewSize.height - contentInsets.top - contentInsets.bottom - textHeight) / 2.0 + contentInsets.top, width: titleLabelSize.width, height: titleLabelSize.height)
            messageLabel.frame = CGRect(x: originX + (textWidth - messageLabelSize.width) / 2.0, y: titleLabel.frame.maxY + (titleLabelSize.height > 0 && messageLabelSize.height > 0 ? textSpacing : 0), width: messageLabelSize.width, height: messageLabelSize.height)
        }
    }
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard contentPenetrable else {
            return super.hitTest(point, with: event)
        }
        
        if contentView.isUserInteractionEnabled,
           contentView.frame.contains(point) {
            let contentPoint = convert(point, to: contentView)
            guard let hitView = contentView.hitTest(contentPoint, with: event) else { return nil }
            return hitView
        }
        return nil
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
            let messageLabelSize = messageLabel.sizeThatFits(CGSize(width: maxContentWidth, height: CGFloat.greatestFiniteMagnitude))

            contentWidth += max(firstViewSize.width, titleLabelSize.width, messageLabelSize.width)
            contentHeight += firstViewSize.height + titleLabelSize.height + messageLabelSize.height
            if firstViewSize.height > 0 && titleLabelSize.height > 0 {
                contentHeight += contentSpacing
            }
            if titleLabelSize.height > 0 && messageLabelSize.height > 0 {
                contentHeight += textSpacing
            }
            return CGSize(width: contentWidth, height: contentHeight)
        } else {
            let titleLabelSize = titleLabel.sizeThatFits(CGSize(width: maxContentWidth - firstViewSize.width - (firstViewSize.width > 0 ? contentSpacing : 0), height: CGFloat.greatestFiniteMagnitude))
            let messageLabelSize = messageLabel.sizeThatFits(CGSize(width: maxContentWidth - firstViewSize.width - (firstViewSize.width > 0 ? contentSpacing : 0), height: CGFloat.greatestFiniteMagnitude))
            let textWidth = max(titleLabelSize.width, messageLabelSize.width)
            var textHeight = titleLabelSize.height + messageLabelSize.height
            if titleLabelSize.height > 0 && messageLabelSize.height > 0 {
                textHeight += textSpacing
            }

            contentWidth += firstViewSize.width + textWidth
            if firstViewSize.width > 0 && textWidth > 0 {
                contentWidth += contentSpacing
            }
            contentHeight += max(firstViewSize.height, textHeight)
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
    open func hide(afterDelay delay: TimeInterval, completion: (@MainActor @Sendable () -> Void)? = nil) -> Bool {
        if superview != nil {
            invalidateTimer()
            hideTimer = Timer.fw.commonTimer(timeInterval: delay, block: { [weak self] _ in
                DispatchQueue.fw.mainAsync { [weak self] in
                    let hideSuccess = self?.hide() ?? false
                    if hideSuccess {
                        completion?()
                    }
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
