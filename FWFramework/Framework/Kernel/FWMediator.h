/*!
 @header     FWMediator.h
 @indexgroup FWFramework
 @brief      FWMediator
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/12/31
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 注册指定业务模块
#define FWModuleRegister(serviceProtocol) \
    [FWMediator registerService:@protocol(serviceProtocol) withModule:self.class];

/// 加载指定业务模块
#define FWModule(serviceProtocol) \
    ((id<serviceProtocol>)[FWMediator moduleByService:@protocol(serviceProtocol)])

/// 模块默认优先级，100
#define FWModulePriorityDefault 100

/*!
 @brief 业务模块协议，各业务必须实现
 */
@protocol FWModuleProtocol <UIApplicationDelegate, NSObject>

@required

/// 模块单例
+ (instancetype)sharedInstance;

/// 模块初始化方法，App启动或模块加载时自动调用
- (void)setup;

@optional

/// 模块优先级，0最低。默认为Default优先级
+ (NSUInteger)priority;

/// 是否主线程同步调用，默认为NO，后台线程异步调用
+ (BOOL)setupSynchronously;

@end

/*!
 @brief iOS模块化架构中间件，结合FWRouter可搭建模块化架构设计
 
 @see https://github.com/youzan/Bifrost
 */
@interface FWMediator : NSObject

/// 注册指定模块服务，返回注册结果
+ (BOOL)registerService:(Protocol *)serviceProtocol withModule:(Class<FWModuleProtocol>)moduleClass;

/// 取消注册指定模块服务
+ (void)unregisterService:(Protocol *)serviceProtocol;

/// 初始化所有模块，推荐在willFinishLaunchingWithOptions中调用
+ (void)setupAllModules;

/// 通过服务协议获取指定模块实例
+ (nullable id<FWModuleProtocol>)moduleByService:(Protocol *)serviceProtocol;

/// 获取所有已注册模块类数组，按照优先级排序
+ (NSArray<Class<FWModuleProtocol>> *)allRegisteredModules;

/// 在UIApplicationDelegate检查所有模块方法
+ (BOOL)checkAllModulesWithSelector:(SEL)selector arguments:(nullable NSArray *)arguments;

@end

/*!
 @brief 业务模块Bundle类，子类可重写
 */
@interface FWModuleBundle : NSObject

/// 指定名称初始化Bundle
+ (NSBundle *)bundleWithName:(NSString *)bundleName;

/// 获取当前模块Bundle
+ (NSBundle *)bundle;

/// 获取当前模块图片
+ (nullable UIImage *)imageNamed:(NSString *)imageName;

/// 获取当前模块多语言
+ (NSString *)localizedString:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
