//
//  ImageCropController.swift
//  FWFramework
//
//  Created by wuyong on 2023/12/8.
//

import UIKit
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

/// 图片裁剪样式
public enum ImageCropCroppingStyle: Int, Sendable {
    case `default`
    case circular
}

/// 常用裁剪比率枚举
public enum ImageCropAspectRatioPreset: Int, Sendable {
    case presetOriginal = 0
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
public enum ImageCropToolbarPosition: Int, Sendable {
    case bottom
    case top
}

/// 裁剪控制器事件代理协议
@MainActor @objc public protocol ImageCropControllerDelegate: NSObjectProtocol {
    @objc optional func cropController(_ cropController: ImageCropController, didCropImageToRect rect: CGRect, angle: Int)
    @objc optional func cropController(_ cropController: ImageCropController, didCropToImage image: UIImage, rect: CGRect, angle: Int)
    @objc optional func cropController(_ cropController: ImageCropController, didCropToCircularImage image: UIImage, rect: CGRect, angle: Int)
    @objc optional func cropController(_ cropController: ImageCropController, didFinishCancelled cancelled: Bool)
}

/// [TOCropViewController](https://github.com/TimOliver/TOCropViewController)
open class ImageCropController: UIViewController, ImageCropControllerProtocol, ImageCropViewDelegate {
    open private(set) var image: UIImage
    open private(set) var croppingStyle: ImageCropCroppingStyle
    open weak var delegate: ImageCropControllerDelegate?

    open var imageCropFrame: CGRect {
        get { cropView.imageCropFrame }
        set { cropView.imageCropFrame = newValue }
    }

    open var angle: Int {
        get { cropView.angle }
        set { cropView.angle = newValue }
    }

    open var minimumAspectRatio: CGFloat {
        get { cropView.minimumAspectRatio }
        set { cropView.minimumAspectRatio = newValue }
    }

    open var toolbarHeight: CGFloat {
        get { _toolbarHeight > 0 ? _toolbarHeight : UIScreen.fw.toolBarHeight - UIScreen.fw.safeAreaInsets.bottom }
        set { _toolbarHeight = newValue }
    }

    private var _toolbarHeight: CGFloat = 0
    open var aspectRatioPreset: ImageCropAspectRatioPreset {
        get { _aspectRatioPreset }
        set { setAspectRatioPreset(newValue, animated: false) }
    }

    private var _aspectRatioPreset: ImageCropAspectRatioPreset = .presetOriginal
    open var customAspectRatio: CGSize = .zero {
        didSet {
            setAspectRatioPreset(.presetCustom, animated: false)
        }
    }

    open var customAspectRatioName: String?
    open var originalAspectRatioName: String?
    open var titleTopPadding: CGFloat = 14.0
    open var doneButtonTitle: String? {
        get { toolbar.doneTextButtonTitle }
        set { toolbar.doneTextButtonTitle = newValue }
    }

    open var cancelButtonTitle: String? {
        get { toolbar.cancelTextButtonTitle }
        set { toolbar.cancelTextButtonTitle = newValue }
    }

    open var aspectRatioLockDimensionSwapEnabled: Bool {
        get { cropView.aspectRatioLockDimensionSwapEnabled }
        set { cropView.aspectRatioLockDimensionSwapEnabled = newValue }
    }

    open var aspectRatioLockEnabled: Bool {
        get { cropView.aspectRatioLockEnabled }
        set {
            toolbar.clampButtonGlowing = newValue
            cropView.aspectRatioLockEnabled = newValue
            if !aspectRatioPickerButtonHidden {
                aspectRatioPickerButtonHidden = newValue && !resetAspectRatioEnabled
            }
        }
    }

    open var resetAspectRatioEnabled: Bool {
        get { cropView.resetAspectRatioEnabled }
        set {
            cropView.resetAspectRatioEnabled = newValue
            if !aspectRatioPickerButtonHidden {
                aspectRatioPickerButtonHidden = !newValue && aspectRatioLockEnabled
            }
        }
    }

    open var toolbarPosition: ImageCropToolbarPosition = .bottom
    open var rotateClockwiseButtonHidden: Bool {
        get { toolbar.rotateClockwiseButtonHidden }
        set { toolbar.rotateClockwiseButtonHidden = newValue }
    }

    open var hidesNavigationBar = true
    open var rotateButtonsHidden: Bool {
        get {
            toolbar.rotateCounterClockwiseButtonHidden && toolbar.rotateClockwiseButtonHidden
        }
        set {
            toolbar.rotateCounterClockwiseButtonHidden = newValue
            toolbar.rotateClockwiseButtonHidden = newValue
        }
    }

    open var resetButtonHidden: Bool {
        get { toolbar.resetButtonHidden }
        set { toolbar.resetButtonHidden = newValue }
    }

    open var aspectRatioPickerButtonHidden: Bool {
        get { toolbar.clampButtonHidden }
        set { toolbar.clampButtonHidden = newValue }
    }

    open var doneButtonHidden: Bool {
        get { toolbar.doneButtonHidden }
        set { toolbar.doneButtonHidden = newValue }
    }

    open var cancelButtonHidden: Bool {
        get { toolbar.cancelButtonHidden }
        set { toolbar.cancelButtonHidden = newValue }
    }

    open var allowedAspectRatios: [ImageCropAspectRatioPreset]?
    open var onDidFinishCancelled: ((_ isFinished: Bool) -> Void)?
    open var onDidCropImageToRect: ((_ cropRect: CGRect, _ angle: Int) -> Void)?
    open var onDidCropToImage: ((_ image: UIImage, _ cropRect: CGRect, _ angle: Int) -> Void)?
    open var onDidCropToCircularImage: ((_ image: UIImage, _ cropRect: CGRect, _ angle: Int) -> Void)?

    open lazy var cropView: ImageCropView = {
        let result = ImageCropView(croppingStyle: croppingStyle, image: image)
        result.delegate = self
        result.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return result
    }()

    open lazy var toolbar: ImageCropToolbar = {
        let result = ImageCropToolbar(frame: .zero)
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
    private var verticalLayout: Bool {
        view.bounds.width < view.bounds.height
    }

    private var statusBarHeight: CGFloat {
        var height: CGFloat = view.safeAreaInsets.top
        if prefersStatusBarHidden && view.safeAreaInsets.bottom <= .ulpOfOne {
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
        self.image = image
        self.croppingStyle = croppingStyle
        super.init(nibName: nil, bundle: nil)
        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .fullScreen
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = cropView.backgroundColor
        view.addSubview(cropView)
        view.addSubview(toolbar)
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

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

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

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        cropView.simpleRenderMode = false

        if animated {
            UIView.animate(withDuration: 0.3) {
                self.titleLabel?.alpha = 1.0
            }
        } else {
            titleLabel?.alpha = 1.0
        }

        if cropView.gridOverlayHidden {
            cropView.setGridOverlayHidden(false, animated: animated)
        }
        if navigationController == nil {
            cropView.setBackgroundImageViewHidden(false, animated: animated)
        }
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let navController = navigationController, hidesNavigationBar {
            navController.setNavigationBarHidden(navigationBarHidden, animated: animated)
            navController.setToolbarHidden(toolbarHidden, animated: animated)
        }
    }

    override open var prefersStatusBarHidden: Bool {
        true
    }

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override open var title: String? {
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

    override open var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        .all
    }

    override open func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        adjustCropViewInsets()
        adjustToolbarInsets()
    }

    override open func viewDidLayoutSubviews() {
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

    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if size == view.bounds.size { return }

        var orientation: UIInterfaceOrientation = .portrait
        if view.bounds.width < size.width {
            orientation = .landscapeLeft
        }

        _willRotateToInterfaceOrientation(orientation, duration: coordinator.transitionDuration)
        coordinator.animate { [weak self] _ in
            self?._willAnimateRotationToInterfaceOrientation(orientation, duration: coordinator.transitionDuration)
        } completion: { [weak self] _ in
            self?._didRotateFromInterfaceOrientation(orientation)
        }
    }

    open func resetCropViewLayout() {
        let animated = cropView.angle == 0
        if resetAspectRatioEnabled {
            aspectRatioLockEnabled = false
        }
        cropView.resetLayoutToDefaultAnimated(animated)
    }

    open func setAspectRatioPreset(_ aspectRatioPreset: ImageCropAspectRatioPreset, animated: Bool) {
        var aspectRatio: CGSize = .zero
        _aspectRatioPreset = aspectRatioPreset

        switch aspectRatioPreset {
        case .presetOriginal:
            aspectRatio = .zero
        case .presetSquare:
            aspectRatio = CGSize(width: 1.0, height: 1.0)
        case .preset3x2:
            aspectRatio = CGSize(width: 3.0, height: 2.0)
        case .preset5x3:
            aspectRatio = CGSize(width: 5.0, height: 3.0)
        case .preset4x3:
            aspectRatio = CGSize(width: 4.0, height: 3.0)
        case .preset5x4:
            aspectRatio = CGSize(width: 5.0, height: 4.0)
        case .preset7x5:
            aspectRatio = CGSize(width: 7.0, height: 5.0)
        case .preset16x9:
            aspectRatio = CGSize(width: 16.0, height: 9.0)
        case .presetCustom:
            aspectRatio = customAspectRatio
        }

        let aspectRatioCanSwapDimensions = !aspectRatioLockEnabled ||
            (aspectRatioLockEnabled && aspectRatioLockDimensionSwapEnabled)
        if cropView.cropBoxAspectRatioIsPortrait && aspectRatioCanSwapDimensions {
            let width = aspectRatio.width
            aspectRatio.width = aspectRatio.height
            aspectRatio.height = width
        }

        cropView.setAspectRatio(aspectRatio, animated: animated)
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
        let toolbarHeight = toolbarHeight

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
        let view: UIView = parent?.view ?? view
        let insets = statusBarSafeInsets
        let bounds = view.bounds
        var frame: CGRect = .zero
        let toolbarHeight = toolbarHeight

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
        toolbarSnapshotView = toolbar.snapshotView(afterScreenUpdates: false)
        toolbarSnapshotView?.frame = toolbar.frame
        if toInterfaceOrientation.isLandscape {
            toolbarSnapshotView?.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        } else {
            toolbarSnapshotView?.autoresizingMask = [.flexibleHeight, .flexibleRightMargin]
        }
        if let snapshotView = toolbarSnapshotView {
            view.addSubview(snapshotView)
        }

        var frame = frameForToolbar(verticalLayout: toInterfaceOrientation.isPortrait)
        if toInterfaceOrientation.isLandscape {
            frame.origin.x = -frame.size.width
        } else {
            frame.origin.y = view.bounds.height
        }
        toolbar.frame = frame
        toolbar.layoutIfNeeded()
        toolbar.alpha = 0

        cropView.prepareForRotation()
        cropView.frame = frameForCropView(verticalLayout: !toInterfaceOrientation.isPortrait)
        cropView.simpleRenderMode = true
        cropView.internalLayoutDisabled = true
    }

    private func _willAnimateRotationToInterfaceOrientation(_ toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        toolbar.frame = frameForToolbar(verticalLayout: !toInterfaceOrientation.isLandscape)
        toolbar.layer.removeAllAnimations()
        toolbar.layer.sublayers?.forEach { $0.removeAllAnimations() }

        UIView.animate(withDuration: duration, delay: 0, options: .beginFromCurrentState, animations: {
            self.cropView.frame = self.frameForCropView(verticalLayout: !toInterfaceOrientation.isLandscape)
            self.toolbar.frame = self.frameForToolbar(verticalLayout: toInterfaceOrientation.isPortrait)
            self.cropView.performRelayoutForRotation()
        }, completion: nil)

        toolbarSnapshotView?.alpha = 0
        toolbar.alpha = 1.0
    }

    private func _didRotateFromInterfaceOrientation(_ fromInterfaceOrientation: UIInterfaceOrientation) {
        toolbarSnapshotView?.removeFromSuperview()
        toolbarSnapshotView = nil

        cropView.setSimpleRenderMode(false, animated: true)
        cropView.internalLayoutDisabled = false
    }

    private func showAspectRatioDialog() {
        if cropView.aspectRatioLockEnabled {
            cropView.aspectRatioLockEnabled = false
            toolbar.clampButtonGlowing = false
            return
        }

        let verticalCropBox = cropView.cropBoxAspectRatioIsPortrait
        let cancelButtonTitle = cancelButtonTitle ?? FrameworkBundle.cancelButton
        let originalButtonTitle = originalAspectRatioName ?? FrameworkBundle.originalButton

        let portraitRatioTitles = [originalButtonTitle, "1:1", "2:3", "3:5", "3:4", "4:5", "5:7", "9:16"]
        let landscapeRatioTitles = [originalButtonTitle, "1:1", "3:2", "5:3", "4:3", "5:4", "7:5", "16:9"]

        var ratioValues = [ImageCropAspectRatioPreset]()
        var itemStrings = [String]()
        if let allowedRatios = allowedAspectRatios {
            for allowedRatio in allowedRatios {
                let itemTitle = verticalCropBox ? portraitRatioTitles[allowedRatio.rawValue] : landscapeRatioTitles[allowedRatio.rawValue]
                itemStrings.append(itemTitle)
                ratioValues.append(allowedRatio)
            }
        } else {
            for i in 0..<(ImageCropAspectRatioPreset.presetCustom.rawValue) {
                let itemTitle = verticalCropBox ? portraitRatioTitles[i] : landscapeRatioTitles[i]
                itemStrings.append(itemTitle)
                ratioValues.append(.init(rawValue: i) ?? .presetOriginal)
            }
        }

        if let customName = customAspectRatioName, customAspectRatio != .zero {
            itemStrings.append(customName)
            ratioValues.append(.presetCustom)
        }

        fw.showSheet(title: nil, message: nil, cancel: cancelButtonTitle, actions: itemStrings) { [weak self] index in
            self?.setAspectRatioPreset(ratioValues[index], animated: true)
            self?.aspectRatioLockEnabled = true
        }
    }

    private func rotateCropViewClockwise() {
        cropView.rotateImageNinetyDegreesAnimated(true, clockwise: true)
    }

    private func rotateCropViewCounterClockwise() {
        cropView.rotateImageNinetyDegreesAnimated(true, clockwise: false)
    }

    private func cancelButtonTapped() {
        var isDelegateOrCallbackHandled = false
        if delegate?.cropController?(self, didFinishCancelled: true) != nil {
            isDelegateOrCallbackHandled = true
        }

        if onDidFinishCancelled != nil {
            onDidFinishCancelled?(true)
            isDelegateOrCallbackHandled = true
        }

        if !isDelegateOrCallbackHandled {
            if let navController = navigationController {
                navController.popViewController(animated: true)
            } else {
                modalTransitionStyle = .coverVertical
                presentingViewController?.dismiss(animated: true)
            }
        }
    }

    private func doneButtonTapped() {
        let cropFrame = cropView.imageCropFrame
        let angle = cropView.angle

        var isCallbackOrDelegateHandled = false
        if delegate?.cropController?(self, didCropImageToRect: cropFrame, angle: angle) != nil {
            isCallbackOrDelegateHandled = true
        }
        if onDidCropImageToRect != nil {
            onDidCropImageToRect?(cropFrame, angle)
            isCallbackOrDelegateHandled = true
        }

        let isCircularImageHandled = delegate?.responds(to: #selector(ImageCropControllerDelegate.cropController(_:didCropToCircularImage:rect:angle:))) == true || onDidCropToCircularImage != nil
        let isDidCropToImageHandled = delegate?.responds(to: #selector(ImageCropControllerDelegate.cropController(_:didCropToImage:rect:angle:))) == true || onDidCropToImage != nil

        if croppingStyle == .circular && isCircularImageHandled {
            if let image = image.fw.croppedImage(frame: cropFrame, angle: angle, circular: true) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                    self.delegate?.cropController?(self, didCropToCircularImage: image, rect: cropFrame, angle: angle)
                    self.onDidCropToCircularImage?(image, cropFrame, angle)
                }
            }

            isCallbackOrDelegateHandled = true
        } else if isDidCropToImageHandled {
            var image: UIImage?
            if angle == 0 && cropFrame == CGRect(origin: .zero, size: self.image.size) {
                image = self.image
            } else {
                image = self.image.fw.croppedImage(frame: cropFrame, angle: angle, circular: false)
            }

            if let image {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                    self.delegate?.cropController?(self, didCropToImage: image, rect: cropFrame, angle: angle)
                    self.onDidCropToImage?(image, cropFrame, angle)
                }
            }

            isCallbackOrDelegateHandled = true
        }

        if !isCallbackOrDelegateHandled {
            presentingViewController?.dismiss(animated: true)
        }
    }
}

open class ImageCropOverlayView: UIView {
    open var gridHidden: Bool {
        get { _gridHidden }
        set { setGridHidden(newValue, animated: false) }
    }

