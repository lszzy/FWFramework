//
//  FWWebImage.swift
//  FWFramework
//
//  Created by wuyong on 2020/11/5.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import SwiftUI

/// SwiftUI加载网络图片
@available(iOS 13.0, *)
public struct FWWebImage: UIViewRepresentable {
    var url: Any?
    var placeholder: UIImage?
    var completion: ((UIImage?, Error?) -> Void)?
    var progress: ((Double) -> Void)?
    var contentMode: UIView.ContentMode = .scaleAspectFill
    
    // TODO: 图片模式，取消方法，是否自动取消，销毁时取消，离开时是否取消，回来时是否继续
    
    public init(url: Any? = nil) {
        self.url = url
    }
    
    // MARK: - UIViewRepresentable
    
    public typealias UIViewType = UIImageView
    
    static var index: Int = 0
    
    public func makeUIView(context: Context) -> UIImageView {
        let imageClass = UIImageView.fwImageViewAnimatedClass as! UIImageView.Type
        let imageView = imageClass.init(frame: .zero)
        imageView.contentMode = contentMode
        imageView.clipsToBounds = true
        Self.index += 1
        imageView.tag = Self.index
        print("FWWebImage: makeUIView \(imageView.tag)")
        imageView.fwSetImage(withURL: url, placeholderImage: placeholder, completion: completion, progress: progress)
        return imageView
    }
    
    public func updateUIView(_ uiView: UIImageView, context: Context) {
        print("FWWebImage: updateUIView \(uiView.tag)")
    }
    
    public static func dismantleUIView(_ uiView: UIImageView, coordinator: ()) {
        print("FWWebImage: dismantleUIView \(uiView.tag)")
    }
    
    // MARK: - Public
    
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
    
    public func contentMode(_ contentMode: UIView.ContentMode) -> FWWebImage {
        var result = self
        result.contentMode = contentMode
        return result
    }
    
    public func cancel() -> FWWebImage {
        var result = self
        return result
    }
}
