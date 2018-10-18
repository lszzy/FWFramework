/*!
 @header     FWFramework.h
 @indexgroup FWFramework
 @brief      FWFramework头文件
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-05-11
 */

#import <Foundation/Foundation.h>

#if __has_include(<FWFramework/FWFramework.h>)

/*! @brief FWFramework版本号数字 */
FOUNDATION_EXPORT double FWFrameworkVersionNumber;
/*! @brief FWFramework版本号字符 */
FOUNDATION_EXPORT const unsigned char FWFrameworkVersionString[];

// Swift
#if __has_include(<FWFramework/FWFramework-Swift.h>)
#import <FWFramework/FWFramework-Swift.h>
#endif

// Framework
#import <FWFramework/Foundation+FWFramework.h>
#import <FWFramework/UIKit+FWFramework.h>
#import <FWFramework/FWMacro.h>
#import <FWFramework/FWLog.h>
#import <FWFramework/FWTest.h>
#import <FWFramework/FWPlugin.h>
#import <FWFramework/FWMessage.h>
#import <FWFramework/FWAspect.h>
#import <FWFramework/FWProxy.h>
#import <FWFramework/FWPromise.h>
#import <FWFramework/FWState.h>
#import <FWFramework/FWMutableArray.h>
#import <FWFramework/FWMutableDictionary.h>
#import <FWFramework/FWAuthorizeManager.h>
#import <FWFramework/FWKeychainManager.h>
#import <FWFramework/FWTaskManager.h>
#import <FWFramework/FWVersionManager.h>
#import <FWFramework/FWNetwork.h>
#import <FWFramework/FWRequest.h>

// Application
#import <FWFramework/FWIndicatorControl.h>
#import <FWFramework/FWProgressView.h>
#import <FWFramework/FWCollectionViewFlowLayout.h>

#else

// Framework
#import "Foundation+FWFramework.h"
#import "UIKit+FWFramework.h"
#import "FWMacro.h"
#import "FWLog.h"
#import "FWTest.h"
#import "FWPlugin.h"
#import "FWMessage.h"
#import "FWAspect.h"
#import "FWProxy.h"
#import "FWPromise.h"
#import "FWState.h"
#import "FWMutableArray.h"
#import "FWMutableDictionary.h"
#import "FWAuthorizeManager.h"
#import "FWKeychainManager.h"
#import "FWTaskManager.h"
#import "FWVersionManager.h"
#import "FWNetwork.h"
#import "FWRequest.h"

// Application
#import "FWIndicatorControl.h"
#import "FWProgressView.h"
#import "FWCollectionViewFlowLayout.h"

#endif
