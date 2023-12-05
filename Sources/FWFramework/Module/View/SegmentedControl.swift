//
//  SegmentedControl.swift
//  FWFramework
//
//  Created by wuyong on 2023/12/05.
//

import UIKit

public enum SegmentedControlSelectionStyle: Int {
    case textWidthStripe
    case fullWidthStripe
    case box
    case arrow
    case circle
}

public enum SegmentedControlSelectionIndicatorLocation: Int {
    case top
    case bottom
    case none
}

public enum SegmentedControlSegmentWidthStyle: Int {
    case fixed
    case dynamic
}

public struct SegmentedControlBorderType: OptionSet {
    public let rawValue: Int
    
    public static let top: LogType = .init(rawValue: 1 << 0)
    public static let left: LogType = .init(rawValue: 1 << 1)
    public static let bottom: LogType = .init(rawValue: 1 << 2)
    public static let right: LogType = .init(rawValue: 1 << 3)
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public enum SegmentedControlType: Int {
    case text
    case images
    case textImages
}

public enum SegmentedControlImagePosition: Int {
    case behindText
    case leftOfText
    case rightOfText
    case aboveText
    case belowText
}

/// [HMSegmentedControl](https://github.com/HeshamMegid/HMSegmentedControl)
open class SegmentedControl: UIControl, UIScrollViewDelegate, SegmentedAccessibilityDelegate {
    
    open var sectionTitles: [StringParameter]? {
        didSet {
            setNeedsLayout()
            setNeedsDisplay()
        }
    }
    open var sectionImages: [UIImage]? {
        didSet {
            setNeedsLayout()
            setNeedsDisplay()
        }
    }
    open var sectionSelectedImages: [UIImage]?
    
    open var indexChangedBlock: ((Int) -> Void)?
    open var titleFormatter: ((_ segmentedControl: SegmentedControl, _ title: String, _ index: Int, _ selected: Bool) -> NSAttributedString)?
    
    open var titleTextAttributes: [NSAttributedString.Key: Any]?
    open var selectedTitleTextAttributes: [NSAttributedString.Key: Any]?
    
