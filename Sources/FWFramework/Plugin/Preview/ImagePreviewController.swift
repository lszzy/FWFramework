//
//  ImagePreviewController.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
import Photos

// MARK: - ImagePreviewView
/// 图片预览媒体类型枚举
@objc public enum ImagePreviewMediaType: UInt {
    case image
    case livePhoto
    case video
    case others
}

/// 图片预览视图代理
@objc public protocol ImagePreviewViewDelegate: ZoomImageViewDelegate {
    
    /// 返回预览的图片数量
    @objc optional func numberOfImages(in imagePreviewView: ImagePreviewView) -> Int
    
    /// 自定义渲染zoomImageView方法
    @objc optional func imagePreviewView(_ imagePreviewView: ImagePreviewView, renderZoomImageView zoomImageView: ZoomImageView, at index: Int)
    
    /// 是否重置指定index的zoomImageView，未实现时默认YES
    @objc optional func imagePreviewView(_ imagePreviewView: ImagePreviewView, shouldResetZoomImageView zoomImageView: ZoomImageView, at index: Int) -> Bool
    
    /// 返回要展示的媒体资源的类型（图片、live photo、视频），如果不实现此方法，则 ImagePreviewView 将无法选择最合适的 cell 来复用从而略微增大系统开销
    @objc optional func imagePreviewView(_ imagePreviewView: ImagePreviewView, assetTypeAt index: Int) -> ImagePreviewMediaType
    
    /// 当左右的滚动停止时会触发这个方法，index为当前滚动到的图片所在的索引
    @objc optional func imagePreviewView(_ imagePreviewView: ImagePreviewView, didScrollTo index: Int)
    
    /// 在滚动过程中，如果某一张图片的边缘（左/右）经过预览控件的中心点时，就会触发这个方法，index为当前滚动到的图片所在的索引
    @objc optional func imagePreviewView(_ imagePreviewView: ImagePreviewView, willScrollHalfTo index: Int)
    
}

/// 查看图片的控件，支持横向滚动、放大缩小、loading 及错误语展示，内部使用 UICollectionView 实现横向滚动及 cell 复用，因此与其他普通的 UICollectionView 一样，也可使用 reloadData、collectionViewLayout 等常用方法。
///
/// 使用方式：
/// 1. 使用 initWithFrame: 或 init 方法初始化。
/// 2. 设置 delegate。
/// 3. 在 delegate 的 numberOfImagesInImagePreviewView: 方法里返回图片总数。
/// 4. 在 delegate 的 imagePreviewView:renderZoomImageView:atIndex: 方法里为 zoomImageView.image 设置图片，如果需要，也可调用 [zoomImageView showLoading] 等方法来显示 loading。
/// 5. 由于 ImagePreviewViewDelegate 继承自 ZoomImageViewDelegate，所以若需要响应单击、双击、长按事件，请实现 ZoomImageViewDelegate 里的对应方法。
/// 6. 若需要从指定的某一张图片开始查看，可使用 currentImageIndex 属性。
///
/// [QMUI_iOS](https://github.com/Tencent/QMUI_iOS)
open class ImagePreviewView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ZoomImageViewDelegate {
    
    /// 事件代理
    open weak var delegate: ImagePreviewViewDelegate?
    
    /// 当前图片数量
    open var imageCount: Int {
        return collectionView.numberOfItems(inSection: 0)
    }
    /// 获取当前正在查看的图片 index，也可强制将图片滚动到指定的 index
    open var currentImageIndex: Int {
        get {
            return _currentImageIndex
        }
        set {
            setCurrentImageIndex(newValue, animated: false)
        }
    }
    private var _currentImageIndex: Int = 0
    
    /// 图片数组，delegate不存在时调用，支持UIImage|PHLivePhoto|AVPlayerItem|NSURL|NSString等
    open var imageURLs: [Any]?
    /// 自定义图片信息数组，默认未使用，可用于自定义内容展示，默认nil
    open var imageInfos: [Any]?
    /// 占位图片句柄，仅imageURLs生效，默认nil
    open var placeholderImage: ((_ index: Int) -> UIImage?)?
    /// 是否自动播放video，默认NO
    open var autoplayVideo: Bool = false
    
    /// 自定义zoomImageView样式句柄，cellForItem方法自动调用，先于renderZoomImageView
    open var customZoomImageView: ((_ zoomImageView: ZoomImageView, _ index: Int) -> Void)?
    /// 自定义渲染zoomImageView句柄，cellForItem方法自动调用，优先级低于delegate
    open var renderZoomImageView: ((_ zoomImageView: ZoomImageView, _ index: Int) -> Void)?
    /// 自定义内容视图句柄，内容显示完成自动调用，优先级低于delegate
    open var customZoomContentView: ((_ zoomImageView: ZoomImageView, _ contentView: UIView) -> Void)?
    /// 获取当前正在查看的zoomImageView，若当前 index 对应的图片不可见（不处于可视区域），则返回 nil
    open weak var currentZoomImageView: ZoomImageView? {
        return zoomImageView(at: currentImageIndex)
    }
    
