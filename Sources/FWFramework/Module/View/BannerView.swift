//
//  BannerView.swift
//  FWFramework
//
//  Created by wuyong on 2023/5/19.
//

import UIKit

// MARK: - BannerView
/// BannerView分页控件对齐方式枚举
public enum BannerViewPageControlAlignment: Int, Sendable {
    /// 右对齐
    case right
    /// 居中对齐
    case center
}

/// BannerView分页控件样式枚举
public enum BannerViewPageControlStyle: Int, Sendable {
    /// 系统样式
    case system
    /// 自定义样式，可设置图片等
    case custom
    /// 不显示
    case none
}

/// Banner视图事件代理
@MainActor @objc public protocol BannerViewDelegate {
    /// 选中指定index
    @objc optional func bannerView(_ bannerView: BannerView, didSelectItemAt index: Int)
    /// 监听bannerView滚动，快速滚动时也会回调
    @objc optional func bannerView(_ bannerView: BannerView, didScrollToItemAt index: Int)
    /// 如果你需要自定义UICollectionViewCell样式，请实现此代理方法，默认的BannerViewCell也会调用
    @objc optional func bannerView(_ bannerView: BannerView, customCell: UICollectionViewCell, for index: Int)
    /// 如果你需要自定义UICollectionViewCell样式，请实现此代理方法返回你的自定义UICollectionViewCell的class
    @objc optional func customCellClass(bannerView: BannerView) -> UICollectionViewCell.Type?
    /// 如果你需要自定义UICollectionViewCell样式，请实现此代理方法返回你的自定义UICollectionViewCell的Nib
    @objc optional func customCellNib(bannerView: BannerView) -> UINib?
}

/// Banner视图
///
/// [SDCycleScrollView](https://github.com/gsdios/SDCycleScrollView)
open class BannerView: UIView, UICollectionViewDataSource, UICollectionViewDelegate {
    private actor Configuration {
        static var trackClickBlock: (@MainActor (UIView, IndexPath?) -> Bool)?
        static var trackExposureBlock: (@MainActor (UIView) -> Void)?
    }

    // MARK: - Track
    // 框架内部统计点击和曝光扩展钩子句柄
    @_spi(FW) public nonisolated static var trackClickBlock: (@MainActor (UIView, IndexPath?) -> Bool)? {
        get { Configuration.trackClickBlock }
        set { Configuration.trackClickBlock = newValue }
    }

    @_spi(FW) public nonisolated static var trackExposureBlock: (@MainActor (UIView) -> Void)? {
        get { Configuration.trackExposureBlock }
        set { Configuration.trackExposureBlock = newValue }
    }

    // MARK: - Accessor
    /// 图片数组，支持String|URL|UIImage
    open var imagesGroup: [Any]? {
        didSet {
            var imagePaths: [Any] = []
            for obj in imagesGroup ?? [] {
                if obj is String || obj is UIImage {
                    imagePaths.append(obj)
                } else if let url = obj as? URL {
                    imagePaths.append(url.absoluteString)
                }
            }
            imagePathsGroup = imagePaths
        }
    }

    /// 每张图片对应要显示的文字数组
    open var titlesGroup: [Any]? {
        didSet {
            if onlyDisplayText {
                var images: [Any] = []
                for _ in 0..<(titlesGroup?.count ?? 0) {
                    images.append("")
                }
                imagesGroup = images
            }
        }
    }

    /// 自动滚动间隔时间,默认2s
    open var autoScrollTimeInterval: TimeInterval = 2.0 {
        didSet {
            let shouldScroll = autoScroll
            autoScroll = shouldScroll
        }
    }

    /// 是否无限循环，默认true
    open var infiniteLoop: Bool = true {
        didSet {
            if imagePathsGroup.count > 0 {
                let imagesGroup = imagePathsGroup
                imagePathsGroup = imagesGroup
            }
        }
    }

    /// 是否自动滚动，默认true
    open var autoScroll: Bool = true {
        didSet {
            invalidateTimer()

            if autoScroll {
                setupTimer()
            }
        }
    }

    /// 图片滚动方向，默认为水平滚动
    open var scrollDirection: UICollectionView.ScrollDirection = .horizontal {
        didSet {
            flowLayout.scrollDirection = scrollDirection
        }
    }

    /// 是否启用根据item分页滚动，默认false，根据frame大小滚动
    open var itemPagingEnabled: Bool = false {
        didSet {
            if itemPagingEnabled {
                mainView.isPagingEnabled = false
                mainView.decelerationRate = .fast
                flowLayout.isPagingEnabled = true

                // 兼容自动布局，避免mainView的frame为0
                if mainView.bounds.size.equalTo(.zero) {
                    setNeedsLayout()
                    layoutIfNeeded()
                }
            } else {
                mainView.isPagingEnabled = true
                flowLayout.isPagingEnabled = false
            }
        }
    }

