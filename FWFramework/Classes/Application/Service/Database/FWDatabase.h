//
//  FWDatabase.h
//  FWDatabase
//
//  Created by admin on 16/5/28.
//  Copyright © 2016年 WHC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 数据库模型协议信息
@protocol FWDatabaseModel <NSObject>
@optional

/**
 自定义数据存储路径
 @return 自定义数据库路径(目录即可)
 */
+ (nullable NSString *)fwDatabasePath;

/// 自定义模型类数据库版本号
/** 注意：
 ***该返回值在改变数据模型属性类型/增加/删除属性时需要更改否则无法自动更新原来模型数据表字段以及类型***
 */
+ (nullable NSString *)fwDatabaseVersion;

/// 自定义数据库加密密码
/** 注意：
 ***该加密功能需要引用SQLCipher三方库才支持***
 /// 引入方式有:
 *** 手动引入 ***
 *** pod 'Component/SQLCipher' ***
 */
+ (nullable NSString *)fwDatabasePasswordKey;

/**
 引入第三方创建的数据库存储路径比如:FMDB
 来使用FWDatabase进行操作其他方式创建的数据库

 @return 存储路径
 */
+ (nullable NSString *)fwDatabaseVendorPath;

/**
 指定自定义表名，默认类名

 在指定引入其他方式创建的数据库时，这个时候如果表名不是模型类名需要实现该方法指定表名称
 
 @return 表名
 */
+ (nullable NSString *)fwTableName;

/// 自定义数据表主键名称，默认pkid
/**
 *** 返回自定义主键名称
 */
+ (nullable NSString *)fwTablePrimaryKey;

/**
 指定数据库表属性黑名单集合

 @return 返回数据库表属性黑名单集合
 */
+ (nullable NSArray<NSString *> *)fwTablePropertyBlacklist;

/**
 指定数据库表属性白名单集合

 @return 返回数据库表属性白名单集合
 */
+ (nullable NSArray<NSString *> *)fwTablePropertyWhitelist;

@end

/*!
 @brief 本地数据库管理类
 
 @see https://github.com/netyouli/WHC_ModelSqliteKit
 */
@interface FWDatabase : NSObject

/**
 * 全局数据库模型版本号，默认1.0。如果模型实现了fwDatabaseVersion且不为空，则会忽略全局版本号
 */
@property (class, nonatomic, copy) NSString *version;

/**
 * 说明: 保存模型到本地，主键存在时更新，不存在时新增
 * @param model_object 模型对象
 * @return 是否保存成功
 */
+ (BOOL)save:(nullable id)model_object;

/**
 * 说明: 新增模型数组到本地(事务方式)
 * @param model_array 模型数组对象(model_array 里对象类型要一致)
 * @return 是否插入成功
 */
+ (BOOL)inserts:(nullable NSArray *)model_array;

/**
 * 说明: 新增模型到本地，自动更新主键
 * @param model_object 模型对象
 * @return 是否插入成功
 */
+ (BOOL)insert:(nullable id)model_object;

/**
 * 说明: 获取模型类表总条数
 * @param model_class 模型类
 * @return 总条数
 */
+ (NSUInteger)count:(Class)model_class;

/**
 * 说明: 查询本地模型对象
 * @param model_class 模型类
 * @return 查询模型对象数组
 */
+ (NSArray *)query:(Class)model_class;

/**
 * 说明: 查询本地模型对象
 * @param model_class 模型类
 * @param where 查询条件(查询语法和SQL where 查询语法一样，where为空则查询所有)
 * @return 查询模型对象数组
 */
+ (NSArray *)query:(Class)model_class where:(nullable NSString *)where;

/**
 * 说明: 查询本地模型对象
 * @param model_class 模型类
 * @param order 排序条件(排序语法和SQL order 查询语法一样，order为空则不排序)
 * @return 查询模型对象数组
 */

/// example: [FWDatabase query:[Person class] order:@"age desc/asc"];
/// 对person数据表查询并且根据age自动降序或者升序排序
+ (NSArray *)query:(Class)model_class order:(nullable NSString *)order;

