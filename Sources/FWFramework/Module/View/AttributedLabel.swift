//
//  AttributedLabel.swift
//  FWFramework
//
//  Created by wuyong on 2023/12/25.
//

import UIKit
import CoreText

// MARK: - AttributedLabel
public enum AttributedLabelAlignment: Int {
    case top
    case center
    case bottom
}

public protocol AttributedLabelDelegate: AnyObject {
    func attributedLabel(_ attributedLabel: AttributedLabel, clickedOnLink linkData: Any)
}

/// [M80AttributedLabel](https://github.com/xiangwangfeng/M80AttributedLabel)
open class AttributedLabel: UIView {
    
    // MARK: - Accessor
    /// 事件代理
    open weak var delegate: AttributedLabelDelegate?
    /// 字体
    open var font: UIFont? {
        get {
            return _font
        }
        set {
            guard let font = newValue, font != _font else { return }
            _font = font
            
            attributedString.removeAttribute(.init(kCTFontAttributeName as String), range: NSMakeRange(0, attributedString.length))
            let fontRef = CTFontCreateWithFontDescriptor(font.fontDescriptor as CTFontDescriptor, font.pointSize, nil)
            attributedString.addAttribute(.init(kCTFontAttributeName as String), value: fontRef, range: NSMakeRange(0, attributedString.length))
            resetFont()
            for attachment in attachments {
                attachment.fontAscent = fontAscent
                attachment.fontDescent = fontDescent
            }
            resetTextFrame()
        }
    }
    private var _font: UIFont? = UIFont.systemFont(ofSize: 15)
    /// 文字颜色
    open var textColor: UIColor? {
        get {
            return _textColor
        }
        set {
            guard let textColor = newValue, textColor != _textColor else { return }
            _textColor = textColor
            
            attributedString.removeAttribute(.init(kCTForegroundColorAttributeName as String), range: NSMakeRange(0, attributedString.length))
            attributedString.addAttribute(.init(kCTForegroundColorAttributeName as String), value: textColor.cgColor, range: NSMakeRange(0, attributedString.length))
            resetTextFrame()
        }
    }
    private var _textColor: UIColor? = .black
    /// 链接点击时背景高亮色
    open var highlightColor: UIColor? = UIColor(red: 215.0 / 255.0, green: 242.0 / 255.0, blue: 255.0 / 255.0, alpha: 1.0) {
        didSet {
            if highlightColor != oldValue {
                resetTextFrame()
            }
        }
    }
    /// 链接色
    open var linkColor: UIColor? = .blue {
        didSet {
            if linkColor != oldValue {
                resetTextFrame()
            }
        }
    }
    /// 阴影颜色
    open var shadowColor: UIColor? {
        didSet {
            if shadowColor != oldValue {
                resetTextFrame()
            }
        }
    }
    /// 阴影offset
    open var shadowOffset: CGSize = .zero {
        didSet {
            if shadowOffset != oldValue {
                resetTextFrame()
            }
        }
    }
    /// 阴影半径
    open var shadowBlur: CGFloat = 0 {
        didSet {
            if shadowBlur != oldValue {
                resetTextFrame()
            }
        }
    }
    /// 链接是否带下划线
    open var underLineForLink: Bool = true {
        didSet {
            if underLineForLink != oldValue {
                resetTextFrame()
            }
        }
    }
    /// 自动检测
    open var autoDetectLinks: Bool = true {
        didSet {
            if autoDetectLinks != oldValue {
                resetTextFrame()
            }
        }
    }
    /// 自定义链接检测器，默认shared
    open var linkDetector: AttributedLabelURLDetectorProtocol? {
        get {
            if _linkDetector == nil {
                _linkDetector = AttributedLabelURLDetector.shared
            }
            return _linkDetector
        }
        set {
            _linkDetector = newValue
            resetTextFrame()
        }
    }
    private var _linkDetector: AttributedLabelURLDetectorProtocol?
    /// 链接点击句柄
    open var clickedOnLink: ((Any) -> Void)?
    /// 行数
    open var numberOfLines: Int = 0 {
        didSet {
            if numberOfLines != oldValue {
                resetTextFrame()
            }
        }
    }
    /// 文字排版样式
    open var textAlignment: CTTextAlignment = .left {
        didSet {
            if textAlignment != oldValue {
                resetTextFrame()
            }
        }
    }
    /// LineBreakMode
    open var lineBreakMode: CTLineBreakMode = .byWordWrapping {
        didSet {
            if lineBreakMode != oldValue {
                resetTextFrame()
            }
        }
    }
    /// 行间距
    open var lineSpacing: CGFloat = 0 {
        didSet {
            if lineSpacing != oldValue {
                resetTextFrame()
            }
        }
    }
    /// 段间距
    open var paragraphSpacing: CGFloat = 0 {
        didSet {
            if paragraphSpacing != oldValue {
                resetTextFrame()
            }
        }
    }
    /// 普通文本，设置nil可重置
    open var text: String? {
        get { return attributedString.string }
        set { attributedText = attributedString(newValue) }
    }
    /// 属性文本，设置nil可重置
    open var attributedText: NSAttributedString? {
        get { return attributedString.copy() as? NSAttributedString }
        set {
            if let newValue = newValue {
                attributedString = .init(attributedString: newValue)
            } else {
                attributedString = .init()
            }
            clearAll()
        }
    }
    /// 最后一行截断之后留白的宽度，默认0不生效，仅lineBreakMode为TruncatingTail且发生截断时生效
    open var lineTruncatingSpacing: CGFloat = 0 {
        didSet {
            if lineTruncatingSpacing != oldValue {
                resetTextFrame()
            }
        }
    }
    /// 最后一行截断之后显示的附件
    open var lineTruncatingAttachment: AttributedLabelAttachment? {
        didSet {
            if lineTruncatingAttachment != oldValue {
                resetTextFrame()
            }
        }
    }
    
