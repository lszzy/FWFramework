/**
 @header     FWLogger.m
 @indexgroup FWFramework
      日志记录
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-11
 */

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
    
    [self logWithType:FWLogTypeTrace message:message];
}

+ (void)debug:(NSString *)format, ...
{
    if (![self check:FWLogTypeDebug]) return;
    
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self logWithType:FWLogTypeDebug message:message];
}

+ (void)info:(NSString *)format, ...
{
    if (![self check:FWLogTypeInfo]) return;
    
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self logWithType:FWLogTypeInfo message:message];
}

+ (void)warn:(NSString *)format, ...
{
    if (![self check:FWLogTypeWarn]) return;
    
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self logWithType:FWLogTypeWarn message:message];
}

+ (void)error:(NSString *)format, ...
{
    if (![self check:FWLogTypeError]) return;
    
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self logWithType:FWLogTypeError message:message];
}

+ (void)group:(NSString *)group type:(FWLogType)type format:(NSString *)format, ...
{
    if (![self check:type]) return;
    
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self logWithType:type message:message group:group userInfo:nil];
}

+ (void)logWithType:(FWLogType)type message:(NSString *)message
{
    [self logWithType:type message:message group:nil userInfo:nil];
}

+ (void)logWithType:(FWLogType)type message:(NSString *)message group:(NSString *)group userInfo:(NSDictionary *)userInfo
{
    // 过滤不支持的级别
    if (![self check:type]) return;
    
    // 插件存在，调用插件；否则使用默认插件
    id<FWLogPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWLogPlugin)];
    if (!plugin || ![plugin respondsToSelector:@selector(logWithType:message:group:userInfo:)]) {
        plugin = FWLogPluginImpl.sharedInstance;
    }
    [plugin logWithType:type message:message group:group userInfo:userInfo];
}

@end

#pragma mark - FWLogPluginImpl

@implementation FWLogPluginImpl

+ (FWLogPluginImpl *)sharedInstance
{
    static FWLogPluginImpl *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FWLogPluginImpl alloc] init];
    });
    return instance;
}

- (void)logWithType:(FWLogType)type message:(NSString *)message group:(NSString *)group userInfo:(NSDictionary *)userInfo
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
