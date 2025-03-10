//
//  Database.swift
//  FWFramework
//
//  Created by wuyong on 2023/12/25.
//

import Foundation
import SQLite3
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

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
public class DatabaseManager: @unchecked Sendable {
    /// 全局数据库模型版本号，默认1.0
    ///
    /// 如果模型实现了databaseVersion且不为空，则会忽略全局版本号；
    /// 可设置为appVersion+appBuildVersion从而实现App升级时自动更新版本号
    public static var version: String {
        get { shared.version }
        set { shared.version = newValue }
    }

    /// 是否打印调试SQL语句，默认true
    public static var printSql: Bool {
        get { shared.printSql }
        set { shared.printSql = newValue }
    }

    private static let shared = DatabaseManager()
    private var version = "1.0"
    private var printSql = true
    private var database: OpaquePointer!
    private var semaphore = DispatchSemaphore(value: 1)
    private var checkUpdate = true
    private var isMigration = false
    private var modelFieldsCaches: [String: [String: DatabasePropertyInfo]] = [:]

    /// 保存模型到本地，主键存在时更新，不存在时新增
    @discardableResult
    public static func save(_ model: DatabaseModel) -> Bool {
        insert(model, isReplace: true)
    }

    /// 新增模型数组到本地(事务方式)，模型数组对象类型要一致
    @discardableResult
    public static func inserts(_ models: [DatabaseModel]) -> Bool {
        if !shared.isMigration {
            shared.semaphore.wait()
        }
        var result = true
        if models.count > 0, openTable(type(of: models[0])) {
            executeSql("BEGIN TRANSACTION")
            for model in models {
                result = commonInsert(model, isReplace: false)
                if !result { break }
            }
            executeSql(result ? "COMMIT" : "ROLLBACK")
            close()
        }
        if !shared.isMigration {
            shared.semaphore.signal()
        }
        return result
    }

    /// 新增模型到本地，自动更新主键
    @discardableResult
    public static func insert(_ model: DatabaseModel) -> Bool {
        insert(model, isReplace: false)
    }

    /// 获取模型类表总条数，支持查询条件
    public static func count<T: DatabaseModel>(_ type: T.Type, where condition: String? = nil) -> Int {
        let count = query(type, func: "count(*)", condition: condition) as? NSNumber
        return count?.intValue ?? 0
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

        if !shared.isMigration {
            shared.semaphore.wait()
        }
        var models: [T] = []
        if openTable(type) {
            models = commonQuery(type, where: condition, order: order, limit: limit) as? [T] ?? []
            close()
        }
        if !shared.isMigration {
            shared.semaphore.signal()
        }
        return models
    }

    /// 自定义sql查询
    public static func query<T: DatabaseModel>(_ type: T.Type, sql: String) -> [T] {
        guard !sql.isEmpty, localName(with: type) != nil else { return [] }

        if !shared.isMigration {
            shared.semaphore.wait()
        }
        var models: [T] = []
        if openTable(type) {
            models = startSqlQuery(type, sql: sql) as? [T] ?? []
            close()
        }
        if !shared.isMigration {
            shared.semaphore.signal()
        }
        return models
    }

    /// 根据主键查询本地模型对象
    public static func query<T: DatabaseModel>(_ type: T.Type, key: Int) -> T? {
        let condition = String(format: "%@ = %ld", getPrimaryKey(type), key)
        return query(type, where: condition).first
    }

    /// 利用sqlite 函数进行查询，condition为其他查询条件例如：(where age > 20 order by age desc ....)
    public static func query<T: DatabaseModel>(_ type: T.Type, func function: String, condition: String? = nil) -> Any? {
        guard localName(with: type) != nil,
              !function.isEmpty else { return nil }

        if !shared.isMigration {
            shared.semaphore.wait()
        }
        var resultArray: [[Any]] = []
        if openTable(type) {
            let tableName = getTableName(type)
            let selectSql = String(format: "SELECT %@ FROM %@ %@", function, tableName, handleWhere(condition))
            if printSql {
                log(String(format: "执行查询 -> %@", selectSql))
            }

            var ppStmt: OpaquePointer?
            if sqlite3_prepare_v2(shared.database, selectSql, -1, &ppStmt, nil) == SQLITE_OK {
                let columnCount = sqlite3_column_count(ppStmt)
                while sqlite3_step(ppStmt) == SQLITE_ROW {
                    var rowResultArray: [Any] = []
                    for column in 0..<columnCount {
                        let columnType = sqlite3_column_type(ppStmt, column)
                        switch columnType {
                        case SQLITE_INTEGER:
                            let value = sqlite3_column_int64(ppStmt, column)
                            rowResultArray.append(NSNumber(value: value))
                        case SQLITE_FLOAT:
                            let value = sqlite3_column_double(ppStmt, column)
                            rowResultArray.append(NSNumber(value: value))
                        case SQLITE_TEXT:
                            let text = sqlite3_column_text(ppStmt, column)
                            if let text {
                                let value = String(cString: UnsafePointer(text))
                                rowResultArray.append(value)
                            }
                        case SQLITE_BLOB:
                            let length = sqlite3_column_bytes(ppStmt, column)
                            let blob = sqlite3_column_blob(ppStmt, column)
                            if blob != nil {
                                let value = NSData(bytes: blob, length: Int(length)) as Data
                                rowResultArray.append(value)
                            }
                        default:
                            break
                        }
                    }
                    if rowResultArray.count > 0 {
                        resultArray.append(rowResultArray)
                    }
                }
                sqlite3_finalize(ppStmt)
            } else {
                log("Sorry 查询失败, 建议检查sqlite 函数书写格式是否正确！", error: true)
            }
            close()

            if resultArray.count > 0 {
                var handleResultDict: [String: [Any]] = [:]
                for rowResultArray in resultArray {
                    for (idx, columnValue) in rowResultArray.enumerated() {
                        let columnArrayKey = "\(idx)"
                        var columnValueArray = handleResultDict[columnArrayKey] ?? []
                        columnValueArray.append(columnValue)
                        handleResultDict[columnArrayKey] = columnValueArray
                    }
                }

                let allKeys = handleResultDict.keys.sorted() as NSArray
                let handleColumnArrayKey = allKeys.sortedArray { key1, key2 in
                    let result = (key1 as! NSString).compare(key2 as! String)
                    return result == .orderedDescending ? .orderedAscending : result
                } as? [String] ?? []
                resultArray.removeAll()
                for key in handleColumnArrayKey {
                    if let value = handleResultDict[key] {
                        resultArray.append(value)
                    }
                }
            }
        }
        if !shared.isMigration {
            shared.semaphore.signal()
        }

        if resultArray.count == 1 {
            let element = resultArray[0]
            return element.count > 1 ? element : element.first
        } else if resultArray.count > 1 {
            return resultArray
        }
        return nil
    }

