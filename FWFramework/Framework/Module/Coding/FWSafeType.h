/*!
 @header     FWSafeType.h
 @indexgroup FWFramework
 @brief      NSObject类型安全分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-07-18
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief 安全数字，不为nil
 
 @param value 参数
 @return 数字
 */
FOUNDATION_EXPORT NSNumber * FWSafeNumber(id _Nullable value);

/*!
 @brief 安全字符串，不为nil
 
 @param value 参数
 @return 字符串
 */
FOUNDATION_EXPORT NSString * FWSafeString(id _Nullable value);

#pragma mark - NSObject+FWSafeType

/*!
 @brief NSObject类型安全分类
 */
@interface NSObject (FWSafeType)

/*!
 @brief 是否是非Null(nil, NSNull)
 
 @return 如果为非Null返回YES，为Null返回NO
 */
- (BOOL)fwIsNotNull;

/*!
 @brief 是否是非空对象(nil, NSNull, count为0, length为0)
 
 @return 如果是非空对象返回YES，为空对象返回NO
 */
- (BOOL)fwIsNotEmpty;

/*!
 @brief 检测并转换为NSInteger
 
 @return NSInteger
 */
- (NSInteger)fwAsInteger;

/*!
 @brief 检测并转换为Float
 
 @return Float
 */
- (float)fwAsFloat;

/*!
 @brief 检测并转换为Double
 
 @return Double
 */
- (double)fwAsDouble;

/*!
 @brief 检测并转换为Bool
 
 @return Bool
 */
- (BOOL)fwAsBool;

/*!
 @brief 检测并转换为NSNumber
 
 @return NSNumber
 */
- (nullable NSNumber *)fwAsNSNumber;

/*!
 @brief 检测并转换为NSString
 
 @return NSString
 */
- (nullable NSString *)fwAsNSString;

/*!
 @brief 检测并转换为NSDate
 
 @return NSDate
 */
- (nullable NSDate *)fwAsNSDate;

/*!
 @brief 检测并转换为NSData
 
 @return NSData
 */
- (nullable NSData *)fwAsNSData;

/*!
 @brief 检测并转换为NSArray
 
 @return NSArray
 */
- (nullable NSArray *)fwAsNSArray;

/*!
 @brief 检测并转换为NSMutableArray
 
 @return NSMutableArray
 */
- (nullable NSMutableArray *)fwAsNSMutableArray;

/*!
 @brief 检测并转换为NSDictionary
 
 @return NSDictionary
 */
- (nullable NSDictionary *)fwAsNSDictionary;

/*!
 @brief 检测并转换为NSMutableDictionary
 
 @return NSMutableDictionary
 */
- (nullable NSMutableDictionary *)fwAsNSMutableDictionary;

/*!
 @brief 检测并转换为指定Class对象
 
 @return 指定Class对象
 */
- (nullable id)fwAsClass:(Class)clazz;

#pragma mark - Property

/*!
 @brief 读取关联属性
 
 @param name 属性名称
 @return 属性值
 */
- (nullable id)fwPropertyForName:(NSString *)name;

/*!
 @brief 设置强关联属性，支持KVO
 
 @param object 属性值
 @param name   属性名称
 */
- (void)fwSetProperty:(nullable id)object forName:(NSString *)name;

/*!
 @brief 设置赋值关联属性，支持KVO，注意可能会产生野指针
 
 @param object 属性值
 @param name   属性名称
 */
- (void)fwSetPropertyAssign:(nullable id)object forName:(NSString *)name;

/*!
 @brief 设置拷贝关联属性，支持KVO
 
 @param object 属性值
 @param name   属性名称
 */
- (void)fwSetPropertyCopy:(nullable id)object forName:(NSString *)name;

/*!
 @brief 读取弱引用关联属性，需和fwSetPropertyWeak配套使用(OC不支持weak关联属性)
 
 @param name 属性名称
 @return 属性值
 */
- (nullable id)fwPropertyWeakForName:(NSString *)name;

/*!
 @brief 设置弱引用关联属性，支持KVO，需和fwPropertyWeakForName配套使用(OC不支持weak关联属性)
 
 @param object 属性值
 @param name   属性名称
 */
- (void)fwSetPropertyWeak:(nullable id)object forName:(NSString *)name;

@end

#pragma mark - NSNumber+FWSafeType

/*!
 @brief NSNumber类型安全分类
 */
@interface NSNumber (FWSafeType)

