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

/*!
 @brief 插件管理器类。支持插件冷替换(使用插件前)和热替换(先释放插件)
 */
@interface FWPluginManager : NSObject

/*! @brief 单例模式 */
@property (class, nonatomic, readonly) FWPluginManager *sharedInstance;

/*!
 @brief 注册默认单例插件，仅当插件未注册时生效
 
 @exception NSException 插件未实现插件协议时抛出异常
 @param protocol 插件协议
 @param obj 插件类或对象，必须实现protocol
 @return 是否注册成功
 */
- (BOOL)registerDefault:(Protocol *)protocol withObject:(id)obj;

/*!
 @brief 注册默认单例插件，仅当插件未注册时生效
 
 @exception NSException 插件未实现插件协议时抛出异常
 @param protocol 插件协议
 @param block 插件块，返回的对象必须实现protocol
 @return 是否注册成功
 */
- (BOOL)registerDefault:(Protocol *)protocol withBlock:(id (^)(void))block;

/*!
 @brief 注册默认工厂插件，仅当插件未注册时生效
 
 @exception NSException 插件未实现插件协议时抛出异常
 @param protocol 插件协议
 @param factory 插件块，返回的对象必须实现protocol
 @return 是否注册成功
 */
- (BOOL)registerDefault:(Protocol *)protocol withFactory:(id (^)(void))factory;

/*!
 @brief 注册单例插件，仅当插件未使用时生效
 
 @exception NSException 插件未实现插件协议时抛出异常
 @param protocol 插件协议
 @param obj 插件类或对象，必须实现protocol
 @return 是否注册成功
 */
- (BOOL)registerPlugin:(Protocol *)protocol withObject:(id)obj;

/*!
 @brief 注册单例插件，仅当插件未使用时生效
 
 @exception NSException 插件未实现插件协议时抛出异常
 @param protocol 插件协议
 @param block 插件块，返回的对象必须实现protocol
 @return 是否注册成功
 */
- (BOOL)registerPlugin:(Protocol *)protocol withBlock:(id (^)(void))block;

/*!
 @brief 注册工厂插件，仅当插件未使用时生效
 
 @exception NSException 插件未实现插件协议时抛出异常
 @param protocol 插件协议
 @param factory 插件块，返回的对象必须实现protocol
 @return 是否注册成功
 */
- (BOOL)registerPlugin:(Protocol *)protocol withFactory:(id (^)(void))factory;

/*!
 @brief 取消插件注册，仅当插件未使用时生效

 @param protocol 插件协议
 */
- (void)unregisterPlugin:(Protocol *)protocol;

/*!
 @brief 延迟加载插件对象，调用后不可再注册该插件

 @exception NSException 插件未实现插件协议时抛出异常
 @param protocol 插件协议
 @return 插件对象，未注册时返回nil
 */
- (nullable id)loadPlugin:(Protocol *)protocol;

/*!
 @brief 释放插件对象并标记为未使用，释放后可重新注册该插件

 @param protocol 插件协议
 */
- (void)unloadPlugin:(Protocol *)protocol;

@end

NS_ASSUME_NONNULL_END
