//
//  Archiver.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation

// MARK: - Wrapper+Data
extension Wrapper where Base == Data {
    /// 将对象归档为data数据，兼容NSCoding和AnyArchivable
    public static func archivedData(_ object: Any?) -> Data? {
        guard var object = object else { return nil }
        do {
            if ArchiverContainer.isArchivableObject(object) {
                let container = ArchiverContainer()
                container.archivableObject = object
                object = container
            }
            
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
    
    /// 将数据解档为指定AnyArchivable对象，推荐使用
    public func unarchivedObject<T>(_ type: T.Type) -> T? where T : AnyArchivable {
        do {
            let container = try NSKeyedUnarchiver.unarchivedObject(ofClass: ArchiverContainer.self, from: base)
            return container?.archivableObject as? T
        } catch {
            #if DEBUG
            Logger.debug(group: Logger.fw.moduleName, "Unarchive error: %@", error.localizedDescription)
            #endif
            return nil
        }
    }
    
    /// 将数据解档为对象，兼容NSCoding和AnyArchivable
    public func unarchivedObject() -> Any? {
        do {
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: base)
            unarchiver.requiresSecureCoding = false
            let result = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey)
            if let container = result as? ArchiverContainer {
                return container.archivableObject
            }
            return result
        } catch {
            #if DEBUG
            Logger.debug(group: Logger.fw.moduleName, "Unarchive error: %@", error.localizedDescription)
            #endif
            return nil
        }
    }
    
    /// 将对象归档保存到文件，兼容NSCoding和AnyArchivable
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
    
    /// 从文件解档指定AnyArchivable对象，推荐使用
    public static func unarchivedObject<T>(_ type: T.Type, withFile path: String) -> T? where T : AnyArchivable {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return data.fw.unarchivedObject(type)
    }
    
    /// 从文件解档对象，兼容NSCoding和AnyArchivable
    public static func unarchivedObject(withFile path: String) -> Any? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return data.fw.unarchivedObject()
    }
    
    /// 将AnyArchivable对象数组编码为Data数据，不调用NSKeyedArchiver
    public static func archiveEncodeObjects(_ objects: [AnyArchivable]?) -> Data? {
        guard let objects = objects else { return nil }
        let array: [String] = objects.compactMap { object in
            guard let data = object.archiveEncode() else { return nil }
            return String(data: data, encoding: .utf8)
        }
        return try? Data.fw.jsonEncode(array)
    }
    
    /// 将Data数据解码为AnyArchivable对象数组，不调用NSKeyedUnarchiver
    public func archiveDecodedObjects<T>(_ type: T.Type) -> [T]? where T : AnyArchivable {
        guard let array = try? Data.fw.jsonDecode(base) as? [String] else { return nil }
        return array.compactMap { T.archiveDecode($0.data(using: .utf8)) }
    }
}

// MARK: - ArchiverContainer
/// AnyArchivable归档容器，注意当archiveObject为struct时，必须先调用registerType注册
public class ArchiverContainer: NSObject, NSSecureCoding {
    /// 指定AnyArchivable对象或对象数组，自动处理归档数据
    public var archivableObject: Any? {
        get {
            guard let archiveType = archiveType else { return nil }
            var resultType = ArchiverContainer.registeredTypes[archiveType]
            if resultType == nil {
                resultType = NSClassFromString(archiveType) as? AnyArchivable.Type
            }
            guard let resultType = resultType else {
                #if DEBUG
                Logger.error(group: Logger.fw.moduleName, "\n========== ERROR ==========\nYou must call ArchiverContainer.registerType(_:) to register %@ before using it\n========== ERROR ==========", archiveType)
                #endif
                return nil
            }
            
            if isCollection {
                return archiveData?.fw.archiveDecodedObjects(resultType)
            } else {
                return resultType.archiveDecode(archiveData)
            }
        }
        set {
            var object = newValue as? AnyArchivable
            if let objects = newValue as? [AnyArchivable] {
                object = objects.first
                archiveData = Data.fw.archiveEncodeObjects(objects)
                isCollection = true
            } else {
                archiveData = object?.archiveEncode()
                isCollection = false
            }
            
            if let object = object, let clazz = type(of: object) as? AnyClass {
                archiveType = NSStringFromClass(clazz)
            } else if let object = object {
                archiveType = String(describing: type(of: object) as AnyObject)
            } else {
                archiveType = nil
            }
        }
    }
    
