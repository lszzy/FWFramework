/**
 @header     FWEncode.h
 @indexgroup FWFramework
      FWEncode
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/9/19
 */

#import "FWWrapper.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWStringWrapper+FWEncode

@interface FWStringWrapper (FWEncode)

#pragma mark - Json

/**
 *  json字符串解码为Foundation对象
 *
 *  @return Foundation对象
 */
- (nullable id)jsonDecode;

#pragma mark - Base64

/**
 *  base64编码
 *
 *  @return base64字符串
 */
- (nullable NSString *)base64Encode;

/**
 *  base64解码
 *
 *  @return 原字符串
 */
- (nullable NSString *)base64Decode;

#pragma mark - Unicode

/**
 *  计算长度，中文为1，英文为0.5
 */
- (NSUInteger)unicodeLength;

/**
 *  截取字符串，中文为1，英文为0.5
 *
 *  @param length 截取长度
 */
- (NSString *)unicodeSubstring:(NSUInteger)length;

/**
 *  Unicode中文编码，将中文转换成Unicode字符串(如\u7E8C)
 *
 *  @return Unicode字符串
 */
- (NSString *)unicodeEncode;

/**
 *  Unicode中文解码，将Unicode字符串(如\u7E8C)转换成中文
 *
 *  @return 中文字符串
 */
- (NSString *)unicodeDecode;

#pragma mark - Url

/**
 *  url参数编码，适用于query参数编码
 *  示例：http://test.com?id=我是中文 =>
 *       http%3A%2F%2Ftest.com%3Fid%3D%E6%88%91%E6%98%AF%E4%B8%AD%E6%96%87
 *
 *  @return url编码字符串
 */
- (nullable NSString *)urlEncodeComponent;

/**
 *  url参数解码，适用于query参数解码
 *  示例：http%3A%2F%2Ftest.com%3Fid%3D%E6%88%91%E6%98%AF%E4%B8%AD%E6%96%87 =>
 *       http://test.com?id=我是中文
 *
 *  @return 原字符串
 */
- (nullable NSString *)urlDecodeComponent;

/**
 *  url编码，适用于整个url编码
 *  示例：http://test.com?id=我是中文 =>
 *       http://test.com?id=%E6%88%91%E6%98%AF%E4%B8%AD%E6%96%87
 *
 *  @return url编码地址
 */
- (nullable NSString *)urlEncode;

/**
 *  url解码，适用于整个url解码
 *  示例：http://test.com?id=%E6%88%91%E6%98%AF%E4%B8%AD%E6%96%87 =>
 *       http://test.com?id=我是中文
 *
 *  @return 原url地址
 */
- (nullable NSString *)urlDecode;

#pragma mark - Query

/**
 * URL参数字符串解码为字典，支持完整URL
 */
- (NSDictionary<NSString *, NSString *> *)queryDecode;

#pragma mark - Md5

/**
 *  md5编码
 *
 *  @return md5字符串
 */
- (NSString *)md5Encode;

/**
 *  文件md5编码
 *
 *  @return md5字符串
 */
- (nullable NSString *)md5EncodeFile;

#pragma mark - Helper

/**
 去掉空白字符
 
 @return trim字符串
 */
@property (nonatomic, copy, readonly) NSString *trimString;

/**
 过滤JSON解码特殊字符
 @note 兼容\uD800-\uDFFF引起JSON解码报错3840问题，不报错时无需调用
 规则：只允许以\uD800-\uDBFF高位开头，紧跟\uDC00-\uDFFF低位；其他全不允许
 参考：https://github.com/SBJson/SBJson/blob/trunk/Classes/SBJson5StreamTokeniser.m
 
 @return JSON过滤字符串
 */
@property (nonatomic, copy, readonly) NSString *escapeJson;

/**
 转换为UTF8编码数据
 
 @return UTF8编码数据
 */
@property (nonatomic, strong, readonly, nullable) NSData *utf8Data;

/**
 转换为NSURL
 
 @return NSURL
 */
@property (nonatomic, copy, readonly, nullable) NSURL *url;

/**
 转换为NSNumber
 
 @return NSNumber
 */
@property (nonatomic, readonly, nullable) NSNumber *number;

@end

#pragma mark - FWStringClassWrapper+FWEncode

@interface FWStringClassWrapper (FWEncode)

#pragma mark - Json

/**
 Foundation对象编码为json字符串
 
 @param object 编码对象
 @return json字符串
 */
