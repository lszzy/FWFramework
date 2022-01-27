/**
 @header     FWRouter.h
 @indexgroup FWFramework
      URL路由
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/11/29
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWRouterContext

@class FWRouterContext;
@class FWLoader<InputType, OutputType>;

/** 路由处理句柄，仅支持openURL时可返回nil */
typedef id _Nullable (^FWRouterHandler)(FWRouterContext *context);
/** 路由完成句柄，openURL时可设置完成回调 */
typedef void (^FWRouterCompletion)(id _Nullable result);

/** URL路由上下文 */
@interface FWRouterContext : NSObject <NSCopying>

/** 路由URL */
@property (nonatomic, copy, readonly) NSString *URL;
/** 路由用户信息 */
@property (nonatomic, copy, readonly, nullable) NSDictionary *userInfo;
/** 路由完成回调 */
@property (nonatomic, copy, readonly, nullable) FWRouterCompletion completion;

/** 路由URL解析参数字典 */
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSString *> *URLParameters;
/** 路由userInfo和URLParameters合并参数，URL参数优先级高 */
@property (nonatomic, copy, readonly) NSDictionary *parameters;
/*！路由是否以openURL方式打开，区别于objectForURL */
@property (nonatomic, assign, readonly) BOOL isOpening;

/** 创建路由参数对象 */
- (instancetype)initWithURL:(NSString *)URL userInfo:(nullable NSDictionary *)userInfo completion:(nullable FWRouterCompletion)completion;

@end

#pragma mark - FWRouterProtocol

/** URL路由协议 */
@protocol FWRouterProtocol <NSObject>

@required
/// 路由支持的解析URL，字符串或字符串数组(批量)
+ (id)routerURL;
/// 路由处理方法，访问支持的解析URL时会调用本方法
+ (nullable id)routerHandler:(FWRouterContext *)context;

@end

#pragma mark - FWRouter

/**
 URL路由器
 
 @see https://github.com/meili/MGJRouter
 */
@interface FWRouter : NSObject

/// 路由类加载器，访问未注册路由时会尝试调用并注册，block返回值为register方法class参数
@property (class, nonatomic, readonly) FWLoader<NSString *, id> *sharedLoader;

#pragma mark - Class

/**
*  注册路由类，需要实现FWRouterProtocol协议
*
*  @param clazz    路由类，需实现FWRouterProtocol协议
*/
+ (BOOL)registerClass:(Class<FWRouterProtocol>)clazz;

/**
*  预置路由类，需要实现FWRouterProtocol协议，仅当路由未被注册时生效
*
*  @param clazz    路由类，需实现FWRouterProtocol协议
*/
+ (BOOL)presetClass:(Class<FWRouterProtocol>)clazz;

/**
 *  取消注册某个路由类
 *
 *  @param clazz    路由类，需实现FWRouterProtocol协议
 */
+ (void)unregisterClass:(Class<FWRouterProtocol>)clazz;

#pragma mark - URL

/**
 *  注册 pattern 对应的 Handler，可返回一个 object 给调用方，也可直接触发事件返回nil
 *
 *  @param pattern    字符串或字符串数组(批量)，带上 scheme，如 app://beauty/:id
 *  @param handler    该 block 会传一个字典，包含了注册的 URL 中对应的变量。
 *                    假如注册的 URL 为 app://beauty/:id 那么，就会传一个 @{@"id": 4} 这样的字典过来
 */
+ (BOOL)registerURL:(id)pattern withHandler:(FWRouterHandler)handler;

/**
 *  预置 pattern 对应的 Handler，可返回一个 object 给调用方，也可直接触发事件返回nil，仅当路由未被注册时生效
 *
 *  @param pattern    字符串或字符串数组(批量)，带上 scheme，如 app://beauty/:id
 *  @param handler    该 block 会传一个字典，包含了注册的 URL 中对应的变量。
 *                    假如注册的 URL 为 app://beauty/:id 那么，就会传一个 @{@"id": 4} 这样的字典过来
 */
+ (BOOL)presetURL:(id)pattern withHandler:(FWRouterHandler)handler;

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

#pragma mark - Handler

/**
 *  设置全局前置过滤器，URL 被访问时优先触发。如果返回YES，继续解析pattern，否则停止解析
 */
