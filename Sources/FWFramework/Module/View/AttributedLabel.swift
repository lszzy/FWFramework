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
    open var font: UIFont?
    /// 文字颜色
    open var textColor: UIColor?
    /// 链接点击时背景高亮色
    open var highlightColor: UIColor?
    /// 链接色
    open var linkColor: UIColor?
    /// 阴影颜色
    open var shadowColor: UIColor?
    /// 阴影offset
    open var shadowOffset: CGSize = .zero
    /// 阴影半径
    open var shadowBlur: CGFloat = 0
    /// 链接是否带下划线
    open var underLineForLink: Bool = false
    /// 自动检测
    open var autoDetectLinks: Bool = false
    /// 自定义链接检测器，默认shared
    open var linkDetector: AttributedLabelURLDetectorProtocol?
    /// 链接点击句柄
    open var clickedOnLink: ((Any) -> Void)?
    /// 行数
    open var numberOfLines: Int = 0
    /// 文字排版样式
    open var textAlignment: CTTextAlignment = .left
    /// LineBreakMode
    open var lineBreakMode: CTLineBreakMode = .byWordWrapping
    /// 行间距
    open var lineSpacing: CGFloat = 0
    /// 段间距
    open var paragraphSpacing: CGFloat = 0
    /// 普通文本，设置nil可重置
    open var text: String?
    /// 属性文本，设置nil可重置
    open var attributedText: NSAttributedString?
    /// 最后一行截断之后留白的宽度，默认0不生效，仅lineBreakMode为TruncatingTail且发生截断时生效
    open var lineTruncatingSpacing: CGFloat = 0
    /// 最后一行截断之后显示的附件
    open var lineTruncatingAttachment: AttributedLabelAttachment?
    
    private var attributedString: NSMutableAttributedString?
    private var attachments: [AttributedLabelAlignment] = []
    private var linkLocations: [AttributedLabelURL] = []
    private var touchedLink: AttributedLabelURL?
    private var textFrame: CTFrame?
    private var fontAscent: CGFloat = 0
    private var fontDescent: CGFloat = 0
    private var fontHeight: CGFloat = 0
    private var linkDetected = false
    private var ignoreRedraw = false
    private var lineTruncatingView: UIView?
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
        
    }
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        .zero
    }
    
    open override var intrinsicContentSize: CGSize {
        .zero
    }
    
    open override func draw(_ rect: CGRect) {
        
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        nil
    }

    // MARK: - Public
    /// 添加文本
    open func appendText(_ text: String) {
    }

    open func appendAttributedText(_ attributedText: NSAttributedString) {
    }

    /// 图片
    open func appendImage(_ image: UIImage) {
    }

    open func appendImage(_ image: UIImage, maxSize: CGSize) {
    }

    open func appendImage(_ image: UIImage, maxSize: CGSize, margin: UIEdgeInsets) {
    }

    open func appendImage(_ image: UIImage, maxSize: CGSize, margin: UIEdgeInsets, alignment: AttributedLabelAlignment) {
    }

    /// UI控件
    open func appendView(_ view: UIView) {
    }

    open func appendView(_ view: UIView, margin: UIEdgeInsets) {
    }

    open func appendView(_ view: UIView, margin: UIEdgeInsets, alignment: AttributedLabelAlignment) {
    }

    /// 添加自定义链接
    open func addCustomLink(_ linkData: Any, for range: NSRange) {
    }

    open func addCustomLink(_ linkData: Any, for range: NSRange, attributes: [NSAttributedString.Key: Any]?) {
    }
    
    // MARK: - Private
    private func clearAll() {
        
    }
    
    private func resetTextFrame() {
        
    }
    
    private func resetFont() {
        
    }
    
    private func attributedString(_ text: String?) -> NSAttributedString {
        return .init()
    }
    
    private func numberOfDisplayedLines() -> Int {
        0
    }
    
    private func attributedStringForDraw() -> NSAttributedString {
        .init()
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
        false
    }
    
    private func recomputeLinksIfNeeded() {
        
    }
    
    private func computeLink(_ text: String) {
        
    }
    
    private func addAutoDetectedLink(_ link: AttributedLabelURL) {
        
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
