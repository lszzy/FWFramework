/*!
 @header     NSData+FWFramework.h
 @indexgroup FWFramework
 @brief      NSData+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/17
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief NSData+FWFramework
 */
@interface NSData (FWFramework)

// 使用NSKeyedArchiver压缩对象
+ (nullable NSData *)fwArchiveObject:(id)object;

// 使用NSKeyedUnarchiver解压数据
- (nullable id)fwUnarchiveObject;

// 保存对象归档
+ (void)fwArchiveObject:(id)object toFile:(NSString *)path;

// 读取对象归档
+ (nullable id)fwUnarchiveObjectWithFile:(NSString *)path;

#pragma mark - Encrypt

/**
 *  利用AES加密数据
 *
 *  @param key key
 *  @param iv  iv description
 *
 *  @return data
 */
- (nullable NSData *)fwAESEncryptWithKey:(NSString *)key andIV:(NSData *)iv;
/**
 *  @brief  利用AES解密据
 *
 *  @param key key
 *  @param iv  iv
 *
 *  @return 解密后数据
 */
- (nullable NSData *)fwAESDecryptWithKey:(NSString *)key andIV:(NSData *)iv;

/**
 *  利用3DES加密数据
 *
 *  @param key key
 *  @param iv  iv description
 *
 *  @return data
 */
- (nullable NSData *)fw3DESEncryptWithKey:(NSString *)key andIV:(NSData *)iv;
/**
 *  @brief   利用3DES解密数据
 *
 *  @param key key
 *  @param iv  iv
 *
 *  @return 解密后数据
 */
- (nullable NSData *)fw3DESDecryptWithKey:(NSString *)key andIV:(NSData *)iv;

@end

NS_ASSUME_NONNULL_END
