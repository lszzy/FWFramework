//
//  Encrypt+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation

extension Wrapper where Base == Data {
    // MARK: - AES
    /// 利用AES加密数据
    public func aesEncrypt(key: String, iv: Data) -> Data? {
        return base.fw_aesEncrypt(key: key, iv: iv)
    }

    /// 利用AES解密数据
    public func aesDecrypt(key: String, iv: Data) -> Data? {
        return base.fw_aesDecrypt(key: key, iv: iv)
    }

    // MARK: - DES
    /// 利用3DES加密数据
    public func des3Encrypt(key: String, iv: Data) -> Data? {
        return base.fw_des3Encrypt(key: key, iv: iv)
    }

    /// 利用3DES解密数据
    public func des3Decrypt(key: String, iv: Data) -> Data? {
        return base.fw_des3Decrypt(key: key, iv: iv)
    }

    // MARK: - RSA
    /// RSA公钥加密，数据传输安全，使用默认标签，执行base64编码
    public func rsaEncrypt(publicKey: String) -> Data? {
        return base.fw_rsaEncrypt(publicKey: publicKey)
    }

    /// RSA公钥加密，数据传输安全，可自定义标签，指定base64编码
    public func rsaEncrypt(publicKey: String, tag: String, base64Encode: Bool) -> Data? {
        return base.fw_rsaEncrypt(publicKey: publicKey, tag: tag, base64Encode: base64Encode)
    }

    /// RSA私钥解密，数据传输安全，使用默认标签，执行base64解密
    public func rsaDecrypt(privateKey: String) -> Data? {
        return base.fw_rsaDecrypt(privateKey: privateKey)
    }

    /// RSA私钥解密，数据传输安全，可自定义标签，指定base64解码
    public func rsaDecrypt(privateKey: String, tag: String, base64Decode: Bool) -> Data? {
        return base.fw_rsaDecrypt(privateKey: privateKey, tag: tag, base64Decode: base64Decode)
    }

    /// RSA私钥加签，防篡改防否认，使用默认标签，执行base64编码
    public func rsaSign(privateKey: String) -> Data? {
        return base.fw_rsaSign(privateKey: privateKey)
    }

    /// RSA私钥加签，防篡改防否认，可自定义标签，指定base64编码
    public func rsaSign(privateKey: String, tag: String, base64Encode: Bool) -> Data? {
        return base.fw_rsaSign(privateKey: privateKey, tag: tag, base64Encode: base64Encode)
    }

    /// RSA公钥验签，防篡改防否认，使用默认标签，执行base64解密
    public func rsaVerify(publicKey: String) -> Data? {
        return base.fw_rsaVerify(publicKey: publicKey)
    }

    /// RSA公钥验签，防篡改防否认，可自定义标签，指定base64解码
    public func rsaVerify(publicKey: String, tag: String, base64Decode: Bool) -> Data? {
        return base.fw_rsaVerify(publicKey: publicKey, tag: tag, base64Decode: base64Decode)
    }
}
