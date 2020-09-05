/*!
 @header     FWModel.h
 @indexgroup FWFramework
 @brief      FWModel
 @author     wuyong
 @copyright  Copyright © 2020 wuyong.site. All rights reserved.
 @updated    2020/7/22
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FWJsonModel;

/*!
 @brief FWModel
 */
@protocol FWModel <FWJsonModel>

@end

/*!
 @brief FWViewModel
 */
@protocol FWViewModel <NSObject>

@end

NS_ASSUME_NONNULL_END
