/*!
 @header     NSUserDefaults+FWFramework.h
 @indexgroup FWFramework
 @brief      NSUserDefaults+FWFramework
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018/9/18
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief NSUserDefaults+FWFramework
 */
@interface NSUserDefaults (FWFramework)

// 从standard读取对象，支持unarchive对象
+ (nullable id)fwObjectForKey:(NSString *)key;

// 保存对象到standard，支持archive对象
+ (void)fwSetObject:(nullable id)object forKey:(NSString *)key;

// 读取对象，支持unarchive对象
- (nullable id)fwObjectForKey:(NSString *)key;

// 保存对象，支持archive对象
- (void)fwSetObject:(nullable id)object forKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
