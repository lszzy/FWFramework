//
//  MarqueeLabel.swift
//  FWFramework
//
//  Created by wuyong on 2023/3/29.
//

import UIKit

/// 简易的跑马灯 label 控件，在文字超过 label 可视区域时会自动开启跑马灯效果展示文字，文字滚动时是首尾连接的效果（参考播放音乐时系统锁屏界面顶部的音乐标题）。
///
/// lineBreakMode 默认为 NSLineBreakByClipping（UILabel 默认值为 NSLineBreakByTruncatingTail）。
/// textAlignment 暂不支持 NSTextAlignmentJustified 和 NSTextAlignmentNatural。
/// 会忽略 numberOfLines 属性，强制以 1 来展示。
///
/// [QMUI_iOS](https://github.com/Tencent/QMUI_iOS)
open class MarqueeLabel: UILabel {
    /// 控制滚动的速度，1 表示一帧滚动 1pt，10 表示一帧滚动 10pt，默认为 .5，与系统一致。
    @IBInspectable open var speed: CGFloat = 0.5

    /// 当文字第一次显示在界面上，以及重复滚动到开头时都要停顿一下，这个属性控制停顿的时长，默认为 2.5（也是与系统一致），单位为秒。
    @IBInspectable open var pauseDurationWhenMoveToEdge: TimeInterval = 2.5

    /// 用于控制首尾连接的文字之间的间距，默认为 40pt。
    @IBInspectable open var spacingBetweenHeadToTail: CGFloat = 40

    /// 用于控制左和右边两端的渐变区域的百分比，默认为 0.2，则是 20% 宽。
    @IBInspectable open var fadeWidthPercent: CGFloat = 0.2 {
        didSet {
            fadeEndPercent = max(0.0, min(fadeWidthPercent, 1.0))
        }
    }

    /// 自动判断 label 的 frame 是否超出当前的 UIWindow 可视范围，超出则自动停止动画。默认为 YES。
    ///
    /// 某些场景并无法触发这个自动检测（例如直接调整 label.superview 的 frame 而不是 label 自身的 frame），这种情况暂不处理。
    @IBInspectable open var automaticallyValidateVisibleFrame: Bool = true

    /// 在文字滚动到左右边缘时，是否要显示一个阴影渐变遮罩，默认为 NO。
    @IBInspectable open var shouldFadeAtEdge: Bool = false {
        didSet {
            checkIfShouldShowGradientLayer()
        }
    }

    /// YES 表示文字会在打开 shouldFadeAtEdge 的情况下，从左边的渐隐区域之后显示，NO 表示不管有没有打开 shouldFadeAtEdge，都会从 label 的边缘开始显示。默认为 NO。
    ///
    /// 如果文字宽度本身就没超过 label 宽度（也即无需滚动），此时必定不会显示渐隐，则这个属性不会影响文字的显示位置。
    @IBInspectable open var textStartAfterFade: Bool = false

    private var offsetX: CGFloat = 0
    private var textWidth: CGFloat = 0
    private var fadeStartPercent: CGFloat = 0 // 渐变开始的百分比，默认为0，不建议改
    private var fadeEndPercent: CGFloat = 0.2 // 渐变结束的百分比，例如0.2，则表示 0~20% 是渐变区间
    private var isFirstDisplay = true
    /// 绘制文本时重复绘制的次数，用于实现首尾连接的滚动效果，1 表示不首尾连接，大于 1 表示首尾连接。
    private var textRepeatCount: Int = 2

    private let mutableState = MutableState()
    private var fadeLayer: CAGradientLayer?

    private class MutableState: @unchecked Sendable {
        var displayLink: CADisplayLink?
    }

    // MARK: - Lifecycle
    override public init(frame: CGRect) {
        super.init(frame: frame)
        lineBreakMode = .byClipping
        clipsToBounds = true
        didInitialize()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        didInitialize()
    }

    private func didInitialize() {
        speed = 0.5
        fadeStartPercent = 0
        fadeEndPercent = 0.2
        pauseDurationWhenMoveToEdge = 2.5
        spacingBetweenHeadToTail = 40
        automaticallyValidateVisibleFrame = true
        shouldFadeAtEdge = false
        textStartAfterFade = false
        isFirstDisplay = true
        textRepeatCount = 2
    }

    deinit {
        mutableState.displayLink?.invalidate()
        mutableState.displayLink = nil
    }

