//
//  Database.swift
//  FWFramework
//
//  Created by wuyong on 2023/12/25.
//

import Foundation
import SQLite3

/// 数据库模型协议信息
@objc public protocol DatabaseModel: NSObjectProtocol {
    
    /// 自定义数据存储路径
    @objc optional static func databasePath() -> String?
    
    /// 自定义模型类数据库版本号
    ///
    /// 注意：该返回值在改变数据模型属性类型/增加/删除属性时需要更改否则无法自动更新原来模型数据表字段以及类型
    @objc optional static func databaseVersion() -> String?
    
    /// 引入第三方创建的数据库存储路径比如:FMDB，使用Database进行操作其他方式创建的数据库
    @objc optional static func databaseVendorPath() -> String?
    
    /// 自定义数据库迁移处理方法，数据库版本发生变化时自动调用
    ///
    /// 注意：数据库结构会一次性升级到最新版本，只需要处理数据迁移或清理即可。当升级多个版本时，可依次比较version进行处理
    @objc optional static func databaseMigration(_ version: String)
    
    /// 指定自定义表名，默认类名，在指定引入其他方式创建的数据库时，这个时候如果表名不是模型类名需要实现该方法指定表名称
    @objc optional static func tableName() -> String?
    
    /// 自定义数据表主键名称，默认pkid
    @objc optional static func tablePrimaryKey() -> String?
    
    /// 指定数据库表属性黑名单集合
    @objc optional static func tablePropertyBlacklist() -> [String]?
    
    /// 指定数据库表属性白名单集合
    @objc optional static func tablePropertyWhitelist() -> [String]?
    
}

/// 本地数据库管理类
///
/// 备注：查询条件、排序条件、限制条件等语法和SQL语法一致，为空则无条件
///
/// [WHC_ModelSqliteKit](https://github.com/netyouli/WHC_ModelSqliteKit)
public class DatabaseManager: NSObject {
    
    /// 全局数据库模型版本号，默认1.0。如果模型实现了databaseVersion且不为空，则会忽略全局版本号
    public static var version: String = "1.0"
    
    private static var database: OpaquePointer!
    private static var semaphore = DispatchSemaphore(value: 1)
    private static var checkUpdate = true
    private static var isMigration = false
    
    /// 保存模型到本地，主键存在时更新，不存在时新增
    @discardableResult
    public static func save(_ model: DatabaseModel?) -> Bool {
        return false
    }
    
    /// 新增模型数组到本地(事务方式)，模型数组对象类型要一致
    @discardableResult
    public static func inserts(_ models: [DatabaseModel]?) -> Bool {
        return false
    }
    
    /// 新增模型到本地，自动更新主键
    @discardableResult
    public static func insert(_ model: DatabaseModel?) -> Bool {
        return false
    }
    
    /// 获取模型类表总条数，支持查询条件
    public static func count<T: DatabaseModel>(_ type: T.Type, where condition: String? = nil) -> UInt {
        let count = query(type, func: "count(*)", condition: condition) as? NSNumber
        return count?.uintValue ?? 0
    }
    
    /// 查询本地模型对象，支持查询条件、排序条件、限制条件
    ///
    /// 示例：
    /// 对person数据表查询age小于30岁并且根据age自动降序或者升序排序并且限制查询的数量为8偏移为8
    /// [DatabaseManager query:[Person class] where:@"age <= 30" order:@"age desc/asc" limit:@"8 offset 8"];
    ///
    /// - Parameters:
    ///   - type: 模型类
    ///   - where: 查询条件(查询语法和SQL where 查询语法一样，where为空则查询所有)
    ///   - order: 排序条件(排序语法和SQL order 查询语法一样，order为空则不排序)
    ///   - limit: 限制条件(限制语法和SQL limit 查询语法一样，limit为空则不限制查询)
    /// - Returns: 查询模型对象数组
    public static func query<T: DatabaseModel>(_ type: T.Type, where condition: String? = nil, order: String? = nil, limit: String? = nil) -> [T] {
        guard localName(with: type) != nil else { return [] }
        
        if !isMigration {
            semaphore.wait()
        }
        var models: [T] = []
        if openTable(type) {
            models = commonQuery(type, where: condition, order: order, limit: limit)
            close()
        }
        if !isMigration {
            semaphore.signal()
        }
        return models
    }
    
