//
//  Bridge.m
//  FWFramework
//
//  Created by wuyong on 2022/11/11.
//

#import "Bridge.h"
#import <sys/sysctl.h>
#import <CommonCrypto/CommonCryptor.h>
#import <Accelerate/Accelerate.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <net/if.h>
#import <dlfcn.h>

#pragma mark - __FWBridge

typedef struct CF_BRIDGED_TYPE(id) CGSVGDocument *CGSVGDocumentRef;
static void (*__FWCGSVGDocumentRelease)(CGSVGDocumentRef);
static CGSVGDocumentRef (*__FWCGSVGDocumentCreateFromData)(CFDataRef data, CFDictionaryRef options);
static void (*__FWCGSVGDocumentWriteToData)(CGSVGDocumentRef document, CFDataRef data, CFDictionaryRef options);
static void (*__FWCGContextDrawSVGDocument)(CGContextRef context, CGSVGDocumentRef document);
static CGSize (*__FWCGSVGDocumentGetCanvasSize)(CGSVGDocumentRef document);
static SEL __FWImageWithCGSVGDocumentSEL = NULL;
static SEL __FWCGSVGDocumentSEL = NULL;

@implementation __FWBridge

+ (NSString *)ipAddress {
    NSString *ipAddr = nil;
    struct ifaddrs *addrs = NULL;
    
    int ret = getifaddrs(&addrs);
    if (0 == ret) {
        const struct ifaddrs * cursor = addrs;
        
        while (cursor) {
            if (AF_INET == cursor->ifa_addr->sa_family && 0 == (cursor->ifa_flags & IFF_LOOPBACK)) {
                ipAddr = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr)];
                break;
            }
            
            cursor = cursor->ifa_next;
        }
        
        freeifaddrs(addrs);
    }
    
    return ipAddr;
}

+ (NSString *)ipAddress:(NSString *)host {
    if ([host hasPrefix:@"http"]) {
        host = [NSURL URLWithString:host].host;
    }
    
    Boolean result, bResolved;
    CFHostRef hostRef;
    CFArrayRef addresses = NULL;
    NSMutableArray *ipsArr = [[NSMutableArray alloc] init];
    CFStringRef hostNameRef = CFStringCreateWithCString(kCFAllocatorDefault, [host cStringUsingEncoding:NSASCIIStringEncoding], kCFStringEncodingASCII);
    
    hostRef = CFHostCreateWithName(kCFAllocatorDefault, hostNameRef);
    result = CFHostStartInfoResolution(hostRef, kCFHostAddresses, NULL);
    if (result == TRUE) {
        addresses = CFHostGetAddressing(hostRef, &result);
    }
    bResolved = result == TRUE ? true : false;
    
    if (bResolved) {
        struct sockaddr_in *remoteAddr;
        for(int i = 0; i < CFArrayGetCount(addresses); i++){
            CFDataRef saData = (CFDataRef)CFArrayGetValueAtIndex(addresses, i);
            remoteAddr = (struct sockaddr_in *)CFDataGetBytePtr(saData);
            if (remoteAddr != NULL) {
                char ip[16];
                strcpy(ip, inet_ntoa(remoteAddr->sin_addr));
                NSString *ipStr = [NSString stringWithCString:ip encoding:NSUTF8StringEncoding];
                [ipsArr addObject:ipStr];
            }
        }
    }
    if (ipsArr.count) {
        return ipsArr[0];
    }
    return nil;
}

+ (NSString *)base64Decode:(NSString *)base64String {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64String options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (!data) return nil;
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (BOOL)svgSupported {
    static BOOL isSupported = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 13.0, *)) {
            __FWCGSVGDocumentRelease = dlsym(RTLD_DEFAULT, [self base64Decode:@"Q0dTVkdEb2N1bWVudFJlbGVhc2U="].UTF8String);
            __FWCGSVGDocumentCreateFromData = dlsym(RTLD_DEFAULT, [self base64Decode:@"Q0dTVkdEb2N1bWVudENyZWF0ZUZyb21EYXRh"].UTF8String);
            __FWCGSVGDocumentWriteToData = dlsym(RTLD_DEFAULT, [self base64Decode:@"Q0dTVkdEb2N1bWVudFdyaXRlVG9EYXRh"].UTF8String);
            __FWCGContextDrawSVGDocument = (void (*)(CGContextRef context, CGSVGDocumentRef document))dlsym(RTLD_DEFAULT, [self base64Decode:@"Q0dDb250ZXh0RHJhd1NWR0RvY3VtZW50"].UTF8String);
            __FWCGSVGDocumentGetCanvasSize = (CGSize (*)(CGSVGDocumentRef document))dlsym(RTLD_DEFAULT, [self base64Decode:@"Q0dTVkdEb2N1bWVudEdldENhbnZhc1NpemU="].UTF8String);
            __FWImageWithCGSVGDocumentSEL = NSSelectorFromString([self base64Decode:@"X2ltYWdlV2l0aENHU1ZHRG9jdW1lbnQ6"]);
            __FWCGSVGDocumentSEL = NSSelectorFromString([self base64Decode:@"X0NHU1ZHRG9jdW1lbnQ="]);
            
            isSupported = [UIImage respondsToSelector:__FWImageWithCGSVGDocumentSEL];
        }
    });
    return isSupported;
}

