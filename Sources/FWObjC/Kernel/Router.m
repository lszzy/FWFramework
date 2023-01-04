//
//  Router.m
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import "Router.h"
#import "Loader.h"
#import "Navigator.h"
#import <objc/runtime.h>

#if FWMacroSPM

@interface NSObject ()

+ (NSArray<NSString *> *)fw_classMethods:(Class)clazz superclass:(BOOL)superclass;

@end

@interface UIWindow ()

@property (class, nonatomic, readwrite, nullable) UIWindow *fw_mainWindow;
- (void)fw_open:(UIViewController *)viewController animated:(BOOL)animated options:(__FWNavigatorOptions)options completion:(nullable void (^)(void))completion;

@end

#else

#import <FWFramework/FWFramework-Swift.h>

#endif

__FWRouterUserInfoKey const __FWRouterSourceKey = @"routerSource";
__FWRouterUserInfoKey const __FWRouterOptionsKey = @"routerOptions";
__FWRouterUserInfoKey const __FWRouterHandlerKey = @"routerHandler";

#pragma mark - __FWRouterContext

@interface __FWRouterContext ()

@property (nonatomic, copy) NSDictionary *URLParameters;
@property (nonatomic, copy) NSDictionary *parameters;
@property (nonatomic, assign) BOOL isOpening;

+ (NSURL *)URLWithString:(NSString *)URLString;

@end

@implementation __FWRouterContext

- (instancetype)initWithURL:(NSString *)URL userInfo:(NSDictionary *)userInfo completion:(__FWRouterCompletion)completion
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
    __FWRouterContext *context = [[[self class] allocWithZone:zone] initWithURL:self.URL userInfo:self.userInfo completion:self.completion];
    context.URLParameters = self.URLParameters;
    context.isOpening = self.isOpening;
    return context;
}

- (NSDictionary<NSString *,NSString *> *)URLParameters
{
    if (!_URLParameters) {
        NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
        NSURL *nsurl = [__FWRouterContext URLWithString:self.URL];
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

#pragma mark - __FWRouter

static NSString * const __FWRouterWildcardCharacter = @"*";
static NSString * __FWRouterSpecialCharacters = @"/?&.";

static NSString * const __FWRouterCoreKey = @"__FWRouterCore";
static NSString * const __FWRouterBlockKey = @"__FWRouterBlock";

NSString *const __FWRouterRewriteMatchRuleKey = @"matchRule";
NSString *const __FWRouterRewriteTargetRuleKey = @"targetRule";

NSString *const __FWRouterRewriteComponentURLKey = @"url";
NSString *const __FWRouterRewriteComponentSchemeKey = @"scheme";
NSString *const __FWRouterRewriteComponentHostKey = @"host";
NSString *const __FWRouterRewriteComponentPortKey = @"port";
NSString *const __FWRouterRewriteComponentPathKey = @"path";
NSString *const __FWRouterRewriteComponentQueryKey = @"query";
NSString *const __FWRouterRewriteComponentFragmentKey = @"fragment";

@interface __FWRouter ()

// 路由列表，结构类似 @{@"beauty": @{@":id": {__FWRouterCoreKey: [block copy]}}}
@property (nonatomic, strong) NSMutableDictionary *routes;

@property (nonatomic, copy) BOOL (^routeFilter)(__FWRouterContext *context);
@property (nonatomic, copy) id (^routeHandler)(__FWRouterContext *context, id object);
@property (nonatomic, copy) void (^errorHandler)(__FWRouterContext *context);

@property (nonatomic, copy) NSString * (^rewriteFilter)(NSString *url);
@property (nonatomic, strong) NSMutableArray *rewriteRules;

@property (nonatomic, strong) __FWLoader<NSString *, id> *routeLoader;

@end

@implementation __FWRouter

+ (__FWRouter *)sharedInstance
{
    static __FWRouter *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[__FWRouter alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _routes = [[NSMutableDictionary alloc] init];
        _rewriteRules = [[NSMutableArray alloc] init];
        _routeLoader = [[__FWLoader<NSString *, id> alloc] init];
    }
    return self;
}

+ (__FWLoader<NSString *,id> *)sharedLoader
{
    return [self sharedInstance].routeLoader;
}

#pragma mark - Class

+ (BOOL)registerClass:(id)clazz withMapper:(NSDictionary<NSString *,NSString *> * (^)(NSArray<NSString *> *))mapper
{
    return [self registerClass:clazz isPreset:NO withMapper:mapper];
}

+ (BOOL)presetClass:(id)clazz withMapper:(NSDictionary<NSString *,NSString *> * (^)(NSArray<NSString *> *))mapper
{
    return [self registerClass:clazz isPreset:YES withMapper:mapper];
}

+ (BOOL)registerClass:(id)clazz isPreset:(BOOL)isPreset withMapper:(NSDictionary<NSString *,NSString *> * (^)(NSArray<NSString *> *))mapper
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    __block BOOL result = YES;
    NSDictionary<NSString *,NSString *> *routes = [self routeClass:clazz withMapper:mapper];
    [routes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        id pattern = [clazz performSelector:NSSelectorFromString(key)];
        result = [self registerURL:pattern withHandler:^id _Nullable(__FWRouterContext * _Nonnull context) {
            return [clazz performSelector:NSSelectorFromString(obj) withObject:context];
        } isPreset:isPreset] && result;
    }];
    return result;
#pragma clang diagnostic pop
}

