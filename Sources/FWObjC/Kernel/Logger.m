//
//  Logger.m
//  FWFramework
//
//  Created by wuyong on 2022/8/20.
//

#import "Logger.h"
#import "Plugin.h"

#ifdef DEBUG

// 调试默认全局日志级别：所有
static __FWLogLevel fwStaticLogLevel = __FWLogLevelAll;

#else

// 正式默认全局日志级别：关闭
static __FWLogLevel fwStaticLogLevel = __FWLogLevelOff;

#endif

@implementation __FWLogger

#pragma mark - Public

+ (__FWLogLevel)level
{
    return fwStaticLogLevel;
}

+ (void)setLevel:(__FWLogLevel)level
{
    fwStaticLogLevel = level;
}

+ (BOOL)check:(__FWLogType)type
{
    return (fwStaticLogLevel & type) ? YES : NO;
}

+ (void)trace:(NSString *)format, ...
{
    if (![self check:__FWLogTypeTrace]) return;
    
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self log:__FWLogTypeTrace message:message];
}

+ (void)debug:(NSString *)format, ...
{
    if (![self check:__FWLogTypeDebug]) return;
    
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self log:__FWLogTypeDebug message:message];
}

+ (void)info:(NSString *)format, ...
{
    if (![self check:__FWLogTypeInfo]) return;
    
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self log:__FWLogTypeInfo message:message];
}

+ (void)warn:(NSString *)format, ...
{
    if (![self check:__FWLogTypeWarn]) return;
    
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self log:__FWLogTypeWarn message:message];
}

+ (void)error:(NSString *)format, ...
{
    if (![self check:__FWLogTypeError]) return;
    
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self log:__FWLogTypeError message:message];
}

+ (void)group:(NSString *)group
         type:(__FWLogType)type
       format:(NSString *)format, ...
{
    if (![self check:type]) return;
    
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self log:type message:message group:group userInfo:nil];
}

+ (void)log:(__FWLogType)type
    message:(NSString *)message
{
    [self log:type message:message group:nil userInfo:nil];
}

+ (void)log:(__FWLogType)type
    message:(NSString *)message
      group:(NSString *)group
   userInfo:(NSDictionary *)userInfo
{
    // 过滤不支持的级别
    if (![self check:type]) return;
    
    // 插件存在，调用插件；否则使用默认插件
    id<__FWLoggerPlugin> plugin = [__FWPluginManager loadPlugin:@protocol(__FWLoggerPlugin)];
    if (!plugin || ![plugin respondsToSelector:@selector(log:message:group:userInfo:)]) {
        plugin = __FWLoggerPluginImpl.sharedInstance;
    }
    [plugin log:type message:message group:group userInfo:userInfo];
}

@end

#pragma mark - __FWLoggerPluginImpl

@implementation __FWLoggerPluginImpl

+ (__FWLoggerPluginImpl *)sharedInstance
{
    static __FWLoggerPluginImpl *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[__FWLoggerPluginImpl alloc] init];
    });
    return instance;
}

- (void)log:(__FWLogType)type
    message:(NSString *)message
      group:(NSString *)group
   userInfo:(NSDictionary *)userInfo
{
    NSString *groupStr = group ? [NSString stringWithFormat:@" [%@]", group] : @"";
    NSString *infoStr = userInfo ? [NSString stringWithFormat:@" %@", userInfo] : @"";
    switch (type) {
        case __FWLogTypeError:
            NSLog(@"%@ ERROR:%@ %@%@", @"❌", groupStr, message, infoStr);
            break;
        case __FWLogTypeWarn:
            NSLog(@"%@ WARN:%@ %@%@", @"⚠️", groupStr, message, infoStr);
            break;
        case __FWLogTypeInfo:
            NSLog(@"%@ INFO:%@ %@%@", @"ℹ️", groupStr, message, infoStr);
            break;
        case __FWLogTypeDebug:
            NSLog(@"%@ DEBUG:%@ %@%@", @"⏱️", groupStr, message, infoStr);
            break;
        default:
            NSLog(@"%@ TRACE:%@ %@%@", @"📝", groupStr, message, infoStr);
            break;
    }
}

@end
