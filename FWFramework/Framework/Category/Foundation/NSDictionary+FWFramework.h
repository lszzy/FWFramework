/*!
 @header     NSDictionary+FWFramework.h
 @indexgroup FWFramework
 @brief      NSDictionary分类
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-09-17
 */

#import <Foundation/Foundation.h>
#import "NSDictionary+FWThread.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 @brief NSDictionary分类
 */
@interface NSDictionary<__covariant KeyType, __covariant ObjectType> (FWFramework)

/*!
 @brief 过滤字典元素
 
 @param block 如果block返回NO，则去掉该元素
 @return 新的字典
 */
- (instancetype)fwFilterWithBlock:(BOOL (^)(KeyType key, ObjectType obj))block;

/*!
 @brief 映射字典元素
 
 @param block 返回的obj重新组装成一个字典
 @return 新的字典
 */
- (NSDictionary *)fwMapWithBlock:(id _Nullable (^)(KeyType key, ObjectType obj))block;

/*!
 @brief 匹配字典第一个元素
 
 @param block 返回满足条件的第一个obj
 @return 指定对象
 */
- (nullable ObjectType)fwMatchWithBlock:(BOOL (^)(KeyType key, ObjectType obj))block;

/*!
 @brief 从字典中随机取出Key，如@{@"a"=>@2, @"b"=>@8, @"c"=>@0}随机取出@"b"
 
 @return 随机Key
 */
- (nullable KeyType)fwRandomKey;

/*!
 @brief 从字典中随机取出对象，如@{@"a"=>@2, @"b"=>@8, @"c"=>@0}随机取出@8
 
 @return 随机对象
 */
- (nullable ObjectType)fwRandomObject;

/*!
 @brief 从字典中按权重Object随机取出Key，如@{@"a"=>@2, @"b"=>@8, @"c"=>@0}大概率取出@"b"，不会取出@"c"
 
 @return 随机Key
 */
- (nullable KeyType)fwRandomWeightKey;

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