    /// 更新本地模型对象，主键必须存在
    @discardableResult
    public static func update(_ model: DatabaseModel) -> Bool {
        let modelClass = type(of: model)
        guard localName(with: modelClass) != nil else { return false }

        let primaryKey = getPrimaryKey(modelClass)
        let primaryValue = getPrimaryValue(model)
        if primaryValue <= 0 { return false }

        if !shared.isMigration {
            shared.semaphore.wait()
        }
        let condition = String(format: "%@ = %ld", primaryKey, primaryValue)
        let result = updateModel(model, where: condition)
        if !shared.isMigration {
            shared.semaphore.signal()
        }
        return result
    }

    /// 更新数据表字段，where为空则更新所有
    @discardableResult
    public static func update<T: DatabaseModel>(_ type: T.Type, value: T, where condition: String? = nil) -> Bool {
        guard localName(with: type) != nil else { return false }

        if !shared.isMigration {
            shared.semaphore.wait()
        }
        let result = updateModel(value, where: condition)
        if !shared.isMigration {
            shared.semaphore.signal()
        }
        return result
    }

    /// 更新数据表字段，where为空则更新所有
    @discardableResult
    public static func update<T: DatabaseModel>(_ type: T.Type, value: String, where condition: String? = nil) -> Bool {
        guard localName(with: type) != nil,
              !value.isEmpty else { return false }

        if !shared.isMigration {
            shared.semaphore.wait()
        }
        var result = false
        if openTable(type) {
            let tableName = getTableName(type)
            var updateSql = String(format: "UPDATE %@ SET %@", tableName, value)
            if let condition, !condition.isEmpty {
                updateSql = updateSql.appendingFormat(" WHERE %@", handleWhere(condition))
            }
            result = executeSql(updateSql)
            close()
        }
        if !shared.isMigration {
            shared.semaphore.signal()
        }
        return result
    }

    /// 清空本地模型对象
    @discardableResult
    public static func clear<T: DatabaseModel>(_ type: T.Type) -> Bool {
        delete(type, where: nil)
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
        if !shared.isMigration {
            shared.semaphore.wait()
        }
        let result = commonDeleteModel(type, where: condition)
        if !shared.isMigration {
            shared.semaphore.signal()
        }
        return result
    }

    /// 清空所有本地模型数据库
    public static func removeAllModels() {
        if !shared.isMigration {
            shared.semaphore.wait()
        }
        let cachePath = databaseCacheDirectory(nil)
        if FileManager.default.fileExists(atPath: cachePath) {
            let fileArray = try? FileManager.default.contentsOfDirectory(atPath: cachePath)
            fileArray?.forEach { file in
                if file != ".DS_Store" {
                    let filePath = cachePath.fw.appendingPath(file)
                    try? FileManager.default.removeItem(atPath: filePath)
                    log(String(format: "已经删除了数据库 -> %@", filePath))
                }
            }
        }
        removeModelFieldsCache(nil)
        if !shared.isMigration {
            shared.semaphore.signal()
        }
    }

    /// 清空指定本地模型数据库
    public static func removeModel<T: DatabaseModel>(_ type: T.Type) {
        if !shared.isMigration {
            shared.semaphore.wait()
        }
        if let filePath = localPath(with: type) {
            try? FileManager.default.removeItem(atPath: filePath)
            log(String(format: "已经删除了数据库 -> %@", filePath))
        }
        removeModelFieldsCache(type)
        if !shared.isMigration {
            shared.semaphore.signal()
        }
    }

    /// 返回本地模型数据库路径
    public static func localPath<T: DatabaseModel>(with type: T.Type) -> String? {
        commonLocalPath(type, isPath: true)
    }

    /// 返回本地模型数据库版本号
    public static func version<T: DatabaseModel>(with type: T.Type) -> String? {
        let modelName = localName(with: type)
        return version(modelName: modelName)
    }
}

extension DatabaseManager {
    fileprivate static func databaseCacheDirectory(_ modelClass: AnyClass?) -> String {
        if let type = modelClass as? DatabaseModel.Type,
           let customPath = type.databasePath?(), !customPath.isEmpty {
            return customPath
        }

        return FileManager.fw.pathCaches.fw.appendingPath(["FWFramework", "Database"])
    }

    fileprivate static func removeModelFieldsCache(_ modelClass: AnyClass?) {
        guard let modelClass else {
            shared.modelFieldsCaches.removeAll()
            return
        }

        let cachePrefix = NSStringFromClass(modelClass)
        let cacheKeys = shared.modelFieldsCaches.keys
        for cacheKey in cacheKeys {
            if cacheKey.hasPrefix(cachePrefix) {
                shared.modelFieldsCaches.removeValue(forKey: cacheKey)
            }
        }
    }

    fileprivate static func parseModelFields(_ modelClass: AnyClass, hasPrimary: Bool) -> [String: DatabasePropertyInfo] {
        let version = getModelVersion(modelClass)
        let cacheKey = NSStringFromClass(modelClass) + "_\(version)_\(hasPrimary ? 1 : 0)"
        if let modelFields = shared.modelFieldsCaches[cacheKey] {
            return modelFields
        }

        let modelFields = parseSubModelFields(modelClass, propertyName: nil, hasPrimary: hasPrimary, completion: nil)
        shared.modelFieldsCaches[cacheKey] = modelFields
        return modelFields
    }