+ (UIImage *)svgDecode:(NSData *)data thumbnailSize:(CGSize)thumbnailSize {
    if (![self svgSupported]) return nil;
    
    BOOL prefersBitmap = NO;
    CGSize imageSize = CGSizeZero;
    if (!CGSizeEqualToSize(thumbnailSize, CGSizeZero)) {
        prefersBitmap = YES;
        imageSize = thumbnailSize;
    }
    
    if (!prefersBitmap) {
        CGSVGDocumentRef document = __FWCGSVGDocumentCreateFromData((__bridge CFDataRef)data, NULL);
        if (!document) return nil;
        UIImage *image = ((UIImage *(*)(id,SEL,CGSVGDocumentRef))[UIImage.class methodForSelector:__FWImageWithCGSVGDocumentSEL])(UIImage.class, __FWImageWithCGSVGDocumentSEL, document);
        __FWCGSVGDocumentRelease(document);
        
        UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(1, 1)];
        @try {
            __unused UIImage *dummyImage = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
                [image drawInRect:CGRectMake(0, 0, 1, 1)];
            }];
        } @catch (...) {
            return nil;
        }
        return image;
    } else {
        CGSVGDocumentRef document = __FWCGSVGDocumentCreateFromData((__bridge CFDataRef)data, NULL);
        if (!document) {
            return nil;
        }
        CGSize size = __FWCGSVGDocumentGetCanvasSize(document);
        if (size.width == 0 || size.height == 0) {
            return nil;
        }
        
        CGFloat xScale;
        CGFloat yScale;
        if (thumbnailSize.width <= 0 && thumbnailSize.height <= 0) {
            thumbnailSize.width = size.width;
            thumbnailSize.height = size.height;
            xScale = 1;
            yScale = 1;
        } else {
            CGFloat xRatio = thumbnailSize.width / size.width;
            CGFloat yRatio = thumbnailSize.height / size.height;
            if (thumbnailSize.width <= 0) {
                yScale = yRatio;
                xScale = yRatio;
                thumbnailSize.width = size.width * xScale;
            } else if (thumbnailSize.height <= 0) {
                xScale = xRatio;
                yScale = xRatio;
                thumbnailSize.height = size.height * yScale;
            } else {
                xScale = MIN(xRatio, yRatio);
                yScale = MIN(xRatio, yRatio);
                thumbnailSize.width = size.width * xScale;
                thumbnailSize.height = size.height * yScale;
            }
        }
        CGRect rect = CGRectMake(0, 0, size.width, size.height);
        CGRect targetRect = CGRectMake(0, 0, thumbnailSize.width, thumbnailSize.height);
        
        CGAffineTransform scaleTransform = CGAffineTransformMakeScale(xScale, yScale);
        CGAffineTransform transform = CGAffineTransformMakeTranslation((targetRect.size.width / xScale - rect.size.width) / 2, (targetRect.size.height / yScale - rect.size.height) / 2);
        
        UIGraphicsBeginImageContextWithOptions(targetRect.size, NO, 0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextTranslateCTM(context, 0, targetRect.size.height);
        CGContextScaleCTM(context, 1, -1);
        CGContextConcatCTM(context, scaleTransform);
        CGContextConcatCTM(context, transform);
        
        __FWCGContextDrawSVGDocument(context, document);
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        __FWCGSVGDocumentRelease(document);
        return image;
    }
}

+ (NSData *)svgEncode:(UIImage *)image {
    if (![self svgSupported]) return nil;
    
    NSMutableData *data = [NSMutableData data];
    CGSVGDocumentRef document = ((CGSVGDocumentRef (*)(id,SEL))[image methodForSelector:__FWCGSVGDocumentSEL])(image, __FWCGSVGDocumentSEL);
    if (!document) return nil;
    __FWCGSVGDocumentWriteToData(document, (__bridge CFDataRef)data, NULL);
    return [data copy];
}

@end

#pragma mark - __FWEncrypt

@implementation NSData (__FWEncrypt)

- (id)__fw_unarchiveObject:(Class)clazz {
    id object = nil;
    @try {
        object = [NSKeyedUnarchiver unarchivedObjectOfClass:clazz fromData:self error:NULL];
    } @catch (NSException *exception) { }
    return object;
}

- (NSData *)__fw_AESEncryptWithKey:(NSString *)key andIV:(NSData *)iv {
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    
    size_t dataMoved;
    NSMutableData *encryptedData = [NSMutableData dataWithLength:self.length + kCCBlockSizeAES128];
    
    CCCryptorStatus status = CCCrypt(kCCEncrypt,                    // kCCEncrypt or kCCDecrypt
                                     kCCAlgorithmAES128,
                                     kCCOptionPKCS7Padding,         // Padding option for CBC Mode
                                     keyData.bytes,
                                     keyData.length,
                                     iv.bytes,
                                     self.bytes,
                                     self.length,
                                     encryptedData.mutableBytes,    // encrypted data out
                                     encryptedData.length,
                                     &dataMoved);                   // total data moved
    
    if (status == kCCSuccess) {
        encryptedData.length = dataMoved;
        return encryptedData;
    }
    
    return nil;
}

