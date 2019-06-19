/*!
 @header     TestChainViewController.m
 @indexgroup Example
 @brief      TestChainViewController
 @author     wuyong
 @copyright  Copyright © 2019 wuyong.site. All rights reserved.
 @updated    2019/6/19
 */

#import "TestChainViewController.h"

@implementation TestChainViewController

- (void)renderView
{
    UIView
    .fwChainFrame(CGRectMake(20, 20, 50, 50))
    .fwChainBackgroundColor(UIColor.redColor)
    .fwChainMoveToSuperview(self.view);
    
    UILabel
    .fwChain()
    .fwChainFrame(CGRectMake(90, 20, 50, 50))
    .fwChainText(@"text")
    .fwChainMoveToSuperview(self.view);
}

@end