    /// 整体布局尺寸，默认0占满视图，itemPagingEnabled启用后生效
    open var itemSize: CGSize = .zero {
        didSet {
            flowLayout.itemSize = itemSize
            itemPagingEnabled = true
        }
    }

    /// 整体布局间隔，默认0，itemPagingEnabled启用后生效
    open var itemSpacing: CGFloat = .zero {
        didSet {
            flowLayout.minimumLineSpacing = itemSpacing
            itemPagingEnabled = true
        }
    }

    /// 是否设置item分页停留位置居中，默认false，停留左侧，itemPagingEnabled启用后生效
    open var itemPagingCenter: Bool = false {
        didSet {
            flowLayout.isPagingCenter = itemPagingCenter
            itemPagingEnabled = true
        }
    }

    /// 事件代理
    open weak var delegate: BannerViewDelegate? {
        didSet {
            if let cellClass = delegate?.customCellClass?(bannerView: self) {
                mainView.register(cellClass, forCellWithReuseIdentifier: bannerViewCellID)
            } else if let cellNib = delegate?.customCellNib?(bannerView: self) {
                mainView.register(cellNib, forCellWithReuseIdentifier: bannerViewCellID)
            }
        }
    }

    /// 句柄方式监听点击，参数为index
    open var didSelectItemBlock: ((Int) -> Void)?

    /// 句柄方式监听滚动，快速滚动时也会回调，参数为index
    open var didScrollToItemBlock: ((Int) -> Void)?

    /// 自定义cell句柄，参数为cell和index
    open var customCellBlock: ((UICollectionViewCell, Int) -> Void)?

    /// 轮播图片的ContentMode，默认为scaleAspectFill
    open var imageViewContentMode: UIView.ContentMode = .scaleAspectFill

    /// 占位图，用于网络未加载到图片时
    open var placeholderImage: UIImage?

    /// 是否显示分页控件
    open var showsPageControl: Bool = true {
        didSet {
            pageControl?.isHidden = !showsPageControl
        }
    }

    /// 自定义pageControl控件，初始化后调用
    open var customPageControl: ((UIControl) -> Void)?

    /// 是否在只有一张图时隐藏pagecontrol，默认为true
    open var hidesForSinglePage: Bool = true

    /// 只展示文字轮播
    open var onlyDisplayText: Bool = false

    /// pageControl 样式，默认为系统样式
    open var pageControlStyle: BannerViewPageControlStyle = .system

    /// 分页控件位置
    open var pageControlAlignment: BannerViewPageControlAlignment = .center

    /// 分页控件距离轮播图的底部间距（在默认间距基础上）的偏移量
    open var pageControlBottomOffset: CGFloat = .zero

    /// 分页控件距离轮播图的右边间距（在默认间距基础上）的偏移量
    open var pageControlRightOffset: CGFloat = .zero

    /// 分页控件小圆标大小
    open var pageControlDotSize: CGSize = .init(width: 10, height: 10) {
        didSet {
            if let pageControl = pageControl as? PageControl {
                pageControl.dotSize = pageControlDotSize
            }
        }
    }

    /// 分页控件当前小圆标大小，默认zero同pageControlDotSize
    open var pageControlCurrentDotSize: CGSize = .zero {
        didSet {
            if let pageControl = pageControl as? PageControl {
                pageControl.currentDotSize = pageControlCurrentDotSize
            }
        }
    }

    /// 分页控件小圆标间隔
    open var pageControlDotSpacing: CGFloat = -1 {
        didSet {
            if let pageControl = pageControl as? PageControl {
                pageControl.spacingBetweenDots = pageControlDotSpacing
            }
        }
    }

    /// 当前分页控件小圆标颜色
    open var currentPageDotColor: UIColor? = .white {
        didSet {
            if let pageControl = pageControl as? PageControl {
                pageControl.currentDotColor = currentPageDotColor
            } else if let pageControl = pageControl as? UIPageControl {
                pageControl.currentPageIndicatorTintColor = currentPageDotColor
            }
        }
    }

    /// 其他分页控件小圆标颜色
    open var pageDotColor: UIColor? = .white.withAlphaComponent(0.5) {
        didSet {
            if let pageControl = pageControl as? PageControl {
                pageControl.dotColor = pageDotColor
            } else if let pageControl = pageControl as? UIPageControl {
                pageControl.pageIndicatorTintColor = pageDotColor
            }
        }
    }

    /// 当前分页控件小圆标图片
    open var currentPageDotImage: UIImage? {
        didSet {
            if pageControlStyle != .custom {
                pageControlStyle = .custom
            }

            if let pageControl = pageControl as? PageControl,
               let image = currentPageDotImage {
                pageControl.currentDotImage = image
            }
        }
    }

