/*!
 @header     NSDictionary+FWFramework.h
 @indexgroup FWFramework
 @brief      NSDictionary分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-09-17
 */

#import <Foundation/Foundation.h>

/*!
 @brief NSDictionary分类
 */
@interface NSDictionary<__covariant KeyType, __covariant ObjectType> (FWFramework)

/*!
 @brief 字典中是否含有NSNull值
 
 @return 是否含有NSNull
 */
- (BOOL)fwIncludeNull;

@end
