/*!
 @header     FWRouter.m
 @indexgroup FWFramework
 @brief      FWRouter
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/11/29
 */

#import "FWRouter.h"

static NSString * const FWRouterWildcardCharacter = @"*";
static NSString * FWRouterSpecialCharacters = @"/?&.";

static NSString * const FWRouterCoreKey = @"FWRouterCore";
static NSString * const FWRouterBlockKey = @"FWRouterBlock";

NSString * const FWRouterURLKey = @"FWRouterURL";
NSString * const FWRouterCompletionKey = @"FWRouterCompletion";
NSString * const FWRouterUserInfoKey = @"FWRouterUserInfo";

@interface FWRouter ()

// 路由列表，结构类似 @{@"beauty": @{@":id": {FWRouterCoreKey, [block copy]}}}
@property (nonatomic, strong) NSMutableDictionary *routes;

// 错误URL Handler，未注册时调用
@property (nonatomic, copy) FWRouterErrorHandler errorHandler;

@end

@implementation FWRouter

+ (instancetype)sharedInstance
{
    static FWRouter *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

+ (void)registerURL:(NSString *)pattern withHandler:(FWRouterHandler)handler
{
    [[self sharedInstance] addRoute:pattern withHandler:handler];
}

+ (void)registerErrorHandler:(FWRouterErrorHandler)handler
{
    [[self sharedInstance] setErrorHandler:handler];
}

+ (void)unregisterURL:(NSString *)pattern
{
    [[self sharedInstance] removeRoute:pattern];
}

+ (void)unregisterAllURLs
{
    [[self sharedInstance] removeAllRoutes];
}

+ (void)openURL:(NSString *)URL
{
    [self openURL:URL completion:nil];
}

+ (void)openURL:(NSString *)URL completion:(void (^)(id result))completion
{
    [self openURL:URL withUserInfo:nil completion:completion];
}

+ (void)openURL:(NSString *)URL withUserInfo:(NSDictionary *)userInfo completion:(void (^)(id result))completion
{
    URL = [URL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *parameters = [[self sharedInstance] extractParametersFromURL:URL];
    if (!parameters) {
        [[self sharedInstance] handleErrorWithURL:URL];
        return;
    }
    
    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, NSString *obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            parameters[key] = [obj stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
    }];
    
    if (parameters) {
        FWRouterHandler handler = parameters[FWRouterBlockKey];
        if (completion) {
            parameters[FWRouterCompletionKey] = completion;
        }
        if (userInfo) {
            parameters[FWRouterUserInfoKey] = userInfo;
        }
        if (handler) {
            [parameters removeObjectForKey:FWRouterBlockKey];
            handler(parameters);
        }
    }
}

+ (BOOL)canOpenURL:(NSString *)URL
{
    return [[self sharedInstance] extractParametersFromURL:URL] ? YES : NO;
}

+ (NSString *)generateURL:(NSString *)pattern parameters:(NSArray *)parameters
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
    
    [placeholders enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        idx = parameters.count > idx ? idx : parameters.count - 1;
        parsedResult = [parsedResult stringByReplacingOccurrencesOfString:obj withString:parameters[idx]];
    }];
    
    return parsedResult;
}

+ (id)objectForURL:(NSString *)URL withUserInfo:(NSDictionary *)userInfo
{
    FWRouter *router = [FWRouter sharedInstance];
    
    URL = [URL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *parameters = [router extractParametersFromURL:URL];
    if (!parameters) {
        [[self sharedInstance] handleErrorWithURL:URL];
        return nil;
    }
    
    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, NSString *obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            parameters[key] = [obj stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
    }];
    
    FWRouterObjectHandler handler = parameters[FWRouterBlockKey];
    if (handler) {
        if (userInfo) {
            parameters[FWRouterUserInfoKey] = userInfo;
        }
        [parameters removeObjectForKey:FWRouterBlockKey];
        return handler(parameters);
    }
    return nil;
}