/*!
 @brief 比较NSNumber是否相等，如果参数为nil，判定为不相等
 
 @param number 比较的number
 @return 是否相等
 */
- (BOOL)fwIsEqualToNumber:(nullable NSNumber *)number;

/*!
@brief 比较NSNumber大小，如果参数为nil，判定为NSOrderedDescending

@param number 比较的number
@return 比较结果
*/
- (NSComparisonResult)fwCompare:(nullable NSNumber *)number;

@end

#pragma mark - NSString+FWSafeType

/*!
 @brief NSString类型安全分类
 */
@interface NSString (FWSafeType)

/*!
 @brief 从指定位置截取子串
 
 @param from 起始位置
 @return 子串
 */
- (nullable NSString *)fwSubstringFromIndex:(NSInteger)from;

/*!
 @brief 截取子串到指定位置
 
 @param to 结束位置
 @return 子串
 */
- (nullable NSString *)fwSubstringToIndex:(NSInteger)to;

/*!
 @brief 截取指定范围的子串
 
 @param range 指定范围
 @return 子串
 */
- (nullable NSString *)fwSubstringWithRange:(NSRange)range;

@end

#pragma mark - NSURL+FWSafeType

/*!
 @brief NSURL类型安全分类
 */
@interface NSURL (FWSafeType)

// 生成URL，中文自动URL编码
+ (nullable instancetype)fwURLWithString:(nullable NSString *)URLString;

// 生成URL，中文自动URL编码
+ (nullable instancetype)fwURLWithString:(nullable NSString *)URLString relativeToURL:(nullable NSURL *)baseURL;

@end

#pragma mark - NSArray+FWSafeType

/*!
 @brief NSArray类型安全分类
 */
@interface NSArray<__covariant ObjectType> (FWSafeType)

/*!
 @brief 安全获取对象
 
 @param index 索引
 @return 对象
 */
- (nullable ObjectType)fwObjectAtIndex:(NSInteger)index;

/*!
 @brief 安全获取子数组
 
 @param range 范围
 @return 对象数组
 */
- (nullable NSArray *)fwSubarrayWithRange:(NSRange)range;

@end

#pragma mark - NSMutableArray+FWSafeType

/*!
 @brief NSMutableArray类型安全分类
 */
@interface NSMutableArray<ObjectType> (FWSafeType)

/*!
 @brief 安全添加对象
 
 @param object 对象
 */
- (void)fwAddObject:(nullable ObjectType)object;

/*!
 @brief 安全移除指定索引对象
 
 @param index 索引
 */
- (void)fwRemoveObjectAtIndex:(NSInteger)index;

/*!
 @brief 安全插入对象到指定位置
 
 @param object 对象
 @param index 索引
 */
- (void)fwInsertObject:(nullable ObjectType)object atIndex:(NSInteger)index;

/*!
 @brief 安全替换对象到指定位置
 
 @param index 索引
 @param object 对象
 */
- (void)fwReplaceObjectAtIndex:(NSInteger)index withObject:(nullable ObjectType)object;

/*!
 @brief 安全移除子数组
 
 @param range 范围
 */
- (void)fwRemoveObjectsInRange:(NSRange)range;

/*!
 @brief 安全插入数组到指定位置
 
 @param objects 要插入的数组
 @param index 索引
 */
- (void)fwInsertObjects:(nullable NSArray *)objects atIndex:(NSInteger)index;

@end

#pragma mark - NSDictionary+FWSafeType

/*!
 @brief NSDictionary类型安全分类
 */
@interface NSDictionary<__covariant KeyType, __covariant ObjectType> (FWSafeType)

/*!
 @brief 安全读取对象（过滤NSNull）
 
 @param key 键名
 @return 键值
 */
- (nullable ObjectType)fwObjectForKey:(nullable KeyType)key;

@end

#pragma mark - NSMutableDictionary+FWSafeType

/*!
 @brief NSMutableDictionary类型安全分类
 */
@interface NSMutableDictionary<KeyType, ObjectType> (FWSafeType)

/*!
 @brief 安全移除指定键名
 
 @param key 键名
 */
- (void)fwRemoveObjectForKey:(nullable KeyType)key;

/*!
 @brief 安全设置对象（过滤NSNull）

 @param object 键值
 @param key 键名
 */
- (void)fwSetObject:(nullable ObjectType)object forKey:(nullable KeyType <NSCopying>)key;

@end

NS_ASSUME_NONNULL_END
