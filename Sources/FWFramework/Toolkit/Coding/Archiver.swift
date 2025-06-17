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
    public static func archivedData<T>(_ object: T?) -> Data? {
        guard let object else { return nil }
        do {
            if ArchiveCoder.isArchivableObject(object) {
                let archiveCoder = ArchiveCoder()
                archiveCoder.setArchivableObject(object)
                return try NSKeyedArchiver.archivedData(withRootObject: archiveCoder, requiringSecureCoding: false)
            } else {
                return try NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: false)
            }
        } catch {
            #if DEBUG
            Logger.debug(group: Logger.fw.moduleName, "Archive error: %@", error.localizedDescription)
            #endif
            return nil
        }
    }

    /// 将数据解档为对象，兼容NSCoding和AnyArchivable
    public func unarchivedObject<T>(as type: T.Type = T.self) -> T? {
        do {
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: base)
            unarchiver.requiresSecureCoding = false
            let result = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey)
            if let archiveCoder = result as? ArchiveCoder {
                return archiveCoder.archivableObject(as: type)
            }
            return result as? T
        } catch {
            #if DEBUG
            Logger.debug(group: Logger.fw.moduleName, "Unarchive error: %@", error.localizedDescription)
            #endif
            return nil
        }
    }

    /// 将对象归档保存到文件，兼容NSCoding和AnyArchivable
    @discardableResult
    public static func archiveObject<T>(_ object: T, toFile path: String) -> Bool {
        guard let data = archivedData(object) else { return false }
        do {
            try data.write(to: URL(fileURLWithPath: path))
            return true
        } catch {
            return false
        }
    }

    /// 从文件解档对象，兼容NSCoding和AnyArchivable
    public static func unarchivedObject<T>(withFile path: String, as type: T.Type = T.self) -> T? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return data.fw.unarchivedObject(as: type)
    }

    /// 将数据解档为指定类型对象，需实现NSSecureCoding，推荐使用
    public func unarchivedCodingObject<T>(as type: T.Type) -> T? where T: NSObject, T: NSCoding {
        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: type, from: base)
        } catch {
            #if DEBUG
            Logger.debug(group: Logger.fw.moduleName, "Unarchive error: %@", error.localizedDescription)
            #endif
            return nil
        }
    }

    /// 将数据解档为指定AnyArchivable对象，推荐使用
    public func unarchivedArchivableObject<T>(as type: T.Type) -> T? where T: AnyArchivable {
        do {
            let archiveCoder = try NSKeyedUnarchiver.unarchivedObject(ofClass: ArchiveCoder.self, from: base)
            return archiveCoder?.archivableObject(as: type)
        } catch {
            #if DEBUG
            Logger.debug(group: Logger.fw.moduleName, "Unarchive error: %@", error.localizedDescription)
            #endif
            return nil
        }
    }

    /// 从文件解档指定类型对象，需实现NSSecureCoding，推荐使用
    public static func unarchivedCodingObject<T>(as type: T.Type, withFile path: String) -> T? where T: NSObject, T: NSCoding {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return data.fw.unarchivedCodingObject(as: type)
    }

    /// 从文件解档指定AnyArchivable对象，推荐使用
    public static func unarchivedArchivableObject<T>(as type: T.Type, withFile path: String) -> T? where T: AnyArchivable {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return data.fw.unarchivedArchivableObject(as: type)
    }
}

// MARK: - ArchiveCoder
/// AnyArchivable归档编码器，注意当archiveObject为struct时，必须先调用registerType注册
public class ArchiveCoder: NSObject, NSSecureCoding {
    // MARK: - Static
    /// 是否是有效的AnyArchivable归档对象或对象数组
    public static func isArchivableObject(_ object: Any?) -> Bool {
        guard let object else { return false }
        return object is [AnyArchivable] || object is AnyArchivable
    }

    /// 是否是有效的AnyArchivable归档数据(即ArchiveCoder归档数据)
    public static func isArchivableData(_ data: Data?) -> Bool {
        guard let data else { return false }
        return unarchivedCoder(data) != nil
    }

    /// 将Data数据解档为ArchiveCoder对象，失败时返回nil
    public static func unarchivedCoder(_ data: Data) -> ArchiveCoder? {
        let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver?.requiresSecureCoding = false
        unarchiver?.decodingFailurePolicy = .setErrorAndReturn
        let result = unarchiver?.decodeObject(forKey: NSKeyedArchiveRootObjectKey)
        return result as? ArchiveCoder
    }

    /// 将AnyArchivable对象编码为Data数据，不调用NSKeyedArchiver
    public static func encodeObject(_ object: AnyArchivable?) -> Data? {
        object?.archiveEncode()
    }

    /// 将AnyArchivable对象数组编码为Data数据，不调用NSKeyedArchiver
    public static func encodeObjects(_ objects: [AnyArchivable]?) -> Data? {
        guard let objects else { return nil }
        let array: [String] = objects.compactMap { object in
            guard let data = object.archiveEncode() else { return nil }
            return String(data: data, encoding: .utf8)
        }
        return try? Data.fw.jsonEncode(array)
    }

    /// 将Data数据解码为AnyArchivable对象，不调用NSKeyedUnarchiver
    public static func decodeObject<T: AnyArchivable>(_ data: Data?, as type: T.Type = T.self) -> T? {
        T.archiveDecode(data)
    }

    /// 将Data数据解码为AnyArchivable对象数组，不调用NSKeyedUnarchiver
    public static func decodeObjects<T: AnyArchivable>(_ data: Data?, as type: T.Type = T.self) -> [T]? {
        guard let data, let array = try? Data.fw.jsonDecode(data) as? [String] else { return nil }
        return array.compactMap { T.archiveDecode($0.data(using: .utf8)) }
    }

