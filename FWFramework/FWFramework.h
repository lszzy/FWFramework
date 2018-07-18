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
#import <FWFramework/FWLog.h>

// Application
#import <FWFramework/FWAppDelegate.h>

#else

// Framework
#import "Foundation+FWFramework.h"
#import "UIKit+FWFramework.h"

// Application
#import "FWAppDelegate.h"

#endif