- (nullable NSString *)jsonEncode:(id)object;

#pragma mark - Query

/**
 * 字典编码为URL参数字符串
 */
- (NSString *)queryEncode:(NSDictionary<NSString *, id> *)dictionary;

@end

#pragma mark - FWDataWrapper+FWEncode

@interface FWDataWrapper (FWEncode)

#pragma mark - Json

/**
 json数据解码为Foundation对象

 @return Foundation对象
 */
- (nullable id)jsonDecode;

#pragma mark - Base64

/**
 *  base64编码
 *
 *  @return base64数据
 */
- (NSData *)base64Encode;

/**
 *  base64解码
 *
 *  @return 原数据
 */
- (nullable NSData *)base64Decode;

#pragma mark - Helper

/**
 转换为UTF8编码字符串
 
 @return UTF8编码字符串
 */
@property (nonatomic, copy, readonly, nullable) NSString *utf8String;

@end

#pragma mark - FWDataClassWrapper+FWEncode

@interface FWDataClassWrapper (FWEncode)

#pragma mark - Json

/**
 Foundation对象编码为json数据
 
 @param object 编码对象
 @return json数据
 */
- (nullable NSData *)jsonEncode:(id)object;

@end

#pragma mark - FWSafeType

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

#pragma mark - FWObjectWrapper+FWSafeType

@interface FWObjectWrapper (FWSafeType)

/**
 是否是非Null(nil, NSNull)
 
 @return 如果为非Null返回YES，为Null返回NO
 */
@property (nonatomic, assign, readonly) BOOL isNotNull;

/**
 是否是非空对象(nil, NSNull, count为0, length为0)
 
 @return 如果是非空对象返回YES，为空对象返回NO
 */
@property (nonatomic, assign, readonly) BOOL isNotEmpty;

/**
 检测并安全转换为NSInteger
 
 @return NSInteger
 */
@property (nonatomic, assign, readonly) NSInteger safeInteger;

/**
 检测并安全转换为Float
 
 @return Float
 */
@property (nonatomic, assign, readonly) float safeFloat;

/**
 检测并安全转换为Double
 
 @return Double
 */
@property (nonatomic, assign, readonly) double safeDouble;

/**
 检测并安全转换为Bool
 
 @return Bool
 */
@property (nonatomic, assign, readonly) BOOL safeBool;

/**
 检测并安全转换为NSNumber
 
 @return NSNumber
 */
@property (nonatomic, strong, readonly) NSNumber *safeNumber;

/**
 检测并安全转换为NSString
 
 @return NSString
 */
@property (nonatomic, copy, readonly) NSString *safeString;

/**
 检测并安全转换为NSDate
 
 @return NSDate
 */
@property (nonatomic, strong, readonly) NSDate *safeDate;

/**
 检测并安全转换为NSData
 
 @return NSData
 */
@property (nonatomic, strong, readonly) NSData *safeData;

/**
 检测并安全转换为NSArray
 
 @return NSArray
 */
@property (nonatomic, strong, readonly) NSArray *safeArray;

/**
 检测并安全转换为NSMutableArray
 
 @return NSMutableArray
 */
@property (nonatomic, strong, readonly) NSMutableArray *safeMutableArray;

/**
 检测并安全转换为NSDictionary
 
 @return NSDictionary
 */
@property (nonatomic, strong, readonly) NSDictionary *safeDictionary;

/**
 检测并安全转换为NSMutableDictionary
 
 @return NSMutableDictionary
 */
@property (nonatomic, strong, readonly) NSMutableDictionary *safeMutableDictionary;

@end

#pragma mark - FWURLWrapper+FWSafeType

@interface FWURLWrapper (FWSafeType)

/// 获取当前query的参数字典，不含空值
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSString *> *queryDictionary;

/// 获取路径URI字符串，不含host|port等，包含path|query|fragment等
@property (nonatomic, copy, readonly, nullable) NSString *pathURI;

@end

#pragma mark - FWURLClassWrapper+FWSafeType

@interface FWURLClassWrapper (FWSafeType)

/// 生成URL，中文自动URL编码
- (nullable NSURL *)urlWithString:(nullable NSString *)string;

/// 生成URL，中文自动URL编码
- (nullable NSURL *)urlWithString:(nullable NSString *)string relativeTo:(nullable NSURL *)baseURL;

@end

NS_ASSUME_NONNULL_END
