//
//  TagCollectionView.swift
//  FWFramework
//
//  Created by wuyong on 2023/12/06.
//

import UIKit

public enum TagCollectionScrollDirection: Int, Sendable {
    case vertical = 0
    case horizontal
}

public enum TagCollectionAlignment: Int, Sendable {
    case left = 0
    case center
    case right
    case fillByExpandingSpace
    case fillByExpandingWidth
    case fillByExpandingWidthExceptLastLine
}

@MainActor @objc public protocol TagCollectionViewDelegate: NSObjectProtocol {
    func tagCollectionView(_ tagCollectionView: TagCollectionView, sizeForTagAt index: Int) -> CGSize

    @objc optional func tagCollectionView(_ tagCollectionView: TagCollectionView, shouldSelectTag tagView: UIView, at index: Int) -> Bool
    @objc optional func tagCollectionView(_ tagCollectionView: TagCollectionView, didSelectTag tagView: UIView, at index: Int)
    @objc optional func tagCollectionView(_ tagCollectionView: TagCollectionView, updateContentSize contentSize: CGSize)
}

@MainActor public protocol TagCollectionViewDataSource: AnyObject {
    func numberOfTags(in tagCollectionView: TagCollectionView) -> Int
    func tagCollectionView(_ tagCollectionView: TagCollectionView, tagViewFor index: Int) -> UIView
}

/// [TTGTagCollectionView](https://github.com/zekunyan/TTGTagCollectionView)
open class TagCollectionView: UIView {
    open weak var dataSource: TagCollectionViewDataSource?
    open weak var delegate: TagCollectionViewDelegate?

    open var scrollDirection: TagCollectionScrollDirection = .vertical {
        didSet { setNeedsLayoutTagViews() }
    }

    open var alignment: TagCollectionAlignment = .left {
        didSet { setNeedsLayoutTagViews() }
    }

    open var numberOfLines: Int = 0 {
        didSet { setNeedsLayoutTagViews() }
    }

    open private(set) var actualNumberOfLines: Int {
        get {
            if scrollDirection == .horizontal {
                return numberOfLines
            } else {
                return _actualNumberOfLines
            }
        }
        set {
            _actualNumberOfLines = newValue
        }
    }

    private var _actualNumberOfLines: Int = 0

    open var horizontalSpacing: CGFloat = 4.0 {
        didSet { setNeedsLayoutTagViews() }
    }

    open var verticalSpacing: CGFloat = 4.0 {
        didSet { setNeedsLayoutTagViews() }
    }

    open var contentInset: UIEdgeInsets = .init(top: 2, left: 2, bottom: 2, right: 2) {
        didSet { setNeedsLayoutTagViews() }
    }

    open var contentSize: CGSize {
        layoutTagViews()
        return scrollView.contentSize
    }

    open var manualCalculateHeight: Bool = false {
        didSet { setNeedsLayoutTagViews() }
    }

    open var preferredMaxLayoutWidth: CGFloat = 0 {
        didSet { setNeedsLayoutTagViews() }
    }

    open var showsHorizontalScrollIndicator: Bool {
        get { scrollView.showsHorizontalScrollIndicator }
        set { scrollView.showsHorizontalScrollIndicator = newValue }
    }

    open var showsVerticalScrollIndicator: Bool {
        get { scrollView.showsVerticalScrollIndicator }
        set { scrollView.showsVerticalScrollIndicator = newValue }
    }

    open var onTapBlankArea: (@MainActor @Sendable (CGPoint) -> Void)?
    open var onTapAllArea: (@MainActor @Sendable (CGPoint) -> Void)?

    open lazy var scrollView: UIScrollView = {
        let result = UIScrollView(frame: self.bounds)
        result.backgroundColor = .clear
        result.isUserInteractionEnabled = true
        result.scrollsToTop = false
        return result
    }()

    @_spi(FW) open lazy var containerView: UIView = {
        let result = UIView(frame: scrollView.bounds)
        result.backgroundColor = .clear
        result.isUserInteractionEnabled = true
        return result
    }()

    private var needsLayoutTagViews: Bool = false

    override public init(frame: CGRect) {
        super.init(frame: frame)
        didInitialize()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        didInitialize()
    }