    /// 其他分页控件小圆标图片
    open var pageDotImage: UIImage? {
        didSet {
            if pageControlStyle != .custom {
                pageControlStyle = .custom
            }

            if let pageControl = pageControl as? PageControl,
               let image = pageDotImage {
                pageControl.dotImage = image
            }
        }
    }

    /// 分页控件自定义视图类，默认为DotView
    open var pageDotViewClass: (UIView & DotViewProtocol).Type? = DotView.self {
        didSet {
            if pageControlStyle != .custom {
                pageControlStyle = .custom
            }

            if let pageControl = pageControl as? PageControl {
                pageControl.dotViewClass = pageDotViewClass
            }
        }
    }

    /// 轮播文字label字体颜色
    open var titleLabelTextColor: UIColor? = .white

    /// 轮播文字label字体
    open var titleLabelTextFont: UIFont? = .systemFont(ofSize: 14)

    /// 轮播文字label背景颜色
    open var titleLabelBackgroundColor: UIColor? = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)

    /// 轮播文字label高度
    open var titleLabelHeight: CGFloat = 30

    /// 轮播文字间距设置(影响背景)，默认全部0
    open var titleLabelInset: UIEdgeInsets = .zero

    /// 轮播文字内容间距设置(不影响背景)，默认{0 16 0 16}
    open var titleLabelContentInset: UIEdgeInsets = .init(top: 0, left: 16, bottom: 0, right: 16)

    /// 轮播文字label对齐方式
    open var titleLabelTextAlignment: NSTextAlignment = .left

    /// 图片视图间距设置，默认全部0
    open var imageViewInset: UIEdgeInsets = .zero

    /// 内容视图间距设置，默认全部0
    open var contentViewInset: UIEdgeInsets = .zero

    /// 内容视图圆角设置，默认0
    open var contentViewCornerRadius: CGFloat = .zero

    /// 内容视图背景色，默认nil
    open var contentViewBackgroundColor: UIColor?

    /// 当前index，默认-1
    open private(set) var currentIndex: Int = -1

    private var imagePathsGroup: [Any] = [] {
        didSet {
            invalidateTimer()

            totalItemsCount = infiniteLoop && imagePathsGroup.count > 1 ? imagePathsGroup.count * 100 : imagePathsGroup.count

            if imagePathsGroup.count > 1 {
                mainView.isScrollEnabled = true
                let shouldScroll = autoScroll
                autoScroll = shouldScroll
            } else {
                mainView.isScrollEnabled = false
                invalidateTimer()
            }

            setupPageControl()
            mainView.reloadData()
        }
    }

    private var totalItemsCount: Int = 0

    private var timer: Timer?

    // MARK: - Subviews
    open private(set) lazy var mainView: UICollectionView = {
        let result = UICollectionView(frame: bounds, collectionViewLayout: flowLayout)
        result.backgroundColor = .clear
        result.isPagingEnabled = true
        result.showsHorizontalScrollIndicator = false
        result.showsVerticalScrollIndicator = false
        result.contentInsetAdjustmentBehavior = .never
        result.dataSource = self
        result.delegate = self
        result.scrollsToTop = false
        result.register(BannerViewCell.self, forCellWithReuseIdentifier: bannerViewCellID)
        return result
    }()

    open private(set) lazy var flowLayout: BannerViewFlowLayout = {
        let result = BannerViewFlowLayout()
        result.minimumLineSpacing = 0
        result.scrollDirection = .horizontal
        return result
    }()

    open private(set) weak var pageControl: UIControl?

    private let bannerViewCellID = "BannerViewCell"

    // MARK: - Lifecycle
    override public init(frame: CGRect) {
        super.init(frame: frame)

        setupMainView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        setupMainView()
    }

    private func setupMainView() {
        backgroundColor = .clear

        addSubview(mainView)
        mainView.fw.pinEdges(autoScale: false)
    }

    override open func layoutSubviews() {
        let currentDelegate = delegate
        delegate = currentDelegate
        super.layoutSubviews()

        if itemSize.equalTo(.zero) {
            if flowLayout.scrollDirection == .horizontal {
                flowLayout.itemSize = CGSize(width: frame.size.width - flowLayout.minimumLineSpacing * 2, height: frame.size.height)
            } else {
                flowLayout.itemSize = CGSize(width: frame.size.width, height: frame.size.height - flowLayout.minimumLineSpacing * 2)
            }
        }

        mainView.frame = bounds
        let needScroll = (flowLayout.scrollDirection == .horizontal) ? mainView.contentOffset.x <= 0 : mainView.contentOffset.y <= 0
        if needScroll && totalItemsCount > 0 {
            let targetIndex: Int = infiniteLoop ? (totalItemsCount / 2) : 0
            flowLayout.scrollToPage(targetIndex, animated: false)
        }

        var size: CGSize = .zero
        if let pageControl = pageControl as? PageControl {
            if !(pageDotImage != nil && currentPageDotImage != nil && pageControlDotSize.equalTo(CGSize(width: 10, height: 10))) {
                pageControl.dotSize = pageControlDotSize
                pageControl.currentDotSize = pageControlCurrentDotSize
            }
            size = pageControl.sizeForNumberOfPages(imagePathsGroup.count)
        } else {
            size = CGSize(width: CGFloat(imagePathsGroup.count) * pageControlDotSize.width * 1.5, height: pageControlDotSize.height)
            // ios14 需要按照系统规则适配pageControl size
            if #available(iOS 14.0, *) {
                if let pageControl = pageControl as? UIPageControl {
                    size.width = pageControl.size(forNumberOfPages: imagePathsGroup.count).width
                }
            }
        }
        var x = (frame.size.width - size.width) * 0.5
        if pageControlAlignment == .right {
            x = mainView.frame.size.width - size.width - 10
        }
        let y = mainView.frame.size.height - size.height - 10

        if let pageControl = pageControl as? PageControl {
            pageControl.sizeToFit()
        }

        var pageControlFrame = CGRect(x: x, y: y, width: size.width, height: size.height)
        pageControlFrame.origin.y -= pageControlBottomOffset
        pageControlFrame.origin.x -= pageControlRightOffset
        pageControl?.frame = pageControlFrame
        pageControl?.isHidden = !showsPageControl
    }

    // 解决当父View释放时，当前视图因为被Timer强引用而不能释放的问题
    override open func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)

        if newSuperview == nil {
            invalidateTimer()
        }
    }

    // MARK: - UICollectionView
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        totalItemsCount
    }

    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: bannerViewCellID, for: indexPath)
        let itemIndex = pageControlIndex(cellIndex: indexPath.item)

        if delegate?.customCellClass?(bannerView: self) != nil {
            delegate?.bannerView?(self, customCell: cell, for: itemIndex)
            customCellBlock?(cell, itemIndex)
            return cell
        } else if delegate?.customCellNib?(bannerView: self) != nil {
            delegate?.bannerView?(self, customCell: cell, for: itemIndex)
            customCellBlock?(cell, itemIndex)
            return cell
        }

        guard let cell = cell as? BannerViewCell else { return cell }
        let imagePath = imagePathsGroup[itemIndex]
        if !onlyDisplayText, let imagePath = imagePath as? String {
            if imagePath.lowercased().hasPrefix("http") ||
                imagePath.lowercased().hasPrefix("data:") {
                cell.imageView.fw.setImage(url: imagePath, placeholderImage: placeholderImage)
            } else {
                let image = UIImage.fw.imageNamed(imagePath)
                cell.imageView.image = image ?? placeholderImage
            }
        } else if !onlyDisplayText, let imagePath = imagePath as? UIImage {
            cell.imageView.image = imagePath
        }

        if !cell.hasConfigured {
            cell.titleLabelBackgroundColor = titleLabelBackgroundColor
            cell.titleLabelHeight = titleLabelHeight
            cell.titleLabelTextAlignment = titleLabelTextAlignment
            cell.titleLabelTextColor = titleLabelTextColor
            cell.titleLabelTextFont = titleLabelTextFont
            cell.titleLabelInset = titleLabelInset
            cell.titleLabelContentInset = titleLabelContentInset
            cell.contentViewInset = contentViewInset
            cell.contentViewCornerRadius = contentViewCornerRadius
            cell.contentViewBackgroundColor = contentViewBackgroundColor
            cell.imageViewInset = imageViewInset
            cell.imageView.contentMode = imageViewContentMode
            cell.onlyDisplayText = onlyDisplayText
            cell.hasConfigured = true
        }

        if let titlesCount = titlesGroup?.count, titlesCount > 0, itemIndex < titlesCount {
            cell.title = titlesGroup?[itemIndex]
        }

        delegate?.bannerView?(self, customCell: cell, for: itemIndex)
        customCellBlock?(cell, itemIndex)
        return cell
    }

    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = pageControlIndex(cellIndex: indexPath.item)
        delegate?.bannerView?(self, didSelectItemAt: index)
        didSelectItemBlock?(index)

        var cellTracked = false
        if let cell = collectionView.cellForItem(at: indexPath) {
            cellTracked = BannerView.trackClickBlock?(cell, IndexPath(row: index, section: 0)) ?? false
        }
        if !cellTracked {
            cellTracked = BannerView.trackClickBlock?(self, IndexPath(row: index, section: 0)) ?? false
        }
    }

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard imagePathsGroup.count > 0 else { return }

        let itemIndex = flowLayout.currentPage ?? 0
        let indexOnPageControl = pageControlIndex(cellIndex: itemIndex)
        if let pageControl = pageControl as? PageControl {
            pageControl.currentPage = indexOnPageControl
        } else if let pageControl = pageControl as? UIPageControl {
            pageControl.currentPage = indexOnPageControl
        }
        notifyPageControlIndex(indexOnPageControl)
    }

    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if autoScroll {
            invalidateTimer()
        }
    }

    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if autoScroll {
            setupTimer()
        }
    }

    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDidEndScrollingAnimation(mainView)
    }

    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard imagePathsGroup.count > 0 else { return }

        let itemIndex = flowLayout.currentPage ?? 0
        // 快速滚动时不计曝光次数
        BannerView.trackExposureBlock?(self)

        if infiniteLoop {
            if itemIndex == totalItemsCount - 1 {
                let targetIndex: Int = totalItemsCount / 2 - 1
                flowLayout.scrollToPage(targetIndex, animated: false)
            } else if itemIndex == 0 {
                let targetIndex: Int = totalItemsCount / 2
                flowLayout.scrollToPage(targetIndex, animated: false)
            }
        }
    }

    // MARK: - Public
    /// 手工滚动到指定index，可指定动画
    open func scrollToIndex(_ index: Int, animated: Bool = false) {
        if autoScroll {
            invalidateTimer()
        }
        guard totalItemsCount > 0 else { return }

        let previousIndex = flowLayout.currentPage ?? 0
        let currentIndex: Int = totalItemsCount / 2 + index
        scrollToPageControlIndex(currentIndex, animated: animated)

        if !animated, currentIndex != previousIndex {
            BannerView.trackExposureBlock?(self)
        }

        if autoScroll {
            setupTimer()
        }
    }

    /// 滚动手势禁用（文字轮播较实用）
    open func disableScrollGesture() {
        mainView.canCancelContentTouches = false
        for gesture in mainView.gestureRecognizers ?? [] {
            if gesture is UIPanGestureRecognizer {
                mainView.removeGestureRecognizer(gesture)
            }
        }
    }

    /// 解决viewWillAppear时出现时轮播图卡在一半的问题，在控制器viewWillAppear时调用此方法
    open func adjustWhenViewWillAppear() {
        let targetIndex = flowLayout.currentPage ?? 0
        if targetIndex < totalItemsCount {
            flowLayout.scrollToPage(targetIndex, animated: false)
        }
    }

    @_spi(FW) public func pageControlIndex(cellIndex index: Int) -> Int {
        index % imagePathsGroup.count
    }

    // MARK: - Private
    private func setupTimer() {
        invalidateTimer()
        guard imagePathsGroup.count > 1 else { return }

        let timer = Timer.scheduledTimer(timeInterval: autoScrollTimeInterval, target: self, selector: #selector(automaticScroll), userInfo: nil, repeats: true)
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func setupPageControl() {
        pageControl?.removeFromSuperview()
        if imagePathsGroup.count == 0 || onlyDisplayText { return }
        if imagePathsGroup.count == 1 && hidesForSinglePage { return }

        let indexOnPageControl = pageControlIndex(cellIndex: flowLayout.currentPage ?? 0)
        switch pageControlStyle {
        case .custom:
            let pageControl = PageControl()
            pageControl.numberOfPages = imagePathsGroup.count
            pageControl.dotColor = pageDotColor
            pageControl.currentDotColor = currentPageDotColor
            pageControl.isUserInteractionEnabled = false
            pageControl.currentPage = indexOnPageControl
            pageControl.dotSize = pageControlDotSize
            pageControl.currentDotSize = pageControlCurrentDotSize
            if let dotViewClass = pageDotViewClass {
                pageControl.dotViewClass = dotViewClass
            }
            if pageControlDotSpacing >= 0 {
                pageControl.spacingBetweenDots = pageControlDotSpacing
            }
            addSubview(pageControl)
            self.pageControl = pageControl
            customPageControl?(pageControl)

        case .system:
            let pageControl = UIPageControl()
            pageControl.numberOfPages = imagePathsGroup.count
            pageControl.currentPageIndicatorTintColor = currentPageDotColor
            pageControl.pageIndicatorTintColor = pageDotColor
            pageControl.isUserInteractionEnabled = false
            pageControl.currentPage = indexOnPageControl
            pageControl.fw.preferredSize = pageControlDotSize
            addSubview(pageControl)
            self.pageControl = pageControl
            customPageControl?(pageControl)

        default:
            break
        }

        if let currentDotImage = currentPageDotImage {
            currentPageDotImage = currentDotImage
        }
        if let dotImage = pageDotImage {
            pageDotImage = dotImage
        }

        currentIndex = -1
        notifyPageControlIndex(indexOnPageControl)
    }

    private func notifyPageControlIndex(_ index: Int) {
        guard currentIndex != index else { return }

        currentIndex = index
        delegate?.bannerView?(self, didScrollToItemAt: index)
        didScrollToItemBlock?(index)
    }

    @objc private func automaticScroll() {
        guard totalItemsCount != 0 else { return }

        let targetIndex = (flowLayout.currentPage ?? 0) + 1
        scrollToPageControlIndex(targetIndex, animated: true)
    }

    private func scrollToPageControlIndex(_ targetIndex: Int, animated: Bool) {
        if targetIndex >= totalItemsCount {
            if infiniteLoop {
                flowLayout.scrollToPage(totalItemsCount / 2, animated: false)
            }
            return
        }
        flowLayout.scrollToPage(targetIndex, animated: animated)
    }
}

// MARK: - BannerViewFlowLayout
/// BannerView流式布局
open class BannerViewFlowLayout: UICollectionViewFlowLayout {
    /// 是否启用分页，默认false
    open var isPagingEnabled: Bool = false

    /// 是否分页居中，默认false
    open var isPagingCenter: Bool = false

    private var lastCollectionViewSize: CGSize = .zero
    private var lastScrollDirection: UICollectionView.ScrollDirection = .horizontal
    private var lastItemSize: CGSize = .zero

    // MARK: - Lifecycle
    override public init() {
        super.init()

        scrollDirection = .horizontal
        self.lastScrollDirection = scrollDirection
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        scrollDirection = .horizontal
        self.lastScrollDirection = scrollDirection
    }

    // MARK: - Public
    /// 获取每页宽度，必须设置itemSize
    open var pageWidth: CGFloat {
        switch scrollDirection {
        case .horizontal:
            return itemSize.width + minimumLineSpacing
        case .vertical:
            return itemSize.height + minimumLineSpacing
        default:
            return 0
        }
    }

    /// 获取当前页数，即居中cell的item
    open var currentPage: Int? {
        guard let collectionView else { return nil }
        if collectionView.frame.width == 0 || collectionView.frame.height == 0 { return nil }

        if !isPagingEnabled {
            var currentPage = 0
            if scrollDirection == .horizontal {
                currentPage = Int((collectionView.contentOffset.x + itemSize.width * 0.5) / itemSize.width)
            } else {
                currentPage = Int((collectionView.contentOffset.y + itemSize.height * 0.5) / itemSize.height)
            }
            return max(0, currentPage)
        }

        let centerPoint = CGPoint(x: collectionView.contentOffset.x + collectionView.bounds.width / 2, y: collectionView.contentOffset.y + collectionView.bounds.height / 2)
        return collectionView.indexPathForItem(at: centerPoint)?.item
    }

    /// 滚动到指定页数
    open func scrollToPage(_ index: Int, animated: Bool = true) {
        guard let collectionView else { return }

        if !isPagingEnabled {
            collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: [], animated: animated)
            return
        }

        let proposedContentOffset: CGPoint
        let shouldAnimate: Bool
        switch scrollDirection {
        case .horizontal:
            let pageOffset = CGFloat(index) * pageWidth - collectionView.contentInset.left
            proposedContentOffset = CGPoint(x: pageOffset, y: collectionView.contentOffset.y)
            shouldAnimate = abs(collectionView.contentOffset.x - pageOffset) > 1 ? animated : false
        case .vertical:
            let pageOffset = CGFloat(index) * pageWidth - collectionView.contentInset.top
            proposedContentOffset = CGPoint(x: collectionView.contentOffset.x, y: pageOffset)
            shouldAnimate = abs(collectionView.contentOffset.y - pageOffset) > 1 ? animated : false
        default:
            proposedContentOffset = .zero
            shouldAnimate = false
        }
        collectionView.setContentOffset(proposedContentOffset, animated: shouldAnimate)
    }

    // MARK: - Override
    override open func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        super.invalidateLayout(with: context)
        guard isPagingEnabled, let collectionView else { return }

        let currentCollectionViewSize = collectionView.bounds.size
        if !currentCollectionViewSize.equalTo(lastCollectionViewSize) || lastScrollDirection != scrollDirection || lastItemSize != itemSize {
            switch scrollDirection {
            case .horizontal:
                let inset = isPagingCenter ? (currentCollectionViewSize.width - itemSize.width) / 2 : minimumLineSpacing
                collectionView.contentInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
                collectionView.contentOffset = CGPoint(x: -inset, y: 0)
            case .vertical:
                let inset = isPagingCenter ? (currentCollectionViewSize.height - itemSize.height) / 2 : minimumLineSpacing
                collectionView.contentInset = UIEdgeInsets(top: inset, left: 0, bottom: inset, right: 0)
                collectionView.contentOffset = CGPoint(x: 0, y: -inset)
            default:
                collectionView.contentInset = .zero
                collectionView.contentOffset = .zero
            }

            lastCollectionViewSize = currentCollectionViewSize
            lastScrollDirection = scrollDirection
            lastItemSize = itemSize
        }
    }

    override open func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard isPagingEnabled else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }

        guard let collectionView else {
            return proposedContentOffset
        }
        let proposedRect = determineProposedRect(collectionView: collectionView, proposedContentOffset: proposedContentOffset)
        guard let layoutAttributes = layoutAttributesForElements(in: proposedRect),
              let candidateAttributesForRect = attributesForRect(collectionView: collectionView, layoutAttributes: layoutAttributes, proposedContentOffset: proposedContentOffset) else {
            return proposedContentOffset
        }

        var newOffset: CGFloat
        let offset: CGFloat
        switch scrollDirection {
        case .horizontal:
            if isPagingCenter {
                newOffset = candidateAttributesForRect.center.x - collectionView.bounds.size.width / 2
            } else {
                newOffset = candidateAttributesForRect.frame.origin.x - minimumLineSpacing
            }
            offset = newOffset - collectionView.contentOffset.x

            if (velocity.x < 0 && offset > 0) || (velocity.x > 0 && offset < 0) {
                newOffset += velocity.x > 0 ? pageWidth : -pageWidth
            }
            return CGPoint(x: newOffset, y: proposedContentOffset.y)
        case .vertical:
            if isPagingCenter {
                newOffset = candidateAttributesForRect.center.y - collectionView.bounds.size.height / 2
            } else {
                newOffset = candidateAttributesForRect.frame.origin.y - minimumLineSpacing
            }
            offset = newOffset - collectionView.contentOffset.y

            if (velocity.y < 0 && offset > 0) || (velocity.y > 0 && offset < 0) {
                newOffset += velocity.y > 0 ? pageWidth : -pageWidth
            }
            return CGPoint(x: proposedContentOffset.x, y: newOffset)
        default:
            return .zero
        }
    }

    func determineProposedRect(collectionView: UICollectionView, proposedContentOffset: CGPoint) -> CGRect {
        let size = collectionView.bounds.size
        let origin: CGPoint
        switch scrollDirection {
        case .horizontal:
            origin = CGPoint(x: proposedContentOffset.x, y: collectionView.contentOffset.y)
        case .vertical:
            origin = CGPoint(x: collectionView.contentOffset.x, y: proposedContentOffset.y)
        default:
            origin = .zero
        }
        return CGRect(origin: origin, size: size)
    }

    func attributesForRect(collectionView: UICollectionView, layoutAttributes: [UICollectionViewLayoutAttributes], proposedContentOffset: CGPoint) -> UICollectionViewLayoutAttributes? {
        var candidateAttributes: UICollectionViewLayoutAttributes?
        let proposedCenterOffset: CGFloat

        switch scrollDirection {
        case .horizontal:
            if isPagingCenter {
                proposedCenterOffset = proposedContentOffset.x + collectionView.bounds.size.width / 2
            } else {
                proposedCenterOffset = proposedContentOffset.x + minimumLineSpacing
            }
        case .vertical:
            if isPagingCenter {
                proposedCenterOffset = proposedContentOffset.y + collectionView.bounds.size.height / 2
            } else {
                proposedCenterOffset = proposedContentOffset.y + minimumLineSpacing
            }
        default:
            proposedCenterOffset = .zero
        }

        for attributes in layoutAttributes {
            guard attributes.representedElementCategory == .cell else { continue }
            guard candidateAttributes != nil else {
                candidateAttributes = attributes
                continue
            }

            switch scrollDirection {
            case .horizontal:
                if isPagingCenter {
                    if abs(attributes.center.x - proposedCenterOffset) < abs(candidateAttributes!.center.x - proposedCenterOffset) {
                        candidateAttributes = attributes
                    }
                } else {
                    if abs(attributes.frame.origin.x - proposedCenterOffset) < abs(candidateAttributes!.frame.origin.x - proposedCenterOffset) {
                        candidateAttributes = attributes
                    }
                }
            case .vertical:
                if isPagingCenter {
                    if abs(attributes.center.y - proposedCenterOffset) < abs(candidateAttributes!.center.y - proposedCenterOffset) {
                        candidateAttributes = attributes
                    }
                } else {
                    if abs(attributes.frame.origin.y - proposedCenterOffset) < abs(candidateAttributes!.frame.origin.y - proposedCenterOffset) {
                        candidateAttributes = attributes
                    }
                }
            default:
                continue
            }
        }
        return candidateAttributes
    }
}