- (NSData *)__fw_AESDecryptWithKey:(NSString *)key andIV:(NSData *)iv {
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    
    size_t dataMoved;
    NSMutableData *decryptedData = [NSMutableData dataWithLength:self.length + kCCBlockSizeAES128];
    
    CCCryptorStatus result = CCCrypt(kCCDecrypt,                    // kCCEncrypt or kCCDecrypt
                                     kCCAlgorithmAES128,
                                     kCCOptionPKCS7Padding,         // Padding option for CBC Mode
                                     keyData.bytes,
                                     keyData.length,
                                     iv.bytes,
                                     self.bytes,
                                     self.length,
                                     decryptedData.mutableBytes,    // encrypted data out
                                     decryptedData.length,
                                     &dataMoved);                   // total data moved
    
    if (result == kCCSuccess) {
        decryptedData.length = dataMoved;
        return decryptedData;
    }
    
    return nil;
}

- (NSData *)__fw_DES3EncryptWithKey:(NSString *)key andIV:(NSData *)iv {
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    
    size_t dataMoved;
    NSMutableData *encryptedData = [NSMutableData dataWithLength:self.length + kCCBlockSize3DES];
    
    CCCryptorStatus result = CCCrypt(kCCEncrypt,                    // kCCEncrypt or kCCDecrypt
                                     kCCAlgorithm3DES,
                                     kCCOptionPKCS7Padding,         // Padding option for CBC Mode
                                     keyData.bytes,
                                     keyData.length,
                                     iv.bytes,
                                     self.bytes,
                                     self.length,
                                     encryptedData.mutableBytes,    // encrypted data out
                                     encryptedData.length,
                                     &dataMoved);                   // total data moved
    
    if (result == kCCSuccess) {
        encryptedData.length = dataMoved;
        return encryptedData;
    }
    
    return nil;
}

- (NSData *)__fw_DES3DecryptWithKey:(NSString *)key andIV:(NSData *)iv {
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    
    size_t dataMoved;
    NSMutableData *decryptedData = [NSMutableData dataWithLength:self.length + kCCBlockSize3DES];
    
    CCCryptorStatus result = CCCrypt(kCCDecrypt,                    // kCCEncrypt or kCCDecrypt
                                     kCCAlgorithm3DES,
                                     kCCOptionPKCS7Padding,         // Padding option for CBC Mode
                                     keyData.bytes,
                                     keyData.length,
                                     iv.bytes,
                                     self.bytes,
                                     self.length,
                                     decryptedData.mutableBytes,    // encrypted data out
                                     decryptedData.length,
                                     &dataMoved);                   // total data moved
    
    if (result == kCCSuccess) {
        decryptedData.length = dataMoved;
        return decryptedData;
    }
    
    return nil;
}

- (NSData *)__fw_RSAEncryptWithPublicKey:(NSString *)publicKey {
    return [self __fw_RSAEncryptWithPublicKey:publicKey andTag:@"FWRSA_PublicKey" base64Encode:YES];
}

- (NSData *)__fw_RSAEncryptWithPublicKey:(NSString *)publicKey andTag:(NSString *)tagName base64Encode:(BOOL)base64Encode {
    if (!publicKey) return nil;
    
    SecKeyRef keyRef = [NSData __fw_RSAAddPublicKey:publicKey andTag:tagName];
    if (!keyRef) return nil;
    
    NSData *data = [NSData __fw_RSAEncryptData:self withKeyRef:keyRef isSign:NO];
    if (data && base64Encode) {
        data = [data base64EncodedDataWithOptions:0];
    }
    return data;
}

- (NSData *)__fw_RSADecryptWithPrivateKey:(NSString *)privateKey {
    return [self __fw_RSADecryptWithPrivateKey:privateKey andTag:@"FWRSA_PrivateKey" base64Decode:YES];
}

- (NSData *)__fw_RSADecryptWithPrivateKey:(NSString *)privateKey andTag:(NSString *)tagName base64Decode:(BOOL)base64Decode {
    NSData *data = self;
    if (base64Decode) {
        data = [[NSData alloc] initWithBase64EncodedData:data options:NSDataBase64DecodingIgnoreUnknownCharacters];
    }
    if (!data || !privateKey) return nil;
    
    SecKeyRef keyRef = [NSData __fw_RSAAddPrivateKey:privateKey andTag:tagName];
    if (!keyRef) return nil;
    
    return [NSData __fw_RSADecryptData:data withKeyRef:keyRef];
}

- (NSData *)__fw_RSASignWithPrivateKey:(NSString *)privateKey {
    return [self __fw_RSASignWithPrivateKey:privateKey andTag:@"FWRSA_PrivateKey" base64Encode:YES];
}

- (NSData *)__fw_RSASignWithPrivateKey:(NSString *)privateKey andTag:(NSString *)tagName base64Encode:(BOOL)base64Encode {
    if (!privateKey) return nil;
    
    SecKeyRef keyRef = [NSData __fw_RSAAddPrivateKey:privateKey andTag:tagName];
    if (!keyRef) return nil;
    
    NSData *data = [NSData __fw_RSAEncryptData:self withKeyRef:keyRef isSign:YES];
    if (data && base64Encode) {
        data = [data base64EncodedDataWithOptions:0];
    }
    return data;
}

