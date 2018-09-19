/*!
 @header     NSArray+FWFramework.h
 @indexgroup FWFramework
 @brief      NSArray分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-09-17
 */

#import <Foundation/Foundation.h>

/*!
 @brief NSArray分类
 */
@interface NSArray<__covariant ObjectType> (FWFramework)

/*!
 @brief 从数组中随机取出对象
 
 @return 随机对象
 */
- (ObjectType)fwRandomObject;

/*!
 @brief 获取翻转后的新数组
 
 @return 翻转后的数组
 */
- (NSArray *)fwReverseArray;

/*!
 @brief 获取打乱后的新数组
 
 @return 打乱后的数组
 */
- (NSArray *)fwShuffleArray;

/*!
 @brief 数组中是否含有NSNull值
 
 @return 是否含有NSNull
 */
- (BOOL)fwIncludeNull;

@end

#pragma mark - NSMutableArray+FWFramework

/*!
 @brief NSMutableArray分类
 */
@interface NSMutableArray<ObjectType> (FWFramework)

/*!
 @brief 当前数组翻转
 */
- (void)fwReverse;

/*!
 @brief 打乱当前数组
 */
- (void)fwShuffle;

@end
