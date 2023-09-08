//
//  EmptyView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - PlaceholderView
/// 通用的空界面控件，布局顺序从上到下依次为：imageView, loadingView, textLabel, detailTextLabel, actionButton
///
/// [QMUI_iOS](https://github.com/Tencent/QMUI_iOS)
open class PlaceholderView: UIView {
    
    // MARK: - Accessor
    /// 内容视图间距，默认为(0, 16, 0, 16)
    open var contentViewInsets: UIEdgeInsets {
        get {
            scrollView.contentInset
        }
        set {
            scrollView.contentInset = newValue
            setNeedsLayout()
        }
    }
    /// 图片视图间距，默认为(0, 0, 36, 0)
    open var imageViewInsets: UIEdgeInsets = .init(top: 0, left: 0, bottom: 36, right: 0) {
        didSet { setNeedsLayout() }
    }
    /// 加载视图间距，默认为(0, 0, 36, 0)
    open var loadingViewInsets: UIEdgeInsets = .init(top: 0, left: 0, bottom: 36, right: 0) {
        didSet { setNeedsLayout() }
    }
    /// 文本视图间距，默认为(0, 0, 10, 0)
    open var textLabelInsets: UIEdgeInsets = .init(top: 0, left: 0, bottom: 10, right: 0) {
        didSet { setNeedsLayout() }
    }
    /// 详细文本视图间距，默认为(0, 0, 14, 0)
    open var detailTextLabelInsets: UIEdgeInsets = .init(top: 0, left: 0, bottom: 14, right: 0) {
        didSet { setNeedsLayout() }
    }
    /// 动作按钮间距，默认为(0, 0, 0, 0)
    open var actionButtonInsets: UIEdgeInsets = .zero {
        didSet { setNeedsLayout() }
    }
    /// 更多动作按钮间距，默认为(0, 24, 0, 0)
    open var moreActionButtonInsets: UIEdgeInsets = .init(top: 0, left: 24, bottom: 0, right: 0) {
        didSet { setNeedsLayout() }
    }
    /// 如果不想要内容整体垂直居中，则可通过调整此属性来进行垂直偏移。默认为-30，即内容比中间略微偏上
    open var verticalOffset: CGFloat {
        get {
            _verticalOffset
        }
        set {
            _verticalOffset = newValue
            setNeedsLayout()
        }
    }
    private var _verticalOffset: CGFloat = -30
    /// 自定义垂直偏移句柄，参数依次为总高度，内容高度，图片高度
    open var verticalOffsetBlock: ((_ totalHeight: CGFloat, _ contentHeight: CGFloat, _ imageHeight: CGFloat) -> CGFloat)? {
        didSet { setNeedsLayout() }
    }

    /// textLabel字体，默认为15pt系统字体
    open var textLabelFont: UIFont = .systemFont(ofSize: 15) {
        didSet {
            textLabel.font = textLabelFont
            setNeedsLayout()
        }
    }
    /// detailTextLabel字体，默认为14pt系统字体
    open var detailTextLabelFont: UIFont = .systemFont(ofSize: 14) {
        didSet {
            detailTextLabel.font = detailTextLabelFont
            setNeedsLayout()
        }
    }
    /// actionButton标题字体，默认为15pt系统字体
    open var actionButtonFont: UIFont = .systemFont(ofSize: 15) {
        didSet {
            actionButton.titleLabel?.font = actionButtonFont
            setNeedsLayout()
        }
    }
    /// moreActionButton标题字体，默认为15pt系统字体
    open var moreActionButtonFont: UIFont = .systemFont(ofSize: 15) {
        didSet {
            moreActionButton.titleLabel?.font = moreActionButtonFont
            setNeedsLayout()
        }
    }