    private func didInitialize() {
        addSubview(scrollView)
        scrollView.addSubview(containerView)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapGesture(_:)))
        containerView.addGestureRecognizer(tapGesture)

        setNeedsLayoutTagViews()
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        if scrollView.frame != bounds {
            scrollView.frame = bounds
            setNeedsLayoutTagViews()
            layoutTagViews()
            containerView.frame = CGRect(origin: .zero, size: scrollView.contentSize)
        }
        layoutTagViews()
    }

    override open var intrinsicContentSize: CGSize {
        scrollView.contentSize
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        contentSize
    }

    open func reload() {
        guard isDelegateAndDataSourceValid() else { return }
        guard let dataSource else { return }

        containerView.subviews.forEach { $0.removeFromSuperview() }
        for i in 0..<dataSource.numberOfTags(in: self) {
            containerView.addSubview(dataSource.tagCollectionView(self, tagViewFor: i))
        }

        setNeedsLayoutTagViews()
        layoutTagViews()

        BannerView.trackExposureBlock?(self)
    }

    open func indexOfTagAt(_ point: CGPoint) -> Int? {
        guard let dataSource else { return nil }

        let convertedPoint = convert(point, to: containerView)
        for i in 0..<dataSource.numberOfTags(in: self) {
            let tagView = dataSource.tagCollectionView(self, tagViewFor: i)
            if tagView.frame.contains(convertedPoint) && !tagView.isHidden {
                return i
            }
        }
        return nil
    }

    @objc private func onTapGesture(_ tapGesture: UITapGestureRecognizer) {
        let tapPointInCollectionView = tapGesture.location(in: self)
        guard let dataSource, let delegate,
              delegate.responds(to: #selector(TagCollectionViewDelegate.tagCollectionView(_:didSelectTag:at:))) else {
            onTapBlankArea?(tapPointInCollectionView)
            onTapAllArea?(tapPointInCollectionView)
            return
        }

        let tapPointInScrollView = tapGesture.location(in: containerView)
        var hasLocatedToTag = false
        for i in 0..<(dataSource.numberOfTags(in: self)) {
            let tagView = dataSource.tagCollectionView(self, tagViewFor: i)
            if tagView.frame.contains(tapPointInScrollView) && !tagView.isHidden {
                hasLocatedToTag = true

                if let shouldSelect = delegate.tagCollectionView?(self, shouldSelectTag: tagView, at: i) {
                    if shouldSelect {
                        delegate.tagCollectionView?(self, didSelectTag: tagView, at: i)
                        _ = BannerView.trackClickBlock?(self, IndexPath(row: i, section: 0))
                    }
                } else {
                    delegate.tagCollectionView?(self, didSelectTag: tagView, at: i)
                    _ = BannerView.trackClickBlock?(self, IndexPath(row: i, section: 0))
                }
            }
        }

        if !hasLocatedToTag {
            onTapBlankArea?(tapPointInCollectionView)
        }
        onTapAllArea?(tapPointInCollectionView)
    }

    private func setNeedsLayoutTagViews() {
        needsLayoutTagViews = true
    }

    private func layoutTagViews() {
        if !needsLayoutTagViews || !isDelegateAndDataSourceValid() { return }

        if scrollDirection == .vertical {
            layoutTagViewsForVerticalDirection()
        } else {
            layoutTagViewsForHorizontalDirection()
        }

        needsLayoutTagViews = false
        invalidateIntrinsicContentSize()
    }

    private func layoutTagViewsForVerticalDirection() {
        let count = dataSource?.numberOfTags(in: self) ?? 0
        let totalWidth = manualCalculateHeight && preferredMaxLayoutWidth > 0 ? preferredMaxLayoutWidth : bounds.width
        let maxLineWidth = totalWidth - contentInset.left - contentInset.right
        var currentLineTagsCount = 0
        var currentLineX: CGFloat = 0
        var currentLineMaxHeight: CGFloat = 0

        var eachLineMaxHeightNumbers = [CGFloat]()
        var eachLineWidthNumbers = [CGFloat]()
        var eachLineTagCountNumbers = [Int]()
        var eachLineTagIndexs = [[Int]]()
        var tmpTagIndexNumbers = [Int]()

        for i in 0..<count {
            let tagSize = delegate?.tagCollectionView(self, sizeForTagAt: i) ?? .zero

            if currentLineX + tagSize.width > maxLineWidth && tmpTagIndexNumbers.count > 0 {
                eachLineMaxHeightNumbers.append(currentLineMaxHeight)
                eachLineWidthNumbers.append(currentLineX - horizontalSpacing)
                eachLineTagCountNumbers.append(currentLineTagsCount)
                eachLineTagIndexs.append(tmpTagIndexNumbers)
                tmpTagIndexNumbers = [Int]()
                currentLineTagsCount = 0
                currentLineMaxHeight = 0
                currentLineX = 0
            }

            if numberOfLines != 0 {
                let tagView = dataSource?.tagCollectionView(self, tagViewFor: i)
                tagView?.isHidden = eachLineWidthNumbers.count >= numberOfLines
            }

            currentLineX += tagSize.width + horizontalSpacing
            currentLineTagsCount += 1
            currentLineMaxHeight = max(tagSize.height, currentLineMaxHeight)
            tmpTagIndexNumbers.append(i)
        }

        eachLineMaxHeightNumbers.append(currentLineMaxHeight)
        eachLineWidthNumbers.append(currentLineX - horizontalSpacing)
        eachLineTagCountNumbers.append(currentLineTagsCount)
        eachLineTagIndexs.append(tmpTagIndexNumbers)

        actualNumberOfLines = eachLineTagCountNumbers.count

        if numberOfLines != 0 {
            eachLineMaxHeightNumbers = Array(eachLineMaxHeightNumbers[0..<min(eachLineMaxHeightNumbers.count, numberOfLines)])
            eachLineWidthNumbers = Array(eachLineWidthNumbers[0..<min(eachLineWidthNumbers.count, numberOfLines)])
            eachLineTagCountNumbers = Array(eachLineTagCountNumbers[0..<min(eachLineTagCountNumbers.count, numberOfLines)])
            eachLineTagIndexs = Array(eachLineTagIndexs[0..<min(eachLineTagIndexs.count, numberOfLines)])
        }

        layoutEachLineTags(
            maxLineWidth: maxLineWidth,
            numberOfLines: eachLineTagCountNumbers.count,
            eachLineTagIndexs: eachLineTagIndexs,
            eachLineTagCount: eachLineTagCountNumbers,
            eachLineWidth: eachLineWidthNumbers,
            eachLineMaxHeight: eachLineMaxHeightNumbers
        )
    }

    private func layoutTagViewsForHorizontalDirection() {
        let count = dataSource?.numberOfTags(in: self) ?? 0
        numberOfLines = min(count, numberOfLines == 0 ? 1 : numberOfLines)

        var maxLineWidth: CGFloat = 0
        var eachLineMaxHeightNumbers = [CGFloat]()
        var eachLineWidthNumbers = [CGFloat]()
        var eachLineTagCountNumbers = [Int]()
        var eachLineTagIndexs = [[Int]]()

        for _ in 0..<numberOfLines {
            eachLineMaxHeightNumbers.append(0)
            eachLineWidthNumbers.append(0)
            eachLineTagCountNumbers.append(0)
            eachLineTagIndexs.append([Int]())
        }

        for tagIndex in 0..<count {
            let currentLine = tagIndex % numberOfLines

            var currentLineTagsCount = eachLineTagCountNumbers[currentLine]
            var currentLineMaxHeight = eachLineMaxHeightNumbers[currentLine]
            var currentLineX = eachLineWidthNumbers[currentLine]
            var currentLineTagIndexNumbers = eachLineTagIndexs[currentLine]

            let tagSize = delegate?.tagCollectionView(self, sizeForTagAt: tagIndex) ?? .zero
            currentLineX += tagSize.width + horizontalSpacing
            currentLineMaxHeight = max(tagSize.height, currentLineMaxHeight)
            currentLineTagsCount += 1
            currentLineTagIndexNumbers.append(tagIndex)

            eachLineTagCountNumbers[currentLine] = currentLineTagsCount
            eachLineMaxHeightNumbers[currentLine] = currentLineMaxHeight
            eachLineWidthNumbers[currentLine] = currentLineX
            eachLineTagIndexs[currentLine] = currentLineTagIndexNumbers
        }

        for currentLine in 0..<numberOfLines {
            var currentLineWidth = eachLineWidthNumbers[currentLine]
            currentLineWidth -= horizontalSpacing
            eachLineWidthNumbers[currentLine] = currentLineWidth

            maxLineWidth = max(currentLineWidth, maxLineWidth)
        }

        layoutEachLineTags(
            maxLineWidth: maxLineWidth,
            numberOfLines: eachLineTagCountNumbers.count,
            eachLineTagIndexs: eachLineTagIndexs,
            eachLineTagCount: eachLineTagCountNumbers,
            eachLineWidth: eachLineWidthNumbers,
            eachLineMaxHeight: eachLineMaxHeightNumbers
        )
    }

    private func layoutEachLineTags(
        maxLineWidth: CGFloat,
        numberOfLines: Int,
        eachLineTagIndexs: [[Int]],
        eachLineTagCount: [Int],
        eachLineWidth: [CGFloat],
        eachLineMaxHeight: [CGFloat]
    ) {
        var currentYBase = contentInset.top
        for currentLine in 0..<numberOfLines {
            let currentLineMaxHeight = eachLineMaxHeight[currentLine]
            var currentLineWidth = eachLineWidth[currentLine]
            let currentLineTagsCount = eachLineTagCount[currentLine]

            var currentLineXOffset: CGFloat = 0
            var currentLineAdditionWidth: CGFloat = 0
            var acturalHorizontalSpacing = horizontalSpacing
            var currentLineX: CGFloat = 0

            switch alignment {
            case .left:
                currentLineXOffset = contentInset.left
            case .center:
                currentLineXOffset = (maxLineWidth - currentLineWidth) / 2 + contentInset.left
            case .right:
                currentLineXOffset = maxLineWidth - currentLineWidth + contentInset.left
            case .fillByExpandingSpace:
                currentLineXOffset = contentInset.left
                acturalHorizontalSpacing = horizontalSpacing + (maxLineWidth - currentLineWidth) / CGFloat(currentLineTagsCount - 1)
                currentLineWidth = maxLineWidth
            case .fillByExpandingWidth, .fillByExpandingWidthExceptLastLine:
                currentLineXOffset = contentInset.left
                currentLineAdditionWidth = (maxLineWidth - currentLineWidth) / CGFloat(currentLineTagsCount)
                currentLineWidth = maxLineWidth

                if alignment == .fillByExpandingWidthExceptLastLine && currentLine == numberOfLines - 1 && numberOfLines != 1 {
                    currentLineAdditionWidth = 0
                }
            }

            for (_, tagIndex) in eachLineTagIndexs[currentLine].enumerated() {
                let tagView = dataSource?.tagCollectionView(self, tagViewFor: tagIndex)
                var tagSize = delegate?.tagCollectionView(self, sizeForTagAt: tagIndex) ?? .zero

                var origin = CGPoint.zero
                origin.x = currentLineXOffset + currentLineX
                origin.y = currentYBase + (currentLineMaxHeight - tagSize.height) / 2

                tagSize.width += currentLineAdditionWidth
                if scrollDirection == .vertical && tagSize.width > maxLineWidth {
                    tagSize.width = maxLineWidth
                }

                tagView?.isHidden = false
                tagView?.frame = CGRect(origin: origin, size: tagSize)

                currentLineX += tagSize.width + acturalHorizontalSpacing
            }

            currentYBase += currentLineMaxHeight + verticalSpacing
        }

        let contentSize = CGSize(width: maxLineWidth + contentInset.right + contentInset.left, height: currentYBase - verticalSpacing + contentInset.bottom)
        if contentSize != scrollView.contentSize {
            scrollView.contentSize = contentSize
            containerView.frame = CGRect(origin: CGPoint.zero, size: contentSize)

            delegate?.tagCollectionView?(self, updateContentSize: contentSize)
        }
    }

    private func isDelegateAndDataSourceValid() -> Bool {
        delegate != nil && dataSource != nil
    }
}

