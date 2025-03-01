//
//  CacheFile.swift
//  FWFramework
//
//  Created by wuyong on 2023/3/29.
//

import CommonCrypto
import Foundation

/// 文件缓存。复杂对象需遵循NSCoding|AnyArchivable协议
open class CacheFile: CacheEngine, @unchecked Sendable {
    /// 单例模式
    public static let shared = CacheFile()
    
    /// 缓存根目录路径
    public private(set) var cachePath: String = ""

    override public convenience init() {
        self.init(path: nil)
    }

    /// 指定路径
    public init(path: String?) {
        super.init()
        // 绝对路径: path
        if let path, (path as NSString).isAbsolutePath {
            self.cachePath = path
        // 相对路径: Libray/Caches/FWFramework/CacheFile/path[shared]
        } else {
            let cachePath = FileManager.fw.pathCaches.fw.appendingPath(["FWFramework", "CacheFile"])
            let fileName = path ?? ""
            self.cachePath = cachePath.fw.appendingPath(!fileName.isEmpty ? fileName : "shared")
        }
    }

    private func filePath(_ key: String) -> String {
        let fileName = "\(key.fw.md5Encode).plist"
        return (cachePath as NSString).appendingPathComponent(fileName)
    }

    // MARK: - CacheEngineProtocol
    override open func readCache<T>(forKey key: String) -> T? {
        let filePath = filePath(key)
        if FileManager.default.fileExists(atPath: filePath) {
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else { return nil }
            return data.fw.unarchivedObject(as: T.self)
        }
        return nil
    }

    override open func writeCache<T>(_ object: T, forKey key: String) {
        let filePath = filePath(key)
        // 自动创建目录
        let fileDir = (filePath as NSString).deletingLastPathComponent
        if !FileManager.default.fileExists(atPath: fileDir) {
            try? FileManager.default.createDirectory(atPath: fileDir, withIntermediateDirectories: true, attributes: nil)
        }
        guard let data = Data.fw.archivedData(object) else { return }
        try? data.write(to: URL(fileURLWithPath: filePath))
    }

    override open func clearCache(forKey key: String) {
        let filePath = filePath(key)
        try? FileManager.default.removeItem(atPath: filePath)
    }

    override open func clearAllCaches() {
        try? FileManager.default.removeItem(atPath: cachePath)
    }
}
