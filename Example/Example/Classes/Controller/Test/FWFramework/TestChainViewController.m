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
    [self renderViewChain];
    [self renderLayoutChain];
}

- (void)renderViewChain
{
    UIView *view = [[UIView alloc] init];
    view.fwViewChain.frame(CGRectMake(20, 20, 50, 50)).backgroundColor(UIColor.redColor).moveToSuperview(self.view);
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(90, 20, 50, 50)];
    label.fwViewChain.text(@"text").textAlignment(NSTextAlignmentCenter).moveToSuperview(self.view);
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.fwViewChain.frame(CGRectMake(160, 20, 50, 50)).titleColorForStateNormal(UIColor.appColorBlack).titleForStateNormal(@"btn").moveToSuperview(self.view);
    
    [UIImageView new].fwViewChain.image([UIImage fwImageWithAppIcon]).frame(CGRectMake(230, 20, 50, 50)).moveToSuperview(self.view);
}

- (void)renderLayoutChain
{
    UIView *view = [[UIView alloc] init];
    view.fwViewChain.backgroundColor(UIColor.redColor).moveToSuperview(self.view);
    view.fwLayoutChain.remake().topWithInset(90).leftWithInset(20).size(CGSizeMake(100, 100)).width(50).height(50);
    
    UILabel *label = [[UILabel alloc] init];
    label.fwViewChain.text(@"text").textAlignment(NSTextAlignmentCenter).moveToSuperview(self.view);
    label.fwLayoutChain.sizeToView(view).topToView(view).leftToRightOfViewWithOffset(view, 20);
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.fwViewChain.titleColorForStateNormal(UIColor.appColorBlack).titleForStateNormal(@"btn").moveToSuperview(self.view);
    button.fwLayoutChain.widthToView(view).heightToView(view).leftToRightOfViewWithOffset(label, 20).topToViewWithOffset(view, 0);
    
    UIImageView *image = [UIImageView new];
    image.fwViewChain.image([UIImage fwImageWithAppIcon]).moveToSuperview(self.view);
    image.fwLayoutChain.attribute(NSLayoutAttributeWidth, NSLayoutAttributeWidth, view).attribute(NSLayoutAttributeHeight, NSLayoutAttributeHeight, view).centerYToView(view).attributeWithOffset(NSLayoutAttributeLeft, NSLayoutAttributeRight, button, 20);
}

@end
