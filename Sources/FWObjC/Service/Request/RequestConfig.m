//
//  RequestConfig.m
//
//  Copyright (c) 2012-2016 FWNetwork https://github.com/yuantiku
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "RequestConfig.h"
#import "BaseRequest.h"
#import "SecurityPolicy.h"
#import "ObjC.h"
#import <CommonCrypto/CommonDigest.h>
#import <objc/runtime.h>

@implementation __FWRequestConfig {
    NSMutableArray<id<__FWUrlFilterProtocol>> *_urlFilters;
    NSMutableArray<id<__FWCacheDirPathFilterProtocol>> *_cacheDirPathFilters;
}

+ (__FWRequestConfig *)sharedConfig {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _baseUrl = @"";
        _cdnUrl = @"";
        _urlFilters = [NSMutableArray array];
        _cacheDirPathFilters = [NSMutableArray array];
        _securityPolicy = [__FWSecurityPolicy defaultPolicy];
        _removeNullValues = YES;
        #ifdef DEBUG
        _debugLogEnabled = YES;
        #else
        _debugLogEnabled = NO;
        #endif
        _debugMockEnabled = NO;
    }
    return self;
}

- (void)addUrlFilter:(id<__FWUrlFilterProtocol>)filter {
    [_urlFilters addObject:filter];
}

- (void)clearUrlFilter {
    [_urlFilters removeAllObjects];
}

- (void)addCacheDirPathFilter:(id<__FWCacheDirPathFilterProtocol>)filter {
    [_cacheDirPathFilters addObject:filter];
}

- (void)clearCacheDirPathFilter {
    [_cacheDirPathFilters removeAllObjects];
}

- (NSArray<id<__FWUrlFilterProtocol>> *)urlFilters {
    return [_urlFilters copy];
}

- (NSArray<id<__FWCacheDirPathFilterProtocol>> *)cacheDirPathFilters {
    return [_cacheDirPathFilters copy];
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p>{ baseURL: %@ } { cdnURL: %@ }", NSStringFromClass([self class]), self, self.baseUrl, self.cdnUrl];
}

@end

@implementation __FWNetworkUtils

+ (BOOL)validateJSON:(id)json withValidator:(id)jsonValidator {
    if ([json isKindOfClass:[NSDictionary class]] &&
        [jsonValidator isKindOfClass:[NSDictionary class]]) {
        NSDictionary * dict = json;
        NSDictionary * validator = jsonValidator;
        BOOL result = YES;
        NSEnumerator * enumerator = [validator keyEnumerator];
        NSString * key;
        while ((key = [enumerator nextObject]) != nil) {
            id value = dict[key];
            id format = validator[key];
            if ([value isKindOfClass:[NSDictionary class]]
                || [value isKindOfClass:[NSArray class]]) {
                result = [self validateJSON:value withValidator:format];
                if (!result) {
                    break;
                }
            } else {
                if ([value isKindOfClass:format] == NO &&
                    [value isKindOfClass:[NSNull class]] == NO) {
                    result = NO;
                    break;
                }
            }
        }
        return result;
    } else if ([json isKindOfClass:[NSArray class]] &&
               [jsonValidator isKindOfClass:[NSArray class]]) {
        NSArray * validatorArray = (NSArray *)jsonValidator;
        if (validatorArray.count > 0) {
            NSArray * array = json;
            NSDictionary * validator = jsonValidator[0];
            for (id item in array) {
                BOOL result = [self validateJSON:item withValidator:validator];
                if (!result) {
                    return NO;
                }
            }
        }
        return YES;
    } else if ([json isKindOfClass:jsonValidator]) {
        return YES;
    } else {
        return NO;
    }
}

+ (void)addDoNotBackupAttribute:(NSString *)path {
    NSURL *url = [NSURL fileURLWithPath:path];
    NSError *error = nil;
    [url setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error];
    if (error) {
        if ([__FWRequestConfig sharedConfig].debugLogEnabled) {
            FWLogDebug(@"error to set do not backup attribute, error = %@", error);
        }
    }
}

+ (NSString *)md5StringFromString:(NSString *)string {
    NSParameterAssert(string != nil && [string length] > 0);

    const char *value = [string UTF8String];

    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, (CC_LONG)strlen(value), outputBuffer);

    NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++){
        [outputString appendFormat:@"%02x", outputBuffer[count]];
    }

    return outputString;
}

+ (NSString *)appVersionString {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

+ (NSStringEncoding)stringEncodingWithRequest:(__FWBaseRequest *)request {
    // From AFNetworking 2.6.3
    NSStringEncoding stringEncoding = NSUTF8StringEncoding;
    NSString *encodingName = [request.response.textEncodingName copy];
    if (encodingName) {
        CFStringEncoding encoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)encodingName);
        if (encoding != kCFStringEncodingInvalidId) {
            stringEncoding = CFStringConvertEncodingToNSStringEncoding(encoding);
        }
    }
    return stringEncoding;
}

+ (BOOL)validateResumeData:(NSData *)data {
    // From http://stackoverflow.com/a/22137510/3562486
    if (!data || [data length] < 1) return NO;

    NSError *error;
    NSDictionary *resumeDictionary = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:&error];
    if (!resumeDictionary || error) return NO;

    return YES;
}

+ (BOOL)isRequestError:(NSError *)error
{
    if (!error) return NO;
    if ([error.domain isEqualToString:NSURLErrorDomain]) return YES;
    return [objc_getAssociatedObject(error, @selector(isRequestError:)) boolValue];
}

+ (void)markRequestError:(NSError *)error
{
    if (!error) return;
    objc_setAssociatedObject(error, @selector(isRequestError:), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (BOOL)isCancelledError:(NSError *)error
{
    if (!error) return NO;
    if (error.code == NSURLErrorCancelled ||
        error.code == NSURLErrorUserCancelledAuthentication ||
        error.code == NSUserCancelledError) {
        return YES;
    }
    return NO;
}

+ (BOOL)isConnectionError:(NSError *)error
{
    if (!error) return NO;
    if (error.code == NSURLErrorCancelled ||
        error.code == NSURLErrorBadURL ||
        error.code == NSURLErrorTimedOut ||
        error.code == NSURLErrorUnsupportedURL ||
        error.code == NSURLErrorCannotFindHost ||
        error.code == NSURLErrorCannotConnectToHost ||
        error.code == NSURLErrorNetworkConnectionLost ||
        error.code == NSURLErrorDNSLookupFailed ||
        error.code == NSURLErrorNotConnectedToInternet ||
        error.code == NSURLErrorUserCancelledAuthentication ||
        error.code == NSURLErrorUserAuthenticationRequired ||
        error.code == NSURLErrorAppTransportSecurityRequiresSecureConnection ||
        error.code == NSURLErrorSecureConnectionFailed ||
        error.code == NSURLErrorServerCertificateHasBadDate ||
        error.code == NSURLErrorServerCertificateUntrusted ||
        error.code == NSURLErrorServerCertificateHasUnknownRoot ||
        error.code == NSURLErrorServerCertificateNotYetValid ||
        error.code == NSURLErrorClientCertificateRejected ||
        error.code == NSURLErrorClientCertificateRequired ||
        error.code == NSURLErrorCannotLoadFromNetwork ||
        error.code == NSURLErrorInternationalRoamingOff ||
        error.code == NSURLErrorCallIsActive ||
        error.code == NSURLErrorDataNotAllowed ||
        error.code == NSURLErrorRequestBodyStreamExhausted) {
        return YES;
    }
    return NO;
}

@end
