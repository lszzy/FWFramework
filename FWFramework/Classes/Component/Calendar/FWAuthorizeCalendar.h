//
//  FWAuthorize.h
//  FWFramework
//
//  Created by wuyong on 17/3/15.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWAuthorize.h"

/// 日历，需启用Calendar子模块，Info.plst需配置NSCalendarsUsageDescription
static const FWAuthorizeType FWAuthorizeTypeCalendars = 7;
/// 提醒，需启用Calendar子模块，Info.plst需配置NSRemindersUsageDescription
static const FWAuthorizeType FWAuthorizeTypeReminders = 8;