    // MARK: - Register
    /// 当识别不出类型时需先注册struct归档类型，如果为class则无需注册(NSClassFromString自动处理)
    public static func registerType<T: AnyArchivable>(_ type: T.Type) {
        let key = String(describing: type as AnyObject)
        FrameworkConfiguration.archiveRegisteredTypes[key] = type
    }

    /// 归档类型加载器，加载未注册类型时会尝试调用并注册，block返回值为registerType方法type参数
    public static let sharedLoader = Loader<String, AnyArchivable.Type>()

    // MARK: - Public
    /// 归档数据，设置归档对象时自动处理
    public private(set) var archiveData: Data?
    /// 归档类型，当识别不出类型且归档对象为struct时，必须先调用registerType注册
    public private(set) var archiveType: String?

    override public init() {
        super.init()
    }

    /// 读取指定AnyArchivable对象或对象数组，自动处理归档数据
    public func archivableObject<T>(as type: T.Type = T.self) -> T? {
        // 指定对象数组类型
        if let objectsType = type as? [AnyArchivable].Type,
           let objectType = objectsType.Element as? AnyArchivable.Type {
            return ArchiveCoder.decodeObjects(archiveData, as: objectType) as? T
            // 指定对象类型
        } else if let objectType = type as? AnyArchivable.Type {
            return ArchiveCoder.decodeObject(archiveData, as: objectType) as? T
            // 未指定类型
        } else {
            guard var archiveType else { return nil }
            var isArray = false
            if archiveType.hasPrefix("["), archiveType.hasSuffix("]") {
                archiveType = String(archiveType.dropFirst().dropLast())
                isArray = true
            }
            var objectType = FrameworkConfiguration.archiveRegisteredTypes[archiveType]
            if objectType == nil {
                if let loadType = try? ArchiveCoder.sharedLoader.load(archiveType) {
                    ArchiveCoder.registerType(loadType)
                    objectType = loadType
                } else {
                    objectType = NSClassFromString(archiveType) as? AnyArchivable.Type
                }
            }
            guard let objectType else {
                #if DEBUG
                Logger.error(group: Logger.fw.moduleName, "\n========== ERROR ==========\nYou must call ArchiveCoder.registerType(_:) to register %@ before using it\n========== ERROR ==========", archiveType)
                #endif
                return nil
            }

            if isArray {
                return ArchiveCoder.decodeObjects(archiveData, as: objectType) as? T
            } else {
                return ArchiveCoder.decodeObject(archiveData, as: objectType) as? T
            }
        }
    }

    /// 设置指定AnyArchivable对象或对象数组，自动处理归档数据
    public func setArchivableObject<T>(_ value: T?) {
        var objectType: AnyArchivable.Type?
        var isArray = false
        // 指定对象数组类型
        if let genericTypes = T.self as? [AnyArchivable].Type,
           let genericType = genericTypes.Element as? AnyArchivable.Type {
            archiveData = ArchiveCoder.encodeObjects(value as? [AnyArchivable])
            objectType = genericType
            isArray = true
            // 指定对象类型
        } else if let genericType = T.self as? AnyArchivable.Type {
            archiveData = ArchiveCoder.encodeObject(value as? AnyArchivable)
            objectType = genericType
            // 未指定类型
        } else {
            if let objects = value as? [AnyArchivable] {
                archiveData = ArchiveCoder.encodeObjects(objects)
                if let object = objects.first { objectType = type(of: object) }
                isArray = true
            } else if let object = value as? AnyArchivable {
                archiveData = ArchiveCoder.encodeObject(object)
                objectType = type(of: object)
            } else {
                archiveData = nil
            }
        }

        if let clazz = objectType as? AnyClass {
            let className = NSStringFromClass(clazz)
            archiveType = isArray ? "[\(className)]" : className
        } else if let objectType {
            let typeName = String(describing: objectType as AnyObject)
            if FrameworkConfiguration.archiveRegisteredTypes[typeName] == nil {
                ArchiveCoder.registerType(objectType)
            }
            archiveType = isArray ? "[\(typeName)]" : typeName
        } else {
            archiveType = nil
        }
    }

    // MARK: - NSSecureCoding
    public static var supportsSecureCoding: Bool {
        true
    }

    public required init?(coder: NSCoder) {
        super.init()
        self.archiveData = coder.decodeObject(forKey: "archiveData") as? Data
        self.archiveType = coder.decodeObject(forKey: "archiveType") as? String
    }

    public func encode(with coder: NSCoder) {
        coder.encode(archiveData, forKey: "archiveData")
        coder.encode(archiveType, forKey: "archiveType")
    }
}

// MARK: - AnyArchivable
/// 任意可归档对象协议，兼容UserDefaults | Cache | Database | Keychain | Codable | CodableModel | SmartModel | MappableModel使用
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
        archiveDecode(data) ?? .init()
    }
}

extension AnyArchivable where Self: Codable {
    /// 默认实现将Data数据解码为对象，不调用NSKeyedUnarchiver
    public static func archiveDecode(_ data: Data?) -> Self? {
        guard let data else { return nil }

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
        ArchiveCoder.decodeObjects(data)
    }

    /// 将Data数据解码为安全对象数组，不调用NSKeyedUnarchiver
    public static func archiveDecodeSafe(_ data: Data?) -> Self {
        archiveDecode(data) ?? []
    }

    /// 将对象数组编码为Data数据，不调用NSKeyedArchiver
    public func archiveEncode() -> Data? {
        ArchiveCoder.encodeObjects(self)
    }
}

// MARK: - FrameworkConfiguration+Archiver
extension FrameworkConfiguration {
    fileprivate static var archiveRegisteredTypes: [String: AnyArchivable.Type] = [:]
}
