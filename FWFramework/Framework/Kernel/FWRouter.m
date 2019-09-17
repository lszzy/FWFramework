/*!
 @header     FWRouter.m
 @indexgroup FWFramework
 @brief      FWRouter
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/11/29
 */

#import "FWRouter.h"
#import "UIWindow+FWFramework.h"

#pragma mark - FWRouter

static NSString * const FWRouterWildcardCharacter = @"*";
static NSString * FWRouterSpecialCharacters = @"/?&.";

static NSString * const FWRouterCoreKey = @"FWRouterCore";
static NSString * const FWRouterBlockKey = @"FWRouterBlock";
static NSString * const FWRouterTypeKey = @"FWRouterType";

NSString * const FWRouterURLKey = @"FWRouterURL";
NSString * const FWRouterCompletionKey = @"FWRouterCompletion";
NSString * const FWRouterUserInfoKey = @"FWRouterUserInfo";

typedef NS_ENUM(NSInteger, FWRouterType) {
    FWRouterTypeDefault = 0,
    FWRouterTypeObject = 1,
};

@interface FWRouter ()

// 路由列表，结构类似 @{@"beauty": @{@":id": {FWRouterCoreKey: [block copy], FWRouterTypeKey: @(FWRouterTypeDefault)}}}
@property (nonatomic, strong) NSMutableDictionary *routes;

// 过滤器URL Handler，URL调用时优先触发
@property (nonatomic, copy) FWRouterFilterHandler filterHandler;

// 错误URL Handler，URL未注册时触发
@property (nonatomic, copy) FWRouterHandler errorHandler;

// rewrite过滤器，优先调用
@property (nonatomic, copy) NSString * (^rewriteFilter)(NSString *url);

// rewrite规格列表，声明到扩展
@property (nonatomic, strong) NSMutableArray *rewriteRules;

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
    }
    return self;
}

#pragma mark - Register

+ (void)registerURL:(id)pattern withHandler:(FWRouterHandler)handler
{
    if ([pattern isKindOfClass:[NSArray class]]) {
        for (id subPattern in pattern) {
            [self registerURL:subPattern withHandler:handler];
        }
    } else {
        NSMutableDictionary *subRoutes = [[self sharedInstance] registerRoute:pattern];
        if (handler && subRoutes) {
            subRoutes[FWRouterCoreKey] = [handler copy];
            subRoutes[FWRouterTypeKey] = @(FWRouterTypeDefault);
        }
    }
}

