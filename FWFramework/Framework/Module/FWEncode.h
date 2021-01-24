/*!
 @header     FWEncode.h
 @indexgroup FWFramework
 @brief      FWEncode
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/19
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - NSString+FWEncode

/**
 *  字符串编码扩展
 */
@interface NSString (FWEncode)

#pragma mark - Json

/*!
 @brief Foundation对象编码为json字符串
 
 @param object 编码对象
 @return json字符串
 */
+ (nullable NSString *)fwJsonEncode:(id)object;

/**
 *  json字符串解码为Foundation对象
 *
 *  @return Foundation对象
 */
- (nullable id)fwJsonDecode;

#pragma mark - Unicode

/**
 *  计算长度，中文为1，英文为0.5
 */
- (NSUInteger)fwUnicodeLength;

/**
 *  截取字符串，中文为1，英文为0.5
 *
 *  @param length 截取长度
 */
- (NSString *)fwUnicodeSubstring:(NSUInteger)length;

/**
 *  Unicode中文编码，将中文转换成Unicode字符串(如\u7E8C)
 *
 *  @return Unicode字符串
 */
- (NSString *)fwUnicodeEncode;

/**
 *  Unicode中文解码，将Unicode字符串(如\u7E8C)转换成中文
 *
 *  @return 中文字符串
 */
- (NSString *)fwUnicodeDecode;

#pragma mark - Base64

/**
 *  base64编码
 *
 *  @return base64字符串
 */
- (nullable NSString *)fwBase64Encode;

/**
 *  base64解码
 *
 *  @return 原字符串
 */
- (nullable NSString *)fwBase64Decode;

#pragma mark - Url

/**
 *  url参数编码，适用于query参数编码
 *  示例：http://test.com?id=我是中文 =>
 *       http%3A%2F%2Ftest.com%3Fid%3D%E6%88%91%E6%98%AF%E4%B8%AD%E6%96%87
 *
 *  @return url编码字符串
 */
- (nullable NSString *)fwUrlEncodeComponent;

/**
 *  url参数解码，适用于query参数解码
 *  示例：http%3A%2F%2Ftest.com%3Fid%3D%E6%88%91%E6%98%AF%E4%B8%AD%E6%96%87 =>
 *       http://test.com?id=我是中文
 *
 *  @return 原字符串
 */
- (nullable NSString *)fwUrlDecodeComponent;

/**
 *  url编码，适用于整个url编码
 *  示例：http://test.com?id=我是中文 =>
 *       http://test.com?id=%E6%88%91%E6%98%AF%E4%B8%AD%E6%96%87
 *
 *  @return url编码地址
 */
- (nullable NSString *)fwUrlEncode;

/**
 *  url解码，适用于整个url解码
 *  示例：http://test.com?id=%E6%88%91%E6%98%AF%E4%B8%AD%E6%96%87 =>
 *       http://test.com?id=我是中文
 *
 *  @return 原url地址
 */
- (nullable NSString *)fwUrlDecode;

#pragma mark - Query

/**
 * 字典编码为url参数字符串
 */
+ (NSString *)fwQueryEncode:(NSDictionary *)dictionary;

/**
 * url参数字符串解码为字典
 */
- (NSDictionary *)fwQueryDecode;

#pragma mark - Md5

/**
 *  md5编码
 *
 *  @return md5字符串
 */
- (NSString *)fwMd5Encode;

/**
 *  文件md5编码
 *
 *  @return md5字符串
 */
- (nullable NSString *)fwMd5EncodeFile;

@end

#pragma mark - FWSafeType

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
 @brief 去掉空白字符
 
 @return trim字符串
 */
- (NSString *)fwTrimString;

/*!
 @brief 转换为UTF8编码数据
 
 @return UTF8编码数据
 */
- (nullable NSData *)fwUTF8Data;

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

#pragma mark - NSData+FWSafeType

/*!
 @brief NSData类型安全分类
 */
@interface NSData (FWSafeType)

/*!
 @brief Foundation对象编码为json数据
 
 @param object 编码对象
 @return json数据
 */
+ (nullable NSData *)fwJsonEncode:(id)object;

/**
 *  json数据解码为Foundation对象
 *
 *  @return Foundation对象
 */
- (nullable id)fwJsonDecode;

/*!
 @brief 转换为UTF8编码字符串
 
 @return UTF8编码字符串
 */
- (nullable NSString *)fwUTF8String;

@end

#pragma mark - NSNull+FWSafeType

/*!
 @brief NSNull分类，解决值为NSNull时调用不存在方法崩溃问题，如JSON中包含null
 @discussion 默认调试环境不处理崩溃，正式环境才处理崩溃，尽量开发阶段避免此问题

 @see https://github.com/nicklockwood/NullSafe
*/
@interface NSNull (FWSafeType)

@end

#pragma mark - NSURL+FWSafeType

/*!
 @brief NSURL类型安全分类
 */
@interface NSURL (FWSafeType)

/// 生成URL，中文自动URL编码
+ (nullable instancetype)fwURLWithString:(nullable NSString *)URLString;

/// 生成URL，中文自动URL编码
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
