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

/// 使用NSKeyedArchiver压缩对象
+ (nullable NSData *)fwArchiveObject:(id)object;

/// 使用NSKeyedUnarchiver解压数据
- (nullable id)fwUnarchiveObject;

/// 保存对象归档
+ (void)fwArchiveObject:(id)object toFile:(NSString *)path;

/// 读取对象归档
+ (nullable id)fwUnarchiveObjectWithFile:(NSString *)path;

#pragma mark - Encrypt

/// 利用AES加密数据
- (nullable NSData *)fwAESEncryptWithKey:(NSString *)key andIV:(NSData *)iv;

/// 利用AES解密数据
- (nullable NSData *)fwAESDecryptWithKey:(NSString *)key andIV:(NSData *)iv;

/// 利用3DES加密数据
- (nullable NSData *)fw3DESEncryptWithKey:(NSString *)key andIV:(NSData *)iv;

/// 利用3DES解密数据
- (nullable NSData *)fw3DESDecryptWithKey:(NSString *)key andIV:(NSData *)iv;

#pragma mark - RSA

/// RSA公钥加密，使用默认标签，执行base64编码
- (nullable NSData *)fwRSAEncryptWithPublicKey:(NSString *)publicKey;

/// RSA公钥加密，可自定义标签，指定base64编码
- (nullable NSData *)fwRSAEncryptWithPublicKey:(NSString *)publicKey andTag:(NSString *)tagName base64Encode:(BOOL)base64Encode;

/// RSA私钥解密，使用默认标签，执行base64解密
- (nullable NSData *)fwRSADecryptWithPrivateKey:(NSString *)privateKey;

/// RSA私钥解密，可自定义标签，指定base64解码
- (nullable NSData *)fwRSADecryptWithPrivateKey:(NSString *)privateKey andTag:(NSString *)tagName base64Decode:(BOOL)base64Decode;

/// RSA私钥加签，使用默认标签，执行base64编码
- (nullable NSData *)fwRSASignWithPrivateKey:(NSString *)privateKey;

/// RSA私钥加签，可自定义标签，指定base64编码
- (nullable NSData *)fwRSASignWithPrivateKey:(NSString *)privateKey andTag:(NSString *)tagName base64Encode:(BOOL)base64Encode;

/// RSA公钥验签，使用默认标签，执行base64解密
- (nullable NSData *)fwRSAVerifyWithPublicKey:(NSString *)publicKey;

/// RSA公钥验签，可自定义标签，指定base64解码
- (nullable NSData *)fwRSAVerifyWithPublicKey:(NSString *)publicKey andTag:(NSString *)tagName base64Decode:(BOOL)base64Decode;

@end

NS_ASSUME_NONNULL_END
