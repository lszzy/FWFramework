//
//  Logger.h
//  FWFramework
//
//  Created by wuyong on 2022/8/20.
//

#import <Foundation/Foundation.h>

/**
 记录分组日志
 
 @param aGroup 分组名称
 @param aType 日志类型
 @param aFormat 日志格式，同NSLog
 */
#define __FWLogGroup( aGroup, aType, aFormat, ... ) \
    if ([__FWLogger check:aType]) [__FWLogger group:aGroup type:aType format:(@"(%@ %@ #%d %s) " aFormat), NSThread.isMainThread ? @"[M]" : @"[T]", [@(__FILE__) lastPathComponent], __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__];

#pragma mark - __FWLogType

NS_ASSUME_NONNULL_BEGIN

/**
 日志类型定义
 
 @const __FWLogTypeError 错误类型，0...00001
 @const __FWLogTypeWarn 警告类型，0...00010
 @const __FWLogTypeInfo 信息类型，0...00100
 @const __FWLogTypeDebug 调试类型，0...01000
 @const __FWLogTypeTrace 跟踪类型，0...10000
 */
typedef NS_OPTIONS(NSUInteger, __FWLogType) {
    __FWLogTypeError = 1 << 0,
    __FWLogTypeWarn  = 1 << 1,
    __FWLogTypeInfo  = 1 << 2,
    __FWLogTypeDebug = 1 << 3,
    __FWLogTypeTrace = 1 << 4,
} NS_SWIFT_NAME(LogType);

#pragma mark - __FWLogLevel

/**
 日志级别定义
 
 @const __FWLogLevelOff 关闭日志，0...00000
 @const __FWLogLevelError 错误以上级别，0...00001
 @const __FWLogLevelWarn 警告以上级别，0...00011
 @const __FWLogLevelInfo 信息以上级别，0...00111
 @const __FWLogLevelDebug 调试以上级别，0...01111
 @const __FWLogLevelTrace 跟踪以上级别，0...11111
 @const __FWLogLevelAll 所有级别，1...11111
 */
typedef NS_ENUM(NSUInteger, __FWLogLevel) {
    __FWLogLevelOff   = 0,
    __FWLogLevelError = __FWLogTypeError,
    __FWLogLevelWarn  = __FWLogLevelError | __FWLogTypeWarn,
    __FWLogLevelInfo  = __FWLogLevelWarn  | __FWLogTypeInfo,
    __FWLogLevelDebug = __FWLogLevelInfo  | __FWLogTypeDebug,
    __FWLogLevelTrace = __FWLogLevelDebug | __FWLogTypeTrace,
    __FWLogLevelAll   = NSUIntegerMax,
} NS_SWIFT_NAME(LogLevel);

#pragma mark - __FWLogger

/**
 日志记录类。支持设置全局日志级别和自定义__FWLoggerPlugin插件
 */
NS_SWIFT_NAME(Logger)
@interface __FWLogger : NSObject

/// 全局日志级别，默认调试为All，正式为Off
@property (class, nonatomic, assign) __FWLogLevel level;

/**
 检查是否需要记录指定类型日志
 
 @param type 日志类型
 @return 是否需要记录
 */
+ (BOOL)check:(__FWLogType)type;

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
         type:(__FWLogType)type
       format:(NSString *)format, ...;

/**
 记录类型日志
 
 @param type 日志类型
 @param message 日志消息
 */
+ (void)log:(__FWLogType)type
    message:(NSString *)message;

/**
 记录类型日志，支持分组和用户信息
 
 @param type 日志类型
 @param message 日志消息
 @param group 日志分组
 @param userInfo 用户信息
 */
+ (void)log:(__FWLogType)type
    message:(NSString *)message
      group:(nullable NSString *)group
   userInfo:(nullable NSDictionary *)userInfo;

@end

#pragma mark - __FWLoggerPlugin

/**
 日志插件协议
 */
NS_SWIFT_NAME(LoggerPlugin)
@protocol __FWLoggerPlugin <NSObject>

@required

/**
 记录日志协议方法

 @param type 日志类型
 @param message 日志消息
 @param group 日志分组
 @param userInfo 用户信息
 */
- (void)log:(__FWLogType)type
    message:(NSString *)message
      group:(nullable NSString *)group
   userInfo:(nullable NSDictionary *)userInfo;

@end

#pragma mark - __FWLoggerPluginImpl

/**
 默认NSLog日志插件
 */
NS_SWIFT_NAME(LoggerPluginImpl)
@interface __FWLoggerPluginImpl : NSObject <__FWLoggerPlugin>

/// 单例模式对象
@property (class, nonatomic, readonly) __FWLoggerPluginImpl *sharedInstance NS_SWIFT_NAME(shared);

@end

NS_ASSUME_NONNULL_END
