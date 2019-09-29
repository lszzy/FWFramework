//
//  AppRouter.h
//  Example
//
//  Created by wuyong on 2018/11/29.
//  Copyright © 2018 wuyong.site. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @brief 路由管理器
 */
@interface AppRouter : NSObject

FWStaticString(ROUTE_TEST);
FWStaticString(ROUTE_WILDCARD);
FWStaticString(ROUTE_OBJECT);
FWStaticString(ROUTE_CONTROLLER);

@end
