//
//  FWEncode.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - NSString+FWEncode

@interface NSString (FWEncode)

#pragma mark - Json

/**
 Foundation对象编码为json字符串
 
 @param object 编码对象
 @return json字符串
 */
+ (nullable NSString *)fw_jsonEncode:(id)object NS_REFINED_FOR_SWIFT;

/**
 *  json字符串解码为Foundation对象
 *
 *  @return Foundation对象
 */
- (nullable id)fw_jsonDecode NS_REFINED_FOR_SWIFT;

#pragma mark - Base64

/**
 *  base64编码
 *
 *  @return base64字符串
 */
- (nullable NSString *)fw_base64Encode NS_REFINED_FOR_SWIFT;

/**
 *  base64解码
 *
 *  @return 原字符串
 */
- (nullable NSString *)fw_base64Decode NS_REFINED_FOR_SWIFT;

#pragma mark - Unicode

/**
 *  计算长度，中文为1，英文为0.5
 */
- (NSUInteger)fw_unicodeLength NS_REFINED_FOR_SWIFT;

/**
 *  截取字符串，中文为1，英文为0.5
 *
 *  @param length 截取长度
 */
- (NSString *)fw_unicodeSubstring:(NSUInteger)length NS_REFINED_FOR_SWIFT;

/**
 *  Unicode中文编码，将中文转换成Unicode字符串(如\u7E8C)
 *
 *  @return Unicode字符串
 */
- (NSString *)fw_unicodeEncode NS_REFINED_FOR_SWIFT;

/**
 *  Unicode中文解码，将Unicode字符串(如\u7E8C)转换成中文
 *
 *  @return 中文字符串
 */
- (NSString *)fw_unicodeDecode NS_REFINED_FOR_SWIFT;

#pragma mark - Url

/**
 *  url参数编码，适用于query参数编码
 *  示例：http://test.com?id=我是中文 =>
 *       http%3A%2F%2Ftest.com%3Fid%3D%E6%88%91%E6%98%AF%E4%B8%AD%E6%96%87
 *
 *  @return url编码字符串
 */
- (nullable NSString *)fw_urlEncodeComponent NS_REFINED_FOR_SWIFT;

/**
 *  url参数解码，适用于query参数解码
 *  示例：http%3A%2F%2Ftest.com%3Fid%3D%E6%88%91%E6%98%AF%E4%B8%AD%E6%96%87 =>
 *       http://test.com?id=我是中文
 *
 *  @return 原字符串
 */
- (nullable NSString *)fw_urlDecodeComponent NS_REFINED_FOR_SWIFT;

/**
 *  url编码，适用于整个url编码
 *  示例：http://test.com?id=我是中文 =>
 *       http://test.com?id=%E6%88%91%E6%98%AF%E4%B8%AD%E6%96%87
 *
 *  @return url编码地址
 */
- (nullable NSString *)fw_urlEncode NS_REFINED_FOR_SWIFT;

/**
 *  url解码，适用于整个url解码
 *  示例：http://test.com?id=%E6%88%91%E6%98%AF%E4%B8%AD%E6%96%87 =>
 *       http://test.com?id=我是中文
 *
 *  @return 原url地址
 */
- (nullable NSString *)fw_urlDecode NS_REFINED_FOR_SWIFT;

#pragma mark - Query

/**
 * 字典编码为URL参数字符串
 */
+ (NSString *)fw_queryEncode:(NSDictionary<NSString *, id> *)dictionary NS_REFINED_FOR_SWIFT;

/**
 * URL参数字符串解码为字典，支持完整URL
 */
- (NSDictionary<NSString *, NSString *> *)fw_queryDecode NS_REFINED_FOR_SWIFT;

#pragma mark - Md5

/**
 *  md5编码
 *
 *  @return md5字符串
 */
- (NSString *)fw_md5Encode NS_REFINED_FOR_SWIFT;

