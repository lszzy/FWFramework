/*!
 @header     FWRouter.m
 @indexgroup FWFramework
 @brief      FWRouter
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/11/29
 */

#import "FWRouter.h"
#import "FWLoader.h"

#pragma mark - FWRouterContext

@interface FWRouterContext ()

@property (nonatomic, copy) NSDictionary *URLParameters;
@property (nonatomic, copy) NSDictionary *parameters;
@property (nonatomic, assign) BOOL isOpening;

+ (NSURL *)URLWithString:(NSString *)URLString;

@end

@implementation FWRouterContext

- (instancetype)initWithURL:(NSString *)URL userInfo:(NSDictionary *)userInfo completion:(FWRouterCompletion)completion
{
    self = [super init];
    if (self) {
        _URL = URL;
        _userInfo = userInfo;
        _completion = completion;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    FWRouterContext *context = [[[self class] allocWithZone:zone] initWithURL:self.URL userInfo:self.userInfo completion:self.completion];
    context.URLParameters = self.URLParameters;
    context.isOpening = self.isOpening;
    return context;
}

- (NSDictionary<NSString *,NSString *> *)URLParameters
{
    if (!_URLParameters) {
        NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
        NSURL *nsurl = [FWRouterContext URLWithString:self.URL];
        if (nsurl) {
            NSArray<NSURLQueryItem *> *queryItems = [[NSURLComponents alloc] initWithURL:nsurl resolvingAgainstBaseURL:false].queryItems;
            // queryItems.value会自动进行URL参数解码
            for (NSURLQueryItem *item in queryItems) {
                parameters[item.name] = item.value;
            }
        }
        _URLParameters = [parameters copy];
    }
    return _URLParameters;
}

- (NSDictionary *)parameters
{
    if (!_parameters) {
        NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
        if (self.userInfo) [parameters addEntriesFromDictionary:self.userInfo];
        [parameters addEntriesFromDictionary:self.URLParameters];
        _parameters = [parameters copy];
    }
    return _parameters;
}

+ (NSURL *)URLWithString:(NSString *)URLString
{
    NSURL *URL = URLString.length > 0 ? [NSURL URLWithString:URLString] : nil;
    if (!URL && URLString.length > 0) {
        URL = [NSURL URLWithString:[URLString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    }
    return URL;
}

@end

#pragma mark - FWRouter

static NSString * const FWRouterWildcardCharacter = @"*";
static NSString * FWRouterSpecialCharacters = @"/?&.";

static NSString * const FWRouterCoreKey = @"FWRouterCore";
static NSString * const FWRouterBlockKey = @"FWRouterBlock";

@interface FWRouter ()

// 路由列表，结构类似 @{@"beauty": @{@":id": {FWRouterCoreKey: [block copy]}}}
@property (nonatomic, strong) NSMutableDictionary *routes;

@property (nonatomic, copy) BOOL (^preFilter)(FWRouterContext *context);
@property (nonatomic, copy) id (^postFilter)(FWRouterContext *context, id object);
@property (nonatomic, copy) void (^errorHandler)(FWRouterContext *context);

@property (nonatomic, copy) NSString * (^rewriteFilter)(NSString *url);
@property (nonatomic, strong) NSMutableArray *rewriteRules;

@property (nonatomic, strong) FWLoader<NSString *, id> *routeLoader;

@end

@implementation FWRouter

+ (FWRouter *)sharedInstance
{
    static FWRouter *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWRouter alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _routes = [[NSMutableDictionary alloc] init];
        _rewriteRules = [[NSMutableArray alloc] init];
        _routeLoader = [[FWLoader<NSString *, id> alloc] init];
    }
    return self;
}

+ (FWLoader<NSString *,id> *)sharedLoader
{
    return [self sharedInstance].routeLoader;
}

#pragma mark - Class

+ (BOOL)registerClass:(Class<FWRouterProtocol>)clazz
{
    if (![clazz conformsToProtocol:@protocol(FWRouterProtocol)]) return NO;
    if (![clazz respondsToSelector:@selector(fwRouterURL)]) return NO;
    if (![clazz respondsToSelector:@selector(fwRouterHandler:)]) return NO;
    
    return [self registerURL:[clazz fwRouterURL] withHandler:^id(FWRouterContext *context) {
        return [clazz fwRouterHandler:context];
    }];
}

+ (BOOL)presetClass:(Class<FWRouterProtocol>)clazz
{
    if (![clazz conformsToProtocol:@protocol(FWRouterProtocol)]) return NO;
    if (![clazz respondsToSelector:@selector(fwRouterURL)]) return NO;
    if (![clazz respondsToSelector:@selector(fwRouterHandler:)]) return NO;
    
    return [self presetURL:[clazz fwRouterURL] withHandler:^id(FWRouterContext *context) {
        return [clazz fwRouterHandler:context];
    }];
}

+ (void)unregisterClass:(Class<FWRouterProtocol>)clazz
{
    if (![clazz conformsToProtocol:@protocol(FWRouterProtocol)]) return;
    if (![clazz respondsToSelector:@selector(fwRouterURL)]) return;
    
    [self unregisterURL:[clazz fwRouterURL]];
}

#pragma mark - URL

+ (BOOL)registerURL:(id)pattern withHandler:(FWRouterHandler)handler
{
    if ([pattern isKindOfClass:[NSArray class]]) {
        BOOL result = YES;
        for (id subPattern in pattern) {
            result = [self registerURL:subPattern withHandler:handler isPreset:NO] && result;
        }
        return result;
    } else {
        return [self registerURL:pattern withHandler:handler isPreset:NO];
    }
}

+ (BOOL)presetURL:(id)pattern withHandler:(FWRouterHandler)handler
{
    if ([pattern isKindOfClass:[NSArray class]]) {
        BOOL result = YES;
        for (id subPattern in pattern) {
            result = [self registerURL:subPattern withHandler:handler isPreset:YES] && result;
        }
        return result;
    } else {
        return [self registerURL:pattern withHandler:handler isPreset:YES];
    }
}

+ (BOOL)registerURL:(NSString *)pattern withHandler:(FWRouterHandler)handler isPreset:(BOOL)isPreset
{
    if (!handler || pattern.length < 1) return NO;
    
    NSMutableDictionary *subRoutes = [[self sharedInstance] registerRoute:pattern];
    if (!subRoutes) return NO;
    if (isPreset && subRoutes[FWRouterCoreKey] != nil) return NO;
    
    subRoutes[FWRouterCoreKey] = [handler copy];
    return YES;
}

+ (void)unregisterURL:(id)pattern
{
    if ([pattern isKindOfClass:[NSArray class]]) {
        for (id subPattern in pattern) {
            [self unregisterURL:subPattern];
        }
    } else {
        NSMutableArray *pathComponents = [NSMutableArray arrayWithArray:[[self sharedInstance] pathComponentsFromURL:pattern]];
        // 只删除该 pattern 的最后一级
        if (pathComponents.count >= 1) {
            // 假如 URLPattern 为 a/b/c, components 就是 @"a.b.c" 正好可以作为 KVC 的 key
            NSString *components = [pathComponents componentsJoinedByString:@"."];
            NSMutableDictionary *route = [[self sharedInstance].routes valueForKeyPath:components];
            
            if (route.count >= 1) {
                NSString *lastComponent = [pathComponents lastObject];
                [pathComponents removeLastObject];
                
                // 有可能是根 key，这样就是 self.routes 了
                route = [self sharedInstance].routes;
                if (pathComponents.count) {
                    NSString *componentsWithoutLast = [pathComponents componentsJoinedByString:@"."];
                    route = [[self sharedInstance].routes valueForKeyPath:componentsWithoutLast];
                }
                [route removeObjectForKey:lastComponent];
            }
        }
    }
}

+ (void)unregisterAllURLs
{
    [[self sharedInstance].routes removeAllObjects];
}

#pragma mark - Handler

+ (BOOL (^)(FWRouterContext *))preFilter
{
    return [self sharedInstance].preFilter;
}

+ (void)setPreFilter:(BOOL (^)(FWRouterContext *))preFilter
{
    [self sharedInstance].preFilter = preFilter;
}

+ (id (^)(FWRouterContext *, id))postFilter
{
    return [self sharedInstance].postFilter;
}

+ (void)setPostFilter:(id (^)(FWRouterContext *, id))postFilter
{
    [self sharedInstance].postFilter = postFilter;
}

+ (void (^)(FWRouterContext *))errorHandler
{
    return [self sharedInstance].errorHandler;
}

+ (void)setErrorHandler:(void (^)(FWRouterContext *))errorHandler
{
    [self sharedInstance].errorHandler = errorHandler;
}

#pragma mark - Open

+ (BOOL)canOpenURL:(id)URL
{
    NSString *rewriteURL = [self rewriteURL:URL];
    if (rewriteURL.length < 1) return NO;
    
    NSMutableDictionary *URLParameters = [[self sharedInstance] routeParametersFromURL:rewriteURL];
    return URLParameters[FWRouterBlockKey] ? YES : NO;
}

+ (void)openURL:(id)URL
{
    [self openURL:URL completion:nil];
}

+ (void)openURL:(id)URL userInfo:(NSDictionary *)userInfo
{
    [self openURL:URL userInfo:userInfo completion:nil];
}

+ (void)openURL:(id)URL completion:(FWRouterCompletion)completion
{
    [self openURL:URL userInfo:nil completion:completion];
}

+ (void)openURL:(id)URL userInfo:(NSDictionary *)userInfo completion:(FWRouterCompletion)completion
{
    NSString *rewriteURL = [self rewriteURL:URL];
    if (rewriteURL.length < 1) return;
    
    NSMutableDictionary *URLParameters = [[self sharedInstance] routeParametersFromURL:rewriteURL];
    FWRouterHandler handler = URLParameters[FWRouterBlockKey];
    [URLParameters removeObjectForKey:FWRouterBlockKey];
    
    FWRouterContext *context = [[FWRouterContext alloc] initWithURL:rewriteURL userInfo:userInfo completion:completion];
    context.URLParameters = [URLParameters copy];
    context.isOpening = YES;
    
    if ([self sharedInstance].preFilter) {
        if (![self sharedInstance].preFilter(context)) return;
    }
    if (handler) {
        id object = handler(context);
        if (object && [self sharedInstance].postFilter) {
            [self sharedInstance].postFilter(context, object);
        }
        return;
    }
    if ([self sharedInstance].errorHandler) {
        [self sharedInstance].errorHandler(context);
    }
}

+ (void)completeURL:(FWRouterContext *)context result:(id)result
{
    if (context.completion) {
        context.completion(result);
    }
}

#pragma mark - Object

+ (id)objectForURL:(id)URL
{
    return [self objectForURL:URL userInfo:nil];
}

+ (id)objectForURL:(id)URL userInfo:(NSDictionary *)userInfo
{
    NSString *rewriteURL = [self rewriteURL:URL];
    if (rewriteURL.length < 1) return nil;
    
    NSMutableDictionary *URLParameters = [[self sharedInstance] routeParametersFromURL:rewriteURL];
    FWRouterHandler handler = URLParameters[FWRouterBlockKey];
    [URLParameters removeObjectForKey:FWRouterBlockKey];
    
    FWRouterContext *context = [[FWRouterContext alloc] initWithURL:rewriteURL userInfo:userInfo completion:nil];
    context.URLParameters = [URLParameters copy];
    context.isOpening = NO;
    
    if ([self sharedInstance].preFilter) {
        if (![self sharedInstance].preFilter(context)) return nil;
    }
    if (handler) {
        id object = handler(context);
        if (object && [self sharedInstance].postFilter) {
            return [self sharedInstance].postFilter(context, object);
        }
        return object;
    }
    if ([self sharedInstance].errorHandler) {
        [self sharedInstance].errorHandler(context);
    }
    return nil;
}

#pragma mark - Generator

+ (NSString *)generateURL:(NSString *)pattern parameters:(id)parameters
{
    NSInteger startIndexOfColon = 0;
    
    NSMutableArray *placeholders = [NSMutableArray array];
    
    for (int i = 0; i < pattern.length; i++) {
        NSString *character = [NSString stringWithFormat:@"%c", [pattern characterAtIndex:i]];
        if ([character isEqualToString:@":"]) {
            startIndexOfColon = i;
        }
        if ([FWRouterSpecialCharacters rangeOfString:character].location != NSNotFound && i > (startIndexOfColon + 1) && startIndexOfColon) {
            NSRange range = NSMakeRange(startIndexOfColon, i - startIndexOfColon);
            NSString *placeholder = [pattern substringWithRange:range];
            NSCharacterSet *specialCharactersSet = [NSCharacterSet characterSetWithCharactersInString:FWRouterSpecialCharacters];
            if ([placeholder rangeOfCharacterFromSet:specialCharactersSet].location == NSNotFound) {
                [placeholders addObject:placeholder];
                startIndexOfColon = 0;
            }
        }
        if (i == pattern.length - 1 && startIndexOfColon) {
            NSRange range = NSMakeRange(startIndexOfColon, i - startIndexOfColon + 1);
            NSString *placeholder = [pattern substringWithRange:range];
            NSCharacterSet *specialCharactersSet = [NSCharacterSet characterSetWithCharactersInString:FWRouterSpecialCharacters];
            if ([placeholder rangeOfCharacterFromSet:specialCharactersSet].location == NSNotFound) {
                [placeholders addObject:placeholder];
            }
        }
    }
    
    __block NSString *parsedResult = pattern;
    
    if ([parameters isKindOfClass:[NSArray class]]) {
        [placeholders enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (idx < [parameters count]) {
                id value = [parameters objectAtIndex:[parameters count] - 1];
                parsedResult = [parsedResult stringByReplacingOccurrencesOfString:obj withString:[NSString stringWithFormat:@"%@", value]];
            }
        }];
    } else if ([parameters isKindOfClass:[NSDictionary class]]) {
        [placeholders enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            id value = [parameters objectForKey:[obj stringByReplacingOccurrencesOfString:@":" withString:@""]];
            if (value) {
                parsedResult = [parsedResult stringByReplacingOccurrencesOfString:obj withString:[NSString stringWithFormat:@"%@", value]];
            }
        }];
    } else if (parameters) {
        [placeholders enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            parsedResult = [parsedResult stringByReplacingOccurrencesOfString:obj withString:[NSString stringWithFormat:@"%@", parameters]];
        }];
    }
    
    return parsedResult;
}