- (NSData *)__fw_RSAVerifyWithPublicKey:(NSString *)publicKey {
    return [self __fw_RSAVerifyWithPublicKey:publicKey andTag:@"FWRSA_PublicKey" base64Decode:YES];
}

- (NSData *)__fw_RSAVerifyWithPublicKey:(NSString *)publicKey andTag:(NSString *)tagName base64Decode:(BOOL)base64Decode {
    NSData *data = self;
    if (base64Decode) {
        data = [[NSData alloc] initWithBase64EncodedData:data options:NSDataBase64DecodingIgnoreUnknownCharacters];
    }
    if (!data || !publicKey) return nil;
    
    SecKeyRef keyRef = [NSData __fw_RSAAddPublicKey:publicKey andTag:tagName];
    if (!keyRef) return nil;
    
    return [NSData __fw_RSADecryptData:data withKeyRef:keyRef];
}

+ (NSData *)__fw_RSAEncryptData:(NSData *)data withKeyRef:(SecKeyRef) keyRef isSign:(BOOL)isSign {
    const uint8_t *srcbuf = (const uint8_t *)[data bytes];
    size_t srclen = (size_t)data.length;
    
    size_t block_size = SecKeyGetBlockSize(keyRef) * sizeof(uint8_t);
    void *outbuf = malloc(block_size);
    size_t src_block_size = block_size - 11;
    
    NSMutableData *ret = [[NSMutableData alloc] init];
    for (int idx = 0; idx < srclen; idx += src_block_size) {
        size_t data_len = srclen - idx;
        if (data_len > src_block_size) {
            data_len = src_block_size;
        }
        
        size_t outlen = block_size;
        OSStatus status = noErr;
        
        if (isSign) {
            status = SecKeyRawSign(keyRef,
                                   kSecPaddingPKCS1,
                                   srcbuf + idx,
                                   data_len,
                                   outbuf,
                                   &outlen
                                   );
        } else {
            status = SecKeyEncrypt(keyRef,
                                   kSecPaddingPKCS1,
                                   srcbuf + idx,
                                   data_len,
                                   outbuf,
                                   &outlen
                                   );
        }
        if (status != 0) {
            ret = nil;
            break;
        } else {
            [ret appendBytes:outbuf length:outlen];
        }
    }
    
    free(outbuf);
    CFRelease(keyRef);
    return ret;
}

+ (NSData *)__fw_RSADecryptData:(NSData *)data withKeyRef:(SecKeyRef)keyRef {
    const uint8_t *srcbuf = (const uint8_t *)[data bytes];
    size_t srclen = (size_t)data.length;
    
    size_t block_size = SecKeyGetBlockSize(keyRef) * sizeof(uint8_t);
    UInt8 *outbuf = malloc(block_size);
    size_t src_block_size = block_size;
    
    NSMutableData *ret = [[NSMutableData alloc] init];
    for (int idx = 0; idx < srclen; idx += src_block_size) {
        size_t data_len = srclen - idx;
        if (data_len > src_block_size) {
            data_len = src_block_size;
        }
        
        size_t outlen = block_size;
        OSStatus status = noErr;
        status = SecKeyDecrypt(keyRef,
                               kSecPaddingNone,
                               srcbuf + idx,
                               data_len,
                               outbuf,
                               &outlen
                               );
        if (status != 0) {
            ret = nil;
            break;
        } else {
            int idxFirstZero = -1;
            int idxNextZero = (int)outlen;
            for (int i = 0; i < outlen; i++) {
                if (outbuf[i] == 0) {
                    if (idxFirstZero < 0) {
                        idxFirstZero = i;
                    } else {
                        idxNextZero = i;
                        break;
                    }
                }
            }
            [ret appendBytes:&outbuf[idxFirstZero + 1] length:idxNextZero - idxFirstZero - 1];
        }
    }
    
    free(outbuf);
    CFRelease(keyRef);
    return ret;
}

