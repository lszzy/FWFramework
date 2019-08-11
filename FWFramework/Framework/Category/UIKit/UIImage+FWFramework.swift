//
//  UIImage+FWFramework.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/28.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation

/// 使用文件名方式加载UIImage。会被系统缓存，适用于大量复用的小资源图
///
/// - Parameter name: 图片名称
/// - Returns: UIImage
public func FWImageName(_ name: String) -> UIImage? {
    return UIImage(named: name)
}

/// 从图片文件或应用资源路径加载UIImage。不会被系统缓存，适用于不被复用的图片，特别是大图
///
/// - Parameter path: 文件路径
/// - Returns: UIImage
public func FWImageFile(_ path: String) -> UIImage? {
    if (path as NSString).isAbsolutePath {
        return UIImage(contentsOfFile: path)
    }
    guard let file = Bundle.main.path(forResource: path, ofType: nil) else { return nil }
    return UIImage(contentsOfFile: file)
}