    open override var backgroundColor: UIColor? {
        get { return _backgroundColor }
        set { _backgroundColor = newValue }
    }
    private var _backgroundColor: UIColor? = .white
    open var selectionIndicatorColor: UIColor? = UIColor(red: 52.0/255.0, green: 181.0/255.0, blue: 229.0/255.0, alpha: 1.0)
    open var selectionIndicatorBoxColor: UIColor? = UIColor(red: 52.0/255.0, green: 181.0/255.0, blue: 229.0/255.0, alpha: 1.0)
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
            return _segmentWidthStyle
        }
        set {
            if self.type == .images {
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
    open var userDraggable: Bool = true
    open var touchEnabled: Bool = true
    open var verticalDividerEnabled: Bool = false
    open var stretchSegmentsToScreenSize: Bool = false
    /// 当前选中index, -1表示不选中
    open var selectedSegmentIndex: Int {
        get {
            return _selectedSegmentIndex
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
    open var segmentEdgeInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
    open var segmentBackgroundColor: UIColor?
    open var segmentBackgroundOpacity: CGFloat = 1.0
    open var segmentBackgroundCornerRadius: CGFloat = 0
    open var segmentBackgroundEdgeInset: UIEdgeInsets = .zero
    open var segmentCustomBlock: ((_ segmentedControl: SegmentedControl, _ index: Int, _ rect: CGRect) -> Void)?
    open var enlargeEdgeInset: UIEdgeInsets = .zero
    open var shouldAnimateUserSelection: Bool = true
    
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
    
    private var segmentWidth: CGFloat = 0
    private var segmentWidthsArray: [CGFloat] = []
    private var segmentAccessibilityElements: [SegmentedAccessibilityElement] = []
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
        
        self.isOpaque = false
        self.contentMode = .redraw
    }
    
    // MARK: - Public
    /// 设置选中index, -1表示不选中
    open func setSelectedSegmentIndex(_ index: Int, animated: Bool) {
        setSelectedSegmentIndex(index, animated: animated, notify: false)
    }
    
    // MARK: - Override
    open override func awakeFromNib() {
        super.awakeFromNib()
        segmentWidth = 0
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        updateSegmentsRects()
    }
    
    open override var frame: CGRect {
        didSet {
            updateSegmentsRects()
        }
    }
    
    open override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview == nil { return }
        
        if sectionTitles != nil || sectionImages != nil {
            updateSegmentsRects()
        }
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        
        let enlargeRect = CGRect(x: bounds.origin.x - enlargeEdgeInset.left, y: bounds.origin.y - enlargeEdgeInset.top, width: bounds.size.width + enlargeEdgeInset.left + enlargeEdgeInset.right, height: bounds.size.height + enlargeEdgeInset.top + enlargeEdgeInset.bottom)
        
        if enlargeRect.contains(touchLocation) {
            var segment: Int = 0
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
            
            var sectionsCount: Int = 0
            if type == .images {
                sectionsCount = sectionImages?.count ?? 0
            } else if type == .textImages || type == .text {
                sectionsCount = sectionTitles?.count ?? 0
            }
            
            if segment != selectedSegmentIndex && segment < sectionsCount {
                if touchEnabled {
                    setSelectedSegmentIndex(segment, animated: shouldAnimateUserSelection, notify: true)
                }
            }
        }
    }
    
    open override func draw(_ rect: CGRect) {
        
    }
    
    // MARK: - Private
    private func measureTitleAtIndex(_ index: Int) -> CGSize {
        guard index < (sectionTitles?.count ?? 0) else {
            return CGSize.zero
        }
        
        let title = sectionTitles?[index]
        var size = CGSize.zero
        let selected = (index == selectedSegmentIndex) ? true : false
        if let attributedTitle = title as? NSAttributedString {
            size = attributedTitle.size()
        } else if let titleFormatter = titleFormatter {
            size = titleFormatter(self, title?.stringValue ?? "", index, selected).size()
        } else {
            let titleAttrs = selected ? resultingSelectedTitleTextAttributes() : resultingTitleTextAttributes()
            let attributedString = NSAttributedString(string: title?.stringValue ?? "", attributes: titleAttrs)
            size = attributedString.size()
        }
        return CGRect(origin: CGPoint.zero, size: size).integral.size
    }
    
    private func attributedTitleAtIndex(_ index: Int) -> NSAttributedString {
        let title = sectionTitles?[index]
        let selected = (index == selectedSegmentIndex) ? true : false
        
        if let attributedTitle = title as? NSAttributedString {
            return attributedTitle
        } else if let titleFormatter = titleFormatter {
            return titleFormatter(self, title?.stringValue ?? "", index, selected)
        } else {
            let titleAttrs = selected ? resultingSelectedTitleTextAttributes() : resultingTitleTextAttributes()
            return NSAttributedString(string: title?.stringValue ?? "", attributes: titleAttrs)
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
        return .zero
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
            
            return CGRect(x: selectedSegmentOffset + selectionIndicatorBoxEdgeInsets.left + contentEdgeInset.left, y: selectionIndicatorBoxEdgeInsets.top, width: segmentWidthsArray[selectedSegmentIndex] - selectionIndicatorBoxEdgeInsets.left - selectionIndicatorBoxEdgeInsets.right, height: self.frame.height - selectionIndicatorBoxEdgeInsets.top - selectionIndicatorBoxEdgeInsets.bottom)
        }
        
        return CGRect(x: segmentWidth * CGFloat(selectedSegmentIndex) + selectionIndicatorBoxEdgeInsets.left + contentEdgeInset.left, y: selectionIndicatorBoxEdgeInsets.top, width: segmentWidth - selectionIndicatorBoxEdgeInsets.left - selectionIndicatorBoxEdgeInsets.right, height: self.frame.height - selectionIndicatorBoxEdgeInsets.top - selectionIndicatorBoxEdgeInsets.bottom)
    }
    
    private func updateSegmentsRects() {
        
    }
    
    private func sectionCount() -> Int {
        if self.type == .text {
            return sectionTitles?.count ?? 0
        } else if self.type == .images || self.type == .textImages {
            return sectionImages?.count ?? 0
        }
        return 0
    }
    
    private func totalSegmentedControlWidth() -> CGFloat {
        if self.type == .text && segmentWidthStyle == .fixed {
            return CGFloat(sectionTitles?.count ?? 0) * segmentWidth
        } else if segmentWidthStyle == .dynamic {
            return segmentWidthsArray.reduce(0, +)
        } else {
            return CGFloat(sectionImages?.count ?? 0) * segmentWidth
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
            fw_statisticalCheckExposure()
        }
    }
    
    private func setSelectedSegmentIndex(_ index: Int, animated: Bool, notify: Bool) {
        _selectedSegmentIndex = index
        setNeedsDisplay()
        
        if index < 0 || sectionCount() < 1 {
            selectionIndicatorShapeLayer.removeFromSuperlayer()
            selectionIndicatorStripLayer.removeFromSuperlayer()
            selectionIndicatorBoxLayer.removeFromSuperlayer()
        } else {
            if segmentWidthStyle == .dynamic && sectionCount() != segmentWidthsArray.count {
                layoutIfNeeded()
                if sectionCount() != segmentWidthsArray.count { return }
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
        fw_statisticalTrackClick(indexPath: IndexPath(row: index, section: 0), event: nil)
    }
    
    private func resultingTitleTextAttributes() -> [NSAttributedString.Key: Any] {
        var resultingAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 19),
            .foregroundColor: UIColor.black,
        ]
        if let titleTextAttributes = titleTextAttributes {
            resultingAttrs.merge(titleTextAttributes) { $1 }
        }
        return resultingAttrs
    }
    
    private func resultingSelectedTitleTextAttributes() -> [NSAttributedString.Key: Any] {
        var resultingAttrs = resultingTitleTextAttributes()
        if let selectedTitleTextAttributes = selectedTitleTextAttributes {
            resultingAttrs.merge(selectedTitleTextAttributes) { $1 }
        }
        return resultingAttrs
    }
    
    // MARK: - UIScrollViewDelegate
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        for (index, element) in segmentAccessibilityElements.enumerated() {
            var offset: CGFloat = 0
            for i in 0..<index {
                let elem = segmentAccessibilityElements[i]
                offset += elem.accessibilityFrame.size.width
            }
            let rect = CGRect(x: offset - scrollView.contentOffset.x + contentEdgeInset.left, y: 0, width: element.accessibilityFrame.size.width, height: element.accessibilityFrame.size.height)
            element.accessibilityFrame = convert(rect, to: nil)
        }
    }
    
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            fw_statisticalCheckExposure()
        }
    }
    
    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        fw_statisticalCheckExposure()
    }
    
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        fw_statisticalCheckExposure()
    }
    
    // MARK: - SegmentedAccessibilityDelegate
    func scrollToAccessibilityElement(_ sender: Any) {
        if let element = sender as? SegmentedAccessibilityElement,
           let index = segmentAccessibilityElements.firstIndex(of: element) {
            scrollTo(index, animated: false)
        }
    }
    
    // MARK: - UIAccessibilityContainer
    open override var accessibilityElements: [Any]? {
        get {
            return segmentAccessibilityElements
        }
        set {
            super.accessibilityElements = newValue
        }
    }
    
    open override var isAccessibilityElement: Bool {
        get {
            return false
        }
        set {
            super.isAccessibilityElement = newValue
        }
    }
    
    open override func accessibilityElementCount() -> Int {
        return segmentAccessibilityElements.count
    }
    
    open override func index(ofAccessibilityElement element: Any) -> Int {
        if let element = element as? SegmentedAccessibilityElement {
            return segmentAccessibilityElements.firstIndex(of: element) ?? NSNotFound
        }
        return NSNotFound
    }
    
    open override func accessibilityElement(at index: Int) -> Any? {
        return segmentAccessibilityElements.safeElement(index)
    }
    
    // MARK: - StatisticalViewProtocol
    open override func statisticalViewWillBindClick(_ containerView: UIView?) -> Bool {
        return true
    }
    
    open override func statisticalViewVisibleIndexPaths() -> [IndexPath]? {
        let visibleMin = self.scrollView.contentOffset.x
        let visibleMax = visibleMin + self.scrollView.frame.size.width
        var sectionCount = 0
        var dynamicWidth = false
        if self.type == .text && self.segmentWidthStyle == .fixed {
            sectionCount = self.sectionTitles?.count ?? 0
        } else if self.segmentWidthStyle == .dynamic {
            sectionCount = self.segmentWidthsArray.count
            dynamicWidth = true
        } else {
            sectionCount = self.sectionImages?.count ?? 0
        }
        
        var indexPaths = [IndexPath]()
        var currentMin = self.contentEdgeInset.left
        for i in 0..<sectionCount {
            let currentMax = currentMin + (dynamicWidth ? self.segmentWidthsArray[i] : self.segmentWidth)
            if currentMin > visibleMax { break }
            
            if currentMin >= visibleMin && currentMax <= visibleMax {
                indexPaths.append(IndexPath(row: i, section: 0))
            }
            currentMin = currentMax
        }
        return indexPaths
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

protocol SegmentedAccessibilityDelegate: NSObjectProtocol {
    func scrollToAccessibilityElement(_ sender: Any)
}

class SegmentedAccessibilityElement: UIAccessibilityElement {
    weak var delegate: SegmentedAccessibilityDelegate?
    
    override func accessibilityElementDidBecomeFocused() {
        delegate?.scrollToAccessibilityElement(self)
    }
}
