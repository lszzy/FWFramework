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

#else

// Framework
#import "FWFramework+Framework.h"

// Application
#if __has_include("FWFramework+Application.h")
#import "FWFramework+Application.h"
#endif

#endif