// MARK: - BannerViewCell
/// Banner视图默认Cell
open class BannerViewCell: UICollectionViewCell {
    // MARK: - Accessor
    /// 标题，支持String|NSAttributedString
    open var title: Any? {
        didSet {
            if let attributedTitle = title as? NSAttributedString {
                titleLabel.text = nil
                titleLabel.attributedText = attributedTitle
            } else {
                titleLabel.attributedText = nil
                titleLabel.text = title as? String
            }
            if titleLabel.isHidden {
                titleLabel.isHidden = false
            }
        }
    }

    /// 轮播文字label字体颜色
    open var titleLabelTextColor: UIColor? = .white {
        didSet {
            titleLabel.textColor = titleLabelTextColor
        }
    }

    /// 轮播文字label字体
    open var titleLabelTextFont: UIFont? = .systemFont(ofSize: 14) {
        didSet {
            titleLabel.font = titleLabelTextFont
        }
    }

    /// 轮播文字label背景颜色
    open var titleLabelBackgroundColor: UIColor? = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5) {
        didSet {
            titleLabel.backgroundColor = titleLabelBackgroundColor
        }
    }

    /// 轮播文字label高度
    open var titleLabelHeight: CGFloat = 30

    /// 轮播文字间距设置(影响背景)，默认全部0
    open var titleLabelInset: UIEdgeInsets = .zero

    /// 轮播文字内容间距设置(不影响背景)，默认{0 16 0 16}
    open var titleLabelContentInset: UIEdgeInsets = .init(top: 0, left: 16, bottom: 0, right: 16) {
        didSet { titleLabel.fw.contentInset = titleLabelContentInset }
    }

    /// 轮播文字label对齐方式
    open var titleLabelTextAlignment: NSTextAlignment = .left {
        didSet {
            titleLabel.textAlignment = titleLabelTextAlignment
        }
    }

    /// 图片视图间距设置，默认全部0
    open var imageViewInset: UIEdgeInsets = .zero

    /// 内容视图间距设置，默认全部0
    open var contentViewInset: UIEdgeInsets = .zero

    /// 内容视图圆角设置，默认0
    open var contentViewCornerRadius: CGFloat = .zero {
        didSet {
            insetView.layer.cornerRadius = contentViewCornerRadius
        }
    }

    /// 内容视图背景色，默认nil
    open var contentViewBackgroundColor: UIColor? {
        didSet {
            insetView.backgroundColor = contentViewBackgroundColor
        }
    }

    /// 是否已配置完成
    open var hasConfigured: Bool = false

    /// 只展示文字轮播
    open var onlyDisplayText: Bool = false

    // MARK: - Subviews
    /// 图片视图
    open lazy var imageView: UIImageView = {
        let result = UIImageView.fw.animatedImageView()
        result.layer.masksToBounds = true
        return result
    }()

    /// 标题标签
    open lazy var titleLabel: UILabel = {
        let result = UILabel()
        result.fw.contentInset = titleLabelContentInset
        result.isHidden = true
        return result
    }()

    private lazy var insetView: UIView = {
        let result = UIView()
        result.layer.masksToBounds = true
        return result
    }()

    // MARK: - Lifecycle
    override public init(frame: CGRect) {
        super.init(frame: frame)

        setupSubviews()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        setupSubviews()
    }

    private func setupSubviews() {
        contentView.addSubview(insetView)
        insetView.addSubview(imageView)
        insetView.addSubview(titleLabel)
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        let frame = CGRect(x: contentViewInset.left, y: contentViewInset.top, width: bounds.size.width - contentViewInset.left - contentViewInset.right, height: bounds.size.height - contentViewInset.top - contentViewInset.bottom)
        insetView.frame = frame

        if onlyDisplayText {
            titleLabel.frame = CGRect(x: titleLabelInset.left, y: titleLabelInset.top, width: insetView.bounds.size.width - titleLabelInset.left - titleLabelInset.right, height: insetView.bounds.size.height - titleLabelInset.top - titleLabelInset.bottom)
        } else {
            imageView.frame = CGRect(x: imageViewInset.left, y: imageViewInset.top, width: insetView.bounds.size.width - imageViewInset.left - imageViewInset.right, height: insetView.bounds.size.height - imageViewInset.top - imageViewInset.bottom)
            titleLabel.frame = CGRect(x: titleLabelInset.left, y: insetView.frame.size.height - titleLabelHeight + titleLabelInset.top - titleLabelInset.bottom, width: insetView.frame.size.width - titleLabelInset.left - titleLabelInset.right, height: titleLabelHeight)
        }
    }
}