+ (SecKeyRef)__fw_RSAAddPublicKey:(NSString *)key andTag:(NSString *)tagName {
    NSRange spos = [key rangeOfString:@"-----BEGIN PUBLIC KEY-----"];
    NSRange epos = [key rangeOfString:@"-----END PUBLIC KEY-----"];
    if (spos.location != NSNotFound && epos.location != NSNotFound) {
        NSUInteger s = spos.location + spos.length;
        NSUInteger e = epos.location;
        NSRange range = NSMakeRange(s, e-s);
        key = [key substringWithRange:range];
    }
    key = [key stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@" "  withString:@""];
    
    NSData *data = [[NSData alloc] initWithBase64EncodedString:key options:NSDataBase64DecodingIgnoreUnknownCharacters];
    data = [self __fw_RSAStripPublicKeyHeader:data];
    if (!data) {
        return nil;
    }

    NSData *tagData = [NSData dataWithBytes:[tagName UTF8String] length:[tagName length]];
    NSMutableDictionary *publicKey = [[NSMutableDictionary alloc] init];
    [publicKey setObject:(__bridge id) kSecClassKey forKey:(__bridge id)kSecClass];
    [publicKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [publicKey setObject:tagData forKey:(__bridge id)kSecAttrApplicationTag];
    SecItemDelete((__bridge CFDictionaryRef)publicKey);
    
    [publicKey setObject:data forKey:(__bridge id)kSecValueData];
    [publicKey setObject:(__bridge id) kSecAttrKeyClassPublic forKey:(__bridge id)kSecAttrKeyClass];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnPersistentRef];
    
    CFTypeRef persistKey = nil;
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)publicKey, &persistKey);
    if (persistKey != nil) {
        CFRelease(persistKey);
    }
    if ((status != noErr) && (status != errSecDuplicateItem)) {
        return nil;
    }

    [publicKey removeObjectForKey:(__bridge id)kSecValueData];
    [publicKey removeObjectForKey:(__bridge id)kSecReturnPersistentRef];
    [publicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
    [publicKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    
    SecKeyRef keyRef = nil;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)publicKey, (CFTypeRef *)&keyRef);
    if (status != noErr) {
        return nil;
    }
    return keyRef;
}

+ (SecKeyRef)__fw_RSAAddPrivateKey:(NSString *)key andTag:(NSString *)tagName {
    NSRange spos;
    NSRange epos;
    spos = [key rangeOfString:@"-----BEGIN RSA PRIVATE KEY-----"];
    if (spos.length > 0) {
        epos = [key rangeOfString:@"-----END RSA PRIVATE KEY-----"];
    } else {
        spos = [key rangeOfString:@"-----BEGIN PRIVATE KEY-----"];
        epos = [key rangeOfString:@"-----END PRIVATE KEY-----"];
    }
    if (spos.location != NSNotFound && epos.location != NSNotFound) {
        NSUInteger s = spos.location + spos.length;
        NSUInteger e = epos.location;
        NSRange range = NSMakeRange(s, e-s);
        key = [key substringWithRange:range];
    }
    key = [key stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@" "  withString:@""];

    NSData *data = [[NSData alloc] initWithBase64EncodedString:key options:NSDataBase64DecodingIgnoreUnknownCharacters];
    data = [self __fw_RSAStripPrivateKeyHeader:data];
    if (!data) {
        return nil;
    }

    NSData *tagData = [NSData dataWithBytes:[tagName UTF8String] length:[tagName length]];
    NSMutableDictionary *privateKey = [[NSMutableDictionary alloc] init];
    [privateKey setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [privateKey setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [privateKey setObject:tagData forKey:(__bridge id)kSecAttrApplicationTag];
    SecItemDelete((__bridge CFDictionaryRef)privateKey);

    [privateKey setObject:data forKey:(__bridge id)kSecValueData];
    [privateKey setObject:(__bridge id) kSecAttrKeyClassPrivate forKey:(__bridge id)kSecAttrKeyClass];
    [privateKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnPersistentRef];

    CFTypeRef persistKey = nil;
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)privateKey, &persistKey);
    if (persistKey != nil) {
        CFRelease(persistKey);
    }
    if ((status != noErr) && (status != errSecDuplicateItem)) {
        return nil;
    }

    [privateKey removeObjectForKey:(__bridge id)kSecValueData];
    [privateKey removeObjectForKey:(__bridge id)kSecReturnPersistentRef];
    [privateKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
    [privateKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];

    SecKeyRef keyRef = nil;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)privateKey, (CFTypeRef *)&keyRef);
    if (status != noErr) {
        return nil;
    }
    return keyRef;
}

+ (NSData *)__fw_RSAStripPublicKeyHeader:(NSData *)d_key {
    if (d_key == nil) return nil;
    unsigned long len = [d_key length];
    if (!len) return nil;
    
    unsigned char *c_key = (unsigned char *)[d_key bytes];
    unsigned int  idx    = 0;
    if (c_key[idx++] != 0x30) return nil;
    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
    else idx++;

    static unsigned char seqiod[] = { 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00 };
    if (memcmp(&c_key[idx], seqiod, 15)) return nil;
    
    idx += 15;
    if (c_key[idx++] != 0x03) return nil;
    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
    else idx++;
    if (c_key[idx++] != '\0') return nil;
    return([NSData dataWithBytes:&c_key[idx] length:len - idx]);
}

+ (NSData *)__fw_RSAStripPrivateKeyHeader:(NSData *)d_key {
    if (d_key == nil) return nil;
    unsigned long len = [d_key length];
    if (!len) return nil;

    unsigned char *c_key = (unsigned char *)[d_key bytes];
    unsigned int  idx     = 22;
    if (0x04 != c_key[idx++]) return d_key;

    unsigned int c_len = c_key[idx++];
    int det = c_len & 0x80;
    if (!det) {
        c_len = c_len & 0x7f;
    } else {
        int byteCount = c_len & 0x7f;
        if (byteCount + idx > len) {
            return nil;
        }
        unsigned int accum = 0;
        unsigned char *ptr = &c_key[idx];
        idx += byteCount;
        while (byteCount) {
            accum = (accum << 8) + *ptr;
            ptr++;
            byteCount--;
        }
        c_len = accum;
    }
    return [d_key subdataWithRange:NSMakeRange(idx, c_len)];
}

