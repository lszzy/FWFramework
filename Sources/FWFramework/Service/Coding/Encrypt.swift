//
//  Encrypt.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import Foundation
import CommonCrypto

@_spi(FW) extension Data {
    // MARK: - AES
    /// 利用AES加密数据
    public func fw_aesEncrypt(key: String, iv: Data) -> Data? {
        guard let keyData = key.data(using: .utf8) as? NSData,
              let encryptedData = NSMutableData(length: (self as NSData).length + kCCBlockSizeAES128) else {
            return nil
        }
        
        var dataMoved: size_t = 0
        let result = CCCrypt(CCOperation(kCCEncrypt),
                             CCAlgorithm(kCCAlgorithmAES128),
                             CCOptions(kCCOptionPKCS7Padding),
                             keyData.bytes,
                             keyData.length,
                             (iv as NSData).bytes,
                             (self as NSData).bytes,
                             (self as NSData).length,
                             encryptedData.mutableBytes,
                             encryptedData.length,
                             &dataMoved)
        
        if result == kCCSuccess {
            encryptedData.length = dataMoved
            return encryptedData as Data
        }
        
        return nil
    }

    /// 利用AES解密数据
    public func fw_aesDecrypt(key: String, iv: Data) -> Data? {
        guard let keyData = key.data(using: .utf8) as? NSData,
              let decryptedData = NSMutableData(length: (self as NSData).length + kCCBlockSizeAES128) else {
            return nil
        }
        
        var dataMoved: size_t = 0
        let result = CCCrypt(CCOperation(kCCDecrypt),
                             CCAlgorithm(kCCAlgorithmAES128),
                             CCOptions(kCCOptionPKCS7Padding),
                             keyData.bytes,
                             keyData.length,
                             (iv as NSData).bytes,
                             (self as NSData).bytes,
                             (self as NSData).length,
                             decryptedData.mutableBytes,
                             decryptedData.length,
                             &dataMoved)
        
        if result == kCCSuccess {
            decryptedData.length = dataMoved
            return decryptedData as Data
        }
        
        return nil
    }

    // MARK: - DES
    /// 利用3DES加密数据
    public func fw_des3Encrypt(key: String, iv: Data) -> Data? {
        guard let keyData = key.data(using: .utf8) as? NSData,
              let encryptedData = NSMutableData(length: (self as NSData).length + kCCBlockSize3DES) else {
            return nil
        }
        
        var dataMoved: size_t = 0
        let result = CCCrypt(CCOperation(kCCEncrypt),
                             CCAlgorithm(kCCAlgorithm3DES),
                             CCOptions(kCCOptionPKCS7Padding),
                             keyData.bytes,
                             keyData.length,
                             (iv as NSData).bytes,
                             (self as NSData).bytes,
                             (self as NSData).length,
                             encryptedData.mutableBytes,
                             encryptedData.length,
                             &dataMoved)
        
        if result == kCCSuccess {
            encryptedData.length = dataMoved
            return encryptedData as Data
        }
        
        return nil
    }

    /// 利用3DES解密数据
    public func fw_des3Decrypt(key: String, iv: Data) -> Data? {
        guard let keyData = key.data(using: .utf8) as? NSData,
              let decryptedData = NSMutableData(length: (self as NSData).length + kCCBlockSize3DES) else {
            return nil
        }
        
        var dataMoved: size_t = 0
        let result = CCCrypt(CCOperation(kCCDecrypt),
                             CCAlgorithm(kCCAlgorithm3DES),
                             CCOptions(kCCOptionPKCS7Padding),
                             keyData.bytes,
                             keyData.length,
                             (iv as NSData).bytes,
                             (self as NSData).bytes,
                             (self as NSData).length,
                             decryptedData.mutableBytes,
                             decryptedData.length,
                             &dataMoved)
        
        if result == kCCSuccess {
            decryptedData.length = dataMoved
            return decryptedData as Data
        }
        
        return nil
    }

    // MARK: - RSA
    /// RSA公钥加密，数据传输安全，使用默认标签，执行base64编码
    public func fw_rsaEncrypt(publicKey: String) -> Data? {
        return fw_rsaEncrypt(publicKey: publicKey, tag: "FWRSA_PublicKey", base64Encode: true)
    }

    /// RSA公钥加密，数据传输安全，可自定义标签，指定base64编码
    public func fw_rsaEncrypt(publicKey: String, tag: String, base64Encode: Bool) -> Data? {
        guard let keyRef = Data.fw_rsaAddPublicKey(key: publicKey, tagName: tag) else { return nil }
        
        let data = Data.fw_rsaEncryptData(data: self, withKeyRef: keyRef, isSign: false)
        return base64Encode ? data?.base64EncodedData() : data
    }

    /// RSA私钥解密，数据传输安全，使用默认标签，执行base64解密
    public func fw_rsaDecrypt(privateKey: String) -> Data? {
        return fw_rsaDecrypt(privateKey: privateKey, tag: "FWRSA_PrivateKey", base64Decode: true)
    }

