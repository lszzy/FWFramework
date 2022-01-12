/**
 @header     FWLog.m
 @indexgroup FWFramework
      日志记录
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-11
 */

#import "FWLog.h"
#import "FWPlugin.h"

#ifdef DEBUG

// 调试默认全局日志级别：所有
static FWLogLevel fwStaticLogLevel = FWLogLevelAll;

#else

// 正式默认全局日志级别：关闭
static FWLogLevel fwStaticLogLevel = FWLogLevelOff;

#endif

@implementation FWLog

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
    
    [self log:FWLogTypeTrace withMessage:message];
}

+ (void)debug:(NSString *)format, ...
{
    if (![self check:FWLogTypeDebug]) return;
    
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self log:FWLogTypeDebug withMessage:message];
}

+ (void)info:(NSString *)format, ...
{
    if (![self check:FWLogTypeInfo]) return;
    
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self log:FWLogTypeInfo withMessage:message];
}

+ (void)warn:(NSString *)format, ...
{
    if (![self check:FWLogTypeWarn]) return;
    
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self log:FWLogTypeWarn withMessage:message];
}

+ (void)error:(NSString *)format, ...
{
    if (![self check:FWLogTypeError]) return;
    
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self log:FWLogTypeError withMessage:message];
}

+ (void)log:(FWLogType)type withMessage:(NSString *)message
{
    // 过滤不支持的级别
    if (![self check:type]) return;
    
    // 插件存在，调用插件；否则使用默认插件
    id<FWLogPlugin> plugin = [FWPluginManager loadPlugin:@protocol(FWLogPlugin)];
    if (!plugin || ![plugin respondsToSelector:@selector(fwLog:withMessage:)]) {
        plugin = FWLogPluginImpl.sharedInstance;
    }
    [plugin fwLog:type withMessage:message];
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

- (void)fwLog:(FWLogType)type withMessage:(NSString *)message
{
    switch (type) {
        case FWLogTypeError:
            NSLog(@"%@ ERROR: %@", @"❌", message);
            break;
        case FWLogTypeWarn:
            NSLog(@"%@ WARN: %@", @"⚠️", message);
            break;
        case FWLogTypeInfo:
            NSLog(@"%@ INFO: %@", @"ℹ️", message);
            break;
        case FWLogTypeDebug:
            NSLog(@"%@ DEBUG: %@", @"⏱️", message);
            break;
        default:
            NSLog(@"%@ TRACE: %@", @"📝", message);
            break;
    }
}

@end
