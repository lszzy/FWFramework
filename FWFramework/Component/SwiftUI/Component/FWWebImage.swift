//
//  FWWebImage.swift
//  FWFramework
//
//  Created by wuyong on 2020/11/5.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#if canImport(SwiftUI)

import SwiftUI

/// SwiftUI加载网络图片
@available(iOS 13.0, *)
public struct FWWebImage: UIViewRepresentable {
    var url: Any?
    var placeholder: UIImage?
    var completion: ((UIImage?, Error?) -> Void)?
    var progress: ((Double) -> Void)?
    var contentMode: UIView.ContentMode = .scaleAspectFill
    
    public init(url: Any? = nil) {
        self.url = url
    }
    
    public func url(_ url: Any?) -> FWWebImage {
        var result = self
        result.url = url
        return result
    }
    
    public func placeholder(_ placeholder: UIImage?) -> FWWebImage {
        var result = self
        result.placeholder = placeholder
        return result
    }
    
    public func completion(_ completion: ((UIImage?, Error?) -> Void)?) -> FWWebImage {
        var result = self
        result.completion = completion
        return result
    }
    
    public func progress(_ progress: ((Double) -> Void)?) -> FWWebImage {
        var result = self
        result.progress = progress
        return result
    }
    
    public func contentMode(_ contentMode: UIView.ContentMode) -> FWWebImage {
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
        imageView.fwSetImage(withURL: url, placeholderImage: placeholder, completion: completion, progress: progress)
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
