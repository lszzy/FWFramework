//
//  SegmentedControl.swift
//  FWFramework
//
//  Created by wuyong on 2023/12/05.
//

import UIKit
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

public enum SegmentedControlSelectionStyle: Int, Sendable {
    case textWidthStripe
    case fullWidthStripe
    case box
    case arrow
    case circle
}

public enum SegmentedControlSelectionIndicatorLocation: Int, Sendable {
    case top
    case bottom
    case none
}

public enum SegmentedControlSegmentWidthStyle: Int, Sendable {
    case fixed
    case dynamic
}

public struct SegmentedControlBorderType: OptionSet, Sendable {
    public let rawValue: Int

    public static let top: SegmentedControlBorderType = .init(rawValue: 1 << 0)
    public static let left: SegmentedControlBorderType = .init(rawValue: 1 << 1)
    public static let bottom: SegmentedControlBorderType = .init(rawValue: 1 << 2)
    public static let right: SegmentedControlBorderType = .init(rawValue: 1 << 3)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public enum SegmentedControlType: Int, Sendable {
    case text
    case images
    case textImages
}

public enum SegmentedControlImagePosition: Int, Sendable {
    case behindText
    case leftOfText
    case rightOfText
    case aboveText
    case belowText
}

/// [HMSegmentedControl](https://github.com/HeshamMegid/HMSegmentedControl)
open class SegmentedControl: UIControl, UIScrollViewDelegate, SegmentedAccessibilityDelegate {
    open var sectionTitles: [StringParameter] = [] {
        didSet {
            setNeedsLayout()
            setNeedsDisplay()
        }
    }

    open var sectionImages: [UIImage] = [] {
        didSet {
            setNeedsLayout()
            setNeedsDisplay()
        }
    }

    open var sectionSelectedImages: [UIImage] = []
    open var sectionCount: Int {
        if type == .text {
            return sectionTitles.count
        } else if type == .images || type == .textImages {
            return sectionImages.count
        }
        return 0
    }

    open var indexChangedBlock: ((Int) -> Void)?
    open var titleFormatter: ((_ segmentedControl: SegmentedControl, _ title: String, _ index: Int, _ selected: Bool) -> NSAttributedString)?

    open var titleTextAttributes: [NSAttributedString.Key: Any]?
    open var selectedTitleTextAttributes: [NSAttributedString.Key: Any]?

    override open var backgroundColor: UIColor? {
        get { _backgroundColor }
        set { _backgroundColor = newValue }
    }

    private var _backgroundColor: UIColor? = .white
    open var selectionIndicatorColor: UIColor? = UIColor(red: 52.0 / 255.0, green: 181.0 / 255.0, blue: 229.0 / 255.0, alpha: 1.0)
    open var selectionIndicatorBoxColor: UIColor? = UIColor(red: 52.0 / 255.0, green: 181.0 / 255.0, blue: 229.0 / 255.0, alpha: 1.0)
    open var verticalDividerColor: UIColor? = .black
    open var selectionIndicatorBoxOpacity: Float = 0.2 {
        didSet {
            selectionIndicatorBoxLayer.opacity = selectionIndicatorBoxOpacity
        }
    }

    open var verticalDividerWidth: CGFloat = 1.0
    open var type: SegmentedControlType = .text
    open var selectionStyle: SegmentedControlSelectionStyle = .textWidthStripe
    open var segmentWidthStyle: SegmentedControlSegmentWidthStyle {
        get {
            _segmentWidthStyle
        }
        set {
            if type == .images {
                _segmentWidthStyle = .fixed
            } else {
                _segmentWidthStyle = newValue
            }
        }
    }

    private var _segmentWidthStyle: SegmentedControlSegmentWidthStyle = .fixed
    open var selectionIndicatorLocation: SegmentedControlSelectionIndicatorLocation = .top {
        didSet {
            if selectionIndicatorLocation == .none {
                selectionIndicatorHeight = 0
            }
        }
    }

    open var borderType: SegmentedControlBorderType = [] {
        didSet {
            setNeedsDisplay()
        }
    }

    open var imagePosition: SegmentedControlImagePosition = .behindText
    open var textImageSpacing: CGFloat = 0
    open var borderColor: UIColor? = .black
    open var borderWidth: CGFloat = 1.0
    open var isUserDraggable: Bool = true
    open var isTouchEnabled: Bool = true
    open var isVerticalDividerEnabled: Bool = false
    open var shouldStretchSegmentsToScreenSize: Bool = false
    open var useSelectedTitleTextAttributesSize: Bool = false
    /// 当前选中index, -1表示不选中
    open var selectedSegmentIndex: Int {
        get {
            _selectedSegmentIndex
        }
        set {
            setSelectedSegmentIndex(newValue, animated: false, notify: false)
        }
    }

    private var _selectedSegmentIndex: Int = 0
    open var selectionIndicatorHeight: CGFloat = 5.0
    open var selectionIndicatorEdgeInsets: UIEdgeInsets = .zero
    open var selectionIndicatorBoxEdgeInsets: UIEdgeInsets = .zero
    open var selectionIndicatorCornerRadius: CGFloat = 0 {
        didSet {
            selectionIndicatorStripLayer.cornerRadius = selectionIndicatorCornerRadius
        }
    }

    open var selectionIndicatorBoxCornerRadius: CGFloat = 0 {
        didSet {
            selectionIndicatorBoxLayer.cornerRadius = selectionIndicatorBoxCornerRadius
        }
    }

    open var contentEdgeInset: UIEdgeInsets = .zero
    open var segmentEdgeInset: UIEdgeInsets = .init(top: 0, left: 5, bottom: 0, right: 5)
    open var segmentBackgroundColor: UIColor?
    open var segmentBackgroundOpacity: Float = 1.0
    open var segmentBackgroundCornerRadius: CGFloat = 0
    open var segmentBackgroundEdgeInset: UIEdgeInsets = .zero
    open var segmentCustomBlock: ((_ segmentedControl: SegmentedControl, _ index: Int, _ rect: CGRect) -> Void)?
    open var enlargeEdgeInset: UIEdgeInsets = .zero
    open var shouldAnimateUserSelection: Bool = true
    open var contentSize: CGSize {
        scrollView.contentSize
    }

