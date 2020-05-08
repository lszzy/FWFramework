/*!
 @header     FWPlugin.m
 @indexgroup FWFramework
 @brief      插件管理器
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-11
 */

#import "FWPlugin.h"
#import <objc/runtime.h>

#pragma mark - FWPlugin

typedef NS_ENUM(NSInteger, FWPluginType) {
    FWPluginTypeObject,
    FWPluginTypeBlock,
    FWPluginTypeFactory,
};

@interface FWPlugin : NSObject

@property (nonatomic, assign) FWPluginType type;
@property (nonatomic, strong, nullable) id value;

@property (nonatomic, strong, nullable) id instance;
@property (nonatomic, assign) BOOL locked;

@end

@implementation FWPlugin

@end

#pragma mark - FWPluginManager

@interface FWPluginManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, FWPlugin *> *pluginPool;

@end

@implementation FWPluginManager

#pragma mark - Lifecycle

+ (FWPluginManager *)sharedInstance
{
    static FWPluginManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWPluginManager alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.pluginPool = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - Public

- (BOOL)registerDefault:(Protocol *)protocol withObject:(id)obj
{
    return [self registerPlugin:protocol withValue:obj type:FWPluginTypeObject isDefault:YES];
}

- (BOOL)registerDefault:(Protocol *)protocol withBlock:(id (^)(void))block
{
    return [self registerPlugin:protocol withValue:block type:FWPluginTypeBlock isDefault:YES];
}

- (BOOL)registerDefault:(Protocol *)protocol withFactory:(id (^)(void))factory
{
    return [self registerPlugin:protocol withValue:factory type:FWPluginTypeFactory isDefault:YES];
}

- (BOOL)registerPlugin:(Protocol *)protocol withObject:(id)obj
{
    return [self registerPlugin:protocol withValue:obj type:FWPluginTypeObject isDefault:NO];
}

- (BOOL)registerPlugin:(Protocol *)protocol withBlock:(id (^)(void))block
{
    return [self registerPlugin:protocol withValue:block type:FWPluginTypeBlock isDefault:NO];
}

- (BOOL)registerPlugin:(Protocol *)protocol withFactory:(id (^)(void))factory
{
    return [self registerPlugin:protocol withValue:factory type:FWPluginTypeFactory isDefault:NO];
}

- (BOOL)registerPlugin:(Protocol *)protocol withValue:(id)value type:(FWPluginType)type isDefault:(BOOL)isDefault
{
    if (!protocol || !value) {
        return NO;
    }
    
    // 插件必须实现插件协议，否则抛出异常
    NSString *protocolName = NSStringFromProtocol(protocol);
    if (type == FWPluginTypeObject) {
        if (![value conformsToProtocol:protocol]) {
            @throw [NSException exceptionWithName:@"FWFramework"
                                           reason:[NSString stringWithFormat:@"plugin %@ must confirms to protocol %@", value, protocolName]
                                         userInfo:nil];
            return NO;
        }
    }
    
    // 插件已锁定时不能注册
    FWPlugin *plugin = [self.pluginPool objectForKey:protocolName];
    if (plugin && plugin.locked) {
        return NO;
    }
    
    // 插件已存在时不能注册默认插件
    if (isDefault && plugin) {
        return NO;
    }
    
    FWPlugin *newPlugin = [[FWPlugin alloc] init];
    newPlugin.type = type;
    newPlugin.value = value;
    [self.pluginPool setObject:newPlugin forKey:protocolName];
    return YES;
}

- (void)unregisterPlugin:(Protocol *)protocol
{
    NSString *protocolName = NSStringFromProtocol(protocol);
    FWPlugin *plugin = [self.pluginPool objectForKey:protocolName];
    if (!plugin || plugin.locked) {
        return;
    }
    
    [self.pluginPool removeObjectForKey:protocolName];
}

- (nullable id)loadPlugin:(Protocol *)protocol
{
    // 插件未注册时返回nil
    NSString *protocolName = NSStringFromProtocol(protocol);
    FWPlugin *plugin = [self.pluginPool objectForKey:protocolName];
    if (!plugin) {
        return nil;
    }
    
    // 插件已初始化直接返回
    if (plugin.instance) {
        return plugin.instance;
    }
    
    // 初始化插件
    plugin.locked = YES;
    id instance = nil;
    switch (plugin.type) {
        case FWPluginTypeObject: {
            if (object_isClass(plugin.value)) {
                Class cls = (Class)plugin.value;
                if ([cls respondsToSelector:@selector(sharedInstance)]) {
                    plugin.instance = [cls sharedInstance];
                } else {
                    plugin.instance = [[cls alloc] init];
                }
            } else {
                plugin.instance = plugin.value;
            }
            instance = plugin.instance;
            break;
        }
        case FWPluginTypeBlock: {
            id (^block)(void) = plugin.value;
            plugin.instance = block();
            instance = plugin.instance;
            break;
        }
        case FWPluginTypeFactory: {
            id (^block)(void) = plugin.value;
            instance = block();
            break;
        }
        default: {
            break;
        }
    }
    
    // 插件必须实现插件协议，否则抛出异常
    if (![instance conformsToProtocol:protocol]) {
        @throw [NSException exceptionWithName:@"FWFramework"
                                       reason:[NSString stringWithFormat:@"plugin %@ must confirms to protocol %@", instance, protocolName]
                                     userInfo:nil];
    }
    
    return instance;
}

- (void)unloadPlugin:(Protocol *)protocol
{
    NSString *protocolName = NSStringFromProtocol(protocol);
    FWPlugin *plugin = [self.pluginPool objectForKey:protocolName];
    if (!plugin) {
        return;
    }
    
    plugin.instance = nil;
    plugin.locked = NO;
}

#pragma mark - NSObject

- (NSString *)debugDescription
{
    NSMutableString *mutableDescription = [[NSMutableString alloc] init];
    for (NSString *protocolName in self.pluginPool) {
        FWPlugin *plugin = [self.pluginPool objectForKey:protocolName];
        [mutableDescription appendFormat:@"%@ : %@\n", protocolName, (plugin.instance ?: plugin.value)];
    }
    
    NSString *debugDescription = [NSString stringWithFormat:@"\n========== PLUGIN ==========\n%@========== PLUGIN ==========", mutableDescription];
    return debugDescription;
}

@end
