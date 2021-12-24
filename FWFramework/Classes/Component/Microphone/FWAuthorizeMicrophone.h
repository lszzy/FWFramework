//
//  FWAuthorizeMicrophone.h
//  FWFramework
//
//  Created by wuyong on 17/3/15.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#if FWFrameworkMicrophone
@import FWFramework;
#else
#import "FWAuthorize.h"
#endif

/// 麦克风，需启用Microphone子模块，Info.plst需配置NSMicrophoneUsageDescription
static const FWAuthorizeType FWAuthorizeTypeMicrophone = 10;
