//
//  CacheFile.swift
//  FWFramework
//
//  Created by wuyong on 2023/3/29.
//

import Foundation
import CommonCrypto

/// 文件缓存
open class CacheFile: CacheEngine {
    
    /// 单例模式
    public static let shared = CacheFile()
    
    private var path: String = ""
    
    public override convenience init() {
        self.init(path: nil)
    }
    
    /// 指定路径
    public init(path: String?) {
        super.init()
        // 绝对路径: path
        if let path = path, (path as NSString).isAbsolutePath {
            self.path = path
        // 相对路径: Libray/Caches/FWCache/path[FWCache]
        } else {
            let cachesPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
            let fileName = path ?? ""
            self.path = (cachesPath as NSString).appendingPathComponent("FWCache/" + (!fileName.isEmpty ? fileName : "FWCache"))
        }
    }
    
    private func filePath(_ key: String) -> String {
        // 文件名md5加密
        let cStr = key.cString(using: .utf8)
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        var digest = [UInt8](repeating: 0, count: digestLen)
        CC_MD5(cStr, CC_LONG(strlen(cStr!)), &digest)
        
        var md5Str = ""
        for i in 0..<digestLen {
            md5Str += String(format: "%02x", digest[i])
        }
        
        let fileName = "\(md5Str).plist"
        return (path as NSString).appendingPathComponent(fileName)
    }
    
    // MARK: - CacheEngineProtocol
    open override func readCache(forKey key: String) -> Any? {
        let filePath = filePath(key)
        if FileManager.default.fileExists(atPath: filePath) {
            return NSKeyedUnarchiver.unarchiveObject(withFile: filePath)
        }
        return nil
    }
    
    open override func writeCache(_ object: Any, forKey key: String) {
        let filePath = filePath(key)
        // 自动创建目录
        let fileDir = (filePath as NSString).deletingLastPathComponent
        if !FileManager.default.fileExists(atPath: fileDir) {
            try? FileManager.default.createDirectory(atPath: fileDir, withIntermediateDirectories: true, attributes: nil)
        }
        NSKeyedArchiver.archiveRootObject(object, toFile: filePath)
    }
    
    open override func clearCache(forKey key: String) {
        let filePath = filePath(key)
        try? FileManager.default.removeItem(atPath: filePath)
    }
    
    open override func clearAllCaches() {
        try? FileManager.default.removeItem(atPath: path)
    }
    
}
