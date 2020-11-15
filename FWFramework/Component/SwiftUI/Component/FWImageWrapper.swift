//
//  FWImageWrapper.swift
//  FWFramework
//
//  Created by wuyong on 2020/11/5.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#if canImport(SwiftUI)
import SwiftUI

/// SwiftUI动图、网络图片包装器
@available(iOS 13.0, *)
public struct FWImageWrapper: UIViewRepresentable {
    
    var url: Any?
    var placeholder: UIImage?
    var contentMode: UIView.ContentMode = .scaleAspectFill
    
    /// 指定本地占位图片初始化
    public init(_ placeholder: UIImage? = nil) {
        self.placeholder = placeholder
    }
    
    /// 指定网络图片URL初始化
    public init(url: Any?) {
        self.url = url
    }
    
    /// 设置网络图片URL
    public func url(_ url: Any?) -> FWImageWrapper {
        var result = self
        result.url = url
        return result
    }
    
    /// 设置本地占位图片
    public func placeholder(_ placeholder: UIImage?) -> FWImageWrapper {
        var result = self
        result.placeholder = placeholder
        return result
    }
    
    /// 设置图片显示内容模式，默认scaleAspectFill
    public func contentMode(_ contentMode: UIView.ContentMode) -> FWImageWrapper {
        var result = self
        result.contentMode = contentMode
        return result
    }
    
    // MARK: - UIViewRepresentable
    
    public typealias UIViewType = UIImageView
    
    public func makeUIView(context: Context) -> UIImageView {
        let imageClass = UIImageView.fwImageViewAnimatedClass as! UIImageView.Type
        let imageView = imageClass.init()
        imageView.contentMode = contentMode
        imageView.fwSetImage(withURL: url, placeholderImage: placeholder)
        return imageView
    }
    
    public func updateUIView(_ imageView: UIImageView, context: Context) {
        imageView.contentMode = contentMode
    }
    
    public static func dismantleUIView(_ imageView: UIImageView, coordinator: ()) {
        imageView.fwCancelImageRequest()
    }
}

#endif
