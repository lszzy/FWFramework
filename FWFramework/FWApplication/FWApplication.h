/*!
 @header     FWApplication.h
 @indexgroup FWApplication
 @brief      FWApplication头文件
 @author     wuyong
 @copyright  Copyright © 2018年 wuyong.site. All rights reserved.
 @updated    2018-09-10
 */

#import <Foundation/Foundation.h>

#if __has_include(<FWApplication/FWApplication.h>)

/*! @brief FWApplication版本号数字 */
FOUNDATION_EXPORT double FWApplicationVersionNumber;
/*! @brief FWApplication版本号字符 */
FOUNDATION_EXPORT const unsigned char FWFWApplicationVersionString[];

// Swift
#if __has_include(<FWApplication/FWApplication-Swift.h>)
#import <FWApplication/FWApplication-Swift.h>
#endif

// Application
#import <FWApplication/FWAppDelegate.h>

#else

// Application
#import "FWAppDelegate.h"

#endif