    private var attributedString: NSMutableAttributedString = .init()
    private var attachments: [AttributedLabelAttachment] = []
    private var linkLocations: [AttributedLabelURL] = []
    private var touchedLink: AttributedLabelURL?
    private var textFrame: CTFrame?
    private var fontAscent: CGFloat = 0
    private var fontDescent: CGFloat = 0
    private var fontHeight: CGFloat = 0
    private var linkDetected = false
    private var ignoreRedraw = false
    private var lineTruncatingView: UIView?
    
    private let minHttpLinkLength: Int = 5
    private let ellipsesCharacter = "\u{2026}"
    
    // MARK: - Lifecycle
    public override init(frame: CGRect) {
        super.init(frame: frame)
        didInitialize()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        didInitialize()
    }
    
    deinit {
        textFrame = nil
    }
    
    private func didInitialize() {
        if backgroundColor == nil {
            backgroundColor = .white
        }
        isUserInteractionEnabled = true
        resetFont()
    }
    
    open override var frame: CGRect {
        didSet {
            if frame != oldValue {
                resetTextFrame()
            }
        }
    }
    
    open override var bounds: CGRect {
        didSet {
            if bounds != oldValue {
                resetTextFrame()
            }
        }
    }
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        .zero
    }
    
    open override var intrinsicContentSize: CGSize {
        return sizeThatFits(CGSize(width: self.bounds.width, height: CGFloat.greatestFiniteMagnitude))
    }
    
    open override func draw(_ rect: CGRect) {
        
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touchedLink == nil {
            let touch = touches.first
            let point = touch?.location(in: self) ?? .zero
            touchedLink = urlForPoint(point)
        }
        if touchedLink != nil {
            setNeedsDisplay()
        } else {
            super.touchesBegan(touches, with: event)
        }
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        let touch = touches.first
        let point = touch?.location(in: self) ?? .zero
        let url = urlForPoint(point)
        if touchedLink != url {
            touchedLink = url
            setNeedsDisplay()
        }
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        if touchedLink != nil {
            touchedLink = nil
            setNeedsDisplay()
        }
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let point = touch?.location(in: self) ?? .zero
        if !onLabelClick(point) {
            super.touchesEnded(touches, with: event)
        }
        if touchedLink != nil {
            touchedLink = nil
            setNeedsDisplay()
        }
    }
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let url = urlForPoint(point)
        if url == nil {
            let subviews = self.subviews
            for view in subviews {
                let hitPoint = view.convert(point, from: self)
                let hitTestView = view.hitTest(hitPoint, with: event)
                if hitTestView != nil {
                    return hitTestView
                }
            }
            return nil
        } else {
            return self
        }
    }

    // MARK: - Public
    /// 添加文本
    open func appendText(_ text: String) {
        appendAttributedText(attributedString(text))
    }

    open func appendAttributedText(_ attributedText: NSAttributedString) {
        attributedString.append(attributedText)
        resetTextFrame()
    }

    /// 图片
    open func appendImage(_ image: UIImage) {
        appendImage(image, maxSize: image.size)
    }

    open func appendImage(_ image: UIImage, maxSize: CGSize, margin: UIEdgeInsets = .zero, alignment: AttributedLabelAlignment = .center) {
        let attachment = AttributedLabelAttachment(content: image, margin: margin, alignment: alignment, maxSize: maxSize)
        appendAttachment(attachment)
    }

    /// UI控件
    open func appendView(_ view: UIView, margin: UIEdgeInsets = .zero, alignment: AttributedLabelAlignment = .center) {
        let attachment = AttributedLabelAttachment(content: view, margin: margin, alignment: alignment, maxSize: .zero)
        appendAttachment(attachment)
    }

    /// 添加自定义链接
    open func addCustomLink(_ linkData: Any, for range: NSRange, attributes: [NSAttributedString.Key: Any]? = nil) {
        let url = AttributedLabelURL(linkData: linkData, range: range, attributes: attributes)
        linkLocations.append(url)
        resetTextFrame()
    }
    
    // MARK: - Private
    private func clearAll() {
        ignoreRedraw = false
        linkDetected = false
        attachments.removeAll()
        linkLocations.removeAll()
        touchedLink = nil
        for subview in subviews {
            subview.removeFromSuperview()
        }
        resetTextFrame()
    }
    
    private func resetTextFrame() {
        if textFrame != nil {
            textFrame = nil
        }
        if Thread.isMainThread {
            if lineTruncatingView != nil {
                lineTruncatingView?.removeFromSuperview()
                lineTruncatingView = nil
            }
            
            if !ignoreRedraw {
                invalidateIntrinsicContentSize()
                setNeedsDisplay()
            }
        }
    }
    
    private func resetFont() {
        guard let font = font else { return }
        let fontRef = CTFontCreateWithFontDescriptor(font.fontDescriptor as CTFontDescriptor, font.pointSize, nil)
        fontAscent = CTFontGetAscent(fontRef)
        fontDescent = CTFontGetDescent(fontRef)
        fontHeight = CTFontGetSize(fontRef)
    }
    
    private func attributedString(_ text: String?) -> NSAttributedString {
        guard let text = text, !text.isEmpty else {
            return NSAttributedString()
        }
        
        let string = NSMutableAttributedString(string: text)
        if let font = font {
            string.removeAttribute(.init(kCTFontAttributeName as String), range: NSMakeRange(0, string.length))
            let fontRef = CTFontCreateWithFontDescriptor(font.fontDescriptor as CTFontDescriptor, font.pointSize, nil)
            string.addAttribute(.init(kCTFontAttributeName as String), value: fontRef, range: NSMakeRange(0, string.length))
        }
        string.removeAttribute(.init(kCTForegroundColorAttributeName as String), range: NSMakeRange(0, string.length))
        if let cgColor = textColor?.cgColor {
            string.addAttribute(.init(kCTForegroundColorAttributeName as String), value: cgColor, range: NSMakeRange(0, string.length))
        }
        return string
    }
    
    private func numberOfDisplayedLines() -> Int {
        guard let textFrame = textFrame else { return 0 }
        let lines = CTFrameGetLines(textFrame)
        return numberOfLines > 0 ? min(CFArrayGetCount(lines), numberOfLines) : CFArrayGetCount(lines)
    }
    
    private func attributedStringForDraw() -> NSAttributedString {
        let drawString = attributedString.mutableCopy() as! NSMutableAttributedString
        
        // 如果LineBreakMode为TranncateTail,那么默认排版模式改成kCTLineBreakByCharWrapping,使得尽可能地显示所有文字
        var lineBreakMode = self.lineBreakMode
        if self.lineBreakMode == .byTruncatingTail {
            lineBreakMode = numberOfLines == 1 ? .byTruncatingTail : .byWordWrapping
        }
        // 使用全局fontHeight作为最小lineHeight
        var fontLineHeight = self.font?.lineHeight ?? .zero
        var textAlignment = self.textAlignment
        var lineSpacing = self.lineSpacing
        var paragraphSpacing = self.paragraphSpacing

        let settings: [CTParagraphStyleSetting] = [
            CTParagraphStyleSetting(spec: .alignment, valueSize: MemoryLayout<CTTextAlignment>.size, value: &textAlignment),
            CTParagraphStyleSetting(spec: .lineBreakMode, valueSize: MemoryLayout<CTLineBreakMode>.size, value: &lineBreakMode),
            CTParagraphStyleSetting(spec: .maximumLineSpacing, valueSize: MemoryLayout<CGFloat>.size, value: &lineSpacing),
            CTParagraphStyleSetting(spec: .minimumLineSpacing, valueSize: MemoryLayout<CGFloat>.size, value: &lineSpacing),
            CTParagraphStyleSetting(spec: .paragraphSpacing, valueSize: MemoryLayout<CGFloat>.size, value: &paragraphSpacing),
            CTParagraphStyleSetting(spec: .minimumLineHeight, valueSize: MemoryLayout<CGFloat>.size, value: &fontLineHeight)
        ]
        let paragraphStyle = CTParagraphStyleCreate(settings, settings.count)
        drawString.addAttribute(.init(kCTParagraphStyleAttributeName as String), value: paragraphStyle, range: NSMakeRange(0, drawString.length))

        for url in linkLocations {
            if url.range.location + url.range.length > attributedString.length {
                continue
            }
            var attributes = url.attributes ?? [:]
            var drawLinkColor = self.linkColor
            let urlColor = attributes[.init(kCTForegroundColorAttributeName as String)] ?? attributes[NSAttributedString.Key.foregroundColor]
            if let urlColor = urlColor {
                if let uiColor = urlColor as? UIColor {
                    drawLinkColor = uiColor
                } else {
                    drawLinkColor = UIColor(cgColor: urlColor as! CGColor)
                }
                attributes.removeValue(forKey: .init(kCTForegroundColorAttributeName as String))
                attributes.removeValue(forKey: .foregroundColor)
            }
            drawString.removeAttribute(.init(kCTForegroundColorAttributeName as String), range: url.range)
            if let cgColor = drawLinkColor?.cgColor {
                drawString.addAttribute(.init(kCTForegroundColorAttributeName as String), value: cgColor, range: url.range)
            }
            
            drawString.removeAttribute(.init(kCTUnderlineColorAttributeName as String), range: url.range)
            var underlineStyle: CTUnderlineStyle = underLineForLink ? .single : []
            let urlUnderline = attributes[.init(kCTUnderlineStyleAttributeName as String)] ?? attributes[.underlineStyle]
            if let urlUnderline = urlUnderline {
                underlineStyle = .init(rawValue: (urlUnderline as? NSNumber)?.int32Value ?? 0)
                attributes.removeValue(forKey: .init(kCTUnderlineStyleAttributeName as String))
                attributes.removeValue(forKey: .underlineStyle)
            }
            drawString.addAttribute(.init(kCTUnderlineStyleAttributeName as String), value: NSNumber(value: underlineStyle.rawValue | CTUnderlineStyleModifiers.patternSolid.rawValue), range: url.range)
            
            if attributes.count > 0 {
                drawString.addAttributes(attributes, range: url.range)
            }
        }
        return drawString
    }
    
    private func urlForPoint(_ point: CGPoint) -> AttributedLabelURL? {
        nil
    }
    
    private func linkDataForPoint(_ point: CGPoint) -> Any? {
        return nil
    }
    
    private func transformForCoreText() -> CGAffineTransform {
        .init()
    }
    
    private func getLineBounds(_ line: CTLine, point: CGPoint) -> CGRect {
        .zero
    }
    
    private func linkAtIndex(_ index: CFIndex) -> AttributedLabelURL? {
        nil
    }
    
    private func rectForRange(_ range: NSRange, inLine line: CTLine, lineOrigin: CGPoint) -> CGRect {
        .zero
    }
    
    private func appendAttachment(_ attachment: AttributedLabelAttachment) {
        
    }
    
    private func prepareTextFrame(_ string: NSAttributedString, rect: CGRect) {
        
    }
    
    private func drawHighlight(rect: CGRect) {
        
    }
    
    private func drawShadow(_ ctx: CGContext) {
        
    }
    
    private func drawText(_ attributedString: NSAttributedString, rect: CGRect, context: CGContext) {
        
    }
    
    private func drawStrikethrough(rect: CGRect, context: CGContext) {
        
    }
    
    private func drawMaxMetric(runs: CFArray, xHeight: UnsafeMutablePointer<CGFloat>, underlinePosition: UnsafeMutablePointer<CGFloat>, lineThickness: UnsafeMutablePointer<CGFloat>) {
        
    }
    
    private func drawAttachments() {
        
    }
    
    private func onLabelClick(_ point: CGPoint) -> Bool {
        guard let linkData = linkDataForPoint(point) else { return false }
        
        if let delegate = delegate {
            delegate.attributedLabel(self, clickedOnLink: linkData)
        } else if clickedOnLink != nil {
            clickedOnLink?(linkData)
        } else {
            var url: URL?
            if let linkString = linkData as? String {
                url = URL.fw_url(string: linkString)
            } else if let linkUrl = linkData as? URL {
                url = linkUrl
            }
            if let url = url {
                UIApplication.shared.open(url)
            }
        }
        return true
    }
    
    private func recomputeLinksIfNeeded() {
        if !autoDetectLinks || linkDetected { return }
        let text = attributedString.string
        if text.count <= minHttpLinkLength { return }
        computeLink(text)
    }
    
    private func computeLink(_ text: String) {
        ignoreRedraw = true
        
        linkDetector?.detectLinks(text, completion: { [weak self] links in
            guard let self = self else { return }
            let plainText = self.attributedString.string
            if text == plainText {
                self.linkDetected = true
                if let links = links, links.count > 0 {
                    for link in links {
                        self.addAutoDetectedLink(link)
                    }
                    self.resetTextFrame()
                }
                self.ignoreRedraw = false
            }
        })
    }
    
    private func addAutoDetectedLink(_ link: AttributedLabelURL) {
        let range = link.range
        for url in linkLocations {
            if NSIntersectionRange(range, url.range).length != 0 {
                return
            }
        }
        addCustomLink(link.linkData, for: link.range, attributes: link.attributes)
    }
    
}

