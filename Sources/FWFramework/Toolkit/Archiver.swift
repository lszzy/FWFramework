//
//  Archiver.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation

// MARK: - Wrapper+Data
extension Wrapper where Base == Data {
    /// 将对象归档为data数据
    public static func archivedData(_ object: Any?) -> Data? {
        guard let object = object else { return nil }
        do {
            return try NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: false)
        } catch {
            #if DEBUG
            Logger.debug(group: Logger.fw.moduleName, "Archive error: %@", error.localizedDescription)
            #endif
            return nil
        }
    }
    
    /// 将数据解档为指定类型对象，需实现NSSecureCoding，推荐使用
    public func unarchivedObject<T>(_ clazz: T.Type) -> T? where T : NSObject, T : NSCoding {
        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: clazz, from: base)
        } catch {
            #if DEBUG
            Logger.debug(group: Logger.fw.moduleName, "Unarchive error: %@", error.localizedDescription)
            #endif
            return nil
        }
    }
    
    /// 将数据解档为对象
    public func unarchivedObject() -> Any? {
        do {
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: base)
            unarchiver.requiresSecureCoding = false
            return unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey)
        } catch {
            #if DEBUG
            Logger.debug(group: Logger.fw.moduleName, "Unarchive error: %@", error.localizedDescription)
            #endif
            return nil
        }
    }
    
    /// 将对象归档保存到文件
    @discardableResult
    public static func archiveObject(_ object: Any, toFile path: String) -> Bool {
        guard let data = archivedData(object) else { return false }
        do {
            try data.write(to: URL(fileURLWithPath: path))
            return true
        } catch {
            return false
        }
    }
    
    /// 从文件解档指定类型对象，需实现NSSecureCoding，推荐使用
    public static func unarchivedObject<T>(_ clazz: T.Type, withFile path: String) -> T? where T : NSObject, T : NSCoding {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return data.fw.unarchivedObject(clazz)
    }
    
    /// 从文件解档对象
    public static func unarchivedObject(withFile path: String) -> Any? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return data.fw.unarchivedObject()
    }
}

// MARK: - ArchiveContainer
public class ArchiveContainer: NSObject, NSSecureCoding {
    public var archiveData: Data?
    public var archiveType: AnyArchivable.Type?
    
    public override init() {
        super.init()
    }
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    public required init?(coder: NSCoder) {
        super.init()
        archiveData = coder.decodeObject(forKey: "archiveData") as? Data
        archiveType = coder.decodeObject(forKey: "archiveType") as? AnyArchivable.Type
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(archiveData, forKey: "archiveData")
        coder.encode(archiveType, forKey: "archiveType")
    }
}

// MARK: - AnyArchivable
/// 任意可归档对象协议
public protocol AnyArchivable: ObjectType {
    /// 将Data数据解档为对象
    static func unarchivedObject(from data: Data?) -> Self?
    /// 将Data数据解档为安全对象
    static func unarchivedSafeObject(from data: Data?) -> Self
    /// 将对象归档为Data数据
    func archivedData() -> Data?
}

extension AnyArchivable {
    /// 默认实现将Data数据解档为安全对象
    public static func unarchivedSafeObject(from data: Data?) -> Self {
        return unarchivedObject(from: data) ?? .init()
    }
}

extension AnyArchivable where Self: Codable {
    /// 默认实现将Data数据解档为对象
    public static func unarchivedObject(from data: Data?) -> Self? {
        guard let data = data else { return nil }
        
        do {
            return try data.decoded() as Self
        } catch {
            #if DEBUG
            Logger.debug(group: Logger.fw.moduleName, "Unarchive error: %@", error.localizedDescription)
            #endif
            return nil
        }
    }
    
    /// 默认实现将对象归档为Data数据
    public func archivedData() -> Data? {
        do {
            return try encoded() as Data
        } catch {
            #if DEBUG
            Logger.debug(group: Logger.fw.moduleName, "Archive error: %@", error.localizedDescription)
            #endif
            return nil
        }
    }
}

extension Array: AnyArchivable where Element: AnyArchivable {
    /// 将Data数据解档为对象
    public static func unarchivedObject(from data: Data?) -> Self? {
        guard let data = data,
              let stringArray = try? Data.fw.jsonDecode(data) as? [String] else {
            return nil
        }
        
        let objectArray = stringArray.compactMap { Element.unarchivedObject(from: $0.data(using: .utf8)) }
        return objectArray
    }
    
    /// 将Data数据解档为安全对象
    public static func unarchivedSafeObject(from data: Data?) -> Self {
        return unarchivedObject(from: data) ?? []
    }
    
    /// 将对象归档为Data数据
    public func archivedData() -> Data? {
        let stringArray: [String] = compactMap { element in
            guard let data = element.archivedData() else { return nil }
            return String(data: data, encoding: .utf8)
        }
        return try? Data.fw.jsonEncode(stringArray)
    }
}
