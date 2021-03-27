// FWOAuth2Manager.m
//
// Copyright (c) 2012-2014 AFNetworking (http://afnetworking.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE

#import "FWOAuth2Manager.h"

#pragma mark - FWOAuth2Manager

NSString * const kFWOAuthClientCredentialsGrantType = @"client_credentials";
NSString * const kFWOAuthPasswordCredentialsGrantType = @"password";
NSString * const kFWOAuthCodeGrantType = @"authorization_code";
NSString * const kFWOAuthRefreshGrantType = @"refresh_token";

NSString * const FWOAuth2ErrorDomain = @"site.wuyong.networking.oauth2.error";

// See: http://tools.ietf.org/html/rfc6749#section-5.2
static NSError * FWErrorFromRFC6749Section5_2Error(id object) {
    if (![object valueForKey:@"error"] || [[object valueForKey:@"error"] isEqual:[NSNull null]]) {
        return nil;
    }

    NSMutableDictionary *mutableUserInfo = [NSMutableDictionary dictionary];

    NSString *description = nil;
    if ([object valueForKey:@"error_description"]) {
        description = [object valueForKey:@"error_description"];
    } else {
        if ([[object valueForKey:@"error"] isEqualToString:@"invalid_request"]) {
            description = NSLocalizedStringFromTable(@"The request is missing a required parameter, includes an unsupported parameter value (other than grant type), repeats a parameter, includes multiple credentials, utilizes more than one mechanism for authenticating the client, or is otherwise malformed.", @"FWOAuth2Manager", @"invalid_request");
        } else if ([[object valueForKey:@"error"] isEqualToString:@"invalid_client"]) {
            description = NSLocalizedStringFromTable(@"Client authentication failed (e.g., unknown client, no client authentication included, or unsupported authentication method).  The authorization server MAY return an HTTP 401 (Unauthorized) status code to indicate which HTTP authentication schemes are supported.  If the client attempted to authenticate via the \"Authorization\" request header field, the authorization server MUST respond with an HTTP 401 (Unauthorized) status code and include the \"WWW-Authenticate\" response header field matching the authentication scheme used by the client.", @"FWOAuth2Manager", @"invalid_request");
        } else if ([[object valueForKey:@"error"] isEqualToString:@"invalid_grant"]) {
            description = NSLocalizedStringFromTable(@"The provided authorization grant (e.g., authorization code, resource owner credentials) or refresh token is invalid, expired, revoked, does not match the redirection URI used in the authorization request, or was issued to another client.", @"FWOAuth2Manager", @"invalid_request");
        } else if ([[object valueForKey:@"error"] isEqualToString:@"unauthorized_client"]) {
            description = NSLocalizedStringFromTable(@"The authenticated client is not authorized to use this authorization grant type.", @"FWOAuth2Manager", @"invalid_request");
        } else if ([[object valueForKey:@"error"] isEqualToString:@"unsupported_grant_type"]) {
            description = NSLocalizedStringFromTable(@"The authorization grant type is not supported by the authorization server.", @"FWOAuth2Manager", @"invalid_request");
        }
    }

    if (description) {
        mutableUserInfo[NSLocalizedDescriptionKey] = description;
    }

    if ([object valueForKey:@"error_uri"]) {
        mutableUserInfo[NSLocalizedRecoverySuggestionErrorKey] = [object valueForKey:@"error_uri"];
    }

    return [NSError errorWithDomain:FWOAuth2ErrorDomain code:-1 userInfo:mutableUserInfo];
}

@interface FWOAuth2Manager()

@property (readwrite, nonatomic, copy) NSString *serviceProviderIdentifier;
@property (readwrite, nonatomic, copy) NSString *clientID;
@property (readwrite, nonatomic, copy) NSString *secret;

@end

@implementation FWOAuth2Manager

+ (instancetype)managerWithBaseURL:(NSURL *)url
                           clientID:(NSString *)clientID
                             secret:(NSString *)secret {
    return [self managerWithBaseURL:url sessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] clientID:clientID secret:secret];
}

+ (instancetype)managerWithBaseURL:(NSURL *)url
               sessionConfiguration:(NSURLSessionConfiguration *)configuration
                           clientID:(NSString *)clientID
                             secret:(NSString *)secret {
    return [[self alloc] initWithBaseURL:url sessionConfiguration:configuration clientID:clientID secret:secret];
}

