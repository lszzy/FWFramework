//
//  Exception.h
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 异常捕获通知，object为NSException对象，userInfo为附加信息(name|reason|method|remark|symbols)
extern NSNotificationName const __FWExceptionCapturedNotification NS_SWIFT_NAME(FWExceptionCaptured);

/// 框架异常捕获类
///
/// @see https://github.com/jezzmemo/JJException
/// @see https://github.com/chenfanfang/AvoidCrash
NS_SWIFT_NAME(ExceptionManager)
@interface __FWExceptionManager : NSObject

/// 自定义需要捕获未定义方法异常的类，默认[NSNull, NSNumber, NSString, NSArray, NSDictionary]
@property (class, nonatomic, copy) NSArray<Class> *captureClasses;

/// 开启框架自带异常捕获功能，默认关闭
+ (void)startCaptureExceptions;

/// 捕获自定义异常并发送通知，可设置备注
+ (void)captureException:(NSException *)exception remark:(nullable NSString *)remark;

@end

NS_ASSUME_NONNULL_END