    open lazy var scrollView: UIScrollView = {
        let result = SegmentedScrollView()
        result.delegate = self
        result.scrollsToTop = false
        result.showsVerticalScrollIndicator = false
        result.showsHorizontalScrollIndicator = false
        return result
    }()

    private lazy var selectionIndicatorStripLayer: CALayer = {
        let result = CALayer()
        return result
    }()

    private lazy var selectionIndicatorBoxLayer: CALayer = {
        let result = CALayer()
        result.opacity = selectionIndicatorBoxOpacity
        result.borderWidth = 1.0
        return result
    }()

    private lazy var selectionIndicatorShapeLayer: CALayer = {
        let result = CALayer()
        return result
    }()

    @_spi(FW) public var segmentWidth: CGFloat = 0
    @_spi(FW) public var segmentWidthsArray: [CGFloat] = []
    private var titleBackgroundLayers: [CALayer] = []
    private var segmentBackgroundLayers: [CALayer] = []

    // MARK: - Lifecycle
    public init(sectionTitles: [StringParameter]) {
        super.init(frame: .zero)
        didInitialize()
        self.type = .text
        self.sectionTitles = sectionTitles
    }

    public init(sectionImages: [UIImage], sectionSelectedImages: [UIImage]) {
        super.init(frame: .zero)
        didInitialize()
        self.type = .images
        self.sectionImages = sectionImages
        self.sectionSelectedImages = sectionSelectedImages
    }

    public init(sectionImages: [UIImage], sectionSelectedImages: [UIImage], sectionTitles: [StringParameter]) {
        super.init(frame: .zero)
        didInitialize()
        self.type = .textImages
        self.sectionImages = sectionImages
        self.sectionSelectedImages = sectionSelectedImages
        self.sectionTitles = sectionTitles
    }

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

        isOpaque = false
        contentMode = .redraw
    }

    // MARK: - Public
    /// 设置选中index, -1表示不选中
    open func setSelectedSegmentIndex(_ index: Int, animated: Bool) {
        setSelectedSegmentIndex(index, animated: animated, notify: false)
    }

    // MARK: - Override
    override open func layoutSubviews() {
        super.layoutSubviews()
        updateSegmentsRects()
    }

    override open var frame: CGRect {
        didSet {
            updateSegmentsRects()
        }
    }

    override open func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview == nil { return }

