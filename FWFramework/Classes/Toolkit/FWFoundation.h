/*!
 @header     FWFoundation.h
 @indexgroup FWFramework
 @brief      FWFoundation
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/10/22
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - NSAttributedString+FWFoundation

/*!
 @brief NSAttributedString+FWFoundation
 */
@interface NSAttributedString (FWFoundation)

/// html字符串转换为NSAttributedString对象。如需设置默认字体和颜色，请使用addAttributes方法或附加CSS样式
+ (nullable instancetype)fwAttributedStringWithHtmlString:(NSString *)htmlString;

/// NSAttributedString对象转换为html字符串
- (nullable NSString *)fwHtmlString;

@end

#pragma mark - NSDate+FWFoundation

/*!
 @brief NSDate+FWFoundation
 */
@interface NSDate (FWFoundation)

/// 当前时间戳，没有设置过返回本地时间戳，可同步设置服务器时间戳，同步后调整手机时间不影响
@property (class, nonatomic, assign) NSTimeInterval fwCurrentTime;

@end

NS_ASSUME_NONNULL_END