    /// 集合视图
    open lazy var collectionView: UICollectionView = {
        let result = UICollectionView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height), collectionViewLayout: collectionViewLayout)
        result.delegate = self
        result.dataSource = self
        result.backgroundColor = .clear
        result.showsHorizontalScrollIndicator = false
        result.showsVerticalScrollIndicator = false
        result.scrollsToTop = false
        result.delaysContentTouches = false
        result.decelerationRate = .fast
        result.contentInsetAdjustmentBehavior = .never
        result.register(ImagePreviewCell.self, forCellWithReuseIdentifier: kImageOrUnknownCellIdentifier)
        result.register(ImagePreviewCell.self, forCellWithReuseIdentifier: kVideoCellIdentifier)
        result.register(ImagePreviewCell.self, forCellWithReuseIdentifier: kLivePhotoCellIdentifier)
        return result
    }()
    
    /// 结合视图布局
    open lazy var collectionViewLayout: CollectionViewPagingLayout = {
        let result = CollectionViewPagingLayout(style: .default)
        result.allowsMultipleItemScroll = false
        return result
    }()
    
    weak var previewController: ImagePreviewController?
    private var isChangingCollectionViewBounds = false
    private var isChangingIndexWhenScrolling = false
    private var previousIndexWhenScrolling: CGFloat = .zero
    
    private let kLivePhotoCellIdentifier = "livephoto"
    private let kVideoCellIdentifier = "video"
    private let kImageOrUnknownCellIdentifier = "imageorunknown"
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        didInitialize()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        didInitialize()
    }
    
    private func didInitialize() {
        addSubview(collectionView)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        let isCollectionViewSizeChanged = !collectionView.bounds.size.equalTo(bounds.size)
        if isCollectionViewSizeChanged {
            isChangingCollectionViewBounds = true
            
            // 必须先 invalidateLayout，再更新 collectionView.frame，否则横竖屏旋转前后的图片不一致（因为 scrollViewDidScroll: 时 contentSize、contentOffset 那些是错的）
            collectionViewLayout.invalidateLayout()
            collectionView.frame = bounds
            if currentImageIndex < collectionView.numberOfItems(inSection: 0) {
                collectionView.scrollToItem(at: IndexPath(item: currentImageIndex, section: 0), at: .centeredHorizontally, animated: false)
            }
            
            isChangingCollectionViewBounds = false
        }
    }
    
    /// 将图片滚动到指定的 index
    open func setCurrentImageIndex(_ currentImageIndex: Int, animated: Bool) {
        _currentImageIndex = currentImageIndex
        isChangingIndexWhenScrolling = false
        previewController?.updatePageLabel()
        
        collectionView.reloadData()
        if currentImageIndex < collectionView.numberOfItems(inSection: 0) {
            collectionView.scrollToItem(at: IndexPath(item: currentImageIndex, section: 0), at: .centeredHorizontally, animated: animated)
            // collectionView.layoutIfNeeded()
        }
    }
    
    /// 获取某个 ZoomImageView 所对应的 index，若当前的 zoomImageView 不可见，会返回nil
    open func index(for zoomImageView: ZoomImageView) -> Int? {
        if let cell = zoomImageView.superview?.superview as? ImagePreviewCell {
            return collectionView.indexPath(for: cell)?.item
        }
        return nil
    }
    
    /// 获取某个 index 对应的 zoomImageView，若该 index 对应的图片当前不可见（不处于可视区域），则返回 nil
    open func zoomImageView(at index: Int) -> ZoomImageView? {
        let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? ImagePreviewCell
        return cell?.zoomImageView
    }
    
    // MARK: - UICollectionView
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let numberOfImages = delegate?.numberOfImages?(in: self) {
            return numberOfImages
        }
        return imageURLs?.count ?? 0
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var identifier = kImageOrUnknownCellIdentifier
        var imageURL: Any?
        if let type = delegate?.imagePreviewView?(self, assetTypeAt: indexPath.item) {
            if type == .livePhoto {
                identifier = kLivePhotoCellIdentifier
            } else if type == .video {
                identifier = kVideoCellIdentifier
            }
        } else if (imageURLs?.count ?? 0) > indexPath.item {
            imageURL = imageURLs?[indexPath.item]
            if imageURL is PHLivePhoto {
                identifier = kLivePhotoCellIdentifier
            } else if imageURL is AVPlayerItem {
                identifier = kVideoCellIdentifier
            }
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! ImagePreviewCell
        let zoomView = cell.zoomImageView
        zoomView.delegate = self
        
        // 因为 cell 复用的问题，很可能此时会显示一张错误的图片，因此这里要清空所有图片的显示
        var shouldReset = true
        if let reset = delegate?.imagePreviewView?(self, shouldResetZoomImageView: zoomView, at: indexPath.item) {
            shouldReset = reset
        }
        if shouldReset {
            zoomView.image = nil
            zoomView.videoPlayerItem = nil
            zoomView.livePhoto = nil
        }
        
        self.customZoomImageView?(zoomView, indexPath.item)
        
        if delegate?.imagePreviewView?(self, renderZoomImageView: zoomView, at: indexPath.item) != nil {
        } else if let renderBlock = self.renderZoomImageView {
            renderBlock(zoomView, indexPath.item)
        } else if (imageURLs?.count ?? 0) > indexPath.item {
            let placeholderImage = self.placeholderImage?(indexPath.item)
            zoomView.setImageURL(imageURL, placeholderImage: placeholderImage, completion: nil)
        }
        
        // 自动播放视频
        if autoplayVideo && !isChangingIndexWhenScrolling {
            if zoomView.videoPlayerItem != nil {
                zoomView.playVideo()
            }
        }
        return cell
    }
    
    open func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? ImagePreviewCell else { return }
        cell.zoomImageView.revertZooming()
    }
    
    open func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? ImagePreviewCell else { return }
        cell.zoomImageView.endPlayingVideo()
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
    
    // MARK: - UIScrollViewDelegate
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == collectionView else { return }
        
        // 当前滚动到的页数
        delegate?.imagePreviewView?(self, didScrollTo: currentImageIndex)
        
        // 自动播放视频
        if autoplayVideo && isChangingIndexWhenScrolling {
            let zoomImageView = zoomImageView(at: currentImageIndex)
            if zoomImageView?.videoPlayerItem != nil {
                zoomImageView?.playVideo()
            }
        }
    }
    
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == collectionView,
              !isChangingCollectionViewBounds else {
            return
        }
        
        let pageWidth = collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: IndexPath(item: 0, section: 0)).width
        let pageHorizontalMargin = collectionViewLayout.minimumLineSpacing
        let contentOffsetX = collectionView.contentOffset.x
        var index = contentOffsetX / (pageWidth + pageHorizontalMargin)
        
        // 在滑动过临界点的那一次才去调用 delegate，避免过于频繁的调用
        let isFirstDidScroll = previousIndexWhenScrolling == 0
        
        // fastToRight 示例 : previousIndexWhenScrolling 1.49, index = 2.0
        let fastToRight = (floor(index) - floor(previousIndexWhenScrolling) >= 1.0) && (floor(index) - previousIndexWhenScrolling > 0.5)
        let turnPageToRight = fastToRight || (previousIndexWhenScrolling <= floor(index) + 0.5 && floor(index) + 0.5 <= index)

        // fastToLeft 示例 : previousIndexWhenScrolling 2.51, index = 1.99
        let fastToLeft = (floor(previousIndexWhenScrolling) - floor(index) >= 1.0) && (previousIndexWhenScrolling - ceil(index) > 0.5)
        let turnPageToLeft = fastToLeft || (index <= floor(index) + 0.5 && floor(index) + 0.5 <= previousIndexWhenScrolling)
        
        if !isFirstDidScroll && (turnPageToRight || turnPageToLeft) {
            index = round(index)
            let roundIndex = Int(index)
            if 0 <= roundIndex && roundIndex < collectionView.numberOfItems(inSection: 0) {
                // 不调用 setter，避免又走一次 scrollToItem
                _currentImageIndex = roundIndex
                isChangingIndexWhenScrolling = true
                previewController?.updatePageLabel()
                
                delegate?.imagePreviewView?(self, willScrollHalfTo: roundIndex)
            }
        }
        previousIndexWhenScrolling = index
    }
    
    // MARK: - ZoomImageViewDelegate
    open func singleTouch(in zoomImageView: ZoomImageView, location: CGPoint) {
        previewController?.dismissingWhenTapped(zoomImageView)
        delegate?.singleTouch?(in: zoomImageView, location: location)
    }
    
    open func doubleTouch(in zoomImageView: ZoomImageView, location: CGPoint) {
        delegate?.doubleTouch?(in: zoomImageView, location: location)
    }
    
    open func longPress(in zoomImageView: ZoomImageView) {
        delegate?.longPress?(in: zoomImageView)
    }
    
    open func zoomImageView(_ zoomImageView: ZoomImageView, didHideVideoToolbar didHide: Bool) {
        delegate?.zoomImageView?(zoomImageView, didHideVideoToolbar: didHide)
    }
    
    open func zoomImageView(_ zoomImageView: ZoomImageView, customContentView contentView: UIView) {
        if delegate?.zoomImageView?(zoomImageView, customContentView: contentView) != nil {
        } else {
            customZoomContentView?(zoomImageView, contentView)
        }
    }
    
    open func enabledZoomView(in zoomImageView: ZoomImageView) -> Bool {
        if let enabled = delegate?.enabledZoomView?(in: zoomImageView) {
            return enabled
        }
        return true
    }
    
}