    /// loadingView颜色，默认灰色
    open var loadingViewColor: UIColor = ViewPluginImpl.indicatorViewColor {
        didSet {
            loadingView.indicatorColor = loadingViewColor
        }
    }
    /// textLabel文本颜色，默认为(93, 100, 110)
    open var textLabelTextColor: UIColor = .init(red: 93.0 / 255.0, green: 100.0 / 255.0, blue: 110.0 / 255.0, alpha: 1.0) {
        didSet {
            textLabel.textColor = textLabelTextColor
        }
    }
    /// detailTextLabel文本颜色，默认为(133, 140, 150)
    open var detailTextLabelTextColor: UIColor = .init(red: 133.0 / 255.0, green: 140.0 / 255.0, blue: 150.0 / 255.0, alpha: 1.0) {
        didSet {
            detailTextLabel.textColor = detailTextLabelTextColor
        }
    }
    /// actionButton标题颜色，默认为(49, 189, 243)
    open var actionButtonTitleColor: UIColor = .init(red: 49.0 / 255.0, green: 189.0 / 255.0, blue: 243.0 / 255.0, alpha: 1.0) {
        didSet {
            actionButton.setTitleColor(actionButtonTitleColor, for: .normal)
            actionButton.setTitleColor(actionButtonTitleColor.withAlphaComponent(0.5), for: .highlighted)
            actionButton.setTitleColor(actionButtonTitleColor.withAlphaComponent(0.5), for: .disabled)
        }
    }
    /// moreActionButton标题颜色，默认为(49, 189, 243)
    open var moreActionButtonTitleColor: UIColor = .init(red: 49.0 / 255.0, green: 189.0 / 255.0, blue: 243.0 / 255.0, alpha: 1.0) {
        didSet {
            moreActionButton.setTitleColor(moreActionButtonTitleColor, for: .normal)
            moreActionButton.setTitleColor(moreActionButtonTitleColor.withAlphaComponent(0.5), for: .highlighted)
            moreActionButton.setTitleColor(moreActionButtonTitleColor.withAlphaComponent(0.5), for: .disabled)
        }
    }
    
    // MARK: - Subviews
    /**
     *  如果要继承PlaceholderView并添加新的子 view，则必须：
     *  1. 像其它自带 view 一样添加到 contentView 上
     *  2. 重写sizeThatContentViewFits
     */
    open lazy var contentView: UIView = {
        let result = UIView()
        return result
    }()
    
    /// 此控件通过设置 loadingView.hidden 来控制 loadinView 的显示和隐藏，因此请确保你的loadingView 没有类似于 hidesWhenStopped = YES 之类会使 view.hidden 失效的属性
    open lazy var loadingView: UIView & IndicatorViewPlugin = {
        let result = UIView.fw_indicatorView(style: .default)
        result.indicatorColor = loadingViewColor
        return result
    }() {
        didSet {
            if !loadingView.isEqual(oldValue) {
                oldValue.removeFromSuperview()
                contentView.addSubview(loadingView)
            }
            setNeedsLayout()
        }
    }
    
    /// 图片控件
    open lazy var imageView: UIImageView = {
        let result = UIImageView()
        result.contentMode = .center
        return result
    }()
    
    /// 文本控件
    open lazy var textLabel: UILabel = {
        let result = UILabel()
        result.font = textLabelFont
        result.textColor = textLabelTextColor
        result.textAlignment = .center
        result.numberOfLines = 0
        return result
    }()
    
    /// 详细文本控件
    open lazy var detailTextLabel: UILabel = {
        let result = UILabel()
        result.font = detailTextLabelFont
        result.textColor = detailTextLabelTextColor
        result.textAlignment = .center
        result.numberOfLines = 0
        return result
    }()
    
    /// 动作按钮控件
    open lazy var actionButton: UIButton = {
        let result = UIButton()
        result.setTitleColor(actionButtonTitleColor, for: .normal)
        result.setTitleColor(actionButtonTitleColor.withAlphaComponent(0.5), for: .highlighted)
        result.setTitleColor(actionButtonTitleColor.withAlphaComponent(0.5), for: .disabled)
        result.titleLabel?.font = actionButtonFont
        result.fw_touchInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return result
    }()
    
    /// 更多动作按钮控件，默认隐藏
    open lazy var moreActionButton: UIButton = {
        let result = UIButton()
        result.setTitleColor(moreActionButtonTitleColor, for: .normal)
        result.setTitleColor(moreActionButtonTitleColor.withAlphaComponent(0.5), for: .highlighted)
        result.setTitleColor(moreActionButtonTitleColor.withAlphaComponent(0.5), for: .disabled)
        result.titleLabel?.font = moreActionButtonFont
        result.fw_touchInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        result.isHidden = true
        return result
    }()
    
    private lazy var scrollView: UIScrollView = {
        let result = UIScrollView()
        result.contentInsetAdjustmentBehavior = .never
        result.showsVerticalScrollIndicator = false
        result.showsHorizontalScrollIndicator = false
        result.scrollsToTop = false
        result.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return result
    }()
    
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
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(loadingView)
        contentView.addSubview(imageView)
        contentView.addSubview(textLabel)
        contentView.addSubview(detailTextLabel)
        contentView.addSubview(actionButton)
        contentView.addSubview(moreActionButton)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        scrollView.frame = bounds
        let contentViewSize = sizeThatContentViewFits()
        // 如果 verticalOffsetBlock 存在，计算垂直偏移
        if let verticalOffsetBlock = verticalOffsetBlock {
            let imageViewHeight = imageView.sizeThatFits(CGSize(width: contentViewSize.width, height: .greatestFiniteMagnitude)).height + (imageViewInsets.top + imageViewInsets.bottom)
            _verticalOffset = verticalOffsetBlock(scrollView.bounds.size.height, contentViewSize.height, imageViewHeight)
        }
        