open class TextTagConfig: NSObject, NSCopying {
    open var textFont: UIFont? = UIFont.systemFont(ofSize: 16)
    open var selectedTextFont: UIFont?

    open var textColor: UIColor? = .white
    open var selectedTextColor: UIColor? = .white

    open var backgroundColor: UIColor? = UIColor(red: 0.30, green: 0.72, blue: 0.53, alpha: 1.0)
    open var selectedBackgroundColor: UIColor? = UIColor(red: 0.22, green: 0.29, blue: 0.36, alpha: 1)

    open var enableGradientBackground = false
    open var gradientBackgroundStartColor: UIColor? = .clear
    open var gradientBackgroundEndColor: UIColor? = .clear
    open var selectedGradientBackgroundStartColor: UIColor? = .clear
    open var selectedGradientBackgroundEndColor: UIColor? = .clear
    open var gradientBackgroundStartPoint: CGPoint = .init(x: 0.5, y: 0)
    open var gradientBackgroundEndPoint: CGPoint = .init(x: 0.5, y: 1.0)

    open var cornerRadius: CGFloat = 4.0
    open var selectedCornerRadius: CGFloat = 4.0
    open var cornerTopRight: Bool = true
    open var cornerTopLeft: Bool = true
    open var cornerBottomRight: Bool = true
    open var cornerBottomLeft: Bool = true