fileprivate class ImagePreviewCell: UICollectionViewCell {
    
    var contentViewBounds: CGRect = .zero
    
    lazy var zoomImageView: ZoomImageView = {
        let result = ZoomImageView()
        return result
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        contentView.addSubview(zoomImageView)
        contentViewBounds = contentView.bounds
        zoomImageView.fw_frameApplyTransform = contentView.bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if !contentView.bounds.equalTo(contentViewBounds) {
            contentViewBounds = contentView.bounds
            zoomImageView.fw_frameApplyTransform = contentView.bounds
        }
    }
    
}

// MARK: - ImagePreviewController
public enum ImagePreviewTransitioningStyle: UInt {
    /// present 时整个界面渐现，dismiss 时整个界面渐隐，默认。
    case fade
    /// present 时从某个指定的位置缩放到屏幕中央，dismiss 时缩放到指定位置，必须实现 sourceImageView 并返回一个非空的值
    case zoom
}

/// 图片预览控件，主要功能由内部自带的 ImagePreviewView 提供，由于以 viewController 的形式存在，所以适用于那种在单独界面里展示图片，或者需要从某张目标图片的位置以动画的形式放大进入预览界面的场景。
///
/// 使用方式：
/// 1. 使用 init 方法初始化
/// 2. 添加 self.imagePreviewView 的 delegate
/// 3. 以 push 或 present 的方式打开界面。如果是 present，则支持 ImagePreviewTransitioningStyle 里定义的动画。特别地，如果使用 zoom 方式，则需要通过 sourceImageView() 返回一个原界面上的 view 以作为 present 动画的起点和 dismiss 动画的终点。
open class ImagePreviewController: UIViewController, UIViewControllerTransitioningDelegate {
    
    /// 图片背后的黑色背景，默认为黑色
    open var backgroundColor: UIColor? = .black {
        didSet {
            if isViewLoaded {
                view.backgroundColor = backgroundColor
            }
        }
    }
    
    /// 以 present 方式进入大图预览的时候使用的转场动画 animator，可通过 ImagePreviewTransitionAnimator 提供的若干个 block 属性自定义动画，也可以完全重写一个自己的 animator。
    open var transitioningAnimator: ImagePreviewTransitionAnimator? {
        didSet {
            transitioningAnimator?.imagePreviewViewController = self
        }
    }
    
    /// present 时的动画，默认为 fade，当修改了 presentingStyle 时会自动把 dismissingStyle 也修改为相同的值。
    open var presentingStyle: ImagePreviewTransitioningStyle = .fade {
        didSet {
            dismissingStyle = presentingStyle
        }
    }
    
    /// dismiss 时的动画，默认为 fade，默认与 presentingStyle 的值相同，若需要与之不同，请在设置完 presentingStyle 之后再设置 dismissingStyle。
    open var dismissingStyle: ImagePreviewTransitioningStyle = .fade
    
    /// 当以 zoom 动画进入/退出大图预览时，会通过这个 block 获取到原本界面上的图片所在的 view，从而进行动画的位置计算，如果返回的值为 nil，则会强制使用 fade 动画。当同时存在 sourceImageView 和 sourceImageRect 时，只有 sourceImageRect 会被调用。支持UIView|NSValue.CGRect类型
    open var sourceImageView: ((_ index: Int) -> Any?)?
    
    /// 当以 zoom 动画进入/退出大图预览时，会通过这个 block 获取到原本界面上的图片所在的 view，从而进行动画的位置计算，如果返回的值为 CGRectZero，则会强制使用 fade 动画。注意返回值要进行坐标系转换。当同时存在 sourceImageView 和 sourceImageRect 时，只有 sourceImageRect 会被调用。
    open var sourceImageRect: ((_ index: Int) -> CGRect)?
    
    /// 当以 zoom 动画进入/退出大图预览时，可以指定一个圆角值，默认为 -1(小于0即可)，也即自动从 sourceImageView.layer.cornerRadius 获取，如果使用的是 sourceImageRect 或希望自定义圆角值，则直接给 sourceImageCornerRadius 赋值即可。
    open var sourceImageCornerRadius: CGFloat = -1
    
    /// 手势拖拽退出预览模式时是否启用缩放效果，默认YES。仅对以 present 方式进入大图预览的场景有效。
    open var dismissingScaleEnabled: Bool = true
    
    /// 是否支持手势拖拽退出预览模式，默认为 YES。仅对以 present 方式进入大图预览的场景有效。
    open var dismissingGestureEnabled: Bool = true
    
    /// 手势单击图片时是否退出预览模式，默认NO。仅对以 present 方式进入大图预览的场景有效。
    open var dismissingWhenTappedImage: Bool = false
    
    /// 手势单击视频时是否退出预览模式，默认NO。仅对以 present 方式进入大图预览的场景有效。
    open var dismissingWhenTappedVideo: Bool = false
    
    /// 当前页数发生变化回调，默认nil
    open var pageIndexChanged: ((_ index: Int) -> Void)?
    
    /// 是否显示页数标签，默认NO
    open var showsPageLabel: Bool {
        get {
            return !pageLabel.isHidden
        }
        set {
            pageLabel.isHidden = !newValue
        }
    }
    
    /// 页数标签中心句柄，默认nil时离底部安全距离+18
    open var pageLabelCenter: (() -> CGPoint)?
    
    /// 页数文本句柄，默认nil时为index / count
    open var pageLabelText: ((_ index: Int, _ count: Int) -> String)?
    
    /// 图片预览视图
    open lazy var imagePreviewView: ImagePreviewView = {
        let result = ImagePreviewView(frame: isViewLoaded ? view.bounds : .zero)
        result.previewController = self
        return result
    }()
    
    /// 页数标签，默认字号16、白色
    open lazy var pageLabel: UILabel = {
        let result = UILabel()
        result.font = UIFont.systemFont(ofSize: 16)
        result.textColor = .white
        result.textAlignment = .center
        result.isHidden = true
        return result
    }()
    
