/*!
 @header     FWAppRefreshPlugin.h
 @indexgroup FWFramework
 @brief      FWAppRefreshPlugin
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/9/10
 */

#import <UIKit/UIKit.h>

@protocol FWAppRefreshPlugin <NSObject>

@required

@end

@interface UIScrollView (FWAppRefreshPlugin)

@property (nonatomic, readonly) id<FWAppRefreshPlugin> fwRefreshPlugin;

@end