    open var borderWidth: CGFloat = 1.0
    open var selectedBorderWidth: CGFloat = 1.0
    open var borderColor: UIColor? = .white
    open var selectedBorderColor: UIColor? = .white

    open var shadowColor: UIColor? = .clear
    open var shadowOffset: CGSize = .zero
    open var shadowRadius: CGFloat = 0
    open var shadowOpacity: Float = 0

    open var extraSpace: CGSize = .init(width: 14, height: 14)
    open var maxWidth: CGFloat = 0
    open var minWidth: CGFloat = 0
    open var exactWidth: CGFloat = 0
    open var exactHeight: CGFloat = 0
    open var extraData: Any?

    override public required init() {
        super.init()
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        let newConfig = Self()
        newConfig.textFont = textFont
        newConfig.selectedTextFont = selectedTextFont
        newConfig.textColor = textColor
        newConfig.selectedTextColor = selectedTextColor
        newConfig.backgroundColor = backgroundColor
        newConfig.selectedBackgroundColor = selectedBackgroundColor

        newConfig.enableGradientBackground = enableGradientBackground
        newConfig.gradientBackgroundStartColor = gradientBackgroundStartColor
        newConfig.gradientBackgroundEndColor = gradientBackgroundEndColor
        newConfig.selectedGradientBackgroundStartColor = selectedGradientBackgroundStartColor
        newConfig.selectedGradientBackgroundEndColor = selectedGradientBackgroundEndColor
        newConfig.gradientBackgroundStartPoint = gradientBackgroundStartPoint
        newConfig.gradientBackgroundEndPoint = gradientBackgroundEndPoint

        newConfig.cornerRadius = cornerRadius
        newConfig.selectedCornerRadius = selectedCornerRadius
        newConfig.cornerTopLeft = cornerTopLeft
        newConfig.cornerTopRight = cornerTopRight
        newConfig.cornerBottomLeft = cornerBottomLeft
        newConfig.cornerBottomRight = cornerBottomRight

        newConfig.borderWidth = borderWidth
        newConfig.selectedBorderWidth = selectedBorderWidth
        newConfig.borderColor = borderColor
        newConfig.selectedBorderColor = selectedBorderColor

        newConfig.shadowColor = shadowColor
        newConfig.shadowOffset = shadowOffset
        newConfig.shadowRadius = shadowRadius
        newConfig.shadowOpacity = shadowOpacity

        newConfig.extraSpace = extraSpace
        newConfig.maxWidth = maxWidth
        newConfig.minWidth = minWidth
        newConfig.exactWidth = exactWidth
        newConfig.exactHeight = exactHeight

        if let copyData = extraData as? NSCopying {
            newConfig.extraData = copyData.copy(with: zone)
        } else {
            newConfig.extraData = extraData
        }
        return newConfig
    }
}