    private var dismissingGesture: UIPanGestureRecognizer?
    private var gestureBeganLocation: CGPoint = .zero
    private weak var gestureZoomImageView: ZoomImageView?
    private var originalStatusBarHidden = false
    private var statusBarHidden = false
    private var useOriginalStatusBarHidden = true
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        didInitialize()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        didInitialize()
    }
    
    private func didInitialize() {
        transitioningAnimator = ImagePreviewTransitionAnimator()
        transitioningAnimator?.imagePreviewViewController = self
        modalPresentationStyle = .custom
        modalPresentationCapturesStatusBarAppearance = true
        transitioningDelegate = self
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = backgroundColor
        view.addSubview(imagePreviewView)
        view.addSubview(pageLabel)
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        imagePreviewView.fw_frameApplyTransform = view.bounds
        if (pageLabel.text?.count ?? 0) < 1 && imagePreviewView.imageCount > 0 {
            updatePageLabel()
        }
        let pageLabelCenter = self.pageLabelCenter?() ?? CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - (UIScreen.fw_safeAreaInsets.bottom + 18))
        pageLabel.center = pageLabelCenter
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if fw_isPresented {
            initObjectsForZoomStyleIfNeeded()
        }
        imagePreviewView.collectionView.reloadData()
        imagePreviewView.collectionView.layoutIfNeeded()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        useOriginalStatusBarHidden = false
        
        if fw_isPresented {
            statusBarHidden = true
        }
        setNeedsStatusBarAppearanceUpdate()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        statusBarHidden = originalStatusBarHidden
        setNeedsStatusBarAppearanceUpdate()
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        useOriginalStatusBarHidden = true
        
        removeObjectsForZoomStyle()
        resetDismissingGesture()
    }
    
    open override var prefersStatusBarHidden: Bool {
        if useOriginalStatusBarHidden {
            // 在 present/dismiss 动画过程中，都使用原界面的状态栏显隐状态
            if presentingViewController != nil {
                originalStatusBarHidden = presentingViewController?.view.window?.windowScene?.statusBarManager?.isStatusBarHidden ?? false
                return originalStatusBarHidden
            }
            return super.prefersStatusBarHidden
        }
        return statusBarHidden
    }
    
    open override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        dismissingGestureChanged(true)
        super.dismiss(animated: flag, completion: completion)
    }
    
    /// 页数标签需要更新，子类可重写
    open func updatePageLabel() {
        if let textBlock = pageLabelText {
            pageLabel.text = textBlock(imagePreviewView.currentImageIndex, imagePreviewView.imageCount)
        } else {
            pageLabel.text = String(format: "%@ / %@", "\(imagePreviewView.currentImageIndex + 1)", "\(imagePreviewView.imageCount)")
        }
        pageLabel.sizeToFit()
        
        pageIndexChanged?(imagePreviewView.currentImageIndex)
    }
    
    /// 处理单击关闭事件，子类可重写
    open func dismissingWhenTapped(_ zoomImageView: ZoomImageView) {
        guard fw_isPresented else { return }
        
        var shouldDismiss = false
        if zoomImageView.videoPlayerItem != nil {
            if dismissingWhenTappedVideo { shouldDismiss = true }
        } else {
            if dismissingWhenTappedImage { shouldDismiss = true }
        }
        if shouldDismiss {
            dismiss(animated: true)
        }
    }
    
    /// 触发拖动手势或dismiss时切换子视图显示或隐藏，子类可重写
    open func dismissingGestureChanged(_ isHidden: Bool) {
        let zoomImageView = imagePreviewView.currentZoomImageView
        if let zoomImageView = zoomImageView, zoomImageView.videoPlayerItem != nil {
            if zoomImageView.showsVideoToolbar {
                zoomImageView.videoToolbar.alpha = isHidden ? 0 : 1
            }
            if zoomImageView.showsVideoCloseButton {
                zoomImageView.videoCloseButton.alpha = isHidden ? 0 : 1
            }
        }
        view.subviews.forEach { obj in
            if obj != self.imagePreviewView {
                obj.alpha = isHidden ? 0 : 1
            }
        }
    }
    
    open func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitioningAnimator
    }
    
    open func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitioningAnimator
    }
    
    private func initObjectsForZoomStyleIfNeeded() {
        if dismissingGesture == nil && dismissingGestureEnabled {
            let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleDismissingPreviewGesture(_:)))
            dismissingGesture = gesture
            view.addGestureRecognizer(gesture)
        }
    }
    
    private func removeObjectsForZoomStyle() {
        guard let gesture = dismissingGesture else { return }
        gesture.removeTarget(self, action: #selector(handleDismissingPreviewGesture(_:)))
        view.removeGestureRecognizer(gesture)
        dismissingGesture = nil
    }
    
    @objc private func handleDismissingPreviewGesture(_ gesture: UIPanGestureRecognizer) {
        guard dismissingGestureEnabled else { return }
        
        switch gesture.state {
        case .began:
            gestureBeganLocation = gesture.location(in: view)
            gestureZoomImageView = imagePreviewView.currentZoomImageView
            // 当 contentView 被放大后，如果不去掉 clipToBounds，那么手势退出预览时，contentView 溢出的那部分内容就看不到
            gestureZoomImageView?.scrollView.clipsToBounds = false
            if dismissingGestureEnabled {
                dismissingGestureChanged(true)
            }
            
        case .changed:
            let location = gesture.location(in: view)
            let horizontalDistance = location.x - gestureBeganLocation.x
            var verticalDistance = location.y - gestureBeganLocation.y
            var ratio: CGFloat = 1.0
            var alpha: CGFloat = 1.0
            
            if verticalDistance > 0 {
                // 往下拉的话，当启用图片缩小，但图片移动距离与手指移动距离保持一致
                if dismissingScaleEnabled {
                    ratio = 1.0 - verticalDistance / view.bounds.height / 2
                }
                
                // 如果预览大图支持横竖屏而背后的界面只支持竖屏，则在横屏时手势拖拽不要露出背后的界面
                if dismissingGestureEnabled {
                    alpha = 1.0 - verticalDistance / view.bounds.height * 1.8
                }
            } else {
                // 往上拉的话，图片不缩小，但手指越往上移动，图片将会越难被拖走；后面这个加数越大，拖动时会越快达到不怎么拖得动的状态
                let a = gestureBeganLocation.y + 100
                let b = 1 - pow((a - abs(verticalDistance)) / a, 2)
                let contentViewHeight = gestureZoomImageView?.contentViewRect.height ?? 0
                let c = (view.bounds.height - contentViewHeight) / 2
                verticalDistance = -c * b
            }
            
            var transform = CGAffineTransform(translationX: horizontalDistance, y: verticalDistance)
            transform = transform.scaledBy(x: ratio, y: ratio)
            gestureZoomImageView?.transform = transform
            view.backgroundColor = view.backgroundColor?.withAlphaComponent(alpha)
            
            let statusBarHidden = alpha >= 1 ? true : originalStatusBarHidden
            if statusBarHidden != self.statusBarHidden {
                self.statusBarHidden = statusBarHidden
                setNeedsStatusBarAppearanceUpdate()
            }
            
        case .ended:
            let location = gesture.location(in: view)
            let verticalDistance = location.y - gestureBeganLocation.y
            if verticalDistance > view.bounds.height / 2 / 3 {
                // 如果背后的界面支持的方向与当前预览大图的界面不一样，则为了避免在 dismiss 后看到背后界面的旋转，这里提前触发背后界面的 viewWillAppear，从而借助 AutomaticallyRotateDeviceOrientation 的功能去提前旋转到正确方向。（备忘，如果不这么处理，标准的触发 viewWillAppear: 的时机是在 animator 的 animateTransition: 时，这里就算重复调用一次也不会导致 viewWillAppear: 多次触发）
                // 这里只能解决手势拖拽的 dismiss，如果是业务代码手动调用 dismiss 则无法兼顾，再看怎么处理。
                if !dismissingGestureEnabled {
                    presentingViewController?.beginAppearanceTransition(true, animated: true)
                }
                
                dismiss(animated: true)
            } else {
                cancelDismissingGesture()
            }
            
        default:
            cancelDismissingGesture()
        }
    }
    
    private func cancelDismissingGesture() {
        // 手势判定失败，恢复到手势前的状态
        statusBarHidden = true
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut) {
            self.setNeedsStatusBarAppearanceUpdate()
            self.resetDismissingGesture()
        }
    }
    
    private func resetDismissingGesture() {
        // 清理手势相关的变量
        gestureZoomImageView?.transform = .identity
        gestureBeganLocation = .zero
        if dismissingGestureEnabled {
            dismissingGestureChanged(false)
        }
        gestureZoomImageView = nil
        view.backgroundColor = backgroundColor
    }
    
}