#pragma mark - Private

- (NSMutableDictionary *)registerRoute:(NSString *)pattern
{
    NSArray *pathComponents = [self pathComponentsFromURL:pattern];
    
    NSMutableDictionary *subRoutes = self.routes;
    
    for (NSString *pathComponent in pathComponents) {
        if (![subRoutes objectForKey:pathComponent]) {
            subRoutes[pathComponent] = [[NSMutableDictionary alloc] init];
        }
        subRoutes = subRoutes[pathComponent];
    }
    return subRoutes;
}

- (NSArray *)pathComponentsFromURL:(NSString *)URL
{
    NSMutableArray *pathComponents = [NSMutableArray array];
    // 解析scheme://path格式
    NSRange urlRange = [URL rangeOfString:@"://"];
    if (urlRange.location == NSNotFound) {
        // 解析scheme:path格式
        NSString *urlScheme = [[FWRouterContext URLWithString:URL].scheme stringByAppendingString:@":"];
        if (urlScheme.length > 1 && [URL hasPrefix:urlScheme]) {
            urlRange = NSMakeRange(urlScheme.length - 1, 1);
        }
    }
    
    if (urlRange.location != NSNotFound) {
        // 如果 URL 包含协议，那么把协议作为第一个元素放进去
        NSString *pathScheme = [URL substringToIndex:urlRange.location];
        if (pathScheme.length > 0) {
            [pathComponents addObject:pathScheme];
        }
        
        // 如果只有协议，那么放一个占位符
        URL = [URL substringFromIndex:urlRange.location + urlRange.length];
        if (!URL.length) {
            [pathComponents addObject:FWRouterWildcardCharacter];
        }
    }
    
    NSURL *nsurl = [FWRouterContext URLWithString:URL];
    for (NSString *pathComponent in [nsurl pathComponents]) {
        if ([pathComponent isEqualToString:@"/"]) continue;
        if ([[pathComponent substringToIndex:1] isEqualToString:@"?"]) break;
        [pathComponents addObject:pathComponent];
    }
    return [pathComponents copy];
}

