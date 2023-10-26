//
//  AssetManager.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
import Photos

// MARK: - Asset
public enum AssetType: UInt {
    case .unknown = 0
    case .image
    case .video
    case .audio
}

public enum AssetSubType: UInt {
    case .unknown = 0
    case .image
    case .livePhoto
    case .gif
}

public enum AssetDownloadStatus: UInt {
    case .succeed = 0
    case .downloading
    case .canceled
    case .failed
}

// MARK: - AssetGroup

// MARK: - AssetManager
