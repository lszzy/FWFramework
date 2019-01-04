/*!
 @header     FWDbModel.h
 @indexgroup FWFramework
 @brief      FWDbModel
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/1/4
 */

#import "FWModel.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  DBModel协议，继承FWModel
 */
@protocol FWDbModel <FWModel>

@optional

// 定义主键字段，默认pkid
+ (nullable NSString *)fwDbModelPrimaryKey;

// 定义表名，默认类名
+ (nullable NSString *)fwDbModelTableName;

@end

@interface NSObject (FWDbModel)

@end

NS_ASSUME_NONNULL_END