    @discardableResult
    fileprivate static func parseSubModelFields(_ modelClass: AnyClass, propertyName mainPropertyName: String?, hasPrimary: Bool, completion: ((String, DatabasePropertyInfo) -> Void)?) -> [String: DatabasePropertyInfo] {
        let needDictionarySave = mainPropertyName == nil && completion == nil
        var fields: [String: DatabasePropertyInfo]? = needDictionarySave ? [:] : nil

        if let superClass = class_getSuperclass(modelClass), superClass != NSObject.self {
            let superFields = parseSubModelFields(superClass, propertyName: mainPropertyName, hasPrimary: hasPrimary, completion: completion)
            if needDictionarySave {
                fields?.merge(superFields, uniquingKeysWith: { $1 })
            }
        }

        var ignoreProperties: [String] = []
        var allProperties: [String] = []
        if let type = modelClass as? DatabaseModel.Type {
            ignoreProperties = type.tablePropertyBlacklist?() ?? []
            allProperties = type.tablePropertyWhitelist?() ?? []
        }

        var propertyCount: UInt32 = 0
        let propertyList = class_copyPropertyList(modelClass, &propertyCount)
        for i in 0..<Int(propertyCount) {
            guard let property = propertyList?[i],
                  let propertyName = String(utf8String: property_getName(property)) else { continue }

            if (ignoreProperties.count > 0 && ignoreProperties.contains(propertyName)) ||
                (allProperties.count > 0 && !allProperties.contains(propertyName)) ||
                (!hasPrimary && propertyName == getPrimaryKey(modelClass)) {
                continue
            }

            var attrString = ""
            if let attributes = property_getAttributes(property) {
                attrString = String(utf8String: attributes) ?? ""
            }
            let propertyAttrs = attrString.components(separatedBy: "\"")
            var name = propertyName

            let propertySetter = DatabasePropertyInfo.setter(propertyName: propertyName)
            if !modelClass.instancesRespond(to: propertySetter) {
                continue
            }
            if !needDictionarySave {
                name = String(format: "%@$%@", mainPropertyName ?? "", propertyName)
            }

            var propertyInfo: DatabasePropertyInfo?
            if propertyAttrs.count == 1 {
                let fieldType = DatabaseFieldType.parseFieldType(attr: propertyAttrs[0])
                propertyInfo = DatabasePropertyInfo(type: fieldType, propertyName: propertyName, name: name)
            } else {
                let classType: AnyClass? = NSClassFromString(propertyAttrs[1])
                if classType == NSNumber.self {
                    propertyInfo = DatabasePropertyInfo(type: .number, propertyName: propertyName, name: name)
                } else if classType == NSString.self {
                    propertyInfo = DatabasePropertyInfo(type: .string, propertyName: propertyName, name: name)
                } else if classType == NSData.self {
                    propertyInfo = DatabasePropertyInfo(type: .data, propertyName: propertyName, name: name)
                } else if classType == NSMutableArray.self {
                    propertyInfo = DatabasePropertyInfo(type: .mutableArray, propertyName: propertyName, name: name)
                } else if classType == NSMutableDictionary.self {
                    propertyInfo = DatabasePropertyInfo(type: .mutableDictionary, propertyName: propertyName, name: name)
                } else if classType == NSArray.self {
                    propertyInfo = DatabasePropertyInfo(type: .array, propertyName: propertyName, name: name)
                } else if classType == NSDictionary.self {
                    propertyInfo = DatabasePropertyInfo(type: .dictionary, propertyName: propertyName, name: name)
                } else if classType == NSDate.self {
                    propertyInfo = DatabasePropertyInfo(type: .date, propertyName: propertyName, name: name)
                } else if classType is AnyArchivable.Type {
                    propertyInfo = DatabasePropertyInfo(type: .archivable, propertyName: propertyName, name: name)
                } else if classType == NSSet.self ||
                    classType == NSValue.self ||
                    classType == NSError.self ||
                    classType == NSURL.self ||
                    classType == Stream.self ||
                    classType == Scanner.self ||
                    classType == NSException.self ||
                    classType == Bundle.self {
                    log("检查模型类异常数据类型", error: true)
                } else if let classType {
                    if needDictionarySave {
                        parseSubModelFields(classType, propertyName: name, hasPrimary: hasPrimary) { key, propertyObject in
                            fields?[key] = propertyObject
                        }
                    } else {
                        parseSubModelFields(classType, propertyName: name, hasPrimary: hasPrimary, completion: completion)
                    }
                }
            }

            if needDictionarySave, let propertyInfo {
                fields?[name] = propertyInfo
            }
            if let propertyInfo, completion != nil {
                completion?(name, propertyInfo)
            }
        }
        free(propertyList)
        return fields ?? [:]
    }

    fileprivate static func isSubModel(_ modelClass: AnyClass) -> Bool {
        if modelClass is AnyArchivable.Type { return false }
        return
            modelClass != NSString.self &&
            modelClass != NSNumber.self &&
            modelClass != NSArray.self &&
            modelClass != NSSet.self &&
            modelClass != NSData.self &&
            modelClass != NSDate.self &&
            modelClass != NSDictionary.self &&
            modelClass != NSValue.self &&
            modelClass != NSError.self &&
            modelClass != NSURL.self &&
            modelClass != Stream.self &&
            modelClass != NSURLRequest.self &&
            modelClass != URLResponse.self &&
            modelClass != Bundle.self &&
            modelClass != Scanner.self &&
            modelClass != NSException.self
    }

    fileprivate static func getModelFieldNames(_ modelClass: AnyClass) -> [String] {
        var fieldNames: [String] = []
        if shared.database != nil {
            let sql = String(format: "pragma table_info ('%@')", getTableName(modelClass))
            var ppStmt: OpaquePointer?
            if sqlite3_prepare_v2(shared.database, sql, -1, &ppStmt, nil) == SQLITE_OK {
                while sqlite3_step(ppStmt) == SQLITE_ROW {
                    let cols = sqlite3_column_count(ppStmt)
                    if cols > 1 {
                        if let text = sqlite3_column_text(ppStmt, 1) {
                            fieldNames.append(String(cString: UnsafePointer(text)))
                        }
                    }
                }
                sqlite3_finalize(ppStmt)
            }
        }
        return fieldNames
    }