+ (void)registerURL:(id)pattern withObjectHandler:(FWRouterObjectHandler)handler
{
    if ([pattern isKindOfClass:[NSArray class]]) {
        for (id subPattern in pattern) {
            [self registerURL:subPattern withObjectHandler:handler];
        }
    } else {
        NSMutableDictionary *subRoutes = [[self sharedInstance] registerRoute:pattern];
        if (handler && subRoutes) {
            subRoutes[FWRouterCoreKey] = [handler copy];
            subRoutes[FWRouterTypeKey] = @(FWRouterTypeObject);
        }
    }
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

+ (void)setFilterHandler:(FWRouterFilterHandler)handler
{
    [self sharedInstance].filterHandler = handler;
}

+ (void)setErrorHandler:(FWRouterHandler)handler
{
    [self sharedInstance].errorHandler = handler;
}

#pragma mark - Open

+ (BOOL)canOpenURL:(NSString *)URL
{
    NSString *rewriteURL = [self rewriteURL:URL];
    NSMutableDictionary *parameters = [[self sharedInstance] extractParametersFromURL:rewriteURL];
    if (parameters[FWRouterBlockKey]) {
        return [parameters[FWRouterTypeKey] integerValue] == FWRouterTypeDefault;
    } else {
        return NO;
    }
}

+ (void)openURL:(NSString *)URL
{
    [self openURL:URL completion:nil];
}

+ (void)openURL:(NSString *)URL userInfo:(NSDictionary *)userInfo
{
    [self openURL:URL userInfo:userInfo completion:nil];
}

+ (void)openURL:(NSString *)URL completion:(void (^)(id result))completion
{
    [self openURL:URL userInfo:nil completion:completion];
}

+ (void)openURL:(NSString *)URL userInfo:(NSDictionary *)userInfo completion:(void (^)(id result))completion
{
    NSString *rewriteURL = [self rewriteURL:URL];
    URL = [rewriteURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *parameters = [[self sharedInstance] extractParametersFromURL:URL];
    
    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, NSString *obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            parameters[key] = [obj stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
    }];
    
    if (completion) {
        parameters[FWRouterCompletionKey] = completion;
    }
    if (userInfo) {
        parameters[FWRouterUserInfoKey] = userInfo;
    }
    
    FWRouterHandler handler = parameters[FWRouterBlockKey];
    FWRouterType type = [parameters[FWRouterTypeKey] integerValue];
    [parameters removeObjectForKey:FWRouterBlockKey];
    [parameters removeObjectForKey:FWRouterTypeKey];
    
    if ([self sharedInstance].filterHandler) {
        if (![self sharedInstance].filterHandler(parameters)) return;
    }
    if (handler && type == FWRouterTypeDefault) {
        handler(parameters);
    } else {
        if ([self sharedInstance].errorHandler) {
            [self sharedInstance].errorHandler(parameters);
        }
    }
}

#pragma mark - Object

+ (BOOL)isObjectURL:(NSString *)URL
{
    NSString *rewriteURL = [self rewriteURL:URL];
    NSMutableDictionary *parameters = [[self sharedInstance] extractParametersFromURL:rewriteURL];
    if (parameters[FWRouterBlockKey]) {
        return [parameters[FWRouterTypeKey] integerValue] == FWRouterTypeObject;
    } else {
        return NO;
    }
}

+ (id)objectForURL:(NSString *)URL
{
    return [self objectForURL:URL userInfo:nil];
}

+ (id)objectForURL:(NSString *)URL userInfo:(NSDictionary *)userInfo
{
    NSString *rewriteURL = [self rewriteURL:URL];
    URL = [rewriteURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *parameters = [[self sharedInstance] extractParametersFromURL:URL];
    
    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, NSString *obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            parameters[key] = [obj stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
    }];
    
    if (userInfo) {
        parameters[FWRouterUserInfoKey] = userInfo;
    }
    
    FWRouterObjectHandler handler = parameters[FWRouterBlockKey];
    FWRouterType type = [parameters[FWRouterTypeKey] integerValue];
    [parameters removeObjectForKey:FWRouterBlockKey];
    [parameters removeObjectForKey:FWRouterTypeKey];
    
    if ([self sharedInstance].filterHandler) {
        if (![self sharedInstance].filterHandler(parameters)) return nil;
    }
    if (handler && type == FWRouterTypeObject) {
        return handler(parameters);
    } else {
        if ([self sharedInstance].errorHandler) {
            [self sharedInstance].errorHandler(parameters);
        }
        return nil;
    }
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
    if ([URL rangeOfString:@"://"].location != NSNotFound) {
        NSArray *pathSegments = [URL componentsSeparatedByString:@"://"];
        // 如果 URL 包含协议，那么把协议作为第一个元素放进去
        NSString *pathScheme = pathSegments.firstObject;
        if (pathScheme.length > 0) {
            [pathComponents addObject:pathScheme];
        }
        
        // 如果只有协议，那么放一个占位符
        URL = pathSegments.lastObject;
        if (!URL.length) {
            [pathComponents addObject:FWRouterWildcardCharacter];
        }
    }
    
    for (NSString *pathComponent in [[NSURL URLWithString:URL] pathComponents]) {
        if ([pathComponent isEqualToString:@"/"]) continue;
        if ([[pathComponent substringToIndex:1] isEqualToString:@"?"]) break;
        [pathComponents addObject:pathComponent];
    }
    return [pathComponents copy];
}

- (NSMutableDictionary *)extractParametersFromURL:(NSString *)url
{
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    
    parameters[FWRouterURLKey] = url;
    
    NSMutableDictionary* subRoutes = self.routes;
    NSArray* pathComponents = [self pathComponentsFromURL:url];
    
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
                parameters[newKey] = newPathComponent;
                break;
            }
        }
        
        // 如果没有找到该 pathComponent 对应的 handler，则以上一层的 handler 作为 fallback
        if (!wildcardMatched && !subRoutes[FWRouterCoreKey]) {
            break;
        }
    }
    
    // Extract Params From Query.
    NSArray<NSURLQueryItem *> *queryItems = [[NSURLComponents alloc] initWithURL:[[NSURL alloc] initWithString:url] resolvingAgainstBaseURL:false].queryItems;
    
    for (NSURLQueryItem *item in queryItems) {
        parameters[item.name] = item.value;
    }
    
    if (subRoutes[FWRouterCoreKey]) {
        parameters[FWRouterBlockKey] = [subRoutes[FWRouterCoreKey] copy];
        parameters[FWRouterTypeKey] = subRoutes[FWRouterTypeKey];
    }
    
    return parameters;
}

