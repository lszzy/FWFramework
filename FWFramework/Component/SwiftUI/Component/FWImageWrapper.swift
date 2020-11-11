//
//  FWImageWrapper.swift
//  FWFramework
//
//  Created by wuyong on 2020/11/5.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#if canImport(SwiftUI)
import SwiftUI
#endif

/// SwiftUI动图、网络图片包装器
@available(iOS 13.0, *)
public struct FWImageWrapper: UIViewRepresentable {
    var image: UIImage?
    var url: Any?
    var placeholder: UIImage?
    var contentMode: UIView.ContentMode = .scaleAspectFill
    
    public init(_ image: UIImage? = nil) {
        self.image = image
    }
    
    public init(url: Any?) {
        self.url = url
    }
    
    public func image(_ image: UIImage?) -> FWImageWrapper {
        var result = self
        result.image = image
        return result
    }
    
    public func url(_ url: Any?) -> FWImageWrapper {
        var result = self
        result.url = url
        return result
    }
    
    public func placeholder(_ placeholder: UIImage?) -> FWImageWrapper {
        var result = self
        result.placeholder = placeholder
        return result
    }
    
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
        if image != nil {
            imageView.image = image
        } else {
            imageView.fwSetImage(withURL: url, placeholderImage: placeholder)
        }
        return imageView
    }
    
    public func updateUIView(_ imageView: UIImageView, context: Context) {
        imageView.contentMode = contentMode
    }
    
    public static func dismantleUIView(_ imageView: UIImageView, coordinator: ()) {
        imageView.fwCancelImageRequest()
    }
}
