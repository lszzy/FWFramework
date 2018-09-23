/*!
 @header     NSData+FWFramework.h
 @indexgroup FWFramework
 @brief      NSData+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/17
 */

#import <Foundation/Foundation.h>

/*!
 @brief NSData+FWFramework
 */
@interface NSData (FWFramework)

// 使用NSKeyedArchiver压缩对象
+ (NSData *)fwArchiveObject:(id)object;

// 使用NSKeyedUnarchiver解压数据
- (id)fwUnarchiveObject;

// 保存对象归档
+ (void)fwArchiveObject:(id)object toFile:(NSString *)path;

// 读取对象归档
+ (id)fwUnarchiveObjectWithFile:(NSString *)path;

// 转为UTF8字符串
- (NSString *)fwUTF8String;

@end
