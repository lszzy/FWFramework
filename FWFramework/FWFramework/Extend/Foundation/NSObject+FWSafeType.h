/*!
 @header     NSObject+FWSafeType.h
 @indexgroup FWFramework
 @brief      NSObject类型安全分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-07-18
 */

#import <Foundation/Foundation.h>

/*!
 @brief 安全数字，不为nil
 
 @param x 参数
 */
#define FWSafeNumber( x ) \
    (x ? x : @0)

/*!
 @brief 安全字符串，不为nil
 
 @param x 参数
 */
#define FWSafeString( x ) \
    (x ? [NSString stringWithFormat:@"%@", x] : @"")

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
- (NSNumber *)fwAsNSNumber;

/*!
 @brief 检测并转换为NSString
 
 @return NSString
 */
- (NSString *)fwAsNSString;

/*!
 @brief 检测并转换为NSDate
 
 @return NSDate
 */
- (NSDate *)fwAsNSDate;

/*!
 @brief 检测并转换为NSData
 
 @return NSData
 */
- (NSData *)fwAsNSData;

/*!
 @brief 检测并转换为NSArray
 
 @return NSArray
 */
- (NSArray *)fwAsNSArray;

/*!
 @brief 检测并转换为NSMutableArray
 
 @return NSMutableArray
 */
- (NSMutableArray *)fwAsNSMutableArray;

/*!
 @brief 检测并转换为NSDictionary
 
 @return NSDictionary
 */
- (NSDictionary *)fwAsNSDictionary;

/*!
 @brief 检测并转换为NSMutableDictionary
 
 @return NSMutableDictionary
 */
- (NSMutableDictionary *)fwAsNSMutableDictionary;

/*!
 @brief 检测并转换为指定Class对象
 
 @return 指定Class对象
 */
- (id)fwAsClass:(Class)clazz;

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
- (NSString *)fwSubstringFromIndex:(NSInteger)from;

/*!
 @brief 截取子串到指定位置
 
 @param to 结束位置
 @return 子串
 */
- (NSString *)fwSubstringToIndex:(NSInteger)to;

/*!
 @brief 截取指定范围的子串
 
 @param range 指定范围
 @return 子串
 */
- (NSString *)fwSubstringWithRange:(NSRange)range;

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
- (ObjectType)fwObjectAtIndex:(NSInteger)index;

/*!
 @brief 安全获取子数组
 
 @param range 范围
 @return 对象数组
 */
- (NSArray *)fwSubarrayWithRange:(NSRange)range;

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
- (void)fwAddObject:(ObjectType)object;

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
- (void)fwInsertObject:(ObjectType)object atIndex:(NSInteger)index;

/*!
 @brief 安全替换对象到指定位置
 
 @param index 索引
 @param object 对象
 */
- (void)fwReplaceObjectAtIndex:(NSInteger)index withObject:(ObjectType)object;

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
- (void)fwInsertObjects:(NSArray *)objects atIndex:(NSInteger)index;

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
- (ObjectType)fwObjectForKey:(KeyType)key;

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
- (void)fwRemoveObjectForKey:(KeyType)key;

/*!
 @brief 安全设置对象（过滤NSNull）

 @param object 键值
 @param key 键名
 */
- (void)fwSetObject:(ObjectType)object forKey:(KeyType <NSCopying>)key;

@end