@end

#pragma mark - UIImage+__FWBridge

@implementation UIImage (__FWBridge)

- (UIImage *)__fw_maskImage {
    NSInteger width = CGImageGetWidth(self.CGImage);
    NSInteger height = CGImageGetHeight(self.CGImage);
    
    NSInteger bytesPerRow = ((width + 3) / 4) * 4;
    void *data = calloc(bytesPerRow * height, sizeof(unsigned char *));
    CGContextRef context = CGBitmapContextCreate(data, width, height, 8, bytesPerRow, NULL, kCGImageAlphaOnly);
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), self.CGImage);
    
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            NSInteger index = y * bytesPerRow + x;
            ((unsigned char *)data)[index] = 255 - ((unsigned char *)data)[index];
        }
    }
    
    CGImageRef maskRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    UIImage *mask = [UIImage imageWithCGImage:maskRef];
    CGImageRelease(maskRef);
    free(data);
    
    return mask;
}

- (UIImage *)__fw_imageWithBlurRadius:(CGFloat)blurRadius saturationDelta:(CGFloat)saturationDelta tintColor:(UIColor *)tintColor maskImage:(UIImage *)maskImage {
    if (self.size.width < 1 || self.size.height < 1) {
        return nil;
    }
    if (!self.CGImage) {
        return nil;
    }
    if (maskImage && !maskImage.CGImage) {
        return nil;
    }
    
    CGRect imageRect = { CGPointZero, self.size };
    UIImage *effectImage = self;
    
    BOOL hasBlur = blurRadius > __FLT_EPSILON__;
    BOOL hasSaturationChange = fabs(saturationDelta - 1.) > __FLT_EPSILON__;
    if (hasBlur || hasSaturationChange) {
        UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
        CGContextRef effectInContext = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(effectInContext, 1.0, -1.0);
        CGContextTranslateCTM(effectInContext, 0, -self.size.height);
        CGContextDrawImage(effectInContext, imageRect, self.CGImage);
        
        vImage_Buffer effectInBuffer;
        effectInBuffer.data     = CGBitmapContextGetData(effectInContext);
        effectInBuffer.width    = CGBitmapContextGetWidth(effectInContext);
        effectInBuffer.height   = CGBitmapContextGetHeight(effectInContext);
        effectInBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectInContext);
        
        UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
        CGContextRef effectOutContext = UIGraphicsGetCurrentContext();
        vImage_Buffer effectOutBuffer;
        effectOutBuffer.data     = CGBitmapContextGetData(effectOutContext);
        effectOutBuffer.width    = CGBitmapContextGetWidth(effectOutContext);
        effectOutBuffer.height   = CGBitmapContextGetHeight(effectOutContext);
        effectOutBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectOutContext);
        
        if (hasBlur) {
            // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
            CGFloat inputRadius = blurRadius * [[UIScreen mainScreen] scale];
            uint32_t radius = floor(inputRadius * 3. * sqrt(2 * M_PI) / 4 + 0.5);
            if (radius % 2 != 1) {
                radius += 1;
            }
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
        }
        BOOL effectImageBuffersAreSwapped = NO;
        if (hasSaturationChange) {
            CGFloat s = saturationDelta;
            CGFloat floatingPointSaturationMatrix[] = {
                0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
                0,                    0,                    0,  1,
            };
            const int32_t divisor = 256;
            NSUInteger matrixSize = sizeof(floatingPointSaturationMatrix)/sizeof(floatingPointSaturationMatrix[0]);
            int16_t saturationMatrix[matrixSize];
            for (NSUInteger i = 0; i < matrixSize; ++i) {
                saturationMatrix[i] = (int16_t)roundf(floatingPointSaturationMatrix[i] * divisor);
            }
            if (hasBlur) {
                vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
                effectImageBuffersAreSwapped = YES;
            }
            else {
                vImageMatrixMultiply_ARGB8888(&effectInBuffer, &effectOutBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
            }
        }
        if (!effectImageBuffersAreSwapped)
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        if (effectImageBuffersAreSwapped)
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    CGContextRef outputContext = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(outputContext, 1.0, -1.0);
    CGContextTranslateCTM(outputContext, 0, -self.size.height);
    CGContextDrawImage(outputContext, imageRect, self.CGImage);
    
    if (hasBlur) {
        CGContextSaveGState(outputContext);
        if (maskImage) {
            CGContextClipToMask(outputContext, imageRect, maskImage.CGImage);
        }
        CGContextDrawImage(outputContext, imageRect, effectImage.CGImage);
        CGContextRestoreGState(outputContext);
    }
    
    if (tintColor) {
        CGContextSaveGState(outputContext);
        CGContextSetFillColorWithColor(outputContext, tintColor.CGColor);
        CGContextFillRect(outputContext, imageRect);
        CGContextRestoreGState(outputContext);
    }
    
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return outputImage;
}

@end

#pragma mark - UIImageView+__FWBridge

@implementation UIImageView (__FWBridge)