/**
 *  文件md5编码
 *
 *  @return md5字符串
 */
- (nullable NSString *)fw_md5EncodeFile NS_REFINED_FOR_SWIFT;

#pragma mark - Helper

/**
 去掉空白字符
 */
@property (nonatomic, copy, readonly) NSString *fw_trimString NS_REFINED_FOR_SWIFT;

/**
 首字母大写
 */
@property (nonatomic, copy, readonly) NSString *fw_ucfirstString NS_REFINED_FOR_SWIFT;

/**
 首字母小写
 */
@property (nonatomic, copy, readonly) NSString *fw_lcfirstString NS_REFINED_FOR_SWIFT;

/**
 驼峰转下划线
 */
@property (nonatomic, copy, readonly) NSString *fw_underlineString NS_REFINED_FOR_SWIFT;

/**
 下划线转驼峰
 */
@property (nonatomic, copy, readonly) NSString *fw_camelString NS_REFINED_FOR_SWIFT;

/**
 中文转拼音
 */
@property (nonatomic, copy, readonly) NSString *fw_pinyinString NS_REFINED_FOR_SWIFT;

/**
 中文转拼音并进行比较
 */
- (NSComparisonResult)fw_pinyinCompare:(NSString *)string NS_REFINED_FOR_SWIFT;

/**
 过滤JSON解码特殊字符
 
 兼容\uD800-\uDFFF引起JSON解码报错3840问题，不报错时无需调用
 规则：只允许以\uD800-\uDBFF高位开头，紧跟\uDC00-\uDFFF低位；其他全不允许
 参考：https://github.com/SBJson/SBJson/blob/trunk/Classes/SBJson5StreamTokeniser.m
 */
@property (nonatomic, copy, readonly) NSString *fw_escapeJson NS_REFINED_FOR_SWIFT;

/**
 转换为UTF8编码数据
 */
@property (nonatomic, strong, readonly, nullable) NSData *fw_utf8Data NS_REFINED_FOR_SWIFT;

/**
 转换为NSURL
 */
@property (nonatomic, copy, readonly, nullable) NSURL *fw_url NS_REFINED_FOR_SWIFT;

/**
 转换为NSNumber
 */
@property (nonatomic, readonly, nullable) NSNumber *fw_number NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSData+FWEncode

@interface NSData (FWEncode)

#pragma mark - Json

/**
 Foundation对象编码为json数据
 
 @param object 编码对象
 @return json数据
 */
+ (nullable NSData *)fw_jsonEncode:(id)object NS_REFINED_FOR_SWIFT;

/**
 json数据解码为Foundation对象

 @return Foundation对象
 */
- (nullable id)fw_jsonDecode NS_REFINED_FOR_SWIFT;

#pragma mark - Base64

/**
 *  base64编码
 *
 *  @return base64数据
 */
- (NSData *)fw_base64Encode NS_REFINED_FOR_SWIFT;

/**
 *  base64解码
 *
 *  @return 原数据
 */
- (nullable NSData *)fw_base64Decode NS_REFINED_FOR_SWIFT;

#pragma mark - Helper

/**
 转换为UTF8编码字符串
 
 @return UTF8编码字符串
 */
@property (nonatomic, copy, readonly, nullable) NSString *fw_utf8String NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSURL+FWEncode

@interface NSURL (FWEncode)

/// 获取当前query的参数字典，不含空值
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSString *> *fw_queryDictionary NS_REFINED_FOR_SWIFT;

/// 获取基准URI字符串，不含path|query|fragment等，包含scheme|host|port等
@property (nonatomic, copy, readonly, nullable) NSString *fw_baseURI NS_REFINED_FOR_SWIFT;

/// 获取路径URI字符串，不含scheme|host|port等，包含path|query|fragment等
@property (nonatomic, copy, readonly, nullable) NSString *fw_pathURI NS_REFINED_FOR_SWIFT;