+ (void)unregisterClass:(id)clazz withMapper:(NSDictionary<NSString *,NSString *> * (^)(NSArray<NSString *> *))mapper
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSDictionary<NSString *,NSString *> *routes = [self routeClass:clazz withMapper:mapper];
    [routes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        id pattern = [clazz performSelector:NSSelectorFromString(key)];
        [self unregisterURL:pattern];
    }];
#pragma clang diagnostic pop
}

+ (NSDictionary<NSString *,NSString *> *)routeClass:(id)clazz withMapper:(NSDictionary<NSString *,NSString *> * (^)(NSArray<NSString *> *))mapper
{
    Class metaClass;
    if (object_isClass(clazz)) {
        metaClass = objc_getMetaClass(NSStringFromClass(clazz).UTF8String);
    } else {
        metaClass = object_getClass(clazz);
    }
    if (!metaClass) return @{};
    
    NSArray<NSString *> *methods = [NSObject fw_classMethods:metaClass superclass:NO];
    if (mapper) {
        return mapper(methods);
    }
    
    NSMutableDictionary *routes = [NSMutableDictionary dictionary];
    for (NSString *method in methods) {
        if (![method hasSuffix:@"Url"] || [method containsString:@":"]) continue;
        
        NSString *handler = [method stringByReplacingOccurrencesOfString:@"Url" withString:@"Router:"];
        if (![methods containsObject:handler]) {
            handler = [method stringByReplacingOccurrencesOfString:@"Url" withString:@"DefaultRouter:"];
            if (![methods containsObject:handler]) continue;
        }
        
        routes[method] = handler;
    }
    return routes;
}

#pragma mark - URL

+ (BOOL)registerURL:(id)pattern withHandler:(__FWRouterHandler)handler
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

+ (BOOL)presetURL:(id)pattern withHandler:(__FWRouterHandler)handler
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

+ (BOOL)registerURL:(NSString *)pattern withHandler:(__FWRouterHandler)handler isPreset:(BOOL)isPreset
{
    if (![pattern isKindOfClass:[NSString class]]) return NO;
    if (!handler || pattern.length < 1) return NO;
    
    NSMutableDictionary *subRoutes = [[self sharedInstance] registerRoute:pattern];
    if (!subRoutes) return NO;
    if (isPreset && subRoutes[__FWRouterCoreKey] != nil) return NO;
    
    subRoutes[__FWRouterCoreKey] = [handler copy];
    return YES;
}

