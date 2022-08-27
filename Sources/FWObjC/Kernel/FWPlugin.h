//
//  FWPlugin.h
//  FWFramework
//
//  Created by wuyong on 2022/8/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Macro

/// 加载指定插件
#define FWPlugin(pluginProtocol) \
    ((id<pluginProtocol>)[FWPluginManager loadPlugin:@protocol(pluginProtocol)])

/// 注册指定插件
#define FWRegPlugin(pluginProtocol) \
    [FWPluginManager registerPlugin:@protocol(pluginProtocol) withObject:self.class];

#pragma mark - FWPluginProtocol

/// 可选插件协议，可不实现。未实现时默认调用sharedInstance > init方法
NS_SWIFT_NAME(PluginProtocol)
@protocol FWPluginProtocol <NSObject>
@optional

/// 可选插件单例方法，优先级高，仅调用一次
+ (instancetype)pluginInstance;

/// 可选插件工厂方法，优先级低，会调用多次
+ (instancetype)pluginFactory;

/// 插件load时钩子方法
- (void)pluginDidLoad;

/// 插件unload时钩子方法
- (void)pluginDidUnload;

@end

#pragma mark - FWPluginManager

@class FWLoader<InputType, OutputType>;

/**
 插件管理器类。支持插件冷替换(使用插件前)和热替换(先释放插件)
 @note 和Mediator对比如下：
    Plugin：和业务无关，侧重于工具类、基础设施、可替换，比如Toast、Loading等
    Mediator: 和业务相关，侧重于架构、业务功能、模块化，比如用户模块，订单模块等
 */
NS_SWIFT_NAME(PluginManager)
@interface FWPluginManager : NSObject

/// 单例插件加载器，加载未注册插件时会尝试调用并注册，block返回值为register方法object参数
@property (class, nonatomic, readonly) FWLoader<Protocol *, id> *sharedLoader;

/// 注册单例插件，仅当插件未使用时生效，插件类或对象必须实现protocol
+ (BOOL)registerPlugin:(Protocol *)pluginProtocol withObject:(id)object;

/// 预置单例插件，仅当插件未注册时生效，插件类或对象必须实现protocol
+ (BOOL)presetPlugin:(Protocol *)pluginProtocol withObject:(id)object;

/// 取消插件注册，仅当插件未使用时生效
+ (void)unregisterPlugin:(Protocol *)pluginProtocol;

/// 延迟加载插件对象，调用后不可再注册该插件
+ (nullable id)loadPlugin:(Protocol *)pluginProtocol;

/// 释放插件对象并标记为未使用，释放后可重新注册该插件
+ (void)unloadPlugin:(Protocol *)pluginProtocol;

@end

NS_ASSUME_NONNULL_END