    fileprivate static func updateTableField(_ modelClass: AnyClass, newVersion: String, localModelName: String) {
        let tableName = getTableName(modelClass)
        let cacheDirectory = databaseCacheDirectory(modelClass)
        let databaseCachePath = cacheDirectory.fw.appendingPath(localModelName)
        if sqlite3_open(databaseCachePath, &shared.database) == SQLITE_OK {
            let oldFieldNames = getModelFieldNames(modelClass)
            let newModelInfo = parseModelFields(modelClass, hasPrimary: false)
            var deleteFieldNames = ""
            var addFieldNames = ""
            for obj in oldFieldNames {
                if newModelInfo[obj] == nil {
                    deleteFieldNames.append(obj + ",")
                }
            }
            for (key, obj) in newModelInfo {
                if !oldFieldNames.contains(key) {
                    addFieldNames.append(String(format: "%@ %@,", key, obj.type.fieldTypeString()))
                }
            }

            if addFieldNames.count > 0 {
                let addFieldArray = addFieldNames.components(separatedBy: ",")
                for addField in addFieldArray {
                    if addField.count > 0 {
                        let addFieldSql = String(format: "ALTER TABLE %@ ADD %@", tableName, addField)
                        executeSql(addFieldSql)
                    }
                }
            }

            if deleteFieldNames.count > 0 {
                deleteFieldNames = String(deleteFieldNames.dropLast())
                let defaultKey = getPrimaryKey(modelClass)
                if defaultKey != deleteFieldNames {
                    shared.checkUpdate = false
                    var oldModelDatas: [DatabaseModel] = []
                    if let type = modelClass as? DatabaseModel.Type {
                        oldModelDatas = commonQuery(type) as? [DatabaseModel] ?? []
                    }
                    close()
                    if let type = modelClass as? DatabaseModel.Type,
                       let filePath = localPath(with: type) {
                        try? FileManager.default.removeItem(atPath: filePath)
                    }

                    if openTable(modelClass) {
                        executeSql("BEGIN TRANSACTION")
                        for oldModelData in oldModelDatas {
                            commonInsert(oldModelData, isReplace: false)
                        }
                        executeSql("COMMIT")
                        close()
                        return
                    }
                }
            }

            close()
            let newDatabasePath = cacheDirectory.fw.appendingPath(String(format: "%@_v%@.sqlite", NSStringFromClass(modelClass), newVersion))
            try? FileManager.default.moveItem(atPath: databaseCachePath, toPath: newDatabasePath)
        }
    }

    fileprivate static func autoNewSubmodel(_ modelClass: AnyClass) -> NSObject? {
        guard let objectClass = modelClass as? NSObject.Type else { return nil }

        let model = objectClass.init()
        var propertyCount: UInt32 = 0
        let propertyList = class_copyPropertyList(modelClass, &propertyCount)
        for i in 0..<Int(propertyCount) {
            guard let property = propertyList?[i],
                  let propertyName = String(utf8String: property_getName(property)) else { continue }

            var attrString = ""
            if let attributes = property_getAttributes(property) {
                attrString = String(utf8String: attributes) ?? ""
            }
            let propertyAttrs = attrString.components(separatedBy: "\"")
            if propertyAttrs.count > 1 {
                let classType: AnyClass? = NSClassFromString(propertyAttrs[1])
                if let classType, isSubModel(classType) {
                    model.setValue(autoNewSubmodel(classType), forKey: propertyName)
                }
            }
        }
        free(propertyList)
        return model
    }

    fileprivate static func getModelVersion(_ modelClass: AnyClass) -> String {
        var version = ""
        if let type = modelClass as? DatabaseModel.Type {
            version = type.databaseVersion?() ?? ""
        }
        return !version.isEmpty ? version : DatabaseManager.version
    }

    fileprivate static func getPrimaryKey(_ modelClass: AnyClass) -> String {
        if let type = modelClass as? DatabaseModel.Type,
           let primaryKey = type.tablePrimaryKey?(), !primaryKey.isEmpty {
            return primaryKey
        }

        return "pkid"
    }

    fileprivate static func getPrimaryValue(_ model: DatabaseModel) -> Int {
        let primaryKey = getPrimaryKey(type(of: model))
        let primaryGetter = NSSelectorFromString(primaryKey)
        if let object = model as? NSObject, object.responds(to: primaryGetter) {
            return object.value(forKey: primaryKey) as? Int ?? -1
        }

        return -1
    }

