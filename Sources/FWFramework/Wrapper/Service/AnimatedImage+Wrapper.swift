//
//  AnimatedImage+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

extension Wrapper where Base: UIImage {
    
    /// 图片循环次数，静态图片始终是0，动态图片0代表无限循环
    public var imageLoopCount: UInt {
        get { return base.fw_imageLoopCount }
        set { base.fw_imageLoopCount = newValue }
    }

    /// 是否是动图，内部检查images数组
    public var isAnimated: Bool {
        return base.fw_isAnimated
    }
    
    /// 是否是向量图，内部检查isSymbolImage属性，iOS11+支持PDF，iOS13+支持SVG
    public var isVector: Bool {
        return base.fw_isVector
    }
    
    /// 获取图片原始数据格式，未指定时尝试从CGImage获取，获取失败返回ImageFormatUndefined
    public var imageFormat: ImageFormat {
        get { return base.fw_imageFormat }
        set { base.fw_imageFormat = newValue }
    }
    
}

extension Wrapper where Base == Data {
    
    /// 获取图片数据的格式，未知格式返回ImageFormatUndefined
    public static func imageFormat(for imageData: Data?) -> ImageFormat {
        return Base.fw_imageFormat(for: imageData)
    }
    
    /// 图片格式转化为UTType，未知格式返回kUTTypeImage
    public static func utType(from imageFormat: ImageFormat) -> CFString {
        return Base.fw_utType(from: imageFormat)
    }

    /// UTType转化为图片格式，未知格式返回ImageFormatUndefined
    public static func imageFormat(from utType: CFString) -> ImageFormat {
        return Base.fw_imageFormat(from: utType)
    }

    /// 图片格式转化为mimeType，未知格式返回application/octet-stream
    public static func mimeType(from imageFormat: ImageFormat) -> String {
        return Base.fw_mimeType(from: imageFormat)
    }
    
    /// 文件后缀转化为mimeType，未知后缀返回application/octet-stream
    public static func mimeType(from fileExtension: String) -> String {
        return Base.fw_mimeType(from: fileExtension)
    }

    /// 图片数据编码为base64字符串，可直接用于H5显示等，字符串格式：data:image/png;base64,数据
    public static func base64String(for imageData: Data?) -> String? {
        return Base.fw_base64String(for: imageData)
    }
    
    /// 图片base64字符串解码为数据，兼容格式：data:image/png;base64,数据
    public static func imageData(for base64String: String?) -> Data? {
        return Base.fw_imageData(for: base64String)
    }
    
}
