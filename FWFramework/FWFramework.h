//
//  FWFramework.h
//  FWFramework
//
//  Created by wuyong on 2019/5/14.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

#if __has_include(<FWFramework/FWFramework.h>)

FOUNDATION_EXPORT double FWFrameworkVersionNumber;
FOUNDATION_EXPORT const unsigned char FWFrameworkVersionString[];

#if __has_include(<FWFramework/FWFramework-Swift.h>)
#import <FWFramework/FWFramework-Swift.h>
#endif

#import <FWFramework/FWFramework+Framework.h>

#if __has_include(<FWFramework/FWFramework+Application.h>)
#import <FWFramework/FWFramework+Application.h>
#endif

#else

#import "FWFramework+Framework.h"

#if __has_include("FWFramework+Application.h")
#import "FWFramework+Application.h"
#endif

#endif
