/*!
 @header     NSObject+FWFramework.h
 @indexgroup FWFramework
 @brief      NSObject分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-15
 */

#import <Foundation/Foundation.h>
#import "NSObject+FWBlock.h"
#import "NSObject+FWRuntime.h"
#import "NSObject+FWSwizzle.h"
#import "NSObject+FWSafeType.h"
#import "NSObject+FWThread.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief NSObject分类
 @discussion 可使用NS_UNAVAILABLE标记方法不可用，NS_DESIGNATED_INITIALIZER标记默认init方法
 */
@interface NSObject (FWFramework)

/*! @brief 临时对象 */
@property (nullable, nonatomic, strong) id fwTempObject;

/**
 使用NSKeyedArchiver和NSKeyedUnarchiver深拷对象
 
 @return 出错返回nil
 */
- (nullable id)fwArchiveCopy;

@end

NS_ASSUME_NONNULL_END