// MARK: - AttributedLabelURL
open class AttributedLabelURL: NSObject {
    open private(set) var linkData: Any
    open private(set) var range: NSRange
    open private(set) var attributes: [NSAttributedString.Key: Any]?
    
    public init(linkData: Any, range: NSRange, attributes: [NSAttributedString.Key: Any]?) {
        self.linkData = linkData
        self.range = range
        self.attributes = attributes
        super.init()
    }
}

// MARK: - AttributedLabelURLDetector
public typealias AttributedLinkDetectCompletion = (_ links: [AttributedLabelURL]?) -> Void

public protocol AttributedLabelURLDetectorProtocol: AnyObject {
    func detectLinks(_ plainText: String, completion: AttributedLinkDetectCompletion)
}

open class AttributedLabelURLDetector: NSObject, AttributedLabelURLDetectorProtocol {
    public static let shared = AttributedLabelURLDetector()
    
    open var detector: AttributedLabelURLDetectorProtocol?
    
    private var regularExpressions: [NSRegularExpression] = []
    
    public override init() {
        super.init()
        
        if let dataDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue | NSTextCheckingResult.CheckingType.phoneNumber.rawValue) {
            addRegularExpression(dataDetector)
        }
    }
    
    open func addRegularExpression(_ regularExpression: NSRegularExpression, attributes: [NSAttributedString.Key: Any]? = nil) {
        regularExpression.fw_setProperty(attributes, forName: "detectLinksAttributes", policy: .OBJC_ASSOCIATION_COPY_NONATOMIC)
        regularExpressions.append(regularExpression)
    }
    
    open func removeAllRegularExpressions() {
        regularExpressions.removeAll()
    }
    
    open func detectLinks(_ plainText: String, completion: ([AttributedLabelURL]?) -> Void) {
        guard !plainText.isEmpty else {
            completion(nil)
            return
        }
        
        if let detector = detector {
            detector.detectLinks(plainText, completion: completion)
            return
        }
        
        var links: [AttributedLabelURL] = []
        let plainString = plainText as NSString
        for regularExpression in regularExpressions {
            let attributes = regularExpression.fw_property(forName: "detectLinksAttributes") as? [NSAttributedString.Key: Any]
            regularExpression.enumerateMatches(in: plainText, range: NSMakeRange(0, plainString.length)) { result, flags, stop in
                if let range = result?.range {
                    let text = plainString.substring(with: range)
                    let link = AttributedLabelURL(linkData: text, range: range, attributes: attributes)
                    links.append(link)
                }
            }
        }
        completion(links)
    }
}

