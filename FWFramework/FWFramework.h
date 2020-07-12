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

// Kernel
#import <FWFramework/FWFramework+Kernel.h>

// Service
#if __has_include(<FWFramework/FWFramework+Service.h>)
#import <FWFramework/FWFramework+Service.h>
#endif

// Component
#if __has_include(<FWFramework/FWFramework+Component.h>)
#import <FWFramework/FWFramework+Component.h>
#endif

// Application
#if __has_include(<FWFramework/FWFramework+Application.h>)
#import <FWFramework/FWFramework+Application.h>
#endif

#else

// Kernel
#import "FWFramework+Kernel.h"

// Service
#if __has_include("FWFramework+Service.h")
#import "FWFramework+Service.h"
#endif

// Component
#if __has_include("FWFramework+Component.h")
#import "FWFramework+Component.h"
#endif

// Application
#if __has_include("FWFramework+Application.h")
#import "FWFramework+Application.h"
#endif

#endif
