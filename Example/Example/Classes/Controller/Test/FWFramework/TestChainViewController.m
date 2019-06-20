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
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(20, 20, 50, 50)];
    view.fwViewChain.backgroundColor(UIColor.redColor).moveToSuperview(self.view);
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(90, 20, 50, 50)];
    label.fwViewChain.text(@"text").moveToSuperview(self.view);
}

@end