/**
 * 说明: 查询本地模型对象
 * @param model_class 模型类
 * @param limit 限制条件(限制语法和SQL limit 查询语法一样，limit为空则不限制查询)
 * @return 查询模型对象数组
 */

/// example: [FWDatabase query:[Person class] limit:@"8"];
/// 对person数据表查询并且并且限制查询数量为8
/// example: [FWDatabase query:[Person class] limit:@"8 offset 8"];
/// 对person数据表查询并且对查询列表偏移8并且限制查询数量为8
+ (NSArray *)query:(Class)model_class limit:(nullable NSString *)limit;

/**
 * 说明: 查询本地模型对象
 * @param model_class 模型类
 * @param where 查询条件(查询语法和SQL where 查询语法一样，where为空则查询所有)
 * @param order 排序条件(排序语法和SQL order 查询语法一样，order为空则不排序)
 * @return 查询模型对象数组
 */

/// example: [FWDatabase query:[Person class] where:@"age < 30" order:@"age desc/asc"];
/// 对person数据表查询age小于30岁并且根据age自动降序或者升序排序
+ (NSArray *)query:(Class)model_class where:(nullable NSString *)where order:(nullable NSString *)order;

/**
 * 说明: 查询本地模型对象
 * @param model_class 模型类
 * @param where 查询条件(查询语法和SQL where 查询语法一样，where为空则查询所有)
 * @param limit 限制条件(限制语法和SQL limit 查询语法一样，limit为空则不限制查询)
 * @return 查询模型对象数组
 */

/// example: [FWDatabase query:[Person class] where:@"age <= 30" limit:@"8"];
/// 对person数据表查询age小于30岁并且限制查询数量为8
/// example: [FWDatabase query:[Person class] where:@"age <= 30" limit:@"8 offset 8"];
/// 对person数据表查询age小于30岁并且对查询列表偏移8并且限制查询数量为8
+ (NSArray *)query:(Class)model_class where:(nullable NSString *)where limit:(nullable NSString *)limit;

/**
 * 说明: 查询本地模型对象
 * @param model_class 模型类
 * @param order 排序条件(排序语法和SQL order 查询语法一样，order为空则不排序)
 * @param limit 限制条件(限制语法和SQL limit 查询语法一样，limit为空则不限制查询)
 * @return 查询模型对象数组
 */

/// example: [FWDatabase query:[Person class] order:@"age desc/asc" limit:@"8"];
/// 对person数据表查询并且根据age自动降序或者升序排序并且限制查询的数量为8
/// example: [FWDatabase query:[Person class] order:@"age desc/asc" limit:@"8 offset 8"];
/// 对person数据表查询并且根据age自动降序或者升序排序并且限制查询的数量为8偏移为8
+ (NSArray *)query:(Class)model_class order:(nullable NSString *)order limit:(nullable NSString *)limit;

/**
 * 说明: 查询本地模型对象
 * @param model_class 模型类
 * @param where 查询条件(查询语法和SQL where 查询语法一样，where为空则查询所有)
 * @param order 排序条件(排序语法和SQL order 查询语法一样，order为空则不排序)
 * @param limit 限制条件(限制语法和SQL limit 查询语法一样，limit为空则不限制查询)
 * @return 查询模型对象数组
 */

/// example: [FWDatabase query:[Person class] where:@"age <= 30" order:@"age desc/asc" limit:@"8"];
/// 对person数据表查询age小于30岁并且根据age自动降序或者升序排序并且限制查询的数量为8
/// example: [FWDatabase query:[Person class] where:@"age <= 30" order:@"age desc/asc" limit:@"8 offset 8"];
/// 对person数据表查询age小于30岁并且根据age自动降序或者升序排序并且限制查询的数量为8偏移为8
+ (NSArray *)query:(Class)model_class where:(nullable NSString *)where order:(nullable NSString *)order limit:(nullable NSString *)limit;

/**
 * 说明: 根据主键查询本地模型对象
 * @param model_class 模型类
 * @param key 主键Id
 * @return 查询模型对象
 */