- (NSMutableDictionary *)routeParametersFromURL:(NSString *)url
{
    NSMutableDictionary *parameters = [self extractParametersFromURL:url];
    if (parameters[FWRouterBlockKey]) return parameters;
    
    id object = [self.routeLoader load:url];
    if (object) {
        [FWRouter registerClass:object];
        parameters = [self extractParametersFromURL:url];
    }
    return parameters;
}

- (NSMutableDictionary *)extractParametersFromURL:(NSString *)url
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    NSMutableDictionary *subRoutes = self.routes;
    NSArray *pathComponents = [self pathComponentsFromURL:url];
    
    BOOL wildcardMatched = NO;
    for (NSString *pathComponent in pathComponents) {
        
        // 对 key 进行排序，这样可以把 * 放到最后
        NSStringCompareOptions comparisonOptions = NSCaseInsensitiveSearch;
        NSArray *subRoutesKeys =[subRoutes.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
            return [obj2 compare:obj1 options:comparisonOptions];
        }];
        
        for (NSString *key in subRoutesKeys) {
            if ([key isEqualToString:pathComponent] || [key isEqualToString:FWRouterWildcardCharacter]) {
                wildcardMatched = YES;
                subRoutes = subRoutes[key];
                break;
            } else if ([key hasPrefix:@":"]) {
                wildcardMatched = YES;
                subRoutes = subRoutes[key];
                NSString *newKey = [key substringFromIndex:1];
                NSString *newPathComponent = pathComponent;
                // 再做一下特殊处理，比如 :id.html -> :id
                NSCharacterSet *specialCharactersSet = [NSCharacterSet characterSetWithCharactersInString:FWRouterSpecialCharacters];
                if ([key rangeOfCharacterFromSet:specialCharactersSet].location != NSNotFound) {
                    NSCharacterSet *specialCharacterSet = [NSCharacterSet characterSetWithCharactersInString:FWRouterSpecialCharacters];
                    NSRange range = [key rangeOfCharacterFromSet:specialCharacterSet];
                    if (range.location != NSNotFound) {
                        // 把 pathComponent 后面的部分也去掉
                        newKey = [newKey substringToIndex:range.location - 1];
                        NSString *suffixToStrip = [key substringFromIndex:range.location];
                        newPathComponent = [newPathComponent stringByReplacingOccurrencesOfString:suffixToStrip withString:@""];
                    }
                }
                parameters[newKey] = [newPathComponent stringByRemovingPercentEncoding];
                break;
            } else {
                wildcardMatched = NO;
            }
        }
        
        // 如果没有找到该 pathComponent 对应的 handler，则以上一层的 handler 作为 fallback
        if (!wildcardMatched && !subRoutes[FWRouterCoreKey]) {
            break;
        }
    }
    
    NSURL *nsurl = [FWRouterContext URLWithString:url];
    if (nsurl) {
        NSArray<NSURLQueryItem *> *queryItems = [[NSURLComponents alloc] initWithURL:nsurl resolvingAgainstBaseURL:false].queryItems;
        // queryItems.value会自动进行URL参数解码
        for (NSURLQueryItem *item in queryItems) {
            parameters[item.name] = item.value;
        }
    }
    
    if (subRoutes[FWRouterCoreKey]) {
        parameters[FWRouterBlockKey] = [subRoutes[FWRouterCoreKey] copy];
    } else {
        [parameters removeObjectForKey:FWRouterBlockKey];
    }
    return parameters;
}

