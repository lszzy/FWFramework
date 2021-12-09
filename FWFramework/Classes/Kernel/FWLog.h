/**
 @header     FWLog.h
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
    [FWLog trace:(@"(%@ %@ #%d %s) " format), NSThread.isMainThread ? @"[M]" : @"[T]", [@(__FILE__) lastPathComponent], __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__];

/**
 记录调试日志
 
 @param format 日志格式，同NSLog
 */
#define FWLogDebug( format, ... ) \
    [FWLog debug:(@"(%@ %@ #%d %s) " format), NSThread.isMainThread ? @"[M]" : @"[T]", [@(__FILE__) lastPathComponent], __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__];

/**
 记录信息日志
 
 @param format 日志格式，同NSLog
 */
#define FWLogInfo( format, ... ) \
    [FWLog info:(@"(%@ %@ #%d %s) " format), NSThread.isMainThread ? @"[M]" : @"[T]", [@(__FILE__) lastPathComponent], __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__];

/**
 记录警告日志
 
 @param format 日志格式，同NSLog
 */
#define FWLogWarn( format, ... ) \
    [FWLog warn:(@"(%@ %@ #%d %s) " format), NSThread.isMainThread ? @"[M]" : @"[T]", [@(__FILE__) lastPathComponent], __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__];

/**
 记录错误日志
 
 @param format 日志格式，同NSLog
 */
#define FWLogError( format, ... ) \
    [FWLog error:(@"(%@ %@ #%d %s) " format), NSThread.isMainThread ? @"[M]" : @"[T]", [@(__FILE__) lastPathComponent], __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__];

#pragma mark - FWLog

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
};

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
};

NS_ASSUME_NONNULL_BEGIN

/**
 日志记录类。支持设置全局日志级别和自定义FWLogPlugin插件
 */
@interface FWLog : NSObject

/** 全局日志级别，默认调试为All，正式为Off */
@property (class, nonatomic, assign) FWLogLevel level;

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
 记录类型日志
 
 @param type 日志类型
 @param message 日志消息
 */
+ (void)log:(FWLogType)type withMessage:(NSString *)message;

@end

#pragma mark - FWLogPlugin

/**
 日志插件协议
 */
@protocol FWLogPlugin <NSObject>

@required

/**
 记录日志协议方法

 @param type 日志类型
 @param message 日志消息
 */
- (void)fwLog:(FWLogType)type withMessage:(NSString *)message;

@end

#pragma mark - FWLogPluginImpl

/**
 默认NSLog日志插件
 */
@interface FWLogPluginImpl : NSObject <FWLogPlugin>

/// 单例模式对象
@property (class, nonatomic, readonly) FWLogPluginImpl *sharedInstance;

@end

NS_ASSUME_NONNULL_END