- (id)initWithBaseURL:(NSURL *)url
             clientID:(NSString *)clientID
               secret:(NSString *)secret {
    return [self initWithBaseURL:url sessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] clientID:clientID secret:secret];
}

- (id)initWithBaseURL:(NSURL *)url
 sessionConfiguration:(NSURLSessionConfiguration *)configuration
             clientID:(NSString *)clientID
               secret:(NSString *)secret {
    NSParameterAssert(url);
    NSParameterAssert(clientID);
    NSParameterAssert(secret);

    self = [super initWithBaseURL:url sessionConfiguration:configuration];
    if (!self) {
        return nil;
    }

    self.serviceProviderIdentifier = [self.baseURL host];
    self.clientID = clientID;
    self.secret = secret;
    self.useHTTPBasicAuthentication = YES;

    [self.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];

    return self;
}

#pragma mark -

- (void)setUseHTTPBasicAuthentication:(BOOL)useHTTPBasicAuthentication {
    _useHTTPBasicAuthentication = useHTTPBasicAuthentication;

    if (self.useHTTPBasicAuthentication) {
        [self.requestSerializer setAuthorizationHeaderFieldWithUsername:self.clientID password:self.secret];
    } else {
        [self.requestSerializer setValue:nil forHTTPHeaderField:@"Authorization"];
    }
}

- (void)setSecret:(NSString *)secret {
    if (!secret) {
        secret = @"";
    }

    _secret = secret;
}

#pragma mark - 

- (NSURLSessionTask *)authenticateUsingOAuthWithURLString:(NSString *)URLString
                                                 username:(NSString *)username
                                                 password:(NSString *)password
                                                    scope:(NSString *)scope
                                                  success:(void (^)(FWOAuthCredential * _Nonnull))success
                                                  failure:(void (^)(NSError * _Nonnull))failure {
    NSParameterAssert(username);
    NSParameterAssert(password);

    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setValue:kFWOAuthPasswordCredentialsGrantType forKey:@"grant_type"];
    [parameters setValue:username forKey:@"username"];
    [parameters setValue:password forKey:@"password"];

    if (scope) {
        [parameters setValue:scope forKey:@"scope"];
    }

    return [self authenticateUsingOAuthWithURLString:URLString parameters:parameters headers:nil success:success failure:failure];
}

- (NSURLSessionTask *)authenticateUsingOAuthWithURLString:(NSString *)URLString
                                                    scope:(NSString *)scope
                                                  success:(void (^)(FWOAuthCredential * _Nonnull))success
                                                  failure:(void (^)(NSError * _Nonnull))failure {

    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setValue:kFWOAuthClientCredentialsGrantType forKey:@"grant_type"];

    if (scope) {
        [parameters setValue:scope forKey:@"scope"];
    }

    return [self authenticateUsingOAuthWithURLString:URLString parameters:parameters headers:nil success:success failure:failure];
}


- (NSURLSessionTask *)authenticateUsingOAuthWithURLString:(NSString *)URLString
                                             refreshToken:(NSString *)refreshToken
                                                  success:(void (^)(FWOAuthCredential *credential))success
                                                  failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(refreshToken);

    NSDictionary *parameters = @{
                                 @"grant_type": kFWOAuthRefreshGrantType,
                                 @"refresh_token": refreshToken
                                 };

    return [self authenticateUsingOAuthWithURLString:URLString parameters:parameters headers:nil success:success failure:failure];
}

- (NSURLSessionTask *)authenticateUsingOAuthWithURLString:(NSString *)URLString
                                                     code:(NSString *)code
                                              redirectURI:(NSString *)uri
                                                  success:(void (^)(FWOAuthCredential *credential))success
                                                  failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(code);
    NSParameterAssert(uri);

    NSDictionary *parameters = @{
                                 @"grant_type": kFWOAuthCodeGrantType,
                                 @"code": code,
                                 @"redirect_uri": uri
                                 };

    return [self authenticateUsingOAuthWithURLString:URLString parameters:parameters headers:nil success:success failure:failure];
}