@end

#pragma mark - FWRouter+Rewrite

NSString *const FWRouterRewriteMatchRuleKey = @"matchRule";
NSString *const FWRouterRewriteTargetRuleKey = @"targetRule";

NSString *const FWRouterRewriteComponentURLKey = @"url";
NSString *const FWRouterRewriteComponentSchemeKey = @"scheme";
NSString *const FWRouterRewriteComponentHostKey = @"host";
NSString *const FWRouterRewriteComponentPortKey = @"port";
NSString *const FWRouterRewriteComponentPathKey = @"path";
NSString *const FWRouterRewriteComponentQueryKey = @"query";
NSString *const FWRouterRewriteComponentFragmentKey = @"fragment";

@implementation FWRouter (Rewrite)

+ (NSString *)rewriteURL:(id)URL
{
    NSString *rewriteURL = [URL isKindOfClass:[NSURL class]] ? [URL absoluteString] : URL;
    if (!rewriteURL) return nil;
    
    if ([self sharedInstance].rewriteFilter) {
        rewriteURL = [self sharedInstance].rewriteFilter(rewriteURL);
        if (!rewriteURL) return nil;
    }
    
    if ([self sharedInstance].rewriteRules.count == 0) return rewriteURL;
    NSString *rewriteCaptureGroupsURL = [self rewriteCaptureGroupsWithOriginalURL:rewriteURL];
    rewriteURL = [self rewriteComponentsWithOriginalURL:rewriteURL targetRule:rewriteCaptureGroupsURL];
    return rewriteURL;
}

