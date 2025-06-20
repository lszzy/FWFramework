//
//  ImageView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import SwiftUI
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - ImageView
/// 图片视图，支持网络图片和动图
public struct ImageView: UIViewRepresentable {
    var url: URLParameter?
    var placeholder: UIImage?
    var options: WebImageOptions = []
    var context: [ImageCoderOptions: Any]?
    var completion: (@MainActor @Sendable (UIImageView, UIImage?) -> Void)?
    var contentMode: UIView.ContentMode = .scaleAspectFill

    /// 指定本地占位图片初始化
    public init(_ placeholder: UIImage? = nil) {
        self.placeholder = placeholder
    }

    /// 指定网络图片URL初始化
    public init(url: URLParameter?) {
        self.url = url
    }

    /// 设置网络图片URL
    public func url(_ url: URLParameter?) -> Self {
        var result = self
        result.url = url
        return result
    }

    /// 设置网络图片加载选项
    public func options(_ options: WebImageOptions) -> Self {
        var result = self
        result.options = options
        return result
    }

    /// 设置本地占位图片
    public func placeholder(_ placeholder: UIImage?) -> Self {
        var result = self
        result.placeholder = placeholder
        return result
    }

    /// 设置图片显示内容模式，默认scaleAspectFill
    public func contentMode(_ contentMode: UIView.ContentMode) -> Self {
        var result = self
        result.contentMode = contentMode
        return result
    }

    // MARK: - UIViewRepresentable
    public typealias UIViewType = ResizableView<UIImageView>

    public func makeUIView(context: Context) -> ResizableView<UIImageView> {
        let imageView = UIImageView.fw.animatedImageView()
        let uiView = ResizableView(imageView)
        uiView.content.contentMode = contentMode
        uiView.content.fw.setImage(url: url, placeholderImage: placeholder, options: options, context: self.context, completion: completion != nil ? { @MainActor @Sendable image, _ in completion?(imageView, image) } : nil)
        return uiView
    }

    public func updateUIView(_ uiView: ResizableView<UIImageView>, context: Context) {
        uiView.content.contentMode = contentMode
    }

    public static func dismantleUIView(_ uiView: ResizableView<UIImageView>, coordinator: ()) {
        uiView.content.fw.cancelImageRequest()
    }
}

// MARK: - ResizableView
/// 可调整大小的视图包装器，解决frame尺寸变为图片尺寸等问题
public class ResizableView<Content: UIView>: UIView {
    public var content: Content
    public var resizable = true

    public init(_ content: Content, frame: CGRect = .zero) {
        self.content = content
        super.init(frame: frame)
        addSubview(content)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        content.frame = bounds
    }

    override public var frame: CGRect {
        didSet { invalidateIntrinsicContentSize() }
    }

    override public var bounds: CGRect {
        didSet { invalidateIntrinsicContentSize() }
    }

    override public var intrinsicContentSize: CGSize {
        resizable ? super.intrinsicContentSize : content.intrinsicContentSize
    }

    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        resizable ? super.intrinsicContentSize : content.intrinsicContentSize
    }
}
