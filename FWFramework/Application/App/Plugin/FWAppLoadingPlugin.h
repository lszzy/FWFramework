/*!
 @header     FWAppLoadingPlugin.h
 @indexgroup FWFramework
 @brief      FWAppLoadingPlugin
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/9/10
 */

#import <UIKit/UIKit.h>

@protocol FWAppLoadingPlugin <NSObject>

@required

@end

@interface UIView (FWAppLoadingPlugin)

@property (nonatomic, readonly) id<FWAppLoadingPlugin> fwLoadingPlugin;

@end
