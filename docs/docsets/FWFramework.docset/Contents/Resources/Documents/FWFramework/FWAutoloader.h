/**
 @header     FWAutoloader.h
 @indexgroup FWFramework
 @author     wuyong
 @copyright  Copyright © 2021 wuyong.site. All rights reserved.
 @updated    2021/1/15
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Function

/// 自动加载Swift类并调用autoload方法，参数为Class或String
FOUNDATION_EXPORT BOOL FWAutoload(id clazz) NS_SWIFT_UNAVAILABLE("");

#pragma mark - FWAutoloader

/**
 自动加载器，处理swift不支持load方法问题
 @note 本方案采用objc扩展方法实现，相对于全局扫描类方案性能高(1/200)，使用简单
    使用方法：新增FWAutoloader扩展objc类方法，以load开头即会自动调用，注意方法名不要重复，建议load+类名+扩展名
 */
NS_SWIFT_NAME(Autoloader)
@interface FWAutoloader : NSObject

@end

NS_ASSUME_NONNULL_END
