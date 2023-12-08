//
//  ImageCropController.swift
//  FWFramework
//
//  Created by wuyong on 2023/12/8.
//

import UIKit

/// 图片裁剪样式
public enum ImageCropCroppingStyle: Int {
    case `default`
    case circular
}

/// 常用裁剪比率枚举
public enum ImageCropAspectRatioPreset: Int {
    case presetOriginal
    case presetSquare
    case preset3x2
    case preset5x3
    case preset4x3
    case preset5x4
    case preset7x5
    case preset16x9
    case presetCustom
}

/// 工具栏位置枚举
public enum ImageCropToolbarPosition: Int {
    case bottom
    case top
}

/// 裁剪控制器事件代理协议
@objc public protocol ImageCropControllerDelegate {
    @objc optional func cropController(_ cropController: ImageCropController, didCropImageTo rect: CGRect, angle: Int)
    @objc optional func cropController(_ cropController: ImageCropController, didCropTo image: UIImage, rect: CGRect, angle: Int)
    @objc optional func cropController(_ cropController: ImageCropController, didCropToCircularImage image: UIImage, rect: CGRect, angle: Int)
    @objc optional func cropController(_ cropController: ImageCropController, didFinishCancelled cancelled: Bool)
}

/// [TOCropViewController](https://github.com/TimOliver/TOCropViewController)
open class ImageCropController: UIViewController, ImageCropViewDelegate {
    
    open private(set) var image: UIImage
    open private(set) var croppingStyle: ImageCropCroppingStyle
    open weak var delegate: ImageCropControllerDelegate?
    
    open var imageCropFrame: CGRect {
        get { return cropView.imageCropFrame }
        set { cropView.imageCropFrame = newValue }
    }
    open var angle: Int {
        get { return cropView.angle }
        set { cropView.angle = newValue }
    }
    open var minimumAspectRatio: CGFloat {
        get { return cropView.minimumAspectRatio }
        set { cropView.minimumAspectRatio = newValue }
    }
    open var toolbarHeight: CGFloat {
        get { return _toolbarHeight > 0 ? _toolbarHeight : UIScreen.fw_toolBarHeight - UIScreen.fw_safeAreaInsets.bottom }
        set { _toolbarHeight = newValue }
    }
    private var _toolbarHeight: CGFloat = 0
    open var aspectRatioPreset: ImageCropAspectRatioPreset = .presetOriginal
    open var customAspectRatio: CGSize = .zero {
        didSet {
            setAspectRatioPreset(.presetCustom, animated: false)
        }
    }
    open var customAspectRatioName: String?
    open var originalAspectRatioName: String?
    open var titleTopPadding: CGFloat = 14.0
    open var doneButtonTitle: String? {
        get { return toolbar.doneTextButtonTitle }
        set { toolbar.doneTextButtonTitle = newValue }
    }
    open var cancelButtonTitle: String? {
        get { return toolbar.cancelTextButtonTitle }
        set { toolbar.cancelTextButtonTitle = newValue }
    }
    open var aspectRatioLockDimensionSwapEnabled: Bool {
        get { return cropView.aspectRatioLockDimensionSwapEnabled }
        set { cropView.aspectRatioLockDimensionSwapEnabled = newValue }
    }
    open var aspectRatioLockEnabled: Bool {
        get { return cropView.aspectRatioLockEnabled }
        set { 
            toolbar.clampButtonGlowing = newValue
            cropView.aspectRatioLockEnabled = newValue
            if !aspectRatioPickerButtonHidden {
                aspectRatioPickerButtonHidden = newValue && !resetAspectRatioEnabled
            }
        }
    }
    open var resetAspectRatioEnabled: Bool {
        get { return cropView.resetAspectRatioEnabled }
        set {
            cropView.resetAspectRatioEnabled = newValue
            if !aspectRatioPickerButtonHidden {
                aspectRatioPickerButtonHidden = !newValue && aspectRatioLockEnabled
            }
        }
    }
    open var toolbarPosition: ImageCropToolbarPosition = .bottom
    open var rotateClockwiseButtonHidden: Bool {
        get { return toolbar.rotateClockwiseButtonHidden }
        set { toolbar.rotateClockwiseButtonHidden = newValue }
    }
    open var hidesNavigationBar = true
    open var rotateButtonsHidden: Bool {
        get {
            return toolbar.rotateCounterClockwiseButtonHidden && toolbar.rotateClockwiseButtonHidden
        }
        set {
            toolbar.rotateCounterClockwiseButtonHidden = newValue
            toolbar.rotateClockwiseButtonHidden = newValue
        }
    }
    open var resetButtonHidden: Bool {
        get { return toolbar.resetButtonHidden }
        set { toolbar.resetButtonHidden = newValue }
    }
    open var aspectRatioPickerButtonHidden: Bool {
        get { return toolbar.clampButtonHidden }
        set { toolbar.clampButtonHidden = newValue }
    }
    open var doneButtonHidden: Bool {
        get { return toolbar.doneButtonHidden }
        set { toolbar.doneButtonHidden = newValue }
    }
    open var cancelButtonHidden: Bool {
        get { return toolbar.cancelButtonHidden }
        set { toolbar.cancelButtonHidden = newValue }
    }
    open var allowedAspectRatios: [ImageCropAspectRatioPreset]?
    open var onDidFinishCancelled: ((_ isFinished: Bool) -> Void)?
    open var onDidCropImageToRect: ((_ cropRect: CGRect, _ angle: Int) -> Void)?
    open var onDidCropToRect: ((_ image: UIImage, _ cropRect: CGRect, _ angle: Int) -> Void)?
    open var onDidCropToCircleImage: ((_ image: UIImage, _ cropRect: CGRect, _ angle: Int) -> Void)?
    
