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
    public static func count<T: DatabaseModel>(_ type: T.Type, where: String? = nil) -> UInt {
        return 0
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
    public static func query<T: DatabaseModel>(_ type: T.Type, where: String? = nil, order: String? = nil, limit: String? = nil) -> [T] {
        return []
    }
    
    /// 自定义sql查询
    public static func query<T: DatabaseModel>(_ type: T.Type, sql: String) -> [T] {
        return []
    }
    
    /// 根据主键查询本地模型对象
    public static func query<T: DatabaseModel>(_ type: T.Type, key: Int) -> T? {
        return nil
    }
    
    /// 利用sqlite 函数进行查询，condition为其他查询条件例如：(where age > 20 order by age desc ....)
    public static func query<T: DatabaseModel>(_ type: T.Type, func: String, condition: String? = nil) -> Any? {
        return nil
    }
    
    /// 更新本地模型对象
    @discardableResult
    public static func update(_ model: DatabaseModel, where: String? = nil) -> Bool {
        return false
    }
    
    /// 更新数据表字段
    @discardableResult
    public static func update<T: DatabaseModel>(_ type: T.Type, value: String, where: String? = nil) -> Bool {
        return false
    }
    
    /// 清空本地模型对象
    @discardableResult
    public static func clear<T: DatabaseModel>(_ type: T.Type) -> Bool {
        return false
    }
    
    /// 根据主键删除本地模型对象，主键必须存在
    @discardableResult
    public static func delete(_ model: DatabaseModel) -> Bool {
        return false
    }
    
    /// 删除本地模型对象
    @discardableResult
    public static func delete<T: DatabaseModel>(_ type: T.Type, where: String? = nil) -> Bool {
        return false
    }
    
    /// 清空所有本地模型数据库
    public static func removeAllModels() {
        
    }
    
    /// 清空指定本地模型数据库
    public static func removeModel<T: DatabaseModel>(_ type: T.Type) {
        
    }
    
    /// 返回本地模型数据库路径
    public static func localPath<T: DatabaseModel>(with type: T.Type) -> String? {
        return nil
    }
    
    /// 返回本地模型数据库版本号
    public static func version<T: DatabaseModel>(with type: T.Type) -> String? {
        return nil
    }
    
}
