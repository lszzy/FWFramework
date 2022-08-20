//
//  FWLogger.m
//  FWFramework
//
//  Created by wuyong on 2022/8/20.
//

#import "FWLogger.h"
#import "FWPlugin.h"

#ifdef DEBUG

// 调试默认全局日志级别：所有
static FWLogLevel fwStaticLogLevel = FWLogLevelAll;

#else

// 正式默认全局日志级别：关闭
static FWLogLevel fwStaticLogLevel = FWLogLevelOff;

#endif

@implementation FWLogger

#pragma mark - Public

+ (FWLogLevel)level
{
    return fwStaticLogLevel;
}

+ (void)setLevel:(FWLogLevel)level
{
    fwStaticLogLevel = level;
}

+ (BOOL)check:(FWLogType)type
{
    return (fwStaticLogLevel & type) ? YES : NO;
}

+ (void)trace:(NSString *)format, ...
{
    if (![self check:FWLogTypeTrace]) return;
    
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self log:FWLogTypeTrace message:message];
}

+ (void)debug:(NSString *)format, ...
{
    if (![self check:FWLogTypeDebug]) return;
    
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self log:FWLogTypeDebug message:message];
}

+ (void)info:(NSString *)format, ...
{
    if (![self check:FWLogTypeInfo]) return;
    
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self log:FWLogTypeInfo message:message];
}

+ (void)warn:(NSString *)format, ...
{
    if (![self check:FWLogTypeWarn]) return;
    
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self log:FWLogTypeWarn message:message];
}

+ (void)error:(NSString *)format, ...
{
    if (![self check:FWLogTypeError]) return;
    
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self log:FWLogTypeError message:message];
}

+ (void)group:(NSString *)group
         type:(FWLogType)type
       format:(NSString *)format, ...
{
    if (![self check:type]) return;
    
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self log:type message:message group:group userInfo:nil];
}

+ (void)log:(FWLogType)type
    message:(NSString *)message
{
    [self log:type message:message group:nil userInfo:nil];
}

+ (void)log:(FWLogType)type
    message:(NSString *)message
      group:(NSString *)group
   userInfo:(NSDictionary *)userInfo
{
    // 过滤不支持的级别
    if (![self check:type]) return;
    
    // 插件存在，调用插件；否则使用默认插件
    id<FWLoggerPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWLoggerPlugin)];
    if (!plugin || ![plugin respondsToSelector:@selector(log:message:group:userInfo:)]) {
        plugin = FWLoggerPluginImpl.sharedInstance;
    }
    [plugin log:type message:message group:group userInfo:userInfo];
}

@end

#pragma mark - FWLoggerPluginImpl

@implementation FWLoggerPluginImpl

+ (FWLoggerPluginImpl *)sharedInstance
{
    static FWLoggerPluginImpl *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWLoggerPluginImpl alloc] init];
    });
    return instance;
}

- (void)log:(FWLogType)type
    message:(NSString *)message
      group:(NSString *)group
   userInfo:(NSDictionary *)userInfo
{
    NSString *groupStr = group ? [NSString stringWithFormat:@" [%@]", group] : @"";
    NSString *infoStr = userInfo ? [NSString stringWithFormat:@" %@", userInfo] : @"";
    switch (type) {
        case FWLogTypeError:
            NSLog(@"%@ ERROR:%@ %@%@", @"❌", groupStr, message, infoStr);
            break;
        case FWLogTypeWarn:
            NSLog(@"%@ WARN:%@ %@%@", @"⚠️", groupStr, message, infoStr);
            break;
        case FWLogTypeInfo:
            NSLog(@"%@ INFO:%@ %@%@", @"ℹ️", groupStr, message, infoStr);
            break;
        case FWLogTypeDebug:
            NSLog(@"%@ DEBUG:%@ %@%@", @"⏱️", groupStr, message, infoStr);
            break;
        default:
            NSLog(@"%@ TRACE:%@ %@%@", @"📝", groupStr, message, infoStr);
            break;
    }
}

@end