@property (class, nonatomic, copy, nullable) BOOL (^preFilter)(FWRouterContext *context);

/**
 *  设置全局后置过滤器，URL 被访问且有返回值时触发，可用于打开VC、附加设置等
 */
@property (class, nonatomic, copy, nullable) id _Nullable (^postFilter)(FWRouterContext *context, id object);

/**
 *  设置全局错误句柄，URL 未注册时触发，可用于错误提示、更新提示等
 */
@property (class, nonatomic, copy, nullable) void (^errorHandler)(FWRouterContext *context);

#pragma mark - Open

/**
 *  是否可以打开URL，不含object
 *
 *  @param URL 带 Scheme，如 app://beauty/3，支持NSURL和NSString
 *
 *  @return 返回BOOL值
 */
+ (BOOL)canOpenURL:(id)URL;

/**
 *  打开此 URL
 *  会在已注册的 URL -> Handler 中寻找，如果找到，则执行 Handler
 *
 *  @param URL 带 Scheme，如 app://beauty/3，支持NSURL和NSString
 */
+ (void)openURL:(id)URL;

/**
 *  打开此 URL，同时当操作完成时，执行额外的代码
 *
 *  @param URL        带 Scheme 的 URL，如 app://beauty/4，支持NSURL和NSString
 *  @param userInfo   附加参数
 */
+ (void)openURL:(id)URL userInfo:(nullable NSDictionary *)userInfo;

/**
 *  打开此 URL，同时当操作完成时，执行额外的代码
 *
 *  @param URL        带 Scheme 的 URL，如 app://beauty/4，支持NSURL和NSString
 *  @param completion URL 处理完成后的 callback，完成的判定跟具体的业务相关
 */
+ (void)openURL:(id)URL completion:(nullable FWRouterCompletion)completion;

/**
 *  打开此 URL，带上附加信息，同时当操作完成时，执行额外的代码
 *
 *  @param URL        带 Scheme 的 URL，如 app://beauty/4，支持NSURL和NSString
 *  @param userInfo   附加参数
 *  @param completion URL 处理完成后的 callback，完成的判定跟具体的业务相关
 */
+ (void)openURL:(id)URL userInfo:(nullable NSDictionary *)userInfo completion:(nullable FWRouterCompletion)completion;

/**
 *  快速调用FWRouterHandler参数中的回调句柄，指定回调结果
 *
 *  @param context FWRouterHandler中的模型参数
 *  @param result URL处理完成后的回调结果
 */
+ (void)completeURL:(FWRouterContext *)context result:(nullable id)result;

#pragma mark - Object

/**
 * 查找谁对某个 URL 感兴趣，如果有的话，返回一个 object；如果没有，返回nil
 *
 *  @param URL 带 Scheme，如 app://beauty/3，支持NSURL和NSString
 */
+ (nullable id)objectForURL:(id)URL;

/**
 * 查找谁对某个 URL 感兴趣，如果有的话，返回一个 object；如果没有，返回nil
 *
 *  @param URL 带 Scheme，如 app://beauty/3，支持NSURL和NSString
 *  @param userInfo 附加参数
 */
+ (nullable id)objectForURL:(id)URL userInfo:(nullable NSDictionary *)userInfo;

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

/**
 URL路由Rewrite
 
 @see https://github.com/imlifengfeng/FFRouter
 */
@interface FWRouter (Rewrite)

/**
 According to the set of Rules, go to rewrite URL.
 
 @param URL URL to be rewritten
 @return URL after being rewritten
 */
+ (nullable NSString *)rewriteURL:(id)URL;

/**
 Set custom rewrite filter block
 
 @param filter Custom filter block
 */
+ (void)setRewriteFilter:(nullable NSString * (^)(NSString *URL))filter;

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

/**
 URL路由导航
 */
@interface FWRouter (Navigation)

/// 使用最顶部的导航栏控制器打开控制器
+ (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

/// 使用最顶部的显示控制器弹出控制器，建议present导航栏控制器(可用来push)
+ (void)presentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(nullable void (^)(void))completion;

/// 使用最顶部的视图控制器打开控制器，自动判断push|present
+ (void)openViewController:(UIViewController *)viewController animated:(BOOL)animated;

/// 关闭最顶部的视图控制器，自动判断pop|dismiss，返回是否成功
+ (BOOL)closeViewControllerAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
