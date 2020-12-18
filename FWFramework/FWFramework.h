//
//  FWFramework.h
//  FWFramework
//
//  Created by wuyong on 2019/5/14.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<FWFramework/FWFramework.h>)

FOUNDATION_EXPORT double FWFrameworkVersionNumber;
FOUNDATION_EXPORT const unsigned char FWFrameworkVersionString[];

#import <FWFramework/FWMacro.h>
#import <FWFramework/FWNotification.h>
#import <FWFramework/FWToolkit.h>

#if __has_include(<FWFramework/FWAppDelegate.h>)
#import <FWFramework/FWAppDelegate.h>
#endif

#if __has_include(<FWFramework/FWWebViewController.h>)
#import <FWFramework/FWWebViewController.h>
#endif

#if __has_include(<FWFramework/FWModel.h>)
#import <FWFramework/FWModel.h>
#endif

#if __has_include(<FWFramework/FWView.h>)
#import <FWFramework/FWView.h>
#endif

#if __has_include(<FWFramework/FWCacheManager.h>)
#import <FWFramework/FWCacheManager.h>
#endif

#if __has_include(<FWFramework/FWDatabaseQueue.h>)
#import <FWFramework/FWDatabaseQueue.h>
#endif

#if __has_include(<FWFramework/FWWebImage.h>)
#import <FWFramework/FWWebImage.h>
#endif

#if __has_include(<FWFramework/FWHTTPSessionManager.h>)
#import <FWFramework/FWHTTPSessionManager.h>
#endif

#if __has_include(<FWFramework/FWNetworkPrivate.h>)
#import <FWFramework/FWNetworkPrivate.h>
#endif

#if __has_include(<FWFramework/FWAsyncSocket.h>)
#import <FWFramework/FWAsyncSocket.h>
#endif

#if __has_include(<FWFramework/Foundation+FWFramework.h>)
#import <FWFramework/Foundation+FWFramework.h>
#endif

#if __has_include(<FWFramework/UIKit+FWFramework.h>)
#import <FWFramework/UIKit+FWFramework.h>
#endif

#if __has_include(<FWFramework/FWAsyncLayer.h>)
#import <FWFramework/FWAsyncLayer.h>
#endif

#else

#import "FWMacro.h"
#import "FWNotification.h"
#import "FWToolkit.h"

#if __has_include("FWAppDelegate.h")
#import "FWAppDelegate.h"
#endif

#if __has_include("FWWebViewController.h")
#import "FWWebViewController.h"
#endif

#if __has_include("FWModel.h")
#import "FWModel.h"
#endif

#if __has_include("FWView.h")
#import "FWView.h"
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

#endif