    fileprivate static func getTableName(_ modelClass: AnyClass) -> String {
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

    fileprivate static func getVendorPath(_ modelClass: AnyClass) -> String? {
        if let type = modelClass as? DatabaseModel.Type,
           let vendorPath = type.databaseVendorPath?(), !vendorPath.isEmpty {
            return vendorPath
        }

        return nil
    }

    fileprivate static func autoHandleOldSqlite(_ modelClass: AnyClass) -> String {
        let cacheDirectory = databaseCacheDirectory(modelClass)
        if !FileManager.default.fileExists(atPath: cacheDirectory) {
            try? FileManager.default.createDirectory(atPath: cacheDirectory, withIntermediateDirectories: true)
        }

        if let vendorPath = getVendorPath(modelClass), !vendorPath.isEmpty {
            let version = getModelVersion(modelClass)
            let sqlitePath = cacheDirectory.fw.appendingPath(String(format: "%@_v%@.sqlite", NSStringFromClass(modelClass), version))
            if FileManager.default.fileExists(atPath: vendorPath),
               !FileManager.default.fileExists(atPath: sqlitePath) {
                try? FileManager.default.copyItem(atPath: vendorPath, toPath: sqlitePath)
            }
        }
        return cacheDirectory
    }

    @discardableResult
    fileprivate static func executeSql(_ sql: String) -> Bool {
        let result = sqlite3_exec(shared.database, sql, nil, nil, nil) == SQLITE_OK
        if !result {
            log(String(format: "执行失败 -> %@", sql), error: true)
        }
        return result
    }

    fileprivate static func handleWhere(_ condition: String?) -> String {
        guard let condition, !condition.isEmpty else { return "" }

        var whereString = ""
        let subWheres = condition.components(separatedBy: " ")
        for subWhere in subWheres {
            if subWhere.range(of: ".") != nil,
               !subWhere.hasPrefix("'"),
               !subWhere.hasSuffix("'") {
                var hasNumber = false
                let subDots = subWhere.components(separatedBy: ".")
                for subDot in subDots {
                    if subDot.count > 0 {
                        let firstChar = String(subDot.prefix(1))
                        if isNumber(firstChar) {
                            hasNumber = true
                            break
                        }
                    }
                }

                if !hasNumber {
                    whereString.append(String(format: "%@ ", subWhere.replacingOccurrences(of: ".", with: "$")))
                } else {
                    whereString.append(String(format: "%@ ", subWhere))
                }
            } else {
                whereString.append(String(format: "%@ ", subWhere))
            }
        }
        if whereString.hasSuffix(" ") {
            whereString = String(whereString.dropLast())
        }
        return whereString
    }

    fileprivate static func openTable(_ modelClass: AnyClass) -> Bool {
        let cacheDirectory = autoHandleOldSqlite(modelClass)
        let version = getModelVersion(modelClass)
        if shared.checkUpdate {
            let localModelName = localName(with: modelClass)
            if let localModelName,
               localModelName.range(of: version) == nil {
                updateTableField(modelClass, newVersion: version, localModelName: localModelName)

                let oldVersion = self.version(modelName: localModelName)
                if let oldVersion, !oldVersion.isEmpty,
                   let type = modelClass as? DatabaseModel.Type {
                    shared.isMigration = true
                    type.databaseMigration?(oldVersion)
                    shared.isMigration = false
                }
            }
        }
        shared.checkUpdate = true
        let databaseCachePath = cacheDirectory.fw.appendingPath(String(format: "%@_v%@.sqlite", NSStringFromClass(modelClass), version))
        if sqlite3_open(databaseCachePath, &shared.database) == SQLITE_OK {
            return createTable(modelClass)
        }
        return false
    }

    fileprivate static func createTable(_ modelClass: AnyClass) -> Bool {
        let tableName = getTableName(modelClass)
        let fieldDictionary = parseModelFields(modelClass, hasPrimary: false)
        guard fieldDictionary.count > 0 else { return false }

        let primaryKey = getPrimaryKey(modelClass)
        var createSql = String(format: "CREATE TABLE IF NOT EXISTS %@ (%@ INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,", tableName, primaryKey)
        for (field, properyInfo) in fieldDictionary {
            createSql.append(String(format: "%@ %@ DEFAULT ", field, properyInfo.type.fieldTypeString()))
            switch properyInfo.type {
            case .data, .string, .char, .dictionary, .array, .mutableDictionary, .mutableArray:
                createSql.append("NULL,")
            case .archivable:
                createSql.append("NULL,")
            case .boolean, .int:
                createSql.append("0,")
            case .float, .double, .number, .date:
                createSql.append("0.0,")
            }
        }
        createSql = String(createSql.dropLast()).appending(")")
        return executeSql(createSql)
    }

    fileprivate static func insert(_ model: DatabaseModel, isReplace: Bool) -> Bool {
        if !shared.isMigration {
            shared.semaphore.wait()
        }
        var result = false
        if openTable(type(of: model)) {
            result = commonInsert(model, isReplace: isReplace)
            let value = result ? getPrimaryValue(model) : -1
            if result && value < 1 {
                let rowId = Int(sqlite3_last_insert_rowid(shared.database))
                let primaryKey = getPrimaryKey(type(of: model))
                let primarySetter = DatabasePropertyInfo.setter(propertyName: primaryKey)
                if let object = model as? NSObject, object.responds(to: primarySetter) {
                    object.setValue(rowId, forKey: primaryKey)
                }
            }
            close()
        }
        if !shared.isMigration {
            shared.semaphore.signal()
        }
        return result
    }

    fileprivate static func startSqlQuery(_ modelClass: AnyClass, sql: String) -> [Any] {
        let fieldDictionary = parseModelFields(modelClass, hasPrimary: false)
        var models: [Any] = []
        if printSql {
            log(String(format: "执行查询 -> %@", sql))
        }

        var ppStmt: OpaquePointer?
        if sqlite3_prepare_v2(shared.database, sql, -1, &ppStmt, nil) == SQLITE_OK {
            let columnCount = sqlite3_column_count(ppStmt)
            while sqlite3_step(ppStmt) == SQLITE_ROW {
                guard let model = autoNewSubmodel(modelClass) else { break }
                let primaryKey = getPrimaryKey(modelClass)
                let primarySetter = DatabasePropertyInfo.setter(propertyName: primaryKey)
                if model.responds(to: primarySetter) {
                    let value = sqlite3_column_int64(ppStmt, 0)
                    model.setValue(value, forKey: primaryKey)
                }
                for column in 1..<columnCount {
                    let fieldName = String(cString: sqlite3_column_name(ppStmt, column), encoding: .utf8)
                    guard var fieldName,
                          let propertyInfo = fieldDictionary[fieldName] else { continue }

                    var currentModel: NSObject? = model
                    if fieldName.range(of: "$") != nil {
                        let handleFieldName = fieldName.replacingOccurrences(of: "$", with: ".") as NSString
                        let backwardsRange = handleFieldName.range(of: ".", options: .backwards)
                        let keyPath = handleFieldName.substring(with: NSMakeRange(0, backwardsRange.location))
                        currentModel = model.value(forKeyPath: keyPath) as? NSObject
                        fieldName = handleFieldName.substring(from: backwardsRange.location + backwardsRange.length)
                    }
                    guard let currentModel else { continue }

                    switch propertyInfo.type {
                    case .mutableArray, .mutableDictionary, .dictionary, .array:
                        let length = sqlite3_column_bytes(ppStmt, column)
                        let blob = sqlite3_column_blob(ppStmt, column)
                        if blob != nil {
                            let value = NSData(bytes: blob, length: Int(length)) as Data
                            var fieldValue: Any? = value.fw.unarchivedObject()
                            if fieldValue != nil {
                                switch propertyInfo.type {
                                case .mutableArray:
                                    if let valueArray = fieldValue as? NSArray {
                                        fieldValue = NSMutableArray(array: valueArray)
                                    }
                                case .mutableDictionary:
                                    if let valueDict = fieldValue as? NSDictionary {
                                        fieldValue = NSMutableDictionary(dictionary: valueDict)
                                    }
                                default:
                                    break
                                }
                                currentModel.setValue(fieldValue, forKey: fieldName)
                            } else if !ArchiveCoder.isArchivableData(value) {
                                log("query 查询异常 Array/Dictionary 元素 \(fieldName) 没实现NSCoding协议解归档失败", error: true)
                            }
                        }
                    case .archivable:
                        let length = sqlite3_column_bytes(ppStmt, column)
                        let blob = sqlite3_column_blob(ppStmt, column)
                        if blob != nil {
                            let value = NSData(bytes: blob, length: Int(length)) as Data
                            let fieldValue: Any? = value.fw.unarchivedObject()
                            if let fieldValue {
                                currentModel.setValue(fieldValue, forKey: fieldName)
                            }
                        }
                    case .date:
                        let value = sqlite3_column_double(ppStmt, column)
                        if value > 0 {
                            let fieldValue = Date(timeIntervalSince1970: value)
                            currentModel.setValue(fieldValue, forKey: fieldName)
                        }
                    case .data:
                        let length = sqlite3_column_bytes(ppStmt, column)
                        let blob = sqlite3_column_blob(ppStmt, column)
                        if blob != nil {
                            let fieldValue = NSData(bytes: blob, length: Int(length)) as Data
                            currentModel.setValue(fieldValue, forKey: fieldName)
                        }
                    case .string:
                        let text = sqlite3_column_text(ppStmt, column)
                        if let text {
                            currentModel.setValue(String(cString: UnsafePointer(text)), forKey: fieldName)
                        }
                    case .number:
                        let value = sqlite3_column_double(ppStmt, column)
                        currentModel.setValue(NSNumber(value: value), forKey: fieldName)
                    case .int:
                        let value = sqlite3_column_int64(ppStmt, column)
                        currentModel.setValue(value, forKey: propertyInfo.propertyName)
                    case .float, .double:
                        let value = sqlite3_column_double(ppStmt, column)
                        currentModel.setValue(value, forKey: propertyInfo.propertyName)
                    case .char, .boolean:
                        let value = sqlite3_column_int(ppStmt, column)
                        currentModel.setValue(value, forKey: propertyInfo.propertyName)
                    }
                }
                models.append(model)
            }
            sqlite3_finalize(ppStmt)
        } else {
            log("Sorry查询语句异常,建议检查查询条件Sql语句语法是否正确", error: true)
        }
        return models
    }

    fileprivate static func commonQuery(_ modelClass: AnyClass, where condition: String? = nil, order: String? = nil, limit: String? = nil) -> [Any] {
        let tableName = getTableName(modelClass)
        var selectSql = String(format: "SELECT * FROM %@", tableName)
        if let condition, !condition.isEmpty {
            selectSql = selectSql.appendingFormat(" WHERE %@", condition)
        }
        if let order, !order.isEmpty {
            selectSql = selectSql.appendingFormat(" ORDER BY %@", order.replacingOccurrences(of: ".", with: "$"))
        }
        if let limit, !limit.isEmpty {
            selectSql = selectSql.appendingFormat(" LIMIT %@", limit.replacingOccurrences(of: ".", with: "$"))
        }
        return startSqlQuery(modelClass, sql: selectSql)
    }

    @discardableResult
    fileprivate static func commonInsert(_ model: DatabaseModel, isReplace: Bool) -> Bool {
        guard let object = model as? NSObject else { return false }

        var ppStmt: OpaquePointer?
        let primaryValue = getPrimaryValue(model)
        let modelClass = type(of: model)
        let fieldDictionary = parseModelFields(modelClass, hasPrimary: primaryValue > 0)
        let tableName = getTableName(modelClass)
        var insertSql = String(format: "%@ INTO %@ (", isReplace ? "REPLACE" : "INSERT", tableName)
        let fieldArray = fieldDictionary.keys
        var valueArray: [Any] = []
        var insertFieldArray: [String] = []
        for field in fieldArray {
            let propertyInfo = fieldDictionary[field]!
            insertFieldArray.append(field)
            insertSql.append(String(format: "%@,", field))
            var value: Any?
            if field.range(of: "$") == nil {
                value = object.value(forKey: field)
            } else {
                value = object.value(forKeyPath: field.replacingOccurrences(of: "$", with: "."))
                if value == nil {
                    switch propertyInfo.type {
                    case .mutableDictionary:
                        value = NSMutableDictionary()
                    case .mutableArray:
                        value = NSMutableArray()
                    case .dictionary:
                        value = NSDictionary()
                    case .array:
                        value = NSArray()
                    case .archivable:
                        value = nil
                    case .int, .float, .double, .number, .char:
                        value = NSNumber(value: 0)
                    case .data:
                        value = Data()
                    case .date:
                        value = Date()
                    case .string:
                        value = ""
                    case .boolean:
                        value = NSNumber(value: false)
                    }
                }
            }
            if let value {
                valueArray.append(value)
            } else {
                switch propertyInfo.type {
                case .mutableArray:
                    let data = Data.fw.archivedData(NSMutableArray())
                    valueArray.append(data ?? Data())
                case .mutableDictionary:
                    let data = Data.fw.archivedData(NSMutableDictionary())
                    valueArray.append(data ?? Data())
                case .array:
                    let data = Data.fw.archivedData(NSArray())
                    valueArray.append(data ?? Data())
                case .dictionary:
                    let data = Data.fw.archivedData(NSDictionary())
                    valueArray.append(data ?? Data())
                case .archivable:
                    valueArray.append(Data())
                case .data:
                    valueArray.append(Data())
                case .string:
                    valueArray.append("")
                case .date, .number:
                    valueArray.append(NSNumber(value: 0))
                case .int:
                    let value = object.value(forKey: propertyInfo.propertyName) as? Int64 ?? 0
                    valueArray.append(NSNumber(value: value))
                case .boolean:
                    let value = object.value(forKey: propertyInfo.propertyName) as? Bool ?? false
                    valueArray.append(NSNumber(value: value))
                case .char:
                    let value = object.value(forKey: propertyInfo.propertyName) as? Int ?? 0
                    valueArray.append(NSNumber(value: value))
                case .double:
                    let value = object.value(forKey: propertyInfo.propertyName) as? Double ?? 0
                    valueArray.append(NSNumber(value: value))
                case .float:
                    let value = object.value(forKey: propertyInfo.propertyName) as? Float ?? 0
                    valueArray.append(NSNumber(value: value))
                }
            }
        }

        insertSql = String(insertSql.dropLast()).appending(") VALUES (")
        for _ in fieldArray {
            insertSql.append("?,")
        }
        insertSql = String(insertSql.dropLast()).appending(")")
        if printSql {
            log(String(format: "执行写入 -> %@", insertSql))
        }

        if sqlite3_prepare_v2(shared.database, insertSql, -1, &ppStmt, nil) == SQLITE_OK {
            for (idx, field) in fieldArray.enumerated() {
                let propertyInfo = fieldDictionary[field]!
                let value = valueArray[idx]
                let index = Int32((insertFieldArray.firstIndex(of: field) ?? 0) + 1)
                switch propertyInfo.type {
                case .mutableDictionary, .mutableArray, .dictionary, .array:
                    var data: NSData?
                    if value is NSArray || value is NSDictionary {
                        data = Data.fw.archivedData(value) as? NSData
                    } else {
                        data = value as? NSData
                    }
                    let safeData = data ?? NSData()
                    sqlite3_bind_blob(ppStmt, index, safeData.bytes, Int32(safeData.length), nil)
                    if data == nil, !ArchiveCoder.isArchivableObject(value) {
                        log("insert 异常 Array/Dictionary类型元素 \(propertyInfo.propertyName) 未实现NSCoding协议归档失败", error: true)
                    }
                case .archivable:
                    var data: NSData?
                    if value is AnyArchivable {
                        data = Data.fw.archivedData(value) as? NSData
                    } else {
                        data = value as? NSData
                    }
                    let safeData = data ?? NSData()
                    sqlite3_bind_blob(ppStmt, index, safeData.bytes, Int32(safeData.length), nil)
                case .data:
                    let data = value as? NSData ?? NSData()
                    sqlite3_bind_blob(ppStmt, index, data.bytes, Int32(data.length), nil)
                case .string:
                    let string = String.fw.safeString(value)
                    sqlite3_bind_text(ppStmt, index, (string as NSString).utf8String, -1, nil)
                case .number, .double, .float:
                    sqlite3_bind_double(ppStmt, index, (value as? NSNumber)?.doubleValue ?? 0)
                case .int:
                    sqlite3_bind_int64(ppStmt, index, (value as? NSNumber)?.int64Value ?? 0)
                case .boolean, .char:
                    sqlite3_bind_int(ppStmt, index, (value as? NSNumber)?.int32Value ?? 0)
                case .date:
                    var timeInterval = (value as? NSNumber)?.doubleValue ?? 0
                    if let date = value as? Date {
                        timeInterval = date.timeIntervalSince1970
                    }
                    sqlite3_bind_double(ppStmt, index, timeInterval)
                }
            }
            let result = sqlite3_step(ppStmt) == SQLITE_DONE
            sqlite3_finalize(ppStmt)
            return result
        } else {
            log("Sorry存储数据失败,建议检查模型类属性类型是否符合规范", error: true)
            return false
        }
    }

    fileprivate static func updateModel(_ model: DatabaseModel, where condition: String?) -> Bool {
        let modelClass = type(of: model)
        if !openTable(modelClass) { return false }

        let fieldDictionary = parseModelFields(modelClass, hasPrimary: false)
        let tableName = getTableName(modelClass)
        var updateSql = String(format: "UPDATE %@ SET ", tableName)
        let fieldArray = fieldDictionary.keys
        var updateFieldArray: [String] = []
        for field in fieldArray {
            updateSql.append(String(format: "%@ = ?,", field))
            updateFieldArray.append(field)
        }
        updateSql = String(updateSql.dropLast())
        if let condition, !condition.isEmpty {
            updateSql.append(String(format: " WHERE %@", handleWhere(condition)))
        }
        if printSql {
            log(String(format: "执行更新 -> %@", updateSql))
        }

        var ppStmt: OpaquePointer?
        if sqlite3_prepare_v2(shared.database, updateSql, -1, &ppStmt, nil) == SQLITE_OK {
            for fieldName in fieldArray {
                let propertyInfo = fieldDictionary[fieldName]!
                var currentModel = model as? NSObject
                var actualField = fieldName
                if fieldName.range(of: "$") != nil {
                    let handleFieldName = fieldName.replacingOccurrences(of: "$", with: ".") as NSString
                    let backwardsRange = handleFieldName.range(of: ".", options: .backwards)
                    let keyPath = handleFieldName.substring(with: NSMakeRange(0, backwardsRange.location))
                    currentModel = currentModel?.value(forKeyPath: keyPath) as? NSObject
                    actualField = handleFieldName.substring(from: backwardsRange.location + backwardsRange.length)
                }
                guard let currentModel else { break }

                let index = Int32((updateFieldArray.firstIndex(of: fieldName) ?? 0) + 1)
                switch propertyInfo.type {
                case .mutableDictionary, .mutableArray, .dictionary, .array:
                    var value = currentModel.value(forKey: actualField)
                    if value == nil {
                        if propertyInfo.type == .mutableDictionary {
                            value = NSMutableDictionary()
                        } else if propertyInfo.type == .mutableArray {
                            value = NSMutableArray()
                        } else if propertyInfo.type == .dictionary {
                            value = NSDictionary()
                        } else {
                            value = NSArray()
                        }
                    }
                    let data = Data.fw.archivedData(value) as? NSData
                    let safeData = data ?? NSData()
                    sqlite3_bind_blob(ppStmt, index, safeData.bytes, Int32(safeData.length), nil)
                    if data == nil, !ArchiveCoder.isArchivableObject(value) {
                        log("update 操作异常 Array/Dictionary 元素 \(actualField) 没实现NSCoding协议归档失败", error: true)
                    }
                case .archivable:
                    let value = currentModel.value(forKey: actualField)
                    let data = Data.fw.archivedData(value) as? NSData
                    let safeData = data ?? NSData()
                    sqlite3_bind_blob(ppStmt, index, safeData.bytes, Int32(safeData.length), nil)
                case .date:
                    let value = currentModel.value(forKey: actualField) as? Date
                    sqlite3_bind_double(ppStmt, index, value?.timeIntervalSince1970 ?? 0)
                case .data:
                    let value = currentModel.value(forKey: actualField) as? NSData ?? NSData()
                    sqlite3_bind_blob(ppStmt, index, value.bytes, Int32(value.length), nil)
                case .string:
                    let value = currentModel.value(forKey: actualField) as? String ?? ""
                    sqlite3_bind_text(ppStmt, index, (value as NSString).utf8String, -1, nil)
                case .number:
                    let value = currentModel.value(forKey: actualField) as? NSNumber ?? NSNumber(value: 0)
                    sqlite3_bind_double(ppStmt, index, value.doubleValue)
                case .int:
                    let value = currentModel.value(forKey: actualField) as? Int64 ?? 0
                    sqlite3_bind_int64(ppStmt, index, value)
                case .char:
                    let value = currentModel.value(forKey: propertyInfo.propertyName) as? Int ?? 0
                    sqlite3_bind_int(ppStmt, index, Int32(value))
                case .boolean:
                    let value = currentModel.value(forKey: propertyInfo.propertyName) as? Bool ?? false
                    sqlite3_bind_int(ppStmt, index, NSNumber(value: value).int32Value)
                case .float:
                    let value = currentModel.value(forKey: actualField) as? Float ?? 0
                    sqlite3_bind_double(ppStmt, index, Double(value))
                case .double:
                    let value = currentModel.value(forKey: actualField) as? Double ?? 0
                    sqlite3_bind_double(ppStmt, index, value)
                }
            }
            let result = sqlite3_step(ppStmt) == SQLITE_DONE
            sqlite3_finalize(ppStmt)
            close()
            return result
        } else {
            log("更新模型失败", error: true)
            close()
            return false
        }
    }

    fileprivate static func commonDeleteModel(_ modelClass: AnyClass, where condition: String?) -> Bool {
        guard localName(with: modelClass) != nil else { return false }

        var result = false
        if openTable(modelClass) {
            let tableName = getTableName(modelClass)
            var deleteSql = String(format: "DELETE FROM %@", tableName)
            if let condition, !condition.isEmpty {
                deleteSql = deleteSql.appendingFormat(" WHERE %@", handleWhere(condition))
            }
            result = executeSql(deleteSql)
            close()
        }
        return result
    }

    fileprivate static func close() {
        if shared.database != nil {
            sqlite3_close(shared.database)
            shared.database = nil
        }
    }

    fileprivate static func commonLocalPath(_ modelClass: AnyClass, isPath: Bool) -> String? {
        let className = NSStringFromClass(modelClass)
        let cacheDirectory = databaseCacheDirectory(modelClass)
        var filePath: String?
        if FileManager.default.fileExists(atPath: cacheDirectory),
           let fileNames = try? FileManager.default.contentsOfDirectory(atPath: cacheDirectory), !fileNames.isEmpty {
            for fileName in fileNames {
                if fileName.range(of: className.appending("_v")) != nil {
                    if isPath {
                        filePath = cacheDirectory.fw.appendingPath(fileName)
                    } else {
                        filePath = fileName
                    }
                    break
                }
            }
        }
        return filePath
    }

    fileprivate static func localName(with modelClass: AnyClass) -> String? {
        commonLocalPath(modelClass, isPath: false)
    }

    fileprivate static func version(modelName: String?) -> String? {
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

    fileprivate static func isNumber(_ char: String) -> Bool {
        var value = 0
        let scanner = Scanner(string: char)
        return scanner.scanInt(&value) && scanner.isAtEnd
    }

    fileprivate static func log(_ msg: String, error: Bool = false) {
        #if DEBUG
        Logger.debug(group: Logger.fw.moduleName, "Database:%@ %@", error ? " [Error]" : "", msg)
        #endif
    }
}

private enum DatabaseFieldType: Int {
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
    case mutableArray
    case mutableDictionary
    case archivable

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
        case .int, .boolean:
            return "INTERGER"
        case .double, .float, .number, .date:
            return "DOUBLE"
        case .char:
            return "NVARCHAR"
        case .data, .array, .dictionary, .mutableArray, .mutableDictionary:
            return "BLOB"
        case .archivable:
            return "BLOB"
        case .string:
            return "TEXT"
        }
    }
}

private class DatabasePropertyInfo {
    let type: DatabaseFieldType
    let name: String
    let propertyName: String

    static func setter(propertyName: String) -> Selector {
        if propertyName.count > 1 {
            return NSSelectorFromString(String(format: "set%@%@:", String(propertyName.prefix(1).uppercased()), String(propertyName.dropFirst())))
        } else {
            return NSSelectorFromString(String(format: "set%@:", propertyName.uppercased()))
        }
    }

    init(type: DatabaseFieldType, propertyName: String, name: String) {
        self.type = type
        self.name = name
        self.propertyName = propertyName
    }
}
