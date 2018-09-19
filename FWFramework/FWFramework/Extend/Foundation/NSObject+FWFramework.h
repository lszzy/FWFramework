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
#import "NSObject+FWSafeType.h"

/*!
 @brief NSObject分类
 */
@interface NSObject (FWFramework)

/*! @brief 临时对象 */
@property (nonatomic, strong) id fwTempObject;

/**
 使用NSKeyedArchiver和NSKeyedUnarchiver深拷对象
 
 @return 出错返回nil
 */
- (id)fwArchiveCopy;

@end