// MARK: - AttributedLabelAttachment
open class AttributedLabelAttachment: NSObject {
    open private(set) var content: Any
    open private(set) var margin: UIEdgeInsets
    open private(set) var alignment: AttributedLabelAlignment
    open private(set) var maxSize: CGSize
    open var fontAscent: CGFloat = 0
    open var fontDescent: CGFloat = 0
    
    public init(content: Any, margin: UIEdgeInsets, alignment: AttributedLabelAlignment, maxSize: CGSize) {
        self.content = content
        self.margin = margin
        self.alignment = alignment
        self.maxSize = maxSize
        super.init()
    }
    
    open func boxSize() -> CGSize {
        var contentSize = attachmentSize()
        if maxSize.width > 0 && maxSize.height > 0 && contentSize.width > 0 && contentSize.height > 0 {
            contentSize = calculateContentSize()
        }
        return CGSize(width: contentSize.width + margin.left + margin.right, height: contentSize.height + margin.top + margin.bottom)
    }
    
    private func calculateContentSize() -> CGSize {
        let attachmentSize = attachmentSize()
        let width = attachmentSize.width
        let height = attachmentSize.height
        let newWidth = maxSize.width
        let newHeight = maxSize.height
        if width <= newWidth && height <= newHeight {
            return attachmentSize
        }
        
        var size: CGSize = .zero
        if width / height > newWidth / newHeight {
            size = CGSize(width: newWidth, height: newWidth * height / width)
        } else {
            size = CGSize(width: newHeight * width / height, height: newHeight)
        }
        return size
    }
    
    private func attachmentSize() -> CGSize {
        var size: CGSize = .zero
        if let image = content as? UIImage {
            size = image.size
        } else if let view = content as? UIView {
            size = view.bounds.size
        }
        return size
    }
}
