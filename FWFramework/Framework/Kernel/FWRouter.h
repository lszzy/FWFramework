/*!
 @header     FWRouter.h
 @indexgroup FWFramework
 @brief      URL路由
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/11/29
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*! @brief 路由URL */
extern NSString * const FWRouterURLKey;

/*! @brief 路由完成回调 */
extern NSString * const FWRouterCompletionKey;

/*! @brief 路由用户信息 */
extern NSString * const FWRouterUserInfoKey;

/*! @brief 路由处理句柄 */
typedef void (^FWRouterHandler)(NSDictionary *parameters);

/*! @brief 路由对象处理句柄 */
typedef id _Nullable (^FWRouterObjectHandler)(NSDictionary *parameters);

/*! @brief 路由过滤器处理句柄 */
typedef BOOL (^FWRouterFilterHandler)(NSDictionary *parameters);

#pragma mark - FWRouter

/*!
 @brief URL路由协议
 */
@protocol FWRouterProtocol <NSObject>

@optional

/// 支持的路由URL
+ (id)fwRouterURL;

/// 支持的Object路由URL
+ (id)fwRouterObjectURL;

/// 路由方法
+ (void)fwRouterHandler:(NSDictionary *)parameters;

/// 对象路由方法
+ (id)fwRouterObjectHandler:(NSDictionary *)parameters;

@end

/*!
 @brief URL路由器
 
 @see https://github.com/meili/MGJRouter
 */
@interface FWRouter : NSObject

#pragma mark - Class

/**
*  注册路由类，需要实现FWRouterProtocol协议
*
*  @param cls         路由类，需实现FWRouterProtocol协议
*/
+ (void)registerClass:(Class)cls;

/**
 *  取消注册某个路由类
 *
 *  @param cls         路由类，需实现FWRouterProtocol协议
 */
+ (void)unregisterClass:(Class)cls;

#pragma mark - URL

/**
 *  注册 pattern 对应的 Handler，在 handler 中可以初始化 VC，然后对 VC 做各种操作
 *
 *  @param pattern    字符串或字符串数组(批量)，带上 scheme，如 app://beauty/:id
 *  @param handler    该 block 会传一个字典，包含了注册的 URL 中对应的变量。
 *                    假如注册的 URL 为 app://beauty/:id 那么，就会传一个 @{@"id": 4} 这样的字典过来
 */
+ (void)registerURL:(id)pattern withHandler:(FWRouterHandler)handler;

/**
 *  注册 pattern 对应的 ObjectHandler，需要返回一个 object 给调用方
 *
 *  @param pattern    字符串或字符串数组(批量)，带上 scheme，如 app://beauty/:id
 *  @param handler    该 block 会传一个字典，包含了注册的 URL 中对应的变量。
 *                    假如注册的 URL 为 app://beauty/:id 那么，就会传一个 @{@"id": 4} 这样的字典过来
 */
+ (void)registerURL:(id)pattern withObjectHandler:(FWRouterObjectHandler)handler;

/**
 *  取消注册某个 pattern
 *
 *  @param pattern    字符串或字符串数组(批量)
 */
+ (void)unregisterURL:(id)pattern;

/**
 *  取消注册所有 pattern
 */
+ (void)unregisterAllURLs;

#pragma mark - Filter

/**
 *  设置 过滤器 对应的 Handler，URL 调用时触发
 *
 *  @param handler    该 block 会传一个字典，包含了注册的 URL 中对应的变量。
 *                    假如注册的 URL 为 app://beauty/:id 那么，就会传一个 @{@"id": 4} 这样的字典过来
 *                    如果 block 返回YES，则继续解析pattern；如果返回NO，则停止解析
 */
+ (void)setFilterHandler:(nullable FWRouterFilterHandler)handler;

/**
 *  设置 错误 对应的 Handler，URL 未注册时触发
 *
 *  @param handler    该 block 回传不支持的URL参数
 */
+ (void)setErrorHandler:(nullable FWRouterHandler)handler;

#pragma mark - Open

/**
 *  是否可以打开URL，不含object
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
 *  @param userInfo   附加参数
 */
+ (void)openURL:(NSString *)URL userInfo:(nullable NSDictionary *)userInfo;

/**
 *  打开此 URL，同时当操作完成时，执行额外的代码
 *
 *  @param URL        带 Scheme 的 URL，如 app://beauty/4
 *  @param completion URL 处理完成后的 callback，完成的判定跟具体的业务相关
 */
+ (void)openURL:(NSString *)URL completion:(nullable void (^)(id _Nullable result))completion;