    /// 自定义sql查询
    public static func query<T: DatabaseModel>(_ type: T.Type, sql: String) -> [T] {
        guard !sql.isEmpty, localName(with: type) != nil else { return [] }
        
        if !isMigration {
            semaphore.wait()
        }
        var models: [T] = []
        if openTable(type) {
            models = startSqlQuery(type, sql: sql)
            close()
        }
        if !isMigration {
            semaphore.signal()
        }
        return models
    }
    
    /// 根据主键查询本地模型对象
    public static func query<T: DatabaseModel>(_ type: T.Type, key: Int) -> T? {
        let condition = String(format: "%@ = %ld", getPrimaryKey(type), key)
        return query(type, where: condition).first
    }
    
    /// 利用sqlite 函数进行查询，condition为其他查询条件例如：(where age > 20 order by age desc ....)
    public static func query<T: DatabaseModel>(_ type: T.Type, func: String, condition: String? = nil) -> Any? {
        return nil
    }
    
    /// 更新本地模型对象
    @discardableResult
    public static func update(_ model: DatabaseModel, where condition: String? = nil) -> Bool {
        guard localName(with: type(of: model)) != nil else { return false }
        
        if !isMigration {
            semaphore.wait()
        }
        let result = updateModel(model, where: condition)
        if !isMigration {
            semaphore.signal()
        }
        return result
    }
    
    /// 更新数据表字段
    @discardableResult
    public static func update<T: DatabaseModel>(_ type: T.Type, value: String, where condition: String? = nil) -> Bool {
        guard localName(with: type) != nil,
              !value.isEmpty else { return false }
        
        if !isMigration {
            semaphore.wait()
        }
        var result = false
        if openTable(type) {
            let tableName = getTableName(type)
            var updateSql = String(format: "UPDATE %@ SET %@", tableName, value)
            if let condition = condition, !condition.isEmpty {
                updateSql = updateSql.appendingFormat(" WHERE %@", handleWhere(condition))
            }
            result = executeSql(updateSql)
            close()
        }
        if !isMigration {
            semaphore.signal()
        }
        return result
    }
    
    /// 清空本地模型对象
    @discardableResult
    public static func clear<T: DatabaseModel>(_ type: T.Type) -> Bool {
        return delete(type, where: nil)
    }
    
    /// 根据主键删除本地模型对象，主键必须存在
    @discardableResult
    public static func delete(_ model: DatabaseModel) -> Bool {
        let modelClass = type(of: model)
        let primaryKey = getPrimaryKey(modelClass)
        let primaryValue = getPrimaryValue(model)
        if primaryValue <= 0 { return false }
        
        let condition = String(format: "%@ = %ld", primaryKey, primaryValue)
        return delete(modelClass, where: condition)
    }
    
    /// 删除本地模型对象
    @discardableResult
    public static func delete<T: DatabaseModel>(_ type: T.Type, where condition: String? = nil) -> Bool {
        if !isMigration {
            semaphore.wait()
        }
        let result = commonDeleteModel(type, where: condition)
        if !isMigration {
            semaphore.signal()
        }
        return result
    }
    
    /// 清空所有本地模型数据库
    public static func removeAllModels() {
        if !isMigration {
            semaphore.wait()
        }
        let cachePath = databaseCacheDirectory(nil)
        if FileManager.default.fileExists(atPath: cachePath) {
            let fileArray = try? FileManager.default.contentsOfDirectory(atPath: cachePath)
            fileArray?.forEach({ file in
                if file != ".DS_Store" {
                    let filePath = cachePath.fw_appendingPath(file)
                    try? FileManager.default.removeItem(atPath: filePath)
                    log(String(format: "已经删除了数据库 ->%@", filePath))
                }
            })
        }
        if !isMigration {
            semaphore.signal()
        }
    }
    
    /// 清空指定本地模型数据库
    public static func removeModel<T: DatabaseModel>(_ type: T.Type) {
        if !isMigration {
            semaphore.wait()
        }
        if let filePath = localPath(with: type) {
            try? FileManager.default.removeItem(atPath: filePath)
        }
        if !isMigration {
            semaphore.signal()
        }
    }
    
    /// 返回本地模型数据库路径
    public static func localPath<T: DatabaseModel>(with type: T.Type) -> String? {
        return commonLocalPath(type, isPath: true)
    }
    