@end

#pragma mark - FWRouter+Rewrite

NSString *const FFRouterRewriteMatchRuleKey = @"matchRule";
NSString *const FFRouterRewriteTargetRuleKey = @"targetRule";

NSString *const FFRouterRewriteComponentURLKey = @"url";
NSString *const FFRouterRewriteComponentSchemeKey = @"scheme";
NSString *const FFRouterRewriteComponentHostKey = @"host";
NSString *const FFRouterRewriteComponentPortKey = @"port";
NSString *const FFRouterRewriteComponentPathKey = @"path";
NSString *const FFRouterRewriteComponentQueryKey = @"query";
NSString *const FFRouterRewriteComponentFragmentKey = @"fragment";

@implementation FWRouter (Rewrite)

+ (NSString *)rewriteURL:(NSString *)URL
{
    if (!URL) return nil;
    
    NSString *rewriteURL = URL;
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
        if ([[ruleDic objectForKey:FFRouterRewriteMatchRuleKey] isEqualToString:matchRule]) {
            [[self sharedInstance].rewriteRules removeObject:ruleDic];
        }
    }
    
    NSDictionary *ruleDic = @{FFRouterRewriteMatchRuleKey:matchRule,FFRouterRewriteTargetRuleKey:targetRule};
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
        NSString *matchRule = [ruleDic objectForKey:FFRouterRewriteMatchRuleKey];
        NSString *targetRule = [ruleDic objectForKey:FFRouterRewriteTargetRuleKey];
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
        if ([[ruleDic objectForKey:FFRouterRewriteMatchRuleKey] isEqualToString:matchRule]) {
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
            NSString *matchRule = [rule objectForKey:FFRouterRewriteMatchRuleKey];
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
                NSString *targetRule = [rule objectForKey:FFRouterRewriteTargetRuleKey];
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
    [componentDic setValue:originalURL forKey:FFRouterRewriteComponentURLKey];
    [componentDic setValue:urlComponents.scheme forKey:FFRouterRewriteComponentSchemeKey];
    [componentDic setValue:urlComponents.host forKey:FFRouterRewriteComponentHostKey];
    [componentDic setValue:urlComponents.port forKey:FFRouterRewriteComponentPortKey];
    [componentDic setValue:urlComponents.path forKey:FFRouterRewriteComponentPathKey];
    [componentDic setValue:urlComponents.query forKey:FFRouterRewriteComponentQueryKey];
    [componentDic setValue:urlComponents.fragment forKey:FFRouterRewriteComponentFragmentKey];
    
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

@end
