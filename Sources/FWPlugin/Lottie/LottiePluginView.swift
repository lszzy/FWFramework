//
//  LottiePluginImpl.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
import Lottie
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

/// Lottile插件视图，可用于加载、进度、下拉刷新等
open class LottiePluginView: UIView, IndicatorViewPlugin, ProgressViewPlugin {
    
    // MARK: - Accessor
    /// 设置或获取进度条大小，默认{37,37}
    open var indicatorSize: CGSize {
        get { return bounds.size }
        set { frame = CGRect(x: frame.minX, y: frame.minY, width: newValue.width, height: newValue.height) }
    }
    
    /// 进度条当前颜色，暂不支持
    open var indicatorColor: UIColor? = .white
    
    /// 设置内容边距，默认zero
    open var contentInset: UIEdgeInsets = .zero {
        didSet {
            animationView.frame = bounds.inset(by: contentInset)
        }
    }
    
    /// 停止动画时是否自动隐藏，默认true
    open var hidesWhenStopped: Bool = true
    
    /// 修改指示器进度时是否始终执行动画，默认false
    open var animateWhenProgress: Bool = false

    /// 当前是否正在执行动画
    open var isAnimating: Bool {
        return animationView.isAnimationPlaying
    }
    
    /// 当前动画速度，默认1
    open var animationSpeed: CGFloat {
        get { return animationView.animationSpeed }
        set { animationView.animationSpeed = newValue }
    }
    
    /// 指示器进度，大于0小于1时自动显示
    open var progress: CGFloat {
        get {
            if animateWhenProgress { return _progress }
            return animationView.currentProgress
        }
        set {
            setProgress(newValue, animated: false)
        }
    }
    private var _progress: CGFloat = 0
    
    // MARK: - Subviews
    /// 当前LottieView视图
    open lazy var animationView: LottieAnimationView = {
        let animationView = LottieAnimationView(frame: bounds)
        animationView.isUserInteractionEnabled = false
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.loopMode = .loop
        return animationView
    }()
    
    // MARK: - Lifecycle
    public init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 37, height: 37))
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
    
    // MARK: - Setup
    private func setupSubviews() {
        isUserInteractionEnabled = false
        clipsToBounds = true
        isHidden = true
        
        addSubview(animationView)
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
    }
    
    // MARK: - Public
    /// 设置指示器进度，大于0小于1时自动显示
    open func setProgress(_ value: CGFloat, animated: Bool) {
        let progress: CGFloat = max(0.0, min(value, 1.0))
        let showingProgress = 0 < progress && progress < 1
        
        if animateWhenProgress {
            _progress = progress
            if showingProgress {
                if !isAnimating { startAnimating() }
            } else {
                if isAnimating { stopAnimating() }
            }
            return
        }
        
        if showingProgress { isHidden = false }
        if animated {
            let currentProgress = animationView.currentProgress
            animationView.play(fromProgress: currentProgress, toProgress: progress, loopMode: .playOnce) { [weak self] _ in
                guard let this = self else { return }
                if !showingProgress && this.hidesWhenStopped { this.isHidden = true }
            }
        } else {
            animationView.currentProgress = progress
            if !showingProgress && hidesWhenStopped { isHidden = true }
        }
    }
    
    /// 设置动画json文件
    open func setAnimation(name: String, bundle: Bundle? = nil) {
        animationView.animation = LottieAnimation.named(name, bundle: bundle ?? .main)
    }
    
    /// 设置动画Data数据
    open func setAnimation(data: Data) {
        animationView.animation = try? LottieAnimation.from(data: data)
    }
    
    /// 开始加载动画
    open func startAnimating() {
        if isAnimating { return }
        isHidden = false
        animationView.play()
    }
    
    /// 停止加载动画
    open func stopAnimating() {
        animationView.stop()
        if hidesWhenStopped { isHidden = true }
    }
    
    // MARK: - Override
    open override var frame: CGRect {
        didSet { invalidateIntrinsicContentSize() }
    }
    
    open override var bounds: CGRect {
        didSet { invalidateIntrinsicContentSize() }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        animationView.frame = bounds.inset(by: contentInset)
    }
    
    open override var intrinsicContentSize: CGSize {
        return bounds.size
    }
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        return bounds.size
    }
    
}

// MARK: - Autoloader+Lottie
@objc extension Autoloader {
    static func loadPlugin_Lottie() {}
}
