//
//  FWFramework.h
//  FWFramework
//
//  Created by wuyong on 2019/5/14.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<FWFramework/FWFramework.h>)

// Version
FOUNDATION_EXPORT double FWFrameworkVersionNumber;
FOUNDATION_EXPORT const unsigned char FWFrameworkVersionString[];

// Framework
#import <FWFramework/FWFramework+Framework.h>

// Application
#if __has_include(<FWFramework/FWFramework+Application.h>)
#import <FWFramework/FWFramework+Application.h>
#endif

// Component
#if __has_include(<FWFramework/FWFramework+Component.h>)
#import <FWFramework/FWFramework+Component.h>
#endif

// AppClip
#if __has_include(<FWFramework/FWFramework+AppClip.h>)
#import <FWFramework/FWFramework+AppClip.h>
#endif

#else

// Framework
#import "FWFramework+Framework.h"

// Application
#if __has_include("FWFramework+Application.h")
#import "FWFramework+Application.h"
#endif

// Component
#if __has_include("FWFramework+Component.h")
#import "FWFramework+Component.h"
#endif

// AppClip
#if __has_include("FWFramework+AppClip.h")
#import "FWFramework+AppClip.h"
#endif

#endif