    open lazy var cropView: ImageCropView = {
        let result = ImageCropView(croppingStyle: croppingStyle, image: image)
        result.delegate = self
        result.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(result)
        return result
    }()
    
    open lazy var toolbar: ImageCropToolbar = {
        let result = ImageCropToolbar(frame: .zero)
        view.addSubview(result)
        return result
    }()
    
    open var titleLabel: UILabel? {
        if (title?.count ?? 0) < 1 { return nil }
        if let titleLabel = _titleLabel { return titleLabel }
        
        let titleLabel = UILabel(frame: .zero)
        _titleLabel = titleLabel
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.backgroundColor = .clear
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 1
        titleLabel.baselineAdjustment = .alignBaselines
        titleLabel.clipsToBounds = true
        titleLabel.textAlignment = .center
        titleLabel.text = title
        view.insertSubview(titleLabel, aboveSubview: cropView)
        return _titleLabel
    }
    private var _titleLabel: UILabel?
    
    private var toolbarSnapshotView: UIView?
    private var navigationBarHidden: Bool = false
    private var toolbarHidden: Bool = false
    private var inTransition: Bool = false
    private var verticalLayout: Bool {
        return view.bounds.width < view.bounds.height
    }
    private var overrideStatusBar: Bool {
        if navigationController != nil { return false }
        if presentingViewController?.prefersStatusBarHidden == true { return false }
        return true
    }
    private var statusBarHidden: Bool {
        if let navController = navigationController {
            return navController.prefersStatusBarHidden
        }
        if presentingViewController?.prefersStatusBarHidden == true { return true }
        return true
    }
    private var statusBarHeight: CGFloat {
        var height: CGFloat = view.safeAreaInsets.top
        if statusBarHidden && view.safeAreaInsets.bottom <= .ulpOfOne {
            height = 0
        }
        return height
    }
    private var statusBarSafeInsets: UIEdgeInsets {
        var insets = view.safeAreaInsets
        insets.top = statusBarHeight
        return insets
    }
    private var firstTime = false
    
    public convenience init(image: UIImage) {
        self.init(croppingStyle: .default, image: image)
    }
    
    public init(croppingStyle: ImageCropCroppingStyle, image: UIImage) {
        super.init(nibName: nil, bundle: nil)
        self.image = image
        self.croppingStyle = croppingStyle
        self.modalTransitionStyle = .crossDissolve
        self.modalPresentationStyle = .fullScreen
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = cropView.backgroundColor
        let circularMode = croppingStyle == .circular
        cropView.frame = frameForCropView(verticalLayout: verticalLayout)
        toolbar.frame = frameForToolbar(verticalLayout: verticalLayout)
        toolbar.clampButtonHidden = aspectRatioPickerButtonHidden || circularMode
        toolbar.rotateClockwiseButtonHidden = rotateClockwiseButtonHidden
        
        toolbar.doneButtonTapped = { [weak self] in
            self?.doneButtonTapped()
        }
        toolbar.cancelButtonTapped = { [weak self] in
            self?.cancelButtonTapped()
        }
        toolbar.resetButtonTapped = { [weak self] in
            self?.resetCropViewLayout()
        }
        toolbar.clampButtonTapped = { [weak self] in
            self?.showAspectRatioDialog()
        }
        toolbar.rotateCounterClockwiseButtonTapped = { [weak self] in
            self?.rotateCropViewCounterClockwise()
        }
        toolbar.rotateClockwiseButtonTapped = { [weak self] in
            self?.rotateCropViewClockwise()
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if animated {
            inTransition = true
            setNeedsStatusBarAppearanceUpdate()
        }
        
        if let navController = navigationController {
            if hidesNavigationBar {
                navigationBarHidden = navController.isNavigationBarHidden
                toolbarHidden = navController.isToolbarHidden
                navController.setNavigationBarHidden(true, animated: animated)
                navController.setToolbarHidden(true, animated: animated)
            }
            
            modalTransitionStyle = .coverVertical
        } else {
            cropView.setBackgroundImageViewHidden(true, animated: false)
            titleLabel?.alpha = animated ? 0 : 1
        }
        
        if aspectRatioPreset != .presetOriginal {
            setAspectRatioPreset(aspectRatioPreset, animated: false)
        }
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        inTransition = false
        cropView.simpleRenderMode = false
        
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.setNeedsStatusBarAppearanceUpdate()
                self.titleLabel?.alpha = 1.0
            }
        } else {
            setNeedsStatusBarAppearanceUpdate()
            titleLabel?.alpha = 1.0
        }
        
