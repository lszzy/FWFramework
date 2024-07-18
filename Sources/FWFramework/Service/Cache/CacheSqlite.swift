//
//  CacheSqlite.swift
//  FWFramework
//
//  Created by wuyong on 2023/3/29.
//

import Foundation
import SQLite3

/// Sqlite缓存。复杂对象需遵循NSCoding|AnyArchivable协议
open class CacheSqlite: CacheEngine, @unchecked Sendable {
    
    /// 单例模式
    public static let shared = CacheSqlite()
    
    private var dbPath: String = ""
    
    private var database: OpaquePointer!
    
    public override convenience init() {
        self.init(path: nil)
    }
    
    /// 指定路径
    public init(path: String?) {
        super.init()
        // 绝对路径: path
        var dbPath: String
        if let path = path, (path as NSString).isAbsolutePath {
            dbPath = path
        // 相对路径: Libray/Caches/FWFramework/CacheSqlite/path[shared.sqlite]
        } else {
            let cachePath = FileManager.fw.pathCaches.fw.appendingPath(["FWFramework", "CacheSqlite"])
            let fileName = path ?? ""
            dbPath = cachePath.fw.appendingPath(!fileName.isEmpty ? fileName : "shared.sqlite")
        }
        self.dbPath = dbPath
        // 自动创建目录
        let fileDir = (dbPath as NSString).deletingLastPathComponent
        if !FileManager.default.fileExists(atPath: fileDir) {
            try? FileManager.default.createDirectory(atPath: fileDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        // 初始化数据库和创建缓存表
        if open() {
            let sql = "CREATE TABLE IF NOT EXISTS FWCache (key TEXT PRIMARY KEY, object BLOB);"
            sqlite3_exec(database, sql, nil, nil, nil)
            close()
        }
    }
    
    private func open() -> Bool {
        if sqlite3_open(dbPath, &database) == SQLITE_OK {
            return true
        }
        return false
    }
    
    private func close() {
        if database != nil {
            sqlite3_close(database)
            database = nil
        }
    }
    
    // MARK: - CacheEngineProtocol
    open override func readCache(forKey key: String) -> Any? {
        var object: Any?
        autoreleasepool {
            if open() {
                let sql = "SELECT object FROM FWCache WHERE key = ?"
                var stmt: OpaquePointer?
                if sqlite3_prepare_v2(database, sql, -1, &stmt, nil) == SQLITE_OK {
                    sqlite3_bind_text(stmt, 1, (key as NSString).utf8String, -1, nil)
                    
                    while sqlite3_step(stmt) == SQLITE_ROW {
                        let dataBuffer = sqlite3_column_blob(stmt, 0)
                        let dataSize = sqlite3_column_bytes(stmt, 0)
                        if let dataBuffer = dataBuffer {
                            let data = Data(bytes: dataBuffer, count: Int(dataSize))
                            object = data.fw.unarchivedObject()
                        }
                    }
                }
                sqlite3_finalize(stmt)
                
                close()
            }
        }
        return object
    }
    
    open override func writeCache(_ object: Any, forKey key: String) {
        guard let data = Data.fw.archivedData(object) as? NSData else { return }
        
        autoreleasepool {
            if open() {
                let sql = "REPLACE INTO FWCache (key, object) VALUES (?, ?)"
                var stmt: OpaquePointer?
                if sqlite3_prepare_v2(database, sql, -1, &stmt, nil) == SQLITE_OK {
                    sqlite3_bind_text(stmt, 1, (key as NSString).utf8String, -1, nil)
                    
                    sqlite3_bind_blob(stmt, 2, data.bytes, Int32(data.length), nil)
                    sqlite3_step(stmt)
                }
                sqlite3_finalize(stmt)
                
                close()
            }
        }
    }
    
    open override func clearCache(forKey key: String) {
        autoreleasepool {
            if open() {
                let sql = "DELETE FROM FWCache WHERE key = ?"
                var stmt: OpaquePointer?
                if sqlite3_prepare_v2(database, sql, -1, &stmt, nil) == SQLITE_OK {
                    sqlite3_bind_text(stmt, 1, (key as NSString).utf8String, -1, nil)
                    
                    sqlite3_step(stmt)
                }
                sqlite3_finalize(stmt)
                
                close()
            }
        }
    }
    
    open override func clearAllCaches() {
        autoreleasepool {
            if open() {
                var sql = "DELETE FROM FWCache"
                sqlite3_exec(database, sql, nil, nil, nil)
                
                sql = "VACUUM"
                sqlite3_exec(database, sql, nil, nil, nil)
                
                close()
            }
        }
    }
    
}