@MainActor @objc public protocol TextTagCollectionViewDelegate {
    @objc optional func textTagCollectionView(_ textTagCollectionView: TextTagCollectionView, canTapTag tagText: String, at index: Int, currentSelected: Bool, tagConfig: TextTagConfig) -> Bool
    @objc optional func textTagCollectionView(_ textTagCollectionView: TextTagCollectionView, didTapTag tagText: String, at index: Int, selected: Bool, tagConfig: TextTagConfig)
    @objc optional func textTagCollectionView(_ textTagCollectionView: TextTagCollectionView, updateContentSize contentSize: CGSize)
}

open class TextTagCollectionView: UIView, TagCollectionViewDataSource, TagCollectionViewDelegate {
    open weak var delegate: TextTagCollectionViewDelegate?

    open var enableTagSelection: Bool = true
    open var scrollDirection: TagCollectionScrollDirection {
        get { tagCollectionView.scrollDirection }
        set { tagCollectionView.scrollDirection = newValue }
    }

    open var alignment: TagCollectionAlignment {
        get { tagCollectionView.alignment }
        set { tagCollectionView.alignment = newValue }
    }

    open var numberOfLines: Int {
        get { tagCollectionView.numberOfLines }
        set { tagCollectionView.numberOfLines = newValue }
    }

    open var actualNumberOfLines: Int {
        tagCollectionView.actualNumberOfLines
    }

    open var selectionLimit: Int = 0
    open var horizontalSpacing: CGFloat {
        get { tagCollectionView.horizontalSpacing }
        set { tagCollectionView.horizontalSpacing = newValue }
    }

    open var verticalSpacing: CGFloat {
        get { tagCollectionView.verticalSpacing }
        set { tagCollectionView.verticalSpacing = newValue }
    }

    open var contentInset: UIEdgeInsets {
        get { tagCollectionView.contentInset }
        set { tagCollectionView.contentInset = newValue }
    }

