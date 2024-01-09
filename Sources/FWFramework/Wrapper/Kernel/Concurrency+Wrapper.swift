//
//  Concurrency+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2023/11/30.
//

import UIKit

extension Wrapper where Base: UIImage {
    
    /// 异步下载网络图片
    public static func downloadImage(_ url: URLParameter?, options: WebImageOptions = [], context: [ImageCoderOptions: Any]? = nil) async throws -> UIImage {
        try await Base.fw_downloadImage(url, options: options, context: context)
    }
    
}
