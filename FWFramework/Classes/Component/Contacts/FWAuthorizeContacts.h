//
//  FWAuthorizeContacts.h
//  FWFramework
//
//  Created by wuyong on 17/3/15.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#if FWFrameworkContacts
@import FWFramework;
#else
#import "FWAuthorize.h"
#endif

/// 联系人，需启用Contacts子模块，Info.plst需配置NSContactsUsageDescription
static const FWAuthorizeType FWAuthorizeTypeContacts = 9;