+ (void)setRewriteFilter:(NSString *(^)(NSString *))filter
{
    [self sharedInstance].rewriteFilter = filter;
}

+ (void)addRewriteRule:(NSString *)matchRule targetRule:(NSString *)targetRule
{
    if (!matchRule || !targetRule) return;
    
    NSArray *rules = [[self sharedInstance].rewriteRules copy];
    for (int idx = 0; idx < rules.count; idx ++) {
        NSDictionary *ruleDic = [rules objectAtIndex:idx];
        if ([[ruleDic objectForKey:FWRouterRewriteMatchRuleKey] isEqualToString:matchRule]) {
            [[self sharedInstance].rewriteRules removeObject:ruleDic];
        }
    }
    
    NSDictionary *ruleDic = @{FWRouterRewriteMatchRuleKey:matchRule,FWRouterRewriteTargetRuleKey:targetRule};
    [[self sharedInstance].rewriteRules addObject:ruleDic];
    
}

+ (void)addRewriteRules:(NSArray<NSDictionary *> *)rules
{
    if (!rules) return;
    
    for (int idx = 0; idx < rules.count; idx ++) {
        id ruleObjc = [rules objectAtIndex:idx];
        
        if (![ruleObjc isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSDictionary *ruleDic = [rules objectAtIndex:idx];
        NSString *matchRule = [ruleDic objectForKey:FWRouterRewriteMatchRuleKey];
        NSString *targetRule = [ruleDic objectForKey:FWRouterRewriteTargetRuleKey];
        if (!matchRule || !targetRule) {
            continue;
        }
        [self addRewriteRule:matchRule targetRule:targetRule];
    }
}

+ (void)removeRewriteRule:(NSString *)matchRule
{
    NSArray *rules = [[self sharedInstance].rewriteRules copy];
    for (int idx = 0; idx < rules.count; idx ++) {
        NSDictionary *ruleDic = [rules objectAtIndex:idx];
        if ([[ruleDic objectForKey:FWRouterRewriteMatchRuleKey] isEqualToString:matchRule]) {
            [[self sharedInstance].rewriteRules removeObject:ruleDic];
            break;
        }
    }
}

+ (void)removeAllRewriteRules
{
    [[self sharedInstance].rewriteRules removeAllObjects];
}

#pragma mark - Private

+ (NSString *)rewriteCaptureGroupsWithOriginalURL:(NSString *)originalURL
{
    NSArray *rules = [self sharedInstance].rewriteRules;
    if ([rules isKindOfClass:[NSArray class]] && rules.count > 0) {
        NSString *targetURL = originalURL;
        NSRegularExpression *replaceRx = [NSRegularExpression regularExpressionWithPattern:@"[$]([$|#]?)(\\d+)" options:0 error:NULL];
        
        for (NSDictionary *rule in rules) {
            NSString *matchRule = [rule objectForKey:FWRouterRewriteMatchRuleKey];
            if (!([matchRule isKindOfClass:[NSString class]] && matchRule.length > 0)) continue;
            
            NSRange searchRange = NSMakeRange(0, targetURL.length);
            NSRegularExpression *rx = [NSRegularExpression regularExpressionWithPattern:matchRule options:0 error:NULL];
            NSRange range = [rx rangeOfFirstMatchInString:targetURL options:0 range:searchRange];
            
            if (range.length != 0) {
                NSMutableArray *groupValues = [NSMutableArray array];
                NSTextCheckingResult *result = [rx firstMatchInString:targetURL options:0 range:searchRange];
                for (NSInteger idx = 0; idx<rx.numberOfCaptureGroups + 1; idx++) {
                    NSRange groupRange = [result rangeAtIndex:idx];
                    if (groupRange.length != 0) {
                        [groupValues addObject:[targetURL substringWithRange:groupRange]];
                    }
                }
                NSString *targetRule = [rule objectForKey:FWRouterRewriteTargetRuleKey];
                NSMutableString *newTargetURL = [NSMutableString stringWithString:targetRule];
                [replaceRx enumerateMatchesInString:targetRule options:0 range:NSMakeRange(0, targetRule.length) usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
                    NSRange matchRange = result.range;
                    
                    NSRange secondGroupRange = [result rangeAtIndex:2];
                    NSString *replacedValue = [targetRule substringWithRange:matchRange];
                    NSInteger index = [[targetRule substringWithRange:secondGroupRange] integerValue];
                    if (index >= 0 && index < groupValues.count) {
                        
                        NSString *newValue = [self convertCaptureGroupsWithCheckingResult:result targetRule:targetRule originalValue:groupValues[index]];
                        [newTargetURL replaceOccurrencesOfString:replacedValue withString:newValue options:0 range:NSMakeRange(0, newTargetURL.length)];
                    }
                }];
                return newTargetURL;
            }
        }
    }
    return originalURL;
}

+ (NSString *)rewriteComponentsWithOriginalURL:(NSString *)originalURL targetRule:(NSString *)targetRule
{
    NSString *encodeURL = [originalURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:encodeURL];
    NSMutableDictionary *componentDic = [[NSMutableDictionary alloc] init];
    [componentDic setValue:originalURL forKey:FWRouterRewriteComponentURLKey];
    [componentDic setValue:urlComponents.scheme forKey:FWRouterRewriteComponentSchemeKey];
    [componentDic setValue:urlComponents.host forKey:FWRouterRewriteComponentHostKey];
    [componentDic setValue:urlComponents.port forKey:FWRouterRewriteComponentPortKey];
    [componentDic setValue:urlComponents.path forKey:FWRouterRewriteComponentPathKey];
    [componentDic setValue:urlComponents.query forKey:FWRouterRewriteComponentQueryKey];
    [componentDic setValue:urlComponents.fragment forKey:FWRouterRewriteComponentFragmentKey];
    
    NSMutableString *targetURL = [NSMutableString stringWithString:targetRule];
    NSRegularExpression *replaceRx = [NSRegularExpression regularExpressionWithPattern:@"[$]([$|#]?)(\\w+)" options:0 error:NULL];
    
    [replaceRx enumerateMatchesInString:targetRule options:0 range:NSMakeRange(0, targetRule.length) usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
        NSRange matchRange = result.range;
        NSRange secondGroupRange = [result rangeAtIndex:2];
        NSString *replaceValue = [targetRule substringWithRange:matchRange];
        NSString *componentKey = [targetRule substringWithRange:secondGroupRange];
        NSString *componentValue = [componentDic valueForKey:componentKey];
        if (!componentValue) {
            componentValue = @"";
        }
        
        NSString *newValue = [self convertCaptureGroupsWithCheckingResult:result targetRule:targetRule originalValue:componentValue];
        [targetURL replaceOccurrencesOfString:replaceValue withString:newValue options:0 range:NSMakeRange(0, targetURL.length)];
    }];
    
    return targetURL;
}