    /// 返回本地模型数据库版本号
    public static func version<T: DatabaseModel>(with type: T.Type) -> String? {
        let modelName = localName(with: type)
        return version(modelName: modelName)
    }
    
}

private extension DatabaseManager {
    
    static func databaseCacheDirectory(_ modelClass: AnyClass?) -> String {
        if let type = modelClass as? DatabaseModel.Type,
           let customPath = type.databasePath?(), !customPath.isEmpty {
            return customPath
        }
        
        return FileManager.fw_pathCaches.fw_appendingPath(["FWFramework", "Database"])
    }
    
    static func getPrimaryKey(_ modelClass: AnyClass) -> String {
        if let type = modelClass as? DatabaseModel.Type,
           let primaryKey = type.tablePrimaryKey?(), !primaryKey.isEmpty {
            return primaryKey
        }
        
        return "pkid"
    }
    
    static func getPrimaryValue(_ model: DatabaseModel?) -> Int {
        guard let model = model else { return -1 }
        let primaryGetter = NSSelectorFromString(getPrimaryKey(type(of: model)))
        if model.responds(to: primaryGetter) {
            return ObjCBridge.invokeMethod(model, selector: primaryGetter) as? Int ?? -1
        }
        
        return -1
    }
    
    static func getTableName(_ modelClass: AnyClass) -> String {
        if let type = modelClass as? DatabaseModel.Type,
           let tableName = type.tableName?(), !tableName.isEmpty {
            return tableName
        }
        
        var tableName = NSStringFromClass(modelClass)
        if tableName.contains(".") {
            tableName = tableName.components(separatedBy: ".").last ?? ""
        }
        return tableName
    }
    
    static func getVendorPath(_ modelClass: AnyClass) -> String? {
        if let type = modelClass as? DatabaseModel.Type,
           let vendorPath = type.databaseVendorPath?(), !vendorPath.isEmpty {
            return vendorPath
        }
        
        return nil
    }
    
    static func autoHandleOldSqlite(_ modelClass: AnyClass) -> String {
        let cacheDirectory = databaseCacheDirectory(modelClass)
        if !FileManager.default.fileExists(atPath: cacheDirectory) {
            try? FileManager.default.createDirectory(atPath: cacheDirectory, withIntermediateDirectories: true)
        }
        
        if let vendorPath = getVendorPath(modelClass), !vendorPath.isEmpty {
            var version = ""
            if let type = modelClass as? DatabaseModel.Type {
                version = type.databaseVersion?() ?? ""
            }
            if version.isEmpty { version = DatabaseManager.version }
            
            let sqlitePath = cacheDirectory.fw_appendingPath(String(format: "%@_v%@.sqlite", NSStringFromClass(modelClass), version))
            if FileManager.default.fileExists(atPath: vendorPath),
               !FileManager.default.fileExists(atPath: sqlitePath) {
                try? FileManager.default.copyItem(atPath: vendorPath, toPath: sqlitePath)
            }
        }
        return cacheDirectory
    }
    
    @discardableResult
    static func executeSql(_ sql: String) -> Bool {
        let result = sqlite3_exec(database, sql, nil, nil, nil) == SQLITE_OK
        if !result {
            log(String(format: "执行失败->%@", sql))
        }
        return result
    }
    
    static func handleWhere(_ where: String?) -> String {
        return ""
    }
    
    static func openTable(_ modelClass: AnyClass) -> Bool {
        return false
    }
    
    static func createTable(_ modelClass: AnyClass) -> Bool {
        return false
    }
    
    static func startSqlQuery<T: DatabaseModel>(_ type: T.Type, sql: String) -> [T] {
        return []
    }
    
    static func commonQuery<T: DatabaseModel>(_ type: T.Type, where: String? = nil, order: String? = nil, limit: String? = nil) -> [T] {
        return []
    }
    
    static func commonInsert(_ model: DatabaseModel, isReplace: Bool) -> Bool {
        return false
    }
    
    static func updateModel(_ model: DatabaseModel, where: String?) -> Bool {
        return false
    }
    