// MARK: - ImagePreviewTransitionAnimator
/// 负责处理 ImagePreviewController 被 present/dismiss 时的动画，如果需要自定义动画效果，可按需修改 animationEnteringBlock、animationBlock、animationCompletionBlock。
open class ImagePreviewTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    /// 当前图片预览控件的引用，在为 ImagePreviewController.transitioningAnimator 赋值时会自动建立这个引用关系
    open weak var imagePreviewViewController: ImagePreviewController?
    
    /// 转场动画的持续时长，默认为 0.25
    open var duration: TimeInterval = 0.25
    
    /// 当 sourceImageView 本身带圆角时，动画过程中会通过这个 layer 来处理圆角的动画
    open lazy var cornerRadiusMaskLayer: CALayer = {
        let result = CALayer()
        result.fw_removeDefaultAnimations()
        result.backgroundColor = UIColor.white.cgColor
        return result
    }()

    /// 动画开始前的准备工作可以在这里做
    ///
    /// animator 当前的动画器 animator
    /// isPresenting YES 表示当前正在 present，NO 表示正在 dismiss
    /// style 当前动画的样式
    /// sourceImageRect 原界面上显示图片的 view 在 imagePreviewViewController.view 坐标系里的 rect，仅在 style 为 zoom 时有值，style 为 fade 时为 CGRectZero
    /// zoomImageView 当前图片
    /// transitionContext 转场动画的上下文，可通过它获取前后界面、动画容器等信息
    open var animationEnteringBlock: ((_ animator: ImagePreviewTransitionAnimator, _ isPresenting: Bool, _ style: ImagePreviewTransitioningStyle, _ sourceImageRect: CGRect, _ zoomImageView: ZoomImageView, _ transitionContext: UIViewControllerContextTransitioning?) -> Void)?
    
    /// 转场时的实际动画内容，整个 block 会在一个 UIView animation block 里被调用，因此直接写动画内容即可，无需包裹一个 animation block
    ///
    /// animator 当前的动画器 animator
    /// isPresenting YES 表示当前正在 present，NO 表示正在 dismiss
    /// style 当前动画的样式
    /// sourceImageRect 原界面上显示图片的 view 在 imagePreviewViewController.view 坐标系里的 rect，仅在 style 为 zoom 时有值，style 为 fade 时为 CGRectZero
    /// zoomImageView 当前图片
    /// transitionContext 转场动画的上下文，可通过它获取前后界面、动画容器等信息
    open var animationBlock: ((_ animator: ImagePreviewTransitionAnimator, _ isPresenting: Bool, _ style: ImagePreviewTransitioningStyle, _ sourceImageRect: CGRect, _ zoomImageView: ZoomImageView, _ transitionContext: UIViewControllerContextTransitioning?) -> Void)?
    
    /// 动画结束后的事情，在执行完这个 block 后才会调用 [transitionContext completeTransition:]
    ///
    /// animator 当前的动画器 animator
    /// isPresenting YES 表示当前正在 present，NO 表示正在 dismiss
    /// style 当前动画的样式
    /// sourceImageRect 原界面上显示图片的 view 在 imagePreviewViewController.view 坐标系里的 rect，仅在 style 为 zoom 时有值，style 为 fade 时为 CGRectZero
    /// zoomImageView 当前图片
    /// transitionContext 转场动画的上下文，可通过它获取前后界面、动画容器等信息
    open var animationCompletionBlock: ((_ animator: ImagePreviewTransitionAnimator, _ isPresenting: Bool, _ style: ImagePreviewTransitioningStyle, _ sourceImageRect: CGRect, _ zoomImageView: ZoomImageView, _ transitionContext: UIViewControllerContextTransitioning?) -> Void)?
    
    /// 动画回调句柄，动画开始和结束时调用
    ///
    /// animator 当前的动画器 animator
    /// isPresenting YES 表示当前正在 present，NO 表示正在 dismiss
    /// isFinished YES 表示动画结束，NO 表示动画开始
    open var animationCallbackBlock: ((_ animator: ImagePreviewTransitionAnimator, _ isPresenting: Bool, _ isFinished: Bool) -> Void)?
    
    public override init() {
        super.init()
        
        self.animationEnteringBlock = { animator, isPresenting, style, sourceImageRect, zoomImageView, transitionContext in
            let previewView = animator.imagePreviewViewController?.view
            
            if style == .fade {
                previewView?.alpha = isPresenting ? 0 : 1
            } else if style == .zoom {
                var contentViewFrame = previewView?.convert(zoomImageView.contentViewRect, from: nil) ?? .zero
                var contentViewCenterInZoomImageView = CGPoint(x: zoomImageView.contentViewRect.midX, y: zoomImageView.contentViewRect.midY)
                if CGRectIsEmpty(contentViewFrame) {
                    // 有可能 start preview 时图片还在 loading，此时拿到的 content rect 是 zero，所以做个保护
                    contentViewFrame = previewView?.convert(zoomImageView.frame, from: zoomImageView.superview) ?? .zero
                    contentViewCenterInZoomImageView = CGPoint(x: contentViewFrame.midX, y: contentViewFrame.midY)
                }
                // 注意不是 zoomImageView 的 center，而是 zoomImageView 这个容器里的中心点
                let centerInZoomImageView = CGPoint(x: zoomImageView.bounds.midX, y: zoomImageView.bounds.midY)
                let horizontalRatio = sourceImageRect.width / contentViewFrame.width
                let verticalRatio = sourceImageRect.height / contentViewFrame.height
                let finalRatio = max(horizontalRatio, verticalRatio)
                
                var fromTransform = CGAffineTransform.identity
                var toTransform = CGAffineTransform.identity
                var transform = CGAffineTransform.identity
                
                // 先缩再移
                transform = transform.scaledBy(x: finalRatio, y: finalRatio)
                let contentViewCenterAfterScale = CGPoint(x: centerInZoomImageView.x + (contentViewCenterInZoomImageView.x - centerInZoomImageView.x) * finalRatio, y: centerInZoomImageView.y + (contentViewCenterInZoomImageView.y - centerInZoomImageView.y) * finalRatio)
                let translationAfterScale = CGSize(width: sourceImageRect.midX - contentViewCenterAfterScale.x, height: sourceImageRect.midY - contentViewCenterAfterScale.y)
                transform = transform.concatenating(CGAffineTransform(translationX: translationAfterScale.width, y: translationAfterScale.height))
                
                if isPresenting {
                    fromTransform = transform
                } else {
                    toTransform = transform
                }
                
                var maskFromBounds = zoomImageView.contentView?.bounds ?? .zero
                var maskToBounds = zoomImageView.contentView?.bounds ?? .zero
                var maskBounds = maskFromBounds
                let maskHorizontalRatio = sourceImageRect.width / maskBounds.width
                let maskVerticalRatio = sourceImageRect.height / maskBounds.height
                let maskFinalRatio = max(maskHorizontalRatio, maskVerticalRatio)
                maskBounds = CGRect(x: 0, y: 0, width: sourceImageRect.width / maskFinalRatio, height: sourceImageRect.height / maskFinalRatio)
                if isPresenting {
                    maskFromBounds = maskBounds
                } else {
                    maskToBounds = maskBounds
                }
                
                let sourceImageIndex = animator.imagePreviewViewController?.imagePreviewView.currentImageIndex ?? 0
                var cornerRadius = max(animator.imagePreviewViewController?.sourceImageCornerRadius ?? 0, 0)
                if (animator.imagePreviewViewController?.sourceImageCornerRadius ?? 0) < 0,
                   let sourceImageView = animator.imagePreviewViewController?.sourceImageView?(sourceImageIndex) as? UIView {
                    cornerRadius = sourceImageView.layer.cornerRadius
                }
                cornerRadius = cornerRadius / maskFinalRatio
                let fromCornerRadius = isPresenting ? cornerRadius : 0
                let toCornerRadius = isPresenting ? 0 : cornerRadius
                
                let cornerRadiusAnimation = CABasicAnimation(keyPath: "cornerRadius")
                cornerRadiusAnimation.fromValue = NSNumber(value: fromCornerRadius)
                cornerRadiusAnimation.toValue = NSNumber(value: toCornerRadius)
                
                let boundsAnimation = CABasicAnimation(keyPath: "bounds")
                boundsAnimation.fromValue = NSValue(cgRect: CGRect(x: 0, y: 0, width: maskFromBounds.size.width, height: maskFromBounds.size.height))
                boundsAnimation.toValue = NSValue(cgRect: CGRect(x: 0, y: 0, width: maskToBounds.size.width, height: maskToBounds.size.height))
                
                let maskAnimation = CAAnimationGroup()
                maskAnimation.duration = animator.duration
                maskAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                maskAnimation.fillMode = .forwards
                // remove 都交给 UIView Block 的 completion 里做，这里是为了避免 Core Animation 和 UIView Animation Block 时间不一致导致的值变动
                maskAnimation.isRemovedOnCompletion = false
                maskAnimation.animations = [cornerRadiusAnimation, boundsAnimation]
                // 不管怎样，mask 都是居中的
                animator.cornerRadiusMaskLayer.position = CGPoint(x: zoomImageView.contentView?.bounds.midX ?? .zero, y: zoomImageView.contentView?.bounds.midY ?? .zero)
                zoomImageView.contentView?.layer.mask = animator.cornerRadiusMaskLayer
                animator.cornerRadiusMaskLayer.add(maskAnimation, forKey: "maskAnimation")
                
                // 动画开始，当 contentView 被放大后，如果不去掉 clipToBounds，那么退出预览时，contentView 溢出的那部分内容就看不到
                zoomImageView.scrollView.clipsToBounds = false
                if isPresenting {
                    zoomImageView.transform = fromTransform
                    previewView?.backgroundColor = UIColor.clear
                }
                
                // 发现 zoomImageView.transform 用 UIView Animation Block 实现的话，手势拖拽 dismissing 的情况下，松手时会瞬间跳动到某个位置，然后才继续做动画，改为 Core Animation 就没这个问题
                let transformAnimation = CABasicAnimation(keyPath: "transform")
                transformAnimation.toValue = NSValue(caTransform3D: CATransform3DMakeAffineTransform(toTransform))
                transformAnimation.duration = animator.duration
                transformAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                transformAnimation.fillMode = .forwards
                // remove 都交给 UIView Block 的 completion 里做，这里是为了避免 Core Animation 和 UIView Animation Block 时间不一致导致的值变动
                transformAnimation.isRemovedOnCompletion = false
                zoomImageView.layer.add(transformAnimation, forKey: "transformAnimation")
            }
        }
        
        self.animationBlock = { animator, isPresenting, style, sourceImageRect, zoomImageView, transitionContext in
            if style == .fade {
                animator.imagePreviewViewController?.view.alpha = isPresenting ? 1 : 0
            } else if style == .zoom {
                animator.imagePreviewViewController?.view.backgroundColor = isPresenting ? animator.imagePreviewViewController?.backgroundColor : UIColor.clear
            }
        }

        self.animationCompletionBlock = { animator, isPresenting, style, sourceImageRect, zoomImageView, transitionContext in
            // fade清理，由于支持 zoom presenting 和 fade dismissing 搭配使用，所以这里不管是哪种 style 都要做相同的清理工作
            animator.imagePreviewViewController?.view.alpha = 1
            
            // zoom清理
            animator.cornerRadiusMaskLayer.removeAnimation(forKey: "maskAnimation")
            zoomImageView.scrollView.clipsToBounds = true
            zoomImageView.contentView?.layer.mask = nil
            zoomImageView.transform = .identity
            zoomImageView.layer.removeAnimation(forKey: "transformAnimation")
        }
    }
    
    // MARK: - UIViewControllerAnimatedTransitioning
    open func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let imagePreviewViewController = self.imagePreviewViewController else { return }
        
        let fromViewController = transitionContext.viewController(forKey: .from)
        let toViewController = transitionContext.viewController(forKey: .to)
        let isPresenting = fromViewController?.presentedViewController == toViewController
        let presentingViewController = isPresenting ? fromViewController : toViewController
        // 触发背后界面的生命周期，从而配合屏幕旋转那边做一些强制旋转的操作
        let shouldAppearanceTransitionManually = imagePreviewViewController.modalPresentationStyle != .fullScreen
        
        var style: ImagePreviewTransitioningStyle = isPresenting ? imagePreviewViewController.presentingStyle : imagePreviewViewController.dismissingStyle
        var sourceImageRect = CGRect.zero
        let currentImageIndex = imagePreviewViewController.imagePreviewView.currentImageIndex
        if style == .zoom {
            if let sourceImageRectBlock = imagePreviewViewController.sourceImageRect {
                sourceImageRect = imagePreviewViewController.view.convert(sourceImageRectBlock(currentImageIndex), from: nil)
            } else if let sourceImageViewBlock = imagePreviewViewController.sourceImageView {
                let sourceImageView = sourceImageViewBlock(currentImageIndex)
                if let view = sourceImageView as? UIView {
                    sourceImageRect = imagePreviewViewController.view.convert(view.frame, from: view.superview)
                } else if let value = sourceImageView as? NSValue {
                    sourceImageRect = imagePreviewViewController.view.convert(value.cgRectValue, from: nil)
                }
            }
        }
        // zoom 类型一定需要有个非 zero 的 sourceImageRect，否则不知道动画的起点/终点，所以当不存在 sourceImageRect 时强制改为用 fade 动画
        style = style == .zoom && sourceImageRect.equalTo(CGRect.zero) ? .fade : style
        
        let containerView = transitionContext.containerView
        // present 时 toViewController 还没走到 viewDidLayoutSubviews，此时做动画可能得到不正确的布局，所以强制布局一次
        let fromView = transitionContext.view(forKey: .from)
        fromView?.setNeedsLayout()
        fromView?.layoutIfNeeded()
        let toView = transitionContext.view(forKey: .to)
        toView?.setNeedsLayout()
        toView?.layoutIfNeeded()
        let zoomImageView = imagePreviewViewController.imagePreviewView.zoomImageView(at: currentImageIndex)
        
        toView?.frame = containerView.bounds
        if isPresenting {
            if let toView = toView {
                containerView.addSubview(toView)
            }
            if shouldAppearanceTransitionManually {
                presentingViewController?.beginAppearanceTransition(false, animated: true)
            }
        } else {
            if let fromView = fromView, let toView = toView {
                containerView.insertSubview(toView, belowSubview: fromView)
            }
            presentingViewController?.beginAppearanceTransition(true, animated: true)
        }
        
        if let zoomImageView = zoomImageView {
            animationEnteringBlock?(self, isPresenting, style, sourceImageRect, zoomImageView, transitionContext)
        }
        animationCallbackBlock?(self, isPresenting, false)
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
            if let zoomImageView = zoomImageView {
                self.animationBlock?(self, isPresenting, style, sourceImageRect, zoomImageView, transitionContext)
            }
        }) { finished in
            presentingViewController?.endAppearanceTransition()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            if let zoomImageView = zoomImageView {
                self.animationCompletionBlock?(self, isPresenting, style, sourceImageRect, zoomImageView, transitionContext)
            }
            self.animationCallbackBlock?(self, isPresenting, true)
        }
    }
    
    open func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
}

