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
    UIView *view = [[UIView alloc] init];
    view.fwViewChain.frame(CGRectMake(20, 20, 50, 50)).backgroundColor(UIColor.redColor).moveToSuperview(self.view);
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(90, 20, 50, 50)];
    label.fwViewChain.text(@"text").textAlignment(NSTextAlignmentCenter).moveToSuperview(self.view);
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.fwViewChain.frame(CGRectMake(160, 20, 50, 50)).titleColorForStateNormal(UIColor.appColorBlack).titleForStateNormal(@"btn").moveToSuperview(self.view);
    
    [UIImageView new].fwViewChain.image([UIImage fwImageWithAppIcon]).frame(CGRectMake(230, 20, 50, 50)).moveToSuperview(self.view);
    
    view = [UIView new];
    view.fwViewChain.backgroundColor(UIColor.redColor).moveToSuperview(self.view);
    view.fwLayoutChain.size(CGSizeMake(50, 50)).leftWithInset(20).topWithInset(90);
}

@end
