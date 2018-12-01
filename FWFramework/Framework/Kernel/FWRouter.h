/*!
 @header     FWRouter.h
 @indexgroup FWFramework
 @brief      URL路由
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/11/29
 */

#import <Foundation/Foundation.h>

/*! @brief 路由URL */
extern NSString * const FWRouterURLKey;

/*! @brief 路由完成回调 */
extern NSString * const FWRouterCompletionKey;

/*! @brief 路由用户信息 */
extern NSString * const FWRouterUserInfoKey;

/*! @brief 路由处理句柄 */
typedef void (^FWRouterHandler)(NSDictionary *parameters);

/*! @brief 路由对象处理句柄 */
typedef id (^FWRouterObjectHandler)(NSDictionary *parameters);

/*! @brief 路由错误处理句柄 */
typedef void (^FWRouterErrorHandler)(NSString *URL);

/*!
 @brief URL路由
 
 @see https://github.com/meili/MGJRouter
 */
@interface FWRouter : NSObject

/**
 *  注册 pattern 对应的 Handler，在 handler 中可以初始化 VC，然后对 VC 做各种操作
 *
 *  @param pattern    带上 scheme，如 app://beauty/:id
 *  @param handler    该 block 会传一个字典，包含了注册的 URL 中对应的变量。
 *                    假如注册的 URL 为 app://beauty/:id 那么，就会传一个 @{@"id": 4} 这样的字典过来
 */
+ (void)registerURL:(NSString *)pattern withHandler:(FWRouterHandler)handler;

/**
 *  注册 pattern 对应的 ObjectHandler，需要返回一个 object 给调用方
 *
 *  @param pattern    带上 scheme，如 app://beauty/:id
 *  @param handler    该 block 会传一个字典，包含了注册的 URL 中对应的变量。
 *                    假如注册的 URL 为 app://beauty/:id 那么，就会传一个 @{@"id": 4} 这样的字典过来
 *                    自带的 key 为 @"url" 和 @"completion" (如果有的话)
 */
+ (void)registerURL:(NSString *)pattern withObjectHandler:(FWRouterObjectHandler)handler;

/**
 *  注册 错误 对应的 Handler，URL 未注册时触发
 *
 *  @param handler    该 block 回传不支持的URL参数
 */
+ (void)registerErrorHandler:(FWRouterErrorHandler)handler;

/**
 *  取消注册某个 pattern
 *
 *  @param pattern pattern
 */
+ (void)unregisterURL:(NSString *)pattern;

/**
 *  取消注册所有 pattern
 */
+ (void)unregisterAllURLs;

/**
 *  是否可以打开URL
 *
 *  @param URL 带 Scheme，如 app://beauty/3
 *
 *  @return 返回BOOL值
 */
+ (BOOL)canOpenURL:(NSString *)URL;

/**
 *  打开此 URL
 *  会在已注册的 URL -> Handler 中寻找，如果找到，则执行 Handler
 *
 *  @param URL 带 Scheme，如 app://beauty/3
 */
+ (void)openURL:(NSString *)URL;

/**
 *  打开此 URL，同时当操作完成时，执行额外的代码
 *
 *  @param URL        带 Scheme 的 URL，如 app://beauty/4
 *  @param completion URL 处理完成后的 callback，完成的判定跟具体的业务相关
 */
+ (void)openURL:(NSString *)URL completion:(void (^)(id result))completion;

/**
 *  打开此 URL，带上附加信息，同时当操作完成时，执行额外的代码
 *
 *  @param URL        带 Scheme 的 URL，如 app://beauty/4
 *  @param userInfo   附加参数
 *  @param completion URL 处理完成后的 callback，完成的判定跟具体的业务相关
 */
+ (void)openURL:(NSString *)URL withUserInfo:(NSDictionary *)userInfo completion:(void (^)(id result))completion;

/**
 * 查找谁对某个 URL 感兴趣，如果有的话，返回一个 object
 *
 *  @param URL 带 Scheme，如 app://beauty/3
 */
+ (id)objectForURL:(NSString *)URL;

/**
 * 查找谁对某个 URL 感兴趣，如果有的话，返回一个 object
 *
 *  @param URL 带 Scheme，如 app://beauty/3
 *  @param userInfo 附加参数
 */
+ (id)objectForURL:(NSString *)URL withUserInfo:(NSDictionary *)userInfo;

/**
 *  调用此方法来拼接 pattern 和 parameters
 *
 *  #define APP_ROUTE_BEAUTY @"beauty/:id"
 *  [FWRouter generateURL:APP_ROUTE_BEAUTY, @[@13]];
 *
 *
 *  @param pattern    url pattern 比如 @"beauty/:id"
 *  @param parameters 一个数组，数量要跟 pattern 里的变量一致
 *
 *  @return 返回生成的URL String
 */
+ (NSString *)generateURL:(NSString *)pattern parameters:(NSArray *)parameters;

@end