        // contentView 默认垂直居中于 scrollView
        contentView.frame = CGRectMake(0, CGRectGetMidY(scrollView.bounds) - contentViewSize.height / 2 + verticalOffset, contentViewSize.width, contentViewSize.height)
        
        // 如果 contentView 要比 scrollView 高，则置顶展示
        if (CGRectGetHeight(contentView.bounds) > CGRectGetHeight(scrollView.bounds)) {
            var frame = contentView.frame
            frame.origin.y = 0
            contentView.frame = frame
        }
        
        scrollView.contentSize = CGSizeMake(max(CGRectGetWidth(scrollView.bounds) - (scrollView.contentInset.left + scrollView.contentInset.right), contentViewSize.width), max(CGRectGetHeight(scrollView.bounds) - (scrollView.contentInset.top + scrollView.contentInset.bottom), CGRectGetMaxY(contentView.frame)))
        
        var originY: CGFloat = 0
        if (!imageView.isHidden) {
            imageView.sizeToFit()
            var frame = imageView.frame
            frame.origin = CGPointMake(((CGRectGetWidth(contentView.bounds) - CGRectGetWidth(imageView.frame)) / 2.0) + imageViewInsets.left - imageViewInsets.right, originY + imageViewInsets.top)
            imageView.frame = frame
            originY = CGRectGetMaxY(imageView.frame) + imageViewInsets.bottom
        }
        
        if !loadingView.isHidden {
            var frame = loadingView.frame
            frame.origin = CGPointMake(((CGRectGetWidth(contentView.bounds) - CGRectGetWidth(loadingView.frame)) / 2.0) + loadingViewInsets.left - loadingViewInsets.right, originY + loadingViewInsets.top)
            loadingView.frame = frame
            originY = CGRectGetMaxY(loadingView.frame) + loadingViewInsets.bottom
        }
        
        if !textLabel.isHidden {
            let textWidth = CGRectGetWidth(contentView.bounds) - (textLabelInsets.left + textLabelInsets.right)
            let textSize = textLabel.sizeThatFits(CGSizeMake(textWidth, .greatestFiniteMagnitude))
            textLabel.frame = CGRectMake(textLabelInsets.left, originY + textLabelInsets.top, textWidth, textSize.height)
            originY = CGRectGetMaxY(textLabel.frame) + textLabelInsets.bottom
        }
        
        if !detailTextLabel.isHidden {
            let detailWidth = CGRectGetWidth(contentView.bounds) - (detailTextLabelInsets.left + detailTextLabelInsets.right)
            let detailSize = detailTextLabel.sizeThatFits(CGSize(width: detailWidth, height: .greatestFiniteMagnitude))
            detailTextLabel.frame = CGRectMake(detailTextLabelInsets.left, originY + detailTextLabelInsets.top, detailWidth, detailSize.height)
            originY = CGRectGetMaxY(detailTextLabel.frame) + detailTextLabelInsets.bottom
        }
        
