/**
 @header     FWException.h
 @indexgroup FWFramework
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2022/04/01
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 异常捕获通知，object为NSException对象，userInfo为附加信息(name|reason|method|remark|symbols)
extern NSNotificationName const FWExceptionCapturedNotification;

/// 框架异常捕获类
///
/// @see https://github.com/jezzmemo/JJException
/// @see https://github.com/chenfanfang/AvoidCrash
@interface FWException : NSObject

/// 开启框架自带异常捕获功能，默认关闭
+ (void)startCaptureExceptions;

/// 捕获自定义异常并发送通知，可设置备注
+ (void)captureException:(NSException *)exception remark:(nullable NSString *)remark;

@end

NS_ASSUME_NONNULL_END
