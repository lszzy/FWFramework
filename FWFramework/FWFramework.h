//
//  FWFramework.h
//  FWFramework
//
//  Created by wuyong on 2019/5/14.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import <UIKit/UIkit.h>

#ifndef FWFramework_h
#define FWFramework_h

static NSString * const FWFrameworkVersion = @"0.7.7";

#if __has_include("FWMacro.h")
#import "FWMacro.h"
#endif

#if __has_include("FWNotification.h")
#import "FWNotification.h"
#endif

#if __has_include("FWToolkit.h")
#import "FWToolkit.h"
#endif

#if __has_include("FWAppDelegate.h")
#import "FWAppDelegate.h"
#endif

#if __has_include("FWCacheManager.h")
#import "FWCacheManager.h"
#endif

#if __has_include("FWDatabaseQueue.h")
#import "FWDatabaseQueue.h"
#endif

#if __has_include("FWWebImage.h")
#import "FWWebImage.h"
#endif

#if __has_include("FWHTTPSessionManager.h")
#import "FWHTTPSessionManager.h"
#endif

#if __has_include("FWNetworkPrivate.h")
#import "FWNetworkPrivate.h"
#endif

#if __has_include("FWAsyncSocket.h")
#import "FWAsyncSocket.h"
#endif

#if __has_include("Foundation+FWFramework.h")
#import "Foundation+FWFramework.h"
#endif

#if __has_include("UIKit+FWFramework.h")
#import "UIKit+FWFramework.h"
#endif

#if __has_include("FWAsyncLayer.h")
#import "FWAsyncLayer.h"
#endif

#endif /* FWFramework_h */
