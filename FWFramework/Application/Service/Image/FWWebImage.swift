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
    
    // TODO: 图片模式，取消方法，是否自动取消，销毁时取消，离开时是否取消，回来时是否继续
    
    public init(url: Any? = nil) {
        self.url = url
    }
    
    // MARK: - UIViewRepresentable
    
    public typealias UIViewType = UIImageView
    
    public func makeUIView(context: Context) -> UIImageView {
        let imageClass = UIImageView.fwImageViewAnimatedClass as! UIImageView.Type
        let imageView = imageClass.init(frame: .zero)
        imageView.fwSetImage(withURL: url, placeholderImage: placeholder, completion: completion, progress: progress)
        return imageView
    }
    
    public func updateUIView(_ uiView: UIImageView, context: Context) {
        
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
}