/// example: [FWDatabase query:[Person class] key:1]; /// 获取Person表主键为1的记录
+ (nullable id)query:(Class)model_class key:(NSInteger)key;

/**
 说明: 自定义sql查询

 @param model_class 接收model类
 @param sql sql语句
 @return 查询模型对象数组
 
 /// example: [FWDatabase query:Model.self sql:@"select cc.* from ( select tt.*, (select count(*)+1 from Chapter where chapter_id = tt.chapter_id and updateTime < tt.updateTime ) as group_id from Chapter tt) cc where cc.group_id <= 7 order by updateTime desc"];
 */
+ (NSArray *)query:(Class)model_class sql:(NSString *)sql;

/**
 * 说明: 利用sqlite 函数进行查询
 
 * @param model_class 要查询模型类
 * @param func sqlite函数例如：（MAX(age),MIN(age),COUNT(*)....）
 * @return 返回查询结果(如果结果条数 > 1返回Array , = 1返回单个值 , = 0返回nil)
 * /// example: [FWDatabase query:[Person class] sqliteFunc:@"max(age)"];  /// 获取Person表的最大age值
 * /// example: [FWDatabase query:[Person class] sqliteFunc:@"count(*)"];  /// 获取Person表的总记录条数
 */
+ (nullable id)query:(Class)model_class func:(NSString *)func;

/**
 * 说明: 利用sqlite 函数进行查询
 
 * @param model_class 要查询模型类
 * @param func sqlite函数例如：（MAX(age),MIN(age),COUNT(*)....）
 * @param condition 其他查询条件例如：(where age > 20 order by age desc ....)
 * @return 返回查询结果(如果结果条数 > 1返回Array , = 1返回单个值 , = 0返回nil)
 * /// example: [FWDatabase query:[Person class] sqliteFunc:@"max(age)" condition:@"where name = '北京'"];  /// 获取Person表name=北京集合中的的最大age值
 * /// example: [FWDatabase query:[Person class] sqliteFunc:@"count(*)" condition:@"where name = '北京'"];  /// 获取Person表name=北京集合中的总记录条数
 */
+ (nullable id)query:(Class)model_class func:(NSString *)func condition:(nullable NSString *)condition;

/**
 * 说明: 更新本地模型对象
 * @param model_object 模型对象
 * @param where 查询条件(查询语法和SQL where 查询语法一样，where为空则更新所有)
 */
+ (BOOL)update:(id)model_object where:(nullable NSString *)where;

/**
 说明: 更新数据表字段

 @param model_class 模型类
 @param value 更新的值
 @param where 更新条件
 @return 是否成功
 /// 更新Person表在age字段大于25岁是的name值为whc，age为100岁
 /// example: [FWDatabase update:Person.self value:@"name = 'whc', age = 100" where:@"age > 25"];
 */
+ (BOOL)update:(Class)model_class value:(NSString *)value where:(nullable NSString *)where;

/**
 * 说明: 清空本地模型对象
 * @param model_class 模型类
 */
+ (BOOL)clear:(Class)model_class;

/**
 * 说明: 根据主键删除本地模型对象，主键必须存在
 * @param model_object 模型对象
 * @return 是否删除成功
 */
+ (BOOL)delete:(id)model_object;

/**
 * 说明: 删除本地模型对象
 * @param model_class 模型类
 * @param where 查询条件(查询语法和SQL where 查询语法一样，where为空则删除所有)
 */
+ (BOOL)delete:(Class)model_class where:(nullable NSString *)where;

/**
 * 说明: 清空所有本地模型数据库
 */
+ (void)removeAllModel;

/**
 * 说明: 清空指定本地模型数据库
 * @param model_class 模型类
 */
+ (void)removeModel:(Class)model_class;

/**
 * 说明: 返回本地模型数据库路径
 * @param model_class 模型类
 * @return 路径
 */
+ (nullable NSString *)localPathWithModel:(Class)model_class;

/**
 * 说明: 返回本地模型数据库版本号
 * @param model_class 模型类
 * @return 版本号
 */
+ (nullable NSString *)versionWithModel:(Class)model_class;

@end

NS_ASSUME_NONNULL_END