- (NSURLSessionTask *)authenticateUsingOAuthWithURLString:(NSString *)URLString
                                               parameters:(NSDictionary *)parameters
                                                  headers:(NSDictionary<NSString *,NSString *> *)headers
                                                  success:(void (^)(FWOAuthCredential *credential))success
                                                  failure:(void (^)(NSError *error))failure
{
    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
    if (!self.useHTTPBasicAuthentication) {
        mutableParameters[@"client_id"] = self.clientID;
        mutableParameters[@"client_secret"] = self.secret;
    }
    parameters = [NSDictionary dictionaryWithDictionary:mutableParameters];

    NSURLSessionTask *task;
    task = [self POST:URLString parameters:parameters headers:headers progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (!responseObject) {
            if (failure) {
                failure(nil);
            }
            return;
        }

        if ([responseObject valueForKey:@"error"]) {
            if (failure) {
                failure(FWErrorFromRFC6749Section5_2Error(responseObject));
            }
        }

        NSString *refreshToken = [responseObject valueForKey:@"refresh_token"];
        if (!refreshToken || [refreshToken isEqual:[NSNull null]]) {
            refreshToken = [parameters valueForKey:@"refresh_token"];
        }

        FWOAuthCredential *credential = [FWOAuthCredential credentialWithOAuthToken:[responseObject valueForKey:@"access_token"] tokenType:[responseObject valueForKey:@"token_type"]];


        if (refreshToken) { // refreshToken is optional in the OAuth2 spec
            [credential setRefreshToken:refreshToken];
        }

        // Expiration is optional, but recommended in the OAuth2 spec. It not provide, assume distantFuture === never expires
        NSDate *expireDate = [NSDate distantFuture];
        id expiresIn = [responseObject valueForKey:@"expires_in"];
        if (expiresIn && ![expiresIn isEqual:[NSNull null]]) {
            expireDate = [NSDate dateWithTimeIntervalSinceNow:[expiresIn doubleValue]];
        }

        if (expireDate) {
            [credential setExpiration:expireDate];
        }

        if (success) {
            success(credential);
        }

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) {
            failure(error);
        }
    }];

    return task;
}

@end

#pragma mark - FWOAuthCredential

NSString * const kFWOAuth2CredentialServiceName = @"FWOAuthCredentialService";

static NSDictionary * FWKeychainQueryDictionaryWithIdentifier(NSString *identifier) {
    NSCParameterAssert(identifier);

    return @{
             (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
             (__bridge id)kSecAttrService: kFWOAuth2CredentialServiceName,
             (__bridge id)kSecAttrAccount: identifier
             };
}

static BOOL FWOAuth2CredentialInKeychain = NO;

@interface FWOAuthCredential()
@property (readwrite, nonatomic, copy) NSString *accessToken;
@property (readwrite, nonatomic, copy) NSString *tokenType;
@property (readwrite, nonatomic, copy) NSString *refreshToken;
@property (readwrite, nonatomic, copy) NSDate *expiration;
@end


@implementation FWOAuthCredential

#pragma mark -

+ (instancetype)credentialWithOAuthToken:(NSString *)token
                               tokenType:(NSString *)type
{
    return [[self alloc] initWithOAuthToken:token tokenType:type];
}

- (id)initWithOAuthToken:(NSString *)token
               tokenType:(NSString *)type
{
    self = [super init];
    if (!self) {
        return nil;
    }

    self.accessToken = token;
    self.tokenType = type;

    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ accessToken:\"%@\" tokenType:\"%@\" refreshToken:\"%@\" expiration:\"%@\">", [self class], self.accessToken, self.tokenType, self.refreshToken, self.expiration];
}

- (void)setRefreshToken:(NSString *)refreshToken
{
    _refreshToken = refreshToken;
}

- (void)setExpiration:(NSDate *)expiration
{
    _expiration = expiration;
}

- (void)setRefreshToken:(NSString *)refreshToken
             expiration:(NSDate *)expiration
{
    NSParameterAssert(refreshToken);
    NSParameterAssert(expiration);

    self.refreshToken = refreshToken;
    self.expiration = expiration;
}

- (BOOL)isExpired {
    return [self.expiration compare:[NSDate date]] == NSOrderedAscending;
}

#pragma mark Keychain

+ (BOOL)storeCredentialInKeychain
{
    return FWOAuth2CredentialInKeychain;
}

+ (void)setStoreCredentialInKeychain:(BOOL)inKeychain
{
    FWOAuth2CredentialInKeychain = inKeychain;
}