+ (NSString *)convertCaptureGroupsWithCheckingResult:(NSTextCheckingResult *)checkingResult targetRule:(NSString *)targetRule originalValue:(NSString *)originalValue
{
    NSString *convertValue = originalValue;
    
    NSRange convertKeyRange = [checkingResult rangeAtIndex:1];
    NSString *convertKey = [targetRule substringWithRange:convertKeyRange];
    if ([convertKey isEqualToString:@"$"]) {
        // URL Encode
        convertValue = [originalValue stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    }else if([convertKey isEqualToString:@"#"]){
        // URL Decode
        convertValue = [originalValue stringByRemovingPercentEncoding];
    }
    
    return convertValue;
}

@end

#pragma mark - FWRouter+Navigation

@implementation FWRouter (Navigation)

+ (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [[UIWindow fwMainWindow] fwPushViewController:viewController animated:animated];
}

+ (void)presentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion
{
    [[UIWindow fwMainWindow] fwPresentViewController:viewController animated:animated completion:completion];
}

+ (void)openViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [[UIWindow fwMainWindow] fwOpenViewController:viewController animated:animated];
}

+ (BOOL)closeViewControllerAnimated:(BOOL)animated
{
    return [[UIWindow fwMainWindow] fwCloseViewControllerAnimated:animated];
}