// MARK: - CollectionViewPagingLayout
/// 分页横向滚动布局样式枚举
public enum CollectionViewPagingLayoutStyle: Int {
    /// 普通模式，水平滑动
    case `default`
    /// 缩放模式，两边的item会小一点，逐渐向中间放大
    case scale
}

/// 支持按页横向滚动的 UICollectionViewLayout，可切换不同类型的滚动动画。
///
/// item 的大小和布局仅支持通过 UICollectionViewFlowLayout 的 property 系列属性修改，也即每个 item 都应相等。对于通过 delegate 方式返回各不相同的 itemSize、sectionInset 的场景是不支持的。
open class CollectionViewPagingLayout: UICollectionViewFlowLayout {
    
    /// 当前布局样式
    open private(set) var style: CollectionViewPagingLayoutStyle = .default
    
    /// 规定超过这个滚动速度就强制翻页，从而使翻页更容易触发。默认为 0.4
    open var velocityForEnsurePageDown: CGFloat = 0.4
    
    /// 是否支持一次滑动可以滚动多个 item，默认为 YES
    open var allowsMultipleItemScroll = true
    
    /// 规定了当支持一次滑动允许滚动多个 item 的时候，滑动速度要达到多少才会滚动多个 item，默认为 2.5
    ///
    /// 仅当 allowsMultipleItemScroll 为 YES 时生效
    open var multipleItemScrollVelocityLimit: CGFloat = 2.5
    
