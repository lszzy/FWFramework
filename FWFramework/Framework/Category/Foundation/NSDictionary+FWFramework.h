/*!
 @header     NSDictionary+FWFramework.h
 @indexgroup FWFramework
 @brief      NSDictionary分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-09-17
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief NSDictionary分类
 */
@interface NSDictionary<__covariant KeyType, __covariant ObjectType> (FWFramework)

/*!
 @brief 字典中是否含有NSNull值
 
 @return 是否含有NSNull
 */
- (BOOL)fwIncludeNull;

/*!
 @brief 递归移除字典中NSNull值
 
 @return 不含NSNull的字典
 */
- (NSDictionary *)fwRemoveNull;

/*!
 @brief 移除字典中NSNull值
 
 @praram recursive 是否递归
 @return 不含NSNull的字典
 */
- (NSDictionary *)fwRemoveNullRecursive:(BOOL)recursive;

@end

NS_ASSUME_NONNULL_END