@end

#pragma mark - UIWindow+FWNavigation

@implementation UIWindow (FWNavigation)

+ (UIWindow *)fwMainWindow
{
    UIWindow *mainWindow = UIApplication.sharedApplication.keyWindow;
    if (!mainWindow) {
        for (UIWindow *window in UIApplication.sharedApplication.windows) {
            if (window.isKeyWindow) { mainWindow = window; break; }
        }
    }
    
#ifdef DEBUG
    // DEBUG模式时兼容FLEX、FWDebug等组件
    if ([mainWindow isKindOfClass:NSClassFromString(@"FLEXWindow")] &&
        [mainWindow respondsToSelector:NSSelectorFromString(@"previousKeyWindow")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        mainWindow = [mainWindow performSelector:NSSelectorFromString(@"previousKeyWindow")];
#pragma clang diagnostic pop
    }
#endif
    return mainWindow;
}

+ (UIWindowScene *)fwMainScene
{
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive &&
            [scene isKindOfClass:[UIWindowScene class]]) {
            return (UIWindowScene *)scene;
        }
    }
    return nil;
}

+ (UIViewController *)fwTopViewController:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[UITabBarController class]]) {
        UIViewController *topController = [(UITabBarController *)viewController selectedViewController];
        if (topController) return [self fwTopViewController:topController];
    }
    
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        UIViewController *topController = [(UINavigationController *)viewController topViewController];
        if (topController) return [self fwTopViewController:topController];
    }
    
    return viewController;
}

