/*!
 @header     FWLog.h
 @indexgroup FWFramework
 @brief      日志记录
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-11
 */

#import <Foundation/Foundation.h>

#pragma mark - Macro

/*!
 @brief 记录日志内部宏
 
 @parseOnly
 @param type 日志类型
 @param format 日志格式，同NSLog
 */
#define FWLogType_( type, format, ... ) \
    if (FWLog.level & type) [FWLog log:type withMessage:[NSString stringWithFormat:(@"(%@ #%d %s) " format), [@(__FILE__) lastPathComponent], __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__]];

/*!
 @brief 记录详细日志
 
 @param format 日志格式，同NSLog
 */
#define FWLogVerbose( format, ... ) \
    FWLogType_( FWLogTypeVerbose, format, ##__VA_ARGS__ );

/*!
 @brief 记录调试日志
 
 @param format 日志格式，同NSLog
 */
#define FWLogDebug( format, ... ) \
    FWLogType_( FWLogTypeDebug, format, ##__VA_ARGS__ );

/*!
 @brief 记录信息日志
 
 @param format 日志格式，同NSLog
 */
#define FWLogInfo( format, ... ) \
    FWLogType_( FWLogTypeInfo, format, ##__VA_ARGS__ );

/*!
 @brief 记录警告日志
 
 @param format 日志格式，同NSLog
 */
#define FWLogWarn( format, ... ) \
    FWLogType_( FWLogTypeWarn, format, ##__VA_ARGS__ );

/*!
 @brief 记录错误日志
 
 @param format 日志格式，同NSLog
 */
#define FWLogError( format, ... ) \
    FWLogType_( FWLogTypeError, format, ##__VA_ARGS__ );

#pragma mark - FWLog

/*!
 @brief 日志类型定义
 
 @const FWLogTypeError 错误类型，0...00001
 @const FWLogTypeWarn 警告类型，0...00010
 @const FWLogTypeInfo 信息类型，0...00100
 @const FWLogTypeDebug 调试类型，0...01000
 @const FWLogTypeVerbose 详细类型，0...10000
 */
typedef NS_OPTIONS(NSUInteger, FWLogType) {
    FWLogTypeError   = 1 << 0,
    FWLogTypeWarn    = 1 << 1,
    FWLogTypeInfo    = 1 << 2,
    FWLogTypeDebug   = 1 << 3,
    FWLogTypeVerbose = 1 << 4,
};

/*!
 @brief 日志级别定义
 
 @const FWLogLevelOff 关闭日志，0...00000
 @const FWLogLevelError 错误以上级别，0...00001
 @const FWLogLevelWarn 警告以上级别，0...00011
 @const FWLogLevelInfo 信息以上级别，0...00111
 @const FWLogLevelDebug 调试以上级别，0...01111
 @const FWLogLevelVerbose 详细以上级别，0...11111
 @const FWLogLevelAll 所有级别，1...11111
 */
typedef NS_ENUM(NSUInteger, FWLogLevel) {
    FWLogLevelOff     = 0,
    FWLogLevelError   = FWLogTypeError,
    FWLogLevelWarn    = FWLogLevelError | FWLogTypeWarn,
    FWLogLevelInfo    = FWLogLevelWarn  | FWLogTypeInfo,
    FWLogLevelDebug   = FWLogLevelInfo  | FWLogTypeDebug,
    FWLogLevelVerbose = FWLogLevelDebug | FWLogTypeVerbose,
    FWLogLevelAll     = NSUIntegerMax,
};

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief 日志记录类。支持设置全局日志级别和自定义FWLogPlugin插件
 */
@interface FWLog : NSObject

/*! @brief 全局日志级别，默认调试为All，正式为Off */
@property (class, nonatomic, assign) FWLogLevel level;

/*!
 @brief 详细日志

 @param message 日志消息
 */
+ (void)verbose:(NSString *)message;

/*!
 @brief 调试日志
 
 @param message 日志消息
 */
+ (void)debug:(NSString *)message;

/*!
 @brief 信息日志
 
 @param message 日志消息
 */
+ (void)info:(NSString *)message;

/*!
 @brief 警告日志
 
 @param message 日志消息
 */
+ (void)warn:(NSString *)message;

/*!
 @brief 错误日志
 
 @param message 日志消息
 */
+ (void)error:(NSString *)message;

/*!
 @brief 记录类型日志
 
 @param type 日志类型
 @param message 日志消息
 */
+ (void)log:(FWLogType)type withMessage:(NSString *)message;

@end

#pragma mark - FWLogPlugin

/*!
 @brief 日志插件协议
 */
@protocol FWLogPlugin <NSObject>

@required

/*!
 @brief 记录日志协议方法

 @param type 日志类型
 @param message 日志消息
 */
- (void)fwLog:(FWLogType)type withMessage:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
