/*!
 @header     FWPlugin.h
 @indexgroup FWFramework
 @brief      插件管理器
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-11
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 加载指定插件
#define FWPlugin(pluginProtocol) \
    ((id<pluginProtocol>)[FWPluginManager loadPlugin:@protocol(pluginProtocol)])

/// 注册指定插件
#define FWRegPlugin(pluginProtocol) \
    [FWPluginManager registerPlugin:@protocol(pluginProtocol) withObject:self.class];

/*!
 @brief 插件管理器类。支持插件冷替换(使用插件前)和热替换(先释放插件)
 @discussion 和Mediator对比如下：
    Plugin：和业务无关，侧重于工具类、基础设施、可替换，比如Toast、Loading等
    Mediator: 和业务相关，侧重于架构、业务功能、模块化，比如用户模块，订单模块等
 */
@interface FWPluginManager : NSObject

/// 注册单例插件，仅当插件未使用时生效，插件类或对象必须实现protocol
+ (BOOL)registerPlugin:(Protocol *)protocol withObject:(id)obj;
/// 预置单例插件，仅当插件未注册时生效，插件类或对象必须实现protocol
+ (BOOL)presetPlugin:(Protocol *)protocol withObject:(id)obj;

/// 注册单例句柄插件，仅当插件未使用时生效，返回的对象必须实现protocol
+ (BOOL)registerPlugin:(Protocol *)protocol withBlock:(id (^)(void))block NS_SWIFT_NAME(registerPlugin(_:withBlock:));
/// 预置单例句柄插件，仅当插件未注册时生效，返回的对象必须实现protocol
+ (BOOL)presetPlugin:(Protocol *)protocol withBlock:(id (^)(void))block NS_SWIFT_NAME(presetPlugin(_:withBlock:));

/// 注册工厂插件，仅当插件未使用时生效，返回的对象必须实现protocol
+ (BOOL)registerPlugin:(Protocol *)protocol withFactory:(id (^)(void))factory;
/// 预置工厂插件，仅当插件未注册时生效，返回的对象必须实现protocol
+ (BOOL)presetPlugin:(Protocol *)protocol withFactory:(id (^)(void))factory;

/// 取消插件注册，仅当插件未使用时生效
+ (void)unregisterPlugin:(Protocol *)protocol;

/// 延迟加载插件对象，调用后不可再注册该插件
+ (nullable id)loadPlugin:(Protocol *)protocol;

/// 释放插件对象并标记为未使用，释放后可重新注册该插件
+ (void)unloadPlugin:(Protocol *)protocol;

@end

NS_ASSUME_NONNULL_END