/// 生成URL，中文自动URL编码
+ (nullable NSURL *)fw_urlWithString:(nullable NSString *)string NS_REFINED_FOR_SWIFT;

/// 生成URL，中文自动URL编码
+ (nullable NSURL *)fw_urlWithString:(nullable NSString *)string relativeTo:(nullable NSURL *)baseURL NS_REFINED_FOR_SWIFT;

@end

#pragma mark - FWSafeValue

/**
 安全数字，不为nil
 
 @param value 参数
 @return 数字
 */
FOUNDATION_EXPORT NSNumber * FWSafeNumber(id _Nullable value) NS_SWIFT_UNAVAILABLE("");

/**
 安全字符串，不为nil
 
 @param value 参数
 @return 字符串
 */
FOUNDATION_EXPORT NSString * FWSafeString(id _Nullable value) NS_SWIFT_UNAVAILABLE("");

/**
 安全URL，不为nil
 
 @param value 参数
 @return URL
 */
FOUNDATION_EXPORT NSURL * FWSafeURL(id _Nullable value) NS_SWIFT_UNAVAILABLE("");

#pragma mark - NSObject+FWSafeType

@interface NSObject (FWSafeType)

/**
 是否是非Null(nil, NSNull)
 
 @return 如果为非Null返回YES，为Null返回NO
 */
@property (nonatomic, assign, readonly) BOOL fw_isNotNull NS_REFINED_FOR_SWIFT;

/**
 是否是非空对象(nil, NSNull, count为0, length为0)
 
 @return 如果是非空对象返回YES，为空对象返回NO
 */
@property (nonatomic, assign, readonly) BOOL fw_isNotEmpty NS_REFINED_FOR_SWIFT;

/**
 检测并安全转换为NSInteger
 
 @return NSInteger
 */
@property (nonatomic, assign, readonly) NSInteger fw_safeInteger NS_REFINED_FOR_SWIFT;

/**
 检测并安全转换为Float
 
 @return Float
 */
@property (nonatomic, assign, readonly) float fw_safeFloat NS_REFINED_FOR_SWIFT;

/**
 检测并安全转换为Double
 
 @return Double
 */
@property (nonatomic, assign, readonly) double fw_safeDouble NS_REFINED_FOR_SWIFT;

/**
 检测并安全转换为Bool
 
 @return Bool
 */
@property (nonatomic, assign, readonly) BOOL fw_safeBool NS_REFINED_FOR_SWIFT;

/**
 检测并安全转换为NSNumber
 
 @return NSNumber
 */
@property (nonatomic, strong, readonly) NSNumber *fw_safeNumber NS_REFINED_FOR_SWIFT;

/**
 检测并安全转换为NSString
 
 @return NSString
 */
@property (nonatomic, copy, readonly) NSString *fw_safeString NS_REFINED_FOR_SWIFT;

/**
 检测并安全转换为NSDate
 
 @return NSDate
 */
@property (nonatomic, strong, readonly) NSDate *fw_safeDate NS_REFINED_FOR_SWIFT;

/**
 检测并安全转换为NSData
 
 @return NSData
 */
@property (nonatomic, strong, readonly) NSData *fw_safeData NS_REFINED_FOR_SWIFT;

/**
 检测并安全转换为NSArray
 
 @return NSArray
 */
@property (nonatomic, strong, readonly) NSArray *fw_safeArray NS_REFINED_FOR_SWIFT;

/**
 检测并安全转换为NSMutableArray
 
 @return NSMutableArray
 */
@property (nonatomic, strong, readonly) NSMutableArray *fw_safeMutableArray NS_REFINED_FOR_SWIFT;

/**
 检测并安全转换为NSDictionary
 
 @return NSDictionary
 */
@property (nonatomic, strong, readonly) NSDictionary *fw_safeDictionary NS_REFINED_FOR_SWIFT;