    /// 当前 cell 的百分之多少滚过临界点时就会触发滚到下一张的动作，默认为 .666，也即超过 2/3 即会滚到下一张。
    /// 对应地，触发滚到上一张的临界点将会被设置为 (1 - pagingThreshold)
    open var pagingThreshold: CGFloat = 2.0 / 3.0
    
    /// 中间那张卡片基于初始大小的缩放倍数，默认为 1.0
    open var maximumScale: CGFloat = 1.0
    
    /// 除了中间之外的其他卡片基于初始大小的缩放倍数，默认为 0.94
    open var minimumScale: CGFloat = 0.94
    
    private var finalItemSize: CGSize = .zero
    
    public init(style: CollectionViewPagingLayoutStyle) {
        super.init()
        self.style = style
        
        didInitialize()
    }
    
    public override init() {
        super.init()
        
        didInitialize()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        didInitialize()
    }
    
    private func didInitialize() {
        minimumInteritemSpacing = 0
        scrollDirection = .horizontal
    }
    
    open override func prepare() {
        super.prepare()
        var itemSize = self.itemSize
        if let collectionView = self.collectionView,
           let layoutDelegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
           let layoutSize = layoutDelegate.collectionView?(collectionView, layout: self, sizeForItemAt: IndexPath(item: 0, section: 0)) {
            itemSize = layoutSize
        }
        self.finalItemSize = itemSize
    }
    
