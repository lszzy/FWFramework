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
        let drawString = attributedStringForDraw()
        let size = CGSize(width: size.width > 0 ? size.width : CGFloat.greatestFiniteMagnitude, height: size.height > 0 ? size.height : CGFloat.greatestFiniteMagnitude)
        let attributedStringRef = drawString as CFAttributedString
        let framesetter = CTFramesetterCreateWithAttributedString(attributedStringRef)
        
        var range = CFRange(location: 0, length: 0)
        if numberOfLines > 0 {
            let path = CGMutablePath()
            path.addRect(CGRect(x: 0, y: 0, width: size.width, height: size.height))
            let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), path, nil)
            let lines = CTFrameGetLines(frame)
            
            if CFArrayGetCount(lines) > 0 {
                let lastVisibleLineIndex = min(numberOfLines, CFArrayGetCount(lines)) - 1
                let lastVisibleLine = unsafeBitCast(CFArrayGetValueAtIndex(lines, lastVisibleLineIndex), to: CTLine.self)
                
                let rangeToLayout = CTLineGetStringRange(lastVisibleLine)
                range = CFRange(location: 0, length: rangeToLayout.location + rangeToLayout.length)
            }
        }
        
        var fitRange = CFRange(location: 0, length: 0)
        let newSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, range, nil, size, &fitRange)
        return CGSize(width: min(ceil(newSize.width), size.width), height: min(ceil(newSize.height), size.height))
    }
    
    open override var intrinsicContentSize: CGSize {
        return sizeThatFits(CGSize(width: self.bounds.width, height: CGFloat.greatestFiniteMagnitude))
    }
    
    open override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.saveGState()
        let transform = transformForCoreText()
        ctx.concatenate(transform)
        
        recomputeLinksIfNeeded()
        
        let drawString = attributedStringForDraw()
        prepareTextFrame(drawString, rect: rect)
        drawHighlight(rect: rect)
        drawAttachments()
        drawShadow(ctx)
        drawText(drawString, rect: rect, context: ctx)
        if #available(iOS 15.0, *) {} else {
            drawStrikethrough(rect: rect, context: ctx)
        }
        
        ctx.restoreGState()
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
            withUnsafePointer(to: &textAlignment) { ptr in
                CTParagraphStyleSetting(spec: .alignment, valueSize: MemoryLayout<CTTextAlignment>.size, value: ptr)
            },
            withUnsafePointer(to: &lineBreakMode) { ptr in
                CTParagraphStyleSetting(spec: .lineBreakMode, valueSize: MemoryLayout<CTLineBreakMode>.size, value: ptr)
            },
            withUnsafePointer(to: &lineSpacing) { ptr in
                CTParagraphStyleSetting(spec: .maximumLineSpacing, valueSize: MemoryLayout<CGFloat>.size, value: ptr)
            },
            withUnsafePointer(to: &lineSpacing) { ptr in
                CTParagraphStyleSetting(spec: .minimumLineSpacing, valueSize: MemoryLayout<CGFloat>.size, value: ptr)
            },
            withUnsafePointer(to: &paragraphSpacing) { ptr in
                CTParagraphStyleSetting(spec: .paragraphSpacing, valueSize: MemoryLayout<CGFloat>.size, value: ptr)
            },
            withUnsafePointer(to: &fontLineHeight) { ptr in
                CTParagraphStyleSetting(spec: .minimumLineHeight, valueSize: MemoryLayout<CGFloat>.size, value: ptr)
            }
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
        let margin: CGFloat = 5
        guard self.bounds.insetBy(dx: 0, dy: -margin).contains(point), let textFrame = textFrame else {
            return nil
        }
        
        let lines = CTFrameGetLines(textFrame)
        let count = CFArrayGetCount(lines)
        
        var origins = [CGPoint](repeating: .zero, count: count)
        CTFrameGetLineOrigins(textFrame, CFRangeMake(0, 0), &origins)
        
        let transform = transformForCoreText()
        let verticalOffset: CGFloat = 0
        
        for i in 0..<count {
            let linePoint = origins[i]
            let line = unsafeBitCast(CFArrayGetValueAtIndex(lines, i), to: CTLine.self)
            let flippedRect = getLineBounds(line, point: linePoint)
            var rect = flippedRect.applying(transform)
            rect = rect.insetBy(dx: 0, dy: -margin)
            rect = rect.offsetBy(dx: 0, dy: verticalOffset)
            
            if rect.contains(point) {
                let relativePoint = CGPoint(x: point.x - rect.minX, y: point.y - rect.minY)
                let idx = CTLineGetStringIndexForPosition(line, relativePoint)
                if let url = linkAtIndex(idx) {
                    return url
                }
            }
        }
        return nil
    }
    
    private func linkDataForPoint(_ point: CGPoint) -> Any? {
        let url = urlForPoint(point)
        return url?.linkData
    }
    
    private func transformForCoreText() -> CGAffineTransform {
        return CGAffineTransform(translationX: 0, y: self.bounds.height).scaledBy(x: 1.0, y: -1.0)
    }
    
    private func getLineBounds(_ line: CTLine, point: CGPoint) -> CGRect {
        var ascent: CGFloat = 0.0
        var descent: CGFloat = 0.0
        var leading: CGFloat = 0.0
        let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))
        let height = ascent + descent
        return CGRect(x: point.x, y: point.y - descent, width: width, height: height)
    }
    
    private func linkAtIndex(_ index: CFIndex) -> AttributedLabelURL? {
        for url in linkLocations {
            if NSLocationInRange(index, url.range) {
                return url
            }
        }
        return nil
    }
    
    private func rectForRange(_ range: NSRange, inLine line: CTLine, lineOrigin: CGPoint) -> CGRect {
        var rectForRange = CGRect.zero
        let runs = CTLineGetGlyphRuns(line)
        
        for i in 0..<CFArrayGetCount(runs) {
            let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, i), to: CTRun.self)
            let stringRunRange = CTRunGetStringRange(run)
            let lineRunRange = NSMakeRange(stringRunRange.location, stringRunRange.length)
            let intersectedRunRange = NSIntersectionRange(lineRunRange, range)
            if intersectedRunRange.length == 0 {
                continue
            }
            
            var ascent: CGFloat = 0.0
            var descent: CGFloat = 0.0
            let leading: CGFloat = 0.0
            
            let width = CGFloat(CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, nil))
            let height = ascent + descent
            
            let xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, nil)
            var linkRect = CGRect(x: lineOrigin.x + xOffset - leading, y: lineOrigin.y - descent, width: width + leading, height: height)
            
            linkRect.origin.y = round(linkRect.origin.y)
            linkRect.origin.x = round(linkRect.origin.x)
            linkRect.size.width = round(linkRect.size.width)
            linkRect.size.height = round(linkRect.size.height)
            
            rectForRange = CGRectIsEmpty(rectForRange) ? linkRect : rectForRange.union(linkRect)
        }
        
        return rectForRange
    }
    
    private func appendAttachment(_ attachment: AttributedLabelAttachment) {
        attachment.fontAscent = fontAscent
        attachment.fontDescent = fontDescent
        var objectReplacementChar: unichar = 0xFFFC
        let objectReplacementString = NSString(characters: &objectReplacementChar, length: 1) as String
        let attachText = NSMutableAttributedString(string: objectReplacementString)
        
        var callbacks = CTRunDelegateCallbacks(version: kCTRunDelegateVersion1, dealloc: { _ in
        }, getAscent: { ref in
            let image = unsafeBitCast(ref, to: AttributedLabelAttachment.self)
            var ascent: CGFloat = 0
            let height = image.boxSize().height
            switch image.alignment {
            case .top:
                ascent = image.fontAscent
            case .center:
                let fontAscent = image.fontAscent
                let fontDescent = image.fontDescent
                let baseLine = (fontAscent + fontDescent) / 2 - fontDescent
                ascent = height / 2 + baseLine
            case .bottom:
                ascent = height - image.fontDescent
            }
            return ascent
        }, getDescent: { ref in
            let image = unsafeBitCast(ref, to: AttributedLabelAttachment.self)
            var descent: CGFloat = 0
            let height = image.boxSize().height
            switch image.alignment {
            case .top:
                descent = height - image.fontAscent
            case .center:
                let fontAscent = image.fontAscent
                let fontDescent = image.fontDescent
                let baseLine = (fontAscent + fontDescent) / 2 - fontDescent
                descent = height / 2 - baseLine
            case .bottom:
                descent = image.fontDescent
            }
            return descent
        }, getWidth: { ref in
            let image = unsafeBitCast(ref, to: AttributedLabelAttachment.self)
            return image.boxSize().width
        })
        
        let delegate = CTRunDelegateCreate(&callbacks, Unmanaged.passRetained(attachment).toOpaque())
        var attr: [NSAttributedString.Key: Any] = [:]
        attr[.init(kCTRunDelegateAttributeName as String)] = delegate
        attachText.setAttributes(attr, range: NSRange(location: 0, length: 1))
        
        attachments.append(attachment)
        appendAttributedText(attachText)
    }
    
    private func prepareTextFrame(_ string: NSAttributedString, rect: CGRect) {
        guard textFrame == nil else { return }
        
        let framesetter = CTFramesetterCreateWithAttributedString(string)
        let path = CGPath(rect: rect, transform: nil)
        textFrame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), path, nil)
    }
    
    private func drawHighlight(rect: CGRect) {
        guard let touchedLink = touchedLink,
              let highlightColor = highlightColor,
              let textFrame = textFrame else { return }
        
        highlightColor.setFill()
        let linkRange = touchedLink.range
        let lines = CTFrameGetLines(textFrame)
        let count = CFArrayGetCount(lines)
        var lineOrigins = [CGPoint](repeating: .zero, count: count)
        CTFrameGetLineOrigins(textFrame, CFRangeMake(0, 0), &lineOrigins)
        let numberOfLines = numberOfDisplayedLines()
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        for i in 0..<numberOfLines {
            let line = unsafeBitCast(CFArrayGetValueAtIndex(lines, i), to: CTLine.self)
            let stringRange = CTLineGetStringRange(line)
            let lineRange = NSMakeRange(stringRange.location, stringRange.length)
            let intersectedRange = NSIntersectionRange(lineRange, linkRange)
            if intersectedRange.length == 0 {
                continue
            }
            
            let highlightRect = rectForRange(linkRange, inLine: line, lineOrigin: lineOrigins[i]).offsetBy(dx: 0, dy: -rect.origin.y)
            if !CGRectIsEmpty(highlightRect) {
                let pi = CGFloat.pi
                
                let radius: CGFloat = 1.0
                ctx.move(to: CGPoint(x: highlightRect.origin.x, y: highlightRect.origin.y + radius))
                ctx.addLine(to: CGPoint(x: highlightRect.origin.x, y: highlightRect.origin.y + highlightRect.size.height - radius))
                ctx.addArc(center: CGPoint(x: highlightRect.origin.x + radius, y: highlightRect.origin.y + highlightRect.size.height - radius), radius: radius, startAngle: pi, endAngle: pi / 2.0, clockwise: true)
                ctx.addLine(to: CGPoint(x: highlightRect.origin.x + highlightRect.size.width - radius, y: highlightRect.origin.y + highlightRect.size.height))
                ctx.addArc(center: CGPoint(x: highlightRect.origin.x + highlightRect.size.width - radius, y: highlightRect.origin.y + highlightRect.size.height - radius), radius: radius, startAngle: pi / 2, endAngle: 0, clockwise: true)
                ctx.addLine(to: CGPoint(x: highlightRect.origin.x + highlightRect.size.width, y: highlightRect.origin.y + radius))
                ctx.addArc(center: CGPoint(x: highlightRect.origin.x + highlightRect.size.width - radius, y: highlightRect.origin.y + radius), radius: radius, startAngle: 0, endAngle: -pi / 2.0, clockwise: true)
                ctx.addLine(to: CGPoint(x: highlightRect.origin.x + radius, y: highlightRect.origin.y))
                ctx.addArc(center: CGPoint(x: highlightRect.origin.x + radius, y: highlightRect.origin.y + radius), radius: radius, startAngle: -pi / 2, endAngle: pi, clockwise: true)
                ctx.fillPath()
            }
        }
    }
    
    private func drawShadow(_ ctx: CGContext) {
        if let shadowColor = shadowColor {
            ctx.setShadow(offset: shadowOffset, blur: shadowBlur, color: shadowColor.cgColor)
        }
    }
    
    private func drawText(_ attributedString: NSAttributedString, rect: CGRect, context: CGContext) {
        guard let textFrame = textFrame else { return }
        
        if numberOfLines > 0 {
            let lines = CTFrameGetLines(textFrame)
            let numberOfLines = numberOfDisplayedLines()

            var lineOrigins = [CGPoint](repeating: .zero, count: numberOfLines)
            CTFrameGetLineOrigins(textFrame, CFRangeMake(0, numberOfLines), &lineOrigins)
            
            for lineIndex in 0..<numberOfLines {
                let lineOrigin = lineOrigins[lineIndex]
                context.textPosition = CGPoint(x: lineOrigin.x, y: lineOrigin.y)
                let line = unsafeBitCast(CFArrayGetValueAtIndex(lines, lineIndex), to: CTLine.self)
                
                var shouldDrawLine = true
                if lineIndex == numberOfLines - 1 && lineBreakMode == .byTruncatingTail {
                    // 找到最后一行并检查是否需要truncatingTail
                    let lastLineRange = CTLineGetStringRange(line)
                    if lastLineRange.location + lastLineRange.length < attributedString.length {
                        let truncationType: CTLineTruncationType = .end
                        let truncationAttributePosition = lastLineRange.location + lastLineRange.length - 1
                        
                        let tokenAttributes = attributedString.attributes(at: truncationAttributePosition, effectiveRange: nil)
                        let tokenString = NSAttributedString(string: ellipsesCharacter, attributes: tokenAttributes)
                        let truncationToken = CTLineCreateWithAttributedString(tokenString as CFAttributedString)
                        
                        let truncationString = attributedString.attributedSubstring(from: NSRange(location: lastLineRange.location, length: lastLineRange.length)).mutableCopy() as! NSMutableAttributedString
                        
                        if lastLineRange.length > 0 {
                            //移除掉最后一个对象...，其实这个地方有点问题,也有可能需要移除最后 2 个对象，因为 attachment 宽度的关系
                            truncationString.deleteCharacters(in: NSRange(location: lastLineRange.length - 1, length: 1))
                        }
                        truncationString.append(tokenString)
                        
                        var truncationWidth = rect.size.width
                        if lineTruncatingSpacing > 0 {
                            truncationWidth -= lineTruncatingSpacing
                            
                            if let attributedImage = lineTruncatingAttachment {
                                var lineAscent: CGFloat = 0
                                var lineDescent: CGFloat = 0
                                CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, nil)
                                let lineHeight = lineAscent + lineDescent
                                let lineBottomY = lineOrigin.y - lineDescent
                                
                                let boxSize = attributedImage.boxSize()
                                let imageBoxHeight = boxSize.height
                                let xOffset = truncationWidth
                                
                                var imageBoxOriginY: CGFloat = 0.0
                                switch attributedImage.alignment {
                                case .top:
                                    imageBoxOriginY = lineBottomY + (lineHeight - imageBoxHeight)
                                case .center:
                                    imageBoxOriginY = lineBottomY + (lineHeight - imageBoxHeight) / 2.0
                                case .bottom:
                                    imageBoxOriginY = lineBottomY
                                }
                                
                                let imageRect = CGRect(x: lineOrigin.x + xOffset, y: imageBoxOriginY, width: boxSize.width, height: imageBoxHeight)
                                var flippedMargins = attributedImage.margin
                                let top = flippedMargins.top
                                flippedMargins.top = flippedMargins.bottom
                                flippedMargins.bottom = top
                                
                                let attachmentRect = imageRect.inset(by: flippedMargins)
                                
                                let content = attributedImage.content
                                if let image = content as? UIImage {
                                    if let cgImage = image.cgImage {
                                        context.draw(cgImage, in: attachmentRect)
                                    }
                                } else if let view = content as? UIView {
                                    lineTruncatingView = view
                                    if view.superview == nil {
                                        addSubview(view)
                                    }
                                    let viewFrame = CGRect(x: attachmentRect.origin.x, y: self.bounds.size.height - attachmentRect.origin.y - attachmentRect.size.height, width: attachmentRect.size.width, height: attachmentRect.size.height)
                                    view.frame = viewFrame
                                }
                            }
                        }
                        
                        let truncationLine = CTLineCreateWithAttributedString(truncationString as CFAttributedString)
                        let truncatedLine = CTLineCreateTruncatedLine(truncationLine, truncationWidth, truncationType, truncationToken) ?? truncationToken
                        CTLineDraw(truncatedLine, context)
                        
                        shouldDrawLine = false
                    }
                }
                if shouldDrawLine {
                    CTLineDraw(line, context)
                }
            }
        } else {
            CTFrameDraw(textFrame, context)
        }
    }
    
    private func drawStrikethrough(rect: CGRect, context: CGContext) {
        guard let textFrame = textFrame else { return }
        
        let lines = CTFrameGetLines(textFrame)
        let numberOfLines = numberOfDisplayedLines()
        let scale = UIScreen.main.scale
        var lineOrigins = [CGPoint](repeating: .zero, count: numberOfLines)
        CTFrameGetLineOrigins(textFrame, CFRangeMake(0, numberOfLines), &lineOrigins)
            
        for lineIndex in 0..<numberOfLines {
            let lineOrigin = lineOrigins[lineIndex]
            let line = unsafeBitCast(CFArrayGetValueAtIndex(lines, lineIndex), to: CTLine.self)
            let runs = CTLineGetGlyphRuns(line)
            
            for runIndex in 0..<CFArrayGetCount(runs) {
                let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, runIndex), to: CTRun.self)
                let glyphCount = CTRunGetGlyphCount(run)
                guard glyphCount > 0 else { continue }
                
                guard let attrs = CTRunGetAttributes(run) as? [NSAttributedString.Key: Any] else { continue }
                guard let strikethrough = attrs[.strikethroughStyle] as? NSNumber else { continue }
                let style = strikethrough.intValue
                let styleBase = style & 0xFF
                guard styleBase != 0 else { continue }

                var color = attrs[.strikethroughColor]
                if color == nil { color = attrs[.init(kCTForegroundColorAttributeName as String)] }
                if color == nil { color = attrs[.foregroundColor] ?? UIColor.black.cgColor }

                var xHeight: CGFloat = 0
                var underLinePosition: CGFloat = 0
                var lineThickness: CGFloat = 0
                drawMaxMetric(runs: runs, xHeight: &xHeight, underlinePosition: &underLinePosition, lineThickness: &lineThickness)
                
                var position = CGPoint(x: lineOrigin.x - underLinePosition, y: lineOrigin.y + xHeight / 2)
                var runPosition = CGPoint.zero
                CTRunGetPositions(run, CFRangeMake(0, 1), &runPosition)
                position.x = lineOrigin.x + runPosition.x
                let width = lineThickness
                let length = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), nil, nil, nil)
                let phase = position.x

                let x1 = round(position.x * scale) / scale
                let x2 = round((position.x + length) * scale) / scale
                let w = (styleBase == NSUnderlineStyle.thick.rawValue) ? width * 2 : width
                var y: CGFloat = 0
                let linePixel = w * scale
                if abs(linePixel - floor(linePixel)) < 0.1 {
                    let iPixel = Int(linePixel)
                    if iPixel == 0 || (iPixel % 2 == 1) {
                        y = (floor(position.y * scale) + 0.5) / scale
                    } else {
                        y = floor(position.y * scale) / scale
                    }
                } else {
                    y = position.y
                }
                
                if let uiColor = color as? UIColor {
                    context.setStrokeColor(uiColor.cgColor)
                } else {
                    context.setStrokeColor(color as! CGColor)
                }
                context.setLineWidth(width)
                context.setLineCap(.butt)
                context.setLineJoin(.miter)
                let dash: CGFloat = 12
                let dot: CGFloat = 5
                let space: CGFloat = 3
                let pattern = style & 0xF00
                if pattern == NSUnderlineStyle.patternDot.rawValue {
                    let lengths: [CGFloat] = [width * dot, width * space]
                    context.setLineDash(phase: phase, lengths: lengths)
                } else if pattern == NSUnderlineStyle.patternDash.rawValue {
                    let lengths: [CGFloat] = [width * dash, width * space]
                    context.setLineDash(phase: phase, lengths: lengths)
                } else if pattern == NSUnderlineStyle.patternDashDot.rawValue {
                    let lengths: [CGFloat] = [width * dash, width * space, width * dot, width * space]
                    context.setLineDash(phase: phase, lengths: lengths)
                } else if pattern == NSUnderlineStyle.patternDashDotDot.rawValue {
                    let lengths: [CGFloat] = [width * dash, width * space, width * dot, width * space, width * dot, width * space]
                    context.setLineDash(phase: phase, lengths: lengths)
                } else {
                    context.setLineDash(phase: phase, lengths: [])
                }

                context.setLineWidth(w)
                if styleBase == NSUnderlineStyle.single.rawValue {
                    context.move(to: CGPoint(x: x1, y: y))
                    context.addLine(to: CGPoint(x: x2, y: y))
                    context.strokePath()
                } else if styleBase == NSUnderlineStyle.thick.rawValue {
                    context.move(to: CGPoint(x: x1, y: y))
                    context.addLine(to: CGPoint(x: x2, y: y))
                    context.strokePath()
                } else if styleBase == NSUnderlineStyle.double.rawValue {
                    context.move(to: CGPoint(x: x1, y: y - w))
                    context.addLine(to: CGPoint(x: x2, y: y - w))
                    context.strokePath()
                    context.move(to: CGPoint(x: x1, y: y + w))
                    context.addLine(to: CGPoint(x: x2, y: y + w))
                    context.strokePath()
                }
            }
        }
    }
    
    private func drawMaxMetric(runs: CFArray, xHeight: inout CGFloat, underlinePosition: inout CGFloat, lineThickness: inout CGFloat) {
        var maxXHeight: CGFloat = 0
        var maxUnderlinePos: CGFloat = 0
        var maxLineThickness: CGFloat = 0
        
        for i in 0..<CFArrayGetCount(runs) {
            let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, i), to: CTRun.self)
            let attrs = CTRunGetAttributes(run) as? [NSAttributedString.Key: Any]
            if let attrs = attrs, let fontValue = attrs[.init(kCTFontAttributeName as String)] {
                let font = fontValue as! CTFont
                let fontXHeight = CTFontGetXHeight(font)
                if fontXHeight > maxXHeight { maxXHeight = fontXHeight }
                
                let fontUnderlinePos = CTFontGetUnderlinePosition(font)
                if fontUnderlinePos < maxUnderlinePos { maxUnderlinePos = fontUnderlinePos }
                
                let fontLineThickness = CTFontGetUnderlineThickness(font)
                if fontLineThickness > maxLineThickness {
                    maxLineThickness = fontLineThickness
                }
            }
        }
        
        xHeight = maxXHeight
        underlinePosition = maxUnderlinePos
        lineThickness = maxLineThickness
    }
    
    private func drawAttachments() {
        guard attachments.count > 0,
              let textFrame = textFrame,
              let ctx = UIGraphicsGetCurrentContext() else { return }
        
        let lines = CTFrameGetLines(textFrame)
        let lineCount = CFArrayGetCount(lines)
        var lineOrigins = [CGPoint](repeating: .zero, count: lineCount)
        CTFrameGetLineOrigins(textFrame, CFRangeMake(0, 0), &lineOrigins)
        let numberOfLines = numberOfDisplayedLines()

        for i in 0 ..< numberOfLines {
            let line = unsafeBitCast(CFArrayGetValueAtIndex(lines, i), to: CTLine.self)
            let runs = CTLineGetGlyphRuns(line)
            let runCount = CFArrayGetCount(runs)
            let lineOrigin = lineOrigins[i]
            var lineAscent: CGFloat = 0.0
            var lineDescent: CGFloat = 0.0
            CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, nil)
            let lineHeight = lineAscent + lineDescent
            let lineBottomY = lineOrigin.y - lineDescent

            // 遍历找到对应的 attachment 进行绘制
            for k in 0..<runCount {
                let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, k), to: CTRun.self)
                let runAttributes = CTRunGetAttributes(run) as? [NSAttributedString.Key: Any]
                let delegate = runAttributes?[.init(kCTRunDelegateAttributeName as String)]
                guard let delegate = delegate else { continue }
                let attributedImage = unsafeBitCast(CTRunDelegateGetRefCon(delegate as! CTRunDelegate), to: AttributedLabelAttachment.self)
                
                var ascent: CGFloat = 0.0
                var descent: CGFloat = 0.0
                let width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, nil)
                let imageBoxHeight = attributedImage.boxSize().height
                let xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, nil)
                
                var imageBoxOriginY: CGFloat = 0.0
                switch attributedImage.alignment {
                case .top:
                    imageBoxOriginY = lineBottomY + (lineHeight - imageBoxHeight)
                case .center:
                    imageBoxOriginY = lineBottomY + (lineHeight - imageBoxHeight) / 2.0
                case .bottom:
                    imageBoxOriginY = lineBottomY
                }
                
                let imageRect = CGRect(x: lineOrigin.x + xOffset, y: imageBoxOriginY, width: width, height: imageBoxHeight)
                var flippedMargins = attributedImage.margin
                let top = flippedMargins.top
                flippedMargins.top = flippedMargins.bottom
                flippedMargins.bottom = top
                
                let attatchmentRect = imageRect.inset(by: flippedMargins)
                
                if i == numberOfLines - 1 && k >= runCount - 2 && lineBreakMode == .byTruncatingTail {
                    // 最后行最后的2个CTRun需要做额外判断
                    let attachmentWidth = attatchmentRect.width
                    let minEllipsesWidth = attachmentWidth
                    if self.bounds.width - attatchmentRect.minX - attachmentWidth < minEllipsesWidth {
                        continue
                    }
                }
                
                let content = attributedImage.content
                if let image = content as? UIImage {
                    if let cgImage = image.cgImage {
                        ctx.draw(cgImage, in: attatchmentRect)
                    }
                } else if let view = content as? UIView {
                    if view.superview == nil {
                        addSubview(view)
                    }
                    let viewFrame = CGRect(x: attatchmentRect.origin.x, y: self.bounds.height - attatchmentRect.origin.y - attatchmentRect.size.height, width: attatchmentRect.size.width, height: attatchmentRect.size.height)
                    view.frame = viewFrame
                }
            }
        }
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
                url = URL.fw.url(string: linkString)
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
        regularExpression.fw.setProperty(attributes, forName: "detectLinksAttributes", policy: .OBJC_ASSOCIATION_COPY_NONATOMIC)
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
            let attributes = regularExpression.fw.property(forName: "detectLinksAttributes") as? [NSAttributedString.Key: Any]
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