+ (void)unregisterURL:(id)pattern
{
    if ([pattern isKindOfClass:[NSArray class]]) {
        for (id subPattern in pattern) {
            [self unregisterURL:subPattern];
        }
    } else if ([pattern isKindOfClass:[NSString class]]) {
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

+ (void)setRouteFilter:(BOOL (^)(__FWRouterContext *))filter
{
    [self sharedInstance].routeFilter = filter;
}

+ (void)setRouteHandler:(id (^)(__FWRouterContext *, id))handler
{
    [self sharedInstance].routeHandler = handler;
}

+ (void)presetRouteHandler:(id (^)(__FWRouterContext *, id))handler
{
    if ([self sharedInstance].routeHandler) return;
    
    [self sharedInstance].routeHandler = handler ?: ^id(__FWRouterContext *context, id object) {
        if (!context.isOpening) return object;
        if (![object isKindOfClass:[UIViewController class]]) return object;
        
        UIViewController *viewController = (UIViewController *)object;
        void (^routerHandler)(__FWRouterContext *context, UIViewController *viewController) = context.userInfo[__FWRouterHandlerKey];
        if (routerHandler != nil) {
            routerHandler(context, viewController);
        } else {
            __FWNavigatorOptions options = 0;
            NSNumber *routerOptions = context.userInfo[__FWRouterOptionsKey];
            if (routerOptions && [routerOptions isKindOfClass:[NSNumber class]]) {
                options = [routerOptions unsignedIntegerValue];
            }
            [UIWindow.__fw_mainWindow __fw_open:viewController animated:YES options:options completion:nil];
        }
        return nil;
    };
}

+ (void)setErrorHandler:(void (^)(__FWRouterContext *))handler
{
    [self sharedInstance].errorHandler = handler;
}

#pragma mark - Open

+ (BOOL)canOpenURL:(id)URL
{
    NSString *rewriteURL = [self rewriteURL:URL];
    if (rewriteURL.length < 1) return NO;
    
    NSMutableDictionary *URLParameters = [[self sharedInstance] routeParametersFromURL:rewriteURL];
    return URLParameters[__FWRouterBlockKey] ? YES : NO;
}

+ (void)openURL:(id)URL
{
    [self openURL:URL completion:nil];
}

+ (void)openURL:(id)URL userInfo:(NSDictionary *)userInfo
{
    [self openURL:URL userInfo:userInfo completion:nil];
}

+ (void)openURL:(id)URL completion:(__FWRouterCompletion)completion
{
    [self openURL:URL userInfo:nil completion:completion];
}

+ (void)openURL:(id)URL userInfo:(NSDictionary *)userInfo completion:(__FWRouterCompletion)completion
{
    NSString *rewriteURL = [self rewriteURL:URL];
    if (rewriteURL.length < 1) return;
    
    NSMutableDictionary *URLParameters = [[self sharedInstance] routeParametersFromURL:rewriteURL];
    __FWRouterHandler handler = URLParameters[__FWRouterBlockKey];
    [URLParameters removeObjectForKey:__FWRouterBlockKey];
    
    __FWRouterContext *context = [[__FWRouterContext alloc] initWithURL:rewriteURL userInfo:userInfo completion:completion];
    context.URLParameters = [URLParameters copy];
    context.isOpening = YES;
    
    if ([self sharedInstance].routeFilter) {
        if (![self sharedInstance].routeFilter(context)) return;
    }
    if (handler) {
        id object = handler(context);
        if (object && [self sharedInstance].routeHandler) {
            [self sharedInstance].routeHandler(context, object);
        }
        return;
    }
    if ([self sharedInstance].errorHandler) {
        [self sharedInstance].errorHandler(context);
    }
}

+ (void)completeURL:(__FWRouterContext *)context result:(id)result
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
    __FWRouterHandler handler = URLParameters[__FWRouterBlockKey];
    [URLParameters removeObjectForKey:__FWRouterBlockKey];
    
    __FWRouterContext *context = [[__FWRouterContext alloc] initWithURL:rewriteURL userInfo:userInfo completion:nil];
    context.URLParameters = [URLParameters copy];
    context.isOpening = NO;
    
    if ([self sharedInstance].routeFilter) {
        if (![self sharedInstance].routeFilter(context)) return nil;
    }
    if (handler) {
        id object = handler(context);
        if (object && [self sharedInstance].routeHandler) {
            return [self sharedInstance].routeHandler(context, object);
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
        if ([__FWRouterSpecialCharacters rangeOfString:character].location != NSNotFound && i > (startIndexOfColon + 1) && startIndexOfColon) {
            NSRange range = NSMakeRange(startIndexOfColon, i - startIndexOfColon);
            NSString *placeholder = [pattern substringWithRange:range];
            NSCharacterSet *specialCharactersSet = [NSCharacterSet characterSetWithCharactersInString:__FWRouterSpecialCharacters];
            if ([placeholder rangeOfCharacterFromSet:specialCharactersSet].location == NSNotFound) {
                [placeholders addObject:placeholder];
                startIndexOfColon = 0;
            }
        }
        if (i == pattern.length - 1 && startIndexOfColon) {
            NSRange range = NSMakeRange(startIndexOfColon, i - startIndexOfColon + 1);
            NSString *placeholder = [pattern substringWithRange:range];
            NSCharacterSet *specialCharactersSet = [NSCharacterSet characterSetWithCharactersInString:__FWRouterSpecialCharacters];
            if ([placeholder rangeOfCharacterFromSet:specialCharactersSet].location == NSNotFound) {
                [placeholders addObject:placeholder];
            }
        }
    }
    
    __block NSString *parsedResult = pattern;
    
    if ([parameters isKindOfClass:[NSArray class]]) {
        [placeholders enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (idx < [parameters count]) {
                id value = [parameters objectAtIndex:idx];
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
    NSURL *fullUrl = [__FWRouterContext URLWithString:URL];
    if (urlRange.location == NSNotFound) {
        // 解析scheme:path格式
        NSString *urlScheme = [fullUrl.scheme stringByAppendingString:@":"];
        if (urlScheme.length > 1 && [URL hasPrefix:urlScheme]) {
            urlRange = NSMakeRange(urlScheme.length - 1, 1);
        }
    }
    
    if (urlRange.location != NSNotFound) {
        // 如果 URL 包含协议，那么把协议作为第一个元素放进去
        NSString *pathScheme = [URL substringToIndex:urlRange.location];
        if (pathScheme.length > 0) [pathComponents addObject:pathScheme];
        
        // 如果只有协议，那么放一个占位符
        URL = [URL substringFromIndex:urlRange.location + urlRange.length];
        if (!URL.length) [pathComponents addObject:__FWRouterWildcardCharacter];
    }
    
    NSURL *pathUrl = [__FWRouterContext URLWithString:URL];
    NSArray<NSString *> *components = [pathUrl pathComponents];
    if (!components && urlRange.location != NSNotFound && URL.length > 0 && fullUrl) {
        NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:fullUrl resolvingAgainstBaseURL:NO];
        if (urlComponents && urlComponents.rangeOfPath.location != NSNotFound) {
            NSString *pathDomain = [URL substringToIndex:urlComponents.rangeOfPath.location - (urlRange.location + urlRange.length)];
            if (pathDomain.length > 0) [pathComponents addObject:pathDomain];
        }
        components = [fullUrl pathComponents];
    }
    for (NSString *pathComponent in components) {
        if (pathComponent.length < 1 || [pathComponent isEqualToString:@"/"]) continue;
        if ([[pathComponent substringToIndex:1] isEqualToString:@"?"]) break;
        [pathComponents addObject:pathComponent];
    }
    return [pathComponents copy];
}

- (NSMutableDictionary *)routeParametersFromURL:(NSString *)url
{
    NSMutableDictionary *parameters = [self extractParametersFromURL:url];
    if (parameters[__FWRouterBlockKey]) return parameters;
    
    id object = [self.routeLoader load:url];
    if (object) {
        [__FWRouter registerClass:object withMapper:nil];
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
            if ([key isEqualToString:pathComponent] || [key isEqualToString:__FWRouterWildcardCharacter]) {
                wildcardMatched = YES;
                subRoutes = subRoutes[key];
                break;
            } else if ([key hasPrefix:@":"]) {
                wildcardMatched = YES;
                subRoutes = subRoutes[key];
                NSString *newKey = [key substringFromIndex:1];
                NSString *newPathComponent = pathComponent;
                // 再做一下特殊处理，比如 :id.html -> :id
                NSCharacterSet *specialCharactersSet = [NSCharacterSet characterSetWithCharactersInString:__FWRouterSpecialCharacters];
                if ([key rangeOfCharacterFromSet:specialCharactersSet].location != NSNotFound) {
                    NSCharacterSet *specialCharacterSet = [NSCharacterSet characterSetWithCharactersInString:__FWRouterSpecialCharacters];
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
        if (!wildcardMatched && !subRoutes[__FWRouterCoreKey]) {
            break;
        }
    }
    
    NSURL *nsurl = [__FWRouterContext URLWithString:url];
    if (nsurl) {
        NSArray<NSURLQueryItem *> *queryItems = [[NSURLComponents alloc] initWithURL:nsurl resolvingAgainstBaseURL:false].queryItems;
        // queryItems.value会自动进行URL参数解码
        for (NSURLQueryItem *item in queryItems) {
            parameters[item.name] = item.value;
        }
    }
    
    if (subRoutes[__FWRouterCoreKey]) {
        parameters[__FWRouterBlockKey] = [subRoutes[__FWRouterCoreKey] copy];
    } else {
        [parameters removeObjectForKey:__FWRouterBlockKey];
    }
    return parameters;
}

#pragma mark - Rewrite

+ (NSString *)rewriteURL:(id)URL
{
    NSString *rewriteURL = [URL isKindOfClass:[NSURL class]] ? [URL absoluteString] : URL;
    if (!rewriteURL || ![rewriteURL isKindOfClass:[NSString class]]) return nil;
    
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
        if ([[ruleDic objectForKey:__FWRouterRewriteMatchRuleKey] isEqualToString:matchRule]) {
            [[self sharedInstance].rewriteRules removeObject:ruleDic];
        }
    }
    
    NSDictionary *ruleDic = @{__FWRouterRewriteMatchRuleKey:matchRule,__FWRouterRewriteTargetRuleKey:targetRule};
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
        NSString *matchRule = [ruleDic objectForKey:__FWRouterRewriteMatchRuleKey];
        NSString *targetRule = [ruleDic objectForKey:__FWRouterRewriteTargetRuleKey];
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
        if ([[ruleDic objectForKey:__FWRouterRewriteMatchRuleKey] isEqualToString:matchRule]) {
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
            NSString *matchRule = [rule objectForKey:__FWRouterRewriteMatchRuleKey];
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
                NSString *targetRule = [rule objectForKey:__FWRouterRewriteTargetRuleKey];
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
    [componentDic setValue:originalURL forKey:__FWRouterRewriteComponentURLKey];
    [componentDic setValue:urlComponents.scheme forKey:__FWRouterRewriteComponentSchemeKey];
    [componentDic setValue:urlComponents.host forKey:__FWRouterRewriteComponentHostKey];
    [componentDic setValue:urlComponents.port forKey:__FWRouterRewriteComponentPortKey];
    [componentDic setValue:urlComponents.path forKey:__FWRouterRewriteComponentPathKey];
    [componentDic setValue:urlComponents.query forKey:__FWRouterRewriteComponentQueryKey];
    [componentDic setValue:urlComponents.fragment forKey:__FWRouterRewriteComponentFragmentKey];
    
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