    private var _gridHidden = false
    open var displayHorizontalGridLines = true {
        didSet {
            horizontalGridLines.forEach { $0.removeFromSuperview() }
            if displayHorizontalGridLines {
                horizontalGridLines = [createNewLineView(), createNewLineView()]
            } else {
                horizontalGridLines = []
            }
            setNeedsDisplay()
        }
    }

    open var displayVerticalGridLines = true {
        didSet {
            verticalGridLines.forEach { $0.removeFromSuperview() }
            if displayVerticalGridLines {
                verticalGridLines = [createNewLineView(), createNewLineView()]
            } else {
                verticalGridLines = []
            }
            setNeedsDisplay()
        }
    }

    private var horizontalGridLines: [UIView] = []
    private var verticalGridLines: [UIView] = []
    private var outerLineViews: [UIView] = []
    private var topLeftLineViews: [UIView] = []
    private var bottomLeftLineViews: [UIView] = []
    private var bottomRightLineViews: [UIView] = []
    private var topRightLineViews: [UIView] = []
    private let layerCornerWidth: CGFloat = 20

    override public init(frame: CGRect) {
        super.init(frame: frame)
        didInitialize()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        didInitialize()
    }

    private func didInitialize() {
        clipsToBounds = false

        outerLineViews = [createNewLineView(), createNewLineView(), createNewLineView(), createNewLineView()]
        topLeftLineViews = [createNewLineView(), createNewLineView()]
        bottomLeftLineViews = [createNewLineView(), createNewLineView()]
        topRightLineViews = [createNewLineView(), createNewLineView()]
        bottomRightLineViews = [createNewLineView(), createNewLineView()]
        horizontalGridLines = [createNewLineView(), createNewLineView()]
        verticalGridLines = [createNewLineView(), createNewLineView()]
        setNeedsDisplay()
    }

    override open var frame: CGRect {
        didSet {
            if !outerLineViews.isEmpty {
                layoutLines()
            }
        }
    }

    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        if !outerLineViews.isEmpty {
            layoutLines()
        }
    }

    open func setGridHidden(_ hidden: Bool, animated: Bool) {
        _gridHidden = hidden

        if !animated {
            horizontalGridLines.forEach { $0.alpha = hidden ? 0.0 : 1.0 }
            verticalGridLines.forEach { $0.alpha = hidden ? 0.0 : 1.0 }
            return
        }

        UIView.animate(withDuration: hidden ? 0.35 : 0.2) {
            self.horizontalGridLines.forEach { $0.alpha = hidden ? 0.0 : 1.0 }
            self.verticalGridLines.forEach { $0.alpha = hidden ? 0.0 : 1.0 }
        }
    }

    private func layoutLines() {
        let boundsSize = bounds.size

        for i in 0..<4 {
            let lineView = outerLineViews[i]

            var frame: CGRect = .zero
            switch i {
            case 0:
                frame = CGRect(x: 0, y: -1.0, width: boundsSize.width + 2.0, height: 1.0)
            case 1:
                frame = CGRect(x: boundsSize.width, y: 0.0, width: 1.0, height: boundsSize.height)
            case 2:
                frame = CGRect(x: -1.0, y: boundsSize.height, width: boundsSize.width + 2.0, height: 1.0)
            case 3:
                frame = CGRect(x: -1.0, y: 0, width: 1.0, height: boundsSize.height + 1.0)
            default:
                break
            }

            lineView.frame = frame
        }

        let cornerLines = [topLeftLineViews, topRightLineViews, bottomRightLineViews, bottomLeftLineViews]
        for i in 0..<4 {
            let cornerLine = cornerLines[i]

            var verticalFrame = CGRect.zero
            var horizontalFrame = CGRect.zero
            switch i {
            case 0:
                verticalFrame = CGRect(x: -3.0, y: -3.0, width: 3.0, height: layerCornerWidth + 3.0)
                horizontalFrame = CGRect(x: 0, y: -3.0, width: layerCornerWidth, height: 3.0)
            case 1:
                verticalFrame = CGRect(x: boundsSize.width, y: -3.0, width: 3.0, height: layerCornerWidth + 3.0)
                horizontalFrame = CGRect(x: boundsSize.width - layerCornerWidth, y: -3.0, width: layerCornerWidth, height: 3.0)
            case 2:
                verticalFrame = CGRect(x: boundsSize.width, y: boundsSize.height - layerCornerWidth, width: 3.0, height: layerCornerWidth + 3.0)
                horizontalFrame = CGRect(x: boundsSize.width - layerCornerWidth, y: boundsSize.height, width: layerCornerWidth, height: 3.0)
            case 3:
                verticalFrame = CGRect(x: -3.0, y: boundsSize.height - layerCornerWidth, width: 3.0, height: layerCornerWidth)
                horizontalFrame = CGRect(x: -3.0, y: boundsSize.height, width: layerCornerWidth + 3.0, height: 3.0)
            default:
                break
            }

            cornerLine[0].frame = verticalFrame
            cornerLine[1].frame = horizontalFrame
        }

        let thickness: CGFloat = 1.0 / UIScreen.main.scale
        var numberOfLines = horizontalGridLines.count
        var padding = (bounds.height - (thickness * CGFloat(numberOfLines))) / (CGFloat(numberOfLines) + 1.0)
        for i in 0..<numberOfLines {
            let lineView = horizontalGridLines[i]
            var frame = CGRect.zero
            frame.size.height = thickness
            frame.size.width = bounds.width
            frame.origin.y = (padding * CGFloat(i + 1)) + (thickness * CGFloat(i))
            lineView.frame = frame
        }

        numberOfLines = verticalGridLines.count
        padding = (bounds.width - (thickness * CGFloat(numberOfLines))) / (CGFloat(numberOfLines) + 1)
        for i in 0..<numberOfLines {
            let lineView = verticalGridLines[i]
            var frame = CGRect.zero
            frame.size.width = thickness
            frame.size.height = bounds.height
            frame.origin.x = (padding * CGFloat(i + 1)) + (thickness * CGFloat(i))
            lineView.frame = frame
        }
    }

    private func createNewLineView() -> UIView {
        let newLine = UIView(frame: .zero)
        newLine.backgroundColor = .white
        addSubview(newLine)
        return newLine
    }
}

