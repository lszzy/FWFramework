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
public enum ImageCropToolbarPosition: Int {
    case bottom
    case top
}

/// 裁剪控制器事件代理协议
@objc public protocol ImageCropControllerDelegate: NSObjectProtocol {
    @objc optional func cropController(_ cropController: ImageCropController, didCropImageToRect rect: CGRect, angle: Int)
    @objc optional func cropController(_ cropController: ImageCropController, didCropToImage image: UIImage, rect: CGRect, angle: Int)
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
    open var aspectRatioPreset: ImageCropAspectRatioPreset {
        get { return _aspectRatioPreset }
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
    open var onDidCropToImage: ((_ image: UIImage, _ cropRect: CGRect, _ angle: Int) -> Void)?
    open var onDidCropToCircularImage: ((_ image: UIImage, _ cropRect: CGRect, _ angle: Int) -> Void)?
    
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
        if size == self.view.bounds.size { return }
        
        var orientation: UIInterfaceOrientation = .portrait
        if self.view.bounds.width < size.width {
            orientation = .landscapeLeft
        }
        
        _willRotateToInterfaceOrientation(orientation, duration: coordinator.transitionDuration)
        coordinator.animate { [weak self] context in
            self?._willAnimateRotationToInterfaceOrientation(orientation, duration: coordinator.transitionDuration)
        } completion: { [weak self] context in
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
        toolbarSnapshotView = toolbar.snapshotView(afterScreenUpdates: false)
        toolbarSnapshotView?.frame = toolbar.frame
        if toInterfaceOrientation.isLandscape {
            toolbarSnapshotView?.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        } else {
            toolbarSnapshotView?.autoresizingMask = [.flexibleHeight, .flexibleRightMargin]
        }
        if let snapshotView = toolbarSnapshotView {
            self.view.addSubview(snapshotView)
        }
        
        var frame = frameForToolbar(verticalLayout: toInterfaceOrientation.isPortrait)
        if toInterfaceOrientation.isLandscape {
            frame.origin.x = -frame.size.width
        } else {
            frame.origin.y = self.view.bounds.height
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
        toolbar.layer.sublayers?.forEach({ $0.removeAllAnimations() })
        
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
        let cancelButtonTitle = self.cancelButtonTitle ?? AppBundle.cancelButton
        let originalButtonTitle = self.originalAspectRatioName ?? AppBundle.originalButton
        
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
        
        fw_showSheet(title: nil, message: nil, cancel: cancelButtonTitle, actions: itemStrings) { [weak self] index in
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
            if let image = self.image.fw_croppedImage(frame: cropFrame, angle: angle, circular: true) {
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
                image = self.image.fw_croppedImage(frame: cropFrame, angle: angle, circular: false)
            }
            
            if let image = image {
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
        get { return _gridHidden }
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
    
    public override init(frame: CGRect) {
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
    
    open override var frame: CGRect {
        didSet {
            if !outerLineViews.isEmpty {
                layoutLines()
            }
        }
    }
    
    open override func didMoveToSuperview() {
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
        let boundsSize = self.bounds.size
        
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
        var padding = (self.bounds.height - (thickness * CGFloat(numberOfLines))) / (CGFloat(numberOfLines) + 1.0)
        for i in 0..<numberOfLines {
            let lineView = horizontalGridLines[i]
            var frame = CGRect.zero
            frame.size.height = thickness
            frame.size.width = self.bounds.width
            frame.origin.y = (padding * CGFloat(i+1)) + (thickness * CGFloat(i))
            lineView.frame = frame
        }

        numberOfLines = verticalGridLines.count
        padding = (self.bounds.width - (thickness * CGFloat(numberOfLines))) / (CGFloat(numberOfLines) + 1)
        for i in 0..<numberOfLines {
            let lineView = verticalGridLines[i]
            var frame = CGRect.zero
            frame.size.width = thickness
            frame.size.height = self.bounds.height
            frame.origin.x = (padding * CGFloat(i+1)) + (thickness * CGFloat(i))
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
        return clampButton.frame
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
        get { return resetButton.isEnabled }
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
        result.setTitle(doneTextButtonTitle ?? AppBundle.doneButton, for: .normal)
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
        result.setTitle(cancelTextButtonTitle ?? AppBundle.cancelButton, for: .normal)
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
        return self.rotateCounterClockwiseButton
    }
    
    private var reverseContentLayout: Bool = false
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        didInitialize()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        didInitialize()
    }
    
    private func didInitialize() {
        addSubview(backgroundView)
        reverseContentLayout = UIView.userInterfaceLayoutDirection(for: self.semanticContentAttribute) == .rightToLeft
        addSubview(doneTextButton)
        addSubview(doneIconButton)
        addSubview(cancelTextButton)
        addSubview(cancelIconButton)
        addSubview(clampButton)
        addSubview(rotateCounterClockwiseButton)
        addSubview(rotateClockwiseButton)
        addSubview(resetButton)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        let verticalLayout = self.bounds.width < self.bounds.height
        let boundsSize = self.bounds.size
        
        cancelIconButton.isHidden = cancelButtonHidden || !verticalLayout
        cancelTextButton.isHidden = cancelButtonHidden || verticalLayout
        doneIconButton.isHidden = doneButtonHidden || !verticalLayout
        doneTextButton.isHidden = doneButtonHidden || verticalLayout
        
        var frame = self.bounds
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
            frame.origin.y = (self.bounds.height - 44.0) / 2.0
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
            
            let containerRect = CGRect(x: x, y: frame.origin.y, width: width, height: self.bounds.height - frame.origin.y).integral
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
            frame.origin.x = (self.bounds.width - 44.0) / 2.0
            frame.size.height = 44.0
            frame.size.width = 44.0
            frame.origin.y = self.bounds.height - 44.0
            cancelIconButton.frame = frame

            frame.origin.y = statusBarHeightInset
            frame.size.width = 44.0
            frame.size.height = 44.0
            doneIconButton.frame = frame

            let containerRect = CGRect(x: frame.origin.x, y: doneIconButton.frame.maxY, width: self.bounds.width - frame.origin.x, height: cancelIconButton.frame.minY - doneIconButton.frame.maxY)
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
            let sameOffset = horizontally ? containerRect.height - button.bounds.height : containerRect.width - button.bounds.width
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

public protocol ImageCropViewDelegate: AnyObject {
    func cropViewDidBecomeResettable(_ cropView: ImageCropView)
    func cropViewDidBecomeNonResettable(_ cropView: ImageCropView)
}

open class ImageCropView: UIView, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
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
    open var cropBoxAspectRatioIsPortrait: Bool {
        let cropFrame = self.cropBoxFrame
        return cropFrame.width < cropFrame.height
    }
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
    private var isEditing = false
    private var disableForegroundMatching = false
    private var rotationContentOffset: CGPoint = .zero
    private var rotationContentSize: CGSize = .zero
    private var rotationBoundFrame: CGRect = .zero
    private var contentBounds: CGRect
    private var imageSize: CGSize
    private var hasAspectRatio: Bool
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
    
    private static var cropViewPadding: CGFloat = 14.0
    private static var cropTimerDuration: TimeInterval = 0.8
    private static var cropViewMinimumBoxSize: CGFloat = 42.0
    private static var cropViewCircularPathRadius: CGFloat = 300.0
    private static var cropMaximumZoomScale: CGFloat = 15.0
    
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
    
    private func layoutInitialImage() {
        
    }
    
    private func matchForegroundToBackground() {
        
    }
    
    private func updateCropBoxFrame(gesturePoint point: CGPoint) {
        
    }
    
    private func toggleTranslucencyViewVisible(_ visible: Bool) {
        
    }
    
    private func updateToImageCropFrame(_ imageCropFrame: CGRect) {
        
    }
    
    @objc private func gridPanGestureRecognized(_ recognizer: UIPanGestureRecognizer) {
        
    }
    
    private func startResetTimer() {
        
    }
    
    @objc private func timerTriggered() {
        
    }
    
    private func cancelResetTimer() {
        
    }
    
    private func cropEdge(for point: CGPoint) -> ImageCropViewOverlayEdge {
        
    }
    
    private func startEditing() {
        
    }
    
    private func setEditing(_ editing: Bool, resetCropBox: Bool, animated: Bool) {
        
    }
    
    private func captureStateForImageRotation() {
        
    }
    
    private func checkForCanReset() {
        
    }
    
}
