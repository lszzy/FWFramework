/*!
 @header     FWRouter.m
 @indexgroup FWFramework
 @brief      FWRouter
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/11/29
 */

#import "FWRouter.h"

#pragma mark - FWRouterContext

@interface FWRouterContext ()

@property (nonatomic, assign) BOOL isOpen;
@property (nonatomic, copy) NSDictionary *routeParameters;
@property (nonatomic, copy) NSDictionary *parameters;

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
    context.isOpen = self.isOpen;
    context.routeParameters = self.routeParameters;
    return context;
}

- (NSDictionary *)parameters
{
    if (_parameters) return _parameters;

    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    if (self.routeParameters) {
        [parameters addEntriesFromDictionary:self.routeParameters];
    }
    
    NSURL *nsurl = self.URL.length > 0 ? [NSURL URLWithString:self.URL] : nil;
    if (!nsurl && self.URL.length > 0) {
        nsurl = [NSURL URLWithString:[self.URL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    }
    if (nsurl) {
        NSArray<NSURLQueryItem *> *queryItems = [[NSURLComponents alloc] initWithURL:nsurl resolvingAgainstBaseURL:false].queryItems;
        for (NSURLQueryItem *item in queryItems) {
            parameters[item.name] = [item.value stringByRemovingPercentEncoding];
        }
    }
    
    _parameters = [parameters copy];
    return _parameters;
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

// 打开URL Handler，openURL返回值不为nil时触发
@property (nonatomic, copy) void (^openHandler)(id result);

// 过滤器URL Handler，URL调用时优先触发
@property (nonatomic, copy) FWRouterHandler filterHandler;

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

#pragma mark - URL

+ (void)registerURL:(id)pattern withClass:(Class<FWRouterProtocol>)clazz
{
    if (![clazz conformsToProtocol:@protocol(FWRouterProtocol)]) return;
    if (![clazz respondsToSelector:@selector(fwRouterHandler:)]) return;
    
    [self registerURL:pattern withHandler:^id(FWRouterContext *context) {
        return [clazz fwRouterHandler:context];
    }];
}

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

#pragma mark - Handler

+ (void (^)(id))openHandler
{
    return [self sharedInstance].openHandler;
}

+ (void)setOpenHandler:(void (^)(id))handler
{
    [self sharedInstance].openHandler = handler;
}

+ (FWRouterHandler)filterHandler
{
    return [self sharedInstance].filterHandler;
}

+ (void)setFilterHandler:(FWRouterHandler)handler
{
    [self sharedInstance].filterHandler = handler;
}

+ (FWRouterHandler)errorHandler
{
    return [self sharedInstance].errorHandler;
}

+ (void)setErrorHandler:(FWRouterHandler)handler
{
    [self sharedInstance].errorHandler = handler;
}

#pragma mark - Open

+ (BOOL)canOpenURL:(id)URL
{
    NSString *rewriteURL = [self rewriteURL:URL];
    if (rewriteURL.length < 1) return NO;
    
    NSMutableDictionary *routeParameters = [[self sharedInstance] routeParametersFromURL:rewriteURL];
    return routeParameters[FWRouterBlockKey] ? YES : NO;
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
    
    URL = [rewriteURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    FWRouterContext *context = [[FWRouterContext alloc] initWithURL:URL userInfo:userInfo completion:completion];
    
    NSMutableDictionary *routeParameters = [[self sharedInstance] routeParametersFromURL:URL];
    FWRouterHandler handler = routeParameters[FWRouterBlockKey];
    [routeParameters removeObjectForKey:FWRouterBlockKey];
    context.routeParameters = [routeParameters copy];
    context.isOpen = YES;
    
    id result = nil;
    if ([self sharedInstance].filterHandler) {
        result = [self sharedInstance].filterHandler(context);
    }
    if (!result) {
        if (handler) {
            result = handler(context);
        } else if ([self sharedInstance].errorHandler) {
            result = [self sharedInstance].errorHandler(context);
        }
    }
    if (result && [self sharedInstance].openHandler) {
        [self sharedInstance].openHandler(result);
    }
}

+ (void)completeURL:(FWRouterContext *)context result:(id)result
{
    if (context.completion) {
        context.completion(result);
    }
}

#pragma mark - Object

+ (BOOL)isObjectURL:(id)URL
{
    NSString *rewriteURL = [self rewriteURL:URL];
    if (rewriteURL.length < 1) return NO;
    
    NSMutableDictionary *routeParameters = [[self sharedInstance] routeParametersFromURL:rewriteURL];
    return routeParameters[FWRouterBlockKey] ? YES : NO;
}

+ (id)objectForURL:(id)URL
{
    return [self objectForURL:URL userInfo:nil];
}

+ (id)objectForURL:(id)URL userInfo:(NSDictionary *)userInfo
{
    NSString *rewriteURL = [self rewriteURL:URL];
    if (rewriteURL.length < 1) return nil;
    
    URL = [rewriteURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    FWRouterContext *context = [[FWRouterContext alloc] initWithURL:URL userInfo:userInfo completion:nil];
    
    NSMutableDictionary *routeParameters = [[self sharedInstance] routeParametersFromURL:URL];
    FWRouterHandler handler = routeParameters[FWRouterBlockKey];
    [routeParameters removeObjectForKey:FWRouterBlockKey];
    context.routeParameters = [routeParameters copy];
    context.isOpen = NO;
    
    if ([self sharedInstance].filterHandler) {
        id result = [self sharedInstance].filterHandler(context);
        if (result) return result;
    }
    if (handler) {
        return handler(context);
    }
    if ([self sharedInstance].errorHandler) {
        return [self sharedInstance].errorHandler(context);
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
    
    NSURL *nsurl = URL.length > 0 ? [NSURL URLWithString:URL] : nil;
    if (!nsurl && URL.length > 0) {
        nsurl = [NSURL URLWithString:[URL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    }
    for (NSString *pathComponent in [nsurl pathComponents]) {
        if ([pathComponent isEqualToString:@"/"]) continue;
        if ([[pathComponent substringToIndex:1] isEqualToString:@"?"]) break;
        [pathComponents addObject:pathComponent];
    }
    return [pathComponents copy];
}

- (NSMutableDictionary *)routeParametersFromURL:(NSString *)url
{
    NSMutableDictionary *routeParameters = [NSMutableDictionary dictionary];
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
                routeParameters[newKey] = [newPathComponent stringByRemovingPercentEncoding];
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
    
    if (subRoutes[FWRouterCoreKey]) {
        routeParameters[FWRouterBlockKey] = [subRoutes[FWRouterCoreKey] copy];
    }
    return routeParameters;
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
