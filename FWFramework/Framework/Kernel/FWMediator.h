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

/// 加载指定业务模块
#define FWModule(serviceProtocol) \
    ((id<serviceProtocol>)[FWMediator loadModule:@protocol(serviceProtocol)])

/// 注册指定业务模块
#define FWRegModule(serviceProtocol) \
    [FWMediator registerService:@protocol(serviceProtocol) withModule:self.class];

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

@class FWLoader<InputType, OutputType>;

/*!
 @brief iOS模块化架构中间件，结合FWRouter可搭建模块化架构设计
 
 @see https://github.com/youzan/Bifrost
 */
@interface FWMediator : NSObject

/// 模块服务加载器，加载未注册模块时会尝试调用并注册，block返回值为register方法module参数
@property (class, nonatomic, readonly) FWLoader<Protocol *, id> *sharedLoader;

/// 注册指定模块服务，返回注册结果
+ (BOOL)registerService:(Protocol *)serviceProtocol withModule:(Class<FWModuleProtocol>)moduleClass;

/// 取消注册指定模块服务
+ (void)unregisterService:(Protocol *)serviceProtocol;

/// 通过服务协议获取指定模块实例
+ (nullable id<FWModuleProtocol>)loadModule:(Protocol *)serviceProtocol;

/// 获取所有已注册模块类数组，按照优先级排序
+ (NSArray<Class<FWModuleProtocol>> *)allRegisteredModules;

/// 初始化所有模块，推荐在willFinishLaunchingWithOptions中调用
+ (void)setupAllModules;

/// 在UIApplicationDelegate检查所有模块方法
+ (BOOL)checkAllModulesWithSelector:(SEL)selector arguments:(nullable NSArray *)arguments;

@end

/*!
 @brief 业务模块Bundle基类，各模块可继承
 */
@interface FWModuleBundle : NSObject

/// 获取当前模块Bundle，默认主Bundle，子类可重写
+ (NSBundle *)bundle;

/// 获取当前模块图片
+ (nullable UIImage *)imageNamed:(NSString *)imageName;

/// 获取当前模块多语言
+ (NSString *)localizedString:(NSString *)key;

/// 获取当前模块指定文件多语言
+ (NSString *)localizedString:(NSString *)key table:(nullable NSString *)table;

@end

NS_ASSUME_NONNULL_END