    open var contentSize: CGSize {
        tagCollectionView.contentSize
    }

    open var manualCalculateHeight: Bool {
        get { tagCollectionView.manualCalculateHeight }
        set { tagCollectionView.manualCalculateHeight = newValue }
    }

    open var preferredMaxLayoutWidth: CGFloat {
        get { tagCollectionView.preferredMaxLayoutWidth }
        set { tagCollectionView.preferredMaxLayoutWidth = newValue }
    }

    open var showsHorizontalScrollIndicator: Bool {
        get { tagCollectionView.showsHorizontalScrollIndicator }
        set { tagCollectionView.showsHorizontalScrollIndicator = newValue }
    }

    open var showsVerticalScrollIndicator: Bool {
        get { tagCollectionView.showsVerticalScrollIndicator }
        set { tagCollectionView.showsVerticalScrollIndicator = newValue }
    }

    open var onTapBlankArea: (@MainActor @Sendable (CGPoint) -> Void)? {
        get { tagCollectionView.onTapBlankArea }
        set { tagCollectionView.onTapBlankArea = newValue }
    }

    open var onTapAllArea: (@MainActor @Sendable (CGPoint) -> Void)? {
        get { tagCollectionView.onTapAllArea }
        set { tagCollectionView.onTapAllArea = newValue }
    }

    open var onTapTag: (@MainActor @Sendable (_ tagText: String, _ index: Int, _ selected: Bool) -> Void)?

    open var defaultConfig: TextTagConfig = .init()

    open var scrollView: UIScrollView {
        tagCollectionView.scrollView
    }

    @_spi(FW) open lazy var tagCollectionView: TagCollectionView = {
        let result = TagCollectionView(frame: bounds)
        result.delegate = self
        result.dataSource = self
        result.horizontalSpacing = 8
        result.verticalSpacing = 8
        return result
    }()

    private var tagLabels: [TextTagLabel] = []

    override public init(frame: CGRect) {
        super.init(frame: frame)
        didInitialize()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        didInitialize()
    }

    private func didInitialize() {
        addSubview(tagCollectionView)
    }

    override open var intrinsicContentSize: CGSize {
        tagCollectionView.intrinsicContentSize
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        contentSize
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        if tagCollectionView.frame != bounds {
            updateAllLabelStyleAndFrame()
            tagCollectionView.frame = bounds
            tagCollectionView.setNeedsLayout()
            tagCollectionView.layoutIfNeeded()
            invalidateIntrinsicContentSize()
        }
    }

    open func reload() {
        updateAllLabelStyleAndFrame()
        tagCollectionView.reload()
        invalidateIntrinsicContentSize()
    }

    open func addTag(_ tag: String, config: TextTagConfig? = nil) {
        insertTag(tag, at: tagLabels.count, config: config)
    }

    open func addTags(_ tags: [String], config: TextTagConfig? = nil) {
        insertTags(tags, at: tagLabels.count, config: config)
    }

    open func insertTag(_ tag: String, at index: Int, config: TextTagConfig? = nil) {
        insertTags([tag], at: index, config: config)
    }

    open func insertTags(_ tags: [String], at index: Int, config: TextTagConfig? = nil) {
        insertTags(tags, at: index, config: config ?? defaultConfig, copyConfig: config != nil)
    }

    private func insertTags(_ tags: [String], at index: Int, config: TextTagConfig, copyConfig: Bool) {
        if index > tagLabels.count { return }

        let config = copyConfig ? (config.copy() as! TextTagConfig) : config
        var newTagLabels: [TextTagLabel] = []
        for tagText in tags {
            let label = newLabel(for: tagText, config: config)
            newTagLabels.append(label)
        }
        tagLabels.insert(contentsOf: newTagLabels, at: index)
        reload()
    }

    open func removeTag(_ tag: String) {
        guard !tag.isEmpty else { return }

        tagLabels.removeAll(where: { tag == $0.label.text })
        reload()
    }

    open func removeTag(at index: Int) {
        guard index < tagLabels.count else { return }

        tagLabels.remove(at: index)
        reload()
    }

    open func removeAllTags() {
        tagLabels.removeAll()
        reload()
    }

    open func setTag(at index: Int, selected: Bool) {
        guard index < tagLabels.count else { return }

        tagLabels[index].selected = selected
        reload()
    }

    open func setTag(at index: Int, config: TextTagConfig) {
        guard index < tagLabels.count else { return }

        tagLabels[index].config = config.copy() as! TextTagConfig
        reload()
    }