/**
 *  打开此 URL，带上附加信息，同时当操作完成时，执行额外的代码
 *
 *  @param URL        带 Scheme 的 URL，如 app://beauty/4
 *  @param userInfo   附加参数
 *  @param completion URL 处理完成后的 callback，完成的判定跟具体的业务相关
 */
+ (void)openURL:(NSString *)URL userInfo:(nullable NSDictionary *)userInfo completion:(nullable void (^)(id _Nullable result))completion;

#pragma mark - Object

/**
 * 检测是否已注册object
 *
 *  @param URL 带 Scheme，如 app://beauty/3
 */
+ (BOOL)isObjectURL:(NSString *)URL;

/**
 * 查找谁对某个 URL 感兴趣，如果有的话，返回一个 object；如果没有，返回nil
 *
 *  @param URL 带 Scheme，如 app://beauty/3
 */
+ (nullable id)objectForURL:(NSString *)URL;

/**
 * 查找谁对某个 URL 感兴趣，如果有的话，返回一个 object；如果没有，返回nil
 *
 *  @param URL 带 Scheme，如 app://beauty/3
 *  @param userInfo 附加参数
 */
+ (nullable id)objectForURL:(NSString *)URL userInfo:(nullable NSDictionary *)userInfo;

#pragma mark - Generator

/**
 *  调用此方法来拼接 pattern 和 parameters
 *
 *  #define APP_ROUTE_BEAUTY @"beauty/:id"
 *  [FWRouter generateURL:APP_ROUTE_BEAUTY, @[@13]];
 *  [FWRouter generateURL:APP_ROUTE_BEAUTY, @{@"id":@13}];
 *
 *  @param pattern    url pattern 比如 @"beauty/:id"
 *  @param parameters 一个数组(数量和变量一致)或一个字典(key为变量名称)或单个值(替换所有参数)
 *
 *  @return 返回生成的URL String
 */
+ (NSString *)generateURL:(NSString *)pattern parameters:(nullable id)parameters;

@end

#pragma mark - FWRouter+Rewrite

/*!
 @brief URL路由Rewrite
 
 @see https://github.com/imlifengfeng/FFRouter
 */
@interface FWRouter (Rewrite)

/**
 According to the set of Rules, go to rewrite URL.
 
 @param url URL to be rewritten
 @return URL after being rewritten
 */
+ (nullable NSString *)rewriteURL:(NSString *)url;

/**
 Set custom rewrite filter block
 
 @param filter Custom filter block
 */
+ (void)setRewriteFilter:(nullable NSString * (^)(NSString *url))filter;

/**
 Add a RewriteRule
 
 @param matchRule Regular matching rule
 @param targetRule Conversion rules
 */
+ (void)addRewriteRule:(NSString *)matchRule targetRule:(NSString *)targetRule;

/**
 Add multiple RewriteRule at the same time, the format must be：@[@{@"matchRule":@"YourMatchRule",@"targetRule":@"YourTargetRule"},...]
 
 @param rules RewriteRules
 */
+ (void)addRewriteRules:(NSArray<NSDictionary *> *)rules;

/**
 Remove a RewriteRule
 
 @param matchRule MatchRule to be removed
 */
+ (void)removeRewriteRule:(NSString *)matchRule;

/**
 Remove all RewriteRule
 */
+ (void)removeAllRewriteRules;

@end

#pragma mark - FWRouter+Navigation

/*!
 @brief URL路由导航
 */
@interface FWRouter (Navigation)

/*!
 @brief 使用最顶部的导航栏控制器打开控制器
 */
+ (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

/*!
 @brief 使用最顶部的显示控制器弹出控制器，建议present导航栏控制器(可用来push)
 */
+ (void)presentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(nullable void (^)(void))completion;

@end

#pragma mark - UIWindow+FWNavigation

/*!
 @brief 窗口导航分类
 */
@interface UIWindow (FWNavigation)

/// 获取当前主window
+ (nullable UIWindow *)fwMainWindow;

/// 获取当前主场景
+ (nullable UIWindowScene *)fwMainScene API_AVAILABLE(ios(13.0));

/// 获取最顶部的视图控制器
- (nullable UIViewController *)fwTopViewController;

/// 获取最顶部的导航栏控制器。如果顶部VC不含导航栏，返回nil
- (nullable UINavigationController *)fwTopNavigationController;

/// 获取最顶部的显示控制器
- (nullable UIViewController *)fwTopPresentedController;

/// 使用最顶部的导航栏控制器打开控制器
- (BOOL)fwPushViewController:(UIViewController *)viewController
                    animated:(BOOL)animated;

/// 使用最顶部的显示控制器弹出控制器，建议present导航栏控制器(可用来push)
- (void)fwPresentViewController:(UIViewController *)viewController
                       animated:(BOOL)animated
                     completion:(nullable void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
