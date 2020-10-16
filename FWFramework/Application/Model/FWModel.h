//
//  FWModel.h
//  FWFramework
//
//  Created by wuyong on 2020/9/7.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

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
@protocol FWViewModel <FWJsonModel>

@end

NS_ASSUME_NONNULL_END