        if cropView.gridOverlayHidden {
            cropView.setGridOverlayHidden(false, animated: animated)
        }
        if navigationController == nil {
            cropView.setBackgroundImageViewHidden(false, animated: animated)
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        inTransition = true
        UIView.animate(withDuration: 0.5) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
        
        if let navController = navigationController, hidesNavigationBar {
            navController.setNavigationBarHidden(navigationBarHidden, animated: animated)
            navController.setToolbarHidden(toolbarHidden, animated: animated)
        }
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        inTransition = false
        setNeedsStatusBarAppearanceUpdate()
    }
    
    open override var title: String? {
        didSet {
            if (title?.count ?? 0) < 1 {
                _titleLabel?.removeFromSuperview()
                cropView.cropRegionInsets = .zero
                _titleLabel = nil
                return
            }
            
            titleLabel?.text = title
            titleLabel?.sizeToFit()
            titleLabel?.frame = frameForTitleLabel(size: titleLabel?.frame.size ?? .zero, verticalLayout: verticalLayout)
        }
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        if navigationController != nil {
            return .lightContent
        }
        return .default
    }
    
    open override var prefersStatusBarHidden: Bool {
        if !overrideStatusBar {
            return statusBarHidden
        }
        return !inTransition && view.superview != nil
    }
    
