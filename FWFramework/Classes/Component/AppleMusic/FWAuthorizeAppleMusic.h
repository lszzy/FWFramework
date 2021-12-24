//
//  FWAuthorizeAppleMusic.h
//  FWFramework
//
//  Created by wuyong on 17/3/15.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#if FWFrameworkAppleMusic
@import FWFramework;
#else
#import "FWAuthorize.h"
#endif

/// 音乐，需启用AppleMusic子模块，Info.plst需配置NSAppleMusicUsageDescription
static const FWAuthorizeType FWAuthorizeTypeAppleMusic = 6;
