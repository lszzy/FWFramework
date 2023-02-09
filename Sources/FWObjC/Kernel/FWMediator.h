//
//  FWMediator.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Macro

/// 加载指定业务模块
#define FWModule(serviceProtocol) \
    ((id<serviceProtocol>)[FWMediator loadModule:@protocol(serviceProtocol)])

/// 注册指定业务模块
#define FWRegModule(serviceProtocol) \
    [FWMediator registerService:@protocol(serviceProtocol) withModule:self.class];

#pragma mark - FWModulePriority

/// 模块优先级可扩展枚举
typedef NSUInteger FWModulePriority NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(ModulePriority);
static const FWModulePriority FWModulePriorityLow = 250;
static const FWModulePriority FWModulePriorityDefault = 500;
static const FWModulePriority FWModulePriorityHigh = 750;

#pragma mark - FWModuleProtocol

/**
 业务模块协议，各业务必须实现
 */
NS_SWIFT_NAME(ModuleProtocol)
@protocol FWModuleProtocol <UIApplicationDelegate, NSObject>

@required

/// 模块单例
+ (instancetype)sharedInstance;

@optional

/// 模块初始化方法，默认未实现，setupAllModules自动调用
- (void)setup;

/// 是否主线程同步调用setup，默认为NO，后台线程异步调用
+ (BOOL)setupSynchronously;

/// 模块优先级，0最低。默认为Default优先级
+ (NSUInteger)priority;

@end

#pragma mark - FWMediator

@class FWLoader<InputType, OutputType>;

/**
 iOS模块化架构中间件，结合FWRouter可搭建模块化架构设计
 
 @see https://github.com/youzan/Bifrost
 */
NS_SWIFT_NAME(Mediator)
@interface FWMediator : NSObject

/// 模块服务加载器，加载未注册模块时会尝试调用并注册，block返回值为register方法module参数
@property (class, nonatomic, readonly) FWLoader<Protocol *, id> *sharedLoader;

/// 注册指定模块服务，返回注册结果
+ (BOOL)registerService:(Protocol *)serviceProtocol withModule:(Class<FWModuleProtocol>)moduleClass;

/// 预置指定模块服务，仅当模块未注册时生效
+ (BOOL)presetService:(Protocol *)serviceProtocol withModule:(Class<FWModuleProtocol>)moduleClass;

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

#pragma mark - FWModuleBundle

/**
 业务模块Bundle基类，各模块可继承
 */
NS_SWIFT_NAME(ModuleBundle)
@interface FWModuleBundle : NSObject

/// 获取当前模块Bundle，默认主Bundle，子类可重写
+ (NSBundle *)bundle;

/// 获取当前模块图片
+ (nullable UIImage *)imageNamed:(NSString *)name;

/// 设置当前模块图片
+ (void)setImage:(nullable UIImage *)image forName:(NSString *)name;

/// 获取当前模块颜色
+ (nullable UIColor *)colorNamed:(NSString *)name;

/// 获取当前模块多语言
+ (NSString *)localizedString:(NSString *)key;

/// 获取当前模块指定文件多语言
+ (NSString *)localizedString:(NSString *)key table:(nullable NSString *)table;

/// 获取当前模块资源文件路径
+ (nullable NSString *)resourcePath:(NSString *)name;

/// 获取当前模块资源文件URL
+ (nullable NSURL *)resourceURL:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