- (UIViewController *)fwTopViewController
{
    return [UIWindow fwTopViewController:[self fwTopPresentedController]];
}

- (UINavigationController *)fwTopNavigationController
{
    return [self fwTopViewController].navigationController;
}

- (UIViewController *)fwTopPresentedController
{
    UIViewController *presentedController = self.rootViewController;
    
    while ([presentedController presentedViewController]) {
        presentedController = [presentedController presentedViewController];
    }
    
    return presentedController;
}

- (BOOL)fwPushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    UINavigationController *navigationController = [self fwTopNavigationController];
    if (navigationController) {
        [navigationController pushViewController:viewController animated:animated];
        return YES;
    }
    return NO;
}

- (void)fwPresentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion
{
    [[self fwTopPresentedController] presentViewController:viewController animated:animated completion:completion];
}

- (void)fwOpenViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [[self fwTopViewController] fwOpenViewController:viewController animated:animated];
}

- (BOOL)fwCloseViewControllerAnimated:(BOOL)animated
{
    return [[self fwTopViewController] fwCloseViewControllerAnimated:animated];
}

@end

#pragma mark - UIViewController+FWNavigation

@implementation UIViewController (FWNavigation)

- (void)fwOpenViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (!self.navigationController || [viewController isKindOfClass:[UINavigationController class]]) {
        [self presentViewController:viewController animated:animated completion:nil];
    } else {
        [self.navigationController pushViewController:viewController animated:animated];
    }
}

- (BOOL)fwCloseViewControllerAnimated:(BOOL)animated
{
    if (self.navigationController) {
        if ([self.navigationController popViewControllerAnimated:animated]) return YES;
    }
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:animated completion:nil];
        return YES;
    }
    return NO;
}

@end