    // MARK: - Override
    override open func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            mutableState.displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
            mutableState.displayLink?.add(to: RunLoop.current, forMode: .common)
        } else {
            mutableState.displayLink?.invalidate()
            mutableState.displayLink = nil
        }
        offsetX = 0
        mutableState.displayLink?.isPaused = !shouldPlayDisplayLink()
        checkIfShouldShowGradientLayer()
    }

    override open var text: String? {
        didSet {
            super.text = text
            offsetX = 0
            textWidth = sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).width
            mutableState.displayLink?.isPaused = !shouldPlayDisplayLink()
            checkIfShouldShowGradientLayer()
        }
    }

    override open var attributedText: NSAttributedString? {
        didSet {
            super.attributedText = attributedText
            offsetX = 0
            textWidth = sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).width
            mutableState.displayLink?.isPaused = !shouldPlayDisplayLink()
            checkIfShouldShowGradientLayer()
        }
    }

    override open var frame: CGRect {
        get {
            super.frame
        }
        set {
            let isSizeChanged = newValue.size != frame.size
            super.frame = frame
            if isSizeChanged {
                offsetX = 0
                mutableState.displayLink?.isPaused = !shouldPlayDisplayLink()
                checkIfShouldShowGradientLayer()
            }
        }
    }

    override open var numberOfLines: Int {
        get { super.numberOfLines }
        set { super.numberOfLines = 1 }
    }

    override open func drawText(in rect: CGRect) {
        var textInitialX: CGFloat = 0
        if textAlignment == .left {
            textInitialX = 0
        } else if textAlignment == .center {
            var floatValue = (bounds.width - textWidth) / 2.0
            floatValue = (floatValue == .leastNormalMagnitude || floatValue == .leastNonzeroMagnitude) ? 0 : floatValue
            let scale = UIScreen.main.scale
            let flattedValue = ceil(floatValue * scale) / scale
            textInitialX = max(0, flattedValue)
        } else if textAlignment == .right {
            textInitialX = max(0, bounds.width - textWidth)
        }

        // 考虑渐变遮罩的偏移
        var textOffsetXByFade: CGFloat = 0
        let shouldTextStartAfterFade = shouldFadeAtEdge && textStartAfterFade && textWidth > bounds.width
        let fadeWidth = bounds.width * 0.5 * max(0, fadeEndPercent - fadeStartPercent)
        if shouldTextStartAfterFade && textInitialX < fadeWidth {
            textOffsetXByFade = fadeWidth
        }
        textInitialX += textOffsetXByFade

        for i in 0..<textRepeatCountConsiderTextWidth {
            attributedText?.draw(in: CGRect(x: offsetX + (textWidth + spacingBetweenHeadToTail) * CGFloat(i) + textInitialX, y: 0, width: textWidth, height: rect.height))
        }
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        fadeLayer?.frame = bounds
    }

    // MARK: - Private
    private var textRepeatCountConsiderTextWidth: Int {
        if textWidth < bounds.width {
            return 1
        }
        return textRepeatCount
    }

    @objc private func handleDisplayLink(_ displayLink: CADisplayLink) {
        if offsetX == 0 {
            displayLink.isPaused = true
            setNeedsDisplay()

            let delay = (isFirstDisplay || textRepeatCount <= 1) ? pauseDurationWhenMoveToEdge : 0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self else { return }
                displayLink.isPaused = !shouldPlayDisplayLink()
                if !displayLink.isPaused {
                    offsetX -= speed
                }
            }

            if delay > 0 && textRepeatCount > 1 {
                isFirstDisplay = false
            }
            return
        }

        offsetX -= speed
        setNeedsDisplay()

        if -offsetX >= textWidth + (textRepeatCountConsiderTextWidth > 1 ? spacingBetweenHeadToTail : 0) {
            displayLink.isPaused = true
            let delay = textRepeatCount > 1 ? pauseDurationWhenMoveToEdge : 0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.offsetX = 0
                self?.handleDisplayLink(displayLink)
            }
        }
    }

    private func shouldPlayDisplayLink() -> Bool {
        let result = window != nil && bounds.width > 0 && textWidth > bounds.width

        // 如果 label.frame 在 window 可视区域之外，也视为不可见，暂停掉 displayLink
        if result && automaticallyValidateVisibleFrame {
            let rectInWindow = window?.convert(frame, from: superview)
            if let rectInWindow, !rectInWindow.intersects(self.window?.bounds ?? .zero) {
                return false
            }
        }

        return result
    }

    private func checkIfShouldShowGradientLayer() {
        let shouldShowFadeLayer = window != nil && shouldFadeAtEdge && bounds.width > 0 && textWidth > bounds.width

        if shouldShowFadeLayer {
            let fadeLayer = CAGradientLayer()
            fadeLayer.locations = [NSNumber(value: fadeStartPercent), NSNumber(value: fadeEndPercent), NSNumber(value: 1 - fadeEndPercent), NSNumber(value: 1 - fadeStartPercent)]
            fadeLayer.startPoint = CGPoint(x: 0, y: 0.5)
            fadeLayer.endPoint = CGPoint(x: 1, y: 0.5)
            fadeLayer.colors = [
                UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0).cgColor,
                UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor,
                UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor,
                UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0).cgColor
            ]
            layer.mask = fadeLayer
            self.fadeLayer = fadeLayer
        } else {
            if layer.mask == fadeLayer {
                layer.mask = nil
            }
        }

        setNeedsLayout()
    }

    // MARK: - Public
    /**
     *  如果在可复用的 UIView 里使用（例如 UITableViewCell、UICollectionViewCell），由于 UIView 可能重复被使用，因此需要在某些显示/隐藏的时机去手动开启/关闭 label 的动画。如果在普通的 UIView 里使用则无需关注这一部分的代码。
     *  尝试开启 label 的滚动动画
     *  @return 是否成功开启
     */
    open func requestToStartAnimation() -> Bool {
        automaticallyValidateVisibleFrame = false
        let shouldPlayDisplayLink = shouldPlayDisplayLink()
        if shouldPlayDisplayLink {
            mutableState.displayLink?.isPaused = false
        }
        return shouldPlayDisplayLink
    }

    /**
     *  尝试停止 label 的滚动动画
     *  @return 是否成功停止
     */
    open func requestToStopAnimation() -> Bool {
        mutableState.displayLink?.isPaused = true
        return true
    }
}