+ (id)objectForURL:(NSString *)URL
{
    return [self objectForURL:URL withUserInfo:nil];
}

+ (void)registerURL:(NSString *)pattern withObjectHandler:(FWRouterObjectHandler)handler
{
    [[self sharedInstance] addRoute:pattern withObjectHandler:handler];
}

- (void)addRoute:(NSString *)pattern withHandler:(FWRouterHandler)handler
{
    NSMutableDictionary *subRoutes = [self addRoute:pattern];
    if (handler && subRoutes) {
        subRoutes[FWRouterCoreKey] = [handler copy];
    }
}

- (void)addRoute:(NSString *)pattern withObjectHandler:(FWRouterObjectHandler)handler
{
    NSMutableDictionary *subRoutes = [self addRoute:pattern];
    if (handler && subRoutes) {
        subRoutes[FWRouterCoreKey] = [handler copy];
    }
}

- (NSMutableDictionary *)addRoute:(NSString *)pattern
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

#pragma mark - Private

- (NSMutableDictionary *)extractParametersFromURL:(NSString *)url
{
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    
    parameters[FWRouterURLKey] = url;
    
    NSMutableDictionary* subRoutes = self.routes;
    NSArray* pathComponents = [self pathComponentsFromURL:url];
    
    BOOL wildcardMatched = NO;
    // borrowed from HHRouter(https://github.com/Huohua/HHRouter)
    for (NSString *pathComponent in pathComponents) {
        
        // 对 key 进行排序，这样可以把 ~ 放到最后
        NSArray *subRoutesKeys =[subRoutes.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
            return [obj1 compare:obj2];
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
            return nil;
        }
    }
    
    // Extract Params From Query.
    NSArray<NSURLQueryItem *> *queryItems = [[NSURLComponents alloc] initWithURL:[[NSURL alloc] initWithString:url] resolvingAgainstBaseURL:false].queryItems;
    
    for (NSURLQueryItem *item in queryItems) {
        parameters[item.name] = item.value;
    }
    
    if (subRoutes[FWRouterCoreKey]) {
        parameters[FWRouterBlockKey] = [subRoutes[FWRouterCoreKey] copy];
    }
    
    return parameters;
}

- (void)handleErrorWithURL:(NSString *)URL
{
    if (self.errorHandler) {
        self.errorHandler(URL);
    }
}

- (void)removeRoute:(NSString *)pattern
{
    NSMutableArray *pathComponents = [NSMutableArray arrayWithArray:[self pathComponentsFromURL:pattern]];
    
    // 只删除该 pattern 的最后一级
    if (pathComponents.count >= 1) {
        // 假如 URLPattern 为 a/b/c, components 就是 @"a.b.c" 正好可以作为 KVC 的 key
        NSString *components = [pathComponents componentsJoinedByString:@"."];
        NSMutableDictionary *route = [self.routes valueForKeyPath:components];
        
        if (route.count >= 1) {
            NSString *lastComponent = [pathComponents lastObject];
            [pathComponents removeLastObject];
            
            // 有可能是根 key，这样就是 self.routes 了
            route = self.routes;
            if (pathComponents.count) {
                NSString *componentsWithoutLast = [pathComponents componentsJoinedByString:@"."];
                route = [self.routes valueForKeyPath:componentsWithoutLast];
            }
            [route removeObjectForKey:lastComponent];
        }
    }
}

- (void)removeAllRoutes
{
    [self.routes removeAllObjects];
}

- (NSArray *)pathComponentsFromURL:(NSString*)URL
{
    NSMutableArray *pathComponents = [NSMutableArray array];
    if ([URL rangeOfString:@"://"].location != NSNotFound) {
        NSArray *pathSegments = [URL componentsSeparatedByString:@"://"];
        // 如果 URL 包含协议，那么把协议作为第一个元素放进去
        [pathComponents addObject:pathSegments[0]];
        
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

- (NSMutableDictionary *)routes
{
    if (!_routes) {
        _routes = [[NSMutableDictionary alloc] init];
    }
    return _routes;
}

@end
