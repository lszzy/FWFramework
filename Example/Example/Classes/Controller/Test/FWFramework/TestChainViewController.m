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
    UIView *view = UIView.fwNew();
    view.fwViewChain.frame(CGRectMake(20, 20, 50, 50)).backgroundColor(UIColor.redColor).moveToSuperview(self.view);
    
    UILabel *label = UILabel.fwNewWithFrame(CGRectMake(90, 20, 50, 50));
    label.fwViewChain.text(@"text").moveToSuperview(self.view);
}

@end
