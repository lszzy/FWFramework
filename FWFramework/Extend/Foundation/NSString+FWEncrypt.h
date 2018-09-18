/*!
 @header     NSString+FWEncrypt.h
 @indexgroup FWFramework
 @brief      NSString+FWEncrypt
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/18
 */

#import <Foundation/Foundation.h>

/*!
 @brief NSString+FWEncrypt
 */
@interface NSString (FWEncrypt)

#pragma mark - Md5

/**
 *  md5编码
 *
 *  @return md5字符串
 */
- (NSString *)fwMd5;

/**
 *  文件md5编码
 *
 *  @return md5字符串
 */
- (NSString *)fwMd5File;

@end

#pragma mark - NSData+FWEncrypt

@interface NSData (FWEncrypt)

/**
 *  利用AES加密数据
 *
 *  @param key key
 *  @param iv  iv description
 *
 *  @return data
 */
- (NSData *)fwAESEncryptWithKey:(NSString *)key andIV:(NSData *)iv;
/**
 *  @brief  利用AES解密据
 *
 *  @param key key
 *  @param iv  iv
 *
 *  @return 解密后数据
 */
- (NSData *)fwAESDecryptWithKey:(NSString *)key andIV:(NSData *)iv;

/**
 *  利用3DES加密数据
 *
 *  @param key key
 *  @param iv  iv description
 *
 *  @return data
 */
- (NSData *)fw3DESEncryptWithKey:(NSString *)key andIV:(NSData *)iv;
/**
 *  @brief   利用3DES解密数据
 *
 *  @param key key
 *  @param iv  iv
 *
 *  @return 解密后数据
 */
- (NSData *)fw3DESDecryptWithKey:(NSString *)key andIV:(NSData *)iv;

@end