    static func commonDeleteModel(_ modelClass: AnyClass, where condition: String?) -> Bool {
        guard localName(with: modelClass) != nil else { return false }
        
        var result = false
        if openTable(modelClass) {
            let tableName = getTableName(modelClass)
            var deleteSql = String(format: "DELETE FROM %@", tableName)
            if let condition = condition, !condition.isEmpty {
                deleteSql = deleteSql.appendingFormat(" WHERE %@", handleWhere(condition))
            }
            result = executeSql(deleteSql)
            close()
        }
        return result
    }
    
    static func close() {
        if database != nil {
            sqlite3_close(database)
            database = nil
        }
    }
    
    static func commonLocalPath(_ modelClass: AnyClass, isPath: Bool) -> String? {
        let className = NSStringFromClass(modelClass)
        let cacheDirectory = databaseCacheDirectory(modelClass)
        var filePath: String?
        if FileManager.default.fileExists(atPath: cacheDirectory),
           let fileNames = try? FileManager.default.contentsOfDirectory(atPath: cacheDirectory), !fileNames.isEmpty {
            for fileName in fileNames {
                if fileName.range(of: className.appending("_v")) != nil {
                    if isPath {
                        filePath = cacheDirectory.fw_appendingPath(fileName)
                    } else {
                        filePath = fileName
                    }
                    break
                }
            }
        }
        return filePath
    }
    
    static func localName(with modelClass: AnyClass) -> String? {
        return commonLocalPath(modelClass, isPath: false)
    }
    
    static func version(modelName: String?) -> String? {
        var modelVersion: String?
        if let modelName = modelName as? NSString {
            let endRange = modelName.range(of: ".", options: .backwards)
            let startRange = modelName.range(of: "v", options: .backwards)
            if endRange.location != NSNotFound, startRange.location != NSNotFound {
                modelVersion = modelName.substring(with: NSMakeRange(startRange.location + startRange.length, endRange.location - (startRange.location + startRange.length)))
            }
        }
        return modelVersion
    }
    
    static func isNumber(_ char: String) -> Bool {
        var value: Int = 0
        let scanner = Scanner(string: char)
        return scanner.scanInt(&value) && scanner.isAtEnd
    }
    
    static func log(_ msg: String) {
        #if DEBUG
        Logger.debug(group: Logger.fw_moduleName, "Database: [%@]", msg)
        #endif
    }
    
}

fileprivate enum DatabaseFieldType: Int {
    case string = 0
    case int
    case boolean
    case double
    case float
    case char
    case number
    case data
    case date
    case array
    case dictionary
    
    static func parseFieldType(attr: String) -> DatabaseFieldType {
        let subAttr = attr.components(separatedBy: ",").first ?? ""
        let firstSubAttr = subAttr.count > 1 ? String(subAttr.dropFirst()) : ""
        var fieldType: DatabaseFieldType = .string
        let type = firstSubAttr.first ?? Character(" ")
        switch type {
        case "B":
            fieldType = .boolean
        case "c", "C":
            fieldType = .char
        case "s", "S", "i", "I", "l", "L", "q", "Q":
            fieldType = .int
        case "f":
            fieldType = .float
        case "d", "D":
            fieldType = .double
        default:
            break
        }
        return fieldType
    }
    
    func fieldTypeString() -> String {
        switch self {
        case .int:
            return "INTERGER"
        case .boolean:
            return "INTERGER"
        case .double:
            return "DOUBLE"
        case .float:
            return "DOUBLE"
        case .char:
            return "NVARCHAR"
        case .number:
            return "DOUBLE"
        case .data:
            return "BLOB"
        case .date:
            return "DOUBLE"
        case .array:
            return "BLOB"
        case .dictionary:
            return "BLOB"
        default:
            return "TEXT"
        }
    }
}

fileprivate class DatabasePropertyInfo: NSObject {
    let type: DatabaseFieldType
    let name: String
    let getter: Selector
    let setter: Selector
    
    static func setter(propertyName: String) -> Selector {
        if propertyName.count > 1 {
            return NSSelectorFromString(String(format: "set%@%@:", String(propertyName.prefix(1).uppercased()), String(propertyName.dropFirst())))
        } else {
            return NSSelectorFromString(String(format: "set%@:", propertyName.uppercased()))
        }
    }
    
    init(type: DatabaseFieldType, propertyName: String, name: String) {
        self.name = name
        self.type = type
        self.setter = DatabasePropertyInfo.setter(propertyName: propertyName)
        self.getter = NSSelectorFromString(propertyName)
        super.init()
    }
}