- (void)__fw_faceAware {
    if (self.image == nil) {
        return;
    }
    
    [self __fw_faceDetect:self.image];
}

- (void)__fw_faceDetect:(UIImage *)aImage {
    static CIDetector *_faceDetector = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                           context:nil
                                           options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
    });
    
    __weak UIImageView *weakBase = self;
    dispatch_queue_t queue = dispatch_queue_create("site.wuyong.queue.uikit.face", NULL);
    dispatch_async(queue, ^{
        CIImage *image = aImage.CIImage;
        if (image == nil) {
            image = [CIImage imageWithCGImage:aImage.CGImage];
        }
        
        NSArray *features = [_faceDetector featuresInImage:image];
        if (features.count == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[weakBase __fw_faceLayer:NO] removeFromSuperlayer];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakBase __fw_faceMark:features size:CGSizeMake(CGImageGetWidth(aImage.CGImage), CGImageGetHeight(aImage.CGImage))];
            });
        }
    });
}

- (void)__fw_faceMark:(NSArray *)features size:(CGSize)size {
    CGRect fixedRect = CGRectMake(MAXFLOAT, MAXFLOAT, 0, 0);
    CGFloat rightBorder = 0, bottomBorder = 0;
    for (CIFaceFeature *f in features){
        CGRect oneRect = f.bounds;
        oneRect.origin.y = size.height - oneRect.origin.y - oneRect.size.height;
        
        fixedRect.origin.x = MIN(oneRect.origin.x, fixedRect.origin.x);
        fixedRect.origin.y = MIN(oneRect.origin.y, fixedRect.origin.y);
        
        rightBorder = MAX(oneRect.origin.x + oneRect.size.width, rightBorder);
        bottomBorder = MAX(oneRect.origin.y + oneRect.size.height, bottomBorder);
    }
    
    fixedRect.size.width = rightBorder - fixedRect.origin.x;
    fixedRect.size.height = bottomBorder - fixedRect.origin.y;
    
    CGPoint fixedCenter = CGPointMake(fixedRect.origin.x + fixedRect.size.width / 2.0,
                                      fixedRect.origin.y + fixedRect.size.height / 2.0);
    CGPoint offset = CGPointZero;
    CGSize finalSize = size;
    if (size.width / size.height > self.bounds.size.width / self.bounds.size.height) {
        finalSize.height = self.bounds.size.height;
        finalSize.width = size.width/size.height * finalSize.height;
        fixedCenter.x = finalSize.width / size.width * fixedCenter.x;
        fixedCenter.y = finalSize.width / size.width * fixedCenter.y;
        
        offset.x = fixedCenter.x - self.bounds.size.width * 0.5;
        if (offset.x < 0) {
            offset.x = 0;
        } else if (offset.x + self.bounds.size.width > finalSize.width) {
            offset.x = finalSize.width - self.bounds.size.width;
        }
        offset.x = - offset.x;
    } else {
        finalSize.width = self.bounds.size.width;
        finalSize.height = size.height/size.width * finalSize.width;
        fixedCenter.x = finalSize.width / size.width * fixedCenter.x;
        fixedCenter.y = finalSize.width / size.width * fixedCenter.y;
        
        offset.y = fixedCenter.y - self.bounds.size.height * (1 - 0.618);
        if (offset.y < 0) {
            offset.y = 0;
        } else if (offset.y + self.bounds.size.height > finalSize.height){
            offset.y = finalSize.height - self.bounds.size.height;
        }
        offset.y = - offset.y;
    }
    
    CALayer *layer = [self __fw_faceLayer:YES];
    layer.frame = CGRectMake(offset.x, offset.y, finalSize.width, finalSize.height);
    layer.contents = (id)self.image.CGImage;
}

- (CALayer *)__fw_faceLayer:(BOOL)lazyload {
    for (CALayer *layer in self.layer.sublayers) {
        if ([@"FWFaceLayer" isEqualToString:layer.name]) {
            return layer;
        }
    }
    
    if (lazyload) {
        CALayer *layer = [CALayer layer];
        layer.name = @"FWFaceLayer";
        layer.actions = @{
                          @"contents": [NSNull null],
                          @"bounds": [NSNull null],
                          @"position": [NSNull null],
                          };
        [self.layer addSublayer:layer];
        return layer;
    }
    
    return nil;
}

@end

#pragma mark - __FWInputTarget

@interface __FWInputTarget ()

@property (nonatomic, weak, nullable, readonly) UITextField *textField;

@end

@implementation __FWInputTarget

- (instancetype)initWithTextInput:(UIView<UITextInput> *)textInput {
    self = [super init];
    if (self) {
        _textInput = textInput;
        _autoCompleteInterval = 0.5;
    }
    return self;
}

+ (NSUInteger)unicodeLength:(NSString *)text {
    NSUInteger strLength = 0;
    for (int i = 0; i < text.length; i++) {
        if ([text characterAtIndex:i] > 0xff) {
            strLength += 2;
        } else {
            strLength ++;
        }
    }
    return ceil(strLength / 2.0);
}

