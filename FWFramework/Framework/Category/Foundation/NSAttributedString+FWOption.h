/*!
 @header     NSAttributedString+FWOption.h
 @indexgroup FWFramework
 @brief      NSAttributedString+FWOption
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/8/14
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - FWAttributedOption

/*!
 @brief NSAttributedString属性封装器
 */
@interface FWAttributedOption : NSObject

// 转换为属性字典
- (NSDictionary<NSAttributedStringKey, id> *)toDictionary;

@end

/*!
 @brief NSAttributedString+FWOption
 */
@interface NSAttributedString (FWOption)

// 快速创建NSAttributedString，自定义选项
+ (instancetype)fwAttributedString:(NSString *)string withOption:(nullable FWAttributedOption *)option;

@end

NS_ASSUME_NONNULL_END
