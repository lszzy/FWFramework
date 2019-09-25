/*!
 @header     FWLog.m
 @indexgroup FWFramework
 @brief      日志记录
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

+ (void)verbose:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self log:FWLogTypeVerbose withMessage:message];
}

+ (void)debug:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self log:FWLogTypeDebug withMessage:message];
}

+ (void)info:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self log:FWLogTypeInfo withMessage:message];
}

+ (void)warn:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self log:FWLogTypeWarn withMessage:message];
}

+ (void)error:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self log:FWLogTypeError withMessage:message];
}

+ (void)log:(FWLogType)type withMessage:(NSString *)message
{
    // 过滤不支持的级别
    if (!(fwStaticLogLevel & type)) return;
    
    // 插件存在，调用插件
    id<FWLogPlugin> plugin = [[FWPluginManager sharedInstance] loadPlugin:@protocol(FWLogPlugin)];
    if (plugin) {
        if ([plugin respondsToSelector:@selector(fwLog:withMessage:)]) {
            [plugin fwLog:type withMessage:message];
        }
        return;
    }
    
    // 插件不存在，系统日志
    switch (type) {
        case FWLogTypeError:
            NSLog(@"❌ ERROR: %@", message);
            break;
        case FWLogTypeWarn:
            NSLog(@"⚠️ WARN: %@", message);
            break;
        case FWLogTypeInfo:
            NSLog(@"ℹ️ INFO: %@", message);
            break;
        case FWLogTypeDebug:
            NSLog(@"📝 DEBUG: %@", message);
            break;
        default:
            NSLog(@"♈ VERBOSE: %@", message);
            break;
    }
}

@end