+ (BOOL)storeCredential:(FWOAuthCredential *)credential
         withIdentifier:(NSString *)identifier
{
    if (!FWOAuth2CredentialInKeychain) {
        return [self storeCredential:credential withIdentifier:identifier withAccessibility:nil];
    }
    
    id securityAccessibility = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-compare"
    if (&kSecAttrAccessibleWhenUnlocked != NULL) {
        securityAccessibility = (__bridge id)kSecAttrAccessibleWhenUnlocked;
    }
#pragma clang diagnostic pop

    return [[self class] storeCredential:credential withIdentifier:identifier withAccessibility:securityAccessibility];
}

+ (BOOL)storeCredential:(FWOAuthCredential *)credential
         withIdentifier:(NSString *)identifier
      withAccessibility:(id)securityAccessibility
{
    if (!FWOAuth2CredentialInKeychain) {
        NSData *credentialData = [NSKeyedArchiver archivedDataWithRootObject:credential];
        [[NSUserDefaults standardUserDefaults] setObject:credentialData forKey:identifier];
        return [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    NSMutableDictionary *queryDictionary = [FWKeychainQueryDictionaryWithIdentifier(identifier) mutableCopy];

    NSMutableDictionary *updateDictionary = [NSMutableDictionary dictionary];
    updateDictionary[(__bridge id)kSecValueData] = [NSKeyedArchiver archivedDataWithRootObject:credential];

    if (securityAccessibility) {
        updateDictionary[(__bridge id)kSecAttrAccessible] = securityAccessibility;
    }

    OSStatus status;
    BOOL exists = ([self retrieveCredentialWithIdentifier:identifier] != nil);

    if (exists) {
        status = SecItemUpdate((__bridge CFDictionaryRef)queryDictionary, (__bridge CFDictionaryRef)updateDictionary);
    } else {
        [queryDictionary addEntriesFromDictionary:updateDictionary];
        status = SecItemAdd((__bridge CFDictionaryRef)queryDictionary, NULL);
    }

    return (status == errSecSuccess);
}

+ (BOOL)deleteCredentialWithIdentifier:(NSString *)identifier {
    if (!FWOAuth2CredentialInKeychain) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:identifier];
        return [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    NSMutableDictionary *queryDictionary = [FWKeychainQueryDictionaryWithIdentifier(identifier) mutableCopy];

    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)queryDictionary);

    return (status == errSecSuccess);
}

+ (FWOAuthCredential *)retrieveCredentialWithIdentifier:(NSString *)identifier {
    if (!FWOAuth2CredentialInKeychain) {
        NSData *credentialData = [[NSUserDefaults standardUserDefaults] objectForKey:identifier];
        if (!credentialData) return nil;
        return [NSKeyedUnarchiver unarchiveObjectWithData:credentialData];
    }
    
    NSMutableDictionary *queryDictionary = [FWKeychainQueryDictionaryWithIdentifier(identifier) mutableCopy];
    queryDictionary[(__bridge id)kSecReturnData] = (__bridge id)kCFBooleanTrue;
    queryDictionary[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;

    CFDataRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)queryDictionary, (CFTypeRef *)&result);

    if (status != errSecSuccess) {
        return nil;
    }

    return [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge_transfer NSData *)result];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    self.accessToken = [decoder decodeObjectForKey:NSStringFromSelector(@selector(accessToken))];
    self.tokenType = [decoder decodeObjectForKey:NSStringFromSelector(@selector(tokenType))];
    self.refreshToken = [decoder decodeObjectForKey:NSStringFromSelector(@selector(refreshToken))];
    self.expiration = [decoder decodeObjectForKey:NSStringFromSelector(@selector(expiration))];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.accessToken forKey:NSStringFromSelector(@selector(accessToken))];
    [encoder encodeObject:self.tokenType forKey:NSStringFromSelector(@selector(tokenType))];
    [encoder encodeObject:self.refreshToken forKey:NSStringFromSelector(@selector(refreshToken))];
    [encoder encodeObject:self.expiration forKey:NSStringFromSelector(@selector(expiration))];
}

@end

@implementation FWHTTPRequestSerializer (OAuth2)

- (void)setAuthorizationHeaderFieldWithCredential:(FWOAuthCredential *)credential {
    if ([credential.tokenType compare:@"Bearer" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
        [self setValue:[NSString stringWithFormat:@"Bearer %@", credential.accessToken] forHTTPHeaderField:@"Authorization"];
    }
}

@end
