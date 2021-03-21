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

#pragma mark - FWRouterContext

@class FWRouterContext;

/*! @brief 路由处理句柄，仅支持openURL时可返回nil */
typedef id _Nullable (^FWRouterHandler)(FWRouterContext *context);
/*! @brief 路由完成句柄，openURL时可设置完成回调 */
typedef void (^FWRouterCompletion)(id _Nullable result);

/*! @brief URL路由上下文 */
@interface FWRouterContext : NSObject <NSCopying>

/*! @brief 路由URL */
@property (nonatomic, copy, readonly) NSString *URL;
/*! @brief 路由用户信息 */
@property (nonatomic, copy, readonly, nullable) NSDictionary *userInfo;
/*! @brief 路由完成回调 */
@property (nonatomic, copy, readonly, nullable) FWRouterCompletion completion;

/*！@brief 路由调用是否是open方式 */
@property (nonatomic, assign, readonly) BOOL isOpen;
/*! @brief 路由URL解析参数字典 */
@property (nonatomic, copy, readonly) NSDictionary *parameters;

/*! @brief 创建路由参数对象 */
- (instancetype)initWithURL:(NSString *)URL userInfo:(nullable NSDictionary *)userInfo completion:(nullable FWRouterCompletion)completion;

@end

#pragma mark - FWRouterProtocol

/*! @brief URL路由协议 */
@protocol FWRouterProtocol <NSObject>

@required
/// 路由处理方法，调用目标URL时会优先调用本方法
+ (nullable id)fwRouterHandler:(FWRouterContext *)context;

@end

#pragma mark - FWRouter

/*!
 @brief URL路由器
 
 @see https://github.com/meili/MGJRouter
 */
@interface FWRouter : NSObject

#pragma mark - URL

/**
 *  注册 pattern 对应的 Handler，可返回一个 object 给调用方，也可直接触发事件返回nil
 *
 *  @param pattern    字符串或字符串数组(批量)，带上 scheme，如 app://beauty/:id
 *  @param clazz        路由实现类，需实现FWRouterProtocol协议
 */
+ (void)registerURL:(id)pattern withClass:(Class<FWRouterProtocol>)clazz;

/**
 *  注册 pattern 对应的 Handler，可返回一个 object 给调用方，也可直接触发事件返回nil
 *
 *  @param pattern    字符串或字符串数组(批量)，带上 scheme，如 app://beauty/:id
 *  @param handler    该 block 会传一个字典，包含了注册的 URL 中对应的变量。
 *                    假如注册的 URL 为 app://beauty/:id 那么，就会传一个 @{@"id": 4} 这样的字典过来
 */
+ (void)registerURL:(id)pattern withHandler:(FWRouterHandler)handler;

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
 *  设置 打开 对应的 Handler，URL有值且openURL返回值不为nil时触发。可用于统一处理openURL返回值(如打开VC)
 */
@property (class, nonatomic, copy, nullable) void (^openHandler)(id result);

/**
 *  设置 过滤器 对应的 Handler，URL 有值且调用时触发。如果返回nil，则继续解析pattern，否则停止解析
 */
@property (class, nonatomic, copy, nullable) FWRouterHandler filterHandler;

/**
 *  设置 错误 对应的 Handler，URL 有值且未注册时触发
 */
@property (class, nonatomic, copy, nullable) FWRouterHandler errorHandler;

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
 * 检测是否已注册object
 *
 *  @param URL 带 Scheme，如 app://beauty/3，支持NSURL和NSString
 */
+ (BOOL)isObjectURL:(id)URL;

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

/*!
 @brief URL路由Rewrite
 
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

/*!
 @brief URL路由导航
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

#pragma mark - UIWindow+FWNavigation

/*!
 @brief 窗口导航分类
 */
@interface UIWindow (FWNavigation)

/// 获取当前主window
@property (class, nonatomic, readonly, nullable) UIWindow *fwMainWindow;

/// 获取当前主场景
@property (class, nonatomic, readonly, nullable) UIWindowScene *fwMainScene API_AVAILABLE(ios(13.0));

/// 获取最顶部的视图控制器
@property (nonatomic, readonly, nullable) UIViewController *fwTopViewController;

/// 获取最顶部的导航栏控制器。如果顶部VC不含导航栏，返回nil
@property (nonatomic, readonly, nullable) UINavigationController *fwTopNavigationController;

/// 获取最顶部的显示控制器
@property (nonatomic, readonly, nullable) UIViewController *fwTopPresentedController;

/// 使用最顶部的导航栏控制器打开控制器
- (BOOL)fwPushViewController:(UIViewController *)viewController animated:(BOOL)animated;

/// 使用最顶部的显示控制器弹出控制器，建议present导航栏控制器(可用来push)
- (void)fwPresentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(nullable void (^)(void))completion;

/// 使用最顶部的视图控制器打开控制器，自动判断push|present
- (void)fwOpenViewController:(UIViewController *)viewController animated:(BOOL)animated;

/// 关闭最顶部的视图控制器，自动判断pop|dismiss，返回是否成功
- (BOOL)fwCloseViewControllerAnimated:(BOOL)animated;

@end

#pragma mark - UIViewController+FWNavigation

/*!
 @brief 控制器导航分类
 */
@interface UIViewController (FWNavigation)

/// 打开控制器。1.如果打开导航栏，则调用present；2.否则如果导航栏存在，则调用push；3.否则调用present
- (void)fwOpenViewController:(UIViewController *)viewController animated:(BOOL)animated;

/// 关闭控制器，返回是否成功。1.如果导航栏不存在，则调用dismiss；2.否则如果已是导航栏底部，则调用dismiss；3.否则调用pop
- (BOOL)fwCloseViewControllerAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