        if sectionTitles.count > 0 || sectionImages.count > 0 {
            updateSegmentsRects()
        }
    }

    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)

        let enlargeRect = CGRect(x: bounds.origin.x - enlargeEdgeInset.left, y: bounds.origin.y - enlargeEdgeInset.top, width: bounds.size.width + enlargeEdgeInset.left + enlargeEdgeInset.right, height: bounds.size.height + enlargeEdgeInset.top + enlargeEdgeInset.bottom)

        if enlargeRect.contains(touchLocation) {
            var segment = 0
            if segmentWidthStyle == .fixed {
                segment = Int((touchLocation.x + scrollView.contentOffset.x - contentEdgeInset.left) / segmentWidth)
            } else if segmentWidthStyle == .dynamic {
                var widthLeft = touchLocation.x + scrollView.contentOffset.x - contentEdgeInset.left
                for width in segmentWidthsArray {
                    widthLeft -= width
                    if widthLeft <= 0 { break }
                    segment += 1
                }
            }

            var sectionsCount = 0
            if type == .images {
                sectionsCount = sectionImages.count
            } else if type == .textImages || type == .text {
                sectionsCount = sectionTitles.count
            }

            if segment != selectedSegmentIndex && segment < sectionsCount {
                if isTouchEnabled {
                    setSelectedSegmentIndex(segment, animated: shouldAnimateUserSelection, notify: true)
                }
            }
        }
    }

    override open func draw(_ rect: CGRect) {
        backgroundColor?.setFill()
        UIRectFill(bounds)

        selectionIndicatorShapeLayer.backgroundColor = selectionIndicatorColor?.cgColor
        selectionIndicatorStripLayer.backgroundColor = selectionIndicatorColor?.cgColor
        selectionIndicatorBoxLayer.backgroundColor = selectionIndicatorBoxColor?.cgColor
        selectionIndicatorBoxLayer.borderColor = selectionIndicatorBoxColor?.cgColor

        scrollView.layer.sublayers = nil
        let oldRect = rect
        accessibilityElements = []

        if type == .text {
            removeTitleBackgroundLayers()
            for idx in 0..<sectionTitles.count {
                let stringSize = measureTitleAtIndex(idx)
                let stringWidth = stringSize.width
                let stringHeight = stringSize.height
                var rectDiv = CGRect.zero
                var fullRect = CGRect.zero

                let locationUp: CGFloat = selectionIndicatorLocation == .top ? 1.0 : 0
                let selectionStyleNotBox: CGFloat = selectionStyle != .box ? 1.0 : 0

                let y = round((CGRectGetHeight(frame) - selectionStyleNotBox * selectionIndicatorHeight) / 2 - stringHeight / 2 + selectionIndicatorHeight * locationUp)
                var rect: CGRect
                if segmentWidthStyle == .fixed {
                    rect = CGRect(x: (segmentWidth * CGFloat(idx)) + (segmentWidth - stringWidth) / 2, y: y, width: stringWidth, height: stringHeight)
                    rectDiv = CGRect(x: (segmentWidth * CGFloat(idx)) - (verticalDividerWidth / 2) + contentEdgeInset.left, y: selectionIndicatorHeight * 2, width: verticalDividerWidth, height: frame.size.height - (selectionIndicatorHeight * 4))
                    fullRect = CGRect(x: segmentWidth * CGFloat(idx) + contentEdgeInset.left, y: 0, width: segmentWidth, height: oldRect.size.height)
                } else {
                    var xOffset: CGFloat = 0
                    var i = 0
                    for width in segmentWidthsArray {
                        if idx == i {
                            break
                        }
                        xOffset = xOffset + width
                        i += 1
                    }

                    let widthForIndex = segmentWidthsArray[idx]
                    rect = CGRect(x: xOffset, y: y, width: widthForIndex, height: stringHeight)
                    fullRect = CGRect(x: xOffset + contentEdgeInset.left, y: 0, width: widthForIndex, height: oldRect.size.height)
                    rectDiv = CGRect(x: xOffset - (verticalDividerWidth / 2) + contentEdgeInset.left, y: selectionIndicatorHeight * 2, width: verticalDividerWidth, height: frame.size.height - (selectionIndicatorHeight * 4))
                }

                rect = CGRect(x: ceil(rect.origin.x) + contentEdgeInset.left, y: ceil(rect.origin.y), width: ceil(rect.size.width), height: ceil(rect.size.height))

                let titleLayer = CATextLayer()
                titleLayer.frame = rect
                titleLayer.alignmentMode = .center
                titleLayer.string = attributedTitleAtIndex(idx)
                titleLayer.contentsScale = UIScreen.main.scale
                scrollView.layer.addSublayer(titleLayer)

                if isVerticalDividerEnabled && idx > 0 {
                    let verticalDividerLayer = CALayer()
                    verticalDividerLayer.frame = rectDiv
                    verticalDividerLayer.backgroundColor = verticalDividerColor?.cgColor
                    scrollView.layer.addSublayer(verticalDividerLayer)
                }

                if _accessibilityElements.count <= idx {
                    let element = SegmentedAccessibilityElement(accessibilityContainer: self)
                    element.delegate = self
                    element.accessibilityLabel = sectionTitles.count > idx ? sectionTitles[idx].stringValue : "item \(idx + 1)"
                    element.accessibilityFrame = convert(fullRect, to: nil)
                    if selectedSegmentIndex == idx {
                        element.accessibilityTraits = [.button, .selected]
                    } else {
                        element.accessibilityTraits = .button
                    }
                    _accessibilityElements.append(element)
                } else {
                    var offset: CGFloat = 0
                    for i in 0..<idx {
                        let accessibilityItem = _accessibilityElements[i]
                        offset += accessibilityItem.accessibilityFrame.size.width
                    }
                    let element = _accessibilityElements[idx]
                    let newRect = CGRect(x: offset - scrollView.contentOffset.x + contentEdgeInset.left, y: 0, width: element.accessibilityFrame.size.width, height: element.accessibilityFrame.size.height)
                    element.accessibilityFrame = convert(newRect, to: nil)
                    if selectedSegmentIndex == idx {
                        element.accessibilityTraits = [.button, .selected]
                    } else {
                        element.accessibilityTraits = .button
                    }
                }

                addBackgroundAndBorderLayer(rect: fullRect, index: idx)
            }
        } else if type == .images {
            removeTitleBackgroundLayers()
            for (idx, icon) in sectionImages.enumerated() {
                let imageWidth: CGFloat = icon.size.width
                let imageHeight: CGFloat = icon.size.height
                let y: CGFloat = round(CGRectGetHeight(frame) - selectionIndicatorHeight) / 2 - imageHeight / 2 + ((selectionIndicatorLocation == .top) ? selectionIndicatorHeight : 0)
                let x: CGFloat = segmentWidth * CGFloat(idx) + (segmentWidth - imageWidth) / 2.0
                let rect = CGRect(x: x + contentEdgeInset.left, y: y, width: imageWidth, height: imageHeight)

                let imageLayer = CALayer()
                imageLayer.frame = rect
                if selectedSegmentIndex == idx && selectedSegmentIndex < sectionSelectedImages.count {
                    imageLayer.contents = sectionSelectedImages[idx].cgImage
                } else {
                    imageLayer.contents = icon.cgImage
                }

                scrollView.layer.addSublayer(imageLayer)
                if isVerticalDividerEnabled && idx > 0 {
                    let verticalDividerLayer = CALayer()
                    verticalDividerLayer.frame = CGRect(x: (segmentWidth * CGFloat(idx)) - (verticalDividerWidth / 2) + contentEdgeInset.left, y: selectionIndicatorHeight * 2, width: verticalDividerWidth, height: frame.size.height - (selectionIndicatorHeight * 4))
                    verticalDividerLayer.backgroundColor = verticalDividerColor?.cgColor
                    scrollView.layer.addSublayer(verticalDividerLayer)
                }

                if _accessibilityElements.count <= idx {
                    let element = SegmentedAccessibilityElement(accessibilityContainer: self)
                    element.delegate = self
                    element.accessibilityLabel = sectionTitles.count > idx ? sectionTitles[idx].stringValue : String(format: "item %u", idx + 1)
                    element.accessibilityFrame = convert(rect, to: nil)
                    if selectedSegmentIndex == idx {
                        element.accessibilityTraits = [.button, .selected]
                    } else {
                        element.accessibilityTraits = .button
                    }
                    _accessibilityElements.append(element)
                } else {
                    var offset: CGFloat = 0.0
                    for i in 0..<idx {
                        let accessibilityItem = _accessibilityElements[i]
                        offset += accessibilityItem.accessibilityFrame.size.width
                    }
                    let element = _accessibilityElements[idx]
                    let newRect = CGRect(x: offset - scrollView.contentOffset.x + contentEdgeInset.left, y: 0, width: element.accessibilityFrame.size.width, height: element.accessibilityFrame.size.height)
                    element.accessibilityFrame = convert(newRect, to: nil)
                    if selectedSegmentIndex == idx {
                        element.accessibilityTraits = [.button, .selected]
                    } else {
                        element.accessibilityTraits = .button
                    }
                }

                addBackgroundAndBorderLayer(rect: rect, index: idx)
            }
        } else if type == .textImages {
            removeTitleBackgroundLayers()
            for (idx, icon) in sectionImages.enumerated() {
                let imageWidth: CGFloat = icon.size.width
                let imageHeight: CGFloat = icon.size.height

                let stringSize: CGSize = measureTitleAtIndex(idx)
                let stringHeight: CGFloat = stringSize.height
                let stringWidth: CGFloat = stringSize.width

                var imageXOffset: CGFloat = segmentWidth * CGFloat(idx)
                var textXOffset: CGFloat = segmentWidth * CGFloat(idx)
                var imageYOffset: CGFloat = ceil((frame.size.height - imageHeight) / 2.0)
                var textYOffset: CGFloat = ceil((frame.size.height - stringHeight) / 2.0)

                if segmentWidthStyle == .fixed {
                    let isImageInLineWidthText = imagePosition == .leftOfText || imagePosition == .rightOfText
                    if isImageInLineWidthText {
                        let whitespace = segmentWidth - stringSize.width - imageWidth - textImageSpacing
                        if imagePosition == .leftOfText {
                            imageXOffset += whitespace / 2.0
                            textXOffset = imageXOffset + imageWidth + textImageSpacing
                        } else {
                            textXOffset += whitespace / 2.0
                            imageXOffset = textXOffset + stringWidth + textImageSpacing
                        }
                    } else {
                        imageXOffset = segmentWidth * CGFloat(idx) + (segmentWidth - imageWidth) / 2.0
                        textXOffset = segmentWidth * CGFloat(idx) + (segmentWidth - stringWidth) / 2.0

                        let whitespace = frame.height - imageHeight - stringHeight - textImageSpacing
                        if imagePosition == .aboveText {
                            imageYOffset = ceil(whitespace / 2.0)
                            textYOffset = imageYOffset + imageHeight + textImageSpacing
                        } else if imagePosition == .belowText {
                            textYOffset = ceil(whitespace / 2.0)
                            imageYOffset = textYOffset + stringHeight + textImageSpacing
                        }
                    }
                } else if segmentWidthStyle == .dynamic {
                    var xOffset: CGFloat = 0
                    var i = 0

                    for width in segmentWidthsArray {
                        if idx == i {
                            break
                        }
                        xOffset += width
                        i += 1
                    }

                    let isImageInLineWidthText = imagePosition == .leftOfText || imagePosition == .rightOfText
                    if isImageInLineWidthText {
                        if imagePosition == .leftOfText {
                            imageXOffset = xOffset
                            textXOffset = imageXOffset + imageWidth + textImageSpacing
                        } else {
                            textXOffset = xOffset
                            imageXOffset = textXOffset + stringWidth + textImageSpacing
                        }
                    } else {
                        imageXOffset = xOffset + (segmentWidthsArray[i] - imageWidth) / 2.0
                        textXOffset = xOffset + (segmentWidthsArray[i] - stringWidth) / 2.0

                        let whitespace = frame.height - imageHeight - stringHeight - textImageSpacing
                        if imagePosition == .aboveText {
                            imageYOffset = ceil(whitespace / 2.0)
                            textYOffset = imageYOffset + imageHeight + textImageSpacing
                        } else if imagePosition == .belowText {
                            textYOffset = ceil(whitespace / 2.0)
                            imageYOffset = textYOffset + stringHeight + textImageSpacing
                        }
                    }
                }

                let imageRect = CGRect(x: imageXOffset + contentEdgeInset.left, y: imageYOffset, width: imageWidth, height: imageHeight)
                let textRect = CGRect(x: ceil(textXOffset) + contentEdgeInset.left, y: ceil(textYOffset), width: ceil(stringWidth), height: ceil(stringHeight))

                let titleLayer = CATextLayer()
                titleLayer.frame = textRect
                titleLayer.alignmentMode = .center
                titleLayer.string = attributedTitleAtIndex(idx)
                let imageLayer = CALayer()
                imageLayer.frame = imageRect

                if selectedSegmentIndex == idx && idx < sectionSelectedImages.count {
                    imageLayer.contents = sectionSelectedImages[idx].cgImage
                } else {
                    imageLayer.contents = icon.cgImage
                }

                scrollView.layer.addSublayer(imageLayer)
                titleLayer.contentsScale = UIScreen.main.scale
                scrollView.layer.addSublayer(titleLayer)

                if _accessibilityElements.count <= idx {
                    let element = SegmentedAccessibilityElement(accessibilityContainer: self)
                    element.delegate = self
                    element.accessibilityLabel = sectionTitles.count > idx ? sectionTitles[idx].stringValue : "item \(idx + 1)"
                    element.accessibilityFrame = convert(CGRectUnion(textRect, imageRect), to: nil)
                    if selectedSegmentIndex == idx {
                        element.accessibilityTraits = [.button, .selected]
                    } else {
                        element.accessibilityTraits = .button
                    }
                    _accessibilityElements.append(element)
                } else {
                    var offset: CGFloat = 0.0
                    for i in 0..<idx {
                        let accessibilityItem = _accessibilityElements[i]
                        offset += accessibilityItem.accessibilityFrame.size.width
                    }
                    let element = _accessibilityElements[idx]
                    let newRect = CGRect(x: offset - scrollView.contentOffset.x + contentEdgeInset.left, y: 0, width: element.accessibilityFrame.size.width, height: element.accessibilityFrame.size.height)
                    element.accessibilityFrame = convert(newRect, to: nil)
                    if selectedSegmentIndex == idx {
                        element.accessibilityTraits = [.button, .selected]
                    } else {
                        element.accessibilityTraits = .button
                    }
                }

                addBackgroundAndBorderLayer(rect: imageRect, index: idx)
            }
        }

        if selectedSegmentIndex >= 0 && sectionCount > 0 {
            if selectionStyle == .arrow ||
                selectionStyle == .circle {
                if selectionIndicatorShapeLayer.superlayer == nil {
                    setShapeFrame()
                    scrollView.layer.addSublayer(selectionIndicatorShapeLayer)
                }
            } else {
                if selectionIndicatorStripLayer.superlayer == nil {
                    selectionIndicatorStripLayer.frame = frameForSelectionIndicator()
                    scrollView.layer.addSublayer(selectionIndicatorStripLayer)

                    if selectionStyle == .box && selectionIndicatorBoxLayer.superlayer == nil {
                        selectionIndicatorBoxLayer.frame = frameForFillerSelectionIndicator()
                        scrollView.layer.insertSublayer(selectionIndicatorBoxLayer, at: 0)
                    }
                }
            }
        }
    }

    // MARK: - Private
    private func measureTitleAtIndex(_ index: Int) -> CGSize {
        guard index < sectionTitles.count else {
            return CGSize.zero
        }

        let title = sectionTitles[index]
        var size = CGSize.zero
        let selected = (index == selectedSegmentIndex) ? true : false
        if let attributedTitle = title as? NSAttributedString {
            size = attributedTitle.size()
        } else if let titleFormatter {
            size = titleFormatter(self, title.stringValue, index, selected).size()
        } else {
            let titleAttrs = selected || useSelectedTitleTextAttributesSize ? resultingSelectedTitleTextAttributes() : resultingTitleTextAttributes()
            let attributedString = NSAttributedString(string: title.stringValue, attributes: titleAttrs)
            size = attributedString.size()
        }
        return CGRect(origin: CGPoint.zero, size: size).integral.size
    }

    private func attributedTitleAtIndex(_ index: Int) -> NSAttributedString {
        let title = sectionTitles[index]
        let selected = (index == selectedSegmentIndex) ? true : false

        if let attributedTitle = title as? NSAttributedString {
            return attributedTitle
        } else if let titleFormatter {
            return titleFormatter(self, title.stringValue, index, selected)
        } else {
            let titleAttrs = selected ? resultingSelectedTitleTextAttributes() : resultingTitleTextAttributes()
            return NSAttributedString(string: title.stringValue, attributes: titleAttrs)
        }
    }

    private func removeTitleBackgroundLayers() {
        if segmentBackgroundLayers.count > 0 {
            segmentBackgroundLayers.forEach { $0.removeFromSuperlayer() }
            segmentBackgroundLayers.removeAll()
        }

        titleBackgroundLayers.forEach { $0.removeFromSuperlayer() }
        titleBackgroundLayers.removeAll()
    }

    private func addBackgroundAndBorderLayer(rect fullRect: CGRect, index: Int) {
        if let segmentBackgroundColor {
            let backgroundLayer = CALayer()
            backgroundLayer.zPosition = -1
            backgroundLayer.backgroundColor = segmentBackgroundColor.cgColor
            backgroundLayer.opacity = segmentBackgroundOpacity
            backgroundLayer.cornerRadius = segmentBackgroundCornerRadius
            backgroundLayer.frame = CGRect(x: fullRect.origin.x + segmentBackgroundEdgeInset.left, y: fullRect.origin.y + segmentBackgroundEdgeInset.top, width: fullRect.size.width - segmentBackgroundEdgeInset.left - segmentBackgroundEdgeInset.right, height: fullRect.size.height - segmentBackgroundEdgeInset.top - segmentBackgroundEdgeInset.bottom)
            scrollView.layer.insertSublayer(backgroundLayer, at: 0)
            segmentBackgroundLayers.append(backgroundLayer)
        }

        let backgroundLayer = CALayer()
        backgroundLayer.frame = fullRect
        layer.insertSublayer(backgroundLayer, at: 0)
        titleBackgroundLayers.append(backgroundLayer)

        if borderType.contains(.top) {
            let borderLayer = CALayer()
            borderLayer.frame = CGRect(x: 0, y: 0, width: fullRect.size.width, height: borderWidth)
            borderLayer.backgroundColor = borderColor?.cgColor
            backgroundLayer.addSublayer(borderLayer)
        }
        if borderType.contains(.left) {
            let borderLayer = CALayer()
            borderLayer.frame = CGRect(x: 0, y: 0, width: borderWidth, height: fullRect.size.height)
            borderLayer.backgroundColor = borderColor?.cgColor
            backgroundLayer.addSublayer(borderLayer)
        }
        if borderType.contains(.bottom) {
            let borderLayer = CALayer()
            borderLayer.frame = CGRect(x: 0, y: fullRect.size.height - borderWidth, width: fullRect.size.width, height: borderWidth)
            borderLayer.backgroundColor = borderColor?.cgColor
            backgroundLayer.addSublayer(borderLayer)
        }
        if borderType.contains(.right) {
            let borderLayer = CALayer()
            borderLayer.frame = CGRect(x: fullRect.size.width - borderWidth, y: 0, width: borderWidth, height: fullRect.size.height)
            borderLayer.backgroundColor = borderColor?.cgColor
            backgroundLayer.addSublayer(borderLayer)
        }

        segmentCustomBlock?(self, index, fullRect)
    }

    private func setShapeFrame() {
        selectionIndicatorShapeLayer.frame = frameForSelectionIndicator()
        selectionIndicatorShapeLayer.mask = nil

        let shapePath: UIBezierPath
        if selectionStyle == .arrow {
            shapePath = UIBezierPath()

            var p1 = CGPoint.zero
            var p2 = CGPoint.zero
            var p3 = CGPoint.zero

            if selectionIndicatorLocation == .bottom {
                p1 = CGPoint(x: selectionIndicatorShapeLayer.bounds.size.width / 2, y: 0)
                p2 = CGPoint(x: 0, y: selectionIndicatorShapeLayer.bounds.size.height)
                p3 = CGPoint(x: selectionIndicatorShapeLayer.bounds.size.width, y: selectionIndicatorShapeLayer.bounds.size.height)
            }

            if selectionIndicatorLocation == .top {
                p1 = CGPoint(x: selectionIndicatorShapeLayer.bounds.size.width / 2, y: selectionIndicatorShapeLayer.bounds.size.height)
                p2 = CGPoint(x: selectionIndicatorShapeLayer.bounds.size.width, y: 0)
                p3 = CGPoint(x: 0, y: 0)
            }

            shapePath.move(to: p1)
            shapePath.addLine(to: p2)
            shapePath.addLine(to: p3)
            shapePath.close()
        } else {
            shapePath = UIBezierPath(roundedRect: selectionIndicatorShapeLayer.bounds, cornerRadius: selectionIndicatorHeight / 2)
        }

        let maskLayer = CAShapeLayer()
        maskLayer.frame = selectionIndicatorShapeLayer.bounds
        maskLayer.path = shapePath.cgPath
        selectionIndicatorShapeLayer.mask = maskLayer
    }

    private func frameForSelectionIndicator() -> CGRect {
        var indicatorYOffset: CGFloat = 0.0
        if selectionIndicatorLocation == .bottom {
            indicatorYOffset = bounds.size.height - selectionIndicatorHeight + selectionIndicatorEdgeInsets.bottom
        }
        if selectionIndicatorLocation == .top {
            indicatorYOffset = selectionIndicatorEdgeInsets.top
        }

        var sectionWidth: CGFloat = 0.0
        if type == .text {
            let stringWidth = measureTitleAtIndex(selectedSegmentIndex).width
            sectionWidth = stringWidth
        } else if type == .images {
            let sectionImage = sectionImages[selectedSegmentIndex]
            let imageWidth = sectionImage.size.width
            sectionWidth = imageWidth
        } else if type == .textImages {
            let stringWidth = measureTitleAtIndex(selectedSegmentIndex).width
            let sectionImage = sectionImages[selectedSegmentIndex]
            let imageWidth = sectionImage.size.width
            sectionWidth = max(stringWidth, imageWidth)
        }

        if selectionStyle == .arrow || selectionStyle == .circle {
            var widthToEndOfSelectedSegment: CGFloat = 0.0
            var widthToStartOfSelectedIndex: CGFloat = 0.0

            if segmentWidthStyle == .dynamic {
                var i = 0
                for width in segmentWidthsArray {
                    if selectedSegmentIndex == i {
                        widthToEndOfSelectedSegment = widthToStartOfSelectedIndex + width
                        break
                    }
                    widthToStartOfSelectedIndex = widthToStartOfSelectedIndex + width
                    i += 1
                }
            } else {
                widthToEndOfSelectedSegment = (segmentWidth * CGFloat(selectedSegmentIndex)) + segmentWidth
                widthToStartOfSelectedIndex = (segmentWidth * CGFloat(selectedSegmentIndex))
            }

            let x = widthToStartOfSelectedIndex + ((widthToEndOfSelectedSegment - widthToStartOfSelectedIndex) / 2) - (selectionIndicatorHeight / 2)
            if selectionStyle == .arrow {
                return CGRect(x: x - (selectionIndicatorHeight / 2) + contentEdgeInset.left, y: indicatorYOffset, width: selectionIndicatorHeight * 2, height: selectionIndicatorHeight)
            } else {
                return CGRect(x: x + contentEdgeInset.left, y: indicatorYOffset, width: selectionIndicatorHeight, height: selectionIndicatorHeight)
            }
        } else {
            if selectionStyle == .textWidthStripe && sectionWidth <= segmentWidth && segmentWidthStyle != .dynamic {
                let widthToEndOfSelectedSegment = (segmentWidth * CGFloat(selectedSegmentIndex)) + segmentWidth
                let widthToStartOfSelectedIndex = (segmentWidth * CGFloat(selectedSegmentIndex))

                let x = ((widthToEndOfSelectedSegment - widthToStartOfSelectedIndex) / 2) + (widthToStartOfSelectedIndex - sectionWidth / 2)
                return CGRect(x: x + selectionIndicatorEdgeInsets.left + contentEdgeInset.left, y: indicatorYOffset, width: sectionWidth - selectionIndicatorEdgeInsets.right, height: selectionIndicatorHeight)
            } else {
                if segmentWidthStyle == .dynamic {
                    var selectedSegmentOffset: CGFloat = 0.0

                    var i = 0
                    for width in segmentWidthsArray {
                        if selectedSegmentIndex == i {
                            break
                        }
                        selectedSegmentOffset = selectedSegmentOffset + width
                        i += 1
                    }
                    if selectionStyle == .textWidthStripe {
                        return CGRect(x: selectedSegmentOffset + selectionIndicatorEdgeInsets.left + segmentEdgeInset.left + contentEdgeInset.left, y: indicatorYOffset, width: segmentWidthsArray[selectedSegmentIndex] - selectionIndicatorEdgeInsets.right - segmentEdgeInset.left - segmentEdgeInset.right, height: selectionIndicatorHeight + selectionIndicatorEdgeInsets.bottom)
                    } else {
                        return CGRect(x: selectedSegmentOffset + selectionIndicatorEdgeInsets.left + contentEdgeInset.left, y: indicatorYOffset, width: segmentWidthsArray[selectedSegmentIndex] - selectionIndicatorEdgeInsets.right, height: selectionIndicatorHeight + selectionIndicatorEdgeInsets.bottom)
                    }
                }

                return CGRect(x: segmentWidth * CGFloat(selectedSegmentIndex) + selectionIndicatorEdgeInsets.left + contentEdgeInset.left, y: indicatorYOffset, width: segmentWidth - selectionIndicatorEdgeInsets.left - selectionIndicatorEdgeInsets.right, height: selectionIndicatorHeight)
            }
        }
    }

    private func frameForFillerSelectionIndicator() -> CGRect {
        if segmentWidthStyle == .dynamic {
            var selectedSegmentOffset: CGFloat = 0.0

            var i = 0
            for width in segmentWidthsArray {
                if selectedSegmentIndex == i { break }
                selectedSegmentOffset += width
                i += 1
            }

            return CGRect(x: selectedSegmentOffset + selectionIndicatorBoxEdgeInsets.left + contentEdgeInset.left, y: selectionIndicatorBoxEdgeInsets.top, width: segmentWidthsArray[selectedSegmentIndex] - selectionIndicatorBoxEdgeInsets.left - selectionIndicatorBoxEdgeInsets.right, height: frame.height - selectionIndicatorBoxEdgeInsets.top - selectionIndicatorBoxEdgeInsets.bottom)
        }

        return CGRect(x: segmentWidth * CGFloat(selectedSegmentIndex) + selectionIndicatorBoxEdgeInsets.left + contentEdgeInset.left, y: selectionIndicatorBoxEdgeInsets.top, width: segmentWidth - selectionIndicatorBoxEdgeInsets.left - selectionIndicatorBoxEdgeInsets.right, height: frame.height - selectionIndicatorBoxEdgeInsets.top - selectionIndicatorBoxEdgeInsets.bottom)
    }

    private func updateSegmentsRects() {
        scrollView.contentInset = .zero
        scrollView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)

        if sectionCount > 0 {
            segmentWidth = frame.size.width / CGFloat(sectionCount)
        }

        if type == .text && segmentWidthStyle == .fixed {
            for (index, _) in sectionTitles.enumerated() {
                let stringWidth = measureTitleAtIndex(index).width + segmentEdgeInset.left + segmentEdgeInset.right
                segmentWidth = max(stringWidth, segmentWidth)
            }
        } else if type == .text && segmentWidthStyle == .dynamic {
            var mutableSegmentWidths: [CGFloat] = []
            var totalWidth: CGFloat = 0.0

            for (index, _) in sectionTitles.enumerated() {
                let stringWidth = measureTitleAtIndex(index).width + segmentEdgeInset.left + segmentEdgeInset.right
                totalWidth += stringWidth
                mutableSegmentWidths.append(stringWidth)
            }

            if shouldStretchSegmentsToScreenSize && mutableSegmentWidths.count > 0 && totalWidth < bounds.size.width {
                let whitespace = bounds.size.width - totalWidth
                let whitespaceForSegment = whitespace / CGFloat(mutableSegmentWidths.count)
                for (idx, width) in mutableSegmentWidths.enumerated() {
                    let extendedWidth = whitespaceForSegment + width
                    mutableSegmentWidths[idx] = extendedWidth
                }
            }

            segmentWidthsArray = mutableSegmentWidths
        } else if type == .images {
            for sectionImage in sectionImages {
                let imageWidth = sectionImage.size.width + segmentEdgeInset.left + segmentEdgeInset.right
                segmentWidth = max(imageWidth, segmentWidth)
            }
        } else if type == .textImages && segmentWidthStyle == .fixed {
            for (index, _) in sectionTitles.enumerated() {
                let stringWidth = measureTitleAtIndex(index).width + segmentEdgeInset.left + segmentEdgeInset.right
                segmentWidth = max(stringWidth, segmentWidth)
            }
        } else if type == .textImages && segmentWidthStyle == .dynamic {
            var mutableSegmentWidths: [CGFloat] = []
            var totalWidth: CGFloat = 0.0

            for (idx, _) in sectionTitles.enumerated() {
                let stringWidth = measureTitleAtIndex(idx).width + segmentEdgeInset.right
                let sectionImage = sectionImages[idx]
                let imageWidth = sectionImage.size.width + segmentEdgeInset.left

                var combinedWidth: CGFloat = 0.0
                if imagePosition == .leftOfText || imagePosition == .rightOfText {
                    combinedWidth = imageWidth + stringWidth + textImageSpacing
                } else {
                    combinedWidth = max(imageWidth, stringWidth)
                }

                totalWidth += combinedWidth
                mutableSegmentWidths.append(combinedWidth)
            }

            if shouldStretchSegmentsToScreenSize && mutableSegmentWidths.count > 0 && totalWidth < bounds.size.width {
                let whitespace = bounds.size.width - totalWidth
                let whitespaceForSegment = whitespace / CGFloat(mutableSegmentWidths.count)
                for (idx, width) in mutableSegmentWidths.enumerated() {
                    let extendedWidth = whitespaceForSegment + width
                    mutableSegmentWidths[idx] = extendedWidth
                }
            }

            segmentWidthsArray = mutableSegmentWidths
        }

        scrollView.isScrollEnabled = isUserDraggable
        scrollView.contentSize = CGSize(width: totalSegmentedControlWidth() + contentEdgeInset.left + contentEdgeInset.right, height: frame.size.height)
    }

    private func totalSegmentedControlWidth() -> CGFloat {
        if type == .text && segmentWidthStyle == .fixed {
            return CGFloat(sectionTitles.count) * segmentWidth
        } else if segmentWidthStyle == .dynamic {
            return segmentWidthsArray.reduce(0, +)
        } else {
            return CGFloat(sectionImages.count) * segmentWidth
        }
    }

    private func scrollToSelectedSegmentIndex(animated: Bool) {
        scrollTo(selectedSegmentIndex, animated: animated)
    }

    private func scrollTo(_ index: Int, animated: Bool) {
        var rectForSelectedIndex: CGRect = .zero
        var selectedSegmentOffset: CGFloat = 0
        if segmentWidthStyle == .fixed {
            rectForSelectedIndex = CGRect(x: segmentWidth * CGFloat(index) + contentEdgeInset.left, y: 0, width: segmentWidth, height: frame.size.height)
            selectedSegmentOffset = (frame.width / 2) - (segmentWidth / 2)
        } else {
            var offsetter: CGFloat = 0
            for (i, width) in segmentWidthsArray.enumerated() {
                if index == i { break }
                offsetter += width
            }

            rectForSelectedIndex = CGRect(x: offsetter + contentEdgeInset.left, y: 0, width: segmentWidthsArray[index], height: frame.size.height)
            selectedSegmentOffset = (frame.width / 2) - (segmentWidthsArray[index] / 2)
        }

        var rectToScrollTo = rectForSelectedIndex
        rectToScrollTo.origin.x -= selectedSegmentOffset
        rectToScrollTo.size.width += selectedSegmentOffset * 2
        scrollView.scrollRectToVisible(rectToScrollTo, animated: animated)

        if !animated {
            BannerView.Configuration.trackExposureBlock?(self)
        }
    }

    private func setSelectedSegmentIndex(_ index: Int, animated: Bool, notify: Bool) {
        _selectedSegmentIndex = index
        setNeedsDisplay()

        if index < 0 || sectionCount < 1 {
            selectionIndicatorShapeLayer.removeFromSuperlayer()
            selectionIndicatorStripLayer.removeFromSuperlayer()
            selectionIndicatorBoxLayer.removeFromSuperlayer()
        } else {
            if segmentWidthStyle == .dynamic && sectionCount != segmentWidthsArray.count {
                layoutIfNeeded()
                if sectionCount != segmentWidthsArray.count { return }
            }

            scrollToSelectedSegmentIndex(animated: animated)

            if animated {
                if selectionStyle == .arrow || selectionStyle == .circle {
                    if selectionIndicatorShapeLayer.superlayer == nil {
                        scrollView.layer.addSublayer(selectionIndicatorShapeLayer)

                        setSelectedSegmentIndex(index, animated: false, notify: true)
                        return
                    }
                } else {
                    if selectionIndicatorStripLayer.superlayer == nil {
                        scrollView.layer.addSublayer(selectionIndicatorStripLayer)

                        if selectionStyle == .box && selectionIndicatorBoxLayer.superlayer == nil {
                            scrollView.layer.insertSublayer(selectionIndicatorBoxLayer, at: 0)
                        }

                        setSelectedSegmentIndex(index, animated: false, notify: true)
                        return
                    }
                }

                if notify {
                    notifyForSegmentChangeToIndex(index)
                }

                selectionIndicatorShapeLayer.actions = nil
                selectionIndicatorStripLayer.actions = nil
                selectionIndicatorBoxLayer.actions = nil

                CATransaction.begin()
                CATransaction.setAnimationDuration(0.15)
                CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .linear))
                setShapeFrame()
                selectionIndicatorBoxLayer.frame = frameForSelectionIndicator()
                selectionIndicatorStripLayer.frame = frameForSelectionIndicator()
                selectionIndicatorBoxLayer.frame = frameForFillerSelectionIndicator()
                CATransaction.commit()
            } else {
                let newActions = ["position": NSNull(), "bounds": NSNull()]
                selectionIndicatorShapeLayer.actions = newActions
                setShapeFrame()

                selectionIndicatorStripLayer.actions = newActions
                selectionIndicatorStripLayer.frame = frameForSelectionIndicator()

                selectionIndicatorBoxLayer.actions = newActions
                selectionIndicatorBoxLayer.frame = frameForFillerSelectionIndicator()

                if notify {
                    notifyForSegmentChangeToIndex(index)
                }
            }
        }
    }

    private func notifyForSegmentChangeToIndex(_ index: Int) {
        if superview != nil {
            sendActions(for: .valueChanged)
        }

        indexChangedBlock?(index)
        _ = BannerView.Configuration.trackClickBlock?(self, IndexPath(row: index, section: 0))
    }

    private func resultingTitleTextAttributes() -> [NSAttributedString.Key: Any] {
        var resultingAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 19),
            .foregroundColor: UIColor.black
        ]
        if let titleTextAttributes {
            resultingAttrs.merge(titleTextAttributes) { $1 }
        }
        return resultingAttrs
    }

    private func resultingSelectedTitleTextAttributes() -> [NSAttributedString.Key: Any] {
        var resultingAttrs = resultingTitleTextAttributes()
        if let selectedTitleTextAttributes {
            resultingAttrs.merge(selectedTitleTextAttributes) { $1 }
        }
        return resultingAttrs
    }

    // MARK: - UIScrollViewDelegate
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        for (index, element) in _accessibilityElements.enumerated() {
            var offset: CGFloat = 0
            for i in 0..<index {
                let elem = _accessibilityElements[i]
                offset += elem.accessibilityFrame.size.width
            }
            let rect = CGRect(x: offset - scrollView.contentOffset.x + contentEdgeInset.left, y: 0, width: element.accessibilityFrame.size.width, height: element.accessibilityFrame.size.height)
            element.accessibilityFrame = convert(rect, to: nil)
        }
    }

    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            BannerView.Configuration.trackExposureBlock?(self)
        }
    }

    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        BannerView.Configuration.trackExposureBlock?(self)
    }

    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        BannerView.Configuration.trackExposureBlock?(self)
    }

    // MARK: - SegmentedAccessibilityDelegate
    func scrollToAccessibilityElement(_ sender: Any) {
        if let element = sender as? SegmentedAccessibilityElement,
           let index = _accessibilityElements.firstIndex(of: element) {
            scrollTo(index, animated: false)
        }
    }

    // MARK: - UIAccessibilityContainer
    override open var accessibilityElements: [Any]? {
        get { _accessibilityElements }
        set { _accessibilityElements = newValue as? [SegmentedAccessibilityElement] ?? [] }
    }

    private var _accessibilityElements: [SegmentedAccessibilityElement] = []

    override open var isAccessibilityElement: Bool {
        get { false }
        set { super.isAccessibilityElement = newValue }
    }

    override open func accessibilityElementCount() -> Int {
        _accessibilityElements.count
    }

    override open func index(ofAccessibilityElement element: Any) -> Int {
        if let element = element as? SegmentedAccessibilityElement {
            return _accessibilityElements.firstIndex(of: element) ?? NSNotFound
        }
        return NSNotFound
    }

    override open func accessibilityElement(at index: Int) -> Any? {
        _accessibilityElements.safeElement(index)
    }
}

class SegmentedScrollView: UIScrollView {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isDragging {
            next?.touchesBegan(touches, with: event)
        } else {
            super.touchesBegan(touches, with: event)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isDragging {
            next?.touchesMoved(touches, with: event)
        } else {
            super.touchesMoved(touches, with: event)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isDragging {
            next?.touchesEnded(touches, with: event)
        } else {
            super.touchesEnded(touches, with: event)
        }
    }
}

@MainActor protocol SegmentedAccessibilityDelegate: NSObjectProtocol {
    func scrollToAccessibilityElement(_ sender: Any)
}

class SegmentedAccessibilityElement: UIAccessibilityElement {
    weak var delegate: SegmentedAccessibilityDelegate?

    override func accessibilityElementDidBecomeFocused() {
        delegate?.scrollToAccessibilityElement(self)
    }
}
