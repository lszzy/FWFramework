/**
 @header     FWLogger.h
 @indexgroup FWFramework
      日志记录
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-11
 */

#import <Foundation/Foundation.h>

#pragma mark - Macro

/**
 记录跟踪日志
 
 @param format 日志格式，同NSLog
 */
#define FWLogTrace( format, ... ) \
    if ([FWLogger check:FWLogTypeTrace]) [FWLogger trace:(@"(%@ %@ #%d %s) " format), NSThread.isMainThread ? @"[M]" : @"[T]", [@(__FILE__) lastPathComponent], __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__];

/**
 记录调试日志
 
 @param format 日志格式，同NSLog
 */
#define FWLogDebug( format, ... ) \
    if ([FWLogger check:FWLogTypeDebug]) [FWLogger debug:(@"(%@ %@ #%d %s) " format), NSThread.isMainThread ? @"[M]" : @"[T]", [@(__FILE__) lastPathComponent], __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__];

/**
 记录信息日志
 
 @param format 日志格式，同NSLog
 */
#define FWLogInfo( format, ... ) \
    if ([FWLogger check:FWLogTypeInfo]) [FWLogger info:(@"(%@ %@ #%d %s) " format), NSThread.isMainThread ? @"[M]" : @"[T]", [@(__FILE__) lastPathComponent], __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__];

/**
 记录警告日志
 
 @param format 日志格式，同NSLog
 */
#define FWLogWarn( format, ... ) \
    if ([FWLogger check:FWLogTypeWarn]) [FWLogger warn:(@"(%@ %@ #%d %s) " format), NSThread.isMainThread ? @"[M]" : @"[T]", [@(__FILE__) lastPathComponent], __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__];

/**
 记录错误日志
 
 @param format 日志格式，同NSLog
 */
#define FWLogError( format, ... ) \
    if ([FWLogger check:FWLogTypeError]) [FWLogger error:(@"(%@ %@ #%d %s) " format), NSThread.isMainThread ? @"[M]" : @"[T]", [@(__FILE__) lastPathComponent], __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__];

/**
 记录分组日志
 
 @param aGroup 分组名称
 @param aType 日志类型
 @param aFormat 日志格式，同NSLog
 */
#define FWLogGroup( aGroup, aType, aFormat, ... ) \
    if ([FWLogger check:aType]) [FWLogger group:aGroup type:aType format:(@"(%@ %@ #%d %s) " aFormat), NSThread.isMainThread ? @"[M]" : @"[T]", [@(__FILE__) lastPathComponent], __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__];

#pragma mark - FWLogType

NS_ASSUME_NONNULL_BEGIN

/**
 日志类型定义
 
 @const FWLogTypeError 错误类型，0...00001
 @const FWLogTypeWarn 警告类型，0...00010
 @const FWLogTypeInfo 信息类型，0...00100
 @const FWLogTypeDebug 调试类型，0...01000
 @const FWLogTypeTrace 跟踪类型，0...10000
 */
typedef NS_OPTIONS(NSUInteger, FWLogType) {
    FWLogTypeError = 1 << 0,
    FWLogTypeWarn  = 1 << 1,
    FWLogTypeInfo  = 1 << 2,
    FWLogTypeDebug = 1 << 3,
    FWLogTypeTrace = 1 << 4,
} NS_SWIFT_NAME(LogType);

#pragma mark - FWLogLevel

/**
 日志级别定义
 
 @const FWLogLevelOff 关闭日志，0...00000
 @const FWLogLevelError 错误以上级别，0...00001
 @const FWLogLevelWarn 警告以上级别，0...00011
 @const FWLogLevelInfo 信息以上级别，0...00111
 @const FWLogLevelDebug 调试以上级别，0...01111
 @const FWLogLevelTrace 跟踪以上级别，0...11111
 @const FWLogLevelAll 所有级别，1...11111
 */
typedef NS_ENUM(NSUInteger, FWLogLevel) {
    FWLogLevelOff   = 0,
    FWLogLevelError = FWLogTypeError,
    FWLogLevelWarn  = FWLogLevelError | FWLogTypeWarn,
    FWLogLevelInfo  = FWLogLevelWarn  | FWLogTypeInfo,
    FWLogLevelDebug = FWLogLevelInfo  | FWLogTypeDebug,
    FWLogLevelTrace = FWLogLevelDebug | FWLogTypeTrace,
    FWLogLevelAll   = NSUIntegerMax,
} NS_SWIFT_NAME(LogLevel);

#pragma mark - FWLogger

/**
 日志记录类。支持设置全局日志级别和自定义FWLoggerPlugin插件
 */
NS_SWIFT_NAME(Logger)
@interface FWLogger : NSObject

/// 全局日志级别，默认调试为All，正式为Off
@property (class, nonatomic, assign) FWLogLevel level;

/**
 检查是否需要记录指定类型日志
 
 @param type 日志类型
 @return 是否需要记录
 */
+ (BOOL)check:(FWLogType)type;

/**
 跟踪日志

 @param format 日志格式，同NSLog
 */
+ (void)trace:(NSString *)format, ...;

/**
 调试日志
 
 @param format 日志格式，同NSLog
 */
+ (void)debug:(NSString *)format, ...;

/**
 信息日志
 
 @param format 日志格式，同NSLog
 */
+ (void)info:(NSString *)format, ...;

/**
 警告日志
 
 @param format 日志格式，同NSLog
 */
+ (void)warn:(NSString *)format, ...;

/**
 错误日志
 
 @param format 日志格式，同NSLog
 */
+ (void)error:(NSString *)format, ...;

/**
 分组日志
 
 @param group 分组名称
 @param type 日志类型
 @param format 日志格式，同NSLog
 */
+ (void)group:(NSString *)group
         type:(FWLogType)type
       format:(NSString *)format, ...;

/**
 记录类型日志
 
 @param type 日志类型
 @param message 日志消息
 */
+ (void)log:(FWLogType)type
    message:(NSString *)message;

/**
 记录类型日志，支持分组和用户信息
 
 @param type 日志类型
 @param message 日志消息
 @param group 日志分组
 @param userInfo 用户信息
 */
+ (void)log:(FWLogType)type
    message:(NSString *)message
      group:(nullable NSString *)group
   userInfo:(nullable NSDictionary *)userInfo;

@end

#pragma mark - FWLoggerPlugin

/**
 日志插件协议
 */
NS_SWIFT_NAME(LoggerPlugin)
@protocol FWLoggerPlugin <NSObject>

@required

/**
 记录日志协议方法

 @param type 日志类型
 @param message 日志消息
 @param group 日志分组
 @param userInfo 用户信息
 */
- (void)log:(FWLogType)type
    message:(NSString *)message
      group:(nullable NSString *)group
   userInfo:(nullable NSDictionary *)userInfo;

@end

#pragma mark - FWLoggerPluginImpl

/**
 默认NSLog日志插件
 */
NS_SWIFT_NAME(LoggerPluginImpl)
@interface FWLoggerPluginImpl : NSObject <FWLoggerPlugin>

/// 单例模式对象
@property (class, nonatomic, readonly) FWLoggerPluginImpl *sharedInstance;

@end

NS_ASSUME_NONNULL_END