    /// RSA私钥解密，数据传输安全，可自定义标签，指定base64解码
    public func fw_rsaDecrypt(privateKey: String, tag: String, base64Decode: Bool) -> Data? {
        guard let data = base64Decode ? Data(base64Encoded: self, options: .ignoreUnknownCharacters) : self else { return nil }
        
        guard let keyRef = Data.fw_rsaAddPrivateKey(key: privateKey, tagName: tag) else { return nil }
        return Data.fw_rsaDecryptData(data: data, withKeyRef: keyRef)
    }

    /// RSA私钥加签，防篡改防否认，使用默认标签，执行base64编码
    public func fw_rsaSign(privateKey: String) -> Data? {
        return fw_rsaSign(privateKey: privateKey, tag: "FWRSA_PrivateKey", base64Encode: true)
    }

    /// RSA私钥加签，防篡改防否认，可自定义标签，指定base64编码
    public func fw_rsaSign(privateKey: String, tag: String, base64Encode: Bool) -> Data? {
        guard let keyRef = Data.fw_rsaAddPrivateKey(key: privateKey, tagName: tag) else { return nil }
        
        let data = Data.fw_rsaEncryptData(data: self, withKeyRef: keyRef, isSign: true)
        return base64Encode ? data?.base64EncodedData() : data
    }

    /// RSA公钥验签，防篡改防否认，使用默认标签，执行base64解密
    public func fw_rsaVerify(publicKey: String) -> Data? {
        return fw_rsaVerify(publicKey: publicKey, tag: "FWRSA_PublicKey", base64Decode: true)
    }

    /// RSA公钥验签，防篡改防否认，可自定义标签，指定base64解码
    public func fw_rsaVerify(publicKey: String, tag: String, base64Decode: Bool) -> Data? {
        guard let data = base64Decode ? Data(base64Encoded: self, options: .ignoreUnknownCharacters) : self else { return nil }
        
        guard let keyRef = Data.fw_rsaAddPublicKey(key: publicKey, tagName: tag) else { return nil }
        return Data.fw_rsaDecryptData(data: data, withKeyRef: keyRef)
    }
    
    private static func fw_rsaEncryptData(data: Data, withKeyRef keyRef: SecKey, isSign: Bool) -> Data? {
        let srcbytes = NSData(data: data).bytes
        let srcbuf = srcbytes.bindMemory(to: UInt8.self, capacity: data.count)
        let srclen = data.count
        
        let block_size = SecKeyGetBlockSize(keyRef) * MemoryLayout<UInt8>.size
        var outbuf = [UInt8](repeating: 0, count: block_size)
        let src_block_size = block_size - 11
        
        var ret: Data? = Data()
        for idx in stride(from: 0, to: srclen, by: src_block_size) {
            var data_len = srclen - idx
            if data_len > src_block_size {
                data_len = src_block_size
            }
            
            var outlen = block_size
            var status: OSStatus = noErr
            if isSign {
                status = SecKeyRawSign(keyRef, SecPadding.PKCS1, srcbuf + idx, data_len, &outbuf, &outlen)
            } else {
                status = SecKeyEncrypt(keyRef, SecPadding.PKCS1, srcbuf + idx, data_len, &outbuf, &outlen)
            }
            if status != 0 {
                ret = nil
                break
            } else {
                ret?.append(outbuf, count: outlen)
            }
        }
        
        return ret
    }
    
    private static func fw_rsaDecryptData(data: Data, withKeyRef keyRef: SecKey) -> Data? {
        let srcbytes = NSData(data: data).bytes
        let srcbuf = srcbytes.bindMemory(to: UInt8.self, capacity: data.count)
        let srclen = data.count
        
        let block_size = SecKeyGetBlockSize(keyRef) * MemoryLayout<UInt8>.size
        var outbuf = [UInt8](repeating: 0, count: block_size)
        let src_block_size = block_size
        
        var ret: Data? = Data()
        for idx in stride(from: 0, to: srclen, by: src_block_size) {
            var data_len = srclen - idx
            if data_len > src_block_size {
                data_len = src_block_size
            }
            
            var outlen = block_size
            var status: OSStatus = noErr
            status = SecKeyDecrypt(keyRef, [], srcbuf + idx, data_len, &outbuf, &outlen)
            if status != 0 {
                ret = nil
                break
            } else {
                var idxFirstZero = -1
                var idxNextZero = outlen
                for i in 0..<outlen {
                    if outbuf[i] == 0 {
                        if idxFirstZero < 0 {
                            idxFirstZero = i
                        } else {
                            idxNextZero = i
                            break
                        }
                    }
                }
                ret?.append(contentsOf: outbuf[idxFirstZero + 1..<idxNextZero])
            }
        }
        
        return ret
    }
    