+ (NSString *)unicodeSubstring:(NSString *)text length:(NSUInteger)length {
    length = length * 2;
    int i = 0;
    int len = 0;
    while (i < text.length) {
        if ([text characterAtIndex:i] > 0xff) {
            len += 2;
        } else {
            len++;
        }
        
        i++;
        if (i >= text.length) {
            return text;
        }
        
        if (len == length) {
            return [text substringToIndex:i];
        } else if (len > length) {
            if (i - 1 <= 0) {
                return @"";
            }
            
            return [text substringToIndex:i - 1];
        }
    }
    return text;
}

- (UITextField *)textField {
    return (UITextField *)self.textInput;
}

- (void)setAutoCompleteInterval:(NSTimeInterval)interval {
    _autoCompleteInterval = interval > 0 ? interval : 0.5;
}

- (void)textLengthChanged {
    if (self.maxLength > 0) {
        if (self.textInput.markedTextRange) {
            if (![self.textInput positionFromPosition:self.textInput.markedTextRange.start offset:0]) {
                if (self.textField.text.length > self.maxLength) {
                    // 获取maxLength处的整个字符range，并截取掉整个字符，防止半个Emoji
                    NSRange maxRange = [self.textField.text rangeOfComposedCharacterSequenceAtIndex:self.maxLength];
                    self.textField.text = [self.textField.text substringToIndex:maxRange.location];
                    // 此方法会导致末尾出现半个Emoji
                    // self.textField.text = [self.textField.text substringToIndex:self.maxLength];
                }
            }
        } else {
            if (self.textField.text.length > self.maxLength) {
                // 获取fwMaxLength处的整个字符range，并截取掉整个字符，防止半个Emoji
                NSRange maxRange = [self.textField.text rangeOfComposedCharacterSequenceAtIndex:self.maxLength];
                self.textField.text = [self.textField.text substringToIndex:maxRange.location];
                // 此方法会导致末尾出现半个Emoji
                // self.textField.text = [self.textField.text substringToIndex:self.maxLength];
            }
        }
    }
    
    if (self.maxUnicodeLength > 0) {
        if (self.textInput.markedTextRange) {
            if (![self.textInput positionFromPosition:self.textInput.markedTextRange.start offset:0]) {
                if ([__FWInputTarget unicodeLength:self.textField.text] > self.maxUnicodeLength) {
                    self.textField.text = [__FWInputTarget unicodeSubstring:self.textField.text length:self.maxUnicodeLength];
                }
            }
        } else {
            if ([__FWInputTarget unicodeLength:self.textField.text] > self.maxUnicodeLength) {
                self.textField.text = [__FWInputTarget unicodeSubstring:self.textField.text length:self.maxUnicodeLength];
            }
        }
    }
}

- (NSString *)filterText:(NSString *)text {
    NSString *filterText = text;
    
    if (self.maxLength > 0) {
        if (self.textInput.markedTextRange) {
            if (![self.textInput positionFromPosition:self.textInput.markedTextRange.start offset:0]) {
                if (filterText.length > self.maxLength) {
                    // 获取maxLength处的整个字符range，并截取掉整个字符，防止半个Emoji
                    NSRange maxRange = [filterText rangeOfComposedCharacterSequenceAtIndex:self.maxLength];
                    filterText = [filterText substringToIndex:maxRange.location];
                    // 此方法会导致末尾出现半个Emoji
                    // filterText = [filterText substringToIndex:self.maxLength];
                }
            }
        } else {
            if (filterText.length > self.maxLength) {
                // 获取fwMaxLength处的整个字符range，并截取掉整个字符，防止半个Emoji
                NSRange maxRange = [filterText rangeOfComposedCharacterSequenceAtIndex:self.maxLength];
                filterText = [filterText substringToIndex:maxRange.location];
                // 此方法会导致末尾出现半个Emoji
                // filterText = [filterText substringToIndex:self.maxLength];
            }
        }
    }
    
    if (self.maxUnicodeLength > 0) {
        if (self.textInput.markedTextRange) {
            if (![self.textInput positionFromPosition:self.textInput.markedTextRange.start offset:0]) {
                if ([__FWInputTarget unicodeLength:filterText] > self.maxUnicodeLength) {
                    filterText = [__FWInputTarget unicodeSubstring:filterText length:self.maxUnicodeLength];
                }
            }
        } else {
            if ([__FWInputTarget unicodeLength:filterText] > self.maxUnicodeLength) {
                filterText = [__FWInputTarget unicodeSubstring:filterText length:self.maxUnicodeLength];
            }
        }
    }
    
    return filterText;
}

- (void)textChangedAction {
    [self textLengthChanged];
    
    if (self.textChangedBlock) {
        NSString *inputText = [self.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        self.textChangedBlock(inputText ?: @"");
    }
    
    if (self.autoCompleteBlock) {
        self.autoCompleteTimestamp = [[NSDate date] timeIntervalSince1970];
        NSString *inputText = [self.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (inputText.length < 1) {
            self.autoCompleteBlock(@"");
        } else {
            NSTimeInterval currentTimestamp = self.autoCompleteTimestamp;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.autoCompleteInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (currentTimestamp == self.autoCompleteTimestamp) {
                    self.autoCompleteBlock(inputText);
                }
            });
        }
    }
}

@end