    open func setTags(in range: NSRange, config: TextTagConfig) {
        if NSMaxRange(range) > tagLabels.count { return }

        let subLabels = Array(tagLabels[(range.location)..<(range.location + range.length)])
        let config = config.copy() as! TextTagConfig
        for label in subLabels {
            label.config = config
        }
        reload()
    }

    open func getTag(at index: Int) -> String? {
        if index < tagLabels.count {
            return tagLabels[index].label.text
        }
        return nil
    }

    open func getTags(in range: NSRange) -> [String] {
        var tags: [String] = []
        if NSMaxRange(range) <= tagLabels.count {
            let subLabels = Array(tagLabels[(range.location)..<(range.location + range.length)])
            for label in subLabels {
                tags.append(label.label.text ?? "")
            }
        }
        return tags
    }

    open func getConfig(at index: Int) -> TextTagConfig? {
        if index < tagLabels.count {
            return tagLabels[index].config.copy() as? TextTagConfig
        }
        return nil
    }

    open func getConfigs(in range: NSRange) -> [TextTagConfig] {
        var configs: [TextTagConfig] = []
        if NSMaxRange(range) <= tagLabels.count {
            let subLabels = Array(tagLabels[(range.location)..<(range.location + range.length)])
            for label in subLabels {
                configs.append(label.config.copy() as! TextTagConfig)
            }
        }
        return configs
    }

    open func allTags() -> [String] {
        var allTags: [String] = []
        for label in tagLabels {
            allTags.append(label.label.text ?? "")
        }
        return allTags
    }

    open func allSelectedTags() -> [String] {
        var allTags: [String] = []
        for label in tagLabels {
            if label.selected {
                allTags.append(label.label.text ?? "")
            }
        }
        return allTags
    }

    open func allNotSelectedTags() -> [String] {
        var allTags: [String] = []
        for label in tagLabels {
            if !label.selected {
                allTags.append(label.label.text ?? "")
            }
        }
        return allTags
    }

    open func indexOfTag(at point: CGPoint) -> Int? {
        let convertedPoint = convert(point, to: tagCollectionView)
        return tagCollectionView.indexOfTagAt(convertedPoint)
    }

    // MARK: - TagCollectionView
    open func numberOfTags(in tagCollectionView: TagCollectionView) -> Int {
        tagLabels.count
    }

    open func tagCollectionView(_ tagCollectionView: TagCollectionView, tagViewFor index: Int) -> UIView {
        tagLabels[index]
    }

    open func tagCollectionView(_ tagCollectionView: TagCollectionView, shouldSelectTag tagView: UIView, at index: Int) -> Bool {
        guard enableTagSelection else { return false }

        let label = tagLabels[index]
        if let shouldSelect = delegate?.textTagCollectionView?(self, canTapTag: label.label.text ?? "", at: index, currentSelected: label.selected, tagConfig: label.config) {
            return shouldSelect
        } else {
            return true
        }
    }

    open func tagCollectionView(_ tagCollectionView: TagCollectionView, didSelectTag tagView: UIView, at index: Int) {
        guard enableTagSelection else { return }

        let label = tagLabels[index]
        if !label.selected && selectionLimit > 0 && (allSelectedTags().count + 1) > selectionLimit { return }

        label.selected = !label.selected
        if alignment == .fillByExpandingWidth || alignment == .fillByExpandingWidthExceptLastLine {
            reload()
        } else {
            updateStyleAndFrame(for: label)
        }

        delegate?.textTagCollectionView?(self, didTapTag: label.label.text ?? "", at: index, selected: label.selected, tagConfig: label.config)
        onTapTag?(label.label.text ?? "", index, label.selected)

        _ = BannerView.trackClickBlock?(self, IndexPath(row: index, section: 0))
    }

    open func tagCollectionView(_ tagCollectionView: TagCollectionView, sizeForTagAt index: Int) -> CGSize {
        tagLabels[index].frame.size
    }

    open func tagCollectionView(_ tagCollectionView: TagCollectionView, updateContentSize contentSize: CGSize) {
        delegate?.textTagCollectionView?(self, updateContentSize: contentSize)
    }

    // MARK: - Private
    private func updateAllLabelStyleAndFrame() {
        for label in tagLabels {
            updateStyleAndFrame(for: label)
        }
    }

    private func updateStyleAndFrame(for label: TextTagLabel) {
        label.updateContentStyle()
        var maxSize: CGSize = .zero
        if scrollDirection == .vertical && bounds.width > 0 {
            maxSize.width = bounds.width - contentInset.left - contentInset.right
        }
        label.updateFrame(maxSize: maxSize)
    }