        if !actionButton.isHidden {
            actionButton.sizeToFit()
            var actionFrame = actionButton.frame
            actionFrame.origin = CGPointMake(((CGRectGetWidth(contentView.bounds) - CGRectGetWidth(actionButton.frame)) / 2.0) + actionButtonInsets.left - actionButtonInsets.right, originY + actionButtonInsets.top)
            actionButton.frame = actionFrame
            
            if !moreActionButton.isHidden {
                moreActionButton.sizeToFit()
                actionFrame.origin.x = ((CGRectGetWidth(contentView.bounds) - CGRectGetWidth(actionButton.frame) - CGRectGetWidth(moreActionButton.frame) - actionButtonInsets.right - moreActionButtonInsets.left) / 2.0) + actionButtonInsets.left
                actionButton.frame = actionFrame
                
                var frame = moreActionButton.frame
                frame.origin = CGPointMake(CGRectGetMaxX(actionButton.frame) + actionButtonInsets.right + moreActionButtonInsets.left - moreActionButtonInsets.right, originY + moreActionButtonInsets.top)
                moreActionButton.frame = frame
            }
        }
    }
    
    // MARK: - Public
    /// 显示或隐藏loading图标
    open func setLoadingViewHidden(_ hidden: Bool) {
        loadingView.isHidden = hidden
        if !hidden {
            loadingView.startAnimating()
        }
        setNeedsLayout()
    }

    /**
     * 设置要显示的图片
     * @param image 要显示的图片，为nil则不显示
     */
    open func setImage(_ image: UIImage?) {
        imageView.image = image
        imageView.isHidden = image == nil
        setNeedsLayout()
    }

    /**
     * 设置提示语
     * @param text 提示语文本，若为nil则隐藏textLabel
     */
    open func setTextLabelText(_ text: Any?) {
        if let attributedText = text as? NSAttributedString {
            textLabel.attributedText = attributedText
        } else {
            textLabel.text = text as? String
        }
        textLabel.isHidden = text == nil
        setNeedsLayout()
    }

    /**
     * 设置详细提示语的文本
     * @param text 详细提示语文本，若为nil则隐藏detailTextLabel
     */
    open func setDetailTextLabelText(_ text: Any?) {
        if let attributedText = text as? NSAttributedString {
            detailTextLabel.attributedText = attributedText
        } else {
            detailTextLabel.text = text as? String
        }
        detailTextLabel.isHidden = text == nil
        setNeedsLayout()
    }

    /**
     * 设置操作按钮的文本
     * @param title 操作按钮的文本，若为nil则隐藏actionButton
     */
    open func setActionButtonTitle(_ title: Any?) {
        if let attributedTitle = title as? NSAttributedString {
            actionButton.setAttributedTitle(attributedTitle, for: .normal)
        } else {
            actionButton.setTitle(title as? String, for: .normal)
        }
        actionButton.isHidden = title == nil
        setNeedsLayout()
    }

    /**
     * 设置更多操作按钮的文本
     * @param title 操作按钮的文本，若为nil则隐藏moreActionButton
     */
    open func setMoreActionButtonTitle(_ title: Any?) {
        if let attributedTitle = title as? NSAttributedString {
            moreActionButton.setAttributedTitle(attributedTitle, for: .normal)
        } else {
            moreActionButton.setTitle(title as? String, for: .normal)
        }
        moreActionButton.isHidden = title == nil
        setNeedsLayout()
    }

    /// 返回一个恰好容纳所有子 view 的大小
    open func sizeThatContentViewFits() -> CGSize {
        let resultWidth = CGRectGetWidth(scrollView.bounds) - (scrollView.contentInset.left + scrollView.contentInset.right)
        let fitsSize = CGSize(width: resultWidth, height: .greatestFiniteMagnitude)
        
        let imageViewHeight = imageView.sizeThatFits(fitsSize).height + (imageViewInsets.top + imageViewInsets.bottom)
        let loadingViewHeight = CGRectGetHeight(loadingView.bounds) + (loadingViewInsets.top + loadingViewInsets.bottom)
        let textLabelHeight = textLabel.sizeThatFits(fitsSize).height + (textLabelInsets.top + textLabelInsets.bottom)
        let detailTextLabelHeight = detailTextLabel.sizeThatFits(fitsSize).height + (detailTextLabelInsets.top + detailTextLabelInsets.bottom)
        let actionButtonHeight = actionButton.sizeThatFits(fitsSize).height + (actionButtonInsets.top + actionButtonInsets.bottom)
        
        var resultHeight: CGFloat = 0
        if !self.imageView.isHidden {
            resultHeight += imageViewHeight
        }
        if !self.loadingView.isHidden {
            resultHeight += loadingViewHeight
        }
        if !self.textLabel.isHidden {
            resultHeight += textLabelHeight
        }
        if !self.detailTextLabel.isHidden {
            resultHeight += detailTextLabelHeight
        }
        if !self.actionButton.isHidden {
            resultHeight += actionButtonHeight
        }
        return CGSizeMake(resultWidth, resultHeight)
    }
    
}

// MARK: - ScrollOverlayView
/// 滚动视图自定义浮层视图
open class ScrollOverlayView: UIView {
    
    /// 添加到父视图时是否执行动画，默认false
    open var fadeAnimated: Bool = false
    
    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if fadeAnimated {
            fadeAnimated = false
            frame = CGRect(x: 0, y: 0, width: superview?.bounds.size.width ?? 0, height: superview?.bounds.size.height ?? 0)
            alpha = 0
            UIView.animate(withDuration: 0.25) {
                self.alpha = 1.0
            }
        } else {
            frame = CGRect(x: 0, y: 0, width: superview?.bounds.size.width ?? 0, height: superview?.bounds.size.height ?? 0)
        }
    }
    
}