open class ImageCropScrollView: UIScrollView {
    open var touchesBegan: (() -> Void)?
    open var touchesCancelled: (() -> Void)?
    open var touchesEnded: (() -> Void)?

    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesBegan?()
        super.touchesBegan(touches, with: event)
    }

    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded?()
        super.touchesEnded(touches, with: event)
    }

    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesCancelled?()
        super.touchesCancelled(touches, with: event)
    }
}

open class ImageCropToolbar: UIView {
    open var statusBarHeightInset: CGFloat = 0 {
        didSet { setNeedsLayout() }
    }

    open var buttonInsetPadding: CGFloat = 16.0 {
        didSet { setNeedsLayout() }
    }

    open var backgroundViewOutsets: UIEdgeInsets = .zero
    open var doneTextButtonTitle: String? {
        didSet {
            doneTextButton.setTitle(doneTextButtonTitle, for: .normal)
            doneTextButton.sizeToFit()
        }
    }

    open var cancelTextButtonTitle: String? {
        didSet {
            cancelTextButton.setTitle(cancelTextButtonTitle, for: .normal)
            cancelTextButton.sizeToFit()
        }
    }

    open var cancelButtonTapped: (() -> Void)?
    open var doneButtonTapped: (() -> Void)?
    open var rotateCounterClockwiseButtonTapped: (() -> Void)?
    open var rotateClockwiseButtonTapped: (() -> Void)?
    open var clampButtonTapped: (() -> Void)?
    open var resetButtonTapped: (() -> Void)?

    open var clampButtonGlowing = false {
        didSet {
            clampButton.tintColor = clampButtonGlowing ? nil : .white
        }
    }

    open var clampButtonFrame: CGRect {
        clampButton.frame
    }

    open var clampButtonHidden = false {
        didSet { setNeedsLayout() }
    }

    open var rotateCounterClockwiseButtonHidden = false {
        didSet { setNeedsLayout() }
    }

    open var rotateClockwiseButtonHidden = false {
        didSet { setNeedsLayout() }
    }

    open var resetButtonHidden = false {
        didSet { setNeedsLayout() }
    }

    open var doneButtonHidden = false {
        didSet { setNeedsLayout() }
    }

    open var cancelButtonHidden = false {
        didSet { setNeedsLayout() }
    }

    open var resetButtonEnabled: Bool {
        get { resetButton.isEnabled }
        set { resetButton.isEnabled = newValue }
    }

    open var doneButtonFrame: CGRect {
        if !doneIconButton.isHidden {
            return doneIconButton.frame
        }
        return doneTextButton.frame
    }

    open lazy var backgroundView: UIView = {
        let result = UIView(frame: bounds)
        result.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        return result
    }()

    open lazy var doneTextButton: UIButton = {
        let result = UIButton(type: .system)
        result.setTitle(doneTextButtonTitle ?? FrameworkBundle.doneButton, for: .normal)
        result.setTitleColor(.white, for: .normal)
        result.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        result.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        result.sizeToFit()
        return result
    }()

    open lazy var doneIconButton: UIButton = {
        let result = UIButton(type: .system)
        result.setImage(Self.doneImage(), for: .normal)
        result.tintColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
        result.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        return result
    }()

    open lazy var cancelTextButton: UIButton = {
        let result = UIButton(type: .system)
        result.setTitle(cancelTextButtonTitle ?? FrameworkBundle.cancelButton, for: .normal)
        result.setTitleColor(.white, for: .normal)
        result.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        result.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        result.sizeToFit()
        return result
    }()

    open lazy var cancelIconButton: UIButton = {
        let result = UIButton(type: .system)
        result.setImage(Self.cancelImage(), for: .normal)
        result.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        return result
    }()

    open var visibleCancelButton: UIButton {
        if !cancelIconButton.isHidden {
            return cancelIconButton
        }
        return cancelTextButton
    }

    open lazy var rotateCounterClockwiseButton: UIButton = {
        let result = UIButton(type: .system)
        result.contentMode = .center
        result.tintColor = .white
        result.setImage(Self.rotateCCWImage(), for: .normal)
        result.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        return result
    }()

    open lazy var resetButton: UIButton = {
        let result = UIButton(type: .system)
        result.contentMode = .center
        result.tintColor = .white
        result.isEnabled = false
        result.setImage(Self.resetImage(), for: .normal)
        result.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        return result
    }()

    open lazy var clampButton: UIButton = {
        let result = UIButton(type: .system)
        result.contentMode = .center
        result.tintColor = .white
        result.setImage(Self.clampImage(), for: .normal)
        result.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        return result
    }()

    open lazy var rotateClockwiseButton: UIButton = {
        let result = UIButton(type: .system)
        result.contentMode = .center
        result.tintColor = .white
        result.setImage(Self.rotateCWImage(), for: .normal)
        result.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        return result
    }()

    open var rotateButton: UIButton {
        rotateCounterClockwiseButton
    }

    private var reverseContentLayout: Bool = false

    override public init(frame: CGRect) {
        super.init(frame: frame)
        didInitialize()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        didInitialize()
    }

    private func didInitialize() {
        addSubview(backgroundView)
        reverseContentLayout = UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft
        addSubview(doneTextButton)
        addSubview(doneIconButton)
        addSubview(cancelTextButton)
        addSubview(cancelIconButton)
        addSubview(clampButton)
        addSubview(rotateCounterClockwiseButton)
        addSubview(rotateClockwiseButton)
        addSubview(resetButton)
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        let verticalLayout = bounds.width < bounds.height
        let boundsSize = bounds.size

        cancelIconButton.isHidden = cancelButtonHidden || !verticalLayout
        cancelTextButton.isHidden = cancelButtonHidden || verticalLayout
        doneIconButton.isHidden = doneButtonHidden || !verticalLayout
        doneTextButton.isHidden = doneButtonHidden || verticalLayout

        var frame = bounds
        frame.origin.x -= backgroundViewOutsets.left
        frame.size.width += backgroundViewOutsets.left
        frame.size.width += backgroundViewOutsets.right
        frame.origin.y -= backgroundViewOutsets.top
        frame.size.height += backgroundViewOutsets.top
        frame.size.height += backgroundViewOutsets.bottom
        backgroundView.frame = frame

        if !verticalLayout {
            let insetPadding = buttonInsetPadding

            var frame = CGRect.zero
            frame.origin.y = (bounds.height - 44.0) / 2.0
            frame.size.height = 44.0
            frame.size.width = min(self.frame.size.width / 3.0, cancelTextButton.frame.size.width)
            if !reverseContentLayout {
                frame.origin.x = insetPadding
            } else {
                frame.origin.x = boundsSize.width - (frame.size.width + insetPadding)
            }
            cancelTextButton.frame = frame

            frame.size.width = min(self.frame.size.width / 3.0, doneTextButton.frame.size.width)
            if !reverseContentLayout {
                frame.origin.x = boundsSize.width - (frame.size.width + insetPadding)
            } else {
                frame.origin.x = insetPadding
            }
            doneTextButton.frame = frame

            let x = reverseContentLayout ? doneTextButton.frame.maxX : cancelTextButton.frame.maxX
            var width: CGFloat = 0.0
            if !reverseContentLayout {
                width = doneTextButton.frame.minX - cancelTextButton.frame.maxX
            } else {
                width = cancelTextButton.frame.minX - doneTextButton.frame.maxX
            }

            let containerRect = CGRect(x: x, y: frame.origin.y, width: width, height: bounds.height - frame.origin.y).integral
            let buttonSize = CGSize(width: 44.0, height: 44.0)

            var buttons: [UIButton] = []
            if !rotateCounterClockwiseButtonHidden {
                buttons.append(rotateCounterClockwiseButton)
            }
            if !resetButtonHidden {
                buttons.append(resetButton)
            }
            if !clampButtonHidden {
                buttons.append(clampButton)
            }
            if !rotateClockwiseButtonHidden {
                buttons.append(rotateClockwiseButton)
            }
            layoutToolbarButtons(buttons, sameButtonSize: buttonSize, inContainerRect: containerRect, horizontally: true)
        } else {
            var frame = CGRect.zero
            frame.origin.x = (bounds.width - 44.0) / 2.0
            frame.size.height = 44.0
            frame.size.width = 44.0
            frame.origin.y = bounds.height - 44.0
            cancelIconButton.frame = frame

            frame.origin.y = statusBarHeightInset
            frame.size.width = 44.0
            frame.size.height = 44.0
            doneIconButton.frame = frame

            let containerRect = CGRect(x: frame.origin.x, y: doneIconButton.frame.maxY, width: bounds.width - frame.origin.x, height: cancelIconButton.frame.minY - doneIconButton.frame.maxY)
            let buttonSize = CGSize(width: 44.0, height: 44.0)

            var buttons = [UIButton]()
            if !rotateCounterClockwiseButtonHidden {
                buttons.append(rotateCounterClockwiseButton)
            }
            if !resetButtonHidden {
                buttons.append(resetButton)
            }
            if !clampButtonHidden {
                buttons.append(clampButton)
            }
            if !rotateClockwiseButtonHidden {
                buttons.append(rotateClockwiseButton)
            }
            layoutToolbarButtons(buttons, sameButtonSize: buttonSize, inContainerRect: containerRect, horizontally: false)
        }
    }

    private func layoutToolbarButtons(_ buttons: [UIButton], sameButtonSize size: CGSize, inContainerRect containerRect: CGRect, horizontally: Bool) {
        guard buttons.count > 0 else { return }

        let count = buttons.count
        let fixedSize = horizontally ? size.width : size.height
        let maxLength = horizontally ? containerRect.width : containerRect.height
        let padding = (maxLength - fixedSize * CGFloat(count)) / (CGFloat(count) + 1)

        for i in 0..<count {
            let button = buttons[i]
            let sameOffset = horizontally ? abs(containerRect.height - 44.0 - button.bounds.height) : abs(containerRect.width - button.bounds.width)
            let diffOffset = padding + CGFloat(i) * (fixedSize + padding)
            var origin = horizontally ? CGPoint(x: diffOffset, y: sameOffset) : CGPoint(x: sameOffset, y: diffOffset)
            if horizontally {
                origin.x += containerRect.minX
            } else {
                origin.y += containerRect.minY
            }
            button.frame = CGRect(origin: origin, size: size)
        }
    }

    @objc private func buttonTapped(_ button: UIButton) {
        if button == cancelTextButton || button == cancelIconButton {
            cancelButtonTapped?()
        } else if button == doneTextButton || button == doneIconButton {
            doneButtonTapped?()
        } else if button == resetButton {
            resetButtonTapped?()
        } else if button == rotateCounterClockwiseButton {
            rotateCounterClockwiseButtonTapped?()
        } else if button == rotateClockwiseButton {
            rotateClockwiseButtonTapped?()
        } else if button == clampButton {
            clampButtonTapped?()
        }
    }