    /// 归档数据，设置归档对象时自动处理
    public private(set) var archiveData: Data?
    /// 归档类型，如果归档对象为struct时，必须先调用registerType注册
    public private(set) var archiveType: String?
    /// 是否是归档集合，设置归档对象时自动处理
    public private(set) var isCollection = false
    
    private static var registeredTypes: [String: AnyArchivable.Type] = [:]
    
    /// 注册struct归档类型，如果为class则无需注册(NSClassFromString自动处理)
    public static func registerType<T: AnyArchivable>(_ type: T.Type) {
        let key = String(describing: type as AnyObject)
        registeredTypes[key] = type
    }
    
    /// 是否是有效的AnyArchivable归档对象或对象数组
    public static func isArchivableObject(_ object: Any?) -> Bool {
        guard let object = object else { return false }
        return object is [AnyArchivable] || object is AnyArchivable
    }
    
    /// 默认初始化方法
    public override init() {
        super.init()
    }
    
    /// 指定归档完整数据并初始化
    public init<T: AnyArchivable>(archiveData: Data?, archiveType: T.Type?, isCollection: Bool = false) {
        super.init()
        self.archiveData = archiveData
        if let archiveClass = archiveType as? AnyClass {
            self.archiveType = NSStringFromClass(archiveClass)
        } else if let archiveType = archiveType {
            self.archiveType = String(describing: archiveType as AnyObject)
        }
        self.isCollection = isCollection
    }
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    public required init?(coder: NSCoder) {
        super.init()
        archiveData = coder.decodeObject(forKey: "archiveData") as? Data
        archiveType = coder.decodeObject(forKey: "archiveType") as? String
        isCollection = coder.decodeBool(forKey: "isCollection")
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(archiveData, forKey: "archiveData")
        coder.encode(archiveType, forKey: "archiveType")
        coder.encode(isCollection, forKey: "isCollection")
    }
}

// MARK: - AnyArchivable
/// 任意可归档对象协议，兼容UserDefaults | Cache | Keychain | Codable | CodableModel | JSONModel使用
public protocol AnyArchivable: ObjectType {
    /// 将Data数据解码为对象，不调用NSKeyedUnarchiver
    static func archiveDecode(_ data: Data?) -> Self?
    /// 将Data数据解码为安全对象，不调用NSKeyedUnarchiver
    static func archiveDecodeSafe(_ data: Data?) -> Self
    /// 将对象编码为Data数据，不调用NSKeyedArchiver
    func archiveEncode() -> Data?
}

extension AnyArchivable {
    /// 默认实现将Data数据解码为安全对象，不调用NSKeyedUnarchiver
    public static func archiveDecodeSafe(_ data: Data?) -> Self {
        return archiveDecode(data) ?? .init()
    }
}

extension AnyArchivable where Self: Codable {
    /// 默认实现将Data数据解码为对象，不调用NSKeyedUnarchiver
    public static func archiveDecode(_ data: Data?) -> Self? {
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
    
    /// 默认实现将对象编码为Data数据，不调用NSKeyedArchiver
    public func archiveEncode() -> Data? {
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

extension Array where Element: AnyArchivable {
    /// 将Data数据解码为对象数组，不调用NSKeyedUnarchiver
    public static func archiveDecode(_ data: Data?) -> Self? {
        return data?.fw.archiveDecodedObjects(Element.self)
    }
    
    /// 将Data数据解码为安全对象数组，不调用NSKeyedUnarchiver
    public static func archiveDecodeSafe(_ data: Data?) -> Self {
        return archiveDecode(data) ?? []
    }
    
    /// 将对象数组编码为Data数据，不调用NSKeyedArchiver
    public func archiveEncode() -> Data? {
        return Data.fw.archiveEncodeObjects(self)
    }
}