    open override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return .all
    }
    
    open override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        adjustCropViewInsets()
        adjustToolbarInsets()
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        cropView.frame = frameForCropView(verticalLayout: verticalLayout)
        adjustCropViewInsets()
        cropView.moveCroppedContentToCenterAnimated(false)
        
        if firstTime == false {
            cropView.performInitialSetup()
            firstTime = true
        }
        
        if (title?.count ?? 0) > 0 {
            titleLabel?.frame = frameForTitleLabel(size: titleLabel?.frame.size ?? .zero, verticalLayout: verticalLayout)
            cropView.moveCroppedContentToCenterAnimated(false)
        }
        
        UIView.performWithoutAnimation {
            self.toolbar.frame = self.frameForToolbar(verticalLayout: self.verticalLayout)
            self.adjustToolbarInsets()
            self.toolbar.setNeedsLayout()
        }
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
    }
    
    open func resetCropViewLayout() {
        let animated = cropView.angle == 0
        if resetAspectRatioEnabled {
            aspectRatioLockEnabled = false
        }
        cropView.resetLayoutToDefaultAnimated(animated)
    }
    
    open func setAspectRatioPreset(_ aspectRatioPreset: ImageCropAspectRatioPreset, animated: Bool) {
        
    }
    
    open func cropViewDidBecomeResettable(_ cropView: ImageCropView) {
        toolbar.resetButtonEnabled = true
    }
    
    open func cropViewDidBecomeNonResettable(_ cropView: ImageCropView) {
        toolbar.resetButtonEnabled = false
    }
    
    private func frameForToolbar(verticalLayout: Bool) -> CGRect {
        let insets = statusBarSafeInsets
        var frame: CGRect = .zero
        let toolbarHeight = self.toolbarHeight
        
        if !verticalLayout {
            frame.origin.x = insets.left
            frame.origin.y = 0
            frame.size.width = toolbarHeight
            frame.size.height = view.frame.height
        } else {
            frame.origin.x = 0
            frame.size.width = view.bounds.width
            frame.size.height = toolbarHeight
            if toolbarPosition == .bottom {
                frame.origin.y = view.bounds.height - (frame.size.height + insets.bottom)
            } else {
                frame.origin.y = insets.top
            }
        }
        return frame
    }
    
    private func frameForCropView(verticalLayout: Bool) -> CGRect {
        let view: UIView = parent?.view ?? self.view
        let insets = statusBarSafeInsets
        let bounds = view.bounds
        var frame: CGRect = .zero
        let toolbarHeight = self.toolbarHeight
        
        if !verticalLayout {
            frame.origin.x = toolbarHeight + insets.left
            frame.size.width = bounds.width - frame.origin.x
            frame.size.height = bounds.height
        } else {
            frame.size.height = bounds.height
            frame.size.width = bounds.width
            
            if toolbarPosition == .bottom {
                frame.size.height -= (insets.bottom + toolbarHeight)
            } else if toolbarPosition == .top {
                frame.origin.y = toolbarHeight + insets.top
                frame.size.height -= frame.origin.y
            }
        }
        return frame
    }
    
    private func frameForTitleLabel(size: CGSize, verticalLayout: Bool) -> CGRect {
        var frame = CGRect(origin: .zero, size: size)
        var viewWidth: CGFloat = view.bounds.width
        var x: CGFloat = 0
        
        if !verticalLayout {
            x = titleTopPadding
            x += view.safeAreaInsets.left
            viewWidth -= x
        }
        
        frame.origin.x = ceil((viewWidth - frame.size.width) * 0.5)
        if !verticalLayout { frame.origin.x += x }
        frame.origin.y = view.safeAreaInsets.top + titleTopPadding
        return frame
    }
    
    private func adjustCropViewInsets() {
        let insets = statusBarSafeInsets
        if (titleLabel?.text?.count ?? 0) < 1 {
            if verticalLayout {
                if toolbarPosition == .top {
                    cropView.cropRegionInsets = UIEdgeInsets(top: 0, left: 0, bottom: insets.bottom, right: 0)
                } else {
                    cropView.cropRegionInsets = UIEdgeInsets(top: insets.top, left: 0, bottom: 0, right: 0)
                }
            } else {
                cropView.cropRegionInsets = UIEdgeInsets(top: 0, left: 0, bottom: insets.bottom, right: 0)
            }
            return
        }
        
        var frame = titleLabel?.frame ?? .zero
        frame.size = titleLabel?.sizeThatFits(cropView.frame.size) ?? .zero
        titleLabel?.frame = frame
        
        var verticalInset = statusBarHeight
        verticalInset += titleTopPadding
        verticalInset += titleLabel?.frame.size.height ?? 0
        cropView.cropRegionInsets = UIEdgeInsets(top: verticalInset, left: 0, bottom: insets.bottom, right: 0)
    }
    
    private func adjustToolbarInsets() {
        var insets: UIEdgeInsets = .zero
        if !verticalLayout {
            insets.left = view.safeAreaInsets.left
        } else {
            if toolbarPosition == .top {
                insets.top = view.safeAreaInsets.top
            } else {
                insets.bottom = view.safeAreaInsets.bottom
            }
        }
        
        toolbar.backgroundViewOutsets = insets
        toolbar.statusBarHeightInset = statusBarHeight
        toolbar.setNeedsLayout()
    }
    
    private func _willRotateToInterfaceOrientation(_ toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        
    }
    
    private func _willAnimateRotationToInterfaceOrientation(_ toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        
    }
    
    private func _didRotateFromInterfaceOrientation(_ fromInterfaceOrientation: UIInterfaceOrientation) {
        
    }
    
    private func showAspectRatioDialog() {
        
    }
    
    private func rotateCropViewClockwise() {
        cropView.rotateImageNinetyDegreesAnimated(true, clockwise: true)
    }
    
    private func rotateCropViewCounterClockwise() {
        cropView.rotateImageNinetyDegreesAnimated(true, clockwise: false)
    }
    
    private func cancelButtonTapped() {
        
    }
    
    private func doneButtonTapped() {
        
    }
    
}

open class ImageCropOverlayView: UIView {
    
    open var gridHidden = false
    open var displayHorizontalGridLines = false
    open var displayVerticalGridLines = false
    
    private let layerCornerWidth: CGFloat = 20
    
    open func setGridHidden(_ hidden: Bool, animated: Bool) {
        
    }
    
}

open class ImageCropScrollView: UIScrollView {
    open var touchesBegan: (() -> Void)?
    open var touchesCancelled: (() -> Void)?
    open var touchesEnded: (() -> Void)?
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesBegan?()
        super.touchesBegan(touches, with: event)
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded?()
        super.touchesEnded(touches, with: event)
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesCancelled?()
        super.touchesCancelled(touches, with: event)
    }
}