    private static func doneImage() -> UIImage? {
        var doneImage: UIImage?
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 17, height: 14), false, 0.0)
        defer { UIGraphicsEndImageContext() }

        let rectanglePath = UIBezierPath()
        rectanglePath.move(to: CGPoint(x: 1, y: 7))
        rectanglePath.addLine(to: CGPoint(x: 6, y: 12))
        rectanglePath.addLine(to: CGPoint(x: 16, y: 1))
        UIColor.white.setStroke()
        rectanglePath.lineWidth = 2
        rectanglePath.stroke()

        doneImage = UIGraphicsGetImageFromCurrentImageContext()
        return doneImage
    }

    private static func cancelImage() -> UIImage? {
        var cancelImage: UIImage?
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 16, height: 16), false, 0.0)
        defer { UIGraphicsEndImageContext() }

        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 15, y: 15))
        bezierPath.addLine(to: CGPoint(x: 1, y: 1))
        UIColor.white.setStroke()
        bezierPath.lineWidth = 2
        bezierPath.stroke()

        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPoint(x: 1, y: 15))
        bezier2Path.addLine(to: CGPoint(x: 15, y: 1))
        UIColor.white.setStroke()
        bezier2Path.lineWidth = 2
        bezier2Path.stroke()

        cancelImage = UIGraphicsGetImageFromCurrentImageContext()
        return cancelImage
    }

    private static func rotateCCWImage() -> UIImage? {
        var rotateImage: UIImage?
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 18, height: 21), false, 0.0)
        defer { UIGraphicsEndImageContext() }

        let rectangle2Path = UIBezierPath(rect: CGRect(x: 0, y: 9, width: 12, height: 12))
        UIColor.white.setFill()
        rectangle2Path.fill()

        let rectangle3Path = UIBezierPath()
        rectangle3Path.move(to: CGPoint(x: 5, y: 3))
        rectangle3Path.addLine(to: CGPoint(x: 10, y: 6))
        rectangle3Path.addLine(to: CGPoint(x: 10, y: 0))
        rectangle3Path.addLine(to: CGPoint(x: 5, y: 3))
        rectangle3Path.close()
        UIColor.white.setFill()
        rectangle3Path.fill()

        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 10, y: 3))
        bezierPath.addCurve(to: CGPoint(x: 17.5, y: 11), controlPoint1: CGPoint(x: 15, y: 3), controlPoint2: CGPoint(x: 17.5, y: 5.91))
        UIColor.white.setStroke()
        bezierPath.lineWidth = 1
        bezierPath.stroke()

        rotateImage = UIGraphicsGetImageFromCurrentImageContext()
        return rotateImage
    }

    private static func rotateCWImage() -> UIImage? {
        guard let rotateCCWImage = rotateCCWImage() else {
            return nil
        }
        UIGraphicsBeginImageContextWithOptions(rotateCCWImage.size, false, rotateCCWImage.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }

        context.translateBy(x: rotateCCWImage.size.width, y: rotateCCWImage.size.height)
        context.rotate(by: CGFloat.pi)
        if let cgImage = rotateCCWImage.cgImage {
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: rotateCCWImage.size.width, height: rotateCCWImage.size.height))
        }
        let rotateCWImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rotateCWImage
    }

    private static func resetImage() -> UIImage? {
        var resetImage: UIImage?
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 22, height: 18), false, 0.0)
        defer { UIGraphicsEndImageContext() }

        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPoint(x: 22, y: 9))
        bezier2Path.addCurve(to: CGPoint(x: 13, y: 18), controlPoint1: CGPoint(x: 22, y: 13.97), controlPoint2: CGPoint(x: 17.97, y: 18))
        bezier2Path.addCurve(to: CGPoint(x: 13, y: 16), controlPoint1: CGPoint(x: 13, y: 17.35), controlPoint2: CGPoint(x: 13, y: 16.68))
        bezier2Path.addCurve(to: CGPoint(x: 20, y: 9), controlPoint1: CGPoint(x: 16.87, y: 16), controlPoint2: CGPoint(x: 20, y: 12.87))
        bezier2Path.addCurve(to: CGPoint(x: 13, y: 2), controlPoint1: CGPoint(x: 20, y: 5.13), controlPoint2: CGPoint(x: 16.87, y: 2))
        bezier2Path.addCurve(to: CGPoint(x: 6.55, y: 6.27), controlPoint1: CGPoint(x: 10.1, y: 2), controlPoint2: CGPoint(x: 7.62, y: 3.76))
        bezier2Path.addCurve(to: CGPoint(x: 6, y: 9), controlPoint1: CGPoint(x: 6.2, y: 7.11), controlPoint2: CGPoint(x: 6, y: 8.03))
        bezier2Path.addLine(to: CGPoint(x: 4, y: 9))
        bezier2Path.addCurve(to: CGPoint(x: 4.65, y: 5.63), controlPoint1: CGPoint(x: 4, y: 7.81), controlPoint2: CGPoint(x: 4.23, y: 6.67))
        bezier2Path.addCurve(to: CGPoint(x: 7.65, y: 1.76), controlPoint1: CGPoint(x: 5.28, y: 4.08), controlPoint2: CGPoint(x: 6.32, y: 2.74))
        bezier2Path.addCurve(to: CGPoint(x: 13, y: 0), controlPoint1: CGPoint(x: 9.15, y: 0.65), controlPoint2: CGPoint(x: 11, y: 0))
        bezier2Path.addCurve(to: CGPoint(x: 22, y: 9), controlPoint1: CGPoint(x: 17.97, y: 0), controlPoint2: CGPoint(x: 22, y: 4.03))
        bezier2Path.close()
        UIColor.white.setFill()
        bezier2Path.fill()

        let polygonPath = UIBezierPath()
        polygonPath.move(to: CGPoint(x: 5, y: 15))
        polygonPath.addLine(to: CGPoint(x: 10, y: 9))
        polygonPath.addLine(to: CGPoint(x: 0, y: 9))
        polygonPath.addLine(to: CGPoint(x: 5, y: 15))
        polygonPath.close()
        UIColor.white.setFill()
        polygonPath.fill()

        resetImage = UIGraphicsGetImageFromCurrentImageContext()
        return resetImage
    }

    private static func clampImage() -> UIImage? {
        var clampImage: UIImage?
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 22, height: 16), false, 0.0)
        defer { UIGraphicsEndImageContext() }

        let outerBox = UIColor(red: 1, green: 1, blue: 1, alpha: 0.553)
        let innerBox = UIColor(red: 1, green: 1, blue: 1, alpha: 0.773)

        let rectanglePath = UIBezierPath(rect: CGRect(x: 0, y: 3, width: 13, height: 13))
        UIColor.white.setFill()
        rectanglePath.fill()

        let topPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 22, height: 2))
        outerBox.setFill()
        topPath.fill()

        let sidePath = UIBezierPath(rect: CGRect(x: 19, y: 2, width: 3, height: 14))
        outerBox.setFill()
        sidePath.fill()

        let rectangle2Path = UIBezierPath(rect: CGRect(x: 14, y: 3, width: 4, height: 13))
        innerBox.setFill()
        rectangle2Path.fill()

        clampImage = UIGraphicsGetImageFromCurrentImageContext()
        return clampImage
    }
}

enum ImageCropViewOverlayEdge: Int {
    case none = 0
    case topLeft
    case top
    case topRight
    case right
    case bottomRight
    case bottom
    case bottomLeft
    case left
}

@MainActor public protocol ImageCropViewDelegate: AnyObject {
    func cropViewDidBecomeResettable(_ cropView: ImageCropView)
    func cropViewDidBecomeNonResettable(_ cropView: ImageCropView)
}

