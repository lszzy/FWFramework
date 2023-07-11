//
//  AnimatedImage.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

@_spi(FW) extension UIImage {
    
    /// 图片循环次数，静态图片始终是0，动态图片0代表无限循环
    public var fw_imageLoopCount: UInt {
        get {
            if let value = fw_property(forName: "fw_imageLoopCount") as? NSNumber {
                return value.uintValue
            }
            return .zero
        }
        set {
            fw_setProperty(NSNumber(value: newValue), forName: "fw_imageLoopCount")
        }
    }

    /// 是否是动图，内部检查images数组
    public var fw_isAnimated: Bool {
        return self.images != nil
    }
    
    /// 是否是向量图，内部检查isSymbolImage属性，iOS11+支持PDF，iOS13+支持SVG
    public var fw_isVector: Bool {
        return ImageCoder.isVectorImage(self)
    }
    
    /// 获取图片原始数据格式，未指定时尝试从CGImage获取，获取失败返回ImageFormatUndefined
    public var fw_imageFormat: ImageFormat {
        get {
            if let value = fw_property(forName: "fw_imageFormat") as? NSNumber {
                return .init(value.intValue)
            }
            return ImageCoder.imageFormat(fromUTType: self.cgImage?.utType)
        }
        set {
            fw_setProperty(NSNumber(value: newValue.rawValue), forName: "fw_imageFormat")
        }
    }
    
}

@_spi(FW) extension Data {
    
    /// 获取图片数据的格式，未知格式返回ImageFormatUndefined
    public static func fw_imageFormat(for imageData: Data?) -> ImageFormat {
        return ImageCoder.imageFormat(forImageData: imageData)
    }
    
    /// 图片格式转化为UTType，未知格式返回kUTTypeImage
    public static func fw_utType(from imageFormat: ImageFormat) -> CFString {
        return ImageCoder.utType(fromImageFormat: imageFormat)
    }

    /// UTType转化为图片格式，未知格式返回ImageFormatUndefined
    public static func fw_imageFormat(from utType: CFString) -> ImageFormat {
        return ImageCoder.imageFormat(fromUTType: utType)
    }

    /// 图片格式转化为mimeType，未知格式返回application/octet-stream
    public static func fw_mimeType(from imageFormat: ImageFormat) -> String {
        return ImageCoder.mimeType(fromImageFormat: imageFormat)
    }
    
    /// 文件后缀转化为mimeType，未知后缀返回application/octet-stream
    public static func fw_mimeType(from ext: String) -> String {
        return ImageCoder.mimeType(fromExtension: ext)
    }

    /// 图片数据编码为base64字符串，可直接用于H5显示等，字符串格式：data:image/png;base64,数据
    public static func fw_base64String(for imageData: Data?) -> String? {
        return ImageCoder.base64String(forImageData: imageData)
    }
    
}
