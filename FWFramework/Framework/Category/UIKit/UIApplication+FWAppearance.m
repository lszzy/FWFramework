/*!
 @header     UIApplication+FWAppearance.m
 @indexgroup FWFramework
 @brief      UIApplication+FWAppearance
 @author     wuyong
 @copyright  Copyright © 2018 wuyong.site. All rights reserved.
 @updated    2018/12/21
 */

#import "UIApplication+FWAppearance.h"

@implementation UIApplication (FWAppearance)

/*!
 @brief 适配界面
 */
+ (void)fwAdaptAppearance
{
    if (@available(iOS 11.0, *)) {
        [UIScrollView appearance].contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    [UITableView appearance].estimatedRowHeight = 0.f;
    [UITableView appearance].estimatedSectionHeaderHeight = 0.f;
    [UITableView appearance].estimatedSectionFooterHeight = 0.f;
}

@end
