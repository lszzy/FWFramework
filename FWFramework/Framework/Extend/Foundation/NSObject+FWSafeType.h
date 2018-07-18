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