    open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if style == .scale {
            return true
        }
        return !CGSizeEqualToSize(collectionView?.bounds.size ?? .zero, newBounds.size)
    }
    
    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        if style == .default {
            return super.layoutAttributesForElements(in: rect)
        }
        
        let resultAttributes = NSArray(array: super.layoutAttributesForElements(in: rect) ?? [], copyItems: true) as? [UICollectionViewLayoutAttributes] ?? []
        let offset = collectionView?.bounds.midX ?? .zero
        let itemSize = finalItemSize
        
        if style == .scale {
            let distanceForMinimumScale = itemSize.width + minimumLineSpacing
            let distanceForMaximumScale: CGFloat = 0.0
            
            for attributes in resultAttributes {
                var scale: CGFloat = 0
                let distance = abs(offset - attributes.center.x)
                if distance >= distanceForMinimumScale {
                    scale = self.minimumScale
                } else if distance == distanceForMaximumScale {
                    scale = self.maximumScale
                } else {
                    scale = self.minimumScale + (distanceForMinimumScale - distance) * (self.maximumScale - self.minimumScale) / (distanceForMinimumScale - distanceForMaximumScale)
                }
                attributes.transform3D = CATransform3DMakeScale(scale, scale, 1)
                attributes.zIndex = 1
            }
            return resultAttributes
        }
        
        return resultAttributes
    }
    
    open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else {
            return proposedContentOffset
        }
        
        let itemSpacing = (scrollDirection == .horizontal ? finalItemSize.width : finalItemSize.height) + minimumLineSpacing
        let contentSize = collectionViewContentSize
        let frameSize = collectionView.bounds.size
        let contentInset = collectionView.adjustedContentInset
        
        // 代表 collectionView 期望的实际滚动方向是向右，但不代表手指拖拽的方向是向右，因为有可能此时已经在左边的尽头，继续往右拖拽，松手的瞬间由于回弹，这里会判断为是想向左滚动，但其实你的手指是向右拖拽
        let scrollingToRight = proposedContentOffset.x < collectionView.contentOffset.x
        let scrollingToBottom = proposedContentOffset.y < collectionView.contentOffset.y
        var forcePaging = false
        let translation = collectionView.panGestureRecognizer.translation(in: collectionView)
        var proposedContentOffset = proposedContentOffset
        
        if scrollDirection == .vertical {
            if !allowsMultipleItemScroll || abs(velocity.y) <= abs(multipleItemScrollVelocityLimit) {
                // 一次性滚多次的本质是系统根据速度算出来的 proposedContentOffset 可能比当前 contentOffset 大很多，所以这里既然限制了一次只能滚一页，那就直接取瞬时 contentOffset 即可。
                proposedContentOffset = collectionView.contentOffset
                
                // 只支持滚动一页 或者 支持滚动多页但是速度不够滚动多页，时，允许强制滚动
                if abs(velocity.y) > velocityForEnsurePageDown {
                    forcePaging = true
                }
            }
            
            // 最顶/最底
            if proposedContentOffset.y < -contentInset.top || proposedContentOffset.y >= contentSize.height + contentInset.bottom - frameSize.height {
                // iOS 10 及以上的版本，直接返回当前的 contentOffset，系统会自动帮你调整到边界状态，而 iOS 9 及以下的版本需要自己计算
                return proposedContentOffset
            }
            
            // 因为第一个 item 初始状态中心点离 contentOffset.y 有半个 item 的距离
            let progress = ((contentInset.top + proposedContentOffset.y) + finalItemSize.height / 2) / itemSpacing
            let currentIndex = Int(progress)
            var targetIndex = currentIndex
            // 加上下面这两个额外的 if 判断是为了避免那种“从0滚到1的左边 1/3，松手后反而会滚回0”的 bug
            if translation.y < 0 && abs(translation.y) > finalItemSize.height / 2 + minimumLineSpacing {
            } else if translation.y > 0 && abs(translation.y) > finalItemSize.height / 2 {
            } else {
                let remainder = progress - CGFloat(currentIndex)
                let offset = remainder * itemSpacing
                let shouldNext = (forcePaging || (offset / finalItemSize.height >= pagingThreshold)) && !scrollingToBottom && velocity.y > 0
                let shouldPrev = (forcePaging || (offset / finalItemSize.height <= 1 - pagingThreshold)) && scrollingToBottom && velocity.y < 0
                targetIndex = currentIndex + (shouldNext ? 1 : (shouldPrev ? -1 : 0))
            }
            
            proposedContentOffset.y = -contentInset.top + CGFloat(targetIndex) * itemSpacing
        } else if scrollDirection == .horizontal {
            if !allowsMultipleItemScroll || abs(velocity.x) <= abs(multipleItemScrollVelocityLimit) {
                // 一次性滚多次的本质是系统根据速度算出来的 proposedContentOffset 可能比当前 contentOffset 大很多，所以这里既然限制了一次只能滚一页，那就直接取瞬时 contentOffset 即可。
                proposedContentOffset = collectionView.contentOffset
                
                // 只支持滚动一页 或者 支持滚动多页但是速度不够滚动多页，时，允许强制滚动
                if abs(velocity.x) > velocityForEnsurePageDown {
                    forcePaging = true
                }
            }
            
            // 最左/最右
            if proposedContentOffset.x < -contentInset.left || proposedContentOffset.x >= contentSize.width + contentInset.right - frameSize.width {
                // iOS 10 及以上的版本，直接返回当前的 contentOffset，系统会自动帮你调整到边界状态，而 iOS 9 及以下的版本需要自己计算
                return proposedContentOffset
            }
            
            // 因为第一个 item 初始状态中心点离 contentOffset.x 有半个 item 的距离
            let progress = ((contentInset.left + proposedContentOffset.x) + finalItemSize.width / 2) / itemSpacing
            let currentIndex = Int(progress)
            var targetIndex = currentIndex
            // 加上下面这两个额外的 if 判断是为了避免那种“从0滚到1的左边 1/3，松手后反而会滚回0”的 bug
            if translation.x < 0 && abs(translation.x) > finalItemSize.width / 2 + minimumLineSpacing {
            } else if translation.x > 0 && abs(translation.x) > finalItemSize.width / 2 {
            } else {
                let remainder = progress - CGFloat(currentIndex)
                let offset = remainder * itemSpacing
                // collectionView 关闭了 bounces 后，如果在第一页向左边快速滑动一段距离，并不会触发上一个「最左/最右」的判断（因为 proposedContentOffset 不够），此时的 velocity 为负数，所以要加上 velocity.x > 0 的判断，否则这种情况会命中 forcePaging && !scrollingToRight 这两个条件，当做下一页处理。
                let shouldNext = (forcePaging || (offset / finalItemSize.width >= pagingThreshold)) && !scrollingToRight && velocity.x > 0
                let shouldPrev = (forcePaging || (offset / finalItemSize.width <= 1 - pagingThreshold)) && scrollingToRight && velocity.x < 0
                targetIndex = currentIndex + (shouldNext ? 1 : (shouldPrev ? -1 : 0))
            }
            
            proposedContentOffset.x = -contentInset.left + CGFloat(targetIndex) * itemSpacing
        }
        
        return proposedContentOffset
    }
    
}