    private static func fw_rsaAddPublicKey(key: String, tagName: String) -> SecKey? {
        let key = key
            .replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\t", with: "")
            .replacingOccurrences(of: " ", with: "")
        guard let data = Data(base64Encoded: key, options: .ignoreUnknownCharacters),
              let data = fw_rsaStripPublicKeyHeader(data) else {
            return nil
        }
        
        var publicKey: [CFString: Any] = [:]
        publicKey[kSecClass] = kSecClassKey
        publicKey[kSecAttrKeyType] = kSecAttrKeyTypeRSA
        publicKey[kSecAttrApplicationTag] = tagName.data(using: .utf8)
        SecItemDelete(publicKey as CFDictionary)
        
        publicKey[kSecValueData] = data
        publicKey[kSecAttrKeyClass] = kSecAttrKeyClassPublic
        publicKey[kSecReturnPersistentRef] = true
        
        var persistKey: CFTypeRef?
        let status = SecItemAdd(publicKey as CFDictionary, &persistKey)
        if status != noErr && status != errSecDuplicateItem {
            return nil
        }
        
        publicKey.removeValue(forKey: kSecValueData)
        publicKey.removeValue(forKey: kSecReturnPersistentRef)
        publicKey[kSecReturnRef] = true
        publicKey[kSecAttrKeyType] = kSecAttrKeyTypeRSA
        
        var keyRef: CFTypeRef?
        let keyStatus = SecItemCopyMatching(publicKey as CFDictionary, &keyRef)
        if keyStatus != noErr {
            return nil
        }
        return keyRef as! SecKey?
    }
    
    private static func fw_rsaAddPrivateKey(key: String, tagName: String) -> SecKey? {
        let key = key
            .replacingOccurrences(of: "-----BEGIN RSA PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END RSA PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\t", with: "")
            .replacingOccurrences(of: " ", with: "")
        guard let data = Data(base64Encoded: key, options: .ignoreUnknownCharacters),
              let data = fw_rsaStripPrivateKeyHeader(data) else {
            return nil
        }

        let tagData = tagName.data(using: .utf8)
        var privateKey: [String: Any] = [:]
        privateKey[kSecClass as String] = kSecClassKey
        privateKey[kSecAttrKeyType as String] = kSecAttrKeyTypeRSA
        privateKey[kSecAttrApplicationTag as String] = tagData
        SecItemDelete(privateKey as CFDictionary)

        privateKey[kSecValueData as String] = data
        privateKey[kSecAttrKeyClass as String] = kSecAttrKeyClassPrivate
        privateKey[kSecReturnPersistentRef as String] = kCFBooleanTrue

        var persistKey: CFTypeRef?
        let status = SecItemAdd(privateKey as CFDictionary, &persistKey)
        if status != noErr && status != errSecDuplicateItem {
            return nil
        }

        privateKey.removeValue(forKey: kSecValueData as String)
        privateKey.removeValue(forKey: kSecReturnPersistentRef as String)
        privateKey[kSecReturnRef as String] = kCFBooleanTrue
        privateKey[kSecAttrKeyType as String] = kSecAttrKeyTypeRSA

        var keyRef: CFTypeRef?
        let keyStatus = SecItemCopyMatching(privateKey as CFDictionary, &keyRef)
        if keyStatus != noErr {
            return nil
        }
        return keyRef as! SecKey?
    }
    
    private static func fw_rsaStripPublicKeyHeader(_ data: Data) -> Data? {
        var idx = 0
        if 0x30 != data[idx] {
            return nil
        }
        idx += 1
        if data[idx] > 0x80 {
            idx += Int(data[idx]) - 0x80 + 1;
        } else {
            idx += 1
        }
        let seqOID = [ 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00 ]
        for i in 0..<15{
            if seqOID[i] != data[idx+i] {
                return nil
            }
        }
        idx += 15
        if data[idx] != 0x03{
            return nil
        }
        idx += 1
        if data[idx] > 0x80 {
            idx += Int(data[idx]) - 0x80 + 1
        } else {
            idx += 1
        }
        if data[idx] != Character("\0").asciiValue{
            return nil
        }
        idx += 1
        return data[idx..<data.count]
    }
    
    private static func fw_rsaStripPrivateKeyHeader(_ data: Data) -> Data? {
        if data.count == 0 {
            return nil
        }
        
        var keyAsArray = [UInt8](repeating: 0, count: data.count / MemoryLayout<UInt8>.size)
        (data as NSData).getBytes(&keyAsArray, length: data.count)
        
        var idx = 22
        if keyAsArray[idx] != 0x04 {
            return nil
        }
        idx += 1
        
        var len = Int(keyAsArray[idx])
        idx += 1
        let det = len & 0x80
        if (det == 0) {
            len = len & 0x7f
        } else {
            var byteCount = Int(len & 0x7f)
            if byteCount + idx > data.count {
                return nil
            }
            var accum: UInt = 0
            var idx2 = idx
            idx += byteCount
            while byteCount > 0 {
                accum = (accum << 8) + UInt(keyAsArray[idx2])
                idx2 += 1
                byteCount -= 1
            }
            len = Int(accum)
        }
        return data.subdata(in: idx..<idx+len)
    }
}