/**
 检测并安全转换为NSMutableDictionary
 
 @return NSMutableDictionary
 */
@property (nonatomic, strong, readonly) NSMutableDictionary *fw_safeMutableDictionary NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSString+FWSafeType

@interface NSString (FWSafeType)

/**
 从指定位置截取子串
 
 @param from 起始位置
 @return 子串
 */
- (nullable NSString *)fw_substringFromIndex:(NSInteger)from NS_REFINED_FOR_SWIFT;

/**
 截取子串到指定位置
 
 @param to 结束位置
 @return 子串
 */
- (nullable NSString *)fw_substringToIndex:(NSInteger)to NS_REFINED_FOR_SWIFT;

/**
 截取指定范围的子串
 
 @param range 指定范围
 @return 子串
 */
- (nullable NSString *)fw_substringWithRange:(NSRange)range NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSArray+FWSafeType

@interface NSArray<__covariant ObjectType> (FWSafeType)

/**
 安全获取对象
 
 @param index 索引
 @return 对象
 */
- (nullable ObjectType)fw_objectAtIndex:(NSInteger)index NS_REFINED_FOR_SWIFT;

/**
 安全获取子数组
 
 @param range 范围
 @return 对象数组
 */
- (nullable NSArray<ObjectType> *)fw_subarrayWithRange:(NSRange)range NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSMutableArray+FWSafeType

@interface NSMutableArray<ObjectType> (FWSafeType)

/**
 安全添加对象
 
 @param object 对象
 */
- (void)fw_addObject:(nullable ObjectType)object NS_REFINED_FOR_SWIFT;

/**
 安全移除指定索引对象
 
 @param index 索引
 */
- (void)fw_removeObjectAtIndex:(NSInteger)index NS_REFINED_FOR_SWIFT;

/**
 安全插入对象到指定位置
 
 @param object 对象
 @param index 索引
 */
- (void)fw_insertObject:(nullable ObjectType)object atIndex:(NSInteger)index NS_REFINED_FOR_SWIFT;

/**
 安全替换对象到指定位置
 
 @param index 索引
 @param object 对象
 */
- (void)fw_replaceObjectAtIndex:(NSInteger)index withObject:(nullable ObjectType)object NS_REFINED_FOR_SWIFT;

/**
 安全移除子数组
 
 @param range 范围
 */
- (void)fw_removeObjectsInRange:(NSRange)range NS_REFINED_FOR_SWIFT;

/**
 安全插入数组到指定位置
 
 @param objects 要插入的数组
 @param index 索引
 */
- (void)fw_insertObjects:(nullable NSArray *)objects atIndex:(NSInteger)index NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSMutableSet+FWSafeType

@interface NSMutableSet<ObjectType> (FWSafeType)

/**
 安全添加对象
 
 @param object 对象
 */
- (void)fw_addObject:(nullable ObjectType)object NS_REFINED_FOR_SWIFT;

/**
 安全移除对象
 
 @param object 对象
 */
- (void)fw_removeObject:(nullable ObjectType)object NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSDictionary+FWSafeType

@interface NSDictionary<__covariant KeyType, __covariant ObjectType> (FWSafeType)

/**
 安全读取对象（过滤NSNull）
 
 @param key 键名
 @return 键值
 */
- (nullable ObjectType)fw_objectForKey:(nullable KeyType)key NS_REFINED_FOR_SWIFT;

@end

#pragma mark - NSMutableDictionary+FWSafeType

@interface NSMutableDictionary<KeyType, ObjectType> (FWSafeType)

/**
 安全移除指定键名
 
 @param key 键名
 */
- (void)fw_removeObjectForKey:(nullable KeyType)key NS_REFINED_FOR_SWIFT;

/**
 安全设置对象（过滤NSNull）

 @param object 键值
 @param key 键名
 */
- (void)fw_setObject:(nullable ObjectType)object forKey:(nullable KeyType <NSCopying>)key NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
