/*!
 @header     UISwitch+FWFramework.m
 @indexgroup FWFramework
 @brief      UISwitch+FWFramework
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/5/17
 */

#import "UISwitch+FWFramework.h"

@implementation UISwitch (FWFramework)

- (void)fwToggle
{
    [self setOn:!self.isOn animated:YES];
}

@end