open class ImageCropToolbar: UIView {
    open var statusBarHeightInset: CGFloat
    open var buttonInsetPadding: CGFloat
    open var backgroundViewOutsets: UIEdgeInsets = .zero
    open var doneTextButtonTitle: String?
    open var cancelTextButtonTitle: String?
    
    open var cancelButtonTapped: (() -> Void)?
    open var doneButtonTapped: (() -> Void)?
    open var rotateCounterClockwiseButtonTapped: (() -> Void)?
    open var rotateClockwiseButtonTapped: (() -> Void)?
    open var clampButtonTapped: (() -> Void)?
    open var resetButtonTapped: (() -> Void)?
    
    open var clampButtonGlowing = false
    open private(set) var clampButtonFrame: CGRect
    
    open var clampButtonHidden = false
    open var rotateCounterClockwiseButtonHidden = false
    open var rotateClockwiseButtonHidden = false
    open var resetButtonHidden = false
    open var doneButtonHidden = false
    open var cancelButtonHidden = false
    
    open var resetButtonEnabled = false
    open private(set) var doneButtonFrame: CGRect
    
    open lazy var backgroundView: UIView = {
        
    }()
    
    open lazy var doneTextButton: UIButton = {
        
    }()
    
    open lazy var doneIconButton: UIButton = {
        
    }()
    
    open lazy var cancelTextButton: UIButton = {
        
    }()
    
    open lazy var cancelIconButton: UIButton = {
        
    }()
    
    open private(set) var visibleCancelButton: UIView
    
    open lazy var rotateCounterClockwiseButton: UIButton = {
        
    }()
    
    open lazy var resetButton: UIButton = {
        
    }()
    
    open lazy var clampButton: UIButton = {
        
    }()
    
    open private(set) var rotateClockwiseButton: UIButton?
    
    open private(set) var rotateButton: UIButton
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public protocol ImageCropViewDelegate: AnyObject {
    func cropViewDidBecomeResettable(_ cropView: ImageCropView)
    func cropViewDidBecomeNonResettable(_ cropView: ImageCropView)
}

open class ImageCropView: UIView {
    open private(set) var image: UIImage
    open private(set) var croppingStyle: ImageCropCroppingStyle
    open weak var delegate: ImageCropViewDelegate?
    open var cropBoxResizeEnabled = true
    open private(set) var canBeReset = false
    open private(set) var cropBoxFrame: CGRect
    open private(set) var imageViewFrame: CGRect
    open var cropRegionInsets: UIEdgeInsets
    open var simpleRenderMode = false
    open var internalLayoutDisabled = false
    open var aspectRatio: CGSize
    open var aspectRatioLockEnabled = false
    open var aspectRatioLockDimensionSwapEnabled = false
    open var resetAspectRatioEnabled = true
    open private(set) var cropBoxAspectRatioIsPortrait
    open var angle: Int
    open var croppingViewsHidden = false
    open var imageCropFrame: CGRect
    open var gridOverlayHidden = false
    open var cropViewPadding: CGFloat = 0
    open var cropAdjustingDelay: TimeInterval = 0.8
    open var minimumAspectRatio: CGFloat = 0
    open var maximumZoomScale: CGFloat
    open var alwaysShowCroppingGrid = false
    open var translucencyAlwaysHidden = false
    
    open lazy var gridOverlayView: ImageCropOverlayView = {
        
    }()
    
    open lazy var foregroundContainerView: UIView = {
        
    }()
    
    public init(image: UIImage) {
        
    }
    
    public init(croppingStyle: ImageCropCroppingStyle, image: UIImage) {
        
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func performInitialSetup() {
        
    }
    
    open func setSimpleRenderMode(_ simpleMode: Bool, animated: Bool) {
        
    }
    
    open func prepareForRotation() {
        
    }
    
    open func performRelayoutForRotation() {
        
    }
    
    open func resetLayoutToDefaultAnimated(_ animated: Bool) {
        
    }
    
    open func setAspectRatio(_ aspectRatio: CGSize, animated: Bool) {
        
    }
    
    open func rotateImageNinetyDegreesAnimated(_ animated: Bool) {
        
    }
    
    open func rotateImageNinetyDegreesAnimated(_ animated: Bool, clockwise: Bool) {
        
    }
    
    open func setGridOverlayHidden(_ gridOverlayHidden: Bool, animated: Bool) {
        
    }
    
    open func setCroppingViewsHidden(_ hidden: Bool, animated: Bool) {
        
    }
    
    open func setBackgroundImageViewHidden(_ hidden: Bool, animated: Bool) {
        
    }
    
    open func moveCroppedContentToCenterAnimated(_ animated: Bool) {
        
    }
}
