/**
 @header     FWPlugin.m
 @indexgroup FWFramework
      插件管理器
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-11
 */

#import "FWPlugin.h"
#import "FWLoader.h"
#import <objc/runtime.h>

#pragma mark - FWInnerPluginTarget

@interface FWInnerPluginTarget : NSObject

@property (nonatomic, strong, nullable) id object;
@property (nonatomic, strong, nullable) id instance;
@property (nonatomic, assign) BOOL locked;
@property (nonatomic, assign) BOOL isFactory;

@end

@implementation FWInnerPluginTarget

@end

#pragma mark - FWPluginManager

@interface FWPluginManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, FWInnerPluginTarget *> *pluginPool;
@property (nonatomic, strong) FWLoader<Protocol *, id> *pluginLoader;

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
        self.pluginLoader = [[FWLoader<Protocol *, id> alloc] init];
    }
    return self;
}

+ (NSString *)debugDescription
{
    NSMutableString *debugDescription = [[NSMutableString alloc] init];
    NSInteger debugCount = 0;
    for (NSString *protocolName in FWPluginManager.sharedInstance.pluginPool) {
        FWInnerPluginTarget *plugin = [FWPluginManager.sharedInstance.pluginPool objectForKey:protocolName];
        [debugDescription appendFormat:@"%@. %@ : %@\n", @(++debugCount), protocolName, (plugin.instance ?: plugin.object)];
    }
    return [NSString stringWithFormat:@"\n========== PLUGIN ==========\n%@========== PLUGIN ==========", debugDescription];
}

#pragma mark - Public

+ (FWLoader *)sharedLoader
{
    return [self sharedInstance].pluginLoader;
}

+ (BOOL)registerPlugin:(Protocol *)pluginProtocol withObject:(id)object
{
    return [self registerPlugin:pluginProtocol withObject:object isPreset:NO];
}

+ (BOOL)presetPlugin:(Protocol *)pluginProtocol withObject:(id)object
{
    return [self registerPlugin:pluginProtocol withObject:object isPreset:YES];
}

+ (BOOL)registerPlugin:(Protocol *)pluginProtocol withObject:(id)object isPreset:(BOOL)isPreset
{
    if (!pluginProtocol || !object) return NO;
    
    NSString *protocolName = NSStringFromProtocol(pluginProtocol);
    FWInnerPluginTarget *plugin = [[self sharedInstance].pluginPool objectForKey:protocolName];
    if (plugin) {
        if (plugin.locked) return NO;
        if (isPreset) return NO;
    }
    
    FWInnerPluginTarget *newPlugin = [[FWInnerPluginTarget alloc] init];
    newPlugin.object = object;
    [[self sharedInstance].pluginPool setObject:newPlugin forKey:protocolName];
    return YES;
}

+ (void)unregisterPlugin:(Protocol *)pluginProtocol
{
    NSString *protocolName = NSStringFromProtocol(pluginProtocol);
    FWInnerPluginTarget *plugin = [[self sharedInstance].pluginPool objectForKey:protocolName];
    if (!plugin || plugin.locked) {
        return;
    }
    
    [[self sharedInstance].pluginPool removeObjectForKey:protocolName];
}

+ (id)loadPlugin:(Protocol *)pluginProtocol
{
    NSString *protocolName = NSStringFromProtocol(pluginProtocol);
    FWInnerPluginTarget *plugin = [[self sharedInstance].pluginPool objectForKey:protocolName];
    if (!plugin) {
        id object = [[self sharedLoader] load:pluginProtocol];
        if (!object) return nil;
        
        [self registerPlugin:pluginProtocol withObject:object];
        plugin = [[self sharedInstance].pluginPool objectForKey:protocolName];
        if (!plugin) return nil;
    }
    
    if (plugin.instance && !plugin.isFactory) {
        return plugin.instance;
    }
    
    plugin.locked = YES;
    plugin.isFactory = NO;
    if (object_isClass(plugin.object)) {
        Class pluginClass = (Class)plugin.object;
        if ([pluginClass respondsToSelector:@selector(pluginInstance)]) {
            plugin.instance = [pluginClass pluginInstance];
        } else if ([pluginClass respondsToSelector:@selector(pluginFactory)]) {
            if (plugin.instance && [plugin.instance respondsToSelector:@selector(pluginDidUnload)]) {
                [plugin.instance pluginDidUnload];
            }
            plugin.instance = [pluginClass pluginFactory];
            plugin.isFactory = YES;
        } else if ([pluginClass respondsToSelector:@selector(sharedInstance)]) {
            plugin.instance = [pluginClass sharedInstance];
        } else {
            plugin.instance = [[pluginClass alloc] init];
        }
    } else {
        plugin.instance = plugin.object;
    }
    
    if (plugin.instance && [plugin.instance respondsToSelector:@selector(pluginDidLoad)]) {
        [plugin.instance pluginDidLoad];
    }
    return plugin.instance;
}

+ (void)unloadPlugin:(Protocol *)pluginProtocol
{
    NSString *protocolName = NSStringFromProtocol(pluginProtocol);
    FWInnerPluginTarget *plugin = [[self sharedInstance].pluginPool objectForKey:protocolName];
    if (!plugin) return;
    
    if (plugin.instance && [plugin.instance respondsToSelector:@selector(pluginDidUnload)]) {
        [plugin.instance pluginDidUnload];
    }
    plugin.instance = nil;
    plugin.isFactory = NO;
    plugin.locked = NO;
}

@end