    private func newLabel(for tagText: String, config: TextTagConfig) -> TextTagLabel {
        let label = TextTagLabel(tagText: tagText, config: config)
        return label
    }
}

class TagGradientLabel: UILabel {
    override class var layerClass: AnyClass {
        CAGradientLayer.self
    }
}

class TextTagLabel: UIView {
    lazy var label: TagGradientLabel = {
        let result = TagGradientLabel(frame: self.bounds)
        result.textAlignment = .center
        result.isUserInteractionEnabled = true
        return result
    }()

    private lazy var borderLayer: CAShapeLayer = {
        let result = CAShapeLayer()
        result.fillColor = nil
        result.opacity = 1
        return result
    }()

    var selected = false
    var config: TextTagConfig

    init(tagText: String, config: TextTagConfig) {
        self.config = config
        super.init(frame: .zero)

        label.text = tagText
        addSubview(label)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        label.frame = bounds

        let path = getNewPath()
        updateMask(path: path)
        updateBorder(path: path)
        updateShadow(path: path)
    }

    override var intrinsicContentSize: CGSize {
        label.intrinsicContentSize
    }

    func updateContentStyle() {
        label.font = selected && config.selectedTextFont != nil ? config.selectedTextFont : config.textFont
        label.textColor = selected ? config.selectedTextColor : config.textColor
        label.backgroundColor = selected ? config.selectedBackgroundColor : config.backgroundColor

        if config.enableGradientBackground {
            label.backgroundColor = .clear
            let gradientLayer = label.layer as? CAGradientLayer
            if selected {
                if let startColor = config.selectedGradientBackgroundStartColor,
                   let endColor = config.selectedGradientBackgroundEndColor {
                    gradientLayer?.colors = [startColor.cgColor, endColor.cgColor]
                }
            } else {
                if let startColor = config.gradientBackgroundStartColor,
                   let endColor = config.gradientBackgroundEndColor {
                    gradientLayer?.colors = [startColor.cgColor, endColor.cgColor]
                }
            }
            gradientLayer?.startPoint = config.gradientBackgroundStartPoint
            gradientLayer?.endPoint = config.gradientBackgroundEndPoint
        }
    }

    func updateFrame(maxSize: CGSize) {
        label.sizeToFit()

        var finalSize = label.frame.size
        finalSize.width += config.extraSpace.width
        finalSize.height += config.extraSpace.height

        if config.maxWidth > 0 && finalSize.width > config.maxWidth {
            finalSize.width = config.maxWidth
        }
        if config.minWidth > 0 && finalSize.width < config.minWidth {
            finalSize.width = config.minWidth
        }
        if config.exactWidth > 0 {
            finalSize.width = config.exactWidth
        }
        if config.exactHeight > 0 {
            finalSize.height = config.exactHeight
        }

        if maxSize.width > 0 {
            finalSize.width = min(maxSize.width, finalSize.width)
        }
        if maxSize.height > 0 {
            finalSize.height = min(maxSize.height, finalSize.height)
        }

        var frame = frame
        frame.size = finalSize
        self.frame = frame
        label.frame = bounds
    }

    private func updateShadow(path: UIBezierPath) {
        layer.shadowColor = (config.shadowColor ?? .clear).cgColor
        layer.shadowOffset = config.shadowOffset
        layer.shadowRadius = config.shadowRadius
        layer.shadowOpacity = config.shadowOpacity
        layer.shadowPath = path.cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
    }

    private func updateMask(path: UIBezierPath) {
        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        maskLayer.path = path.cgPath
        label.layer.mask = maskLayer
    }

    private func updateBorder(path: UIBezierPath) {
        borderLayer.removeFromSuperlayer()
        borderLayer.frame = bounds
        borderLayer.path = path.cgPath
        borderLayer.lineWidth = selected ? config.selectedBorderWidth : config.borderWidth
        borderLayer.strokeColor = selected && config.selectedBorderColor != nil ? config.selectedBorderColor?.cgColor : config.borderColor?.cgColor
        layer.addSublayer(borderLayer)
    }

    private func getNewPath() -> UIBezierPath {
        var corners: UIRectCorner = []
        if config.cornerTopLeft {
            corners.formUnion(.topLeft)
        }
        if config.cornerTopRight {
            corners.formUnion(.topRight)
        }
        if config.cornerBottomLeft {
            corners.formUnion(.bottomLeft)
        }
        if config.cornerBottomRight {
            corners.formUnion(.bottomRight)
        }

        let cornerRadius = selected ? config.selectedCornerRadius : config.cornerRadius
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        return path
    }
}