open class ImageCropView: UIView, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    open private(set) var image: UIImage
    open private(set) var croppingStyle: ImageCropCroppingStyle
    open weak var delegate: ImageCropViewDelegate?
    open var cropBoxResizeEnabled = true {
        didSet {
            gridPanGestureRecognizer.isEnabled = cropBoxResizeEnabled
        }
    }

    open private(set) var canBeReset = false {
        didSet {
            guard canBeReset != oldValue else { return }

            if canBeReset {
                delegate?.cropViewDidBecomeResettable(self)
            } else {
                delegate?.cropViewDidBecomeNonResettable(self)
            }
        }
    }

    open private(set) var cropBoxFrame: CGRect {
        get {
            _cropBoxFrame
        }
        set {
            if _cropBoxFrame == newValue { return }

            var cropBoxFrame = newValue
            let frameSize = cropBoxFrame.size
            if frameSize.width < CGFloat.ulpOfOne || frameSize.height < CGFloat.ulpOfOne { return }
            if frameSize.width.isNaN || frameSize.height.isNaN { return }

            let contentFrame = contentBounds
            let xOrigin = ceil(contentFrame.origin.x)
            let xDelta = cropBoxFrame.origin.x - xOrigin
            cropBoxFrame.origin.x = floor(max(cropBoxFrame.origin.x, xOrigin))
            if xDelta < -CGFloat.ulpOfOne {
                cropBoxFrame.size.width += xDelta
            }

            let yOrigin = ceil(contentFrame.origin.y)
            let yDelta = cropBoxFrame.origin.y - yOrigin
            cropBoxFrame.origin.y = floor(max(cropBoxFrame.origin.y, yOrigin))
            if yDelta < -CGFloat.ulpOfOne {
                cropBoxFrame.size.height += yDelta
            }

            let maxWidth = (contentFrame.size.width + contentFrame.origin.x) - cropBoxFrame.origin.x
            cropBoxFrame.size.width = floor(min(cropBoxFrame.size.width, maxWidth))

            let maxHeight = (contentFrame.size.height + contentFrame.origin.y) - cropBoxFrame.origin.y
            cropBoxFrame.size.height = floor(min(cropBoxFrame.size.height, maxHeight))

            cropBoxFrame.size.width = max(cropBoxFrame.size.width, Self.cropViewMinimumBoxSize)
            cropBoxFrame.size.height = max(cropBoxFrame.size.height, Self.cropViewMinimumBoxSize)

            _cropBoxFrame = cropBoxFrame

            foregroundContainerView.frame = _cropBoxFrame
            gridOverlayView.frame = _cropBoxFrame

            if circularMaskLayer != nil {
                let scale = _cropBoxFrame.size.width / Self.cropViewCircularPathRadius
                circularMaskLayer?.transform = CATransform3DScale(CATransform3DIdentity, scale, scale, 1.0)
            }

            scrollView.contentInset = UIEdgeInsets(top: _cropBoxFrame.minY, left: _cropBoxFrame.minX, bottom: bounds.maxY - _cropBoxFrame.maxY, right: bounds.maxX - _cropBoxFrame.maxX)

            let imageSize = backgroundContainerView.bounds.size
            let scale = max(cropBoxFrame.size.height / imageSize.height, cropBoxFrame.size.width / imageSize.width)
            scrollView.minimumZoomScale = scale

            var size = scrollView.contentSize
            size.width = floor(size.width)
            size.height = floor(size.height)
            scrollView.contentSize = size

            let zoomScale = scrollView.zoomScale
            scrollView.zoomScale = zoomScale

            matchForegroundToBackground()
        }
    }

    private var _cropBoxFrame: CGRect = .zero
    open var imageViewFrame: CGRect {
        var frame = CGRect.zero
        frame.origin.x = -scrollView.contentOffset.x
        frame.origin.y = -scrollView.contentOffset.y
        frame.size = scrollView.contentSize
        return frame
    }

    open var cropRegionInsets: UIEdgeInsets = .zero
    open var simpleRenderMode: Bool {
        get { _simpleRenderMode }
        set { setSimpleRenderMode(newValue, animated: false) }
    }

    private var _simpleRenderMode = false
    open var internalLayoutDisabled = false
    open var aspectRatio: CGSize {
        get { _aspectRatio }
        set { setAspectRatio(newValue, animated: false) }
    }

    private var _aspectRatio: CGSize = .zero
    open var aspectRatioLockEnabled = false
    open var aspectRatioLockDimensionSwapEnabled = false
    open var resetAspectRatioEnabled = true
    open var cropBoxAspectRatioIsPortrait: Bool {
        let cropFrame = cropBoxFrame
        return cropFrame.width < cropFrame.height
    }

    open var angle: Int {
        get {
            _angle
        }
        set {
            var newAngle = newValue
            if newValue % 90 != 0 {
                newAngle = 0
            }

            if !initialSetupPerformed {
                restoreAngle = newAngle
                return
            }

            if newAngle >= 0 {
                while abs(self.angle) != abs(newAngle) {
                    rotateImageNinetyDegreesAnimated(false, clockwise: true)
                }
            } else {
                while -abs(self.angle) != -abs(newAngle) {
                    rotateImageNinetyDegreesAnimated(false, clockwise: false)
                }
            }
        }
    }

    private var _angle: Int = 0
    open var croppingViewsHidden: Bool {
        get { _croppingViewsHidden }
        set { setCroppingViewsHidden(newValue, animated: false) }
    }

    private var _croppingViewsHidden = false
    open var imageCropFrame: CGRect {
        get {
            let imageSize = imageSize
            let contentSize = scrollView.contentSize
            let cropBoxFrame = cropBoxFrame
            let contentOffset = scrollView.contentOffset
            let edgeInsets = scrollView.contentInset
            let scaleWidth = imageSize.width / contentSize.width
            let scaleHeight = imageSize.height / contentSize.height
            let isSquare = floor(cropBoxFrame.size.width) == floor(cropBoxFrame.size.height)

            var frame = CGRect.zero
            frame.origin.x = floor((floor(contentOffset.x) + edgeInsets.left) * (imageSize.width / contentSize.width))
            frame.origin.x = max(0, frame.origin.x)
            frame.origin.y = floor((floor(contentOffset.y) + edgeInsets.top) * (imageSize.height / contentSize.height))
            frame.origin.y = max(0, frame.origin.y)
            frame.size.width = ceil(cropBoxFrame.size.width * (isSquare ? min(scaleWidth, scaleHeight) : scaleWidth))
            frame.size.width = min(imageSize.width, frame.size.width)
            frame.size.height = isSquare ? frame.size.width : ceil(cropBoxFrame.size.height * scaleHeight)
            frame.size.height = min(imageSize.height, frame.size.height)
            return frame
        }
        set {
            if !initialSetupPerformed {
                restoreImageCropFrame = newValue
                return
            }

            updateToImageCropFrame(newValue)
        }
    }

    open var gridOverlayHidden: Bool {
        get { _gridOverlayHidden }
        set { setGridOverlayHidden(newValue, animated: false) }
    }

    private var _gridOverlayHidden = false
    open var cropViewPadding: CGFloat = 14.0
    open var cropAdjustingDelay: TimeInterval = 0.8
    open var minimumAspectRatio: CGFloat = 0
    open var maximumZoomScale: CGFloat = 15.0
    open var alwaysShowCroppingGrid = false {
        didSet {
            if alwaysShowCroppingGrid != oldValue {
                gridOverlayView.setGridHidden(!alwaysShowCroppingGrid, animated: true)
            }
        }
    }

    open var translucencyAlwaysHidden = false {
        didSet {
            translucencyView.isHidden = translucencyAlwaysHidden
        }
    }

    open lazy var gridOverlayView: ImageCropOverlayView = {
        let result = ImageCropOverlayView(frame: foregroundContainerView.frame)
        result.isUserInteractionEnabled = false
        result.gridHidden = true
        return result
    }()

    open lazy var foregroundContainerView: UIView = {
        let result = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        result.clipsToBounds = true
        result.isUserInteractionEnabled = false
        return result
    }()

    private lazy var foregroundImageView: UIImageView = {
        let result = UIImageView(image: self.image)
        result.layer.minificationFilter = .trilinear
        result.accessibilityIgnoresInvertColors = true
        return result
    }()

    private lazy var backgroundImageView: UIImageView = {
        let result = UIImageView(image: self.image)
        result.layer.minificationFilter = .trilinear
        result.accessibilityIgnoresInvertColors = true
        return result
    }()

    private lazy var backgroundContainerView: UIView = {
        let result = UIView(frame: backgroundImageView.frame)
        return result
    }()

    private lazy var scrollView: ImageCropScrollView = {
        let result = ImageCropScrollView(frame: bounds)
        result.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        result.alwaysBounceHorizontal = true
        result.alwaysBounceVertical = true
        result.showsHorizontalScrollIndicator = false
        result.showsVerticalScrollIndicator = false
        result.delegate = self
        result.contentInsetAdjustmentBehavior = .never
        result.touchesBegan = { [weak self] in
            self?.startEditing()
        }
        result.touchesEnded = { [weak self] in
            self?.startResetTimer()
        }
        return result
    }()

    private lazy var overlayView: UIView = {
        let result = UIView(frame: self.bounds)
        result.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        result.backgroundColor = backgroundColor?.withAlphaComponent(0.35)
        result.isHidden = false
        result.isUserInteractionEnabled = false
        return result
    }()

    private lazy var translucencyView: UIVisualEffectView = {
        let result = UIVisualEffectView(effect: translucencyEffect)
        result.frame = self.bounds
        result.isHidden = translucencyAlwaysHidden
        result.isUserInteractionEnabled = false
        result.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return result
    }()

    private lazy var translucencyEffect: UIBlurEffect = {
        let result = UIBlurEffect(style: .dark)
        return result
    }()

    private lazy var gridPanGestureRecognizer: UIPanGestureRecognizer = {
        let result = UIPanGestureRecognizer(target: self, action: #selector(gridPanGestureRecognized(_:)))
        result.delegate = self
        return result
    }()

    private var circularMaskLayer: CAShapeLayer?
    private var applyInitialCroppedImageFrame = false
    private var tappedEdge: ImageCropViewOverlayEdge = .none
    private var cropOriginFrame: CGRect = .zero
    private var panOriginPoint: CGPoint = .zero
    private var resetTimer: Timer?
    private var editing: Bool {
        get { _editing }
        set { setEditing(newValue, resetCropBox: false, animated: false) }
    }

    private var _editing = false
    private var disableForegroundMatching = false
    private var rotationContentOffset: CGPoint = .zero
    private var rotationContentSize: CGSize = .zero
    private var rotationBoundFrame: CGRect = .zero
    private var contentBounds: CGRect {
        var contentRect = CGRect.zero
        contentRect.origin.x = cropViewPadding + cropRegionInsets.left
        contentRect.origin.y = cropViewPadding + cropRegionInsets.top
        contentRect.size.width = bounds.width - ((cropViewPadding * 2) + cropRegionInsets.left + cropRegionInsets.right)
        contentRect.size.height = bounds.height - ((cropViewPadding * 2) + cropRegionInsets.top + cropRegionInsets.bottom)
        return contentRect
    }

    private var imageSize: CGSize {
        if angle == -90 || angle == -270 || angle == 90 || angle == 270 {
            return CGSize(width: image.size.height, height: image.size.width)
        }
        return CGSize(width: image.size.width, height: image.size.height)
    }

    private var hasAspectRatio: Bool {
        aspectRatio.width > .ulpOfOne && aspectRatio.height > .ulpOfOne
    }

    private var cropBoxLastEditedSize: CGSize = .zero
    private var cropBoxLastEditedAngle: Int = 0
    private var cropBoxLastEditedZoomScale: CGFloat = 0
    private var cropBoxLastEditedMinZoomScale: CGFloat = 0
    private var rotateAnimationInProgress = false
    private var originalCropBoxSize: CGSize = .zero
    private var originalContentOffset: CGPoint = .zero
    private var restoreAngle: Int = 0
    private var restoreImageCropFrame: CGRect = .zero
    private var initialSetupPerformed = false

    private static var cropViewMinimumBoxSize: CGFloat = 42.0
    private static var cropViewCircularPathRadius: CGFloat = 300.0

    public convenience init(image: UIImage) {
        self.init(croppingStyle: .default, image: image)
    }

    public init(croppingStyle: ImageCropCroppingStyle, image: UIImage) {
        self.image = image
        self.croppingStyle = croppingStyle
        super.init(frame: .zero)
        didInitialize()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func didInitialize() {
        let circularMode = (croppingStyle == .circular)
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        cropBoxResizeEnabled = !circularMode
        aspectRatio = circularMode ? CGSize(width: 1.0, height: 1.0) : .zero
        resetAspectRatioEnabled = !circularMode

        addSubview(scrollView)
        backgroundContainerView.addSubview(backgroundImageView)
        scrollView.addSubview(backgroundContainerView)
        addSubview(overlayView)
        addSubview(translucencyView)
        addSubview(foregroundContainerView)
        foregroundContainerView.addSubview(foregroundImageView)

        if circularMode {
            let circlePath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: Self.cropViewCircularPathRadius, height: Self.cropViewCircularPathRadius))
            circularMaskLayer = CAShapeLayer()
            circularMaskLayer?.path = circlePath.cgPath
            foregroundContainerView.layer.mask = circularMaskLayer
            return
        }

        addSubview(gridOverlayView)
        scrollView.panGestureRecognizer.require(toFail: gridPanGestureRecognizer)
        addGestureRecognizer(gridPanGestureRecognizer)
    }

    open func performInitialSetup() {
        guard !initialSetupPerformed else { return }
        initialSetupPerformed = true

        layoutInitialImage()
        if restoreAngle != 0 {
            angle = restoreAngle
            restoreAngle = 0
            cropBoxLastEditedAngle = angle
        }

        if !CGRectIsEmpty(restoreImageCropFrame) {
            imageCropFrame = restoreImageCropFrame
            restoreImageCropFrame = .zero
        }

        captureStateForImageRotation()
        checkForCanReset()
    }

    open func setSimpleRenderMode(_ simpleMode: Bool, animated: Bool) {
        if simpleMode == _simpleRenderMode { return }
        _simpleRenderMode = simpleMode

        editing = false
        if !animated {
            toggleTranslucencyViewVisible(!simpleMode)
            return
        }

        UIView.animate(withDuration: 0.25) {
            self.toggleTranslucencyViewVisible(!simpleMode)
        }
    }

    open func prepareForRotation() {
        rotationContentOffset = scrollView.contentOffset
        rotationContentSize = scrollView.contentSize
        rotationBoundFrame = contentBounds
    }

    open func performRelayoutForRotation() {
        var cropFrame = cropBoxFrame
        let contentFrame = contentBounds

        let scale = min(contentFrame.size.width / cropFrame.size.width, contentFrame.size.height / cropFrame.size.height)
        scrollView.minimumZoomScale *= scale
        scrollView.zoomScale *= scale

        cropFrame.size.width = floor(cropFrame.size.width * scale)
        cropFrame.size.height = floor(cropFrame.size.height * scale)
        cropFrame.origin.x = floor(contentFrame.origin.x + ((contentFrame.size.width - cropFrame.size.width) * 0.5))
        cropFrame.origin.y = floor(contentFrame.origin.y + ((contentFrame.size.height - cropFrame.size.height) * 0.5))
        cropBoxFrame = cropFrame

        captureStateForImageRotation()

        let oldMidPoint = CGPoint(x: rotationBoundFrame.midX, y: rotationBoundFrame.midY)
        let contentCenter = CGPoint(x: rotationContentOffset.x + oldMidPoint.x, y: rotationContentOffset.y + oldMidPoint.y)

        var normalizedCenter = CGPoint.zero
        normalizedCenter.x = contentCenter.x / rotationContentSize.width
        normalizedCenter.y = contentCenter.y / rotationContentSize.height
        let newMidPoint = CGPoint(x: contentBounds.midX, y: contentBounds.midY)

        var translatedContentOffset = CGPoint.zero
        translatedContentOffset.x = scrollView.contentSize.width * normalizedCenter.x
        translatedContentOffset.y = scrollView.contentSize.height * normalizedCenter.y

        var offset = CGPoint.zero
        offset.x = floor(translatedContentOffset.x - newMidPoint.x)
        offset.y = floor(translatedContentOffset.y - newMidPoint.y)
        offset.x = max(-scrollView.contentInset.left, offset.x)
        offset.y = max(-scrollView.contentInset.top, offset.y)

        var maximumOffset = CGPoint.zero
        maximumOffset.x = (bounds.size.width - scrollView.contentInset.right) + scrollView.contentSize.width
        maximumOffset.y = (bounds.size.height - scrollView.contentInset.bottom) + scrollView.contentSize.height
        offset.x = min(offset.x, maximumOffset.x)
        offset.y = min(offset.y, maximumOffset.y)
        scrollView.contentOffset = offset

        matchForegroundToBackground()
    }

    open func resetLayoutToDefaultAnimated(_ animated: Bool) {
        if hasAspectRatio && resetAspectRatioEnabled {
            _aspectRatio = CGSize.zero
        }

        if !animated || angle != 0 {
            _angle = 0

            scrollView.zoomScale = 1.0
            let imageRect = CGRect(origin: .zero, size: image.size)

            backgroundImageView.transform = CGAffineTransform.identity
            backgroundContainerView.transform = CGAffineTransform.identity
            backgroundImageView.frame = imageRect
            backgroundContainerView.frame = imageRect

            foregroundImageView.transform = CGAffineTransform.identity
            foregroundImageView.frame = imageRect

            layoutInitialImage()
            checkForCanReset()
            return
        }

        if resetTimer != nil {
            cancelResetTimer()
            setEditing(false, resetCropBox: false, animated: false)
        }

        setSimpleRenderMode(true, animated: false)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .beginFromCurrentState, animations: {
                self.layoutInitialImage()
            }) { _ in
                self.setSimpleRenderMode(false, animated: true)
            }
        }
    }

    open func setAspectRatio(_ aspectRatio: CGSize, animated: Bool) {
        var aspectRatio = aspectRatio
        _aspectRatio = aspectRatio
        if !initialSetupPerformed { return }

        if aspectRatio.width < CGFloat.ulpOfOne && aspectRatio.height < CGFloat.ulpOfOne {
            aspectRatio = CGSize(width: imageSize.width, height: imageSize.height)
        }

        let boundsFrame = contentBounds
        var cropBoxFrame = cropBoxFrame
        var offset = scrollView.contentOffset

        var cropBoxIsPortrait = false
        if Int(aspectRatio.width) == 1 && Int(aspectRatio.height) == 1 {
            cropBoxIsPortrait = image.size.width > image.size.height
        } else {
            cropBoxIsPortrait = aspectRatio.width < aspectRatio.height
        }

        var zoomOut = false
        if cropBoxIsPortrait {
            let newWidth = floor(cropBoxFrame.size.height * (aspectRatio.width / aspectRatio.height))
            var delta = cropBoxFrame.size.width - newWidth
            cropBoxFrame.size.width = newWidth
            offset.x += (delta * 0.5)

            if delta < .ulpOfOne {
                cropBoxFrame.origin.x = contentBounds.origin.x
            }

            let boundsWidth = boundsFrame.width
            if newWidth > boundsWidth {
                let scale = boundsWidth / newWidth
                let newHeight = cropBoxFrame.size.height * scale
                delta = cropBoxFrame.size.height - newHeight
                cropBoxFrame.size.height = newHeight

                offset.y += (delta * 0.5)
                cropBoxFrame.size.width = boundsWidth
                zoomOut = true
            }
        } else {
            let newHeight = floor(cropBoxFrame.size.width * (aspectRatio.height / aspectRatio.width))
            var delta = cropBoxFrame.size.height - newHeight
            cropBoxFrame.size.height = newHeight
            offset.y += (delta * 0.5)

            if delta < .ulpOfOne {
                cropBoxFrame.origin.y = contentBounds.origin.y
            }

            let boundsHeight = boundsFrame.height
            if newHeight > boundsHeight {
                let scale = boundsHeight / newHeight
                let newWidth = cropBoxFrame.size.width * scale
                delta = cropBoxFrame.size.width - newWidth
                cropBoxFrame.size.width = newWidth

                offset.x += (delta * 0.5)
                cropBoxFrame.size.height = boundsHeight
                zoomOut = true
            }
        }

        cropBoxLastEditedSize = cropBoxFrame.size
        cropBoxLastEditedAngle = angle

        let translateBlock: () -> Void = {
            self.scrollView.contentOffset = offset
            self.cropBoxFrame = cropBoxFrame

            if zoomOut {
                self.scrollView.zoomScale = self.scrollView.minimumZoomScale
            }

            self.moveCroppedContentToCenterAnimated(false)
            self.checkForCanReset()
        }

        if !animated {
            translateBlock()
            return
        }

        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.7, options: .beginFromCurrentState, animations: translateBlock, completion: nil)
    }

    open func rotateImageNinetyDegreesAnimated(_ animated: Bool) {
        rotateImageNinetyDegreesAnimated(animated, clockwise: false)
    }

    open func rotateImageNinetyDegreesAnimated(_ animated: Bool, clockwise: Bool) {
        if rotateAnimationInProgress { return }

        if resetTimer != nil {
            cancelResetTimer()
            setEditing(false, resetCropBox: true, animated: false)

            cropBoxLastEditedAngle = angle
            captureStateForImageRotation()
        }

        var newAngle = angle
        newAngle = clockwise ? newAngle + 90 : newAngle - 90
        if newAngle <= -360 || newAngle >= 360 {
            newAngle = 0
        }
        _angle = newAngle

        var angleInRadians: CGFloat = 0.0
        switch newAngle {
        case 90:
            angleInRadians = CGFloat.pi / 2
        case -90:
            angleInRadians = -CGFloat.pi / 2
        case 180:
            angleInRadians = CGFloat.pi
        case -180:
            angleInRadians = -CGFloat.pi
        case 270:
            angleInRadians = CGFloat.pi + CGFloat.pi / 2
        case -270:
            angleInRadians = -(CGFloat.pi + CGFloat.pi / 2)
        default:
            break
        }

        let rotation = CGAffineTransformRotate(.identity, angleInRadians)
        let contentBounds = contentBounds
        let cropBoxFrame = cropBoxFrame
        let scale = min(contentBounds.size.width / cropBoxFrame.size.height, contentBounds.size.height / cropBoxFrame.size.width)

        let cropMidPoint = CGPoint(x: cropBoxFrame.midX, y: cropBoxFrame.midY)
        var cropTargetPoint = CGPoint(x: cropMidPoint.x + scrollView.contentOffset.x, y: cropMidPoint.y + scrollView.contentOffset.y)

        var newCropFrame = CGRect.zero
        if abs(angle) == abs(cropBoxLastEditedAngle) || (abs(angle) * -1) == ((abs(cropBoxLastEditedAngle) - 180) % 360) {
            newCropFrame.size = cropBoxLastEditedSize

            scrollView.minimumZoomScale = cropBoxLastEditedMinZoomScale
            scrollView.zoomScale = cropBoxLastEditedZoomScale
        } else {
            newCropFrame.size = CGSize(width: floor(self.cropBoxFrame.size.height * scale), height: floor(self.cropBoxFrame.size.width * scale))

            scrollView.minimumZoomScale *= scale
            scrollView.zoomScale *= scale
        }

        newCropFrame.origin.x = floor(contentBounds.midX - (newCropFrame.size.width * 0.5))
        newCropFrame.origin.y = floor(contentBounds.midY - (newCropFrame.size.height * 0.5))

        var snapshotView: UIView?
        if animated {
            snapshotView = foregroundContainerView.snapshotView(afterScreenUpdates: false)
            rotateAnimationInProgress = true
        }

        backgroundImageView.transform = rotation

        let containerSize = backgroundContainerView.frame.size
        backgroundContainerView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: containerSize.height, height: containerSize.width))
        backgroundImageView.frame = CGRect(origin: CGPoint.zero, size: backgroundImageView.frame.size)

        foregroundContainerView.transform = .identity
        foregroundImageView.transform = rotation

        scrollView.contentSize = backgroundContainerView.frame.size

        self.cropBoxFrame = newCropFrame
        moveCroppedContentToCenterAnimated(false)
        newCropFrame = self.cropBoxFrame

        cropTargetPoint.x *= scale
        cropTargetPoint.y *= scale

        let swap = cropTargetPoint.x
        if clockwise {
            cropTargetPoint.x = scrollView.contentSize.width - cropTargetPoint.y
            cropTargetPoint.y = swap
        } else {
            cropTargetPoint.x = cropTargetPoint.y
            cropTargetPoint.y = scrollView.contentSize.height - swap
        }

        let midPoint = CGPoint(x: newCropFrame.midX, y: newCropFrame.midY)
        var offset = CGPoint.zero
        offset.x = floor(-midPoint.x + cropTargetPoint.x)
        offset.y = floor(-midPoint.y + cropTargetPoint.y)
        offset.x = max(-scrollView.contentInset.left, offset.x)
        offset.y = max(-scrollView.contentInset.top, offset.y)
        offset.x = min(scrollView.contentSize.width - (newCropFrame.size.width - scrollView.contentInset.right), offset.x)
        offset.y = min(scrollView.contentSize.height - (newCropFrame.size.height - scrollView.contentInset.bottom), offset.y)

        if offset.x == scrollView.contentOffset.x && offset.y == scrollView.contentOffset.y && scale == 1 {
            matchForegroundToBackground()
        }
        scrollView.contentOffset = offset

        if animated {
            snapshotView?.center = CGPoint(x: contentBounds.midX, y: contentBounds.midY)
            if let snapshotView {
                addSubview(snapshotView)
            }

            backgroundContainerView.isHidden = true
            foregroundContainerView.isHidden = true
            translucencyView.isHidden = true
            gridOverlayView.isHidden = true

            UIView.animate(withDuration: 0.45, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.8, options: .beginFromCurrentState, animations: {
                let transform = CGAffineTransform(rotationAngle: clockwise ? CGFloat.pi / 2 : -CGFloat.pi / 2).scaledBy(x: scale, y: scale)
                snapshotView?.transform = transform
            }, completion: { _ in
                self.backgroundContainerView.isHidden = false
                self.foregroundContainerView.isHidden = false
                self.translucencyView.isHidden = self.translucencyAlwaysHidden
                self.gridOverlayView.isHidden = false

                self.backgroundContainerView.alpha = 0.0
                self.gridOverlayView.alpha = 0.0
                self.translucencyView.alpha = 1.0

                UIView.animate(withDuration: 0.45, animations: {
                    snapshotView?.alpha = 0.0
                    self.backgroundContainerView.alpha = 1.0
                    self.gridOverlayView.alpha = 1.0
                }, completion: { _ in
                    self.rotateAnimationInProgress = false
                    snapshotView?.removeFromSuperview()

                    let aspectRatioCanSwapDimensions = !self.aspectRatioLockEnabled ||
                        (self.aspectRatioLockEnabled && self.aspectRatioLockDimensionSwapEnabled)
                    if !aspectRatioCanSwapDimensions {
                        self.setAspectRatio(self.aspectRatio, animated: animated)
                    }
                })
            })
        }

        checkForCanReset()
    }

    open func setGridOverlayHidden(_ gridOverlayHidden: Bool, animated: Bool) {
        _gridOverlayHidden = gridOverlayHidden

        gridOverlayView.alpha = gridOverlayHidden ? 1.0 : 0.0
        UIView.animate(withDuration: 0.4) {
            self.gridOverlayView.alpha = gridOverlayHidden ? 0.0 : 1.0
        }
    }

    open func setCroppingViewsHidden(_ hidden: Bool, animated: Bool) {
        if _croppingViewsHidden == hidden { return }
        _croppingViewsHidden = hidden

        let alpha: CGFloat = hidden ? 0.0 : 1.0
        if !animated {
            backgroundImageView.alpha = alpha
            foregroundContainerView.alpha = alpha
            gridOverlayView.alpha = alpha
            toggleTranslucencyViewVisible(!hidden)
            return
        }

        foregroundContainerView.alpha = alpha
        backgroundImageView.alpha = alpha
        UIView.animate(withDuration: 0.4) {
            self.toggleTranslucencyViewVisible(!hidden)
            self.gridOverlayView.alpha = alpha
        }
    }

    open func setBackgroundImageViewHidden(_ hidden: Bool, animated: Bool) {
        if !animated {
            backgroundImageView.isHidden = hidden
            return
        }

        let beforeAlpha: CGFloat = hidden ? 1.0 : 0.0
        let toAlpha: CGFloat = hidden ? 0.0 : 1.0
        backgroundImageView.isHidden = false
        backgroundImageView.alpha = beforeAlpha
        UIView.animate(withDuration: 0.5) {
            self.backgroundImageView.alpha = toAlpha
        } completion: { _ in
            if hidden {
                self.backgroundImageView.isHidden = true
            }
        }
    }

    open func moveCroppedContentToCenterAnimated(_ animated: Bool) {
        if internalLayoutDisabled { return }

        let contentRect = contentBounds
        var cropFrame = cropBoxFrame
        if cropFrame.size.width < .ulpOfOne || cropFrame.size.height < .ulpOfOne {
            return
        }

        let scale = min(contentRect.width / cropFrame.width, contentRect.height / cropFrame.height)
        let focusPoint = CGPoint(x: cropFrame.midX, y: cropFrame.midY)
        let midPoint = CGPoint(x: contentRect.midX, y: contentRect.midY)

        cropFrame.size.width = ceil(cropFrame.size.width * scale)
        cropFrame.size.height = ceil(cropFrame.size.height * scale)
        cropFrame.origin.x = contentRect.origin.x + ceil((contentRect.size.width - cropFrame.size.width) * 0.5)
        cropFrame.origin.y = contentRect.origin.y + ceil((contentRect.size.height - cropFrame.size.height) * 0.5)

        var contentTargetPoint = CGPoint.zero
        contentTargetPoint.x = ((focusPoint.x + scrollView.contentOffset.x) * scale)
        contentTargetPoint.y = ((focusPoint.y + scrollView.contentOffset.y) * scale)

        var offset = CGPoint.zero
        offset.x = -midPoint.x + contentTargetPoint.x
        offset.y = -midPoint.y + contentTargetPoint.y
        offset.x = max(-cropFrame.origin.x, offset.x)
        offset.y = max(-cropFrame.origin.y, offset.y)

        let translateBlock: () -> Void = {
            self.disableForegroundMatching = true

            if scale < 1.0 - .ulpOfOne || scale > 1.0 + .ulpOfOne {
                self.scrollView.zoomScale *= scale
                self.scrollView.zoomScale = min(self.scrollView.maximumZoomScale, self.scrollView.zoomScale)
            }

            if self.scrollView.zoomScale < self.scrollView.maximumZoomScale - .ulpOfOne {
                offset.x = min(-cropFrame.maxX + self.scrollView.contentSize.width, offset.x)
                offset.y = min(-cropFrame.maxY + self.scrollView.contentSize.height, offset.y)
                self.scrollView.contentOffset = offset
            }

            self.cropBoxFrame = cropFrame

            self.disableForegroundMatching = false
            self.matchForegroundToBackground()
        }

        if !animated {
            translateBlock()
            return
        }

        matchForegroundToBackground()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .beginFromCurrentState, animations: translateBlock, completion: nil)
        }
    }

    // MARK: - UIGestureRecognizerDelegate
    @objc private func gridPanGestureRecognized(_ recognizer: UIPanGestureRecognizer) {
        let point = recognizer.location(in: self)

        if recognizer.state == .began {
            startEditing()
            panOriginPoint = point
            cropOriginFrame = cropBoxFrame
            tappedEdge = cropEdge(for: panOriginPoint)
        }

        if recognizer.state == .ended {
            startResetTimer()
        }

        updateCropBoxFrame(gesturePoint: point)
    }

    @objc private func longPressGestureRecognized(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            gridOverlayView.setGridHidden(false, animated: true)
        }

        if recognizer.state == .ended {
            gridOverlayView.setGridHidden(true, animated: true)
        }
    }

    override open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer != gridPanGestureRecognizer { return true }

        let tapPoint = gestureRecognizer.location(in: self)
        let frame = gridOverlayView.frame
        let innerFrame = CGRectInset(frame, 22.0, 22.0)
        let outerFrame = CGRectInset(frame, -22.0, -22.0)
        if innerFrame.contains(tapPoint) || !outerFrame.contains(tapPoint) {
            return false
        }
        return true
    }

    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gridPanGestureRecognizer.state == .changed {
            return false
        }
        return true
    }

    // MARK: - ScrollViewDelegate
    open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        backgroundContainerView
    }

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        matchForegroundToBackground()
    }

    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        startEditing()
        canBeReset = true
    }

    open func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        startEditing()
        canBeReset = true
    }

    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        startResetTimer()
        checkForCanReset()
    }

    open func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        startResetTimer()
        checkForCanReset()
    }

    open func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView.isTracking {
            cropBoxLastEditedZoomScale = scrollView.zoomScale
            cropBoxLastEditedMinZoomScale = scrollView.minimumZoomScale
        }

        matchForegroundToBackground()
    }

    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            startResetTimer()
        }
    }

    // MARK: - Private
    private func layoutInitialImage() {
        let imageSize = imageSize
        scrollView.contentSize = imageSize

        let bounds = contentBounds
        let boundsSize = bounds.size
        var scale: CGFloat = 0.0
        scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let scaledImageSize = CGSize(width: floor(imageSize.width * scale), height: floor(imageSize.height * scale))

        var cropBoxSize = CGSize.zero
        if hasAspectRatio {
            let ratioScale = aspectRatio.width / aspectRatio.height
            let fullSizeRatio = CGSize(width: boundsSize.height * ratioScale, height: boundsSize.height)
            let fitScale = min(boundsSize.width / fullSizeRatio.width, boundsSize.height / fullSizeRatio.height)
            cropBoxSize = CGSize(width: fullSizeRatio.width * fitScale, height: fullSizeRatio.height * fitScale)
            scale = max(cropBoxSize.width / imageSize.width, cropBoxSize.height / imageSize.height)
        }

        let scaledSize = CGSize(width: floor(imageSize.width * scale), height: floor(imageSize.height * scale))
        scrollView.minimumZoomScale = scale
        scrollView.maximumZoomScale = scale * maximumZoomScale

        var frame = CGRect.zero
        frame.size = hasAspectRatio ? cropBoxSize : scaledSize
        frame.origin.x = bounds.origin.x + floor((bounds.width - frame.size.width) * 0.5)
        frame.origin.y = bounds.origin.y + floor((bounds.height - frame.size.height) * 0.5)
        cropBoxFrame = frame

        scrollView.zoomScale = scrollView.minimumZoomScale
        scrollView.contentSize = scaledSize
        if frame.size.width < scaledSize.width - .ulpOfOne || frame.size.height < scaledSize.height - .ulpOfOne {
            var offset = CGPoint.zero
            offset.x = -floor(bounds.midX - (scaledSize.width * 0.5))
            offset.y = -floor(bounds.midY - (scaledSize.height * 0.5))
            scrollView.contentOffset = offset
        }

        cropBoxLastEditedAngle = 0
        captureStateForImageRotation()
        originalCropBoxSize = resetAspectRatioEnabled ? scaledImageSize : cropBoxFrame.size
        originalContentOffset = scrollView.contentOffset
        checkForCanReset()
        matchForegroundToBackground()
    }

    private func matchForegroundToBackground() {
        if disableForegroundMatching { return }

        foregroundImageView.frame = backgroundContainerView.superview?.convert(backgroundContainerView.frame, to: foregroundContainerView) ?? .zero
    }

    private func updateCropBoxFrame(gesturePoint: CGPoint) {
        var frame = cropBoxFrame
        let originFrame = cropOriginFrame
        let contentFrame = contentBounds

        var point = gesturePoint
        point.x = max(contentFrame.origin.x - cropViewPadding, point.x)
        point.y = max(contentFrame.origin.y - cropViewPadding, point.y)
        var xDelta = ceil(point.x - panOriginPoint.x)
        var yDelta = ceil(point.y - panOriginPoint.y)

        let aspectRatio = (originFrame.size.width / originFrame.size.height)
        var aspectHorizontal = false
        var aspectVertical = false
        var clampMinFromTop = false
        var clampMinFromLeft = false

        switch tappedEdge {
        case .left:
            if aspectRatioLockEnabled {
                aspectHorizontal = true
                xDelta = max(xDelta, 0)
                let scaleOrigin = CGPoint(x: originFrame.maxX, y: originFrame.midY)
                frame.size.height = frame.size.width / aspectRatio
                frame.origin.y = scaleOrigin.y - (frame.size.height * 0.5)
            }
            let newWidth = originFrame.size.width - xDelta
            let newHeight = originFrame.size.height
            if min(newHeight, newWidth) / max(newHeight, newWidth) >= minimumAspectRatio {
                frame.origin.x = originFrame.origin.x + xDelta
                frame.size.width = originFrame.size.width - xDelta
            }

            clampMinFromLeft = true
        case .right:
            if aspectRatioLockEnabled {
                aspectHorizontal = true
                let scaleOrigin = CGPoint(x: originFrame.minX, y: originFrame.midY)
                frame.size.height = frame.size.width / aspectRatio
                frame.origin.y = scaleOrigin.y - (frame.size.height * 0.5)
                frame.size.width = originFrame.size.width + xDelta
                frame.size.width = min(frame.size.width, contentFrame.size.height * aspectRatio)
            } else {
                let newWidth = originFrame.size.width + xDelta
                let newHeight = originFrame.size.height
                if min(newHeight, newWidth) / max(newHeight, newWidth) >= minimumAspectRatio {
                    frame.size.width = originFrame.size.width + xDelta
                }
            }
        case .bottom:
            if aspectRatioLockEnabled {
                aspectVertical = true
                let scaleOrigin = CGPoint(x: originFrame.midX, y: originFrame.minY)
                frame.size.width = frame.size.height * aspectRatio
                frame.origin.x = scaleOrigin.x - (frame.size.width * 0.5)
                frame.size.height = originFrame.size.height + yDelta
                frame.size.height = min(frame.size.height, contentFrame.size.width / aspectRatio)
            } else {
                let newWidth = originFrame.size.width
                let newHeight = originFrame.size.height + yDelta

                if min(newHeight, newWidth) / max(newHeight, newWidth) >= minimumAspectRatio {
                    frame.size.height = originFrame.size.height + yDelta
                }
            }
        case .top:
            if aspectRatioLockEnabled {
                aspectVertical = true
                yDelta = max(0, yDelta)
                let scaleOrigin = CGPoint(x: originFrame.midX, y: originFrame.maxY)
                frame.size.width = frame.size.height * aspectRatio
                frame.origin.x = scaleOrigin.x - (frame.size.width * 0.5)
                frame.origin.y = originFrame.origin.y + yDelta
                frame.size.height = originFrame.size.height - yDelta
            } else {
                let newWidth = originFrame.size.width
                let newHeight = originFrame.size.height - yDelta

                if min(newHeight, newWidth) / max(newHeight, newWidth) >= minimumAspectRatio {
                    frame.origin.y = originFrame.origin.y + yDelta
                    frame.size.height = originFrame.size.height - yDelta
                }
            }

            clampMinFromTop = true
        case .topLeft:
            if aspectRatioLockEnabled {
                xDelta = max(xDelta, 0)
                yDelta = max(yDelta, 0)

                let distance = CGPoint(x: 1.0 - (xDelta / originFrame.width), y: 1.0 - (yDelta / originFrame.height))
                let scale = (distance.x + distance.y) * 0.5

                frame.size.width = ceil(originFrame.width * scale)
                frame.size.height = ceil(originFrame.height * scale)
                frame.origin.x = originFrame.origin.x + (originFrame.width - frame.size.width)
                frame.origin.y = originFrame.origin.y + (originFrame.height - frame.size.height)

                aspectVertical = true
                aspectHorizontal = true
            } else {
                let newWidth = originFrame.size.width - xDelta
                let newHeight = originFrame.size.height - yDelta

                if min(newHeight, newWidth) / max(newHeight, newWidth) >= minimumAspectRatio {
                    frame.origin.x = originFrame.origin.x + xDelta
                    frame.size.width = originFrame.size.width - xDelta
                    frame.origin.y = originFrame.origin.y + yDelta
                    frame.size.height = originFrame.size.height - yDelta
                }
            }

            clampMinFromTop = true
            clampMinFromLeft = true
        case .topRight:
            if aspectRatioLockEnabled {
                xDelta = min(xDelta, 0)
                yDelta = max(yDelta, 0)

                let distance = CGPoint(x: 1.0 - ((-xDelta) / originFrame.width), y: 1.0 - (yDelta / originFrame.height))
                let scale = (distance.x + distance.y) * 0.5

                frame.size.width = ceil(originFrame.width * scale)
                frame.size.height = ceil(originFrame.height * scale)
                frame.origin.y = originFrame.origin.y + (originFrame.height - frame.size.height)

                aspectVertical = true
                aspectHorizontal = true
            } else {
                let newWidth = originFrame.size.width + xDelta
                let newHeight = originFrame.size.height - yDelta

                if min(newHeight, newWidth) / max(newHeight, newWidth) >= minimumAspectRatio {
                    frame.size.width = originFrame.size.width + xDelta
                    frame.origin.y = originFrame.origin.y + yDelta
                    frame.size.height = originFrame.size.height - yDelta
                }
            }

            clampMinFromTop = true
        case .bottomLeft:
            if aspectRatioLockEnabled {
                let distance = CGPoint(x: 1.0 - (xDelta / originFrame.width), y: 1.0 - (-yDelta / originFrame.height))
                let scale = (distance.x + distance.y) * 0.5

                frame.size.width = ceil(originFrame.width * scale)
                frame.size.height = ceil(originFrame.height * scale)
                frame.origin.x = originFrame.maxX - frame.size.width

                aspectVertical = true
                aspectHorizontal = true
            } else {
                let newWidth = originFrame.size.width - xDelta
                let newHeight = originFrame.size.height + yDelta

                if min(newHeight, newWidth) / max(newHeight, newWidth) >= minimumAspectRatio {
                    frame.size.height = originFrame.size.height + yDelta
                    frame.origin.x = originFrame.origin.x + xDelta
                    frame.size.width = originFrame.size.width - xDelta
                }
            }

            clampMinFromLeft = true
        case .bottomRight:
            if aspectRatioLockEnabled {
                let distanceX = 1.0 - ((-1.0 * xDelta) / originFrame.width)
                let distanceY = 1.0 - ((-1.0 * yDelta) / originFrame.height)
                let scale = (distanceX + distanceY) * 0.5

                frame.size.width = ceil(originFrame.width * scale)
                frame.size.height = ceil(originFrame.height * scale)

                aspectVertical = true
                aspectHorizontal = true
            } else {
                let newWidth = originFrame.size.width + xDelta
                let newHeight = originFrame.size.height + yDelta

                if min(newHeight, newWidth) / max(newHeight, newWidth) >= minimumAspectRatio {
                    frame.size.height = originFrame.size.height + yDelta
                    frame.size.width = originFrame.size.width + xDelta
                }
            }
        default:
            break
        }

        var minSize = CGSize(width: Self.cropViewMinimumBoxSize, height: Self.cropViewMinimumBoxSize)
        var maxSize = CGSize(width: contentFrame.width, height: contentFrame.height)
        if aspectRatioLockEnabled && aspectHorizontal {
            maxSize.height = contentFrame.width / aspectRatio
            minSize.width = Self.cropViewMinimumBoxSize * aspectRatio
        }
        if aspectRatioLockEnabled && aspectVertical {
            maxSize.width = contentFrame.height * aspectRatio
            minSize.height = Self.cropViewMinimumBoxSize / aspectRatio
        }

        if clampMinFromLeft {
            let maxWidth = cropOriginFrame.maxX - contentFrame.origin.x
            frame.size.width = min(frame.size.width, maxWidth)
        }
        if clampMinFromTop {
            let maxHeight = cropOriginFrame.maxY - contentFrame.origin.y
            frame.size.height = min(frame.size.height, maxHeight)
        }

        frame.size.width = max(frame.size.width, minSize.width)
        frame.size.height = max(frame.size.height, minSize.height)
        frame.size.width = min(frame.size.width, maxSize.width)
        frame.size.height = min(frame.size.height, maxSize.height)

        frame.origin.x = max(frame.origin.x, contentFrame.minX)
        frame.origin.x = min(frame.origin.x, contentFrame.maxX - minSize.width)
        frame.origin.y = max(frame.origin.y, contentFrame.minY)
        frame.origin.y = min(frame.origin.y, contentFrame.maxY - minSize.height)

        if clampMinFromLeft && frame.size.width <= minSize.width + .ulpOfOne {
            frame.origin.x = originFrame.maxX - minSize.width
        }
        if clampMinFromTop && frame.size.height <= minSize.height + .ulpOfOne {
            frame.origin.y = originFrame.maxY - minSize.height
        }

        cropBoxFrame = frame
        checkForCanReset()
    }

    private func toggleTranslucencyViewVisible(_ visible: Bool) {
        translucencyView.effect = visible ? translucencyEffect : nil
    }

    private func updateToImageCropFrame(_ imageCropFrame: CGRect) {
        let minimumSize = scrollView.minimumZoomScale
        let scaledOffset = CGPoint(x: imageCropFrame.origin.x * minimumSize, y: imageCropFrame.origin.y * minimumSize)
        let scaledCropSize = CGSize(width: imageCropFrame.size.width * minimumSize, height: imageCropFrame.size.height * minimumSize)

        let bounds = contentBounds
        let scale = min(bounds.size.width / scaledCropSize.width, bounds.size.height / scaledCropSize.height)
        scrollView.zoomScale = scrollView.minimumZoomScale * scale

        var frame = CGRect.zero
        frame.size = CGSize(width: scaledCropSize.width * scale, height: scaledCropSize.height * scale)

        var cropBoxFrame = CGRect.zero
        cropBoxFrame.size = frame.size
        cropBoxFrame.origin.x = bounds.midX - (frame.size.width * 0.5)
        cropBoxFrame.origin.y = bounds.midY - (frame.size.height * 0.5)
        self.cropBoxFrame = cropBoxFrame

        frame.origin.x = (scaledOffset.x * scale) - scrollView.contentInset.left
        frame.origin.y = (scaledOffset.y * scale) - scrollView.contentInset.top
        scrollView.contentOffset = frame.origin
    }

    private func startResetTimer() {
        guard resetTimer == nil else { return }
        resetTimer = Timer.scheduledTimer(timeInterval: cropAdjustingDelay, target: self, selector: #selector(timerTriggered), userInfo: nil, repeats: false)
    }

    @objc private func timerTriggered() {
        setEditing(false, resetCropBox: true, animated: true)
        resetTimer?.invalidate()
        resetTimer = nil
    }

    private func cancelResetTimer() {
        resetTimer?.invalidate()
        resetTimer = nil
    }

    private func cropEdge(for point: CGPoint) -> ImageCropViewOverlayEdge {
        var frame = cropBoxFrame
        frame = frame.insetBy(dx: -32.0, dy: -32.0)

        let topLeftRect = CGRect(origin: frame.origin, size: CGSize(width: 64, height: 64))
        if topLeftRect.contains(point) {
            return .topLeft
        }

        var topRightRect = topLeftRect
        topRightRect.origin.x = frame.maxX - 64.0
        if topRightRect.contains(point) {
            return .topRight
        }

        var bottomLeftRect = topLeftRect
        bottomLeftRect.origin.y = frame.maxY - 64.0
        if bottomLeftRect.contains(point) {
            return .bottomLeft
        }

        var bottomRightRect = topRightRect
        bottomRightRect.origin.y = bottomLeftRect.origin.y
        if bottomRightRect.contains(point) {
            return .bottomRight
        }

        let topRect = CGRect(origin: frame.origin, size: CGSize(width: frame.width, height: 64.0))
        if topRect.contains(point) {
            return .top
        }

        var bottomRect = topRect
        bottomRect.origin.y = frame.maxY - 64.0
        if bottomRect.contains(point) {
            return .bottom
        }

        let leftRect = CGRect(origin: frame.origin, size: CGSize(width: 64.0, height: frame.height))
        if leftRect.contains(point) {
            return .left
        }

        var rightRect = leftRect
        rightRect.origin.x = frame.maxX - 64.0
        if rightRect.contains(point) {
            return .right
        }

        return .none
    }

    private func startEditing() {
        cancelResetTimer()
        setEditing(true, resetCropBox: false, animated: true)
    }

    private func setEditing(_ editing: Bool, resetCropBox: Bool, animated: Bool) {
        if editing == _editing { return }
        _editing = editing

        var hidden = !editing
        if alwaysShowCroppingGrid {
            hidden = false
        }
        gridOverlayView.setGridHidden(hidden, animated: animated)

        if resetCropBox {
            moveCroppedContentToCenterAnimated(animated)
            captureStateForImageRotation()
            cropBoxLastEditedAngle = angle
        }

        if !animated {
            toggleTranslucencyViewVisible(!editing)
            return
        }

        let duration: TimeInterval = editing ? 0.05 : 0.35
        var delay: TimeInterval = editing ? 0.0 : 0.35
        if croppingStyle == .circular {
            delay = 0.0
        }
        UIView.animateKeyframes(withDuration: duration, delay: delay) {
            self.toggleTranslucencyViewVisible(!editing)
        }
    }

    private func captureStateForImageRotation() {
        cropBoxLastEditedSize = cropBoxFrame.size
        cropBoxLastEditedZoomScale = scrollView.zoomScale
        cropBoxLastEditedMinZoomScale = scrollView.minimumZoomScale
    }

    private func checkForCanReset() {
        var canReset = false
        if angle != 0 {
            canReset = true
        } else if scrollView.zoomScale > scrollView.minimumZoomScale + .ulpOfOne {
            canReset = true
        } else if Int(floor(cropBoxFrame.size.width)) != Int(floor(originalCropBoxSize.width)) ||
            Int(floor(cropBoxFrame.size.height)) != Int(floor(originalCropBoxSize.height)) {
            canReset = true
        } else if Int(floor(scrollView.contentOffset.x)) != Int(floor(originalContentOffset.x)) ||
            Int(floor(scrollView.contentOffset.y)) != Int(floor(originalContentOffset.y)) {
            canReset = true
        }
        canBeReset = canReset
    }
}

// MARK: - FrameworkAutoloader+ImagePickerPlugin
extension FrameworkAutoloader {
    @objc static func loadPlugin_ImagePickerPlugin() {
        UIImagePickerController.cropControllerBlock = { image in
            let cropController = ImageCropController(image: image)
            cropController.aspectRatioPreset = .presetSquare
            cropController.aspectRatioLockEnabled = true
            cropController.resetAspectRatioEnabled = false
            cropController.aspectRatioPickerButtonHidden = true
            return cropController
        }
    }
}
